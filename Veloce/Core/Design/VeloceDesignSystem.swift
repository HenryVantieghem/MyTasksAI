//
//  VeloceDesignSystem.swift
//  Veloce
//
//  Unified Design System
//  Single source of truth for all design tokens
//  Inspired by Tiimo's clean, minimalist aesthetic
//

import SwiftUI

// MARK: - Veloce Design System

enum Veloce {

    // MARK: - Colors

    enum Colors {

        // MARK: Surfaces (3 levels - simplified from 10+)

        /// Deepest background - pure void
        static let voidBlack = Color(red: 0.02, green: 0.02, blue: 0.035)

        /// Elevated surfaces - cards, modals
        static let surfaceElevated = Color(red: 0.05, green: 0.05, blue: 0.07)

        /// Card backgrounds - interactive elements
        static let surfaceCard = Color(red: 0.08, green: 0.08, blue: 0.12)

        /// Input field backgrounds
        static let surfaceInput = Color(red: 0.10, green: 0.10, blue: 0.14)

        // MARK: Text (3 levels)

        /// Primary text - headlines, important content
        static let textPrimary = Color.white.opacity(0.95)

        /// Secondary text - body copy, descriptions
        static let textSecondary = Color.white.opacity(0.65)

        /// Tertiary text - hints, placeholders, captions
        static let textTertiary = Color.white.opacity(0.40)

        /// Disabled text
        static let textDisabled = Color.white.opacity(0.25)

        // MARK: Accent Colors

        /// Primary accent - main interactive elements
        static let accentPrimary = Color(hex: "6366F1") // Indigo

        /// Secondary accent - complementary highlights
        static let accentSecondary = Color(hex: "22D3EE") // Cyan

        /// Tertiary accent - subtle accents
        static let accentTertiary = Color(hex: "A78BFA") // Purple

        // MARK: Semantic Colors

        /// Success states
        static let success = Color(hex: "10B981") // Emerald

        /// Warning states
        static let warning = Color(hex: "F59E0B") // Amber

        /// Error states
        static let error = Color(hex: "EF4444") // Red

        /// Info states
        static let info = Color(hex: "3B82F6") // Blue

        // MARK: Special Purpose

        /// AI/Oracle elements
        static let ai = Color(hex: "8B5CF6") // Violet

        /// Focus mode
        static let focus = Color(hex: "06B6D4") // Cyan

        /// Gamification/Points
        static let gamification = Color(hex: "F97316") // Orange

        /// Social/Circles
        static let social = Color(hex: "EC4899") // Pink

        // MARK: Gradients

        static let primaryGradient = LinearGradient(
            colors: [accentPrimary, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let aiGradient = LinearGradient(
            colors: [ai, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let successGradient = LinearGradient(
            colors: [success, Color(hex: "34D399")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let warmGradient = LinearGradient(
            colors: [warning, gamification],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // MARK: Glass Overlays

        static let glassOverlay = Color.white.opacity(0.05)
        static let glassBorder = Color.white.opacity(0.1)
        static let glassHighlight = Color.white.opacity(0.15)

        // MARK: Glass Effect Colors (for auth/onboarding)

        /// Base glass fill - subtle white
        static let glassBase = Color.white.opacity(0.03)

        /// Glass fill when focused/active
        static let glassFocused = Color.white.opacity(0.06)

        /// Glass border focused
        static let glassBorderFocused = Color.white.opacity(0.18)

        /// Glass inner shadow (for depth)
        static let glassInnerShadow = Color.black.opacity(0.30)

        // MARK: Star Colors

        /// Bright star
        static let starBright = Color.white

        /// Dim star
        static let starDim = Color.white.opacity(0.35)

        // MARK: Additional Gradients

        /// Orb gradient (purple core → cyan edge)
        static var orbGradient: LinearGradient {
            LinearGradient(
                colors: [ai, accentPrimary, accentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Angular gradient for rings
        static func orbRing(rotation: Angle = .zero) -> AngularGradient {
            AngularGradient(
                colors: [
                    accentTertiary.opacity(0.4),
                    accentPrimary.opacity(0.3),
                    accentSecondary.opacity(0.4),
                    success.opacity(0.2),
                    accentTertiary.opacity(0.4)
                ],
                center: .center,
                angle: rotation
            )
        }

        /// Radial glow from center
        static func radialGlow(color: Color = accentTertiary, intensity: Double = 0.25) -> RadialGradient {
            RadialGradient(
                colors: [color.opacity(intensity), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
        }

        /// Glass border gradient (highlight at top-left)
        static var glassBorderGradient: LinearGradient {
            LinearGradient(
                colors: [
                    glassHighlight,
                    glassBorder,
                    glassBorder.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Glass border when focused
        static func glassBorderFocusedGradient(color: Color = accentPrimary) -> LinearGradient {
            LinearGradient(
                colors: [
                    color.opacity(0.7),
                    color.opacity(0.4),
                    glassBorder
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Typography

    enum Typography {

        // MARK: Display

        /// Hero headlines - splash, onboarding
        static let displayHero = Font.system(size: 48, weight: .thin, design: .default)

        /// Large display - section headers
        static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)

        // MARK: Titles

        /// Title 1 - Page titles
        static let title1 = Font.system(size: 28, weight: .semibold, design: .default)

        /// Title 2 - Section titles
        static let title2 = Font.system(size: 22, weight: .semibold, design: .default)

        /// Title 3 - Card titles
        static let title3 = Font.system(size: 18, weight: .semibold, design: .rounded)

        // MARK: Body

        /// Body - Primary content
        static let body = Font.system(size: 16, weight: .regular, design: .default)

        /// Body emphasized - Important body text
        static let bodyEmphasized = Font.system(size: 16, weight: .medium, design: .default)

        /// Body small - Compact content
        static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

        // MARK: Captions

        /// Caption - Labels, metadata
        static let caption = Font.system(size: 13, weight: .medium, design: .default)

        /// Caption small - Timestamps, hints
        static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)

        // MARK: Special

        /// Monospace - Code, technical data
        static let monospace = Font.system(size: 13, weight: .regular, design: .monospaced)

        /// AI whisper - AI insights
        static let aiWhisper = Font.system(size: 14, weight: .regular, design: .serif).italic()

        /// Button text
        static let button = Font.system(size: 16, weight: .semibold, design: .rounded)

        /// Tab bar labels
        static let tabLabel = Font.system(size: 10, weight: .medium, design: .rounded)
    }

    // MARK: - Spacing (8pt Grid)

    enum Spacing {
        /// 4pt - Minimal spacing
        static let xxs: CGFloat = 4

        /// 8pt - Tight spacing
        static let xs: CGFloat = 8

        /// 12pt - Compact spacing
        static let sm: CGFloat = 12

        /// 16pt - Standard spacing
        static let md: CGFloat = 16

        /// 24pt - Comfortable spacing
        static let lg: CGFloat = 24

        /// 32pt - Generous spacing
        static let xl: CGFloat = 32

        /// 48pt - Section spacing
        static let xxl: CGFloat = 48

        /// Screen edge padding
        static let screenPadding: CGFloat = 20

        /// Card internal padding
        static let cardPadding: CGFloat = 16

        /// Button internal padding
        static let buttonPadding: CGFloat = 12
    }

    // MARK: - Corner Radius

    enum Radius {
        /// 4pt - Subtle rounding
        static let xs: CGFloat = 4

        /// 8pt - Small elements
        static let sm: CGFloat = 8

        /// 12pt - Buttons, inputs
        static let md: CGFloat = 12

        /// 16pt - Cards
        static let lg: CGFloat = 16

        /// 20pt - Large cards
        static let xl: CGFloat = 20

        /// 24pt - Sheets, modals
        static let xxl: CGFloat = 24

        /// Full circle
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    enum Shadow {
        static let small = VeloceShadowStyle(
            color: .black.opacity(0.15),
            radius: 4,
            x: 0,
            y: 2
        )

        static let medium = VeloceShadowStyle(
            color: .black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )

        static let large = VeloceShadowStyle(
            color: .black.opacity(0.25),
            radius: 16,
            x: 0,
            y: 8
        )

        static let glow = VeloceShadowStyle(
            color: Colors.accentPrimary.opacity(0.3),
            radius: 12,
            x: 0,
            y: 0
        )
    }

    // MARK: - Animation

    enum Animation {
        // MARK: Timing

        /// Quick interactions - 150ms
        static let quick: SwiftUI.Animation = .easeOut(duration: 0.15)

        /// Standard transitions - 250ms
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)

        /// Smooth transitions - 350ms
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.35)

        /// Slow reveal
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.5)

        /// Spring animation
        static let spring: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.7)

        /// Bouncy spring for interactive feedback
        static let bouncy: SwiftUI.Animation = .bouncy

        /// Snappy spring for quick response
        static let snappy: SwiftUI.Animation = .snappy

        /// Gentle spring for subtle motion
        static let springGentle: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.8)

        // MARK: Continuous Animations

        /// Orb breathing (2.5s cycle)
        static let orbBreathing: SwiftUI.Animation = .easeInOut(duration: 2.5).repeatForever(autoreverses: true)

        /// Orb rotation (8s continuous)
        static let orbRotation: SwiftUI.Animation = .linear(duration: 8).repeatForever(autoreverses: false)

        /// Glow pulse (1.5s cycle)
        static let glowPulse: SwiftUI.Animation = .easeInOut(duration: 1.5).repeatForever(autoreverses: true)

        /// Star twinkle
        static func starTwinkle(delay: Double = 0) -> SwiftUI.Animation {
            .easeInOut(duration: Double.random(in: 2...4))
                .repeatForever(autoreverses: true)
                .delay(delay)
        }

        /// Particle orbit
        static let particleOrbit: SwiftUI.Animation = .linear(duration: 4).repeatForever(autoreverses: false)

        /// Gradient flow for buttons
        static let gradientFlow: SwiftUI.Animation = .linear(duration: 3).repeatForever(autoreverses: false)

        // MARK: Stagger Delays

        /// Stagger delay for lists
        static let staggerDelay: Double = 0.05

        /// Delay for card reveals
        static let cardRevealDelay: Double = 0.12
    }

    // MARK: - Sizing

    enum Size {
        /// Minimum touch target
        static let minTouchTarget: CGFloat = 44

        /// Icon size - small
        static let iconSmall: CGFloat = 16

        /// Icon size - medium
        static let iconMedium: CGFloat = 24

        /// Icon size - large
        static let iconLarge: CGFloat = 32

        /// Avatar size - small
        static let avatarSmall: CGFloat = 32

        /// Avatar size - medium
        static let avatarMedium: CGFloat = 48

        /// Avatar size - large
        static let avatarLarge: CGFloat = 64

        /// Button height
        static let buttonHeight: CGFloat = 50

        /// Button height - small
        static let buttonHeightSmall: CGFloat = 44

        /// Input height
        static let inputHeight: CGFloat = 48

        /// Tab bar height
        static let tabBarHeight: CGFloat = 60

        // MARK: Orb Sizes

        /// Tiny orb
        static let orbTiny: CGFloat = 24

        /// Small orb
        static let orbSmall: CGFloat = 40

        /// Medium orb
        static let orbMedium: CGFloat = 80

        /// Large orb
        static let orbLarge: CGFloat = 120

        /// Hero orb
        static let orbHero: CGFloat = 140

        /// Massive orb
        static let orbMassive: CGFloat = 200
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
}

// MARK: - Color Extension for Hex
// Note: Color(hex:) is defined in UtopianDesignSystem.swift to avoid duplication

// MARK: - Veloce Shadow Style

struct VeloceShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {
    /// Apply Veloce card styling
    func veloceCard() -> some View {
        self
            .padding(Veloce.Spacing.cardPadding)
            .background(Veloce.Colors.surfaceCard)
            .cornerRadius(Veloce.Radius.lg)
            .shadow(
                color: Veloce.Shadow.medium.color,
                radius: Veloce.Shadow.medium.radius,
                x: Veloce.Shadow.medium.x,
                y: Veloce.Shadow.medium.y
            )
    }

    /// Apply Veloce glass card styling
    func veloceGlassCard() -> some View {
        self
            .padding(Veloce.Spacing.cardPadding)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Veloce.Radius.lg))
    }

    /// Apply Veloce primary button styling
    func velocePrimaryButton() -> some View {
        self
            .font(Veloce.Typography.button)
            .foregroundStyle(.white)
            .frame(height: Veloce.Size.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(Veloce.Colors.primaryGradient)
            .cornerRadius(Veloce.Radius.md)
    }

    /// Apply Veloce secondary button styling
    func veloceSecondaryButton() -> some View {
        self
            .font(Veloce.Typography.button)
            .foregroundStyle(Veloce.Colors.textPrimary)
            .frame(height: Veloce.Size.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(Veloce.Colors.surfaceCard)
            .cornerRadius(Veloce.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Veloce.Radius.md)
                    .stroke(Veloce.Colors.glassBorder, lineWidth: 1)
            )
    }

    /// Apply Veloce text field styling
    func veloceTextField() -> some View {
        self
            .font(Veloce.Typography.body)
            .foregroundStyle(Veloce.Colors.textPrimary)
            .padding(.horizontal, Veloce.Spacing.md)
            .frame(height: Veloce.Size.inputHeight)
            .background(Veloce.Colors.surfaceInput)
            .cornerRadius(Veloce.Radius.md)
    }

    /// Apply shadow style
    func veloceShadow(_ style: VeloceShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}

// MARK: - Text Style Extensions

extension Text {
    func veloceStyle(_ style: VeloceTextStyle) -> Text {
        switch style {
        case .displayHero:
            return self.font(Veloce.Typography.displayHero)
                .foregroundColor(Veloce.Colors.textPrimary)
        case .displayLarge:
            return self.font(Veloce.Typography.displayLarge)
                .foregroundColor(Veloce.Colors.textPrimary)
        case .title1:
            return self.font(Veloce.Typography.title1)
                .foregroundColor(Veloce.Colors.textPrimary)
        case .title2:
            return self.font(Veloce.Typography.title2)
                .foregroundColor(Veloce.Colors.textPrimary)
        case .title3:
            return self.font(Veloce.Typography.title3)
                .foregroundColor(Veloce.Colors.textPrimary)
        case .body:
            return self.font(Veloce.Typography.body)
                .foregroundColor(Veloce.Colors.textSecondary)
        case .bodyEmphasized:
            return self.font(Veloce.Typography.bodyEmphasized)
                .foregroundColor(Veloce.Colors.textPrimary)
        case .caption:
            return self.font(Veloce.Typography.caption)
                .foregroundColor(Veloce.Colors.textTertiary)
        case .aiWhisper:
            return self.font(Veloce.Typography.aiWhisper)
                .foregroundColor(Veloce.Colors.ai)
        }
    }
}

enum VeloceTextStyle {
    case displayHero
    case displayLarge
    case title1
    case title2
    case title3
    case body
    case bodyEmphasized
    case caption
    case aiWhisper
}

// MARK: - Previews

#Preview("Colors") {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                Text("Surfaces")
                    .font(Veloce.Typography.title2)
                HStack(spacing: 10) {
                    ColorSwatch(color: Veloce.Colors.voidBlack, name: "Void")
                    ColorSwatch(color: Veloce.Colors.surfaceElevated, name: "Elevated")
                    ColorSwatch(color: Veloce.Colors.surfaceCard, name: "Card")
                }
            }

            Group {
                Text("Accents")
                    .font(Veloce.Typography.title2)
                HStack(spacing: 10) {
                    ColorSwatch(color: Veloce.Colors.accentPrimary, name: "Primary")
                    ColorSwatch(color: Veloce.Colors.accentSecondary, name: "Secondary")
                    ColorSwatch(color: Veloce.Colors.accentTertiary, name: "Tertiary")
                }
            }

            Group {
                Text("Semantic")
                    .font(Veloce.Typography.title2)
                HStack(spacing: 10) {
                    ColorSwatch(color: Veloce.Colors.success, name: "Success")
                    ColorSwatch(color: Veloce.Colors.warning, name: "Warning")
                    ColorSwatch(color: Veloce.Colors.error, name: "Error")
                }
            }
        }
        .padding()
    }
    .background(Veloce.Colors.voidBlack)
}

private struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)
            Text(name)
                .font(Veloce.Typography.captionSmall)
                .foregroundStyle(Veloce.Colors.textSecondary)
        }
    }
}
