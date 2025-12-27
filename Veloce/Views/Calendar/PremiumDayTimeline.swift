//
//  PremiumDayTimeline.swift
//  Veloce
//
//  Premium Day Timeline with glass-effect task blocks
//  Time slots from 6am-10pm with tap-to-add and drag-to-reschedule
//

import SwiftUI
import EventKit

// MARK: - Premium Day Timeline

struct PremiumDayTimeline: View {
    let date: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onTimeSlotTap: (Date) -> Void
    let onTaskComplete: (TaskItem) -> Void
    let onTaskDrag: (TaskItem, Date) -> Void

    // Timeline configuration
    private let startHour = 6
    private let endHour = 22
    private let hourHeight: CGFloat = 64
    private let timeGutterWidth: CGFloat = 52

    private let calendar = Calendar.current

    @State private var draggedTask: TaskItem?
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Hour grid
                    hourGrid

                    // Apple Calendar events (behind tasks)
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
            .padding(.horizontal, 16)
            .onAppear {
                if isToday {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            proxy.scrollTo("now", anchor: .center)
                        }
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
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: timeGutterWidth, alignment: .trailing)
                        .padding(.trailing, 12)
                        .offset(y: -6)

                    // Grid line
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(.white.opacity(0.06))
                            .frame(height: 0.5)

                        Spacer()

                        // Half-hour line (more subtle)
                        Rectangle()
                            .fill(.white.opacity(0.03))
                            .frame(height: 0.5)
                            .padding(.leading, 20)

                        Spacer()
                    }
                }
                .frame(height: hourHeight)
            }
        }
    }

    // MARK: - Task Block

    private func taskBlock(for task: TaskItem) -> some View {
        let yOffset = taskYOffset(for: task)
        let height = taskHeight(for: task)
        let isBeingDragged = draggedTask?.id == task.id

        return PremiumTaskBlock(
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
            color: isBeingDragged ? Theme.Colors.aiPurple.opacity(0.4) : .clear,
            radius: isBeingDragged ? 16 : 0,
            y: isBeingDragged ? 8 : 0
        )
        .zIndex(isBeingDragged ? 100 : 1)
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture())
                .onChanged { value in
                    switch value {
                    case .first(true):
                        // Long press started
                        HapticsService.shared.impact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            draggedTask = task
                            isDragging = true
                        }
                    case .second(true, let drag):
                        // Dragging
                        if let drag = drag {
                            dragOffset = drag.translation.height
                        }
                    default:
                        break
                    }
                }
                .onEnded { _ in
                    // Calculate new time
                    if let task = draggedTask {
                        let slotsMoved = Int(round(dragOffset / (hourHeight / 4)))
                        if slotsMoved != 0, let currentTime = task.scheduledTime {
                            let newTime = calendar.date(byAdding: .minute, value: slotsMoved * 15, to: currentTime)
                            if let newTime = newTime {
                                HapticsService.shared.success()
                                onTaskDrag(task, newTime)
                            }
                        }
                    }

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        draggedTask = nil
                        dragOffset = 0
                        isDragging = false
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
            return Theme.Colors.aiBlue
        }()

        return HStack(spacing: 0) {
            Text(event.title ?? "Event")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(height, 28))
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.25))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.4), lineWidth: 0.5)
                }
        }
        .offset(y: yOffset)
        .padding(.leading, timeGutterWidth + 8)
        .padding(.trailing, 8)
        .opacity(0.8)
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        guard hour >= startHour && hour < endHour else {
            return AnyView(EmptyView())
        }

        let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

        return AnyView(
            HStack(spacing: 0) {
                // Time label
                Text(now.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.Colors.aiCyan)
                    .frame(width: timeGutterWidth, alignment: .trailing)
                    .padding(.trailing, 8)

                // Dot
                Circle()
                    .fill(Theme.Colors.aiCyan)
                    .frame(width: 8, height: 8)
                    .shadow(color: Theme.Colors.aiCyan.opacity(0.6), radius: 4)

                // Line
                Rectangle()
                    .fill(Theme.Colors.aiCyan)
                    .frame(height: 1.5)
                    .shadow(color: Theme.Colors.aiCyan.opacity(0.4), radius: 4)
            }
            .offset(y: yOffset - 4)
        )
    }

    // MARK: - Tap Zones

    private var tapZones: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - timeGutterWidth - 16

            ForEach(0..<((endHour - startHour) * 4), id: \.self) { slot in
                let hour = startHour + slot / 4
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
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour

        if let date = calendar.date(from: components) {
            return formatter.string(from: date).lowercased()
        }
        return "\(hour)"
    }

    private func taskYOffset(for task: TaskItem) -> CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private func taskHeight(for task: TaskItem) -> CGFloat {
        let minutes = CGFloat(task.estimatedMinutes ?? task.duration ?? 30)
        return max((minutes / 60.0) * hourHeight, 36)
    }

    private func eventYOffset(for event: EKEvent) -> CGFloat {
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private func eventHeight(for event: EKEvent) -> CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60
        return max((CGFloat(duration) / 60.0) * hourHeight, 28)
    }

    private func makeTargetDate(hour: Int, minute: Int) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Premium Task Block

struct PremiumTaskBlock: View {
    let task: TaskItem
    let height: CGFloat
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var isPressed = false

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    private var priorityBorderWidth: CGFloat {
        switch task.starRating {
        case 3: return 4
        case 2: return 3
        default: return 2
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Priority color border
                RoundedRectangle(cornerRadius: 2)
                    .fill(taskColor)
                    .frame(width: priorityBorderWidth)
                    .shadow(color: taskColor.opacity(0.5), radius: 4)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(height > 50 ? 2 : 1)

                    // Duration
                    if height > 44, let minutes = task.estimatedMinutes ?? task.duration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))

                            Text(formatDuration(minutes))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                Spacer()

                // Complete button (visible on larger blocks)
                if height > 50 {
                    Button {
                        onComplete()
                    } label: {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(task.isCompleted ? Theme.Colors.success : .white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(taskColor.opacity(0.08))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.2),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        HapticsService.shared.lightImpact()
                        isPressed = true
                    }
                }
                .onEnded { _ in isPressed = false }
        )
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

#Preview("Day Timeline") {
    ZStack {
        Color.black.ignoresSafeArea()

        PremiumDayTimeline(
            date: Date(),
            tasks: [
                TaskItem(
                    title: "Morning planning",
                    estimatedMinutes: 30,
                    scheduledTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
                    taskTypeRaw: "coordinate"
                ),
                TaskItem(
                    title: "Design new calendar UI",
                    estimatedMinutes: 90,
                    scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()),
                    taskTypeRaw: "create",
                    starRating: 3
                )
            ],
            events: [],
            onTaskTap: { _ in },
            onTimeSlotTap: { _ in },
            onTaskComplete: { _ in },
            onTaskDrag: { _, _ in }
        )
    }
}
