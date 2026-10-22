import SwiftUI
import EmberCore

struct MainView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let zen = model.zen
        ZStack(alignment: .topTrailing) {
            Theme.bg
            VStack(spacing: zen ? 0 : 24) {
                if !zen { header }
                TimersPane()
            }
            .padding(zen ? 20 : 32)

            if zen { ZenExit() }
        }
        .onAppear { AppDelegate.openMain = { openWindow(id: "main") } }
        .frame(minWidth: 680, minHeight: 500)
        .ignoresSafeArea()
        .animation(Theme.layout, value: zen)
    }

    private var header: some View {
        HStack(spacing: 4) {
            if model.timers.count > 1 {
                SortBar().transition(.opacity)
            }
            Spacer()
            iconButton("arrow.up.left.and.arrow.down.right", help: "Distraction-free") { model.enterZen() }
                .disabled(model.timers.isEmpty)
            iconButton("chart.bar", help: "Stats") { openWindow(id: "stats") }
            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.ink2)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PressStyle())
            .help("Settings (⌘,)")
        }
        .animation(Theme.spring, value: model.timers.count > 1)
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
}

/// The only chrome left in distraction-free mode: faint until the pointer is near it. Esc also exits.
private struct ZenExit: View {
    @Environment(AppModel.self) private var model
    @State private var hovering = false

    var body: some View {
        Button { model.exitZen() } label: {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.ink2)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.surface.opacity(hovering ? 1 : 0)))
        }
        .buttonStyle(PressStyle())
        .keyboardShortcut(.cancelAction)
        .opacity(hovering ? 1 : 0.28)
        .onHover { over in withAnimation(Theme.spring) { hovering = over } }
        .padding(14)
        .help("Exit distraction-free (Esc)")
    }
}
