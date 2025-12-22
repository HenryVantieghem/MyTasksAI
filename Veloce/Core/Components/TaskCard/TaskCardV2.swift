//
//  TaskCardV2.swift
//  MyTasksAI
//
//  Task Card V2 - The Living Task
//  Premium task card with Energy Core, AI Whisper, and dynamic animations
//  Designed to feel alive, intelligent, and personally relevant
//

import SwiftUI

// MARK: - Task Card V2

struct TaskCardV2: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @State private var isPressed: Bool = false
    @State private var breathePhase: CGFloat = 0
    @State private var showWhisper: Bool = true
    @State private var isHovering: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var taskTypeColor: Color {
        switch task.taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    private var isHighPriority: Bool {
        task.starRating == 3
    }

    private var shouldShowWhisper: Bool {
        !task.isCompleted && showWhisper && hasGuidanceText
    }

    private var hasGuidanceText: Bool {
        (task.aiAdvice != nil && !task.aiAdvice!.isEmpty) ||
        (task.aiQuickTip != nil && !task.aiQuickTip!.isEmpty)
    }

    private var guidanceText: String {
        // Prefer aiAdvice, fall back to quickTip, then generate fallback
        if let advice = task.aiAdvice, !advice.isEmpty {
            return advice
        }
        if let tip = task.aiQuickTip, !tip.isEmpty {
            return tip
        }
        return AIGuidanceGenerator.generateFallback(for: task.title, taskType: task.taskType)
    }

    // MARK: - Body

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap()
        } label: {
            cardContent
        }
        .buttonStyle(TaskCardV2ButtonStyle(isPressed: $isPressed))
        .onAppear {
            if isHighPriority && !reduceMotion {
                startBreathingAnimation()
            }
        }
        .contextMenu {
            contextMenuContent
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Top row: Energy Core + Title + Points Badge
            topRow

            // AI Guidance Whisper (collapsible)
            if shouldShowWhisper {
                AIGuidanceWhisper(
                    guidance: guidanceText,
                    isExpanded: false
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showWhisper.toggle()
                    }
                }
                .padding(.leading, 36) // Align with title after energy core
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // Metadata row
            metadataRow

            // Explore prompt
            exploreIndicator
        }
        .padding(Theme.Spacing.md + 2)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg + 2))
        .overlay(cardBorder)
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            y: 2
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm + 2) {
            // Energy Core (completion toggle)
            EnergyCore(
                energyState: task.energyState,
                potentialPoints: task.potentialPoints,
                taskTypeColor: taskTypeColor,
                isCompleted: task.isCompleted,
                size: DesignTokens.EnergyCore.size
            ) {
                HapticsService.shared.impact()
                onToggleComplete()
            }

            // Task title
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary.opacity(0.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Task type label (subtle)
                if !task.isCompleted {
                    Text(task.taskType.rawValue.capitalized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(taskTypeColor.opacity(0.8))
                }
            }

            Spacer()

            // Points Badge
            EnergyPointsBadge(
                points: task.potentialPoints,
                energyState: task.energyState,
                isEarned: task.isCompleted
            )
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Time estimate
            if let estimate = task.estimatedTimeFormatted {
                metadataChip(
                    icon: "clock",
                    text: estimate,
                    color: .secondary
                )
            }

            // AI indicator
            if task.hasAIProcessing {
                AIGuidanceChip(hasGuidance: hasGuidanceText)
            }

            Spacer()

            // Due date / Scheduled
            if let scheduledTime = task.scheduledTime {
                metadataChip(
                    icon: "calendar",
                    text: formatScheduledTime(scheduledTime),
                    color: task.isOverdue ? Theme.Colors.error : .secondary
                )
            }
        }
        .padding(.leading, 36) // Align with title
    }

    private func metadataChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
    }

    private func formatScheduledTime(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    // MARK: - Explore Indicator

    private var exploreIndicator: some View {
        HStack {
            Spacer()

            HStack(spacing: 4) {
                Text("explore")
                    .font(.system(size: 11, weight: .medium))

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(
                task.hasAIProcessing
                    ? taskTypeColor.opacity(0.8 + breathePhase * 0.2)
                    : Color.secondary.opacity(0.5)
            )
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg + 2)
                .fill(.ultraThinMaterial)

            // Task type tint gradient
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg + 2)
                .fill(
                    LinearGradient(
                        colors: [
                            taskTypeColor.opacity(task.isCompleted ? 0.02 : 0.06),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // High priority breathing glow
            if isHighPriority && !task.isCompleted && !reduceMotion {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg + 2)
                    .fill(taskTypeColor.opacity(0.04 * breathePhase))
            }

            // Completion celebration overlay
            if task.isCompleted {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg + 2)
                    .fill(Theme.CelestialColors.successNebula.opacity(0.03))
            }
        }
    }

    // MARK: - Card Border

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg + 2)
            .stroke(borderGradient, lineWidth: borderWidth)
    }

    private var borderGradient: LinearGradient {
        if task.isCompleted {
            return LinearGradient(
                colors: [
                    Theme.CelestialColors.successNebula.opacity(0.3),
                    Theme.CelestialColors.successNebula.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if task.hasAIProcessing {
            return LinearGradient(
                colors: [
                    taskTypeColor.opacity(0.4),
                    Theme.Colors.aiCyan.opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderWidth: CGFloat {
        task.hasAIProcessing || task.isCompleted ? 1.5 : 1
    }

    private var shadowColor: Color {
        if task.isCompleted {
            return Theme.CelestialColors.successNebula.opacity(0.15)
        }
        if isHighPriority {
            return taskTypeColor.opacity(0.2 + breathePhase * 0.1)
        }
        return Color.black.opacity(0.1)
    }

    private var shadowRadius: CGFloat {
        isHighPriority ? 8 + breathePhase * 4 : 4
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            onToggleComplete()
        } label: {
            Label(
                task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                systemImage: task.isCompleted ? "circle" : "checkmark.circle"
            )
        }

        Divider()

        Button {
            // Future: Schedule action
        } label: {
            Label("Schedule", systemImage: "calendar")
        }

        Button {
            // Future: AI enhance action
        } label: {
            Label("AI Enhance", systemImage: "sparkles")
        }
    }

    // MARK: - Animations

    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 3)
            .repeatForever(autoreverses: true)
        ) {
            breathePhase = 1
        }
    }
}

// MARK: - Button Style

private struct TaskCardV2ButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
                if pressed {
                    HapticsService.shared.selectionFeedback()
                }
            }
    }
}

// MARK: - Preview

#Preview("Task Card V2") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Task Card V2")
                .font(.title2.bold())
                .foregroundStyle(.white)

            // High priority task with AI
            TaskCardV2(
                task: {
                    let task = TaskItem(title: "Write quarterly report")
                    task.starRating = 3
                    task.aiAdvice = "You've totally got this! Start by just outlining the three main sections. Your future self will thank you for getting the structure down first."
                    task.aiProcessedAt = .now
                    task.taskTypeRaw = TaskType.create.rawValue
                    task.estimatedMinutes = 60
                    task.scheduledTime = Calendar.current.date(byAdding: .hour, value: 2, to: .now)
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )

            // Medium priority task
            TaskCardV2(
                task: {
                    let task = TaskItem(title: "Send email to Nicholas")
                    task.starRating = 2
                    task.taskTypeRaw = TaskType.communicate.rawValue
                    task.estimatedMinutes = 15
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )

            // Low priority completed task
            TaskCardV2(
                task: {
                    let task = TaskItem(title: "Review meeting notes")
                    task.starRating = 1
                    task.isCompleted = true
                    task.taskTypeRaw = TaskType.consume.rawValue
                    task.pointsEarned = 25
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )

            // Max energy task
            TaskCardV2(
                task: {
                    let task = TaskItem(title: "Prepare presentation for board meeting")
                    task.starRating = 3
                    task.aiAdvice = "This is your moment to shine! Break it into slides - intro, 3 key points, conclusion. You've done harder things before."
                    task.aiProcessedAt = .now
                    task.taskTypeRaw = TaskType.create.rawValue
                    task.estimatedMinutes = 120
                    task.scheduledTime = Calendar.current.date(byAdding: .day, value: 1, to: .now)
                    return task
                }(),
                onTap: {},
                onToggleComplete: {}
            )
        }
        .padding()
    }
    .background(Theme.CelestialColors.void)
}
