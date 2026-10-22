import SwiftUI
import EmberCore

/// The five directions from design/mocks.html, each drawing the same timer differently.
enum TimerTheme: String, CaseIterable, Identifiable {
    case halo, mono, tide, cinder, tape

    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}

/// Natural size of a face; cards and settings previews scale it.
enum FaceMetrics {
    static let size = CGSize(width: 192, height: 104)
}

struct TimerFace: View {
    let theme: TimerTheme
    let remaining: TimeInterval
    let duration: TimeInterval
    let tint: Color
    var running = false

    private var left: Double { duration > 0 ? min(1, max(0, remaining / duration)) : 0 }
    private var clock: String { TimeFormat.clock(remaining) }
    /// Hour-long times need to fit inside the ring and the vessel.
    private var dialTextSize: CGFloat { clock.count > 5 ? 15 : 22 }

    var body: some View {
        Group {
            switch theme {
            case .halo: halo
            case .mono: mono
            case .tide: tide
            case .cinder: cinder
            case .tape: tape
            }
        }
        .frame(width: FaceMetrics.size.width, height: FaceMetrics.size.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(TimeFormat.spoken(remaining)) remaining")
    }

    // MARK: Halo — ring dial, knob rides the leading edge of what remains

    private var halo: some View {
        let d = FaceMetrics.size.height
        return ZStack {
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let r = min(size.width, size.height) / 2
                for i in 0..<60 {
                    let a = Double(i) / 60 * 2 * .pi
                    let major = i % 5 == 0
                    let r1 = r * (major ? 0.9 : 0.94), r2 = r * 0.985
                    var p = Path()
                    p.move(to: CGPoint(x: c.x + r1 * sin(a), y: c.y - r1 * cos(a)))
                    p.addLine(to: CGPoint(x: c.x + r2 * sin(a), y: c.y - r2 * cos(a)))
                    ctx.stroke(p, with: .color(Theme.line2), lineWidth: major ? 1.3 : 0.8)
                }
            }
            Circle().stroke(Theme.surface2, lineWidth: 5).padding(14)
            Circle().trim(from: 0, to: left)
                .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(14)
            Circle().fill(Theme.surface).overlay(Circle().strokeBorder(tint, lineWidth: 2.5))
                .frame(width: 13, height: 13)
                .offset(y: -(d / 2 - 14))
                .rotationEffect(.degrees(left * 360))
            TimeText(clock: clock, size: dialTextSize, weight: .light)
        }
        .frame(width: d, height: d)
    }

    // MARK: Mono — the numerals are the interface, one hairline underneath

    private var mono: some View {
        VStack(spacing: 12) {
            TimeText(clock: clock, size: 46, weight: .ultraLight)
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.line2).frame(height: 1)
                Rectangle().fill(tint).frame(width: FaceMetrics.size.width * (1 - left), height: 2)
            }
        }
    }

    // MARK: Tide — a pill that drains

    private var tide: some View {
        VStack(alignment: .leading, spacing: 14) {
            TimeText(clock: clock, size: 32, weight: .light)
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface2)
                Capsule().fill(LinearGradient(colors: [tint.opacity(0.78), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(16, FaceMetrics.size.width * left))
            }
            .frame(height: 16)
        }
    }

    // MARK: Cinder — a vessel of liquid that settles

    private var cinder: some View {
        let d = FaceMetrics.size.height
        return TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !running)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let wave = WaveShape(level: left, phase: t * 1.8, amplitude: running ? 2.4 : 0)
            ZStack {
                if running { Circle().fill(tint.opacity(0.22)).blur(radius: 14).scaleEffect(1.08) }
                Circle().fill(Theme.surface)
                wave.fill(LinearGradient(colors: [tint.opacity(0.82), tint], startPoint: .top, endPoint: .bottom))
                    .clipShape(Circle())
                if running { sparks(t: t, diameter: d) }
                Circle().strokeBorder(Theme.line2, lineWidth: 1)
                TimeText(clock: clock, size: dialTextSize, weight: .light)
                TimeText(clock: clock, size: dialTextSize, weight: .light, color: Theme.onAccent).mask(wave)
            }
            .frame(width: d - 6, height: d - 6)
        }
        .frame(width: d, height: d)
    }

    private func sparks(t: Double, diameter: CGFloat) -> some View {
        let seeds: [(x: Double, speed: Double, offset: Double, r: Double)] = [(0.28, 0.21, 0.0, 2.6), (0.45, 0.17, 0.4, 1.8), (0.6, 0.24, 0.7, 2.2), (0.73, 0.19, 0.2, 1.6), (0.37, 0.15, 0.85, 1.4)]
        let h = Double(diameter - 6)
        return ZStack {
            ForEach(Array(seeds.enumerated()), id: \.offset) { _, s in
                let u = (t * s.speed + s.offset).truncatingRemainder(dividingBy: 1)
                Circle().fill(Theme.onAccent.opacity(0.7 * (1 - u)))
                    .frame(width: s.r * 2, height: s.r * 2)
                    .position(x: h * s.x, y: h - h * left * u)
            }
        }
        .frame(width: h, height: h)
        .clipShape(Circle())
        .opacity(left > 0.05 ? 1 : 0)
    }

    // MARK: Tape — a ruler slides under a fixed needle; the elapsed part is drawn in

    private var tape: some View {
        VStack(spacing: 14) {
            TimeText(clock: clock, size: 32, weight: .light)
            TapeStrip(remaining: remaining, duration: duration, tint: tint)
                .frame(width: FaceMetrics.size.width, height: 44)
        }
    }
}

private struct TimeText: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let clock: String
    let size: CGFloat
    let weight: Font.Weight
    var color: Color = Theme.ink

    var body: some View {
        Text(clock)
            .font(.system(size: size, weight: weight))
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
            .animation(reduceMotion ? nil : Theme.spring, value: clock)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

private struct WaveShape: Shape {
    var level: Double
    var phase: Double
    var amplitude: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard level > 0 else { return p }
        let top = rect.height * (1 - level)
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: top))
        for x in stride(from: 0.0, through: rect.width, by: 3) {
            p.addLine(to: CGPoint(x: x, y: top + amplitude * sin(x / rect.width * 2 * .pi * 1.6 + phase)))
        }
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.closeSubpath()
        return p
    }
}

private struct TapeStrip: View {
    let remaining: TimeInterval
    let duration: TimeInterval
    let tint: Color

    var body: some View {
        Canvas { ctx, size in
            let unit = duration > 5400 ? 5.0 : 1.0
            let pt: CGFloat = 10
            let value = remaining / 60 / unit
            let maxTick = Int((duration / 60 / unit).rounded(.up))
            let cx = size.width / 2
            func x(_ t: Double) -> CGFloat { cx + CGFloat(t - value) * pt }

            let bar = CGRect(x: max(0, x(0)), y: 21, width: max(0, cx - max(0, x(0))), height: 3)
            ctx.fill(Path(roundedRect: bar, cornerRadius: 1.5), with: .color(tint))

            let first = max(0, Int(floor(value - cx / pt)))
            let last = min(maxTick, Int(ceil(value + cx / pt)))
            if first <= last {
                for t in first...last {
                    let major = t % 5 == 0
                    var p = Path()
                    p.move(to: CGPoint(x: x(Double(t)), y: major ? 6 : 12))
                    p.addLine(to: CGPoint(x: x(Double(t)), y: 22))
                    ctx.stroke(p, with: .color(major ? Theme.ink3 : Theme.line2), lineWidth: major ? 1.2 : 0.8)
                    if major {
                        ctx.draw(Text("\(Int(Double(t) * unit))").font(.system(size: 9, weight: .medium)).foregroundColor(Theme.ink3),
                                 at: CGPoint(x: x(Double(t)), y: 34))
                    }
                }
            }

            var needle = Path()
            needle.move(to: CGPoint(x: cx - 5, y: 0)); needle.addLine(to: CGPoint(x: cx + 5, y: 0)); needle.addLine(to: CGPoint(x: cx, y: 8)); needle.closeSubpath()
            needle.move(to: CGPoint(x: cx, y: 8)); needle.addLine(to: CGPoint(x: cx, y: 28))
            ctx.fill(needle, with: .color(tint))
            ctx.stroke(Path { $0.move(to: CGPoint(x: cx, y: 8)); $0.addLine(to: CGPoint(x: cx, y: 28)) }, with: .color(tint), lineWidth: 1.5)
        }
        .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.14), .init(color: .black, location: 0.86), .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))
    }
}
