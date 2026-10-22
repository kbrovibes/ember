import AppKit
import SwiftUI
import EmberCore

/// `Ember --snapshot <dir>` renders key screens to PNGs and exits. Used for visual verification without Screen Recording permission.
@MainActor
enum SnapshotTool {
    static func runIfRequested() {
        let args = CommandLine.arguments
        guard let flag = args.firstIndex(of: "--snapshot"), args.indices.contains(flag + 1) else { return }
        let dir = URL(fileURLWithPath: args[flag + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let scratch = FileManager.default.temporaryDirectory.appendingPathComponent("ember-snapshot-\(UUID().uuidString)")
        let model = AppModel(prefs: Prefs(defaults: UserDefaults(suiteName: "ember.snapshot")!), store: HistoryStore(directory: scratch), stateStore: StateStore(directory: scratch))

        func shot<V: View>(_ name: String, size: CGSize, dark: Bool = false, @ViewBuilder _ content: () -> V) {
            model.prefs.appearance = dark ? "dark" : "light"
            let view = content()
                .environment(model)
                .environment(\.colorScheme, dark ? .dark : .light)
                .frame(width: size.width, height: size.height)
                .fixedSize()

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let cg = renderer.cgImage else { print("snapshot failed: \(name)"); return }
            try? NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])?.write(to: dir.appendingPathComponent("\(name).png"))
            print("wrote \(name).png")
        }

        let window = CGSize(width: 840, height: 540)
        let popover = CGSize(width: 320, height: 430)

        for spec in ["focus 20min", "water 1h", "tea 5m", "eggs 90s"] { model.addTimer(text: spec) }
        for theme in TimerTheme.allCases {
            model.prefs.timerTheme = theme
            shot("theme-\(theme.rawValue)", size: window) { MainView() }
        }
        model.prefs.timerTheme = .tape
        for spec in ["lunch 12m", "stretch 3m", "email 15m"] { model.addTimer(text: spec) }
        shot("main-seven", size: window) { MainView() }
        shot("main-seven-large", size: CGSize(width: 1600, height: 1000)) { MainView() }
        shot("main-large", size: CGSize(width: 1600, height: 1000)) { MainView() }
        shot("popover-timers", size: popover) { PopoverView() }
        shot("themepicker", size: CGSize(width: 440, height: 120)) { ThemePicker().padding(20).background(Theme.bg) }

        var finished = QuickTimer(label: "Tea", duration: 60)
        finished.toggle(at: Date(timeIntervalSinceNow: -120))
        finished.tick(at: Date())
        shot("card-done", size: CGSize(width: 260, height: 250)) { TimerCard(timer: finished).padding(18).background(Theme.bg) }
        shot("main-timers-dark", size: window, dark: true) { MainView() }
        shot("settings", size: CGSize(width: 480, height: 640)) { SettingsView() }
        exit(0)
    }
}
