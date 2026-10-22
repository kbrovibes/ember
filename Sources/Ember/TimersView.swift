import SwiftUI
import EmberCore

/// Independent countdowns shown as a grid; the Pomodoro cycle lives in the main window.
struct TimersView: View {
    @Environment(AppModel.self) private var model
    @State private var name = ""
    @State private var duration = ""
    @State private var invalid = false

    private let columns = [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 14)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Timers").font(.system(size: 22, weight: .semibold))

            HStack(spacing: 10) {
                field("Name (optional)", text: $name, width: nil)
                field("20m, 1h30m, 90s", text: $duration, width: 130, invalid: invalid)
                    .onChange(of: duration) { invalid = false }
                Button(action: add) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.accent(.focus)))
                }
                .buttonStyle(PressStyle())
                .help("Add timer")
            }

            HStack(spacing: 10) {
                Text("Quick start").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.ink3)
                QuickStartRow(limit: 5)
            }

            if model.timers.isEmpty {
                VStack(spacing: 6) {
                    Text("No timers running").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink2)
                    Text("Tap a quick timer, or name one and give it a duration. Add as many as you like.")
                        .font(.system(size: 12)).foregroundStyle(Theme.ink3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(model.timers) { timer in
                            TimerCard(timer: timer)
                                .transition(.scale(scale: 0.94).combined(with: .opacity))
                        }
                    }
                    .animation(Theme.spring, value: model.timers.map(\.id))
                }
            }
        }
        .padding(28)
        .frame(minWidth: 640, minHeight: 380, alignment: .topLeading)
        .background(Theme.bg)
    }

    private func field(_ prompt: String, text: Binding<String>, width: CGFloat?, invalid: Bool = false) -> some View {
        TextField(prompt, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .padding(.horizontal, 12)
            .frame(width: width, height: 32)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(invalid ? Theme.accent(.focus) : Theme.line))
            .onSubmit(add)
    }

    private func add() {
        let spec = duration.trimmingCharacters(in: .whitespaces)
        guard !spec.isEmpty else { invalid = true; return }
        if model.addTimer(text: spec, name: name) {
            name = ""
            duration = ""
        } else {
            invalid = true
        }
    }
}

struct TimerCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let timer: QuickTimer

    var body: some View {
        let remaining = timer.remaining(at: model.now)
        let clock = TimeFormat.clock(remaining)
        let tint = timer.isDone ? Theme.accent(.shortBreak) : Theme.accent(.focus)

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: timer.isDone ? "checkmark.circle.fill" : "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
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
                Button { model.toggleTimer(timer.id) } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(tint))
                }
                .buttonStyle(PressStyle())
                .help(timer.isRunning ? "Pause" : "Start")
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
                Spacer()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(timer.isRunning ? tint.opacity(0.45) : Theme.line))
        .animation(Theme.colorShift, value: timer.isRunning)
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
