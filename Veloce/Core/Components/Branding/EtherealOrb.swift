//
//  EtherealOrb.swift
//  Veloce
//
//  Premium Ethereal Orb Logo
//  A clean, translucent iridescent sphere with soft ethereal glow
//  Inspired by the reference image - no neural patterns, pure elegance
//

import SwiftUI

// MARK: - Ethereal Orb State

enum EtherealOrbState {
    case idle         // Subtle breathing, minimal movement
    case active       // Enhanced glow, faster color shifts
    case celebration  // Burst effect, rainbow color cycle
}

// MARK: - Ethereal Orb

/// Premium ethereal orb logo - clean, translucent, iridescent
/// Matches the reference image aesthetic with soft pink/purple/cyan colors
struct EtherealOrb: View {
    let size: LogoSize
    var state: EtherealOrbState = .idle
    var isAnimating: Bool = true
    var intensity: Double = 1.0
    var showGlow: Bool = true
    var tintColor: Color? = nil

    // Animation states
    @State private var breathePhase: CGFloat = 0
    @State private var colorShiftPhase: Double = 0
    @State private var glowPulsePhase: Double = 0.8
    @State private var shimmerPhase: Double = 0.6
    @State private var floatOffset: CGFloat = 0
    @State private var celebrationScale: CGFloat = 1.0
    @State private var rimRotation: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Color Palette (matching reference image)

    // Deep background colors
    private let voidIndigo = Color(red: 0.08, green: 0.06, blue: 0.18)
    private let deepPurple = Color(red: 0.15, green: 0.10, blue: 0.30)

    // Inner ethereal colors (soft, pastel-like)
    private let softPink = Color(red: 0.95, green: 0.65, blue: 0.80)
    private let softPurple = Color(red: 0.75, green: 0.55, blue: 0.90)
    private let softCyan = Color(red: 0.55, green: 0.85, blue: 0.95)
    private let softLavender = Color(red: 0.70, green: 0.60, blue: 0.95)

    // Rim/Edge colors
    private let cyanRim = Color(red: 0.25, green: 0.85, blue: 0.95)
    private let whiteHighlight = Color.white

    // Computed properties for animation
    private var effectiveIntensity: Double {
        switch state {
        case .idle: return intensity
        case .active: return intensity * 1.3
        case .celebration: return intensity * 1.6
        }
    }

    private var breatheDuration: Double {
        switch state {
        case .idle: return 4.0
        case .active: return 2.5
        case .celebration: return 1.5
        }
    }

    private var colorShiftDuration: Double {
        switch state {
        case .idle: return 8.0
        case .active: return 5.0
        case .celebration: return 2.0
        }
    }

    var body: some View {
        let dim = size.dimension

        ZStack {
            // Layer 1: Outer Atmospheric Glow
            if showGlow && size.showGlow {
                outerAtmosphericGlow(size: dim)
            }

            // Layer 2: Core Glass Sphere
            coreGlassSphere(size: dim)

            // Layer 3: Inner Color Field (animated)
            innerColorField(size: dim)

            // Layer 4: Rim Highlight
            rimHighlight(size: dim)

            // Layer 5: Specular Highlights
            specularHighlights(size: dim)
        }
        .frame(width: dim * 1.5, height: dim * 1.5)
        .scaleEffect(celebrationScale)
        .offset(y: floatOffset)
        .onAppear {
            guard isAnimating && !reduceMotion else { return }
            startAnimations()
        }
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
        }
    }

    // MARK: - Layer 1: Outer Atmospheric Glow

    private func outerAtmosphericGlow(size: CGFloat) -> some View {
        ZStack {
            // Primary soft purple glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            softPurple.opacity(0.35 * effectiveIntensity * glowPulsePhase),
                            softCyan.opacity(0.20 * effectiveIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.25,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.15)

            // Secondary pink accent glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            softPink.opacity(0.25 * effectiveIntensity),
                            softLavender.opacity(0.12 * effectiveIntensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.55, y: 0.40),
                        startRadius: size * 0.10,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .blur(radius: size * 0.12)
                .offset(x: size * 0.03)

            // Cyan rim glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            cyanRim.opacity(0.15 * effectiveIntensity),
                            cyanRim.opacity(0.25 * effectiveIntensity * glowPulsePhase),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.30,
                        endRadius: size * 0.52
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)
                .blur(radius: size * 0.05)
        }
    }

    // MARK: - Layer 2: Core Glass Sphere

    private func coreGlassSphere(size: CGFloat) -> some View {
        ZStack {
            // Deep translucent base with depth gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (tintColor ?? deepPurple).opacity(0.85),
                            voidIndigo.opacity(0.92),
                            voidIndigo
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: size * 0.05,
                        endRadius: size * 0.38
                    )
                )
                .frame(width: size * 0.70, height: size * 0.70)

            // Subtle depth shadow at bottom
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            voidIndigo.opacity(0.3),
                            voidIndigo.opacity(0.5)
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.35),
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.70, height: size * 0.70)
        }
        .scaleEffect(1.0 + breathePhase * 0.025)
    }

    // MARK: - Layer 3: Inner Color Field (Animated)

    private func innerColorField(size: CGFloat) -> some View {
        let colorProgress = sin(colorShiftPhase * .pi / 4)
        let colorProgress2 = cos(colorShiftPhase * .pi / 4)

        return ZStack {
            // Pink glow - upper region
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            softPink.opacity(0.40 * effectiveIntensity * (0.7 + colorProgress * 0.3)),
                            softPink.opacity(0.15 * effectiveIntensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.45, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.20
                    )
                )
                .frame(width: size * 0.45, height: size * 0.35)
                .offset(x: -size * 0.06, y: -size * 0.08)
                .blur(radius: size * 0.06)

            // Cyan glow - lower right
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            softCyan.opacity(0.35 * effectiveIntensity * (0.8 + colorProgress2 * 0.2)),
                            softCyan.opacity(0.12 * effectiveIntensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.55, y: 0.55),
                        startRadius: 0,
                        endRadius: size * 0.18
                    )
                )
                .frame(width: size * 0.40, height: size * 0.30)
                .offset(x: size * 0.08, y: size * 0.06)
                .blur(radius: size * 0.05)

            // Purple center blend
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            softPurple.opacity(0.30 * effectiveIntensity),
                            softLavender.opacity(0.15 * effectiveIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.22
                    )
                )
                .frame(width: size * 0.45, height: size * 0.45)
                .blur(radius: size * 0.04)

            // Central white luminescence
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            whiteHighlight.opacity(0.35 * effectiveIntensity * glowPulsePhase),
                            whiteHighlight.opacity(0.15 * effectiveIntensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.42, y: 0.40),
                        startRadius: 0,
                        endRadius: size * 0.15
                    )
                )
                .frame(width: size * 0.35, height: size * 0.35)
                .blur(radius: size * 0.03)
        }
        .blendMode(.screen)
    }

    // MARK: - Layer 4: Rim Highlight

    private func rimHighlight(size: CGFloat) -> some View {
        ZStack {
            // Primary cyan rim glow
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            cyanRim.opacity(0.55 * effectiveIntensity),
                            Color.clear,
                            softPurple.opacity(0.25 * effectiveIntensity),
                            Color.clear,
                            cyanRim.opacity(0.45 * effectiveIntensity),
                            Color.clear,
                            softPink.opacity(0.20 * effectiveIntensity),
                            cyanRim.opacity(0.55 * effectiveIntensity)
                        ],
                        center: .center,
                        startAngle: .degrees(-60 + rimRotation),
                        endAngle: .degrees(300 + rimRotation)
                    ),
                    lineWidth: size * 0.025
                )
                .frame(width: size * 0.68, height: size * 0.68)
                .blur(radius: size * 0.012)

            // Inner soft rim
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            whiteHighlight.opacity(0.30 * effectiveIntensity),
                            Color.clear,
                            cyanRim.opacity(0.15 * effectiveIntensity),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.012
                )
                .frame(width: size * 0.64, height: size * 0.64)
        }
    }

    // MARK: - Layer 5: Specular Highlights

    private func specularHighlights(size: CGFloat) -> some View {
        ZStack {
            // Primary specular (upper left)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            whiteHighlight.opacity(0.90),
                            whiteHighlight.opacity(0.50),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.055
                    )
                )
                .frame(width: size * 0.12, height: size * 0.06)
                .offset(x: -size * 0.13, y: -size * 0.17)
                .blur(radius: size * 0.008)

            // Secondary specular (smaller, above primary)
            Ellipse()
                .fill(whiteHighlight.opacity(0.55))
                .frame(width: size * 0.055, height: size * 0.028)
                .offset(x: -size * 0.10, y: -size * 0.21)
                .blur(radius: 1)

            // Sparkle point (for larger sizes)
            if size >= 80 {
                Circle()
                    .fill(whiteHighlight.opacity(0.85 * shimmerPhase))
                    .frame(width: size * 0.022)
                    .offset(x: -size * 0.155, y: -size * 0.145)
                    .blur(radius: 0.5)
            }

            // Subtle lower reflection
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            cyanRim.opacity(0.20 * effectiveIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.08
                    )
                )
                .frame(width: size * 0.15, height: size * 0.08)
                .offset(x: size * 0.08, y: size * 0.18)
                .blur(radius: size * 0.02)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Breathing animation
        withAnimation(.easeInOut(duration: breatheDuration).repeatForever(autoreverses: true)) {
            breathePhase = 1.0
        }

        // Color shift rotation
        withAnimation(.linear(duration: colorShiftDuration).repeatForever(autoreverses: false)) {
            colorShiftPhase = 8.0
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowPulsePhase = 1.0
        }

        // Shimmer for specular highlights
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            shimmerPhase = 1.0
        }

        // Subtle float
        withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
            floatOffset = -size.dimension * 0.03
        }

        // Rim rotation
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            rimRotation = 360
        }
    }

    private func handleStateChange(_ newState: EtherealOrbState) {
        guard !reduceMotion else { return }

        switch newState {
        case .idle:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                celebrationScale = 1.0
            }

        case .active:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                celebrationScale = 1.05
            }

        case .celebration:
            // Scale burst
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                celebrationScale = 1.15
            }

            // Return to slightly elevated scale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    celebrationScale = 1.08
                }
            }
        }
    }
}

// MARK: - Static Ethereal Orb

/// Non-animated version for performance-sensitive contexts
struct StaticEtherealOrb: View {
    let size: LogoSize
    var intensity: Double = 1.0

    var body: some View {
        EtherealOrb(size: size, isAnimating: false, intensity: intensity)
    }
}

// MARK: - Ethereal Orb With Branding

/// Orb with MyTasksAI branding below
struct EtherealOrbWithBranding: View {
    let size: LogoSize
    var showTagline: Bool = true

    var body: some View {
        VStack(spacing: size.dimension * 0.14) {
            EtherealOrb(size: size)

            VStack(spacing: 8) {
                Text("MyTasksAI")
                    .font(.system(size: size.dimension * 0.20, weight: .thin))
                    .tracking(5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if showTagline {
                    Text("INTELLIGENT PRODUCTIVITY")
                        .font(.system(size: size.dimension * 0.052, weight: .semibold))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Ethereal Orb - Hero") {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        EtherealOrb(size: .hero)
    }
}

#Preview("Ethereal Orb - Sizes") {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        VStack(spacing: 40) {
            EtherealOrb(size: .hero)

            HStack(spacing: 30) {
                EtherealOrb(size: .large)
                EtherealOrb(size: .medium)
            }

            HStack(spacing: 20) {
                EtherealOrb(size: .small)
                EtherealOrb(size: .tiny)
            }
        }
    }
}

#Preview("Ethereal Orb - States") {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        VStack(spacing: 50) {
            VStack(spacing: 8) {
                EtherealOrb(size: .large, state: .idle)
                Text("Idle").font(.caption).foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 8) {
                EtherealOrb(size: .large, state: .active)
                Text("Active").font(.caption).foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 8) {
                EtherealOrb(size: .large, state: .celebration)
                Text("Celebration").font(.caption).foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

#Preview("Ethereal Orb With Branding") {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        EtherealOrbWithBranding(size: .hero)
    }
}
