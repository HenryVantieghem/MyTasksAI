//
//  CosmosCalendarView.swift
//  Veloce
//
//  Living Cosmos Calendar - Main Container
//  A cosmic calendar experience with plasma effects, portal transitions,
//  and deep space aesthetics
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - Cosmos View Mode

enum CosmosViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var icon: String {
        switch self {
        case .day: return "sun.horizon.fill"
        case .week: return "calendar.day.timeline.left"
        case .month: return "calendar"
        }
    }

    /// Cosmic scale factor for zoom transitions
    var cosmicScale: CGFloat {
        switch self {
        case .day: return 1.0      // Close-up planetary view
        case .week: return 0.85    // Solar system view
        case .month: return 0.7    // Galaxy overview
        }
    }
}

// MARK: - Cosmos Calendar View

/// Main container for the Living Cosmos calendar experience
struct CosmosCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]
    @Bindable var viewModel: CalendarViewModel

    // MARK: - State

    @State private var viewMode: CosmosViewMode = .day
    @State private var selectedDate: Date = Date()
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false
    @State private var showDatePicker = false
    @State private var showRescheduleConfirmation = false
    @State private var rescheduleTask: TaskItem?
    @State private var rescheduleNewTime: Date?
    @State private var showQuickAdd = false
    @State private var quickAddTime: Date?
    @State private var showDayPreview = false
    @State private var dayPreviewDate: Date = Date()

    // Transition animation state
    @State private var isTransitioning = false
    @State private var transitionScale: CGFloat = 1.0
    @State private var transitionBlur: CGFloat = 0
    @Namespace private var calendarTransition

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            // Cosmic void background
            VoidBackground.calendar

            if !viewModel.isAuthorized {
                calendarPermissionView
            } else {
                calendarContent
            }
        }
        // Task Detail Sheet
        .sheet(isPresented: $showTaskDetail) {
            if let task = selectedTask {
                TaskDetailSheet(task: task, viewModel: TasksViewModel())
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
            }
        }
        // Date Picker Sheet
        .sheet(isPresented: $showDatePicker) {
            CalendarDatePickerSheet(selectedDate: $selectedDate)
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
        // Reschedule Confirmation
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
        // Quick Add Sheet
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
        // Day Preview Sheet (for month view tap)
        .sheet(isPresented: $showDayPreview) {
            DayPreviewSheet(
                date: dayPreviewDate,
                tasks: tasksForDate(dayPreviewDate),
                events: viewModel.events(for: dayPreviewDate),
                onTaskTap: { task in
                    showDayPreview = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedTask = task
                        showTaskDetail = true
                    }
                },
                onViewFullDay: {
                    showDayPreview = false
                    withAnimation(cosmicTransition) {
                        selectedDate = dayPreviewDate
                        viewMode = .day
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Permission View

    private var calendarPermissionView: some View {
        VStack(spacing: 24) {
            // Cosmic calendar icon
            ZStack {
                // Outer glow
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.nebulaCore,
                                Theme.CelestialColors.plasmaCore
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Calendar Access Required")
                    .font(Theme.Typography.cosmosTitleLarge)
                    .foregroundStyle(.white)

                Text("Enable calendar access to sync your tasks with your schedule and unlock the visual timeline.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.CelestialColors.starDim)
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
                .background(LivingCosmos.Button.primaryGradient)
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
            Spacer().frame(height: Theme.Spacing.universalHeaderHeight)

            // Cosmic header with date navigation
            cosmosHeader

            // Date carousel
            CosmosDateCarousel(
                selectedDate: $selectedDate,
                viewMode: viewMode,
                hasEvents: hasEvents(on:),
                onSwipe: handleDateSwipe
            )

            // Main content with cosmic transitions
            ZStack {
                switch viewMode {
                case .day:
                    CosmosDayView(
                        date: selectedDate,
                        tasks: tasksForSelectedDate,
                        events: eventsForSelectedDate,
                        onTaskTap: { task in
                            selectedTask = task
                            showTaskDetail = true
                        },
                        onReschedule: { task, newTime in
                            rescheduleTask = task
                            rescheduleNewTime = newTime
                            showRescheduleConfirmation = true
                        },
                        onTimeSlotLongPress: { time in
                            quickAddTime = time
                            showQuickAdd = true
                        }
                    )
                    .transition(cosmicViewTransition(for: .day))

                case .week:
                    CosmosWeekView(
                        centerDate: selectedDate,
                        tasks: allTasks,
                        events: viewModel.events,
                        onTaskTap: { task in
                            selectedTask = task
                            showTaskDetail = true
                        },
                        onDayTap: { date in
                            transitionToDay(from: date)
                        },
                        onReschedule: { task, newTime in
                            rescheduleTask = task
                            rescheduleNewTime = newTime
                            showRescheduleConfirmation = true
                        }
                    )
                    .transition(cosmicViewTransition(for: .week))

                case .month:
                    CosmosMonthView(
                        selectedDate: $selectedDate,
                        tasks: allTasks,
                        onDateTap: { date in
                            dayPreviewDate = date
                            showDayPreview = true
                        }
                    )
                    .transition(cosmicViewTransition(for: .month))
                }
            }
            .scaleEffect(transitionScale)
            .blur(radius: transitionBlur)
            .animation(cosmicTransition, value: viewMode)

            Spacer()

            // Scheduled tasks horizontal list (day view only)
            if viewMode == .day {
                if !tasksForSelectedDate.isEmpty {
                    scheduledTasksList
                } else {
                    cosmosEmptyState
                }
            }
        }
        .gesture(daySwipeGesture)
    }

    // MARK: - Cosmos Header

    private var cosmosHeader: some View {
        HStack {
            // Month/Year with plasma glow
            Button {
                HapticsService.shared.selectionFeedback()
                showDatePicker = true
            } label: {
                HStack(spacing: 8) {
                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                        .font(Theme.Typography.cosmosTitleLarge)
                        .foregroundStyle(.white)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.plasmaCore)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Cosmic view mode toggle
            CosmosViewModeToggle(viewMode: $viewMode, onModeChange: handleViewModeChange)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Scheduled Tasks List

    private var scheduledTasksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SCHEDULED")
                    .font(LivingCosmos.SectionHeader.font)
                    .foregroundStyle(LivingCosmos.SectionHeader.color)
                    .tracking(LivingCosmos.SectionHeader.letterSpacing)

                Spacer()

                Text("\(tasksForSelectedDate.count) task\(tasksForSelectedDate.count == 1 ? "" : "s")")
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(tasksForSelectedDate.enumerated()), id: \.element.id) { index, task in
                        CosmosScheduledTaskCard(task: task) {
                            selectedTask = task
                            showTaskDetail = true
                        }
                        .staggeredReveal(index: index, isVisible: true)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Empty State

    private var cosmosEmptyState: some View {
        VStack(spacing: 16) {
            // Cosmic empty icon
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.nebulaCore.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            VStack(spacing: 4) {
                Text("No tasks scheduled")
                    .font(Theme.Typography.cosmosTitle)
                    .foregroundStyle(.white)

                Text("Long-press the timeline to add a task")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            Button {
                quickAddTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate)
                showQuickAdd = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Task")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.plasmaCore)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Transitions

    private var cosmicTransition: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.2)
            : .spring(response: 0.5, dampingFraction: 0.8)
    }

    private func cosmicViewTransition(for mode: CosmosViewMode) -> AnyTransition {
        guard !reduceMotion else {
            return .opacity
        }

        switch mode {
        case .day:
            return .asymmetric(
                insertion: .modifier(
                    active: CosmicZoomModifier(scale: 1.3, opacity: 0, blur: 8),
                    identity: CosmicZoomModifier(scale: 1.0, opacity: 1, blur: 0)
                ),
                removal: .modifier(
                    active: CosmicZoomModifier(scale: 0.85, opacity: 0, blur: 4),
                    identity: CosmicZoomModifier(scale: 1.0, opacity: 1, blur: 0)
                )
            )
        case .week:
            return .scale.combined(with: .opacity)
        case .month:
            return .asymmetric(
                insertion: .modifier(
                    active: CosmicZoomModifier(scale: 0.7, opacity: 0, blur: 6),
                    identity: CosmicZoomModifier(scale: 1.0, opacity: 1, blur: 0)
                ),
                removal: .modifier(
                    active: CosmicZoomModifier(scale: 1.2, opacity: 0, blur: 4),
                    identity: CosmicZoomModifier(scale: 1.0, opacity: 1, blur: 0)
                )
            )
        }
    }

    // MARK: - Gestures

    private var daySwipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                guard viewMode == .day else { return }

                let threshold: CGFloat = 50
                if value.translation.width > threshold {
                    // Swipe right -> previous day
                    HapticsService.shared.selectionFeedback()
                    withAnimation(cosmicTransition) {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    }
                } else if value.translation.width < -threshold {
                    // Swipe left -> next day
                    HapticsService.shared.selectionFeedback()
                    withAnimation(cosmicTransition) {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    }
                }
            }
    }

    // MARK: - Actions

    private func handleViewModeChange(_ newMode: CosmosViewMode) {
        guard newMode != viewMode else { return }

        HapticsService.shared.selectionFeedback()
        withAnimation(cosmicTransition) {
            viewMode = newMode
        }
    }

    private func handleDateSwipe(_ direction: SwipeDirection) {
        HapticsService.shared.selectionFeedback()
        withAnimation(cosmicTransition) {
            switch viewMode {
            case .day:
                selectedDate = Calendar.current.date(
                    byAdding: .day,
                    value: direction == .left ? 1 : -1,
                    to: selectedDate
                ) ?? selectedDate
            case .week:
                selectedDate = Calendar.current.date(
                    byAdding: .weekOfYear,
                    value: direction == .left ? 1 : -1,
                    to: selectedDate
                ) ?? selectedDate
            case .month:
                selectedDate = Calendar.current.date(
                    byAdding: .month,
                    value: direction == .left ? 1 : -1,
                    to: selectedDate
                ) ?? selectedDate
            }
        }
    }

    private func transitionToDay(from date: Date) {
        HapticsService.shared.impact()
        withAnimation(cosmicTransition) {
            selectedDate = date
            viewMode = .day
        }
    }

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

    private func tasksForDate(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        return allTasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }.sorted { ($0.scheduledTime ?? Date.distantFuture) < ($1.scheduledTime ?? Date.distantFuture) }
    }
}

// MARK: - Swipe Direction

enum SwipeDirection {
    case left, right
}

// MARK: - Cosmic Zoom Modifier

struct CosmicZoomModifier: ViewModifier {
    let scale: CGFloat
    let opacity: Double
    let blur: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1.0 : scale)
            .opacity(reduceMotion ? 1.0 : opacity)
            .blur(radius: reduceMotion ? 0 : blur)
    }
}

// MARK: - View Mode Toggle

struct CosmosViewModeToggle: View {
    @Binding var viewMode: CosmosViewMode
    let onModeChange: (CosmosViewMode) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(CosmosViewMode.allCases, id: \.self) { mode in
                Button {
                    onModeChange(mode)
                } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(viewMode == mode ? .white : Theme.CelestialColors.starDim)
                        .frame(width: 36, height: 32)
                        .background {
                            if viewMode == mode {
                                Capsule()
                                    .fill(Theme.CelestialColors.nebulaCore.opacity(0.4))
                                    .overlay {
                                        Capsule()
                                            .stroke(Theme.CelestialColors.nebulaEdge.opacity(0.3), lineWidth: 1)
                                    }
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

// MARK: - Scheduled Task Card

struct CosmosScheduledTaskCard: View {
    let task: TaskItem
    let onTap: () -> Void

    @State private var isPressed = false

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Mini plasma core
                ZStack {
                    SwiftUI.Circle()
                        .fill(taskColor.opacity(0.2))
                        .frame(width: 32, height: 32)

                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [taskColor, taskColor.opacity(0.6)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 20, height: 20)

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .strikethrough(task.isCompleted, color: .white.opacity(0.5))

                    if let time = task.scheduledTime {
                        Text(time.formatted(.dateTime.hour().minute()))
                            .font(Theme.Typography.cosmosMeta)
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }

                Spacer()

                // Points badge
                if !task.isCompleted {
                    Text("+\(task.potentialPoints)")
                        .font(Theme.Typography.cosmosPoints)
                        .foregroundStyle(taskColor)
                }
            }
            .padding(12)
            .frame(width: 200)
            .background {
                RoundedRectangle(cornerRadius: LivingCosmos.Calendar.blockCornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: LivingCosmos.Calendar.blockCornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [taskColor.opacity(0.1), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: LivingCosmos.Calendar.blockCornerRadius)
                            .stroke(taskColor.opacity(0.3), lineWidth: 1)
                    }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(LivingCosmos.Animations.quick) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(LivingCosmos.Animations.quick) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview {
    CosmosCalendarView(viewModel: CalendarViewModel())
}
