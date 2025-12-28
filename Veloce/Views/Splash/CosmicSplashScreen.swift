//
//  CosmicSplashScreen.swift
//  MyTasksAI
//
//  Ultra-Premium Liquid Glass Splash Screen
//  A breathtaking 9-phase journey from void to brand reveal featuring
//  the Ethereal Orb with iOS 26 Liquid Glass effects, glass halo rings,
//  prismatic shimmers, and seamless morphing transitions.
//  Designed with premium elegance and refined animations.
//

import SwiftUI

// MARK: - Screen Bounds Helper

private extension UIApplication {
    static var screenBounds: CGRect {
        guard let windowScene = shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return CGRect(x: 0, y: 0, width: 393, height: 852) // iPhone 15 Pro fallback
        }
        return windowScene.screen.bounds
    }
}

// MARK: - Cosmic Splash Screen

struct CosmicSplashScreen: View {
    let onComplete: () -> Void

    // Glass morphing namespace for transition to Auth
    @Namespace private var splashNamespace

    // MARK: - Animation States
    @State private var phase: SplashPhase = .void
    @State private var starOpacity: Double = 0
    @State private var orbScale: CGFloat = 0.4
    @State private var orbOpacity: Double = 0
    @State private var orbIntensity: Double = 0.5
    @State private var orbState: EtherealOrbState = .idle
    @State private var logoOpacity: Double = 0
    @State private var logoOffset: CGFloat = 25
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 15
    @State private var glowIntensity: Double = 0
    @State private var showParticles = false
    @State private var stars: [SplashStar] = []
    @State private var twinklePhase: Double = 0
    @State private var nebulaPhase: Double = 0

    // 🔮 Liquid Glass Animation States
    @State private var glassRingScale: CGFloat = 0.3
    @State private var glassRingOpacity: Double = 0
    @State private var glassRingRotation: Double = 0
    @State private var innerRingScale: CGFloat = 0.2
    @State private var innerRingOpacity: Double = 0
    @State private var prismaticRotation: Double = 0
    @State private var glassShimmerOffset: CGFloat = -200
    @State private var logoGlassOpacity: Double = 0
    @State private var showGlassParticles = false
    @State private var transitionReady = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Ethereal color palette (matching EtherealOrb)
    private let etherealColors: [Color] = [
        Color(red: 0.75, green: 0.55, blue: 0.90), // softPurple
        Color(red: 0.55, green: 0.85, blue: 0.95), // softCyan
        Color(red: 0.95, green: 0.65, blue: 0.80), // softPink
        Color(red: 0.70, green: 0.60, blue: 0.95), // softLavender
    ]

    // 🔮 Enhanced 9-Phase Animation Sequence (4.5s total)
    enum SplashPhase {
        case void               // 0.0s - Deep void initialization
        case nebulaHints        // 0.3s - Nebula tendrils with glass shimmer
        case orbMaterialize     // 0.6s - EtherealOrb materializes with glass halo
        case orbExpand          // 1.2s - Orb expands with particle burst
        case glassRings         // 1.8s - Glass rings morph around orb
        case brandReveal        // 2.4s - Brand text reveals with glass underlay
        case tagline            // 3.0s - Tagline with prismatic shimmer
        case ambientSettle      // 3.6s - Ambient settle with floating glass particles
        case transitionReady    // 4.2s - Prepare morphing transition to Auth
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Ultra-deep void background
                premiumVoidBackground

                // Subtle nebula layers with glass shimmer
                subtleNebula(in: geometry)

                // Glass shimmer overlay
                glassShimmerLayer(in: geometry)

                // Refined star field
                refinedStarField(in: geometry)

                // Ambient particle field
                if showParticles {
                    AmbientParticleField(
                        density: .sparse,
                        colors: etherealColors,
                        bounds: geometry.size
                    )
                    .opacity(showParticles ? 0.8 : 0)
                }

                // 🔮 Floating glass particles
                if showGlassParticles {
                    SplashGlassParticleField(bounds: geometry.size)
                        .opacity(showGlassParticles ? 0.7 : 0)
                }

                // 🔮 Glass halo rings around orb
                glassHaloRings(in: geometry)

                // Ethereal Orb - the hero element with glass morphing ID
                EtherealOrb(
                    size: .hero,
                    state: orbState,
                    isAnimating: true,
                    intensity: orbIntensity,
                    showGlow: true
                )
                .scaleEffect(orbScale)
                .opacity(orbOpacity)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.38)
                .matchedGeometryEffect(id: "heroOrb", in: splashNamespace)

                // 🔮 Brand reveal with glass underlay
                liquidGlassBrandReveal(in: geometry)
            }
        }
        .onAppear {
            if reduceMotion {
                // Skip animations for accessibility
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            } else {
                generateStars()
                startContinuousAnimations()
                startGlassAnimations()
                startEnhancedSplashSequence()
            }
        }
    }

    // MARK: - 🔮 Glass Shimmer Layer

    private func glassShimmerLayer(in geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.08),
                        LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.06),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 150, height: geometry.size.height)
            .blur(radius: 30)
            .offset(x: glassShimmerOffset)
            .opacity(phase != .void ? 0.6 : 0)
    }

    // MARK: - 🔮 Glass Halo Rings

    private func glassHaloRings(in geometry: GeometryProxy) -> some View {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height * 0.38

        return ZStack {
            // Outer glass ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.4),
                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.3),
                            LiquidGlassDesignSystem.VibrantAccents.nebulaPink.opacity(0.25),
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.4)
                        ],
                        center: .center,
                        startAngle: .degrees(glassRingRotation),
                        endAngle: .degrees(glassRingRotation + 360)
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 180, height: 180)
                .scaleEffect(glassRingScale)
                .opacity(glassRingOpacity)
                .blur(radius: 0.5)

            // Inner glass ring with different rotation
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            LiquidGlassDesignSystem.VibrantAccents.auroraGreen.opacity(0.3),
                            LiquidGlassDesignSystem.VibrantAccents.solarGold.opacity(0.25),
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.3),
                            LiquidGlassDesignSystem.VibrantAccents.auroraGreen.opacity(0.3)
                        ],
                        center: .center,
                        startAngle: .degrees(-glassRingRotation * 0.7),
                        endAngle: .degrees(-glassRingRotation * 0.7 + 360)
                    ),
                    lineWidth: 1
                )
                .frame(width: 140, height: 140)
                .scaleEffect(innerRingScale)
                .opacity(innerRingOpacity)

            // Glass halo glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.15 * glassRingOpacity),
                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.08 * glassRingOpacity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(glassRingScale)
        }
        .position(x: centerX, y: centerY)
    }

    // MARK: - 🔮 Liquid Glass Brand Reveal

    private func liquidGlassBrandReveal(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 14) {
            Spacer()
                .frame(height: geometry.size.height * 0.56)

            // Glass underlay for logo
            ZStack {
                // Glass backing
                if logoGlassOpacity > 0 {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(width: 280, height: 80)
                        .opacity(logoGlassOpacity * 0.3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                }

                // App Name - with prismatic shimmer
                ZStack {
                    Text("Veloce")
                        .font(.system(size: 52, weight: .thin, design: .default))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.88)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // Prismatic shimmer overlay
                    Text("Veloce")
                        .font(.system(size: 52, weight: .thin, design: .default))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.5),
                                    LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.4),
                                    .clear
                                ],
                                startPoint: UnitPoint(x: prismaticRotation - 0.5, y: 0),
                                endPoint: UnitPoint(x: prismaticRotation + 0.5, y: 1)
                            )
                        )
                        .opacity(logoOpacity > 0.5 ? 0.6 : 0)
                }
                .opacity(logoOpacity)
                .offset(y: logoOffset)
            }

            // Tagline with subtle glass effect
            ZStack {
                // Glass pill backing
                if taglineOpacity > 0.5 {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .frame(width: 200, height: 24)
                        .opacity(taglineOpacity * 0.2)
                }

                Text("VELOCITY FOR LIFE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(6)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .opacity(taglineOpacity)
            .offset(y: taglineOffset)

            Spacer()
        }
    }

    // MARK: - 🔮 Glass Continuous Animations

    private func startGlassAnimations() {
        // Glass ring rotation
        withAnimation(
            .linear(duration: LiquidGlassDesignSystem.MorphAnimation.prismaticRotation)
            .repeatForever(autoreverses: false)
        ) {
            glassRingRotation = 360
        }

        // Prismatic shimmer sweep
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            prismaticRotation = 1.5
        }

        // Glass shimmer sweep across screen
        withAnimation(
            .easeInOut(duration: 4.0)
            .repeatForever(autoreverses: false)
        ) {
            glassShimmerOffset = UIApplication.screenBounds.width + 200
        }
    }

    // MARK: - Premium Void Background

    private var premiumVoidBackground: some View {
        ZStack {
            // True void (consistent with VoidBackground)
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()

            // Subtle radial vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Theme.CelestialColors.void.opacity(0.5),
                    Color.black.opacity(0.35)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Subtle Nebula

    private func subtleNebula(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Primary nebula - soft purple
            RadialGradient(
                colors: [
                    etherealColors[0].opacity(0.12 * glowIntensity),
                    etherealColors[3].opacity(0.06 * glowIntensity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.35 + nebulaPhase * 0.08, y: 0.28),
                startRadius: 0,
                endRadius: 300
            )
            .blur(radius: 50)

            // Secondary nebula - soft cyan
            RadialGradient(
                colors: [
                    etherealColors[1].opacity(0.08 * glowIntensity),
                    etherealColors[2].opacity(0.04 * glowIntensity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.65 - nebulaPhase * 0.08, y: 0.55),
                startRadius: 0,
                endRadius: 250
            )
            .blur(radius: 45)

            // Central glow halo around orb position
            RadialGradient(
                colors: [
                    etherealColors[1].opacity(0.10 * glowIntensity),
                    etherealColors[0].opacity(0.05 * glowIntensity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 30,
                endRadius: 200
            )
            .blur(radius: 30)
        }
    }

    // MARK: - Refined Star Field

    private func refinedStarField(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            for star in stars {
                let twinkle = sin(twinklePhase + star.twinkleOffset) * 0.5 + 0.5
                let opacity = starOpacity * star.baseOpacity * (0.6 + twinkle * 0.4)

                let rect = CGRect(
                    x: star.position.x - star.size / 2,
                    y: star.position.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )

                let starColor: Color
                switch star.colorType {
                case 0: starColor = .white
                case 1: starColor = etherealColors[0].opacity(0.8)
                case 2: starColor = etherealColors[1].opacity(0.8)
                default: starColor = .white
                }

                context.fill(
                    Circle().path(in: rect),
                    with: .color(starColor.opacity(opacity))
                )

                // Subtle glow for bright stars
                if star.isBright {
                    let glowRect = CGRect(
                        x: star.position.x - star.size * 1.2,
                        y: star.position.y - star.size * 1.2,
                        width: star.size * 2.4,
                        height: star.size * 2.4
                    )
                    context.fill(
                        Circle().path(in: glowRect),
                        with: .color(starColor.opacity(opacity * 0.25))
                    )
                }
            }
        }
    }

    // MARK: - Star Generation

    private func generateStars() {
        let screenBounds = UIApplication.screenBounds

        // Reduced star count for cleaner look (70 -> 45)
        stars = (0..<45).map { _ in
            SplashStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenBounds.width),
                    y: CGFloat.random(in: 0...screenBounds.height)
                ),
                size: CGFloat.random(in: 0.6...2.0),
                baseOpacity: Double.random(in: 0.25...0.70),
                twinkleOffset: Double.random(in: 0...(.pi * 2)),
                isBright: Double.random(in: 0...1) < 0.10,
                colorType: Int.random(in: 0...4)
            )
        }
    }

    // MARK: - Continuous Animations

    private func startContinuousAnimations() {
        // Star twinkle
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            twinklePhase = .pi * 2
        }

        // Nebula drift (slower for elegance)
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            nebulaPhase = 1
        }
    }

    // MARK: - 🔮 Enhanced 9-Phase Splash Sequence (4.5s total)

    private func startEnhancedSplashSequence() {
        // Phase 1: Nebula hints with glass shimmer (0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            phase = .nebulaHints
            withAnimation(.easeIn(duration: 0.5)) {
                glowIntensity = 0.35
                starOpacity = 0.35
            }
        }

        // Phase 2: Orb materializes with glass halo (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            phase = .orbMaterialize
            withAnimation(LiquidGlassDesignSystem.Springs.reveal) {
                orbScale = 0.75
                orbOpacity = 0.85
                orbIntensity = 0.75
            }
            withAnimation(.easeIn(duration: 0.4)) {
                starOpacity = 0.60
            }
        }

        // Phase 3: Orb expands with particle burst (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            phase = .orbExpand
            orbState = .active
            HapticsService.shared.cosmicPulse()

            withAnimation(LiquidGlassDesignSystem.Springs.focus) {
                orbScale = 1.0
                orbOpacity = 1.0
                orbIntensity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                glowIntensity = 1.0
                starOpacity = 0.85
            }
        }

        // Phase 4: Glass rings morph around orb (1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            phase = .glassRings
            HapticsService.shared.glassMorph()

            withAnimation(LiquidGlassDesignSystem.Springs.reveal) {
                glassRingScale = 1.0
                glassRingOpacity = 1.0
                innerRingScale = 1.0
                innerRingOpacity = 0.8
            }
        }

        // Phase 5: Brand text reveals with glass underlay (2.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            phase = .brandReveal
            HapticsService.shared.sparkleCascade()

            withAnimation(LiquidGlassDesignSystem.Springs.reveal) {
                logoOpacity = 1
                logoOffset = 0
                logoGlassOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.35)) {
                orbIntensity = 1.15
            }
        }

        // Phase 6: Tagline with prismatic shimmer (3.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            phase = .tagline
            withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                taglineOpacity = 1
                taglineOffset = 0
            }
        }

        // Phase 7: Ambient settle with floating glass particles (3.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            phase = .ambientSettle
            withAnimation(.easeIn(duration: 0.4)) {
                showParticles = true
                showGlassParticles = true
            }
            // Gentle orb pulse
            orbState = .idle
        }

        // Phase 8: Prepare morphing transition to Auth (4.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            phase = .transitionReady
            transitionReady = true
            HapticsService.shared.glassMorph()

            // Subtle preparation for transition
            withAnimation(.easeOut(duration: 0.3)) {
                glassRingOpacity = 0.6
                innerRingOpacity = 0.5
            }
        }

        // Phase 9: Complete (4.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            onComplete()
        }
    }
}

// MARK: - 🔮 Splash Glass Particle Field (distinct from other GlassParticleField types)

private struct SplashGlassParticleField: View {
    let bounds: CGSize

    @State private var particles: [SplashGlassParticle] = []

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x - particle.size / 2,
                    y: particle.position.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )

                // Glass circle with gradient
                context.fill(
                    Circle().path(in: rect),
                    with: .color(particle.color.opacity(particle.opacity))
                )

                // Subtle glow
                let glowRect = CGRect(
                    x: particle.position.x - particle.size,
                    y: particle.position.y - particle.size,
                    width: particle.size * 2,
                    height: particle.size * 2
                )
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(particle.color.opacity(particle.opacity * 0.2))
                )
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        let colors: [Color] = [
            LiquidGlassDesignSystem.VibrantAccents.electricCyan,
            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
            LiquidGlassDesignSystem.VibrantAccents.auroraGreen,
            Color.white
        ]

        particles = (0..<25).map { _ in
            SplashGlassParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: CGFloat.random(in: 0...bounds.height)
                ),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.2...0.5),
                color: colors.randomElement() ?? .white
            )
        }
    }
}

private struct SplashGlassParticle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let color: Color
}

// MARK: - Supporting Types

struct SplashStar: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let twinkleOffset: Double
    let isBright: Bool
    let colorType: Int
}

// MARK: - Preview

#Preview {
    CosmicSplashScreen {
        print("Splash complete!")
    }
}
