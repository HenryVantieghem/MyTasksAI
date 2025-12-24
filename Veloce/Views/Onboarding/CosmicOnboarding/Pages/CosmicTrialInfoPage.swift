//
//  CosmicTrialInfoPage.swift
//  Veloce
//
//  Cosmic Trial Info Page - Honest, Not Pushy Free Trial Information
//  Shows what users get, with transparent pricing and no pressure tactics
//

import SwiftUI

struct CosmicTrialInfoPage: View {
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showTitle = false
    @State private var showFeatures = false
    @State private var showPricing = false
    @State private var showButton = false
    @State private var featureAppearance: [Bool] = [false, false, false, false, false]
    @State private var crownRotation: Double = 0
    @State private var crownGlow: CGFloat = 0
    @State private var orbitalParticles: [CGFloat] = [0, 72, 144, 216, 288]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let trialFeatures: [(icon: String, title: String, subtitle: String)] = [
        ("infinity", "Unlimited Tasks", "Create as many tasks as you need"),
        ("brain.head.profile", "AI Insights", "Smart suggestions and goal optimization"),
        ("shield.fill", "Focus Protection", "Block distracting apps during sessions"),
        ("chart.line.uptrend.xyaxis", "Advanced Analytics", "Deep insights into your productivity"),
        ("icloud.fill", "Cloud Sync", "Access everywhere, always backed up")
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    Spacer(minLength: geometry.size.height * 0.03)

                    // Crown illustration
                    crownIllustration
                        .padding(.top, Theme.Spacing.md)

                    // Title section
                    titleSection

                    // Features list
                    featuresSection
                        .padding(.horizontal, Theme.Spacing.lg)

                    // Pricing transparency
                    pricingSection
                        .padding(.horizontal, Theme.Spacing.lg)

                    Spacer(minLength: 40)

                    // CTA button
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

    // MARK: - Crown Illustration

    private var crownIllustration: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(
                        Theme.CelestialColors.solarFlare.opacity(0.12 - Double(ring) * 0.03),
                        lineWidth: 1.5
                    )
                    .frame(
                        width: 130 + CGFloat(ring) * 40,
                        height: 130 + CGFloat(ring) * 40
                    )
                    .scaleEffect(1 + crownGlow * 0.04 * CGFloat(ring + 1))
            }

            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.solarFlare.opacity(0.3),
                            Theme.Colors.aiPurple.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)

            // Orbiting stars
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare,
                                Theme.Colors.aiPurple
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(x: 80)
                    .rotationEffect(.degrees(orbitalParticles[i] + crownRotation))
            }

            // Main crown container
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare.opacity(0.25),
                                Theme.Colors.aiPurple.opacity(0.15),
                                Theme.CelestialColors.void.opacity(0.5)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 130, height: 130)

                // Glass overlay
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)

                // Border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare.opacity(0.5),
                                Theme.Colors.aiPurple.opacity(0.4),
                                Theme.CelestialColors.solarFlare.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 110, height: 110)

                // Crown icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare,
                                Theme.Colors.aiPurple
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.CelestialColors.solarFlare.opacity(0.5), radius: 8)
            }
        }
        .scaleEffect(showContent ? 1 : 0.8)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Try Everything Free")
                .font(.system(size: 30, weight: .thin, design: .default))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            HStack(spacing: Theme.Spacing.xs) {
                Text("3 days")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.solarFlare)

                Text("to explore all features")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Text("No commitment. Cancel anytime.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .padding(.top, Theme.Spacing.xs)
        }
        .opacity(showTitle ? 1 : 0)
        .offset(y: showTitle ? 0 : 20)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(trialFeatures.enumerated()), id: \.offset) { index, feature in
                TrialFeatureRow(
                    icon: feature.icon,
                    title: feature.title,
                    subtitle: feature.subtitle,
                    isVisible: featureAppearance[index]
                )

                if index < trialFeatures.count - 1 {
                    Divider()
                        .background(Theme.CelestialColors.starGhost.opacity(0.15))
                        .padding(.vertical, Theme.Spacing.sm)
                }
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
                                    Theme.CelestialColors.solarFlare.opacity(0.2),
                                    Theme.Colors.aiPurple.opacity(0.15),
                                    Color.white.opacity(0.1)
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

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Pricing note
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starGhost)

                Text("After your trial, continue with a subscription")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            // Free tier note
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen.opacity(0.8))

                Text("Or use the free tier with core features forever")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.CelestialColors.void.opacity(0.4))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Theme.CelestialColors.starGhost.opacity(0.15),
                            lineWidth: 1
                        )
                }
        }
        .opacity(showPricing ? 1 : 0)
        .offset(y: showPricing ? 0 : 20)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                HapticsService.shared.impact()
                onContinue()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Start Free Trial")
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
                                    Theme.CelestialColors.solarFlare,
                                    Theme.Colors.aiPurple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Theme.CelestialColors.solarFlare.opacity(0.4), radius: 15, y: 8)
            }
            .buttonStyle(.plain)

            // No payment required note
            Text("No payment required until trial ends")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starGhost.opacity(0.7))
        }
        .opacity(showButton ? 1 : 0)
        .offset(y: showButton ? 0 : 30)
    }

    // MARK: - Animations

    private func startAnimations() {
        if reduceMotion {
            showContent = true
            showTitle = true
            showFeatures = true
            showPricing = true
            showButton = true
            featureAppearance = [true, true, true, true, true]
            crownGlow = 1
            return
        }

        // Crown appears
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showContent = true
        }

        // Crown rotation
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            crownRotation = 360
        }

        // Crown glow pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            crownGlow = 1
        }

        // Title appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showTitle = true
            }
        }

        // Features section appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showFeatures = true
            }
        }

        // Feature rows appear with stagger
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.1) {
                withAnimation(LivingCosmos.Animations.stellarBounce) {
                    featureAppearance[i] = true
                }
            }
        }

        // Pricing section appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showPricing = true
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

// MARK: - Trial Feature Row

struct TrialFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare.opacity(0.15),
                                Theme.Colors.aiPurple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare,
                                Theme.Colors.aiPurple
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Spacer()

            // Included checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.CelestialColors.auroraGreen.opacity(0.8))
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.onboarding

        CosmicTrialInfoPage {
            print("Continue tapped")
        }
    }
}
