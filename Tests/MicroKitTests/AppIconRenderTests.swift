import SwiftUI
import XCTest
import MicroKit

/// Renders the suite's app icons from the real kit views, so an icon is
/// what the app shows: `KitGround` at rest behind `KitOrb`, in the app's hue,
/// carrying the app's own mark. The one difference from the screen is size:
/// the orb fills more of the square and the mark more of the orb.
///
/// Not a test of behaviour. It is skipped unless `ICON_OUT` names a folder,
/// and it is run on the iOS simulator by `scripts/render-app-icons.sh`
/// (system colours such as `.indigo` resolve differently on macOS).
///
/// The hue and mark of each row are copied from that app's `Kit.Identity`.
/// Change them there first, then here.
///
/// Note: the marks are SF Symbols. Apple's licence does not allow SF Symbols
/// in app icons. Using them here is the owner's decision (2026-11-17), and
/// it is something to revisit before an App Store submission.
final class AppIconRenderTests: XCTestCase {
    private struct Icon {
        let file: String
        let identity: Kit.Identity
        /// A flat background, for an app that has no `KitGround`.
        var flatGround: Color?
    }

    private static let icons: [Icon] = [
        Icon(file: "catch", identity: Kit.Identity(name: "Catch", hue: .indigo, mark: "waveform")),
        Icon(file: "hold", identity: Kit.Identity(
            name: "Hold", hue: Color(red: 0.545, green: 0.310, blue: 0.839), mark: "pin.fill")),
        Icon(file: "ramp", identity: Kit.Identity(name: "Ramp", hue: .teal, mark: "airplane.arrival")),
        Icon(file: "actual", identity: Kit.Identity(
            name: "Actual", hue: Color(red: 0.72, green: 0.52, blue: 0.03), mark: "stopwatch.fill")),
        Icon(file: "runway", identity: Kit.Identity(
            name: "Runway", hue: Color(red: 0.25, green: 0.62, blue: 0.95), mark: "airplane.departure")),
        Icon(file: "sweep", identity: Kit.Identity(
            name: "Sweep", hue: Color(red: 0.15, green: 0.78, blue: 0.35), mark: "checkmark")),
        // Faces has no KitGround: its screens sit on Theme.bg.
        Icon(file: "faces", identity: Kit.Identity(
            name: "Faces", hue: Color(red: 242 / 255, green: 86 / 255, blue: 156 / 255), mark: "face.smiling"),
             flatGround: Color(red: 13 / 255, green: 12 / 255, blue: 18 / 255)),
    ]

    @MainActor
    func testRenderAppIcons() throws {
        guard let out = ProcessInfo.processInfo.environment["ICON_OUT"], !out.isEmpty else {
            throw XCTSkip("Set ICON_OUT to render the app icons (see scripts/render-app-icons.sh).")
        }
        let folder = URL(fileURLWithPath: out, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let side: CGFloat = 1024
        for icon in Self.icons {
            let view = ZStack {
                // The window behind a dark-mode app is black; the ground's
                // top colour is translucent and shows it.
                Color.black
                if let flat = icon.flatGround { flat } else { KitGround(stage: .ready) }
                // The app's own orb, with its mark enlarged (0.42 on screen) so it
                // reads at home-screen size.
                KitOrb(diameter: side * 0.74, breathes: false, markScale: 0.56)
            }
            .frame(width: side, height: side)
            .kitIdentity(icon.identity)
            .environment(\.colorScheme, .dark)
            .transaction { $0.animation = nil }

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            renderer.proposedSize = ProposedViewSize(width: side, height: side)
            let rendered = try XCTUnwrap(renderer.cgImage, "no image for \(icon.file)")

            // Flatten onto an opaque canvas: app icons may not carry alpha.
            let context = try XCTUnwrap(CGContext(
                data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ))
            context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            context.draw(rendered, in: CGRect(x: 0, y: 0, width: side, height: side))
            let flat = try XCTUnwrap(context.makeImage())

            let url = folder.appendingPathComponent("\(icon.file).png")
            let destination = try XCTUnwrap(
                CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
            )
            CGImageDestinationAddImage(destination, flat, nil)
            XCTAssertTrue(CGImageDestinationFinalize(destination), "could not write \(url.path)")
        }
    }
}
