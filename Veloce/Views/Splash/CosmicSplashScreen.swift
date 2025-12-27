//
//  CosmicSplashScreen.swift
//  MyTasksAI
//
//  Celestial Luminescence Splash Screen
//  A breathtaking journey from void to brand reveal featuring
//  the Ethereal Orb with soft, iridescent glow.
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Ethereal color palette (matching EtherealOrb)
    private let etherealColors: [Color] = [
        Color(red: 0.75, green: 0.55, blue: 0.90), // softPurple
        Color(red: 0.55, green: 0.85, blue: 0.95), // softCyan
        Color(red: 0.95, green: 0.65, blue: 0.80), // softPink
        Color(red: 0.70, green: 0.60, blue: 0.95), // softLavender
    ]

    enum SplashPhase {
        case void           // 0.0s - Pure darkness
        case nebulaHints    // 0.3s - Subtle nebula appears
        case orbMaterialize // 0.6s - Ethereal Orb fades in
        case orbGlow        // 1.3s - Orb expands with glow
        case brandReveal    // 2.0s - Logo fades in elegantly
        case tagline        // 2.5s - Tagline appears
        case ambientSettle  // 3.0s - Particles float in
        case complete       // 3.5s - Ready to transition
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Ultra-deep void background
                premiumVoidBackground

                // Subtle nebula layers
                subtleNebula(in: geometry)

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

                // Ethereal Orb - the hero element
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

                // Brand reveal
                brandReveal(in: geometry)
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
                startSplashSequence()
            }
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

    // MARK: - Brand Reveal

    private func brandReveal(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 14) {
            Spacer()
                .frame(height: geometry.size.height * 0.56)

            // App Name - refined typography
            Text("MyTasksAI")
                .font(.system(size: 52, weight: .thin, design: .default))
                .tracking(6)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(logoOpacity)
                .offset(y: logoOffset)

            // Tagline - increased tracking
            Text("INTELLIGENT PRODUCTIVITY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(6)
                .foregroundStyle(Color.white.opacity(0.38))
                .opacity(taglineOpacity)
                .offset(y: taglineOffset)

            Spacer()
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

    // MARK: - Splash Sequence

    private func startSplashSequence() {
        // Phase 1: Nebula hints (0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            phase = .nebulaHints
            withAnimation(.easeIn(duration: 0.5)) {
                glowIntensity = 0.35
                starOpacity = 0.35
            }
        }

        // Phase 2: Orb materializes (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            phase = .orbMaterialize
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                orbScale = 0.75
                orbOpacity = 0.85
                orbIntensity = 0.75
            }
            withAnimation(.easeIn(duration: 0.4)) {
                starOpacity = 0.60
            }
        }

        // Phase 3: Orb expands with glow (1.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            phase = .orbGlow
            orbState = .active
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                orbScale = 1.0
                orbOpacity = 1.0
                orbIntensity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                glowIntensity = 1.0
                starOpacity = 0.85
            }
        }

        // Phase 4: Logo fades in (2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            phase = .brandReveal
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                logoOpacity = 1
                logoOffset = 0
            }
            withAnimation(.easeInOut(duration: 0.35)) {
                orbIntensity = 1.15
            }
        }

        // Phase 5: Tagline appears (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            phase = .tagline
            withAnimation(.spring(response: 0.45, dampingFraction: 0.80)) {
                taglineOpacity = 1
                taglineOffset = 0
            }
        }

        // Phase 6: Ambient particles settle in (3.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            phase = .ambientSettle
            withAnimation(.easeIn(duration: 0.4)) {
                showParticles = true
            }
            // Gentle orb pulse
            orbState = .idle
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

// MARK: - Preview

#Preview {
    CosmicSplashScreen {
        print("Splash complete!")
    }
}
