//
//  GlowingOrbLogo.swift
//  Veloce
//
//  Ethereal Iridescent Orb Logo
//  A luminous, translucent sphere inspired by soap bubbles
//  with cyan/purple/pink iridescence and ethereal glow
//

import SwiftUI

// MARK: - Glowing Orb Logo

/// Ethereal iridescent orb logo - translucent bubble aesthetic
struct GlowingOrbLogo: View {
    let size: LogoSize
    var isAnimating: Bool = true
    var showParticles: Bool = true
    var intensity: Double = 1.0

    @State private var floatPhase: Double = 0
    @State private var breathePhase: Double = 0
    @State private var colorShiftPhase: Double = 0
    @State private var shimmerPhase: Double = 0
    @State private var glowPulsePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Ethereal bubble colors - cyan/purple/pink iridescence
    private let iridescenceColors: [Color] = [
        Color(red: 0.40, green: 0.90, blue: 0.98),   // Electric cyan
        Color(red: 0.50, green: 0.75, blue: 0.98),   // Sky blue
        Color(red: 0.65, green: 0.60, blue: 0.98),   // Soft purple
        Color(red: 0.80, green: 0.55, blue: 0.95),   // Lavender pink
        Color(red: 0.90, green: 0.70, blue: 0.95),   // Rose pink
        Color(red: 0.85, green: 0.85, blue: 0.98),   // Pearl white
        Color(red: 0.60, green: 0.85, blue: 0.98),   // Light cyan
        Color(red: 0.70, green: 0.70, blue: 0.98),   // Soft violet
    ]

    // Core colors for the translucent center
    private var coreGlow: Color { Color(red: 0.45, green: 0.88, blue: 0.98) }
    private var corePurple: Color { Color(red: 0.65, green: 0.55, blue: 0.95) }
    private var corePink: Color { Color(red: 0.85, green: 0.60, blue: 0.90) }

    var body: some View {
        ZStack {
            // Outer atmospheric glow
            if size.showGlow {
                outerAtmosphericGlow
                midGlowHalo
            }

            // Main translucent orb body
            mainBubbleBody

            // Inner luminescent core
            innerLuminescence

            // Iridescent surface reflections
            iridescentSurface

            // Bubble edge rim light
            bubbleRimLight

            // Specular highlights (top)
            specularHighlights

            // Floating particle motes
            if showParticles && size.showParticles && !reduceMotion {
                floatingMotes
            }
        }
        .frame(width: size.dimension * 1.6, height: size.dimension * 1.6)
        .offset(y: -floatPhase * size.dimension * 0.04)
        .onAppear {
            guard isAnimating && !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Outer Atmospheric Glow

    private var outerAtmosphericGlow: some View {
        ZStack {
            // Primary cyan glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            coreGlow.opacity(0.50 * intensity * (0.85 + glowPulsePhase * 0.15)),
                            corePurple.opacity(0.30 * intensity),
                            corePink.opacity(0.15 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size.dimension * 0.20,
                        endRadius: size.dimension * 0.85
                    )
                )
                .frame(width: size.dimension * 1.7, height: size.dimension * 1.7)
                .blur(radius: size.dimension * 0.20)

            // Secondary purple accent glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            corePurple.opacity(0.35 * intensity),
                            corePink.opacity(0.20 * intensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.65, y: 0.6),
                        startRadius: size.dimension * 0.10,
                        endRadius: size.dimension * 0.60
                    )
                )
                .frame(width: size.dimension * 1.5, height: size.dimension * 1.5)
                .blur(radius: size.dimension * 0.15)
                .offset(x: size.dimension * 0.08, y: size.dimension * 0.05)
        }
    }

    private var midGlowHalo: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.20 * intensity),
                        coreGlow.opacity(0.30 * intensity * (0.9 + breathePhase * 0.1)),
                        corePurple.opacity(0.15 * intensity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size.dimension * 0.18,
                    endRadius: size.dimension * 0.50
                )
            )
            .frame(width: size.dimension * 1.0, height: size.dimension * 1.0)
            .blur(radius: size.dimension * 0.06)
            .scaleEffect(1.0 + breathePhase * 0.03)
    }

    // MARK: - Main Bubble Body (Translucent)

    private var mainBubbleBody: some View {
        ZStack {
            // Base translucent sphere with gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            coreGlow.opacity(0.45),
                            corePurple.opacity(0.35),
                            corePink.opacity(0.25),
                            Color(red: 0.15, green: 0.25, blue: 0.50).opacity(0.40)
                        ],
                        center: UnitPoint(x: 0.40, y: 0.40),
                        startRadius: size.dimension * 0.05,
                        endRadius: size.dimension * 0.38
                    )
                )
                .frame(width: size.dimension * 0.70, height: size.dimension * 0.70)

            // Angular iridescent overlay
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            iridescenceColors[0].opacity(0.30),
                            iridescenceColors[2].opacity(0.25),
                            iridescenceColors[4].opacity(0.20),
                            iridescenceColors[6].opacity(0.25),
                            iridescenceColors[0].opacity(0.30)
                        ],
                        center: .center,
                        angle: .degrees(colorShiftPhase * 25)
                    )
                )
                .frame(width: size.dimension * 0.68, height: size.dimension * 0.68)
                .blur(radius: size.dimension * 0.05)
                .blendMode(.screen)

            // Bottom shadow for depth
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(red: 0.12, green: 0.18, blue: 0.45).opacity(0.30),
                            Color(red: 0.08, green: 0.12, blue: 0.35).opacity(0.45)
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.35),
                        endPoint: .bottom
                    )
                )
                .frame(width: size.dimension * 0.70, height: size.dimension * 0.70)
        }
        .scaleEffect(1.0 + breathePhase * 0.015)
    }

    // MARK: - Inner Luminescence

    private var innerLuminescence: some View {
        ZStack {
            // Bright cyan core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.70 * intensity),
                            coreGlow.opacity(0.55 * intensity),
                            corePurple.opacity(0.25 * intensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.45, y: 0.40),
                        startRadius: 0,
                        endRadius: size.dimension * 0.28
                    )
                )
                .frame(width: size.dimension * 0.60, height: size.dimension * 0.60)
                .blur(radius: size.dimension * 0.04)

            // Pulsing pink accent
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            corePink.opacity(0.40 * intensity * (0.8 + glowPulsePhase * 0.2)),
                            corePurple.opacity(0.25 * intensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.55, y: 0.50),
                        startRadius: 0,
                        endRadius: size.dimension * 0.20
                    )
                )
                .frame(width: size.dimension * 0.50, height: size.dimension * 0.50)
                .blur(radius: size.dimension * 0.03)
        }
    }

    // MARK: - Iridescent Surface

    private var iridescentSurface: some View {
        ZStack {
            // Main top reflection arc
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            coreGlow.opacity(0.40),
                            corePurple.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: 0.1, y: 0.15),
                        endPoint: UnitPoint(x: 0.75, y: 0.65)
                    )
                )
                .frame(width: size.dimension * 0.55, height: size.dimension * 0.30)
                .rotationEffect(.degrees(-20))
                .offset(x: -size.dimension * 0.06, y: -size.dimension * 0.12)
                .blur(radius: size.dimension * 0.02)

            // Right side iridescent streak
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            corePink.opacity(0.35 * (0.85 + shimmerPhase * 0.15)),
                            corePurple.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: 0.85, y: 0.35),
                        endPoint: UnitPoint(x: 0.35, y: 0.80)
                    )
                )
                .frame(width: size.dimension * 0.22, height: size.dimension * 0.40)
                .offset(x: size.dimension * 0.18, y: 0)
                .blur(radius: size.dimension * 0.02)

            // Bottom pink reflection
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            corePink.opacity(0.30),
                            corePurple.opacity(0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.14
                    )
                )
                .frame(width: size.dimension * 0.28, height: size.dimension * 0.22)
                .offset(x: -size.dimension * 0.08, y: size.dimension * 0.14)
                .blur(radius: size.dimension * 0.02)
        }
    }

    // MARK: - Bubble Rim Light

    private var bubbleRimLight: some View {
        ZStack {
            // Outer rim with iridescence
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.60),
                            coreGlow.opacity(0.45),
                            corePurple.opacity(0.35),
                            Color.clear,
                            Color.clear,
                            corePink.opacity(0.30),
                            Color.white.opacity(0.45)
                        ],
                        center: .center,
                        startAngle: .degrees(-70),
                        endAngle: .degrees(290)
                    ),
                    lineWidth: size.dimension * 0.022
                )
                .frame(width: size.dimension * 0.68, height: size.dimension * 0.68)
                .blur(radius: size.dimension * 0.008)

            // Inner subtle rim
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.30),
                            Color.clear,
                            coreGlow.opacity(0.20),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size.dimension * 0.010
                )
                .frame(width: size.dimension * 0.64, height: size.dimension * 0.64)
        }
    }

    // MARK: - Specular Highlights

    private var specularHighlights: some View {
        ZStack {
            // Primary bright highlight (top-left)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.60),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.055
                    )
                )
                .frame(width: size.dimension * 0.11, height: size.dimension * 0.055)
                .offset(x: -size.dimension * 0.13, y: -size.dimension * 0.17)
                .blur(radius: size.dimension * 0.006)

            // Secondary smaller highlight
            Ellipse()
                .fill(Color.white.opacity(0.50))
                .frame(width: size.dimension * 0.05, height: size.dimension * 0.025)
                .offset(x: -size.dimension * 0.09, y: -size.dimension * 0.21)
                .blur(radius: 1.5)

            // Tiny sparkle point
            Circle()
                .fill(Color.white.opacity(0.80 * (0.7 + shimmerPhase * 0.3)))
                .frame(width: size.dimension * 0.02, height: size.dimension * 0.02)
                .offset(x: -size.dimension * 0.16, y: -size.dimension * 0.14)
                .blur(radius: 0.5)
        }
    }

    // MARK: - Floating Motes

    private var floatingMotes: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                IridescentMote(
                    index: index,
                    phase: colorShiftPhase,
                    orbSize: size.dimension,
                    colors: iridescenceColors
                )
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
            floatPhase = 1.0
        }
        withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
            breathePhase = 1.0
        }
        withAnimation(.linear(duration: 18.0).repeatForever(autoreverses: false)) {
            colorShiftPhase = 14.0
        }
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            shimmerPhase = 1.0
        }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            glowPulsePhase = 1.0
        }
    }
}

// MARK: - Iridescent Mote

private struct IridescentMote: View {
    let index: Int
    let phase: Double
    let orbSize: CGFloat
    let colors: [Color]

    var body: some View {
        let seed = Double(index) * 1.618
        let baseAngle = seed * .pi * 2 / 8
        let radius = orbSize * (0.40 + sin(seed * 2.1) * 0.08)
        let sz = orbSize * (0.012 + sin(seed * 1.7) * 0.006)
        let currentAngle = baseAngle + phase * 0.25
        let x = cos(currentAngle) * radius
        let y = sin(currentAngle) * radius * 0.5

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        colors[index % colors.count].opacity(0.5 + sin(phase * .pi + Double(index)) * 0.3),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: sz
                )
            )
            .frame(width: sz * 2.5, height: sz * 2.5)
            .offset(x: x, y: y)
            .blur(radius: sz * 0.25)
    }
}

// MARK: - Static Orb Logo

struct StaticOrbLogo: View {
    let size: LogoSize
    var intensity: Double = 1.0

    private let coreGlow = Color(red: 0.45, green: 0.88, blue: 0.98)
    private let corePurple = Color(red: 0.65, green: 0.55, blue: 0.95)
    private let corePink = Color(red: 0.85, green: 0.60, blue: 0.90)

    var body: some View {
        ZStack {
            // Outer glow
            if size.showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                coreGlow.opacity(0.40 * intensity),
                                corePurple.opacity(0.25 * intensity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size.dimension * 0.18,
                            endRadius: size.dimension * 0.55
                        )
                    )
                    .frame(width: size.dimension * 1.1, height: size.dimension * 1.1)
                    .blur(radius: size.dimension * 0.08)
            }

            // Main orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            coreGlow.opacity(0.50),
                            corePurple.opacity(0.40),
                            corePink.opacity(0.30),
                            Color(red: 0.15, green: 0.22, blue: 0.45).opacity(0.50)
                        ],
                        center: UnitPoint(x: 0.38, y: 0.38),
                        startRadius: size.dimension * 0.05,
                        endRadius: size.dimension * 0.36
                    )
                )
                .frame(width: size.dimension * 0.70, height: size.dimension * 0.70)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.60 * intensity),
                            coreGlow.opacity(0.45 * intensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.42, y: 0.40),
                        startRadius: 0,
                        endRadius: size.dimension * 0.22
                    )
                )
                .frame(width: size.dimension * 0.55, height: size.dimension * 0.55)
                .blur(radius: size.dimension * 0.025)

            // Top reflection
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.50),
                            coreGlow.opacity(0.35),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.dimension * 0.50, height: size.dimension * 0.28)
                .rotationEffect(.degrees(-22))
                .offset(x: -size.dimension * 0.05, y: -size.dimension * 0.11)
                .blur(radius: size.dimension * 0.018)

            // Specular highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.90),
                            Color.white.opacity(0.50),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.045
                    )
                )
                .frame(width: size.dimension * 0.09, height: size.dimension * 0.045)
                .offset(x: -size.dimension * 0.11, y: -size.dimension * 0.16)
                .blur(radius: 1)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}

// MARK: - Loading Orb Logo

struct LoadingOrbLogo: View {
    let size: LogoSize
    @State private var pulsePhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pulseColors: [Color] = [
        Color(red: 0.45, green: 0.88, blue: 0.98),
        Color(red: 0.65, green: 0.55, blue: 0.95),
        Color(red: 0.85, green: 0.60, blue: 0.90)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let progress = (pulsePhase + Double(index) * 0.33).truncatingRemainder(dividingBy: 1.0)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                pulseColors[index % 3].opacity((1.0 - progress) * 0.5),
                                pulseColors[(index + 1) % 3].opacity((1.0 - progress) * 0.25),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: size.dimension * (0.7 + progress * 0.5),
                        height: size.dimension * (0.7 + progress * 0.5)
                    )
            }
            GlowingOrbLogo(size: size, isAnimating: true, showParticles: false, intensity: 0.9 + pulsePhase * 0.2)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                pulsePhase = 1.0
            }
        }
    }
}

// MARK: - Success Orb Burst

struct SuccessOrbBurst: View {
    let size: LogoSize
    @Binding var shouldBurst: Bool
    @State private var burstParticles: [OrbBurstParticle] = []
    @State private var showCheckmark = false
    @State private var ringScale: CGFloat = 0.5

    private let successColors: [Color] = [
        Color(red: 0.45, green: 0.88, blue: 0.98),
        Color(red: 0.65, green: 0.55, blue: 0.95),
        Color(red: 0.85, green: 0.60, blue: 0.90),
        Color(red: 0.40, green: 0.85, blue: 0.70),
        Color.white
    ]

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.40, green: 0.85, blue: 0.70),
                            Color(red: 0.45, green: 0.88, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size.dimension * ringScale, height: size.dimension * ringScale)
                .opacity(showCheckmark ? 0 : 0.8)

            GlowingOrbLogo(size: size, isAnimating: true, showParticles: false, intensity: 1.3)

            ForEach(burstParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.width, y: particle.offset.height)
                    .opacity(particle.opacity)
                    .blur(radius: particle.size * 0.15)
            }

            if showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: size.dimension * 0.22, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 0.40, green: 0.85, blue: 0.70).opacity(0.8), radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size.dimension * 1.8, height: size.dimension * 1.8)
        .onChange(of: shouldBurst) { _, newValue in
            if newValue { triggerBurst() }
        }
    }

    private func triggerBurst() {
        burstParticles = (0..<24).map { i in
            let angle = Double(i) / 24.0 * 2 * .pi
            let dist = CGFloat.random(in: size.dimension * 0.4...size.dimension * 0.9)
            return OrbBurstParticle(
                id: UUID(),
                color: successColors[i % 5],
                size: CGFloat.random(in: 5...14),
                offset: .zero,
                targetOffset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                opacity: 1.0
            )
        }

        withAnimation(.easeOut(duration: 0.5)) {
            ringScale = 1.5
        }

        withAnimation(.easeOut(duration: 0.7)) {
            for i in burstParticles.indices {
                burstParticles[i].offset = burstParticles[i].targetOffset
            }
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            for i in burstParticles.indices {
                burstParticles[i].opacity = 0
            }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.25)) {
            showCheckmark = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            shouldBurst = false
            showCheckmark = false
            burstParticles = []
            ringScale = 0.5
        }
    }
}

private struct OrbBurstParticle: Identifiable {
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
                Text("MyTasksAI")
                    .font(.system(size: size.dimension * 0.16, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                if showTagline {
                    Text("AI-POWERED PRODUCTIVITY")
                        .font(.system(size: size.dimension * 0.050, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(2)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Ethereal Iridescent Orb") {
    ZStack {
        Color(red: 0.05, green: 0.08, blue: 0.18)
            .ignoresSafeArea()
        GlowingOrbLogo(size: .hero)
    }
}
