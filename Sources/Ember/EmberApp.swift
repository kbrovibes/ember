import SwiftUI
import EmberCore

@main
struct EmberApp: App {
    @State private var model = AppModel()

    init() {
        MainActor.assumeIsolated { SnapshotTool.runIfRequested() }
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView().environment(model)
        } label: {
            MenuBarLabel().environment(model)
        }
        .menuBarExtraStyle(.window)

        Window("Ember", id: "main") {
            MainView().environment(model)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 840, height: 540)

        Window("Scenarios", id: "scenarios") {
            ScenarioEditorView().environment(model)
        }
        .defaultSize(width: 760, height: 480)

        Window("Focus", id: "focus") {
            FocusView().environment(model)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView().environment(model)
        }
    }
}
