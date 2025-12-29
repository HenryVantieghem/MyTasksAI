//
//  TaskCardV4.swift
//  Veloce
//
//  Cosmic Widget Task Card - Bold Category Colors + Dark Void
//  4px category color bar on left edge with glow halo
//  Solid void background - NO glass on content layer
//

import SwiftUI

// MARK: - Task Card V4 (Cosmic Widget Edition)

struct TaskCardV4: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    var onStartFocus: ((TaskItem, Int) -> Void)?
    var onSnooze: ((TaskItem) -> Void)?
    var onDelete: ((TaskItem) -> Void)?

    /// Set to true to show AI thinking animation (e.g., after task creation)
    var showAIThinking: Bool = false
    var onAIThinkingComplete: (() -> Void)?

    // Interaction states
    @State private var isPressed = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showMoreMenu = false
    @State private var selectedFocusDuration: Int = 25
    @State private var isShowingAIThinking = false

    @Environment(\.responsiveLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let swipeCompleteThreshold: CGFloat = 80
    private let swipeSnoozeThreshold: CGFloat = 80
    private let swipeDeleteThreshold: CGFloat = 150
    private let categoryBarWidth: CGFloat = 4

    // MARK: - Computed Properties

    /// Category color based on task type - ULTRA SATURATED
    private var categoryColor: Color {
        // Map task type to CosmicWidget category colors
        switch task.taskType {
        case .create: return CosmicWidget.Category.creative      // Magenta
        case .communicate: return CosmicWidget.Category.personal // Orange
        case .consume: return CosmicWidget.Category.learning     // Violet
        case .coordinate: return CosmicWidget.Category.work      // Teal
        }
    }

    /// Legacy taskTypeColor for backward compatibility
    private var taskTypeColor: Color {
        categoryColor
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
        .aiThinkingOverlay(
            isThinking: $isShowingAIThinking,
            duration: 3.0,
            onComplete: {
                onAIThinkingComplete?()
            }
        )
        // Premium glow on newly created tasks (during AI thinking)
        .premiumGlowRoundedRect(
            cornerRadius: 16,
            style: .aiAccent,
            intensity: isShowingAIThinking ? .subtle : .whisper,
            animated: isShowingAIThinking && !reduceMotion
        )
        .opacity(task.isCompleted ? 0.65 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.isCompleted)
        .onChange(of: showAIThinking) { _, newValue in
            if newValue {
                isShowingAIThinking = true
            }
        }
        .onAppear {
            if showAIThinking {
                isShowingAIThinking = true
            }
        }
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
                    .padding(.horizontal, layout.cardPadding)
                    .padding(.top, layout.cardPadding - 2)

                // AI insight whisper - distinctive italic serif
                if let insight = aiInsight, !task.isCompleted {
                    Text(insight)
                        .font(CosmicWidget.Typography.aiWhisper)
                        .foregroundStyle(CosmicWidget.Text.tertiary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, layout.cardPadding)
                        .padding(.top, 4)
                }

                // Divider
                Divider()
                    .padding(.horizontal, layout.cardPadding)
                    .padding(.vertical, layout.spacing / 2)

                // Metadata row
                metadataRow
                    .padding(.horizontal, layout.cardPadding)

                // Action row: Focus button + More menu
                if !task.isCompleted {
                    actionRow
                        .padding(.horizontal, layout.cardPadding)
                        .padding(.top, layout.spacing * 0.75)
                }

                Spacer().frame(height: layout.cardPadding - 2)
            }
            .background(cardBackground)
        }
        .buttonStyle(TaskCardV4ButtonStyle(isPressed: $isPressed, reduceMotion: reduceMotion))
        .iPadHoverEffect(.lift)
    }

    // MARK: - Main Row

    private var mainRow: some View {
        HStack(spacing: layout.spacing * 0.75) {
            // Elegant checkbox
            ElegantCheckBubble(
                taskTypeColor: taskTypeColor,
                isCompleted: task.isCompleted,
                onComplete: {
                    HapticsService.shared.impact(.medium)
                    onToggleComplete()
                }
            )

            // Title - Dynamic Type for accessibility
            Text(task.title)
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(CosmicWidget.Text.primary)
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
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(
                        index < task.starRating
                            ? CosmicWidget.Widget.gold
                            : CosmicWidget.Text.disabled
                    )
            }
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: layout.spacing * 0.625) {
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

    // MARK: - Points Badge (Mint Success)

    private var pointsBadge: some View {
        let points = task.pointsEarned > 0 ? task.pointsEarned : 25

        return HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
                .dynamicTypeFont(base: 9, weight: .bold)

            Text("+\(points)")
                .font(CosmicWidget.Typography.caption)
        }
        .foregroundStyle(CosmicWidget.Semantic.success)
        .padding(.horizontal, layout.spacing / 2)
        .padding(.vertical, layout.spacing / 4)
        .background(
            Capsule()
                .fill(CosmicWidget.Semantic.success.opacity(0.15))
        )
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: layout.spacing * 0.75) {
            // Focus button (Liquid Glass)
            focusButton

            Spacer()

            // More menu (Liquid Glass)
            moreMenuButton
        }
    }

    // MARK: - Focus Button (AI Accent - Electric Cyan)

    private var focusButton: some View {
        Button {
            HapticsService.shared.impact()
            onStartFocus?(task, selectedFocusDuration)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .dynamicTypeFont(base: 11, weight: .semibold)

                Text("Focus")
                    .dynamicTypeFont(base: 14, weight: .medium)
            }
            .foregroundStyle(CosmicWidget.Text.inverse)
            .padding(.horizontal, layout.cardPadding - 2)
            .padding(.vertical, layout.spacing / 2)
            .background(CosmicWidget.Gradient.ai)
            .clipShape(Capsule())
            // AI glow effect
            .shadow(color: CosmicWidget.Widget.electricCyan.opacity(0.5), radius: 12, x: 0, y: 0)
        }
        .buttonStyle(.cosmicTap)
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
                .foregroundStyle(CosmicWidget.Text.tertiary)
                .frame(width: 36, height: 36)
                .background(CosmicWidget.Void.interactive)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card Background (Cosmic Widget Style)

    private var cardBackground: some View {
        ZStack(alignment: .leading) {
            // Solid void background - NO GLASS on content layer
            RoundedRectangle(cornerRadius: CosmicWidget.Radius.card, style: .continuous)
                .fill(CosmicWidget.Void.nebula)

            // Subtle top highlight for depth
            RoundedRectangle(cornerRadius: CosmicWidget.Radius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            // BOLD 4px Category Color Bar on left edge
            UnevenRoundedRectangle(
                topLeadingRadius: CosmicWidget.Radius.card,
                bottomLeadingRadius: CosmicWidget.Radius.card,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(categoryColor)
            .frame(width: categoryBarWidth)
        }
        // Category glow halo - makes the color POP
        .shadow(color: categoryColor.opacity(0.35), radius: 16, x: 0, y: 0)
        // Depth shadow
        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
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

#Preview("TaskCardV4 - Cosmic Widget") {
    ScrollView {
        VStack(spacing: 16) {
            // Work task - Teal
            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Write quarterly report for Q4 2024 review meeting")
                    t.aiAdvice = "Break into sections: data gathering, writing, review"
                    t.estimatedMinutes = 45
                    t.starRating = 3
                    t.scheduledTime = Date().addingTimeInterval(3600)
                    t.taskType = .coordinate
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            // Personal task - Orange
            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Call mom for birthday")
                    t.aiQuickTip = "She mentioned wanting that cookbook"
                    t.estimatedMinutes = 20
                    t.starRating = 2
                    t.taskType = .communicate
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            // Creative task - Magenta
            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Design new app icon concepts")
                    t.aiAdvice = "Try 3 variations: minimal, bold, playful"
                    t.estimatedMinutes = 60
                    t.starRating = 3
                    t.taskType = .create
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            // Learning task - Violet
            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Read SwiftUI documentation")
                    t.estimatedMinutes = 30
                    t.starRating = 1
                    t.taskType = .consume
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )

            // Completed task
            TaskCardV4(
                task: {
                    let t = TaskItem(title: "Team standup call")
                    t.estimatedMinutes = 15
                    t.starRating = 1
                    t.isCompleted = true
                    t.taskType = .communicate
                    return t
                }(),
                onTap: {},
                onToggleComplete: {},
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )
        }
        .padding(CosmicWidget.Spacing.screenPadding)
    }
    .background(CosmicWidget.Void.cosmos)
}
