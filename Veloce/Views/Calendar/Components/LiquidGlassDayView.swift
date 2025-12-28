//
//  LiquidGlassDayView.swift
//  Veloce
//
//  iOS 26 Liquid Glass Day Timeline
//  Apple Calendar-style full day view with proper sizing and interaction
//

import SwiftUI
import EventKit

// MARK: - Liquid Glass Day View

struct LiquidGlassDayView: View {
    let date: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onTimeSlotTap: (Date) -> Void
    let onTaskComplete: (TaskItem) -> Void
    let onTaskDrag: (TaskItem, Date) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // Timeline configuration
    private let startHour = 0
    private let endHour = 24
    private let hourHeight: CGFloat = 60
    private let timeGutterWidth: CGFloat = 56
    private let allDayHeight: CGFloat = 52

    private let calendar = Calendar.current

    @State private var draggedTask: TaskItem?
    @State private var dragOffset: CGFloat = 0

    // Responsive padding
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 24 : 16
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    // All-day events and tasks
    private var allDayItems: [(title: String, color: Color, isTask: Bool)] {
        var items: [(String, Color, Bool)] = []

        // All-day events
        for event in events where event.isAllDay {
            let color: Color = {
                if let cgColor = event.calendar?.cgColor {
                    return Color(cgColor: cgColor)
                }
                return .blue
            }()
            items.append((event.title ?? "Event", color, false))
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // All-day section (if any)
            if !allDayItems.isEmpty {
                allDaySection
            }

            // Scrollable timeline - fills remaining space
            timelineContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - All Day Section

    private var allDaySection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("all-day")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: timeGutterWidth, alignment: .trailing)
                    .padding(.trailing, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allDayItems.indices, id: \.self) { index in
                            let item = allDayItems[index]
                            allDayPill(title: item.title, color: item.color, isTask: item.isTask)
                        }
                    }
                }
            }
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
        }
        .background(Theme.CelestialColors.abyss.opacity(0.4))
    }

    private func allDayPill(title: String, color: Color, isTask: Bool) -> some View {
        HStack(spacing: 6) {
            if isTask {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 12))
            }

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Hour grid
                    hourGrid

                    // Events (behind tasks)
                    ForEach(events.filter { !$0.isAllDay }, id: \.eventIdentifier) { event in
                        eventBlock(for: event)
                    }

                    // Task blocks
                    ForEach(tasks) { task in
                        taskBlock(for: task)
                    }

                    // Current time indicator
                    if isToday {
                        currentTimeIndicator
                            .id("now")
                    }

                    // Tap zones for adding tasks
                    tapZones
                }
                .frame(height: CGFloat(endHour - startHour) * hourHeight)
            }
            .onAppear {
                if isToday {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            proxy.scrollTo("now", anchor: .center)
                        }
                    }
                } else {
                    // Scroll to 8am by default
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(8, anchor: .top)
                    }
                }
            }
        }
    }

    // MARK: - Hour Grid

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: timeGutterWidth, alignment: .trailing)
                        .padding(.trailing, 12)
                        .offset(y: -8)

                    // Grid line with half-hour marker
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(.separator).opacity(0.3))
                            .frame(height: 0.5)

                        Spacer()

                        // Half-hour line (subtle)
                        Rectangle()
                            .fill(Color(.separator).opacity(0.15))
                            .frame(height: 0.5)
                            .padding(.leading, 16)

                        Spacer()
                    }
                }
                .frame(height: hourHeight)
                .id(hour)
            }
        }
    }

    // MARK: - Task Block

    private func taskBlock(for task: TaskItem) -> some View {
        let yOffset = taskYOffset(for: task)
        let height = taskHeight(for: task)
        let isBeingDragged = draggedTask?.id == task.id

        return DayTaskCard(
            task: task,
            height: height,
            onTap: { onTaskTap(task) },
            onComplete: { onTaskComplete(task) }
        )
        .offset(y: yOffset + (isBeingDragged ? dragOffset : 0))
        .padding(.leading, timeGutterWidth + 8)
        .padding(.trailing, 8)
        .scaleEffect(isBeingDragged ? 1.03 : 1.0)
        .shadow(
            color: isBeingDragged ? Color.accentColor.opacity(0.3) : .clear,
            radius: isBeingDragged ? 16 : 0,
            y: isBeingDragged ? 8 : 0
        )
        .zIndex(isBeingDragged ? 100 : 1)
        .gesture(
            LongPressGesture(minimumDuration: 0.4)
                .sequenced(before: DragGesture())
                .onChanged { value in
                    switch value {
                    case .first(true):
                        HapticsService.shared.impact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            draggedTask = task
                        }
                    case .second(true, let drag):
                        if let drag = drag {
                            dragOffset = drag.translation.height
                        }
                    default:
                        break
                    }
                }
                .onEnded { _ in
                    if let task = draggedTask {
                        let slotsMoved = Int(round(dragOffset / (hourHeight / 4)))
                        if slotsMoved != 0, let currentTime = task.scheduledTime {
                            if let newTime = calendar.date(byAdding: .minute, value: slotsMoved * 15, to: currentTime) {
                                HapticsService.shared.success()
                                onTaskDrag(task, newTime)
                            }
                        }
                    }

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        draggedTask = nil
                        dragOffset = 0
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isBeingDragged)
    }

    // MARK: - Event Block

    private func eventBlock(for event: EKEvent) -> some View {
        let yOffset = eventYOffset(for: event)
        let height = eventHeight(for: event)
        let color: Color = {
            if let cgColor = event.calendar?.cgColor {
                return Color(cgColor: cgColor)
            }
            return .blue
        }()

        return HStack(spacing: 0) {
            // Color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Event")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(color)
                    .lineLimit(height > 40 ? 2 : 1)

                if height > 40 {
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(height, 32))
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.12))
        )
        .offset(y: yOffset)
        .padding(.leading, timeGutterWidth + 8)
        .padding(.trailing, 8)
    }

    // MARK: - Current Time Indicator

    @ViewBuilder
    private var currentTimeIndicator: some View {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

        HStack(spacing: 0) {
            // Time label
            Text(now.formatted(.dateTime.hour().minute()))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.red)
                .frame(width: timeGutterWidth, alignment: .trailing)
                .padding(.trailing, 4)

            // Dot
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)

            // Line
            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
        }
        .offset(y: yOffset - 5)
    }

    // MARK: - Tap Zones

    private var tapZones: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - timeGutterWidth - 16

            ForEach(0..<(endHour * 4), id: \.self) { slot in
                let hour = slot / 4
                let minute = (slot % 4) * 15

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: availableWidth, height: hourHeight / 4)
                    .offset(
                        x: timeGutterWidth + 8,
                        y: CGFloat(slot) * hourHeight / 4
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let targetDate = makeTargetDate(hour: hour, minute: minute)
                        HapticsService.shared.lightImpact()
                        onTimeSlotTap(targetDate)
                    }
            }
        }
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 || hour == 24 {
            return "12 AM"
        } else if hour == 12 {
            return "12 PM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else {
            return "\(hour - 12) PM"
        }
    }

    private func taskYOffset(for task: TaskItem) -> CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private func taskHeight(for task: TaskItem) -> CGFloat {
        let minutes = CGFloat(task.estimatedMinutes ?? task.duration ?? 30)
        return max((minutes / 60.0) * hourHeight, 40)
    }

    private func eventYOffset(for event: EKEvent) -> CGFloat {
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private func eventHeight(for event: EKEvent) -> CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60
        return max((CGFloat(duration) / 60.0) * hourHeight, 32)
    }

    private func makeTargetDate(hour: Int, minute: Int) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Day Task Card

struct DayTaskCard: View {
    let task: TaskItem
    let height: CGFloat
    let onTap: () -> Void
    let onComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Priority color bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(taskColor)
                    .frame(width: 4)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(height > 56 ? 2 : 1)

                    // Duration
                    if height > 48, let minutes = task.estimatedMinutes ?? task.duration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))

                            Text(formatDuration(minutes))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Spacer(minLength: 0)

                // Complete button
                if height > 56 {
                    Button {
                        HapticsService.shared.success()
                        onComplete()
                    } label: {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(task.isCompleted ? Color.green : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.CelestialColors.abyss.opacity(0.8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(taskColor.opacity(0.12))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    }
            )
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// MARK: - Preview

#Preview("Day View") {
    LiquidGlassDayView(
        date: Date(),
        tasks: [],
        events: [],
        onTaskTap: { _ in },
        onTimeSlotTap: { _ in },
        onTaskComplete: { _ in },
        onTaskDrag: { _, _ in }
    )
    .background(Color(.systemGroupedBackground))
}
