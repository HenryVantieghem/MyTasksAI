//
//  CelestialOnboardingContainer.swift
//  Veloce
//
//  Living Cosmos Onboarding Flow
//  Premium 7-step onboarding with celestial void aesthetic,
//  AI Genius showcase, permissions, goal setting, and 3-day trial info
//

import SwiftUI
import UserNotifications
import EventKit

// MARK: - Celestial Onboarding Steps

enum CelestialOnboardingStep: Int, CaseIterable {
    case welcome
    case geniusShowcase
    case permissions
    case goalSetup
    case featuresTour
    case trialInfo
    case complete
}

// MARK: - Celestial Onboarding Container

struct CelestialOnboardingContainer: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var viewModel: OnboardingViewModel

    @State private var currentStep: CelestialOnboardingStep = .welcome
    @State private var showContent = false
    @State private var orbState: OrbState = .dormant

    /// Adaptive padding based on device size
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : Theme.Spacing.lg
    }

    /// Max content width for iPad
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 600 : .infinity
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Living Cosmos void background
                VoidBackground.onboarding

                VStack(spacing: 0) {
                    // Constellation progress
                    OnboardingConstellationProgress(
                        totalSteps: CelestialOnboardingStep.allCases.count,
                        currentStep: currentStep.rawValue
                    )
                    .frame(maxWidth: maxContentWidth)
                    .padding(.horizontal, horizontalPadding + 20)
                    .padding(.top, Theme.Spacing.xl)
                    .frame(maxWidth: .infinity)

                    // Step content
                    TabView(selection: $currentStep) {
                        CelestialWelcomeStep(
                            onContinue: { nextStep() },
                            orbState: $orbState
                        )
                        .tag(CelestialOnboardingStep.welcome)

                        CelestialGeniusShowcaseStep(
                            onContinue: { nextStep() },
                            onBack: { previousStep() },
                            orbState: $orbState
                        )
                        .tag(CelestialOnboardingStep.geniusShowcase)

                        CelestialPermissionsStep(
                            viewModel: viewModel,
                            onContinue: { nextStep() },
                            onBack: { previousStep() },
                            onSkip: { nextStep() },
                            orbState: $orbState
                        )
                        .tag(CelestialOnboardingStep.permissions)

                        CelestialGoalSetupStep(
                            viewModel: viewModel,
                            onContinue: { nextStep() },
                            onBack: { previousStep() },
                            orbState: $orbState
                        )
                        .tag(CelestialOnboardingStep.goalSetup)

                        CelestialFeaturesTourStep(
                            onContinue: { nextStep() },
                            onBack: { previousStep() },
                            orbState: $orbState
                        )
                        .tag(CelestialOnboardingStep.featuresTour)

                        CelestialTrialInfoStep(
                            onContinue: { nextStep() },
                            onBack: { previousStep() },
                            orbState: $orbState
                        )
                        .tag(CelestialOnboardingStep.trialInfo)

                        CelestialCompleteStep(
                            viewModel: viewModel,
                            onComplete: {
                                HapticsService.shared.celebration()
                                viewModel.completeOnboarding()
                            },
                            orbState: $orbState
                        )
                        .tag(CelestialOnboardingStep.complete)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(LivingCosmos.Animations.spring, value: currentStep)
                }
            }
        }
        .onChange(of: currentStep) { _, newStep in
            updateOrbForStep(newStep)
        }
        .task {
            viewModel.onComplete = {
                Task {
                    await appViewModel.checkAuthenticationState()
                }
            }
        }
    }

    // MARK: - Navigation

    private func nextStep() {
        HapticsService.shared.impact()
        let allSteps = CelestialOnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            withAnimation(LivingCosmos.Animations.portalOpen) {
                currentStep = allSteps[currentIndex + 1]
            }
        }
    }

    private func previousStep() {
        HapticsService.shared.lightImpact()
        let allSteps = CelestialOnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            withAnimation(LivingCosmos.Animations.spring) {
                currentStep = allSteps[currentIndex - 1]
            }
        }
    }

    // MARK: - Orb State

    private func updateOrbForStep(_ step: CelestialOnboardingStep) {
        withAnimation(LivingCosmos.Animations.spring) {
            switch step {
            case .welcome:
                orbState = .aware
            case .geniusShowcase:
                orbState = .processing
            case .permissions, .goalSetup, .featuresTour, .trialInfo:
                orbState = .active
            case .complete:
                orbState = .celebration
            }
        }
    }
}

// MARK: - Onboarding Constellation Progress

struct OnboardingConstellationProgress: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: LivingCosmos.Onboarding.progressOrbSpacing) {
            ForEach(0..<totalSteps, id: \.self) { index in
                progressOrb(for: index)
            }
        }
    }

    private func progressOrb(for index: Int) -> some View {
        let isComplete = index < currentStep
        let isCurrent = index == currentStep

        return ZStack {
            // Glow for current
            if isCurrent {
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.4))
                    .frame(width: 20, height: 20)
                    .blur(radius: 6)
            }

            // Orb
            SwiftUI.Circle()
                .fill(orbColor(isComplete: isComplete, isCurrent: isCurrent))
                .frame(
                    width: isCurrent ? LivingCosmos.Onboarding.progressOrbSize + 4 : LivingCosmos.Onboarding.progressOrbSize,
                    height: isCurrent ? LivingCosmos.Onboarding.progressOrbSize + 4 : LivingCosmos.Onboarding.progressOrbSize
                )

            // Checkmark for complete
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .animation(LivingCosmos.Animations.spring, value: currentStep)
    }

    private func orbColor(isComplete: Bool, isCurrent: Bool) -> Color {
        if isComplete {
            return Theme.CelestialColors.auroraGreen
        } else if isCurrent {
            return Theme.Colors.aiPurple
        } else {
            return Theme.CelestialColors.starGhost.opacity(0.4)
        }
    }
}

// MARK: - Step 1: Welcome

struct CelestialWelcomeStep: View {
    let onContinue: () -> Void
    @Binding var orbState: OrbState

    @State private var showContent = false
    @State private var featureAppearance: [Bool] = [false, false, false]

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Title section
            VStack(spacing: Theme.Spacing.md) {
                Text("Welcome to")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .staggeredReveal(index: 0, isVisible: showContent)

                Text("Veloce")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.CelestialColors.starWhite, Theme.Colors.aiPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .staggeredReveal(index: 1, isVisible: showContent)

                Text("Your AI-powered productivity companion")
                    .font(Theme.Typography.cosmosWhisper)
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .staggeredReveal(index: 2, isVisible: showContent)
            }
            .padding(.top, 100) // Space for orb

            // Features preview
            VStack(spacing: Theme.Spacing.md) {
                CelestialFeatureRow(
                    icon: "brain.head.profile",
                    iconColor: Theme.Colors.aiPurple,
                    title: "AI Task Advice",
                    subtitle: "Smart suggestions for every task",
                    isVisible: featureAppearance[0]
                )

                CelestialFeatureRow(
                    icon: "sparkles",
                    iconColor: Theme.CelestialColors.plasmaCore,
                    title: "Brain Dump",
                    subtitle: "Turn thoughts into organized tasks",
                    isVisible: featureAppearance[1]
                )

                CelestialFeatureRow(
                    icon: "trophy.fill",
                    iconColor: Theme.Colors.xp,
                    title: "Gamification",
                    subtitle: "Earn XP and unlock achievements",
                    isVisible: featureAppearance[2]
                )
            }
            .padding(Theme.Spacing.lg)
            .celestialGlass()
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            // CTA
            CosmicButton("Begin Journey", style: .primary, icon: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
            .staggeredReveal(index: 3, isVisible: showContent)
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            orbState = .aware
        }

        withAnimation(LivingCosmos.Animations.portalOpen.delay(0.3)) {
            showContent = true
        }

        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(index) * 0.12) {
                withAnimation(LivingCosmos.Animations.stellarBounce) {
                    featureAppearance[index] = true
                }
            }
        }
    }
}

// MARK: - Step 2: Genius Showcase

struct CelestialGeniusShowcaseStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    @Binding var orbState: OrbState

    @State private var showContent = false
    @State private var demoStep = 0
    @State private var showDemo = false

    private let demoTasks = [
        ("Buy groceries", "Consider meal prepping on Sunday to save time during the week"),
        ("Finish report", "Break into 25-min focused sprints with short breaks"),
        ("Call mom", "Schedule for Sunday afternoon when she's usually free")
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Title
            VStack(spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.Colors.aiPurple)
                    Text("Meet Genius")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                }

                Text("Your AI-powered task advisor")
                    .font(Theme.Typography.cosmosWhisper)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            .staggeredReveal(index: 0, isVisible: showContent)
            .padding(.top, 80)

            // Demo card
            VStack(spacing: Theme.Spacing.md) {
                if showDemo && demoStep < demoTasks.count {
                    let task = demoTasks[demoStep]

                    // Task
                    HStack {
                        SwiftUI.Circle()
                            .strokeBorder(Theme.CelestialColors.starDim, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        Text(task.0)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.starWhite)

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // AI Advice
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.aiPurple)

                        Text(task.1)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                            .italic()
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.aiPurple.opacity(0.1))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .frame(height: 140)
            .padding(.vertical, Theme.Spacing.md)
            .celestialGlass()
            .padding(.horizontal, Theme.Spacing.lg)
            .staggeredReveal(index: 1, isVisible: showContent)

            // Info text
            CosmicInfoCard(
                message: "Genius analyzes your tasks and provides personalized advice to help you stay productive",
                style: .tip
            )
            .padding(.horizontal, Theme.Spacing.lg)
            .staggeredReveal(index: 2, isVisible: showContent)

            Spacer()

            // Navigation
            HStack(spacing: Theme.Spacing.md) {
                CosmicButton("Back", style: .ghost, icon: "chevron.left", iconPosition: .leading) {
                    onBack()
                }
                .frame(width: 100)

                Spacer()

                CosmicButton("Continue", style: .primary, icon: "arrow.right") {
                    onContinue()
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        orbState = .processing

        withAnimation(LivingCosmos.Animations.portalOpen.delay(0.2)) {
            showContent = true
        }

        // Start demo cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(LivingCosmos.Animations.spring) {
                showDemo = true
            }
            startDemoCycle()
        }
    }

    private func startDemoCycle() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            withAnimation(LivingCosmos.Animations.spring) {
                demoStep = (demoStep + 1) % demoTasks.count
            }
        }
    }
}

// MARK: - Step 3: Permissions

struct CelestialPermissionsStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void
    @Binding var orbState: OrbState

    @State private var showContent = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer(minLength: 100)

                // Title
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Let Me Help You Best")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("Enable features for the full experience")
                        .font(Theme.Typography.cosmosWhisper)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .staggeredReveal(index: 0, isVisible: showContent)

                // Permission toggles
                VStack(spacing: 0) {
                    CosmicToggleRow(
                        icon: "bell.badge.fill",
                        iconColor: Theme.Colors.accent,
                        title: "Notifications",
                        subtitle: "Get timely reminders for tasks",
                        isOn: $viewModel.notificationsGranted
                    )
                    .onChange(of: viewModel.notificationsGranted) { _, granted in
                        if granted {
                            orbState = .success
                            Task {
                                await viewModel.requestNotifications()
                            }
                        }
                    }

                    CosmicDivider()

                    CosmicToggleRow(
                        icon: "calendar",
                        iconColor: Theme.Colors.aiBlue,
                        title: "Calendar Sync",
                        subtitle: "Integrate with Apple Calendar",
                        isOn: $viewModel.calendarGranted
                    )
                    .onChange(of: viewModel.calendarGranted) { _, granted in
                        if granted {
                            orbState = .success
                            Task {
                                await viewModel.requestCalendar()
                            }
                        }
                    }
                }
                .celestialGlass()
                .padding(.horizontal, Theme.Spacing.lg)
                .staggeredReveal(index: 1, isVisible: showContent)

                // Privacy note
                CosmicInfoCard(
                    icon: "lock.shield.fill",
                    message: "Your data stays private and secure. We never share your information.",
                    style: .success
                )
                .padding(.horizontal, Theme.Spacing.lg)
                .staggeredReveal(index: 2, isVisible: showContent)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .safeAreaInset(edge: .bottom) {
            // Navigation
            HStack(spacing: Theme.Spacing.md) {
                CosmicButton("Back", style: .ghost, icon: "chevron.left", iconPosition: .leading) {
                    onBack()
                }
                .frame(width: 100)

                Spacer()

                CosmicLinkButton("Skip", color: Theme.CelestialColors.starGhost) {
                    onSkip()
                }

                CosmicButton("Continue", style: .primary, icon: "arrow.right") {
                    onContinue()
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            orbState = .active
            withAnimation(LivingCosmos.Animations.portalOpen.delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Step 4: Goal Setup

struct CelestialGoalSetupStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onBack: () -> Void
    @Binding var orbState: OrbState

    @State private var showContent = false

    private let dailyOptions = [3, 5, 7, 10]
    private let weeklyOptions = [15, 25, 35, 50]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer(minLength: 100)

                // Title
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Set Your Ambitions")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("How many tasks do you want to complete?")
                        .font(Theme.Typography.cosmosWhisper)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .staggeredReveal(index: 0, isVisible: showContent)

                // Daily goal
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Label("Daily Tasks", systemImage: "sun.max.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.aiPurple)

                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(dailyOptions, id: \.self) { option in
                            CelestialGoalOption(
                                value: option,
                                isSelected: viewModel.dailyTaskGoal == option,
                                accentColor: Theme.Colors.aiPurple
                            ) {
                                orbState = .active
                                HapticsService.shared.selectionFeedback()
                                viewModel.dailyTaskGoal = option
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
                .celestialGlass()
                .padding(.horizontal, Theme.Spacing.lg)
                .staggeredReveal(index: 1, isVisible: showContent)

                // Weekly goal
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Label("Weekly Tasks", systemImage: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.aiBlue)

                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(weeklyOptions, id: \.self) { option in
                            CelestialGoalOption(
                                value: option,
                                isSelected: viewModel.weeklyTaskGoal == option,
                                accentColor: Theme.Colors.aiBlue
                            ) {
                                orbState = .active
                                HapticsService.shared.selectionFeedback()
                                viewModel.weeklyTaskGoal = option
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
                .celestialGlass()
                .padding(.horizontal, Theme.Spacing.lg)
                .staggeredReveal(index: 2, isVisible: showContent)

                // Pro tip
                CosmicInfoCard(
                    message: "Start small and increase as you build momentum",
                    style: .tip
                )
                .padding(.horizontal, Theme.Spacing.lg)
                .staggeredReveal(index: 3, isVisible: showContent)

                Spacer(minLength: 100)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: Theme.Spacing.md) {
                CosmicButton("Back", style: .ghost, icon: "chevron.left", iconPosition: .leading) {
                    onBack()
                }
                .frame(width: 100)

                Spacer()

                CosmicButton("Continue", style: .primary, icon: "arrow.right") {
                    onContinue()
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            orbState = .active
            withAnimation(LivingCosmos.Animations.portalOpen.delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Step 5: Features Tour

struct CelestialFeaturesTourStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    @Binding var orbState: OrbState

    @State private var showContent = false
    @State private var currentFeature = 0

    private let features: [(icon: String, color: Color, title: String, description: String)] = [
        ("brain.head.profile", Theme.Colors.aiPurple, "AI Task Advice", "Get personalized suggestions for every task to help you work smarter"),
        ("timer", Theme.Colors.aiAmber, "Focus Timer", "Stay productive with Pomodoro-style focus sessions and app blocking"),
        ("trophy.fill", Theme.Colors.xp, "XP & Levels", "Earn experience points and level up as you complete tasks"),
        ("person.2.fill", Theme.Colors.aiBlue, "Social Circles", "Join accountability groups and stay motivated together")
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Title
            VStack(spacing: Theme.Spacing.sm) {
                Text("Key Features")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Everything you need to be productive")
                    .font(Theme.Typography.cosmosWhisper)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            .staggeredReveal(index: 0, isVisible: showContent)
            .padding(.top, 80)

            // Feature carousel
            TabView(selection: $currentFeature) {
                ForEach(0..<features.count, id: \.self) { index in
                    featureCard(features[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 280)
            .padding(.horizontal, Theme.Spacing.lg)
            .staggeredReveal(index: 1, isVisible: showContent)

            // Page dots
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<features.count, id: \.self) { index in
                    SwiftUI.Circle()
                        .fill(index == currentFeature ? Theme.Colors.aiPurple : Theme.CelestialColors.starGhost.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .animation(LivingCosmos.Animations.quick, value: currentFeature)

            Spacer()

            // Navigation
            HStack(spacing: Theme.Spacing.md) {
                CosmicButton("Back", style: .ghost, icon: "chevron.left", iconPosition: .leading) {
                    onBack()
                }
                .frame(width: 100)

                Spacer()

                CosmicButton("Continue", style: .primary, icon: "arrow.right") {
                    onContinue()
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .onAppear {
            orbState = .active
            withAnimation(LivingCosmos.Animations.portalOpen.delay(0.2)) {
                showContent = true
            }
        }
    }

    private func featureCard(_ feature: (icon: String, color: Color, title: String, description: String)) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon
            ZStack {
                SwiftUI.Circle()
                    .fill(feature.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                SwiftUI.Circle()
                    .fill(feature.color.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .blur(radius: 12)

                Image(systemName: feature.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(feature.color)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text(feature.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text(feature.description)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .celestialGlass(accentColor: feature.color)
    }
}

// MARK: - Step 6: Trial Info

struct CelestialTrialInfoStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    @Binding var orbState: OrbState

    @State private var showContent = false

    private let proFeatures = [
        ("sparkles", "AI Genius Advice", "Personalized task suggestions"),
        ("brain", "Unlimited Brain Dumps", "Turn thoughts into tasks"),
        ("chart.bar.fill", "Advanced Analytics", "Track your productivity"),
        ("person.2.fill", "Social Circles", "Accountability groups"),
        ("bell.badge.fill", "Smart Reminders", "Context-aware notifications")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer(minLength: 80)

                // Title
                VStack(spacing: Theme.Spacing.md) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Theme.Colors.xp)
                        Text("3-Day Free Trial")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.CelestialColors.starWhite)
                        Image(systemName: "star.fill")
                            .foregroundStyle(Theme.Colors.xp)
                    }

                    Text("Try everything free for 3 days")
                        .font(Theme.Typography.cosmosWhisper)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .staggeredReveal(index: 0, isVisible: showContent)

                // Pro features list
                VStack(spacing: 0) {
                    ForEach(0..<proFeatures.count, id: \.self) { index in
                        let feature = proFeatures[index]

                        HStack(spacing: Theme.Spacing.md) {
                            ZStack {
                                SwiftUI.Circle()
                                    .fill(Theme.Colors.aiPurple.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: feature.0)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Theme.Colors.aiPurple)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.1)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.CelestialColors.starWhite)

                                Text(feature.2)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.CelestialColors.starDim)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.CelestialColors.auroraGreen)
                        }
                        .padding(.vertical, Theme.Spacing.sm)

                        if index < proFeatures.count - 1 {
                            CosmicDivider()
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
                .celestialGlass(accentColor: Theme.Colors.xp)
                .padding(.horizontal, Theme.Spacing.lg)
                .staggeredReveal(index: 1, isVisible: showContent)

                // No charge note
                CosmicInfoCard(
                    icon: "creditcard",
                    message: "No charge today. Cancel anytime during your trial.",
                    style: .info
                )
                .padding(.horizontal, Theme.Spacing.lg)
                .staggeredReveal(index: 2, isVisible: showContent)

                Spacer(minLength: 100)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: Theme.Spacing.md) {
                CosmicButton("Back", style: .ghost, icon: "chevron.left", iconPosition: .leading) {
                    onBack()
                }
                .frame(width: 100)

                Spacer()

                CosmicButton("Start Free Trial", style: .primary, icon: "sparkles") {
                    onContinue()
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            orbState = .active
            withAnimation(LivingCosmos.Animations.portalOpen.delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Step 7: Complete

struct CelestialCompleteStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void
    @Binding var orbState: OrbState

    @State private var showContent = false
    @State private var showSummary = false
    @State private var showButton = false
    @State private var triggerBurst = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Celebration
            VStack(spacing: Theme.Spacing.md) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.CelestialColors.starWhite, Theme.CelestialColors.auroraGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .staggeredReveal(index: 0, isVisible: showContent)

                Text("Your AI companion is ready to help you succeed")
                    .font(Theme.Typography.cosmosWhisper)
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .staggeredReveal(index: 1, isVisible: showContent)
            }
            .padding(.top, 120)

            // Summary card
            VStack(spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Theme.Colors.xp)
                    Text("Your Setup")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                    Spacer()
                }

                CosmicDivider()

                CelestialSummaryRow(icon: "sun.max.fill", iconColor: Theme.Colors.aiPurple, label: "Daily Goal", value: "\(viewModel.dailyTaskGoal) tasks")
                CelestialSummaryRow(icon: "calendar", iconColor: Theme.Colors.aiBlue, label: "Weekly Goal", value: "\(viewModel.weeklyTaskGoal) tasks")
                CelestialSummaryRow(icon: "bell.fill", iconColor: Theme.CelestialColors.auroraGreen, label: "Notifications", value: viewModel.notificationsGranted ? "Enabled" : "Disabled")
                CelestialSummaryRow(icon: "calendar.badge.checkmark", iconColor: Theme.Colors.aiBlue, label: "Calendar", value: viewModel.calendarGranted ? "Synced" : "Not synced")
            }
            .padding(Theme.Spacing.lg)
            .celestialGlass(accentColor: Theme.CelestialColors.auroraGreen, isSelected: true)
            .padding(.horizontal, Theme.Spacing.lg)
            .opacity(showSummary ? 1 : 0)
            .offset(y: showSummary ? 0 : 30)

            Spacer()

            // Let's Go button
            CosmicButton("Let's Get Productive!", style: .success, icon: "arrow.right") {
                onComplete()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 30)
            .supernovaBurst(trigger: $triggerBurst, color: Theme.CelestialColors.auroraGreen)
        }
        .onAppear {
            startCelebration()
        }
    }

    private func startCelebration() {
        orbState = .celebration

        withAnimation(LivingCosmos.Animations.portalOpen.delay(0.2)) {
            showContent = true
        }

        withAnimation(LivingCosmos.Animations.stellarBounce.delay(0.5)) {
            showSummary = true
        }

        withAnimation(LivingCosmos.Animations.stellarBounce.delay(0.9)) {
            showButton = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            triggerBurst = true
        }

        HapticsService.shared.taskComplete()
    }
}

// MARK: - Helper Components

struct CelestialFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
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

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.CelestialColors.auroraGreen.opacity(0.8))
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

struct CelestialGoalOption: View {
    let value: Int
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starDim)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? accentColor : Theme.CelestialColors.void.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected ? accentColor : Theme.CelestialColors.starGhost.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? accentColor.opacity(0.4) : Color.clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(LivingCosmos.Animations.quick, value: isPressed)
        .animation(LivingCosmos.Animations.spring, value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct CelestialSummaryRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starWhite)
        }
    }
}

// MARK: - Preview

#Preview {
    CelestialOnboardingContainer(viewModel: OnboardingViewModel())
        .environment(AppViewModel())
}
