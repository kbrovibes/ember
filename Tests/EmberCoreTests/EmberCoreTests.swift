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

@Suite struct FormatTests {
    @Test func clock() {
        #expect(TimeFormat.clock(1500) == "25:00")
        #expect(TimeFormat.clock(1499.2) == "25:00")
        #expect(TimeFormat.clock(59) == "00:59")
        #expect(TimeFormat.clock(3725) == "1:02:05")
        #expect(TimeFormat.clock(-3) == "00:00")
    }

    @Test func spoken() {
        #expect(TimeFormat.spoken(1500) == "25 min")
        #expect(TimeFormat.spoken(5400) == "1 h 30 min")
        #expect(TimeFormat.spoken(7200) == "2 h")
        #expect(TimeFormat.spoken(45) == "45 s")
    }
}

@Suite struct HistoryTests {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func at(_ daysAgo: Int, hour: Int = 10, from now: Date) -> Date {
        cal.date(byAdding: .hour, value: hour, to: cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: now))!)!
    }

    @Test func summarizesTodayAndStreak() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let records = [0, 0, 1, 2, 4].map { SessionRecord(endedAt: at($0, from: now), duration: 1500) }
        let s = History.summarize(records, now: now, calendar: cal)
        #expect(s.todaySessions == 2)
        #expect(s.todayFocus == 3000)
        #expect(s.streakDays == 3)
        #expect(s.last7Days.count == 7)
        #expect(s.last7Days.last == 3000)
    }

    @Test func streakSurvivesUntilEndOfNextDay() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let records = [1, 2].map { SessionRecord(endedAt: at($0, from: now), duration: 1500) }
        #expect(History.summarize(records, now: now, calendar: cal).streakDays == 2)
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
        #expect(events == [.segmentEnded(.focus, duration: 1500)])
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

@Suite struct QuickTimerTests {
    let t0 = Date(timeIntervalSince1970: 1_000)

    @Test func countsDownPausesAndResumes() {
        var timer = QuickTimer(label: "tea", duration: 300)
        timer.toggle(at: t0)
        #expect(timer.remaining(at: t0.addingTimeInterval(100)) == 200)
        timer.toggle(at: t0.addingTimeInterval(100))
        #expect(timer.remaining(at: t0.addingTimeInterval(500)) == 200)
        timer.toggle(at: t0.addingTimeInterval(500))
        #expect(timer.remaining(at: t0.addingTimeInterval(550)) == 150)
    }

    @Test func finishesOnceAndRestarts() {
        var timer = QuickTimer(label: "eggs", duration: 60)
        timer.toggle(at: t0)
        let early = timer.tick(at: t0.addingTimeInterval(59))
        let finishing = timer.tick(at: t0.addingTimeInterval(60))
        let after = timer.tick(at: t0.addingTimeInterval(61))
        #expect(!early)
        #expect(finishing)
        #expect(!after)
        #expect(timer.isDone)
        timer.toggle(at: t0.addingTimeInterval(70))
        #expect(timer.isRunning)
        #expect(timer.remaining(at: t0.addingTimeInterval(70)) == 60)
    }

    @Test func resetReturnsToIdle() {
        var timer = QuickTimer(label: "x", duration: 60)
        timer.toggle(at: t0)
        timer.reset()
        #expect(timer.state == .idle)
        #expect(timer.progress(at: t0) == 0)
    }
}

@Suite struct PersistenceTests {
    let t0 = Date(timeIntervalSince1970: 1_000)

    @Test func quickTimerSurvivesEncoding() throws {
        var timer = QuickTimer(label: "tea", duration: 300)
        timer.toggle(at: t0)
        let decoded = try JSONDecoder().decode(QuickTimer.self, from: JSONEncoder().encode(timer))
        #expect(decoded == timer)
    }

    @Test func templatesRankByUseThenRecency() {
        var templates = TimerTemplates()
        templates.record(name: "Water", duration: 3600, at: t0)
        templates.record(name: "water", duration: 3600, at: t0.addingTimeInterval(10))
        templates.record(name: "Stretch", duration: 120, at: t0.addingTimeInterval(20))
        let names = templates.top(3).map(\.name)
        #expect(names == ["Water", "Stretch", "Focus"])
        #expect(templates.items.filter { $0.id.hasPrefix("water") }.count == 1)
    }

    @Test func seedsAreRemovable() {
        var templates = TimerTemplates()
        templates.remove(id: TimerTemplates.seeds[0].id)
        #expect(templates.items.count == TimerTemplates.seeds.count - 1)
    }

    @Test func engineRestoresMidSegmentAndAdvancesWhenExpired() {
        let a = PomodoroEngine(preset: .classic, clock: { Date(timeIntervalSince1970: 1_000) })
        a.start()
        let saved = a.snapshot()

        let b = PomodoroEngine(preset: .classic, clock: { Date(timeIntervalSince1970: 1_100) })
        b.restore(saved)
        #expect(b.isRunning)
        #expect(b.remaining(at: Date(timeIntervalSince1970: 1_100)) == 1_400)

        let c = PomodoroEngine(preset: .classic, clock: { Date(timeIntervalSince1970: 9_000) })
        c.restore(saved)
        #expect(c.isIdle)
        #expect(c.phase == .shortBreak)
    }
}
