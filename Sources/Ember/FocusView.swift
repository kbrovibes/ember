import AppKit
import SwiftUI
import EmberCore

struct WindowAccessor: NSViewRepresentable {
    var onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { if let window = view.window { onWindow(window) } }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}
}

/// Fullscreen focus mode: huge numerals; secondary controls fade to 0.22 after 2s without pointer movement while running.
struct FocusView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var dim = false
    @State private var fade: Task<Void, Never>?

    var body: some View {
        let phase = model.engine.phase
        let faded = dim && model.engine.isRunning
        ZStack {
            Theme.bg
            Theme.soft(phase).opacity(0.55)

            VStack(spacing: 44) {
                PhaseChip().opacity(faded ? 0.22 : 1)
                RollingTime(size: 240, weight: .ultraLight)
                TimerTape(height: 72).frame(maxWidth: 760).opacity(faded ? 0.22 : 1)
                Controls(size: 76).opacity(faded ? 0.22 : 1)
            }
            .padding(48)

            VStack {
                HStack {
                    Spacer()
                    Button { dismissWindow(id: "focus") } label: {
                        Label("Exit", systemImage: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.ink2)
                    }
                    .buttonStyle(.plain)
                    .help("Exit focus mode (Esc)")
                }
                Spacer()
            }
            .padding(24)
            .opacity(faded ? 0 : 1)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: faded)
        .animation(Theme.colorShift, value: phase)
        .background(WindowAccessor { window in
            if !window.styleMask.contains(.fullScreen) { window.toggleFullScreen(nil) }
        })
        .focusable()
        .focusEffectDisabled()
        .onExitCommand { dismissWindow(id: "focus") }
        .onContinuousHover { _ in wake() }
        .onAppear { wake() }
    }

    private func wake() {
        if dim { dim = false }
        fade?.cancel()
        fade = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { dim = true }
        }
    }
}
