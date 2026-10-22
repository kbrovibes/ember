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
            Section("Theme") {
                ThemePicker()
            }

            Section("Timer glyphs") {
                GlyphPicker()
            }

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

            Section("General") {
                Toggle("Go distraction-free after 10 minutes idle", isOn: $prefs.autoZen)
                Toggle("Show countdown in menu bar", isOn: $prefs.menuBarShowsTime)
                Toggle("Launch at login", isOn: Binding(get: { loginEnabled }, set: setLaunchAtLogin))
                if let loginError {
                    Text(loginError).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Sound") {
                Toggle("Play alarm", isOn: $prefs.soundEnabled)
                Group {
                    soundPicker("Alarm sound", selection: $prefs.timerSound, volume: prefs.soundVolume)
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
                LabeledContent("History and timers") {
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([model.dataFolder])
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 740)
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

/// Five live previews; picking one restyles every timer immediately.
struct ThemePicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimerTheme.allCases) { theme in
                let selected = model.prefs.timerTheme == theme
                Button { withAnimation(Theme.spring) { model.prefs.timerTheme = theme } } label: {
                    VStack(spacing: 6) {
                        TimerFace(theme: theme, remaining: 13 * 60, duration: 20 * 60, tint: Theme.accent, k: 0.36)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Theme.accent : Theme.line, lineWidth: selected ? 2 : 1))
                        Text(theme.name)
                            .font(.system(size: 11, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? Theme.ink : Theme.ink3)
                    }
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("\(theme.name) theme")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

/// Previews each glyph style on three sample names; picking one applies to every timer immediately.
struct GlyphPicker: View {
    @Environment(AppModel.self) private var model
    private let samples = ["Water", "Focus", "Tea"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(GlyphStyle.allCases) { style in
                let selected = model.prefs.glyphStyle == style
                Button { withAnimation(Theme.spring) { model.prefs.glyphStyle = style } } label: {
                    VStack(spacing: 6) {
                        Group {
                            if style == .off {
                                Text("None").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.ink3)
                            } else {
                                HStack(spacing: 4) {
                                    ForEach(samples, id: \.self) { TimerGlyph(style: style, name: $0, size: 18, running: style == .buddy) }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Theme.accent : Theme.line, lineWidth: selected ? 2 : 1))
                        Text(style.name)
                            .font(.system(size: 11, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? Theme.ink : Theme.ink3)
                    }
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("\(style.name) glyphs")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
