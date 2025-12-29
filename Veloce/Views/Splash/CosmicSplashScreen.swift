//
//  CosmicSplashScreen.swift
//  Veloce
//
//  Cosmic Widget Splash Screen - SIMPLIFIED
//  5-phase journey from void to brand reveal (2.5s total)
//  Uses CosmicWidget design system with amplified cyan glow
//

import SwiftUI

// MARK: - Cosmic Splash Screen

struct CosmicSplashScreen: View {
    let onComplete: () -> Void

    // MARK: - Animation States
    @State private var phase: SplashPhase = .void
    @State private var starOpacity: Double = 0
    @State private var orbScale: CGFloat = 0.3
    @State private var orbOpacity: Double = 0
    @State private var orbIntensity: Double = 0.5
    @State private var orbState: EtherealOrbState = .idle
    @State private var logoOpacity: Double = 0
    @State private var logoOffset: CGFloat = 20
    @State private var glowIntensity: Double = 0
    @State private var stars: [SplashStar] = []
    @State private var twinklePhase: Double = 0

    // Glass halo ring states
    @State private var glassRingScale: CGFloat = 0.5
    @State private var glassRingOpacity: Double = 0
    @State private var glassRingRotation: Double = 0
    @State private var viewSize: CGSize = CGSize(width: 400, height: 900)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - 5-Phase Animation Sequence (2.5s total)

    enum SplashPhase {
        case void               // 0.0s - Deep void initialization
        case starShimmer        // 0.5s - Subtle star shimmer
        case orbMaterialize     // 0.5s - EtherealOrb materializes
        case orbPulse           // 1.2s - Orb pulses with cyan glow
        case brandReveal        // 1.8s - Brand text reveals
        case complete           // 2.5s - Transition ready
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep void background
                CosmicWidget.Void.deepSpace
                    .ignoresSafeArea()

                // Subtle radial vignette
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.3)
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                // Central cyan glow halo
                centralGlowHalo(in: geometry)

                // Refined star field
                starField(in: geometry)

                // Glass halo ring around orb
                glassHaloRing(in: geometry)

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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            } else {
                generateStars(in: viewSize)
                startContinuousAnimations()
                startSplashSequence()
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            if stars.isEmpty && newSize.width > 0 && newSize.height > 0 {
                viewSize = newSize
                generateStars(in: newSize)
            }
        }
    }

    // MARK: - Central Glow Halo (Electric Cyan)

    private func centralGlowHalo(in geometry: GeometryProxy) -> some View {
        RadialGradient(
            colors: [
                CosmicWidget.Widget.electricCyan.opacity(0.20 * glowIntensity),
                CosmicWidget.Widget.violet.opacity(0.10 * glowIntensity),
                Color.clear
            ],
            center: UnitPoint(x: 0.5, y: 0.38),
            startRadius: 50,
            endRadius: 250
        )
        .blur(radius: 40)
    }

    // MARK: - Glass Halo Ring

    private func glassHaloRing(in geometry: GeometryProxy) -> some View {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height * 0.38

        return Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        CosmicWidget.Widget.electricCyan.opacity(0.6),
                        Color.clear,
                        CosmicWidget.Widget.violet.opacity(0.3),
                        Color.clear,
                        CosmicWidget.Widget.electricCyan.opacity(0.6)
                    ],
                    center: .center,
                    startAngle: .degrees(glassRingRotation),
                    endAngle: .degrees(glassRingRotation + 360)
                ),
                lineWidth: 2
            )
            .frame(width: 180, height: 180)
            .scaleEffect(glassRingScale)
            .opacity(glassRingOpacity)
            .blur(radius: 1)
            .position(x: centerX, y: centerY)
    }

    // MARK: - Brand Reveal

    private func brandReveal(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: geometry.size.height * 0.58)

            // App Name - ultra-thin typography
            Text("MyTasksAI")
                .font(CosmicWidget.Typography.displayHero)
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            CosmicWidget.Text.primary,
                            CosmicWidget.Text.secondary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(logoOpacity)
                .offset(y: logoOffset)

            // Tagline with cyan accent
            Text("AI-POWERED PRODUCTIVITY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            CosmicWidget.Text.tertiary,
                            CosmicWidget.Widget.electricCyan.opacity(0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(logoOpacity * 0.8)
                .offset(y: logoOffset * 0.5)

            Spacer()
        }
    }

    // MARK: - Star Field

    private func starField(in geometry: GeometryProxy) -> some View {
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

                context.fill(
                    Circle().path(in: rect),
                    with: .color(Color.white.opacity(opacity))
                )

                // Subtle glow for bright stars
                if star.isBright {
                    let glowRect = CGRect(
                        x: star.position.x - star.size * 1.5,
                        y: star.position.y - star.size * 1.5,
                        width: star.size * 3,
                        height: star.size * 3
                    )
                    context.fill(
                        Circle().path(in: glowRect),
                        with: .color(Color.white.opacity(opacity * 0.2))
                    )
                }
            }
        }
    }

    // MARK: - Star Generation

    private func generateStars(in size: CGSize) {
        // Sparse star field - 30 stars
        stars = (0..<30).map { _ in
            SplashStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 0.8...2.0),
                baseOpacity: Double.random(in: 0.3...0.7),
                twinkleOffset: Double.random(in: 0...(.pi * 2)),
                isBright: Double.random(in: 0...1) < 0.12
            )
        }
    }

    // MARK: - Continuous Animations

    private func startContinuousAnimations() {
        // Star twinkle
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            twinklePhase = .pi * 2
        }

        // Glass ring rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            glassRingRotation = 360
        }
    }

    // MARK: - 5-Phase Splash Sequence (2.5s total)

    private func startSplashSequence() {
        // Phase 1: Star shimmer (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            phase = .starShimmer
            withAnimation(.easeIn(duration: 0.4)) {
                starOpacity = 0.5
            }
        }

        // Phase 2: Orb materializes (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            phase = .orbMaterialize
            withAnimation(CosmicMotion.Springs.morph) {
                orbScale = 0.85
                orbOpacity = 0.9
                orbIntensity = 0.8
            }
            withAnimation(.easeIn(duration: 0.3)) {
                glowIntensity = 0.6
                starOpacity = 0.7
            }
        }

        // Phase 3: Orb pulses with cyan glow (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            phase = .orbPulse
            orbState = .active
            HapticsService.shared.cosmicPulse()

            withAnimation(CosmicMotion.Springs.celebrate) {
                orbScale = 1.0
                orbOpacity = 1.0
                orbIntensity = 1.2
                glassRingScale = 1.0
                glassRingOpacity = 0.8
            }
            withAnimation(.easeInOut(duration: 0.4)) {
                glowIntensity = 1.0
                starOpacity = 0.85
            }
        }

        // Phase 4: Brand reveal (1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            phase = .brandReveal
            HapticsService.shared.selectionFeedback()

            withAnimation(CosmicMotion.Springs.ui) {
                logoOpacity = 1
                logoOffset = 0
            }
            // Settle orb
            orbState = .idle
            withAnimation(.easeOut(duration: 0.3)) {
                orbIntensity = 1.0
            }
        }

        // Phase 5: Complete (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
}

// MARK: - Preview

#Preview("Cosmic Splash Screen") {
    CosmicSplashScreen {
        print("Splash complete!")
    }
}
