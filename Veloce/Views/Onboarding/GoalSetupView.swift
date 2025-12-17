//
//  GoalSetupView.swift
//  MyTasksAI
//
//  Goal Setup Onboarding Step
//  Configure daily and weekly task goals
//

import SwiftUI

// MARK: - Goal Setup View
struct GoalSetupView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                headerSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Daily goal
                goalSection(
                    title: "Daily Goal",
                    subtitle: "How many tasks do you want to complete each day?",
                    icon: "sun.max.fill",
                    options: [3, 5, 7, 10],
                    selectedValue: viewModel.dailyTaskGoal,
                    onSelect: { viewModel.dailyTaskGoal = $0 }
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                // Weekly goal
                goalSection(
                    title: "Weekly Goal",
                    subtitle: "What's your weekly target?",
                    icon: "calendar.badge.clock",
                    options: [15, 25, 35, 50],
                    selectedValue: viewModel.weeklyTaskGoal,
                    onSelect: { viewModel.weeklyTaskGoal = $0 }
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 40)

                // Tip
                tipCard
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 50)

                Spacer(minLength: 100)
            }
            .padding(Theme.Spacing.lg)
        }
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "target")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(Theme.Colors.accent)

            Text("Set Your Goals")
                .font(Theme.Typography.title1)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Start with achievable targets. You can always adjust later.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Goal Section
    private func goalSection(
        title: String,
        subtitle: String,
        icon: String,
        options: [Int],
        selectedValue: Int,
        onSelect: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: Theme.Size.iconMedium))
                    .foregroundStyle(Theme.Colors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(subtitle)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            // Option buttons
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(options, id: \.self) { option in
                    GoalOptionButton(
                        value: option,
                        isSelected: selectedValue == option,
                        onTap: { onSelect(option) }
                    )
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .glassCardStyle()
    }

    // MARK: - Tip Card
    private var tipCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: Theme.Size.iconMedium))
                .foregroundStyle(Theme.Colors.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pro Tip")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Start small and build momentum. It's better to exceed your goals than fall short.")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.gold.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Colors.gold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Goal Option Button
struct GoalOptionButton: View {
    let value: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Text("\(value)")
                .font(Theme.Typography.title2)
                .foregroundStyle(isSelected ? Color.white : Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    isSelected ?
                    AnyShapeStyle(Theme.Colors.accentGradient) :
                    AnyShapeStyle(Theme.Colors.glassBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(isSelected ? Color.clear : Theme.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(
                    color: isSelected ? Theme.Colors.accent.opacity(0.3) : Color.clear,
                    radius: 8,
                    y: 4
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(Theme.Animation.quickSpring, value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    GoalSetupView(viewModel: OnboardingViewModel())
        .iridescentBackground()
}
