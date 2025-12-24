//
//  TiimoMonthView.swift
//  Veloce
//
//  Tiimo-Style Month Calendar Grid
//  Visual month overview with task count indicators
//

import SwiftUI

// MARK: - Tiimo Month View

/// Month calendar grid with task indicators
struct TiimoMonthView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    let onDateSelect: (Date) -> Void

    @State private var displayedMonth: Date = Date()

    private var calendar: Calendar { Calendar.current }

    /// All dates to display in the month grid (including padding days)
    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }

        var days: [Date?] = []
        var currentDay = monthFirstWeek.start

        while currentDay < monthLastWeek.end {
            // Only include if it's in displayed month, otherwise nil for padding
            if calendar.isDate(currentDay, equalTo: displayedMonth, toGranularity: .month) {
                days.append(currentDay)
            } else {
                days.append(currentDay) // Include for layout, but style differently
            }
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
        }

        return days
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation header
            monthHeader

            // Weekday headers
            weekdayHeaders

            // Calendar grid
            calendarGrid
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            // Previous month
            Button {
                HapticsService.shared.selectionFeedback()
                withAnimation(TiimoDesignTokens.Animation.viewTransition) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            // Month and year
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            // Next month
            Button {
                HapticsService.shared.selectionFeedback()
                withAnimation(TiimoDesignTokens.Animation.viewTransition) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        HStack(spacing: 0) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day.prefix(1).uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: TiimoDesignTokens.MonthView.cellSpacing), count: 7),
            spacing: TiimoDesignTokens.MonthView.cellSpacing
        ) {
            ForEach(monthDays.indices, id: \.self) { index in
                if let date = monthDays[index] {
                    TiimoMonthDayCell(
                        date: date,
                        displayedMonth: displayedMonth,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        taskCount: taskCount(for: date),
                        hasHighPriority: hasHighPriorityTask(on: date)
                    ) {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(TiimoDesignTokens.Animation.viewTransition) {
                            selectedDate = date
                            onDateSelect(date)
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: TiimoDesignTokens.MonthView.cellHeight)
                }
            }
        }
    }

    // MARK: - Helpers

    private func taskCount(for date: Date) -> Int {
        tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }.count
    }

    private func hasHighPriorityTask(on date: Date) -> Bool {
        tasks.contains { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date) && task.starRating == 3
        }
    }
}

// MARK: - Month Day Cell

/// Individual day cell in the month grid
struct TiimoMonthDayCell: View {
    let date: Date
    let displayedMonth: Date
    let isSelected: Bool
    let isToday: Bool
    let taskCount: Int
    let hasHighPriority: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    private var calendar: Calendar { Calendar.current }

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 15, weight: isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(foregroundColor)

                // Task indicators
                taskIndicators
            }
            .frame(height: TiimoDesignTokens.MonthView.cellHeight)
            .frame(maxWidth: .infinity)
            .background(cellBackground)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(TiimoDesignTokens.Animation.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Task Indicators

    @ViewBuilder
    private var taskIndicators: some View {
        if taskCount > 0 && isInCurrentMonth {
            HStack(spacing: 2) {
                // Show up to 3 dots
                ForEach(0..<min(taskCount, 3), id: \.self) { index in
                    SwiftUI.Circle()
                        .fill(indicatorColor(index: index))
                        .frame(width: 4, height: 4)
                }

                // Show +N if more than 3
                if taskCount > 3 {
                    Text("+\(taskCount - 3)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        } else {
            // Spacer for alignment
            Color.clear
                .frame(height: 4)
        }
    }

    private func indicatorColor(index: Int) -> Color {
        if hasHighPriority && index == 0 {
            return Theme.Colors.error
        }
        if isSelected {
            return .white
        }
        return Theme.Colors.aiCyan
    }

    // MARK: - Background

    @ViewBuilder
    private var cellBackground: some View {
        if isSelected {
            SwiftUI.Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.5),
                            Theme.Colors.aiBlue.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
        } else if isToday {
            SwiftUI.Circle()
                .stroke(Theme.Colors.aiCyan.opacity(0.5), lineWidth: 1)
                .frame(width: 40, height: 40)
        }
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        if isSelected {
            return .white
        }
        if !isInCurrentMonth {
            return .white.opacity(0.2)
        }
        if isToday {
            return Theme.Colors.aiCyan
        }
        return .white.opacity(0.8)
    }

    private var accessibilityLabel: String {
        var label = date.formatted(.dateTime.weekday(.wide).month(.wide).day())

        if taskCount > 0 {
            label += ", \(taskCount) task\(taskCount == 1 ? "" : "s")"
        }

        if hasHighPriority {
            label += ", has high priority"
        }

        return label
    }
}

// MARK: - Preview

#Preview("Month View") {
    ZStack {
        Color.black.ignoresSafeArea()

        TiimoMonthView(
            selectedDate: .constant(Date()),
            tasks: [
                TaskItem(
                    title: "Task 1",
                    scheduledTime: Date(),
                    starRating: 3
                ),
                TaskItem(
                    title: "Task 2",
                    scheduledTime: Date()
                ),
                TaskItem(
                    title: "Task 3",
                    scheduledTime: Calendar.current.date(byAdding: .day, value: 2, to: Date())
                )
            ],
            onDateSelect: { _ in }
        )
    }
}
