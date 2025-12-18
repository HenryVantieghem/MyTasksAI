//
//  Theme.swift
//  MyTasksAI
//
//  Comprehensive Design System
//  Colors, Typography, Spacing, and Animations
//

import SwiftUI

// MARK: - Theme
/// Central design system namespace
enum Theme {

    // MARK: - Colors
    enum Colors {
        // MARK: Primary Colors
        static let accent = Color(red: 0.45, green: 0.35, blue: 0.95)  // Purple-blue
        static let accentSecondary = Color(red: 0.6, green: 0.4, blue: 1.0)

        // MARK: Background Colors
        static let background = Color(uiColor: .systemBackground)
        static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
        static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)

        // MARK: Text Colors
        static let textPrimary = Color(uiColor: .label)
        static let textSecondary = Color(uiColor: .secondaryLabel)
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        static let textOnAccent = Color.white

        // MARK: Semantic Colors
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.7, blue: 0.2)
        static let error = Color(red: 1.0, green: 0.35, blue: 0.35)
        static let info = Color(red: 0.3, green: 0.6, blue: 1.0)

        // MARK: AI Colors (Iridescent)
        static let aiPurple = Color(red: 0.6, green: 0.3, blue: 1.0)
        static let aiBlue = Color(red: 0.3, green: 0.5, blue: 1.0)
        static let aiCyan = Color(red: 0.2, green: 0.8, blue: 0.9)
        static let aiPink = Color(red: 1.0, green: 0.4, blue: 0.7)
        static let aiGold = Color(red: 1.0, green: 0.85, blue: 0.4)
        static let aiOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

        // MARK: Iridescent Colors (Confetti/Effects)
        static let iridescentPink = Color(red: 1.0, green: 0.5, blue: 0.8)
        static let iridescentCyan = Color(red: 0.4, green: 0.9, blue: 1.0)
        static let iridescentYellow = Color(red: 1.0, green: 0.95, blue: 0.4)
        static let iridescentLavender = Color(red: 0.8, green: 0.6, blue: 1.0)
        static let iridescentMint = Color(red: 0.4, green: 1.0, blue: 0.7)

        // MARK: Gamification Colors
        static let streakOrange = Color(red: 1.0, green: 0.5, blue: 0.1)
        static let xp = Color(red: 0.9, green: 0.75, blue: 0.2)
        static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
        static let fire = Color(red: 1.0, green: 0.35, blue: 0.1)

        // MARK: Aliases
        static let primaryText = textPrimary
        static let secondaryText = textSecondary
        static let tertiaryText = textTertiary
        static let destructive = error
        static let glassBackground = Color.white.opacity(0.1)
        static let cardBackgroundSecondary = Color(uiColor: .tertiarySystemBackground)

        // MARK: Surface Colors
        static let cardBackground = Color(uiColor: .secondarySystemBackground)
        static let glassBorder = Color.white.opacity(0.2)
        static let divider = Color(uiColor: .separator)

        // MARK: Dark Mode Aware Colors (use with DarkModeAware modifier)
        /// Returns different colors based on color scheme
        static func adaptiveGlass(light: Double = 0.1, dark: Double = 0.15) -> (light: Color, dark: Color) {
            (Color.white.opacity(light), Color.white.opacity(dark))
        }

        static func adaptiveBorder(light: Double = 0.2, dark: Double = 0.25) -> (light: Color, dark: Color) {
            (Color.white.opacity(light), Color.white.opacity(dark))
        }

        static func adaptiveShadow(light: Double = 0.1, dark: Double = 0.3) -> (light: Color, dark: Color) {
            (Color.black.opacity(light), Color.black.opacity(dark))
        }

        // MARK: Gradient Presets
        static var accentGradient: LinearGradient {
            LinearGradient(
                colors: [accent, accentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var iridescentGradient: [Color] {
            [aiPurple, aiBlue, aiCyan, aiPink]
        }

        static var iridescentGradientLinear: LinearGradient {
            LinearGradient(
                colors: iridescentGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var aiGradient: [Color] {
            [aiOrange, aiPurple, aiBlue, aiCyan]
        }

        static var aiGradientLinear: LinearGradient {
            LinearGradient(
                colors: aiGradient,
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        static var successGradient: LinearGradient {
            LinearGradient(
                colors: [success, success.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // MARK: Angular Gradients
        static func iridescentAngularGradient(angle: Angle = .degrees(0)) -> AngularGradient {
            AngularGradient(
                colors: [aiPurple, aiBlue, aiCyan, aiPink, aiPurple],
                center: .center,
                angle: angle
            )
        }

        // MARK: - Claude/Anthropic Inspired Colors
        /// Warm, friendly palette inspired by Anthropic's Claude design system
        enum Claude {
            /// Primary warm orange (Crail #C15F3C)
            static let primary = Color(red: 0.757, green: 0.373, blue: 0.235)

            /// Soft gray (Cloudy #B1ADA1)
            static let secondary = Color(red: 0.694, green: 0.678, blue: 0.631)

            /// Off-white background (Pampas #F4F3EE)
            static let background = Color(red: 0.957, green: 0.953, blue: 0.933)

            /// Pure white for cards
            static let cardBackground = Color.white

            /// Warm charcoal text
            static let textPrimary = Color(red: 0.15, green: 0.15, blue: 0.15)

            /// Warm gray secondary text
            static let textSecondary = Color(red: 0.45, green: 0.43, blue: 0.40)

            /// Lighter tertiary text
            static let textTertiary = Color(red: 0.65, green: 0.63, blue: 0.60)

            /// Gradient for primary actions
            static var primaryGradient: LinearGradient {
                LinearGradient(
                    colors: [primary, primary.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - Layout Constants
    enum Layout {
        static let regularPadding: CGFloat = 48
        static let maxCardWidth: CGFloat = 600
        static let maxContentWidth: CGFloat = 800
    }

    // MARK: - Typography
    enum Typography {
        // MARK: Display
        static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title = Font.system(.title, design: .rounded, weight: .semibold)
        static let title1 = Font.system(.title, design: .rounded, weight: .bold)
        static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
        static let title3 = Font.system(.title3, design: .rounded, weight: .medium)

        // MARK: Body
        static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
        static let body = Font.system(.body, design: .rounded)
        static let bodyBold = Font.system(.body, design: .rounded, weight: .semibold)
        static let callout = Font.system(.callout, design: .rounded)

        // MARK: Supporting
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let subheadlineMedium = Font.system(.subheadline, design: .rounded, weight: .medium)
        static let footnote = Font.system(.footnote, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let caption1 = Font.system(.caption, design: .rounded)  // Alias for caption
        static let caption1Medium = Font.system(.caption, design: .rounded, weight: .medium)
        static let caption2 = Font.system(.caption2, design: .rounded)

        // MARK: AI Fonts
        static let aiWhisper = Font.system(.footnote, design: .rounded).italic()

        // MARK: Pill/Button Text
        static let pillText = Font.system(.subheadline, design: .rounded, weight: .medium)

        // MARK: Monospace
        static let code = Font.system(.body, design: .monospaced)
        static let codeSmall = Font.system(.footnote, design: .monospaced)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
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
        static let itemSpacing: CGFloat = 12
        static let compactSpacing: CGFloat = 8
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 999

        // Semantic
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let textField: CGFloat = 12
        static let pill: CGFloat = 999

        // Aliases
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    // Radius alias for convenience
    typealias Radius = CornerRadius

    // MARK: - Size
    enum Size {
        static let checkboxSize: CGFloat = 24
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
    }

    // MARK: - Shadow
    enum Shadow {
        // Light mode shadows
        static let sm = ShadowStyle(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let md = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let lg = ShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        static let glow = ShadowStyle(color: Colors.accent.opacity(0.4), radius: 20, x: 0, y: 0)
        static let aiGlow = ShadowStyle(color: Colors.aiPurple.opacity(0.5), radius: 24, x: 0, y: 0)

        // Dark mode enhanced shadows (use with adaptiveShadow modifier)
        static let smDark = ShadowStyle(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        static let mdDark = ShadowStyle(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        static let lgDark = ShadowStyle(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        static let glowDark = ShadowStyle(color: Colors.accent.opacity(0.5), radius: 24, x: 0, y: 0)
        static let aiGlowDark = ShadowStyle(color: Colors.aiPurple.opacity(0.6), radius: 28, x: 0, y: 0)
    }

    // MARK: - Animation
    enum Animation {
        static let instant = SwiftUI.Animation.easeOut(duration: 0.1)
        static let fast = SwiftUI.Animation.easeOut(duration: 0.2)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)

        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let springSnappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let springGentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
        static let bouncySpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let quickSpring = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.7)

        // AI Animations
        static let aiPulse = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        static let aiShimmer = SwiftUI.Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
        static let iridescentRotation = SwiftUI.Animation.linear(duration: 8.0).repeatForever(autoreverses: false)
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    /// Apply theme shadow
    func themeShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    /// Apply adaptive theme shadow (different in light/dark mode)
    func themeShadow(_ light: ShadowStyle, dark: ShadowStyle) -> some View {
        modifier(AdaptiveThemeShadowModifier(lightShadow: light, darkShadow: dark))
    }

    /// Apply standard adaptive shadow (auto-selects light/dark variant)
    func adaptiveThemeShadow(_ size: AdaptiveShadowSize) -> some View {
        switch size {
        case .sm:
            return AnyView(themeShadow(Theme.Shadow.sm, dark: Theme.Shadow.smDark))
        case .md:
            return AnyView(themeShadow(Theme.Shadow.md, dark: Theme.Shadow.mdDark))
        case .lg:
            return AnyView(themeShadow(Theme.Shadow.lg, dark: Theme.Shadow.lgDark))
        case .glow:
            return AnyView(themeShadow(Theme.Shadow.glow, dark: Theme.Shadow.glowDark))
        case .aiGlow:
            return AnyView(themeShadow(Theme.Shadow.aiGlow, dark: Theme.Shadow.aiGlowDark))
        }
    }
}

/// Adaptive shadow sizes for convenience
enum AdaptiveShadowSize {
    case sm, md, lg, glow, aiGlow
}

/// Modifier for adaptive shadows based on color scheme
struct AdaptiveThemeShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let lightShadow: ShadowStyle
    let darkShadow: ShadowStyle

    func body(content: Content) -> some View {
        let shadow = colorScheme == .dark ? darkShadow : lightShadow
        content.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Card Style Extensions
extension View {
    /// Apply card style with adaptive shadows
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }

    /// Apply glass card style with adaptive dark mode
    func glassCardStyle() -> some View {
        modifier(GlassCardStyleModifier())
    }

    /// Apply screen padding
    func screenPadding() -> some View {
        self.padding(.horizontal, Theme.Spacing.screenPadding)
    }
}

/// Card style modifier with adaptive shadows
struct CardStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.cardPadding)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                radius: colorScheme == .dark ? 6 : 4,
                x: 0,
                y: colorScheme == .dark ? 3 : 2
            )
    }
}

/// Glass card style modifier with adaptive dark mode
struct GlassCardStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.cardPadding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(colorScheme == .dark ? 0.15 : 0.25),
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                radius: colorScheme == .dark ? 8 : 4,
                x: 0,
                y: colorScheme == .dark ? 4 : 2
            )
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Height.button)
            .background(
                Theme.Colors.accentGradient
                    .opacity(isEnabled ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.button))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Colors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Height.button)
            .background(Theme.Colors.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.button)
                    .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.bodyBold)
            .foregroundStyle(Theme.Colors.accent)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                configuration.isPressed ?
                Theme.Colors.accent.opacity(0.1) :
                    Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}

// MARK: - Glass Button Styles
// NOTE: iOS 26 provides built-in .glass and .glassProminent button styles
// via Liquid Glass design system. Use .buttonStyle(.glass) directly.
