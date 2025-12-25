//
//  CosmicWelcomePage.swift
//  Veloce
//
//  Welcome to the Cosmos - First Onboarding Page
//  A breathtaking introduction with animated starfield and personalized greeting
//

import SwiftUI

struct CosmicWelcomePage: View {
    let userName: String
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showGreeting = false
    @State private var showTagline = false
    @State private var showFeatures = false
    @State private var showButton = false
    @State private var logoGlow: CGFloat = 0
    @State private var logoRotation: Double = 0
    @State private var featureAppearance: [Bool] = [false, false, false]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var displayName: String {
        userName.isEmpty ? "Explorer" : userName.components(separatedBy: " ").first ?? userName
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer(minLength: geometry.size.height * 0.08)

                    // Animated Logo
                    logoSection
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)

                    // Greeting
                    greetingSection
                        .padding(.top, Theme.Spacing.lg)

                    // Features preview
                    featuresSection
                        .padding(.horizontal, Theme.Spacing.lg)

                    Spacer(minLength: 60)

                    // CTA Button
                    ctaButton
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl * 2)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3) { ring in
                SwiftUI.Circle()
                    .stroke(
                        Theme.CelestialColors.solarFlare.opacity(0.1 - Double(ring) * 0.03),
                        lineWidth: 1
                    )
                    .frame(
                        width: 140 + CGFloat(ring) * 40,
                        height: 140 + CGFloat(ring) * 40
                    )
                    .scaleEffect(1 + logoGlow * 0.05 * CGFloat(ring + 1))
            }

            // Ambient glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.solarFlare.opacity(0.4 * logoGlow),
                            Theme.CelestialColors.solarFlare.opacity(0.1 * logoGlow),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)

            // Logo icon - cosmic orbital design
            ZStack {
                // Outer orbital ring
                SwiftUI.Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare.opacity(0.9),
                                Theme.Colors.aiPurple.opacity(0.7),
                                Theme.CelestialColors.plasmaCore.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(logoRotation))

                // Inner cosmic core
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare,
                                Theme.Colors.aiPurple.opacity(0.8),
                                Theme.CelestialColors.plasmaCore
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: Theme.CelestialColors.solarFlare.opacity(0.5), radius: 15)

                // Orbital particle
                SwiftUI.Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .white.opacity(0.8), radius: 6)
                    .offset(x: 50, y: 0)
                    .rotationEffect(.degrees(-logoRotation * 2))
            }
        }
    }

    // MARK: - Greeting Section

    private var greetingSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Welcome text
            Text("Welcome to the cosmos,")
                .font(.system(size: 18, weight: .medium, design: .default))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .opacity(showGreeting ? 1 : 0)
                .offset(y: showGreeting ? 0 : 20)

            // User name
            Text(displayName)
                .font(.system(size: 44, weight: .thin, design: .default))
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
                .opacity(showGreeting ? 1 : 0)
                .offset(y: showGreeting ? 0 : 20)

            // Tagline
            Text("Your journey to peak productivity begins")
                .font(.system(size: 16, weight: .light, design: .default))
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
                .opacity(showTagline ? 1 : 0)
                .offset(y: showTagline ? 0 : 15)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            CosmicWelcomeFeatureRow(
                icon: "sparkles",
                iconColor: Theme.Colors.aiPurple,
                title: "AI-Powered Insights",
                subtitle: "Smart suggestions for every task",
                isVisible: featureAppearance[0]
            )

            CosmicWelcomeFeatureRow(
                icon: "timer",
                iconColor: Theme.CelestialColors.solarFlare,
                title: "Deep Focus Mode",
                subtitle: "Block distractions, enter flow state",
                isVisible: featureAppearance[1]
            )

            CosmicWelcomeFeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Theme.CelestialColors.auroraGreen,
                title: "Track Your Momentum",
                subtitle: "Visualize progress, stay motivated",
                isVisible: featureAppearance[2]
            )
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
                                    Color.white.opacity(0.1),
                                    Theme.Colors.aiPurple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .opacity(showFeatures ? 1 : 0)
        .offset(y: showFeatures ? 0 : 30)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            HapticsService.shared.impact()
            onContinue()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Let's set up your universe")
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
                            colors: [
                                Theme.Colors.aiPurple,
                                Theme.CelestialColors.plasmaCore
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 15, y: 8)
        }
        .buttonStyle(.plain)
        .opacity(showButton ? 1 : 0)
        .offset(y: showButton ? 0 : 30)
    }

    // MARK: - Animations

    private func startAnimations() {
        if reduceMotion {
            showContent = true
            showGreeting = true
            showTagline = true
            showFeatures = true
            showButton = true
            featureAppearance = [true, true, true]
            logoGlow = 1
            return
        }

        // Logo appears
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showContent = true
        }

        // Logo glow pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            logoGlow = 1
        }

        // Logo rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            logoRotation = 360
        }

        // Greeting appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showGreeting = true
            }
        }

        // Tagline appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showTagline = true
            }
        }

        // Features section appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showFeatures = true
            }
        }

        // Feature rows appear with stagger
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9 + Double(i) * 0.12) {
                withAnimation(LivingCosmos.Animations.stellarBounce) {
                    featureAppearance[i] = true
                }
            }
        }

        // Button appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }
}

// MARK: - Welcome Feature Row

struct CosmicWelcomeFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .blur(radius: 8)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.CelestialColors.auroraGreen.opacity(0.8))
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.onboarding

        CosmicWelcomePage(userName: "Alex") {
            print("Continue tapped")
        }
    }
}
