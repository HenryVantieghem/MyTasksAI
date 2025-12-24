//
//  WeekViewTimeline.swift
//  Veloce
//
//  Week View Timeline - 7-day horizontal layout with vertical hour grid
//  Apple Calendar-inspired week view with task blocks
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Week View Timeline

struct WeekViewTimeline: View {
    let centerDate: Date
    let tasks: [TaskItem]
    let onTaskTap: (TaskItem) -> Void
    let onSlotTap: (Date) -> Void
    var onReschedule: ((TaskItem, Date) -> Void)?

    @State private var scrollPosition: CGFloat = 0
    @State private var currentHourOffset: CGFloat = 0
    @State private var dragTargetSlot: (date: Date, hour: Int)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Configuration
    private let hourHeight: CGFloat = 60
    private let dayWidth: CGFloat = 100
    private let headerHeight: CGFloat = 60
    private let startHour: Int = 6  // 6 AM
    private let endHour: Int = 23   // 11 PM

    private var weekDates: [Date] {
        let calendar = Calendar.current
        return (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: centerDate)
        }
    }

    private var totalHours: Int {
        endHour - startHour
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Day headers
                dayHeaders

                // Scrollable timeline
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid
                        hourGrid

                        // Current time indicator
                        CurrentTimeLineView(
                            hourHeight: hourHeight,
                            startHour: startHour,
                            dayWidth: dayWidth,
                            weekDates: weekDates
                        )

                        // Task blocks for each day
                        ForEach(weekDates, id: \.self) { date in
                            dayColumn(for: date, index: weekDates.firstIndex(of: date) ?? 0)
                        }
                    }
                    .frame(height: CGFloat(totalHours) * hourHeight)
                }
            }
        }
        .background(Color.clear)
    }

    // MARK: - Day Headers

    private var dayHeaders: some View {
        HStack(spacing: 0) {
            // Time column spacer
            Color.clear
                .frame(width: 50)

            // Day headers
            ForEach(weekDates, id: \.self) { date in
                dayHeader(for: date)
            }
        }
        .frame(height: headerHeight)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }

    private func dayHeader(for date: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: centerDate)

        return VStack(spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isToday ? Theme.Colors.accent : Theme.Colors.textSecondary)

            ZStack {
                if isToday {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 32, height: 32)
                } else if isSelected {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.glassBackground)
                        .frame(width: 32, height: 32)
                }

                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 16, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(isToday ? .white : Theme.Colors.textPrimary)
            }
        }
        .frame(width: dayWidth)
    }

    // MARK: - Hour Grid

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(spacing: 0) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(width: 50, alignment: .trailing)
                        .padding(.trailing, 8)

                    // Grid lines
                    Rectangle()
                        .fill(Theme.Colors.textTertiary.opacity(0.1))
                        .frame(height: 1)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        guard let date = Calendar.current.date(from: components) else { return "" }
        return formatter.string(from: date)
    }

    // MARK: - Day Column

    private func dayColumn(for date: Date, index: Int) -> some View {
        let dayTasks = tasksForDay(date)
        let xOffset: CGFloat = 50 + (CGFloat(index) * dayWidth)

        return ZStack(alignment: .top) {
            // Tappable/droppable slots for empty areas
            ForEach(startHour..<endHour, id: \.self) { hour in
                let isDropTarget = dragTargetSlot?.date == date && dragTargetSlot?.hour == hour

                TimeSlotDropZone(
                    date: date,
                    hour: hour,
                    dayWidth: dayWidth,
                    hourHeight: hourHeight,
                    startHour: startHour,
                    isDropTarget: isDropTarget,
                    onTap: { tapDate in
                        onSlotTap(tapDate)
                    },
                    onDrop: { task, targetDate in
                        onReschedule?(task, targetDate)
                    },
                    onTargetChange: { targeted in
                        if targeted {
                            dragTargetSlot = (date, hour)
                        } else if dragTargetSlot?.date == date && dragTargetSlot?.hour == hour {
                            dragTargetSlot = nil
                        }
                    }
                )
            }

            // Draggable task blocks
            ForEach(dayTasks) { task in
                WeekTaskBlock(
                    task: task,
                    hourHeight: hourHeight,
                    dayWidth: dayWidth - 8,
                    startHour: startHour,
                    onTap: { onTaskTap(task) }
                )
                .draggable(task) {
                    TaskDragPreview(task: task)
                }
            }
        }
        .frame(width: dayWidth)
        .offset(x: xOffset)
    }

    private func tasksForDay(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }
    }
}

// MARK: - Week Task Block

struct WeekTaskBlock: View {
    let task: TaskItem
    let hourHeight: CGFloat
    let dayWidth: CGFloat
    let startHour: Int
    let onTap: () -> Void

    @State private var isPressed = false

    private var topOffset: CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)
        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) * hourHeight / 60
    }

    private var blockHeight: CGFloat {
        let minutes = task.estimatedMinutes ?? 30
        return max(CGFloat(minutes) * hourHeight / 60, hourHeight / 2)
    }

    private var taskColor: Color {
        switch task.starRating {
        case 3: return Theme.Colors.error
        case 2: return Theme.Colors.xp
        default: return Theme.Colors.aiBlue
        }
    }

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let mins = task.estimatedMinutes, mins > 30 {
                    Text("\(mins) min")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(width: dayWidth - 4, height: blockHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(taskColor.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(taskColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1)
        .offset(x: dayWidth / 2, y: topOffset + blockHeight / 2)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Current Time Line

struct CurrentTimeLineView: View {
    let hourHeight: CGFloat
    let startHour: Int
    let dayWidth: CGFloat
    let weekDates: [Date]

    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var currentHour: Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        return Double(hour) + Double(minute) / 60
    }

    private var yOffset: CGFloat {
        CGFloat(currentHour - Double(startHour)) * hourHeight
    }

    private var todayIndex: Int? {
        weekDates.firstIndex { Calendar.current.isDateInToday($0) }
    }

    var body: some View {
        if let todayIndex = todayIndex,
           Int(currentHour) >= startHour {
            let xOffset = 50 + CGFloat(todayIndex) * dayWidth

            ZStack(alignment: .leading) {
                // Line
                Rectangle()
                    .fill(Theme.Colors.error)
                    .frame(width: dayWidth, height: 2)

                // Circle indicator
                SwiftUI.Circle()
                    .fill(Theme.Colors.error)
                    .frame(width: 10, height: 10)
                    .offset(x: -5)
            }
            .offset(x: xOffset, y: yOffset)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }
}

// MARK: - Time Slot Drop Zone

struct TimeSlotDropZone: View {
    let date: Date
    let hour: Int
    let dayWidth: CGFloat
    let hourHeight: CGFloat
    let startHour: Int
    let isDropTarget: Bool
    let onTap: (Date) -> Void
    let onDrop: (TaskItem, Date) -> Void
    let onTargetChange: (Bool) -> Void

    @State private var isTargeted = false

    private var targetDate: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        return calendar.date(from: components) ?? date
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: dayWidth - 8, height: hourHeight)
            .contentShape(Rectangle())
            .background {
                if isTargeted || isDropTarget {
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                .fill(Theme.Colors.accent.opacity(0.15))
                        )
                        .transition(.opacity)
                }
            }
            .position(
                x: dayWidth / 2,
                y: CGFloat(hour - startHour) * hourHeight + hourHeight / 2
            )
            .onTapGesture {
                onTap(targetDate)
            }
            .dropDestination(for: TaskItem.self) { items, _ in
                guard let task = items.first else { return false }
                HapticsService.shared.success()
                onDrop(task, targetDate)
                return true
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isTargeted = targeted
                    onTargetChange(targeted)
                }
            }
    }
}

// MARK: - Preview

#Preview("Week View Timeline") {
    WeekViewTimeline(
        centerDate: Date(),
        tasks: [],
        onTaskTap: { _ in },
        onSlotTap: { _ in }
    )
    .background { VoidBackground.calendar }
}
