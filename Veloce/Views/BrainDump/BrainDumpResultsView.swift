//
//  BrainDumpResultsView.swift
//  Veloce
//
//  Brain Dump Results View
//  Beautiful cards emerging from processed thoughts
//

import SwiftUI

// MARK: - Brain Dump Results View

struct BrainDumpResultsView: View {
    @Bindable var viewModel: BrainDumpViewModel
    let onComplete: () -> Void

    @State private var showCards: Bool = false
    @State private var showObservation: Bool = false
    @State private var showActions: Bool = false
    @State private var cardAppearance: [Bool] = []

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background
            resultsBackground

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .padding(.top, Theme.Spacing.lg)

                    // AI Observation
                    if let observation = viewModel.gentleObservation, showObservation {
                        observationCard(observation)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Mood & Themes
                    if showObservation {
                        moodAndThemes
                            .transition(.opacity)
                    }

                    // Task Cards
                    if showCards {
                        tasksSection
                    }

                    // Bottom spacing for button
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
            }

            // Bottom action bar
            if showActions {
                VStack {
                    Spacer()
                    actionBar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            initializeCardAppearance()
            animateIn()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Success icon
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.success.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "sparkles")
                    .dynamicTypeFont(base: 28, weight: .medium)
                    .foregroundStyle(Theme.Colors.success)
            }

            Text("Found \(viewModel.extractedTasks.count) tasks")
                .dynamicTypeFont(base: 24, weight: .bold)
                .foregroundStyle(Color.white)

            Text("~\(viewModel.formattedEstimatedTime) total")
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }

    // MARK: - Observation Card

    private func observationCard(_ observation: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // AI Avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.iridescentGradientLinear)
                    .frame(width: 36, height: 36)

                Image(systemName: "brain.head.profile")
                    .dynamicTypeFont(base: 16, weight: .medium)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Insight")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .textCase(.uppercase)
                    .tracking(1)

                Text(observation)
                    .dynamicTypeFont(base: 15, weight: .regular)
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Mood & Themes

    private var moodAndThemes: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let mood = viewModel.overallMood {
                moodPill(mood)
            }

            ForEach(viewModel.detectedThemes.prefix(3), id: \.self) { theme in
                themePill(theme)
            }

            Spacer()
        }
    }

    private func moodPill(_ mood: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .dynamicTypeFont(base: 10)
            Text(mood)
                .dynamicTypeFont(base: 12, weight: .medium)
        }
        .foregroundStyle(Theme.Colors.aiPink)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.Colors.aiPink.opacity(0.15))
        )
    }

    private func themePill(_ theme: String) -> some View {
        Text(theme)
            .dynamicTypeFont(base: 12, weight: .medium)
            .foregroundStyle(Color.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Text("Tasks")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(Color.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Button {
                    if viewModel.selectedCount == viewModel.extractedTasks.count {
                        viewModel.deselectAllTasks()
                    } else {
                        viewModel.selectAllTasks()
                    }
                } label: {
                    Text(viewModel.selectedCount == viewModel.extractedTasks.count ? "Deselect All" : "Select All")
                        .dynamicTypeFont(base: 13, weight: .medium)
                        .foregroundStyle(Theme.Colors.accent)
                }
            }

            // Task cards
            ForEach(Array(viewModel.extractedTasks.enumerated()), id: \.element.id) { index, task in
                if index < cardAppearance.count && cardAppearance[index] {
                    ExtractedTaskCard(
                        task: task,
                        isSelected: task.isSelected,
                        onToggle: {
                            viewModel.toggleTaskSelection(task)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 20)),
                        removal: .opacity
                    ))
                }
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [Color.clear, Color(white: 0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)

            HStack(spacing: Theme.Spacing.md) {
                // Back button
                Button {
                    HapticsService.shared.impact()
                    viewModel.goBackToInput()
                } label: {
                    Image(systemName: "arrow.left")
                        .dynamicTypeFont(base: 18, weight: .medium)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 50, height: 50)
                        .background(
                            SwiftUI.Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .buttonStyle(.plain)

                // Add tasks button
                Button {
                    HapticsService.shared.impact()
                    Task {
                        let count = await viewModel.addSelectedTasksToList()
                        if count > 0 {
                            onComplete()
                        }
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .dynamicTypeFont(base: 18, weight: .semibold)

                        Text("Add \(viewModel.selectedCount) Tasks")
                            .dynamicTypeFont(base: 17, weight: .semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedCount > 0 ? Theme.Colors.accentGradient : LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing))
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedCount == 0)
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.bottom, Theme.Spacing.xl)
            .background(Color(white: 0.02))
        }
    }

    // MARK: - Results Background

    private var resultsBackground: some View {
        ZStack {
            Color(white: 0.02)

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.05),
                    Color.clear,
                    Theme.Colors.aiBlue.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Animations

    private func initializeCardAppearance() {
        cardAppearance = Array(repeating: false, count: viewModel.extractedTasks.count)
    }

    private func animateIn() {
        // Show observation first
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            showObservation = true
        }

        // Then show cards with stagger
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
            showCards = true
        }

        // Stagger card appearances
        for index in cardAppearance.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(index) * 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    if index < cardAppearance.count {
                        cardAppearance[index] = true
                    }
                }
            }
        }

        // Finally show actions
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.8)) {
            showActions = true
        }
    }
}

// MARK: - Extracted Task Card

struct ExtractedTaskCard: View {
    let task: ExtractedTask
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Checkbox
                ZStack {
                    SwiftUI.Circle()
                        .stroke(isSelected ? Theme.Colors.accent : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .dynamicTypeFont(base: 12, weight: .bold)
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(task.title)
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Metadata row
                    HStack(spacing: Theme.Spacing.sm) {
                        // Priority
                        HStack(spacing: 2) {
                            ForEach(0..<task.priority.starRating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .dynamicTypeFont(base: 10)
                                    .foregroundStyle(priorityColor)
                            }
                        }

                        // Time estimate
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .dynamicTypeFont(base: 10)
                            Text(formatMinutes(task.estimatedMinutes))
                                .dynamicTypeFont(base: 12, weight: .medium)
                        }
                        .foregroundStyle(Color.white.opacity(0.5))

                        // Due context
                        if let due = task.dueContext {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .dynamicTypeFont(base: 10)
                                Text(due)
                                    .dynamicTypeFont(base: 12, weight: .medium)
                            }
                            .foregroundStyle(Theme.Colors.aiBlue.opacity(0.8))
                        }

                        // Person
                        if let person = task.relatedPerson {
                            HStack(spacing: 4) {
                                Image(systemName: "person")
                                    .dynamicTypeFont(base: 10)
                                Text(person)
                                    .dynamicTypeFont(base: 12, weight: .medium)
                            }
                            .foregroundStyle(Theme.Colors.aiPink.opacity(0.8))
                        }
                    }

                    // Suggestion
                    if let suggestion = task.suggestion {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .dynamicTypeFont(base: 10)
                            Text(suggestion)
                                .dynamicTypeFont(base: 12, weight: .regular)
                        }
                        .foregroundStyle(Theme.Colors.xp.opacity(0.8))
                        .padding(.top, 2)
                    }
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .stroke(
                                isSelected ? Theme.Colors.accent.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .opacity(isSelected ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return Theme.Colors.xp
        case .low: return .green
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let vm = BrainDumpViewModel()
    return BrainDumpResultsView(viewModel: vm) {
        print("Complete")
    }
}
