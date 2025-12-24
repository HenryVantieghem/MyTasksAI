//
//  GoalSetupView.swift
//  MyTasksAI
//
//  Goal Setup Onboarding Step - Aurora Design System
//  Celestial cosmic design with stunning animations
//

import SwiftUI

// MARK: - Goal Setup View

struct GoalSetupView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var dailySectionVisible = false
    @State private var weeklySectionVisible = false
    @State private var tipVisible = false
    @State private var iconPulse: CGFloat = 1.0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Aurora.Layout.spacingXL) {
                // Enhanced header
                enhancedHeaderSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Daily goal with animation
                EnhancedGoalSection(
                    title: "Daily Goal",
                    subtitle: "How many tasks each day?",
                    icon: "sun.max.fill",
                    iconColor: Aurora.Colors.electric,
                    options: [3, 5, 7, 10],
                    selectedValue: viewModel.dailyTaskGoal,
                    onSelect: { value in
                        HapticsService.shared.selectionFeedback()
                        viewModel.dailyTaskGoal = value
                    }
                )
                .opacity(dailySectionVisible ? 1 : 0)
                .offset(y: dailySectionVisible ? 0 : 30)

                // Weekly goal with animation
                EnhancedGoalSection(
                    title: "Weekly Goal",
                    subtitle: "What's your weekly target?",
                    icon: "calendar.badge.clock",
                    iconColor: Aurora.Colors.cyan,
                    options: [15, 25, 35, 50],
                    selectedValue: viewModel.weeklyTaskGoal,
                    onSelect: { value in
                        HapticsService.shared.selectionFeedback()
                        viewModel.weeklyTaskGoal = value
                    }
                )
                .opacity(weeklySectionVisible ? 1 : 0)
                .offset(y: weeklySectionVisible ? 0 : 30)

                // Enhanced tip card
                enhancedTipCard
                    .opacity(tipVisible ? 1 : 0)
                    .offset(y: tipVisible ? 0 : 20)

                Spacer(minLength: 100)
            }
            .padding(Aurora.Layout.screenPadding)
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Enhanced Header Section

    private var enhancedHeaderSection: some View {
        VStack(spacing: Aurora.Layout.spacing) {
            // Animated icon
            ZStack {
                // Glow
                SwiftUI.Circle()
                    .fill(Aurora.Colors.electric.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .blur(radius: 20)
                    .scaleEffect(iconPulse)

                SwiftUI.Circle()
                    .fill(Aurora.Colors.cosmicElevated)
                    .frame(width: 80, height: 80)

                Image(systemName: "target")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Aurora.Colors.electric, Aurora.Colors.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Set Your Goals")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Aurora.Colors.textPrimary)

            Text("Start with achievable targets.\nYou can always adjust later.")
                .font(.system(size: 16))
                .foregroundStyle(Aurora.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Enhanced Tip Card

    private var enhancedTipCard: some View {
        HStack(spacing: Aurora.Layout.spacing) {
            ZStack {
                SwiftUI.Circle()
                    .fill(Aurora.Colors.gold.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Aurora.Colors.gold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Pro Tip")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Aurora.Colors.gold)

                Text("Start small and build momentum. It's better to exceed your goals than fall short.")
                    .font(.system(size: 14))
                    .foregroundStyle(Aurora.Colors.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(Aurora.Layout.spacingLarge)
        .background(
            RoundedRectangle(cornerRadius: Aurora.Radius.large)
                .fill(Aurora.Colors.gold.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Aurora.Radius.large)
                        .stroke(Aurora.Colors.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func startAnimations() {
        // Header fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            showContent = true
        }

        // Icon pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            iconPulse = 1.1
        }

        // Staggered sections
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Aurora.Animation.spring) {
                dailySectionVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(Aurora.Animation.spring) {
                weeklySectionVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(Aurora.Animation.spring) {
                tipVisible = true
            }
        }
    }
}

// MARK: - Enhanced Goal Section

struct EnhancedGoalSection: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let options: [Int]
    let selectedValue: Int
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Aurora.Layout.spacingLarge) {
            HStack(spacing: Aurora.Layout.spacing) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Aurora.Colors.textSecondary)
                }

                Spacer()
            }

            // Option buttons
            HStack(spacing: Aurora.Layout.spacingSmall) {
                ForEach(options, id: \.self) { option in
                    EnhancedGoalOptionButton(
                        value: option,
                        isSelected: selectedValue == option,
                        accentColor: iconColor,
                        onTap: { onSelect(option) }
                    )
                }
            }
        }
        .padding(Aurora.Layout.spacingXL)
        .background(
            RoundedRectangle(cornerRadius: Aurora.Radius.xl)
                .fill(Aurora.Colors.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Aurora.Radius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    iconColor.opacity(0.3),
                                    iconColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: iconColor.opacity(0.1), radius: 15, y: 8)
    }
}

// MARK: - Enhanced Goal Option Button

struct EnhancedGoalOptionButton: View {
    let value: Int
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Aurora.Colors.textPrimary)

                if isSelected {
                    Text("tasks")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Aurora.Colors.cosmicElevated
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Aurora.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Aurora.Radius.large)
                    .stroke(
                        isSelected ? Color.clear : Aurora.Colors.glassBorder,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? accentColor.opacity(0.4) : Color.clear,
                radius: 10,
                y: 5
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(Aurora.Animation.spring, value: isSelected)
    }
}

// MARK: - Legacy Goal Option Button

struct GoalOptionButton: View {
    let value: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Text("\(value)")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Aurora.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    isSelected ?
                    AnyShapeStyle(Aurora.Gradients.aurora) :
                    AnyShapeStyle(Aurora.Colors.glassBase)
                )
                .clipShape(RoundedRectangle(cornerRadius: Aurora.Radius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: Aurora.Radius.medium)
                        .stroke(isSelected ? Color.clear : Aurora.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(
                    color: isSelected ? Aurora.Colors.electric.opacity(0.3) : Color.clear,
                    radius: 8,
                    y: 4
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(Aurora.Animation.spring, value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    GoalSetupView(viewModel: OnboardingViewModel())
        .background(AuroraBackground.onboardingStep)
}
