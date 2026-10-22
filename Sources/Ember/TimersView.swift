import SwiftUI
import EmberCore

/// The whole app: one text line, quick-start chips, and a grid that rescales to fill the window without scrolling.
struct TimersPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        GeometryReader { outer in
            VStack(alignment: .leading, spacing: 26) {
                TimerEntry(fontSize: min(max(outer.size.width * 0.055, 44), 88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                QuickStartRow(limit: 5)

                if model.timers.isEmpty {
                    VStack(spacing: 6) {
                        Text("Nothing running").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink2)
                        Text("Type a name and a time, like “focus 20min”, or tap one above.").font(.system(size: 12)).foregroundStyle(Theme.ink3)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TimerGrid(timers: model.sortedTimers)
                }
            }
            .frame(width: outer.size.width, height: outer.size.height)
        }
    }
}

/// Cards are placed by position, not nested stacks, so when the column count changes they glide to their new slots
/// instead of being rebuilt. While a window is dragged smoothly the scale just tracks the edge; the spring only
/// kicks in when the arrangement itself changes (columns, or a timer added or removed).
private struct TimerGrid: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let timers: [QuickTimer]
    private let gap: CGFloat = 14

    private struct Arrangement: Equatable {
        var columns: Int
        var ids: [QuickTimer.ID]
    }

    var body: some View {
        GeometryReader { geo in
            let count = timers.count
            let fit = best(count: count, in: geo.size)
            let cell = CGSize(width: TimerCard.size.width * fit.scale, height: TimerCard.size.height * fit.scale)
            let rows = (count + fit.columns - 1) / fit.columns
            let total = CGSize(width: CGFloat(fit.columns) * cell.width + CGFloat(fit.columns - 1) * gap,
                               height: CGFloat(rows) * cell.height + CGFloat(rows - 1) * gap)
            let origin = CGPoint(x: (geo.size.width - total.width) / 2, y: (geo.size.height - total.height) / 2)

            ZStack(alignment: .topLeading) {
                ForEach(Array(timers.enumerated()), id: \.element.id) { index, timer in
                    let row = index / fit.columns
                    let inRow = min(fit.columns, count - row * fit.columns)
                    let indent = CGFloat(fit.columns - inRow) * (cell.width + gap) / 2
                    TimerCard(timer: timer, scale: fit.scale)
                        .frame(width: cell.width, height: cell.height)
                        .position(x: origin.x + indent + CGFloat(index % fit.columns) * (cell.width + gap) + cell.width / 2,
                                  y: origin.y + CGFloat(row) * (cell.height + gap) + cell.height / 2)
                        .transition(.scale(scale: 0.88).combined(with: .opacity))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .animation(reduceMotion ? nil : Theme.layout, value: Arrangement(columns: fit.columns, ids: timers.map(\.id)))
        }
    }

    /// The column count that lets every card show at the largest scale.
    private func best(count: Int, in size: CGSize) -> (columns: Int, scale: CGFloat) {
        var best = (columns: 1, scale: CGFloat(0))
        for columns in 1...max(1, count) {
            let rows = (count + columns - 1) / columns
            let w = (size.width - gap * CGFloat(columns - 1)) / CGFloat(columns) / TimerCard.size.width
            let h = (size.height - gap * CGFloat(rows - 1)) / CGFloat(rows) / TimerCard.size.height
            let scale = min(w, h, 3.5)
            if scale > best.scale + 0.0001 { best = (columns, scale) }
        }
        return (best.columns, max(best.scale, 0.2))
    }
}

/// Sized by `scale` through layout (every metric is multiplied), not by scaling a rendered layer, so it stays sharp at
/// any size. Conforming to `Animatable` makes SwiftUI re-run `body` for each interpolated scale, so reflows stay crisp too.
struct TimerCard: View, Animatable {
    static let size = CGSize(width: 224, height: 214)
    @Environment(AppModel.self) private var model
    let timer: QuickTimer
    var scale: CGFloat = 1

    var animatableData: CGFloat {
        get { scale }
        set { scale = newValue }
    }

    var body: some View {
        let k = scale
        let remaining = timer.remaining(at: model.now)
        let ringing = model.ringing.contains(timer.id)
        let tint = timer.isDone ? Theme.done : Theme.accent

        VStack(spacing: 12 * k) {
            HStack(spacing: 6 * k) {
                Image(systemName: ringing ? "bell.fill" : "timer")
                    .font(.system(size: 11 * k, weight: .semibold))
                    .foregroundStyle(tint)
                    .symbolEffect(.bounce, options: .repeating, isActive: ringing)
                TextField("Name", text: Binding(get: { timer.label }, set: { model.renameTimer(timer.id, to: $0) }))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12 * k, weight: .semibold))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(1)
                if !timer.isDone {
                    Button { model.removeTimer(timer.id) } label: {
                        Image(systemName: "xmark").font(.system(size: 9 * k, weight: .bold)).foregroundStyle(Theme.ink3)
                            .frame(width: 20 * k, height: 20 * k)
                    }
                    .buttonStyle(PressStyle())
                    .help("Remove")
                }
            }

            TimerFace(theme: model.prefs.timerTheme, remaining: remaining, duration: timer.duration, tint: tint, running: timer.isRunning, k: k)

            HStack(spacing: 10 * k) {
                if timer.isDone {
                    round("checkmark", tint: tint, filled: true, help: "Done") { model.removeTimer(timer.id) }
                    round("arrow.counterclockwise", tint: tint, filled: false, help: "Restart") { model.toggleTimer(timer.id) }
                } else {
                    round(timer.isRunning ? "pause.fill" : "play.fill", tint: tint, filled: true, help: timer.isRunning ? "Pause" : "Start") { model.toggleTimer(timer.id) }
                    round("arrow.counterclockwise", tint: tint, filled: false, help: "Reset") { model.resetTimer(timer.id) }
                }
            }
        }
        .padding(16 * k)
        .frame(width: Self.size.width * k, height: Self.size.height * k)
        .background(RoundedRectangle(cornerRadius: 16 * k).fill(ringing ? tint.opacity(0.12) : Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16 * k).strokeBorder(ringing ? tint : (timer.isRunning ? tint.opacity(0.45) : Theme.line), lineWidth: ringing ? max(2, 2 * k) : max(1, k)))
        .animation(Theme.colorShift, value: timer.isRunning)
        .animation(Theme.colorShift, value: ringing)
    }

    private func round(_ symbol: String, tint: Color, filled: Bool, help: String, action: @escaping () -> Void) -> some View {
        let k = scale
        return Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12 * k, weight: .semibold))
                .foregroundStyle(filled ? Theme.onAccent : Theme.ink2)
                .frame(width: 34 * k, height: 34 * k)
                .background(Circle().fill(filled ? tint : Theme.surface))
                .overlay(Circle().strokeBorder(filled ? .clear : Theme.line, lineWidth: max(1, k)))
        }
        .buttonStyle(PressStyle())
        .help(help)
    }
}
