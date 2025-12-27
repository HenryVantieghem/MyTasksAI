//
//  LiquidGlassMonthView.swift
//  Veloce
//
//  iOS 26 Liquid Glass Month Grid
//  Responsive layout with proper HIG spacing and accessibility
//

import SwiftUI
import EventKit

// MARK: - Liquid Glass Month View

struct LiquidGlassMonthView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let cellSize: CGFloat
    let onDayTap: (Date) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let calendar = Calendar.current
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let shortWeekDays = ["S", "M", "T", "W", "T", "F", "S"]

    // Use abbreviated or single letter based on size
    private var weekDayLabels: [String] {
        cellSize < 50 ? shortWeekDays : weekDays
    }

    // Responsive padding
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 24 : 16
    }

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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                // Weekday headers
                weekdayHeader

                // Month grid
                monthGrid

                // Upcoming events section
                if !upcomingTasksAndEvents.isEmpty {
                    upcomingSection
                }

                // Bottom spacer for floating button
                Spacer()
                    .frame(height: 80)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 8)
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDayLabels.enumerated()), id: \.offset) { index, day in
                Text(day)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        VStack(spacing: 4) {
            ForEach(monthDays.indices, id: \.self) { weekIndex in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let date = monthDays[weekIndex][dayIndex] {
                            dayCell(for: date)
                        } else {
                            // Empty cell
                            Color.clear
                                .frame(height: cellSize)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let taskCount = tasksForDate(date).count
        let eventCount = eventsForDate(date).count
        let totalCount = taskCount + eventCount
        let isWeekend = calendar.isDateInWeekend(date)

        return Button {
            HapticsService.shared.selectionFeedback()
            onDayTap(date)
        } label: {
            VStack(spacing: 6) {
                // Date number
                ZStack {
                    // Selection/Today indicator
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: min(cellSize * 0.7, 36), height: min(cellSize * 0.7, 36))
                    } else if isToday {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                            .frame(width: min(cellSize * 0.7, 36), height: min(cellSize * 0.7, 36))
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 18 : 15,
                                      weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ? .white :
                            isToday ? Color.accentColor :
                            isWeekend ? .secondary :
                            .primary
                        )
                }

                // Event indicators
                eventIndicators(taskCount: taskCount, eventCount: eventCount, isSelected: isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Event Indicators

    @ViewBuilder
    private func eventIndicators(taskCount: Int, eventCount: Int, isSelected: Bool) -> some View {
        let total = taskCount + eventCount

        if total > 0 {
            HStack(spacing: 3) {
                ForEach(0..<min(total, 3), id: \.self) { index in
                    Circle()
                        .fill(isSelected ? .white.opacity(0.8) : dotColor(index: index, taskCount: taskCount))
                        .frame(width: 5, height: 5)
                }

                if total > 3 {
                    Text("+\(total - 3)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
        } else {
            // Placeholder to maintain consistent height
            Spacer()
                .frame(height: 5)
        }
    }

    private func dotColor(index: Int, taskCount: Int) -> Color {
        if index < taskCount {
            return Color.accentColor
        }
        return Color.blue
    }

    // MARK: - Upcoming Section

    private var upcomingTasksAndEvents: [(date: Date, title: String, isTask: Bool, color: Color)] {
        var items: [(Date, String, Bool, Color)] = []

        // Add tasks
        for task in tasks.prefix(10) {
            if let date = task.scheduledTime, date >= Date() {
                items.append((date, task.title, true, task.taskType.tiimoColor))
            }
        }

        // Add events
        for event in events.prefix(10) {
            if event.startDate >= Date() {
                let color: Color = {
                    if let cgColor = event.calendar?.cgColor {
                        return Color(cgColor: cgColor)
                    }
                    return .blue
                }()
                items.append((event.startDate, event.title ?? "Event", false, color))
            }
        }

        return items.sorted { $0.0 < $1.0 }.prefix(8).map { $0 }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("Upcoming")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(upcomingTasksAndEvents.count) items")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // Items list
            LazyVStack(spacing: 8) {
                ForEach(upcomingTasksAndEvents.indices, id: \.self) { index in
                    let item = upcomingTasksAndEvents[index]
                    upcomingItemRow(item: item)
                }
            }
        }
    }

    private func upcomingItemRow(item: (date: Date, title: String, isTask: Bool, color: Color)) -> some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(item.color)
                .frame(width: 4, height: 36)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(item.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Type indicator
            Image(systemName: item.isTask ? "checkmark.circle" : "calendar")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
    GeometryReader { geometry in
        let cellSize = (geometry.size.width - 32 - 24) / 7

        LiquidGlassMonthView(
            selectedDate: .constant(Date()),
            tasks: [],
            events: [],
            cellSize: cellSize,
            onDayTap: { _ in }
        )
    }
    .background(Color(.systemGroupedBackground))
}
