//
//  PaywallView.swift
//  Veloce
//
//  Paywall View - Aurora Design System
//  Premium subscription screen with celestial aurora aesthetic
//  matching the auth/onboarding flow
//

import SwiftUI

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @State private var subscription = SubscriptionService.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Animation states
    @State private var showContent = false
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showPriceCard = false
    @State private var featureAppearance: [Bool] = Array(repeating: false, count: 7)
    @State private var logoGlow: Double = 0.6

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Aurora background - consistent with auth
                AuroraBackground.paywall

                // Animated Logo at top
                AppLogoView(
                    size: logoSize(for: geometry),
                    isAnimating: true,
                    showParticles: false
                )
                .opacity(showLogo ? 1 : 0)
                .scaleEffect(showLogo ? 1 : 0.8)
                .position(
                    x: geometry.size.width / 2,
                    y: logoYPosition(for: geometry)
                )

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Aurora.Layout.spacingXL) {
                        // Spacer for logo
                        Spacer(minLength: logoSpacerHeight(for: geometry))

                        // Title section - editorial thin style
                        titleSection
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 20)

                        // Features list with crystalline card
                        featuresSection
                            .padding(.horizontal, Aurora.Layout.screenPadding)

                        // Price card
                        priceCard
                            .opacity(showPriceCard ? 1 : 0)
                            .scaleEffect(showPriceCard ? 1 : 0.95)
                            .padding(.horizontal, Aurora.Layout.screenPadding)

                        // CTA button
                        ctaButton
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .padding(.horizontal, Aurora.Layout.screenPadding)

                        // Footer
                        footerSection
                            .opacity(showContent ? 1 : 0)

                        Spacer(minLength: Aurora.Layout.spacingXL)
                    }
                    .padding(.top, Aurora.Layout.spacingLarge)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: Aurora.Layout.spacingSmall) {
            // Editorial thin typography - consistent with AuthView
            Text("MyTasksAI")
                .font(.system(size: 42, weight: .thin, design: .default))
                .foregroundStyle(Aurora.Colors.textPrimary)

            Text("Your Trial Has Ended")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Aurora.Colors.textPrimary)
                .padding(.top, Aurora.Layout.spacingSmall)

            Text("Subscribe to continue using all AI features")
                .font(.system(size: 15))
                .foregroundStyle(Aurora.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: Aurora.Layout.spacing) {
            ForEach(Array(SubscriptionTier.pro.features.enumerated()), id: \.offset) { index, feature in
                featureRow(feature, index: index)
            }
        }
        .crystallineCard()
    }

    private func featureRow(_ feature: String, index: Int) -> some View {
        HStack(spacing: Aurora.Layout.spacing) {
            // Checkmark with glow
            ZStack {
                SwiftUI.Circle()
                    .fill(Aurora.Colors.success.opacity(0.15))
                    .frame(width: 32, height: 32)

                SwiftUI.Circle()
                    .fill(Aurora.Colors.success.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .blur(radius: 6)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Aurora.Colors.success)
            }

            Text(feature)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Aurora.Colors.textPrimary)

            Spacer()
        }
        .opacity(index < featureAppearance.count && featureAppearance[index] ? 1 : 0)
        .offset(x: index < featureAppearance.count && featureAppearance[index] ? 0 : -20)
    }

    // MARK: - Price Card

    private var priceCard: some View {
        VStack(spacing: Aurora.Layout.spacing) {
            // Crown badge
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                Text("Unlock Pro")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Aurora.Colors.violet)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Aurora.Colors.violet.opacity(0.15))
            )

            // Price display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("$9.99")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Text("/month")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }

            // Cancel info
            Text("Cancel anytime • Automatic renewal")
                .font(.system(size: 13))
                .foregroundStyle(Aurora.Colors.textTertiary)
        }
        .padding(Aurora.Layout.spacingXL)
        .background(
            RoundedRectangle(cornerRadius: Aurora.Radius.xxl)
                .fill(Aurora.Colors.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Aurora.Radius.xxl)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Aurora.Colors.violet.opacity(0.5),
                                    Aurora.Colors.electric.opacity(0.3),
                                    Aurora.Colors.glassBorder
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Aurora.Colors.violet.opacity(0.2), radius: 20, y: 8)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        AuroraButton(
            isPurchasing ? "Processing..." : "Subscribe Now",
            style: .primary,
            isLoading: isPurchasing,
            icon: isPurchasing ? nil : "crown.fill"
        ) {
            Task {
                await purchaseSubscription()
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: Aurora.Layout.spacing) {
            // Restore purchases
            AuroraLinkButton("Restore Purchases", color: Aurora.Colors.textSecondary) {
                Task {
                    await restorePurchases()
                }
            }

            // Legal links
            HStack(spacing: Aurora.Layout.spacingLarge) {
                AuroraLinkButton("Privacy Policy", color: Aurora.Colors.textTertiary) {
                    openURL("https://yourapp.com/privacy")
                }

                AuroraLinkButton("Terms of Use", color: Aurora.Colors.textTertiary) {
                    openURL("https://yourapp.com/terms")
                }
            }

            // Fine print
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundStyle(Aurora.Colors.textQuaternary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Aurora.Layout.spacingXL)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Staggered reveal
        withAnimation(Aurora.Animation.spring.delay(0.1)) {
            showLogo = true
        }

        withAnimation(Aurora.Animation.spring.delay(0.3)) {
            showTitle = true
        }

        // Stagger feature appearance
        for index in featureAppearance.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(index) * 0.08) {
                withAnimation(Aurora.Animation.spring) {
                    featureAppearance[index] = true
                }
            }
        }

        withAnimation(Aurora.Animation.spring.delay(0.9)) {
            showPriceCard = true
        }

        withAnimation(Aurora.Animation.spring.delay(1.1)) {
            showContent = true
        }

        // Logo glow pulse
        withAnimation(Aurora.Animation.glowPulse) {
            logoGlow = 0.9
        }
    }

    // MARK: - Actions

    private func purchaseSubscription() async {
        isPurchasing = true
        HapticsService.shared.impact()

        do {
            try await subscription.purchasePro()

            if subscription.canAccessApp {
                HapticsService.shared.celebration()
                appViewModel.handleSubscriptionCompleted()
            } else {
                HapticsService.shared.notification(.error)
                errorMessage = "Unable to complete purchase. Please try again."
                showError = true
            }
        } catch {
            HapticsService.shared.notification(.error)
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
    }

    private func restorePurchases() async {
        isPurchasing = true
        HapticsService.shared.impact()

        do {
            try await subscription.restorePurchases()
            if subscription.isSubscribed {
                HapticsService.shared.celebration()
                appViewModel.handleSubscriptionCompleted()
            } else {
                errorMessage = "No previous purchases found."
                showError = true
            }
        } catch {
            HapticsService.shared.notification(.error)
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Aurora Background Extension

extension AuroraBackground {
    /// Paywall screen background - premium feel
    static var paywall: AuroraBackground {
        AuroraBackground(
            showStars: true,
            starCount: 45,
            auroraIntensity: 0.42,
            glowColor: Aurora.Colors.violet,
            glowPosition: UnitPoint(x: 0.5, y: 0.25)
        )
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environment(AppViewModel())
}
