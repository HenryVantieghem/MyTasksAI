//
//  ChatTasksView.swift
//  Veloce
//
//  Living Cosmos Tasks View - iOS 26 Ultrathink Edition
//  Features: List/Kanban toggle, TaskCardV5 Floating Glass Island, staggered animations
//

import SwiftUI

// MARK: - View Mode (Legacy - now uses TasksDisplayMode)

/// Display mode for tasks list
enum TaskViewMode: String, CaseIterable {
    case list = "List"
    case columns = "Columns"

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .columns: return "rectangle.split.3x1"
        }
    }

    /// Convert to new TasksDisplayMode
    var displayMode: TasksDisplayMode {
        switch self {
        case .list: return .smartList
        case .columns: return .kanban
        }
    }
}

// MARK: - Kanban Section

/// Kanban workflow sections for task organization
enum KanbanSection: String, CaseIterable {
    case toDo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"

    var icon: String {
        switch self {
        case .toDo: return "circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .done: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .toDo: return Theme.AdaptiveColors.aiSecondary
        case .inProgress: return Theme.AdaptiveColors.warning
        case .done: return Theme.AdaptiveColors.success
        }
    }
}

// MARK: - Kanban Section Header

struct KanbanSectionHeader: View {
    let section: KanbanSection
    let count: Int

    @State private var glowPulse: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Glowing orb indicator
            ZStack {
                // Outer glow
                SwiftUI.Circle()
                    .fill(section.color.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .blur(radius: 4 + (glowPulse * 2))

                // Core dot
                SwiftUI.Circle()
                    .fill(section.color)
                    .frame(width: 8, height: 8)
            }

            // Section title
            Text(section.rawValue.uppercased())
                .font(Theme.Typography.cosmosSectionHeader)
                .foregroundStyle(Theme.CelestialColors.starDim)
                .tracking(1.5)

            // Count badge
            Text("\(count)")
                .font(Theme.Typography.cosmosMetaSmall)
                .foregroundStyle(section.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    Capsule()
                        .fill(section.color.opacity(0.15))
                        .overlay {
                            Capsule()
                                .strokeBorder(section.color.opacity(0.3), lineWidth: 0.5)
                        }
                }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .onAppear {
            guard !reduceMotion, section == .inProgress else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse = 1
            }
        }
    }
}

// MARK: - Chat Tasks View (Living Cosmos Edition)

struct ChatTasksView: View {
    @Bindable var viewModel: ChatTasksViewModel

    // Task selection callback - handled by parent for full-screen overlay
    var onTaskSelected: ((TaskItem) -> Void)?

    // Timer start callback - navigate to Focus tab with task context
    var onStartTimer: ((TaskItem) -> Void)?

    // Focus callback - for ImmersiveFocusOverlay
    var onStartFocus: ((TaskItem, Int) -> Void)?

    // Date selection
    @State private var selectedDate: Date = Date()

    // View mode toggle - persisted with AppStorage
    @AppStorage("tasksDisplayMode") private var displayMode: TasksDisplayMode = .smartList
    @State private var userOverrodeViewMode = false
    @Environment(\.responsiveLayout) private var layout

    // Legacy view mode (for compatibility)
    @State private var viewMode: TaskViewMode = .list

    // Computed effective view mode (auto-kanban on iPad landscape)
    private var effectiveDisplayMode: TasksDisplayMode {
        // If user manually changed view mode, respect their choice
        if userOverrodeViewMode { return displayMode }
        // Auto-switch to kanban on iPad landscape
        if layout.deviceType.isTablet && layout.isLandscape {
            return .kanban
        }
        return displayMode
    }

    // Legacy computed property for backward compatibility
    private var effectiveViewMode: TaskViewMode {
        effectiveDisplayMode == .smartList ? .list : .columns
    }

    // Animation states
    @State private var showConfetti = false
    @State private var showAICreationAnimation = false
    @State private var pointsAnimations: [PointsAnimationState] = []
    @State private var lastCompletedPosition: CGPoint = .zero

    // AI Thinking animation tracking for newly created tasks
    @State private var newlyCreatedTaskIds: Set<UUID> = []

    // Staggered entry tracking
    @State private var visibleTaskIds: Set<UUID> = []
    @State private var hasInitiallyLoaded = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Filtered Tasks by Date

    private var filteredTasks: [TaskItem] {
        let calendar = Calendar.current
        return viewModel.sortedTasks.filter { task in
            if let scheduledTime = task.scheduledTime {
                return calendar.isDate(scheduledTime, inSameDayAs: selectedDate)
            }
            return calendar.isDate(task.createdAt, inSameDayAs: selectedDate)
        }
    }

    private var filteredRecentlyCompleted: [TaskItem] {
        let calendar = Calendar.current
        return viewModel.recentlyCompleted.filter { task in
            if let completedAt = task.completedAt {
                return calendar.isDate(completedAt, inSameDayAs: selectedDate)
            }
            if let scheduledTime = task.scheduledTime {
                return calendar.isDate(scheduledTime, inSameDayAs: selectedDate)
            }
            return calendar.isDate(task.createdAt, inSameDayAs: selectedDate)
        }
    }

    // MARK: - Kanban Section Filters

    /// Tasks currently in progress (high priority or scheduled for now/soon)
    private var inProgressTasks: [TaskItem] {
        let now = Date()

        return filteredTasks.filter { task in
            // High priority (3 stars) tasks are always "in progress"
            if task.starRating == 3 {
                return true
            }

            // Tasks scheduled within the next 2 hours are "in progress"
            if let scheduledTime = task.scheduledTime {
                let hoursUntil = scheduledTime.timeIntervalSince(now) / 3600
                if hoursUntil <= 2 && hoursUntil >= -1 {  // Include slightly overdue
                    return true
                }
            }

            return false
        }
    }

    /// Tasks to be done (not in progress, not completed)
    private var toDoTasks: [TaskItem] {
        let inProgressIds = Set(inProgressTasks.map(\.id))
        return filteredTasks.filter { !inProgressIds.contains($0.id) }
    }

    // Productivity level (0-1) for nebula intensity
    private var productivityLevel: Double {
        let completed = filteredRecentlyCompleted.count
        let total = filteredTasks.count + completed
        guard total > 0 else { return 0 }
        return min(1.0, Double(completed) / Double(max(total, 5)))
    }

    var body: some View {
        ZStack {
            // Cosmic void background (consistent with GrowView)
            VoidBackground.calendar

            // Main content
            VStack(spacing: 0) {
                // Header with date and view toggle
                viewModeHeader
                    .padding(.top, 48)

                // Task feed or empty state
                if filteredTasks.isEmpty && filteredRecentlyCompleted.isEmpty {
                    EmptyTasksView()
                        .padding(.top, Theme.Spacing.universalHeaderHeight - 60)
                } else {
                    if effectiveDisplayMode == .smartList {
                        listTaskFeed
                    } else {
                        kanbanTaskFeed
                    }
                }
            }

            // Celebration overlays
            celebrationOverlays
        }
        .onAppear {
            // Trigger initial staggered load
            if !hasInitiallyLoaded {
                triggerStaggeredEntry()
            }
        }
        .onChange(of: viewModel.sortedTasks.count) { oldCount, newCount in
            // Detect when a new task is added
            if newCount > oldCount {
                // Find the newest task (most recently created)
                if let newestTask = viewModel.sortedTasks
                    .sorted(by: { $0.createdAt > $1.createdAt })
                    .first {
                    // Only trigger AI animation if task was just created (within last 2 seconds)
                    if Date().timeIntervalSince(newestTask.createdAt) < 2 {
                        withAnimation(.spring(response: 0.4)) {
                            newlyCreatedTaskIds.insert(newestTask.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - View Mode Header

    private var viewModeHeader: some View {
        ZStack {
            // Today pill (absolute center)
            TodayPillView(selectedDate: $selectedDate)

            // View mode toggle (right-aligned) - New Liquid Glass Toggle
            HStack {
                Spacer()

                TasksViewModeToggleCompact(mode: $displayMode)
                    .onChange(of: displayMode) { _, _ in
                        userOverrodeViewMode = true  // User manually changed view mode
                    }
            }
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
    }

    // MARK: - List Task Feed

    private var listTaskFeed: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // In Progress section (high priority, urgent tasks)
                    if !inProgressTasks.isEmpty {
                        inProgressSection
                            .staggeredReveal(
                                isVisible: hasInitiallyLoaded,
                                delay: 0,
                                direction: .fromTop
                            )
                    }

                    // To Do section (remaining tasks)
                    if !toDoTasks.isEmpty {
                        toDoSection
                            .staggeredReveal(
                                isVisible: hasInitiallyLoaded,
                                delay: Theme.Animation.staggerDelay * Double(inProgressTasks.count + 1),
                                direction: .fromBottom
                            )
                    }

                    // Done section (completed tasks)
                    if !filteredRecentlyCompleted.isEmpty {
                        doneSection
                            .staggeredReveal(
                                isVisible: hasInitiallyLoaded,
                                delay: Theme.Animation.staggerDelay * Double(filteredTasks.count + 1),
                                direction: .fromBottom
                            )
                    }

                    // Bottom spacer
                    Spacer(minLength: 120)
                        .id("bottom")
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
                .padding(.top, Theme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .onChange(of: filteredTasks.count) { oldCount, newCount in
                if newCount > oldCount {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Kanban Task Feed (New Premium Edition)

    private var kanbanTaskFeed: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: layout.spacing * 1.5) {
                // In Progress Column
                KanbanColumnView(
                    section: .inProgress,
                    tasks: inProgressTasks,
                    onTaskTap: { task in
                        HapticsService.shared.selectionFeedback()
                        onTaskSelected?(task)
                    },
                    onToggleComplete: { task in
                        completeTask(task)
                    },
                    onTaskDrop: handleTaskDrop,
                    onStartFocus: onStartFocus,
                    onSnooze: { task in
                        viewModel.snoozeTask(task)
                    },
                    onDelete: { task in
                        viewModel.deleteTask(task)
                    }
                )

                // To Do Column
                KanbanColumnView(
                    section: .toDo,
                    tasks: toDoTasks,
                    onTaskTap: { task in
                        HapticsService.shared.selectionFeedback()
                        onTaskSelected?(task)
                    },
                    onToggleComplete: { task in
                        completeTask(task)
                    },
                    onTaskDrop: handleTaskDrop,
                    onStartFocus: onStartFocus,
                    onSnooze: { task in
                        viewModel.snoozeTask(task)
                    },
                    onDelete: { task in
                        viewModel.deleteTask(task)
                    }
                )

                // Done Column
                KanbanColumnView(
                    section: .done,
                    tasks: filteredRecentlyCompleted,
                    onTaskTap: { task in
                        HapticsService.shared.selectionFeedback()
                        onTaskSelected?(task)
                    },
                    onToggleComplete: { task in
                        viewModel.uncompleteTask(task)
                    },
                    onTaskDrop: handleTaskDrop,
                    onStartFocus: nil,
                    onSnooze: nil,
                    onDelete: nil
                )
            }
            .padding(.horizontal, layout.cardPadding)
            .padding(.top, layout.spacing)
            .padding(.bottom, 120)
        }
        .scrollTargetBehavior(.viewAligned)
    }

    // MARK: - Handle Task Drop (Drag & Drop)

    private func handleTaskDrop(task: TaskItem, targetSection: TaskSection) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            switch targetSection {
            case .inProgress:
                task.isCompleted = false
                task.isInProgress = true
            case .toDo:
                task.isCompleted = false
                task.isInProgress = false
            case .done:
                // Use the completeTask function to trigger celebration
                completeTask(task)
            }
        }
    }

    // MARK: - Column Task Feed (Legacy)

    private var columnTaskFeed: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                // To Do Column
                KanbanColumn(
                    section: .toDo,
                    tasks: toDoTasks,
                    onTaskTap: { task in
                        HapticsService.shared.selectionFeedback()
                        onTaskSelected?(task)
                    },
                    onTaskComplete: { task in
                        completeTask(task)
                    },
                    onStartFocus: onStartFocus,
                    onSnooze: { task in
                        viewModel.snoozeTask(task)
                    },
                    onDelete: { task in
                        viewModel.deleteTask(task)
                    }
                )

                // In Progress Column
                KanbanColumn(
                    section: .inProgress,
                    tasks: inProgressTasks,
                    onTaskTap: { task in
                        HapticsService.shared.selectionFeedback()
                        onTaskSelected?(task)
                    },
                    onTaskComplete: { task in
                        completeTask(task)
                    },
                    onStartFocus: onStartFocus,
                    onSnooze: { task in
                        viewModel.snoozeTask(task)
                    },
                    onDelete: { task in
                        viewModel.deleteTask(task)
                    }
                )

                // Done Column
                KanbanColumn(
                    section: .done,
                    tasks: filteredRecentlyCompleted,
                    onTaskTap: { task in
                        HapticsService.shared.selectionFeedback()
                        onTaskSelected?(task)
                    },
                    onTaskComplete: { task in
                        viewModel.uncompleteTask(task)
                    },
                    onStartFocus: nil,
                    onSnooze: nil,
                    onDelete: nil
                )
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
    }
    // MARK: - In Progress Section

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            KanbanSectionHeader(section: .inProgress, count: inProgressTasks.count)

            ForEach(Array(inProgressTasks.enumerated()), id: \.element.id) { index, task in
                TaskCardV4(
                    task: task,
                    onTap: {
                        HapticsService.shared.selectionFeedback()
                        onTaskSelected?(task)
                    },
                    onToggleComplete: {
                        completeTask(task)
                    },
                    onStartFocus: onStartFocus,
                    onSnooze: { task in
                        viewModel.snoozeTask(task)
                    },
                    onDelete: { task in
                        viewModel.deleteTask(task)
                    },
                    showAIThinking: newlyCreatedTaskIds.contains(task.id),
                    onAIThinkingComplete: {
                        // Remove from newly created set after animation completes
                        newlyCreatedTaskIds.remove(task.id)
                    }
                )
                .id(task.id)
                .zIndex(Double(inProgressTasks.count - index))
            }
        }
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - To Do Section

    private var toDoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            KanbanSectionHeader(section: .toDo, count: toDoTasks.count)

            ForEach(Array(toDoTasks.enumerated()), id: \.element.id) { index, task in
                TaskCardV4(
                    task: task,
                    onTap: {
                        HapticsService.shared.selectionFeedback()
                        onTaskSelected?(task)
                    },
                    onToggleComplete: {
                        completeTask(task)
                    },
                    onStartFocus: onStartFocus,
                    onSnooze: { task in
                        viewModel.snoozeTask(task)
                    },
                    onDelete: { task in
                        viewModel.deleteTask(task)
                    },
                    showAIThinking: newlyCreatedTaskIds.contains(task.id),
                    onAIThinkingComplete: {
                        // Remove from newly created set after animation completes
                        newlyCreatedTaskIds.remove(task.id)
                    }
                )
                .id(task.id)
                .zIndex(Double(toDoTasks.count - index))
            }
        }
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Done Section

    private var doneSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            KanbanSectionHeader(section: .done, count: filteredRecentlyCompleted.count)

            // Completed task rows (constellation style)
            ForEach(filteredRecentlyCompleted) { task in
                ConstellationTaskRow(task: task) {
                    viewModel.uncompleteTask(task)
                }
            }
        }
        .padding(.bottom, Theme.Spacing.md)
        // Achievement aurora glow
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.auroraGreen.opacity(0.03))
                .blur(radius: 20)
                .offset(y: 10)
        }
    }

    // MARK: - Constellation Completed Section (Legacy)

    private var constellationCompletedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header with aurora glow
            HStack(spacing: Theme.Spacing.sm) {
                // Constellation icon
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)

                Text("Completed")
                    .font(Theme.Typography.cosmosSectionHeader)
                    .foregroundStyle(Theme.CelestialColors.starDim)

                // Count badge
                Text("\(filteredRecentlyCompleted.count)")
                    .font(Theme.Typography.cosmosMetaSmall)
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Theme.CelestialColors.auroraGreen.opacity(0.15))
                    }
            }
            .padding(.horizontal, Theme.Spacing.sm)

            // Completed task rows (fade to constellation)
            ForEach(filteredRecentlyCompleted) { task in
                ConstellationTaskRow(task: task) {
                    viewModel.uncompleteTask(task)
                }
            }
        }
        .padding(.bottom, Theme.Spacing.md)
        // Achievement aurora glow
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.auroraGreen.opacity(0.03))
                .blur(radius: 20)
                .offset(y: 10)
        }
    }

    // MARK: - Celebration Overlays

    @ViewBuilder
    private var celebrationOverlays: some View {
        // Confetti burst
        if showConfetti {
            ConfettiBurst(particleCount: 80)
                .ignoresSafeArea()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showConfetti = false
                    }
                }
        }

        // Points animations
        PointsAnimationContainer(animations: $pointsAnimations)

        // AI Creation Animation
        if showAICreationAnimation {
            AITaskCreationAnimation {
                showAICreationAnimation = false
            }
            .zIndex(2)
        }
    }

    // MARK: - Actions

    private func triggerStaggeredEntry() {
        guard !reduceMotion else {
            hasInitiallyLoaded = true
            return
        }

        // Slight delay then trigger staggered reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(Theme.Animation.portalOpen) {
                hasInitiallyLoaded = true
            }
        }
    }

    private func completeTask(_ task: TaskItem) {
        // Get position for points animation
        let screenCenter = CGPoint(x: 200, y: 400)

        // Complete and get points
        let points = viewModel.completeTask(task)

        // Show points animation
        let animation = PointsAnimationState(
            points: points,
            position: screenCenter,
            isBonus: points > DesignTokens.Gamification.taskComplete
        )
        pointsAnimations.append(animation)

        // Check for celebration triggers
        let gamification = GamificationService.shared
        if gamification.tasksCompletedToday == gamification.dailyGoal {
            showConfetti = true
        }
    }
}

// MARK: - Dynamic Nebula Background

struct DynamicNebulaBackground: View {
    let productivityLevel: Double
    let hasOverdueTasks: Bool

    @State private var nebulaPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Color shifts based on productivity
    private var primaryColor: Color {
        if hasOverdueTasks {
            return Theme.CelestialColors.urgencyNear.opacity(0.15)
        }
        // Warm up as productivity increases
        let warmth = productivityLevel
        return Color(
            red: 0.58 + (warmth * 0.2),
            green: 0.25 + (warmth * 0.3),
            blue: 0.98 - (warmth * 0.3)
        ).opacity(0.12)
    }

    private var secondaryColor: Color {
        if hasOverdueTasks {
            return Theme.CelestialColors.urgencyCritical.opacity(0.08)
        }
        return Theme.CelestialColors.auroraGreen.opacity(0.08 * productivityLevel)
    }

    var body: some View {
        ZStack {
            // Base void
            Theme.CelestialColors.void
                .ignoresSafeArea()

            // Primary nebula
            RadialGradient(
                colors: [
                    primaryColor,
                    primaryColor.opacity(0.5),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Secondary nebula (shifts with productivity)
            RadialGradient(
                colors: [
                    secondaryColor,
                    Color.clear
                ],
                center: UnitPoint(
                    x: 0.8 + (nebulaPhase * 0.1),
                    y: 0.3
                ),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Ambient star dust
            if !reduceMotion {
                StarFieldView(shift: nebulaPhase * 5, density: .sparse)
                    .opacity(0.4)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 8)
                    .repeatForever(autoreverses: true)
                ) {
                    nebulaPhase = 1
                }
            }
        }
    }
}

// MARK: - Constellation Task Row

struct ConstellationTaskRow: View {
    let task: TaskItem
    let onUncomplete: () -> Void

    @State private var starTwinkle: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Star constellation point (where checkmark was)
            ZStack {
                // Glow
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.auroraGreen.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .blur(radius: 4 + (starTwinkle * 2))

                // Star
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
            }

            // Title (faded, ethereal)
            Text(task.title)
                .font(Theme.Typography.cosmosWhisperSmall)
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .strikethrough(true, color: Theme.CelestialColors.starGhost.opacity(0.5))
                .lineLimit(1)

            Spacer()

            // Undo (re-materialize)
            Button {
                HapticsService.shared.selectionFeedback()
                onUncomplete()
            } label: {
                Text("Restore")
                    .font(Theme.Typography.cosmosMetaSmall)
                    .foregroundStyle(Theme.CelestialColors.nebulaEdge)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.CelestialColors.abyss.opacity(0.5))
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    starTwinkle = 1
                }
            }
        }
    }
}

// MARK: - Kanban Column

struct KanbanColumn: View {
    let section: KanbanSection
    let tasks: [TaskItem]
    let onTaskTap: (TaskItem) -> Void
    let onTaskComplete: (TaskItem) -> Void
    var onStartFocus: ((TaskItem, Int) -> Void)?
    var onSnooze: ((TaskItem) -> Void)?
    var onDelete: ((TaskItem) -> Void)?

    @Environment(\.responsiveLayout) private var layout

    private var columnWidth: CGFloat {
        switch layout.deviceType {
        case .iPhoneSE: return 240
        case .iPhoneStandard: return 260
        case .iPhoneProMax: return 280
        case .iPadMini: return 300
        case .iPad, .iPadPro11: return 320
        case .iPadPro13: return 360
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column header with Liquid Glass
            columnHeader

            // Tasks in column
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(tasks) { task in
                        TaskCardV4(
                            task: task,
                            onTap: { onTaskTap(task) },
                            onToggleComplete: { onTaskComplete(task) },
                            onStartFocus: onStartFocus,
                            onSnooze: onSnooze,
                            onDelete: onDelete
                        )
                    }

                    if tasks.isEmpty {
                        emptyColumnPlaceholder
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(width: columnWidth)
    }

    private var columnHeader: some View {
        HStack(spacing: 10) {
            // Status indicator
            Circle()
                .fill(section.color)
                .frame(width: 10, height: 10)

            Text(section.rawValue)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            // Count badge
            Text("\(tasks.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(section.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(section.color.opacity(0.12))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(section.color.opacity(0.2), lineWidth: 0.5)
        }
    }

    private var emptyColumnPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: section.icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)

            Text("No tasks")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .foregroundStyle(Color(.tertiarySystemFill))
        )
    }
}

// MARK: - Chat Schedule Picker Sheet

struct ChatSchedulePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Date) -> Void

    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                DatePicker(
                    "Schedule",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(Theme.Colors.accent)

                Button {
                    onSelect(selectedDate)
                    dismiss()
                } label: {
                    Text("Set Schedule")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
            }
            .padding(Theme.Spacing.screenPadding)
            .navigationTitle("Schedule Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Priority Picker Sheet

struct PriorityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(1...3, id: \.self) { priority in
                    Button {
                        HapticsService.shared.selectionFeedback()
                        onSelect(priority)
                        dismiss()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            // Stars
                            HStack(spacing: 4) {
                                ForEach(0..<priority, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Theme.Colors.xp)
                                }
                                ForEach(0..<(3 - priority), id: \.self) { _ in
                                    Image(systemName: "star")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                            }

                            Spacer()

                            // Label
                            Text(priorityLabel(priority))
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.md)
                                .fill(Theme.Colors.glassBackground.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.screenPadding)
            .navigationTitle("Set Priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func priorityLabel(_ priority: Int) -> String {
        switch priority {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "Medium"
        }
    }
}

// MARK: - Chat Task Detail Sheet

struct ChatTaskDetailSheet: View {
    let task: TaskItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Title
                    Text(task.title)
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    // Metadata
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        if task.starRating > 0 {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Theme.Colors.xp)
                                Text("Priority: \(task.starRating)/3")
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }

                        if let scheduled = task.scheduledTime {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(Theme.Colors.aiBlue)
                                Text("Scheduled: \(scheduled.formatted(date: .abbreviated, time: .shortened))")
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }

                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundStyle(Theme.Colors.textTertiary)
                            Text("Created: \(task.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(Theme.Spacing.screenPadding)
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatTasksView(viewModel: ChatTasksViewModel())
    }
}
