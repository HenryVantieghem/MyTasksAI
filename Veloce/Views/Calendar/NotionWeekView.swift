//
//  NotionWeekView.swift
//  Veloce
//
//  Notion Calendar-Inspired Week View
//  Clean 7-day grid with compact event display
//

import SwiftUI
import EventKit

// MARK: - Notion Week View

struct NotionWeekView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onDayTap: (Date) -> Void
    let onTaskTap: (TaskItem) -> Void

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Day headers
            weekHeader

            // Week grid
            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 1) {
                    // Time gutter
                    NotionCompactTimelineGrid()
                        .frame(width: 24)

                    // Day columns
                    ForEach(weekDates, id: \.self) { date in
                        dayColumn(for: date)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(gridBorder)
        }
        .padding(.horizontal, NotionCalendarTokens.Spacing.screenPadding)
    }

    // MARK: - Week Header

    private var weekHeader: some View {
        HStack(spacing: 1) {
            // Empty space for time gutter
            Color.clear
                .frame(width: 24)

            // Day headers
            ForEach(weekDates, id: \.self) { date in
                dayHeaderCell(for: date)
            }
        }
        .padding(.bottom, 8)
    }

    private func dayHeaderCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayNumber = calendar.component(.day, from: date)

        return Button {
            HapticsService.shared.selectionFeedback()
            onDayTap(date)
        } label: {
            VStack(spacing: 4) {
                // Day of week
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isToday ? Theme.Colors.aiCyan : .white.opacity(0.5))

                // Date number
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Theme.Colors.aiCyan)
                            .frame(width: 28, height: 28)
                    } else if isSelected {
                        Circle()
                            .fill(Theme.Colors.aiPurple.opacity(0.3))
                            .frame(width: 28, height: 28)
                    }

                    Text("\(dayNumber)")
                        .font(.system(size: 14, weight: isToday || isSelected ? .semibold : .regular))
                        .foregroundStyle(isToday ? .white : (isSelected ? .white : .white.opacity(0.8)))
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Day Column

    private func dayColumn(for date: Date) -> some View {
        let dayTasks = tasksForDate(date)
        let dayEvents = eventsForDate(date)
        let isToday = calendar.isDateInToday(date)

        return ZStack(alignment: .top) {
            // Today highlight
            if isToday {
                Rectangle()
                    .fill(Theme.Colors.aiCyan.opacity(0.03))
            }

            // Hour grid lines
            VStack(spacing: 0) {
                ForEach(NotionCalendarTokens.Timeline.startHour..<NotionCalendarTokens.Timeline.endHour, id: \.self) { _ in
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(NotionCalendarTokens.Colors.gridLine)
                            .frame(height: 0.5)
                        Spacer()
                    }
                    .frame(height: NotionCalendarTokens.WeekView.hourHeight)
                }
            }

            // Events
            ForEach(dayEvents, id: \.eventIdentifier) { event in
                weekEventCapsule(for: event)
            }

            // Tasks
            ForEach(dayTasks) { task in
                weekTaskCapsule(for: task)
                    .onTapGesture {
                        onTaskTap(task)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            onDayTap(date)
        }
    }

    // MARK: - Event Capsules

    private func weekTaskCapsule(for task: TaskItem) -> some View {
        let yOffset = taskYOffset(for: task)
        let height = taskHeight(for: task)

        return HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(task.taskType.tiimoColor)
                .frame(width: 2)

            Text(task.title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.leading, 4)
                .padding(.trailing, 2)
        }
        .frame(height: max(height, 16))
        .padding(.horizontal, 1)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(task.taskType.tiimoColor.opacity(0.2))
        )
        .offset(y: yOffset)
    }

    private func weekEventCapsule(for event: EKEvent) -> some View {
        let yOffset = eventYOffset(for: event)
        let height = eventHeight(for: event)
        let color: Color = {
            if let cgColor = event.calendar?.cgColor {
                return Color(cgColor: cgColor)
            }
            return NotionCalendarTokens.Colors.appleEventDefault
        }()

        return Text(event.title ?? "")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .lineLimit(1)
            .padding(.horizontal, 4)
            .frame(height: max(height, 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.6))
            )
            .padding(.horizontal, 1)
            .offset(y: yOffset)
            .opacity(0.85)
    }

    private var gridBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
    }

    // MARK: - Helpers

    private func tasksForDate(_ date: Date) -> [TaskItem] {
        tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }
    }

    private func eventsForDate(_ date: Date) -> [EKEvent] {
        events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date) && !event.isAllDay
        }
    }

    private func taskYOffset(for task: TaskItem) -> CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)

        let startHour = NotionCalendarTokens.Timeline.startHour
        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * NotionCalendarTokens.WeekView.hourHeight +
               CGFloat(minute) / 60.0 * NotionCalendarTokens.WeekView.hourHeight
    }

    private func taskHeight(for task: TaskItem) -> CGFloat {
        let minutes = CGFloat(task.estimatedMinutes ?? 30)
        return (minutes / 60.0) * NotionCalendarTokens.WeekView.hourHeight
    }

    private func eventYOffset(for event: EKEvent) -> CGFloat {
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        let startHour = NotionCalendarTokens.Timeline.startHour
        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * NotionCalendarTokens.WeekView.hourHeight +
               CGFloat(minute) / 60.0 * NotionCalendarTokens.WeekView.hourHeight
    }

    private func eventHeight(for event: EKEvent) -> CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60
        return (CGFloat(duration) / 60.0) * NotionCalendarTokens.WeekView.hourHeight
    }
}

// MARK: - Preview

#Preview("Week View") {
    ZStack {
        VoidBackground.calendar

        VStack {
            Spacer()
                .frame(height: 120)

            NotionWeekView(
                selectedDate: .constant(Date()),
                tasks: [
                    TaskItem(
                        title: "Design meeting",
                        estimatedMinutes: 60,
                        scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()),
                        taskTypeRaw: "create"
                    ),
                    TaskItem(
                        title: "Code review",
                        estimatedMinutes: 45,
                        scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
                        taskTypeRaw: "coordinate"
                    )
                ],
                events: [],
                onDayTap: { _ in },
                onTaskTap: { _ in }
            )

            Spacer()
        }
    }
}
