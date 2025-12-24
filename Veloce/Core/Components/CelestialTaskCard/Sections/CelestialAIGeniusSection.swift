//
//  CelestialAIGeniusSection.swift
//  Veloce
//
//  AI Genius section containing all AI-powered modules:
//  - Emotional Check-In (conditional)
//  - Start Here (micro-challenge)
//  - AI Strategy
//  - Resources (YouTube)
//  - AI Chat
//

import SwiftUI

struct CelestialAIGeniusSection: View {
    @Bindable var viewModel: CelestialTaskCardViewModel
    @State private var activeModule: AIGeniusModule?

    private enum AIGeniusModule: String, CaseIterable, Identifiable {
        case emotional = "How You Feel"
        case startHere = "Start Here"
        case strategy = "AI Strategy"
        case resources = "Resources"
        case chat = "AI Chat"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .emotional: return "heart.fill"
            case .startHere: return "bolt.fill"
            case .strategy: return "lightbulb.fill"
            case .resources: return "play.rectangle.fill"
            case .chat: return "bubble.left.and.bubble.right.fill"
            }
        }

        var color: Color {
            switch self {
            case .emotional: return Theme.TaskCardColors.emotional
            case .startHere: return Theme.Colors.success
            case .strategy: return Theme.Colors.aiPurple
            case .resources: return Color.red
            case .chat: return Theme.Colors.aiBlue
            }
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Module chips row
            moduleChipsRow

            // Active module content
            if let module = activeModule {
                moduleContent(for: module)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                defaultState
            }
        }
        .padding(Theme.Spacing.md)
        .celestialGlassCard(accent: Theme.Colors.aiPurple)
    }

    // MARK: - Module Chips Row

    private var moduleChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(availableModules) { module in
                    moduleChip(module)
                }
            }
        }
    }

    private var availableModules: [AIGeniusModule] {
        var modules: [AIGeniusModule] = []

        // Emotional check-in only if task rescheduled 2+ times
        if viewModel.showEmotionalCheckInModule {
            modules.append(.emotional)
        }

        // Always available modules
        modules.append(contentsOf: [.startHere, .strategy, .resources, .chat])

        return modules
    }

    private func moduleChip(_ module: AIGeniusModule) -> some View {
        let isSelected = activeModule == module

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                activeModule = isSelected ? nil : module
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: module.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(module.rawValue)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : module.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? module.color : module.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .strokeBorder(module.color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Default State

    private var defaultState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundStyle(Theme.Colors.aiPurple.opacity(0.6))

            Text("Tap a module above to get AI assistance")
                .font(.system(size: 13))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Module Content

    @ViewBuilder
    private func moduleContent(for module: AIGeniusModule) -> some View {
        switch module {
        case .emotional:
            emotionalCheckInContent
        case .startHere:
            startHereContent
        case .strategy:
            strategyContent
        case .resources:
            resourcesContent
        case .chat:
            chatContent
        }
    }

    // MARK: - Emotional Check-In

    private var emotionalCheckInContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("This task has been waiting. That's okay—let's make it feel possible.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))

            // Emotion buttons
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(Emotion.allCases, id: \.self) { emotion in
                    emotionButton(emotion)
                }
            }

            // AI Response
            if let response = viewModel.emotionResponse {
                aiResponseBubble(response, color: Theme.TaskCardColors.emotional)
            }
        }
    }

    private func emotionButton(_ emotion: Emotion) -> some View {
        let isSelected = viewModel.selectedEmotion == emotion

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectEmotion(emotion)
            }
        } label: {
            VStack(spacing: 4) {
                Text(emotion.emoji)
                    .font(.system(size: 22))
                Text(emotion.rawValue)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected
                          ? Theme.TaskCardColors.emotional.opacity(0.2)
                          : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isSelected
                                    ? Theme.TaskCardColors.emotional.opacity(0.5)
                                    : .clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Start Here (Micro-Challenge)

    private var startHereContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Challenge description
            VStack(alignment: .leading, spacing: 8) {
                Text("30-SECOND CHALLENGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.Colors.success)

                Text(viewModel.firstStepTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }

            // Timer or Start button
            if viewModel.isChallengeActive {
                // Countdown timer
                VStack(spacing: Theme.Spacing.sm) {
                    Text("\(viewModel.countdown)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.success)
                        .contentTransition(.numericText())

                    Text("seconds remaining")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Button {
                        viewModel.completeMicroChallenge()
                    } label: {
                        Text("I Did It!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Theme.Colors.success)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            } else if viewModel.challengeCompleted {
                // Completed state
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.success)

                    Text("Challenge Complete!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("You've overcome the first barrier. Keep the momentum going!")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
            } else {
                // Start button
                Button {
                    viewModel.startMicroChallenge()
                    HapticsService.shared.mediumImpact()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))

                        Text("Start 30-Second Challenge")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.Colors.success)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - AI Strategy (Rich Display)

    private var strategyContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if viewModel.isStrategyLoading {
                VStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                        .tint(Theme.Colors.aiPurple)

                    Text("Crafting your personalized strategy...")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.lg)
            } else if let strategy = viewModel.celestialStrategy {
                // Rich strategy display
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Overview section
                    Text(strategy.overview)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(4)

                    // Key Points
                    if !strategy.keyPoints.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Label("Key Strategy Points", systemImage: "lightbulb.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.Colors.aiPurple)

                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(strategy.keyPoints, id: \.self) { point in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(Theme.Colors.aiPurple)
                                            .frame(width: 5, height: 5)
                                            .offset(y: 6)

                                        Text(point)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white.opacity(0.85))
                                    }
                                }
                            }
                        }
                        .padding(Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.Colors.aiPurple.opacity(0.08))
                        )
                    }

                    // Actionable Steps
                    if !strategy.actionableSteps.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Label("Action Steps", systemImage: "checklist")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.Colors.success)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(strategy.actionableSteps.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 20, height: 20)
                                            .background(
                                                Circle()
                                                    .fill(index == 0 ? Theme.Colors.success : Theme.Colors.aiPurple.opacity(0.5))
                                            )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(step)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.85))

                                            if index == 0 {
                                                Text("Start here — under 2 minutes")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(Theme.Colors.success.opacity(0.8))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.Colors.success.opacity(0.08))
                        )
                    }

                    // Potential Obstacles
                    if let obstacles = strategy.potentialObstacles, !obstacles.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Label("Watch Out For", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.Colors.warning)

                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(obstacles, id: \.self) { obstacle in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.circle")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.Colors.warning.opacity(0.8))

                                        Text(obstacle)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.75))
                                    }
                                }
                            }
                        }
                        .padding(Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.Colors.warning.opacity(0.08))
                        )
                    }

                    // Refresh button
                    Button {
                        Task {
                            await viewModel.refreshAIStrategy()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                            Text("Generate new strategy")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Theme.Colors.aiPurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.aiPurple.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Generate strategy button
                Button {
                    Task {
                        await viewModel.loadAIStrategy()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Generate AI Strategy")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.Colors.aiPurple)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Resources (YouTube Search)

    private var resourcesContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if viewModel.isLoadingYouTube {
                VStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                        .tint(.red)
                    Text("Finding helpful tutorials...")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.lg)
            } else if viewModel.youtubeSearchResources.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Text("Find tutorials to help you complete this task")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .multilineTextAlignment(.center)

                    Button {
                        Task {
                            await viewModel.loadYouTubeResources()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                            Text("Find YouTube Tutorials")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    // Header
                    HStack {
                        Label("YouTube Tutorials", systemImage: "play.rectangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.red)

                        Spacer()

                        Button {
                            Task {
                                await viewModel.loadYouTubeResources()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                        }
                        .buttonStyle(.plain)
                    }

                    // Search resources
                    ForEach(viewModel.youtubeSearchResources) { resource in
                        youtubeSearchRow(resource)
                    }

                    // Note about search
                    Text("Tap to search YouTube for tutorials")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private func youtubeSearchRow(_ resource: YouTubeSearchResource) -> some View {
        Button {
            resource.openInYouTube()
            HapticsService.shared.softImpact()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                // Relevance indicator
                Image(systemName: resource.relevanceIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(resource.displayTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)

                    if let reasoning = resource.reasoning {
                        Text(reasoning)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                            .lineLimit(2)
                    }

                    // Search query hint
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 9))
                        Text(resource.searchQuery)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.7))
                }

                Spacer()

                // Open in YouTube indicator
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                    if let label = resource.relevanceLabel {
                        Text(label)
                            .font(.system(size: 8, weight: .medium))
                    }
                }
                .foregroundStyle(Theme.CelestialColors.starDim)
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.red.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Chat

    private var chatContent: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Chat messages
            if viewModel.chatMessages.isEmpty {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Colors.aiBlue.opacity(0.6))

                    Text("Ask me anything about this task")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(viewModel.chatMessages) { message in
                            chatMessageBubble(message)
                        }

                        if viewModel.isAIThinking {
                            HStack {
                                ProgressView()
                                    .tint(Theme.Colors.aiBlue)
                                Text("Thinking...")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.CelestialColors.starDim)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            // Input field
            HStack(spacing: Theme.Spacing.sm) {
                TextField("Ask a question...", text: $viewModel.chatInput)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.white.opacity(0.08))
                    )
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            viewModel.chatInput.isEmpty
                                ? Theme.CelestialColors.starDim
                                : Theme.Colors.aiBlue
                        )
                }
                .disabled(viewModel.chatInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func chatMessageBubble(_ message: CelestialChatMessage) -> some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            Text(message.content)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(message.role == .user
                              ? Theme.Colors.aiBlue.opacity(0.3)
                              : .white.opacity(0.08))
                )

            if message.role == .assistant {
                Spacer()
            }
        }
    }

    private func sendMessage() {
        let message = viewModel.chatInput.trimmingCharacters(in: .whitespaces)
        guard !message.isEmpty else { return }

        Task {
            await viewModel.sendChatMessage(message)
        }
    }

    // MARK: - AI Response Bubble

    private func aiResponseBubble(_ response: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "quote.opening")
                .font(.system(size: 12))
                .foregroundStyle(color.opacity(0.6))

            Text(response)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .italic()
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
                    vm.aiStrategy = "Focus on starting with the smallest possible action. Once you begin, momentum builds naturally."
                    return vm
                }()
            )
            .padding()
        }
    }
}
