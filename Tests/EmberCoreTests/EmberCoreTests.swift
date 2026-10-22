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
}

@Suite struct NamedParserTests {
    @Test(arguments: [
        ("water 2m", "Water", 120.0),
        ("focus 20min", "Focus", 1200.0),
        ("20 min focus", "Focus", 1200.0),
        ("Tea 1h30m", "Tea", 5400.0),
        ("laundry for 1 hour 30 minutes", "Laundry", 5400.0),
        ("eggs 90s", "Eggs", 90.0),
        ("focus 20", "Focus", 1200.0),
        ("round 2 focus 20m", "Round 2 focus", 1200.0),
        ("5m #tea", "Tea", 300.0),
        ("10m", "", 600.0),
        ("stretch 1:30", "Stretch", 90.0),
    ])
    func extractsNameAndDuration(input: String, name: String, seconds: Double) {
        #expect(InputParser.parseNamed(input) == NamedTimer(name: name, duration: seconds))
    }

    @Test func rejectsTextWithoutDuration() {
        #expect(InputParser.parseNamed("water") == nil)
        #expect(InputParser.parseNamed("0m") == nil)
        #expect(InputParser.parseNamed("") == nil)
    }
}
