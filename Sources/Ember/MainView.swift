import SwiftUI
import EmberCore

struct MainView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack {
            Theme.bg
            VStack(spacing: 24) {
                HStack(spacing: 4) {
                    Spacer()
                    Button { openWindow(id: "stats") } label: {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.ink2)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(PressStyle())
                    .help("Stats")
                    SettingsLink {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.ink2)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(PressStyle())
                    .help("Settings (⌘,)")
                }
                TimersPane()
            }
            .padding(32)
        }
        .onAppear { AppDelegate.openMain = { openWindow(id: "main") } }
        .frame(minWidth: 680, minHeight: 500)
        .ignoresSafeArea()
    }
}
