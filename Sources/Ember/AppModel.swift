import Foundation
import Observation
import EmberCore

@Observable
@MainActor
final class AppModel {
    let engine: PomodoroEngine
    let prefs: Prefs
    private(set) var records: [SessionRecord]
    private(set) var customPresets: [Preset]
    /// Refreshed ~10x/s while running; views read this instead of polling the clock.
    private(set) var now = Date()
    private(set) var clockText = "25:00"
    private(set) var timers: [QuickTimer] = []
    @ObservationIgnored private let store: HistoryStore
    @ObservationIgnored private let presetStore: PresetStore
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let dock = DockProgress()

    var presets: [Preset] { Preset.builtIn + customPresets }

    init(prefs: Prefs = Prefs(), store: HistoryStore = HistoryStore(), presetStore: PresetStore = PresetStore()) {
        self.prefs = prefs
        self.store = store
        self.presetStore = presetStore
        records = store.load()
        let custom = presetStore.load()
        customPresets = custom
        prefs.applyAppearance()

        let preset = (Preset.builtIn + custom).first { $0.id == prefs.presetID } ?? .classic
        engine = PomodoroEngine(preset: preset)
        engine.autoStartNext = prefs.autoStartNext
        engine.onEvent = { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }

        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let timersRunning = self.timers.contains { $0.isRunning }
                guard self.engine.isRunning || timersRunning else { return }
                if self.engine.isRunning { self.engine.tick() }
                if timersRunning { self.tickTimers() }
                self.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer

        refresh()
        Alerts.requestAuthorization()
    }

    var summary: HistorySummary { History.summarize(records) }
    var remaining: TimeInterval { engine.remaining(at: now) }
    var progress: Double { engine.progress(at: now) }

    // MARK: actions

    func toggle() { engine.toggle(); refresh() }
    func reset() { engine.reset(); refresh() }
    func skip() { engine.skip(); refresh() }

    func setMinutes(_ minutes: Double) {
        engine.setDuration(minutes * 60)
        refresh()
    }

    /// Red Hot Timer–style shorthand: `25`, `1h30m`, `5m/1m #tag`. Returns false if unparseable.
    @discardableResult
    func apply(text: String) -> Bool {
        guard let parsed = InputParser.parse(text) else { return false }
        engine.reset()
        engine.setDuration(parsed.duration)
        refresh()
        return true
    }

    func select(_ preset: Preset) {
        prefs.presetID = preset.id
        engine.select(preset)
        refresh()
    }

    // MARK: quick timers

    /// Accepts the same shorthand as the main field (`5m`, `1h30m`, `90s #tea`). Returns false if unparseable.
    @discardableResult
    func addTimer(text: String, start: Bool = true) -> Bool {
        guard let parsed = InputParser.parse(text) else { return false }
        var timer = QuickTimer(label: parsed.tag ?? TimeFormat.spoken(parsed.duration), duration: parsed.duration)
        if start { timer.toggle(at: Date()) }
        timers.append(timer)
        refresh()
        return true
    }

    func toggleTimer(_ id: QuickTimer.ID) { mutateTimer(id) { $0.toggle(at: Date()) } }
    func resetTimer(_ id: QuickTimer.ID) { mutateTimer(id) { $0.reset() } }
    func removeTimer(_ id: QuickTimer.ID) { timers.removeAll { $0.id == id }; refresh() }

    private func mutateTimer(_ id: QuickTimer.ID, _ change: (inout QuickTimer) -> Void) {
        guard let i = timers.firstIndex(where: { $0.id == id }) else { return }
        change(&timers[i])
        refresh()
    }

    private func tickTimers() {
        let date = Date()
        for i in timers.indices where timers[i].tick(at: date) {
            Alerts.timerDone(timers[i].label, sound: prefs.soundEnabled, notify: prefs.notificationsEnabled)
        }
    }

    // MARK: scenarios

    func isBuiltIn(_ preset: Preset) -> Bool { Preset.builtIn.contains { $0.id == preset.id } }

    @discardableResult
    func addPreset(from template: Preset? = nil) -> Preset {
        let base = template ?? .classic
        var copy = base
        copy.id = UUID().uuidString
        copy.name = template == nil ? "Custom \(customPresets.count + 1)" : "\(base.name) copy"
        customPresets.append(copy)
        presetStore.save(customPresets)
        return copy
    }

    func update(_ preset: Preset) {
        guard let i = customPresets.firstIndex(where: { $0.id == preset.id }) else { return }
        customPresets[i] = preset
        presetStore.save(customPresets)
        if engine.preset.id == preset.id && engine.isIdle { engine.select(preset); refresh() }
    }

    func deletePreset(_ id: String) {
        customPresets.removeAll { $0.id == id }
        presetStore.save(customPresets)
        if engine.preset.id == id { select(.classic) }
    }

    // MARK: internals

    private func refresh() {
        now = Date()
        let text = TimeFormat.clock(engine.remaining(at: now))
        if text != clockText { clockText = text }
        dock.update(progress: engine.isIdle ? nil : engine.progress(at: now), phase: engine.phase)
    }

    private func handle(_ event: EngineEvent) {
        guard case .segmentEnded(let ended, let duration) = event else { return }
        if ended == .focus {
            records.append(SessionRecord(endedAt: Date(), duration: duration))
            store.save(records)
        }
        engine.autoStartNext = prefs.autoStartNext
        Alerts.segmentEnded(ended, next: engine.phase, sound: prefs.soundEnabled, notify: prefs.notificationsEnabled)
    }
}
