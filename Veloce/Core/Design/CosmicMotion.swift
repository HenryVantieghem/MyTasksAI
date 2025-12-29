//
//  CosmicMotion.swift
//  Veloce
//
//  Cosmic Motion System
//  Refined animation presets - purposeful, not noisy
//
//  Philosophy:
//  - 4 springs cover ALL interaction needs
//  - Continuous animations for living elements only
//  - Motion enhances, never distracts
//

import SwiftUI

// MARK: - Cosmic Motion System

/// Unified motion system with refined, purposeful animations
enum CosmicMotion {

    // MARK: - Spring Presets (Only 4 Needed)

    /// Four springs to rule them all
    enum Springs {

        /// Tap response - instant feedback (0.15s)
        /// Use for: Button taps, toggles, checkbox fills
        static let tap = Animation.spring(response: 0.15, dampingFraction: 0.75)

        /// UI transitions - standard feel (0.25s)
        /// Use for: Navigation, sheet presentations, state changes
        static let ui = Animation.spring(response: 0.25, dampingFraction: 0.7)

        /// Morph transitions - smooth transformations (0.4s)
        /// Use for: Liquid Glass morphing, card expansions, layout changes
        static let morph = Animation.spring(response: 0.4, dampingFraction: 0.75)

        /// Celebrate - bouncy delight (0.35s, less damping)
        /// Use for: Achievements, completions, rare rewards
        static let celebrate = Animation.spring(response: 0.35, dampingFraction: 0.55)

        /// UI bouncy - slightly bouncier version of ui (0.3s)
        /// Use for: Playful UI transitions, fun interactions
        static let uiBouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
    }

    // MARK: - Continuous Animations (Living Elements Only)

    /// Animations that loop - use sparingly
    enum Continuous {

        /// Glow pulse for AI/focus elements (2s cycle)
        static let glowPulse = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

        /// Orb breathing animation (3s cycle)
        static let orbBreath = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)

        /// Ring rotation for loading/processing (6s cycle)
        static let ringRotation = Animation.linear(duration: 6.0).repeatForever(autoreverses: false)

        /// Subtle shimmer for premium elements (4s cycle)
        static let shimmer = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
    }

    // MARK: - Timing Functions

    /// Easing curves for non-spring animations
    enum Easing {

        /// Quick micro-interaction (0.15s)
        static let quick = Animation.easeOut(duration: 0.15)

        /// Standard transition (0.3s)
        static let standard = Animation.easeInOut(duration: 0.3)

        /// Slow reveal (0.5s)
        static let slow = Animation.easeInOut(duration: 0.5)

        /// Dramatic entrance (0.8s)
        static let dramatic = Animation.easeOut(duration: 0.8)
    }

    // MARK: - Stagger Helpers

    /// Stagger delays for sequential animations
    enum Stagger {

        /// Fast stagger between items (0.05s)
        static let fast: Double = 0.05

        /// Standard stagger (0.08s)
        static let standard: Double = 0.08

        /// Slow stagger for dramatic reveals (0.12s)
        static let slow: Double = 0.12

        /// Calculate delay for index in sequence
        static func delay(for index: Int, interval: Double = standard) -> Double {
            Double(index) * interval
        }
    }

    // MARK: - Reduce Motion Support

    /// Check if reduced motion is enabled
    static var reducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Returns appropriate animation respecting accessibility
    static func animation(_ animation: Animation) -> Animation {
        reducedMotion ? .easeInOut(duration: 0.001) : animation
    }

    /// Returns appropriate continuous animation (nil if reduced motion)
    static func continuousAnimation(_ animation: Animation) -> Animation? {
        reducedMotion ? nil : animation
    }
}

// MARK: - View Extensions

extension View {

    /// Apply tap spring animation
    func tapAnimation() -> some View {
        self.animation(CosmicMotion.Springs.tap, value: UUID())
    }

    /// Apply UI spring animation to a value change
    func uiAnimation<V: Equatable>(value: V) -> some View {
        self.animation(CosmicMotion.Springs.ui, value: value)
    }

    /// Apply morph spring animation to a value change
    func morphAnimation<V: Equatable>(value: V) -> some View {
        self.animation(CosmicMotion.Springs.morph, value: value)
    }

    /// Apply celebrate spring animation to a value change
    func celebrateAnimation<V: Equatable>(value: V) -> some View {
        self.animation(CosmicMotion.Springs.celebrate, value: value)
    }

    /// Apply staggered appearance animation
    func staggeredAppearance(index: Int, interval: Double = CosmicMotion.Stagger.standard) -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(CosmicMotion.Springs.ui.delay(CosmicMotion.Stagger.delay(for: index, interval: interval))) {
                    // Animation triggers on appear
                }
            }
    }

    /// Conditional animation respecting Reduce Motion
    func cosmicAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(CosmicMotion.animation(animation), value: value)
    }
}

// MARK: - Button Style with Tap Animation

/// Button style with instant tap feedback
struct CosmicTapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(CosmicMotion.Springs.tap, value: configuration.isPressed)
    }
}

/// Button style with celebrate bounce
struct CosmicCelebrateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(CosmicMotion.Springs.celebrate, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CosmicTapButtonStyle {
    static var cosmicTap: CosmicTapButtonStyle { CosmicTapButtonStyle() }
}

extension ButtonStyle where Self == CosmicCelebrateButtonStyle {
    static var cosmicCelebrate: CosmicCelebrateButtonStyle { CosmicCelebrateButtonStyle() }
}

// MARK: - Transition Presets

extension AnyTransition {

    /// Scale + fade transition using morph spring
    static var cosmicScale: AnyTransition {
        .scale(scale: 0.9)
        .combined(with: .opacity)
    }

    /// Slide up + fade transition
    static var cosmicSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Blur + fade transition for dramatic reveals
    static var cosmicBlur: AnyTransition {
        .opacity.combined(with: .scale(scale: 1.02))
    }
}

// MARK: - Preview

#Preview("Cosmic Motion") {
    VStack(spacing: 32) {
        Text("Motion Presets")
            .font(CosmicWidget.Typography.title2)
            .foregroundStyle(CosmicWidget.Text.primary)

        // Tap button
        Button("Tap Spring") { }
            .buttonStyle(.cosmicTap)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(CosmicWidget.Widget.teal)
            .clipShape(Capsule())
            .foregroundStyle(CosmicWidget.Text.inverse)

        // Celebrate button
        Button("Celebrate Spring") { }
            .buttonStyle(.cosmicCelebrate)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(CosmicWidget.Widget.magenta)
            .clipShape(Capsule())
            .foregroundStyle(CosmicWidget.Text.inverse)

        // Glow pulse demo
        Circle()
            .fill(CosmicWidget.Widget.electricCyan)
            .frame(width: 60, height: 60)
            .shadow(color: CosmicWidget.Widget.electricCyan.opacity(0.6), radius: 20)

        Text("Glow Pulse (2s)")
            .font(CosmicWidget.Typography.caption)
            .foregroundStyle(CosmicWidget.Text.tertiary)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(CosmicWidget.Void.cosmos)
}
