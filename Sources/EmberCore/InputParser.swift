import Foundation

public struct ParsedTimer: Equatable, Sendable {
    public var duration: TimeInterval
    public var signalInterval: TimeInterval?
    public var tag: String?
}

/// Parses Red Hot Timer–style shorthand: `25`, `25m`, `1h30m`, `90s`, `25:00`, `5m/1m`, `25m #deep`.
public enum InputParser {
    public static func parse(_ input: String) -> ParsedTimer? {
        var tag: String?
        var words: [String] = []
        for word in input.split(whereSeparator: \.isWhitespace) {
            if word.hasPrefix("#"), word.count > 1 { tag = String(word.dropFirst()) } else { words.append(String(word)) }
        }
        guard let spec = words.first, words.count == 1 else { return nil }

        let parts = spec.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard parts.count <= 2, let duration = seconds(parts[0]), duration > 0 else { return nil }

        var signal: TimeInterval?
        if parts.count == 2 {
            guard let s = seconds(parts[1]), s > 0, s < duration else { return nil }
            signal = s
        }
        return ParsedTimer(duration: duration, signalInterval: signal, tag: tag)
    }

    static func seconds(_ text: String) -> TimeInterval? {
        let t = text.lowercased()
        if t.contains(":") {
            let fields = t.split(separator: ":", omittingEmptySubsequences: false).map { Double($0) }
            guard fields.count == 2 || fields.count == 3, !fields.contains(where: { $0 == nil }) else { return nil }
            return fields.compactMap { $0 }.reduce(0) { $0 * 60 + $1 }
        }
        if let bare = Double(t) { return bare * 60 }

        var total = 0.0
        var number = ""
        var sawUnit = false
        for ch in t {
            if ch.isNumber || ch == "." {
                number.append(ch)
            } else if let value = Double(number), let unit = ["h": 3600.0, "m": 60.0, "s": 1.0][String(ch)] {
                total += value * unit
                number = ""
                sawUnit = true
            } else {
                return nil
            }
        }
        return number.isEmpty && sawUnit ? total : nil
    }
}
