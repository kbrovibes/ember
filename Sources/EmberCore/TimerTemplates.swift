import Foundation

/// A named duration the user has started before; the most-used ones become one-tap quick timers.
public struct TimerTemplate: Codable, Equatable, Identifiable, Sendable {
    public var name: String
    public var duration: TimeInterval
    public var uses: Int
    public var lastUsed: Date

    public var id: String { "\(name.lowercased())|\(Int(duration))" }
}

public struct TimerTemplates: Codable, Equatable, Sendable {
    public private(set) var items: [TimerTemplate]

    public static let seeds: [TimerTemplate] = [
        TimerTemplate(name: "focus", duration: 20 * 60, uses: 0, lastUsed: Date(timeIntervalSince1970: 0)),
        TimerTemplate(name: "water", duration: 60 * 60, uses: 0, lastUsed: Date(timeIntervalSince1970: 0)),
        TimerTemplate(name: "break", duration: 5 * 60, uses: 0, lastUsed: Date(timeIntervalSince1970: 0)),
    ]

    public init(items: [TimerTemplate] = TimerTemplates.seeds) { self.items = items }

    public mutating func record(name: String, duration: TimeInterval, at now: Date) {
        let key = TimerTemplate(name: name, duration: duration, uses: 0, lastUsed: now).id
        if let i = items.firstIndex(where: { $0.id == key }) {
            items[i].uses += 1
            items[i].lastUsed = now
        } else {
            items.append(TimerTemplate(name: name, duration: duration, uses: 1, lastUsed: now))
        }
    }

    public mutating func remove(id: String) { items.removeAll { $0.id == id } }

    public func top(_ count: Int) -> [TimerTemplate] {
        let ranked = items.sorted { ($0.uses, $0.lastUsed) > ($1.uses, $1.lastUsed) }
        return Array(ranked.prefix(count))
    }
}
