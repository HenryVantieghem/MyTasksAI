//
//  CosmicOnboardingContainer.swift
//  Veloce
//
//  Cosmic Onboarding Container - Living Cosmos Design
//  A stunning 11-step celestial journey that creates an unforgettable first impression
//  Permission handling, feature showcases, goal setting, and trial information
//

import SwiftUI
import EventKit
import UserNotifications
import FamilyControls

// MARK: - Cosmic Onboarding Step

enum CosmicOnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case calendarPermission = 1
    case notificationPermission = 2
    case screenTimePermission = 3
    case featureTasks = 4
    case featureFocus = 5
    case featureMomentum = 6
    case featureAI = 7
    case goalSetup = 8
    case trialInfo = 9
    case readyToLaunch = 10

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .calendarPermission: return "Calendar"
        case .notificationPermission: return "Notifications"
        case .screenTimePermission: return "Screen Time"
        case .featureTasks: return "Tasks"
        case .featureFocus: return "Focus"
        case .featureMomentum: return "Momentum"
        case .featureAI: return "AI Oracle"
        case .goalSetup: return "Your Goal"
        case .trialInfo: return "Free Trial"
        case .readyToLaunch: return "Launch"
        }
    }

    var isPermission: Bool {
        switch self {
        case .calendarPermission, .notificationPermission, .screenTimePermission:
            return true
        default:
            return false
        }
    }

    var isFeature: Bool {
        switch self {
        case .featureTasks, .featureFocus, .featureMomentum, .featureAI:
            return true
        default:
            return false
        }
    }
}

// MARK: - Cosmic Onboarding Container

struct CosmicOnboardingContainer: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var viewModel: CosmicOnboardingViewModel

    @State private var currentStep: CosmicOnboardingStep = .welcome
    @State private var showContent = false
    @State private var starfieldOffset: CGFloat = 0
    @State private var nebulaPhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : Theme.Spacing.lg
    }

    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 600 : .infinity
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated starfield background
                CosmicOnboardingBackground(
                    phase: nebulaPhase,
                    productivity: currentStep == .readyToLaunch ? .productive : .neutral
                )

                VStack(spacing: 0) {
                    // Top bar with skip and progress
                    topBar
                        .padding(.top, Theme.Spacing.md)

                    // Main content area
                    TabView(selection: $currentStep) {
                        // Page 1: Welcome
                        CosmicWelcomePage(
                            userName: viewModel.userName,
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.welcome)

                        // Page 2: Calendar Permission
                        CosmicPermissionPage(
                            type: .calendar,
                            isGranted: viewModel.calendarGranted,
                            onAllow: { await viewModel.requestCalendarPermission() },
                            onSkip: { nextStep() },
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.calendarPermission)

                        // Page 3: Notification Permission
                        CosmicPermissionPage(
                            type: .notifications,
                            isGranted: viewModel.notificationsGranted,
                            onAllow: { await viewModel.requestNotificationPermission() },
                            onSkip: { nextStep() },
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.notificationPermission)

                        // Page 4: Screen Time Permission
                        CosmicPermissionPage(
                            type: .screenTime,
                            isGranted: viewModel.screenTimeGranted,
                            onAllow: { await viewModel.requestScreenTimePermission() },
                            onSkip: { nextStep() },
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.screenTimePermission)

                        // Page 5: Feature - Tasks
                        CosmicFeaturePage(
                            feature: .tasks,
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.featureTasks)

                        // Page 6: Feature - Focus
                        CosmicFeaturePage(
                            feature: .focus,
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.featureFocus)

                        // Page 7: Feature - Momentum
                        CosmicFeaturePage(
                            feature: .momentum,
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.featureMomentum)

                        // Page 8: Feature - AI
                        CosmicFeaturePage(
                            feature: .ai,
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.featureAI)

                        // Page 9: Goal Setup
                        CosmicGoalSetupPage(
                            viewModel: viewModel,
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.goalSetup)

                        // Page 10: Free Trial Info
                        CosmicTrialInfoPage(
                            onContinue: { nextStep() }
                        )
                        .tag(CosmicOnboardingStep.trialInfo)

                        // Page 11: Ready to Launch
                        CosmicLaunchPage(
                            userName: viewModel.userName,
                            goalSummary: viewModel.goalSummary,
                            onLaunch: {
                                HapticsService.shared.celebration()
                                viewModel.completeOnboarding()
                            }
                        )
                        .tag(CosmicOnboardingStep.readyToLaunch)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(LivingCosmos.Animations.portalOpen, value: currentStep)
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

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Back button (hidden on first page)
            if currentStep != .welcome {
                Button {
                    previousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer().frame(width: 44)
            }

            Spacer()

            // Progress dots
            progressDots

            Spacer()

            // Skip button (hidden on last page)
            if currentStep != .readyToLaunch {
                Button {
                    skipToEnd()
                } label: {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }
                .frame(width: 44)
            } else {
                Spacer().frame(width: 44)
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(CosmicOnboardingStep.allCases) { step in
                progressDot(for: step)
            }
        }
    }

    private func progressDot(for step: CosmicOnboardingStep) -> some View {
        let isComplete = step.rawValue < currentStep.rawValue
        let isCurrent = step == currentStep

        return ZStack {
            if isCurrent {
                // Glow
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.5))
                    .frame(width: 16, height: 16)
                    .blur(radius: 4)
            }

            SwiftUI.Circle()
                .fill(dotColor(isComplete: isComplete, isCurrent: isCurrent))
                .frame(width: isCurrent ? 10 : 6, height: isCurrent ? 10 : 6)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 5, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .animation(LivingCosmos.Animations.spring, value: currentStep)
    }

    private func dotColor(isComplete: Bool, isCurrent: Bool) -> Color {
        if isComplete {
            return Theme.CelestialColors.auroraGreen
        } else if isCurrent {
            return Theme.Colors.aiPurple
        } else {
            return Theme.CelestialColors.starGhost.opacity(0.4)
        }
    }

    // MARK: - Navigation

    private func nextStep() {
        HapticsService.shared.impact()
        let allSteps = CosmicOnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            withAnimation(LivingCosmos.Animations.portalOpen) {
                currentStep = allSteps[currentIndex + 1]
            }
        }
    }

    private func previousStep() {
        HapticsService.shared.lightImpact()
        let allSteps = CosmicOnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            withAnimation(LivingCosmos.Animations.spring) {
                currentStep = allSteps[currentIndex - 1]
            }
        }
    }

    private func skipToEnd() {
        HapticsService.shared.lightImpact()
        withAnimation(LivingCosmos.Animations.portalOpen) {
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
    }
}

// MARK: - Cosmic Onboarding Background

struct CosmicOnboardingBackground: View {
    let phase: CGFloat
    let productivity: VoidBackground.ProductivityLevel

    @State private var stars: [CosmicStar] = []
    @State private var twinklePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

                // Dynamic nebula layers
                NebulaCloud(
                    colors: productivity.nebulaColors,
                    position: UnitPoint(x: 0.3, y: 0.2),
                    radius: 300,
                    phase: phase,
                    intensity: productivity.intensity
                )

                NebulaCloud(
                    colors: [
                        Theme.Colors.aiPurple.opacity(0.08),
                        Theme.CelestialColors.plasmaCore.opacity(0.04),
                        Color.clear
                    ],
                    position: UnitPoint(x: 0.7, y: 0.7),
                    radius: 250,
                    phase: phase * 0.7,
                    intensity: 0.06
                )

                // Star field
                cosmicStarField(in: geometry)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            regenerateStars()
            startAnimations()
        }
    }

    private func cosmicStarField(in geometry: GeometryProxy) -> some View {
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

                let starColor: Color
                switch star.starType {
                case .bright:
                    starColor = Color.white.opacity(opacity)
                case .plasma:
                    starColor = Theme.CelestialColors.plasmaCore.opacity(opacity * 0.8)
                case .nebula:
                    starColor = Theme.CelestialColors.nebulaEdge.opacity(opacity * 0.6)
                case .dim:
                    starColor = Theme.CelestialColors.starDim.opacity(opacity)
                }

                context.fill(
                    SwiftUI.Circle().path(in: rect),
                    with: .color(starColor)
                )

                if star.size > 2 && !reduceMotion {
                    let glowRect = CGRect(
                        x: star.position.x - star.size,
                        y: star.position.y - star.size,
                        width: star.size * 2,
                        height: star.size * 2
                    )
                    context.fill(
                        SwiftUI.Circle().path(in: glowRect),
                        with: .color(starColor.opacity(0.2))
                    )
                }
            }
        }
    }

    private func regenerateStars() {
        // Use a reasonable default size for star field
        let size = CGSize(width: 400, height: 800)
        stars = CosmicStar.generateField(count: 40, in: size)
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            twinklePhase = .pi * 2
        }
    }
}

// MARK: - Preview

#Preview {
    CosmicOnboardingContainer(viewModel: CosmicOnboardingViewModel())
        .environment(AppViewModel())
}
