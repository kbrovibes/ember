import Foundation
import Observation

@Observable
final class Settings {
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            "autoStartNext": true,
            "soundEnabled": true,
            "notificationsEnabled": true,
            "menuBarShowsTime": true,
            "presetID": "classic",
        ])
        autoStartNext = defaults.bool(forKey: "autoStartNext")
        soundEnabled = defaults.bool(forKey: "soundEnabled")
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        menuBarShowsTime = defaults.bool(forKey: "menuBarShowsTime")
        presetID = defaults.string(forKey: "presetID") ?? "classic"
    }

    var autoStartNext: Bool { didSet { defaults.set(autoStartNext, forKey: "autoStartNext") } }
    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    var notificationsEnabled: Bool { didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") } }
    var menuBarShowsTime: Bool { didSet { defaults.set(menuBarShowsTime, forKey: "menuBarShowsTime") } }
    var presetID: String { didSet { defaults.set(presetID, forKey: "presetID") } }
}
