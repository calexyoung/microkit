#!/usr/bin/env swift
//
//  ADHD Microtools: app icon generator for the whole suite.
//
//  Each icon is the app's in-app hero: the kit orb in the app's hue, on the
//  kit ground, carrying the app's mark in white. The hue and the idea behind
//  each mark come from the app's `Kit.Identity`.
//
//  The marks are drawn here in Core Graphics. They are NOT SF Symbols:
//  Apple's licence forbids SF Symbols, or anything confusingly similar, in
//  app icons. Keep it that way when a mark changes.
//
//  Output is a square, opaque, full-bleed 1024 px PNG. iOS applies the mask.
//
//  Usage:
//    swift scripts/generate-app-icons.swift <Developer dir>          all seven, into each repo
//    swift scripts/generate-app-icons.swift --preview <output dir>   all seven, into one folder
//

import AppKit
import CoreGraphics

// MARK: - The suite

struct App {
    let name: String
    /// The app's `Kit.Identity.hue`, 0...1.
    let hue: (r: CGFloat, g: CGFloat, b: CGFloat)
    /// Path of the icon PNG inside the Developer directory.
    let iconPath: String
    /// Draws the mark in white, centred on (0, 0), inside a 440-unit box.
    let mark: (CGContext) -> Void
}

let apps: [App] = [
    App(name: "catch", hue: (0.369, 0.361, 0.902),   // .indigo
        iconPath: "catch-the-thought/CatchTheThought/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
        mark: drawWaveform),
    App(name: "hold", hue: (0.545, 0.310, 0.839),    // #8B4FD6
        iconPath: "hold/Hold/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
        mark: drawPin),
    App(name: "ramp", hue: (0.251, 0.784, 0.878),    // .teal
        iconPath: "ramp/Ramp/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
        mark: drawLanding),
    App(name: "actual", hue: (0.72, 0.52, 0.03),
        iconPath: "actual/Actual/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
        mark: drawStopwatch),
    App(name: "runway", hue: (0.25, 0.62, 0.95),
        iconPath: "runway/Runway/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
        mark: drawTakeoff),
    App(name: "sweep", hue: (0.15, 0.78, 0.35),
        iconPath: "sweep/Sweep/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
        mark: drawCheck),
    App(name: "faces", hue: (0.949, 0.337, 0.612),   // Theme.blue, the brand pink
        iconPath: "meeting-place/CatchAFace/Assets.xcassets/AppIcon.appiconset/Icon-1024.png",
        mark: drawFace),
]

// MARK: - Colour helpers

let space = CGColorSpaceCreateDeviceRGB()

func rgb(_ c: (r: CGFloat, g: CGFloat, b: CGFloat), _ a: CGFloat = 1) -> CGColor {
    CGColor(red: c.r, green: c.g, blue: c.b, alpha: a)
}

/// `c` moved toward black (t < 0) or white (t > 0) by |t|.
func shade(_ c: (r: CGFloat, g: CGFloat, b: CGFloat), _ t: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
    let target: CGFloat = t < 0 ? 0 : 1
    let k = abs(t)
    return (c.r + (target - c.r) * k, c.g + (target - c.g) * k, c.b + (target - c.b) * k)
}

let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

// MARK: - Ground and orb (shared by every icon)

/// The kit ground at rest: the hue at the top, falling to near-black.
func drawGround(_ ctx: CGContext, hue: (r: CGFloat, g: CGFloat, b: CGFloat)) {
    let gradient = CGGradient(
        colorsSpace: space,
        colors: [rgb(shade(hue, -0.25)), rgb(shade(hue, -0.72)), rgb(shade(hue, -0.93))] as CFArray,
        locations: [0, 0.6, 1]
    )!
    ctx.drawLinearGradient(
        gradient, start: CGPoint(x: 512, y: 0), end: CGPoint(x: 512, y: 1024),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}

/// The kit orb: a soft glow, then a sphere lit from the upper left. The
/// highlight is kept small and off to the side so a white mark stays clear.
func drawOrb(_ ctx: CGContext, hue: (r: CGFloat, g: CGFloat, b: CGFloat)) {
    let centre = CGPoint(x: 512, y: 512)
    let radius: CGFloat = 390

    let glow = CGGradient(
        colorsSpace: space,
        colors: [rgb(hue, 0.75), rgb(hue, 0.30), rgb(hue, 0)] as CFArray,
        locations: [0, 0.72, 1]
    )!
    ctx.drawRadialGradient(glow, startCenter: centre, startRadius: radius * 0.8,
                           endCenter: centre, endRadius: radius * 1.42, options: [.drawsBeforeStartLocation])

    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
    ctx.clip()
    let light = CGPoint(x: centre.x - radius * 0.42, y: centre.y - radius * 0.52)
    let body = CGGradient(
        colorsSpace: space,
        colors: [rgb(shade(hue, 0.42)), rgb(shade(hue, 0.08)), rgb(hue), rgb(shade(hue, -0.38))] as CFArray,
        locations: [0, 0.3, 0.62, 1]
    )!
    ctx.drawRadialGradient(body, startCenter: light, startRadius: 0,
                           endCenter: light, endRadius: radius * 1.75, options: [.drawsAfterEndLocation])
    ctx.restoreGState()
}

// MARK: - Mark helpers

func stroke(_ ctx: CGContext, _ path: CGPath, width: CGFloat) {
    ctx.addPath(path)
    ctx.setStrokeColor(white)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
}

func fill(_ ctx: CGContext, _ path: CGPath) {
    ctx.addPath(path)
    ctx.setFillColor(white)
    ctx.fillPath()
}

func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r), transform: nil)
}

/// A solid arrowhead with its tip at `tip`, pointing along `angle` (radians,
/// y down).
func arrowhead(tip: CGPoint, angle: CGFloat, length: CGFloat, halfWidth: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let back = CGPoint(x: tip.x - cos(angle) * length, y: tip.y - sin(angle) * length)
    let nx = -sin(angle), ny = cos(angle)
    p.move(to: tip)
    p.addLine(to: CGPoint(x: back.x + nx * halfWidth, y: back.y + ny * halfWidth))
    p.addLine(to: CGPoint(x: back.x - nx * halfWidth, y: back.y - ny * halfWidth))
    p.closeSubpath()
    return p
}

// MARK: - The marks (original drawings; y grows downward)

/// Catch: a voice, as five bars.
func drawWaveform(_ ctx: CGContext) {
    let heights: [CGFloat] = [130, 300, 420, 230, 340]
    let step: CGFloat = 92
    for (i, h) in heights.enumerated() {
        let x = (CGFloat(i) - 2) * step
        let bar = CGMutablePath()
        bar.move(to: CGPoint(x: x, y: -h / 2 + 24))
        bar.addLine(to: CGPoint(x: x, y: h / 2 - 24))
        stroke(ctx, bar, width: 48)
    }
}

/// Hold: a pushpin, tilted, holding the thought in place.
func drawPin(_ ctx: CGContext) {
    ctx.saveGState()
    ctx.rotate(by: 32 * .pi / 180)
    ctx.translateBy(x: 0, y: -30)
    fill(ctx, circle(0, -110, 112))                                   // head
    fill(ctx, CGPath(roundedRect: CGRect(x: -52, y: -20, width: 104, height: 70),
                     cornerWidth: 14, cornerHeight: 14, transform: nil))   // neck
    fill(ctx, CGPath(roundedRect: CGRect(x: -128, y: 40, width: 256, height: 52),
                     cornerWidth: 26, cornerHeight: 26, transform: nil))   // collar
    let needle = CGMutablePath()
    needle.move(to: CGPoint(x: -17, y: 88))
    needle.addLine(to: CGPoint(x: 17, y: 88))
    needle.addLine(to: CGPoint(x: 0, y: 262))
    needle.closeSubpath()
    fill(ctx, needle)
    ctx.restoreGState()
}

/// Ramp: coming down onto solid ground. One unbroken line to land on.
func drawLanding(_ ctx: CGContext) {
    let arc = CGMutablePath()
    arc.move(to: CGPoint(x: 150, y: -200))
    arc.addQuadCurve(to: CGPoint(x: -98, y: 72), control: CGPoint(x: 10, y: -170))
    stroke(ctx, arc, width: 50)
    fill(ctx, arrowhead(tip: CGPoint(x: -128, y: 132), angle: 2.03, length: 120, halfWidth: 84))
    let ground = CGMutablePath()
    ground.move(to: CGPoint(x: -200, y: 192))
    ground.addLine(to: CGPoint(x: 200, y: 192))
    stroke(ctx, ground, width: 44)
}

/// Runway: lifting off. A dashed centre line left behind.
func drawTakeoff(_ ctx: CGContext) {
    for x in stride(from: CGFloat(-190), through: 150, by: 170) {
        let dash = CGMutablePath()
        dash.move(to: CGPoint(x: x, y: 192))
        dash.addLine(to: CGPoint(x: x + 80, y: 192))
        stroke(ctx, dash, width: 40)
    }
    let arc = CGMutablePath()
    arc.move(to: CGPoint(x: -190, y: 96))
    arc.addQuadCurve(to: CGPoint(x: 96, y: -116), control: CGPoint(x: 30, y: 84))
    stroke(ctx, arc, width: 50)
    fill(ctx, arrowhead(tip: CGPoint(x: 150, y: -196), angle: -0.98, length: 120, halfWidth: 84))
}

/// Actual: a stopwatch, with the time already running.
func drawStopwatch(_ ctx: CGContext) {
    stroke(ctx, circle(0, 40, 168), width: 46)
    fill(ctx, CGPath(roundedRect: CGRect(x: -56, y: -212, width: 112, height: 52),
                     cornerWidth: 22, cornerHeight: 22, transform: nil))   // crown
    fill(ctx, CGPath(rect: CGRect(x: -20, y: -170, width: 40, height: 40), transform: nil))
    ctx.saveGState()                                                         // side button
    ctx.translateBy(x: 138, y: -100)
    ctx.rotate(by: 45 * .pi / 180)
    fill(ctx, CGPath(roundedRect: CGRect(x: -24, y: -44, width: 48, height: 60),
                     cornerWidth: 16, cornerHeight: 16, transform: nil))
    ctx.restoreGState()
    let hand = CGMutablePath()
    hand.move(to: CGPoint(x: 0, y: 40))
    hand.addLine(to: CGPoint(x: 62, y: -44))
    stroke(ctx, hand, width: 38)
    fill(ctx, circle(0, 40, 30))
}

/// Sweep: checked, done.
func drawCheck(_ ctx: CGContext) {
    let tick = CGMutablePath()
    tick.move(to: CGPoint(x: -176, y: 20))
    tick.addLine(to: CGPoint(x: -58, y: 140))
    tick.addLine(to: CGPoint(x: 184, y: -140))
    stroke(ctx, tick, width: 72)
}

/// Faces: a friendly face you want to remember.
func drawFace(_ ctx: CGContext) {
    stroke(ctx, circle(0, 0, 196), width: 46)
    fill(ctx, CGPath(ellipseIn: CGRect(x: -98, y: -92, width: 50, height: 72), transform: nil))
    fill(ctx, CGPath(ellipseIn: CGRect(x: 48, y: -92, width: 50, height: 72), transform: nil))
    let smile = CGMutablePath()
    smile.move(to: CGPoint(x: -100, y: 46))
    smile.addQuadCurve(to: CGPoint(x: 100, y: 46), control: CGPoint(x: 0, y: 150))
    stroke(ctx, smile, width: 40)
}

// MARK: - Rendering

func render(_ app: App) -> Data {
    let size = 1024
    // No alpha channel: App Store icons must be opaque.
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1)

    drawGround(ctx, hue: app.hue)
    drawOrb(ctx, hue: app.hue)

    ctx.saveGState()
    ctx.translateBy(x: 512, y: 512)
    ctx.scaleBy(x: 1.12, y: 1.12)
    // A faint shadow in the app's own dark lifts the mark off the highlight.
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: rgb(shade(app.hue, -0.7), 0.55))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    app.mark(ctx)
    ctx.endTransparencyLayer()
    ctx.restoreGState()

    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

// MARK: - Entry

let args = CommandLine.arguments
func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

if args.count == 3, args[1] == "--preview" {
    let dir = URL(fileURLWithPath: args[2], isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for app in apps {
        try render(app).write(to: dir.appendingPathComponent("\(app.name).png"))
    }
    print("wrote \(apps.count) previews to \(dir.path)")
} else if args.count == 2 {
    let root = URL(fileURLWithPath: args[1], isDirectory: true)
    for app in apps {
        let out = root.appendingPathComponent(app.iconPath)
        guard FileManager.default.fileExists(atPath: out.deletingLastPathComponent().path) else {
            fail("no icon set for \(app.name) at \(out.deletingLastPathComponent().path)")
        }
        try render(app).write(to: out)
        print("wrote \(app.name): \(out.path)")
    }
} else {
    fail("usage: generate-app-icons.swift <Developer dir> | --preview <output dir>")
}
