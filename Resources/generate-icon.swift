import AppKit
import CoreGraphics
import Foundation

let size = 1024
let width = CGFloat(size)
let height = CGFloat(size)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Failed to create CGContext")
}

let nsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGraphicsContext.current = nsContext

// Helper for continuous squircle path (macOS app icon shape)
func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    return NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

// 1. Outer drop shadow + macOS Squircle Base (824x824 centered in 1024x1024 per Apple HIG)
let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let iconRadius: CGFloat = 185

ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: -24),
    blur: 44,
    color: NSColor(calibratedWhite: 0, alpha: 0.42).cgColor
)
let squircle = roundedRectPath(iconRect, radius: iconRadius)
NSColor(calibratedRed: 0.07, green: 0.10, blue: 0.18, alpha: 1.0).setFill()
squircle.fill()
ctx.restoreGState()

// Clip to squircle
ctx.saveGState()
squircle.addClip()

// Background rich gradient (deep slate-navy -> electric indigo)
let bgColors = [
    NSColor(calibratedRed: 0.13, green: 0.18, blue: 0.34, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.18, alpha: 1.0).cgColor
] as CFArray
let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 512, y: 924),
    end: CGPoint(x: 512, y: 100),
    options: []
)

// Ambient cyan/blue glow in top-left and purple-blue glow in bottom-right
let glowColors1 = [
    NSColor(calibratedRed: 0.16, green: 0.65, blue: 1.0, alpha: 0.35).cgColor,
    NSColor(calibratedRed: 0.16, green: 0.65, blue: 1.0, alpha: 0.0).cgColor
] as CFArray
let glowGrad1 = CGGradient(colorsSpace: colorSpace, colors: glowColors1, locations: [0.0, 1.0])!
ctx.drawRadialGradient(
    glowGrad1,
    startCenter: CGPoint(x: 280, y: 780),
    startRadius: 0,
    endCenter: CGPoint(x: 280, y: 780),
    endRadius: 480,
    options: [.drawsBeforeStartLocation]
)

// 2. Back Folder (Ghost / Hidden Folder - offset up-right with dashed outline)
func folderBackPath(in rect: CGRect) -> NSBezierPath {
    let path = NSBezierPath()
    let r: CGFloat = 38
    let tabWidth = rect.width * 0.38
    let tabHeight: CGFloat = 46
    let bodyTop = rect.maxY - tabHeight

    path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
    path.line(to: CGPoint(x: rect.maxX - r, y: rect.minY))
    path.appendArc(
        withCenter: CGPoint(x: rect.maxX - r, y: rect.minY + r),
        radius: r,
        startAngle: 270,
        endAngle: 360
    )
    path.line(to: CGPoint(x: rect.maxX, y: bodyTop - r))
    path.appendArc(
        withCenter: CGPoint(x: rect.maxX - r, y: bodyTop - r),
        radius: r,
        startAngle: 0,
        endAngle: 90
    )
    path.line(to: CGPoint(x: rect.minX + tabWidth + 36, y: bodyTop))
    // Smooth curve up to tab
    path.curve(
        to: CGPoint(x: rect.minX + tabWidth, y: rect.maxY),
        controlPoint1: CGPoint(x: rect.minX + tabWidth + 16, y: bodyTop),
        controlPoint2: CGPoint(x: rect.minX + tabWidth + 14, y: rect.maxY)
    )
    path.line(to: CGPoint(x: rect.minX + r, y: rect.maxY))
    path.appendArc(
        withCenter: CGPoint(x: rect.minX + r, y: rect.maxY - r),
        radius: r,
        startAngle: 90,
        endAngle: 180
    )
    path.line(to: CGPoint(x: rect.minX, y: rect.minY + r))
    path.appendArc(
        withCenter: CGPoint(x: rect.minX + r, y: rect.minY + r),
        radius: r,
        startAngle: 180,
        endAngle: 270
    )
    path.close()
    return path
}

// Ghosted "Hidden" folder behind
let ghostRect = CGRect(x: 275, y: 365, width: 510, height: 395)
let ghostPath = folderBackPath(in: ghostRect)
NSColor(calibratedRed: 0.35, green: 0.75, blue: 1.0, alpha: 0.12).setFill()
ghostPath.fill()

let dashPattern: [CGFloat] = [18, 12]
ghostPath.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
ghostPath.lineWidth = 5
NSColor(calibratedRed: 0.45, green: 0.82, blue: 1.0, alpha: 0.55).setStroke()
ghostPath.stroke()

// 3. Main Folder (Foreground)
let folderRect = CGRect(x: 220, y: 255, width: 540, height: 420)
let backPath = folderBackPath(in: folderRect)

ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: -18),
    blur: 32,
    color: NSColor(calibratedWhite: 0, alpha: 0.45).cgColor
)
NSColor(calibratedRed: 0.12, green: 0.52, blue: 0.92, alpha: 1.0).setFill()
backPath.fill()
ctx.restoreGState()

ctx.saveGState()
backPath.addClip()
let backGradColors = [
    NSColor(calibratedRed: 0.22, green: 0.68, blue: 0.98, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.09, green: 0.44, blue: 0.85, alpha: 1.0).cgColor
] as CFArray
let backGrad = CGGradient(colorsSpace: colorSpace, colors: backGradColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(
    backGrad,
    start: CGPoint(x: folderRect.midX, y: folderRect.maxY),
    end: CGPoint(x: folderRect.midX, y: folderRect.minY),
    options: []
)
ctx.restoreGState()

// Document sheet peeking inside folder (with ".hidden" style dot & lines)
let docRect = CGRect(x: 265, y: 340, width: 450, height: 275)
let docPath = roundedRectPath(docRect, radius: 22)
ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: 4),
    blur: 12,
    color: NSColor(calibratedWhite: 0, alpha: 0.2).cgColor
)
NSColor(calibratedRed: 0.95, green: 0.98, blue: 1.0, alpha: 0.95).setFill()
docPath.fill()
ctx.restoreGState()

// Folder Front Pocket
let frontRect = CGRect(x: 220, y: 255, width: 540, height: 335)
let frontPath = roundedRectPath(frontRect, radius: 38)

ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: 6),
    blur: 16,
    color: NSColor(calibratedWhite: 0, alpha: 0.25).cgColor
)
NSColor(calibratedRed: 0.25, green: 0.75, blue: 1.0, alpha: 1.0).setFill()
frontPath.fill()
ctx.restoreGState()

// Split effect on Front Pocket: Left half solid vibrant macOS blue, Right half frosted/translucent "hidden" state
ctx.saveGState()
frontPath.addClip()

// Left side (Solid Visible Folder)
let leftGradColors = [
    NSColor(calibratedRed: 0.36, green: 0.82, blue: 1.0, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.14, green: 0.56, blue: 0.96, alpha: 1.0).cgColor
] as CFArray
let leftGrad = CGGradient(colorsSpace: colorSpace, colors: leftGradColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(
    leftGrad,
    start: CGPoint(x: frontRect.minX, y: frontRect.maxY),
    end: CGPoint(x: frontRect.minX, y: frontRect.minY),
    options: []
)

// Right side overlay (Translucent/xray effect with subtle grid/dots to signify hidden files)
ctx.saveGState()
let splitX = frontRect.midX
ctx.clip(to: CGRect(x: splitX, y: frontRect.minY, width: frontRect.width / 2, height: frontRect.height))
let rightGradColors = [
    NSColor(calibratedRed: 0.12, green: 0.28, blue: 0.52, alpha: 0.88).cgColor,
    NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.36, alpha: 0.92).cgColor
] as CFArray
let rightGrad = CGGradient(colorsSpace: colorSpace, colors: rightGradColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(
    rightGrad,
    start: CGPoint(x: splitX, y: frontRect.maxY),
    end: CGPoint(x: splitX, y: frontRect.minY),
    options: []
)

// Dot matrix pattern on the right half
NSColor(calibratedRed: 0.45, green: 0.85, blue: 1.0, alpha: 0.18).setFill()
for gx in stride(from: Int(splitX + 22), to: Int(frontRect.maxX - 15), by: 26) {
    for gy in stride(from: Int(frontRect.minY + 22), to: Int(frontRect.maxY - 15), by: 26) {
        let dot = NSBezierPath(ovalIn: CGRect(x: gx, y: gy, width: 6, height: 6))
        dot.fill()
    }
}
ctx.restoreGState()

// Center divider glow line
let dividerPath = NSBezierPath()
dividerPath.move(to: CGPoint(x: splitX, y: frontRect.minY))
dividerPath.line(to: CGPoint(x: splitX, y: frontRect.maxY))
dividerPath.lineWidth = 3
NSColor(calibratedWhite: 1.0, alpha: 0.45).setStroke()
dividerPath.stroke()

// Top edge highlight on folder front
let topHighlight = roundedRectPath(frontRect.insetBy(dx: 1.5, dy: 1.5), radius: 36.5)
topHighlight.lineWidth = 3
NSColor(calibratedWhite: 1.0, alpha: 0.35).setStroke()
topHighlight.stroke()

ctx.restoreGState()

// 4. Center Eye Emblem (Visibility Symbol) on the Folder Front
let eyeCenter = CGPoint(x: folderRect.midX, y: frontRect.midY)
let eyeWidth: CGFloat = 220
let eyeHeight: CGFloat = 126

let eyePath = NSBezierPath()
eyePath.move(to: CGPoint(x: eyeCenter.x - eyeWidth / 2, y: eyeCenter.y))
eyePath.curve(
    to: CGPoint(x: eyeCenter.x + eyeWidth / 2, y: eyeCenter.y),
    controlPoint1: CGPoint(x: eyeCenter.x - eyeWidth * 0.22, y: eyeCenter.y + eyeHeight * 0.68),
    controlPoint2: CGPoint(x: eyeCenter.x + eyeWidth * 0.22, y: eyeCenter.y + eyeHeight * 0.68)
)
eyePath.curve(
    to: CGPoint(x: eyeCenter.x - eyeWidth / 2, y: eyeCenter.y),
    controlPoint1: CGPoint(x: eyeCenter.x + eyeWidth * 0.22, y: eyeCenter.y - eyeHeight * 0.68),
    controlPoint2: CGPoint(x: eyeCenter.x - eyeWidth * 0.22, y: eyeCenter.y - eyeHeight * 0.68)
)
eyePath.close()

ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: -8),
    blur: 20,
    color: NSColor(calibratedRed: 0.0, green: 0.12, blue: 0.30, alpha: 0.55).cgColor
)
NSColor.white.setFill()
eyePath.fill()
ctx.restoreGState()

// Outer iris
let irisRadius: CGFloat = 42
let irisRect = CGRect(
    x: eyeCenter.x - irisRadius,
    y: eyeCenter.y - irisRadius,
    width: irisRadius * 2,
    height: irisRadius * 2
)
let irisPath = NSBezierPath(ovalIn: irisRect)
ctx.saveGState()
irisPath.addClip()
let irisColors = [
    NSColor(calibratedRed: 0.0, green: 0.78, blue: 0.98, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.06, green: 0.32, blue: 0.75, alpha: 1.0).cgColor
] as CFArray
let irisGrad = CGGradient(colorsSpace: colorSpace, colors: irisColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(
    irisGrad,
    start: CGPoint(x: eyeCenter.x, y: irisRect.maxY),
    end: CGPoint(x: eyeCenter.x, y: irisRect.minY),
    options: []
)
ctx.restoreGState()

// Inner pupil
let pupilRadius: CGFloat = 20
let pupilPath = NSBezierPath(
    ovalIn: CGRect(
        x: eyeCenter.x - pupilRadius,
        y: eyeCenter.y - pupilRadius,
        width: pupilRadius * 2,
        height: pupilRadius * 2
    )
)
NSColor(calibratedRed: 0.04, green: 0.10, blue: 0.22, alpha: 1.0).setFill()
pupilPath.fill()

// Specular glint on eye
let glintPath = NSBezierPath(
    ovalIn: CGRect(x: eyeCenter.x + 10, y: eyeCenter.y + 10, width: 15, height: 15)
)
NSColor.white.setFill()
glintPath.fill()

// 5. Inner border highlight on the outer squircle
let borderSquircle = roundedRectPath(iconRect.insetBy(dx: 2, dy: 2), radius: iconRadius - 2)
borderSquircle.lineWidth = 4
NSColor(calibratedWhite: 1.0, alpha: 0.16).setStroke()
borderSquircle.stroke()

ctx.restoreGState()

// Write 1024x1024 PNG
guard let cgImage = ctx.makeImage() else {
    fatalError("Failed to make image")
}
let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/AppIcon-1024.png"
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Generated icon at \(outputPath)")
