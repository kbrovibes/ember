import AppKit
import SwiftUI
import EmberCore

extension NSColor {
    convenience init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&v)
        self.init(srgbRed: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: 1)
    }
}

extension Color {
    init(light: String, dark: String) {
        self = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(hex: dark) : NSColor(hex: light)
        }))
    }
}

/// Values mirror design/tokens.json.
enum Theme {
    static let bg = Color(light: "FAFAFA", dark: "0E0E10")
    static let surface = Color(light: "FFFFFF", dark: "17171A")
    static let surface2 = Color(light: "F4F4F5", dark: "1F1F23")
    static let line = Color(light: "E4E4E7", dark: "2A2A2F")
    static let line2 = Color(light: "D4D4D8", dark: "3A3A41")
    static let ink = Color(light: "18181B", dark: "F4F4F5")
    static let ink2 = Color(light: "52525B", dark: "A1A1AA")
    static let ink3 = Color(light: "676773", dark: "9A9AA5")
    static let onAccent = Color(light: "FFFFFF", dark: "1A0D07")

    static let spring = Animation.spring(response: 0.39, dampingFraction: 0.81)
    static let colorShift = Animation.easeInOut(duration: 0.7)

    static func accent(_ phase: Phase) -> Color {
        switch phase {
        case .focus: (Prefs.current?.accent ?? .ember).accent
        case .shortBreak: Color(light: "2C7A8C", dark: "6CC4D6")
        case .longBreak: Color(light: "5A5FB8", dark: "9EA3F0")
        }
    }

    static func soft(_ phase: Phase) -> Color {
        switch phase {
        case .focus: (Prefs.current?.accent ?? .ember).soft
        case .shortBreak: Color(light: "E4F1F4", dark: "10252A")
        case .longBreak: Color(light: "ECEDF9", dark: "1A1B33")
        }
    }
}

/// Colour theme for the focus phase and timer cards. Break phases keep their own colours.
enum AccentTheme: String, CaseIterable, Identifiable {
    case ember, plum, moss, graphite

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var lightHex: String {
        switch self {
        case .ember: "CC4317"
        case .plum: "8A3F9E"
        case .moss: "3E7D4F"
        case .graphite: "3F3F46"
        }
    }

    var accent: Color {
        switch self {
        case .ember: Color(light: "CC4317", dark: "FF8A5B")
        case .plum: Color(light: "8A3F9E", dark: "D39BE4")
        case .moss: Color(light: "3E7D4F", dark: "86CF99")
        case .graphite: Color(light: "3F3F46", dark: "D4D4D8")
        }
    }

    var soft: Color {
        switch self {
        case .ember: Color(light: "FCEDE6", dark: "2B1710")
        case .plum: Color(light: "F4EAF7", dark: "261430")
        case .moss: Color(light: "E8F3EB", dark: "11261A")
        case .graphite: Color(light: "EFEFF1", dark: "222226")
        }
    }
}

extension Phase {
    var label: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short break"
        case .longBreak: "Long break"
        }
    }

    var symbol: String {
        switch self {
        case .focus: "flame.fill"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "moon.fill"
        }
    }

    /// Allowed drag-to-set range, in minutes.
    var minuteRange: ClosedRange<Double> {
        switch self {
        case .focus: 1...90
        case .shortBreak: 1...30
        case .longBreak: 5...60
        }
    }
}
