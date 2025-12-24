//
//  GlowingOrbLogo.swift
//  Veloce
//
//  Celestial Floating Orb Logo
//  Ultra-premium 3D orb with levitation, aurora glow, and ethereal particles
//

import SwiftUI

// MARK: - Glowing Orb Logo

/// Celestial floating orb logo with ethereal presence
/// Features:
/// - Levitating animation with subtle bounce
/// - Multi-layer aurora glow system
/// - Liquid glass sphere with depth
/// - Ethereal particle nebula
/// - Pulsing energy core
/// - Dynamic light reflections
struct GlowingOrbLogo: View {
    let size: LogoSize
    var isAnimating: Bool = true
    var showParticles: Bool = true
    var intensity: Double = 1.0

    // Animation states
    @State private var floatPhase: Double = 0
    @State private var breathePhase: Double = 0
    @State private var auroraRotation: Double = 0
    @State private var coreEnergyPhase: Double = 0
    @State private var particleOrbitPhase: Double = 0
    @State private var glowPulsePhase: Double = 0
    @State private var shimmerPhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Aurora Color Palette

    private let auroraColors: [Color] = [
        Color(hex: "A855F7"), // Vivid Purple
        Color(hex: "8B5CF6"), // Purple
        Color(hex: "6366F1"), // Indigo
        Color(hex: "3B82F6"), // Blue
        Color(hex: "0EA5E9"), // Sky
        Color(hex: "06B6D4"), // Cyan
        Color(hex: "14B8A6"), // Teal
        Color(hex: "10B981"), // Emerald
    ]

    var body: some View {
        ZStack {
            // Layer 0: Ground shadow (floating effect)
            if size.showGlow {
                groundShadow
            }

            // Layer 1: Outer aurora nebula
            if size.showGlow {
                auroraNebula
            }

            // Layer 2: Energy field rings
            if size.showGlow {
                energyFieldRings
            }

            // Layer 3: Ethereal particle cloud
            if showParticles && size.showParticles && !reduceMotion {
                etherealParticles
            }

            // Layer 4: Glass sphere body
            glassSphere

            // Layer 5: Inner plasma core
            plasmaCore

            // Layer 6: Surface shimmer
            surfaceShimmer

            // Layer 7: Specular highlight
            specularHighlight
        }
        .frame(width: size.dimension * 1.8, height: size.dimension * 1.8)
        .offset(y: -floatPhase * size.dimension * 0.05) // Floating offset
        .onAppear {
            guard isAnimating && !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Ground Shadow (Floating Effect)

    private var groundShadow: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        auroraColors[0].opacity(0.25 * intensity * (1 - floatPhase * 0.3)),
                        auroraColors[3].opacity(0.15 * intensity * (1 - floatPhase * 0.3)),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.dimension * 0.4
                )
            )
            .frame(width: size.dimension * 0.7, height: size.dimension * 0.15)
            .offset(y: size.dimension * 0.45 + floatPhase * size.dimension * 0.08)
            .blur(radius: size.dimension * 0.08)
    }

    // MARK: - Aurora Nebula

    private var auroraNebula: some View {
        ZStack {
            // Primary aurora sweep
            ForEach(0..<3, id: \.self) { layer in
                Circle()
                    .fill(
                        AngularGradient(
                            colors: rotatedColors(by: layer * 2),
                            center: .center,
                            angle: .degrees(auroraRotation + Double(layer) * 60)
                        )
                    )
                    .frame(
                        width: size.dimension * (1.4 - Double(layer) * 0.15),
                        height: size.dimension * (1.4 - Double(layer) * 0.15)
                    )
                    .blur(radius: size.dimension * (0.25 - Double(layer) * 0.05))
                    .opacity((0.3 - Double(layer) * 0.08) * intensity * (0.8 + glowPulsePhase * 0.2))
            }

            // Radial atmosphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            auroraColors[0].opacity(0.35 * intensity),
                            auroraColors[2].opacity(0.2 * intensity),
                            auroraColors[4].opacity(0.1 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size.dimension * 0.15,
                        endRadius: size.dimension * 0.75
                    )
                )
                .frame(width: size.dimension * 1.5, height: size.dimension * 1.5)
                .blur(radius: size.dimension * 0.15)
                .scaleEffect(1.0 + breathePhase * 0.08)
        }
    }

    private func rotatedColors(by offset: Int) -> [Color] {
        var colors = auroraColors
        for _ in 0..<offset {
            let first = colors.removeFirst()
            colors.append(first)
        }
        return colors + [colors[0]]
    }

    // MARK: - Energy Field Rings

    private var energyFieldRings: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                let progress = (glowPulsePhase + Double(index) * 0.25).truncatingRemainder(dividingBy: 1.0)
                let scale = 0.5 + progress * 0.5
                let opacity = (1.0 - progress) * 0.4 * intensity

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                auroraColors[index % auroraColors.count].opacity(opacity),
                                auroraColors[(index + 2) % auroraColors.count].opacity(opacity * 0.5),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size.dimension * 0.015 * (1.0 - progress * 0.5)
                    )
                    .frame(width: size.dimension * scale, height: size.dimension * scale)
                    .blur(radius: size.dimension * 0.02)
            }
        }
    }

    // MARK: - Ethereal Particles

    private var etherealParticles: some View {
        ZStack {
            // Inner orbit particles
            ForEach(0..<12, id: \.self) { index in
                EtherealParticle(
                    index: index,
                    totalCount: 12,
                    phase: particleOrbitPhase,
                    orbRadius: size.dimension * 0.35,
                    particleSize: size.dimension * 0.025,
                    colors: auroraColors,
                    orbitTilt: 0.6
                )
            }

            // Outer nebula particles
            ForEach(0..<8, id: \.self) { index in
                EtherealParticle(
                    index: index,
                    totalCount: 8,
                    phase: particleOrbitPhase * 0.7,
                    orbRadius: size.dimension * 0.55,
                    particleSize: size.dimension * 0.018,
                    colors: auroraColors,
                    orbitTilt: 0.4
                )
            }

            // Sparkle dust
            ForEach(0..<16, id: \.self) { index in
                SparkleParticle(
                    index: index,
                    phase: shimmerPhase,
                    fieldSize: size.dimension * 0.5,
                    particleSize: size.dimension * 0.012
                )
            }
        }
    }

    // MARK: - Glass Sphere Body

    private var glassSphere: some View {
        ZStack {
            // Base sphere with rotating aurora
            Circle()
                .fill(
                    AngularGradient(
                        colors: auroraColors + [auroraColors[0]],
                        center: .center,
                        angle: .degrees(auroraRotation * 1.5)
                    )
                )
                .frame(width: size.dimension * 0.52, height: size.dimension * 0.52)

            // Glass overlay with depth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear,
                            Color.black.opacity(0.25)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size.dimension * 0.3
                    )
                )
                .frame(width: size.dimension * 0.52, height: size.dimension * 0.52)

            // Inner refraction
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            auroraColors[4].opacity(0.3),
                            auroraColors[0].opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.dimension * 0.48, height: size.dimension * 0.48)
                .blendMode(.overlay)

            // Edge glow
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            auroraColors[4].opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size.dimension * 0.01
                )
                .frame(width: size.dimension * 0.52, height: size.dimension * 0.52)
                .blur(radius: 1)
        }
        .scaleEffect(1.0 + breathePhase * 0.03)
    }

    // MARK: - Plasma Core

    private var plasmaCore: some View {
        ZStack {
            // Outer core halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            auroraColors[4].opacity(0.6),
                            auroraColors[0].opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.18
                    )
                )
                .frame(width: size.dimension * 0.36, height: size.dimension * 0.36)
                .blur(radius: size.dimension * 0.02)
                .scaleEffect(1.0 + coreEnergyPhase * 0.1)

            // Hot white center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.85),
                            Color(hex: "E0F2FE").opacity(0.6),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.1
                    )
                )
                .frame(width: size.dimension * 0.2, height: size.dimension * 0.2)
                .blur(radius: size.dimension * 0.01)
                .scaleEffect(1.0 + coreEnergyPhase * 0.15)

            // Energy flare
            Circle()
                .fill(Color.white.opacity(0.95 + coreEnergyPhase * 0.05))
                .frame(width: size.dimension * 0.08, height: size.dimension * 0.08)
                .blur(radius: size.dimension * 0.005)
        }
    }

    // MARK: - Surface Shimmer

    private var surfaceShimmer: some View {
        ZStack {
            // Traveling light band
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.dimension * 0.4, height: size.dimension * 0.03)
                .offset(x: -size.dimension * 0.1, y: -size.dimension * 0.08)
                .rotationEffect(.degrees(-30))
                .blur(radius: 2)
                .opacity(0.6 + shimmerPhase * 0.4)
        }
    }

    // MARK: - Specular Highlight

    private var specularHighlight: some View {
        ZStack {
            // Primary highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.08
                    )
                )
                .frame(width: size.dimension * 0.14, height: size.dimension * 0.07)
                .offset(x: -size.dimension * 0.1, y: -size.dimension * 0.14)
                .blur(radius: size.dimension * 0.008)

            // Secondary soft highlight
            Ellipse()
                .fill(Color.white.opacity(0.25))
                .frame(width: size.dimension * 0.08, height: size.dimension * 0.04)
                .offset(x: -size.dimension * 0.06, y: -size.dimension * 0.18)
                .blur(radius: 3)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Floating levitation (2.5s gentle bounce)
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            floatPhase = 1.0
        }

        // Breathing scale (3s subtle pulse)
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breathePhase = 1.0
        }

        // Aurora rotation (12s smooth spin)
        withAnimation(.linear(duration: 12.0).repeatForever(autoreverses: false)) {
            auroraRotation = 360
        }

        // Core energy pulse (1.2s fast pulse)
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            coreEnergyPhase = 1.0
        }

        // Particle orbit (15s continuous)
        withAnimation(.linear(duration: 15.0).repeatForever(autoreverses: false)) {
            particleOrbitPhase = 1.0
        }

        // Glow ring expansion (3s wave)
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            glowPulsePhase = 1.0
        }

        // Surface shimmer (2s sparkle)
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            shimmerPhase = 1.0
        }
    }
}

// MARK: - Ethereal Particle

private struct EtherealParticle: View {
    let index: Int
    let totalCount: Int
    let phase: Double
    let orbRadius: CGFloat
    let particleSize: CGFloat
    let colors: [Color]
    let orbitTilt: Double

    private var config: (baseAngle: Double, speed: Double, verticalScale: Double) {
        let seed = Double(index)
        let baseAngle = (seed / Double(totalCount)) * 2 * .pi
        let speed = 0.6 + sin(seed * 1.7) * 0.4
        let verticalScale = orbitTilt + sin(seed * 2.3) * 0.2
        return (baseAngle, speed, verticalScale)
    }

    var body: some View {
        let (baseAngle, speed, verticalScale) = config
        let currentAngle = baseAngle + phase * 2 * .pi * speed

        let x = cos(currentAngle) * orbRadius
        let y = sin(currentAngle) * orbRadius * verticalScale

        // Depth-based effects
        let depthFactor = (sin(currentAngle) + 1) / 2
        let currentOpacity = 0.3 + depthFactor * 0.5
        let currentSize = particleSize * (0.7 + depthFactor * 0.6)

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        colors[index % colors.count].opacity(currentOpacity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: currentSize
                )
            )
            .frame(width: currentSize * 2, height: currentSize * 2)
            .offset(x: x, y: y)
            .blur(radius: currentSize * 0.15)
    }
}

// MARK: - Sparkle Particle

private struct SparkleParticle: View {
    let index: Int
    let phase: Double
    let fieldSize: CGFloat
    let particleSize: CGFloat

    private var position: (x: CGFloat, y: CGFloat, opacity: Double) {
        let seed = Double(index) * 1.618 // Golden ratio distribution
        let angle = seed * 2.4 // Golden angle
        let radius = fieldSize * (0.3 + sin(seed * 3.1) * 0.4)

        let x = cos(angle) * radius
        let y = sin(angle) * radius * 0.7

        // Twinkle based on phase
        let twinkle = sin(phase * .pi * 2 + seed * 2.7)
        let opacity = max(0, twinkle) * 0.7

        return (x, y, opacity)
    }

    var body: some View {
        let pos = position

        Circle()
            .fill(Color.white)
            .frame(width: particleSize, height: particleSize)
            .offset(x: pos.x, y: pos.y)
            .opacity(pos.opacity)
            .blur(radius: particleSize * 0.2)
    }
}

// MARK: - Static Orb Logo (Non-animated variant)

struct StaticOrbLogo: View {
    let size: LogoSize
    var intensity: Double = 1.0

    private let auroraColors: [Color] = [
        Color(hex: "A855F7"),
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
                                auroraColors[0].opacity(0.25 * intensity),
                                auroraColors[3].opacity(0.15 * intensity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size.dimension * 0.15,
                            endRadius: size.dimension * 0.6
                        )
                    )
                    .frame(width: size.dimension * 1.3, height: size.dimension * 1.3)
                    .blur(radius: size.dimension * 0.12)
            }

            // Main orb
            Circle()
                .fill(
                    AngularGradient(
                        colors: auroraColors + [auroraColors[0]],
                        center: .center
                    )
                )
                .frame(width: size.dimension * 0.52, height: size.dimension * 0.52)

            // Glass overlay
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear,
                            Color.black.opacity(0.2)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size.dimension * 0.3
                    )
                )
                .frame(width: size.dimension * 0.52, height: size.dimension * 0.52)

            // Inner core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.6),
                            auroraColors[4].opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.12
                    )
                )
                .frame(width: size.dimension * 0.24, height: size.dimension * 0.24)

            // Top highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.06
                    )
                )
                .frame(width: size.dimension * 0.12, height: size.dimension * 0.06)
                .offset(x: -size.dimension * 0.08, y: -size.dimension * 0.12)
                .blur(radius: 2)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}

// MARK: - Loading Orb Logo (Pulsing variant)

struct LoadingOrbLogo: View {
    let size: LogoSize
    @State private var pulsePhase: Double = 0
    @State private var rotationPhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Pulsing rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.5 - Double(index) * 0.15),
                                Color(hex: "06B6D4").opacity(0.3 - Double(index) * 0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: size.dimension * (0.6 + pulsePhase * 0.3 + Double(index) * 0.15),
                        height: size.dimension * (0.6 + pulsePhase * 0.3 + Double(index) * 0.15)
                    )
                    .opacity(1.0 - pulsePhase * 0.5 - Double(index) * 0.2)
                    .rotationEffect(.degrees(rotationPhase + Double(index) * 30))
            }

            GlowingOrbLogo(
                size: size,
                isAnimating: true,
                showParticles: false,
                intensity: 0.9 + pulsePhase * 0.2
            )
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsePhase = 1.0
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotationPhase = 360
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
    @State private var ringScale: CGFloat = 0.5

    private let successColors: [Color] = [
        Color(hex: "8B5CF6"),
        Color(hex: "3B82F6"),
        Color(hex: "06B6D4"),
        Color(hex: "10B981"),
        Color(hex: "22C55E"),
    ]

    var body: some View {
        ZStack {
            // Success ring burst
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "22C55E"), Color(hex: "10B981")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size.dimension * ringScale, height: size.dimension * ringScale)
                .opacity(showCheckmark ? 0 : 0.8)

            // Base orb with success tint
            GlowingOrbLogo(size: size, isAnimating: true, showParticles: false, intensity: 1.3)

            // Burst particles
            ForEach(burstParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.width, y: particle.offset.height)
                    .opacity(particle.opacity)
                    .blur(radius: particle.size * 0.15)
            }

            // Success checkmark overlay
            if showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: size.dimension * 0.22, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: "22C55E").opacity(0.8), radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size.dimension * 1.8, height: size.dimension * 1.8)
        .onChange(of: shouldBurst) { _, newValue in
            if newValue {
                triggerBurst()
            }
        }
    }

    private func triggerBurst() {
        // Create burst particles
        burstParticles = (0..<24).map { index in
            let angle = Double(index) / 24.0 * 2 * .pi
            let distance = CGFloat.random(in: size.dimension * 0.4...size.dimension * 0.9)
            return BurstParticle(
                id: UUID(),
                color: successColors[index % successColors.count],
                size: CGFloat.random(in: 5...14),
                offset: .zero,
                targetOffset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                opacity: 1.0
            )
        }

        // Animate ring expansion
        withAnimation(.easeOut(duration: 0.5)) {
            ringScale = 1.5
        }

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.7)) {
            for i in burstParticles.indices {
                burstParticles[i].offset = burstParticles[i].targetOffset
            }
        }

        // Fade out particles
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            for i in burstParticles.indices {
                burstParticles[i].opacity = 0
            }
        }

        // Show checkmark
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.25)) {
            showCheckmark = true
        }

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            shouldBurst = false
            showCheckmark = false
            burstParticles = []
            ringScale = 0.5
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
        VStack(spacing: size.dimension * 0.12) {
            GlowingOrbLogo(size: size)

            VStack(spacing: 6) {
                Text("Veloce")
                    .font(.system(size: size.dimension * 0.18, weight: .thin, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if showTagline {
                    Text("INFINITE MOMENTUM")
                        .font(.system(size: size.dimension * 0.055, weight: .medium, design: .default))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(3)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Celestial Floating Orb - All Sizes") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 50) {
            GlowingOrbLogo(size: .hero)

            HStack(spacing: 50) {
                GlowingOrbLogo(size: .large)
                GlowingOrbLogo(size: .medium)
            }

            HStack(spacing: 40) {
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

#Preview("Loading Orb Logo") {
    ZStack {
        Color.black.ignoresSafeArea()
        LoadingOrbLogo(size: .large)
    }
}

#Preview("Static Orb Logo") {
    ZStack {
        Color.black.ignoresSafeArea()
        StaticOrbLogo(size: .large)
    }
}
