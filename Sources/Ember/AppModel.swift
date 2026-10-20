import Foundation
import Observation
import EmberCore

@Observable
@MainActor
final class AppModel {
    let engine: PomodoroEngine
    let prefs: Prefs
    private(set) var records: [SessionRecord]
    /// Refreshed ~10x/s while running; views read this instead of polling the clock.
    private(set) var now = Date()
    private(set) var clockText = "25:00"
    @ObservationIgnored private let store: HistoryStore
    @ObservationIgnored private var ticker: Timer?

    var presets: [Preset] { Preset.builtIn }

    init(prefs: Prefs = Prefs(), store: HistoryStore = HistoryStore()) {
        self.prefs = prefs
        self.store = store
        records = store.load()
        prefs.applyAppearance()

        let preset = Preset.builtIn.first { $0.id == prefs.presetID } ?? .classic
        engine = PomodoroEngine(preset: preset)
        engine.autoStartNext = prefs.autoStartNext
        engine.onEvent = { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }

        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.engine.isRunning else { return }
                self.engine.tick()
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

    // MARK: internals

    private func refresh() {
        now = Date()
        let text = TimeFormat.clock(engine.remaining(at: now))
        if text != clockText { clockText = text }
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
