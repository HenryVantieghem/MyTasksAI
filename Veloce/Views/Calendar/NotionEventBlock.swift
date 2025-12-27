//
//  NotionEventBlock.swift
//  Veloce
//
//  Notion Calendar-Inspired Event Block
//  Clean, minimal event display for both tasks and Apple Calendar events
//

import SwiftUI
import EventKit

// MARK: - Notion Task Block

/// A task block displayed on the calendar timeline
struct NotionTaskBlock: View {
    let task: TaskItem
    let hourHeight: CGFloat
    let onTap: () -> Void
    let onComplete: (() -> Void)?

    @State private var isPressed = false
    @Environment(\.modelContext) private var modelContext

    init(
        task: TaskItem,
        hourHeight: CGFloat = NotionCalendarTokens.Timeline.hourHeight,
        onTap: @escaping () -> Void,
        onComplete: (() -> Void)? = nil
    ) {
        self.task = task
        self.hourHeight = hourHeight
        self.onTap = onTap
        self.onComplete = onComplete
    }

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    private var blockHeight: CGFloat {
        let minutes = CGFloat(task.estimatedMinutes ?? 30)
        let calculatedHeight = (minutes / 60.0) * hourHeight
        return max(calculatedHeight, NotionCalendarTokens.EventBlock.minHeight)
    }

    private var timeString: String {
        guard let scheduledTime = task.scheduledTime else { return "" }
        let endTime = Calendar.current.date(
            byAdding: .minute,
            value: task.estimatedMinutes ?? 30,
            to: scheduledTime
        ) ?? scheduledTime

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        return "\(formatter.string(from: scheduledTime)) - \(formatter.string(from: endTime))"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(taskColor)
                    .frame(width: NotionCalendarTokens.EventBlock.colorBarWidth)
                    .shadow(color: taskColor.opacity(0.5), radius: 4)

                // Content
                HStack(spacing: 10) {
                    // Completion checkbox
                    if let onComplete = onComplete {
                        completionButton(action: onComplete)
                    }

                    // Task info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(NotionCalendarTokens.Typography.eventTitle)
                            .foregroundStyle(.white)
                            .lineLimit(blockHeight > 50 ? 2 : 1)

                        if blockHeight > 44 {
                            Text(timeString)
                                .font(NotionCalendarTokens.Typography.eventTime)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    Spacer()

                    // Duration badge
                    if let minutes = task.estimatedMinutes, blockHeight > 50 {
                        Text("\(minutes)m")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.08))
                            )
                    }
                }
                .padding(.horizontal, NotionCalendarTokens.EventBlock.padding)
                .padding(.vertical, 8)
            }
            .frame(height: blockHeight)
            .background(blockBackground)
            .clipShape(RoundedRectangle(cornerRadius: NotionCalendarTokens.EventBlock.cornerRadius))
            .overlay(blockBorder)
            .shadow(
                color: taskColor.opacity(0.15),
                radius: NotionCalendarTokens.EventBlock.shadowRadius,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? NotionCalendarTokens.EventBlock.pressedScale : 1.0)
        .animation(NotionCalendarTokens.Animation.blockPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticsService.shared.impact()
                    }
                }
                .onEnded { _ in isPressed = false }
        )
    }

    private var blockBackground: some View {
        ZStack {
            // Glass material
            RoundedRectangle(cornerRadius: NotionCalendarTokens.EventBlock.cornerRadius)
                .fill(.ultraThinMaterial)

            // Color tint
            RoundedRectangle(cornerRadius: NotionCalendarTokens.EventBlock.cornerRadius)
                .fill(taskColor.opacity(0.08))
        }
    }

    private var blockBorder: some View {
        RoundedRectangle(cornerRadius: NotionCalendarTokens.EventBlock.cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.15),
                        .white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    private func completionButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 20, height: 20)

                if task.isCompleted {
                    Circle()
                        .fill(Theme.Colors.aiCyan)
                        .frame(width: 20, height: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notion Apple Calendar Event Block

/// An Apple Calendar event block displayed on the timeline
struct NotionAppleEventBlock: View {
    let event: EKEvent
    let hourHeight: CGFloat
    let startHour: Int

    @State private var isPressed = false

    init(
        event: EKEvent,
        hourHeight: CGFloat = NotionCalendarTokens.Timeline.hourHeight,
        startHour: Int = NotionCalendarTokens.Timeline.startHour
    ) {
        self.event = event
        self.hourHeight = hourHeight
        self.startHour = startHour
    }

    private var eventColor: Color {
        if let cgColor = event.calendar?.cgColor {
            return Color(cgColor: cgColor)
        }
        return NotionCalendarTokens.Colors.appleEventDefault
    }

    private var blockHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60
        let calculatedHeight = (CGFloat(duration) / 60.0) * hourHeight
        return max(calculatedHeight, NotionCalendarTokens.EventBlock.minHeight)
    }

    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }

    var body: some View {
        HStack(spacing: 10) {
            // Calendar icon
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))

            // Event info
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Untitled Event")
                    .font(NotionCalendarTokens.Typography.eventTitle)
                    .foregroundStyle(.white)
                    .lineLimit(blockHeight > 50 ? 2 : 1)

                if blockHeight > 44 {
                    Text(timeString)
                        .font(NotionCalendarTokens.Typography.eventTime)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(.horizontal, NotionCalendarTokens.EventBlock.padding)
        .padding(.vertical, 8)
        .frame(height: blockHeight)
        .background(
            RoundedRectangle(cornerRadius: NotionCalendarTokens.EventBlock.cornerRadius)
                .fill(eventColor.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NotionCalendarTokens.EventBlock.cornerRadius)
                .stroke(eventColor.opacity(0.9), lineWidth: 0.5)
        )
        .offset(y: yOffset)
        .scaleEffect(isPressed ? NotionCalendarTokens.EventBlock.pressedScale : 1.0)
        .animation(NotionCalendarTokens.Animation.blockPress, value: isPressed)
    }
}

// MARK: - All Day Event Banner

struct NotionAllDayBanner: View {
    let events: [EKEvent]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(events, id: \.eventIdentifier) { event in
                    allDayChip(for: event)
                }
            }
            .padding(.horizontal, NotionCalendarTokens.Spacing.screenPadding)
        }
        .padding(.vertical, 8)
    }

    private func allDayChip(for event: EKEvent) -> some View {
        let eventColor: Color = {
            if let cgColor = event.calendar?.cgColor {
                return Color(cgColor: cgColor)
            }
            return NotionCalendarTokens.Colors.appleEventDefault
        }()

        return HStack(spacing: 6) {
            Circle()
                .fill(eventColor)
                .frame(width: 8, height: 8)

            Text(event.title ?? "All Day")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(eventColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(eventColor.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Compact Event Capsule (for Week View)

struct NotionEventCapsule: View {
    let task: TaskItem

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(taskColor)
                .frame(width: 6, height: 6)

            Text(task.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(taskColor.opacity(0.2))
        )
    }
}

// MARK: - Preview

#Preview("Task Block") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            NotionTaskBlock(
                task: TaskItem(
                    title: "Design new calendar UI",
                    estimatedMinutes: 60,
                    scheduledTime: Date(),
                    taskTypeRaw: "create"
                ),
                onTap: {},
                onComplete: {}
            )
            .padding(.horizontal, 60)

            NotionTaskBlock(
                task: TaskItem(
                    title: "Team standup meeting",
                    estimatedMinutes: 30,
                    scheduledTime: Date(),
                    taskTypeRaw: "communicate"
                ),
                onTap: {},
                onComplete: {}
            )
            .padding(.horizontal, 60)

            NotionTaskBlock(
                task: TaskItem(
                    title: "Quick task",
                    estimatedMinutes: 15,
                    scheduledTime: Date(),
                    taskTypeRaw: "coordinate"
                ),
                onTap: {},
                onComplete: nil
            )
            .padding(.horizontal, 60)
        }
    }
}
