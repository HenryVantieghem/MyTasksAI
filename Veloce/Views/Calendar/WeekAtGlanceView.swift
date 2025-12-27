//
//  WeekAtGlanceView.swift
//  Veloce
//
//  Apple Calendar-style week view with 7 day columns
//  Shows tasks and events positioned by time across the entire week
//

import SwiftUI
import EventKit

// MARK: - Week At Glance View

struct WeekAtGlanceView: View {
    @Binding var selectedDate: Date
    let weekDates: [Date]
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onTimeSlotTap: (Date) -> Void
    let onTaskDrag: (TaskItem, Date) -> Void
    let onTaskComplete: (TaskItem) -> Void

    // Timeline configuration
    private let startHour = 6
    private let endHour = 22
    private let hourHeight: CGFloat = 52
    private let timeGutterWidth: CGFloat = 44
    private let dayColumnMinWidth: CGFloat = 44

    private let calendar = Calendar.current

    @State private var draggedTask: TaskItem?
    @State private var dragOffset: CGPoint = .zero
    @State private var isDragging = false

    private var isToday: Bool {
        weekDates.contains { calendar.isDateInToday($0) }
    }

    var body: some View {
        GeometryReader { geometry in
            let dayColumnWidth = (geometry.size.width - timeGutterWidth - 16) / 7

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid background
                        hourGridBackground(dayColumnWidth: dayColumnWidth)

                        // Day columns with events
                        dayColumnsOverlay(dayColumnWidth: dayColumnWidth)

                        // Current time indicator
                        if isToday {
                            currentTimeIndicator(dayColumnWidth: dayColumnWidth)
                                .id("now")
                        }
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
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Hour Grid Background

    private func hourGridBackground(dayColumnWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: timeGutterWidth, alignment: .trailing)
                        .padding(.trailing, 6)
                        .offset(y: -5)

                    // Grid line across all days
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(height: 0.5)

                        Spacer()
                    }
                }
                .frame(height: hourHeight)
            }
        }
    }

    // MARK: - Day Columns Overlay

    private func dayColumnsOverlay(dayColumnWidth: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Time gutter spacer
            Color.clear
                .frame(width: timeGutterWidth)

            // Day columns
            ForEach(weekDates, id: \.self) { date in
                dayColumn(for: date, width: dayColumnWidth)
            }
        }
    }

    private func dayColumn(for date: Date, width: CGFloat) -> some View {
        let dayTasks = tasksForDate(date)
        let dayEvents = eventsForDate(date)
        let isSelectedDay = calendar.isDate(date, inSameDayAs: selectedDate)
        let isTodayDate = calendar.isDateInToday(date)

        return ZStack(alignment: .topLeading) {
            // Selected day highlight
            if isSelectedDay {
                Rectangle()
                    .fill(Theme.Colors.aiPurple.opacity(0.06))
            }

            // Today highlight
            if isTodayDate && !isSelectedDay {
                Rectangle()
                    .fill(Theme.Colors.aiCyan.opacity(0.04))
            }

            // Vertical separator
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 0.5)
                Spacer()
            }

            // Events (behind tasks)
            ForEach(dayEvents.filter { !$0.isAllDay }, id: \.eventIdentifier) { event in
                weekEventBlock(for: event, columnWidth: width)
            }

            // Tasks
            ForEach(dayTasks) { task in
                weekTaskBlock(for: task, columnWidth: width, date: date)
            }

            // Tap zones for adding tasks
            tapZonesForDay(date: date, width: width)
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDate = date
            }
            HapticsService.shared.selectionFeedback()
        }
    }

    // MARK: - Week Task Block

    private func weekTaskBlock(for task: TaskItem, columnWidth: CGFloat, date: Date) -> some View {
        let yOffset = taskYOffset(for: task)
        let height = taskHeight(for: task)
        let isBeingDragged = draggedTask?.id == task.id

        return Button {
            onTaskTap(task)
        } label: {
            HStack(spacing: 0) {
                // Color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(task.taskType.tiimoColor)
                    .frame(width: 3)

                // Title
                Text(task.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(height > 30 ? 2 : 1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: max(height, 20))
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(task.taskType.tiimoColor.opacity(0.12))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.15), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .offset(y: yOffset + (isBeingDragged ? dragOffset.y : 0))
        .scaleEffect(isBeingDragged ? 1.05 : 1.0)
        .zIndex(isBeingDragged ? 100 : 1)
        .shadow(
            color: isBeingDragged ? Theme.Colors.aiPurple.opacity(0.4) : .clear,
            radius: isBeingDragged ? 8 : 0,
            y: isBeingDragged ? 4 : 0
        )
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture())
                .onChanged { value in
                    switch value {
                    case .first(true):
                        HapticsService.shared.impact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            draggedTask = task
                            isDragging = true
                        }
                    case .second(true, let drag):
                        if let drag = drag {
                            dragOffset = CGPoint(x: drag.translation.width, y: drag.translation.height)
                        }
                    default:
                        break
                    }
                }
                .onEnded { _ in
                    if let task = draggedTask {
                        let slotsMoved = Int(round(dragOffset.y / (hourHeight / 4)))
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
                        dragOffset = .zero
                        isDragging = false
                    }
                }
        )
    }

    // MARK: - Week Event Block

    private func weekEventBlock(for event: EKEvent, columnWidth: CGFloat) -> some View {
        let yOffset = eventYOffset(for: event)
        let height = eventHeight(for: event)
        let color: Color = {
            if let cgColor = event.calendar?.cgColor {
                return Color(cgColor: cgColor)
            }
            return Theme.Colors.aiBlue
        }()

        return HStack(spacing: 0) {
            Text(event.title ?? "")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(height, 16))
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.25))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color.opacity(0.4), lineWidth: 0.5)
                }
        }
        .padding(.horizontal, 2)
        .offset(y: yOffset)
        .opacity(0.85)
    }

    // MARK: - Current Time Indicator

    private func currentTimeIndicator(dayColumnWidth: CGFloat) -> some View {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        guard hour >= startHour && hour < endHour else {
            return AnyView(EmptyView())
        }

        let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

        // Find today's column index
        let todayIndex = weekDates.firstIndex { calendar.isDateInToday($0) } ?? 0
        let xOffset = timeGutterWidth + CGFloat(todayIndex) * dayColumnWidth

        return AnyView(
            HStack(spacing: 0) {
                // Line across all columns
                Rectangle()
                    .fill(Theme.Colors.aiCyan)
                    .frame(height: 1.5)
            }
            .padding(.leading, timeGutterWidth)
            .overlay(alignment: .leading) {
                // Dot on today's column
                Circle()
                    .fill(Theme.Colors.aiCyan)
                    .frame(width: 8, height: 8)
                    .shadow(color: Theme.Colors.aiCyan.opacity(0.6), radius: 4)
                    .offset(x: xOffset - 4)
            }
            .offset(y: yOffset - 0.75)
        )
    }

    // MARK: - Tap Zones

    private func tapZonesForDay(date: Date, width: CGFloat) -> some View {
        GeometryReader { _ in
            ForEach(0..<((endHour - startHour) * 2), id: \.self) { slot in
                let hour = startHour + slot / 2
                let minute = (slot % 2) * 30

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: width - 4, height: hourHeight / 2)
                    .offset(y: CGFloat(slot) * hourHeight / 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let targetDate = makeTargetDate(date: date, hour: hour, minute: minute)
                        HapticsService.shared.lightImpact()
                        onTimeSlotTap(targetDate)
                    }
            }
        }
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        var components = DateComponents()
        components.hour = hour

        if let date = calendar.date(from: components) {
            return formatter.string(from: date).lowercased()
        }
        return "\(hour)"
    }

    private func tasksForDate(_ date: Date) -> [TaskItem] {
        tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }
    }

    private func eventsForDate(_ date: Date) -> [EKEvent] {
        events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
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
        return max((minutes / 60.0) * hourHeight, 20)
    }

    private func eventYOffset(for event: EKEvent) -> CGFloat {
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private func eventHeight(for event: EKEvent) -> CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60
        return max((CGFloat(duration) / 60.0) * hourHeight, 16)
    }

    private func makeTargetDate(date: Date, hour: Int, minute: Int) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Week Day Header

struct WeekDayHeader: View {
    let weekDates: [Date]
    @Binding var selectedDate: Date
    let timeGutterWidth: CGFloat

    private let calendar = Calendar.current

    var body: some View {
        GeometryReader { geometry in
            let dayWidth = (geometry.size.width - timeGutterWidth) / 7

            HStack(spacing: 0) {
                // Time gutter spacer
                Color.clear
                    .frame(width: timeGutterWidth)

                // Day headers
                ForEach(weekDates, id: \.self) { date in
                    dayHeaderCell(for: date, width: dayWidth)
                }
            }
        }
        .frame(height: 56)
    }

    private func dayHeaderCell(for date: Date, width: CGFloat) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDate = date
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            VStack(spacing: 4) {
                // Day of week
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        isToday ? Theme.Colors.aiCyan :
                        isSelected ? .white :
                        .white.opacity(0.5)
                    )

                // Date number
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.aiPurple.opacity(0.8),
                                        Theme.Colors.aiBlue.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                    } else if isToday {
                        Circle()
                            .stroke(Theme.Colors.aiCyan, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 14, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ? .white :
                            isToday ? Theme.Colors.aiCyan :
                            .white.opacity(0.8)
                        )
                }
            }
            .frame(width: width)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Week At Glance") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 0) {
            let today = Date()
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

            WeekDayHeader(
                weekDates: weekDates,
                selectedDate: .constant(today),
                timeGutterWidth: 44
            )
            .padding(.horizontal, 8)

            WeekAtGlanceView(
                selectedDate: .constant(today),
                weekDates: weekDates,
                tasks: [
                    TaskItem(
                        title: "Morning standup",
                        estimatedMinutes: 30,
                        scheduledTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today),
                        taskTypeRaw: "coordinate"
                    ),
                    TaskItem(
                        title: "Design review",
                        estimatedMinutes: 60,
                        scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: today),
                        taskTypeRaw: "create"
                    )
                ],
                events: [],
                onTaskTap: { _ in },
                onTimeSlotTap: { _ in },
                onTaskDrag: { _, _ in },
                onTaskComplete: { _ in }
            )
        }
    }
}
