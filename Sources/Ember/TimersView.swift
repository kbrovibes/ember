import SwiftUI
import EmberCore

/// The whole app: one text line, quick-start chips, and a grid that shrinks cards to fit instead of scrolling.
struct TimersPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 26) {
            TimerEntry()
                .frame(maxWidth: 560)
            QuickStartRow(limit: 5)

            if model.timers.isEmpty {
                VStack(spacing: 6) {
                    Text("Nothing running").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink2)
                    Text("Type a name and a time, like “focus 20min”, or tap one above.").font(.system(size: 12)).foregroundStyle(Theme.ink3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TimerGrid(timers: model.timers)
            }
        }
    }
}

/// Picks the column count that lets every card show at the largest scale, so the area never needs to scroll. Grows as well as shrinks with the window.
private struct TimerGrid: View {
    let timers: [QuickTimer]
    private let gap: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let fit = best(count: timers.count, in: geo.size)
            let cell = CGSize(width: TimerCard.size.width * fit.scale, height: TimerCard.size.height * fit.scale)
            VStack(alignment: .center, spacing: gap) {
                ForEach(Array(stride(from: 0, to: timers.count, by: fit.columns)), id: \.self) { start in
                    HStack(spacing: gap) {
                        ForEach(timers[start..<min(start + fit.columns, timers.count)]) { timer in
                            TimerCard(timer: timer)
                                .scaleEffect(fit.scale)
                                .frame(width: cell.width, height: cell.height)
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(Theme.spring, value: timers.map(\.id))
        }
    }

    private func best(count: Int, in size: CGSize) -> (columns: Int, scale: CGFloat) {
        var best = (columns: 1, scale: CGFloat(0))
        for columns in 1...max(1, count) {
            let rows = (count + columns - 1) / columns
            let w = (size.width - gap * CGFloat(columns - 1)) / CGFloat(columns) / TimerCard.size.width
            let h = (size.height - gap * CGFloat(rows - 1)) / CGFloat(rows) / TimerCard.size.height
            let scale = min(w, h, 3.5)
            if scale > best.scale { best = (columns, scale) }
        }
        return (best.columns, max(best.scale, 0.2))
    }
}

struct TimerCard: View {
    static let size = CGSize(width: 224, height: 214)
    @Environment(AppModel.self) private var model
    let timer: QuickTimer

    var body: some View {
        let remaining = timer.remaining(at: model.now)
        let ringing = model.ringing.contains(timer.id)
        let tint = timer.isDone ? Theme.done : Theme.accent

        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: ringing ? "bell.fill" : "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                    .symbolEffect(.bounce, options: .repeating, isActive: ringing)
                TextField("Name", text: Binding(get: { timer.label }, set: { model.renameTimer(timer.id, to: $0) }))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(1)
                if !timer.isDone {
                    Button { model.removeTimer(timer.id) } label: {
                        Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.ink3)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(PressStyle())
                    .help("Remove")
                }
            }

            TimerFace(theme: model.prefs.timerTheme, remaining: remaining, duration: timer.duration, tint: tint, running: timer.isRunning)

            HStack(spacing: 10) {
                if timer.isDone {
                    round("checkmark", tint: tint, filled: true, help: "Done") { model.removeTimer(timer.id) }
                    round("arrow.counterclockwise", tint: tint, filled: false, help: "Restart") { model.toggleTimer(timer.id) }
                } else {
                    round(timer.isRunning ? "pause.fill" : "play.fill", tint: tint, filled: true, help: timer.isRunning ? "Pause" : "Start") { model.toggleTimer(timer.id) }
                    round("arrow.counterclockwise", tint: tint, filled: false, help: "Reset") { model.resetTimer(timer.id) }
                }
            }
        }
        .padding(16)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(RoundedRectangle(cornerRadius: 16).fill(ringing ? tint.opacity(0.12) : Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(ringing ? tint : (timer.isRunning ? tint.opacity(0.45) : Theme.line), lineWidth: ringing ? 2 : 1))
        .animation(Theme.colorShift, value: timer.isRunning)
        .animation(Theme.colorShift, value: ringing)
    }

    private func round(_ symbol: String, tint: Color, filled: Bool, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(filled ? Theme.onAccent : Theme.ink2)
                .frame(width: 34, height: 34)
                .background(Circle().fill(filled ? tint : Theme.surface))
                .overlay(Circle().strokeBorder(filled ? .clear : Theme.line))
        }
        .buttonStyle(PressStyle())
        .help(help)
    }
}
