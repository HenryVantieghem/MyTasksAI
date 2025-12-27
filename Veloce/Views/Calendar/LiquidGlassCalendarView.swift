//
//  LiquidGlassCalendarView.swift
//  Veloce
//
//  iOS 26 Liquid Glass Calendar - Apple Calendar-inspired design
//  Proper HIG compliance with responsive layouts and native materials
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - Liquid Glass Calendar View

struct LiquidGlassCalendarView: View {
    @Bindable var viewModel: CalendarViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: State
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetailSheet = false
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var showQuickAdd = false
    @State private var quickAddDate: Date?
    @State private var showDatePicker = false
    @State private var showNewTaskDetail = false
    @State private var newTaskForDetail: TaskItem?

    // MARK: Animation
    @Namespace private var calendarAnimation

    // MARK: Layout Constants (4pt/8pt grid system)
    private var gridSpacing: CGFloat { 8 }
    private var sectionSpacing: CGFloat { 16 }
    private var screenPadding: CGFloat { horizontalSizeClass == .regular ? 24 : 16 }

    // Responsive day cell size based on device
    private func dayCellSize(in geometry: GeometryProxy) -> CGFloat {
        let availableWidth = geometry.size.width - (screenPadding * 2)
        let cellWidth = (availableWidth - (gridSpacing * 6)) / 7
        return max(cellWidth, 44) // Minimum 44pt for touch targets
    }

    // Week dates for week view
    private var currentWeekDates: [Date] {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: viewModel.selectedDate)?.start else {
            return []
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Adaptive background - respects system appearance
                adaptiveBackground

                if viewModel.isAuthorized {
                    authorizedContent(geometry: geometry)
                } else {
                    CalendarPermissionRequestView(onRequest: {
                        Task { await viewModel.requestAccess() }
                    })
                }
            }
        }
        .onAppear {
            viewModel.setup(context: modelContext)
            if viewModel.viewMode != .week {
                viewModel.viewMode = .week
            }
        }
        .sheet(isPresented: $showDatePicker) {
            LiquidGlassDatePickerSheet(selectedDate: $viewModel.selectedDate)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTaskDetailSheet) {
            if let task = selectedTask {
                CalendarTaskDetailSheet(
                    task: task,
                    onComplete: { completeTask(task) },
                    onDuplicate: { duplicateTask(task) },
                    onSnooze: { date in snoozeTask(task, to: date) },
                    onDelete: { deleteTask(task) },
                    onSchedule: { date in rescheduleTask(task, to: date) }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            if let date = quickAddDate {
                QuickAddTaskSheet(
                    selectedTime: date,
                    onAdd: { title, scheduledDate, duration in
                        addNewTask(title: title, date: scheduledDate, duration: duration)
                        showQuickAdd = false
                    },
                    onCancel: { showQuickAdd = false }
                )
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Adaptive Background

    @ViewBuilder
    private var adaptiveBackground: some View {
        // Use system background that adapts to light/dark mode
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }

    // MARK: - Authorized Content

    private func authorizedContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // iOS 26 Liquid Glass Header
            LiquidGlassCalendarHeader(
                selectedDate: $viewModel.selectedDate,
                viewMode: $viewModel.viewMode,
                onPrevious: { viewModel.goToPrevious() },
                onNext: { viewModel.goToNext() },
                onDateTap: { showDatePicker = true },
                onTodayTap: { viewModel.selectedDate = Date() }
            )

            // Content based on view mode
            Group {
                switch viewModel.viewMode {
                case .day:
                    LiquidGlassDayView(
                        date: viewModel.selectedDate,
                        tasks: viewModel.tasks(for: viewModel.selectedDate),
                        events: viewModel.events(for: viewModel.selectedDate),
                        onTaskTap: { task in
                            selectedTask = task
                            showTaskDetailSheet = true
                        },
                        onTimeSlotTap: { date in
                            quickAddDate = date
                            showQuickAdd = true
                        },
                        onTaskComplete: completeTask,
                        onTaskDrag: rescheduleTask
                    )

                case .week:
                    LiquidGlassWeekView(
                        selectedDate: $viewModel.selectedDate,
                        weekDates: currentWeekDates,
                        tasks: viewModel.scheduledTasks,
                        events: viewModel.events,
                        onTaskTap: { task in
                            selectedTask = task
                            showTaskDetailSheet = true
                        },
                        onTimeSlotTap: { date in
                            quickAddDate = date
                            showQuickAdd = true
                        },
                        onTaskDrag: rescheduleTask,
                        onTaskComplete: completeTask
                    )

                case .month:
                    LiquidGlassMonthView(
                        selectedDate: $viewModel.selectedDate,
                        tasks: viewModel.scheduledTasks,
                        events: viewModel.events,
                        cellSize: dayCellSize(in: geometry),
                        onDayTap: { date in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.selectedDate = date
                                viewModel.viewMode = .day
                            }
                            HapticsService.shared.selectionFeedback()
                        }
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 80, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height

                        // Only handle clear horizontal swipes
                        if abs(horizontalAmount) > abs(verticalAmount) * 2 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if horizontalAmount < -80 {
                                    viewModel.goToNext()
                                } else if horizontalAmount > 80 {
                                    viewModel.goToPrevious()
                                }
                            }
                        }
                    }
            )
        }
        .safeAreaInset(edge: .bottom) {
            // Floating add button with Liquid Glass
            floatingAddButton
                .padding(.horizontal, screenPadding)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Floating Add Button (Liquid Glass)

    @ViewBuilder
    private var floatingAddButton: some View {
        Button {
            HapticsService.shared.impact()
            quickAddDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: viewModel.selectedDate)
            showQuickAdd = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))

                Text("Add Task")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50) // 50pt height for comfortable touch
            .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func addNewTask(title: String, date: Date, duration: Int) {
        let task = TaskItem(title: title)
        task.scheduledTime = date
        task.duration = duration
        task.estimatedMinutes = duration
        modelContext.insert(task)

        Task {
            try? await viewModel.scheduleTask(task, at: date)
        }
    }

    private func completeTask(_ task: TaskItem) {
        task.isCompleted = true
        task.completedAt = Date()
        try? modelContext.save()
        HapticsService.shared.taskComplete()

        Task { await viewModel.loadData() }
    }

    private func rescheduleTask(_ task: TaskItem, to newTime: Date) {
        task.scheduledTime = newTime
        task.updatedAt = Date()
        try? modelContext.save()
        HapticsService.shared.success()

        Task { await viewModel.loadData() }
    }

    private func snoozeTask(_ task: TaskItem, to date: Date) {
        rescheduleTask(task, to: date)
    }

    private func duplicateTask(_ task: TaskItem) {
        let newTask = TaskItem(title: task.title)
        newTask.taskTypeRaw = task.taskTypeRaw
        newTask.estimatedMinutes = task.estimatedMinutes
        newTask.duration = task.duration
        newTask.notes = task.notes
        newTask.contextNotes = task.contextNotes
        newTask.starRating = task.starRating
        modelContext.insert(newTask)
        try? modelContext.save()
        HapticsService.shared.success()

        Task { await viewModel.loadData() }
    }

    private func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
        HapticsService.shared.impact()

        Task { await viewModel.loadData() }
    }
}

// MARK: - Calendar Permission Request View

struct CalendarPermissionRequestView: View {
    let onRequest: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon with subtle background
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 12) {
                Text("Connect Your Calendar")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("See your Apple Calendar events alongside\nyour tasks for a complete view of your day")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onRequest) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Connect Calendar")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(height: 50)
                .frame(maxWidth: 280)
                .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview {
    LiquidGlassCalendarView(viewModel: CalendarViewModel())
}
