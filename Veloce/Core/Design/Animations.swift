//
//  Animations.swift
//  MyTasksAI
//
//  Animation Utilities and Effects
//  Custom animations and transition effects
//

import SwiftUI

// MARK: - Bounce Animation Modifier
struct BounceModifier: ViewModifier {
    @State private var isBouncing = false

    let trigger: Bool
    let scale: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? scale : 1.0)
            .onChange(of: trigger) { _, newValue in
                if newValue {
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
    @State private var shakeOffset: CGFloat = 0

    let trigger: Bool
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
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
    @State private var isWiggling = false

    let active: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isWiggling ? 2 : -2))
            .animation(
                active ?
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
    @State private var opacity: Double = 0

    let delay: Double
    let duration: Double

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - Slide In Animation Modifier
struct SlideInModifier: ViewModifier {
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0

    let edge: Edge
    let delay: Double

    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? -offset : (edge == .trailing ? offset : 0),
                y: edge == .top ? -offset : (edge == .bottom ? offset : 0)
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - Scale In Animation Modifier
struct ScaleInModifier: ViewModifier {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
                    scale = 1
                    opacity = 1
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

// MARK: - Floating Animation Modifier
struct FloatingModifier: ViewModifier {
    @State private var offset: CGFloat = 0

    let amplitude: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = amplitude
                }
            }
    }
}

// MARK: - Rotation Animation Modifier
struct ContinuousRotationModifier: ViewModifier {
    @State private var rotation: Double = 0

    let duration: Double
    let clockwise: Bool

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

    /// Floating animation
    func floating(amplitude: CGFloat = 5, duration: Double = 2) -> some View {
        modifier(FloatingModifier(amplitude: amplitude, duration: duration))
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
