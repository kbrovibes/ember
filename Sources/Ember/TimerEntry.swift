import SwiftUI
import EmberCore

/// The big borderless text line: type a name and a time ("water 2m"), press Return.
struct TimerEntry: View {
    @Environment(AppModel.self) private var model
    var fontSize: CGFloat = 34
    @State private var text = ""
    @State private var invalid = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if SnapshotTool.active {
                Text("water 2m").font(.system(size: fontSize, weight: .ultraLight)).foregroundStyle(Theme.ink3.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TextField("", text: $text, prompt: Text("water 2m").foregroundStyle(Theme.ink3.opacity(0.6)))
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .focusEffectDisabled()
                    .font(.system(size: fontSize, weight: .ultraLight))
                    .foregroundStyle(Theme.ink)
                    .onSubmit(add)
                    .onChange(of: text) { invalid = false }
            }

            Rectangle()
                .fill(invalid || focused ? Theme.accent : Theme.line2)
                .frame(height: focused || invalid ? 2 : 1)
                .animation(Theme.spring, value: focused)
        }
        .onAppear { focused = true }
    }

    private func add() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if model.addTimer(text: trimmed) { text = "" } else { invalid = true }
    }
}
