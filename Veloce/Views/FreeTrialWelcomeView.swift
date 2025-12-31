//
//  FreeTrialWelcomeView.swift
//  Veloce
//
//  Free Trial Welcome View - Utopian Design System
//  First screen users see - celestial cosmic welcome experience
//  matching auth/onboarding flow
//

import SwiftUI

// MARK: - Free Trial Welcome View

struct FreeTrialWelcomeView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @State private var showContent = false
    @State private var showLogo = false
    @State private var featureAppearance: [Bool] = Array(repeating: false, count: 4)
    @State private var logoScale: CGFloat = 0.9
    @State private var showHowItWorks = false

    private let features: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("brain.head.profile", "AI-Powered Tasks", "Smart suggestions for every task", UtopianDesignFallback.Colors.aiPurple),
        ("sparkles", "Brain Dump", "Turn thoughts into organized tasks", UtopianDesignFallback.Colors.focusActive),
        ("trophy.fill", "Gamification", "Earn XP and unlock achievements", UtopianDesignFallback.Gamification.starGold),
        ("calendar.badge.clock", "Smart Scheduling", "AI-optimized planning", UtopianDesignFallback.Colors.focusActive)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Utopian background - consistent with auth
                UtopianGradients.background(for: Date())

                // Animated Logo at top
                AppLogoView(
                    size: logoSize(for: geometry),
                    isAnimating: true,
                    showParticles: false
                )
                .scaleEffect(logoScale)
                .opacity(showLogo ? 1 : 0)
                .position(
                    x: geometry.size.width / 2,
                    y: logoYPosition(for: geometry)
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: UtopianDesignFallback.Spacing.xl) {
                        // Spacer for logo
                        Spacer(minLength: logoSpacerHeight(for: geometry))

                        // Header with branding
                        headerSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : -20)

                        // Features list
                        featuresSection
                            .padding(.horizontal, UtopianDesignFallback.Spacing.lg)

                        // CTA section
                        ctaSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .padding(.horizontal, UtopianDesignFallback.Spacing.lg)

                        // Footer
                        footerSection
                            .opacity(showContent ? 1 : 0)
                            .padding(.bottom, UtopianDesignFallback.Spacing.xl)
                    }
                    .padding(.top, UtopianDesignFallback.Spacing.lg)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksView()
        }
    }

    // MARK: - Layout Calculations

    private func logoSize(for geometry: GeometryProxy) -> LogoSize {
        geometry.size.height < 700 ? .medium : .large
    }

    private func logoYPosition(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        return height < 700 ? height * 0.12 : height * 0.14
    }

    private func logoSpacerHeight(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        return height < 700 ? 120 : 160
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.md) {
            // Editorial thin typography - matching AuthView
            Text("MyTasksAI")
                .font(.system(size: 42, weight: .thin, design: .default))
                .foregroundStyle(.white)

            // Tagline
            Text("AI-Powered Productivity")
                .dynamicTypeFont(base: 15)
                .foregroundStyle(.white.opacity(0.7))

            // Trial badge with Utopian glow
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .dynamicTypeFont(base: 14)
                Text("3 Days Free")
                    .dynamicTypeFont(base: 15, weight: .semibold)
            }
            .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.15))
            )
            .padding(.top, UtopianDesignFallback.Spacing.sm)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.lg) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                WelcomeFeatureRow(
                    icon: feature.icon,
                    iconColor: feature.color,
                    title: feature.title,
                    subtitle: feature.subtitle,
                    isVisible: index < featureAppearance.count && featureAppearance[index]
                )
            }
        }
        .crystallineCard()
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.lg) {
            // Primary button - Start Free Trial
            AuroraButton(
                "Start Your Free Trial",
                style: .primary,
                icon: "sparkles"
            ) {
                appViewModel.handleWelcomeContinue(toSignUp: true)
            }

            // Secondary link - Already have an account
            HStack(spacing: UtopianDesignFallback.Spacing.xs) {
                Text("Already have an account?")
                    .dynamicTypeFont(base: 15)
                    .foregroundStyle(.white.opacity(0.7))

                AuroraLinkButton("Sign In") {
                    HapticsService.shared.selectionFeedback()
                    appViewModel.handleWelcomeContinue(toSignUp: false)
                }
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.sm) {
            Text("No credit card required")
                .dynamicTypeFont(base: 13)
                .foregroundStyle(.white.opacity(0.5))

            // How It Works link
            AuroraLinkButton("How It Works", color: UtopianDesignFallback.Colors.focusActive) {
                HapticsService.shared.selectionFeedback()
                showHowItWorks = true
            }
            .padding(.top, UtopianDesignFallback.Spacing.xs)

            HStack(spacing: UtopianDesignFallback.Spacing.lg) {
                AuroraLinkButton("Privacy Policy", color: .white.opacity(0.5)) {
                    openURL("https://yourapp.com/privacy")
                }
                AuroraLinkButton("Terms of Use", color: .white.opacity(0.5)) {
                    openURL("https://yourapp.com/terms")
                }
            }
        }
    }

    // MARK: - Helpers

    private func startAnimations() {
        // Logo fade in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.1)) {
            showLogo = true
        }

        // Logo breathing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.3)) {
            logoScale = 1.02
        }

        // Fade in main content
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.3)) {
            showContent = true
        }

        // Stagger feature rows
        for index in featureAppearance.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(index) * 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    featureAppearance[index] = true
                }
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Welcome Feature Row

struct WelcomeFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: UtopianDesignFallback.Spacing.md) {
            // Icon with glow
            ZStack {
                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .blur(radius: 8)

                Image(systemName: icon)
                    .dynamicTypeFont(base: 22, weight: .medium)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .dynamicTypeFont(base: 17, weight: .semibold)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .dynamicTypeFont(base: 20)
                .foregroundStyle(UtopianDesignFallback.Colors.completed.opacity(0.8))
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

// MARK: - Preview

#Preview {
    FreeTrialWelcomeView()
        .environment(AppViewModel())
}
