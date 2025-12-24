//
//  TiimoCalendarView.swift
//  Veloce
//
//  Tiimo-Style Visual Planner Main Container
//  The complete Tiimo-inspired calendar experience
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - Tiimo Calendar View

/// Main container for the Tiimo-style visual planner
struct TiimoCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]
    @Bindable var viewModel: CalendarViewModel

    @State private var viewMode: TiimoViewMode = .day
    @State private var selectedDate: Date = Date()
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false
    @State private var showDatePicker = false
    @State private var showRescheduleConfirmation = false
    @State private var rescheduleTask: TaskItem?
    @State private var rescheduleNewTime: Date?
    @State private var showQuickAdd = false
    @State private var quickAddTime: Date?

    // MARK: - Computed Properties

    private var tasksForSelectedDate: [TaskItem] {
        let calendar = Calendar.current
        return allTasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: selectedDate)
        }.sorted { ($0.scheduledTime ?? Date.distantFuture) < ($1.scheduledTime ?? Date.distantFuture) }
    }

    private var eventsForSelectedDate: [EKEvent] {
        viewModel.events(for: selectedDate)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            VoidBackground.calendar

            if !viewModel.isAuthorized {
                calendarPermissionView
            } else {
                calendarContent
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
        .sheet(isPresented: $showQuickAdd) {
            if let time = quickAddTime {
                TimelineQuickAddView(
                    selectedTime: time,
                    onAdd: { title, selectedTime, duration in
                        createQuickTask(title: title, time: selectedTime, duration: duration)
                        showQuickAdd = false
                        quickAddTime = nil
                    },
                    onCancel: {
                        showQuickAdd = false
                        quickAddTime = nil
                    }
                )
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
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
                            Theme.Colors.aiPurple.opacity(0.6),
                            Theme.Colors.aiCyan.opacity(0.4)
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
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 4)
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
            TiimoDateCarousel(
                selectedDate: $selectedDate,
                hasEvents: hasEvents(on:)
            )

            // Main content area
            ZStack {
                switch viewMode {
                case .day:
                    TiimoDayView(
                        date: selectedDate,
                        tasks: tasksForSelectedDate,
                        events: eventsForSelectedDate,
                        onTaskTap: { task in
                            selectedTask = task
                            showTaskDetail = true
                        },
                        onEventTap: nil,
                        onReschedule: { task, newTime in
                            rescheduleTask = task
                            rescheduleNewTime = newTime
                            showRescheduleConfirmation = true
                        },
                        onTimeSlotTap: { time in
                            quickAddTime = time
                            showQuickAdd = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case .week:
                    TiimoWeekView(
                        centerDate: selectedDate,
                        tasks: allTasks,
                        events: viewModel.events,
                        onTaskTap: { task in
                            selectedTask = task
                            showTaskDetail = true
                        },
                        onDayTap: { date in
                            withAnimation(TiimoDesignTokens.Animation.viewTransition) {
                                selectedDate = date
                                viewMode = .day
                            }
                        },
                        onReschedule: { task, newTime in
                            rescheduleTask = task
                            rescheduleNewTime = newTime
                            showRescheduleConfirmation = true
                        }
                    )
                    .transition(.scale.combined(with: .opacity))

                case .month:
                    TiimoMonthView(
                        selectedDate: $selectedDate,
                        tasks: allTasks,
                        onDateSelect: { date in
                            withAnimation(TiimoDesignTokens.Animation.viewTransition) {
                                viewMode = .day
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .animation(TiimoDesignTokens.Animation.viewTransition, value: viewMode)

            Spacer()

            // Scheduled tasks list
            if !tasksForSelectedDate.isEmpty && viewMode == .day {
                scheduledTasksList
            } else if tasksForSelectedDate.isEmpty && viewMode == .day {
                TiimoDayEmptyState {
                    quickAddTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate)
                    showQuickAdd = true
                }
            }
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        HStack {
            // Month/Year button
            TiimoMonthYearHeader(
                selectedDate: $selectedDate,
                onMonthTap: {
                    HapticsService.shared.selectionFeedback()
                    showDatePicker = true
                }
            )

            Spacer()

            // View mode toggle
            TiimoViewModeToggle(viewMode: $viewMode)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Scheduled Tasks List

    private var scheduledTasksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Text("\(tasksForSelectedDate.count) task\(tasksForSelectedDate.count == 1 ? "" : "s")")
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

    // MARK: - Actions

    private func performReschedule(task: TaskItem, to newTime: Date, updateCalendar: Bool) {
        task.scheduledTime = newTime
        task.timesRescheduled = (task.timesRescheduled ?? 0) + 1
        try? modelContext.save()

        if updateCalendar, let eventId = task.calendarEventId {
            Task {
                await viewModel.updateCalendarEvent(eventId: eventId, newTime: newTime)
            }
        }

        HapticsService.shared.success()
    }

    private func createQuickTask(title: String, time: Date, duration: Int) {
        let task = TaskItem(
            title: title,
            estimatedMinutes: duration,
            scheduledTime: time,
            taskTypeRaw: "coordinate"
        )
        modelContext.insert(task)
        try? modelContext.save()

        HapticsService.shared.success()
    }

    private func hasEvents(on date: Date) -> Bool {
        let calendar = Calendar.current
        return allTasks.contains { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TiimoCalendarView(viewModel: CalendarViewModel())
    }
}
