import AppKit
import SwiftUI
import EmberCore

struct PopoverView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TimerEntry(fontSize: 24)

            QuickStartRow(limit: 2)

            if !model.timers.isEmpty {
                VStack(spacing: 10) {
                    ForEach(model.timers.prefix(5)) { TimerRow(timer: $0) }
                    if model.timers.count > 5 {
                        Text("+\(model.timers.count - 5) more in the main window").font(.system(size: 11)).foregroundStyle(Theme.ink3)
                    }
                }
            }

            Divider().overlay(Theme.line)

            HStack {
                Text(todayLine).font(.system(size: 11)).foregroundStyle(Theme.ink3)
                Spacer()
                footerButton("Open") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                footerButton("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(Theme.bg)
    }

    private var todayLine: String {
        let s = model.summary
        return s.todaySessions == 0 ? "Nothing finished today" : "Today · \(s.todaySessions) done · \(TimeFormat.spoken(s.todayFocus))"
    }

    private func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.ink2)
            .padding(.leading, 8)
    }
}

private struct TimerRow: View {
    @Environment(AppModel.self) private var model
    let timer: QuickTimer

    var body: some View {
        let tint = timer.isDone ? Theme.done : Theme.accent
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Text(timer.label).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.ink).lineLimit(1)
                Spacer()
                Text(TimeFormat.clock(timer.remaining(at: model.now)))
                    .font(.system(size: 13)).monospacedDigit().foregroundStyle(Theme.ink2)
                if timer.isDone {
                    rowButton("arrow.counterclockwise", tint: tint, filled: false) { model.toggleTimer(timer.id) }
                    rowButton("checkmark", tint: tint, filled: true) { model.removeTimer(timer.id) }
                } else {
                    rowButton(timer.isRunning ? "pause.fill" : "play.fill", tint: tint, filled: true) { model.toggleTimer(timer.id) }
                    Button { model.removeTimer(timer.id) } label: {
                        Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.ink3).frame(width: 18, height: 24)
                    }
                    .buttonStyle(PressStyle())
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surface2)
                    Capsule().fill(tint).frame(width: max(3, geo.size.width * timer.progress(at: model.now)))
                }
            }
            .frame(height: 3)
        }
    }
}

extension TimerRow {
    fileprivate func rowButton(_ symbol: String, tint: Color, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(filled ? Theme.onAccent : Theme.ink2)
                .frame(width: 24, height: 24)
                .background(Circle().fill(filled ? tint : Theme.surface))
                .overlay(Circle().strokeBorder(filled ? .clear : Theme.line))
        }
        .buttonStyle(PressStyle())
    }
}

struct MenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: model.ringing.isEmpty ? "flame.fill" : "bell.fill")
            if model.prefs.menuBarShowsTime, let next = model.soonest {
                Text(TimeFormat.clock(next.remaining(at: model.now))).monospacedDigit()
            }
        }
    }
}
