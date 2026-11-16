import SwiftUI
import XCTest
// Plain import, not @testable: these tests double as proof that everything
// an app needs from the kit is actually public.
import MicroKit

/// The pure parts of the shared design kit. The visual parts are checked by
/// eye in each app; these by test. (Catch carries a copy of the kit and of
/// these tests — see MicrotoolsKit.swift.)
final class KitTests: XCTestCase {
    @MainActor
    func testPublicSurfaceIsConstructibleFromOutsideTheModule() {
        // Compiles only if every initialiser an app calls is public.
        _ = KitGround(stage: .attention)
        _ = KitOrb(diameter: 64, breathes: false)
        _ = KitListening(level: 0.5, elapsed: 3, hint: "Tap anywhere to stop")
        _ = KitQuietRow { EmptyView() }
        _ = KitChip("lunch", isSelected: true) {}
        _ = KitPill(text: "Deleted", symbol: "trash", actionTitle: "Undo") {}
        _ = KitGear {}
        _ = Kit.Identity(name: "Test", hue: .teal, mark: "circle")
        _ = (KitMainButtonStyle(), KitSecondaryButtonStyle(), KitQuietButtonStyle(isDestructive: true))
    }

    func testAttentionGroundIsTheSameInEveryAppAndUnlikeReady() {
        XCTAssertEqual(
            Kit.groundColors(hue: .indigo, stage: .attention),
            Kit.groundColors(hue: .teal, stage: .attention)
        )
        // (Which is why no app may take a state colour as its own hue: an
        // orange app could not look any different when something came due.)
        XCTAssertNotEqual(
            Kit.groundColors(hue: .teal, stage: .attention).first,
            Kit.groundColors(hue: .teal, stage: .ready).first
        )
    }

    func testReadyAndWorkingGroundsUseTheAppHueAndDiffer() {
        let ready = Kit.groundColors(hue: .indigo, stage: .ready)
        let working = Kit.groundColors(hue: .indigo, stage: .working)
        XCTAssertEqual(ready.last, .black, "every ground fades to black")
        XCTAssertEqual(working.last, .black)
        XCTAssertNotEqual(ready.first, working.first, "working is the hue dimmed, not the hue")
        XCTAssertNotEqual(
            Kit.groundColors(hue: .teal, stage: .ready).first, ready.first,
            "the ground is how one app differs from another"
        )
    }

    func testListeningGroundIsTheSameInEveryApp() {
        XCTAssertEqual(
            Kit.groundColors(hue: .indigo, stage: .listening),
            Kit.groundColors(hue: .teal, stage: .listening),
            "a live microphone looks identical across the suite"
        )
    }

    func testStateColoursAreDistinct() {
        let colours = [Kit.Palette.listening, Kit.Palette.attention, Kit.Palette.done, Kit.Palette.failed]
        XCTAssertEqual(Set(colours.map { "\($0)" }).count, colours.count)
    }

    func testTypeRolesAreOrderedBySize() {
        let sizes = [Kit.TypeRole.number, .title, .timer, .line, .note].map(\.baseSize)
        XCTAssertEqual(sizes, sizes.sorted(by: >), "number > title > timer > line > note")
        XCTAssertEqual(Kit.TypeRole.title.baseSize, 36)
        XCTAssertEqual(Kit.TypeRole.number.baseSize, 72)
    }

    func testEveryHapticIsDistinguishable() {
        let all = Kit.Haptic.allCases.map(\.feedback)
        for (i, a) in all.enumerated() {
            for b in all[(i + 1)...] {
                XCTAssertNotEqual(a, b, "two events must never feel the same")
            }
        }
    }

    func testListeningClock() {
        XCTAssertEqual(Kit.clock(0), "0:00")
        XCTAssertEqual(Kit.clock(7.9), "0:07")
        XCTAssertEqual(Kit.clock(75), "1:15")
        XCTAssertEqual(Kit.clock(-3), "0:00")
    }

    func testPillKindsHaveTheirOwnLook() {
        XCTAssertEqual(KitPill.Kind.done.symbol, "checkmark.circle.fill")
        XCTAssertEqual(KitPill.Kind.failed.symbol, "exclamationmark.triangle.fill")
        XCTAssertNil(KitPill.Kind.neutral.symbol)
        XCTAssertNotEqual(KitPill.Kind.done.fill, KitPill.Kind.failed.fill)
    }
}
