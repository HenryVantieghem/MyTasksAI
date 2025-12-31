//
//  AuroraMotion.swift
//  Veloce
//
//  Aurora Motion System - Fluid, Spring-Based Animation Language
//  "Everything flows, nothing snaps"
//

import SwiftUI

// MARK: - Aurora Motion System

/// The motion language for Aurora Design System
/// Built on spring physics for organic, fluid animations
public enum AuroraMotion {

    // MARK: - Spring Presets

    /// Spring animation presets for consistent motion feel
    public enum Spring {

        /// Liquid Snap - Instant feedback (0.15s)
        /// Use for: Tap feedback, button press, micro-interactions
        public static let liquidSnap = Animation.spring(response: 0.15, dampingFraction: 0.85)

        /// UI Standard - Standard transitions (0.25s)
        /// Use for: Most UI transitions, state changes
        public static let ui = Animation.spring(response: 0.25, dampingFraction: 0.75)

        /// Fluid Morph - Smooth transformations (0.35s)
        /// Use for: Shape morphing, expand/collapse
        public static let fluidMorph = Animation.spring(response: 0.35, dampingFraction: 0.70)

        /// Sheet - Modal presentations (0.4s)
        /// Use for: Sheets, drawers, overlays
        public static let sheet = Animation.spring(response: 0.40, dampingFraction: 0.72)

        /// Focus - Card expansion, detail views (0.5s)
        /// Use for: Task detail open, card expand
        public static let focus = Animation.spring(response: 0.50, dampingFraction: 0.70)

        /// Deep Breath - Ambient pulse (0.6s)
        /// Use for: Idle state breathing, gentle transitions
        public static let deepBreath = Animation.spring(response: 0.60, dampingFraction: 0.75)

        /// Elastic Bounce - Celebration bounce (0.35s, less damping)
        /// Use for: Completions, achievements, success
        public static let elasticBounce = Animation.spring(response: 0.35, dampingFraction: 0.55)

        /// Bouncy - Playful delight (0.4s, low damping)
        /// Use for: Level up, milestones, special moments
        public static let bouncy = Animation.spring(response: 0.40, dampingFraction: 0.50)

        /// Gentle - Subtle, refined (0.5s, high damping)
        /// Use for: Background elements, subtle state changes
        public static let gentle = Animation.spring(response: 0.50, dampingFraction: 0.85)

        /// Portal - Dramatic opening (0.6s)
        /// Use for: Portal animations, major transitions
        public static let portal = Animation.spring(response: 0.60, dampingFraction: 0.65)

        /// Morph - Smooth shape transformations
        /// Use for: Card morphing, state transitions
        public static let morph = Animation.spring(response: 0.4, dampingFraction: 0.7)
    }

    // MARK: - Timing Curves

    /// Easing curves for non-spring animations
    public enum Easing {

        /// Smooth ease in-out
        public static let smooth = Animation.easeInOut(duration: 0.3)

        /// Quick ease out (for reveals)
        public static let quickOut = Animation.easeOut(duration: 0.2)

        /// Slow ease in (for fades)
        public static let slowIn = Animation.easeIn(duration: 0.4)

        /// Linear (for continuous rotation)
        public static let linear = Animation.linear
    }

    // MARK: - Durations

    /// Standard duration constants
    public enum Duration {

        /// Instant - 0.1s
        public static let instant: Double = 0.1

        /// Quick - 0.15s
        public static let quick: Double = 0.15

        /// Fast - 0.2s
        public static let fast: Double = 0.2

        /// Standard - 0.3s
        public static let standard: Double = 0.3

        /// Medium - 0.4s
        public static let medium: Double = 0.4

        /// Slow - 0.5s
        public static let slow: Double = 0.5

        /// Relaxed - 0.6s
        public static let relaxed: Double = 0.6

        /// Portal - 2.0s (major transitions)
        public static let portal: Double = 2.0

        // MARK: Continuous Animation Cycles

        /// Breathing cycle - 2.5s
        public static let breathingCycle: Double = 2.5

        /// Glow pulse cycle - 2.0s
        public static let glowPulse: Double = 2.0

        /// Shimmer sweep - 3.0s
        public static let shimmerSweep: Double = 3.0

        /// Aurora wave - 12-25s (varies by layer)
        public static let auroraWaveFast: Double = 12.0
        public static let auroraWaveMedium: Double = 18.0
        public static let auroraWaveSlow: Double = 25.0

        /// Prismatic border rotation - 12s
        public static let prismaticRotation: Double = 12.0

        /// Orb color shift - 8s
        public static let orbColorShift: Double = 8.0

        /// Rim rotation - 20s
        public static let rimRotation: Double = 20.0

        /// Particle float - 5s
        public static let particleFloat: Double = 5.0
    }

    // MARK: - Delays

    /// Stagger delay constants
    public enum Delay {

        /// Micro stagger - 20ms
        public static let micro: Double = 0.02

        /// Small stagger - 50ms
        public static let small: Double = 0.05

        /// Standard stagger - 80ms
        public static let standard: Double = 0.08

        /// Medium stagger - 100ms
        public static let medium: Double = 0.10

        /// Large stagger - 150ms
        public static let large: Double = 0.15

        /// Section stagger - 200ms
        public static let section: Double = 0.20
    }

    // MARK: - Scale Values

    /// Scale constants for press/hover effects
    public enum Scale {

        /// Pressed state - 0.96
        public static let pressed: CGFloat = 0.96

        /// Subtle press - 0.98
        public static let subtlePress: CGFloat = 0.98

        /// Bounce peak - 1.05
        public static let bouncePeak: CGFloat = 1.05

        /// Celebration burst - 1.15
        public static let celebrationBurst: CGFloat = 1.15

        /// Major burst - 1.25
        public static let majorBurst: CGFloat = 1.25

        /// Portal expansion - 1.5
        public static let portalExpansion: CGFloat = 1.5
    }
}

// MARK: - View Modifiers for Motion

extension View {

    /// Apply staggered entry animation
    /// - Parameters:
    ///   - index: Item index in list
    ///   - baseDelay: Base delay before first item
    ///   - staggerDelay: Delay between items
    func staggeredEntry(
        index: Int,
        baseDelay: Double = 0,
        staggerDelay: Double = AuroraMotion.Delay.standard
    ) -> some View {
        self
            .animation(
                AuroraMotion.Spring.ui.delay(baseDelay + Double(index) * staggerDelay),
                value: index
            )
    }

    /// Apply breathing animation (continuous subtle pulse)
    func breathing(
        intensity: CGFloat = 0.03,
        duration: Double = AuroraMotion.Duration.breathingCycle
    ) -> some View {
        self.modifier(BreathingModifier(intensity: intensity, duration: duration))
    }

    /// Apply floating animation (vertical bob)
    func floating(
        amplitude: CGFloat = 8,
        duration: Double = 3.0
    ) -> some View {
        self.modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }

    /// Apply pulse glow animation
    func pulsingGlow(
        color: Color,
        minIntensity: CGFloat = 0.2,
        maxIntensity: CGFloat = 0.5,
        duration: Double = AuroraMotion.Duration.glowPulse
    ) -> some View {
        self.modifier(PulsingGlowModifier(
            color: color,
            minIntensity: minIntensity,
            maxIntensity: maxIntensity,
            duration: duration
        ))
    }

    /// Apply press scale effect
    func pressScale(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? AuroraMotion.Scale.pressed : 1.0)
            .animation(AuroraMotion.Spring.liquidSnap, value: isPressed)
    }

    /// Apply celebration bounce
    func celebrationBounce(trigger: Bool) -> some View {
        self.modifier(CelebrationBounceModifier(trigger: trigger))
    }

    /// Apply continuous rotation
    func continuousRotation(
        duration: Double = AuroraMotion.Duration.prismaticRotation,
        clockwise: Bool = true
    ) -> some View {
        self.modifier(ContinuousRotationModifier(duration: duration, clockwise: clockwise))
    }
}

// MARK: - Breathing Modifier

struct BreathingModifier: ViewModifier {
    let intensity: CGFloat
    let duration: Double

    @State private var isBreathing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? 1 + intensity : 1 - intensity * 0.5)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isBreathing = true
                }
            }
    }
}

// MARK: - Floating Modifier

struct FloatingModifier: ViewModifier {
    let amplitude: CGFloat
    let duration: Double

    @State private var isFloating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating = true
                }
            }
    }
}

// MARK: - Pulsing Glow Modifier

struct PulsingGlowModifier: ViewModifier {
    let color: Color
    let minIntensity: CGFloat
    let maxIntensity: CGFloat
    let duration: Double

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isPulsing ? maxIntensity : minIntensity),
                radius: isPulsing ? 20 : 12,
                x: 0,
                y: isPulsing ? 6 : 4
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Celebration Bounce Modifier

struct CelebrationBounceModifier: ViewModifier {
    let trigger: Bool

    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    // Burst up
                    withAnimation(AuroraMotion.Spring.elasticBounce) {
                        scale = AuroraMotion.Scale.celebrationBurst
                    }
                    // Settle back
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(AuroraMotion.Spring.ui) {
                            scale = 1.0
                        }
                    }
                }
            }
    }
}

// MARK: - Continuous Rotation Modifier

struct ContinuousRotationModifier: ViewModifier {
    let duration: Double
    let clockwise: Bool

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = clockwise ? 360 : -360
                }
            }
    }
}

// MARK: - Transition Extensions

extension AnyTransition {

    /// Aurora scale + fade transition
    static var auroraScale: AnyTransition {
        .scale(scale: 0.85)
        .combined(with: .opacity)
    }

    /// Aurora slide up transition
    static var auroraSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Aurora blur transition
    static var auroraBlur: AnyTransition {
        .modifier(
            active: BlurTransitionModifier(blur: 10, opacity: 0),
            identity: BlurTransitionModifier(blur: 0, opacity: 1)
        )
    }

    /// Portal warp transition (for major screen changes)
    static var portalWarp: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.5).combined(with: .opacity),
            removal: .scale(scale: 1.5).combined(with: .opacity)
        )
    }

    /// Constellation appear (scale from point)
    static var constellationAppear: AnyTransition {
        .scale(scale: 0.1, anchor: .center)
        .combined(with: .opacity)
    }
}

// MARK: - Blur Transition Modifier

struct BlurTransitionModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
    }
}

// MARK: - Haptic Feedback Integration

public enum AuroraHaptics {

    /// Light tap feedback
    public static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact (button press)
    public static func impact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Soft impact (subtle feedback)
    public static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Rigid impact (sharp, precise)
    public static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    /// Selection changed
    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Success notification
    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning notification
    public static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error notification
    public static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Dopamine burst sequence (task completion)
    public static func dopamineBurst() {
        // Initial press
        soft()

        // Burst after 100ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            success()
        }

        // Cascade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tap()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            tap()
        }
    }

    /// Portal opening sequence
    public static func portalOpen() {
        // Build up
        soft()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            impact()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            rigid()
        }

        // Breakthrough
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            success()
        }
    }

    /// Celebration cascade (level up, milestone)
    public static func celebration() {
        success()

        // Sparkle cascade
        for i in 1...4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                tap()
            }
        }

        // Final burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            success()
        }
    }

    /// Recording pulse (for voice input)
    public static func recordingPulse() {
        soft()
    }

    /// AI processing tick
    public static func aiTick() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
    }

    // MARK: - Convenience Aliases

    /// Light feedback (alias for tap)
    public static func light() {
        tap()
    }

    /// Medium feedback (alias for impact)
    public static func medium() {
        impact()
    }

    /// Light impact (alias)
    public static func lightImpact() {
        tap()
    }

    /// Medium impact (alias)
    public static func mediumImpact() {
        impact()
    }

    /// Light flutter effect
    public static func lightFlutter() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                tap()
            }
        }
    }
}

// MARK: - Preview

#Preview("Motion Examples") {
    VStack(spacing: 40) {
        // Breathing
        RoundedRectangle(cornerRadius: 16)
            .fill(Aurora.Colors.electricCyan)
            .frame(width: 100, height: 100)
            .breathing()
            .overlay(Text("Breathing").foregroundStyle(.white))

        // Floating
        Circle()
            .fill(Aurora.Colors.borealisViolet)
            .frame(width: 60, height: 60)
            .floating()
            .overlay(Text("Float").font(.caption).foregroundStyle(.white))

        // Pulsing Glow
        RoundedRectangle(cornerRadius: 12)
            .fill(Aurora.Colors.voidNebula)
            .frame(width: 120, height: 50)
            .pulsingGlow(color: Aurora.Colors.electricCyan)
            .overlay(Text("Glow").foregroundStyle(.white))

        // Continuous Rotation
        Image(systemName: "sparkle")
            .dynamicTypeFont(base: 40)
            .foregroundStyle(Aurora.Colors.cosmicGold)
            .continuousRotation(duration: 4)
    }
    .padding(40)
    .background(Aurora.Colors.voidCosmos)
}
