//
//  FreeTrialWelcomeView.swift
//  Veloce
//
//  Free Trial Welcome View - Aurora Design System
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

    private let features: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("brain.head.profile", "AI-Powered Tasks", "Smart suggestions for every task", Aurora.Colors.violet),
        ("sparkles", "Brain Dump", "Turn thoughts into organized tasks", Aurora.Colors.electric),
        ("trophy.fill", "Gamification", "Earn XP and unlock achievements", Aurora.Colors.gold),
        ("calendar.badge.clock", "Smart Scheduling", "AI-optimized planning", Aurora.Colors.cyan)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Aurora background - consistent with auth
                AuroraBackground.auth

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
                    VStack(spacing: Aurora.Layout.spacingXL) {
                        // Spacer for logo
                        Spacer(minLength: logoSpacerHeight(for: geometry))

                        // Header with branding
                        headerSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : -20)

                        // Features list
                        featuresSection
                            .padding(.horizontal, Aurora.Layout.screenPadding)

                        // CTA section
                        ctaSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .padding(.horizontal, Aurora.Layout.screenPadding)

                        // Footer
                        footerSection
                            .opacity(showContent ? 1 : 0)
                            .padding(.bottom, Aurora.Layout.spacingXL)
                    }
                    .padding(.top, Aurora.Layout.spacingLarge)
                }
            }
        }
        .onAppear {
            startAnimations()
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
        VStack(spacing: Aurora.Layout.spacing) {
            // Editorial thin typography - matching AuthView
            Text("MyTasksAI")
                .font(.system(size: 42, weight: .thin, design: .default))
                .foregroundStyle(Aurora.Colors.textPrimary)

            // Tagline
            Text("AI-Powered Productivity")
                .font(.system(size: 15))
                .foregroundStyle(Aurora.Colors.textSecondary)

            // Trial badge with aurora glow
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14))
                Text("3 Days Free")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Aurora.Colors.violet)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Aurora.Colors.violet.opacity(0.15))
            )
            .padding(.top, Aurora.Layout.spacingSmall)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Layout.spacingLarge) {
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
        VStack(spacing: Aurora.Layout.spacingLarge) {
            // Primary button - Start Free Trial
            AuroraButton(
                "Start Your Free Trial",
                style: .primary,
                icon: "sparkles"
            ) {
                appViewModel.handleWelcomeContinue(toSignUp: true)
            }

            // Secondary link - Already have an account
            HStack(spacing: Aurora.Layout.spacingTiny) {
                Text("Already have an account?")
                    .font(.system(size: 15))
                    .foregroundStyle(Aurora.Colors.textSecondary)

                AuroraLinkButton("Sign In") {
                    HapticsService.shared.selectionFeedback()
                    appViewModel.handleWelcomeContinue(toSignUp: false)
                }
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: Aurora.Layout.spacingSmall) {
            Text("No credit card required")
                .font(.system(size: 13))
                .foregroundStyle(Aurora.Colors.textTertiary)

            HStack(spacing: Aurora.Layout.spacingLarge) {
                AuroraLinkButton("Privacy Policy", color: Aurora.Colors.textTertiary) {
                    openURL("https://yourapp.com/privacy")
                }
                AuroraLinkButton("Terms of Use", color: Aurora.Colors.textTertiary) {
                    openURL("https://yourapp.com/terms")
                }
            }
        }
    }

    // MARK: - Helpers

    private func startAnimations() {
        // Logo fade in
        withAnimation(Aurora.Animation.spring.delay(0.1)) {
            showLogo = true
        }

        // Logo breathing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.3)) {
            logoScale = 1.02
        }

        // Fade in main content
        withAnimation(Aurora.Animation.spring.delay(0.3)) {
            showContent = true
        }

        // Stagger feature rows
        for index in featureAppearance.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(index) * 0.1) {
                withAnimation(Aurora.Animation.spring) {
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
        HStack(spacing: Aurora.Layout.spacing) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .blur(radius: 8)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Aurora.Colors.success.opacity(0.8))
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
