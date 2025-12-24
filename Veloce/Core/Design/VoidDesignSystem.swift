//
//  VoidDesignSystem.swift
//  Veloce
//
//  Void Design System
//  The cosmic dark aesthetic inspired by Brain Dump
//  Deep blacks, twinkling stars, AI orbs, and ethereal glows
//

import SwiftUI

// MARK: - Void Design System

/// Central namespace for the Void design language
enum VoidDesign {

    // MARK: - Void Colors
    // NOTE: These now reference Theme.CelestialColors for consistency

    enum Colors {
        /// Pure void black for deepest backgrounds
        static var voidBlack: Color { Theme.CelestialColors.void }

        /// Slightly lighter void for layering
        static let voidDeep = Color(white: 0.03)

        /// Void surface for cards on void backgrounds
        static let voidSurface = Color(white: 0.05)

        /// Void elevated for floating elements
        static var voidElevated: Color { Theme.CelestialColors.nebulaDust }

        /// Star particle colors
        static var starWhite: Color { Theme.CelestialColors.starWhite }
        static var starDim: Color { Theme.CelestialColors.starDim }

        // MARK: Void Text Opacity Scale

        /// Primary text on void (full white)
        static var textPrimary: Color { Theme.CelestialColors.starWhite }

        /// Secondary text on void
        static var textSecondary: Color { Theme.CelestialColors.starDim }

        /// Tertiary text on void
        static let textTertiary = Color.white.opacity(0.6)

        /// Quaternary text on void
        static var textQuaternary: Color { Theme.CelestialColors.starGhost }

        /// Hint text on void
        static var textHint: Color { Theme.CelestialColors.starGhost }

        /// Disabled text on void
        static let textDisabled = Color.white.opacity(0.3)
    }

    // MARK: - Animation Timing

    enum Animation {
        /// Orb breathing animation (scale 1.0 → 1.1)
        static let orbBreathing: SwiftUI.Animation = .easeInOut(duration: 2.0).repeatForever(autoreverses: true)

        /// Orb rotation animation (360° continuous)
        static let orbRotation: SwiftUI.Animation = .linear(duration: 8.0).repeatForever(autoreverses: false)

        /// Glow pulse animation
        static let glowPulse: SwiftUI.Animation = .easeInOut(duration: 1.5).repeatForever(autoreverses: true)

        /// Particle orbit animation
        static let particleOrbit: SwiftUI.Animation = .linear(duration: 4.0).repeatForever(autoreverses: false)

        /// Star twinkling base animation
        static func starTwinkle(delay: Double = 0) -> SwiftUI.Animation {
            .easeInOut(duration: Double.random(in: 2...4))
                .repeatForever(autoreverses: true)
                .delay(delay)
        }

        /// Card appearance animation
        static let cardAppear: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.75)

        /// Stagger delay for list items
        static let staggerDelay: Double = 0.1

        /// Status message cycling interval
        static let statusCycle: Double = 2.0

        /// Ring expansion animation
        static let ringExpand: SwiftUI.Animation = .easeInOut(duration: 2.5).repeatForever(autoreverses: true)

        /// Shimmer sweep animation
        static let shimmerSweep: SwiftUI.Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)
    }

    // MARK: - Star Configuration

    enum Stars {
        /// Minimum number of stars for sparse backgrounds
        static let countSparse: Int = 15

        /// Standard number of stars
        static let countStandard: Int = 25

        /// Dense star field
        static let countDense: Int = 40

        /// Star size range
        static let sizeRange: ClosedRange<CGFloat> = 1...3

        /// Star opacity range for twinkling
        static let opacityRange: ClosedRange<Double> = 0.02...0.08

        /// Brighter star opacity range
        static let brightOpacityRange: ClosedRange<Double> = 0.15...0.35
    }

    // MARK: - Orb Sizes

    enum OrbSize: CGFloat {
        case tiny = 16
        case small = 32
        case medium = 60
        case large = 80
        case hero = 120
        case massive = 160
    }

    // MARK: - Glow Positions

    /// Predefined glow positions for different pages
    enum GlowPosition {
        case bottom          // Tasks (productivity energy rising)
        case topTrailing     // Calendar (celestial/time theme)
        case center          // Focus mode (spotlight effect)
        case centerSubtle    // Settings
        case bottomLeading   // Brain dump

        var unitPoint: UnitPoint {
            switch self {
            case .bottom: return .bottom
            case .topTrailing: return .topTrailing
            case .center: return .center
            case .centerSubtle: return .center
            case .bottomLeading: return .bottomLeading
            }
        }

        var intensity: Double {
            switch self {
            case .bottom: return 0.15
            case .topTrailing: return 0.12
            case .center: return 0.2
            case .centerSubtle: return 0.08
            case .bottomLeading: return 0.15
            }
        }

        var radius: CGFloat {
            switch self {
            case .bottom: return 400
            case .topTrailing: return 350
            case .center: return 300
            case .centerSubtle: return 400
            case .bottomLeading: return 400
            }
        }
    }

    // MARK: - Void Card Configuration

    enum Card {
        /// Standard void card border opacity
        static let borderOpacity: Double = 0.3

        /// Selected card border opacity
        static let borderOpacitySelected: Double = 0.5

        /// AI-processed card glow opacity
        static let aiGlowOpacity: Double = 0.4

        /// Default corner radius for void cards
        static let cornerRadius: CGFloat = Theme.CornerRadius.xl

        /// Pressed scale effect
        static let pressedScale: CGFloat = 0.98
    }

    // MARK: - Gradients

    /// Deep void gradient for backgrounds
    static var voidGradient: LinearGradient {
        LinearGradient(
            colors: [
                Colors.voidBlack,
                Colors.voidSurface,
                Colors.voidDeep
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// AI orb gradient (purple → blue → cyan) - uses CelestialColors
    static var orbGradient: LinearGradient {
        Theme.CelestialColors.nebulaGradient
    }

    /// Radial glow gradient for ambient effects
    static func ambientGlow(color: Color = Theme.CelestialColors.nebulaCore, intensity: Double = 0.15) -> RadialGradient {
        RadialGradient(
            colors: [
                color.opacity(intensity),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }

    /// Void card border gradient - uses CelestialColors for consistency
    static func cardBorder(color: Color = Theme.CelestialColors.nebulaCore, opacity: Double = Theme.CelestialColors.glassBorderOpacity) -> LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(opacity),
                color.opacity(opacity * 0.5),
                Theme.CelestialColors.nebulaEdge.opacity(opacity * 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Void Card Modifier

/// Void-styled card modifier for dark cosmic aesthetic
struct VoidCardModifier: ViewModifier {
    let borderColor: Color
    let borderOpacity: Double
    let glowColor: Color?
    let glowOpacity: Double
    let cornerRadius: CGFloat

    init(
        borderColor: Color = Theme.CelestialColors.nebulaCore,
        borderOpacity: Double = Theme.CelestialColors.glassBorderOpacity,
        glowColor: Color? = nil,
        glowOpacity: Double = 0.15,
        cornerRadius: CGFloat = VoidDesign.Card.cornerRadius
    ) {
        self.borderColor = borderColor
        self.borderOpacity = borderOpacity
        self.glowColor = glowColor
        self.glowOpacity = glowOpacity
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base glass material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Subtle dark gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    VoidDesign.Colors.voidSurface.opacity(0.3),
                                    VoidDesign.Colors.voidDeep.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        VoidDesign.cardBorder(color: borderColor, opacity: borderOpacity),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: (glowColor ?? borderColor).opacity(glowOpacity),
                radius: 16,
                x: 0,
                y: 4
            )
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// MARK: - View Extension for Void Card

extension View {
    /// Apply void card styling with cosmic dark aesthetic
    func voidCard(
        borderColor: Color = Theme.CelestialColors.nebulaCore,
        borderOpacity: Double = Theme.CelestialColors.glassBorderOpacity,
        glowColor: Color? = nil,
        glowOpacity: Double = 0.15,
        cornerRadius: CGFloat = VoidDesign.Card.cornerRadius
    ) -> some View {
        modifier(VoidCardModifier(
            borderColor: borderColor,
            borderOpacity: borderOpacity,
            glowColor: glowColor,
            glowOpacity: glowOpacity,
            cornerRadius: cornerRadius
        ))
    }

    /// Apply void card with AI processing glow
    func voidCardAI(animated: Bool = false) -> some View {
        modifier(VoidCardAIModifier(animated: animated))
    }
}

// MARK: - Void Card AI Modifier

/// Enhanced void card with AI glow effect
struct VoidCardAIModifier: ViewModifier {
    @State private var glowPulse: Double = 0.3

    let animated: Bool

    func body(content: Content) -> some View {
        content
            .voidCard(
                borderColor: Theme.CelestialColors.nebulaCore,
                borderOpacity: animated ? glowPulse : VoidDesign.Card.aiGlowOpacity,
                glowColor: Theme.CelestialColors.nebulaCore,
                glowOpacity: animated ? glowPulse * 0.5 : 0.2
            )
            .onAppear {
                if animated {
                    withAnimation(VoidDesign.Animation.glowPulse) {
                        glowPulse = 0.5
                    }
                }
            }
    }
}

// MARK: - Void Text Styles

extension View {
    /// Apply void primary text style
    func voidTextPrimary() -> some View {
        self.foregroundStyle(VoidDesign.Colors.textPrimary)
    }

    /// Apply void secondary text style
    func voidTextSecondary() -> some View {
        self.foregroundStyle(VoidDesign.Colors.textSecondary)
    }

    /// Apply void tertiary text style
    func voidTextTertiary() -> some View {
        self.foregroundStyle(VoidDesign.Colors.textTertiary)
    }

    /// Apply void hint text style
    func voidTextHint() -> some View {
        self.foregroundStyle(VoidDesign.Colors.textHint)
    }
}

// MARK: - Star Particle Model

/// Model for a single star particle in the void background
struct StarParticle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let twinkleDelay: Double
    let isBright: Bool

    static func random(in size: CGSize, isBright: Bool = false) -> StarParticle {
        StarParticle(
            position: CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            ),
            size: CGFloat.random(in: VoidDesign.Stars.sizeRange),
            baseOpacity: isBright
                ? Double.random(in: VoidDesign.Stars.brightOpacityRange)
                : Double.random(in: VoidDesign.Stars.opacityRange),
            twinkleDelay: Double.random(in: 0...2),
            isBright: isBright
        )
    }

    static func generateField(count: Int, in size: CGSize, brightPercentage: Double = 0.1) -> [StarParticle] {
        let brightCount = Int(Double(count) * brightPercentage)
        let dimCount = count - brightCount

        return (0..<dimCount).map { _ in StarParticle.random(in: size, isBright: false) }
            + (0..<brightCount).map { _ in StarParticle.random(in: size, isBright: true) }
    }
}

// MARK: - Preview

#Preview("Void Card") {
    ZStack {
        Color(white: 0.02)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Standard Void Card")
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .voidCard()

            Text("AI Processing Card")
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .voidCardAI(animated: true)

            Text("Custom Glow Card")
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .voidCard(
                    borderColor: Theme.Colors.aiCyan,
                    glowColor: Theme.Colors.aiCyan
                )
        }
        .padding()
    }
}
