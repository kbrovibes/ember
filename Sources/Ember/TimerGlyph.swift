import SwiftUI

/// Optional per-timer personality: the same name always gets the same look, so "Water" is recognisable at a glance.
enum GlyphStyle: String, CaseIterable, Identifiable {
    case off, symbol, monogram, pattern, buddy

    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}

struct TimerGlyph: View {
    let style: GlyphStyle
    let name: String
    var size: CGFloat = 26
    var running = false
    var done = false

    private var seed: UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for byte in name.lowercased().utf8 { h = (h ^ UInt64(byte)) &* 0x100000001b3 }
        return h
    }

    private static let palette: [Color] = ["E5603B", "D98A1D", "3E9B6B", "2C8FA6", "4F6FDB", "8B5CD6", "C94B9B", "6B7280"].map { Color(nsColor: NSColor(hex: $0)) }
    private var color: Color { Self.palette[Int(seed % UInt64(Self.palette.count))] }

    var body: some View {
        Group {
            switch style {
            case .off: EmptyView()
            case .symbol: symbol
            case .monogram: monogram
            case .pattern: pattern
            case .buddy: buddy
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    // MARK: Symbol — picked from the name, falls back to a stable random one

    private static let keywords: [(words: [String], symbol: String)] = [
        (["water", "drink", "hydrat"], "drop.fill"),
        (["focus", "work", "deep", "write", "code", "pomodoro"], "flame.fill"),
        (["tea", "coffee", "brew", "cup"], "cup.and.saucer.fill"),
        (["egg", "cook", "pasta", "oven", "lunch", "dinner", "food", "rice"], "fork.knife"),
        (["laundry", "wash", "dryer"], "washer.fill"),
        (["break", "rest", "nap", "sleep"], "moon.fill"),
        (["stretch", "walk", "run", "gym", "exercise", "workout", "yoga"], "figure.walk"),
        (["email", "mail", "inbox"], "envelope.fill"),
        (["call", "phone", "meeting", "standup"], "phone.fill"),
        (["read", "book", "study", "learn"], "book.fill"),
        (["music", "practice", "guitar", "piano"], "music.note"),
        (["meditat", "breath", "calm"], "leaf.fill"),
        (["tidy", "clean", "chore"], "sparkles"),
        (["walk the dog", "dog", "pet"], "pawprint.fill"),
    ]
    private static let fallbacks = ["star.fill", "bolt.fill", "leaf.fill", "sparkles", "moon.stars.fill", "sun.max.fill", "cloud.fill", "heart.fill", "hare.fill", "tortoise.fill", "atom", "scope"]

    private var symbolName: String {
        let lower = name.lowercased()
        if let hit = Self.keywords.first(where: { $0.words.contains { lower.contains($0) } }) { return hit.symbol }
        return Self.fallbacks[Int(seed % UInt64(Self.fallbacks.count))]
    }

    private var symbol: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(color.opacity(0.16))
            Image(systemName: symbolName)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    // MARK: Monogram

    private var monogram: some View {
        let letter = name.first(where: { $0.isLetter || $0.isNumber }).map { String($0).uppercased() } ?? "#"
        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(LinearGradient(colors: [color, color.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(letter).font(.system(size: size * 0.54, weight: .bold, design: .rounded)).foregroundStyle(.white)
        }
    }

    // MARK: Pattern — a small symmetric identicon

    private var pattern: some View {
        var bits = seed
        if bits.nonzeroBitCount < 12 { bits |= 0x2A5 }
        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(color.opacity(0.14))
            Canvas { ctx, canvas in
                let inset = canvas.width * 0.16
                let cell = (canvas.width - inset * 2) / 5
                for row in 0..<5 {
                    for col in 0..<3 where (bits >> UInt64(row * 3 + col)) & 1 == 1 {
                        for x in Set([col, 4 - col]) {
                            let r = CGRect(x: inset + CGFloat(x) * cell, y: inset + CGFloat(row) * cell, width: cell, height: cell).insetBy(dx: cell * 0.08, dy: cell * 0.08)
                            ctx.fill(Path(roundedRect: r, cornerRadius: cell * 0.3), with: .color(color))
                        }
                    }
                }
            }
        }
    }

    // MARK: Buddy — a little face that blinks, and beams when its timer is done

    private var buddy: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let period = 3.0 + Double(seed % 7) * 0.2
            let blink = ((t + Double(seed % 13)).truncatingRemainder(dividingBy: period)) < 0.13
            let bob = running ? sin(t * 3.2 + Double(seed % 5)) * size * 0.04 : 0
            Canvas { ctx, canvas in
                let w = canvas.width
                let body = CGRect(x: 0, y: 0, width: w, height: w).insetBy(dx: w * 0.04, dy: w * 0.04).offsetBy(dx: 0, dy: bob)
                let shape: Path
                switch seed % 4 {
                case 0: shape = Path(ellipseIn: body)
                case 1: shape = Path(roundedRect: body, cornerRadius: w * 0.34)
                case 2: shape = Path(roundedRect: body.insetBy(dx: w * 0.04, dy: w * 0.0), cornerRadius: w * 0.5)
                default: shape = Path(roundedRect: body, cornerRadius: w * 0.22)
                }
                ctx.fill(shape, with: .color(color))

                let eyeY = body.minY + w * 0.40
                let ink = Color.white
                for dx in [-0.17, 0.17] {
                    let cx = body.midX + w * dx
                    let eye = CGRect(x: cx - w * 0.055, y: eyeY - (blink ? w * 0.012 : w * 0.07), width: w * 0.11, height: blink ? w * 0.024 : w * 0.14)
                    ctx.fill(Path(ellipseIn: eye), with: .color(ink))
                }
                let mouthY = body.minY + w * 0.62
                var mouth = Path()
                if done {
                    mouth.addArc(center: CGPoint(x: body.midX, y: mouthY - w * 0.02), radius: w * 0.15, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    mouth.closeSubpath()
                    ctx.fill(mouth, with: .color(ink))
                    for dx in [-0.27, 0.27] {
                        ctx.fill(Path(ellipseIn: CGRect(x: body.midX + w * dx - w * 0.05, y: mouthY - w * 0.06, width: w * 0.1, height: w * 0.07)), with: .color(.white.opacity(0.35)))
                    }
                } else if running {
                    mouth.addArc(center: CGPoint(x: body.midX, y: mouthY - w * 0.03), radius: w * 0.1, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                    ctx.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.045, lineCap: .round))
                } else {
                    mouth.move(to: CGPoint(x: body.midX - w * 0.07, y: mouthY)); mouth.addLine(to: CGPoint(x: body.midX + w * 0.07, y: mouthY))
                    ctx.stroke(mouth, with: .color(ink.opacity(0.9)), style: StrokeStyle(lineWidth: w * 0.045, lineCap: .round))
                }
            }
        }
    }
}
