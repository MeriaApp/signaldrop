#!/usr/bin/env swift

import AppKit
import Foundation

// MARK: - Constants

let W: CGFloat = 2880
let H: CGFloat = 1800
let OUTPUT_DIR = "/Users/jesse/Developer/dropout/Screenshots"

// Colors
let BG_TOP = NSColor(red: 0x1e/255.0, green: 0x29/255.0, blue: 0x3b/255.0, alpha: 1)
let BG_BOTTOM = NSColor(red: 0x0f/255.0, green: 0x17/255.0, blue: 0x2a/255.0, alpha: 1)
let WHITE = NSColor.white
let GRAY_SUB = NSColor(white: 0.55, alpha: 1)
let CARD_BG = NSColor(red: 0x1a/255.0, green: 0x1f/255.0, blue: 0x2e/255.0, alpha: 1)
let CARD_STROKE = NSColor(white: 1.0, alpha: 0.08)
let RED = NSColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 1)
let ORANGE = NSColor(red: 1.0, green: 0.65, blue: 0.20, alpha: 1)
let GREEN = NSColor(red: 0.30, green: 0.85, blue: 0.55, alpha: 1)
let BLUE = NSColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1)
let PURPLE = NSColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 1)
let DIM = NSColor(white: 0.4, alpha: 1)
let MED = NSColor(white: 0.7, alpha: 1)
let SEP_COLOR = NSColor(white: 1.0, alpha: 0.06)
let NOTIF_BG = NSColor(red: 0x22/255.0, green: 0x27/255.0, blue: 0x36/255.0, alpha: 1)

// MARK: - Fonts

func heavy(_ s: CGFloat) -> NSFont { .systemFont(ofSize: s, weight: .heavy) }
func bold(_ s: CGFloat) -> NSFont { .systemFont(ofSize: s, weight: .bold) }
func semi(_ s: CGFloat) -> NSFont { .systemFont(ofSize: s, weight: .semibold) }
func med(_ s: CGFloat) -> NSFont { .systemFont(ofSize: s, weight: .medium) }
func reg(_ s: CGFloat) -> NSFont { .systemFont(ofSize: s, weight: .regular) }
func mono(_ s: CGFloat) -> NSFont { .monospacedSystemFont(ofSize: s, weight: .medium) }

// MARK: - Coordinate Helpers (top-down)

/// Convert top-down Y to AppKit bottom-up Y
func ty(_ topY: CGFloat) -> CGFloat { H - topY }

func sz(_ text: String, _ font: NSFont) -> NSSize {
    (text as NSString).size(withAttributes: [.font: font])
}

func text(_ str: String, x: CGFloat, topY: CGFloat, font: NSFont, color: NSColor) {
    let s = sz(str, font)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    (str as NSString).draw(at: NSPoint(x: x, y: ty(topY) - s.height), withAttributes: attrs)
}

func textCenter(_ str: String, topY: CGFloat, font: NSFont, color: NSColor, maxW: CGFloat) {
    let ps = NSMutableParagraphStyle()
    ps.alignment = .center
    ps.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: ps]
    let x = (W - maxW) / 2
    let lineH = font.ascender - font.descender + font.leading
    let rectH = lineH * 3 + 20
    let rect = NSRect(x: x, y: ty(topY) - rectH, width: maxW, height: rectH)
    (str as NSString).draw(in: rect, withAttributes: attrs)
}

func textRight(_ str: String, rightX: CGFloat, topY: CGFloat, font: NSFont, color: NSColor) {
    let s = sz(str, font)
    text(str, x: rightX - s.width, topY: topY, font: font, color: color)
}

// MARK: - Shapes

func roundedRect(_ x: CGFloat, _ topY: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat, fill: NSColor, stroke: NSColor? = nil, strokeW: CGFloat = 1, shadow: Bool = false) {
    let rect = NSRect(x: x, y: ty(topY) - h, width: w, height: h)
    let path = NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r)
    if shadow {
        NSGraphicsContext.saveGraphicsState()
        let s = NSShadow()
        s.shadowColor = NSColor.black.withAlphaComponent(0.5)
        s.shadowOffset = NSSize(width: 0, height: -12)
        s.shadowBlurRadius = 50
        s.set()
        fill.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
    }
    fill.setFill()
    path.fill()
    if let stroke = stroke {
        stroke.setStroke()
        path.lineWidth = strokeW
        path.stroke()
    }
}

func sep(_ topY: CGFloat, x: CGFloat, w: CGFloat) {
    let path = NSBezierPath()
    let ay = ty(topY)
    path.move(to: NSPoint(x: x, y: ay))
    path.line(to: NSPoint(x: x + w, y: ay))
    SEP_COLOR.setStroke()
    path.lineWidth = 1.5
    path.stroke()
}

func gradientBG() {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let cs = CGColorSpaceCreateDeviceRGB()
    let colors = [BG_BOTTOM.cgColor, BG_TOP.cgColor] as CFArray
    guard let g = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 1]) else { return }
    ctx.drawLinearGradient(g, start: .init(x: W/2, y: 0), end: .init(x: W/2, y: H), options: [])
}

func glow(cx: CGFloat, cy: CGFloat, radius: CGFloat, color: NSColor) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let cs = CGColorSpaceCreateDeviceRGB()
    let c1 = color.withAlphaComponent(0.08).cgColor
    let c2 = color.withAlphaComponent(0.0).cgColor
    guard let g = CGGradient(colorsSpace: cs, colors: [c1, c2] as CFArray, locations: [0, 1]) else { return }
    ctx.drawRadialGradient(g, startCenter: .init(x: cx, y: ty(cy)), startRadius: 0, endCenter: .init(x: cx, y: ty(cy)), endRadius: radius, options: [])
}

// MARK: - Components

func menuCard(x: CGFloat, topY: CGFloat, w: CGFloat, h: CGFloat) {
    roundedRect(x, topY, w, h, r: 28, fill: CARD_BG, stroke: CARD_STROKE, strokeW: 2.5, shadow: true)
}

func menuHeader(cx: CGFloat, cty: CGFloat, cw: CGFloat, status: String, sColor: NSColor) {
    let pad: CGFloat = 52
    let hty = cty + 30
    text("Dropout", x: cx + pad, topY: hty, font: bold(44), color: WHITE)

    let dotSz: CGFloat = 18
    let sFont = med(32)
    let sSz = sz(status, sFont)
    let sX = cx + cw - pad - sSz.width
    let dotX = sX - dotSz - 14
    roundedRect(dotX, hty + 10, dotSz, dotSz, r: dotSz/2, fill: sColor)
    text(status, x: sX, topY: hty + 2, font: sFont, color: sColor)

    sep(cty + 90, x: cx + pad, w: cw - pad * 2)
}

struct Row {
    let label: String
    let value: String
    let valueColor: NSColor
    var valueFont: NSFont? = nil
}

func drawRows(_ rows: [Row], startTopY: CGFloat, x: CGFloat, w: CGFloat, rowH: CGFloat = 72, labelFont: NSFont? = nil, defaultValueFont: NSFont? = nil) {
    let lf = labelFont ?? med(32)
    let dvf = defaultValueFont ?? med(32)
    var ry = startTopY
    for (i, row) in rows.enumerated() {
        text(row.label, x: x, topY: ry, font: lf, color: DIM)
        let vf = row.valueFont ?? dvf
        textRight(row.value, rightX: x + w, topY: ry, font: vf, color: row.valueColor)
        ry += rowH
        if i < rows.count - 1 {
            sep(ry - 18, x: x, w: w)
        }
    }
}

func notifBanner(x: CGFloat, topY: CGFloat, w: CGFloat, h: CGFloat, title: String, body: String, icon: String, iconColor: NSColor) {
    roundedRect(x, topY, w, h, r: 22, fill: NOTIF_BG, stroke: CARD_STROKE, strokeW: 2, shadow: true)

    let pad: CGFloat = 36
    let iSz: CGFloat = 72
    let iTopY = topY + (h - iSz) / 2
    roundedRect(x + pad, iTopY, iSz, iSz, r: iSz/2, fill: iconColor.withAlphaComponent(0.15))

    let iFont = bold(36)
    let its = sz(icon, iFont)
    text(icon, x: x + pad + (iSz - its.width)/2, topY: iTopY + (iSz - its.height)/2, font: iFont, color: iconColor)

    let tx = x + pad + iSz + 28
    text(title, x: tx, topY: topY + h/2 - 34, font: semi(36), color: WHITE)
    text(body, x: tx, topY: topY + h/2 + 10, font: reg(28), color: MED)
    text("DROPOUT", x: x + w - pad - 140, topY: topY + 16, font: med(21), color: DIM)
}

// MARK: - Bitmap

func render(_ draw: () -> Void) -> NSBitmapImageRep {
    let bmp = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    bmp.size = NSSize(width: W, height: H)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bmp)!
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return bmp
}

// MARK: - Screenshot 1: Never Miss a WiFi Drop Again

func ss1() -> NSBitmapImageRep {
    render {
        gradientBG()
        glow(cx: W/2, cy: 800, radius: 1200, color: RED)

        textCenter("Never Miss a WiFi\nDrop Again", topY: 80, font: heavy(128), color: WHITE, maxW: 2400)
        textCenter("Instant notifications when your connection drops or reconnects", topY: 370, font: reg(50), color: GRAY_SUB, maxW: 2000)

        // Card
        let cw: CGFloat = 1100
        let ch: CGFloat = 820
        let cx = (W - cw) / 2
        let cty: CGFloat = 520
        menuCard(x: cx, topY: cty, w: cw, h: ch)
        menuHeader(cx: cx, cty: cty, cw: cw, status: "Disconnected", sColor: RED)

        let px = cx + 52
        let pw = cw - 104
        drawRows([
            Row(label: "Network", value: "HomeWiFi-5G", valueColor: WHITE),
            Row(label: "Signal", value: "Lost", valueColor: RED),
            Row(label: "Downtime", value: "2m 14s", valueColor: ORANGE),
            Row(label: "Drops Today", value: "4", valueColor: ORANGE),
            Row(label: "Quality", value: "C", valueColor: ORANGE, valueFont: bold(34)),
        ], startTopY: cty + 112, x: px, w: pw, rowH: 78)

        // Notification overlapping top-right of card
        notifBanner(x: cx + cw - 300, topY: cty - 80, w: 1000, h: 155, title: "WiFi Disconnected", body: "Lost connection to HomeWiFi-5G", icon: "!", iconColor: RED)
    }
}

// MARK: - Screenshot 2: Know Before You Drop

func ss2() -> NSBitmapImageRep {
    render {
        gradientBG()
        glow(cx: W/2, cy: 800, radius: 1200, color: ORANGE)

        textCenter("Know Before\nYou Drop", topY: 80, font: heavy(128), color: WHITE, maxW: 2400)
        textCenter("Signal degradation warnings alert you before it happens", topY: 370, font: reg(50), color: GRAY_SUB, maxW: 2000)

        let cw: CGFloat = 1100
        let ch: CGFloat = 780
        let cx = (W - cw) / 2
        let cty: CGFloat = 540
        menuCard(x: cx, topY: cty, w: cw, h: ch)
        menuHeader(cx: cx, cty: cty, cw: cw, status: "Weak Signal", sColor: ORANGE)

        let px = cx + 52
        let pw = cw - 104
        drawRows([
            Row(label: "Network", value: "HomeWiFi-5G", valueColor: WHITE),
            Row(label: "Signal", value: "Weak  (-76 dBm)", valueColor: ORANGE),
            Row(label: "Noise", value: "-68 dBm", valueColor: MED),
            Row(label: "TX Rate", value: "58 Mbps", valueColor: MED),
            Row(label: "Quality", value: "B-", valueColor: ORANGE, valueFont: bold(34)),
        ], startTopY: cty + 112, x: px, w: pw, rowH: 78)

        notifBanner(x: cx + cw - 280, topY: cty - 70, w: 960, h: 155, title: "WiFi Signal Weak", body: "Signal dropping -- may lose connection soon", icon: "!", iconColor: ORANGE)
    }
}

// MARK: - Screenshot 3: Connection Quality Score

func ss3() -> NSBitmapImageRep {
    render {
        gradientBG()
        glow(cx: W/2, cy: 800, radius: 1200, color: BLUE)

        textCenter("Connection\nQuality Score", topY: 60, font: heavy(128), color: WHITE, maxW: 2400)
        textCenter("Track your WiFi reliability with a real-time grade", topY: 350, font: reg(50), color: GRAY_SUB, maxW: 2000)

        let cw: CGFloat = 1200
        let ch: CGFloat = 960
        let cx = (W - cw) / 2
        let cty: CGFloat = 480
        menuCard(x: cx, topY: cty, w: cw, h: ch)
        menuHeader(cx: cx, cty: cty, cw: cw, status: "Connected", sColor: GREEN)

        // Big grade
        let gradeFont = heavy(200)
        let gradeText = "B+"
        let gs = sz(gradeText, gradeFont)
        let gx = W/2 - gs.width/2 - 25
        let gradeTopY: CGFloat = cty + 120
        text(gradeText, x: gx, topY: gradeTopY, font: gradeFont, color: BLUE)
        text("^", x: gx + gs.width + 20, topY: gradeTopY + 50, font: bold(80), color: GREEN)

        let label = "Network Reliability"
        let ls = sz(label, med(34))
        text(label, x: W/2 - ls.width/2, topY: gradeTopY + gs.height + 16, font: med(34), color: DIM)

        let statsTopY = gradeTopY + gs.height + 72
        sep(statsTopY - 14, x: cx + 52, w: cw - 104)

        let px = cx + 52
        let pw = cw - 104
        drawRows([
            Row(label: "Drops Today", value: "3", valueColor: ORANGE, valueFont: bold(34)),
            Row(label: "Total Downtime", value: "1m 22s", valueColor: ORANGE, valueFont: bold(32)),
            Row(label: "Longest Session", value: "3h 47m", valueColor: GREEN, valueFont: bold(32)),
            Row(label: "Avg Signal", value: "-54 dBm", valueColor: GREEN, valueFont: bold(32)),
        ], startTopY: statsTopY + 10, x: px, w: pw, rowH: 76)
    }
}

// MARK: - Screenshot 4: ISP Troubleshooting Report

func ss4() -> NSBitmapImageRep {
    render {
        gradientBG()
        glow(cx: W/2, cy: 800, radius: 1200, color: PURPLE)

        textCenter("ISP Troubleshooting\nReport", topY: 50, font: heavy(124), color: WHITE, maxW: 2400)
        textCenter("Generate a detailed report to show your internet provider", topY: 340, font: reg(48), color: GRAY_SUB, maxW: 2000)

        let cw: CGFloat = 1340
        let ch: CGFloat = 1080
        let cx = (W - cw) / 2
        let cty: CGFloat = 460
        menuCard(x: cx, topY: cty, w: cw, h: ch)

        let px = cx + 60
        let pw = cw - 120
        var ry: CGFloat = cty + 40

        text("Dropout -- Network Report", x: px, topY: ry, font: bold(40), color: WHITE)
        ry += 52
        text("Generated Mar 26, 2026 at 2:14 PM", x: px, topY: ry, font: reg(28), color: DIM)
        ry += 56
        sep(ry, x: px, w: pw)
        ry += 22

        text("SUMMARY", x: px, topY: ry, font: bold(26), color: PURPLE)
        ry += 48

        let summaryItems: [(String, String, NSColor)] = [
            ("Network:", "HomeWiFi-5G (Comcast)", WHITE),
            ("Period:", "Mar 19 -- Mar 26, 2026", WHITE),
            ("Total Drops:", "23", RED),
            ("Total Downtime:", "47m 18s", RED),
        ]
        for (lbl, val, c) in summaryItems {
            text(lbl, x: px, topY: ry, font: med(30), color: DIM)
            text(val, x: px + 280, topY: ry, font: med(30), color: c)
            ry += 44
        }
        ry += 16
        sep(ry, x: px, w: pw)
        ry += 22

        text("OUTAGE TIMELINE", x: px, topY: ry, font: bold(26), color: PURPLE)
        ry += 48

        let outages: [(String, String, String)] = [
            ("Mar 26  1:42 PM", "3m 12s", "Signal lost"),
            ("Mar 25  9:18 PM", "8m 04s", "Dead network"),
            ("Mar 25  3:55 PM", "0m 47s", "Signal lost"),
            ("Mar 24  11:22 AM", "12m 33s", "Dead network"),
            ("Mar 23  7:08 PM", "1m 14s", "Signal lost"),
        ]
        for (time, dur, reason) in outages {
            text(time, x: px, topY: ry, font: mono(27), color: MED)
            text(dur, x: px + 440, topY: ry, font: mono(27), color: ORANGE)
            text(reason, x: px + 640, topY: ry, font: mono(27), color: DIM)
            ry += 42
        }
        ry += 18
        sep(ry, x: px, w: pw)
        ry += 22

        text("DAILY BREAKDOWN", x: px, topY: ry, font: bold(26), color: PURPLE)
        ry += 48

        let days: [(String, String, String)] = [
            ("Wed Mar 26", "4 drops", "6m 41s"),
            ("Tue Mar 25", "6 drops", "12m 03s"),
            ("Mon Mar 24", "5 drops", "18m 22s"),
            ("Sun Mar 23", "3 drops", "4m 08s"),
        ]
        for (day, drops, dt) in days {
            text(day, x: px, topY: ry, font: mono(27), color: MED)
            text(drops, x: px + 400, topY: ry, font: mono(27), color: ORANGE)
            text(dt, x: px + 640, topY: ry, font: mono(27), color: RED)
            ry += 42
        }
    }
}

// MARK: - Screenshot 5: Dead Network Detection

func ss5() -> NSBitmapImageRep {
    render {
        gradientBG()
        glow(cx: W/2, cy: 800, radius: 1200, color: RED)

        textCenter("Dead Network\nDetection", topY: 80, font: heavy(128), color: WHITE, maxW: 2400)
        textCenter("Auto-disconnects from WiFi with no internet", topY: 370, font: reg(50), color: GRAY_SUB, maxW: 2000)

        let cw: CGFloat = 1100
        let ch: CGFloat = 860
        let cx = (W - cw) / 2
        let cty: CGFloat = 530
        menuCard(x: cx, topY: cty, w: cw, h: ch)
        menuHeader(cx: cx, cty: cty, cw: cw, status: "Dead Network", sColor: RED)

        let px = cx + 52
        let pw = cw - 104
        drawRows([
            Row(label: "Network", value: "HomeWiFi-5G", valueColor: WHITE),
            Row(label: "Internet", value: "No Connectivity", valueColor: RED),
            Row(label: "Signal", value: "Strong (-42 dBm)", valueColor: GREEN),
            Row(label: "Action", value: "Auto-Disconnected", valueColor: ORANGE, valueFont: semi(32)),
            Row(label: "Reason", value: "DNS + HTTP checks failed", valueColor: MED),
            Row(label: "Status", value: "Scanning for networks...", valueColor: BLUE),
        ], startTopY: cty + 112, x: px, w: pw, rowH: 78)

        // Custom notification
        let bx = cx + cw - 280
        let bty = cty - 85
        let bw: CGFloat = 1020
        let bh: CGFloat = 170
        roundedRect(bx, bty, bw, bh, r: 22, fill: NOTIF_BG, stroke: CARD_STROKE, strokeW: 2, shadow: true)

        let pad: CGFloat = 36
        let iSz: CGFloat = 72
        roundedRect(bx + pad, bty + (bh - iSz)/2, iSz, iSz, r: iSz/2, fill: RED.withAlphaComponent(0.15))

        let iFont = bold(36)
        let its = sz("X", iFont)
        text("X", x: bx + pad + (iSz - its.width)/2, topY: bty + (bh - its.height)/2, font: iFont, color: RED)

        let tx = bx + pad + iSz + 28
        text("Dead Network -- Switching", x: tx, topY: bty + bh/2 - 36, font: semi(34), color: WHITE)
        text("HomeWiFi has no internet. Disconnected to find better.", x: tx, topY: bty + bh/2 + 10, font: reg(26), color: MED)
        text("DROPOUT", x: bx + bw - pad - 140, topY: bty + 18, font: med(21), color: DIM)
    }
}

// MARK: - Save & Run

func save(_ bmp: NSBitmapImageRep, _ path: String) -> Bool {
    guard let data = bmp.representation(using: .png, properties: [:]) else {
        print("ERROR: PNG encoding failed for \(path)")
        return false
    }
    do {
        try data.write(to: URL(fileURLWithPath: path))
        print("OK: \(path)")
        return true
    } catch {
        print("ERROR: \(error)")
        return false
    }
}

let fm = FileManager.default
if !fm.fileExists(atPath: OUTPUT_DIR) { try! fm.createDirectory(atPath: OUTPUT_DIR, withIntermediateDirectories: true) }

let screenshots: [(String, () -> NSBitmapImageRep)] = [
    ("screenshot-1.png", ss1),
    ("screenshot-2.png", ss2),
    ("screenshot-3.png", ss3),
    ("screenshot-4.png", ss4),
    ("screenshot-5.png", ss5),
]

var ok = true
for (name, gen) in screenshots {
    if !save(gen(), "\(OUTPUT_DIR)/\(name)") { ok = false }
}

print(ok ? "\nAll 5 screenshots saved to \(OUTPUT_DIR)/" : "\nSome failed.")
if !ok { exit(1) }
