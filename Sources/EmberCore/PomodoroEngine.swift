import Foundation
import Observation

public enum EngineEvent: Equatable, Sendable {
    /// Emitted after the engine has moved on, so `engine.phase` is already the next phase.
    case segmentEnded(Phase, duration: TimeInterval)
    case cycleCompleted
}

@Observable
public final class PomodoroEngine {
    public enum Status: Equatable, Sendable, Codable {
        case idle
        case running(endsAt: Date)
        case paused(remaining: TimeInterval)
    }

    public private(set) var preset: Preset
    public private(set) var segments: [Segment]
    public private(set) var index = 0
    public private(set) var status: Status = .idle
    public private(set) var completedFocusSessions = 0

    public var autoStartNext = true
    @ObservationIgnored public var onEvent: ((EngineEvent) -> Void)?
    @ObservationIgnored private let clock: () -> Date

    public init(preset: Preset = .classic, clock: @escaping () -> Date = Date.init) {
        self.preset = preset
        self.segments = preset.segments
        self.clock = clock
    }

    public var segment: Segment { segments[index] }
    public var phase: Phase { segment.phase }
    public var round: Int { index / 2 + 1 }
    public var isRunning: Bool { if case .running = status { return true } else { return false } }
    public var isIdle: Bool { status == .idle }

    public func remaining(at now: Date) -> TimeInterval {
        switch status {
        case .idle: return segment.duration
        case .running(let end): return max(0, end.timeIntervalSince(now))
        case .paused(let remaining): return remaining
        }
    }

    public func progress(at now: Date) -> Double {
        guard segment.duration > 0 else { return 0 }
        return min(1, max(0, 1 - remaining(at: now) / segment.duration))
    }

    public func start() {
        switch status {
        case .idle: status = .running(endsAt: clock().addingTimeInterval(segment.duration))
        case .paused(let remaining): status = .running(endsAt: clock().addingTimeInterval(remaining))
        case .running: break
        }
    }

    public func pause() {
        guard case .running = status else { return }
        status = .paused(remaining: remaining(at: clock()))
    }

    public func toggle() { isRunning ? pause() : start() }

    public func reset() { status = .idle }

    public func resetCycle() {
        index = 0
        completedFocusSessions = 0
        status = .idle
    }

    public func skip() {
        advance(emitEvent: false)
    }

    public func select(_ newPreset: Preset) {
        preset = newPreset
        segments = newPreset.segments
        resetCycle()
    }

    /// One-off duration override for the current segment; only while idle.
    public func setDuration(_ seconds: TimeInterval) {
        guard isIdle else { return }
        segments[index].duration = max(1, seconds)
    }

    /// Call from a UI timer. Advances the cycle when the running segment has elapsed.
    public func tick(now: Date? = nil) {
        guard case .running(let end) = status, (now ?? clock()) >= end else { return }
        advance(emitEvent: true)
    }

    public struct Snapshot: Codable, Equatable, Sendable {
        public var presetID: String
        public var index: Int
        public var status: Status
        public var completedFocusSessions: Int
        public var durations: [TimeInterval]
    }

    public func snapshot() -> Snapshot {
        Snapshot(presetID: preset.id, index: index, status: status, completedFocusSessions: completedFocusSessions, durations: segments.map(\.duration))
    }

    /// Reapplies saved progress onto the already-selected preset. A segment that finished while the app was closed moves on, idle.
    public func restore(_ saved: Snapshot, now: Date? = nil) {
        guard saved.presetID == preset.id, segments.indices.contains(saved.index) else { return }
        if saved.durations.count == segments.count {
            for i in segments.indices { segments[i].duration = saved.durations[i] }
        }
        index = saved.index
        completedFocusSessions = saved.completedFocusSessions
        status = saved.status
        if case .running(let end) = saved.status, (now ?? clock()) >= end { advance(emitEvent: false) }
    }

    private func advance(emitEvent: Bool) {
        let ended = segment
        if ended.phase == .focus { completedFocusSessions += 1 }

        let wrapped = index + 1 >= segments.count
        index = wrapped ? 0 : index + 1
        status = .idle

        if emitEvent {
            if !wrapped && autoStartNext { start() }
            onEvent?(.segmentEnded(ended.phase, duration: ended.duration))
            if wrapped { onEvent?(.cycleCompleted) }
        }
    }
}
