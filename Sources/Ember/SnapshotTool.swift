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
        let model = AppModel(prefs: Prefs(defaults: UserDefaults(suiteName: "ember.snapshot")!), store: HistoryStore(directory: scratch), presetStore: PresetStore(directory: scratch))
        model.prefs.appearance = "light"

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
            let rep = NSBitmapImageRep(cgImage: cg)
            try? rep.representation(using: .png, properties: [:])?.write(to: dir.appendingPathComponent("\(name).png"))
            print("wrote \(name).png")
        }

        let popover = CGSize(width: 320, height: 430)
        let window = CGSize(width: 840, height: 540)

        model.setMinutes(25)
        shot("popover-idle", size: popover) { PopoverView() }
        shot("main-idle", size: window) { MainView() }
        shot("main-idle-dark", size: window, dark: true) { MainView() }
        shot("scenarios", size: CGSize(width: 760, height: 480)) { ScenarioEditorView() }
        shot("stats", size: CGSize(width: 640, height: 470)) { StatsView() }
        shot("focus-idle", size: CGSize(width: 1280, height: 800)) { FocusView() }

        model.toggle()
        shot("popover-running", size: popover) { PopoverView() }
        shot("main-running", size: window) { MainView() }

        model.toggle()
        model.skip()
        shot("popover-break", size: popover) { PopoverView() }
        shot("main-break", size: window) { MainView() }
        shot("focus-break", size: CGSize(width: 1280, height: 800)) { FocusView() }

        exit(0)
    }
}
