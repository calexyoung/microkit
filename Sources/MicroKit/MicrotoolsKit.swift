import SwiftUI

// ADHD Microtools — shared design kit.
//
// One look for every tool in the suite, so a user who has learned one has
// learned them all: a dark ground in the app's own hue, one glowing mark,
// rounded type that follows the system text size, one white main button at
// thumb height, quiet secondary actions, and a pill that says what just
// happened.
//
// WHERE THIS FILE LIVES
//   microkit/Sources/MicroKit/MicrotoolsKit.swift      ← the source of truth
//   catch-the-thought/CatchTheThought/Kit/MicrotoolsKit.swift  ← a copy
// Every app except Catch gets the kit by importing MicroKit. Catch has no
// MicroKit dependency (its CI can't resolve a local path package), so it
// carries a byte-identical copy; `scripts/check-kit-sync.sh` in Catch and in
// MicroKit verifies the two match. Change this one, then copy it to Catch.
// (`public` is harmless in Catch's app target — it is there for the package.)
//
// Nothing here knows which app it is in. The app describes itself once, at
// its root, with `.kitIdentity(...)`.

// MARK: - Identity

public enum Kit {
    /// What makes one microtool recognisably itself: its hue and its mark.
    /// Two things, not one — hue alone can't tell apps apart for everyone.
    public struct Identity: Equatable, Sendable {
        public var name: String
        public var hue: Color
        /// SF Symbol name drawn inside the orb.
        public var mark: String

        public init(name: String, hue: Color, mark: String) {
            self.name = name
            self.hue = hue
            self.mark = mark
        }

        /// Used only until an app sets its own (previews, tests).
        public static let placeholder = Identity(name: "Microtool", hue: .indigo, mark: "circle")
    }

    // MARK: Ground

    /// What the whole screen is saying. The ground colour carries state so
    /// it can be read without reading: a glance, or the edge of your vision.
    public enum Stage: Equatable, Sendable {
        /// Waiting for you. The app's own hue.
        case ready
        /// Busy on your behalf. The app's hue, dimmed — never a different
        /// colour, because every other colour already means something.
        case working
        /// The microphone is live. Pink in every app.
        case listening
        /// Act now: something you set up has come due. Orange in every app.
        /// For things the user asked to be told about — never as a nag.
        case attention
    }

    public static func groundColors(hue: Color, stage: Stage) -> [Color] {
        switch stage {
        case .ready: [hue.opacity(0.85), .black]
        case .working: [hue.opacity(0.45), .black]
        case .listening: [Palette.listening.opacity(0.9), .purple, .black]
        case .attention: [Palette.attention.opacity(0.85), .black]
        }
    }

    // MARK: Colour

    /// State colours mean the same thing in every app. They are not
    /// decoration and are never used as an app's hue.
    public enum Palette {
        /// The microphone is live.
        public static let listening = Color.pink
        /// Act now.
        public static let attention = Color.orange
        /// It worked.
        public static let done = Color.green
        /// It didn't.
        public static let failed = Color.red
        /// Label on a main button.
        public static let ink = Color(red: 0.08, green: 0.09, blue: 0.17)
    }

    // MARK: Type

    /// The suite's type sizes. All of them follow the system text size.
    public enum TypeRole: CaseIterable, Sendable {
        /// The one big figure on a screen: a countdown, a duration.
        case number
        /// The one line that says what to do.
        case title
        /// A running clock. Monospaced digits so it doesn't jitter.
        case timer
        /// A supporting sentence.
        case line
        /// Reassurance and fine print.
        case note

        /// Point size at the default text size.
        public var baseSize: CGFloat {
            switch self {
            case .number: 72
            case .title: 36
            case .timer: 28
            case .line: 16
            case .note: 13
            }
        }

        public var textStyle: Font.TextStyle {
            switch self {
            case .number, .title: .largeTitle
            case .timer: .title
            case .line: .callout
            case .note: .footnote
            }
        }

        public var weight: Font.Weight {
            switch self {
            case .number: .bold
            case .title: .semibold
            case .timer: .medium
            case .line, .note: .regular
            }
        }

        /// Hero roles use the rounded face; running text uses the default.
        public var isRounded: Bool {
            switch self {
            case .number, .title, .timer: true
            case .line, .note: false
            }
        }
    }

    // MARK: Haptics

    /// One vocabulary of clicks, so the hand learns it once. These apps are
    /// used mid-walk and mid-conversation; the click is the confirmation.
    public enum Haptic: CaseIterable, Sendable {
        /// Something began (the mic went live, a timer was armed).
        case start
        /// It ended and is being dealt with.
        case stop
        /// It worked.
        case done
        /// It didn't.
        case failed

        public var feedback: SensoryFeedback {
            switch self {
            case .start: .impact(weight: .heavy)
            case .stop: .impact(flexibility: .soft)
            case .done: .success
            case .failed: .error
            }
        }
    }

    /// The live-recording clock, e.g. "1:15".
    public static func clock(_ elapsed: TimeInterval) -> String {
        let total = max(0, Int(elapsed))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Environment

private struct KitIdentityKey: EnvironmentKey {
    static let defaultValue = Kit.Identity.placeholder
}

public extension EnvironmentValues {
    var kitIdentity: Kit.Identity {
        get { self[KitIdentityKey.self] }
        set { self[KitIdentityKey.self] = newValue }
    }
}

public extension View {
    /// Tells the kit which app it is in. Set once, at the root. Sheets get
    /// their own environment, so pass it into those too.
    func kitIdentity(_ identity: Kit.Identity) -> some View {
        environment(\.kitIdentity, identity)
    }

    /// Sets text in one of the suite's type roles.
    func kitFont(_ role: Kit.TypeRole) -> some View {
        modifier(KitFont(role: role))
    }
}

private struct KitFont: ViewModifier {
    let role: Kit.TypeRole
    @ScaledMetric private var size: CGFloat

    init(role: Kit.TypeRole) {
        self.role = role
        _size = ScaledMetric(wrappedValue: role.baseSize, relativeTo: role.textStyle)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: role.weight, design: role.isRounded ? .rounded : .default))
            .kitMonospacedDigit(role == .timer || role == .number)
    }
}

private extension View {
    @ViewBuilder
    func kitMonospacedDigit(_ on: Bool) -> some View {
        if on { self.monospacedDigit() } else { self }
    }
}

// MARK: - Ground

/// The full-screen background. Give it the stage; it fades between them.
public struct KitGround: View {
    private let stage: Kit.Stage
    @Environment(\.kitIdentity) private var identity

    public init(stage: Kit.Stage) {
        self.stage = stage
    }

    public var body: some View {
        LinearGradient(
            colors: Kit.groundColors(hue: identity.hue, stage: stage),
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
        // A colour fade is not motion in the Reduce Motion sense — nothing
        // travels — so it runs either way.
        .animation(.easeInOut(duration: 0.4), value: stage)
    }
}

// MARK: - Orb

/// The app's mark in a glowing disc of its hue. Breathes slowly while the
/// app is waiting for you; perfectly still under Reduce Motion.
public struct KitOrb: View {
    private let diameter: CGFloat
    private let breathes: Bool
    private let markScale: CGFloat

    @Environment(\.kitIdentity) private var identity
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inhale = false

    /// - Parameters:
    ///   - diameter: 132 for a screen's hero; about 64 when something else
    ///     (a number, an intention) is the hero.
    ///   - breathes: pass `false` wherever the orb is not the thing to look
    ///     at, so it never pulls the eye from what is.
    ///   - markScale: the mark's size as a share of the diameter. Leave it
    ///     alone on screen; the app icons use a larger mark so it reads at
    ///     home-screen size.
    public init(diameter: CGFloat = 132, breathes: Bool = true, markScale: CGFloat = 0.42) {
        self.diameter = diameter
        self.breathes = breathes
        self.markScale = markScale
    }

    /// Re-evaluated on every render, so turning Reduce Motion on while the
    /// orb is on screen stills it.
    private var isBreathing: Bool { breathes && !reduceMotion }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.55), identity.hue, identity.hue.opacity(0.55)],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 0, endRadius: diameter * 0.75
                    )
                )
                .shadow(color: identity.hue.opacity(0.7), radius: diameter * 0.28)
            Image(systemName: identity.mark)
                .font(.system(size: diameter * markScale, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isBreathing && inhale ? 1.06 : 1)
        .animation(
            isBreathing ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : nil,
            value: inhale
        )
        .onAppear { inhale = true }
        .accessibilityHidden(true)
    }
}

// MARK: - Listening

/// The live-microphone display: a disc that swells with your voice, rings
/// that pulse outward, and a clock. Under Reduce Motion the rings hold
/// still and the disc keeps its size — the pink ground and the clock
/// already say "recording".
public struct KitListening: View {
    private let level: Float
    private let elapsed: TimeInterval
    private let hint: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    /// - Parameters:
    ///   - level: 0…1 input level.
    ///   - hint: what a tap does now, e.g. "Tap anywhere to stop".
    public init(level: Float, elapsed: TimeInterval, hint: String) {
        self.level = level
        self.elapsed = elapsed
        self.hint = hint
    }

    private var swell: CGFloat { reduceMotion ? 0 : CGFloat(level) * 60 }

    public var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                        .scaleEffect(reduceMotion ? 1.15 + Double(i) * 0.2 : (pulse ? 1.6 + Double(i) * 0.2 : 1))
                        .opacity(reduceMotion ? 0.35 : (pulse ? 0 : 0.6))
                        .animation(
                            reduceMotion ? nil :
                                .easeOut(duration: 1.6).repeatForever(autoreverses: false).delay(Double(i) * 0.4),
                            value: pulse
                        )
                }
                Circle()
                    .fill(.white)
                    .frame(width: 140 + swell, height: 140 + swell)
                    .shadow(color: Kit.Palette.listening.opacity(0.6), radius: 30)
                    .animation(.easeOut(duration: 0.1), value: level)
                Image(systemName: "mic.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Kit.Palette.listening)
            }
            .frame(width: 240, height: 240)
            .onAppear { pulse = true }
            .accessibilityHidden(true)

            Text(Kit.clock(elapsed))
                .kitFont(.timer)
                .foregroundStyle(.white)
                .accessibilityLabel("Recording, \(Int(elapsed)) seconds")
            Text(hint)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Buttons

/// The one main action on a screen: full width, at thumb height, white with
/// a dark label. One per screen — if a second thing wants this style, one of
/// them is not the main action.
public struct KitMainButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(Kit.Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.35)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// The second-most-likely action when a screen really has one (Hold's
/// "Extend"): as wide and as easy to hit as the main button, but outlined,
/// so it never competes with it.
public struct KitSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(configuration.isPressed ? 0.22 : 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.35)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// A secondary action: quiet to look at, but still comfortably readable
/// at arm's length and a full 44-point target to hit.
public struct KitQuietButtonStyle: ButtonStyle {
    private let isDestructive: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(isDestructive ? Kit.Palette.failed : Color.primary)
            .opacity(isEnabled ? (configuration.isPressed ? 0.5 : 0.8) : 0.3)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

public extension ButtonStyle where Self == KitMainButtonStyle {
    static var kitMain: KitMainButtonStyle { KitMainButtonStyle() }
}

public extension ButtonStyle where Self == KitSecondaryButtonStyle {
    static var kitSecondary: KitSecondaryButtonStyle { KitSecondaryButtonStyle() }
}

public extension ButtonStyle where Self == KitQuietButtonStyle {
    static var kitQuiet: KitQuietButtonStyle { KitQuietButtonStyle() }
    /// A quiet action that removes something. Coloured, and kept at the far
    /// end of its row — never beside the main button.
    static var kitQuietDestructive: KitQuietButtonStyle { KitQuietButtonStyle(isDestructive: true) }
}

/// The quiet actions that sit under a main button. Side by side when they
/// fit; stacked when they don't (large text sizes, long labels), so nothing
/// is ever squeezed or clipped.
public struct KitQuietRow<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 24) { content }
            VStack(spacing: 0) { content }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Chip

/// A one-word choice you can switch on or off — a label for a timer, a kind
/// of task. Always optional: nothing in the suite makes you pick one.
public struct KitChip: View {
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                // A chip grows taller before it cuts its own word short:
                // two lines, then a slight shrink, never an ellipsis on a
                // one-word choice at large text sizes.
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(minHeight: 36)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(.white.opacity(isSelected ? 0.9 : 0.12)))
                .foregroundStyle(isSelected ? Kit.Palette.ink : .white)
                // 36 points to look at, 44 to hit.
                .contentShape(Capsule().inset(by: -4))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Pill

/// Says what just happened, briefly, and offers the way back when there is
/// one. Every exit in every app ends in one of these.
public struct KitPill: View {
    public enum Kind: Equatable, Sendable {
        case done, failed, neutral

        public var fill: Color {
            switch self {
            case .done: Kit.Palette.done.opacity(0.9)
            case .failed: Kit.Palette.failed.opacity(0.85)
            case .neutral: Color(white: 0.18).opacity(0.95)
            }
        }

        public var symbol: String? {
            switch self {
            case .done: "checkmark.circle.fill"
            case .failed: "exclamationmark.triangle.fill"
            case .neutral: nil
            }
        }
    }

    private let text: String
    private let kind: Kind
    private let symbol: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    /// - Parameters:
    ///   - symbol: overrides the kind's own symbol (e.g. a trash can on
    ///     "Deleted").
    ///   - actionTitle: a trailing button such as "Undo"; shown only with
    ///     an `action`.
    public init(
        text: String,
        kind: Kind = .neutral,
        symbol: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.kind = kind
        self.symbol = symbol
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 10) {
            if let name = symbol ?? kind.symbol {
                Image(systemName: name)
                    .font(.body.weight(.semibold))
            }
            Text(text)
                .font(.footnote.weight(.medium))
                .lineLimit(2)
                .truncationMode(.middle)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.footnote.weight(.bold))
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 32)
                    .background(Capsule().fill(.white.opacity(0.22)))
                    .contentShape(Capsule().inset(by: -6))
            }
        }
        .foregroundStyle(.white)
        .padding(.leading, 14)
        .padding(.trailing, action == nil ? 14 : 8)
        .padding(.vertical, action == nil ? 10 : 6)
        .background(
            Capsule()
                .fill(kind.fill)
                .shadow(color: .black.opacity(0.22), radius: 6, y: 2)
        )
        .accessibilityElement(children: .contain)
    }
}

public extension AnyTransition {
    /// How a pill arrives and leaves: slides in from its edge, or simply
    /// fades when Reduce Motion is on.
    static func kitPill(from edge: Edge, reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: edge).combined(with: .opacity)
    }
}

// MARK: - Gear

/// Settings: the same icon, in the same corner, in every app.
public struct KitGear: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Settings")
    }
}
