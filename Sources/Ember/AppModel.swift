import AppKit
import Foundation
import Observation
import EmberCore

enum MainTab: Hashable { case pomodoro, timers }

@Observable
@MainActor
final class AppModel {
    var mainTab: MainTab = .pomodoro
    /// Timers that have finished and are still alarming; they ring on repeat until dismissed.
    private(set) var ringing: Set<QuickTimer.ID> = []
    @ObservationIgnored private var alarm: Timer?

    let engine: PomodoroEngine
    let prefs: Prefs
    private(set) var records: [SessionRecord]
    private(set) var customPresets: [Preset]
    /// Refreshed ~10x/s while running; views read this instead of polling the clock.
    private(set) var now = Date()
    private(set) var clockText = "25:00"
    private(set) var timers: [QuickTimer]
    private(set) var templates: TimerTemplates
    @ObservationIgnored private let store: HistoryStore
    @ObservationIgnored private let presetStore: PresetStore
    @ObservationIgnored private let stateStore: StateStore
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let dock = DockProgress()

    var dataFolder: URL { stateStore.url.deletingLastPathComponent() }

    var presets: [Preset] { Preset.builtIn + customPresets }

    init(prefs: Prefs = Prefs(), store: HistoryStore = HistoryStore(), presetStore: PresetStore = PresetStore(), stateStore: StateStore = StateStore()) {
        self.prefs = prefs
        self.store = store
        self.presetStore = presetStore
        self.stateStore = stateStore
        records = store.load()
        let custom = presetStore.load()
        customPresets = custom
        prefs.applyAppearance()

        let preset = (Preset.builtIn + custom).first { $0.id == prefs.presetID } ?? .classic
        engine = PomodoroEngine(preset: preset)
        engine.autoStartNext = prefs.autoStartNext

        let saved = stateStore.load()
        templates = saved.templates
        let launch = Date()
        timers = saved.timers.map { var t = $0; t.tick(at: launch); return t }
        if let snapshot = saved.engine { engine.restore(snapshot) }
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
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.persist() }
        }
    }

    var summary: HistorySummary { History.summarize(records) }
    var remaining: TimeInterval { engine.remaining(at: now) }
    var progress: Double { engine.progress(at: now) }

    // MARK: actions

    func toggle() { engine.toggle(); commit() }
    func reset() { engine.reset(); commit() }
    func skip() { engine.skip(); commit() }

    func setMinutes(_ minutes: Double) {
        engine.setDuration(minutes * 60)
        commit()
    }

    /// Red Hot Timer–style shorthand: `25`, `1h30m`, `5m/1m #tag`. Returns false if unparseable.
    @discardableResult
    func apply(text: String) -> Bool {
        guard let parsed = InputParser.parse(text) else { return false }
        engine.reset()
        engine.setDuration(parsed.duration)
        commit()
        return true
    }

    func select(_ preset: Preset) {
        prefs.presetID = preset.id
        engine.select(preset)
        commit()
    }

    // MARK: quick timers

    /// Free-form entry such as `water 2m` or `focus 20min`. Returns false if no duration can be found.
    @discardableResult
    func addTimer(text: String) -> Bool {
        guard let parsed = InputParser.parseNamed(text) else { return false }
        addTimer(name: parsed.name, duration: parsed.duration)
        return true
    }

    func showTimers() { mainTab = .timers }

    /// Named timers are remembered, so the ones used most show up as quick-start chips next launch.
    func addTimer(name: String, duration: TimeInterval) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        var timer = QuickTimer(label: trimmed.isEmpty ? TimeFormat.spoken(duration) : trimmed, duration: duration)
        timer.toggle(at: Date())
        timers.append(timer)
        if !trimmed.isEmpty { templates.record(name: trimmed, duration: duration, at: Date()) }
        commit()
    }

    func startTemplate(_ template: TimerTemplate) { addTimer(name: template.name, duration: template.duration) }
    func removeTemplate(_ template: TimerTemplate) { templates.remove(id: template.id); commit() }
    func renameTimer(_ id: QuickTimer.ID, to label: String) { mutateTimer(id) { $0.label = label } }

    func toggleTimer(_ id: QuickTimer.ID) { dismissAlarm(id); mutateTimer(id) { $0.toggle(at: Date()) } }
    func resetTimer(_ id: QuickTimer.ID) { dismissAlarm(id); mutateTimer(id) { $0.reset() } }
    func removeTimer(_ id: QuickTimer.ID) { dismissAlarm(id); timers.removeAll { $0.id == id }; commit() }
    func dismissAlarm(_ id: QuickTimer.ID) {
        guard ringing.remove(id) != nil else { return }
        if ringing.isEmpty { alarm?.invalidate(); alarm = nil }
    }

    private func startAlarm(for id: QuickTimer.ID) {
        ringing.insert(id)
        guard alarm == nil else { return }
        let timer = Timer(timeInterval: 2.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.prefs.soundEnabled else { return }
                Alerts.play(self.prefs.timerSound, volume: self.prefs.soundVolume)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        alarm = timer
        if prefs.soundEnabled { Alerts.play(prefs.timerSound, volume: prefs.soundVolume) }
    }

    private func mutateTimer(_ id: QuickTimer.ID, _ change: (inout QuickTimer) -> Void) {
        guard let i = timers.firstIndex(where: { $0.id == id }) else { return }
        change(&timers[i])
        commit()
    }

    private func tickTimers() {
        let date = Date()
        for i in timers.indices where timers[i].tick(at: date) {
            Alerts.timerDone(timers[i].label, prefs: prefs)
            startAlarm(for: timers[i].id)
            mainTab = .timers
            NSApp.activate(ignoringOtherApps: true)
            NSApp.requestUserAttention(.criticalRequest)
        }
        persist()
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
        if engine.preset.id == preset.id && engine.isIdle { engine.select(preset); commit() }
    }

    func deletePreset(_ id: String) {
        customPresets.removeAll { $0.id == id }
        presetStore.save(customPresets)
        if engine.preset.id == id { select(.classic) }
    }

    // MARK: internals

    private func commit() {
        refresh()
        persist()
    }

    private func persist() {
        stateStore.save(AppState(timers: timers, templates: templates, engine: engine.snapshot()))
    }

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
        Alerts.segmentEnded(ended, next: engine.phase, prefs: prefs)
        persist()
    }
}
