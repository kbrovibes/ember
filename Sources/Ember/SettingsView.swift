import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

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
                Toggle("Launch at login", isOn: Binding(get: { loginEnabled }, set: setLaunchAtLogin))
                if let loginError {
                    Text(loginError).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Alerts") {
                Toggle("Play sound", isOn: $prefs.soundEnabled)
                Toggle("Show notifications", isOn: $prefs.notificationsEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 420)
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Couldn't change login item: \(error.localizedDescription)"
        }
        loginEnabled = SMAppService.mainApp.status == .enabled
    }
}
