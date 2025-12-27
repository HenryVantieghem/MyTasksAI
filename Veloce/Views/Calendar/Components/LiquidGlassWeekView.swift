//
//  LiquidGlassWeekView.swift
//  Veloce
//
//  iOS 26 Liquid Glass Week View
//  Apple Calendar-style 7-column week with proper typography and spacing
//

import SwiftUI
import EventKit

// MARK: - Liquid Glass Week View

struct LiquidGlassWeekView: View {
    @Binding var selectedDate: Date
    let weekDates: [Date]
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onTimeSlotTap: (Date) -> Void
    let onTaskDrag: (TaskItem, Date) -> Void
    let onTaskComplete: (TaskItem) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // Timeline configuration
    private let startHour = 6
    private let endHour = 23
    private let hourHeight: CGFloat = 56
    private let timeGutterWidth: CGFloat = 48
    private let allDayHeight: CGFloat = 44

    private let calendar = Calendar.current

    @State private var draggedTask: TaskItem?
    @State private var dragOffset: CGPoint = .zero

    // Responsive padding
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 24 : 8
    }

    private var isCurrentWeek: Bool {
        weekDates.contains { calendar.isDateInToday($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Week day header with date selection
            weekDayHeader

            // All-day events section (if any)
            if hasAllDayEvents {
                allDaySection
            }

            // Scrollable time grid
            timeGrid
        }
        .padding(.horizontal, horizontalPadding)
    }

    // MARK: - Week Day Header

    private var weekDayHeader: some View {
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
        .frame(height: 72)
        .background {
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color(.separator).opacity(0.3))
                    .frame(height: 0.5)
            }
        }
    }

    private func dayHeaderCell(for date: Date, width: CGFloat) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 6) {
                // Day of week
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(
                        isToday ? Color.accentColor :
                        isSelected ? .primary :
                        .secondary
                    )

                // Date number with circle indicator
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 16, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ? .white :
                            isToday ? Color.accentColor :
                            .primary
                        )
                }
            }
            .frame(width: width)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - All Day Section

    private var hasAllDayEvents: Bool {
        events.contains { $0.isAllDay }
    }

    @ViewBuilder
    private var allDaySection: some View {
        GeometryReader { geometry in
            let dayWidth = (geometry.size.width - timeGutterWidth) / 7

            HStack(spacing: 0) {
                // Label
                Text("all-day")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: timeGutterWidth, alignment: .trailing)
                    .padding(.trailing, 4)

                // All-day events for each day
                ForEach(weekDates, id: \.self) { date in
                    allDayEventsForDate(date, width: dayWidth)
                }
            }
        }
        .frame(height: allDayHeight)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
    }

    private func allDayEventsForDate(_ date: Date, width: CGFloat) -> some View {
        let dayAllDayEvents = events.filter { event in
            event.isAllDay && calendar.isDate(event.startDate, inSameDayAs: date)
        }

        return VStack(spacing: 2) {
            ForEach(dayAllDayEvents.prefix(2), id: \.eventIdentifier) { event in
                allDayEventPill(event, width: width)
            }

            if dayAllDayEvents.count > 2 {
                Text("+\(dayAllDayEvents.count - 2)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: width)
    }

    private func allDayEventPill(_ event: EKEvent, width: CGFloat) -> some View {
        let color: Color = {
            if let cgColor = event.calendar?.cgColor {
                return Color(cgColor: cgColor)
            }
            return .blue
        }()

        return Text(event.title ?? "")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: width - 4, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: 3))
    }

    // MARK: - Time Grid

    private var timeGrid: some View {
        GeometryReader { geometry in
            let dayWidth = (geometry.size.width - timeGutterWidth) / 7

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid lines
                        hourGridLines(dayWidth: dayWidth)

                        // Day column separators
                        dayColumnSeparators(dayWidth: dayWidth)

                        // Events and tasks
                        ForEach(weekDates, id: \.self) { date in
                            dayContentOverlay(for: date, dayWidth: dayWidth)
                        }

                        // Current time indicator
                        if isCurrentWeek {
                            currentTimeIndicator(dayWidth: dayWidth)
                                .id("now")
                        }
                    }
                    .frame(height: CGFloat(endHour - startHour) * hourHeight)
                }
                .onAppear {
                    if isCurrentWeek {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                proxy.scrollTo("now", anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Hour Grid Lines

    private func hourGridLines(dayWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: timeGutterWidth, alignment: .trailing)
                        .padding(.trailing, 8)
                        .offset(y: -7)

                    // Grid line
                    Rectangle()
                        .fill(Color(.separator).opacity(0.3))
                        .frame(height: 0.5)
                }
                .frame(height: hourHeight)
            }
        }
    }

    // MARK: - Day Column Separators

    private func dayColumnSeparators(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: timeGutterWidth)

            ForEach(0..<7, id: \.self) { index in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.separator).opacity(0.15))
                        .frame(width: 0.5)
                    Spacer()
                }
                .frame(width: dayWidth)
            }
        }
    }

    // MARK: - Day Content Overlay

    private func dayContentOverlay(for date: Date, dayWidth: CGFloat) -> some View {
        let dayIndex = weekDates.firstIndex(of: date) ?? 0
        let xOffset = timeGutterWidth + CGFloat(dayIndex) * dayWidth
        let dayTasks = tasksForDate(date)
        let dayEvents = eventsForDate(date).filter { !$0.isAllDay }

        return ZStack(alignment: .topLeading) {
            // Events (behind tasks)
            ForEach(dayEvents, id: \.eventIdentifier) { event in
                weekEventBlock(for: event, width: dayWidth)
            }

            // Tasks
            ForEach(dayTasks) { task in
                weekTaskBlock(for: task, width: dayWidth, date: date)
            }
        }
        .offset(x: xOffset)
    }

    // MARK: - Week Task Block

    private func weekTaskBlock(for task: TaskItem, width: CGFloat, date: Date) -> some View {
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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(height > 32 ? 2 : 1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)

                Spacer(minLength: 0)
            }
            .frame(width: width - 4, alignment: .leading)
            .frame(height: max(height, 22))
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(task.taskType.tiimoColor.opacity(0.1))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                    }
            )
        }
        .buttonStyle(.plain)
        .offset(x: 2, y: yOffset + (isBeingDragged ? dragOffset.y : 0))
        .scaleEffect(isBeingDragged ? 1.05 : 1.0)
        .zIndex(isBeingDragged ? 100 : 1)
        .shadow(
            color: isBeingDragged ? Color.accentColor.opacity(0.3) : .clear,
            radius: isBeingDragged ? 8 : 0,
            y: isBeingDragged ? 4 : 0
        )
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
                            if let newTime = calendar.date(byAdding: .minute, value: slotsMoved * 15, to: currentTime) {
                                HapticsService.shared.success()
                                onTaskDrag(task, newTime)
                            }
                        }
                    }

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        draggedTask = nil
                        dragOffset = .zero
                    }
                }
        )
    }

    // MARK: - Week Event Block

    private func weekEventBlock(for event: EKEvent, width: CGFloat) -> some View {
        let yOffset = eventYOffset(for: event)
        let height = eventHeight(for: event)
        let color: Color = {
            if let cgColor = event.calendar?.cgColor {
                return Color(cgColor: cgColor)
            }
            return .blue
        }()

        return Text(event.title ?? "")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(width: width - 4, alignment: .leading)
            .frame(height: max(height, 18))
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.15))
            )
            .offset(x: 2, y: yOffset)
            .opacity(0.9)
    }

    // MARK: - Current Time Indicator

    @ViewBuilder
    private func currentTimeIndicator(dayWidth: CGFloat) -> some View {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        if hour >= startHour && hour < endHour {
            let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
            let todayIndex = weekDates.firstIndex { calendar.isDateInToday($0) } ?? 0
            let xOffset = timeGutterWidth + CGFloat(todayIndex) * dayWidth

            ZStack(alignment: .leading) {
                // Full width line
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
                    .padding(.leading, timeGutterWidth)

                // Circle on today's column
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .offset(x: xOffset - 5)
            }
            .offset(y: yOffset - 1)
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
        return max((minutes / 60.0) * hourHeight, 22)
    }

    private func eventYOffset(for event: EKEvent) -> CGFloat {
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private func eventHeight(for event: EKEvent) -> CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60
        return max((CGFloat(duration) / 60.0) * hourHeight, 18)
    }
}

// MARK: - Preview

#Preview("Week View") {
    let today = Date()
    let calendar = Calendar.current
    let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
    let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

    LiquidGlassWeekView(
        selectedDate: .constant(today),
        weekDates: weekDates,
        tasks: [],
        events: [],
        onTaskTap: { _ in },
        onTimeSlotTap: { _ in },
        onTaskDrag: { _, _ in },
        onTaskComplete: { _ in }
    )
    .background(Color(.systemGroupedBackground))
}
