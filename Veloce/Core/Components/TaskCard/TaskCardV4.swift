//
//  TaskCardV4.swift
//  Veloce
//
//  Apple-like Task Card - iOS 26 Ultrathink Design
//  Clean hierarchy, adaptive colors, inline Focus button
//  Solid backgrounds for content layer, glass for interactive elements
//

import SwiftUI

// MARK: - Task Card V4 (Apple Ultrathink Edition)

struct TaskCardV4: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    var onStartFocus: ((TaskItem, Int) -> Void)?
    var onSnooze: ((TaskItem) -> Void)?
    var onDelete: ((TaskItem) -> Void)?

    // Interaction states
    @State private var isPressed = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showMoreMenu = false
    @State private var selectedFocusDuration: Int = 25

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let swipeCompleteThreshold: CGFloat = 80
    private let swipeSnoozeThreshold: CGFloat = 80
    private let swipeDeleteThreshold: CGFloat = 150

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

    private var aiInsight: String? {
        if let advice = task.aiAdvice, !advice.isEmpty {
            return advice
        }
        if let tip = task.aiQuickTip, !tip.isEmpty {
            return tip
        }
        return nil
    }

    private var urgencyShadowColor: Color {
        guard let scheduledTime = task.scheduledTime else {
            return .black.opacity(0.1)
        }

        let hoursUntil = scheduledTime.timeIntervalSince(Date()) / 3600
        if hoursUntil < 0 {
            return Theme.AdaptiveColors.destructive.opacity(0.3)
        } else if hoursUntil < 2 {
            return Theme.AdaptiveColors.warning.opacity(0.25)
        }
        return .black.opacity(0.1)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Swipe action backgrounds
            swipeBackgrounds

            // Main card content
            cardContent
                .offset(x: swipeOffset)
                .gesture(swipeGesture)
        }
        .opacity(task.isCompleted ? 0.65 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.isCompleted)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap()
        } label: {
            VStack(spacing: 0) {
                // Main row: Checkbox + Title + Stars
                mainRow
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                // AI insight whisper
                if let insight = aiInsight, !task.isCompleted {
                    Text(insight)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }

                // Divider
                Divider()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                // Metadata row
                metadataRow
                    .padding(.horizontal, 16)

                // Action row: Focus button + More menu
                if !task.isCompleted {
                    actionRow
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                Spacer().frame(height: 14)
            }
            .background(cardBackground)
        }
        .buttonStyle(TaskCardV4ButtonStyle(isPressed: $isPressed, reduceMotion: reduceMotion))
    }

    // MARK: - Main Row

    private var mainRow: some View {
        HStack(spacing: 12) {
            // Elegant checkbox
            ElegantCheckBubble(
                taskTypeColor: taskTypeColor,
                isCompleted: task.isCompleted,
                onComplete: {
                    HapticsService.shared.impact(.medium)
                    onToggleComplete()
                }
            )

            // Title
            Text(task.title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            // Priority stars
            if !task.isCompleted {
                priorityStars
            }
        }
    }

    // MARK: - Priority Stars

    private var priorityStars: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < task.starRating ? "star.fill" : "star")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        index < task.starRating
                            ? Theme.AdaptiveColors.warning
                            : Color(.tertiaryLabel)
                    )
            }
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: 10) {
            // Duration estimate
            if let duration = task.estimatedMinutes, duration > 0 {
                MetadataChip(
                    icon: "clock.fill",
                    text: "\(duration)m",
                    color: Theme.AdaptiveColors.aiSecondary
                )
            }

            // Scheduled time
            if let scheduledTime = task.scheduledTime {
                MetadataChip(
                    icon: "calendar",
                    text: formatScheduledTime(scheduledTime),
                    color: Theme.AdaptiveColors.accent
                )
            }

            // Recurring indicator
            if task.isRecurring {
                MetadataChip(
                    icon: "repeat",
                    text: task.recurringExtended.shortLabel,
                    color: Theme.AdaptiveColors.aiTertiary
                )
            }

            Spacer()

            // Points badge
            if task.pointsEarned > 0 || !task.isCompleted {
                pointsBadge
            }
        }
    }

    // MARK: - Points Badge

    private var pointsBadge: some View {
        let points = task.pointsEarned > 0 ? task.pointsEarned : 25

        return HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 9, weight: .bold))

            Text("+\(points)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Theme.AdaptiveColors.success)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Theme.AdaptiveColors.success.opacity(0.12))
        )
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: 12) {
            // Focus button (Liquid Glass)
            focusButton

            Spacer()

            // More menu (Liquid Glass)
            moreMenuButton
        }
    }

    // MARK: - Focus Button

    private var focusButton: some View {
        Button {
            HapticsService.shared.impact()
            onStartFocus?(task, selectedFocusDuration)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 11, weight: .semibold))

                Text("Focus")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.AdaptiveColors.aiGradient)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .adaptiveGlassCapsule()
    }

    // MARK: - More Menu Button

    private var moreMenuButton: some View {
        Menu {
            Section {
                Button {
                    HapticsService.shared.selectionFeedback()
                    onSnooze?(task)
                } label: {
                    Label("Snooze", systemImage: "moon.fill")
                }

                Button {
                    HapticsService.shared.selectionFeedback()
                    onTap()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            Section {
                Button(role: .destructive) {
                    HapticsService.shared.warning()
                    onDelete?(task)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Theme.AdaptiveColors.cardBackground)
            .overlay {
                // Subtle task-type tint border
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                taskTypeColor.opacity(0.3),
                                taskTypeColor.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: urgencyShadowColor, radius: 8, y: 4)
    }

    // MARK: - Swipe Backgrounds

    private var swipeBackgrounds: some View {
        ZStack {
            // Right swipe background (Complete)
            HStack {
                ZStack {
                    Theme.AdaptiveColors.success.opacity(0.2)

                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.AdaptiveColors.success)
                        .opacity(swipeOffset > swipeCompleteThreshold * 0.5 ? 1 : 0)
                }
                .frame(width: max(0, swipeOffset))

                Spacer()
            }

            // Left swipe background (Snooze / Delete)
            HStack {
                Spacer()

                ZStack {
                    let isDelete = -swipeOffset > swipeDeleteThreshold
                    (isDelete ? Theme.AdaptiveColors.destructive : Theme.AdaptiveColors.warning).opacity(0.2)

                    Image(systemName: isDelete ? "trash.fill" : "moon.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(isDelete ? Theme.AdaptiveColors.destructive : Theme.AdaptiveColors.warning)
                        .opacity(-swipeOffset > swipeSnoozeThreshold * 0.5 ? 1 : 0)
                }
                .frame(width: max(0, -swipeOffset))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let translation = value.translation.width
                if translation > 0 {
                    swipeOffset = min(translation, swipeCompleteThreshold + 20)
                } else {
                    swipeOffset = max(translation, -(swipeDeleteThreshold + 20))
                }
            }
            .onEnded { value in
                let translation = value.translation.width

                if translation > swipeCompleteThreshold {
                    HapticsService.shared.success()
                    onToggleComplete()
                } else if translation < -swipeDeleteThreshold {
                    HapticsService.shared.warning()
                    onDelete?(task)
                } else if translation < -swipeSnoozeThreshold {
                    HapticsService.shared.impact(.light)
                    onSnooze?(task)
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    swipeOffset = 0
                }
            }
    }

    // MARK: - Helpers

    private func formatScheduledTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "h:mm a"
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Task Card V4 Button Style

struct TaskCardV4ButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.15, dampingFraction: 0.8),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Metadata Chip

struct MetadataChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))

            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Recurring Type Extension

extension RecurringTypeExtended {
    var shortLabel: String {
        switch self {
        case .once: return "Once"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .weekly: return "Weekly"
        case .biweekly: return "Biweekly"
        case .monthly: return "Monthly"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Preview

#Preview("TaskCardV4 - Light") {
    ScrollView {
        VStack(spacing: 16) {
            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Write quarterly report for Q4 2024 review meeting")
                    t.aiAdvice = "Break into sections: data gathering, writing, review"
                    t.estimatedMinutes = 45
                    t.starRating = 3
                    t.scheduledTime = Date().addingTimeInterval(3600)
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Review design mockups")
                    t.aiQuickTip = "Focus on mobile-first layouts"
                    t.estimatedMinutes = 20
                    t.starRating = 2
                    t.setRecurringExtended(type: .daily, customDays: nil, endDate: nil)
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Team standup call")
                    t.estimatedMinutes = 15
                    t.starRating = 1
                    t.isCompleted = true
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("TaskCardV4 - Dark") {
    ScrollView {
        VStack(spacing: 16) {
            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Prepare presentation slides")
                    t.aiAdvice = "Use company template, focus on key metrics"
                    t.estimatedMinutes = 60
                    t.starRating = 3
                    t.scheduledTime = Date().addingTimeInterval(-3600) // Overdue
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
