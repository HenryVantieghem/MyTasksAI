//
//  CosmicSplashScreen.swift
//  Veloce
//
//  Cosmic Splash Screen - Living Cosmos Design
//  A mesmerizing 3-second journey from void to brand reveal
//  Stars coalesce into the MyTasksAI logo with cosmic energy
//

import SwiftUI

// MARK: - Cosmic Splash Screen

struct CosmicSplashScreen: View {
    let onComplete: () -> Void

    // MARK: - Animation States
    @State private var phase: SplashPhase = .void
    @State private var starOpacity: Double = 0
    @State private var centralStarScale: CGFloat = 0
    @State private var centralStarOpacity: Double = 0
    @State private var starsCoalescing = false
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var glowIntensity: Double = 0
    @State private var particleBurst = false
    @State private var taglineOpacity: Double = 0
    @State private var stars: [SplashStar] = []
    @State private var coalescingStars: [CoalescingStar] = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum SplashPhase {
        case void           // 0.0s - Pure darkness
        case centralStar    // 0.3s - Single star appears
        case starField      // 0.5s - Stars fade in
        case coalesce       // 1.0s - Stars move toward center
        case logoForm       // 1.5s - Logo forms
        case glow           // 2.0s - Amber glow
        case burst          // 2.5s - Particle burst
        case complete       // 3.0s - Ready to transition
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep void background
                Theme.CelestialColors.voidDeep
                    .ignoresSafeArea()

                // Subtle nebula hint
                nebulaBackground(in: geometry)

                // Star field
                starFieldLayer(in: geometry)

                // Coalescing stars
                coalescingStarsLayer(in: geometry)

                // Central star
                centralStar(in: geometry)

                // Logo reveal
                logoReveal(in: geometry)

                // Particle burst
                if particleBurst {
                    SplashParticleBurst(
                        center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.42)
                    )
                }
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
                startSplashSequence()
            }
        }
    }

    // MARK: - Nebula Background

    private func nebulaBackground(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Primary nebula
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaCore.opacity(0.08 * glowIntensity),
                    Theme.CelestialColors.nebulaEdge.opacity(0.04 * glowIntensity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 300
            )

            // Secondary wisp
            RadialGradient(
                colors: [
                    Theme.CelestialColors.solarFlare.opacity(0.05 * glowIntensity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.7, y: 0.6),
                startRadius: 0,
                endRadius: 200
            )
        }
    }

    // MARK: - Star Field Layer

    private func starFieldLayer(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            for star in stars {
                let rect = CGRect(
                    x: star.position.x - star.size / 2,
                    y: star.position.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )

                let opacity = starOpacity * star.baseOpacity * (starsCoalescing ? 0.3 : 1.0)

                context.fill(
                    SwiftUI.Circle().path(in: rect),
                    with: .color(Color.white.opacity(opacity))
                )

                // Glow for bright stars
                if star.isBright && !starsCoalescing {
                    let glowRect = CGRect(
                        x: star.position.x - star.size,
                        y: star.position.y - star.size,
                        width: star.size * 2,
                        height: star.size * 2
                    )
                    context.fill(
                        SwiftUI.Circle().path(in: glowRect),
                        with: .color(Color.white.opacity(opacity * 0.3))
                    )
                }
            }
        }
    }

    // MARK: - Coalescing Stars Layer

    private func coalescingStarsLayer(in geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.42)

        return ForEach(coalescingStars) { star in
            SwiftUI.Circle()
                .fill(star.color)
                .frame(width: star.size, height: star.size)
                .blur(radius: star.size > 3 ? 1 : 0)
                .position(star.currentPosition)
                .opacity(star.opacity)
        }
    }

    // MARK: - Central Star

    private func centralStar(in geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.42)

        return ZStack {
            // Outer glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.solarFlare.opacity(0.6),
                            Theme.CelestialColors.solarFlare.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 20)

            // Core star
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            Theme.CelestialColors.solarFlare,
                            Theme.CelestialColors.solarFlare.opacity(0.5)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 15
                    )
                )
                .frame(width: 30, height: 30)
        }
        .position(center)
        .scaleEffect(centralStarScale)
        .opacity(centralStarOpacity)
    }

    // MARK: - Logo Reveal

    private func logoReveal(in geometry: GeometryProxy) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            // App Icon/Logo
            ZStack {
                // Amber glow behind logo
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare.opacity(0.5 * glowIntensity),
                                Theme.CelestialColors.solarFlare.opacity(0.2 * glowIntensity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)

                // Logo placeholder - orbital design
                ZStack {
                    // Outer ring
                    SwiftUI.Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Theme.CelestialColors.solarFlare.opacity(0.8),
                                    Theme.Colors.aiPurple.opacity(0.6),
                                    Theme.CelestialColors.plasmaCore.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 80, height: 80)

                    // Inner filled circle
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.CelestialColors.solarFlare,
                                    Theme.Colors.aiPurple.opacity(0.8)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)

                    // Orbital dot
                    SwiftUI.Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .offset(x: 40, y: 0)
                        .rotationEffect(.degrees(glowIntensity * 90))
                }
            }

            // App Name
            Text("MyTasksAI")
                .font(.system(size: 42, weight: .thin, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.starWhite,
                            Theme.CelestialColors.solarFlare.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Tagline
            Text("Achieve the Impossible")
                .font(.system(size: 16, weight: .light, design: .default))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .opacity(taglineOpacity)
        }
        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.45)
        .opacity(logoOpacity)
        .scaleEffect(logoScale)
    }

    // MARK: - Star Generation

    private func generateStars() {
        let screenBounds = UIScreen.main.bounds

        // Generate static star field
        stars = (0..<60).map { _ in
            SplashStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenBounds.width),
                    y: CGFloat.random(in: 0...screenBounds.height)
                ),
                size: CGFloat.random(in: 1...3),
                baseOpacity: Double.random(in: 0.3...0.9),
                isBright: Double.random(in: 0...1) < 0.15
            )
        }

        // Generate coalescing stars
        let center = CGPoint(x: screenBounds.width / 2, y: screenBounds.height * 0.42)
        coalescingStars = (0..<30).map { i in
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 150...400)
            let startPosition = CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )

            return CoalescingStar(
                id: UUID(),
                startPosition: startPosition,
                currentPosition: startPosition,
                targetPosition: center,
                size: CGFloat.random(in: 2...5),
                color: [
                    Color.white,
                    Theme.CelestialColors.plasmaCore,
                    Theme.CelestialColors.solarFlare,
                    Theme.CelestialColors.nebulaEdge
                ].randomElement()!,
                opacity: 0,
                delay: Double(i) * 0.03
            )
        }
    }

    // MARK: - Animation Sequence

    private func startSplashSequence() {
        // Phase 1: Void → Central Star (0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            phase = .centralStar
            withAnimation(.easeOut(duration: 0.4)) {
                centralStarScale = 1.2
                centralStarOpacity = 1
            }
            // Pulse effect
            withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
                centralStarScale = 1.0
            }
        }

        // Phase 2: Star Field Appears (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            phase = .starField
            withAnimation(.easeIn(duration: 0.5)) {
                starOpacity = 1
            }
        }

        // Phase 3: Stars Coalesce (1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            phase = .coalesce

            // Dim central star
            withAnimation(.easeOut(duration: 0.3)) {
                centralStarOpacity = 0.3
            }

            // Start coalescing animation
            withAnimation(.easeIn(duration: 0.3)) {
                starsCoalescing = true
            }

            // Animate each coalescing star
            for (index, star) in coalescingStars.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + star.delay) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        coalescingStars[index].opacity = 1
                    }

                    withAnimation(.easeInOut(duration: 0.5)) {
                        coalescingStars[index].currentPosition = star.targetPosition
                    }

                    // Fade out as it reaches center
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            coalescingStars[index].opacity = 0
                        }
                    }
                }
            }
        }

        // Phase 4: Logo Forms (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            phase = .logoForm

            // Hide central star
            withAnimation(.easeOut(duration: 0.2)) {
                centralStarOpacity = 0
            }

            // Reveal logo
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                logoOpacity = 1
                logoScale = 1.0
            }
        }

        // Phase 5: Amber Glow (2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            phase = .glow
            withAnimation(.easeInOut(duration: 0.5)) {
                glowIntensity = 1.0
            }

            // Tagline fade in
            withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
                taglineOpacity = 1
            }
        }

        // Phase 6: Particle Burst (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            phase = .burst
            particleBurst = true
            HapticsService.shared.impact()
        }

        // Phase 7: Complete (3.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            phase = .complete
            onComplete()
        }
    }
}

// MARK: - Supporting Types

struct SplashStar: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let isBright: Bool
}

struct CoalescingStar: Identifiable {
    let id: UUID
    let startPosition: CGPoint
    var currentPosition: CGPoint
    let targetPosition: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
    let delay: Double
}

// MARK: - Splash Particle Burst

struct SplashParticleBurst: View {
    let center: CGPoint

    @State private var particles: [SplashBurstParticle] = []
    @State private var centralFlash: CGFloat = 0

    var body: some View {
        ZStack {
            // Central flash
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            Theme.CelestialColors.solarFlare.opacity(0.8),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .position(center)
                .scaleEffect(centralFlash)
                .opacity(Double(2 - centralFlash))

            // Particles
            ForEach(particles) { particle in
                SwiftUI.Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .blur(radius: particle.blur)
            }
        }
        .onAppear {
            triggerBurst()
        }
    }

    private func triggerBurst() {
        // Flash
        withAnimation(.easeOut(duration: 0.3)) {
            centralFlash = 2
        }

        // Generate particles
        let colors: [Color] = [
            .white,
            Theme.CelestialColors.solarFlare,
            Theme.CelestialColors.plasmaCore,
            Theme.CelestialColors.nebulaCore
        ]

        for i in 0..<24 {
            let angle = (Double(i) / 24.0) * 2 * .pi + Double.random(in: -0.2...0.2)
            let distance = CGFloat.random(in: 80...180)
            let targetPosition = CGPoint(
                x: center.x + CGFloat(Darwin.cos(angle)) * distance,
                y: center.y + CGFloat(Darwin.sin(angle)) * distance
            )

            var particle = SplashBurstParticle(
                id: UUID(),
                position: center,
                targetPosition: targetPosition,
                size: CGFloat.random(in: 3...7),
                color: colors.randomElement()!,
                opacity: 1,
                blur: 0
            )

            particles.append(particle)

            // Animate outward
            let index = particles.count - 1
            withAnimation(.easeOut(duration: Double.random(in: 0.4...0.7))) {
                particles[index].position = targetPosition
                particles[index].opacity = 0
                particles[index].blur = 2
            }
        }
    }
}

struct SplashBurstParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let targetPosition: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
    var blur: CGFloat
}

// MARK: - Preview

#Preview {
    CosmicSplashScreen {
        print("Splash complete!")
    }
}
