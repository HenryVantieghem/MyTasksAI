//
//  DailyBriefView.swift
//  Veloce
//
//  Daily Brief View - Morning productivity summary
//  One-tap schedule acceptance with personalized insights
//

import SwiftUI

// MARK: - Daily Brief View

struct DailyBriefView: View {
    let brief: DailyBrief
    let onAcceptSchedule: () async throws -> Void
    let onDismiss: () -> Void

    @State private var isAccepting = false
    @State private var showSuccess = false
    @State private var sectionsRevealed = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                VoidBackground.momentum

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Greeting & Score
                        headerSection
                            .staggeredReveal(isVisible: sectionsRevealed, delay: 0, direction: .scale)

                        // Streak Status
                        streakSection
                            .staggeredReveal(isVisible: sectionsRevealed, delay: 0.1, direction: .fromBottom)

                        // Priority Tasks
                        if !brief.priorityTasks.isEmpty {
                            priorityTasksSection
                                .staggeredReveal(isVisible: sectionsRevealed, delay: 0.2, direction: .fromBottom)
                        }

                        // Schedule Suggestions
                        if brief.hasSuggestions {
                            scheduleSuggestionsSection
                                .staggeredReveal(isVisible: sectionsRevealed, delay: 0.3, direction: .fromBottom)
                        }

                        // Insight Card
                        insightSection
                            .staggeredReveal(isVisible: sectionsRevealed, delay: 0.4, direction: .fromBottom)

                        // Focus Suggestion
                        focusSuggestionSection
                            .staggeredReveal(isVisible: sectionsRevealed, delay: 0.5, direction: .fromBottom)

                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                    .padding(.top, Theme.Spacing.lg)
                }
            }
            .navigationTitle("Daily Brief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sectionsRevealed = true
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Date
            Text(brief.formattedDate)
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(.secondary)

            // Greeting
            Text(brief.greeting)
                .dynamicTypeFont(base: 28, weight: .bold)
                .foregroundStyle(.primary)

            // Velocity Score
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.accent.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Text("\(brief.velocityScore)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Velocity Score")
                        .dynamicTypeFont(base: 12, weight: .medium)
                        .foregroundStyle(.secondary)
                    Text(brief.summaryText)
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: brief.streakStatus.icon)
                .dynamicTypeFont(base: 24)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(brief.streakStatus.message)
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - Priority Tasks Section

    private var priorityTasksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "star.fill")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(.yellow)
                Text("Priority Tasks")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                Spacer()
            }

            ForEach(brief.priorityTasks) { task in
                HStack(spacing: Theme.Spacing.sm) {
                    SwiftUI.Circle()
                        .stroke(Theme.Colors.accent, lineWidth: 2)
                        .frame(width: 20, height: 20)

                    Text(task.title)
                        .dynamicTypeFont(base: 14)
                        .lineLimit(1)

                    Spacer()

                    if let time = task.scheduledTime {
                        Text(time.formatted(.dateTime.hour().minute()))
                            .dynamicTypeFont(base: 12, weight: .medium)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Schedule Suggestions Section

    private var scheduleSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Theme.Colors.accent)
                Text("AI Schedule Suggestions")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                Spacer()

                Text("\(brief.suggestedSchedule.count) tasks")
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(.secondary)
            }

            ForEach(brief.suggestedSchedule) { suggestion in
                HStack(spacing: Theme.Spacing.md) {
                    // Time
                    Text(suggestion.formattedTime)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 60, alignment: .leading)

                    // Task title
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.task?.title ?? "Task")
                            .dynamicTypeFont(base: 14)
                            .lineLimit(1)

                        Text(suggestion.reason)
                            .dynamicTypeFont(base: 11)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Confidence
                    Text("\(suggestion.confidencePercentage)%")
                        .dynamicTypeFont(base: 11, weight: .medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)

                if suggestion.id != brief.suggestedSchedule.last?.id {
                    Divider()
                }
            }

            // Accept All Button
            Button {
                acceptSchedule()
            } label: {
                HStack {
                    if isAccepting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Accept Schedule")
                    }
                }
                .dynamicTypeFont(base: 15, weight: .semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.accentGradient)
                }
            }
            .buttonStyle(.plain)
            .disabled(isAccepting)
            .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 12, y: 4)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - Insight Section

    private var insightSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .dynamicTypeFont(base: 20)
                .foregroundStyle(.yellow)

            Text(brief.insight)
                .dynamicTypeFont(base: 14)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - Focus Suggestion Section

    private var focusSuggestionSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "timer")
                .dynamicTypeFont(base: 20)
                .foregroundStyle(Theme.Colors.aiAmber)

            VStack(alignment: .leading, spacing: 2) {
                Text("Focus Tip")
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(.secondary)
                Text(brief.focusSuggestion)
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .dynamicTypeFont(base: 12, weight: .semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .dynamicTypeFont(base: 64)
                    .foregroundStyle(.green)

                Text("Schedule Accepted!")
                    .dynamicTypeFont(base: 20, weight: .bold)

                Text("Your tasks have been scheduled")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(.secondary)
            }
            .padding(Theme.Spacing.xl)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func acceptSchedule() {
        isAccepting = true
        HapticsService.shared.impact()

        Task {
            do {
                try await onAcceptSchedule()
                HapticsService.shared.success()

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showSuccess = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showSuccess = false
                    }
                    onDismiss()
                }
            } catch {
                HapticsService.shared.error()
            }
            isAccepting = false
        }
    }
}

// MARK: - Preview

#Preview {
    DailyBriefView(
        brief: DailyBrief(
            date: Date(),
            greeting: "Good morning, Henry",
            velocityScore: 72,
            scheduledTasksCount: 3,
            priorityTasks: [],
            suggestedSchedule: [],
            insight: "You're 40% more productive in the morning",
            streakStatus: .active(days: 7),
            focusSuggestion: "Try a 25-min Pomodoro to start"
        ),
        onAcceptSchedule: { },
        onDismiss: { }
    )
    .preferredColorScheme(.dark)
}
