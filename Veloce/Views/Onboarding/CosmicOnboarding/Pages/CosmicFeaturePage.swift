//
//  CosmicFeaturePage.swift
//  Veloce
//
//  Cosmic Feature Showcase Pages
//  Stunning animated presentations for Tasks, Focus, Momentum, and AI features
//

import SwiftUI

// MARK: - Feature Type

enum FeatureType: Identifiable {
    case tasks
    case focus
    case momentum
    case ai

    var id: String {
        switch self {
        case .tasks: return "tasks"
        case .focus: return "focus"
        case .momentum: return "momentum"
        case .ai: return "ai"
        }
    }

    var title: String {
        switch self {
        case .tasks: return "Transform Intentions into Achievements"
        case .focus: return "Enter the Flow State"
        case .momentum: return "Track Your Cosmic Journey"
        case .ai: return "Your Personal Oracle Awaits"
        }
    }

    var icon: String {
        switch self {
        case .tasks: return "sparkles.rectangle.stack"
        case .focus: return "scope"
        case .momentum: return "chart.line.uptrend.xyaxis"
        case .ai: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .tasks: return Theme.Colors.aiPurple
        case .focus: return Theme.CelestialColors.solarFlare
        case .momentum: return Theme.CelestialColors.auroraGreen
        case .ai: return Theme.CelestialColors.plasmaCore
        }
    }

    var benefits: [(icon: String, text: String)] {
        switch self {
        case .tasks:
            return [
                ("wand.and.stars", "AI-powered task breakdown"),
                ("calendar.badge.clock", "Smart scheduling"),
                ("trophy.fill", "XP gamification")
            ]
        case .focus:
            return [
                ("timer", "Pomodoro & deep work modes"),
                ("shield.fill", "App blocking"),
                ("sparkles", "Distraction-free focus")
            ]
        case .momentum:
            return [
                ("chart.bar.fill", "Productivity analytics"),
                ("target", "Goal setting & tracking"),
                ("chart.xyaxis.line", "Progress visualization")
            ]
        case .ai:
            return [
                ("lightbulb.fill", "Smart suggestions"),
                ("text.bubble", "Task insights"),
                ("sunrise.fill", "Daily briefings")
            ]
        }
    }
}

// MARK: - Cosmic Feature Page

struct CosmicFeaturePage: View {
    let feature: FeatureType
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var animationPhase: CGFloat = 0
    @State private var benefitAppearance: [Bool] = [false, false, false]
    @State private var orbitalRotation: Double = 0
    @State private var floatingOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer(minLength: geometry.size.height * 0.03)

                    // Hero illustration
                    heroIllustration
                        .frame(height: 280)

                    // Title
                    Text(feature.title)
                        .font(.system(size: 28, weight: .thin, design: .default))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Benefits list
                    benefitsSection
                        .padding(.horizontal, Theme.Spacing.lg)

                    Spacer(minLength: 60)

                    // Continue button
                    continueButton
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl * 2)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Hero Illustration

    @ViewBuilder
    private var heroIllustration: some View {
        switch feature {
        case .tasks:
            tasksIllustration
        case .focus:
            focusIllustration
        case .momentum:
            momentumIllustration
        case .ai:
            aiIllustration
        }
    }

    // MARK: - Tasks Illustration (Floating planets)

    private var tasksIllustration: some View {
        ZStack {
            // Central glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            feature.color.opacity(0.3),
                            feature.color.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)

            // Orbiting task "planets"
            ForEach(0..<4) { i in
                taskPlanet(index: i)
            }

            // Central hub
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                feature.color,
                                feature.color.opacity(0.6)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white)
            }
            .shadow(color: feature.color.opacity(0.5), radius: 20)
        }
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.8)
    }

    private func taskPlanet(index: Int) -> some View {
        let angles: [Double] = [0, 90, 180, 270]
        let sizes: [CGFloat] = [36, 28, 32, 24]
        let distances: [CGFloat] = [90, 100, 110, 85]
        let colors: [Color] = [
            Theme.CelestialColors.solarFlare,
            Theme.CelestialColors.auroraGreen,
            Theme.Colors.aiBlue,
            Theme.CelestialColors.plasmaCore
        ]

        let angle = angles[index] + orbitalRotation
        let size = sizes[index]
        let distance = distances[index]
        let color = colors[index]

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color, color.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.4), radius: 8)

            // Checkmark on some
            if index % 2 == 0 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .offset(
            x: CGFloat(cos(angle * .pi / 180)) * distance,
            y: CGFloat(sin(angle * .pi / 180)) * distance + floatingOffset * (index % 2 == 0 ? 1 : -1)
        )
    }

    // MARK: - Focus Illustration (Timer ring with cosmic glow)

    private var focusIllustration: some View {
        ZStack {
            // Outer cosmic glow
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(
                        feature.color.opacity(0.2 - Double(ring) * 0.05),
                        lineWidth: 3
                    )
                    .frame(
                        width: 180 + CGFloat(ring) * 40,
                        height: 180 + CGFloat(ring) * 40
                    )
                    .scaleEffect(1 + animationPhase * 0.02 * CGFloat(ring))
            }

            // Timer ring background
            Circle()
                .stroke(
                    Theme.CelestialColors.starGhost.opacity(0.2),
                    lineWidth: 8
                )
                .frame(width: 160, height: 160)

            // Animated timer progress
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(
                        colors: [
                            feature.color,
                            feature.color.opacity(0.8),
                            feature.color.opacity(0.4),
                            feature.color
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(orbitalRotation * 0.2))

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            feature.color.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)

            // Time display
            VStack(spacing: 4) {
                Text("25:00")
                    .font(.system(size: 40, weight: .thin, design: .monospaced))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("DEEP FOCUS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(feature.color)
                    .tracking(2)
            }

            // Shield particles
            ForEach(0..<6) { i in
                Circle()
                    .fill(feature.color.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(x: 95)
                    .rotationEffect(.degrees(Double(i) * 60 + orbitalRotation))
            }
        }
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.8)
    }

    // MARK: - Momentum Illustration (Stats rising)

    private var momentumIllustration: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            feature.color.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)

            // Rising bar chart
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(0..<5) { i in
                    momentumBar(index: i)
                }
            }

            // Trend line
            Path { path in
                path.move(to: CGPoint(x: -80, y: 40))
                path.addQuadCurve(
                    to: CGPoint(x: 80, y: -60),
                    control: CGPoint(x: 0, y: -20)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [
                        feature.color.opacity(0.4),
                        feature.color
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )

            // Star burst at peak
            Image(systemName: "star.fill")
                .font(.system(size: 24))
                .foregroundStyle(Theme.Colors.xp)
                .offset(x: 80, y: -70)
                .scaleEffect(1 + animationPhase * 0.1)
        }
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.8)
    }

    private func momentumBar(index: Int) -> some View {
        let heights: [CGFloat] = [40, 60, 50, 80, 100]
        let delays: [Double] = [0, 0.1, 0.2, 0.3, 0.4]

        return RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [
                        feature.color,
                        feature.color.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 24, height: heights[index] * (showContent ? 1 : 0))
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7).delay(delays[index]),
                value: showContent
            )
    }

    // MARK: - AI Illustration (Oracle orb with wisdom)

    private var aiIllustration: some View {
        ZStack {
            // Outer mystic rings
            ForEach(0..<4) { ring in
                Circle()
                    .stroke(
                        feature.color.opacity(0.15 - Double(ring) * 0.03),
                        lineWidth: 1
                    )
                    .frame(
                        width: 200 + CGFloat(ring) * 35,
                        height: 200 + CGFloat(ring) * 35
                    )
                    .rotationEffect(.degrees(orbitalRotation * (ring % 2 == 0 ? 1 : -1) * 0.3))
            }

            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            feature.color.opacity(0.4),
                            feature.color.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)

            // The Oracle orb
            ZStack {
                // Glass sphere effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.3),
                                feature.color.opacity(0.2),
                                feature.color.opacity(0.4),
                                Theme.CelestialColors.void.opacity(0.6)
                            ],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                // Inner sparkle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.6),
                                feature.color.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(1 + animationPhase * 0.1)

                // AI icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.9))

                // Highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: 140, height: 140)
                    .mask {
                        Circle()
                            .frame(width: 60, height: 60)
                            .offset(x: -30, y: -30)
                    }
            }
            .shadow(color: feature.color.opacity(0.5), radius: 30)

            // Floating wisdom particles
            ForEach(0..<8) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 8...14)))
                    .foregroundStyle(feature.color.opacity(0.7))
                    .offset(
                        x: CGFloat(cos(Double(i) * .pi / 4 + orbitalRotation * 0.01)) * 110,
                        y: CGFloat(sin(Double(i) * .pi / 4 + orbitalRotation * 0.01)) * 110 + floatingOffset * (i % 2 == 0 ? 1 : -1)
                    )
            }
        }
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.8)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(Array(feature.benefits.enumerated()), id: \.offset) { index, benefit in
                FeatureBenefitRow(
                    icon: benefit.icon,
                    text: benefit.text,
                    color: feature.color,
                    isVisible: benefitAppearance[index]
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    feature.color.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 30)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            HapticsService.shared.impact()
            onContinue()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [feature.color, feature.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: feature.color.opacity(0.4), radius: 15, y: 8)
        }
        .buttonStyle(.plain)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 30)
    }

    // MARK: - Animations

    private func startAnimations() {
        if reduceMotion {
            showContent = true
            benefitAppearance = [true, true, true]
            return
        }

        // Content appears
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showContent = true
        }

        // Orbital rotation
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            orbitalRotation = 360
        }

        // Animation phase
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }

        // Floating effect
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatingOffset = 10
        }

        // Benefits appear with stagger
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.1) {
                withAnimation(LivingCosmos.Animations.stellarBounce) {
                    benefitAppearance[i] = true
                }
            }
        }
    }
}

// MARK: - Feature Benefit Row

struct FeatureBenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    let isVisible: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
}

// MARK: - Preview

#Preview("Tasks Feature") {
    ZStack {
        VoidBackground.onboarding
        CosmicFeaturePage(feature: .tasks) { }
    }
}

#Preview("Focus Feature") {
    ZStack {
        VoidBackground.onboarding
        CosmicFeaturePage(feature: .focus) { }
    }
}

#Preview("Momentum Feature") {
    ZStack {
        VoidBackground.onboarding
        CosmicFeaturePage(feature: .momentum) { }
    }
}

#Preview("AI Feature") {
    ZStack {
        VoidBackground.onboarding
        CosmicFeaturePage(feature: .ai) { }
    }
}
