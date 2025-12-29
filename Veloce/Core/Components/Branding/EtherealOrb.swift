//
//  EtherealOrb.swift
//  Veloce
//
//  Cosmic Widget Ethereal Orb - AMPLIFIED Electric Cyan Glow
//  AI-powered orb with ultra-saturated cyan accent
//  Uses CosmicWidget design system colors
//

import SwiftUI

// MARK: - Ethereal Orb State

enum EtherealOrbState {
    case idle         // Subtle breathing, minimal movement
    case active       // Enhanced glow, faster color shifts
    case celebration  // Burst effect, rainbow color cycle
}

// MARK: - Ethereal Orb

/// Premium ethereal orb with AMPLIFIED electric cyan glow
/// Uses CosmicWidget ultra-saturated colors
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

    // MARK: - Color Palette (CosmicWidget ULTRA SATURATED)

    // Deep void core - dark cosmic background
    private var voidCore: Color { CosmicWidget.Void.deepSpace }
    private var voidDeep: Color { Color(red: 0.04, green: 0.06, blue: 0.14) }

    // AMPLIFIED Electric Cyan - Primary AI accent (ULTRA BRIGHT)
    private var electricCyan: Color { CosmicWidget.Widget.electricCyan }

    // Supporting colors from CosmicWidget
    private var violet: Color { CosmicWidget.Widget.violet }
    private var magenta: Color { CosmicWidget.Widget.magenta }

    // Highlight colors
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

    // MARK: - Layer 1: Outer Atmospheric Glow (AMPLIFIED CYAN)

    private func outerAtmosphericGlow(size: CGFloat) -> some View {
        ZStack {
            // Primary ELECTRIC CYAN glow - AMPLIFIED
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            electricCyan.opacity(0.50 * effectiveIntensity * glowPulsePhase),
                            electricCyan.opacity(0.25 * effectiveIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.20,
                        endRadius: size * 0.90
                    )
                )
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: size * 0.18)

            // Secondary violet accent glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            violet.opacity(0.30 * effectiveIntensity),
                            violet.opacity(0.12 * effectiveIntensity),
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

            // Outer cyan ring glow - SUPER BRIGHT
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            electricCyan.opacity(0.20 * effectiveIntensity),
                            electricCyan.opacity(0.40 * effectiveIntensity * glowPulsePhase),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.28,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: size * 0.06)
        }
    }

    // MARK: - Layer 2: Core Glass Sphere

    private func coreGlassSphere(size: CGFloat) -> some View {
        ZStack {
            // Deep void core with subtle violet tint
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (tintColor ?? voidDeep).opacity(0.90),
                            voidCore.opacity(0.95),
                            voidCore
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
                            voidCore.opacity(0.3),
                            voidCore.opacity(0.5)
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.35),
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.70, height: size * 0.70)
        }
        .scaleEffect(1.0 + breathePhase * 0.025)
    }

    // MARK: - Layer 3: Inner Color Field (Animated - Cyan + Violet)

    private func innerColorField(size: CGFloat) -> some View {
        let colorProgress = sin(colorShiftPhase * .pi / 4)
        let colorProgress2 = cos(colorShiftPhase * .pi / 4)

        return ZStack {
            // Magenta glow - upper region
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            magenta.opacity(0.35 * effectiveIntensity * (0.7 + colorProgress * 0.3)),
                            magenta.opacity(0.12 * effectiveIntensity),
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

            // ELECTRIC CYAN glow - lower right (AMPLIFIED)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            electricCyan.opacity(0.50 * effectiveIntensity * (0.8 + colorProgress2 * 0.2)),
                            electricCyan.opacity(0.20 * effectiveIntensity),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.55, y: 0.55),
                        startRadius: 0,
                        endRadius: size * 0.20
                    )
                )
                .frame(width: size * 0.45, height: size * 0.35)
                .offset(x: size * 0.08, y: size * 0.06)
                .blur(radius: size * 0.05)

            // Violet center blend
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            violet.opacity(0.35 * effectiveIntensity),
                            violet.opacity(0.15 * effectiveIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.22
                    )
                )
                .frame(width: size * 0.45, height: size * 0.45)
                .blur(radius: size * 0.04)

            // Central cyan luminescence - BRIGHT
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            electricCyan.opacity(0.45 * effectiveIntensity * glowPulsePhase),
                            whiteHighlight.opacity(0.20 * effectiveIntensity),
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

    // MARK: - Layer 4: Rim Highlight (Electric Cyan)

    private func rimHighlight(size: CGFloat) -> some View {
        ZStack {
            // Primary ELECTRIC CYAN rim glow - AMPLIFIED
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            electricCyan.opacity(0.65 * effectiveIntensity),
                            Color.clear,
                            violet.opacity(0.30 * effectiveIntensity),
                            Color.clear,
                            electricCyan.opacity(0.55 * effectiveIntensity),
                            Color.clear,
                            magenta.opacity(0.25 * effectiveIntensity),
                            electricCyan.opacity(0.65 * effectiveIntensity)
                        ],
                        center: .center,
                        startAngle: .degrees(-60 + rimRotation),
                        endAngle: .degrees(300 + rimRotation)
                    ),
                    lineWidth: size * 0.028
                )
                .frame(width: size * 0.68, height: size * 0.68)
                .blur(radius: size * 0.012)

            // Inner soft rim
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            whiteHighlight.opacity(0.35 * effectiveIntensity),
                            Color.clear,
                            electricCyan.opacity(0.20 * effectiveIntensity),
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
                            whiteHighlight.opacity(0.95),
                            whiteHighlight.opacity(0.55),
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
                .fill(whiteHighlight.opacity(0.60))
                .frame(width: size * 0.055, height: size * 0.028)
                .offset(x: -size * 0.10, y: -size * 0.21)
                .blur(radius: 1)

            // Cyan sparkle point (for larger sizes) - AMPLIFIED
            if size >= 80 {
                Circle()
                    .fill(electricCyan.opacity(0.90 * shimmerPhase))
                    .frame(width: size * 0.025)
                    .offset(x: -size * 0.155, y: -size * 0.145)
                    .blur(radius: 0.5)
            }

            // Subtle lower cyan reflection
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            electricCyan.opacity(0.30 * effectiveIntensity),
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
                    Text("AI-POWERED PRODUCTIVITY")
                        .font(.system(size: size.dimension * 0.050, weight: .semibold))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.40))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Ethereal Orb - Hero") {
    ZStack {
        CosmicWidget.Void.deepSpace
            .ignoresSafeArea()

        EtherealOrb(size: .hero)
    }
}

#Preview("Ethereal Orb - Sizes") {
    ZStack {
        CosmicWidget.Void.deepSpace
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
        CosmicWidget.Void.deepSpace
            .ignoresSafeArea()

        VStack(spacing: 50) {
            VStack(spacing: 8) {
                EtherealOrb(size: .large, state: .idle)
                Text("Idle")
                    .font(CosmicWidget.Typography.caption)
                    .foregroundStyle(CosmicWidget.Text.tertiary)
            }

            VStack(spacing: 8) {
                EtherealOrb(size: .large, state: .active)
                Text("Active")
                    .font(CosmicWidget.Typography.caption)
                    .foregroundStyle(CosmicWidget.Text.tertiary)
            }

            VStack(spacing: 8) {
                EtherealOrb(size: .large, state: .celebration)
                Text("Celebration")
                    .font(CosmicWidget.Typography.caption)
                    .foregroundStyle(CosmicWidget.Text.tertiary)
            }
        }
    }
}

#Preview("Ethereal Orb With Branding") {
    ZStack {
        CosmicWidget.Void.deepSpace
            .ignoresSafeArea()

        EtherealOrbWithBranding(size: .hero)
    }
}
