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

        shot("main-empty", size: window) { MainView() }
        shot("popover-empty", size: popover) { PopoverView() }

        for spec in ["focus 20min", "water 1h", "tea 5m", "eggs 90s"] { model.addTimer(text: spec) }
        shot("main-timers", size: window) { MainView() }
        shot("main-timers-dark", size: window, dark: true) { MainView() }
        shot("popover-timers", size: popover) { PopoverView() }

        for spec in ["lunch 12m", "stretch 3m", "email 15m", "call 45m", "read 30m", "walk 20m", "tidy 10m"] { model.addTimer(text: spec) }
        shot("main-many", size: window) { MainView() }

        shot("stats", size: CGSize(width: 640, height: 470)) { StatsView() }
        shot("settings", size: CGSize(width: 460, height: 520)) { SettingsView() }
        exit(0)
    }
}
