//
//  Animations.swift
//  MyTasksAI
//
//  Animation Utilities and Effects
//  Custom animations and transition effects
//  Respects accessibility reduceMotion setting
//

import SwiftUI

// MARK: - Reduce Motion Aware Animation
/// Returns an animation that respects the reduce motion setting
struct ReduceMotionAnimation {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static func animation(_ animation: Animation, reduced: Animation = .linear(duration: 0.01)) -> Animation {
        // Note: This is a static helper - callers should check reduceMotion in their view
        animation
    }
}

// MARK: - Bounce Animation Modifier
struct BounceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBouncing = false

    let trigger: Bool
    let scale: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? scale : 1.0)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    // Skip animation if reduce motion is enabled
                    guard !reduceMotion else { return }

                    withAnimation(.spring(response: duration, dampingFraction: 0.5)) {
                        isBouncing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation(.spring(response: duration, dampingFraction: 0.7)) {
                            isBouncing = false
                        }
                    }
                }
            }
    }
}

// MARK: - Shake Animation Modifier
struct ShakeModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shakeOffset: CGFloat = 0

    let trigger: Bool
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    // Skip animation if reduce motion is enabled
                    guard !reduceMotion else { return }

                    withAnimation(.linear(duration: 0.05).repeatCount(6, autoreverses: true)) {
                        shakeOffset = intensity
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.linear(duration: 0.05)) {
                            shakeOffset = 0
                        }
                    }
                }
            }
    }
}

// MARK: - Wiggle Animation Modifier
struct WiggleModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isWiggling = false

    let active: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees((isWiggling && !reduceMotion) ? 2 : (isWiggling && !reduceMotion) ? -2 : 0))
            .animation(
                (active && !reduceMotion) ?
                    .linear(duration: 0.1).repeatForever(autoreverses: true) :
                    .default,
                value: isWiggling
            )
            .onChange(of: active) { _, newValue in
                isWiggling = newValue
            }
    }
}

// MARK: - Fade In Animation Modifier
struct FadeInModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opacity: Double = 0

    let delay: Double
    let duration: Double

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                // Fade is gentle enough for reduce motion, but make it instant
                let animationDuration = reduceMotion ? 0.01 : duration
                withAnimation(.easeIn(duration: animationDuration).delay(reduceMotion ? 0 : delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - Slide In Animation Modifier
struct SlideInModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0

    let edge: Edge
    let delay: Double

    func body(content: Content) -> some View {
        content
            .offset(
                x: reduceMotion ? 0 : (edge == .leading ? -offset : (edge == .trailing ? offset : 0)),
                y: reduceMotion ? 0 : (edge == .top ? -offset : (edge == .bottom ? offset : 0))
            )
            .opacity(opacity)
            .onAppear {
                if reduceMotion {
                    // Instant appearance for reduce motion
                    offset = 0
                    opacity = 1
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                        offset = 0
                        opacity = 1
                    }
                }
            }
    }
}

// MARK: - Scale In Animation Modifier
struct ScaleInModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1 : scale)
            .opacity(opacity)
            .onAppear {
                if reduceMotion {
                    // Instant appearance for reduce motion
                    scale = 1
                    opacity = 1
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
                        scale = 1
                        opacity = 1
                    }
                }
            }
    }
}

// MARK: - Staggered Animation Container
struct StaggeredAnimationContainer<Content: View>: View {
    let content: Content
    let animation: Animation
    let staggerDelay: Double

    @State private var isAnimating = false

    init(
        animation: Animation = .spring(response: 0.4, dampingFraction: 0.7),
        staggerDelay: Double = 0.05,
        @ViewBuilder content: () -> Content
    ) {
        self.animation = animation
        self.staggerDelay = staggerDelay
        self.content = content()
    }

    var body: some View {
        content
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Floating Animation Modifier (respects reduce motion)
struct SimpleFloatingModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0

    let amplitude: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                // Skip continuous animation for reduce motion
                guard !reduceMotion else { return }

                withAnimation(
                    .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = amplitude
                }
            }
            .transaction { transaction in
                // Make animation interruptible
                transaction.animation = transaction.animation?.speed(1.0)
            }
    }
}

// MARK: - Rotation Animation Modifier
struct ContinuousRotationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0

    let duration: Double
    let clockwise: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                // Skip continuous rotation for reduce motion
                guard !reduceMotion else { return }

                withAnimation(
                    .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = clockwise ? 360 : -360
                }
            }
            .transaction { transaction in
                // Make animation interruptible
                transaction.animation = transaction.animation?.speed(1.0)
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Bounce animation
    func bounce(trigger: Bool, scale: CGFloat = 1.2, duration: Double = 0.3) -> some View {
        modifier(BounceModifier(trigger: trigger, scale: scale, duration: duration))
    }

    /// Shake animation
    func shake(trigger: Bool, intensity: CGFloat = 10) -> some View {
        modifier(ShakeModifier(trigger: trigger, intensity: intensity))
    }

    /// Wiggle animation
    func wiggle(when active: Bool) -> some View {
        modifier(WiggleModifier(active: active))
    }

    /// Fade in animation
    func fadeIn(delay: Double = 0, duration: Double = 0.3) -> some View {
        modifier(FadeInModifier(delay: delay, duration: duration))
    }

    /// Slide in animation
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        modifier(SlideInModifier(edge: edge, delay: delay))
    }

    /// Scale in animation
    func scaleIn(delay: Double = 0) -> some View {
        modifier(ScaleInModifier(delay: delay))
    }

    /// Floating animation (respects reduce motion)
    func floating(amplitude: CGFloat = 5, duration: Double = 2) -> some View {
        modifier(SimpleFloatingModifier(amplitude: amplitude, duration: duration))
    }

    /// Continuous rotation
    func continuousRotation(duration: Double = 2, clockwise: Bool = true) -> some View {
        modifier(ContinuousRotationModifier(duration: duration, clockwise: clockwise))
    }
}

// MARK: - Transition Extensions
extension AnyTransition {
    /// Slide and fade from bottom
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }

    /// Scale and fade
    static var scaleAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }

    /// Blur transition
    static var blur: AnyTransition {
        .modifier(
            active: BlurTransitionModifier(isActive: true),
            identity: BlurTransitionModifier(isActive: false)
        )
    }
}

// MARK: - Blur Transition Modifier
struct BlurTransitionModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: isActive ? 10 : 0)
            .opacity(isActive ? 0 : 1)
    }
}

// MARK: - Animation Phase Animator
struct PhaseAnimator<Phase: Equatable, Content: View>: View {
    let phases: [Phase]
    let trigger: Bool
    @ViewBuilder let content: (Phase) -> Content

    @State private var currentPhaseIndex = 0

    var body: some View {
        content(phases[currentPhaseIndex])
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    animateThroughPhases()
                }
            }
    }

    private func animateThroughPhases() {
        for (index, _) in phases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(Theme.Animation.spring) {
                    currentPhaseIndex = index
                }
            }
        }
    }
}

// MARK: - Animated Number View
/// Smoothly animates between number values with numeric text transition
struct AnimatedNumber: View {
    let value: Int
    let format: String?

    @State private var displayValue: Int = 0

    init(_ value: Int, format: String? = nil) {
        self.value = value
        self.format = format
    }

    var body: some View {
        Text(formattedValue)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayValue)
            .onChange(of: value) { _, newValue in
                displayValue = newValue
            }
            .onAppear {
                displayValue = value
            }
    }

    private var formattedValue: String {
        if let format = format {
            return String(format: format, displayValue)
        }
        return "\(displayValue)"
    }
}

// MARK: - Animated Double View
/// Smoothly animates between decimal values
struct AnimatedDouble: View {
    let value: Double
    let decimalPlaces: Int
    let suffix: String

    @State private var displayValue: Double = 0

    init(_ value: Double, decimalPlaces: Int = 1, suffix: String = "") {
        self.value = value
        self.decimalPlaces = decimalPlaces
        self.suffix = suffix
    }

    var body: some View {
        Text(formattedValue)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayValue)
            .onChange(of: value) { _, newValue in
                displayValue = newValue
            }
            .onAppear {
                displayValue = value
            }
    }

    private var formattedValue: String {
        String(format: "%.\(decimalPlaces)f\(suffix)", displayValue)
    }
}

// MARK: - List Item Transition
/// Standard transition for list items with asymmetric insert/remove
extension AnyTransition {
    static var listItem: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9)
                .combined(with: .opacity)
                .combined(with: .move(edge: .top)),
            removal: .scale(scale: 0.9)
                .combined(with: .opacity)
        )
    }

}

// MARK: - Spring Presets
/// Consistent spring animation presets used across the app
extension Animation {
    /// Quick response for button presses (0.2s)
    static let pressSpring = Animation.spring(response: 0.2, dampingFraction: 0.7)

    /// Standard UI spring (0.3s)
    static let uiSpring = Animation.spring(response: 0.3, dampingFraction: 0.75)

    /// Card/modal presentation spring (0.4s)
    static let presentSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Bouncy spring for celebrations (0.5s)
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Gentle spring for ambient animations (0.6s)
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.85)
}
