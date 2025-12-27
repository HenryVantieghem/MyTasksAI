//
//  NotionMonthView.swift
//  Veloce
//
//  Notion Calendar-Inspired Month View
//  Clean 6x7 grid with event dots and smooth animations
//

import SwiftUI
import EventKit

// MARK: - Notion Month View

struct NotionMonthView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onDayTap: (Date) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var monthDates: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date?] = []
        var currentDate = firstWeek.start

        // Generate 6 weeks of dates
        for _ in 0..<42 {
            if calendar.isDate(currentDate, equalTo: selectedDate, toGranularity: .month) {
                dates.append(currentDate)
            } else {
                dates.append(nil) // Outside current month
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return dates
    }

    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            weekdayHeader

            // Month grid
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(monthDates.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        monthDayCell(for: date)
                    } else {
                        Color.clear
                            .frame(height: NotionCalendarTokens.MonthView.cellHeight)
                    }
                }
            }
        }
        .padding(.horizontal, NotionCalendarTokens.Spacing.screenPadding)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day.prefix(1).uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Day Cell

    private func monthDayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayNumber = calendar.component(.day, from: date)
        let dayTasks = tasksForDate(date)
        let dayEvents = eventsForDate(date)

        return Button {
            HapticsService.shared.selectionFeedback()
            onDayTap(date)
        } label: {
            VStack(spacing: 6) {
                // Date number
                ZStack {
                    // Selection indicator
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                    } else if isToday {
                        Circle()
                            .stroke(Theme.Colors.aiCyan, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }

                    Text("\(dayNumber)")
                        .font(.system(size: 16, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : (isToday ? Theme.Colors.aiCyan : .white.opacity(0.8)))
                }

                // Event dots
                eventDots(tasks: dayTasks, events: dayEvents)
            }
            .frame(height: NotionCalendarTokens.MonthView.cellHeight)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Event Dots

    private func eventDots(tasks: [TaskItem], events: [EKEvent]) -> some View {
        HStack(spacing: 3) {
            // Show up to 3 dots
            let taskColors = tasks.prefix(2).map { $0.taskType.tiimoColor }
            let eventColors = events.prefix(max(0, 3 - taskColors.count)).compactMap { event -> Color? in
                if let cgColor = event.calendar?.cgColor {
                    return Color(cgColor: cgColor)
                }
                return NotionCalendarTokens.Colors.appleEventDefault
            }

            let allColors = Array(taskColors) + eventColors

            ForEach(Array(allColors.prefix(3).enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: NotionCalendarTokens.MonthView.dotSize, height: NotionCalendarTokens.MonthView.dotSize)
            }

            // Overflow indicator
            if tasks.count + events.count > 3 {
                Text("+")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(height: NotionCalendarTokens.MonthView.dotSize)
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
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
}

// MARK: - Preview

#Preview("Month View") {
    ZStack {
        VoidBackground.calendar

        VStack {
            Spacer()
                .frame(height: 120)

            NotionMonthView(
                selectedDate: .constant(Date()),
                tasks: [
                    TaskItem(
                        title: "Design meeting",
                        estimatedMinutes: 60,
                        scheduledTime: Date(),
                        taskTypeRaw: "create"
                    ),
                    TaskItem(
                        title: "Code review",
                        estimatedMinutes: 45,
                        scheduledTime: Date(),
                        taskTypeRaw: "coordinate"
                    )
                ],
                events: [],
                onDayTap: { _ in }
            )

            Spacer()
        }
    }
}
