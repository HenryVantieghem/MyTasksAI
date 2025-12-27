//
//  NeuralOrb.swift
//  MyTasksAI
//
//  Neural Orb - Premium AI Companion
//  A breathtaking prismatic glass sphere with holographic reflections,
//  liquid metal core, neural network energy patterns, and particle constellation.
//  Designed to feel like Apple paid a billion dollars for this.
//

import SwiftUI

// MARK: - Neural Orb

/// Ultra-premium AI orb with prismatic holographic effects
struct NeuralOrb: View {
    let size: NeuralOrbSize
    var isAnimating: Bool = true
    var intensity: Double = 1.0
    var showParticles: Bool = true
    var showNeuralNetwork: Bool = true

    // Animation states
    @State private var rotationPhase: Double = 0
    @State private var pulsePhase: Double = 0
    @State private var colorShiftPhase: Double = 0
    @State private var breatheScale: CGFloat = 1.0
    @State private var innerGlowPhase: Double = 0
    @State private var neuralPulsePhase: Double = 0
    @State private var shimmerPhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Premium color palette - prismatic holographic spectrum
    private let prismaticColors: [Color] = [
        Color(red: 0.55, green: 0.35, blue: 1.0),   // Deep violet
        Color(red: 0.35, green: 0.55, blue: 1.0),   // Electric blue
        Color(red: 0.25, green: 0.85, blue: 0.95),  // Cyan plasma
        Color(red: 0.55, green: 0.95, blue: 0.85),  // Seafoam
        Color(red: 0.95, green: 0.55, blue: 0.85),  // Rose quartz
        Color(red: 0.85, green: 0.45, blue: 0.95),  // Magenta
    ]

    // Core colors
    private var liquidMetalCore: Color { Color(red: 0.15, green: 0.18, blue: 0.35) }
    private var plasmaEnergy: Color { Color(red: 0.45, green: 0.65, blue: 1.0) }

    var body: some View {
        ZStack {
            // Layer 1: Outer aura - diffuse cosmic glow
            outerAura

            // Layer 2: Holographic halo rings
            holographicRings

            // Layer 3: Neural network connections
            if showNeuralNetwork && size.showNeuralNetwork {
                neuralNetworkLayer
            }

            // Layer 4: Primary glow field
            primaryGlowField

            // Layer 5: Liquid metal core
            liquidMetalCoreLayer

            // Layer 6: Prismatic glass surface
            prismaticGlassSurface

            // Layer 7: Inner energy pulse
            innerEnergyPulse

            // Layer 8: Specular highlights
            specularHighlights

            // Layer 9: Particle constellation
            if showParticles && size.showParticles && !reduceMotion {
                particleConstellation
            }
        }
        .frame(width: size.dimension * 2.0, height: size.dimension * 2.0)
        .scaleEffect(breatheScale)
        .onAppear {
            guard isAnimating && !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Outer Aura

    private var outerAura: some View {
        ZStack {
            // Primary diffuse glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            prismaticColors[0].opacity(0.35 * intensity * (0.8 + pulsePhase * 0.2)),
                            prismaticColors[2].opacity(0.2 * intensity),
                            prismaticColors[4].opacity(0.1 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size.dimension * 0.3,
                        endRadius: size.dimension * 0.95
                    )
                )
                .frame(width: size.dimension * 1.9, height: size.dimension * 1.9)
                .blur(radius: size.dimension * 0.15)

            // Secondary chromatic aberration
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            prismaticColors[1].opacity(0.25 * intensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: size.dimension * 0.1,
                        endRadius: size.dimension * 0.7
                    )
                )
                .frame(width: size.dimension * 1.7, height: size.dimension * 1.7)
                .blur(radius: size.dimension * 0.12)
                .rotationEffect(.degrees(rotationPhase * 0.3))
        }
    }

    // MARK: - Holographic Rings

    private var holographicRings: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                prismaticColors[(index + Int(colorShiftPhase)) % prismaticColors.count].opacity(0.4 - Double(index) * 0.1),
                                prismaticColors[(index + 2 + Int(colorShiftPhase)) % prismaticColors.count].opacity(0.3 - Double(index) * 0.08),
                                Color.clear,
                                prismaticColors[(index + 4 + Int(colorShiftPhase)) % prismaticColors.count].opacity(0.25 - Double(index) * 0.06),
                                prismaticColors[(index + Int(colorShiftPhase)) % prismaticColors.count].opacity(0.4 - Double(index) * 0.1)
                            ],
                            center: .center,
                            angle: .degrees(rotationPhase + Double(index * 30))
                        ),
                        lineWidth: size.dimension * 0.015
                    )
                    .frame(
                        width: size.dimension * (1.1 + CGFloat(index) * 0.15),
                        height: size.dimension * (1.1 + CGFloat(index) * 0.15)
                    )
                    .rotationEffect(.degrees(rotationPhase * (index.isMultiple(of: 2) ? 1 : -0.7)))
                    .opacity(0.7 - Double(index) * 0.15)
                    .blur(radius: 0.5)
            }
        }
    }

    // MARK: - Neural Network Layer

    private var neuralNetworkLayer: some View {
        ZStack {
            // Neural connection lines
            ForEach(0..<8, id: \.self) { index in
                NeuralConnection(
                    index: index,
                    phase: neuralPulsePhase,
                    size: size.dimension,
                    color: prismaticColors[index % prismaticColors.count]
                )
            }
        }
        .opacity(0.6)
    }

    // MARK: - Primary Glow Field

    private var primaryGlowField: some View {
        ZStack {
            // Main glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            plasmaEnergy.opacity(0.6 * intensity),
                            prismaticColors[0].opacity(0.4 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size.dimension * 0.1,
                        endRadius: size.dimension * 0.55
                    )
                )
                .frame(width: size.dimension * 1.1, height: size.dimension * 1.1)
                .blur(radius: size.dimension * 0.15)

            // Pulsing energy core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.4 * intensity * (0.7 + innerGlowPhase * 0.3)),
                            plasmaEnergy.opacity(0.3 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.35
                    )
                )
                .frame(width: size.dimension * 0.7, height: size.dimension * 0.7)
                .blur(radius: size.dimension * 0.08)
        }
    }

    // MARK: - Liquid Metal Core

    private var liquidMetalCoreLayer: some View {
        ZStack {
            // Base dark core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            liquidMetalCore,
                            liquidMetalCore.opacity(0.95),
                            Color(red: 0.08, green: 0.10, blue: 0.20)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: size.dimension * 0.05,
                        endRadius: size.dimension * 0.35
                    )
                )
                .frame(width: size.dimension * 0.7, height: size.dimension * 0.7)

            // Liquid flow gradient
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            prismaticColors[0].opacity(0.3),
                            prismaticColors[1].opacity(0.25),
                            prismaticColors[2].opacity(0.2),
                            prismaticColors[3].opacity(0.25),
                            prismaticColors[4].opacity(0.3),
                            prismaticColors[0].opacity(0.3)
                        ],
                        center: .center,
                        angle: .degrees(colorShiftPhase * 60)
                    )
                )
                .frame(width: size.dimension * 0.65, height: size.dimension * 0.65)
                .blur(radius: size.dimension * 0.06)
                .blendMode(.screen)

            // Depth shadow
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: UnitPoint(x: 0.3, y: 0.3),
                        endPoint: .bottom
                    )
                )
                .frame(width: size.dimension * 0.7, height: size.dimension * 0.7)
        }
    }

    // MARK: - Prismatic Glass Surface

    private var prismaticGlassSurface: some View {
        ZStack {
            // Primary iridescent surface
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            prismaticColors[Int(shimmerPhase) % prismaticColors.count].opacity(0.4),
                            prismaticColors[(Int(shimmerPhase) + 2) % prismaticColors.count].opacity(0.25),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: 0.1, y: 0.1),
                        endPoint: UnitPoint(x: 0.8, y: 0.7)
                    )
                )
                .frame(width: size.dimension * 0.58, height: size.dimension * 0.35)
                .rotationEffect(.degrees(-30))
                .offset(x: -size.dimension * 0.08, y: -size.dimension * 0.12)
                .blur(radius: size.dimension * 0.02)

            // Secondary reflection
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            prismaticColors[(Int(shimmerPhase) + 3) % prismaticColors.count].opacity(0.35 * (0.8 + shimmerPhase.truncatingRemainder(dividingBy: 1) * 0.2)),
                            prismaticColors[(Int(shimmerPhase) + 5) % prismaticColors.count].opacity(0.2),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: 0.9, y: 0.2),
                        endPoint: UnitPoint(x: 0.3, y: 0.9)
                    )
                )
                .frame(width: size.dimension * 0.28, height: size.dimension * 0.5)
                .offset(x: size.dimension * 0.18, y: -size.dimension * 0.02)
                .blur(radius: size.dimension * 0.02)

            // Edge rim highlight
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            prismaticColors[0].opacity(0.4),
                            Color.clear,
                            Color.clear,
                            prismaticColors[3].opacity(0.3),
                            Color.white.opacity(0.5)
                        ],
                        center: .center,
                        startAngle: .degrees(-70),
                        endAngle: .degrees(290)
                    ),
                    lineWidth: size.dimension * 0.025
                )
                .frame(width: size.dimension * 0.68, height: size.dimension * 0.68)
                .blur(radius: size.dimension * 0.01)
        }
    }

    // MARK: - Inner Energy Pulse

    private var innerEnergyPulse: some View {
        ZStack {
            // Central energy core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.75 * intensity * (0.6 + innerGlowPhase * 0.4)),
                            plasmaEnergy.opacity(0.5 * intensity),
                            prismaticColors[1].opacity(0.3 * intensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.45, y: 0.42),
                        startRadius: 0,
                        endRadius: size.dimension * 0.25
                    )
                )
                .frame(width: size.dimension * 0.5, height: size.dimension * 0.5)
                .blur(radius: size.dimension * 0.03)

            // Rose accent pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            prismaticColors[4].opacity(0.4 * intensity * (0.7 + innerGlowPhase * 0.3)),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.55, y: 0.48),
                        startRadius: 0,
                        endRadius: size.dimension * 0.18
                    )
                )
                .frame(width: size.dimension * 0.4, height: size.dimension * 0.4)
                .blur(radius: size.dimension * 0.025)
        }
    }

    // MARK: - Specular Highlights

    private var specularHighlights: some View {
        ZStack {
            // Primary specular
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.6),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.06
                    )
                )
                .frame(width: size.dimension * 0.14, height: size.dimension * 0.07)
                .offset(x: -size.dimension * 0.14, y: -size.dimension * 0.18)
                .blur(radius: size.dimension * 0.008)

            // Secondary specular
            Ellipse()
                .fill(Color.white.opacity(0.5))
                .frame(width: size.dimension * 0.07, height: size.dimension * 0.035)
                .offset(x: -size.dimension * 0.1, y: -size.dimension * 0.22)
                .blur(radius: 2)

            // Sparkle point
            Circle()
                .fill(Color.white.opacity(0.85 * (0.6 + shimmerPhase.truncatingRemainder(dividingBy: 1) * 0.4)))
                .frame(width: size.dimension * 0.03, height: size.dimension * 0.03)
                .offset(x: -size.dimension * 0.17, y: -size.dimension * 0.15)
                .blur(radius: 0.5)
        }
    }

    // MARK: - Particle Constellation

    private var particleConstellation: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                ConstellationParticle(
                    index: index,
                    phase: rotationPhase,
                    colorPhase: colorShiftPhase,
                    orbSize: size.dimension,
                    colors: prismaticColors
                )
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Rotation - slow continuous
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            rotationPhase = 360
        }

        // Pulse - breathing rhythm
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            pulsePhase = 1.0
        }

        // Color shift - prismatic cycling
        withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
            colorShiftPhase = Double(prismaticColors.count)
        }

        // Breathe scale
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breatheScale = 1.03
        }

        // Inner glow
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            innerGlowPhase = 1.0
        }

        // Neural pulse
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            neuralPulsePhase = 1.0
        }

        // Shimmer
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            shimmerPhase = Double(prismaticColors.count)
        }
    }
}

// MARK: - Neural Connection

private struct NeuralConnection: View {
    let index: Int
    let phase: Double
    let size: CGFloat
    let color: Color

    var body: some View {
        let seed = Double(index) * 1.618
        let baseAngle = seed * .pi * 2 / 8
        let innerRadius = size * 0.35
        let outerRadius = size * 0.52

        let startAngle = baseAngle + phase * .pi * 2
        let endAngle = startAngle + .pi * 0.3

        Path { path in
            let startX = cos(startAngle) * innerRadius
            let startY = sin(startAngle) * innerRadius * 0.8
            let endX = cos(endAngle) * outerRadius
            let endY = sin(endAngle) * outerRadius * 0.8

            path.move(to: CGPoint(x: startX + size, y: startY + size))

            let controlX = (startX + endX) / 2 + cos(startAngle + .pi / 2) * size * 0.1
            let controlY = (startY + endY) / 2 + sin(startAngle + .pi / 2) * size * 0.1

            path.addQuadCurve(
                to: CGPoint(x: endX + size, y: endY + size),
                control: CGPoint(x: controlX + size, y: controlY + size)
            )
        }
        .stroke(
            LinearGradient(
                colors: [
                    color.opacity(0.4 + sin(phase * .pi * 2 + seed) * 0.3),
                    color.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
        )
        .frame(width: size * 2, height: size * 2)
    }
}

// MARK: - Constellation Particle

private struct ConstellationParticle: View {
    let index: Int
    let phase: Double
    let colorPhase: Double
    let orbSize: CGFloat
    let colors: [Color]

    var body: some View {
        let seed = Double(index) * 1.618
        let baseAngle = (seed / 12.0) * .pi * 2
        let orbitRadius = orbSize * (0.45 + sin(seed * 2.1) * 0.1)
        let particleSize = orbSize * (0.018 + sin(seed * 1.7) * 0.008)
        let speed = 0.4 + sin(seed * 1.3) * 0.25
        let opacity = 0.5 + sin(seed * 2.1) * 0.3

        let currentAngle = baseAngle + phase / 360 * .pi * 2 * speed
        let x = cos(currentAngle) * orbitRadius
        let y = sin(currentAngle) * orbitRadius * 0.6

        let colorIndex = (index + Int(colorPhase)) % colors.count

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(opacity),
                        colors[colorIndex].opacity(opacity * 0.6),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: particleSize
                )
            )
            .frame(width: particleSize * 2.5, height: particleSize * 2.5)
            .offset(x: x, y: y)
            .blur(radius: particleSize * 0.25)
    }
}

// MARK: - Neural Orb Size

enum NeuralOrbSize {
    case tiny      // 28pt - Tab bar, small icons
    case small     // 48pt - Navigation, buttons
    case medium    // 100pt - Cards, headers
    case large     // 150pt - Splash, onboarding
    case hero      // 220pt - Auth screen hero

    var dimension: CGFloat {
        switch self {
        case .tiny: return 28
        case .small: return 48
        case .medium: return 100
        case .large: return 150
        case .hero: return 220
        }
    }

    var showParticles: Bool {
        switch self {
        case .tiny, .small: return false
        case .medium, .large, .hero: return true
        }
    }

    var showNeuralNetwork: Bool {
        switch self {
        case .tiny, .small, .medium: return false
        case .large, .hero: return true
        }
    }
}

// MARK: - Static Neural Orb

struct StaticNeuralOrb: View {
    let size: NeuralOrbSize
    var intensity: Double = 1.0

    var body: some View {
        NeuralOrb(size: size, isAnimating: false, intensity: intensity)
    }
}

// MARK: - Neural Orb With Branding

struct NeuralOrbWithBranding: View {
    let size: NeuralOrbSize
    var showTagline: Bool = true

    var body: some View {
        VStack(spacing: size.dimension * 0.15) {
            NeuralOrb(size: size)

            VStack(spacing: 8) {
                Text("MyTasksAI")
                    .font(.system(size: size.dimension * 0.22, weight: .ultraLight, design: .default))
                    .tracking(4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if showTagline {
                    Text("INTELLIGENT PRODUCTIVITY")
                        .font(.system(size: size.dimension * 0.055, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .tracking(4)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Neural Orb Hero") {
    ZStack {
        Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea()

        NeuralOrb(size: .hero)
    }
}

#Preview("Neural Orb Sizes") {
    ZStack {
        Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea()

        VStack(spacing: 50) {
            NeuralOrb(size: .hero)

            HStack(spacing: 40) {
                NeuralOrb(size: .large)
                NeuralOrb(size: .medium)
            }

            HStack(spacing: 30) {
                NeuralOrb(size: .small)
                NeuralOrb(size: .tiny)
            }
        }
    }
}

#Preview("Neural Orb With Branding") {
    ZStack {
        Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea()

        NeuralOrbWithBranding(size: .hero)
    }
}
