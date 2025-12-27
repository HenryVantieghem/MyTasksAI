//
//  PremiumMonthView.swift
//  Veloce
//
//  Premium Month Grid with task indicators
//  Full month view with event dots and selection states
//

import SwiftUI
import EventKit

// MARK: - Premium Month View

struct PremiumMonthView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onDayTap: (Date) -> Void

    private let calendar = Calendar.current
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]

    private var monthDays: [[Date?]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else {
            return []
        }

        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []

        // Add empty days for first week
        for _ in 1..<firstWeekday {
            currentWeek.append(nil)
        }

        // Add days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(bySetting: .day, value: day, of: firstDay) {
                currentWeek.append(date)

                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
        }

        // Add remaining empty days
        while currentWeek.count < 7 && !currentWeek.isEmpty {
            currentWeek.append(nil)
        }

        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }

        return weeks
    }

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            // Month grid
            VStack(spacing: 4) {
                ForEach(monthDays.indices, id: \.self) { weekIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            if let date = monthDays[weekIndex][dayIndex] {
                                dayCell(for: date)
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let taskCount = tasksForDate(date).count
        let eventCount = eventsForDate(date).count
        let totalCount = taskCount + eventCount

        return Button {
            HapticsService.shared.selectionFeedback()
            onDayTap(date)
        } label: {
            VStack(spacing: 4) {
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
                            .frame(width: 32, height: 32)
                            .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 6, y: 3)
                    } else if isToday {
                        Circle()
                            .stroke(Theme.Colors.aiCyan, lineWidth: 1.5)
                            .frame(width: 32, height: 32)
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 14, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ? .white :
                                isToday ? Theme.Colors.aiCyan :
                                .white.opacity(0.8)
                        )
                }

                // Event dots
                HStack(spacing: 2) {
                    if totalCount > 0 {
                        ForEach(0..<min(totalCount, 3), id: \.self) { index in
                            Circle()
                                .fill(dotColor(for: date, index: index))
                                .frame(width: 4, height: 4)
                        }
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private func dotColor(for date: Date, index: Int) -> Color {
        let dayTasks = tasksForDate(date)
        let dayEvents = eventsForDate(date)

        if index < dayTasks.count {
            return dayTasks[index].taskType.tiimoColor
        }

        let eventIndex = index - dayTasks.count
        if eventIndex < dayEvents.count {
            let event = dayEvents[eventIndex]
            if let cgColor = event.calendar?.cgColor {
                return Color(cgColor: cgColor)
            }
            return Theme.Colors.aiBlue
        }

        return Theme.Colors.aiPurple
    }
}

// MARK: - Preview

#Preview("Month View") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
                .frame(height: 100)

            PremiumMonthView(
                selectedDate: .constant(Date()),
                tasks: [],
                events: [],
                onDayTap: { _ in }
            )

            Spacer()
        }
    }
}
