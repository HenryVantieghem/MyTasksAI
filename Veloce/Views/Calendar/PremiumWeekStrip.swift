//
//  PremiumWeekStrip.swift
//  Veloce
//
//  Premium Week Strip with task count dots
//  Horizontal scrolling week view with glass-pill selection
//

import SwiftUI
import EventKit

// MARK: - Premium Week Strip

struct PremiumWeekStrip: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onDayTap: (Date) -> Void

    private let calendar = Calendar.current

    // Get 3 weeks centered on selected date
    private var visibleWeeks: [[Date]] {
        var weeks: [[Date]] = []

        // Previous week
        if let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate),
           let weekStart = calendar.dateInterval(of: .weekOfYear, for: prevWeekStart)?.start {
            weeks.append((0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) })
        }

        // Current week
        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start {
            weeks.append((0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) })
        }

        // Next week
        if let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate),
           let weekStart = calendar.dateInterval(of: .weekOfYear, for: nextWeekStart)?.start {
            weeks.append((0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) })
        }

        return weeks
    }

    private var currentWeekDates: [Date] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(visibleWeeks.flatMap { $0 }, id: \.self) { date in
                        dayCell(for: date)
                            .id(date)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                // Scroll to selected date
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(selectedDate, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    proxy.scrollTo(newDate, anchor: .center)
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

        return Button {
            onDayTap(date)
        } label: {
            VStack(spacing: 6) {
                // Day of week
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(
                        isToday ? Theme.Colors.aiCyan :
                            isSelected ? .white :
                            .white.opacity(0.4)
                    )

                // Date number with glass pill
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.aiPurple.opacity(0.7),
                                        Theme.Colors.aiBlue.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
                            }
                            .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 8, y: 4)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.aiCyan, lineWidth: 1.5)
                            .frame(width: 40, height: 40)
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 17, weight: isSelected || isToday ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(
                            isSelected ? .white :
                                isToday ? Theme.Colors.aiCyan :
                                .white.opacity(0.8)
                        )
                }
                .frame(width: 44, height: 44)

                // Task indicator dots
                HStack(spacing: 3) {
                    if totalCount > 0 {
                        ForEach(0..<min(totalCount, 3), id: \.self) { index in
                            Circle()
                                .fill(dotColor(for: date, index: index))
                                .frame(width: 5, height: 5)
                        }

                        if totalCount > 3 {
                            Text("+")
                                .dynamicTypeFont(base: 8, weight: .bold)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    } else {
                        // Empty placeholder for consistent height
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 8)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
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

        // First show task dots (by priority color)
        if index < dayTasks.count {
            let task = dayTasks.sorted { ($0.starRating) > ($1.starRating) }[index]
            return task.taskType.tiimoColor
        }

        // Then show event dots
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

#Preview("Week Strip") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
                .frame(height: 100)

            PremiumWeekStrip(
                selectedDate: .constant(Date()),
                tasks: [
                    TaskItem(
                        title: "Test task 1",
                        scheduledTime: Date(),
                        taskTypeRaw: "create"
                    ),
                    TaskItem(
                        title: "Test task 2",
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
