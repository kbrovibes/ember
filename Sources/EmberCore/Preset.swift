import Foundation

public enum Phase: String, Codable, Sendable {
    case focus, shortBreak, longBreak

    public var isBreak: Bool { self != .focus }
}

public struct Segment: Codable, Hashable, Sendable {
    public var phase: Phase
    public var duration: TimeInterval

    public init(phase: Phase, duration: TimeInterval) {
        self.phase = phase
        self.duration = duration
    }
}

public struct Preset: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var focus: TimeInterval
    public var shortBreak: TimeInterval
    public var longBreak: TimeInterval
    public var rounds: Int

    public init(id: String, name: String, focus: TimeInterval, shortBreak: TimeInterval, longBreak: TimeInterval, rounds: Int = 4) {
        self.id = id
        self.name = name
        self.focus = focus
        self.shortBreak = shortBreak
        self.longBreak = longBreak
        self.rounds = max(1, rounds)
    }

    public var segments: [Segment] {
        (1...rounds).flatMap { round -> [Segment] in
            [
                Segment(phase: .focus, duration: focus),
                Segment(phase: round == rounds ? .longBreak : .shortBreak,
                        duration: round == rounds ? longBreak : shortBreak),
            ]
        }
    }

    public static let classic = Preset(id: "classic", name: "Classic", focus: 25 * 60, shortBreak: 5 * 60, longBreak: 15 * 60)
    public static let deep = Preset(id: "deep", name: "Deep", focus: 50 * 60, shortBreak: 10 * 60, longBreak: 30 * 60, rounds: 3)
    public static let sprint = Preset(id: "sprint", name: "Sprint", focus: 15 * 60, shortBreak: 3 * 60, longBreak: 10 * 60)

    public static let builtIn: [Preset] = [.classic, .deep, .sprint]
}
