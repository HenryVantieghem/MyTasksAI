//
//  LiquidGlassDesignSystem.swift
//  Veloce
//
//  Ultra-Premium Liquid Glass Design System
//  iOS 26 Liquid Glass tokens with vibrant "pop" colors
//  and choreographed animation timings.
//

import SwiftUI

// MARK: - Liquid Glass Design System

enum LiquidGlassDesignSystem {

    // MARK: - Vibrant Accent Colors (Enhanced "Pop")

    /// Vibrant accent colors designed to "pop" against dark void backgrounds
    /// while maintaining sophistication and premium feel
    enum VibrantAccents {
        /// Electric Cyan - Primary action color, ultra-bright cyan energy
        static let electricCyan = Color(red: 0.0, green: 0.95, blue: 1.0)

        /// Plasma Purple - AI/Premium accent, rich vivid purple
        static let plasmaPurple = Color(red: 0.65, green: 0.25, blue: 1.0)

        /// Aurora Green - Success states, vibrant organic green
        static let auroraGreen = Color(red: 0.15, green: 1.0, blue: 0.65)

        /// Solar Gold - Warmth/Achievement, rich warm gold
        static let solarGold = Color(red: 1.0, green: 0.85, blue: 0.25)

        /// Nebula Pink - Energy/Celebration, vivid pink
        static let nebulaPink = Color(red: 1.0, green: 0.45, blue: 0.75)

        /// Cosmic Blue - Deep interactive blue
        static let cosmicBlue = Color(red: 0.25, green: 0.55, blue: 1.0)

        /// Stellar White - Pure highlight white
        static let stellarWhite = Color(red: 1.0, green: 0.98, blue: 0.95)
    }

    // MARK: - Glass Tint Presets

    /// Tint colors for `.glassEffect(.regular.tint(color))` usage
    enum GlassTints {
        /// Primary purple tint for default glass elements
        static let primary = Color.purple.opacity(0.15)

        /// Success green tint for validated/completed states
        static let success = Color.green.opacity(0.12)

        /// Interactive cyan tint for focused/active states
        static let interactive = Color.cyan.opacity(0.10)

        /// Elevated white tint for prominent elements
        static let elevated = Color.white.opacity(0.08)

        /// Error red tint for validation errors
        static let error = Color.red.opacity(0.12)

        /// Warning amber tint for caution states
        static let warning = Color.orange.opacity(0.10)

        /// Neutral tint for subtle glass
        static let neutral = Color.white.opacity(0.05)
    }

    // MARK: - Gradient Presets

    /// Premium gradients for buttons and backgrounds
    enum Gradients {
        /// Primary CTA gradient (cyan to purple)
        static let ctaPrimary = LinearGradient(
            colors: [
                Color(red: 0.0, green: 0.85, blue: 1.0),
                Color(red: 0.55, green: 0.25, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Success gradient (green to cyan)
        static let success = LinearGradient(
            colors: [
                Color(red: 0.15, green: 1.0, blue: 0.65),
                Color(red: 0.0, green: 0.85, blue: 0.95)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// AI/Premium gradient (purple to blue)
        static let aiPremium = LinearGradient(
            colors: [
                Color(red: 0.65, green: 0.25, blue: 1.0),
                Color(red: 0.35, green: 0.45, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Warm celebration gradient (gold to pink)
        static let celebration = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.85, blue: 0.25),
                Color(red: 1.0, green: 0.45, blue: 0.75)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// Prismatic border gradient (rotating iridescent)
        static func prismaticBorder(rotation: Double = 0) -> AngularGradient {
            AngularGradient(
                colors: [
                    Color(red: 0.55, green: 0.35, blue: 1.0),   // Deep violet
                    Color(red: 0.35, green: 0.55, blue: 1.0),   // Electric blue
                    Color(red: 0.25, green: 0.85, blue: 0.95),  // Cyan plasma
                    Color(red: 0.55, green: 0.95, blue: 0.85),  // Seafoam
                    Color(red: 0.95, green: 0.55, blue: 0.85),  // Rose quartz
                    Color(red: 0.55, green: 0.35, blue: 1.0)    // Back to violet
                ],
                center: .center,
                startAngle: .degrees(rotation),
                endAngle: .degrees(rotation + 360)
            )
        }

        /// Glass border gradient (subtle white fade)
        static let glassBorder = LinearGradient(
            colors: [
                Color.white.opacity(0.28),
                Color.white.opacity(0.12),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Animation Choreography

    /// Precise timing for glass morphing animations
    enum MorphAnimation {
        /// Splash to Auth transition duration
        static let splashToAuth: Double = 0.8

        /// Auth screen switch (SignIn ↔ SignUp)
        static let authScreenSwitch: Double = 0.5

        /// Onboarding page transition
        static let onboardingTransition: Double = 0.6

        /// Glass appear/disappear
        static let glassAppear: Double = 0.4

        /// Orb morph between states
        static let orbMorph: Double = 0.7

        /// Field focus animation
        static let fieldFocus: Double = 0.3

        /// Button press feedback
        static let buttonPress: Double = 0.15

        /// Validation state change
        static let validationChange: Double = 0.25

        /// Stagger delay between elements
        static let staggerDelay: Double = 0.08

        /// Prismatic border rotation cycle
        static let prismaticRotation: Double = 8.0

        /// Shimmer sweep duration
        static let shimmerSweep: Double = 3.0

        /// Glow pulse cycle
        static let glowPulse: Double = 2.0
    }

    // MARK: - Spring Configurations

    /// Pre-configured springs for glass animations
    enum Springs {
        /// Quick press feedback spring
        static let press = Animation.spring(response: 0.2, dampingFraction: 0.9)

        /// Standard UI spring
        static let ui = Animation.spring(response: 0.35, dampingFraction: 0.8)

        /// Morphing transition spring
        static let morph = Animation.spring(response: 0.5, dampingFraction: 0.75)

        /// Bouncy celebration spring
        static let bouncy = Animation.spring(response: 0.55, dampingFraction: 0.65)

        /// Gentle ambient spring
        static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.85)

        /// Snappy focus spring
        static let focus = Animation.spring(response: 0.3, dampingFraction: 0.78)

        /// Reveal animation spring (for dramatic entrances)
        static let reveal = Animation.spring(response: 0.6, dampingFraction: 0.7)
    }

    // MARK: - Glass Configuration

    /// Glass effect configuration values
    enum GlassConfig {
        /// Border opacity at rest
        static let borderOpacityRest: Double = 0.25

        /// Border opacity when focused
        static let borderOpacityFocused: Double = 0.45

        /// Border opacity when pressed
        static let borderOpacityPressed: Double = 0.55

        /// Standard border width
        static let borderWidth: CGFloat = 0.75

        /// Enhanced border width for focus
        static let borderWidthFocused: CGFloat = 1.0

        /// Inner highlight opacity
        static let innerHighlight: Double = 0.08

        /// Shadow blur for glass cards
        static let shadowBlur: CGFloat = 20

        /// Shadow opacity for glass cards
        static let shadowOpacity: Double = 0.25

        /// Glow intensity at rest
        static let glowIntensityRest: Double = 0.3

        /// Glow intensity when active
        static let glowIntensityActive: Double = 0.6

        /// Glow blur radius
        static let glowBlurRadius: CGFloat = 24
    }

    // MARK: - Component Sizing

    /// Standard sizes for glass components
    enum Sizing {
        /// Standard button height
        static let buttonHeight: CGFloat = 56

        /// Compact button height
        static let buttonHeightCompact: CGFloat = 44

        /// Text field height
        static let textFieldHeight: CGFloat = 56

        /// Icon container size
        static let iconContainer: CGFloat = 40

        /// Progress node size
        static let progressNode: CGFloat = 16

        /// Progress node size (current)
        static let progressNodeCurrent: CGFloat = 20

        /// Standard corner radius
        static let cornerRadius: CGFloat = 16

        /// Button corner radius
        static let buttonCornerRadius: CGFloat = 14

        /// Card corner radius
        static let cardCornerRadius: CGFloat = 20

        /// Pill corner radius
        static let pillCornerRadius: CGFloat = 999
    }

    // MARK: - Spacing

    /// Spacing values for glass layouts
    enum Spacing {
        /// Tight spacing (4pt)
        static let tight: CGFloat = 4

        /// Compact spacing (8pt)
        static let compact: CGFloat = 8

        /// Standard spacing (12pt)
        static let standard: CGFloat = 12

        /// Comfortable spacing (16pt)
        static let comfortable: CGFloat = 16

        /// Relaxed spacing (24pt)
        static let relaxed: CGFloat = 24

        /// Generous spacing (32pt)
        static let generous: CGFloat = 32

        /// Form field spacing
        static let formField: CGFloat = 16

        /// Section spacing
        static let section: CGFloat = 28
    }
}

// MARK: - Glass Style Enum

/// Glass effect styles for components
enum LiquidGlassStyle {
    case regular
    case elevated
    case subtle
    case interactive
    case focused
    case error
    case success

    var tint: Color {
        switch self {
        case .regular:
            return LiquidGlassDesignSystem.GlassTints.primary
        case .elevated:
            return LiquidGlassDesignSystem.GlassTints.elevated
        case .subtle:
            return LiquidGlassDesignSystem.GlassTints.neutral
        case .interactive:
            return LiquidGlassDesignSystem.GlassTints.interactive
        case .focused:
            return LiquidGlassDesignSystem.GlassTints.interactive
        case .error:
            return LiquidGlassDesignSystem.GlassTints.error
        case .success:
            return LiquidGlassDesignSystem.GlassTints.success
        }
    }

    var borderOpacity: Double {
        switch self {
        case .regular, .subtle:
            return LiquidGlassDesignSystem.GlassConfig.borderOpacityRest
        case .elevated, .interactive:
            return LiquidGlassDesignSystem.GlassConfig.borderOpacityFocused
        case .focused:
            return LiquidGlassDesignSystem.GlassConfig.borderOpacityFocused
        case .error, .success:
            return LiquidGlassDesignSystem.GlassConfig.borderOpacityPressed
        }
    }

    var glowIntensity: Double {
        switch self {
        case .regular, .subtle:
            return 0
        case .elevated:
            return 0.2
        case .interactive, .focused:
            return LiquidGlassDesignSystem.GlassConfig.glowIntensityRest
        case .error, .success:
            return LiquidGlassDesignSystem.GlassConfig.glowIntensityActive
        }
    }
}

// MARK: - Button Style Enum

/// Button styles for LiquidGlassButton
enum LiquidGlassButtonStyle {
    case primary      // Gradient fill + glass overlay + glow
    case secondary    // Glass with prismatic border
    case ghost        // Transparent + border only
    case success      // Green tinted glass + glow
    case destructive  // Red tinted glass

    var usesGradient: Bool {
        switch self {
        case .primary, .success:
            return true
        case .secondary, .ghost, .destructive:
            return false
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .primary:
            return LiquidGlassDesignSystem.Gradients.ctaPrimary
        case .success:
            return LiquidGlassDesignSystem.Gradients.success
        case .secondary, .ghost:
            return LiquidGlassDesignSystem.Gradients.aiPremium
        case .destructive:
            return LinearGradient(
                colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var tint: Color {
        switch self {
        case .primary:
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        case .secondary:
            return LiquidGlassDesignSystem.GlassTints.primary
        case .ghost:
            return .clear
        case .success:
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        case .destructive:
            return Color.red.opacity(0.15)
        }
    }

    var glowColor: Color {
        switch self {
        case .primary:
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        case .secondary:
            return LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
        case .ghost:
            return .clear
        case .success:
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        case .destructive:
            return Color.red
        }
    }
}

// MARK: - Validation State

/// Validation state for form fields
enum GlassValidationState: Equatable {
    case idle
    case validating
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var message: String? {
        if case .invalid(let msg) = self { return msg }
        return nil
    }

    var tint: Color {
        switch self {
        case .idle:
            return LiquidGlassDesignSystem.GlassTints.primary
        case .validating:
            return LiquidGlassDesignSystem.GlassTints.interactive
        case .valid:
            return LiquidGlassDesignSystem.GlassTints.success
        case .invalid:
            return LiquidGlassDesignSystem.GlassTints.error
        }
    }

    var iconName: String? {
        switch self {
        case .idle:
            return nil
        case .validating:
            return "ellipsis"
        case .valid:
            return "checkmark.circle.fill"
        case .invalid:
            return "exclamationmark.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .idle:
            return .clear
        case .validating:
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        case .valid:
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        case .invalid:
            return Color.red
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply vibrant glow effect with specified color
    func vibrantGlow(
        color: Color,
        intensity: Double = 0.5,
        radius: CGFloat = 20
    ) -> some View {
        self.shadow(
            color: color.opacity(intensity),
            radius: radius,
            x: 0,
            y: 0
        )
    }

    /// Apply prismatic animated border
    func prismaticBorder(
        rotation: Double,
        lineWidth: CGFloat = 1.0,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LiquidGlassDesignSystem.Gradients.prismaticBorder(rotation: rotation),
                    lineWidth: lineWidth
                )
        )
    }

    /// Apply standard glass border
    func glassBorder(
        opacity: Double = 0.25,
        lineWidth: CGFloat = 0.75,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(opacity),
                            Color.white.opacity(opacity * 0.4),
                            Color.white.opacity(opacity * 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
        )
    }
}

// MARK: - Preview

#Preview("Vibrant Colors") {
    ZStack {
        Theme.CelestialColors.voidDeep
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Vibrant Accents")
                .font(.title2.bold())
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                colorSwatch(LiquidGlassDesignSystem.VibrantAccents.electricCyan, "Cyan")
                colorSwatch(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple, "Purple")
                colorSwatch(LiquidGlassDesignSystem.VibrantAccents.auroraGreen, "Green")
            }

            HStack(spacing: 16) {
                colorSwatch(LiquidGlassDesignSystem.VibrantAccents.solarGold, "Gold")
                colorSwatch(LiquidGlassDesignSystem.VibrantAccents.nebulaPink, "Pink")
                colorSwatch(LiquidGlassDesignSystem.VibrantAccents.cosmicBlue, "Blue")
            }

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical)

            Text("Gradients")
                .font(.title2.bold())
                .foregroundStyle(.white)

            RoundedRectangle(cornerRadius: 12)
                .fill(LiquidGlassDesignSystem.Gradients.ctaPrimary)
                .frame(height: 50)
                .overlay(Text("CTA Primary").foregroundStyle(.white))

            RoundedRectangle(cornerRadius: 12)
                .fill(LiquidGlassDesignSystem.Gradients.success)
                .frame(height: 50)
                .overlay(Text("Success").foregroundStyle(.white))

            RoundedRectangle(cornerRadius: 12)
                .fill(LiquidGlassDesignSystem.Gradients.aiPremium)
                .frame(height: 50)
                .overlay(Text("AI Premium").foregroundStyle(.white))
        }
        .padding()
    }
}

@ViewBuilder
private func colorSwatch(_ color: Color, _ name: String) -> some View {
    VStack(spacing: 8) {
        Circle()
            .fill(color)
            .frame(width: 50, height: 50)
            .shadow(color: color.opacity(0.5), radius: 10)

        Text(name)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
    }
}
