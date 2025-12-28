//
//  LiquidGlassOnboardingContainer.swift
//  Veloce
//
//  Ultra-Premium Liquid Glass Onboarding Container
//  An award-winning 11-step journey featuring iOS 26 Liquid Glass effects,
//  constellation progress navigation, prismatic transitions, and premium haptics.
//

import SwiftUI
import EventKit
import UserNotifications
import FamilyControls

// MARK: - Liquid Glass Onboarding Container

struct LiquidGlassOnboardingContainer: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var viewModel: CosmicOnboardingViewModel

    // Glass morphing namespace
    @Namespace private var onboardingNamespace

    @State private var currentStep: CosmicOnboardingStep = .welcome
    @State private var showContent = false
    @State private var nebulaPhase: CGFloat = 0
    @State private var glassShimmerOffset: CGFloat = -300
    @State private var transitionDirection: Int = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : Theme.Spacing.lg
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium animated background
                LiquidGlassOnboardingBackground(
                    phase: nebulaPhase,
                    currentStep: currentStep
                )

                // Glass shimmer overlay
                glassShimmerLayer(in: geometry)

                VStack(spacing: 0) {
                    // Liquid Glass top bar
                    liquidGlassTopBar
                        .padding(.top, Theme.Spacing.md)

                    // Main content with glass transitions
                    TabView(selection: $currentStep) {
                        // Page 1: Welcome
                        LiquidGlassWelcomePage(
                            userName: viewModel.userName,
                            namespace: onboardingNamespace,
                            onContinue: { advanceToNext() }
                        )
                        .tag(CosmicOnboardingStep.welcome)

                        // Pages 2-4: Permissions with glass toggle rows
                        ForEach([
                            (CosmicOnboardingStep.calendarPermission, OnboardingPermissionType.calendar, viewModel.calendarGranted, { await viewModel.requestCalendarPermission() }),
                            (CosmicOnboardingStep.notificationPermission, OnboardingPermissionType.notifications, viewModel.notificationsGranted, { await viewModel.requestNotificationPermission() }),
                            (CosmicOnboardingStep.screenTimePermission, OnboardingPermissionType.screenTime, viewModel.screenTimeGranted, { await viewModel.requestScreenTimePermission() })
                        ], id: \.0) { step, type, granted, request in
                            LiquidGlassPermissionPage(
                                type: type,
                                isGranted: granted,
                                namespace: onboardingNamespace,
                                onAllow: request,
                                onSkip: { advanceToNext() },
                                onContinue: { advanceToNext() }
                            )
                            .tag(step)
                        }

                        // Pages 5-8: Feature showcases with glass cards
                        ForEach([
                            (CosmicOnboardingStep.featureTasks, OnboardingFeatureType.tasks),
                            (CosmicOnboardingStep.featureFocus, OnboardingFeatureType.focus),
                            (CosmicOnboardingStep.featureMomentum, OnboardingFeatureType.momentum),
                            (CosmicOnboardingStep.featureAI, OnboardingFeatureType.ai)
                        ], id: \.0) { step, feature in
                            LiquidGlassFeaturePage(
                                feature: feature,
                                namespace: onboardingNamespace,
                                onContinue: { advanceToNext() }
                            )
                            .tag(step)
                        }

                        // Page 9: Goal Setup with glass cards
                        LiquidGlassGoalSetupPage(
                            viewModel: viewModel,
                            namespace: onboardingNamespace,
                            onContinue: { advanceToNext() }
                        )
                        .tag(CosmicOnboardingStep.goalSetup)

                        // Page 10: Trial Info
                        LiquidGlassTrialInfoPage(
                            namespace: onboardingNamespace,
                            onContinue: { advanceToNext() }
                        )
                        .tag(CosmicOnboardingStep.trialInfo)

                        // Page 11: Launch
                        LiquidGlassLaunchPage(
                            userName: viewModel.userName,
                            goalSummary: viewModel.goalSummary,
                            namespace: onboardingNamespace,
                            onLaunch: {
                                HapticsService.shared.onboardingComplete()
                                viewModel.completeOnboarding()
                            }
                        )
                        .tag(CosmicOnboardingStep.readyToLaunch)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(LiquidGlassDesignSystem.Springs.focus, value: currentStep)
                }
            }
        }
        .onAppear {
            startBackgroundAnimations()
        }
        .task {
            viewModel.onComplete = {
                Task {
                    await appViewModel.checkAuthenticationState()
                }
            }
        }
    }

    // MARK: - Glass Shimmer Layer

    private func glassShimmerLayer(in geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.06),
                        LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.04),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 200, height: geometry.size.height)
            .blur(radius: 40)
            .offset(x: glassShimmerOffset)
            .opacity(0.5)
    }

    // MARK: - Liquid Glass Top Bar

    private var liquidGlassTopBar: some View {
        HStack {
            // Back button with glass effect
            if currentStep != .welcome {
                Button {
                    goToPrevious()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                }
                .liquidGlassInteractive()
                .clipShape(Circle())
                .transition(.scale.combined(with: .opacity))
            } else {
                Spacer().frame(width: 40)
            }

            Spacer()

            // Glass Constellation Progress
            GlassConstellationProgress(
                steps: CosmicOnboardingStep.allCases,
                currentStep: currentStep,
                namespace: onboardingNamespace
            )

            Spacer()

            // Skip button with glass effect
            if currentStep != .readyToLaunch {
                Button {
                    skipToLaunch()
                } label: {
                    Text("Skip")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .liquidGlassInteractive()
                .clipShape(Capsule())
            } else {
                Spacer().frame(width: 40)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .animation(LiquidGlassDesignSystem.Springs.ui, value: currentStep)
    }

    // MARK: - Navigation

    private func advanceToNext() {
        HapticsService.shared.pageTransition()
        transitionDirection = 1

        let allSteps = CosmicOnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            withAnimation(LiquidGlassDesignSystem.Springs.focus) {
                currentStep = allSteps[currentIndex + 1]
            }
        }
    }

    private func goToPrevious() {
        HapticsService.shared.lightImpact()
        transitionDirection = -1

        let allSteps = CosmicOnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                currentStep = allSteps[currentIndex - 1]
            }
        }
    }

    private func skipToLaunch() {
        HapticsService.shared.glassMorph()
        withAnimation(LiquidGlassDesignSystem.Springs.focus) {
            currentStep = .readyToLaunch
        }
    }

    // MARK: - Background Animations

    private func startBackgroundAnimations() {
        guard !reduceMotion else { return }

        // Nebula drift
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            nebulaPhase = 1
        }

        // Glass shimmer sweep (use fixed large value for shimmer destination)
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: false)) {
            glassShimmerOffset = 700
        }
    }
}

// MARK: - Onboarding Permission Type (distinct from CosmicPermissionPage.PermissionType)

enum OnboardingPermissionType {
    case calendar
    case notifications
    case screenTime

    var title: String {
        switch self {
        case .calendar: return "Calendar Access"
        case .notifications: return "Stay on Track"
        case .screenTime: return "Focus Mode"
        }
    }

    var subtitle: String {
        switch self {
        case .calendar: return "Sync your schedule for smart task planning"
        case .notifications: return "Get timely reminders and celebrations"
        case .screenTime: return "Block distractions during focus sessions"
        }
    }

    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .notifications: return "bell.badge.fill"
        case .screenTime: return "hourglass"
        }
    }

    var color: Color {
        switch self {
        case .calendar: return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        case .notifications: return LiquidGlassDesignSystem.VibrantAccents.solarGold
        case .screenTime: return LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
        }
    }
}

// MARK: - Onboarding Feature Type (distinct from CosmicFeaturePage.FeatureType)

enum OnboardingFeatureType {
    case tasks
    case focus
    case momentum
    case ai

    var title: String {
        switch self {
        case .tasks: return "Smart Tasks"
        case .focus: return "Deep Focus"
        case .momentum: return "Momentum"
        case .ai: return "AI Oracle"
        }
    }

    var subtitle: String {
        switch self {
        case .tasks: return "Effortlessly organize your day with AI-powered task management"
        case .focus: return "Enter flow state with distraction-free focus sessions"
        case .momentum: return "Track your progress and build unstoppable habits"
        case .ai: return "Your intelligent productivity companion"
        }
    }

    var icon: String {
        switch self {
        case .tasks: return "checkmark.circle.fill"
        case .focus: return "brain.head.profile"
        case .momentum: return "chart.line.uptrend.xyaxis"
        case .ai: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .tasks: return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        case .focus: return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        case .momentum: return LiquidGlassDesignSystem.VibrantAccents.solarGold
        case .ai: return LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
        }
    }
}

// MARK: - Liquid Glass Onboarding Background

struct LiquidGlassOnboardingBackground: View {
    let phase: CGFloat
    let currentStep: CosmicOnboardingStep

    @State private var stars: [CosmicStar] = []
    @State private var twinklePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stepColor: Color {
        switch currentStep {
        case .welcome:
            return LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
        case .calendarPermission, .notificationPermission, .screenTimePermission:
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        case .featureTasks, .featureFocus, .featureMomentum, .featureAI:
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        case .goalSetup:
            return LiquidGlassDesignSystem.VibrantAccents.solarGold
        case .trialInfo:
            return LiquidGlassDesignSystem.VibrantAccents.nebulaPink
        case .readyToLaunch:
            return LiquidGlassDesignSystem.VibrantAccents.cosmicBlue
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep void gradient
                LinearGradient(
                    colors: [
                        Theme.CelestialColors.voidDeep,
                        Theme.CelestialColors.void,
                        Theme.CelestialColors.abyss
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Dynamic step-colored nebula
                RadialGradient(
                    colors: [
                        stepColor.opacity(0.15),
                        stepColor.opacity(0.08),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5 + phase * 0.15, y: 0.3),
                    startRadius: 50,
                    endRadius: 350
                )
                .blur(radius: 60)
                .animation(LiquidGlassDesignSystem.Springs.focus, value: currentStep)

                // Secondary nebula
                RadialGradient(
                    colors: [
                        LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.08),
                        LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.04),
                        .clear
                    ],
                    center: UnitPoint(x: 0.3 - phase * 0.1, y: 0.7),
                    startRadius: 30,
                    endRadius: 250
                )
                .blur(radius: 50)

                // Star field
                starField(in: geometry)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            regenerateStars()
            startAnimations()
        }
    }

    private func starField(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            for star in stars {
                let twinkle = reduceMotion ? 1.0 : sin(twinklePhase + star.twinkleDelay * .pi) * 0.5 + 0.5
                let opacity = star.baseOpacity * (0.5 + twinkle * 0.5)

                let rect = CGRect(
                    x: star.position.x - star.size / 2,
                    y: star.position.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )

                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
    }

    private func regenerateStars() {
        let size = CGSize(width: 400, height: 800)
        stars = CosmicStar.generateField(count: 35, in: size)
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            twinklePhase = .pi * 2
        }
    }
}

// MARK: - Placeholder Pages (To be fully implemented)

struct LiquidGlassWelcomePage: View {
    let userName: String
    let namespace: Namespace.ID
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Hero orb with glass halo
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)

                EtherealOrb(
                    size: .large,
                    state: .active,
                    isAnimating: true,
                    intensity: 1.0,
                    showGlow: true
                )
                .matchedGeometryEffect(id: "welcomeOrb", in: namespace)
            }

            VStack(spacing: 16) {
                Text(userName.isEmpty ? "Welcome" : "Welcome, \(userName)")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white)

                Text("Your journey to peak productivity begins now")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            // CTA Button
            LiquidGlassButton.primary(
                title: "Begin Journey",
                icon: "arrow.right",
                action: onContinue
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct LiquidGlassPermissionPage: View {
    let type: OnboardingPermissionType
    let isGranted: Bool
    let namespace: Namespace.ID
    let onAllow: () async -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Permission icon with glass container
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(type.color.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: type.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(type.color)
            }

            VStack(spacing: 12) {
                Text(type.title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)

                Text(type.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                if isGranted {
                    // Already granted
                    LiquidGlassButton.success(
                        title: "Enabled",
                        icon: "checkmark",
                        action: onContinue
                    )
                } else {
                    // Request permission
                    LiquidGlassButton.primary(
                        title: "Allow Access",
                        icon: nil,
                        action: {
                            Task { await onAllow() }
                        }
                    )

                    Button("Maybe Later") {
                        onSkip()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct LiquidGlassFeaturePage: View {
    let feature: OnboardingFeatureType
    let namespace: Namespace.ID
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Feature icon with animated glass container
            ZStack {
                // Animated rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(feature.color.opacity(0.2 - Double(i) * 0.05), lineWidth: 1)
                        .frame(width: 140 + CGFloat(i) * 30, height: 140 + CGFloat(i) * 30)
                }

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [feature.color.opacity(0.4), feature.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )

                Image(systemName: feature.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(feature.color)
            }

            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)

                Text(feature.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            LiquidGlassButton.primary(
                title: "Continue",
                icon: "arrow.right",
                action: onContinue
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct LiquidGlassGoalSetupPage: View {
    @Bindable var viewModel: CosmicOnboardingViewModel
    let namespace: Namespace.ID
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Set Your Goal")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 32)

                Text("What would you like to achieve?")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))

                // Goal category selection
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(OnboardingGoalCategory.allCases) { category in
                        GoalCategoryCard(
                            category: category,
                            isSelected: viewModel.selectedCategory == category,
                            onTap: {
                                HapticsService.shared.glassFocus()
                                viewModel.selectedCategory = category
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 100)

                if viewModel.canProceedFromGoal {
                    LiquidGlassButton.primary(
                        title: "Continue",
                        icon: "arrow.right",
                        action: onContinue
                    )
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 48)
        }
    }
}

struct GoalCategoryCard: View {
    let category: OnboardingGoalCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? category.color : .white.opacity(0.6))

                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? category.color.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct LiquidGlassTrialInfoPage: View {
    let namespace: Namespace.ID
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Trial badge
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        LiquidGlassDesignSystem.VibrantAccents.solarGold.opacity(0.5),
                                        LiquidGlassDesignSystem.VibrantAccents.nebulaPink.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                VStack(spacing: 4) {
                    Text("7")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.solarGold)
                    Text("DAYS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            VStack(spacing: 12) {
                Text("Free Trial")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Experience all premium features free for 7 days. Cancel anytime.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            LiquidGlassButton.primary(
                title: "Start Free Trial",
                icon: "sparkles",
                action: onContinue
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct LiquidGlassLaunchPage: View {
    let userName: String
    let goalSummary: String
    let namespace: Namespace.ID
    let onLaunch: () -> Void

    @State private var showCelebration = false
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Launch portal rings
            ZStack {
                ForEach(0..<4) { i in
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    LiquidGlassDesignSystem.VibrantAccents.cosmicBlue.opacity(0.4),
                                    LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.3),
                                    LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.4)
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120 + CGFloat(i) * 35, height: 120 + CGFloat(i) * 35)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity - Double(i) * 0.15)
                }

                Image(systemName: "rocket.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.cosmicBlue)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    ringScale = 1.0
                    ringOpacity = 1.0
                }
            }

            VStack(spacing: 12) {
                Text("Ready for Liftoff")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Your productivity journey awaits, \(userName.isEmpty ? "Explorer" : userName)")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            LiquidGlassButton.primary(
                title: "Launch",
                icon: "arrow.up.forward",
                action: onLaunch
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Preview

#Preview {
    LiquidGlassOnboardingContainer(viewModel: CosmicOnboardingViewModel())
        .environment(AppViewModel())
}
