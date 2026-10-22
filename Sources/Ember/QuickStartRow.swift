import SwiftUI
import EmberCore

/// One-tap chips for the timers used most. Each tap starts a new timer.
struct QuickStartRow: View {
    @Environment(AppModel.self) private var model
    var limit = 4
    var onStart: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(model.templates.top(limit)) { template in
                Button {
                    model.startTemplate(template)
                    model.showTimers()
                    onStart?()
                } label: {
                    HStack(spacing: 6) {
                        Text(template.name).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink)
                            .lineLimit(1).frame(maxWidth: 96)
                        Text(TimeFormat.spoken(template.duration)).font(.system(size: 11)).foregroundStyle(Theme.ink3)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Capsule().fill(Theme.surface))
                    .overlay(Capsule().strokeBorder(Theme.line))
                    .fixedSize()
                }
                .buttonStyle(PressStyle())
                .help("Start \(template.name) · \(TimeFormat.spoken(template.duration))")
                .contextMenu { Button("Remove from quick timers") { model.removeTemplate(template) } }
            }
        }
        .animation(Theme.spring, value: model.templates.top(limit).map(\.id))
    }
}
