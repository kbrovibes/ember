import SwiftUI
import EmberCore

struct MainView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let phase = model.engine.phase
        ZStack {
            Theme.bg
            Theme.soft(phase).opacity(0.45)

            VStack(spacing: 28) {
                HStack {
                    PhaseChip()
                    Spacer()
                    Button { openWindow(id: "focus") } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.ink2)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(PressStyle())
                    .help("Focus mode")
                    PresetMenu()
                }

                Spacer(minLength: 0)

                RollingTime(size: 112, weight: .ultraLight)
                    .frame(maxWidth: .infinity)

                TimerTape(height: 64)
                    .frame(maxWidth: 520)

                Controls(size: 64)

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
            .padding(32)
        }
        .animation(Theme.colorShift, value: phase)
        .frame(minWidth: 640, minHeight: 420)
        .ignoresSafeArea()
    }

    private func stat(title: String, value: String, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.ink3)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink)
        }
        .frame(width: 120, alignment: trailing ? .trailing : .leading)
    }
}
