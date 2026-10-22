import SwiftUI
import EmberCore

/// The whole app: one text line, quick-start chips, and a grid that rescales to fill the window without scrolling.
struct TimersPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        GeometryReader { outer in
            if model.zen {
                TimerGrid(timers: model.sortedTimers)
                    .frame(width: outer.size.width, height: outer.size.height)
            } else {
            VStack(alignment: .leading, spacing: 26) {
                TimerEntry(fontSize: min(max(outer.size.width * 0.055, 44), 88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .center, spacing: 24) {
                    QuickStartRow(limit: min(5, max(2, Int((outer.size.width - 300) / 150))))
                    Spacer(minLength: 0)
                    if model.timers.count > 1 {
                        SortBar().transition(.opacity)
                    }
                }
                .animation(Theme.spring, value: model.timers.count > 1)

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
}

/// Cards are placed by position, not nested stacks, so when the column count changes they glide to their new slots
/// instead of being rebuilt. While a window is dragged smoothly the scale just tracks the edge; the spring only
/// kicks in when the arrangement itself changes (columns, or a timer added or removed).
private struct TimerGrid: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppModel.self) private var model
    let timers: [QuickTimer]
    private let gap: CGFloat = 14

    private struct Arrangement: Equatable {
        var columns: Int
        var ids: [QuickTimer.ID]
        var zen: Bool
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
            .animation(reduceMotion ? nil : Theme.layout, value: Arrangement(columns: fit.columns, ids: timers.map(\.id), zen: model.zen))
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
    static let size = CGSize(width: 216, height: 208)
    @Environment(AppModel.self) private var model
    let timer: QuickTimer
    var scale: CGFloat = 1

    var animatableData: CGFloat {
        get { scale }
        set { scale = newValue }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A soft lub-dub every 1.5s, 0...1, so finished timers are easy to spot at a glance.
    private static func heartbeat(_ t: Double) -> Double {
        let phase = t.truncatingRemainder(dividingBy: 1.5)
        func bump(_ centre: Double) -> Double { exp(-pow((phase - centre) / 0.07, 2)) }
        return min(1, bump(0.15) + 0.65 * bump(0.45))
    }

    var body: some View {
        if timer.isDone {
            TimelineView(.animation) { tl in
                let p = reduceMotion ? 0.5 : Self.heartbeat(tl.date.timeIntervalSinceReferenceDate)
                card(k: scale * (reduceMotion ? 1 : 1 + 0.03 * p), glow: p)
            }
        } else {
            card(k: scale, glow: 0)
        }
    }

    @ViewBuilder
    private func card(k: CGFloat, glow: Double) -> some View {
        let remaining = timer.remaining(at: model.now)
        let ringing = model.ringing.contains(timer.id)
        let tint = timer.isDone ? Theme.done : Theme.accent
        let bare = model.zen && !timer.isDone
        let done = timer.isDone
        let fill: Color = done ? tint.opacity(0.06 + 0.10 * glow) : Theme.surface
        let idleBorder: Color = timer.isRunning ? tint.opacity(0.45) : Theme.line
        let border: Color = done ? tint.opacity(0.55 + 0.45 * glow) : idleBorder
        let borderWidth: CGFloat = done ? max(2, 2 * k) : max(1, k)
        let glowColor: Color = done ? tint.opacity(0.10 + 0.30 * glow) : .clear

        VStack(spacing: 8 * k) {
            if bare {
                Spacer(minLength: 0)
                HStack(spacing: 8 * k) {
                    glyph(k: k)
                    Text(timer.label)
                        .font(.system(size: 14 * k, weight: .semibold))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
            } else {
            HStack(spacing: 6 * k) {
                if model.prefs.glyphStyle == .off {
                    Image(systemName: ringing ? "bell.fill" : "timer")
                        .font(.system(size: 11 * k, weight: .semibold))
                        .foregroundStyle(tint)
                        .symbolEffect(.bounce, options: .repeating, isActive: ringing)
                } else {
                    glyph(k: k)
                }
                if SnapshotTool.active {
                    Text(timer.label).font(.system(size: 13 * k, weight: .semibold)).foregroundStyle(Theme.ink2).lineLimit(1)
                    Spacer(minLength: 0)
                } else {
                    TextField("Name", text: Binding(get: { timer.label }, set: { model.renameTimer(timer.id, to: $0) }))
                        .textFieldStyle(.plain)
                        .font(.system(size: 13 * k, weight: .semibold))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                if !timer.isDone {
                    Button { model.removeTimer(timer.id) } label: {
                        Image(systemName: "xmark").font(.system(size: 9 * k, weight: .bold)).foregroundStyle(Theme.ink3)
                            .frame(width: 20 * k, height: 20 * k)
                    }
                    .buttonStyle(PressStyle())
                    .help("Remove")
                }
            }
            }

            TimerFace(theme: model.prefs.timerTheme, remaining: remaining, duration: timer.duration, tint: tint, running: timer.isRunning, k: k)

            if bare {
                Spacer(minLength: 0)
            } else {
            HStack(spacing: 10 * k) {
                if timer.isDone {
                    round(k, "checkmark", tint: tint, filled: true, help: "Done") { model.removeTimer(timer.id) }
                    round(k, "arrow.counterclockwise", tint: tint, filled: false, help: "Restart") { model.toggleTimer(timer.id) }
                } else {
                    round(k, timer.isRunning ? "pause.fill" : "play.fill", tint: tint, filled: true, help: timer.isRunning ? "Pause" : "Start") { model.toggleTimer(timer.id) }
                    round(k, "arrow.counterclockwise", tint: tint, filled: false, help: "Reset") { model.resetTimer(timer.id) }
                }
            }
            }
        }
                .padding(12 * k)
        .frame(width: Self.size.width * k, height: Self.size.height * k)
        .background(RoundedRectangle(cornerRadius: 14 * k).fill(fill))
        .overlay(RoundedRectangle(cornerRadius: 14 * k).strokeBorder(border, lineWidth: borderWidth))
        .shadow(color: glowColor, radius: (4 + 14 * glow) * k)
        .animation(Theme.colorShift, value: timer.isRunning)
        .animation(Theme.colorShift, value: ringing)
    }

    @ViewBuilder
    private func glyph(k: CGFloat) -> some View {
        if model.prefs.glyphStyle != .off {
            TimerGlyph(style: model.prefs.glyphStyle, name: timer.label, size: 24 * k, running: timer.isRunning, done: timer.isDone)
        }
    }

    private func round(_ k: CGFloat, _ symbol: String, tint: Color, filled: Bool, help: String, action: @escaping () -> Void) -> some View {
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
