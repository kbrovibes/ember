import AppKit
import Foundation
import Observation

enum TimerSort: String, CaseIterable, Identifiable {
    case added, name, remaining, total

    var id: String { rawValue }
    var title: String {
        switch self {
        case .added: "Order"
        case .name: "A–Z"
        case .remaining: "Time left"
        case .total: "Length"
        }
    }
}

@Observable
final class Prefs {
    /// Theme colours read this so views re-render when the accent changes.
    nonisolated(unsafe) static var current: Prefs?

    static let sounds = ["Glass", "Pop", "Hero", "Ping", "Tink", "Submarine", "Funk", "Purr", "Blow", "Bottle", "Frog", "Morse", "Basso", "Sosumi"]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            "soundEnabled": true,
            "notificationsEnabled": true,
            "menuBarShowsTime": true,
            "appearance": "light",
            "accent": "ember",
            "timerTheme": "tape",
            "autoZen": true,
            "glyphStyle": "symbol",
            "sort": "added",
            "sortAscending": true,
            "timerSound": "Hero",
            "soundVolume": 0.8,
        ])
        soundEnabled = defaults.bool(forKey: "soundEnabled")
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        menuBarShowsTime = defaults.bool(forKey: "menuBarShowsTime")
        appearance = defaults.string(forKey: "appearance") ?? "light"
        autoZen = defaults.bool(forKey: "autoZen")
        glyphStyle = GlyphStyle(rawValue: defaults.string(forKey: "glyphStyle") ?? "") ?? .symbol
        sort = TimerSort(rawValue: defaults.string(forKey: "sort") ?? "") ?? .added
        sortAscending = defaults.bool(forKey: "sortAscending")
        timerTheme = TimerTheme(rawValue: defaults.string(forKey: "timerTheme") ?? "") ?? .tape
        accent = AccentTheme(rawValue: defaults.string(forKey: "accent") ?? "") ?? .ember
        timerSound = defaults.string(forKey: "timerSound") ?? "Hero"
        soundVolume = defaults.double(forKey: "soundVolume")
        Prefs.current = self
    }

    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    var notificationsEnabled: Bool { didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") } }
    var menuBarShowsTime: Bool { didSet { defaults.set(menuBarShowsTime, forKey: "menuBarShowsTime") } }
    var glyphStyle: GlyphStyle { didSet { defaults.set(glyphStyle.rawValue, forKey: "glyphStyle") } }
    var autoZen: Bool { didSet { defaults.set(autoZen, forKey: "autoZen") } }
    var sort: TimerSort { didSet { defaults.set(sort.rawValue, forKey: "sort") } }
    var sortAscending: Bool { didSet { defaults.set(sortAscending, forKey: "sortAscending") } }
    var timerTheme: TimerTheme { didSet { defaults.set(timerTheme.rawValue, forKey: "timerTheme") } }
    var accent: AccentTheme { didSet { defaults.set(accent.rawValue, forKey: "accent") } }
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
