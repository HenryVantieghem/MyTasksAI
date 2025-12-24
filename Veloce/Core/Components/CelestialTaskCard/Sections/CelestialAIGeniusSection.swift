//
//  CelestialAIGeniusSection.swift
//  Veloce
//
//  AI Genius section - All AI-powered features displayed directly:
//  - AI Strategy (always visible at top)
//  - YouTube Resources with thumbnails
//  - Smart Scheduling with "Add to Calendar"
//  - Secondary: Emotional Check-In (conditional), AI Chat
//

import SwiftUI

struct CelestialAIGeniusSection: View {
    @Bindable var viewModel: CelestialTaskCardViewModel
    @State private var showEmotionalExpanded = false
    @State private var showChatExpanded = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // MARK: - AI Strategy (Always Visible at Top)
            aiStrategySection

            // MARK: - YouTube Resources
            youtubeResourcesSection

            // MARK: - Smart Scheduling
            smartSchedulingSection

            // MARK: - Secondary Features (Expandable)
            secondaryFeaturesSection
        }
        .padding(Theme.Spacing.md)
        .celestialGlassCard(accent: Theme.Colors.aiPurple)
    }

    // MARK: - AI Strategy Section (Always Visible)

    private var aiStrategySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("AI Strategy")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Spacer()

                if viewModel.celestialStrategy != nil {
                    Button {
                        Task { await viewModel.refreshAIStrategy() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Strategy Content
            if viewModel.isStrategyLoading {
                strategyLoadingState
            } else if let strategy = viewModel.celestialStrategy {
                strategyContent(strategy)
            } else {
                generateStrategyButton
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Colors.aiPurple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(Theme.Colors.aiPurple.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var strategyLoadingState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .tint(Theme.Colors.aiPurple)

            Text("Crafting your personalized strategy...")
                .font(.system(size: 13))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
    }

    private func strategyContent(_ strategy: CelestialAIStrategy) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Overview
            Text(strategy.overview)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)

            // Key Points (Condensed)
            if !strategy.keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(strategy.keyPoints.prefix(3), id: \.self) { point in
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

            // First Action Step (Highlighted)
            if let firstStep = strategy.actionableSteps.first {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.success)

                    Text("Start with: \(firstStep)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.Colors.success.opacity(0.15))
                )
            }

            // Duration Estimate
            if let minutes = viewModel.aiEstimatedDuration {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text("Estimated: \(formatDuration(minutes))")
                        .font(.system(size: 12, weight: .medium))
                    if let confidence = viewModel.durationConfidence {
                        Text("(\(confidence) confidence)")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }
                .foregroundStyle(Theme.CelestialColors.starWhite)
            }
        }
    }

    private var generateStrategyButton: some View {
        Button {
            Task { await viewModel.loadAIStrategy() }
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

    // MARK: - YouTube Resources Section

    private var youtubeResourcesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red)

                Text("YouTube Tutorials")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.red)

                Spacer()

                if !viewModel.youtubeSearchResources.isEmpty {
                    Button {
                        Task { await viewModel.loadYouTubeResources() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Content
            if viewModel.isLoadingYouTube {
                youtubeLoadingState
            } else if viewModel.youtubeSearchResources.isEmpty {
                findTutorialsButton
            } else {
                youtubeResourcesList
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Color.red.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var youtubeLoadingState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .tint(.red)
            Text("Finding helpful tutorials...")
                .font(.system(size: 13))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
    }

    private var findTutorialsButton: some View {
        Button {
            Task { await viewModel.loadYouTubeResources() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                Text("Find Tutorials")
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
        .buttonStyle(.plain)
    }

    private var youtubeResourcesList: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(viewModel.youtubeSearchResources) { resource in
                youtubeResourceRow(resource)
            }
        }
    }

    private func youtubeResourceRow(_ resource: YouTubeSearchResource) -> some View {
        Button {
            resource.openInYouTube()
            HapticsService.shared.softImpact()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                // Thumbnail placeholder with play icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 56, height: 40)

                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(resource.displayTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let reasoning = resource.reasoning {
                        Text(reasoning)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Smart Scheduling Section

    private var smartSchedulingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.TaskCardColors.schedule)

                Text("Smart Scheduling")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.TaskCardColors.schedule)

                Spacer()
            }

            // AI Suggestion
            if let suggestion = viewModel.scheduleSuggestions.first {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    // Suggested time
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.xp)

                        Text("Suggested: \(suggestion.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    // Reason
                    Text(suggestion.reason)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    // Duration picker (compact)
                    durationPicker

                    // Add to Calendar button
                    Button {
                        viewModel.editedScheduledTime = suggestion.date
                        viewModel.showCalendarScheduling = true
                        HapticsService.shared.mediumImpact()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Calendar")
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
                    .buttonStyle(.plain)
                }
            } else {
                // No suggestions yet
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Finding the best time for this task...")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Button {
                        viewModel.showSchedulePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                            Text("Pick a time manually")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.TaskCardColors.schedule)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.TaskCardColors.schedule.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(Theme.TaskCardColors.schedule.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var durationPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Duration:")
                .font(.system(size: 12))
                .foregroundStyle(Theme.CelestialColors.starDim)

            ForEach([15, 30, 45, 60, 90], id: \.self) { minutes in
                durationChip(minutes)
            }
        }
    }

    private func durationChip(_ minutes: Int) -> some View {
        let isSelected = viewModel.editedDuration == minutes

        return Button {
            viewModel.editedDuration = minutes
            viewModel.hasUnsavedChanges = true
            HapticsService.shared.selectionFeedback()
        } label: {
            Text(formatDuration(minutes))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starWhite)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.TaskCardColors.schedule : .white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Secondary Features (Expandable)

    private var secondaryFeaturesSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Emotional Check-In (only if needed)
            if viewModel.showEmotionalCheckInModule {
                emotionalCheckInExpandable
            }

            // AI Chat (always available)
            aiChatExpandable
        }
    }

    private var emotionalCheckInExpandable: some View {
        VStack(spacing: 0) {
            // Header (tap to expand)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showEmotionalExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.TaskCardColors.emotional)

                    Text("How are you feeling about this task?")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    Image(systemName: showEmotionalExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Expanded content
            if showEmotionalExpanded {
                emotionalCheckInContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.TaskCardColors.emotional.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(Theme.TaskCardColors.emotional.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var emotionalCheckInContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("This task has been waiting. That's okay—let's make it feel possible.")
                .font(.system(size: 13))
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
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
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
                    .font(.system(size: 20))
                Text(emotion.rawValue)
                    .font(.system(size: 9, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected
                          ? Theme.TaskCardColors.emotional.opacity(0.2)
                          : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                isSelected ? Theme.TaskCardColors.emotional.opacity(0.5) : .clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    private var aiChatExpandable: some View {
        VStack(spacing: 0) {
            // Header (tap to expand)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showChatExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.aiBlue)

                    Text("Ask AI anything about this task")
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

            // Expanded content
            if showChatExpanded {
                chatContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Colors.aiBlue.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(Theme.Colors.aiBlue.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var chatContent: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Chat messages
            if !viewModel.chatMessages.isEmpty {
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
                .frame(maxHeight: 150)
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
                    .onSubmit { sendMessage() }

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
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    private func chatMessageBubble(_ message: CelestialChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer() }

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

            if message.role == .assistant { Spacer() }
        }
    }

    private func sendMessage() {
        let message = viewModel.chatInput.trimmingCharacters(in: .whitespaces)
        guard !message.isEmpty else { return }

        Task {
            await viewModel.sendChatMessage(message)
        }
    }

    // MARK: - Helper Views

    private func aiResponseBubble(_ response: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "quote.opening")
                .font(.system(size: 12))
                .foregroundStyle(color.opacity(0.6))

            Text(response)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))
                .italic()
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
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
