//
//  CosmosMonthView.swift
//  Veloce
//
//  Living Cosmos Month View
//  A full calendar grid with dot indicators and orbital selection
//

import SwiftUI

struct CosmosMonthView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    let onDateTap: (Date) -> Void

    @State private var displayedMonth: Date
    @State private var appeared = false
    @GestureState private var swipeOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(selectedDate: Binding<Date>, tasks: [TaskItem], onDateTap: @escaping (Date) -> Void) {
        self._selectedDate = selectedDate
        self.tasks = tasks
        self.onDateTap = onDateTap
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }

    // MARK: - Computed Properties

    private var monthDays: [Date?] {
        let calendar = Calendar.current

        // Get first day of month
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }

        // Get weekday of first day (0 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // Get number of days in month
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let daysInMonth = range.count

        // Create array with padding
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private var weekdayHeaders: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation header
            monthHeader

            // Weekday headers
            weekdayHeaderRow

            // Calendar grid
            calendarGrid
        }
        .padding(.horizontal, 16)
        .offset(x: swipeOffset * 0.3)
        .gesture(monthSwipeGesture)
        .onAppear {
            withAnimation(LivingCosmos.Animations.stellarBounce.delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            // Update displayed month when selection changes
            let calendar = Calendar.current
            if !calendar.isDate(displayedMonth, equalTo: newDate, toGranularity: .month) {
                withAnimation(LivingCosmos.Animations.spring) {
                    displayedMonth = newDate
                }
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthYearString)
                .font(Theme.Typography.cosmosTitleLarge)
                .foregroundStyle(.white)

            Spacer()

            Button {
                navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdayHeaders, id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
            ForEach(Array(monthDays.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    CosmosMonthDayCell(
                        date: date,
                        taskCount: taskCount(for: date),
                        hasHighPriority: hasHighPriorityTask(for: date),
                        isToday: Calendar.current.isDateInToday(date),
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        onTap: {
                            HapticsService.shared.selectionFeedback()
                            selectedDate = date
                            onDateTap(date)
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .animation(
                        LivingCosmos.Animations.stellarBounce.delay(Double(index) * 0.01),
                        value: appeared
                    )
                } else {
                    Color.clear
                        .frame(height: LivingCosmos.Calendar.dayCellSize)
                }
            }
        }
    }

    // MARK: - Gestures

    private var monthSwipeGesture: some Gesture {
        DragGesture()
            .updating($swipeOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                if value.translation.width > threshold {
                    navigateMonth(by: -1)
                } else if value.translation.width < -threshold {
                    navigateMonth(by: 1)
                }
            }
    }

    // MARK: - Helper Functions

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func navigateMonth(by value: Int) {
        HapticsService.shared.selectionFeedback()
        withAnimation(LivingCosmos.Animations.spring) {
            if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
                displayedMonth = newMonth
            }
        }
    }

    private func taskCount(for date: Date) -> Int {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }.count
    }

    private func hasHighPriorityTask(for date: Date) -> Bool {
        let calendar = Calendar.current
        return tasks.contains { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date) && task.starRating == 3
        }
    }
}

// MARK: - Month Day Cell

struct CosmosMonthDayCell: View {
    let date: Date
    let taskCount: Int
    let hasHighPriority: Bool
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void

    @State private var glowPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Day number
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundStyle(foregroundColor)

                // Task indicators
                taskIndicators
            }
            .frame(width: LivingCosmos.Calendar.dayCellSize, height: LivingCosmos.Calendar.dayCellSize)
            .background(cellBackground)
        }
        .buttonStyle(.plain)
        .onAppear {
            if isSelected && !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
            }
        }
    }

    // MARK: - Components

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Theme.CelestialColors.plasmaCore
        } else {
            return .white.opacity(0.9)
        }
    }

    @ViewBuilder
    private var taskIndicators: some View {
        if taskCount > 0 {
            HStack(spacing: 3) {
                ForEach(0..<min(taskCount, LivingCosmos.Calendar.maxIndicatorDots), id: \.self) { index in
                    SwiftUI.Circle()
                        .fill(
                            index == 0 && hasHighPriority
                                ? Theme.CelestialColors.urgencyCritical
                                : Theme.CelestialColors.plasmaCore
                        )
                        .frame(width: 5, height: 5)
                }

                if taskCount > LivingCosmos.Calendar.maxIndicatorDots {
                    Text("+\(taskCount - LivingCosmos.Calendar.maxIndicatorDots)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
        } else {
            Spacer()
                .frame(height: 5)
        }
    }

    @ViewBuilder
    private var cellBackground: some View {
        if isSelected {
            ZStack {
                // Orbital glow
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.nebulaEdge.opacity(0.3 + glowPhase * 0.2))
                    .blur(radius: 6)
                    .scaleEffect(1.2)

                // Selection fill
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.nebulaCore.opacity(0.6),
                                Theme.CelestialColors.nebulaGlow.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
            }
        } else if isToday {
            SwiftUI.Circle()
                .stroke(Theme.CelestialColors.plasmaCore, lineWidth: 2)
                .frame(width: 40, height: 40)
                .overlay {
                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.plasmaCore.opacity(0.1))
                        .blur(radius: 4)
                }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.calendar

        CosmosMonthView(
            selectedDate: .constant(Date()),
            tasks: [],
            onDateTap: { _ in }
        )
    }
}
