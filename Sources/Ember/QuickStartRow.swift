import SwiftUI
import EmberCore

/// One-tap chips for the timers used most. Each tap starts a new timer.
struct QuickStartRow: View {
    @Environment(AppModel.self) private var model
    var limit = 4
    var onStart: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(model.templates.top(limit)) { template in
                Chip(template: template) {
                    model.startTemplate(template)
                    onStart?()
                }
                .contextMenu { Button("Remove from quick timers") { model.removeTemplate(template) } }
            }
        }
        .animation(Theme.spring, value: model.templates.top(limit).map(\.id))
    }
}

private struct Chip: View {
    let template: TimerTemplate
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(hovering ? Theme.onAccent : Theme.accent)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(hovering ? Theme.accent : Theme.soft))
                Text(template.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .frame(maxWidth: 110)
                Text(TimeFormat.spoken(template.duration))
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink3)
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .frame(height: 34)
            .background(Capsule().fill(hovering ? Theme.soft : Theme.surface))
            .overlay(Capsule().strokeBorder(hovering ? Theme.accent.opacity(0.4) : Theme.line))
            .shadow(color: .black.opacity(hovering ? 0.08 : 0.03), radius: hovering ? 8 : 2, y: hovering ? 3 : 1)
            .fixedSize()
        }
        .buttonStyle(PressStyle())
        .onHover { over in withAnimation(Theme.spring) { hovering = over } }
        .help("Start \(template.name) · \(TimeFormat.spoken(template.duration))")
    }
}
