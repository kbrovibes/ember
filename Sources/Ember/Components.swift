import SwiftUI
import EmberCore

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Theme.spring, value: configuration.isPressed)
    }
}

struct RollingTime: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var size: CGFloat
    var weight: Font.Weight = .light

    var body: some View {
        Text(model.clockText)
            .font(.system(size: size, weight: weight))
            .monospacedDigit()
            .foregroundStyle(Theme.ink)
            .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
            .animation(reduceMotion ? nil : Theme.spring, value: model.clockText)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .accessibilityLabel("Time remaining \(TimeFormat.spoken(model.remaining))")
    }
}

struct PhaseChip: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let phase = model.engine.phase
        HStack(spacing: 6) {
            Image(systemName: phase.symbol).font(.system(size: 11, weight: .semibold))
            Text(phase.label).font(.system(size: 12, weight: .semibold))
            Text("· \(model.engine.round) of \(model.engine.preset.rounds)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.ink3)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(Theme.accent(phase))
        .background(Capsule().fill(Theme.soft(phase)))
        .animation(Theme.colorShift, value: phase)
        .contentTransition(.interpolate)
    }
}

struct Controls: View {
    @Environment(AppModel.self) private var model
    var size: CGFloat = 56

    var body: some View {
        let phase = model.engine.phase
        HStack(spacing: 18) {
            ghost("arrow.counterclockwise", help: "Reset") { model.reset() }
                .disabled(model.engine.isIdle)

            Button { model.toggle() } label: {
                Image(systemName: model.engine.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: size, height: size)
                    .background(Circle().fill(Theme.accent(phase)))
                    .shadow(color: Theme.accent(phase).opacity(0.28), radius: 10, y: 4)
            }
            .buttonStyle(PressStyle())
            .keyboardShortcut(.space, modifiers: [])
            .help(model.engine.isRunning ? "Pause (Space)" : "Start (Space)")
            .animation(Theme.colorShift, value: phase)

            ghost("forward.end.fill", help: "Skip") { model.skip() }
        }
    }

    private func ghost(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.ink2)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.surface))
                .overlay(Circle().strokeBorder(Theme.line, lineWidth: 1))
        }
        .buttonStyle(PressStyle())
        .help(help)
    }
}

struct CycleStrip: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let engine = model.engine
        HStack(spacing: 5) {
            ForEach(Array(engine.segments.enumerated()), id: \.offset) { i, seg in
                let fraction: Double = i < engine.index ? 1 : (i == engine.index ? model.progress : 0)
                let width: CGFloat = seg.phase == .focus ? 30 : (seg.phase == .shortBreak ? 14 : 22)
                Capsule()
                    .fill(Theme.soft(seg.phase))
                    .frame(width: width, height: seg.phase == .focus ? 8 : 5)
                    .overlay(alignment: .leading) {
                        Capsule().fill(Theme.accent(seg.phase)).frame(width: width * fraction)
                    }
                    .overlay {
                        if i == engine.index {
                            Capsule().strokeBorder(Theme.accent(seg.phase).opacity(0.5), lineWidth: 1).padding(-2.5)
                        }
                    }
            }
        }
        .animation(Theme.spring, value: engine.index)
        .accessibilityElement()
        .accessibilityLabel("Round \(engine.round) of \(engine.preset.rounds)")
    }
}

struct PresetMenu: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Menu {
            ForEach(model.presets) { preset in
                Button {
                    model.select(preset)
                } label: {
                    let mark = preset.id == model.engine.preset.id ? "✓ " : ""
                    Text("\(mark)\(preset.name) · \(Int(preset.focus / 60))/\(Int(preset.shortBreak / 60))")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(model.engine.preset.name).font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(Theme.ink2)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

struct TimerTape: View {
    @Environment(AppModel.self) private var model
    var height: CGFloat = 54

    var body: some View {
        let phase = model.engine.phase
        TapeRuler(
            minutes: model.engine.isIdle ? model.engine.segment.duration / 60 : model.remaining / 60,
            range: phase.minuteRange,
            accent: Theme.accent(phase),
            interactive: model.engine.isIdle,
            height: height,
            onSet: { model.setMinutes($0) }
        )
    }
}
