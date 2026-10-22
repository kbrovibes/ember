import AppKit
import Foundation
import Observation
import EmberCore

@Observable
@MainActor
final class AppModel {
    let prefs: Prefs
    private(set) var records: [SessionRecord]
    private(set) var timers: [QuickTimer]
    private(set) var templates: TimerTemplates
    /// Timers that have finished and are still alarming; they ring on repeat until dismissed.
    private(set) var ringing: Set<QuickTimer.ID> = []
    /// Refreshed ~10x/s while a timer runs; views read this instead of polling the clock.
    private(set) var now = Date()
    @ObservationIgnored private let store: HistoryStore
    @ObservationIgnored private let stateStore: StateStore
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var alarm: Timer?
    @ObservationIgnored private let dock = DockProgress()

    init(prefs: Prefs = Prefs(), store: HistoryStore = HistoryStore(), stateStore: StateStore = StateStore()) {
        self.prefs = prefs
        self.store = store
        self.stateStore = stateStore
        records = store.load()
        prefs.applyAppearance()

        let saved = stateStore.load()
        templates = saved.templates
        let launch = Date()
        timers = saved.timers.map { var t = $0; t.tick(at: launch); return t }

        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.timers.contains(where: \.isRunning) else { return }
                self.tickTimers()
                self.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer

        refresh()
        Alerts.requestAuthorization()
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.persist() }
        }
    }

    var summary: HistorySummary { History.summarize(records) }
    var dataFolder: URL { stateStore.url.deletingLastPathComponent() }

    /// The running timer that finishes first; drives the menu-bar countdown and Dock progress.
    var soonest: QuickTimer? {
        timers.filter(\.isRunning).min { $0.remaining(at: now) < $1.remaining(at: now) }
    }

    // MARK: timers

    /// Timers in the user's chosen order. Ties keep the order they were added in.
    var sortedTimers: [QuickTimer] {
        let ascending = prefs.sortAscending
        let indexed = Array(timers.enumerated())
        let ordered: [(offset: Int, element: QuickTimer)]
        switch prefs.sort {
        case .added: ordered = indexed
        case .name: ordered = indexed.sorted { order($0.element.label.localizedStandardCompare($1.element.label), $0.offset, $1.offset) }
        case .remaining: ordered = indexed.sorted { order(compare($0.element.remaining(at: now), $1.element.remaining(at: now)), $0.offset, $1.offset) }
        case .total: ordered = indexed.sorted { order(compare($0.element.duration, $1.element.duration), $0.offset, $1.offset) }
        }
        return (ascending ? ordered : ordered.reversed()).map(\.element)
    }

    /// Picking the active sort again flips its direction.
    func chooseSort(_ sort: TimerSort) {
        if prefs.sort == sort { prefs.sortAscending.toggle() } else { prefs.sort = sort; prefs.sortAscending = true }
    }

    private func compare(_ a: Double, _ b: Double) -> ComparisonResult { a < b ? .orderedAscending : (a > b ? .orderedDescending : .orderedSame) }
    private func order(_ result: ComparisonResult, _ i: Int, _ j: Int) -> Bool { result == .orderedSame ? i < j : result == .orderedAscending }

    /// Free-form entry such as `water 2m` or `focus 20min`. Returns false if no duration can be found.
    @discardableResult
    func addTimer(text: String) -> Bool {
        guard let parsed = InputParser.parseNamed(text) else { return false }
        addTimer(name: parsed.name, duration: parsed.duration)
        return true
    }

    /// Named timers are remembered, so the ones used most show up as quick-start chips next launch.
    func addTimer(name: String, duration: TimeInterval) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        var timer = QuickTimer(label: trimmed.isEmpty ? TimeFormat.spoken(duration) : trimmed, duration: duration)
        timer.toggle(at: Date())
        timers.append(timer)
        if !trimmed.isEmpty { templates.record(name: trimmed, duration: duration, at: Date()) }
        commit()
    }

    func startTemplate(_ template: TimerTemplate) { addTimer(name: template.name, duration: template.duration) }
    func removeTemplate(_ template: TimerTemplate) { templates.remove(id: template.id); commit() }
    func renameTimer(_ id: QuickTimer.ID, to label: String) { mutateTimer(id) { $0.label = label } }

    func toggleTimer(_ id: QuickTimer.ID) { dismissAlarm(id); mutateTimer(id) { $0.toggle(at: Date()) } }
    func resetTimer(_ id: QuickTimer.ID) { dismissAlarm(id); mutateTimer(id) { $0.reset() } }
    func removeTimer(_ id: QuickTimer.ID) { dismissAlarm(id); timers.removeAll { $0.id == id }; commit() }

    func dismissAlarm(_ id: QuickTimer.ID) {
        guard ringing.remove(id) != nil else { return }
        if ringing.isEmpty { alarm?.invalidate(); alarm = nil }
    }

    // MARK: internals

    private func mutateTimer(_ id: QuickTimer.ID, _ change: (inout QuickTimer) -> Void) {
        guard let i = timers.firstIndex(where: { $0.id == id }) else { return }
        change(&timers[i])
        commit()
    }

    private func tickTimers() {
        let date = Date()
        for i in timers.indices where timers[i].tick(at: date) {
            records.append(SessionRecord(endedAt: date, duration: timers[i].duration, tag: timers[i].label))
            store.save(records)
            Alerts.timerDone(timers[i].label, prefs: prefs)
            startAlarm(for: timers[i].id)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.requestUserAttention(.criticalRequest)
        }
        persist()
    }

    private func startAlarm(for id: QuickTimer.ID) {
        ringing.insert(id)
        guard alarm == nil else { return }
        let timer = Timer(timeInterval: 2.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.prefs.soundEnabled else { return }
                Alerts.play(self.prefs.timerSound, volume: self.prefs.soundVolume)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        alarm = timer
        if prefs.soundEnabled { Alerts.play(prefs.timerSound, volume: prefs.soundVolume) }
    }

    private func commit() {
        refresh()
        persist()
    }

    private func persist() {
        stateStore.save(AppState(timers: timers, templates: templates))
    }

    private func refresh() {
        now = Date()
        dock.update(progress: soonest?.progress(at: now))
    }
}
