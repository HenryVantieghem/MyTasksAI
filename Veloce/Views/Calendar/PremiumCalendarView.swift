//
//  PremiumCalendarView.swift
//  Veloce
//
//  Premium Calendar - Apple Calendar-inspired design with glass effects
//  Day, Week (7-column), and Month views with swipe gestures
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - Premium Calendar View

struct PremiumCalendarView: View {
    @Bindable var viewModel: CalendarViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: State
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetailSheet = false
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var showQuickAdd = false
    @State private var quickAddDate: Date?
    @State private var showDatePicker = false
    @State private var showNewTaskDetail = false
    @State private var newTaskForDetail: TaskItem?
    @State private var draggedTask: TaskItem?
    @State private var dragOffset: CGSize = .zero

    // MARK: Animation
    @Namespace private var calendarAnimation

    // Week dates for week view
    private var currentWeekDates: [Date] {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: viewModel.selectedDate)?.start else {
            return []
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        ZStack {
            // Background
            VoidBackground.calendar

            if viewModel.isAuthorized {
                authorizedContent
            } else {
                CalendarPermissionView(onRequest: {
                    Task { await viewModel.requestAccess() }
                })
            }
        }
        .onAppear {
            viewModel.setup(context: modelContext)
            // Default to week view
            if viewModel.viewMode != .week {
                viewModel.viewMode = .week
            }
        }
        .sheet(isPresented: $showDatePicker) {
            CalendarDatePickerSheet(selectedDate: $viewModel.selectedDate)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        // iOS-Native Slidable Bottom Sheet for Task Details
        .slidableBottomSheet(
            isPresented: $showTaskDetailSheet,
            selectedDetent: $sheetDetent,
            detents: [.fraction(0.25), .medium, .fraction(0.85), .large],
            showDragIndicator: true,
            cornerRadius: 32,
            backgroundStyle: .celestial
        ) {
            if let task = selectedTask {
                TaskDetailBottomSheet(
                    task: task,
                    onComplete: {
                        completeTask(task)
                    },
                    onDuplicate: {
                        duplicateTask(task)
                    },
                    onSnooze: { date in
                        snoozeTask(task, to: date)
                    },
                    onDelete: {
                        deleteTask(task)
                    },
                    onSchedule: { date in
                        rescheduleTask(task, to: date)
                    },
                    onStartTimer: { _ in }
                )
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            if let date = quickAddDate {
                EnhancedQuickAddView(
                    selectedTime: date,
                    onAdd: { title, scheduledDate, duration in
                        addNewTask(title: title, date: scheduledDate, duration: duration)
                        showQuickAdd = false
                    },
                    onCancel: { showQuickAdd = false },
                    onExpandToDetail: {
                        showQuickAdd = false
                        let task = TaskItem(title: "")
                        task.scheduledTime = date
                        modelContext.insert(task)
                        newTaskForDetail = task
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showNewTaskDetail = true
                        }
                    }
                )
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
            }
        }
        .slidableBottomSheet(
            isPresented: $showNewTaskDetail,
            selectedDetent: .constant(.large),
            detents: [.medium, .large],
            showDragIndicator: true,
            cornerRadius: 32,
            backgroundStyle: .celestial
        ) {
            if let task = newTaskForDetail {
                TaskDetailBottomSheet(
                    task: task,
                    onComplete: {
                        completeTask(task)
                        newTaskForDetail = nil
                    },
                    onDuplicate: {},
                    onSnooze: { _ in },
                    onDelete: {
                        deleteTask(task)
                        newTaskForDetail = nil
                    },
                    onSchedule: { date in
                        rescheduleTask(task, to: date)
                    },
                    onStartTimer: { _ in }
                )
            }
        }
        .onChange(of: showNewTaskDetail) { _, isPresented in
            if !isPresented {
                // Keep the task if it has a title
                if let task = newTaskForDetail, task.title.isEmpty {
                    modelContext.delete(task)
                }
                newTaskForDetail = nil
                Task { await viewModel.loadData() }
            }
        }
    }

    // MARK: - Authorized Content

    private var authorizedContent: some View {
        VStack(spacing: 0) {
            // Premium Header
            PremiumCalendarHeader(
                selectedDate: $viewModel.selectedDate,
                viewMode: $viewModel.viewMode,
                onPrevious: { viewModel.goToPrevious() },
                onNext: { viewModel.goToNext() },
                onDateTap: { showDatePicker = true }
            )
            .padding(.top, 8)

            // Content based on view mode
            Group {
                switch viewModel.viewMode {
                case .day:
                    dayViewContent
                case .week:
                    weekAtGlanceContent
                case .month:
                    monthViewContent
                }
            }
            .gesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height

                        // Only handle horizontal swipes (ignore vertical scrolling)
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if horizontalAmount < -50 {
                                    viewModel.goToNext()
                                } else if horizontalAmount > 50 {
                                    viewModel.goToPrevious()
                                }
                            }
                        }
                    }
            )
        }
        .safeAreaInset(edge: .bottom) {
            quickAddButton
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .allowsHitTesting(false)
                }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.viewMode)
    }

    // MARK: - Day View Content (Full single day timeline)

    private var dayViewContent: some View {
        VStack(spacing: 0) {
            // Compact week strip for day navigation
            PremiumWeekStrip(
                selectedDate: $viewModel.selectedDate,
                tasks: viewModel.scheduledTasks,
                events: viewModel.events,
                onDayTap: { date in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.selectedDate = date
                    }
                    HapticsService.shared.selectionFeedback()
                }
            )
            .padding(.vertical, 8)

            // Selected Day Label
            selectedDayLabel
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            // Full Day Timeline (6am-10pm)
            PremiumDayTimeline(
                date: viewModel.selectedDate,
                tasks: viewModel.tasks(for: viewModel.selectedDate),
                events: viewModel.events(for: viewModel.selectedDate),
                onTaskTap: { task in
                    selectedTask = task
                    sheetDetent = .medium
                    showTaskDetailSheet = true
                },
                onTimeSlotTap: { date in
                    quickAddDate = date
                    showQuickAdd = true
                },
                onTaskComplete: { task in
                    completeTask(task)
                },
                onTaskDrag: { task, newTime in
                    rescheduleTask(task, to: newTime)
                }
            )
        }
    }

    // MARK: - Week At Glance Content (Apple Calendar-style 7 columns)

    private var weekAtGlanceContent: some View {
        VStack(spacing: 0) {
            // Week day header with date selection
            WeekDayHeader(
                weekDates: currentWeekDates,
                selectedDate: $viewModel.selectedDate,
                timeGutterWidth: 44
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)

            // 7-column week timeline
            WeekAtGlanceView(
                selectedDate: $viewModel.selectedDate,
                weekDates: currentWeekDates,
                tasks: viewModel.scheduledTasks,
                events: viewModel.events,
                onTaskTap: { task in
                    selectedTask = task
                    sheetDetent = .medium
                    showTaskDetailSheet = true
                },
                onTimeSlotTap: { date in
                    quickAddDate = date
                    showQuickAdd = true
                },
                onTaskDrag: { task, newTime in
                    rescheduleTask(task, to: newTime)
                },
                onTaskComplete: { task in
                    completeTask(task)
                }
            )
        }
    }

    // MARK: - Month View Content

    private var monthViewContent: some View {
        VStack(spacing: 0) {
            // Month Grid
            PremiumMonthView(
                selectedDate: $viewModel.selectedDate,
                tasks: viewModel.scheduledTasks,
                events: viewModel.events,
                onDayTap: { date in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.selectedDate = date
                        // Switch to day view when tapping a day
                        viewModel.viewMode = .day
                    }
                    HapticsService.shared.selectionFeedback()
                }
            )
            .padding(.top, 12)

            Spacer()

            // Upcoming tasks for the month
            if !viewModel.scheduledTasks.isEmpty {
                upcomingTasksList
            }
        }
    }

    // MARK: - Upcoming Tasks List

    private var upcomingTasksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.scheduledTasks.prefix(6)) { task in
                        upcomingTaskCard(task)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }

    private func upcomingTaskCard(_ task: TaskItem) -> some View {
        Button {
            selectedTask = task
            sheetDetent = .medium
            showTaskDetailSheet = true
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(task.taskType.tiimoColor)
                    .frame(width: 3, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let time = task.scheduledTime {
                        Text(time.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()
            }
            .padding(12)
            .frame(width: 180)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Selected Day Label

    private var selectedDayLabel: some View {
        HStack {
            Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            // Task count for the day
            let dayTaskCount = viewModel.tasks(for: viewModel.selectedDate).count
            if dayTaskCount > 0 {
                Text("\(dayTaskCount) task\(dayTaskCount == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        Button {
            HapticsService.shared.impact()
            quickAddDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: viewModel.selectedDate)
            showQuickAdd = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))

                Text("Add task to \(viewModel.selectedDate.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(0.8),
                                Theme.Colors.aiBlue.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    }
            }
            .shadow(color: Theme.Colors.aiPurple.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
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

        Task {
            await viewModel.loadData()
        }
    }

    private func rescheduleTask(_ task: TaskItem, to newTime: Date) {
        task.scheduledTime = newTime
        task.updatedAt = Date()
        try? modelContext.save()
        HapticsService.shared.success()

        Task {
            await viewModel.loadData()
        }
    }

    private func snoozeTask(_ task: TaskItem, to date: Date) {
        task.scheduledTime = date
        task.updatedAt = Date()
        try? modelContext.save()
        HapticsService.shared.success()

        Task {
            await viewModel.loadData()
        }
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

        Task {
            await viewModel.loadData()
        }
    }

    private func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
        HapticsService.shared.impact()

        Task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Calendar Permission View

struct CalendarPermissionView: View {
    let onRequest: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            Theme.Colors.aiPurple.opacity(0.1 - Double(i) * 0.03),
                            lineWidth: 1
                        )
                        .frame(width: 140 + CGFloat(i) * 30, height: 140 + CGFloat(i) * 30)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(0.2),
                                Theme.Colors.aiPurple.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("Connect Your Calendar")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("See your Apple Calendar events alongside\nyour tasks for a complete view of your day")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onRequest) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Connect Calendar")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 16, y: 8)
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview {
    PremiumCalendarView(viewModel: CalendarViewModel())
}
