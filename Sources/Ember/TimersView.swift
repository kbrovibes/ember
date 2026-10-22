import SwiftUI
import EmberCore

/// Timers tab of the main window: one big text line, quick-start chips, and a grid that shrinks cards to fit, never scrolls.
struct TimersPane: View {
    @Environment(AppModel.self) private var model
    @State private var text = ""
    @State private var invalid = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 26) {
            entry
                .frame(maxWidth: 560)
            QuickStartRow(limit: 5)

            if model.timers.isEmpty {
                VStack(spacing: 6) {
                    Text("Nothing running").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink2)
                    Text("Type a name and a time, like “water 2m”.").font(.system(size: 12)).foregroundStyle(Theme.ink3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TimerGrid(timers: model.timers)
            }
        }
        .onAppear { focused = true }
    }

    private var entry: some View {
        let parsed = InputParser.parseNamed(text)
        return VStack(alignment: .leading, spacing: 10) {
            TextField("", text: $text, prompt: Text("water 2m").foregroundStyle(Theme.ink3.opacity(0.6)))
                .textFieldStyle(.plain)
                .focused($focused)
                .focusEffectDisabled()
                .font(.system(size: 34, weight: .ultraLight))
                .foregroundStyle(Theme.ink)
                .onSubmit(add)
                .onChange(of: text) { invalid = false }

            Rectangle()
                .fill(invalid ? Theme.accent(.focus) : (focused ? Theme.accent(.focus) : Theme.line2))
                .frame(height: focused || invalid ? 2 : 1)
                .animation(Theme.spring, value: focused)

            Text(hint(parsed))
                .font(.system(size: 12))
                .foregroundStyle(invalid ? Theme.accent(.focus) : Theme.ink3)
                .contentTransition(.interpolate)
                .animation(Theme.spring, value: hint(parsed))
        }
    }

    private func hint(_ parsed: NamedTimer?) -> String {
        if invalid { return "Add a time, like 2m, 20min or 1h30m" }
        guard let parsed else { return "Name and time, then Return · “focus 20min”, “eggs 90s”, “tea 1h30m”" }
        let name = parsed.name.isEmpty ? "Timer" : parsed.name
        return "\(name) · \(TimeFormat.spoken(parsed.duration)) — press Return to start"
    }

    private func add() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if model.addTimer(text: trimmed) { text = "" } else { invalid = true }
    }
}

/// Picks the column count that lets every card show at the largest scale, so the area never needs to scroll.
private struct TimerGrid: View {
    let timers: [QuickTimer]
    private let gap: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let fit = best(count: timers.count, in: geo.size)
            let cell = CGSize(width: TimerCard.size.width * fit.scale, height: TimerCard.size.height * fit.scale)
            VStack(alignment: .leading, spacing: gap) {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(Theme.spring, value: timers.map(\.id))
        }
    }

    private func best(count: Int, in size: CGSize) -> (columns: Int, scale: CGFloat) {
        var best = (columns: 1, scale: CGFloat(0))
        for columns in 1...max(1, count) {
            let rows = (count + columns - 1) / columns
            let w = (size.width - gap * CGFloat(columns - 1)) / CGFloat(columns) / TimerCard.size.width
            let h = (size.height - gap * CGFloat(rows - 1)) / CGFloat(rows) / TimerCard.size.height
            let scale = min(w, h, 1)
            if scale > best.scale { best = (columns, scale) }
        }
        return (best.columns, max(best.scale, 0.2))
    }
}

struct TimerCard: View {
    static let size = CGSize(width: 220, height: 176)
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let timer: QuickTimer

    var body: some View {
        let remaining = timer.remaining(at: model.now)
        let clock = TimeFormat.clock(remaining)
        let tint = timer.isDone ? Theme.accent(.shortBreak) : Theme.accent(.focus)
        let ringing = model.ringing.contains(timer.id)

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: ringing ? "bell.fill" : (timer.isDone ? "checkmark.circle.fill" : "timer"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                    .symbolEffect(.bounce, options: .repeating, isActive: ringing)
                TextField("Name", text: Binding(get: { timer.label }, set: { model.renameTimer(timer.id, to: $0) }))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(1)
                if timer.isDone {
                    Text("Done").font(.system(size: 11, weight: .medium)).foregroundStyle(tint)
                }
                Spacer()
                Button { model.removeTimer(timer.id) } label: {
                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.ink3)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PressStyle())
                .help("Remove")
            }

            Text(clock)
                .font(.system(size: 40, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                .animation(reduceMotion ? nil : Theme.spring, value: clock)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityLabel("\(timer.label), \(TimeFormat.spoken(remaining)) remaining")

            ProgressTrack(progress: timer.progress(at: model.now), tint: tint)

            HStack(spacing: 10) {
                Button { ringing ? model.dismissAlarm(timer.id) : model.toggleTimer(timer.id) } label: {
                    Image(systemName: ringing ? "checkmark" : (timer.isRunning ? "pause.fill" : "play.fill"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(tint))
                }
                .buttonStyle(PressStyle())
                .help(ringing ? "Dismiss alarm" : (timer.isRunning ? "Pause" : "Start"))
                Button { model.resetTimer(timer.id) } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.ink2)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.surface))
                        .overlay(Circle().strokeBorder(Theme.line))
                }
                .buttonStyle(PressStyle())
                .help("Reset")
                if ringing { Text("Dismiss").font(.system(size: 12, weight: .semibold)).foregroundStyle(tint) }
                Spacer()
            }
        }
        .padding(16)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(RoundedRectangle(cornerRadius: 16).fill(ringing ? tint.opacity(0.12) : Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(ringing ? tint : (timer.isRunning ? tint.opacity(0.45) : Theme.line), lineWidth: ringing ? 2 : 1))
        .animation(Theme.colorShift, value: timer.isRunning)
        .animation(Theme.colorShift, value: ringing)
    }
}

private struct ProgressTrack: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface2)
                Capsule().fill(tint).frame(width: max(4, geo.size.width * progress))
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}
