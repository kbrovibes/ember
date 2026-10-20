import AppKit
import Foundation
import Observation

@Observable
final class Prefs {
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            "autoStartNext": true,
            "soundEnabled": true,
            "notificationsEnabled": true,
            "menuBarShowsTime": true,
            "presetID": "classic",
            "appearance": "light",
        ])
        autoStartNext = defaults.bool(forKey: "autoStartNext")
        soundEnabled = defaults.bool(forKey: "soundEnabled")
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        menuBarShowsTime = defaults.bool(forKey: "menuBarShowsTime")
        presetID = defaults.string(forKey: "presetID") ?? "classic"
        appearance = defaults.string(forKey: "appearance") ?? "light"
    }

    var autoStartNext: Bool { didSet { defaults.set(autoStartNext, forKey: "autoStartNext") } }
    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    var notificationsEnabled: Bool { didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") } }
    var menuBarShowsTime: Bool { didSet { defaults.set(menuBarShowsTime, forKey: "menuBarShowsTime") } }
    var presetID: String { didSet { defaults.set(presetID, forKey: "presetID") } }
    /// "light" (default), "dark" or "system".
    var appearance: String {
        didSet {
            defaults.set(appearance, forKey: "appearance")
            applyAppearance()
        }
    }

    func applyAppearance() {
        NSApplication.shared.appearance = switch appearance {
        case "dark": NSAppearance(named: .darkAqua)
        case "system": nil
        default: NSAppearance(named: .aqua)
        }
    }
}
