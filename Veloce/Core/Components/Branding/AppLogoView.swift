//
//  AppLogoView.swift
//  Veloce
//
//  App Logo - Pure Spherical Glowing Orb
//  Premium 3D orb with concentric glow rings and orbiting particles
//

import SwiftUI

// MARK: - App Logo View

/// Main app logo component - delegates to GlowingOrbLogo
/// This is the primary logo used throughout the app
struct AppLogoView: View {
    let size: LogoSize
    var isAnimating: Bool = true
    var showParticles: Bool = true
    var intensity: Double = 1.0

    var body: some View {
        GlowingOrbLogo(
            size: size,
            isAnimating: isAnimating,
            showParticles: showParticles,
            intensity: intensity
        )
    }
}

// MARK: - Particle Field

struct ParticleField: View {
    let phase: Double
    let size: CGFloat

    private let particleCount = 12

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                ParticleView(
                    index: index,
                    totalCount: particleCount,
                    phase: phase,
                    fieldSize: size
                )
            }
        }
    }
}

struct ParticleView: View {
    let index: Int
    let totalCount: Int
    let phase: Double
    let fieldSize: CGFloat

    private var particleConfig: ParticleConfig {
        let seed = Double(index)
        let baseAngle = (seed / Double(totalCount)) * 2 * .pi
        let orbitRadius = fieldSize * (0.35 + sin(seed * 1.7) * 0.15)
        let particleSize = fieldSize * (0.02 + sin(seed * 2.3) * 0.01)
        let speed = 0.5 + sin(seed * 1.3) * 0.3
        let opacity = 0.4 + sin(seed * 2.1) * 0.3

        return ParticleConfig(
            baseAngle: baseAngle,
            orbitRadius: orbitRadius,
            particleSize: particleSize,
            speed: speed,
            opacity: opacity
        )
    }

    var body: some View {
        let config = particleConfig
        let currentAngle = config.baseAngle + phase * 2 * .pi * config.speed
        let x = cos(currentAngle) * config.orbitRadius
        let y = sin(currentAngle) * config.orbitRadius * 0.6 // Elliptical orbit

        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(config.opacity),
                        Color(hex: "06B6D4").opacity(config.opacity * 0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: config.particleSize
                )
            )
            .frame(width: config.particleSize * 2, height: config.particleSize * 2)
            .offset(x: x, y: y)
            .blur(radius: config.particleSize * 0.3)
    }
}

struct ParticleConfig {
    let baseAngle: Double
    let orbitRadius: CGFloat
    let particleSize: CGFloat
    let speed: Double
    let opacity: Double
}

// MARK: - Logo Size

enum LogoSize {
    case tiny      // 24pt - Tab bar, small icons
    case small     // 40pt - Navigation, buttons
    case medium    // 80pt - Cards, headers
    case large     // 120pt - Splash, onboarding
    case hero      // 200pt - Auth screen hero

    var dimension: CGFloat {
        switch self {
        case .tiny: return 24
        case .small: return 40
        case .medium: return 80
        case .large: return 120
        case .hero: return 200
        }
    }

    var showGlow: Bool {
        switch self {
        case .tiny, .small: return false
        case .medium, .large, .hero: return true
        }
    }

    var showParticles: Bool {
        switch self {
        case .tiny, .small, .medium: return false
        case .large, .hero: return true
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            AppLogoView(size: .hero)

            HStack(spacing: 30) {
                AppLogoView(size: .large)
                AppLogoView(size: .medium)
            }

            HStack(spacing: 20) {
                AppLogoView(size: .small)
                AppLogoView(size: .tiny)
            }
        }
    }
}
