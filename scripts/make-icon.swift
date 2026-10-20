// Generates Resources/AppIcon.icns. Run: swift scripts/make-icon.swift
import AppKit

func render(size: Int) -> Data {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
    }

    // macOS icon grid: artwork occupies ~82% of the canvas.
    let inset = s * 0.09
    let body = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let squircle = NSBezierPath(roundedRect: body, xRadius: body.width * 0.2237, yRadius: body.width * 0.2237)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x000000, 0.18)
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.012)
    shadow.shadowBlurRadius = s * 0.03
    shadow.set()
    color(0xFFFFFF).setFill()
    squircle.fill()
    NSGraphicsContext.restoreGraphicsState()

    squircle.addClip()
    NSGradient(colors: [color(0xFFFFFF), color(0xFBEBE3)])!.draw(in: body, angle: -90)

    // Ember disc
    let d = body.width * 0.56
    let disc = NSRect(x: body.midX - d / 2, y: body.midY - d / 2 + s * 0.01, width: d, height: d)
    NSGraphicsContext.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = color(0xCC4317, 0.35)
    glow.shadowOffset = NSSize(width: 0, height: -s * 0.02)
    glow.shadowBlurRadius = s * 0.05
    glow.set()
    NSGradient(colors: [color(0xE8683A), color(0xC23F14)])!.draw(in: NSBezierPath(ovalIn: disc), angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // Progress ring: faint track plus a bright arc with a round cap, reads as "timer".
    let center = NSPoint(x: disc.midX, y: disc.midY)
    let radius = d * 0.31
    let lineWidth = d * 0.095
    let track = NSBezierPath()
    track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
    track.lineWidth = lineWidth
    color(0xFFFFFF, 0.28).setStroke()
    track.stroke()

    let arc = NSBezierPath()
    arc.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - 250, clockwise: true)
    arc.lineWidth = lineWidth
    arc.lineCapStyle = .round
    color(0xFFFFFF).setStroke()
    arc.stroke()

    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in variants {
    try render(size: px).write(to: iconset.appendingPathComponent("\(name).png"))
}
try fm.createDirectory(at: root.appendingPathComponent("Resources"), withIntermediateDirectories: true)
try render(size: 1024).write(to: root.appendingPathComponent("build/icon-preview.png"))
print("iconset ready: \(iconset.path)")
