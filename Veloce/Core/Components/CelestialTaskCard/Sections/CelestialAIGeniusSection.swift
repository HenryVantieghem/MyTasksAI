//
//  CelestialAIGeniusSection.swift
//  Veloce
//
//  Living Cosmos - AI Oracle Experience
//  Mystical oracle that speaks wisdom with aurora particles,
//  crystal formations, and cosmic typography
//

import SwiftUI

struct CelestialAIGeniusSection: View {
    @Bindable var viewModel: CelestialTaskCardViewModel
    @State private var showEmotionalExpanded = false
    @State private var showChatExpanded = false
    @State private var oraclePhase: CGFloat = 0
    @State private var crystalRotation: Double = 0
    @State private var isVisible = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // MARK: - Oracle Header
            oracleHeader
                .sectionReveal(isVisible: isVisible, index: 0)

            // MARK: - AI Strategy (Crystal Formation)
            crystalStrategySection
                .sectionReveal(isVisible: isVisible, index: 1)

            // MARK: - YouTube Constellation
            youtubeConstellationSection
                .sectionReveal(isVisible: isVisible, index: 2)

            // MARK: - Smart Scheduling Orbit
            schedulingOrbitSection
                .sectionReveal(isVisible: isVisible, index: 3)

            // MARK: - Secondary Features
            secondaryFeaturesSection
                .sectionReveal(isVisible: isVisible, index: 4)
        }
        .padding(Theme.Spacing.lg)
        .background(oracleContainerBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .overlay(oracleContainerBorder)
        .onAppear {
            withAnimation(Theme.Animation.stellarBounce.delay(0.1)) {
                isVisible = true
            }
            startOracleAnimations()
        }
    }

    // MARK: - Oracle Container Background

    private var oracleContainerBackground: some View {
        ZStack {
            // Deep void base
            Theme.CelestialColors.abyss

            // Aurora gradient overlay
            RadialGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.15),
                    Theme.Colors.aiPurple.opacity(0.05),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )

            // Secondary glow
            RadialGradient(
                colors: [
                    Theme.CelestialColors.plasmaCore.opacity(0.08),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 200
            )

            // Floating particles
            if !reduceMotion {
                OracleAuroraParticles()
            }
        }
    }

    private var oracleContainerBorder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiPurple.opacity(0.4),
                        Theme.CelestialColors.plasmaCore.opacity(0.2),
                        Theme.Colors.aiPurple.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Oracle Header

    private var oracleHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Oracle orb
            OracleOrb(phase: oraclePhase, isActive: viewModel.isStrategyLoading || viewModel.isAIThinking)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Oracle")
                    .font(Theme.Typography.cosmosTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiPurple,
                                Theme.CelestialColors.plasmaCore
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Wisdom for your journey")
                    .font(Theme.Typography.cosmosWhisper)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Spacer()
        }
    }

    // MARK: - Crystal Strategy Section

    private var crystalStrategySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header with crystal icon
            HStack(spacing: Theme.Spacing.sm) {
                CrystalIcon(rotation: crystalRotation)
                    .frame(width: 20, height: 20)

                Text("Strategy Crystal")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Spacer()

                if viewModel.celestialStrategy != nil {
                    Button {
                        Task { await viewModel.refreshAIStrategy() }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                            .rotationEffect(.degrees(crystalRotation * 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Strategy Content
            if viewModel.isStrategyLoading {
                oracleThinkingState
            } else if let strategy = viewModel.celestialStrategy {
                crystalStrategyContent(strategy)
            } else {
                generateCrystalButton
            }
        }
        .padding(Theme.Spacing.md)
        .background(crystalSectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(crystalSectionBorder)
    }

    private var crystalSectionBackground: some View {
        ZStack {
            Theme.Colors.aiPurple.opacity(0.08)

            // Crystal facet highlights
            LinearGradient(
                colors: [
                    .white.opacity(0.03),
                    Color.clear,
                    .white.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var crystalSectionBorder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiPurple.opacity(0.3),
                        Theme.CelestialColors.plasmaCore.opacity(0.15),
                        Theme.Colors.aiPurple.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private var oracleThinkingState: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Pulsing oracle indicator
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<3) { i in
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiPurple)
                        .frame(width: 8, height: 8)
                        .opacity(0.4 + Double(i) * 0.2)
                        .scaleEffect(reduceMotion ? 1 : 0.8 + sin(oraclePhase + Double(i) * 0.5) * 0.2)
                }
            }

            Text("The Oracle is divining your path...")
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(Theme.CelestialColors.starDim)

            // Aurora line
            if !reduceMotion {
                AuroraLoadingLine()
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
    }

    private func crystalStrategyContent(_ strategy: CelestialAIStrategy) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Overview with wisdom styling
            Text(strategy.overview)
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(5)
                .padding(Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.white.opacity(0.03))
                )

            // Crystal key points
            if !strategy.keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(strategy.keyPoints.prefix(3).enumerated()), id: \.offset) { index, point in
                        CrystalKeyPoint(point: point, index: index, phase: oraclePhase)
                    }
                }
            }

            // First action (glowing)
            if let firstStep = strategy.actionableSteps.first {
                GlowingActionStep(step: firstStep)
            }

            // Duration estimate
            if let minutes = viewModel.aiEstimatedDuration {
                OracleEstimate(
                    minutes: minutes,
                    confidence: viewModel.durationConfidence
                )
            }
        }
    }

    private var generateCrystalButton: some View {
        Button {
            Task { await viewModel.loadAIStrategy() }
        } label: {
            HStack(spacing: 10) {
                CrystalIcon(rotation: crystalRotation)
                    .frame(width: 18, height: 18)

                Text("Summon Strategy")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.aiPurple,
                                    Theme.Colors.aiPurple.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Shimmer overlay
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: reduceMotion ? 0 : sin(oraclePhase) * 100)
                }
            )
        }
        .buttonStyle(CosmicPressStyle())
    }

    // MARK: - YouTube Constellation Section

    private var youtubeConstellationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.red)
                }

                Text("Knowledge Stars")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.red)

                Spacer()

                if !viewModel.youtubeSearchResources.isEmpty {
                    Button {
                        Task { await viewModel.loadYouTubeResources() }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Content
            if viewModel.isLoadingYouTube {
                constellationLoadingState
            } else if viewModel.youtubeSearchResources.isEmpty {
                findStarsButton
            } else {
                constellationGrid
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            ZStack {
                Color.red.opacity(0.06)

                // Star scatter effect
                GeometryReader { geo in
                    ForEach(0..<5) { i in
                        SwiftUI.Circle()
                            .fill(.red.opacity(0.3))
                            .frame(width: 2, height: 2)
                            .position(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                            )
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Color.red.opacity(0.15), lineWidth: 1)
        )
    }

    private var constellationLoadingState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ConstellationLoader()
                .frame(width: 40, height: 40)

            Text("Mapping the knowledge stars...")
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
    }

    private var findStarsButton: some View {
        Button {
            Task { await viewModel.loadYouTubeResources() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkle.magnifyingglass")
                Text("Discover Resources")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red)
            )
        }
        .buttonStyle(CosmicPressStyle())
    }

    private var constellationGrid: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(viewModel.youtubeSearchResources.enumerated()), id: \.element.id) { index, resource in
                ConstellationResourceRow(resource: resource, index: index, phase: oraclePhase)
            }
        }
    }

    // MARK: - Smart Scheduling Orbit Section

    private var schedulingOrbitSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.TaskCardColors.schedule.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.TaskCardColors.schedule)
                }

                Text("Time Orbit")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.TaskCardColors.schedule)

                Spacer()
            }

            // AI Suggestion
            if let suggestion = viewModel.scheduleSuggestions.first {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    // Orbital time display
                    OrbitalTimeDisplay(date: suggestion.date, phase: oraclePhase)

                    // Reason
                    Text(suggestion.reason)
                        .font(Theme.Typography.cosmosWhisper)
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    // Duration selector
                    orbitalDurationPicker

                    // Schedule button
                    Button {
                        viewModel.editedScheduledTime = suggestion.date
                        viewModel.showCalendarScheduling = true
                        HapticsService.shared.mediumImpact()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Lock into Orbit")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.TaskCardColors.schedule)
                        )
                    }
                    .buttonStyle(CosmicPressStyle())
                }
            } else {
                manualSchedulePrompt
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.TaskCardColors.schedule.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.TaskCardColors.schedule.opacity(0.15), lineWidth: 1)
        )
    }

    private var orbitalDurationPicker: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text("Duration:")
                .font(Theme.Typography.cosmosMeta)
                .foregroundStyle(Theme.CelestialColors.starDim)

            ForEach([15, 30, 45, 60, 90], id: \.self) { minutes in
                OrbitalDurationChip(
                    minutes: minutes,
                    isSelected: viewModel.editedDuration == minutes,
                    phase: oraclePhase
                ) {
                    viewModel.editedDuration = minutes
                    viewModel.hasUnsavedChanges = true
                    HapticsService.shared.selectionFeedback()
                }
            }
        }
    }

    private var manualSchedulePrompt: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Calculating optimal orbit...")
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(Theme.CelestialColors.starDim)

            Button {
                viewModel.showSchedulePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                    Text("Set coordinates manually")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.TaskCardColors.schedule)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
    }

    // MARK: - Secondary Features

    private var secondaryFeaturesSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if viewModel.showEmotionalCheckInModule {
                emotionalNebula
            }

            aiChatNebula
        }
    }

    private var emotionalNebula: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(Theme.Animation.stellarBounce) {
                    showEmotionalExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.TaskCardColors.emotional.opacity(0.2))
                            .frame(width: 24, height: 24)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.TaskCardColors.emotional)
                    }

                    Text("Emotional Check-In")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    Image(systemName: showEmotionalExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .rotationEffect(.degrees(showEmotionalExpanded ? 0 : 0))
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            if showEmotionalExpanded {
                emotionalNebulaContent
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .background(Theme.TaskCardColors.emotional.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.TaskCardColors.emotional.opacity(0.12), lineWidth: 1)
        )
    }

    private var emotionalNebulaContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("This task has been waiting. That's okay—let's make it feel possible.")
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(.white.opacity(0.8))

            // Emotion orbs
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(Emotion.allCases, id: \.self) { emotion in
                    EmotionOrb(
                        emotion: emotion,
                        isSelected: viewModel.selectedEmotion == emotion,
                        phase: oraclePhase
                    ) {
                        withAnimation(Theme.Animation.stellarBounce) {
                            viewModel.selectEmotion(emotion)
                        }
                    }
                }
            }

            // AI Response
            if let response = viewModel.emotionResponse {
                OracleResponseBubble(response: response, color: Theme.TaskCardColors.emotional)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    private var aiChatNebula: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(Theme.Animation.stellarBounce) {
                    showChatExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.aiBlue.opacity(0.2))
                            .frame(width: 24, height: 24)

                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.Colors.aiBlue)
                    }

                    Text("Commune with the Oracle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    Image(systemName: showChatExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            if showChatExpanded {
                oracleChatContent
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .background(Theme.Colors.aiBlue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.Colors.aiBlue.opacity(0.12), lineWidth: 1)
        )
    }

    private var oracleChatContent: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Chat messages
            if !viewModel.chatMessages.isEmpty {
                ScrollView {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(viewModel.chatMessages) { message in
                            OracleChatBubble(message: message)
                        }

                        if viewModel.isAIThinking {
                            OracleThinkingIndicator()
                        }
                    }
                }
                .frame(maxHeight: 150)
            }

            // Input field
            HStack(spacing: Theme.Spacing.sm) {
                TextField("Seek wisdom...", text: $viewModel.chatInput)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Theme.Colors.aiBlue.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }

                Button {
                    sendMessage()
                } label: {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(
                                viewModel.chatInput.isEmpty
                                    ? Color.clear
                                    : Theme.Colors.aiBlue
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(
                                viewModel.chatInput.isEmpty
                                    ? Theme.CelestialColors.starDim
                                    : .white
                            )
                    }
                }
                .disabled(viewModel.chatInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    private func sendMessage() {
        let message = viewModel.chatInput.trimmingCharacters(in: .whitespaces)
        guard !message.isEmpty else { return }

        Task {
            await viewModel.sendChatMessage(message)
        }
    }

    // MARK: - Animations

    private func startOracleAnimations() {
        guard !reduceMotion else { return }

        // Continuous oracle phase
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            oraclePhase = .pi * 2
        }

        // Crystal rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            crystalRotation = 360
        }
    }
}

// MARK: - Oracle Orb

struct OracleOrb: View {
    let phase: CGFloat
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Outer glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.4),
                            Theme.Colors.aiPurple.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 20
                    )
                )
                .scaleEffect(reduceMotion ? 1 : 1 + sin(phase * 2) * 0.1)

            // Inner orb
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.plasmaCore,
                            Theme.Colors.aiPurple,
                            Theme.Colors.aiPurple.opacity(0.8)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 18
                    )
                )
                .frame(width: 24, height: 24)

            // Highlight
            Ellipse()
                .fill(.white.opacity(0.3))
                .frame(width: 8, height: 4)
                .offset(x: -3, y: -6)

            // Active pulse ring
            if isActive && !reduceMotion {
                let sinValue = CGFloat(Darwin.sin(Double(phase * 4)))
                SwiftUI.Circle()
                    .stroke(Theme.Colors.aiPurple.opacity(0.5), lineWidth: 2)
                    .scaleEffect(1 + sinValue * 0.3)
                    .opacity(0.5 + sinValue * 0.3)
            }
        }
    }
}

// MARK: - Crystal Icon

struct CrystalIcon: View {
    let rotation: Double

    var body: some View {
        ZStack {
            // Crystal shape using path
            Path { path in
                path.move(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 18, y: 8))
                path.addLine(to: CGPoint(x: 10, y: 20))
                path.addLine(to: CGPoint(x: 2, y: 8))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiPurple,
                        Theme.CelestialColors.plasmaCore
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Inner facet
            Path { path in
                path.move(to: CGPoint(x: 10, y: 4))
                path.addLine(to: CGPoint(x: 14, y: 8))
                path.addLine(to: CGPoint(x: 10, y: 14))
                path.addLine(to: CGPoint(x: 6, y: 8))
                path.closeSubpath()
            }
            .fill(.white.opacity(0.2))
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
    }
}

// MARK: - Aurora Loading Line

struct AuroraLoadingLine: View {
    @State private var offset: CGFloat = -200

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 1.5)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Theme.Colors.aiPurple.opacity(0.5),
                            Theme.CelestialColors.plasmaCore,
                            Theme.Colors.aiPurple.opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 100)
                .offset(x: offset)
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        offset = geo.size.width
                    }
                }
        }
        .clipShape(Capsule())
        .background(Capsule().fill(.white.opacity(0.05)))
    }
}

// MARK: - Crystal Key Point

struct CrystalKeyPoint: View {
    let point: String
    let index: Int
    let phase: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Crystal bullet
            Path { path in
                path.move(to: CGPoint(x: 4, y: 0))
                path.addLine(to: CGPoint(x: 8, y: 4))
                path.addLine(to: CGPoint(x: 4, y: 8))
                path.addLine(to: CGPoint(x: 0, y: 4))
                path.closeSubpath()
            }
            .fill(Theme.Colors.aiPurple)
            .frame(width: 8, height: 8)
            .offset(y: 4)

            Text(point)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Glowing Action Step

struct GlowingActionStep: View {
    let step: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.success.opacity(0.2))
                    .frame(width: 24, height: 24)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.success)
            }

            Text("Start: \(step)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.Colors.success.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.Colors.success.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Oracle Estimate

struct OracleEstimate: View {
    let minutes: Int
    let confidence: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.system(size: 11))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Text("Estimated: \(formatDuration(minutes))")
                .font(Theme.Typography.cosmosMeta)
                .foregroundStyle(Theme.CelestialColors.starWhite)

            if let confidence = confidence {
                Text("(\(confidence))")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Constellation Loader

struct ConstellationLoader: View {
    @State private var phase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                SwiftUI.Circle()
                    .fill(Color.red.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(y: -12)
                    .rotationEffect(.degrees(Double(i) * 60 + phase * 360))
            }

            SwiftUI.Circle()
                .fill(Color.red.opacity(0.4))
                .frame(width: 8, height: 8)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Constellation Resource Row

struct ConstellationResourceRow: View {
    let resource: YouTubeSearchResource
    let index: Int
    let phase: CGFloat

    var body: some View {
        Button {
            resource.openInYouTube()
            HapticsService.shared.softImpact()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                // Star icon with orbit ring
                ZStack {
                    SwiftUI.Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        .frame(width: 40, height: 40)

                    SwiftUI.Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 30, height: 30)

                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(resource.displayTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let reasoning = resource.reasoning {
                        Text(reasoning)
                            .font(Theme.Typography.cosmosMeta)
                            .foregroundStyle(Theme.CelestialColors.starDim)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
        .buttonStyle(CosmicPressStyle())
    }
}

// MARK: - Orbital Time Display

struct OrbitalTimeDisplay: View {
    let date: Date
    let phase: CGFloat

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Mini orbit visualization
            ZStack {
                SwiftUI.Circle()
                    .stroke(Theme.TaskCardColors.schedule.opacity(0.3), lineWidth: 1)
                    .frame(width: 28, height: 28)

                SwiftUI.Circle()
                    .fill(Theme.TaskCardColors.schedule)
                    .frame(width: 6, height: 6)
                    .offset(y: -11)
                    .rotationEffect(.degrees(Double(phase) * 20))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Optimal: \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text("AI calculated from your patterns")
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
        }
    }
}

// MARK: - Orbital Duration Chip

struct OrbitalDurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let phase: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(formatDuration(minutes))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starWhite)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.TaskCardColors.schedule : .white.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Theme.TaskCardColors.schedule.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Emotion Orb

struct EmotionOrb: View {
    let emotion: Emotion
    let isSelected: Bool
    let phase: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        SwiftUI.Circle()
                            .fill(Theme.TaskCardColors.emotional.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }

                    Text(emotion.emoji)
                        .font(.system(size: 22))
                }

                Text(emotion.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Oracle Response Bubble

struct OracleResponseBubble: View {
    let response: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(color.opacity(0.7))

            Text(response)
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Oracle Chat Bubble

struct OracleChatBubble: View {
    let message: CelestialChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            Text(message.content)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            message.role == .user
                                ? Theme.Colors.aiBlue.opacity(0.3)
                                : .white.opacity(0.08)
                        )
                )

            if message.role == .assistant { Spacer() }
        }
    }
}

// MARK: - Oracle Thinking Indicator

struct OracleThinkingIndicator: View {
    @State private var phase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func dotOpacity(for index: Int) -> Double {
        if reduceMotion { return 0.6 }
        let sinValue = Darwin.sin(Double(phase) + Double(index) * 0.5)
        return 0.3 + sinValue * 0.4
    }

    private func dotScale(for index: Int) -> CGFloat {
        if reduceMotion { return 1 }
        let sinValue = Darwin.sin(Double(phase) + Double(index) * 0.5)
        return 0.8 + CGFloat(sinValue) * 0.2
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Animated dots
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiBlue)
                        .frame(width: 6, height: 6)
                        .opacity(dotOpacity(for: i))
                        .scaleEffect(dotScale(for: i))
                }
            }

            Text("Consulting the cosmos...")
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Oracle Aurora Particles

struct OracleAuroraParticles: View {
    @State private var particles: [AuroraParticle] = []

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { particle in
                SwiftUI.Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .blur(radius: particle.size > 3 ? 1 : 0)
            }
            .onAppear {
                generateParticles(in: geo.size)
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<15).map { _ in
            AuroraParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1.5...4),
                color: [
                    Theme.Colors.aiPurple.opacity(0.4),
                    Theme.CelestialColors.plasmaCore.opacity(0.3),
                    .white.opacity(0.2)
                ].randomElement() ?? .white,
                opacity: Double.random(in: 0.2...0.5)
            )
        }
    }
}

struct AuroraParticle: Identifiable {
    let id: UUID
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
}

// MARK: - Cosmic Press Style

struct CosmicPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            CelestialAIGeniusSection(
                viewModel: {
                    let task = TaskItem(title: "Complete project proposal")
                    task.starRating = 3
                    task.timesRescheduled = 3
                    let vm = CelestialTaskCardViewModel(task: task)
                    vm.aiStrategy = "Focus on starting with the smallest possible action."
                    return vm
                }()
            )
            .padding()
        }
    }
}
