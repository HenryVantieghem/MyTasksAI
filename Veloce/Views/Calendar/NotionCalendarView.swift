//
//  NotionCalendarView.swift
//  Veloce
//
//  Notion Calendar-Inspired Main Container
//  Clean, minimal calendar with swipeable navigation and beautiful animations
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - Notion Calendar View

struct NotionCalendarView: View {
    @Bindable var viewModel: CalendarViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: Sheet State
    @State private var showDatePicker = false
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false
    @State private var quickAddDate: Date?
    @State private var showQuickAdd = false

    // MARK: Gesture State
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false

    var body: some View {
        ZStack {
            // Background
            VoidBackground.calendar

            // Content
            if viewModel.isAuthorized {
                authorizedContent
            } else {
                permissionView
            }
        }
        .onAppear {
            viewModel.setup(context: modelContext)
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            Task {
                await viewModel.loadData()
            }
        }
        .onChange(of: viewModel.viewMode) { _, _ in
            Task {
                await viewModel.loadData()
            }
        }
        // Sheets
        .sheet(isPresented: $showDatePicker) {
            CalendarDatePickerSheet(selectedDate: $viewModel.selectedDate)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedTask) { task in
            CalendarTaskPreviewSheet(task: task)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showQuickAdd) {
            if let date = quickAddDate {
                TimelineQuickAddView(
                    selectedTime: date,
                    onAdd: { title, scheduledDate, duration in
                        let task = TaskItem(title: title)
                        task.scheduledTime = scheduledDate
                        task.duration = duration
                        Task {
                            try? await viewModel.scheduleTask(task, at: scheduledDate)
                        }
                        showQuickAdd = false
                    },
                    onCancel: {
                        showQuickAdd = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Authorized Content

    private var authorizedContent: some View {
        VStack(spacing: 0) {
            // Header
            NotionCalendarHeader(
                selectedDate: $viewModel.selectedDate,
                viewMode: $viewModel.viewMode,
                onDateTap: { showDatePicker = true }
            )
            .padding(.top, 8)

            // Date strip (for day view)
            if viewModel.viewMode == .day {
                NotionDateStrip(
                    selectedDate: $viewModel.selectedDate,
                    hasEvents: { date in
                        !viewModel.tasks(for: date).isEmpty || !viewModel.events(for: date).isEmpty
                    }
                )
            }

            // Main content with swipe gestures
            calendarContent
                .gesture(swipeGesture)
        }
    }

    // MARK: - Calendar Content

    @ViewBuilder
    private var calendarContent: some View {
        switch viewModel.viewMode {
        case .day:
            dayView
                .transition(.asymmetric(
                    insertion: .move(edge: dragOffset > 0 ? .leading : .trailing).combined(with: .opacity),
                    removal: .move(edge: dragOffset > 0 ? .trailing : .leading).combined(with: .opacity)
                ))

        case .week:
            weekView
                .transition(.asymmetric(
                    insertion: .move(edge: dragOffset > 0 ? .leading : .trailing).combined(with: .opacity),
                    removal: .move(edge: dragOffset > 0 ? .trailing : .leading).combined(with: .opacity)
                ))

        case .month:
            monthView
                .transition(.opacity)
        }
    }

    // MARK: - Day View

    private var dayView: some View {
        NotionDayView(
            date: viewModel.selectedDate,
            tasks: viewModel.scheduledTasks,
            events: viewModel.events,
            onTaskTap: { task in
                selectedTask = task
            },
            onEventTap: nil,
            onTimeSlotTap: { date in
                quickAddDate = date
                showQuickAdd = true
            },
            onComplete: { task in
                task.isCompleted = true
                task.completedAt = Date()
                try? modelContext.save()
                HapticsService.shared.taskComplete()
                Task {
                    await viewModel.loadData()
                }
            }
        )
    }

    // MARK: - Week View

    private var weekView: some View {
        NotionWeekView(
            selectedDate: $viewModel.selectedDate,
            tasks: viewModel.scheduledTasks,
            events: viewModel.events,
            onDayTap: { date in
                withAnimation(NotionCalendarTokens.Animation.viewModeChange) {
                    viewModel.selectedDate = date
                    viewModel.viewMode = .day
                }
            },
            onTaskTap: { task in
                selectedTask = task
            }
        )
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 0) {
            NotionMonthView(
                selectedDate: $viewModel.selectedDate,
                tasks: viewModel.scheduledTasks,
                events: viewModel.events,
                onDayTap: { date in
                    withAnimation(NotionCalendarTokens.Animation.viewModeChange) {
                        viewModel.selectedDate = date
                        viewModel.viewMode = .day
                    }
                }
            )

            Spacer()

            // Upcoming tasks preview
            if !viewModel.scheduledTasks.isEmpty {
                upcomingTasksPreview
            }
        }
    }

    // MARK: - Upcoming Tasks Preview

    private var upcomingTasksPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, NotionCalendarTokens.Spacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.scheduledTasks.prefix(5)) { task in
                        upcomingTaskCard(task)
                    }
                }
                .padding(.horizontal, NotionCalendarTokens.Spacing.screenPadding)
            }
        }
        .padding(.vertical, 16)
    }

    private func upcomingTaskCard(_ task: TaskItem) -> some View {
        Button {
            selectedTask = task
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 50

                withAnimation(NotionCalendarTokens.Animation.daySwipe) {
                    if value.translation.width > threshold {
                        // Swipe right - go to previous
                        viewModel.goToPrevious()
                        dragOffset = 0
                    } else if value.translation.width < -threshold {
                        // Swipe left - go to next
                        viewModel.goToNext()
                        dragOffset = 0
                    } else {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Permission View

    private var permissionView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.1))
                    .frame(width: 160, height: 160)

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

            // Text
            VStack(spacing: 12) {
                Text("Connect Your Calendar")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text("See your Apple Calendar events alongside\nyour tasks for a complete view of your day")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Connect button
            Button {
                Task {
                    await viewModel.requestAccess()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Connect Calendar")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 16, y: 8)
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview("Calendar View - Day") {
    NotionCalendarView(viewModel: CalendarViewModel())
}

#Preview("Calendar View - Week") {
    let vm = CalendarViewModel()
    vm.viewMode = .week
    return NotionCalendarView(viewModel: vm)
}

#Preview("Calendar View - Month") {
    let vm = CalendarViewModel()
    vm.viewMode = .month
    return NotionCalendarView(viewModel: vm)
}
