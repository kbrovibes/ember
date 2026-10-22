import Foundation

/// An independent countdown, separate from the Pomodoro cycle.
public struct QuickTimer: Identifiable, Equatable, Sendable, Codable {
    public enum State: Equatable, Sendable, Codable {
        case idle
        case running(endsAt: Date)
        case paused(remaining: TimeInterval)
        case done
    }

    public let id: UUID
    public var label: String
    public let duration: TimeInterval
    public private(set) var state: State = .idle

    public init(id: UUID = UUID(), label: String, duration: TimeInterval) {
        self.id = id
        self.label = label
        self.duration = duration
    }

    public var isRunning: Bool { if case .running = state { true } else { false } }
    public var isDone: Bool { state == .done }

    public func remaining(at now: Date) -> TimeInterval {
        switch state {
        case .idle: duration
        case .running(let endsAt): max(0, endsAt.timeIntervalSince(now))
        case .paused(let remaining): remaining
        case .done: 0
        }
    }

    public func progress(at now: Date) -> Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, 1 - remaining(at: now) / duration))
    }

    public mutating func toggle(at now: Date) {
        switch state {
        case .idle, .done: state = .running(endsAt: now.addingTimeInterval(duration))
        case .running: state = .paused(remaining: remaining(at: now))
        case .paused(let remaining): state = .running(endsAt: now.addingTimeInterval(remaining))
        }
    }

    public mutating func reset() { state = .idle }

    /// Returns true on the tick that finishes the timer.
    @discardableResult
    public mutating func tick(at now: Date) -> Bool {
        guard case .running(let endsAt) = state, now >= endsAt else { return false }
        state = .done
        return true
    }
}
