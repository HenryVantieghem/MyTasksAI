//
//  OnboardingContainerView.swift
//  Veloce
//
//  Onboarding Container View - Celestial Aurora Design
//  A journey with an awakening AI companion through cosmic aurora
//

import SwiftUI

// MARK: - Onboarding Container View

struct OnboardingContainerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var viewModel: OnboardingViewModel

    /// Shared orb state across all onboarding steps
    @State private var orbState: OrbState = .dormant

    /// Adaptive padding based on device size
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : Aurora.Layout.screenPadding
    }

    /// Max content width for iPad
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 600 : .infinity
    }

    /// Current step index
    private var currentStepIndex: Int {
        OnboardingStep.allCases.firstIndex(of: viewModel.currentStep) ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Aurora background (changes based on step)
                auroraBackground(for: viewModel.currentStep)

                // Celestial Orb - The AI companion
                CelestialOrb(
                    state: $orbState,
                    size: orbSize(for: geometry),
                    showRings: true,
                    showParticles: orbState == .processing || orbState == .celebration
                )
                .position(
                    x: geometry.size.width / 2,
                    y: orbYPosition(for: geometry)
                )

                VStack(spacing: 0) {
                    // Aurora progress indicator
                    AuroraProgressIndicator(
                        totalSteps: OnboardingStep.allCases.count,
                        currentStep: currentStepIndex
                    )
                    .frame(maxWidth: maxContentWidth)
                    .padding(.horizontal, horizontalPadding + 20)
                    .padding(.top, Aurora.Layout.spacingLarge)
                    .frame(maxWidth: .infinity)

                    // Content - Step views
                    TabView(selection: Binding(
                        get: { viewModel.currentStep },
                        set: { _ in }
                    )) {
                        AuroraWelcomeStepView(viewModel: viewModel, orbState: $orbState)
                            .tag(OnboardingStep.welcome)

                        AuroraGoalSetupView(viewModel: viewModel, orbState: $orbState)
                            .tag(OnboardingStep.goals)

                        AuroraFocusAreasView(viewModel: viewModel, orbState: $orbState)
                            .tag(OnboardingStep.focusAreas)

                        AuroraPermissionsView(viewModel: viewModel, orbState: $orbState)
                            .tag(OnboardingStep.notifications)

                        AuroraCompleteView(viewModel: viewModel, orbState: $orbState)
                            .tag(OnboardingStep.complete)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(Aurora.Animation.spring, value: viewModel.currentStep)

                    // Navigation buttons
                    auroraNavigationButtons
                        .frame(maxWidth: maxContentWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, Aurora.Layout.spacingLarge)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onChange(of: viewModel.currentStep) { _, newStep in
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

    // MARK: - Layout Calculations

    private func orbSize(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        switch viewModel.currentStep {
        case .welcome: return height < 700 ? 100 : 120 // Larger for welcome
        case .complete: return height < 700 ? 120 : 140 // Largest for celebration
        default: return height < 700 ? 60 : 80 // Smaller for steps
        }
    }

    private func orbYPosition(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        switch viewModel.currentStep {
        case .welcome: return height * 0.22
        case .complete: return height * 0.20
        default: return height * 0.12 // Higher for step screens
        }
    }

    // MARK: - Aurora Background

    @ViewBuilder
    private func auroraBackground(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            AuroraBackground.onboardingWelcome
        case .complete:
            AuroraBackground.onboardingComplete
        default:
            AuroraBackground.onboardingStep
        }
    }

    // MARK: - Orb State Management

    private func updateOrbForStep(_ step: OnboardingStep) {
        withAnimation(Aurora.Animation.spring) {
            switch step {
            case .welcome:
                orbState = .aware
            case .goals, .focusAreas, .notifications:
                orbState = .active
            case .complete:
                orbState = .celebration
            }
        }
    }

    // MARK: - Navigation Buttons

    private var auroraNavigationButtons: some View {
        HStack(spacing: Aurora.Layout.spacing) {
            // Back button
            if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                AuroraButton("Back", style: .secondary, icon: "chevron.left") {
                    HapticsService.shared.lightImpact()
                    viewModel.previousStep()
                }
                .frame(width: 110)
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            Spacer()

            // Skip button
            if viewModel.currentStep != .complete && viewModel.currentStep != .welcome {
                AuroraLinkButton("Skip", color: Aurora.Colors.textTertiary) {
                    HapticsService.shared.lightImpact()
                    viewModel.skip()
                }
            }

            // CTA button
            if viewModel.currentStep != .complete {
                AuroraButton(
                    nextButtonTitle,
                    style: .primary,
                    isEnabled: canProceed,
                    icon: "arrow.right"
                ) {
                    HapticsService.shared.impact()
                    viewModel.nextStep()
                }
                .frame(minWidth: 140)
            }
        }
        .animation(Aurora.Animation.spring, value: viewModel.currentStep)
    }

    // MARK: - Helpers

    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .welcome: return "Get Started"
        case .goals, .focusAreas, .notifications: return "Continue"
        case .complete: return "Done"
        }
    }

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .focusAreas: return !viewModel.selectedFocusAreas.isEmpty
        default: return true
        }
    }
}

// MARK: - Aurora Progress Indicator

struct AuroraProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: Aurora.Layout.spacingSmall) {
            ForEach(0..<totalSteps, id: \.self) { index in
                progressDot(for: index)
            }
        }
    }

    private func progressDot(for index: Int) -> some View {
        let isComplete = index < currentStep
        let isCurrent = index == currentStep

        return SwiftUI.Circle()
            .fill(dotColor(isComplete: isComplete, isCurrent: isCurrent))
            .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
            .shadow(
                color: isCurrent ? Aurora.Colors.electric.opacity(0.5) : Color.clear,
                radius: 4
            )
            .animation(Aurora.Animation.spring, value: currentStep)
    }

    private func dotColor(isComplete: Bool, isCurrent: Bool) -> Color {
        if isComplete {
            return Aurora.Colors.success
        } else if isCurrent {
            return Aurora.Colors.electric
        } else {
            return Aurora.Colors.glassBase
        }
    }
}

// MARK: - Aurora Welcome Step View

struct AuroraWelcomeStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var orbState: OrbState
    @State private var showContent = false
    @State private var featureAppearance: [Bool] = [false, false, false]

    var body: some View {
        VStack(spacing: Aurora.Layout.spacingXL) {
            Spacer()

            // Title section
            VStack(spacing: Aurora.Layout.spacing) {
                Text("Welcome to")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Aurora.Colors.textSecondary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                Text("MyTasksAI")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Aurora.Colors.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Your AI-powered productivity companion")
                    .font(.system(size: 16))
                    .foregroundStyle(Aurora.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Aurora.Layout.spacingXL)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .padding(.top, 100) // Space for the orb

            // Features list
            VStack(alignment: .leading, spacing: Aurora.Layout.spacingLarge) {
                AuroraFeatureRow(
                    icon: "brain.head.profile",
                    iconColor: Aurora.Colors.violet,
                    title: "AI Task Advice",
                    subtitle: "Smart suggestions for every task",
                    isVisible: featureAppearance[0]
                )

                AuroraFeatureRow(
                    icon: "sparkles",
                    iconColor: Aurora.Colors.electric,
                    title: "Brain Dump",
                    subtitle: "Turn thoughts into organized tasks",
                    isVisible: featureAppearance[1]
                )

                AuroraFeatureRow(
                    icon: "trophy.fill",
                    iconColor: Aurora.Colors.gold,
                    title: "Gamification",
                    subtitle: "Earn XP and unlock achievements",
                    isVisible: featureAppearance[2]
                )
            }
            .crystallineCard()
            .padding(.horizontal, Aurora.Layout.screenPadding)

            Spacer()
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Awaken the orb
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            orbState = .aware
        }

        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            showContent = true
        }

        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(index) * 0.15) {
                withAnimation(Aurora.Animation.spring) {
                    featureAppearance[index] = true
                }
            }
        }
    }
}

// MARK: - Aurora Feature Row

struct AuroraFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: Aurora.Layout.spacing) {
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
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Aurora.Colors.success.opacity(0.8))
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

// MARK: - Aurora Goal Setup View

struct AuroraGoalSetupView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var orbState: OrbState
    @State private var showContent = false

    private let dailyOptions = [3, 5, 7, 10]
    private let weeklyOptions = [15, 25, 35, 50]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Aurora.Layout.spacingXL) {
                Spacer(minLength: 100)

                // Title
                VStack(spacing: Aurora.Layout.spacingSmall) {
                    Text("Set Your Ambitions")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    Text("How many tasks do you want to complete?")
                        .font(.system(size: 15))
                        .foregroundStyle(Aurora.Colors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Daily goal
                VStack(alignment: .leading, spacing: Aurora.Layout.spacing) {
                    Label("Daily Tasks", systemImage: "sun.max.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Aurora.Colors.electric)

                    HStack(spacing: Aurora.Layout.spacingSmall) {
                        ForEach(dailyOptions, id: \.self) { option in
                            AuroraGoalOption(
                                value: option,
                                isSelected: viewModel.dailyTaskGoal == option,
                                accentColor: Aurora.Colors.electric
                            ) {
                                orbState = .active
                                HapticsService.shared.selectionFeedback()
                                viewModel.dailyTaskGoal = option
                            }
                        }
                    }
                }
                .crystallineCard()
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Weekly goal
                VStack(alignment: .leading, spacing: Aurora.Layout.spacing) {
                    Label("Weekly Tasks", systemImage: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Aurora.Colors.cyan)

                    HStack(spacing: Aurora.Layout.spacingSmall) {
                        ForEach(weeklyOptions, id: \.self) { option in
                            AuroraGoalOption(
                                value: option,
                                isSelected: viewModel.weeklyTaskGoal == option,
                                accentColor: Aurora.Colors.cyan
                            ) {
                                orbState = .active
                                HapticsService.shared.selectionFeedback()
                                viewModel.weeklyTaskGoal = option
                            }
                        }
                    }
                }
                .crystallineCard()
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Pro tip
                HStack(spacing: Aurora.Layout.spacingSmall) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Aurora.Colors.gold)

                    Text("Start small and increase as you build momentum")
                        .font(.system(size: 13))
                        .foregroundStyle(Aurora.Colors.textTertiary)
                }
                .padding()
                .crystallineCard(padding: Aurora.Layout.spacing)
                .opacity(showContent ? 1 : 0)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Aurora.Layout.screenPadding)
        }
        .onAppear {
            withAnimation(Aurora.Animation.spring.delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Aurora Goal Option

struct AuroraGoalOption: View {
    let value: Int
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Aurora.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: Aurora.Radius.medium)
                        .fill(isSelected ? accentColor : Aurora.Colors.glassBase)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Aurora.Radius.medium)
                        .stroke(
                            isSelected ? accentColor : Aurora.Colors.glassBorder,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? accentColor.opacity(0.3) : Color.clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Aurora.Animation.quick, value: isPressed)
        .animation(Aurora.Animation.spring, value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Aurora Focus Areas View

struct AuroraFocusAreasView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var orbState: OrbState
    @State private var showContent = false

    private let columns = [
        GridItem(.flexible(), spacing: Aurora.Layout.spacing),
        GridItem(.flexible(), spacing: Aurora.Layout.spacing)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Aurora.Layout.spacingXL) {
                Spacer(minLength: 100)

                // Title
                VStack(spacing: Aurora.Layout.spacingSmall) {
                    Text("What Drives You?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    HStack(spacing: Aurora.Layout.spacingTiny) {
                        Text("Select your focus areas")
                            .font(.system(size: 15))
                            .foregroundStyle(Aurora.Colors.textSecondary)

                        if !viewModel.selectedFocusAreas.isEmpty {
                            Text("(\(viewModel.selectedFocusAreas.count) selected)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Aurora.Colors.electric)
                        }
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Focus areas grid
                LazyVGrid(columns: columns, spacing: Aurora.Layout.spacing) {
                    ForEach(FocusArea.allCases, id: \.self) { area in
                        AuroraFocusAreaCard(
                            area: area,
                            isSelected: viewModel.selectedFocusAreas.contains(area)
                        ) {
                            orbState = .active
                            HapticsService.shared.selectionFeedback()
                            if viewModel.selectedFocusAreas.contains(area) {
                                viewModel.selectedFocusAreas.remove(area)
                            } else {
                                viewModel.selectedFocusAreas.insert(area)
                            }
                        }
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Aurora.Layout.screenPadding)
        }
        .onAppear {
            withAnimation(Aurora.Animation.spring.delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Aurora Focus Area Card

struct AuroraFocusAreaCard: View {
    let area: FocusArea
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Aurora.Layout.spacingSmall) {
                // Icon circle
                ZStack {
                    SwiftUI.Circle()
                        .fill(isSelected ? area.color.opacity(0.2) : Aurora.Colors.cosmicElevated)
                        .frame(width: 56, height: 56)

                    if isSelected {
                        SwiftUI.Circle()
                            .stroke(area.color.opacity(0.5), lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }

                    Image(systemName: area.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isSelected ? area.color : Aurora.Colors.textSecondary)
                }

                Text(area.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Aurora.Colors.textPrimary : Aurora.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Aurora.Layout.spacing)
            .crystallineCard(isSelected: isSelected, accentColor: area.color, padding: Aurora.Layout.spacingSmall)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Aurora.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Aurora Permissions View

struct AuroraPermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var orbState: OrbState
    @State private var showContent = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Aurora.Layout.spacingXL) {
                Spacer(minLength: 100)

                // Title
                VStack(spacing: Aurora.Layout.spacingSmall) {
                    Text("Let Me Help You Best")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    Text("Enable features to maximize your productivity")
                        .font(.system(size: 15))
                        .foregroundStyle(Aurora.Colors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Permission toggles
                VStack(spacing: Aurora.Layout.spacing) {
                    AuroraToggleRow(
                        icon: "bell.badge.fill",
                        title: "Notifications",
                        description: "Get timely reminders for your tasks",
                        isOn: $viewModel.notificationsGranted
                    ) { granted in
                        if granted {
                            orbState = .success
                            Task {
                                await viewModel.requestNotifications()
                            }
                        } else {
                            orbState = .active
                        }
                    }

                    AuroraToggleRow(
                        icon: "calendar",
                        title: "Calendar Sync",
                        description: "Integrate tasks with your calendar",
                        isOn: $viewModel.calendarGranted
                    ) { granted in
                        if granted {
                            orbState = .success
                            Task {
                                await viewModel.requestCalendar()
                            }
                        } else {
                            orbState = .active
                        }
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Privacy note
                HStack(spacing: Aurora.Layout.spacingSmall) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Aurora.Colors.success)

                    Text("Your data stays on your device. We respect your privacy.")
                        .font(.system(size: 13))
                        .foregroundStyle(Aurora.Colors.textTertiary)
                }
                .padding()
                .crystallineCard(padding: Aurora.Layout.spacing)
                .opacity(showContent ? 1 : 0)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Aurora.Layout.screenPadding)
        }
        .onAppear {
            withAnimation(Aurora.Animation.spring.delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Aurora Complete View

struct AuroraCompleteView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var orbState: OrbState
    @State private var showContent = false
    @State private var showSummary = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: Aurora.Layout.spacingXL) {
            Spacer()

            // Celebration text
            VStack(spacing: Aurora.Layout.spacing) {
                Text("We're Ready Together!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Aurora.Colors.emerald],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Your AI companion is excited to help you succeed")
                    .font(.system(size: 16))
                    .foregroundStyle(Aurora.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .padding(.top, 140) // Extra space for celebration orb

            // Summary card
            VStack(spacing: Aurora.Layout.spacing) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Aurora.Colors.gold)
                    Text("Your Setup")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Aurora.Colors.textPrimary)
                    Spacer()
                }

                Rectangle()
                    .fill(Aurora.Colors.glassBorder)
                    .frame(height: 1)

                AuroraSummaryRow(icon: "sun.max.fill", iconColor: Aurora.Colors.electric, label: "Daily Goal", value: "\(viewModel.dailyTaskGoal) tasks")
                AuroraSummaryRow(icon: "calendar", iconColor: Aurora.Colors.cyan, label: "Weekly Goal", value: "\(viewModel.weeklyTaskGoal) tasks")
                AuroraSummaryRow(icon: "square.grid.2x2", iconColor: Aurora.Colors.violet, label: "Focus Areas", value: "\(viewModel.selectedFocusAreas.count) selected")
                AuroraSummaryRow(icon: "bell.fill", iconColor: Aurora.Colors.success, label: "Notifications", value: viewModel.notificationsGranted ? "Enabled" : "Disabled")
                AuroraSummaryRow(icon: "calendar.badge.checkmark", iconColor: Aurora.Colors.emerald, label: "Calendar Sync", value: viewModel.calendarGranted ? "Enabled" : "Disabled")
            }
            .crystallineCard(isSelected: true, accentColor: Aurora.Colors.success)
            .padding(.horizontal, Aurora.Layout.screenPadding)
            .opacity(showSummary ? 1 : 0)
            .offset(y: showSummary ? 0 : 30)

            Spacer()

            // Let's Go button
            Button {
                HapticsService.shared.celebration()
                viewModel.onComplete?()
            } label: {
                ZStack {
                    Capsule()
                        .fill(Aurora.Colors.success.opacity(0.3))
                        .blur(radius: 20)
                        .offset(y: 8)

                    HStack(spacing: Aurora.Layout.spacingSmall) {
                        Text("Let's Go!")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        LinearGradient(
                            colors: [Aurora.Colors.success, Aurora.Colors.emerald],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Aurora.Colors.success.opacity(0.4), radius: 15, y: 8)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Aurora.Layout.screenPadding)
            .padding(.bottom, Aurora.Layout.spacingXL)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 30)
        }
        .onAppear {
            startCelebration()
        }
    }

    private func startCelebration() {
        // Trigger celebration orb state
        orbState = .celebration

        withAnimation(Aurora.Animation.spring.delay(0.2)) {
            showContent = true
        }

        withAnimation(Aurora.Animation.spring.delay(0.5)) {
            showSummary = true
        }

        withAnimation(Aurora.Animation.spring.delay(0.9)) {
            showButton = true
        }

        HapticsService.shared.taskComplete()
    }
}

// MARK: - Aurora Summary Row

struct AuroraSummaryRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            HStack(spacing: Aurora.Layout.spacingSmall) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Aurora.Colors.textPrimary)
        }
    }
}

// MARK: - Legacy Views (Kept for compatibility)

struct FloatingOrb: View {
    let color: Color
    let size: CGFloat
    let position: CGPoint

    var body: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.4), color.opacity(0.2), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .position(position)
            .blur(radius: size / 4)
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView(viewModel: OnboardingViewModel())
        .environment(AppViewModel())
}
