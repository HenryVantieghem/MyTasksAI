//
//  OnboardingContainerView.swift
//  MyTasksAI
//
//  Onboarding Container View
//  Multi-step wizard with beautiful transitions
//

import SwiftUI

// MARK: - Onboarding Container View
struct OnboardingContainerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var viewModel: OnboardingViewModel

    /// Adaptive padding based on device size
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? Theme.Layout.regularPadding : Theme.Spacing.lg
    }

    /// Max content width for iPad
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? Theme.Layout.maxCardWidth : .infinity
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Iridescent background
                IridescentBackground(intensity: 0.5)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar - centered on iPad
                    progressBar
                        .frame(maxWidth: maxContentWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, Theme.Spacing.md)
                        .frame(maxWidth: .infinity)

                    // Content
                    TabView(selection: Binding(
                        get: { viewModel.currentStep },
                        set: { _ in }
                    )) {
                        WelcomeStepView(viewModel: viewModel)
                            .tag(OnboardingStep.welcome)

                        GoalSetupView(viewModel: viewModel)
                            .tag(OnboardingStep.goals)

                        FocusAreasView(viewModel: viewModel)
                            .tag(OnboardingStep.focusAreas)

                        PermissionsView(viewModel: viewModel)
                            .tag(OnboardingStep.notifications)

                        CompleteView(viewModel: viewModel)
                            .tag(OnboardingStep.complete)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(Theme.Animation.spring, value: viewModel.currentStep)

                    // Navigation buttons - centered on iPad
                    navigationButtons
                        .frame(maxWidth: maxContentWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, Theme.Spacing.lg)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.glassBorder)
                    .frame(height: 4)

                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * viewModel.progress, height: 4)
                    .animation(Theme.Animation.spring, value: viewModel.progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Back button
            if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                Button {
                    viewModel.previousStep()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.secondary)
            }

            Spacer()

            // Skip button (except on complete)
            if viewModel.currentStep != .complete && viewModel.currentStep != .welcome {
                Button("Skip") {
                    viewModel.skip()
                }
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
            }

            // Next/Continue button
            if viewModel.currentStep != .complete {
                Button {
                    viewModel.nextStep()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(nextButtonTitle)
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.primary)
                .disabled(!canProceed)
                .opacity(canProceed ? 1 : 0.6)
            }
        }
    }

    // MARK: - Helpers
    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .welcome: return "Get Started"
        case .goals: return "Continue"
        case .focusAreas: return "Continue"
        case .name: return "Continue"
        case .notifications: return "Continue"
        case .calendar: return "Continue"
        case .complete: return "Done"
        }
    }

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .focusAreas: return !viewModel.selectedFocusAreas.isEmpty
        case .name: return !viewModel.fullName.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }
}

// MARK: - Welcome Step View
struct WelcomeStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Icon with glow
            ZStack {
                IridescentOrb(size: 120)
                    .blur(radius: 30)
                    .opacity(showContent ? 1 : 0)

                Image(systemName: "sparkles")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: Theme.Colors.iridescentGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Welcome to MyTasksAI")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Let's set up your personal task planner with AI-powered suggestions")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }

            // Features list
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                FeatureRow(icon: "brain.head.profile", title: "AI Task Advice", subtitle: "Get smart suggestions for every task")
                FeatureRow(icon: "calendar", title: "Calendar Sync", subtitle: "Seamlessly integrate with your calendar")
                FeatureRow(icon: "trophy.fill", title: "Gamification", subtitle: "Earn points and unlock achievements")
            }
            .padding(Theme.Spacing.lg)
            .glassCardStyle()
            .padding(.horizontal, Theme.Spacing.lg)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)

            Spacer()
        }
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: Theme.Size.iconLarge))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Complete View
struct CompleteView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var confettiTrigger = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Success animation
            ZStack {
                // Glow effect
                Circle()
                    .fill(Theme.Colors.success.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .scaleEffect(showContent ? 1.2 : 0.5)

                IridescentOrb(size: 150)
                    .opacity(showContent ? 0.6 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100, weight: .light))
                    .foregroundStyle(Theme.Colors.success)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.3)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("You're All Set!")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Start adding tasks and let AI help you stay productive")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }

            // Summary card
            summaryCard
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

            Spacer()

            // Start button
            Button {
                viewModel.onComplete?()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Start Planning")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.primary)
            .padding(.horizontal, Theme.Spacing.lg)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.2)) {
                showContent = true
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Text("Your Setup")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
            }

            Divider()

            SummaryRow(label: "Daily Goal", value: "\(viewModel.dailyTaskGoal) tasks")
            SummaryRow(label: "Weekly Goal", value: "\(viewModel.weeklyTaskGoal) tasks")
            SummaryRow(label: "Focus Areas", value: "\(viewModel.selectedFocusAreas.count) selected")
            SummaryRow(label: "Notifications", value: viewModel.notificationsGranted ? "Enabled" : "Disabled")
            SummaryRow(label: "Calendar Sync", value: viewModel.calendarGranted ? "Enabled" : "Disabled")
        }
        .padding(Theme.Spacing.lg)
        .glassCardStyle()
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView(viewModel: OnboardingViewModel())
}
