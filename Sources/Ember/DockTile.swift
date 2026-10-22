import AppKit

/// Draws the app icon with a progress bar along the bottom, so the Dock shows how far along the timer is.
@MainActor
final class DockProgress {
    private let tileView = DockTileView()
    private var lastBucket = -1

    init() {
        let tile = NSApplication.shared.dockTile
        tileView.frame = NSRect(x: 0, y: 0, width: 128, height: 128)
        tile.contentView = tileView
        tile.display()
    }

    /// `progress` is nil when idle (no bar).
    func update(progress: Double?) {
        let bucket = progress.map { Int($0 * 200) } ?? -1
        guard bucket != lastBucket else { return }
        lastBucket = bucket
        tileView.progress = progress
        NSApplication.shared.dockTile.display()
    }
}

private final class DockTileView: NSView {
    var progress: Double?

    override func draw(_ dirtyRect: NSRect) {
        NSApplication.shared.applicationIconImage?.draw(in: bounds)
        guard let progress else { return }

        let inset = bounds.width * 0.14
        let track = NSRect(x: inset, y: bounds.height * 0.07, width: bounds.width - inset * 2, height: bounds.height * 0.085)
        NSColor.black.withAlphaComponent(0.28).setFill()
        NSBezierPath(roundedRect: track, xRadius: track.height / 2, yRadius: track.height / 2).fill()

        var fill = track
        fill.size.width = max(track.height, track.width * progress)
        let hex = Prefs.current?.accent.lightHex ?? "CC4317"
        NSColor(hex: hex).setFill()
        NSBezierPath(roundedRect: fill, xRadius: fill.height / 2, yRadius: fill.height / 2).fill()
    }
}
