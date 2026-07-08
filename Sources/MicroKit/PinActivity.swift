// The 📌 externalized-persistence idiom, extracted from Hold when Sweep became
// the second consumer (foundation policy). A pin is a Live Activity that keeps
// one short text visible on the Lock Screen / Dynamic Island until resolved —
// object permanence, outsourced.
//
// Each app supplies its own `LiveActivityIntent` for the Done button (the
// intent's perform() touches app-specific storage, so it can't live here).
#if os(iOS)
import ActivityKit
import AppIntents
import SwiftUI

/// The shared Activity contract for a pinned text.
public struct PinAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var text: String
        public var pinnedAt: Date
        /// nil = pinned until resolved (Sweep's missing items); non-nil = the
        /// moment has passed and the pin silently expires (Hold).
        public var expiresAt: Date?

        public init(text: String, pinnedAt: Date, expiresAt: Date? = nil) {
            self.text = text
            self.pinnedAt = pinnedAt
            self.expiresAt = expiresAt
        }
    }

    public var pinID: UUID

    public init(pinID: UUID) {
        self.pinID = pinID
    }
}

/// Lock Screen / banner presentation: 📌 + the text large + elapsed +
/// interactive Done. Generic over the app's Done intent.
public struct PinLockScreenView<DoneIntent: AppIntent>: View {
    let state: PinAttributes.ContentState
    let doneIntent: DoneIntent

    public init(state: PinAttributes.ContentState, doneIntent: DoneIntent) {
        self.state = state
        self.doneIntent = doneIntent
    }

    public var body: some View {
        HStack(spacing: 14) {
            Text("📌")
                .font(.system(size: 34))
            VStack(alignment: .leading, spacing: 4) {
                Text(state.text)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(state.pinnedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer(minLength: 8)
            Button(intent: doneIntent) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .tint(.green)
            .accessibilityLabel("Done")
        }
        .padding(16)
    }
}

/// Compact Dynamic Island trailing text: first ~14 characters.
public extension String {
    var pinCompactPreview: String {
        count <= 14 ? self : String(prefix(13)) + "…"
    }
}
#endif
