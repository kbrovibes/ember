import Foundation

public struct SessionRecord: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var endedAt: Date
    public var duration: TimeInterval
    public var tag: String?

    public init(id: UUID = UUID(), endedAt: Date, duration: TimeInterval, tag: String? = nil) {
        self.id = id
        self.endedAt = endedAt
        self.duration = duration
        self.tag = tag
    }
}

public struct HistorySummary: Equatable, Sendable {
    public var todaySessions: Int
    public var todayFocus: TimeInterval
    public var streakDays: Int
    /// Focus seconds for the last 7 days, oldest first, ending today.
    public var last7Days: [TimeInterval]
}

public enum History {
    public static func summarize(_ records: [SessionRecord], now: Date = Date(), calendar: Calendar = .current) -> HistorySummary {
        let today = calendar.startOfDay(for: now)
        var perDay: [Date: TimeInterval] = [:]
        var countToday = 0
        for r in records {
            let day = calendar.startOfDay(for: r.endedAt)
            perDay[day, default: 0] += r.duration
            if day == today { countToday += 1 }
        }

        let last7 = (0..<7).reversed().map { offset -> TimeInterval in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return perDay[day] ?? 0
        }

        // A streak survives until the end of the next day: if nothing yet today, count from yesterday.
        var cursor = perDay[today] != nil ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        var streak = 0
        while perDay[cursor] != nil {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }

        return HistorySummary(todaySessions: countToday, todayFocus: perDay[today] ?? 0, streakDays: streak, last7Days: last7)
    }
}
