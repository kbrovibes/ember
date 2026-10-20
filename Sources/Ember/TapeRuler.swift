import AppKit
import SwiftUI

/// Draws the ruler centred on `value` (minutes). Animatable so a spring release glides.
private struct TapeCanvas: View, Animatable {
    var value: Double
    var ppm: CGFloat

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Canvas { ctx, size in
            let mid = size.width / 2
            let span = Int(ceil(size.width / 2 / ppm)) + 2
            let center = Int(value.rounded())
            for m in (center - span)...(center + span) where m >= 0 {
                let x = mid + (CGFloat(m) - CGFloat(value)) * ppm
                let isTen = m % 10 == 0
                let isFive = m % 5 == 0
                let h: CGFloat = isTen ? 24 : isFive ? 16 : 9

                var tick = Path()
                tick.move(to: CGPoint(x: x, y: 6))
                tick.addLine(to: CGPoint(x: x, y: 6 + h))
                ctx.stroke(tick, with: .color(isFive ? Theme.ink3 : Theme.line2), style: StrokeStyle(lineWidth: isTen ? 1.5 : 1, lineCap: .round))

                if isTen {
                    let label = Text("\(m)").font(.system(size: 10, weight: .medium)).monospacedDigit().foregroundStyle(Theme.ink3)
                    ctx.draw(label, at: CGPoint(x: x, y: 6 + h + 4), anchor: .top)
                }
            }
        }
    }
}

/// Drag-to-set ruler. Idle: drag sideways to set the duration (10pt = 1 min). Running: shows remaining time, read-only.
struct TapeRuler: View {
    var minutes: Double
    var range: ClosedRange<Double>
    var accent: Color
    var interactive: Bool
    var height: CGFloat = 54
    var onSet: (Double) -> Void

    @State private var live = 0.0
    @State private var base: Double?
    @State private var dragging = false
    @State private var lastDetent = 0
    @State private var settle: Task<Void, Never>?

    private let ppm: CGFloat = 10

    var body: some View {
        TapeCanvas(value: dragging ? live : minutes, ppm: ppm)
            .frame(height: height)
            .overlay(alignment: .top) { indicator }
            .mask(fade)
            .contentShape(Rectangle())
            .gesture(drag, including: interactive ? .all : .subviews)
            .onHover { inside in
                guard interactive else { return }
                if inside { NSCursor.openHand.push() } else { NSCursor.pop() }
            }
            .accessibilityElement()
            .accessibilityLabel("Duration")
            .accessibilityValue("\(Int(minutes)) minutes")
            .accessibilityAdjustableAction { direction in
                guard interactive else { return }
                onSet(clamp(minutes + (direction == .increment ? 1 : -1)))
            }
    }

    private var indicator: some View {
        VStack(spacing: 0) {
            Circle().fill(accent).frame(width: 7, height: 7)
            Capsule().fill(accent).frame(width: 2.5, height: 34)
        }
        .offset(y: -3)
        .animation(Theme.colorShift, value: accent)
    }

    private var fade: some View {
        LinearGradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.2),
            .init(color: .black, location: 0.8),
            .init(color: .clear, location: 1),
        ], startPoint: .leading, endPoint: .trailing)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { g in
                if base == nil {
                    settle?.cancel()
                    base = minutes
                    live = minutes
                    dragging = true
                    lastDetent = Int((minutes / 5).rounded(.down))
                    NSCursor.closedHand.set()
                }
                live = clamp(base! - Double(g.translation.width / ppm))
                let detent = Int((live / 5).rounded(.down))
                if detent != lastDetent {
                    lastDetent = detent
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                }
                onSet(live.rounded())
            }
            .onEnded { g in
                guard let start = base else { return }
                let projected = g.translation.width + (g.predictedEndTranslation.width - g.translation.width) * 0.3
                let target = clamp(start - Double(projected / ppm)).rounded()
                base = nil
                withAnimation(Theme.spring) { live = target }
                onSet(target)
                NSCursor.openHand.set()
                settle = Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    if !Task.isCancelled { dragging = false }
                }
            }
    }

    private func clamp(_ v: Double) -> Double { min(max(v, range.lowerBound), range.upperBound) }
}
