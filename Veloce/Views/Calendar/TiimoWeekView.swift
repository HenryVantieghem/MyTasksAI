//
//  TiimoWeekView.swift
//  Veloce
//
//  Tiimo-Style Week View
//  7-day grid with compact task blocks
//

import SwiftUI
import EventKit

// MARK: - Tiimo Week View

/// Week view with 7 day columns showing tasks and events
struct TiimoWeekView: View {
    let centerDate: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onDayTap: (Date) -> Void
    let onReschedule: ((TaskItem, Date) -> Void)?

    private let startHour = TiimoDesignTokens.Timeline.startHour
    private let endHour = TiimoDesignTokens.Timeline.endHour
    private let hourHeight = TiimoDesignTokens.WeekView.hourHeight
    private let dayWidth = TiimoDesignTokens.WeekView.dayWidth
    private let headerHeight = TiimoDesignTokens.WeekView.headerHeight
    private let timeGutterWidth = TiimoDesignTokens.WeekView.timeGutterWidth

    /// Week dates starting from Sunday
    private var weekDates: [Date] {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: centerDate)?.start else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    /// Index of today in the week (nil if not in this week)
    private var todayIndex: Int? {
        weekDates.firstIndex { Calendar.current.isDateInToday($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed day headers
            dayHeaders

            // Scrollable timeline content
            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // Time gutter
                    timeGutter

                    // Day columns
                    ForEach(weekDates.indices, id: \.self) { index in
                        let date = weekDates[index]
                        TiimoWeekDayColumn(
                            date: date,
                            tasks: tasksForDay(date),
                            events: eventsForDay(date),
                            hourHeight: hourHeight,
                            dayWidth: dayWidth,
                            startHour: startHour,
                            endHour: endHour,
                            isToday: index == todayIndex,
                            onTaskTap: onTaskTap,
                            onDayTap: { onDayTap(date) },
                            onReschedule: onReschedule
                        )
                    }
                }
                .frame(height: CGFloat(endHour - startHour) * hourHeight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 12)
    }

    // MARK: - Day Headers

    private var dayHeaders: some View {
        HStack(spacing: 0) {
            // Time gutter spacer
            Color.clear
                .frame(width: timeGutterWidth)

            // Day headers
            ForEach(weekDates.indices, id: \.self) { index in
                let date = weekDates[index]
                let isToday = index == todayIndex

                Button {
                    onDayTap(date)
                } label: {
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 16, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Theme.Colors.aiCyan : .white.opacity(0.8))
                    }
                    .frame(width: dayWidth)
                    .padding(.vertical, 8)
                    .background {
                        if isToday {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.Colors.aiCyan.opacity(0.15))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: headerHeight)
        .background(.ultraThinMaterial)
    }

    // MARK: - Time Gutter

    private var timeGutter: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                Text(formatHour(hour))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: timeGutterWidth, height: hourHeight, alignment: .topTrailing)
                    .padding(.trailing, 4)
                    .padding(.top, -6)
            }
        }
    }

    // MARK: - Helpers

    private func tasksForDay(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }
    }

    private func eventsForDay(_ date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let isPM = hour >= 12
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour)\(isPM ? "p" : "a")"
    }
}

// MARK: - Week Day Column

/// Single day column in the week view
struct TiimoWeekDayColumn: View {
    let date: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let hourHeight: CGFloat
    let dayWidth: CGFloat
    let startHour: Int
    let endHour: Int
    let isToday: Bool
    let onTaskTap: (TaskItem) -> Void
    let onDayTap: () -> Void
    let onReschedule: ((TaskItem, Date) -> Void)?

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hour grid lines
            VStack(spacing: 0) {
                ForEach(startHour..<endHour, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.05))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    Spacer()
                        .frame(height: hourHeight - 1)
                }
            }

            // Background highlight for today
            if isToday {
                Rectangle()
                    .fill(Theme.Colors.aiCyan.opacity(0.03))
            }

            // Events (background)
            ForEach(events.filter { !$0.isAllDay }, id: \.eventIdentifier) { event in
                TiimoCompactEventBlock(
                    event: event,
                    hourHeight: hourHeight,
                    startHour: startHour
                )
                .padding(.horizontal, 2)
            }

            // Tasks (foreground)
            ForEach(tasks) { task in
                TiimoCompactTimeBlock(
                    task: task,
                    hourHeight: hourHeight,
                    onTap: { onTaskTap(task) }
                )
                .offset(y: yOffset(for: task))
                .padding(.horizontal, 2)
            }

            // Current time indicator
            if isToday {
                TiimoCompactNowIndicator(
                    hourHeight: hourHeight,
                    startHour: startHour,
                    columnWidth: dayWidth,
                    dayOffset: 0
                )
            }
        }
        .frame(width: dayWidth)
        .contentShape(Rectangle())
        .onTapGesture {
            onDayTap()
        }
    }

    private func yOffset(for task: TaskItem) -> CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }
}

// MARK: - Preview

#Preview("Week View") {
    ZStack {
        Color.black.ignoresSafeArea()

        TiimoWeekView(
            centerDate: Date(),
            tasks: [
                TaskItem(
                    title: "Team sync",
                    estimatedMinutes: 30,
                    scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()),
                    taskTypeRaw: "communicate"
                ),
                TaskItem(
                    title: "Deep work",
                    estimatedMinutes: 120,
                    scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
                    taskTypeRaw: "create",
                    starRating: 3
                )
            ],
            events: [],
            onTaskTap: { _ in },
            onDayTap: { _ in },
            onReschedule: nil
        )
    }
}
