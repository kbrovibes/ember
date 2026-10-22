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

public struct NamedTimer: Equatable, Sendable {
    public var name: String
    public var duration: TimeInterval
}

extension InputParser {
    private static let unitRun = try! NSRegularExpression(
        pattern: #"(?:\d+(?:\.\d+)?\s*(?:hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)(?![a-z])[\s,]*(?:and\s+)?)+|\b\d+:\d{2}(?::\d{2})?\b"#,
        options: [.caseInsensitive])
    private static let bareNumber = try! NSRegularExpression(pattern: #"\b\d+(?:\.\d+)?\b"#)
    private static let fillers: Set<String> = ["for", "a", "an", "of", "in", "timer", "set", "start", "new", "minute", "minutes", "min", "mins"]

    /// Free-form entry like `water 2m`, `focus 20min`, `1 hour 30 minutes laundry` or `5m #tea`: the duration is
    /// pulled out wherever it sits and what remains becomes the name, lowercased. A lone bare number means minutes.
    public static func parseNamed(_ input: String) -> NamedTimer? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let whole = NSRange(text.startIndex..., in: text)
        guard let match = unitRun.firstMatch(in: text, range: whole) ?? bareNumber.firstMatch(in: text, range: whole),
              let range = Range(match.range, in: text) else { return nil }

        let spec = text[range].trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard let duration = duration(of: spec), duration > 0 else { return nil }

        var rest = text
        rest.removeSubrange(range)
        var words = rest.split(whereSeparator: \.isWhitespace).map(String.init)
        if let tag = words.first(where: { $0.hasPrefix("#") && $0.count > 1 }) {
            words = [String(tag.dropFirst())]
        }
        while let first = words.first, fillers.contains(first.lowercased()) { words.removeFirst() }
        while let last = words.last, fillers.contains(last.lowercased()) { words.removeLast() }

        return NamedTimer(name: words.joined(separator: " ").lowercased(), duration: duration)
    }

    private static func duration(of spec: String) -> TimeInterval? {
        if spec.contains(":") || Double(spec) != nil { return seconds(spec) }
        let units: [(String, Double)] = [("hours", 3600), ("hour", 3600), ("hrs", 3600), ("hr", 3600), ("h", 3600),
                                         ("minutes", 60), ("minute", 60), ("mins", 60), ("min", 60), ("m", 60),
                                         ("seconds", 1), ("second", 1), ("secs", 1), ("sec", 1), ("s", 1)]
        guard let pairs = try? NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*([a-z]+)"#, options: .caseInsensitive) else { return nil }
        var total = 0.0
        for m in pairs.matches(in: spec, range: NSRange(spec.startIndex..., in: spec)) {
            guard let n = Range(m.range(at: 1), in: spec), let u = Range(m.range(at: 2), in: spec),
                  let value = Double(spec[n]),
                  let factor = units.first(where: { $0.0 == spec[u].lowercased() })?.1 else { return nil }
            total += value * factor
        }
        return total
    }
}
