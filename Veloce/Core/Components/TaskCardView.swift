//
//  TaskCardView.swift
//  Veloce
//
//  Task Card View
//  Enhanced glass morphic task card with AI advice
//

import SwiftUI

// MARK: - Task Card View

struct TaskCardView: View {
    let task: TaskItem
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    @State private var isCompleting = false
    @State private var completionGlow: Double = 0
    @State private var showParticles = false
    @State private var isPressed = false
    @State private var glowOpacity: Double = 0.2
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content section
            HStack(spacing: Theme.Spacing.md) {
                // Checkbox
                TaskCardCheckbox(
                    isChecked: task.isCompleted,
                    isAnimating: isCompleting
                ) {
                    triggerCompletion()
                }

                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    // Title - larger and more prominent
                    Text(task.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(task.isCompleted ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                        .strikethrough(task.isCompleted, color: Theme.Colors.textTertiary)
                        .lineLimit(2)

                    // Metadata row with all indicators
                    if hasMetadata {
                        HStack(spacing: Theme.Spacing.md) {
                            // Priority stars
                            if task.starRating > 0 {
                                HStack(spacing: Theme.Spacing.xxs) {
                                    ForEach(0..<task.starRating, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Theme.Colors.xp)
                                    }
                                }
                            }

                            // Due date badge
                            if let scheduledTime = task.scheduledTime {
                                DueDateBadge(date: scheduledTime)
                            }

                            // Time estimate badge
                            if let minutes = task.estimatedMinutes, minutes > 0 {
                                TimeEstimateBadge(minutes: minutes)
                            }

                            // AI processed indicator
                            if task.aiProcessedAt != nil {
                                HStack(spacing: Theme.Spacing.xxs) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10, weight: .medium))
                                    Text("AI")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundStyle(Theme.CelestialColors.nebulaCore)
                            }
                        }
                    }
                }

                Spacer(minLength: Theme.Spacing.sm)

                // Chevron with subtle glow
                ZStack {
                    if task.hasAIProcessing {
                        Circle()
                            .fill(Theme.CelestialColors.nebulaCore.opacity(0.15))
                            .frame(width: 28, height: 28)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(task.hasAIProcessing ? Theme.CelestialColors.nebulaCore : Theme.Colors.textTertiary.opacity(0.5))
                }
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.vertical, Theme.Spacing.lg)

            // AI Advice section (if available)
            if let aiAdvice = task.aiAdvice, !aiAdvice.isEmpty, !task.isCompleted {
                VStack(spacing: 0) {
                    // Divider
                    Rectangle()
                        .fill(Theme.Colors.glassBorder.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, Theme.Spacing.lg)

                    // AI Advice content
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        // Lightbulb icon with glow
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.xp.opacity(0.15))
                                .frame(width: 24, height: 24)

                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.Colors.xp)
                        }

                        Text(aiAdvice)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                    .padding(.vertical, Theme.Spacing.md + 2)
                }
            }
        }
        .background(cardBackground)
        .overlay(cardBorderOverlay)
        .overlay(completionGlowOverlay)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
        .contentShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
        .shadow(color: cardShadowColor, radius: Theme.Spacing.md, y: Theme.Spacing.xs)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(Theme.Animation.quickSpring, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    HapticsService.shared.selectionFeedback()
                    onTap()
                }
        )
        .onAppear {
            if task.hasAIProcessing {
                startAIGlow()
            }
        }
    }

    // MARK: - Helpers

    private var hasMetadata: Bool {
        task.starRating > 0 || task.scheduledTime != nil || task.aiProcessedAt != nil || (task.estimatedMinutes ?? 0) > 0
    }

    // Task type color for consistency with TaskCardV2
    private var taskTypeColor: Color {
        switch task.taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            // Base glass material
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(.ultraThinMaterial)

            // Task type tint gradient (consistent with TaskCardV2)
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
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

            // Gradient overlay for depth
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.glassBackground.opacity(colorScheme == .dark ? 0.15 : 0.08),
                            Theme.Colors.glassBackground.opacity(colorScheme == .dark ? 0.05 : 0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Card Border

    private var cardBorderOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                        .white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                        task.hasAIProcessing ? taskTypeColor.opacity(glowOpacity) : Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: task.hasAIProcessing ? 1.5 : 1
            )
    }

    // MARK: - Card Shadow

    private var cardShadowColor: Color {
        if task.hasAIProcessing {
            return taskTypeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)
        }
        return Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08)
    }

    // MARK: - Completion Glow

    private var completionGlowOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
            .stroke(Theme.CelestialColors.successNebula, lineWidth: 3)
            .blur(radius: Theme.Spacing.sm)
            .opacity(completionGlow)
    }

    // MARK: - AI Glow Animation

    private func startAIGlow() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.4
        }
    }

    // MARK: - Completion Animation

    private func triggerCompletion() {
        guard !isCompleting else { return }

        isCompleting = true
        HapticsService.shared.taskComplete()

        // Glow animation
        withAnimation(.easeIn(duration: 0.2)) {
            completionGlow = 0.8
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            completionGlow = 0
        }

        // Trigger completion callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onToggleComplete()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isCompleting = false
        }
    }
}

// MARK: - Task Card Checkbox

struct TaskCardCheckbox: View {
    let isChecked: Bool
    let isAnimating: Bool
    let action: () -> Void

    @State private var scale: CGFloat = 1
    @State private var checkmarkProgress: CGFloat = 0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(isChecked ? Theme.Colors.success : Theme.Colors.glassBorder, lineWidth: 2)
                    .frame(width: 24, height: 24)

                // Filled background when checked
                if isChecked {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 24, height: 24)

                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkmarkProgress)
                }
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .onChange(of: isChecked) { _, checked in
            if checked {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.2
                    checkmarkProgress = 1
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7).delay(0.1)) {
                    scale = 1
                }
            } else {
                checkmarkProgress = 0
            }
        }
    }
}

// MARK: - Due Date Badge

struct DueDateBadge: View {
    let date: Date

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 9, weight: .medium))

            Text(formattedDate)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(dateColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(dateColor.opacity(0.1))
        )
    }

    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    private var dateColor: Color {
        let calendar = Calendar.current
        if date < Date() {
            return Theme.Colors.error
        } else if calendar.isDateInToday(date) {
            return Theme.Colors.warning
        }
        return Theme.Colors.textSecondary
    }
}

// MARK: - Time Estimate Badge

struct TimeEstimateBadge: View {
    let minutes: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 9, weight: .medium))

            Text(formattedTime)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Theme.Colors.aiBlue)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Theme.Colors.aiBlue.opacity(0.1))
        )
    }

    private var formattedTime: String {
        if minutes < 60 {
            return "~\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "~\(hours)h"
            } else {
                return "~\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TaskCardView(
            task: TaskItem(title: "Complete the project proposal"),
            onToggleComplete: { },
            onTap: { }
        )

        TaskCardView(
            task: {
                let task = TaskItem(title: "Review design mockups with the team", scheduledTime: Date().addingTimeInterval(3600), starRating: 3)
                return task
            }(),
            onToggleComplete: { },
            onTap: { }
        )

        TaskCardView(
            task: {
                let task = TaskItem(title: "Completed task example", isCompleted: true)
                return task
            }(),
            onToggleComplete: { },
            onTap: { }
        )
    }
    .padding()
    .background(IridescentBackground(intensity: 0.4))
}
