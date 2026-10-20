import Foundation
import Observation
import EmberCore

@Observable
@MainActor
final class AppModel {
    let engine: PomodoroEngine
    let settings: Settings
    private(set) var records: [SessionRecord]
    @ObservationIgnored private let store: HistoryStore
    @ObservationIgnored private var ticker: Timer?

    var presets: [Preset] { Preset.builtIn }

    init(settings: Settings = Settings(), store: HistoryStore = HistoryStore()) {
        self.settings = settings
        self.store = store
        records = store.load()

        let preset = Preset.builtIn.first { $0.id == settings.presetID } ?? .classic
        engine = PomodoroEngine(preset: preset)
        engine.autoStartNext = settings.autoStartNext
        engine.onEvent = { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }

        ticker = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.engine.tick() }
        }
        RunLoop.main.add(ticker!, forMode: .common)
        Alerts.requestAuthorization()
    }

    var summary: HistorySummary { History.summarize(records) }

    func select(_ preset: Preset) {
        settings.presetID = preset.id
        engine.select(preset)
    }

    private func handle(_ event: EngineEvent) {
        guard case .segmentEnded(let ended, let duration) = event else { return }
        if ended == .focus {
            records.append(SessionRecord(endedAt: Date(), duration: duration))
            store.save(records)
        }
        engine.autoStartNext = settings.autoStartNext
        Alerts.segmentEnded(ended, next: engine.phase, sound: settings.soundEnabled, notify: settings.notificationsEnabled)
    }
}
