// Draws Resources/dmg-background.png: 1320×880 px at 144 dpi, shown as a 660×440 pt DMG window.
// Run from the project root: swift Resources/generate-dmg-background.swift
// Layout must match release.sh: app icon at (180, 220), Applications at (480, 220) in window points.
import AppKit

let width = 1320, height = 880
let navy = NSColor(calibratedRed: 0.07, green: 0.10, blue: 0.18, alpha: 1)
let accent = NSColor(calibratedRed: 0.12, green: 0.53, blue: 0.95, alpha: 1)
let gray = NSColor(calibratedWhite: 0.42, alpha: 1)

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
)!
let cg = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
// Top-left origin, like Finder's icon positions.
cg.translateBy(x: 0, y: CGFloat(height))
cg.scaleBy(x: 1, y: -1)
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

// Background: light blue at the top fading to white.
NSGradient(
    starting: NSColor(calibratedRed: 0.92, green: 0.96, blue: 1.0, alpha: 1),
    ending: .white
)!.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 90)

func text(_ string: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSAttributedString {
    NSAttributedString(string: string, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ])
}

func drawCentered(_ string: NSAttributedString, y: CGFloat) {
    string.draw(at: NSPoint(x: (CGFloat(width) - string.size().width) / 2, y: y))
}

// Header: icon + name, then tagline.
let icon = NSImage(contentsOfFile: "Resources/AppIcon-1024.png")!
let title = text("Show Hidden Files", size: 64, weight: .semibold, color: navy)
let iconSize: CGFloat = 112, gap: CGFloat = 22
let headerX = (CGFloat(width) - iconSize - gap - title.size().width) / 2
icon.draw(
    in: NSRect(x: headerX, y: 48, width: iconSize, height: iconSize),
    from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil
)
title.draw(at: NSPoint(x: headerX + iconSize + gap, y: 104 - title.size().height / 2))
drawCentered(text("Show and hide files and folders on macOS", size: 30, weight: .regular, color: gray), y: 172)

// Dotted arrow between the two icons (window y = 220 pt → 440 px).
accent.setFill()
for x in stride(from: 540, through: 730, by: 30) {
    NSBezierPath(ovalIn: NSRect(x: CGFloat(x) - 7, y: 433, width: 14, height: 14)).fill()
}
let chevron = NSBezierPath()
chevron.move(to: NSPoint(x: 752, y: 412))
chevron.line(to: NSPoint(x: 780, y: 440))
chevron.line(to: NSPoint(x: 752, y: 468))
chevron.lineWidth = 12
chevron.lineCapStyle = .round
chevron.lineJoinStyle = .round
accent.setStroke()
chevron.stroke()

// Instructions: English, then Turkish.
let line1 = NSMutableAttributedString(attributedString: text("Drag the icon onto the ", size: 34, weight: .medium, color: navy))
line1.append(text("Applications", size: 34, weight: .semibold, color: accent))
line1.append(text(" folder.", size: 34, weight: .medium, color: navy))
drawCentered(line1, y: 736)
drawCentered(text("Simgeyi sürükleyip Uygulamalar klasörünün üzerine bırakın.", size: 28, weight: .regular, color: gray), y: 794)

NSGraphicsContext.current = nil
rep.size = NSSize(width: width / 2, height: height / 2) // 144 dpi → Finder shows it at 660×440 pt
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Resources/dmg-background.png"))
print("Wrote Resources/dmg-background.png")
