//
//  CosmosWeekView.swift
//  Veloce
//
//  Living Cosmos Week View
//  A 7-day horizontal grid that fits on screen with compact task indicators
//  and tap-to-zoom day transitions
//

import SwiftUI
import EventKit

struct CosmosWeekView: View {
    let centerDate: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onDayTap: (Date) -> Void
    let onReschedule: ((TaskItem, Date) -> Void)?

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let hourHeight = LivingCosmos.Calendar.compactHourHeight
    private let startHour = LivingCosmos.Calendar.startHour
    private let endHour = LivingCosmos.Calendar.endHour

    // MARK: - Computed Properties

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: centerDate)) ?? centerDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private var columnWidth: CGFloat {
        LivingCosmos.Calendar.weekDayColumnWidth
    }

    private var totalHeight: CGFloat {
        CGFloat(endHour - startHour) * hourHeight
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Day headers
            dayHeaders

            // Timeline content
            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // Time gutter
                    timeGutter

                    // Day columns
                    ForEach(Array(weekDays.enumerated()), id: \.element) { index, date in
                        CosmosWeekDayColumn(
                            date: date,
                            tasks: tasksFor(date),
                            events: eventsFor(date),
                            hourHeight: hourHeight,
                            startHour: startHour,
                            endHour: endHour,
                            onTap: { onDayTap(date) },
                            onTaskTap: onTaskTap
                        )
                        .frame(width: columnWidth)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            LivingCosmos.Animations.stellarBounce.delay(Double(index) * 0.05),
                            value: appeared
                        )
                    }
                }
                .frame(height: totalHeight)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(timelineBorder)
        }
        .padding(.horizontal, 8)
        .onAppear {
            withAnimation(LivingCosmos.Animations.stellarBounce.delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Day Headers

    private var dayHeaders: some View {
        HStack(spacing: 0) {
            // Time gutter spacer
            Spacer()
                .frame(width: 36)

            ForEach(Array(weekDays.enumerated()), id: \.offset) { _, date in
                VStack(spacing: 2) {
                    // Day name
                    Text(dayName(for: date))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    // Day number with highlight for today
                    ZStack {
                        if Calendar.current.isDateInToday(date) {
                            Circle()
                                .fill(Theme.CelestialColors.plasmaCore)
                                .frame(width: 28, height: 28)
                        }

                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 14, weight: Calendar.current.isDateInToday(date) ? .bold : .medium))
                            .foregroundStyle(Calendar.current.isDateInToday(date) ? .white : .white.opacity(0.9))
                    }
                }
                .frame(width: columnWidth)
            }
        }
        .padding(.vertical, 8)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Time Gutter

    private var timeGutter: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                Text(formatHour(hour))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
                    .frame(height: hourHeight, alignment: .top)
            }
        }
        .frame(width: 36)
    }

    // MARK: - Timeline Border

    private var timelineBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
    }

    // MARK: - Helper Functions

    private func tasksFor(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }.sorted { ($0.scheduledTime ?? Date.distantFuture) < ($1.scheduledTime ?? Date.distantFuture) }
    }

    private func eventsFor(_ date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 12 {
            return "12P"
        } else if hour > 12 {
            return "\(hour - 12)P"
        } else if hour == 0 {
            return "12A"
        } else {
            return "\(hour)A"
        }
    }
}

// MARK: - Week Day Column

struct CosmosWeekDayColumn: View {
    let date: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let hourHeight: CGFloat
    let startHour: Int
    let endHour: Int
    let onTap: () -> Void
    let onTaskTap: (TaskItem) -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Column background
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticsService.shared.selectionFeedback()
                    onTap()
                }

            // Hour grid lines
            hourGridLines

            // Events (background)
            ForEach(events.filter { !$0.isAllDay }, id: \.eventIdentifier) { event in
                compactEventBlock(for: event)
            }

            // Tasks (foreground)
            ForEach(scheduledTasks) { task in
                compactTaskBlock(for: task)
            }

            // Current time indicator
            if isToday {
                currentTimeIndicator
            }

            // Column border
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .offset(x: -0.5)
        }
    }

    // MARK: - Components

    private var hourGridLines: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { _ in
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                }
                .frame(height: hourHeight)
            }
        }
    }

    private var currentTimeIndicator: some View {
        GeometryReader { geometry in
            let calendar = Calendar.current
            let now = Date()
            let hour = calendar.component(.hour, from: now)
            let minute = calendar.component(.minute, from: now)
            let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

            CosmosCompactNowIndicator()
                .offset(y: yOffset)
        }
    }

    private var scheduledTasks: [TaskItem] {
        tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            let hour = Calendar.current.component(.hour, from: scheduledTime)
            return hour >= startHour && hour < endHour
        }
    }

    @ViewBuilder
    private func compactTaskBlock(for task: TaskItem) -> some View {
        let yOffset = self.yOffset(for: task.scheduledTime)
        let height = blockHeight(for: task)

        CosmosCompactTimeBlock(task: task) {
            onTaskTap(task)
        }
        .frame(height: height)
        .offset(y: yOffset)
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private func compactEventBlock(for event: EKEvent) -> some View {
        let yOffset = self.yOffset(for: event.startDate)
        let height = eventHeight(for: event)

        Rectangle()
            .fill(Color(cgColor: event.calendar.cgColor).opacity(0.3))
            .frame(height: height)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color(cgColor: event.calendar.cgColor))
                    .frame(width: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .offset(y: yOffset)
            .padding(.horizontal, 2)
    }

    // MARK: - Helpers

    private func yOffset(for date: Date?) -> CGFloat {
        guard let date = date else { return 0 }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private func blockHeight(for task: TaskItem) -> CGFloat {
        let minutes = task.estimatedMinutes ?? 30
        return max(CGFloat(minutes) / 60.0 * hourHeight, 20)
    }

    private func eventHeight(for event: EKEvent) -> CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600
        return max(CGFloat(hours) * hourHeight, 20)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.calendar

        CosmosWeekView(
            centerDate: Date(),
            tasks: [],
            events: [],
            onTaskTap: { _ in },
            onDayTap: { _ in },
            onReschedule: nil
        )
    }
}
