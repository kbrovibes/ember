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
        let model = AppModel(prefs: Prefs(defaults: UserDefaults(suiteName: "ember.snapshot")!), store: HistoryStore(directory: scratch))
        model.prefs.appearance = "light"

        func shot(_ name: String, size: CGSize, dark: Bool = false) {
            model.prefs.appearance = dark ? "dark" : "light"
            let view = Group {
                if size.width < 400 { PopoverView() } else { MainView() }
            }
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
        shot("popover-idle", size: popover)
        shot("main-idle", size: window)
        shot("main-idle-dark", size: window, dark: true)

        model.toggle()
        shot("popover-running", size: popover)
        shot("main-running", size: window)

        model.toggle()
        model.skip()
        shot("popover-break", size: popover)
        shot("main-break", size: window)

        exit(0)
    }
}
