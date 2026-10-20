import Testing
import Foundation
@testable import EmberCore

@Suite struct InputParserTests {
    @Test func bareNumberIsMinutes() {
        #expect(InputParser.parse("25")?.duration == 1500)
    }

    @Test func units() {
        #expect(InputParser.parse("1h30m")?.duration == 5400)
        #expect(InputParser.parse("90s")?.duration == 90)
        #expect(InputParser.parse("25:00")?.duration == 1500)
        #expect(InputParser.parse("1:00:00")?.duration == 3600)
    }

    @Test func signalAndTag() {
        let p = InputParser.parse("5m/1m #deep")
        #expect(p?.duration == 300)
        #expect(p?.signalInterval == 60)
        #expect(p?.tag == "deep")
    }

    @Test func rejectsGarbage() {
        for bad in ["", "abc", "5m/10m", "5m 6m", "0"] {
            #expect(InputParser.parse(bad) == nil, "\(bad) should not parse")
        }
    }
}

@Suite struct PresetTests {
    @Test func classicHasEightSegmentsEndingInLongBreak() {
        let s = Preset.classic.segments
        #expect(s.count == 8)
        #expect(s.map(\.phase) == [.focus, .shortBreak, .focus, .shortBreak, .focus, .shortBreak, .focus, .longBreak])
        #expect(s.last?.duration == TimeInterval(900))
    }
}

@Suite final class EngineTests {
    private var now = Date(timeIntervalSince1970: 1_000_000)

    private func makeEngine() -> PomodoroEngine {
        PomodoroEngine(preset: .classic, clock: { [unowned self] in self.now })
    }

    @Test func startPauseResumePreservesRemaining() {
        let e = makeEngine()
        e.start()
        now.addTimeInterval(100)
        e.pause()
        #expect(abs(e.remaining(at: now) - 1400) < 0.001)
        now.addTimeInterval(500)
        e.start()
        now.addTimeInterval(50)
        #expect(abs(e.remaining(at: now) - 1350) < 0.001)
    }

    @Test func autoAdvanceToBreakAndEmitsEvent() {
        let e = makeEngine()
        var events: [EngineEvent] = []
        e.onEvent = { events.append($0) }
        e.start()
        now.addTimeInterval(1500)
        e.tick()
        #expect(events == [.segmentEnded(.focus)])
        #expect(e.phase == .shortBreak)
        #expect(e.isRunning)
        #expect(e.completedFocusSessions == 1)
    }

    @Test func noAutoStartLeavesIdle() {
        let e = makeEngine()
        e.autoStartNext = false
        e.start()
        now.addTimeInterval(1500)
        e.tick()
        #expect(e.isIdle)
        #expect(e.phase == .shortBreak)
    }

    @Test func fullCycleCompletes() {
        let e = makeEngine()
        var events: [EngineEvent] = []
        e.onEvent = { events.append($0) }
        e.start()
        for segment in Preset.classic.segments {
            now.addTimeInterval(segment.duration)
            e.tick()
        }
        #expect(events.last == .cycleCompleted)
        #expect(e.completedFocusSessions == 4)
        #expect(e.index == 0)
        #expect(e.isIdle)
    }

    @Test func setDurationOnlyWhenIdle() {
        let e = makeEngine()
        e.setDuration(600)
        #expect(e.segment.duration == 600)
        e.start()
        e.setDuration(900)
        #expect(e.segment.duration == 600)
    }

    @Test func skipMovesOnWithoutEvent() {
        let e = makeEngine()
        var events: [EngineEvent] = []
        e.onEvent = { events.append($0) }
        e.skip()
        #expect(e.phase == .shortBreak)
        #expect(events.isEmpty)
    }
}
