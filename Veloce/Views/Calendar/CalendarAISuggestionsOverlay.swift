//
//  CalendarAISuggestionsOverlay.swift
//  Veloce
//
//  Calendar AI Suggestions Overlay - Smart scheduling suggestions
//  Shows AI-recommended time slots for unscheduled tasks
//

import SwiftUI

// MARK: - Calendar AI Suggestions Overlay

struct CalendarAISuggestionsOverlay: View {
    let unscheduledTasks: [TaskItem]
    let onSchedule: (TaskItem, Date) -> Void
    let onDismiss: () -> Void

    @State private var suggestions: [TaskScheduleSuggestion] = []
    @State private var isLoading = false
    @State private var selectedTask: TaskItem?
    @State private var showSuggestions = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Floating card at bottom
            if !unscheduledTasks.isEmpty {
                suggestionCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: unscheduledTasks.count)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuggestions)
    }

    // MARK: - Suggestion Card

    private var suggestionCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header
            HStack {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.aiPurple)

                    Text("AI Scheduling")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                // Task count badge
                Text("\(unscheduledTasks.count) unscheduled")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.glassBackground)
                    )

                Button {
                    HapticsService.shared.lightImpact()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }

            // Task list or suggestions
            if showSuggestions, let task = selectedTask {
                suggestionsForTask(task)
            } else {
                unscheduledTasksList
            }
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.bottom, Theme.Spacing.floatingTabBarClearance)
    }

    // MARK: - Unscheduled Tasks List

    private var unscheduledTasksList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(unscheduledTasks.prefix(5)) { task in
                    UnscheduledTaskChip(task: task) {
                        selectedTask = task
                        withAnimation {
                            showSuggestions = true
                        }
                        loadSuggestions(for: task)
                    }
                }

                if unscheduledTasks.count > 5 {
                    Text("+\(unscheduledTasks.count - 5) more")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.horizontal, Theme.Spacing.sm)
                }
            }
        }
    }

    // MARK: - Suggestions for Task

    @ViewBuilder
    private func suggestionsForTask(_ task: TaskItem) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            // Selected task header
            HStack {
                Button {
                    withAnimation {
                        showSuggestions = false
                        selectedTask = nil
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.accent)
                }
                .buttonStyle(.plain)

                Text(task.title)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Spacer()
            }

            if isLoading {
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                        .tint(Theme.Colors.accent)
                    Text("Finding best times...")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(height: 60)
            } else if suggestions.isEmpty {
                Text("No suggestions available")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(height: 60)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(suggestions) { suggestion in
                            SuggestionSlotButton(suggestion: suggestion) {
                                onSchedule(task, suggestion.suggestedTime)
                                withAnimation {
                                    showSuggestions = false
                                    selectedTask = nil
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Load Suggestions

    private func loadSuggestions(for task: TaskItem) {
        isLoading = true
        suggestions = []

        // Generate mock suggestions for now
        // In production, this would call GeminiService.suggestOptimalSchedule()
        Task {
            try? await Task.sleep(for: .milliseconds(800))

            await MainActor.run {
                suggestions = generateMockSuggestions(for: task)
                isLoading = false
            }
        }
    }

    private func generateMockSuggestions(for task: TaskItem) -> [TaskScheduleSuggestion] {
        let calendar = Calendar.current
        let now = Date()

        return (0..<3).compactMap { index in
            let hours = [9, 14, 16][index]
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hours
            components.minute = 0

            guard let suggestedTime = calendar.date(from: components) else { return nil }

            let reasons = [
                "Your most productive time based on past completions",
                "Clear slot after your scheduled meetings",
                "Good time for focused work before evening"
            ]

            return TaskScheduleSuggestion(
                taskId: task.id,
                suggestedTime: suggestedTime,
                confidence: Double(90 - index * 15) / 100,
                reason: reasons[index]
            )
        }
    }
}

// MARK: - Unscheduled Task Chip

struct UnscheduledTaskChip: View {
    let task: TaskItem
    let onTap: () -> Void

    @State private var isPressed = false

    private var priorityColor: Color {
        switch task.starRating {
        case 3: return Theme.Colors.error
        case 2: return Theme.Colors.xp
        default: return Theme.Colors.aiBlue
        }
    }

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                SwiftUI.Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)

                Text(task.title)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Theme.Colors.glassBackground)
                    .overlay(
                        Capsule()
                            .stroke(priorityColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Suggestion Slot Button

struct SuggestionSlotButton: View {
    let suggestion: TaskScheduleSuggestion
    let onSelect: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticsService.shared.success()
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Time
                Text(suggestion.suggestedTime.formatted(.dateTime.hour().minute()))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                // Confidence
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10))
                    Text("\(Int(suggestion.confidence * 100))% match")
                        .font(Theme.Typography.caption2)
                }
                .foregroundStyle(Theme.Colors.aiPurple)

                // Reason
                Text(suggestion.reason)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
                    .frame(width: 140, alignment: .leading)
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Theme.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Task Schedule Suggestion

struct TaskScheduleSuggestion: Identifiable, Sendable {
    let id = UUID()
    let taskId: UUID
    let suggestedTime: Date
    let confidence: Double
    let reason: String
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.calendar

        CalendarAISuggestionsOverlay(
            unscheduledTasks: [],
            onSchedule: { _, _ in },
            onDismiss: {}
        )
    }
}
