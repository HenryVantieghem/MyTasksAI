//
//  LiquidGlassOnboardingContainer.swift
//  Veloce
//
//  Utopian Design System - Onboarding Journey
//  "Ascending Through the Utopian Nebula"
//  An award-winning 11-step portal journey with flowing Utopian waves,
//  firefly particles, prismatic transitions, and cosmic sounds.
//

import SwiftUI
import EventKit
import UserNotifications
import FamilyControls

// MARK: - Utopian Onboarding Container

struct LiquidGlassOnboardingContainer: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.responsiveLayout) private var layout
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var viewModel: CosmicOnboardingViewModel

    // Glass morphing namespace
    @Namespace private var onboardingNamespace

    @State private var currentStep: CosmicOnboardingStep = .welcome
    @State private var showContent = false
    @State private var nebulaPhase: CGFloat = 0
    @State private var glassShimmerOffset: CGFloat = -300
    @State private var transitionDirection: Int = 1

    // Utopian state
    @State private var auroraIntensity: CGFloat = 0.25
    @State private var showPortalEffect = false
    @State private var portalScale: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Use ResponsiveLayout for horizontal padding
    private var horizontalPadding: CGFloat {
        layout.screenPadding
    }

    // Utopian colors per step (ascending through the nebula)
    private var stepAuroraColors: [Color] {
        switch currentStep {
        case .welcome:
            return [UtopianDesignFallback.Colors.aiPurple.opacity(0.5)]
        case .calendarPermission:
            return [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple]
        case .notificationPermission:
            return [UtopianDesignFallback.Gamification.starGold, UtopianDesignFallback.Colors.focusActive]
        case .screenTimePermission:
            return [UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.aiPurple]
        case .featureTasks:
            return [UtopianDesignFallback.Colors.completed, UtopianDesignFallback.Colors.focusActive]
        case .featureFocus:
            return [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple.opacity(0.8)]
        case .featureMomentum:
            return [UtopianDesignFallback.Gamification.starGold, UtopianDesignFallback.Colors.aiPurple]
        case .featureAI:
            return [UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.focusActive]
        case .goalSetup:
            return [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed]
        case .trialInfo:
            return [UtopianDesignFallback.Gamification.starGold, UtopianDesignFallback.Colors.completed]
        case .readyToLaunch:
            return [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed]
        }
    }

    // Utopian intensity increases as user progresses
    private var stepIntensity: CGFloat {
        let progress = CGFloat(CosmicOnboardingStep.allCases.firstIndex(of: currentStep) ?? 0)
        let total = CGFloat(CosmicOnboardingStep.allCases.count - 1)
        return 0.2 + (progress / total) * 0.5
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Utopian animated wave background
                AuroraAnimatedWaveBackground(
                    intensity: stepIntensity,
                    showParticles: true,
                    customColors: stepAuroraColors
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)

                // Firefly constellation overlay
                if !reduceMotion {
                    AuroraFireflyField(
                        count: 25,
                        colors: stepAuroraColors
                    )
                    .opacity(0.6)
                }

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
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
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

    // MARK: - Utopian Glass Shimmer Layer

    private func glassShimmerLayer(in geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        UtopianDesignFallback.Colors.focusActive.opacity(0.08),
                        UtopianDesignFallback.Colors.aiPurple.opacity(0.06),
                        UtopianDesignFallback.Colors.aiPurple.opacity(0.04),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: layout.heroOrbSize * 0.9, height: geometry.size.height)
            .blur(radius: 50)
            .offset(x: glassShimmerOffset)
            .opacity(0.6)
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
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: layout.minTouchTarget, height: layout.minTouchTarget)
                }
                .background {
                    if #available(iOS 26.0, *) {
                        Color.clear.glassEffect(.regular.interactive(true), in: Circle())
                    } else {
                        Circle().fill(.ultraThinMaterial)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Spacer().frame(width: layout.minTouchTarget)
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
                        .dynamicTypeFont(base: 13, weight: .medium)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, layout.spacing)
                        .padding(.vertical, layout.spacing / 2)
                }
                .background {
                    if #available(iOS 26.0, *) {
                        Color.clear.glassEffect(.regular.interactive(true), in: Capsule())
                    } else {
                        Capsule().fill(.ultraThinMaterial)
                    }
                }
            } else {
                Spacer().frame(width: layout.minTouchTarget)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
    }

    // MARK: - Utopian Navigation

    private func advanceToNext() {
        // Utopian feedback: cosmic whoosh + haptic
        AuroraSoundEngine.shared.play(.tabSwitch)
        HapticsService.shared.impact(.light)
        transitionDirection = 1

        let allSteps = CosmicOnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                currentStep = allSteps[currentIndex + 1]
            }
        }
    }

    private func goToPrevious() {
        AuroraSoundEngine.shared.play(.dismiss)
        HapticsService.shared.selectionFeedback()
        transitionDirection = -1

        let allSteps = CosmicOnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                currentStep = allSteps[currentIndex - 1]
            }
        }
    }

    private func skipToLaunch() {
        // Portal jump effect
        AuroraSoundEngine.shared.portalOpen()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
        case .calendar: return UtopianDesignFallback.Colors.focusActive
        case .notifications: return UtopianDesignFallback.Gamification.starGold
        case .screenTime: return UtopianDesignFallback.Colors.aiPurple
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
        case .tasks: return UtopianDesignFallback.Colors.completed
        case .focus: return UtopianDesignFallback.Colors.focusActive
        case .momentum: return UtopianDesignFallback.Gamification.starGold
        case .ai: return UtopianDesignFallback.Colors.aiPurple
        }
    }
}

// MARK: - Utopian Onboarding Background (Legacy - kept for reference)

struct LiquidGlassOnboardingBackground: View {
    let phase: CGFloat
    let currentStep: CosmicOnboardingStep

    @State private var stars: [CosmicStar] = []
    @State private var twinklePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stepColor: Color {
        switch currentStep {
        case .welcome:
            return UtopianDesignFallback.Colors.aiPurple
        case .calendarPermission, .notificationPermission, .screenTimePermission:
            return UtopianDesignFallback.Colors.focusActive
        case .featureTasks, .featureFocus, .featureMomentum, .featureAI:
            return UtopianDesignFallback.Colors.completed
        case .goalSetup:
            return UtopianDesignFallback.Gamification.starGold
        case .trialInfo:
            return UtopianDesignFallback.Colors.aiPurple
        case .readyToLaunch:
            return UtopianDesignFallback.Colors.aiPurple.opacity(0.8)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Utopian void gradient
                UtopianGradients.background(for: Date())

                // Dynamic step-colored nebula
                RadialGradient(
                    colors: [
                        stepColor.opacity(0.18),
                        stepColor.opacity(0.08),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5 + phase * 0.15, y: 0.3),
                    startRadius: 50,
                    endRadius: 350
                )
                .blur(radius: 60)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)

                // Secondary Utopian nebula
                RadialGradient(
                    colors: [
                        UtopianDesignFallback.Colors.aiPurple.opacity(0.1),
                        UtopianDesignFallback.Colors.focusActive.opacity(0.05),
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
                    with: .color(Color.white.opacity(opacity))
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

    @State private var orbPulse: CGFloat = 1.0
    @State private var haloRotation: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.xl) {
            Spacer()

            // Aurora Hero Orb with prismatic halo
            ZStack {
                // Multi-layer aurora halo
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    UtopianDesignFallback.Colors.aiPurple.opacity(0.3 - Double(i) * 0.08),
                                    UtopianDesignFallback.Colors.focusActive.opacity(0.25 - Double(i) * 0.06),
                                    UtopianDesignFallback.Colors.aiPurple.opacity(0.2 - Double(i) * 0.05),
                                    UtopianDesignFallback.Colors.aiPurple.opacity(0.3 - Double(i) * 0.08)
                                ],
                                center: .center,
                                startAngle: .degrees(haloRotation + Double(i) * 40),
                                endAngle: .degrees(haloRotation + 360 + Double(i) * 40)
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 160 + CGFloat(i) * 35, height: 160 + CGFloat(i) * 35)
                        .blur(radius: CGFloat(i) * 2)
                }

                // Outer bloom
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                UtopianDesignFallback.Colors.aiPurple.opacity(0.35),
                                UtopianDesignFallback.Colors.focusActive.opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 30)
                    .scaleEffect(orbPulse)

                // The EtherealOrb
                EtherealOrb(
                    size: .large,
                    state: .active,
                    isAnimating: true,
                    intensity: 1.0,
                    showGlow: true
                )
                .scaleEffect(orbPulse)
                .matchedGeometryEffect(id: "welcomeOrb", in: namespace)
            }

            VStack(spacing: UtopianDesignFallback.Spacing.md) {
                Text(userName.isEmpty ? "Welcome" : "Welcome, \(userName)")
                    .font(UtopianDesignFallback.Typography.display)
                    .foregroundStyle(.white)

                Text("Your journey to peak productivity begins now")
                    .font(UtopianDesignFallback.Typography.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, UtopianDesignFallback.Spacing.xl)
            .opacity(contentOpacity)
            .offset(y: contentOffset)

            Spacer()

            // Aurora CTA Button with prismatic glow
            Button {
                AuroraSoundEngine.shared.play(.taskComplete)
                HapticsService.shared.impact(.medium)
                onContinue()
            } label: {
                HStack(spacing: 12) {
                    Text("Begin Journey")
                        .dynamicTypeFont(base: 17, weight: .semibold)
                    Image(systemName: "arrow.right")
                        .dynamicTypeFont(base: 15, weight: .semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: UtopianDesignFallback.Colors.focusActive.opacity(0.4), radius: 12, y: 4)
            }
            .clipShape(Capsule())
            .padding(.horizontal, UtopianDesignFallback.Spacing.xl)
            .padding(.bottom, UtopianDesignFallback.Spacing.xxl)
            .opacity(contentOpacity)
        }
        .onAppear {
            startWelcomeAnimations()
        }
    }

    private func startWelcomeAnimations() {
        guard !reduceMotion else {
            contentOpacity = 1
            contentOffset = 0
            return
        }

        // Content fade in
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            contentOpacity = 1
            contentOffset = 0
        }

        // Orb breathing pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            orbPulse = 1.03
        }

        // Halo rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            haloRotation = 360
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
                if #available(iOS 26.0, *) {
                    Color.clear
                        .frame(width: 120, height: 120)
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(type.color.opacity(0.3), lineWidth: 1)
                        }
                } else {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .overlay {
                            Circle()
                                .stroke(type.color.opacity(0.3), lineWidth: 1)
                        }
                }

                Image(systemName: type.icon)
                    .dynamicTypeFont(base: 48)
                    .foregroundStyle(type.color)
            }

            VStack(spacing: 12) {
                Text(type.title)
                    .dynamicTypeFont(base: 28, weight: .semibold)
                    .foregroundStyle(.white)

                Text(type.subtitle)
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                if isGranted {
                    // Already granted
                    LiquidGlassButton.success(
                        "Enabled",
                        icon: "checkmark",
                        action: onContinue
                    )
                } else {
                    // Request permission
                    LiquidGlassButton.primary(
                        "Allow Access",
                        icon: nil,
                        action: {
                            Task { await onAllow() }
                        }
                    )

                    Button("Maybe Later") {
                        onSkip()
                    }
                    .dynamicTypeFont(base: 14, weight: .medium)
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

                // Native iOS 26 Liquid Glass or fallback
                if #available(iOS 26.0, *) {
                    Color.clear
                        .frame(width: 120, height: 120)
                        .glassEffect(
                            .regular.tint(feature.color.opacity(0.1)),
                            in: Circle()
                        )
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [feature.color.opacity(0.4), feature.color.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                } else {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [feature.color.opacity(0.4), feature.color.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                }

                Image(systemName: feature.icon)
                    .dynamicTypeFont(base: 48)
                    .foregroundStyle(feature.color)
            }

            VStack(spacing: 12) {
                Text(feature.title)
                    .dynamicTypeFont(base: 28, weight: .semibold)
                    .foregroundStyle(.white)

                Text(feature.subtitle)
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            LiquidGlassButton.primary(
                "Continue",
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
                    .dynamicTypeFont(base: 28, weight: .semibold)
                    .foregroundStyle(.white)
                    .padding(.top, 32)

                Text("What would you like to achieve?")
                    .dynamicTypeFont(base: 16)
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
                        "Continue",
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
                    .dynamicTypeFont(base: 28)
                    .foregroundStyle(isSelected ? category.color : .white.opacity(0.6))

                Text(category.rawValue)
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
        }
        .buttonStyle(.plain)
        .background {
            let shape = RoundedRectangle(cornerRadius: 16)
            
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(
                        isSelected ? .regular.tint(category.color.opacity(0.2)).interactive(true) : .regular,
                        in: shape
                    )
                    .overlay {
                        shape.stroke(
                            isSelected ? category.color.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                    }
            } else {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if isSelected {
                        shape.fill(category.color.opacity(0.1))
                    }
                }
                .overlay {
                    shape.stroke(
                        isSelected ? category.color.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 0.5
                    )
                }
            }
        }
    }
}

struct LiquidGlassTrialInfoPage: View {
    let namespace: Namespace.ID
    let onContinue: () -> Void

    @State private var badgeGlow: CGFloat = 0.4
    @State private var badgeRotation: Double = 0
    @State private var showSparkles = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.xl) {
            Spacer()

            // Aurora Trial Badge with prismatic glow
            ZStack {
                // Outer glow bloom
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                UtopianDesignFallback.Gamification.starGold.opacity(badgeGlow * 0.5),
                                UtopianDesignFallback.Colors.aiPurple.opacity(badgeGlow * 0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 30)

                // Rotating prismatic ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                UtopianDesignFallback.Gamification.starGold.opacity(0.5),
                                UtopianDesignFallback.Colors.aiPurple.opacity(0.3),
                                UtopianDesignFallback.Colors.completed.opacity(0.4),
                                UtopianDesignFallback.Gamification.starGold.opacity(0.5)
                            ],
                            center: .center,
                            startAngle: .degrees(badgeRotation),
                            endAngle: .degrees(badgeRotation + 360)
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)

                // Glass badge
                Group {
                    if #available(iOS 26.0, *) {
                        Color.clear
                            .frame(width: 120, height: 120)
                            .glassEffect(
                                .regular.tint(UtopianDesignFallback.Gamification.starGold.opacity(0.1)),
                                in: Circle()
                            )
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 120, height: 120)
                            .overlay {
                                Circle()
                                    .fill(UtopianDesignFallback.Gamification.starGold.opacity(0.05))
                            }
                    }
                }
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    UtopianDesignFallback.Gamification.starGold.opacity(0.6),
                                    UtopianDesignFallback.Colors.aiPurple.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }

                // Badge content
                VStack(spacing: 2) {
                    Text("7")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [UtopianDesignFallback.Gamification.starGold, UtopianDesignFallback.Colors.aiPurple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("DAYS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(2)
                }
            }
            .matchedGeometryEffect(id: "trialBadge", in: namespace)

            VStack(spacing: UtopianDesignFallback.Spacing.sm) {
                Text("Free Trial")
                    .font(UtopianDesignFallback.Typography.title1)
                    .foregroundStyle(.white)

                Text("Experience all premium features free for 7 days.\nCancel anytime, no questions asked.")
                    .font(UtopianDesignFallback.Typography.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, UtopianDesignFallback.Spacing.xl)

            // Feature highlights with aurora icons
            VStack(spacing: UtopianDesignFallback.Spacing.md) {
                trialFeatureRow(icon: "sparkles", text: "AI-Powered Task Intelligence", color: UtopianDesignFallback.Colors.aiPurple)
                trialFeatureRow(icon: "brain.head.profile", text: "Deep Focus Mode", color: UtopianDesignFallback.Colors.focusActive)
                trialFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced Analytics", color: UtopianDesignFallback.Colors.completed)
            }
            .padding(.horizontal, UtopianDesignFallback.Spacing.xl)

            Spacer()

            // CTA with success prismatic border
            Button {
                AuroraSoundEngine.shared.play(.success)
                HapticsService.shared.notification(.success)
                onContinue()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .dynamicTypeFont(base: 16, weight: .semibold)
                    Text("Start Free Trial")
                        .dynamicTypeFont(base: 17, weight: .semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [UtopianDesignFallback.Gamification.starGold, UtopianDesignFallback.Colors.completed],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .clipShape(Capsule())
            .shadow(color: UtopianDesignFallback.Gamification.starGold.opacity(0.3), radius: 12, y: 4)
            .padding(.horizontal, UtopianDesignFallback.Spacing.xl)
            .padding(.bottom, UtopianDesignFallback.Spacing.xxl)
        }
        .onAppear {
            startTrialAnimations()
        }
    }

    private func trialFeatureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: UtopianDesignFallback.Spacing.sm) {
            Image(systemName: icon)
                .dynamicTypeFont(base: 18)
                .foregroundStyle(color)
                .frame(width: 28)

            Text(text)
                .font(UtopianDesignFallback.Typography.callout)
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .dynamicTypeFont(base: 16)
                .foregroundStyle(UtopianDesignFallback.Colors.completed)
        }
        .padding(.horizontal, UtopianDesignFallback.Spacing.md)
        .padding(.vertical, UtopianDesignFallback.Spacing.xs)
    }

    private func startTrialAnimations() {
        guard !reduceMotion else { return }

        // Badge glow pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            badgeGlow = 0.7
        }

        // Ring rotation
        withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
            badgeRotation = 360
        }
    }
}

struct LiquidGlassLaunchPage: View {
    let userName: String
    let goalSummary: String
    let namespace: Namespace.ID
    let onLaunch: () -> Void

    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var portalPulse: CGFloat = 1.0
    @State private var coreGlow: CGFloat = 0.3
    @State private var showSupernova = false
    @State private var isLaunching = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Spacer()

                // Aurora Portal - Multi-layer rotating rings with prismatic glow
                ZStack {
                    // Outer glow bloom
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    UtopianDesignFallback.Colors.focusActive.opacity(coreGlow * 0.4),
                                    UtopianDesignFallback.Colors.aiPurple.opacity(coreGlow * 0.2),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 180
                            )
                        )
                        .frame(width: 360, height: 360)
                        .blur(radius: 40)

                    // Rotating prismatic rings
                    ForEach(0..<5) { i in
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed].map { $0.opacity(0.6 - Double(i) * 0.1) },
                                    center: .center,
                                    startAngle: .degrees(ringRotation + Double(i) * 30),
                                    endAngle: .degrees(ringRotation + 360 + Double(i) * 30)
                                ),
                                lineWidth: 2.5 - CGFloat(i) * 0.3
                            )
                            .frame(width: 100 + CGFloat(i) * 40, height: 100 + CGFloat(i) * 40)
                            .scaleEffect(ringScale * portalPulse)
                            .opacity(ringOpacity - Double(i) * 0.12)
                            .blur(radius: CGFloat(i) * 0.5)
                    }

                    // Inner portal core with glass
                    ZStack {
                        // Core glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .white.opacity(coreGlow),
                                        UtopianDesignFallback.Colors.focusActive.opacity(coreGlow * 0.5),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)

                        // Glass core
                        Group {
                            if #available(iOS 26.0, *) {
                                Color.clear
                                    .frame(width: 80, height: 80)
                                    .glassEffect(.regular, in: Circle())
                            } else {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 80, height: 80)
                            }
                        }

                        // Rocket icon with bloom
                        Image(systemName: "rocket.fill")
                            .dynamicTypeFont(base: 36, weight: .medium)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, UtopianDesignFallback.Colors.focusActive],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: UtopianDesignFallback.Colors.focusActive.opacity(0.6), radius: 12)
                    }
                }
                .matchedGeometryEffect(id: "launchPortal", in: namespace)

                VStack(spacing: 16) {
                    Text("Ready for Liftoff")
                        .font(UtopianDesignFallback.Typography.title1)
                        .foregroundStyle(.white)

                    Text("Your productivity journey awaits, \(userName.isEmpty ? "Explorer" : userName)")
                        .font(UtopianDesignFallback.Typography.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    if !goalSummary.isEmpty {
                        Text("Goal: \(goalSummary)")
                            .font(UtopianDesignFallback.Typography.caption1)
                            .foregroundStyle(UtopianDesignFallback.Gamification.starGold)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, UtopianDesignFallback.Spacing.xl)

                Spacer()

                // Launch button with prismatic border
                Button {
                    triggerLaunch()
                } label: {
                    HStack(spacing: 12) {
                        Text("Launch")
                            .dynamicTypeFont(base: 18, weight: .semibold)
                        Image(systemName: "arrow.up.forward")
                            .dynamicTypeFont(base: 16, weight: .semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .clipShape(Capsule())
                .shadow(color: UtopianDesignFallback.Colors.focusActive.opacity(0.4), radius: 16, y: 6)
                .disabled(isLaunching)
                .padding(.horizontal, UtopianDesignFallback.Spacing.xl)
                .padding(.bottom, UtopianDesignFallback.Spacing.xxl)
            }

            // Supernova celebration overlay
            if showSupernova {
                AuroraSupernovaBurst(
                    isActive: $showSupernova,
                    colors: [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed]
                )
            }
        }
        .onAppear {
            startPortalAnimations()
        }
    }

    private func startPortalAnimations() {
        guard !reduceMotion else {
            ringScale = 1.0
            ringOpacity = 1.0
            coreGlow = 0.6
            return
        }

        // Scale in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            ringScale = 1.0
            ringOpacity = 1.0
        }

        // Start rotation
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Pulse effect
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            portalPulse = 1.05
            coreGlow = 0.8
        }
    }

    private func triggerLaunch() {
        guard !isLaunching else { return }
        isLaunching = true

        // Epic launch feedback
        AuroraSoundEngine.shared.celebration()

        // Supernova burst
        showSupernova = true

        // Portal collapse + launch
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            ringScale = 2.0
            ringOpacity = 0
        }

        // Delay then complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onLaunch()
        }
    }
}

// MARK: - Preview

#Preview {
    LiquidGlassOnboardingContainer(viewModel: CosmicOnboardingViewModel())
        .environment(AppViewModel())
}
