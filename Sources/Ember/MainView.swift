import SwiftUI
import EmberCore

struct MainView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let phase = model.engine.phase
        let onPomodoro = model.mainTab == .pomodoro
        ZStack {
            Theme.bg
            Theme.soft(phase).opacity(onPomodoro ? 0.45 : 0)

            VStack(spacing: 24) {
                header(onPomodoro: onPomodoro)
                if onPomodoro { pomodoro } else { TimersPane() }
            }
            .padding(32)
        }
        .onAppear { AppDelegate.openMain = { openWindow(id: "main") } }
        .animation(Theme.colorShift, value: phase)
        .animation(Theme.colorShift, value: onPomodoro)
        .frame(minWidth: 680, minHeight: 500)
        .ignoresSafeArea()
    }

    private func header(onPomodoro: Bool) -> some View {
        HStack(spacing: 4) {
            tab("Pomodoro", .pomodoro)
            tab("Timers", .timers)
            Spacer()
            iconButton("arrow.up.left.and.arrow.down.right", help: "Focus mode") { openWindow(id: "focus") }
            iconButton("chart.bar", help: "Stats") { openWindow(id: "stats") }
            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.ink2)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PressStyle())
            .help("Settings (⌘,)")
            if onPomodoro { PresetMenu() }
        }
    }

    private var pomodoro: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            PhaseChip()
            RollingTime(size: 112, weight: .ultraLight)
                .frame(maxWidth: .infinity)
            TimerTape(height: 64)
                .frame(maxWidth: 520)
            Controls(size: 64)
            QuickStartRow(limit: 4)
            Spacer(minLength: 0)

            HStack {
                let s = model.summary
                stat(title: "Today", value: s.todaySessions == 0 ? "None yet" : "\(s.todaySessions) · \(TimeFormat.spoken(s.todayFocus))")
                Spacer()
                CycleStrip()
                Spacer()
                stat(title: "Streak", value: s.streakDays == 0 ? "—" : "\(s.streakDays) day\(s.streakDays == 1 ? "" : "s")", trailing: true)
            }
        }
    }

    private func tab(_ title: String, _ tab: MainTab) -> some View {
        let selected = model.mainTab == tab
        return Button { withAnimation(Theme.spring) { model.mainTab = tab } } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selected ? Theme.ink : Theme.ink3)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(Capsule().fill(selected ? Theme.surface : .clear))
                .overlay(Capsule().strokeBorder(selected ? Theme.line : .clear))
        }
        .buttonStyle(PressStyle())
    }

    private func iconButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.ink2)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(PressStyle())
        .help(help)
    }

    private func stat(title: String, value: String, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.ink3)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink)
        }
        .frame(width: 120, alignment: trailing ? .trailing : .leading)
    }
}
