import AppKit
import SwiftUI
import EmberCore

struct PopoverView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @State private var input = ""
    @State private var inputInvalid = false

    var body: some View {
        let phase = model.engine.phase
        VStack(spacing: 16) {
            HStack {
                PhaseChip()
                Spacer()
                PresetMenu()
            }

            RollingTime(size: 58)
                .frame(maxWidth: .infinity)

            TimerTape(height: 50)

            Controls(size: 52)

            CycleStrip()

            QuickStartRow(limit: 2) {
                openWindow(id: "timers")
                NSApp.activate(ignoringOtherApps: true)
            }

            quickInput

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
        .background(Theme.soft(phase).opacity(0.5))
        .animation(Theme.colorShift, value: phase)
    }

    private var quickInput: some View {
        TextField("25m · 1h30m · 5m/1m #tag", text: $input)
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(inputInvalid ? Theme.accent(.focus) : Theme.line, lineWidth: 1))
            .disabled(!model.engine.isIdle)
            .opacity(model.engine.isIdle ? 1 : 0.5)
            .onSubmit {
                if model.apply(text: input) {
                    input = ""
                    inputInvalid = false
                } else {
                    withAnimation(Theme.spring) { inputInvalid = true }
                }
            }
            .onChange(of: input) { inputInvalid = false }
    }

    private var todayLine: String {
        let s = model.summary
        return s.todaySessions == 0 ? "No sessions yet today" : "Today · \(s.todaySessions) · \(TimeFormat.spoken(s.todayFocus))"
    }

    private func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.ink2)
            .padding(.leading, 8)
    }
}

struct MenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: model.engine.phase.symbol)
            if model.prefs.menuBarShowsTime && !model.engine.isIdle {
                Text(model.clockText).monospacedDigit()
            }
        }
    }
}
