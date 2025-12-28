//
//  GoalSpotlightCard.swift
//  MyTasksAI
//
//  Goal Spotlight Card for Momentum Tab
//  Displays the most urgent goal with progress visualization
//

import SwiftUI

// MARK: - Goal Spotlight Card
struct GoalSpotlightCard: View {
    let goal: Goal
    var linkedTasksProgress: Double = 0
    var onTap: () -> Void

    @State private var glowPulse: Double = 0.5
    @State private var isPressed = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header: Timeframe + Days Remaining
                header

                // Main content: Orb + Title
                HStack(spacing: 16) {
                    GoalStatusOrb(goal: goal, size: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.displayTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let aiTitle = goal.aiRefinedTitle, aiTitle != goal.title {
                            Text(goal.title)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        }

                        // Category badge
                        if let category = goal.categoryEnum {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 10))
                                Text(category.displayName)
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(category.color.opacity(0.8))
                        }
                    }

                    Spacer(minLength: 0)
                }

                // Milestone progress
                if goal.milestoneCount > 0 {
                    MilestoneProgressBar(
                        completed: goal.completedMilestoneCount,
                        total: goal.milestoneCount,
                        accentColor: goal.themeColor
                    )
                }

                // Linked tasks summary
                if goal.linkedTaskCount > 0 {
                    LinkedTasksSummary(
                        count: goal.linkedTaskCount,
                        progress: linkedTasksProgress
                    )
                }

                // Check-in prompt if due
                if goal.isCheckInDue {
                    checkInPrompt
                }

                // AI quote if available
                if let quote = goal.aiMotivationalQuote {
                    aiQuote(quote)
                }
            }
            .padding(20)
            .background(cardBackground)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            if let timeframe = goal.timeframeEnum {
                TimeframeBadge(timeframe: timeframe, size: .compact)
            }

            Spacer()

            if let daysRemaining = goal.daysRemaining {
                DaysRemainingPill(days: daysRemaining, isOverdue: goal.isOverdue)
            }
        }
    }

    private var checkInPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.warning)

            Text("Weekly check-in due")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Colors.warning)

            Spacer()

            Text("Tap to complete")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.Colors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.Colors.warning.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    private func aiQuote(_ quote: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.aiPurple.opacity(0.6))

            Text(quote)
                .font(.system(size: 12).italic())
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(2)
        }
        .padding(.top, 4)
    }

    private var cardBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.clear)
            
            // Subtle tint overlay
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            goal.themeColor.opacity(0.12 * glowPulse),
                            goal.themeColor.opacity(0.06 * glowPulse),
                            .clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
        }
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            // Premium border
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            goal.themeColor.opacity(0.4),
                            goal.themeColor.opacity(0.2),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: goal.themeColor.opacity(0.2 * glowPulse),
            radius: 20,
            y: 10
        )
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPulse = 1.0
        }
    }
}

// MARK: - Goal Spotlight Section
/// Container for the spotlight card with add button
struct GoalSpotlightSection: View {
    let spotlightGoal: Goal?
    let linkedTasksProgress: Double
    var onGoalTap: (Goal) -> Void
    var onAddGoal: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Label("Goals", systemImage: "target")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Button(action: onAddGoal) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.aiPurple.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            // Spotlight card or empty state
            if let goal = spotlightGoal {
                GoalSpotlightCard(
                    goal: goal,
                    linkedTasksProgress: linkedTasksProgress,
                    onTap: { onGoalTap(goal) }
                )
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        Button(action: onAddGoal) {
            VStack(spacing: 16) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiPurple.opacity(0.1))
                        .frame(width: 64, height: 64)

                    Image(systemName: "target")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Colors.aiPurple.opacity(0.6))
                }

                VStack(spacing: 4) {
                    Text("Set Your First Goal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Turn your aspirations into achievements with AI-powered planning")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Create Goal")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Theme.Colors.aiPurple)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Theme.Colors.aiPurple.opacity(0.15))
                )
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Theme.Colors.aiPurple.opacity(0.2),
                                style: StrokeStyle(lineWidth: 1, dash: [8, 8])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Card (Compact)
/// Smaller goal card for lists
struct GoalCardCompact: View {
    let goal: Goal
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                GoalProgressRing(
                    progress: goal.progress,
                    size: 44,
                    lineWidth: 4,
                    accentColor: goal.themeColor
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let timeframe = goal.timeframeEnum {
                            TimeframeBadge(timeframe: timeframe, size: .compact, showLabel: false)
                        }

                        if let days = goal.daysRemaining {
                            Text(days == 0 ? "Today" : "\(days)d")
                                .font(.system(size: 11))
                                .foregroundStyle(
                                    days <= 3 ? Theme.Colors.warning : Theme.Colors.textTertiary
                                )
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews
#Preview("Spotlight Card") {
    ScrollView {
        VStack(spacing: 20) {
            // Mock goal
            let goal = Goal(
                title: "Launch my productivity app",
                goalDescription: "Ship the MVP of MyTasksAI to the App Store",
                targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                category: GoalCategory.career.rawValue,
                timeframe: GoalTimeframe.milestone.rawValue
            )

            GoalSpotlightCard(
                goal: goal,
                linkedTasksProgress: 0.4,
                onTap: {}
            )
        }
        .padding()
    }
    .background(Theme.CelestialColors.void)
}

#Preview("Spotlight Section") {
    ScrollView {
        VStack(spacing: 20) {
            // With goal
            GoalSpotlightSection(
                spotlightGoal: Goal(
                    title: "Learn SwiftUI",
                    targetDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                    category: GoalCategory.education.rawValue,
                    timeframe: GoalTimeframe.milestone.rawValue
                ),
                linkedTasksProgress: 0.3,
                onGoalTap: { _ in },
                onAddGoal: {}
            )

            Divider().background(.white.opacity(0.2))

            // Empty state
            GoalSpotlightSection(
                spotlightGoal: nil,
                linkedTasksProgress: 0,
                onGoalTap: { _ in },
                onAddGoal: {}
            )
        }
        .padding()
    }
    .background(Theme.CelestialColors.void)
}
