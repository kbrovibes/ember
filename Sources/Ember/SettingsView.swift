import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            Section("Appearance") {
                Picker("Mode", selection: $prefs.appearance) {
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                    Text("System").tag("system")
                }
                .pickerStyle(.segmented)
                LabeledContent("Accent") {
                    HStack(spacing: 10) {
                        ForEach(AccentTheme.allCases) { theme in
                            swatch(theme, selected: prefs.accent == theme) { prefs.accent = theme }
                        }
                    }
                }
            }

            Section("Timer") {
                Toggle("Start next phase automatically", isOn: $prefs.autoStartNext)
                Toggle("Show countdown in menu bar", isOn: $prefs.menuBarShowsTime)
                Toggle("Launch at login", isOn: Binding(get: { loginEnabled }, set: setLaunchAtLogin))
                if let loginError {
                    Text(loginError).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Sound") {
                Toggle("Play sounds", isOn: $prefs.soundEnabled)
                Group {
                    soundPicker("Focus ends", selection: $prefs.focusEndSound, volume: prefs.soundVolume)
                    soundPicker("Break ends", selection: $prefs.breakEndSound, volume: prefs.soundVolume)
                    soundPicker("Timer done", selection: $prefs.timerSound, volume: prefs.soundVolume)
                    LabeledContent("Volume") {
                        Slider(value: $prefs.soundVolume, in: 0.1...1) { editing in
                            if !editing { Alerts.play(prefs.timerSound, volume: prefs.soundVolume) }
                        }
                        .frame(width: 160)
                    }
                }
                .disabled(!prefs.soundEnabled)
            }

            Section("Notifications") {
                Toggle("Show notifications", isOn: $prefs.notificationsEnabled)
            }

            Section("Data") {
                LabeledContent("History, timers and scenarios") {
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([model.dataFolder])
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 620)
    }

    private func swatch(_ theme: AccentTheme, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(theme.accent)
                .frame(width: 20, height: 20)
                .overlay { if selected { Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.onAccent) } }
                .padding(3)
                .overlay(Circle().strokeBorder(selected ? theme.accent : .clear, lineWidth: 1.5))
        }
        .buttonStyle(PressStyle())
        .help(theme.name)
        .accessibilityLabel("\(theme.name) accent")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func soundPicker(_ title: String, selection: Binding<String>, volume: Double) -> some View {
        Picker(title, selection: selection) {
            ForEach(Prefs.sounds, id: \.self) { Text($0).tag($0) }
        }
        .onChange(of: selection.wrappedValue) { _, name in Alerts.play(name, volume: volume) }
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
