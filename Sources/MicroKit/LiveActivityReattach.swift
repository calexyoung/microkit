// Gated on `os(iOS)`, not `canImport(ActivityKit)`: ActivityKit *is* importable
// on macOS (its types are just marked unavailable), so canImport wouldn't
// exclude this from the macOS CI-host build.
#if os(iOS)
import ActivityKit

/// Generic helpers for the suite's "relaunch must never orphan a stale pin"
/// rule: on launch, re-bind to a still-live Activity; on resolve/expire, end
/// every stray. Every countdown/pin app (Hold, Ramp, Runway, Actual) needs
/// exactly this, so it lives in MicroKit rather than being re-implemented.
///
/// Gated on `canImport(ActivityKit)` so MicroKit still builds for the macOS CI
/// host (ActivityKit is iOS-only).
public enum LiveActivityReattach {
    /// The first live Activity of the given attributes type, if any — used on
    /// launch to reconcile in-memory state with a pin that survived a kill.
    public static func first<A: ActivityAttributes>(_ type: A.Type) -> Activity<A>? {
        Activity<A>.activities.first
    }

    /// End every live Activity of the given type immediately.
    public static func endAll<A: ActivityAttributes>(_ type: A.Type) async {
        for activity in Activity<A>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
