import AppKit
import SwiftUI

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
    /// Softer than `spring`: used when timer cards reflow after the window or the timer count changes.
    static let layout = Animation.spring(response: 0.5, dampingFraction: 0.86)
    static let colorShift = Animation.easeInOut(duration: 0.7)

    static var accent: Color { (Prefs.current?.accent ?? .ember).accent }
    static var soft: Color { (Prefs.current?.accent ?? .ember).soft }
    /// Used for finished timers.
    static let done = Color(light: "2C7A8C", dark: "6CC4D6")
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Theme.spring, value: configuration.isPressed)
    }
}

/// Accent colour for buttons, timer cards and the text-line underline.
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

    var darkHex: String {
        switch self {
        case .ember: "FF8A5B"
        case .plum: "D39BE4"
        case .moss: "86CF99"
        case .graphite: "D4D4D8"
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
