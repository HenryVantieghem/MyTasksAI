//
//  EmptyTasksView.swift
//  Veloce
//
//  Living Cosmos - Cosmic Void Empty State
//  A beautiful void with distant stars, a glowing creation orb
//  in the center, and particles flowing toward the input bar
//

import SwiftUI

// MARK: - Empty Tasks View

struct EmptyTasksView: View {
    let onAddTask: () -> Void

    @State private var showContent = false
    @State private var orbPulse: CGFloat = 0
    @State private var nebulaPhase: CGFloat = 0
    @State private var starPhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Cosmic void background
                cosmicVoidBackground

                // Distant star field
                DistantStarField(phase: starPhase)

                // Central composition
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()

                    // Creation orb
                    creationOrb
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)

                    // Cosmic message
                    cosmicMessage
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Summon button
                    summonButton
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.9)

                    Spacer()

                    // Particle attractor hint
                    particleAttractorHint(size: geo.size)
                        .opacity(showContent ? 1 : 0)
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.stellarBounce.delay(0.2)) {
                showContent = true
            }
            startCosmicAnimations()
        }
    }

    // MARK: - Cosmic Void Background

    private var cosmicVoidBackground: some View {
        ZStack {
            // Deep void
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()

            // Nebula wisps
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaCore.opacity(0.1),
                    Theme.CelestialColors.nebulaEdge.opacity(0.05),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadius: 50,
                endRadius: 300
            )
            .rotationEffect(.degrees(nebulaPhase * 30))
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.7, y: 0.6),
                startRadius: 30,
                endRadius: 200
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Creation Orb

    private var creationOrb: some View {
        ZStack {
            // Outer aurora rings
            ForEach(0..<3, id: \.self) { i in
                SwiftUI.Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.plasmaCore.opacity(0.3 - Double(i) * 0.08),
                                Theme.Colors.aiPurple.opacity(0.2 - Double(i) * 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: CGFloat(100 + i * 30), height: CGFloat(100 + i * 30))
                    .scaleEffect(reduceMotion ? 1 : 1 + orbPulse * 0.05 * CGFloat(i + 1))
                    .opacity(reduceMotion ? 0.5 : 0.6 - orbPulse * 0.2)
            }

            // Nebula glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.plasmaCore.opacity(0.4),
                            Theme.Colors.aiPurple.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)
                .scaleEffect(reduceMotion ? 1 : 1 + orbPulse * 0.1)

            // Inner orb
            ZStack {
                // Glass shell
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.CelestialColors.abyss,
                                Theme.CelestialColors.void
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        SwiftUI.Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Theme.CelestialColors.plasmaCore.opacity(0.6),
                                        Theme.Colors.aiPurple.opacity(0.3),
                                        Theme.CelestialColors.nebulaEdge.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                // Plasma core
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white,
                                Theme.CelestialColors.plasmaCore,
                                Theme.CelestialColors.plasmaCore.opacity(0.5)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 30, height: 30)
                    .scaleEffect(reduceMotion ? 1 : 1 + orbPulse * 0.15)

                // Highlight
                Ellipse()
                    .fill(.white.opacity(0.4))
                    .frame(width: 20, height: 8)
                    .offset(x: -10, y: -20)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            // Floating particles around orb
            if !reduceMotion {
                OrbParticleField(phase: orbPulse)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Cosmic Message

    private var cosmicMessage: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("The cosmos awaits")
                .font(Theme.Typography.cosmosTitleLarge)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .white,
                            Theme.CelestialColors.starWhite
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Summon your first task and begin your journey")
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(Theme.CelestialColors.starDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    // MARK: - Summon Button

    private var summonButton: some View {
        Button {
            HapticsService.shared.mediumImpact()
            onAddTask()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                // Orb icon
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.plasmaCore.opacity(0.3))
                        .frame(width: 24, height: 24)

                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.plasmaCore)
                        .frame(width: 12, height: 12)
                }

                Text("Summon Task")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(summonButtonBackground)
        }
        .buttonStyle(CosmicSummonButtonStyle())
    }

    private var summonButtonBackground: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple,
                            Theme.CelestialColors.nebulaCore
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Shimmer effect
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.15),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: reduceMotion ? 0 : sin(orbPulse * .pi * 2) * 60)

            // Border
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.plasmaCore.opacity(0.5),
                            Theme.Colors.aiPurple.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 20, x: 0, y: 8)
    }

    // MARK: - Particle Attractor Hint

    private func particleAttractorHint(size: CGSize) -> some View {
        ZStack {
            // Converging particles
            if !reduceMotion {
                ForEach(0..<8, id: \.self) { i in
                    AttractorParticle(
                        index: i,
                        phase: orbPulse,
                        targetY: size.height * 0.85
                    )
                }
            }

            // Hint text
            VStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.5))

                Text("Type below to create")
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.6))
            }
        }
        .frame(height: 60)
    }

    // MARK: - Animations

    private func startCosmicAnimations() {
        guard !reduceMotion else { return }

        // Orb pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            orbPulse = 1
        }

        // Nebula drift
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            nebulaPhase = 1
        }

        // Star twinkle
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            starPhase = 1
        }
    }
}

// MARK: - Distant Star Field

struct DistantStarField: View {
    let phase: CGFloat

    @State private var stars: [DistantStar] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                SwiftUI.Circle()
                    .fill(star.color)
                    .frame(width: star.size, height: star.size)
                    .position(star.position)
                    .opacity({
                        if reduceMotion { return star.opacity }
                        let angle = Double(phase) * Double.pi * 2.0 + star.twinklePhase
                        return star.opacity + Darwin.sin(angle) * 0.2
                    }())
                    .blur(radius: star.size > 2 ? 0.5 : 0)
            }
            .onAppear {
                generateStars(in: geo.size)
            }
        }
    }

    private func generateStars(in size: CGSize) {
        stars = (0..<40).map { _ in
            DistantStar(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1...2.5),
                color: [
                    .white.opacity(0.8),
                    Theme.CelestialColors.starWhite.opacity(0.6),
                    Theme.CelestialColors.plasmaCore.opacity(0.4)
                ].randomElement() ?? .white,
                opacity: Double.random(in: 0.2...0.6),
                twinklePhase: Double.random(in: 0...(.pi * 2))
            )
        }
    }
}

struct DistantStar: Identifiable {
    let id: UUID
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
    let twinklePhase: Double
}

// MARK: - Orb Particle Field

struct OrbParticleField: View {
    let phase: CGFloat

    var body: some View {
        ForEach(0..<8, id: \.self) { i in
            SwiftUI.Circle()
                .fill(Theme.CelestialColors.plasmaCore.opacity(0.6))
                .frame(width: 3, height: 3)
                .offset(
                    x: Darwin.cos(Double(i) * .pi / 4 + Double(phase) * .pi * 2) * 50,
                    y: Darwin.sin(Double(i) * .pi / 4 + Double(phase) * .pi * 2) * 50
                )
                .opacity(0.4 + Darwin.sin(Double(phase) * .pi * 4 + Double(i)) * 0.3)
        }
    }
}

// MARK: - Attractor Particle

struct AttractorParticle: View {
    let index: Int
    let phase: CGFloat
    let targetY: CGFloat

    @State private var particleY: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var xOffset: CGFloat {
        let spread: CGFloat = 150
        let angle = Double(index) * .pi / 4
        return Darwin.cos(angle) * spread * 0.5
    }

    var body: some View {
        SwiftUI.Circle()
            .fill(Theme.CelestialColors.plasmaCore.opacity(0.4))
            .frame(width: 4, height: 4)
            .offset(x: xOffset)
            .offset(y: particleY)
            .opacity(0.3 + Darwin.sin(Double(phase) * .pi * 2 + Double(index)) * 0.3)
            .onAppear {
                guard !reduceMotion else { return }
                let delay = Double(index) * 0.15
                withAnimation(.easeInOut(duration: 1.5).delay(delay).repeatForever(autoreverses: true)) {
                    particleY = 30
                }
            }
    }
}

// MARK: - Cosmic Summon Button Style

struct CosmicSummonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? 0.1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Cosmic Void Empty State") {
    EmptyTasksView {
        print("Add task tapped")
    }
}
