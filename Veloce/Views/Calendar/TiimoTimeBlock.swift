//
//  TiimoTimeBlock.swift
//  Veloce
//
//  Tiimo-Style Task Time Block
//  Visual task block with icon, color, and drag-to-reschedule
//

import SwiftUI

// MARK: - Tiimo Time Block

/// Visual task block for the Tiimo-style vertical timeline
struct TiimoTimeBlock: View {
    let task: TaskItem
    let hourHeight: CGFloat
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    @State private var isPressed = false
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed Properties

    /// Block height proportional to task duration
    private var blockHeight: CGFloat {
        let minutes = task.estimatedMinutes ?? 30
        let height = CGFloat(minutes) / 60.0 * hourHeight
        return max(height, TiimoDesignTokens.Block.minHeight)
    }

    /// Color based on task type
    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    /// Icon for the task (custom or default based on type)
    private var taskIcon: String {
        // TODO: Use task.taskIcon when field is added
        task.taskType.defaultIcon
    }

    /// Emoji for the task if set
    private var taskEmoji: String? {
        // TODO: Use task.taskEmoji when field is added
        nil
    }

    /// Whether this is a compact block (< 50pt height)
    private var isCompact: Bool {
        blockHeight < 50
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon container
                iconContainer

                // Task info
                taskInfo

                Spacer(minLength: 0)

                // Priority indicator
                priorityIndicator
            }
            .padding(.horizontal, TiimoDesignTokens.Block.padding)
            .padding(.vertical, isCompact ? 8 : TiimoDesignTokens.Block.padding)
            .frame(height: blockHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(blockBackground)
            .clipShape(RoundedRectangle(cornerRadius: TiimoDesignTokens.Block.cornerRadius))
            .overlay(blockBorder)
            .shadow(
                color: taskColor.opacity(isDragging ? 0.4 : 0.2),
                radius: isDragging ? 12 : 4,
                y: isDragging ? 8 : 2
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : (isDragging ? 1.02 : 1.0))
        .offset(dragOffset)
        .animation(TiimoDesignTokens.Animation.buttonPress, value: isPressed)
        .animation(TiimoDesignTokens.Animation.dragDrop, value: isDragging)
        .simultaneousGesture(pressGesture)
        .onLongPressGesture(minimumDuration: 0.3) {
            HapticsService.shared.impact()
            onLongPress?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var iconContainer: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(.white.opacity(0.2))
                .frame(
                    width: TiimoDesignTokens.Block.iconSize,
                    height: TiimoDesignTokens.Block.iconSize
                )

            if let emoji = taskEmoji {
                Text(emoji)
                    .font(.system(size: 16))
            } else {
                Image(systemName: taskIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private var taskInfo: some View {
        VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
            // Task title
            Text(task.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(isCompact ? 1 : 2)

            // Time and duration (only show if block is tall enough)
            if !isCompact, let time = task.scheduledTime {
                HStack(spacing: 4) {
                    Text(time.formatted(.dateTime.hour().minute()))

                    if let mins = task.estimatedMinutes {
                        Text("•")
                        Text("\(mins)m")
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    @ViewBuilder
    private var priorityIndicator: some View {
        if task.starRating == 3 {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var blockBackground: some View {
        ZStack {
            // Solid color base
            RoundedRectangle(cornerRadius: TiimoDesignTokens.Block.cornerRadius)
                .fill(taskColor.opacity(0.85))

            // Glass overlay
            RoundedRectangle(cornerRadius: TiimoDesignTokens.Block.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            .white.opacity(0.05),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var blockBorder: some View {
        RoundedRectangle(cornerRadius: TiimoDesignTokens.Block.cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        taskColor.opacity(0.6),
                        taskColor.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    isPressed = true
                }
            }
            .onEnded { _ in
                isPressed = false
            }
    }

    private var accessibilityLabel: String {
        var label = task.title

        if let time = task.scheduledTime {
            label += ", scheduled at \(time.formatted(.dateTime.hour().minute()))"
        }

        if let mins = task.estimatedMinutes {
            label += ", \(mins) minutes"
        }

        if task.starRating == 3 {
            label += ", high priority"
        }

        return label
    }
}

// MARK: - Compact Time Block (for Week View)

/// Smaller task block for week view columns
struct TiimoCompactTimeBlock: View {
    let task: TaskItem
    let hourHeight: CGFloat
    let onTap: () -> Void

    @State private var isPressed = false

    private var blockHeight: CGFloat {
        let minutes = task.estimatedMinutes ?? 30
        let height = CGFloat(minutes) / 60.0 * hourHeight
        return max(height, 30)
    }

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(blockHeight > 40 ? 2 : 1)

                if blockHeight > 35, let time = task.scheduledTime {
                    Text(time.formatted(.dateTime.hour(.conversationalDefaultDigits(amPM: .abbreviated))))
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(height: blockHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(taskColor.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(taskColor.opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(TiimoDesignTokens.Animation.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Drag Preview

/// Preview shown while dragging a task
struct TiimoTaskDragPreview: View {
    let task: TaskItem

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        HStack(spacing: 8) {
            SwiftUI.Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: task.taskType.defaultIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                )

            Text(task.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(taskColor.opacity(0.9))
                .shadow(color: taskColor.opacity(0.4), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Time Block") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            // Long task
            TiimoTimeBlock(
                task: TaskItem(
                    title: "Write documentation for API",
                    estimatedMinutes: 60,
                    scheduledTime: Date(),
                    taskTypeRaw: "create",
                    starRating: 3
                ),
                hourHeight: TiimoDesignTokens.Timeline.hourHeight,
                onTap: {}
            )

            // Short task
            TiimoTimeBlock(
                task: TaskItem(
                    title: "Quick call",
                    estimatedMinutes: 15,
                    scheduledTime: Date(),
                    taskTypeRaw: "communicate"
                ),
                hourHeight: TiimoDesignTokens.Timeline.hourHeight,
                onTap: {}
            )

            // Medium task
            TiimoTimeBlock(
                task: TaskItem(
                    title: "Read article",
                    estimatedMinutes: 30,
                    scheduledTime: Date(),
                    taskTypeRaw: "consume"
                ),
                hourHeight: TiimoDesignTokens.Timeline.hourHeight,
                onTap: {}
            )
        }
        .padding()
    }
}
