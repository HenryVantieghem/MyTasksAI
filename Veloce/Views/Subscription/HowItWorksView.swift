//
//  HowItWorksView.swift
//  Veloce
//
//  How It Works View - Utopian Design System
//  Explains the 3-day free trial subscription flow
//  with visual timeline showing trial → paywall → subscribe
//

import SwiftUI

// MARK: - How It Works View

struct HowItWorksView: View {
    @Environment(\.dismiss) private var dismiss

    // Animation states
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showTimeline = false
    @State private var stepAppearance: [Bool] = Array(repeating: false, count: 3)
    @State private var showFooter = false
    @State private var activeStep = 0
    @State private var logoScale: CGFloat = 0.9

    private let steps: [(icon: String, title: String, subtitle: String, color: Color)] = [
        (
            "gift.fill",
            "3 Days Free",
            "Full access to all features. No credit card required to start.",
            UtopianDesignFallback.Colors.completed
        ),
        (
            "clock.badge.exclamationmark.fill",
            "Trial Ends",
            "After 3 days, your free trial expires and the paywall appears.",
            UtopianDesignFallback.Gamification.starGold
        ),
        (
            "crown.fill",
            "Subscribe to Continue",
            "Choose a plan to unlock all AI features and continue your productivity journey.",
            UtopianDesignFallback.Colors.aiPurple
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Utopian background
                AuroraBackground.howItWorks

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

                        // Title section
                        titleSection
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 20)

                        // Timeline section
                        timelineSection
                            .padding(.horizontal, UtopianDesignFallback.Spacing.screenPadding)
                            .opacity(showTimeline ? 1 : 0)

                        // Footer
                        footerSection
                            .opacity(showFooter ? 1 : 0)
                            .offset(y: showFooter ? 0 : 20)
                            .padding(.horizontal, UtopianDesignFallback.Spacing.screenPadding)

                        Spacer(minLength: UtopianDesignFallback.Spacing.xl)
                    }
                    .padding(.top, UtopianDesignFallback.Spacing.lg)
                }

                // Close button
                closeButton
                    .opacity(showLogo ? 1 : 0)
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
        return height < 700 ? height * 0.10 : height * 0.12
    }

    private func logoSpacerHeight(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        return height < 700 ? 100 : 140
    }

    // MARK: - Close Button

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    HapticsService.shared.selectionFeedback()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .dynamicTypeFont(base: 28)
                        .foregroundStyle(.white.opacity(0.7))
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1).opacity(0.5))
                                .frame(width: 30, height: 30)
                        )
                }
                .padding(.trailing, UtopianDesignFallback.Spacing.screenPadding)
                .padding(.top, 16)
            }
            Spacer()
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.md) {
            // Badge
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle.fill")
                    .dynamicTypeFont(base: 14)
                Text("How It Works")
                    .dynamicTypeFont(base: 15, weight: .semibold)
            }
            .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(UtopianDesignFallback.Colors.focusActive.opacity(0.15))
            )

            // Main title
            Text("Your Free Trial")
                .dynamicTypeFont(base: 34, weight: .bold)
                .foregroundStyle(.white)

            // Subtitle
            Text("Experience all premium features\nfor 3 days, completely free")
                .dynamicTypeFont(base: 16)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                TimelineStepCard(
                    stepNumber: index + 1,
                    icon: step.icon,
                    title: step.title,
                    subtitle: step.subtitle,
                    color: step.color,
                    isLast: index == steps.count - 1,
                    isVisible: index < stepAppearance.count && stepAppearance[index],
                    isActive: index == activeStep
                )
            }
        }
        .crystallineCard(padding: UtopianDesignFallback.Spacing.lg)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.lg) {
            // Got it button
            AuroraButton(
                "Got It",
                style: .primary,
                icon: "checkmark.circle.fill"
            ) {
                HapticsService.shared.impact()
                dismiss()
            }

            // No commitment message
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(UtopianDesignFallback.Colors.completed)

                Text("No credit card required to start")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Logo fade in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.1)) {
            showLogo = true
        }

        // Logo breathing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.3)) {
            logoScale = 1.02
        }

        // Title
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.3)) {
            showTitle = true
        }

        // Timeline container
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.5)) {
            showTimeline = true
        }

        // Stagger step cards
        for index in stepAppearance.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(index) * 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    stepAppearance[index] = true
                }
            }
        }

        // Animate active step indicator
        startStepAnimation()

        // Footer
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(1.4)) {
            showFooter = true
        }
    }

    private func startStepAnimation() {
        // Cycle through steps to show progression
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                activeStep = (activeStep + 1) % steps.count
            }
        }
    }
}

// MARK: - Timeline Step Card

struct TimelineStepCard: View {
    let stepNumber: Int
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isLast: Bool
    let isVisible: Bool
    let isActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: UtopianDesignFallback.Spacing.md) {
            // Timeline indicator
            VStack(spacing: 0) {
                // Step circle
                ZStack {
                    // Outer glow when active
                    if isActive {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 56, height: 56)
                            .blur(radius: 8)
                    }

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(color.opacity(isActive ? 0.8 : 0.4), lineWidth: 2)
                        )

                    // Icon
                    Image(systemName: icon)
                        .dynamicTypeFont(base: 20, weight: .semibold)
                        .foregroundStyle(color)
                }
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isActive)

                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.4), nextStepColor.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 50)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.sm) {
                // Step number badge
                Text("Step \(stepNumber)")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )

                // Title
                Text(title)
                    .dynamicTypeFont(base: 18, weight: .bold)
                    .foregroundStyle(.white)

                // Subtitle
                Text(subtitle)
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
            .padding(.bottom, isLast ? 0 : UtopianDesignFallback.Spacing.lg)

            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }

    private var nextStepColor: Color {
        switch stepNumber {
        case 1: return UtopianDesignFallback.Gamification.starGold
        case 2: return UtopianDesignFallback.Colors.aiPurple
        default: return Color.white.opacity(0.3)
        }
    }
}

// MARK: - Utopian Background Extension

extension AuroraBackground {
    /// How It Works screen background
    static var howItWorks: AuroraBackground {
        AuroraBackground(
            showStars: true,
            starCount: 40,
            auroraIntensity: 0.35,
            glowColor: UtopianDesignFallback.Colors.focusActive,
            glowPosition: UnitPoint(x: 0.5, y: 0.3)
        )
    }
}

// MARK: - Preview

#Preview {
    HowItWorksView()
}
