// swift-tools-version: 6.2
import PackageDescription

// MicroKit — the small shared core for the ADHD-microtools suite. Extracted
// from Hold once Ramp became the second consumer (foundation policy: extract
// when the second app needs it, never before).
//
// Contents are deliberately minimal — only what ≥2 apps actually share:
// JSONStore (persistence), LaunchAction (intent→UI handoff), and a Live
// Activity re-attach helper. App-specific views/intents/models stay app-local.
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
