#!/usr/bin/swift

import AppKit
import Foundation

// MARK: - Constants

let outputPath = "Resources/AppIcon.icns"
let masterSize: CGFloat = 1024

let iconSizes: [(name: String, size: Int)] = [
    ("icon_16x16",       16),
    ("icon_16x16@2x",    32),
    ("icon_32x32",       32),
    ("icon_32x32@2x",    64),
    ("icon_128x128",     128),
    ("icon_128x128@2x",  256),
    ("icon_256x256",     256),
    ("icon_256x256@2x",  512),
    ("icon_512x512",     512),
    ("icon_512x512@2x",  1024),
]

// MARK: - Color Helpers

func color(hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255.0
    let g = CGFloat((hex >> 8) & 0xFF) / 255.0
    let b = CGFloat(hex & 0xFF) / 255.0
    return NSColor(calibratedRed: r, green: g, blue: b, alpha: alpha)
}

// MARK: - Icon Rendering

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        fatalError("Failed to get CGContext")
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // -- Rounded rectangle (squircle) background --
    let cornerRadius = size * 0.22
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.01, dy: size * 0.01),
                               xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient: dark indigo top (#0f172a) to slightly lighter bottom (#1e293b)
    // Note: Core Graphics Y is flipped in lockFocus — 0 is bottom.
    // We want dark at top (high Y) and lighter at bottom (low Y).
    let gradientColors = [
        color(hex: 0x1e293b).cgColor,  // bottom (lighter)
        color(hex: 0x0f172a).cgColor,  // top (darker)
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0]) else {
        fatalError("Failed to create gradient")
    }

    context.saveGState()
    bgPath.addClip()
    context.drawLinearGradient(gradient,
                               start: CGPoint(x: size / 2, y: 0),
                               end: CGPoint(x: size / 2, y: size),
                               options: [])
    context.restoreGState()

    // -- Subtle inner shadow / border for depth --
    let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.01, dy: size * 0.01),
                                   xRadius: cornerRadius, yRadius: cornerRadius)
    color(hex: 0xFFFFFF, alpha: 0.06).setStroke()
    borderPath.lineWidth = size * 0.005
    borderPath.stroke()

    // -- WiFi arcs --
    let lineWidth = size * 0.04
    let arcCenterX = size * 0.46
    let arcCenterY = size * 0.42  // slightly below vertical center (remember: Y=0 is bottom in CG)
    let arcCenter = CGPoint(x: arcCenterX, y: arcCenterY)

    let arcRadii: [CGFloat] = [size * 0.14, size * 0.25, size * 0.36]
    let arcOpacities: [CGFloat] = [1.0, 0.75, 0.50]

    let startAngle = CGFloat.pi / 4        // 45°
    let endAngle = CGFloat.pi * 3 / 4      // 135°

    for (i, radius) in arcRadii.enumerated() {
        let path = NSBezierPath()
        path.appendArc(withCenter: arcCenter,
                       radius: radius,
                       startAngle: startAngle * 180 / .pi,
                       endAngle: endAngle * 180 / .pi,
                       clockwise: false)
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        color(hex: 0xFFFFFF, alpha: arcOpacities[i]).setStroke()
        path.stroke()
    }

    // -- White dot at the base of arcs --
    let dotRadius = size * 0.035
    let dotRect = CGRect(x: arcCenterX - dotRadius,
                         y: arcCenterY - dotRadius,
                         width: dotRadius * 2,
                         height: dotRadius * 2)
    color(hex: 0xFFFFFF, alpha: 1.0).setFill()
    NSBezierPath(ovalIn: dotRect).fill()

    // -- Alert badge (amber circle with "!" in bottom-right) --
    let badgeSize = size * 0.26
    let badgePadding = size * 0.10
    let badgeCenterX = size - badgePadding - badgeSize / 2
    let badgeCenterY = badgePadding + badgeSize / 2  // bottom-right (Y=0 is bottom)
    let badgeRect = CGRect(x: badgeCenterX - badgeSize / 2,
                           y: badgeCenterY - badgeSize / 2,
                           width: badgeSize,
                           height: badgeSize)

    // Badge shadow
    context.saveGState()
    let shadowColor = NSColor.black.withAlphaComponent(0.35).cgColor
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.008),
                      blur: size * 0.025,
                      color: shadowColor)
    color(hex: 0xf59e0b).setFill()
    NSBezierPath(ovalIn: badgeRect).fill()
    context.restoreGState()

    // Badge fill (redraw without shadow for clean color)
    color(hex: 0xf59e0b).setFill()
    NSBezierPath(ovalIn: badgeRect).fill()

    // Subtle gradient overlay on badge for depth
    context.saveGState()
    let badgePath = NSBezierPath(ovalIn: badgeRect)
    badgePath.addClip()
    let badgeGradientColors = [
        color(hex: 0xfbbf24).cgColor,  // lighter top
        color(hex: 0xd97706).cgColor,  // darker bottom
    ] as CFArray
    guard let badgeGradient = CGGradient(colorsSpace: colorSpace, colors: badgeGradientColors, locations: [0.0, 1.0]) else {
        fatalError("Failed to create badge gradient")
    }
    context.drawLinearGradient(badgeGradient,
                               start: CGPoint(x: badgeCenterX, y: badgeCenterY + badgeSize / 2),
                               end: CGPoint(x: badgeCenterX, y: badgeCenterY - badgeSize / 2),
                               options: [])
    context.restoreGState()

    // Exclamation mark "!"
    let fontSize = badgeSize * 0.62
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let exclamation = "!" as NSString
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let textSize = exclamation.size(withAttributes: attributes)
    let textOrigin = CGPoint(x: badgeCenterX - textSize.width / 2,
                             y: badgeCenterY - textSize.height / 2)
    exclamation.draw(at: textOrigin, withAttributes: attributes)

    image.unlockFocus()
    return image
}

// MARK: - PNG Export

func writePNG(image: NSImage, to path: String, pixelSize: Int) -> Bool {
    let targetSize = NSSize(width: pixelSize, height: pixelSize)

    let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmapRep.size = targetSize

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
    NSGraphicsContext.current?.imageInterpolation = .high

    image.draw(in: NSRect(origin: .zero, size: targetSize),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy,
               fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        return false
    }

    return FileManager.default.createFile(atPath: path, contents: pngData)
}

// MARK: - Main

func main() {
    let fileManager = FileManager.default

    // Resolve paths relative to the script's working directory
    let workingDir = fileManager.currentDirectoryPath
    let resourcesDir = (workingDir as NSString).appendingPathComponent("Resources")
    let icnsPath = (workingDir as NSString).appendingPathComponent(outputPath)
    let iconsetDir = NSTemporaryDirectory() + "Dropout.iconset"

    // Ensure Resources directory exists
    try? fileManager.createDirectory(atPath: resourcesDir, withIntermediateDirectories: true)

    // Clean up any previous iconset
    try? fileManager.removeItem(atPath: iconsetDir)

    do {
        try fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
    } catch {
        print("ERROR: Failed to create iconset directory: \(error)")
        exit(1)
    }

    print("Rendering master icon at \(Int(masterSize))x\(Int(masterSize))...")
    let masterImage = renderIcon(size: masterSize)

    // Generate each size
    for entry in iconSizes {
        let filename = "\(entry.name).png"
        let filePath = (iconsetDir as NSString).appendingPathComponent(filename)

        if !writePNG(image: masterImage, to: filePath, pixelSize: entry.size) {
            print("ERROR: Failed to write \(filename)")
            exit(1)
        }
        print("  \(filename) (\(entry.size)x\(entry.size))")
    }

    // Convert to .icns using iconutil
    print("Converting to .icns...")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]

    let pipe = Pipe()
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        print("ERROR: Failed to run iconutil: \(error)")
        exit(1)
    }

    if process.terminationStatus != 0 {
        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
        print("ERROR: iconutil failed: \(errorMsg)")
        exit(1)
    }

    // Clean up temp iconset
    try? fileManager.removeItem(atPath: iconsetDir)

    print("Success: \(icnsPath)")
}

main()
