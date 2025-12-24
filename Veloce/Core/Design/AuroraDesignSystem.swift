//
//  AuroraDesignSystem.swift
//  Veloce
//
//  Aurora Design System
//  A premium ethereal aesthetic with flowing aurora effects
//  and crystalline glass morphism for auth & onboarding
//

import SwiftUI

// MARK: - Aurora Design System

/// Central namespace for the Celestial Aurora design language
enum Aurora {

    // MARK: - Colors

    enum Colors {

        // MARK: Aurora Palette - Rich, Vibrant Gradients

        /// Deep violet - primary aurora color
        static let violet = Color(red: 0.48, green: 0.12, blue: 0.74)

        /// Rich purple - secondary aurora
        static let purple = Color(red: 0.58, green: 0.22, blue: 0.88)

        /// Electric blue - accent aurora
        static let electric = Color(red: 0.24, green: 0.56, blue: 0.98)

        /// Bright cyan - highlight aurora
        static let cyan = Color(red: 0.14, green: 0.82, blue: 0.94)

        /// Fresh emerald - tertiary aurora
        static let emerald = Color(red: 0.20, green: 0.85, blue: 0.64)

        /// Warm rose - accent for warmth
        static let rose = Color(red: 0.98, green: 0.36, blue: 0.64)

        /// Soft gold - premium accent
        static let gold = Color(red: 1.0, green: 0.84, blue: 0.40)

        // MARK: Cosmic Backgrounds - True Blacks That Render Colors Properly

        /// Pure cosmic black with slight blue tint
        static let cosmicBlack = Color(red: 0.02, green: 0.02, blue: 0.04)

        /// Deep cosmic for layering
        static let cosmicDeep = Color(red: 0.03, green: 0.03, blue: 0.06)

        /// Surface layer for cards
        static let cosmicSurface = Color(red: 0.06, green: 0.06, blue: 0.10)

        /// Elevated surface for prominent elements
        static let cosmicElevated = Color(red: 0.08, green: 0.08, blue: 0.14)

        // MARK: Glass Effect Colors

        /// Base glass fill - subtle white
        static let glassBase = Color.white.opacity(0.03)

        /// Glass fill when focused/active
        static let glassFocused = Color.white.opacity(0.06)

        /// Glass border default
        static let glassBorder = Color.white.opacity(0.10)

        /// Glass border focused
        static let glassBorderFocused = Color.white.opacity(0.18)

        /// Glass inner highlight
        static let glassHighlight = Color.white.opacity(0.20)

        /// Glass inner shadow (for depth)
        static let glassInnerShadow = Color.black.opacity(0.30)

        // MARK: Text Colors on Cosmic

        /// Primary text - full brightness
        static let textPrimary = Color.white

        /// Secondary text - slightly dimmed
        static let textSecondary = Color.white.opacity(0.85)

        /// Tertiary text - supporting info
        static let textTertiary = Color.white.opacity(0.60)

        /// Quaternary text - hints
        static let textQuaternary = Color.white.opacity(0.40)

        /// Disabled text
        static let textDisabled = Color.white.opacity(0.25)

        // MARK: Semantic Colors

        /// Success state
        static let success = Color(red: 0.20, green: 0.88, blue: 0.56)

        /// Error state
        static let error = Color(red: 1.0, green: 0.36, blue: 0.36)

        /// Warning state
        static let warning = Color(red: 1.0, green: 0.76, blue: 0.28)

        // MARK: Star Colors

        /// Bright star
        static let starBright = Color.white

        /// Dim star
        static let starDim = Color.white.opacity(0.35)
    }

    // MARK: - Gradients

    enum Gradients {

        /// Primary aurora gradient (violet → electric → cyan)
        static var aurora: LinearGradient {
            LinearGradient(
                colors: [Colors.violet, Colors.electric, Colors.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Aurora with emerald (violet → cyan → emerald)
        static var auroraFull: LinearGradient {
            LinearGradient(
                colors: [Colors.violet, Colors.purple, Colors.electric, Colors.cyan, Colors.emerald],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Horizontal aurora for buttons
        static var auroraHorizontal: LinearGradient {
            LinearGradient(
                colors: [Colors.violet, Colors.purple, Colors.electric],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        /// Cosmic background gradient
        static var cosmic: LinearGradient {
            LinearGradient(
                colors: [Colors.cosmicBlack, Colors.cosmicDeep, Colors.cosmicBlack],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        /// Radial glow from center
        static func radialGlow(color: Color = Colors.violet, intensity: Double = 0.25) -> RadialGradient {
            RadialGradient(
                colors: [color.opacity(intensity), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
        }

        /// Orb gradient (purple core → cyan edge)
        static var orb: LinearGradient {
            LinearGradient(
                colors: [Colors.purple, Colors.electric, Colors.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Angular gradient for rings
        static func orbRing(rotation: Angle = .zero) -> AngularGradient {
            AngularGradient(
                colors: [
                    Colors.violet.opacity(0.4),
                    Colors.electric.opacity(0.3),
                    Colors.cyan.opacity(0.4),
                    Colors.emerald.opacity(0.2),
                    Colors.violet.opacity(0.4)
                ],
                center: .center,
                angle: rotation
            )
        }

        /// Glass border gradient (highlight at top-left)
        static var glassBorder: LinearGradient {
            LinearGradient(
                colors: [
                    Colors.glassHighlight,
                    Colors.glassBorder,
                    Colors.glassBorder.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Glass border when focused
        static func glassBorderFocused(color: Color = Colors.electric) -> LinearGradient {
            LinearGradient(
                colors: [
                    color.opacity(0.7),
                    color.opacity(0.4),
                    Colors.glassBorder
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Animation

    enum Animation {

        // MARK: Timing

        /// Quick micro-interaction
        static let quick: SwiftUI.Animation = .easeOut(duration: 0.15)

        /// Standard transition
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.3)

        /// Slow reveal
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.5)

        /// Bouncy spring for interactive feedback
        static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.7)

        /// Snappy spring for quick response
        static let springSnappy: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.75)

        /// Gentle spring for subtle motion
        static let springGentle: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.8)

        // MARK: Continuous Animations

        /// Orb breathing (2.5s cycle)
        static let orbBreathing: SwiftUI.Animation = .easeInOut(duration: 2.5).repeatForever(autoreverses: true)

        /// Orb rotation (8s continuous)
        static let orbRotation: SwiftUI.Animation = .linear(duration: 8).repeatForever(autoreverses: false)

        /// Aurora flow (12s continuous)
        static let auroraFlow: SwiftUI.Animation = .linear(duration: 12).repeatForever(autoreverses: false)

        /// Aurora pulse (3s cycle)
        static let auroraPulse: SwiftUI.Animation = .easeInOut(duration: 3).repeatForever(autoreverses: true)

        /// Glow pulse (1.5s cycle)
        static let glowPulse: SwiftUI.Animation = .easeInOut(duration: 1.5).repeatForever(autoreverses: true)

        /// Star twinkle
        static func starTwinkle(delay: Double = 0) -> SwiftUI.Animation {
            .easeInOut(duration: Double.random(in: 2...4))
                .repeatForever(autoreverses: true)
                .delay(delay)
        }

        /// Gradient flow for buttons
        static let gradientFlow: SwiftUI.Animation = .linear(duration: 3).repeatForever(autoreverses: false)

        /// Particle orbit
        static let particleOrbit: SwiftUI.Animation = .linear(duration: 4).repeatForever(autoreverses: false)

        // MARK: Stagger Delays

        /// Delay between staggered items
        static let staggerDelay: Double = 0.08

        /// Delay for card reveals
        static let cardRevealDelay: Double = 0.12
    }

    // MARK: - Layout

    enum Layout {

        /// Screen horizontal padding
        static let screenPadding: CGFloat = 24

        /// Card internal padding
        static let cardPadding: CGFloat = 20

        /// Standard spacing between elements
        static let spacing: CGFloat = 16

        /// Large spacing
        static let spacingLarge: CGFloat = 24

        /// Extra large spacing
        static let spacingXL: CGFloat = 32

        /// Small spacing
        static let spacingSmall: CGFloat = 8

        /// Tiny spacing
        static let spacingTiny: CGFloat = 4
    }

    // MARK: - Corner Radius

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 999

        // Semantic
        static let card: CGFloat = 20
        static let button: CGFloat = 16
        static let textField: CGFloat = 14
    }

    // MARK: - Sizes

    enum Size {

        // Orb sizes
        static let orbTiny: CGFloat = 24
        static let orbSmall: CGFloat = 40
        static let orbMedium: CGFloat = 80
        static let orbLarge: CGFloat = 120
        static let orbHero: CGFloat = 140

        // Button heights
        static let buttonHeight: CGFloat = 56
        static let buttonHeightSmall: CGFloat = 44

        // Text field height
        static let textFieldHeight: CGFloat = 56

        // Icon sizes
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
    }

    // MARK: - Shadow

    enum Shadow {

        /// Subtle shadow
        static let subtle = ShadowConfig(color: .black.opacity(0.2), radius: 8, y: 4)

        /// Medium shadow
        static let medium = ShadowConfig(color: .black.opacity(0.3), radius: 16, y: 8)

        /// Strong shadow
        static let strong = ShadowConfig(color: .black.opacity(0.4), radius: 24, y: 12)

        /// Glow shadow
        static func glow(color: Color = Colors.violet, intensity: Double = 0.4) -> ShadowConfig {
            ShadowConfig(color: color.opacity(intensity), radius: 20, y: 0)
        }

        /// Inner shadow effect (simulated with overlay)
        static let inner = ShadowConfig(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

// MARK: - Shadow Configuration

struct ShadowConfig {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - View Extension for Shadows

extension View {
    func auroraShadow(_ config: ShadowConfig) -> some View {
        shadow(color: config.color, radius: config.radius, x: config.x, y: config.y)
    }
}

// MARK: - Orb State Enum

/// States for the CelestialOrb that drive animations across the UI
enum OrbState: Equatable {
    /// User hasn't interacted, subtle breathing animation
    case dormant

    /// User focused a field, orb "notices" and responds
    case aware

    /// User is actively typing, orb glows brighter
    case active

    /// Authentication/operation in progress
    case processing

    /// Operation completed successfully
    case success

    /// Operation failed
    case error

    /// Celebration mode (onboarding complete)
    case celebration
}

// MARK: - Star Particle Model

/// Individual star for the starfield background
struct AuroraStarParticle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let twinkleDelay: Double
    let isBright: Bool

    static func random(in size: CGSize, isBright: Bool = false) -> AuroraStarParticle {
        AuroraStarParticle(
            position: CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            ),
            size: CGFloat.random(in: 1...3),
            baseOpacity: isBright
                ? Double.random(in: 0.20...0.45)
                : Double.random(in: 0.03...0.10),
            twinkleDelay: Double.random(in: 0...2),
            isBright: isBright
        )
    }

    static func generateField(count: Int, in size: CGSize, brightPercentage: Double = 0.12) -> [AuroraStarParticle] {
        let brightCount = Int(Double(count) * brightPercentage)
        let dimCount = count - brightCount

        return (0..<dimCount).map { _ in random(in: size, isBright: false) }
            + (0..<brightCount).map { _ in random(in: size, isBright: true) }
    }
}

// MARK: - Preview

#Preview("Aurora Colors") {
    ScrollView {
        VStack(spacing: 20) {
            // Aurora gradient swatch
            RoundedRectangle(cornerRadius: Aurora.Radius.large)
                .fill(Aurora.Gradients.aurora)
                .frame(height: 80)
                .overlay(
                    Text("Aurora Gradient")
                        .font(.headline)
                        .foregroundStyle(.white)
                )

            // Color swatches
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                colorSwatch("Violet", Aurora.Colors.violet)
                colorSwatch("Purple", Aurora.Colors.purple)
                colorSwatch("Electric", Aurora.Colors.electric)
                colorSwatch("Cyan", Aurora.Colors.cyan)
                colorSwatch("Emerald", Aurora.Colors.emerald)
                colorSwatch("Rose", Aurora.Colors.rose)
            }

            // Cosmic backgrounds
            VStack(spacing: 8) {
                Text("Cosmic Backgrounds")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 12) {
                    cosmicSwatch("Black", Aurora.Colors.cosmicBlack)
                    cosmicSwatch("Deep", Aurora.Colors.cosmicDeep)
                    cosmicSwatch("Surface", Aurora.Colors.cosmicSurface)
                    cosmicSwatch("Elevated", Aurora.Colors.cosmicElevated)
                }
            }
        }
        .padding()
    }
    .background(Aurora.Colors.cosmicBlack)
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
        SwiftUI.Circle()
            .fill(color)
            .frame(width: 50, height: 50)
            .shadow(color: color.opacity(0.5), radius: 8)
        Text(name)
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.7))
    }
}

private func cosmicSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 60, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        Text(name)
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.5))
    }
}
