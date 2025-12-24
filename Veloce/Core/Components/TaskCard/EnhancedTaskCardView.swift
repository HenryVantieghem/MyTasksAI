//
//  EnhancedTaskCardView.swift
//  MyTasksAI
//
//  Enhanced collapsed task card with:
//  - Task type orb (breathing, color-coded)
//  - Points potential badge with glow
//  - AI quick tip (5-sentence motivation)
//  - Metadata row (stars, time, AI badge, due date)
//  - Show more indicator (glows if AI enhanced)
//  - High-priority breathing animation
//  - Satisfying completion animation
//

import SwiftUI

// MARK: - Enhanced Task Card View

struct EnhancedTaskCardView: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @State private var isPressed: Bool = false
    @State private var breathePhase: CGFloat = 0
    @State private var showCompletionBurst: Bool = false
    @State private var checkmarkScale: CGFloat = 1
    @State private var isAIProcessing: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var taskTypeColor: Color {
        switch task.taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    private var potentialPoints: Int {
        var points = DesignTokens.Gamification.pointsTaskComplete
        if task.starRating == 3 { points += 10 }
        else if task.starRating == 2 { points += 5 }
        if task.hasAIProcessing { points += 2 }
        if task.isScheduled { points += 3 }
        return points
    }

    private var isHighPriority: Bool {
        task.starRating == 3
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            cardContent
        }
        .buttonStyle(TaskCardButtonStyle(isPressed: $isPressed))
        .onAppear {
            if isHighPriority && !reduceMotion {
                startBreathingAnimation()
            }
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Top row: Checkbox + Title + Points
            topRow

            // AI Quick Tip (if available)
            if let quickTip = task.aiQuickTip, !quickTip.isEmpty {
                aiQuickTipView(quickTip)
            }

            // Metadata row
            metadataRow

            // Show more indicator
            showMoreIndicator
        }
        .padding(Theme.Spacing.md)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .overlay(cardBorder)
        .shadow(
            color: isHighPriority
                ? taskTypeColor.opacity(0.2 + breathePhase * 0.1)
                : .black.opacity(0.1),
            radius: isHighPriority ? 8 + breathePhase * 4 : 4,
            y: 2
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Completion checkbox with task type orb
            completionCheckbox

            // Task title
            Text(task.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            // Points badge
            pointsBadge
        }
    }

    // MARK: - Completion Checkbox

    private var completionCheckbox: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                checkmarkScale = 0.8
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onToggleComplete()

                if !task.isCompleted {
                    showCompletionBurst = true
                    triggerCompletionHaptic()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCompletionBurst = false
                    }
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    checkmarkScale = 1
                }
            }
        } label: {
            ZStack {
                // Task type orb (background)
                TaskTypeOrb(
                    color: taskTypeColor,
                    isActive: !task.isCompleted,
                    size: 24
                )

                // Checkmark overlay when completed
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkmarkScale)
                }

                // Completion burst effect
                if showCompletionBurst {
                    MiniBloom(color: Theme.TaskCardColors.startHere)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Points Badge

    private var pointsBadge: some View {
        TaskPointsBadge(points: potentialPoints, isEarned: task.isCompleted)
    }

    // MARK: - AI Quick Tip

    private func aiQuickTipView(_ tip: String) -> some View {
        HStack(spacing: 4) {
            Text("💡")
                .font(.system(size: 12))

            Text(tip)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.leading, 32) // Align with title after checkbox
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Priority stars
            Text(task.priorityStars)
                .font(.system(size: 12))
                .foregroundStyle(task.priority.color)

            // Time estimate
            if let estimate = task.estimatedTimeFormatted {
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(estimate)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }

            // AI badge
            if task.hasAIProcessing {
                AIBadgeAnimated(isProcessing: isAIProcessing)
            }

            Spacer()

            // Due date
            if let scheduledDate = task.scheduledDateFormatted {
                HStack(spacing: 2) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(scheduledDate)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(task.isOverdue ? Theme.Colors.error : .secondary)
            }
        }
        .padding(.leading, 32) // Align with title
    }

    // MARK: - Show More Indicator

    private var showMoreIndicator: some View {
        HStack {
            Spacer()

            HStack(spacing: 4) {
                Text("more")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(task.hasAIProcessing ? taskTypeColor : .secondary)
            .opacity(task.hasAIProcessing ? 0.8 + breathePhase * 0.2 : 0.6)
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            // Base material
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(.ultraThinMaterial)

            // Subtle gradient overlay for task type
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            taskTypeColor.opacity(0.05),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // High priority breathing glow
            if isHighPriority && !reduceMotion {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(taskTypeColor.opacity(0.03 * breathePhase))
            }
        }
    }

    // MARK: - Card Border

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
            .stroke(
                LinearGradient(
                    colors: task.hasAIProcessing
                        ? [taskTypeColor.opacity(0.4), taskTypeColor.opacity(0.1)]
                        : [Theme.Colors.glassBorder.opacity(0.3), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: task.hasAIProcessing ? 1.5 : 1
            )
    }

    // MARK: - Animations

    private func startBreathingAnimation() {
        withAnimation(Theme.GeniusAnimation.cardBreathing) {
            breathePhase = 1
        }
    }

    private func triggerCompletionHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Task Card Button Style

struct TaskCardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}

// MARK: - Task Type Orb

struct TaskTypeOrb: View {
    let color: Color
    let isActive: Bool
    let size: CGFloat

    @State private var breathePhase: CGFloat = 0
    @State private var glowPhase: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Outer glow
            SwiftUI.Circle()
                .fill(color.opacity(0.3 * glowPhase))
                .frame(width: size * 1.3, height: size * 1.3)
                .blur(radius: 3)

            // Main orb
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.9),
                            color.opacity(0.6)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(1 + breathePhase * 0.08)

            // Highlight
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.6), .clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.3
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(x: -size * 0.1, y: -size * 0.1)
        }
        .frame(width: size, height: size)
        .onAppear {
            if isActive && !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    breathePhase = 1
                    glowPhase = 1
                }
            }
        }
    }
}

// MARK: - Task Points Badge

struct TaskPointsBadge: View {
    let points: Int
    let isEarned: Bool

    @State private var glowPhase: CGFloat = 0.5

    var body: some View {
        HStack(spacing: 2) {
            Text("+\(points)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Text("🔥")
                .font(.system(size: 10))
        }
        .foregroundStyle(isEarned ? Theme.TaskCardColors.startHere : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    isEarned
                        ? Theme.TaskCardColors.startHere.opacity(0.15)
                        : Color.secondary.opacity(0.1)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isEarned
                                ? Theme.TaskCardColors.pointsGlow.opacity(0.4 * glowPhase)
                                : .clear,
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: isEarned
                ? Theme.TaskCardColors.pointsGlow.opacity(0.3 * glowPhase)
                : .clear,
            radius: 4
        )
        .onAppear {
            if isEarned && !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
            }
        }
    }
}

// MARK: - AI Motivation Pill

struct AIMotivationPill: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 10))
                .foregroundStyle(Theme.TaskCardColors.strategy)

            Text(text)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.TaskCardColors.strategy.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // High priority with AI
            EnhancedTaskCardView(
                task: {
                    let task = TaskItem(title: "Write quarterly business report for stakeholders")
                    task.starRating = 3
                    task.estimatedMinutes = 60
                    task.taskTypeRaw = TaskType.create.rawValue
                    task.aiAdvice = "Focus on key metrics"
                    task.aiQuickTip = "Start with just the executive summary. The rest will flow naturally."
                    task.scheduledTime = Date()
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )

            // Medium priority
            EnhancedTaskCardView(
                task: {
                    let task = TaskItem(title: "Schedule team sync meeting")
                    task.starRating = 2
                    task.estimatedMinutes = 15
                    task.taskTypeRaw = TaskType.coordinate.rawValue
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )

            // Completed task
            EnhancedTaskCardView(
                task: {
                    let task = TaskItem(title: "Review pull request")
                    task.starRating = 1
                    task.estimatedMinutes = 20
                    task.taskTypeRaw = TaskType.consume.rawValue
                    task.isCompleted = true
                    task.pointsEarned = 12
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
