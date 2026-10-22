import AppKit
import Foundation
import Observation

@Observable
final class Prefs {
    /// Theme colours read this so views re-render when the accent changes.
    nonisolated(unsafe) static var current: Prefs?

    static let sounds = ["Glass", "Pop", "Hero", "Ping", "Tink", "Submarine", "Funk", "Purr", "Blow", "Bottle", "Frog", "Morse", "Basso", "Sosumi"]

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
            "accent": "ember",
            "focusEndSound": "Glass",
            "breakEndSound": "Pop",
            "timerSound": "Hero",
            "soundVolume": 0.8,
        ])
        autoStartNext = defaults.bool(forKey: "autoStartNext")
        soundEnabled = defaults.bool(forKey: "soundEnabled")
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        menuBarShowsTime = defaults.bool(forKey: "menuBarShowsTime")
        presetID = defaults.string(forKey: "presetID") ?? "classic"
        appearance = defaults.string(forKey: "appearance") ?? "light"
        accent = AccentTheme(rawValue: defaults.string(forKey: "accent") ?? "") ?? .ember
        focusEndSound = defaults.string(forKey: "focusEndSound") ?? "Glass"
        breakEndSound = defaults.string(forKey: "breakEndSound") ?? "Pop"
        timerSound = defaults.string(forKey: "timerSound") ?? "Hero"
        soundVolume = defaults.double(forKey: "soundVolume")
        Prefs.current = self
    }

    var autoStartNext: Bool { didSet { defaults.set(autoStartNext, forKey: "autoStartNext") } }
    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    var notificationsEnabled: Bool { didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") } }
    var menuBarShowsTime: Bool { didSet { defaults.set(menuBarShowsTime, forKey: "menuBarShowsTime") } }
    var presetID: String { didSet { defaults.set(presetID, forKey: "presetID") } }
    var accent: AccentTheme { didSet { defaults.set(accent.rawValue, forKey: "accent") } }
    var focusEndSound: String { didSet { defaults.set(focusEndSound, forKey: "focusEndSound") } }
    var breakEndSound: String { didSet { defaults.set(breakEndSound, forKey: "breakEndSound") } }
    var timerSound: String { didSet { defaults.set(timerSound, forKey: "timerSound") } }
    var soundVolume: Double { didSet { defaults.set(soundVolume, forKey: "soundVolume") } }
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
