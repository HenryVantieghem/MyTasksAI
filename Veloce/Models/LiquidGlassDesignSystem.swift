//
//  LiquidGlassDesignSystem.swift
//  Veloce
//
//  Design Tokens Only - Colors, Typography, Spacing
//
//  For glass effects, use NativeLiquidGlass.swift which provides
//  pure Apple native Liquid Glass APIs (iOS 26+).
//
//  Architecture:
//  - Navigation Layer: Liquid Glass (use .glassEffect() from NativeLiquidGlass)
//  - Content Layer: Solid backgrounds (use .contentCard() from NativeLiquidGlass)
//

import SwiftUI

// MARK: - Liquid Glass Design System (Tokens Only)

enum LiquidGlassDesignSystem {

    // MARK: - Vibrant Accents

    enum VibrantAccents {
        /// Electric Cyan - Primary action
        static let electricCyan = Color(red: 0.0, green: 0.95, blue: 1.0)

        /// Plasma Purple - AI/premium
        static let plasmaPurple = Color(red: 0.65, green: 0.25, blue: 1.0)

        /// Utopian Green - Success
        static let utopianGreen = Color(red: 0.15, green: 1.0, blue: 0.65)

        /// Solar Gold - Achievement
        static let solarGold = Color(red: 1.0, green: 0.85, blue: 0.25)

        /// Nebula Pink - Celebration
        static let nebulaPink = Color(red: 1.0, green: 0.45, blue: 0.75)

        /// Cosmic Blue - Interactive
        static let cosmicBlue = Color(red: 0.25, green: 0.55, blue: 1.0)

        /// Stellar White - Highlight
        static let stellarWhite = Color(red: 1.0, green: 0.98, blue: 0.95)
    }

    // MARK: - Void Backgrounds

    enum Void {
        /// Deepest background
        static let deepSpace = Color(red: 0.01, green: 0.01, blue: 0.03)

        /// Main background
        static let cosmos = Color(red: 0.02, green: 0.02, blue: 0.04)

        /// Card surface
        static let abyss = Color(red: 0.04, green: 0.04, blue: 0.06)

        /// Interactive surface
        static let nebula = Color(red: 0.06, green: 0.06, blue: 0.10)
    }

    // MARK: - Semantic Colors

    enum Semantic {
        static let success = VibrantAccents.utopianGreen
        static let warning = VibrantAccents.solarGold
        static let error = Color(red: 1.0, green: 0.35, blue: 0.40)
        static let info = VibrantAccents.cosmicBlue
        static let premium = VibrantAccents.plasmaPurple
    }

    // MARK: - Text Colors

    enum Text {
        /// Primary text - 95% white
        static let primary = Color.white.opacity(0.95)

        /// Secondary text - 60% white
        static let secondary = Color.white.opacity(0.60)

        /// Tertiary text - 40% white
        static let tertiary = Color.white.opacity(0.40)

        /// Disabled text - 25% white
        static let disabled = Color.white.opacity(0.25)
    }

    // MARK: - Typography

    enum Typography {
        // Display (Thin, Editorial)
        static let displayHero = Font.system(size: 48, weight: .thin)
        static let displayLarge = Font.system(size: 36, weight: .thin)
        static let displayMedium = Font.system(size: 28, weight: .thin)

        // Titles (Rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 18, weight: .semibold, design: .rounded)

        // Body
        static let body = Font.system(size: 16, weight: .regular)
        static let bodyBold = Font.system(size: 16, weight: .semibold)
        static let callout = Font.system(size: 15, weight: .regular)

        // Supporting
        static let caption = Font.system(size: 13, weight: .medium)
        static let caption2 = Font.system(size: 11, weight: .regular)

        // Special
        static let aiWhisper = Font.system(size: 14, weight: .regular, design: .serif).italic()
        static let code = Font.system(size: 13, weight: .regular, design: .monospaced)

        // MARK: Responsive Typography

        static func displayHeroResponsive(for layout: ResponsiveLayout) -> Font {
            .system(size: 42 * layout.fontScale, weight: .thin)
        }

        static func displayLargeResponsive(for layout: ResponsiveLayout) -> Font {
            .system(size: 34 * layout.fontScale, weight: .thin)
        }

        static func title1Responsive(for layout: ResponsiveLayout) -> Font {
            .system(size: 26 * layout.fontScale, weight: .bold, design: .rounded)
        }

        static func title2Responsive(for layout: ResponsiveLayout) -> Font {
            .system(size: 21 * layout.fontScale, weight: .semibold, design: .rounded)
        }

        static func title3Responsive(for layout: ResponsiveLayout) -> Font {
            .system(size: 17 * layout.fontScale, weight: .semibold, design: .rounded)
        }

        static func bodyResponsive(for layout: ResponsiveLayout) -> Font {
            .system(size: 15 * layout.fontScale, weight: .regular)
        }

        static func captionResponsive(for layout: ResponsiveLayout) -> Font {
            .system(size: 12 * layout.fontScale, weight: .medium)
        }
    }

    // MARK: - Responsive Sizing

    enum ResponsiveSizing {
        static func buttonHeight(for layout: ResponsiveLayout) -> CGFloat {
            layout.buttonHeight
        }

        static func inputHeight(for layout: ResponsiveLayout) -> CGFloat {
            layout.textFieldHeight
        }

        static func screenPadding(for layout: ResponsiveLayout) -> CGFloat {
            layout.screenPadding
        }

        static func cardPadding(for layout: ResponsiveLayout) -> CGFloat {
            layout.cardPadding
        }

        static func cornerRadius(for layout: ResponsiveLayout) -> CGFloat {
            layout.deviceType.isTablet ? 20 : 16
        }

        static func touchTarget(for layout: ResponsiveLayout) -> CGFloat {
            layout.minTouchTarget
        }
    }

    // MARK: - Spacing (8pt Grid)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48

        // Semantic
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let comfortable: CGFloat = 20
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999

        // Semantic
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let input: CGFloat = 12
    }

    // MARK: - Animation Springs

    enum Springs {
        /// UI interactions (250ms)
        static let ui: Animation = .spring(response: 0.25, dampingFraction: 0.7)

        /// Sheet presentations (400ms)
        static let sheet: Animation = .spring(response: 0.4, dampingFraction: 0.75)

        /// Focus transitions (500ms)
        static let focus: Animation = .spring(response: 0.5, dampingFraction: 0.75)

        /// Bouncy feedback (350ms)
        static let bouncy: Animation = .spring(response: 0.35, dampingFraction: 0.6)

        /// Quick response (150ms)
        static let quick: Animation = .spring(response: 0.15, dampingFraction: 0.8)

        /// Gentle float (600ms)
        static let gentle: Animation = .spring(response: 0.6, dampingFraction: 0.85)

        /// Press animation (150ms)
        static let press: Animation = .spring(response: 0.15, dampingFraction: 0.8)
    }

    // MARK: - Shadow Tokens

    enum Shadow {
        static let small = ShadowToken(color: .black.opacity(0.2), radius: 4, y: 2)
        static let medium = ShadowToken(color: .black.opacity(0.25), radius: 8, y: 4)
        static let large = ShadowToken(color: .black.opacity(0.3), radius: 16, y: 8)
    }

    struct ShadowToken {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }

    // MARK: - Sizing Tokens

    enum Sizing {
        static let buttonHeight: CGFloat = 50
        static let inputHeight: CGFloat = 48
        static let textFieldHeight: CGFloat = 48
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 20
        static let iconLarge: CGFloat = 24
        static let touchTarget: CGFloat = 44
        static let cornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 12
    }
}

// MARK: - Validation State (Simplified)

enum GlassValidationState: Equatable {
    case idle
    case valid
    case invalid(String)
    case validating

    var tint: Color {
        switch self {
        case .idle: return LiquidGlassDesignSystem.Text.tertiary
        case .valid: return LiquidGlassDesignSystem.VibrantAccents.utopianGreen
        case .invalid: return LiquidGlassDesignSystem.Semantic.error
        case .validating: return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        }
    }
}

// MARK: - Simple View Extensions

extension View {
    /// Apply shadow from token
    func liquidShadow(_ token: LiquidGlassDesignSystem.ShadowToken) -> some View {
        self.shadow(color: token.color, radius: token.radius, x: token.x, y: token.y)
    }

    /// Apply screen padding
    func liquidScreenPadding() -> some View {
        self.padding(.horizontal, LiquidGlassDesignSystem.Spacing.screenPadding)
    }
}

// MARK: - Preview

#Preview("Design Tokens") {
    ZStack {
        LiquidGlassDesignSystem.Void.cosmos
            .ignoresSafeArea()

        VStack(spacing: 24) {
            Text("Design Tokens")
                .font(LiquidGlassDesignSystem.Typography.title1)
                .foregroundStyle(LiquidGlassDesignSystem.Text.primary)

            HStack(spacing: 12) {
                Circle().fill(LiquidGlassDesignSystem.VibrantAccents.electricCyan).frame(width: 40, height: 40)
                Circle().fill(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple).frame(width: 40, height: 40)
                Circle().fill(LiquidGlassDesignSystem.VibrantAccents.utopianGreen).frame(width: 40, height: 40)
                Circle().fill(LiquidGlassDesignSystem.VibrantAccents.solarGold).frame(width: 40, height: 40)
                Circle().fill(LiquidGlassDesignSystem.VibrantAccents.nebulaPink).frame(width: 40, height: 40)
            }

            Text("For glass effects, use NativeLiquidGlass.swift")
                .font(LiquidGlassDesignSystem.Typography.caption)
                .foregroundStyle(LiquidGlassDesignSystem.Text.tertiary)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
