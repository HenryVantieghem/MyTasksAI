//
//  TaskCardUnified.swift
//  Veloce
//
//  Unified Task Card - Clean, Simple, Utopian Design
//  Replaces: TaskCardV2, V3, V4, V5, TaskCardView (~2,500+ lines → ~200 lines)
//
//  Design Philosophy:
//  - Content layer: Solid background (NOT glass)
//  - Clear hierarchy: Checkbox → Title → Metadata
//  - Gold gamification: Stars + XP badge
//  - Rewarding completion animation
//

import SwiftUI

// MARK: - Unified Task Card

struct TaskCardUnified: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @State private var isPressed = false
    @State private var showCompletion = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: {
            HapticsService.shared.selectionFeedback()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Checkbox
                checkboxView

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title + Stars
                    HStack {
                        Text(task.title)
                            .font(UtopianDesignFallback.Typography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(task.isCompleted ? .secondary : .white)
                            .strikethrough(task.isCompleted)
                            .lineLimit(2)

                        Spacer()

                        // Priority stars (gold)
                        if !task.isCompleted {
                            priorityStars
                        }
                    }

                    // Metadata row
                    metadataRow
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(UtopianDesignFallback.Spacing.md)
            .contentCard()
        }
        .buttonStyle(TaskCardButtonStyle(isPressed: $isPressed, reduceMotion: reduceMotion))
        .opacity(task.isCompleted ? 0.7 : 1.0)
        .overlay(alignment: .center) {
            if showCompletion {
                completionBurst
            }
        }
    }

    // MARK: - Checkbox

    private var checkboxView: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if !task.isCompleted {
                    showCompletion = true
                    HapticsService.shared.success()
                }
                onToggleComplete()
            }
            // Reset completion animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showCompletion = false
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(
                        task.isCompleted
                            ? Color(hex: "#10B981") // Completed green
                            : Color.white.opacity(0.4),
                        lineWidth: 2
                    )
                    .frame(width: 28, height: 28)

                if task.isCompleted {
                    Circle()
                        .fill(Color(hex: "#10B981"))
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Priority Stars (Gold Theme)

    private var priorityStars: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < task.starRating ? "star.fill" : "star")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        index < task.starRating
                            ? Color(hex: "#FFC145") // Gold star
                            : Color.white.opacity(0.2)
                    )
            }
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: 8) {
            // Duration
            if let minutes = task.estimatedMinutes, minutes > 0 {
                metadataChip(icon: "clock", text: "\(minutes)m")
            }

            // Due date
            if let scheduledTime = task.scheduledTime {
                metadataChip(
                    icon: "calendar",
                    text: formatDate(scheduledTime),
                    color: task.isOverdue ? Color(hex: "#EF4444") : nil
                )
            }

            // Recurring
            if task.isRecurring {
                metadataChip(icon: "repeat", text: task.recurringExtended.shortLabel)
            }

            Spacer()

            // XP Badge (gold theme)
            xpBadge
        }
    }

    // MARK: - Metadata Chip

    private func metadataChip(icon: String, text: String, color: Color? = nil) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color ?? .white.opacity(0.6))
    }

    // MARK: - XP Badge

    private var xpBadge: some View {
        let points = task.pointsEarned > 0 ? task.pointsEarned : 25

        return HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 9, weight: .bold))
            Text("+\(points)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color(hex: "#FFD700")) // XP Gold
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "#FFD700").opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Completion Burst Animation

    private var completionBurst: some View {
        ZStack {
            // Expanding ring
            Circle()
                .stroke(Color(hex: "#10B981").opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 60)
                .scaleEffect(showCompletion ? 2 : 0.5)
                .opacity(showCompletion ? 0 : 1)

            // Gold flash
            Circle()
                .fill(Color(hex: "#FFD700").opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(showCompletion ? 1.5 : 0.5)
                .opacity(showCompletion ? 0 : 0.8)
        }
        .animation(.easeOut(duration: 0.5), value: showCompletion)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
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
}

// MARK: - Button Style

private struct TaskCardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.7),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview("TaskCardUnified - Utopian Design") {
    ZStack {
        UtopianGradients.background(for: Date())
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 12) {
                Text("Unified Task Cards")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                TaskCardUnified(
                    task: {
                        let t = TaskItem(title: "Design quarterly presentation")
                        t.estimatedMinutes = 45
                        t.starRating = 3
                        t.scheduledTime = Date().addingTimeInterval(3600)
                        return t
                    }(),
                    onTap: {},
                    onToggleComplete: {}
                )

                TaskCardUnified(
                    task: {
                        let t = TaskItem(title: "Quick 15-minute review")
                        t.estimatedMinutes = 15
                        t.starRating = 2
                        t.setRecurringExtended(type: .daily, customDays: nil, endDate: nil)
                        return t
                    }(),
                    onTap: {},
                    onToggleComplete: {}
                )

                TaskCardUnified(
                    task: {
                        let t = TaskItem(title: "Completed task example")
                        t.estimatedMinutes = 30
                        t.starRating = 1
                        t.isCompleted = true
                        t.pointsEarned = 35
                        return t
                    }(),
                    onTap: {},
                    onToggleComplete: {}
                )

                TaskCardUnified(
                    task: {
                        let t = TaskItem(title: "Overdue task - needs attention")
                        t.estimatedMinutes = 20
                        t.starRating = 3
                        t.scheduledTime = Date().addingTimeInterval(-3600) // Past due
                        return t
                    }(),
                    onTap: {},
                    onToggleComplete: {}
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
}
