import AppKit
import SwiftUI
import EmberCore

/// Ember lives in the menu bar: closing the window never quits; Quit is explicit (Dock menu, menu bar, ⌘Q).
final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor static var openMain: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("Ember keeps timers running")
        ProcessInfo.processInfo.disableSuddenTermination()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @MainActor
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        if let window = sender.windows.first(where: { $0.title == "Ember" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            AppDelegate.openMain?()
        }
        sender.activate(ignoringOtherApps: true)
        return false
    }
}

@main
struct EmberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model = AppModel()

    init() {
        MainActor.assumeIsolated { SnapshotTool.runIfRequested() }
    }

    var body: some Scene {
        Window("Ember", id: "main") {
            MainView().environment(model)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 840, height: 540)

        MenuBarExtra {
            PopoverView().environment(model)
        } label: {
            MenuBarLabel().environment(model)
        }
        .menuBarExtraStyle(.window)

        Window("Scenarios", id: "scenarios") {
            ScenarioEditorView().environment(model)
        }
        .defaultSize(width: 760, height: 480)

        Window("Stats", id: "stats") {
            StatsView().environment(model)
        }
        .defaultSize(width: 640, height: 470)

        Window("Focus", id: "focus") {
            FocusView().environment(model)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView().environment(model)
        }
    }
}
