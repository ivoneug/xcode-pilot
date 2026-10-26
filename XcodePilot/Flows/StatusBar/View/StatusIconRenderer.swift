// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import AppKit

/// Draws the menu bar icon. Neutral states are template images, so they follow the menu bar's
/// appearance; the result badges are colored and drawn over a glyph in the label color.
enum StatusIconRenderer {

    // MARK: - Internal methods
    /// - Parameter phase: Animation phase in `0..<1` for the spinning and pulsing states
    static func image(for state: StatusIconState, phase: Double) -> NSImage {
        let image = NSImage(size: Constants.size, flipped: false) { rect in
            draw(state, phase: phase, in: rect)
            return true
        }
        switch state {
        case .idle, .working, .running:
            image.isTemplate = true
        case .succeeded, .failed:
            image.isTemplate = false
        }
        return image
    }

    // MARK: - Private methods
    private static func draw(_ state: StatusIconState, phase: Double, in rect: NSRect) {
        switch state {
        case .idle:
            drawSymbol(Constants.idleSymbol, pointSize: Constants.largeSymbolSize, color: .black, in: rect)
        case .working(let work, let progress):
            drawSymbol(work.symbolName, pointSize: Constants.smallSymbolSize, color: .black, in: rect)
            drawRing(progress: progress, phase: phase, in: rect)
        case .running:
            drawSymbol(Constants.runningSymbol, pointSize: Constants.smallSymbolSize, color: .black, in: rect)
            drawPulse(phase: phase, in: rect)
        case .succeeded:
            drawSymbol(Constants.idleSymbol, pointSize: Constants.largeSymbolSize, color: .labelColor, in: rect)
            drawBadge(symbol: Constants.successBadgeSymbol, color: Colors.success.nsColor, in: rect)
        case .failed:
            drawSymbol(Constants.idleSymbol, pointSize: Constants.largeSymbolSize, color: .labelColor, in: rect)
            drawBadge(symbol: Constants.failureBadgeSymbol, color: Colors.failure.nsColor, in: rect)
        }
    }

    private static func drawSymbol(_ name: String, pointSize: CGFloat, color: NSColor, in rect: NSRect) {
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(configuration) else {
            return
        }
        let origin = NSPoint(x: rect.midX - symbol.size.width / 2, y: rect.midY - symbol.size.height / 2)
        symbol.draw(in: NSRect(origin: origin, size: symbol.size))
    }

    private static func drawRing(progress: Double?, phase: Double, in rect: NSRect) {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2 - Constants.ringWidth

        let track = NSBezierPath()
        track.appendArc(withCenter: center, radius: radius, startAngle: .zero, endAngle: Constants.fullCircle)
        track.lineWidth = Constants.ringWidth
        NSColor.black.withAlphaComponent(Constants.trackAlpha).setStroke()
        track.stroke()

        let arc = NSBezierPath()
        if let progress {
            // Clockwise from the top
            let end = Constants.topAngle - Constants.fullCircle * CGFloat(max(progress, Constants.minimalVisibleProgress))
            arc.appendArc(withCenter: center, radius: radius, startAngle: Constants.topAngle, endAngle: end, clockwise: true)
        } else {
            let start = Constants.topAngle - Constants.fullCircle * CGFloat(phase)
            arc.appendArc(withCenter: center, radius: radius, startAngle: start, endAngle: start - Constants.spinnerArc, clockwise: true)
        }
        arc.lineWidth = Constants.ringWidth
        arc.lineCapStyle = .round
        NSColor.black.setStroke()
        arc.stroke()
    }

    private static func drawPulse(phase: Double, in rect: NSRect) {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2 - Constants.ringWidth
        let ring = NSBezierPath()
        ring.appendArc(withCenter: center, radius: radius, startAngle: .zero, endAngle: Constants.fullCircle)
        ring.lineWidth = Constants.ringWidth
        // Breathes between half and full opacity
        let alpha = Constants.pulseMinimalAlpha + (1 - Constants.pulseMinimalAlpha) * (0.5 + 0.5 * sin(phase * 2 * .pi))
        NSColor.black.withAlphaComponent(alpha).setStroke()
        ring.stroke()
    }

    private static func drawBadge(symbol: String, color: NSColor, in rect: NSRect) {
        let diameter = Constants.badgeDiameter
        let badgeRect = NSRect(x: rect.maxX - diameter, y: rect.minY, width: diameter, height: diameter)

        // A gap around the badge keeps it apart from the glyph under it
        if let context = NSGraphicsContext.current {
            context.saveGraphicsState()
            context.compositingOperation = .destinationOut
            NSBezierPath(ovalIn: badgeRect.insetBy(dx: -Constants.badgeGap, dy: -Constants.badgeGap)).fill()
            context.restoreGraphicsState()
        }

        color.setFill()
        NSBezierPath(ovalIn: badgeRect).fill()
        drawSymbol(symbol, pointSize: Constants.badgeSymbolSize, color: .white, in: badgeRect)
    }

}

private enum Constants {
    static let size = NSSize(width: 18, height: 18)
    static let idleSymbol = "hammer.fill"
    static let runningSymbol = "play.fill"
    static let successBadgeSymbol = "checkmark"
    static let failureBadgeSymbol = "xmark"
    static let largeSymbolSize: CGFloat = 13
    static let smallSymbolSize: CGFloat = 8
    static let badgeSymbolSize: CGFloat = 5
    static let ringWidth: CGFloat = 1.6
    static let trackAlpha: CGFloat = 0.25
    static let fullCircle: CGFloat = 360
    static let topAngle: CGFloat = 90
    static let spinnerArc: CGFloat = 110
    static let minimalVisibleProgress = 0.03
    static let pulseMinimalAlpha: CGFloat = 0.35
    static let badgeDiameter: CGFloat = 9
    static let badgeGap: CGFloat = 1.2
}
