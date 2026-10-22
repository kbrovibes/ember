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
            HStack(spacing: 0) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: hovering ? 17 : 0, alignment: .leading)
                    .opacity(hovering ? 1 : 0)
                    .clipped()
                Text(template.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .frame(maxWidth: 110)
                Text(TimeFormat.spoken(template.duration))
                    .font(.system(size: 13, weight: .regular))
                    .monospacedDigit()
                    .opacity(0.55)
                    .padding(.leading, 7)
            }
            .foregroundStyle(hovering ? Theme.accent : Theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(hovering ? Theme.soft : Theme.surface2))
            .fixedSize()
        }
        .buttonStyle(PressStyle())
        .onHover { over in withAnimation(Theme.spring) { hovering = over } }
        .help("Start \(template.name) · \(TimeFormat.spoken(template.duration))")
    }
}
