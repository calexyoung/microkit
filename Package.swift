// swift-tools-version: 6.2
import PackageDescription

// MicroKit — the small shared core for the ADHD-microtools suite. Extracted
// from Hold once Ramp became the second consumer (foundation policy: extract
// when the second app needs it, never before).
//
// Contents are deliberately minimal — only what ≥2 apps actually share:
// JSONStore (persistence), LaunchAction (intent→UI handoff), a Live Activity
// re-attach helper, the pin Live Activity, and the suite's design kit
// (MicrotoolsKit.swift — moved here 2026-11-16 once Ramp became its third
// adopter, after being proven in Catch and Hold). App-specific
// views/intents/models stay app-local.
//
// Catch does not depend on this package and carries a byte-identical copy of
// MicrotoolsKit.swift; run scripts/check-kit-sync.sh after changing it.
let package = Package(
    name: "MicroKit",
    // iOS is the real target; macOS is declared only so the CI host can
    // `swift test` the platform-agnostic core (JSONStore). A recent macOS min
    // is needed for os.Logger's privacy-annotated interpolation.
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [
        .library(name: "MicroKit", targets: ["MicroKit"]),
    ],
    targets: [
        .target(name: "MicroKit"),
        .testTarget(name: "MicroKitTests", dependencies: ["MicroKit"]),
    ]
)
