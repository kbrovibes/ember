import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            Picker("Appearance", selection: $prefs.appearance) {
                Text("Light").tag("light")
                Text("Dark").tag("dark")
                Text("System").tag("system")
            }
            .pickerStyle(.segmented)

            Section("Timer") {
                Toggle("Start next phase automatically", isOn: $prefs.autoStartNext)
                Toggle("Show countdown in menu bar", isOn: $prefs.menuBarShowsTime)
            }

            Section("Alerts") {
                Toggle("Play sound", isOn: $prefs.soundEnabled)
                Toggle("Show notifications", isOn: $prefs.notificationsEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 360)
    }
}
