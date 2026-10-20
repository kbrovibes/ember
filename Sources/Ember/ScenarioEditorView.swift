import SwiftUI
import EmberCore

struct ScenarioEditorView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedID: String?

    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 230)
            Divider()
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.bg)
        .frame(minWidth: 640, minHeight: 420)
        .onAppear { selectedID = selectedID ?? model.engine.preset.id }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selectedID) {
                Section("Built in") {
                    ForEach(Preset.builtIn) { row($0) }
                }
                Section("Yours") {
                    ForEach(model.customPresets) { row($0) }
                }
            }
            .scrollContentBackground(.hidden)

            Divider()
            Button {
                selectedID = model.addPreset().id
            } label: {
                Label("New scenario", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.ink2)
            .padding(12)
        }
        .background(Theme.surface2.opacity(0.6))
    }

    private func row(_ preset: Preset) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(preset.name).font(.system(size: 13, weight: .medium))
            Text(summary(preset)).font(.system(size: 11)).foregroundStyle(Theme.ink3)
        }
        .tag(preset.id)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var detail: some View {
        if let preset = model.presets.first(where: { $0.id == selectedID }) {
            let editable = !model.isBuiltIn(preset)
            VStack(alignment: .leading, spacing: 22) {
                if editable {
                    TextField("Name", text: bind(preset, \.name))
                        .textFieldStyle(.plain)
                        .font(.system(size: 22, weight: .semibold))
                } else {
                    Text(preset.name).font(.system(size: 22, weight: .semibold))
                }

                preview(preset)

                VStack(spacing: 0) {
                    stepperRow("Focus", phase: .focus, value: minutes(preset, \.focus), range: 1...90, editable: editable)
                    Divider().overlay(Theme.line)
                    stepperRow("Short break", phase: .shortBreak, value: minutes(preset, \.shortBreak), range: 1...30, editable: editable)
                    Divider().overlay(Theme.line)
                    stepperRow("Long break", phase: .longBreak, value: minutes(preset, \.longBreak), range: 5...60, editable: editable)
                    Divider().overlay(Theme.line)
                    roundsRow(preset, editable: editable)
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line))

                Text("Total \(TimeFormat.spoken(preset.segments.reduce(0) { $0 + $1.duration }))")
                    .font(.system(size: 12)).foregroundStyle(Theme.ink3)

                Spacer(minLength: 0)

                HStack {
                    if editable {
                        Button("Delete", role: .destructive) {
                            model.deletePreset(preset.id)
                            selectedID = model.engine.preset.id
                        }
                    } else {
                        Button("Duplicate to edit") { selectedID = model.addPreset(from: preset).id }
                    }
                    Spacer()
                    Button(model.engine.preset.id == preset.id ? "In use" : "Use this scenario") { model.select(preset) }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent(.focus))
                        .disabled(model.engine.preset.id == preset.id)
                }
            }
            .padding(28)
        } else {
            Text("Select a scenario").foregroundStyle(Theme.ink3)
        }
    }

    private func preview(_ preset: Preset) -> some View {
        let total = preset.segments.reduce(0) { $0 + $1.duration }
        return GeometryReader { geo in
            HStack(spacing: 3) {
                ForEach(Array(preset.segments.enumerated()), id: \.offset) { _, seg in
                    Capsule()
                        .fill(Theme.accent(seg.phase))
                        .frame(width: max(4, (geo.size.width - CGFloat(preset.segments.count) * 3) * seg.duration / total), height: seg.phase == .focus ? 10 : 6)
                        .opacity(seg.phase == .focus ? 1 : 0.55)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 12)
        .animation(Theme.spring, value: preset)
    }

    private func stepperRow(_ title: String, phase: Phase, value: Binding<Int>, range: ClosedRange<Int>, editable: Bool) -> some View {
        HStack {
            Image(systemName: phase.symbol).foregroundStyle(Theme.accent(phase)).frame(width: 20)
            Text(title).font(.system(size: 13))
            Spacer()
            Text("\(value.wrappedValue) min").font(.system(size: 13, weight: .medium)).monospacedDigit().foregroundStyle(Theme.ink2)
            Stepper("", value: value, in: range).labelsHidden().disabled(!editable)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private func roundsRow(_ preset: Preset, editable: Bool) -> some View {
        let rounds = Binding(get: { preset.rounds }, set: { var p = preset; p.rounds = $0; model.update(p) })
        return HStack {
            Image(systemName: "repeat").foregroundStyle(Theme.ink3).frame(width: 20)
            Text("Rounds before long break").font(.system(size: 13))
            Spacer()
            Text("\(rounds.wrappedValue)").font(.system(size: 13, weight: .medium)).monospacedDigit().foregroundStyle(Theme.ink2)
            Stepper("", value: rounds, in: 2...8).labelsHidden().disabled(!editable)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private func summary(_ p: Preset) -> String {
        "\(Int(p.focus / 60)) / \(Int(p.shortBreak / 60)) / \(Int(p.longBreak / 60)) · \(p.rounds) rounds"
    }

    private func bind(_ preset: Preset, _ key: WritableKeyPath<Preset, String>) -> Binding<String> {
        Binding(get: { preset[keyPath: key] }, set: { var p = preset; p[keyPath: key] = $0; model.update(p) })
    }

    private func minutes(_ preset: Preset, _ key: WritableKeyPath<Preset, TimeInterval>) -> Binding<Int> {
        Binding(get: { Int(preset[keyPath: key] / 60) }, set: { var p = preset; p[keyPath: key] = TimeInterval($0 * 60); model.update(p) })
    }
}
