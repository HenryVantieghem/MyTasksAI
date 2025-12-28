//
//  VelocityTierOrb.swift
//  Veloce
//
//  Premium animated gradient orb for Velocity Score tier display
//  A mesmerizing visual "jewel" with tier-based colors and dopamine-inducing animations
//

import SwiftUI

/// Premium animated orb for Velocity Score tier display
/// Features: 5-layer visual system with tier gradients, inner glow rotation,
/// prismatic color shifts, breathing scale, and micro-particles (Legendary tier)
struct VelocityTierOrb: View {
    let tier: ScoreTier
    var size: CGFloat = 14
    var isAnimating: Bool = true

    // Animation state
    @State private var innerGlowRotation: Double = 0
    @State private var colorShiftPhase: Double = 0
    @State private var breatheScale: CGFloat = 1.0
    @State private var glowPulseOpacity: Double = 0.4
    @State private var prismaticHue: Double = 0
    @State private var particlePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Animation Timing

    private enum Timing {
        static let innerGlowRotation: Double = 8.0
        static let colorShift: Double = 6.0
        static let breathe: Double = 3.0
        static let glowPulse: Double = 2.5
        static let prismatic: Double = 12.0
        static let particleOrbit: Double = 4.0
    }

    // MARK: - Tier Colors

    private var tierGradientColors: [Color] {
        switch tier {
        case .beginning: return [.gray, .gray.opacity(0.7)]
        case .starting: return [.blue, .cyan]
        case .building: return [.green, .mint]
        case .good: return [.yellow, .orange]
        case .excellent: return [.orange, .red]
        case .legendary: return [.purple, .pink, .orange]
        }
    }

    private var tierCoreColor: Color {
        switch tier {
        case .beginning: return Color(white: 0.25)
        case .starting: return Color(red: 0.1, green: 0.2, blue: 0.4)
        case .building: return Color(red: 0.1, green: 0.3, blue: 0.2)
        case .good: return Color(red: 0.4, green: 0.35, blue: 0.1)
        case .excellent: return Color(red: 0.4, green: 0.2, blue: 0.1)
        case .legendary: return Color(red: 0.3, green: 0.15, blue: 0.35)
        }
    }

    private var prismaticSpectrum: [Color] {
        if tier == .legendary {
            return [.purple, .blue, .cyan, .green, .yellow, .orange, .red, .pink, .purple]
        } else {
            return tierGradientColors + [tierGradientColors.first!]
        }
    }

    private var adjacentTierColor: Color {
        switch tier {
        case .beginning: return .gray.opacity(0.5)
        case .starting: return .green
        case .building: return .yellow
        case .good: return .orange
        case .excellent: return .purple
        case .legendary: return .cyan
        }
    }

    // Animation intensity scales with tier
    private var animationIntensity: Double {
        switch tier {
        case .beginning: return 0.5
        case .starting: return 0.6
        case .building: return 0.7
        case .good: return 0.8
        case .excellent: return 0.9
        case .legendary: return 1.0
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layer 1: Outer Ambient Glow
            outerGlow

            // Layer 2: Core Sphere
            coreSphere

            // Layer 3: Inner Color Field
            innerColorField

            // Layer 4: Rim Highlight
            rimHighlight

            // Layer 5: Specular + Particles
            specularAndParticles
        }
        .frame(width: size, height: size)
        .drawingGroup(opaque: false)
        .onAppear {
            startAnimations()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Velocity score orb, \(tier.label) tier")
    }

    // MARK: - Layer 1: Outer Glow

    private var outerGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        tier.color.opacity(0.5 * glowPulseOpacity * animationIntensity),
                        tier.color.opacity(0.2 * glowPulseOpacity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
            )
            .frame(width: size * 1.8, height: size * 1.8)
            .blur(radius: size * 0.2)
    }

    // MARK: - Layer 2: Core Sphere

    private var coreSphere: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        tierCoreColor.opacity(0.95),
                        Theme.CelestialColors.void.opacity(0.9),
                        Theme.CelestialColors.voidDeep
                    ],
                    center: UnitPoint(x: 0.35, y: 0.35),
                    startRadius: size * 0.02,
                    endRadius: size * 0.55
                )
            )
            .frame(width: size, height: size)
            .scaleEffect(breatheScale)
    }

    // MARK: - Layer 3: Inner Color Field

    private var innerColorField: some View {
        ZStack {
            // Primary color region - animated position
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: tierGradientColors.map { $0.opacity(0.6 * animationIntensity) } + [Color.clear],
                        center: UnitPoint(
                            x: 0.4 + cos(colorShiftPhase) * 0.15,
                            y: 0.35 + sin(colorShiftPhase) * 0.1
                        ),
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.75, height: size * 0.55)
                .rotationEffect(.degrees(innerGlowRotation))
                .blur(radius: size * 0.08)

            // Secondary prismatic shift overlay
            Circle()
                .fill(
                    AngularGradient(
                        colors: prismaticSpectrum,
                        center: .center,
                        startAngle: .degrees(prismaticHue),
                        endAngle: .degrees(prismaticHue + 360)
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)
                .blur(radius: size * 0.12)
                .opacity(0.35 * animationIntensity)
                .blendMode(.overlay)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .blendMode(.screen)
    }

    // MARK: - Layer 4: Rim Highlight

    private var rimHighlight: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        .white.opacity(0.75),
                        tier.color.opacity(0.5),
                        Color.clear,
                        adjacentTierColor.opacity(0.35),
                        Color.clear,
                        tier.color.opacity(0.45),
                        .white.opacity(0.75)
                    ],
                    center: .center,
                    startAngle: .degrees(-30 + innerGlowRotation * 0.5),
                    endAngle: .degrees(330 + innerGlowRotation * 0.5)
                ),
                lineWidth: max(1, size * 0.07)
            )
            .frame(width: size * 0.9, height: size * 0.9)
            .blur(radius: 0.3)
    }

    // MARK: - Layer 5: Specular + Particles

    private var specularAndParticles: some View {
        ZStack {
            // Primary specular highlight (upper-left)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.9),
                            .white.opacity(0.35),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.12
                    )
                )
                .frame(width: size * 0.28, height: size * 0.14)
                .offset(x: -size * 0.18, y: -size * 0.22)

            // Secondary soft highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.4),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.08
                    )
                )
                .frame(width: size * 0.15, height: size * 0.08)
                .offset(x: -size * 0.12, y: -size * 0.28)

            // Micro-particles (Legendary tier only)
            if tier == .legendary && isAnimating && !reduceMotion {
                ForEach(0..<3, id: \.self) { index in
                    microParticle(index: index)
                }
            }
        }
    }

    // MARK: - Micro Particles

    private func microParticle(index: Int) -> some View {
        let baseAngle = (Double(index) / 3.0) * .pi * 2
        let currentAngle = baseAngle + particlePhase
        let orbitRadius = size * 0.55

        return Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.95),
                        prismaticSpectrum[index % prismaticSpectrum.count].opacity(0.7),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.05
                )
            )
            .frame(width: size * 0.1, height: size * 0.1)
            .offset(
                x: cos(currentAngle) * orbitRadius,
                y: sin(currentAngle) * orbitRadius * 0.7
            )
            .blur(radius: 0.5)
    }

    // MARK: - Animations

    private func startAnimations() {
        guard isAnimating && !reduceMotion else {
            // Static state for reduced motion
            breatheScale = 1.0
            glowPulseOpacity = 0.5
            return
        }

        // Inner glow rotation - continuous mesmerizing effect
        withAnimation(.linear(duration: Timing.innerGlowRotation).repeatForever(autoreverses: false)) {
            innerGlowRotation = 360
        }

        // Color shift phase - sine wave motion for organic feel
        withAnimation(.easeInOut(duration: Timing.colorShift).repeatForever(autoreverses: true)) {
            colorShiftPhase = .pi * 2
        }

        // Breathing - subtle scale pulse
        withAnimation(.easeInOut(duration: Timing.breathe).repeatForever(autoreverses: true)) {
            breatheScale = 1.0 + (0.03 * animationIntensity)
        }

        // Glow pulse - opacity variation
        withAnimation(.easeInOut(duration: Timing.glowPulse).repeatForever(autoreverses: true)) {
            glowPulseOpacity = 0.7 + (0.3 * animationIntensity)
        }

        // Prismatic hue (enhanced for higher tiers)
        if tier == .legendary || tier == .excellent {
            withAnimation(.linear(duration: Timing.prismatic).repeatForever(autoreverses: false)) {
                prismaticHue = 360
            }
        }

        // Particle orbit (legendary only)
        if tier == .legendary {
            withAnimation(.linear(duration: Timing.particleOrbit).repeatForever(autoreverses: false)) {
                particlePhase = .pi * 2
            }
        }
    }
}

// MARK: - Previews

#Preview("All Tiers - Small") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 24) {
            ForEach(ScoreTier.allCases, id: \.self) { tier in
                HStack(spacing: 20) {
                    VelocityTierOrb(tier: tier, size: 14)
                    Text(tier.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }
            }
        }
        .padding(40)
    }
}

#Preview("All Tiers - Large") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            ForEach(ScoreTier.allCases, id: \.self) { tier in
                HStack(spacing: 24) {
                    VelocityTierOrb(tier: tier, size: 40)
                    VStack(alignment: .leading) {
                        Text(tier.label)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(tier.message)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                }
            }
        }
        .padding(40)
    }
}

#Preview("Legendary Hero") {
    ZStack {
        Color.black.ignoresSafeArea()

        VelocityTierOrb(tier: .legendary, size: 80)
    }
}
