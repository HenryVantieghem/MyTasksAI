//
//  LogoVariants.swift
//  Veloce
//
//  Logo Variants - Static and specialized versions
//  Now using pure spherical orb design throughout
//

import SwiftUI

// MARK: - Static Logo (Now uses StaticOrbLogo)

/// Non-animated logo for performance-sensitive contexts
/// Delegates to the new StaticOrbLogo implementation
struct StaticLogoView: View {
    let size: LogoSize
    var tintColor: Color? = nil

    var body: some View {
        StaticOrbLogo(size: size, intensity: tintColor != nil ? 0.8 : 1.0)
    }
}

// MARK: - Loading Logo (Now uses LoadingOrbLogo)

/// Logo with pulsing animation for loading states
struct LoadingLogoView: View {
    let size: LogoSize

    var body: some View {
        LoadingOrbLogo(size: size)
    }
}

// MARK: - Success Logo Burst (Now uses SuccessOrbBurst)

/// Logo that bursts into particles on success
/// Delegates to the new SuccessOrbBurst implementation
struct SuccessLogoBurst: View {
    let size: LogoSize
    @Binding var shouldBurst: Bool

    var body: some View {
        SuccessOrbBurst(size: size, shouldBurst: $shouldBurst)
    }
}

// MARK: - Monochrome Logo

/// Single-color logo for specific UI contexts
struct MonochromeLogo: View {
    let size: LogoSize
    let color: Color

    var body: some View {
        ZStack {
            // Glow in specified color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.6
                    )
                )
                .frame(width: size.dimension * 1.2, height: size.dimension * 1.2)
                .blur(radius: size.dimension * 0.1)

            // Core orb in specified color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color,
                            color.opacity(0.7),
                            color.opacity(0.3)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size.dimension * 0.25
                    )
                )
                .frame(width: size.dimension * 0.5, height: size.dimension * 0.5)

            // White hot center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.12
                    )
                )
                .frame(width: size.dimension * 0.25, height: size.dimension * 0.25)

            // Top highlight
            Ellipse()
                .fill(Color.white.opacity(0.4))
                .frame(width: size.dimension * 0.1, height: size.dimension * 0.05)
                .offset(x: -size.dimension * 0.05, y: -size.dimension * 0.08)
                .blur(radius: 1)
        }
        .frame(width: size.dimension, height: size.dimension)
        .opacity(0.8)
    }
}

// MARK: - Logo with Text (Now uses OrbLogoWithText internally)

struct LogoWithText: View {
    let size: LogoSize
    var showTagline: Bool = true
    var isAnimating: Bool = true

    var body: some View {
        VStack(spacing: textSpacing) {
            AppLogoView(size: size, isAnimating: isAnimating)

            VStack(spacing: 4) {
                // Editorial thin typography from Auth design
                Text("MyTasksAI")
                    .font(titleFont)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if showTagline {
                    Text("INFINITE PRODUCTIVITY")
                        .font(taglineFont)
                        .foregroundStyle(Color(hex: "06B6D4").opacity(0.7))
                        .tracking(taglineTracking)
                }
            }
        }
    }

    private var textSpacing: CGFloat {
        switch size {
        case .tiny, .small: return 8
        case .medium: return 16
        case .large: return 24
        case .hero: return 32
        }
    }

    // Updated to use thin weight like Auth screen
    private var titleFont: Font {
        switch size {
        case .tiny, .small: return .system(size: 14, weight: .thin, design: .default)
        case .medium: return .system(size: 20, weight: .thin, design: .default)
        case .large: return .system(size: 28, weight: .thin, design: .default)
        case .hero: return .system(size: 42, weight: .thin, design: .default)
        }
    }

    private var taglineFont: Font {
        switch size {
        case .tiny, .small: return .system(size: 8, weight: .medium)
        case .medium: return .system(size: 10, weight: .medium)
        case .large: return .system(size: 12, weight: .medium)
        case .hero: return .system(size: 14, weight: .medium)
        }
    }

    private var taglineTracking: CGFloat {
        switch size {
        case .tiny, .small: return 1
        case .medium: return 1.5
        case .large, .hero: return 2
        }
    }
}

// MARK: - App Icon Generator View

/// For generating app icon assets - uses static orb
struct AppIconView: View {
    let iconSize: CGFloat

    private let gradientColors: [Color] = [
        Color(hex: "8B5CF6"),
        Color(hex: "6366F1"),
        Color(hex: "3B82F6"),
        Color(hex: "0EA5E9"),
        Color(hex: "06B6D4"),
        Color(hex: "14B8A6"),
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0F0A1A"),
                    Color(hex: "1A0F2E"),
                    Color(hex: "0F0A1A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Atmospheric glow
            RadialGradient(
                colors: [
                    gradientColors[0].opacity(0.4),
                    gradientColors[2].opacity(0.2),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: iconSize * 0.5
            )

            // Main orb
            Circle()
                .fill(
                    AngularGradient(
                        colors: gradientColors + [gradientColors[0]],
                        center: .center
                    )
                )
                .frame(width: iconSize * 0.35, height: iconSize * 0.35)

            // Inner core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: iconSize * 0.12
                    )
                )
                .frame(width: iconSize * 0.25, height: iconSize * 0.25)

            // Top highlight
            Ellipse()
                .fill(Color.white.opacity(0.5))
                .frame(width: iconSize * 0.08, height: iconSize * 0.04)
                .offset(x: -iconSize * 0.04, y: -iconSize * 0.08)
                .blur(radius: 2)

            // Outer glow ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: gradientColors.map { $0.opacity(0.4) } + [gradientColors[0].opacity(0.4)],
                        center: .center
                    ),
                    lineWidth: iconSize * 0.015
                )
                .frame(width: iconSize * 0.45, height: iconSize * 0.45)
                .blur(radius: iconSize * 0.02)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// MARK: - Custom Logo Size Extension

extension LogoSize {
    static func custom(dimension: CGFloat) -> LogoSize {
        if dimension <= 24 { return .tiny }
        if dimension <= 40 { return .small }
        if dimension <= 80 { return .medium }
        if dimension <= 120 { return .large }
        return .hero
    }
}

// MARK: - Previews

#Preview("Logo Variants") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            StaticLogoView(size: .large)

            HStack(spacing: 20) {
                StaticLogoView(size: .medium)
                StaticLogoView(size: .small)
                StaticLogoView(size: .tiny)
            }

            MonochromeLogo(size: .medium, color: .green)
        }
    }
}

#Preview("Logo With Text") {
    ZStack {
        Color.black.ignoresSafeArea()
        LogoWithText(size: .hero)
    }
}

#Preview("App Icon") {
    AppIconView(iconSize: 200)
}
