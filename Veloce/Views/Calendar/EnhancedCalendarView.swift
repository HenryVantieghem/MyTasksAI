//
//  EnhancedCalendarView.swift
//  MyTasksAI
//
//  Enhanced Calendar - Container with Timeline & Grid views
//  Full Apple Calendar integration with premium visual design
//

import SwiftUI
import SwiftData

// MARK: - Timeline Display Mode

enum TimelineDisplayMode: String, CaseIterable {
    case timeline = "Timeline"
    case week = "Week"
    case month = "Month"

    var icon: String {
        switch self {
        case .timeline: return "chart.bar.xaxis"
        case .week: return "calendar.day.timeline.left"
        case .month: return "calendar"
        }
    }
}

// MARK: - Enhanced Calendar View

struct EnhancedCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]
    @Bindable var viewModel: CalendarViewModel

    @State private var viewMode: TimelineDisplayMode = .timeline
    @State private var selectedDate: Date = Date()
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false
    @State private var showDatePicker = false
    @State private var showRescheduleConfirmation = false
    @State private var rescheduleTask: TaskItem?
    @State private var rescheduleNewTime: Date?

    private var tasksForSelectedDate: [TaskItem] {
        let calendar = Calendar.current
        return allTasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        ZStack {
            // Background - Void design system
            VoidBackground.calendar

            if !viewModel.isAuthorized {
                calendarPermissionView
            } else {
                calendarContent
            }
        }
    }

    // MARK: - Permission View

    private var calendarPermissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.6),
                            Color(red: 0.024, green: 0.714, blue: 0.831).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("Calendar Access Required")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text("Enable calendar access to sync your tasks with your schedule and unlock the visual timeline.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await viewModel.requestAccess()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                    Text("Enable Calendar Access")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.545, green: 0.361, blue: 0.965),
                            Color(red: 0.231, green: 0.510, blue: 0.965)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.4), radius: 12, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
        .padding(.top, Theme.Spacing.universalHeaderHeight)
    }

    // MARK: - Calendar Content

    private var calendarContent: some View {
        VStack(spacing: 0) {
            // Spacing below universal header
            Spacer()
                .frame(height: Theme.Spacing.universalHeaderHeight)

            // Header with date navigation and view toggle
            calendarHeader

            // Date carousel
            dateCarousel

            // Main content area
            ZStack {
                switch viewMode {
                case .timeline:
                    VisualTimelineView(
                        date: selectedDate,
                        tasks: tasksForSelectedDate,
                        onTaskTap: { task in
                            selectedTask = task
                            showTaskDetail = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case .week:
                    WeekViewTimeline(
                        centerDate: selectedDate,
                        tasks: allTasks,
                        onTaskTap: { task in
                            selectedTask = task
                            showTaskDetail = true
                        },
                        onSlotTap: { date in
                            // Handle quick add at time slot
                            selectedDate = date
                            HapticsService.shared.selectionFeedback()
                        },
                        onReschedule: { task, newTime in
                            rescheduleTask = task
                            rescheduleNewTime = newTime
                            showRescheduleConfirmation = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))

                case .month:
                    MonthGridView(
                        selectedDate: $selectedDate,
                        tasks: allTasks
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewMode)

            Spacer()

            // Task list for selected date
            if !tasksForSelectedDate.isEmpty {
                scheduledTasksList
            } else {
                emptyStateView
            }
        }
        .sheet(isPresented: $showTaskDetail) {
            if let task = selectedTask {
                CalendarTaskPreviewSheet(task: task)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            CalendarDatePickerSheet(selectedDate: $selectedDate)
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRescheduleConfirmation) {
            if let task = rescheduleTask, let newTime = rescheduleNewTime {
                RescheduleConfirmationSheet(
                    task: task,
                    originalTime: task.scheduledTime,
                    newTime: newTime,
                    onConfirm: { updateCalendarEvent in
                        performReschedule(task: task, to: newTime, updateCalendar: updateCalendarEvent)
                        showRescheduleConfirmation = false
                        rescheduleTask = nil
                        rescheduleNewTime = nil
                    },
                    onCancel: {
                        showRescheduleConfirmation = false
                        rescheduleTask = nil
                        rescheduleNewTime = nil
                    }
                )
            }
        }
    }

    // MARK: - Reschedule Action

    private func performReschedule(task: TaskItem, to newTime: Date, updateCalendar: Bool) {
        task.scheduledTime = newTime
        try? modelContext.save()

        // Update calendar event if requested
        if updateCalendar, let eventId = task.calendarEventId {
            Task {
                await viewModel.updateCalendarEvent(eventId: eventId, newTime: newTime)
            }
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        HStack {
            // Month/Year button
            Button {
                HapticsService.shared.selectionFeedback()
                showDatePicker = true
            } label: {
                HStack(spacing: 8) {
                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // View mode toggle
            viewModeToggle
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: 4) {
            ForEach(TimelineDisplayMode.allCases, id: \.self) { mode in
                Button {
                    HapticsService.shared.selectionFeedback()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewMode = mode
                    }
                } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(viewMode == mode ? .white : .white.opacity(0.4))
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewMode == mode ? .white.opacity(0.15) : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Date Carousel

    private var dateCarousel: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(-3..<11, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        DateCarouselItem(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            hasEvents: hasEvents(on: date)
                        ) {
                            HapticsService.shared.selectionFeedback()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedDate = date
                            }
                        }
                        .id(offset)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 80)
            .onAppear {
                proxy.scrollTo(0, anchor: .center)
            }
        }
    }

    // MARK: - Scheduled Tasks List

    private var scheduledTasksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Text("\(tasksForSelectedDate.count) tasks")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(tasksForSelectedDate) { task in
                        ScheduledTaskCard(task: task) {
                            selectedTask = task
                            showTaskDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.6),
                            Color(red: 0.024, green: 0.714, blue: 0.831).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 4) {
                Text("No tasks scheduled")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text("Drag tasks to the timeline or tap + to add")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func hasEvents(on date: Date) -> Bool {
        let calendar = Calendar.current
        return allTasks.contains { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }
    }
}

// MARK: - Date Carousel Item

struct DateCarouselItem: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let onTap: () -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Day of week
                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
                    .tracking(1)

                // Day number
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                // Event indicator
                Circle()
                    .fill(hasEvents ? eventIndicatorColor : .clear)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 56, height: 72)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.4),
                                        Color(red: 0.231, green: 0.510, blue: 0.965).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    } else if isToday {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var eventIndicatorColor: Color {
        if isSelected {
            return .white
        }
        return Color(red: 0.024, green: 0.714, blue: 0.831)
    }
}

// MARK: - Scheduled Task Card

struct ScheduledTaskCard: View {
    let task: TaskItem
    let onTap: () -> Void

    @State private var isPressed = false

    private var taskColor: Color {
        switch task.taskType {
        case .create:
            return Color(red: 0.545, green: 0.361, blue: 0.965)
        case .communicate:
            return Color(red: 0.231, green: 0.510, blue: 0.965)
        case .consume:
            return Color(red: 0.024, green: 0.714, blue: 0.831)
        case .coordinate:
            return Color(red: 0.961, green: 0.420, blue: 0.420)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(taskColor)
                    .frame(width: 4, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let time = task.scheduledTime {
                        Text(time.formatted(.dateTime.hour().minute()))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                if let minutes = task.estimatedMinutes {
                    Text("\(minutes)m")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.1))
                        )
                }
            }
            .padding(12)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Month Grid View (Placeholder)

struct MonthGridView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]

    @State private var displayedMonth: Date = Date()

    private var calendar: Calendar { Calendar.current }

    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }

        var days: [Date] = []
        var currentDay = monthFirstWeek.start

        while currentDay < monthLastWeek.end {
            days.append(currentDay)
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
        }

        return days
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(monthDays, id: \.self) { date in
                    MonthDayCell(
                        date: date,
                        displayedMonth: displayedMonth,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasEvents: hasEvents(on: date)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 16)
    }

    private func hasEvents(on date: Date) -> Bool {
        tasks.contains { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }
    }
}

// MARK: - Month Day Cell

struct MonthDayCell: View {
    let date: Date
    let displayedMonth: Date
    let isSelected: Bool
    let hasEvents: Bool
    let onTap: () -> Void

    private var calendar: Calendar { Calendar.current }

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 15, weight: isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(foregroundColor)

                // Event dot
                Circle()
                    .fill(hasEvents && isInCurrentMonth ? dotColor : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.5),
                                        Color(red: 0.231, green: 0.510, blue: 0.965).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                    } else if isToday {
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 40, height: 40)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        }
        if !isInCurrentMonth {
            return .white.opacity(0.2)
        }
        if isToday {
            return Color(red: 0.024, green: 0.714, blue: 0.831)
        }
        return .white.opacity(0.8)
    }

    private var dotColor: Color {
        if isSelected {
            return .white
        }
        return Color(red: 0.024, green: 0.714, blue: 0.831)
    }
}

// MARK: - Calendar Date Picker Sheet

struct CalendarDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Select Date")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.024, green: 0.714, blue: 0.831))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .tint(Color(red: 0.024, green: 0.714, blue: 0.831))
                .padding(.horizontal, 8)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    }
}

// MARK: - Calendar Task Preview Sheet

struct CalendarTaskPreviewSheet: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss

    private var taskColor: Color {
        switch task.taskType {
        case .create:
            return Color(red: 0.545, green: 0.361, blue: 0.965)
        case .communicate:
            return Color(red: 0.231, green: 0.510, blue: 0.965)
        case .consume:
            return Color(red: 0.024, green: 0.714, blue: 0.831)
        case .coordinate:
            return Color(red: 0.961, green: 0.420, blue: 0.420)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with color accent
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(taskColor)
                    .frame(width: 4, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        Label(task.taskType.rawValue, systemImage: taskTypeIcon)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(taskColor)

                        if let minutes = task.estimatedMinutes {
                            Text("•")
                                .foregroundStyle(.white.opacity(0.3))
                            Text("\(minutes) min")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()
                .background(.white.opacity(0.1))

            // Time info
            if let scheduledTime = task.scheduledTime {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(scheduledTime.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            // Notes if any
            if let notes = task.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(notes)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Spacer()
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    }

    private var taskTypeIcon: String {
        switch task.taskType {
        case .create: return "paintbrush.fill"
        case .communicate: return "bubble.left.fill"
        case .consume: return "book.fill"
        case .coordinate: return "person.2.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EnhancedCalendarView(viewModel: CalendarViewModel())
    }
}
