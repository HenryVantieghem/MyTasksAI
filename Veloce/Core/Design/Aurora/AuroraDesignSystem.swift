//
//  AuroraDesignSystem.swift
//  Veloce
//
//  Aurora Design System - "Holy Fuck" Level Visual Excellence
//  A living, breathing design language inspired by the Northern Lights
//

import SwiftUI

// MARK: - Aurora Design System

/// The Aurora Design System transforms Veloce into a jaw-dropping visual masterpiece
/// through living aurora backgrounds, prismatic glass, and energy-based interactions.
public enum Aurora {

    // MARK: - Color Spectrum

    /// Core aurora colors - ultra-saturated, vibrant, alive
    public enum Colors {

        // MARK: Primary Aurora Spectrum

        /// Electric Cyan - AI primary, ultra-bright action color
        public static let electricCyan = Color(red: 0.0, green: 0.95, blue: 1.0)

        // MARK: Aliases for compatibility
        public static let violet = borealisViolet
        public static let purple = borealisViolet
        public static let electric = electricCyan
        public static let cyan = electricCyan
        public static let emerald = prismaticGreen
        public static let rose = stellarMagenta
        public static let gold = cosmicGold
        public static let cosmicBlack = voidDeep
        public static let cosmicDeep = voidCosmos
        public static let cosmicSurface = voidNebula
        public static let cosmicElevated = voidElevated
        public static let glassBase = Color.white.opacity(0.08)
        public static let glassBorder = Color.white.opacity(0.15)
        public static let glassHighlight = Color.white.opacity(0.25)
        public static let glassFocused = Color.white.opacity(0.12)
        public static let textQuaternary = Color.white.opacity(0.30)

        /// Borealis Violet - Deep aurora purple, mystical depth
        public static let borealisViolet = Color(red: 0.45, green: 0.15, blue: 0.85)

        /// Stellar Magenta - Vibrant pink energy, celebration
        public static let stellarMagenta = Color(red: 0.95, green: 0.25, blue: 0.75)

        /// Prismatic Green - Northern lights green, vitality
        public static let prismaticGreen = Color(red: 0.15, green: 0.95, blue: 0.55)

        /// Cosmic Gold - Achievement warmth, solar energy
        public static let cosmicGold = Color(red: 1.0, green: 0.75, blue: 0.15)

        /// Deep Plasma - Deep blue plasma, calm energy
        public static let deepPlasma = Color(red: 0.25, green: 0.55, blue: 0.95)

        /// Stellar White - Pure highlight, star core
        public static let stellarWhite = Color(red: 1.0, green: 0.99, blue: 0.95)

        // MARK: Void Backgrounds (Deep Space)

        /// Deep Void - Ultimate darkness, pure black space
        public static let voidDeep = Color(red: 0.01, green: 0.01, blue: 0.02)

        /// Void Cosmos - Main app background
        public static let voidCosmos = Color(red: 0.02, green: 0.02, blue: 0.04)

        /// Void Nebula - Card surfaces, elevated content
        public static let voidNebula = Color(red: 0.04, green: 0.04, blue: 0.06)

        /// Void Indigo - Richer void with purple hint
        public static let voidIndigo = Color(red: 0.08, green: 0.06, blue: 0.12)

        /// Void Elevated - Sheets, modals
        public static let voidElevated = Color(red: 0.06, green: 0.06, blue: 0.10)

        // MARK: Category Colors (Enhanced with Aurora Treatment)

        /// Work category - Electric Teal with cyan glow
        public static let categoryWork = Color(red: 0.0, green: 0.85, blue: 0.85)

        /// Personal category - Sunset Orange with warm halo
        public static let categoryPersonal = Color(red: 1.0, green: 0.55, blue: 0.20)

        /// Creative category - Hot Magenta with particle effects
        public static let categoryCreative = Color(red: 1.0, green: 0.30, blue: 0.65)

        /// Learning category - Vibrant Violet with mystical shimmer
        public static let categoryLearning = Color(red: 0.70, green: 0.35, blue: 1.0)

        /// Health category - Mint with vitality pulse
        public static let categoryHealth = Color(red: 0.20, green: 1.0, blue: 0.70)

        /// Focus category - Electric Cyan (AI)
        public static let categoryFocus = electricCyan

        // MARK: Semantic Colors

        /// Success - Aurora green bloom
        public static let success = prismaticGreen

        /// Warning - Cosmic gold pulse
        public static let warning = cosmicGold

        /// Error - Soft red (cosmic, not harsh)
        public static let error = Color(red: 1.0, green: 0.35, blue: 0.40)

        /// AI Accent - Electric cyan
        public static let aiAccent = electricCyan

        // MARK: Text Colors

        /// Primary text - near white
        public static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.97)

        /// Secondary text - muted
        public static let textSecondary = Color(red: 0.65, green: 0.65, blue: 0.70)

        /// Tertiary text - subtle
        public static let textTertiary = Color(red: 0.45, green: 0.45, blue: 0.50)

        /// AI Whisper text - cyan tinted
        public static let textAIWhisper = Color(red: 0.70, green: 0.90, blue: 0.95)
    }

    // MARK: - Gradients

    public enum Gradients {

        /// Aurora horizontal gradient (alias)
        public static var auroraHorizontal: LinearGradient {
            LinearGradient(
                colors: [Colors.electricCyan, Colors.borealisViolet],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        /// Aurora gradient (alias)
        public static var aurora: LinearGradient {
            aiGradient
        }

        /// Full aurora spectrum gradient (7 colors)
        public static var auroraSpectrum: [Color] {
            [
                Colors.electricCyan,
                Colors.deepPlasma,
                Colors.borealisViolet,
                Colors.stellarMagenta,
                Colors.cosmicGold,
                Colors.prismaticGreen,
                Colors.electricCyan
            ]
        }

        /// Primary AI gradient (cyan → violet)
        public static var aiGradient: LinearGradient {
            LinearGradient(
                colors: [Colors.electricCyan, Colors.borealisViolet],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Primary button gradient (cyan → violet → magenta)
        public static var primaryButton: LinearGradient {
            LinearGradient(
                colors: [Colors.electricCyan, Colors.borealisViolet, Colors.stellarMagenta],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        /// Success gradient (green → cyan)
        public static var successGradient: LinearGradient {
            LinearGradient(
                colors: [Colors.prismaticGreen, Colors.electricCyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Gold achievement gradient
        public static var achievementGradient: LinearGradient {
            LinearGradient(
                colors: [Colors.cosmicGold, Colors.stellarMagenta.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Void gradient (background depth)
        public static var voidGradient: LinearGradient {
            LinearGradient(
                colors: [Colors.voidDeep, Colors.voidCosmos, Colors.voidIndigo.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        /// Prismatic angular gradient (for borders)
        public static func prismaticBorder(phase: Double = 0) -> AngularGradient {
            AngularGradient(
                colors: auroraSpectrum,
                center: .center,
                startAngle: .degrees(phase),
                endAngle: .degrees(phase + 360)
            )
        }

        /// Time-of-day aurora gradient
        public static func timeOfDayAurora(for date: Date = Date()) -> [Color] {
            let hour = Calendar.current.component(.hour, from: date)

            switch hour {
            case 5..<9: // Dawn
                return [Colors.stellarMagenta.opacity(0.6), Colors.cosmicGold, Colors.electricCyan]
            case 9..<17: // Day
                return [Colors.electricCyan, Colors.borealisViolet]
            case 17..<21: // Dusk
                return [Colors.stellarMagenta, Colors.borealisViolet, Colors.deepPlasma]
            default: // Night
                return [Colors.borealisViolet, Colors.voidIndigo, Colors.deepPlasma]
            }
        }

        /// Category-specific gradient
        public static func categoryGradient(_ category: String?) -> LinearGradient {
            let baseColor: Color
            switch category?.lowercased() {
            case "work": baseColor = Colors.categoryWork
            case "personal": baseColor = Colors.categoryPersonal
            case "creative": baseColor = Colors.categoryCreative
            case "learning": baseColor = Colors.categoryLearning
            case "health": baseColor = Colors.categoryHealth
            default: baseColor = Colors.electricCyan
            }

            return LinearGradient(
                colors: [baseColor, baseColor.opacity(0.7), baseColor.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Spacing (Fibonacci-based for organic rhythm)

    public enum Spacing {
        /// 2pt - Micro spacing
        public static let micro: CGFloat = 2

        /// 4pt - Extra small
        public static let xs: CGFloat = 4

        /// 8pt - Small
        public static let sm: CGFloat = 8

        /// 13pt - Medium (Fibonacci)
        public static let md: CGFloat = 13

        /// 16pt - Standard
        public static let standard: CGFloat = 16

        /// 21pt - Large (Fibonacci)
        public static let lg: CGFloat = 21

        /// 34pt - Extra large (Fibonacci)
        public static let xl: CGFloat = 34

        /// 55pt - 2X large (Fibonacci)
        public static let xxl: CGFloat = 55

        /// 89pt - 3X large (Fibonacci)
        public static let xxxl: CGFloat = 89

        // Semantic spacing
        public static let screenPadding: CGFloat = 20
        public static let universalHeaderHeight: CGFloat = 60
    }

    // MARK: - Animation

    public enum Animation {
        public static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        public static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        public static let bouncy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.55)
    }

    // MARK: - Layout

    public enum Layout {
        public static let cardPadding: CGFloat = 16
        public static let screenPadding: CGFloat = 20
        public static let maxContentWidth: CGFloat = 600
    }

    // MARK: - Size

    public enum Size {
        public static let small: CGFloat = 32
        public static let medium: CGFloat = 44
        public static let large: CGFloat = 56
        public static let orbDefault: CGFloat = 80
        public static let orbHero: CGFloat = 120
    }

    // MARK: - Corner Radii (Continuous curves)

    public enum Radius {
        /// 4pt - Subtle
        public static let subtle: CGFloat = 4

        /// 8pt - Small (pills, chips)
        public static let small: CGFloat = 8

        /// 12pt - Medium
        public static let medium: CGFloat = 12

        /// 16pt - Standard (cards)
        public static let standard: CGFloat = 16

        /// 20pt - Large
        public static let large: CGFloat = 20

        /// 24pt - Prominent (sheets)
        public static let prominent: CGFloat = 24

        /// 32pt - Dramatic (hero elements)
        public static let dramatic: CGFloat = 32

        /// Maximum (pill shape)
        public static let pill: CGFloat = 9999

        // Semantic aliases
        public static let card: CGFloat = 16
        public static let textField: CGFloat = 12
        public static let xxl: CGFloat = 28
    }

    // MARK: - Shadows (3-tier elevation system)

    public enum Shadow {

        /// Resting shadow - subtle depth
        public static func resting(color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color.opacity(0.25), 8, 0, 2)
        }

        /// Floating shadow - elevated elements
        public static func floating(color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color.opacity(0.35), 20, 0, 8)
        }

        /// Elevated shadow - maximum depth
        public static func elevated(color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color.opacity(0.45), 32, 0, 12)
        }

        /// Aurora glow shadow - colored halo effect
        public static func auroraGlow(color: Color, intensity: CGFloat = 0.35) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color.opacity(intensity), 16, 0, 4)
        }

        /// Category glow - task card category halo
        public static func categoryGlow(color: Color) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color.opacity(0.4), 12, 0, 6)
        }
    }

    // MARK: - Typography

    public enum Typography {

        /// Display - Hero numbers, major stats (64pt)
        public static let display = Font.system(size: 64, weight: .black, design: .rounded)

        /// Title 1 - Page titles (34pt)
        public static let title1 = Font.system(size: 34, weight: .heavy, design: .rounded)

        /// Title 2 - Section headers (28pt)
        public static let title2 = Font.system(size: 28, weight: .bold, design: .rounded)

        /// Title 3 - Card titles (22pt)
        public static let title3 = Font.system(size: 22, weight: .bold, design: .rounded)

        /// Headline - Important labels (18pt)
        public static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)

        /// Body - Standard text (17pt)
        public static let body = Font.system(size: 17, weight: .regular, design: .rounded)

        /// Body Bold
        public static let bodyBold = Font.system(size: 17, weight: .semibold, design: .rounded)

        /// Callout - Secondary text (16pt)
        public static let callout = Font.system(size: 16, weight: .medium, design: .rounded)

        /// Subheadline (15pt)
        public static let subheadline = Font.system(size: 15, weight: .medium, design: .rounded)

        /// Footnote (13pt)
        public static let footnote = Font.system(size: 13, weight: .medium, design: .rounded)

        /// Caption (12pt)
        public static let caption = Font.system(size: 12, weight: .medium, design: .rounded)

        /// Micro - Tiny labels (10pt)
        public static let micro = Font.system(size: 10, weight: .semibold, design: .rounded)

        /// AI Whisper - Mystical AI text (14pt italic serif)
        public static let aiWhisper = Font.system(size: 14, weight: .regular, design: .serif).italic()

        /// Monospace - Timestamps, codes (13pt)
        public static let monospace = Font.system(size: 13, weight: .medium, design: .monospaced)

        /// Display Thin - Editorial hero text (48pt)
        public static let displayThin = Font.system(size: 48, weight: .ultraLight, design: .default)

        // Aliases for compatibility
        public static let meta = Font.system(size: 11, weight: .medium, design: .rounded)
        public static let caption2 = Font.system(size: 10, weight: .medium, design: .rounded)
        public static let statSmall = Font.system(size: 14, weight: .bold, design: .rounded)
    }

    // MARK: - Blur Radii

    public enum Blur {
        /// Subtle blur (8pt)
        public static let subtle: CGFloat = 8

        /// Standard blur (16pt)
        public static let standard: CGFloat = 16

        /// Medium blur (24pt)
        public static let medium: CGFloat = 24

        /// Heavy blur (40pt)
        public static let heavy: CGFloat = 40

        /// Aurora wave blur (60pt)
        public static let auroraWave: CGFloat = 60

        /// Bloom effect blur (80pt)
        public static let bloom: CGFloat = 80
    }

    // MARK: - Particle Counts

    public enum Particles {
        /// Firefly constellation (ambient)
        public static let firefly: Int = 40

        /// Energy dust trail (completion)
        public static let dustTrail: Int = 30

        /// Supernova burst (celebration)
        public static let supernova: Int = 32

        /// Confetti shower (milestone)
        public static let confetti: Int = 80

        /// Mini burst (checkbox)
        public static let miniBurst: Int = 16

        /// Ambient stars (background)
        public static let stars: Int = 35
    }

    // MARK: - Glow Intensities

    public enum GlowIntensity {
        /// Dormant - barely visible (0.15)
        public static let dormant: CGFloat = 0.15

        /// Subtle - soft glow (0.25)
        public static let subtle: CGFloat = 0.25

        /// Standard - normal glow (0.35)
        public static let standard: CGFloat = 0.35

        /// Intense - bright glow (0.5)
        public static let intense: CGFloat = 0.5

        /// Maximum - full bloom (0.7)
        public static let maximum: CGFloat = 0.7

        /// Supernova - overwhelming (0.9)
        public static let supernova: CGFloat = 0.9
    }

    // MARK: - iOS Version Detection

    /// Check if iOS 26+ is available for native Liquid Glass
    public static var supportsLiquidGlass: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }

    /// Check if device supports high refresh rate
    public static var supportsProMotion: Bool {
        UIScreen.main.maximumFramesPerSecond >= 120
    }
}

// MARK: - Color Extensions

extension Color {

    /// Create aurora gradient text effect
    func auroraGradient() -> LinearGradient {
        LinearGradient(
            colors: [self, self.opacity(0.8), Aurora.Colors.borealisViolet],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - View Extensions

extension View {

    /// Apply aurora void background
    func auroraVoidBackground() -> some View {
        self.background(Aurora.Gradients.voidGradient)
    }

    /// Apply aurora glow shadow
    func auroraGlow(color: Color, intensity: CGFloat = Aurora.GlowIntensity.standard, radius: CGFloat = 16) -> some View {
        self.shadow(color: color.opacity(intensity), radius: radius, x: 0, y: 4)
    }

    /// Apply category-specific glow
    func categoryGlow(_ category: String?) -> some View {
        let color: Color
        switch category?.lowercased() {
        case "work": color = Aurora.Colors.categoryWork
        case "personal": color = Aurora.Colors.categoryPersonal
        case "creative": color = Aurora.Colors.categoryCreative
        case "learning": color = Aurora.Colors.categoryLearning
        case "health": color = Aurora.Colors.categoryHealth
        default: color = Aurora.Colors.electricCyan
        }
        return self.auroraGlow(color: color)
    }

    /// Apply shimmer effect overlay
    func auroraShimmer(isActive: Bool = true, duration: Double = 3.0) -> some View {
        self.modifier(AuroraShimmerModifier(isActive: isActive, duration: duration))
    }
}

// MARK: - Shimmer Modifier

struct AuroraShimmerModifier: ViewModifier {
    let isActive: Bool
    let duration: Double

    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                Aurora.Colors.stellarWhite.opacity(0.3),
                                Aurora.Colors.electricCyan.opacity(0.2),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.5)
                        .offset(x: phase * geometry.size.width * 1.5)
                        .onAppear {
                            withAnimation(
                                .linear(duration: duration)
                                .repeatForever(autoreverses: false)
                            ) {
                                phase = 1
                            }
                        }
                    }
                }
                .mask(content)
            )
    }
}

// MARK: - Preview

#Preview("Aurora Colors") {
    ScrollView {
        VStack(spacing: Aurora.Spacing.lg) {
            // Primary Spectrum
            VStack(alignment: .leading, spacing: Aurora.Spacing.sm) {
                Text("Primary Spectrum")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                HStack(spacing: Aurora.Spacing.xs) {
                    colorSwatch(Aurora.Colors.electricCyan, "Cyan")
                    colorSwatch(Aurora.Colors.borealisViolet, "Violet")
                    colorSwatch(Aurora.Colors.stellarMagenta, "Magenta")
                    colorSwatch(Aurora.Colors.prismaticGreen, "Green")
                }

                HStack(spacing: Aurora.Spacing.xs) {
                    colorSwatch(Aurora.Colors.cosmicGold, "Gold")
                    colorSwatch(Aurora.Colors.deepPlasma, "Plasma")
                    colorSwatch(Aurora.Colors.stellarWhite, "White")
                }
            }

            // Void Backgrounds
            VStack(alignment: .leading, spacing: Aurora.Spacing.sm) {
                Text("Void Backgrounds")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                HStack(spacing: Aurora.Spacing.xs) {
                    colorSwatch(Aurora.Colors.voidDeep, "Deep")
                    colorSwatch(Aurora.Colors.voidCosmos, "Cosmos")
                    colorSwatch(Aurora.Colors.voidNebula, "Nebula")
                    colorSwatch(Aurora.Colors.voidIndigo, "Indigo")
                }
            }

            // Category Colors
            VStack(alignment: .leading, spacing: Aurora.Spacing.sm) {
                Text("Category Colors")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                HStack(spacing: Aurora.Spacing.xs) {
                    colorSwatch(Aurora.Colors.categoryWork, "Work")
                    colorSwatch(Aurora.Colors.categoryPersonal, "Personal")
                    colorSwatch(Aurora.Colors.categoryCreative, "Creative")
                }

                HStack(spacing: Aurora.Spacing.xs) {
                    colorSwatch(Aurora.Colors.categoryLearning, "Learning")
                    colorSwatch(Aurora.Colors.categoryHealth, "Health")
                }
            }

            // Gradients
            VStack(alignment: .leading, spacing: Aurora.Spacing.sm) {
                Text("Gradients")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                RoundedRectangle(cornerRadius: Aurora.Radius.standard)
                    .fill(Aurora.Gradients.primaryButton)
                    .frame(height: 50)
                    .overlay(
                        Text("Primary Button")
                            .font(Aurora.Typography.bodyBold)
                            .foregroundStyle(.white)
                    )

                RoundedRectangle(cornerRadius: Aurora.Radius.standard)
                    .fill(Aurora.Gradients.aiGradient)
                    .frame(height: 50)
                    .overlay(
                        Text("AI Gradient")
                            .font(Aurora.Typography.bodyBold)
                            .foregroundStyle(.white)
                    )

                RoundedRectangle(cornerRadius: Aurora.Radius.standard)
                    .fill(Aurora.Gradients.successGradient)
                    .frame(height: 50)
                    .overlay(
                        Text("Success")
                            .font(Aurora.Typography.bodyBold)
                            .foregroundStyle(.white)
                    )
            }
        }
        .padding(Aurora.Spacing.lg)
    }
    .background(Aurora.Colors.voidCosmos)
}

@ViewBuilder
private func colorSwatch(_ color: Color, _ name: String) -> some View {
    VStack(spacing: Aurora.Spacing.xs) {
        RoundedRectangle(cornerRadius: Aurora.Radius.small)
            .fill(color)
            .frame(width: 60, height: 60)
            .auroraGlow(color: color, intensity: 0.4)

        Text(name)
            .font(Aurora.Typography.caption)
            .foregroundStyle(Aurora.Colors.textSecondary)
    }
}
