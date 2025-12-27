//
//  CosmicSplashScreen.swift
//  MyTasksAI
//
//  Ultra-Premium Splash Screen
//  A breathtaking journey from void to brand reveal featuring
//  the Neural Orb with prismatic holographic effects.
//  Designed to feel like Apple paid a billion dollars for this.
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

    // MARK: - Animation States
    @State private var phase: SplashPhase = .void
    @State private var starOpacity: Double = 0
    @State private var orbScale: CGFloat = 0.3
    @State private var orbOpacity: Double = 0
    @State private var orbIntensity: Double = 0.5
    @State private var logoOpacity: Double = 0
    @State private var logoOffset: CGFloat = 30
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 20
    @State private var glowIntensity: Double = 0
    @State private var particleBurst = false
    @State private var stars: [SplashStar] = []
    @State private var twinklePhase: Double = 0
    @State private var nebulaPhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Premium prismatic colors
    private let prismaticColors: [Color] = [
        Color(red: 0.55, green: 0.35, blue: 1.0),
        Color(red: 0.35, green: 0.55, blue: 1.0),
        Color(red: 0.25, green: 0.85, blue: 0.95),
        Color(red: 0.95, green: 0.55, blue: 0.85),
    ]

    enum SplashPhase {
        case void           // 0.0s - Pure darkness
        case nebula         // 0.3s - Nebula hints appear
        case orbAppear      // 0.6s - Neural Orb materializes
        case orbGrow        // 1.2s - Orb pulses and grows
        case logoForm       // 2.0s - Logo fades in
        case tagline        // 2.5s - Tagline appears
        case burst          // 3.0s - Particle burst
        case complete       // 3.5s - Ready to transition
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Ultra-deep void background
                premiumBackground

                // Dynamic nebula layers
                dynamicNebula(in: geometry)

                // Premium star field
                premiumStarField(in: geometry)

                // Neural Orb - the hero element
                NeuralOrb(
                    size: .hero,
                    isAnimating: true,
                    intensity: orbIntensity,
                    showParticles: phase == .orbGrow || phase == .logoForm || phase == .tagline || phase == .burst,
                    showNeuralNetwork: phase == .orbGrow || phase == .logoForm || phase == .tagline || phase == .burst
                )
                .scaleEffect(orbScale)
                .opacity(orbOpacity)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.38)

                // Brand reveal
                brandReveal(in: geometry)

                // Particle burst
                if particleBurst {
                    PremiumParticleBurst(
                        center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.38),
                        colors: prismaticColors
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
                startAnimations()
                startSplashSequence()
            }
        }
    }

    // MARK: - Premium Background

    private var premiumBackground: some View {
        ZStack {
            // Pure void
            Color(red: 0.01, green: 0.01, blue: 0.02)
                .ignoresSafeArea()

            // Subtle vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4)
                ],
                center: .center,
                startRadius: 150,
                endRadius: 500
            )
        }
    }

    // MARK: - Dynamic Nebula

    private func dynamicNebula(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Primary nebula - violet
            RadialGradient(
                colors: [
                    prismaticColors[0].opacity(0.15 * glowIntensity),
                    prismaticColors[1].opacity(0.08 * glowIntensity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3 + nebulaPhase * 0.1, y: 0.25),
                startRadius: 0,
                endRadius: 350
            )

            // Secondary nebula - cyan
            RadialGradient(
                colors: [
                    prismaticColors[2].opacity(0.1 * glowIntensity),
                    prismaticColors[3].opacity(0.05 * glowIntensity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.7 - nebulaPhase * 0.1, y: 0.6),
                startRadius: 0,
                endRadius: 280
            )

            // Tertiary wisp - rose
            RadialGradient(
                colors: [
                    prismaticColors[3].opacity(0.08 * glowIntensity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 50,
                endRadius: 400
            )
        }
        .blur(radius: 40)
    }

    // MARK: - Premium Star Field

    private func premiumStarField(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            for star in stars {
                let twinkle = sin(twinklePhase + star.twinkleOffset) * 0.5 + 0.5
                let opacity = starOpacity * star.baseOpacity * (0.5 + twinkle * 0.5)

                let rect = CGRect(
                    x: star.position.x - star.size / 2,
                    y: star.position.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )

                let starColor: Color
                switch star.colorType {
                case 0: starColor = .white
                case 1: starColor = prismaticColors[0]
                case 2: starColor = prismaticColors[2]
                default: starColor = .white
                }

                context.fill(
                    Circle().path(in: rect),
                    with: .color(starColor.opacity(opacity))
                )

                // Glow for bright stars
                if star.isBright {
                    let glowRect = CGRect(
                        x: star.position.x - star.size * 1.5,
                        y: star.position.y - star.size * 1.5,
                        width: star.size * 3,
                        height: star.size * 3
                    )
                    context.fill(
                        Circle().path(in: glowRect),
                        with: .color(starColor.opacity(opacity * 0.3))
                    )
                }
            }
        }
    }

    // MARK: - Brand Reveal

    private func brandReveal(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: geometry.size.height * 0.55)

            // App Name - ultra-premium typography
            Text("MyTasksAI")
                .font(.system(size: 48, weight: .ultraLight, design: .default))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(logoOpacity)
                .offset(y: logoOffset)

            // Tagline
            Text("INTELLIGENT PRODUCTIVITY")
                .font(.system(size: 11, weight: .medium))
                .tracking(5)
                .foregroundStyle(Color.white.opacity(0.45))
                .opacity(taglineOpacity)
                .offset(y: taglineOffset)

            Spacer()
        }
    }

    // MARK: - Star Generation

    private func generateStars() {
        let screenBounds = UIApplication.screenBounds

        stars = (0..<70).map { _ in
            SplashStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenBounds.width),
                    y: CGFloat.random(in: 0...screenBounds.height)
                ),
                size: CGFloat.random(in: 0.8...2.5),
                baseOpacity: Double.random(in: 0.3...0.8),
                twinkleOffset: Double.random(in: 0...(.pi * 2)),
                isBright: Double.random(in: 0...1) < 0.12,
                colorType: Int.random(in: 0...4)
            )
        }
    }

    // MARK: - Continuous Animations

    private func startAnimations() {
        // Star twinkle
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            twinklePhase = .pi * 2
        }

        // Nebula drift
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            nebulaPhase = 1
        }
    }

    // MARK: - Splash Sequence

    private func startSplashSequence() {
        // Phase 1: Nebula hints (0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            phase = .nebula
            withAnimation(.easeIn(duration: 0.6)) {
                glowIntensity = 0.4
                starOpacity = 0.4
            }
        }

        // Phase 2: Orb materializes (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            phase = .orbAppear
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                orbScale = 0.7
                orbOpacity = 0.8
                orbIntensity = 0.7
            }
            withAnimation(.easeIn(duration: 0.4)) {
                starOpacity = 0.7
            }
        }

        // Phase 3: Orb grows and pulses (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            phase = .orbGrow
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                orbScale = 1.0
                orbOpacity = 1.0
                orbIntensity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                glowIntensity = 1.0
                starOpacity = 1.0
            }
        }

        // Phase 4: Logo fades in (2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            phase = .logoForm
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                logoOpacity = 1
                logoOffset = 0
            }
            withAnimation(.easeInOut(duration: 0.4)) {
                orbIntensity = 1.2
            }
        }

        // Phase 5: Tagline appears (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            phase = .tagline
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                taglineOpacity = 1
                taglineOffset = 0
            }
        }

        // Phase 6: Particle burst (3.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            phase = .burst
            particleBurst = true
            HapticsService.shared.impact()
        }

        // Phase 7: Complete (3.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
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
    let twinkleOffset: Double
    let isBright: Bool
    let colorType: Int
}

// MARK: - Premium Particle Burst

struct PremiumParticleBurst: View {
    let center: CGPoint
    let colors: [Color]

    @State private var particles: [PremiumBurstParticle] = []
    @State private var centralFlash: CGFloat = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 1

    var body: some View {
        ZStack {
            // Central flash
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            colors[0].opacity(0.8),
                            colors[1].opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .position(center)
                .scaleEffect(centralFlash)
                .opacity(Double(2.5 - centralFlash) * 0.8)

            // Expanding ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: colors + [colors[0]],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 150, height: 150)
                .position(center)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .blur(radius: 2)

            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                particle.color,
                                particle.color.opacity(0.5),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size
                        )
                    )
                    .frame(width: particle.size * 2, height: particle.size * 2)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            triggerBurst()
        }
    }

    private func triggerBurst() {
        // Central flash
        withAnimation(.easeOut(duration: 0.4)) {
            centralFlash = 2.5
        }

        // Expanding ring
        withAnimation(.easeOut(duration: 0.6)) {
            ringScale = 3
            ringOpacity = 0
        }

        // Generate particles
        for i in 0..<32 {
            let angle = (Double(i) / 32.0) * 2 * .pi + Double.random(in: -0.15...0.15)
            let distance = CGFloat.random(in: 100...220)
            let targetPosition = CGPoint(
                x: center.x + CGFloat(cos(angle)) * distance,
                y: center.y + CGFloat(sin(angle)) * distance
            )

            let particle = PremiumBurstParticle(
                id: UUID(),
                position: center,
                targetPosition: targetPosition,
                size: CGFloat.random(in: 4...10),
                color: colors.randomElement()!,
                opacity: 1
            )

            particles.append(particle)

            // Animate outward
            let index = particles.count - 1
            withAnimation(.easeOut(duration: Double.random(in: 0.5...0.8))) {
                particles[index].position = targetPosition
                particles[index].opacity = 0
            }
        }
    }
}

struct PremiumBurstParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let targetPosition: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
}

// MARK: - Preview

#Preview {
    CosmicSplashScreen {
        print("Splash complete!")
    }
}
