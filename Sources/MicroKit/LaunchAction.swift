import Observation

/// A self-consuming one-shot flag that carries "the user asked to start now"
/// from an App Intent's `perform()` (or a widget deep link) to the just-mounted
/// UI. Generalized from Catch's / Hold's `LaunchActions`.
///
/// The UI checks it in two places — its first `.task` (cold launch: the flag is
/// already set) and `.onChange` (warm launch: the flag flips while the view is
/// alive) — and consumes it immediately so a stale request can't auto-fire on a
/// later, unrelated launch.
@Observable
@MainActor
public final class LaunchAction {
    /// Set by the intent / deep link; the UI reads and clears it via `consume()`.
    public var isRequested = false

    public init() {}

    /// Atomically read-and-clear. Returns true exactly once per request.
    public func consume() -> Bool {
        guard isRequested else { return false }
        isRequested = false
        return true
    }
}
