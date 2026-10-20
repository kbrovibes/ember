import Foundation

public enum TimeFormat {
    /// `24:59`, or `1:05:00` past an hour. Rounds up so a running timer never shows 00:00 early.
    public static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    /// `25 min`, `1 h 30 min`, `45 s` — for labels and stats.
    public static func spoken(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        switch (h, m) {
        case (0, 0): return "\(s) s"
        case (0, _): return "\(m) min"
        case (_, 0): return "\(h) h"
        default: return "\(h) h \(m) min"
        }
    }
}
