import Foundation
import EmberCore

struct AppState: Codable {
    var timers: [QuickTimer] = []
    var templates = TimerTemplates()
    var engine: PomodoroEngine.Snapshot?
}

struct StateStore {
    let url: URL

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Ember", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        url = base.appendingPathComponent("state.json")
    }

    func load() -> AppState {
        guard let data = try? Data(contentsOf: url) else { return AppState() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return (try? decoder.decode(AppState.self, from: data)) ?? AppState()
    }

    func save(_ state: AppState) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
