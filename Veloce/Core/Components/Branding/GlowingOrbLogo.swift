//
//  GlowingOrbLogo.swift
//  Veloce
//
//  Pure Spherical Glowing Orb Logo
//  Premium 3D orb with concentric glow rings and orbiting particles
//

import SwiftUI

// MARK: - Glowing Orb Logo

/// Pure spherical glowing orb logo replacing the infinity curve
/// Features:
/// - 3D sphere with radial gradient
/// - White-hot inner core
/// - 3 concentric pulsing glow rings
/// - 8 orbiting particles
/// - Breathing animation
struct GlowingOrbLogo: View {
    let size: LogoSize
    var isAnimating: Bool = true
    var showParticles: Bool = true
    var intensity: Double = 1.0

    // Animation states
    @State private var breathePhase: Double = 0
    @State private var glowRingPhase: Double = 0
    @State private var gradientRotation: Double = 0
    @State private var particleOrbitPhase: Double = 0
    @State private var innerPulsePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Gradient Colors (Same as original logo)

    private let gradientColors: [Color] = [
        Color(hex: "8B5CF6"), // Purple
        Color(hex: "6366F1"), // Indigo
        Color(hex: "3B82F6"), // Blue
        Color(hex: "0EA5E9"), // Sky
        Color(hex: "06B6D4"), // Cyan
        Color(hex: "14B8A6"), // Teal
    ]

    var body: some View {
        ZStack {
            // Layer 1: Outer atmospheric glow
            if size.showGlow {
                atmosphericGlow
            }

            // Layer 2: Concentric glow rings (pulsing outward)
            if size.showGlow {
                concentricGlowRings
            }

            // Layer 3: Orbiting particles
            if showParticles && size.showParticles && !reduceMotion {
                orbitingParticles
            }

            // Layer 4: Main orb sphere
            orbSphere

            // Layer 5: Inner hot core
            innerCore

            // Layer 6: Top highlight (3D effect)
            topHighlight
        }
        .frame(width: size.dimension, height: size.dimension)
        .onAppear {
            guard isAnimating && !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Atmospheric Glow

    private var atmosphericGlow: some View {
        ZStack {
            // Primary atmospheric halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            gradientColors[0].opacity(0.25 * intensity),
                            gradientColors[2].opacity(0.15 * intensity),
                            gradientColors[4].opacity(0.08 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size.dimension * 0.2,
                        endRadius: size.dimension * 0.8
                    )
                )
                .frame(width: size.dimension * 1.6, height: size.dimension * 1.6)
                .blur(radius: size.dimension * 0.2)

            // Secondary color wash
            Circle()
                .fill(
                    AngularGradient(
                        colors: gradientColors + [gradientColors[0]],
                        center: .center,
                        angle: .degrees(gradientRotation)
                    )
                )
                .frame(width: size.dimension * 1.3, height: size.dimension * 1.3)
                .blur(radius: size.dimension * 0.35)
                .opacity(0.2 * intensity)
        }
    }

    // MARK: - Concentric Glow Rings

    private var concentricGlowRings: some View {
        ZStack {
            // Ring 1 - Innermost (brightest)
            glowRing(
                radiusMultiplier: 0.55 + glowRingPhase * 0.05,
                opacity: 0.6 - glowRingPhase * 0.2,
                strokeWidth: size.dimension * 0.03
            )

            // Ring 2 - Middle
            glowRing(
                radiusMultiplier: 0.65 + glowRingPhase * 0.08,
                opacity: 0.4 - glowRingPhase * 0.15,
                strokeWidth: size.dimension * 0.02
            )

            // Ring 3 - Outermost (faintest)
            glowRing(
                radiusMultiplier: 0.75 + glowRingPhase * 0.1,
                opacity: 0.2 - glowRingPhase * 0.1,
                strokeWidth: size.dimension * 0.015
            )
        }
    }

    private func glowRing(radiusMultiplier: Double, opacity: Double, strokeWidth: CGFloat) -> some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: gradientColors.map { $0.opacity(max(0, opacity * intensity)) } + [gradientColors[0].opacity(max(0, opacity * intensity))],
                    center: .center,
                    angle: .degrees(gradientRotation * 0.5)
                ),
                lineWidth: strokeWidth
            )
            .frame(
                width: size.dimension * radiusMultiplier,
                height: size.dimension * radiusMultiplier
            )
            .blur(radius: strokeWidth * 2)
    }

    // MARK: - Orbiting Particles

    private var orbitingParticles: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                OrbParticle(
                    index: index,
                    totalCount: 8,
                    phase: particleOrbitPhase,
                    orbRadius: size.dimension * 0.42,
                    particleSize: size.dimension * 0.04,
                    color: gradientColors[index % gradientColors.count]
                )
            }
        }
    }

    // MARK: - Main Orb Sphere

    private var orbSphere: some View {
        ZStack {
            // Base sphere with conic gradient (rotating)
            Circle()
                .fill(
                    AngularGradient(
                        colors: gradientColors + [gradientColors[0]],
                        center: .center,
                        angle: .degrees(gradientRotation)
                    )
                )
                .frame(width: size.dimension * 0.5, height: size.dimension * 0.5)

            // 3D depth overlay - darker at edges
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.3)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: size.dimension * 0.1,
                        endRadius: size.dimension * 0.3
                    )
                )
                .frame(width: size.dimension * 0.5, height: size.dimension * 0.5)

            // Gradient overlay for richness
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            gradientColors[0].opacity(0.4),
                            gradientColors[2].opacity(0.3),
                            gradientColors[4].opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.25
                    )
                )
                .frame(width: size.dimension * 0.5, height: size.dimension * 0.5)
                .blendMode(.overlay)
        }
        .scaleEffect(1.0 + breathePhase * 0.04)
    }

    // MARK: - Inner Hot Core

    private var innerCore: some View {
        ZStack {
            // White hot center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95 + innerPulsePhase * 0.05),
                            Color.white.opacity(0.7),
                            gradientColors[4].opacity(0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.18
                    )
                )
                .frame(width: size.dimension * 0.35, height: size.dimension * 0.35)
                .blur(radius: size.dimension * 0.02)

            // Inner glow pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6 + innerPulsePhase * 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.12
                    )
                )
                .frame(width: size.dimension * 0.25, height: size.dimension * 0.25)
                .blur(radius: size.dimension * 0.015)
        }
        .scaleEffect(1.0 + breathePhase * 0.06)
    }

    // MARK: - Top Highlight (3D Effect)

    private var topHighlight: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.5),
                        Color.white.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.dimension * 0.1
                )
            )
            .frame(width: size.dimension * 0.15, height: size.dimension * 0.08)
            .offset(x: -size.dimension * 0.08, y: -size.dimension * 0.12)
            .blur(radius: size.dimension * 0.01)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Breathing animation (3s cycle)
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breathePhase = 1.0
        }

        // Glow ring pulse (2s staggered cycle)
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowRingPhase = 1.0
        }

        // Gradient rotation (8s continuous)
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }

        // Particle orbit (10s continuous)
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            particleOrbitPhase = 1.0
        }

        // Inner core pulse (1.5s fast pulse)
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            innerPulsePhase = 1.0
        }
    }
}

// MARK: - Orb Particle

private struct OrbParticle: View {
    let index: Int
    let totalCount: Int
    let phase: Double
    let orbRadius: CGFloat
    let particleSize: CGFloat
    let color: Color

    private var config: (baseAngle: Double, speed: Double, verticalOffset: Double) {
        let seed = Double(index)
        let baseAngle = (seed / Double(totalCount)) * 2 * .pi
        let speed = 0.7 + sin(seed * 1.5) * 0.3 // Varying speeds
        let verticalOffset = sin(seed * 2.3) * 0.3 // Different orbital planes
        return (baseAngle, speed, verticalOffset)
    }

    var body: some View {
        let (baseAngle, speed, verticalOffset) = config
        let currentAngle = baseAngle + phase * 2 * .pi * speed

        // Elliptical orbit with varying inclination
        let x = cos(currentAngle) * orbRadius
        let y = sin(currentAngle) * orbRadius * (0.5 + verticalOffset * 0.3)

        // Depth-based opacity (particles in "front" are brighter)
        let depthOpacity = 0.5 + sin(currentAngle) * 0.3

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        color.opacity(depthOpacity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: particleSize
                )
            )
            .frame(width: particleSize * 2, height: particleSize * 2)
            .offset(x: x, y: y)
            .blur(radius: particleSize * 0.2)
    }
}

// MARK: - Static Orb Logo (Non-animated variant)

struct StaticOrbLogo: View {
    let size: LogoSize
    var intensity: Double = 1.0

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
            // Atmospheric glow
            if size.showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                gradientColors[0].opacity(0.2 * intensity),
                                gradientColors[2].opacity(0.1 * intensity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size.dimension * 0.2,
                            endRadius: size.dimension * 0.7
                        )
                    )
                    .frame(width: size.dimension * 1.4, height: size.dimension * 1.4)
                    .blur(radius: size.dimension * 0.15)
            }

            // Main orb
            Circle()
                .fill(
                    AngularGradient(
                        colors: gradientColors + [gradientColors[0]],
                        center: .center
                    )
                )
                .frame(width: size.dimension * 0.5, height: size.dimension * 0.5)

            // Inner core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.15
                    )
                )
                .frame(width: size.dimension * 0.3, height: size.dimension * 0.3)

            // Top highlight
            Ellipse()
                .fill(Color.white.opacity(0.4))
                .frame(width: size.dimension * 0.12, height: size.dimension * 0.06)
                .offset(x: -size.dimension * 0.06, y: -size.dimension * 0.1)
                .blur(radius: 2)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}

// MARK: - Loading Orb Logo (Pulsing variant)

struct LoadingOrbLogo: View {
    let size: LogoSize
    @State private var pulsePhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlowingOrbLogo(size: size, isAnimating: true, showParticles: false, intensity: 0.8 + pulsePhase * 0.4)
            .opacity(0.7 + pulsePhase * 0.3)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulsePhase = 1.0
                }
            }
    }
}

// MARK: - Success Orb Burst (Celebration effect)

struct SuccessOrbBurst: View {
    let size: LogoSize
    @Binding var shouldBurst: Bool

    @State private var burstParticles: [BurstParticle] = []
    @State private var showCheckmark = false

    private let gradientColors: [Color] = [
        Color(hex: "8B5CF6"),
        Color(hex: "3B82F6"),
        Color(hex: "06B6D4"),
        Color(hex: "14B8A6"),
        Color(hex: "22C55E"), // Success green
    ]

    var body: some View {
        ZStack {
            // Base orb (green success tint)
            GlowingOrbLogo(size: size, isAnimating: true, showParticles: false, intensity: 1.2)

            // Burst particles
            ForEach(burstParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.width, y: particle.offset.height)
                    .opacity(particle.opacity)
                    .blur(radius: particle.size * 0.2)
            }

            // Success checkmark overlay
            if showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: size.dimension * 0.25, weight: .bold))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .onChange(of: shouldBurst) { _, newValue in
            if newValue {
                triggerBurst()
            }
        }
    }

    private func triggerBurst() {
        // Create burst particles
        burstParticles = (0..<20).map { index in
            let angle = Double(index) / 20.0 * 2 * .pi
            let distance = CGFloat.random(in: size.dimension * 0.3...size.dimension * 0.8)
            return BurstParticle(
                id: UUID(),
                color: gradientColors[index % gradientColors.count],
                size: CGFloat.random(in: 4...12),
                offset: .zero,
                targetOffset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                opacity: 1.0
            )
        }

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.6)) {
            for i in burstParticles.indices {
                burstParticles[i].offset = burstParticles[i].targetOffset
            }
        }

        // Fade out particles
        withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
            for i in burstParticles.indices {
                burstParticles[i].opacity = 0
            }
        }

        // Show checkmark
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
            showCheckmark = true
        }

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            shouldBurst = false
            showCheckmark = false
            burstParticles = []
        }
    }
}

private struct BurstParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var offset: CGSize
    let targetOffset: CGSize
    var opacity: Double
}

// MARK: - Orb Logo With Text

struct OrbLogoWithText: View {
    let size: LogoSize
    var showTagline: Bool = true

    var body: some View {
        VStack(spacing: size.dimension * 0.15) {
            GlowingOrbLogo(size: size)

            VStack(spacing: 4) {
                Text("MyTasksAI")
                    .font(.system(size: size.dimension * 0.2, weight: .thin, design: .default))
                    .foregroundStyle(.white)

                if showTagline {
                    Text("INFINITE PRODUCTIVITY")
                        .font(.system(size: size.dimension * 0.06, weight: .medium, design: .default))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(2)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Glowing Orb Logo - All Sizes") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            GlowingOrbLogo(size: .hero)

            HStack(spacing: 40) {
                GlowingOrbLogo(size: .large)
                GlowingOrbLogo(size: .medium)
            }

            HStack(spacing: 30) {
                GlowingOrbLogo(size: .small)
                GlowingOrbLogo(size: .tiny)
            }
        }
    }
}

#Preview("Orb Logo With Text") {
    ZStack {
        Color.black.ignoresSafeArea()
        OrbLogoWithText(size: .hero)
    }
}

#Preview("Static Orb Logo") {
    ZStack {
        Color.black.ignoresSafeArea()
        StaticOrbLogo(size: .large)
    }
}

#Preview("Loading Orb Logo") {
    ZStack {
        Color.black.ignoresSafeArea()
        LoadingOrbLogo(size: .large)
    }
}
