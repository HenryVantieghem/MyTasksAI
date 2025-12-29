//
//  ChatTasksView.swift
//  Veloce
//
//  Aurora Design System - Productivity Constellation
//  Living aurora backgrounds that respond to task completion,
//  tasks as energy nodes, completion transforms into stars.
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
        case .toDo: return Aurora.Colors.electricCyan
        case .inProgress: return Aurora.Colors.cosmicGold
        case .done: return Aurora.Colors.prismaticGreen
        }
    }
}

// MARK: - Kanban Section Header

struct KanbanSectionHeader: View {
    let section: KanbanSection
    let count: Int

    @State private var glowPulse: CGFloat = 0
    @State private var haloRotation: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Aurora.Spacing.sm) {
            // Aurora energy orb indicator
            ZStack {
                // Outer aurora glow
                SwiftUI.Circle()
                    .fill(section.color.opacity(0.4))
                    .frame(width: 20, height: 20)
                    .blur(radius: 6 + (glowPulse * 3))

                // Rotating halo (for in-progress)
                if section == .inProgress && !reduceMotion {
                    SwiftUI.Circle()
                        .stroke(
                            AngularGradient(
                                colors: [section.color, section.color.opacity(0.3), section.color],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(haloRotation))
                }

                // Core energy dot
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [Aurora.Colors.stellarWhite, section.color],
                            center: .center,
                            startRadius: 0,
                            endRadius: 5
                        )
                    )
                    .frame(width: 8, height: 8)
            }

            // Section title with Aurora typography
            Text(section.rawValue.uppercased())
                .font(Aurora.Typography.caption)
                .foregroundStyle(Aurora.Colors.textSecondary)
                .tracking(1.5)

            // Aurora count badge
            Text("\(count)")
                .font(Aurora.Typography.statSmall)
                .foregroundStyle(section.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(section.color.opacity(0.12))
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [section.color.opacity(0.5), section.color.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                }

            Spacer()
        }
        .padding(.horizontal, Aurora.Spacing.sm)
        .padding(.vertical, Aurora.Spacing.xs)
        .onAppear {
            guard !reduceMotion else { return }
            // Glow pulse for all sections
            withAnimation(
                .easeInOut(duration: AuroraMotion.Duration.glowPulse)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = 1
            }
            // Rotating halo for in-progress
            if section == .inProgress {
                withAnimation(
                    .linear(duration: 4)
                    .repeatForever(autoreverses: false)
                ) {
                    haloRotation = 360
                }
            }
        }
    }
}

// MARK: - Chat Tasks View (Aurora Productivity Constellation)

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
            // Aurora productivity-responsive background
            AuroraAnimatedWaveBackground.forProductivityState(
                productivityLevel: productivityLevel,
                hasOverdueTasks: inProgressTasks.contains { task in
                    if let scheduled = task.scheduledTime {
                        return scheduled < Date()
                    }
                    return false
                }
            )
            .ignoresSafeArea()

            // Ambient firefly particles
            if !reduceMotion {
                AuroraFireflyField(
                    particleCount: 25,
                    colors: [
                        Aurora.Colors.electricCyan.opacity(0.6),
                        Aurora.Colors.borealisViolet.opacity(0.4),
                        Aurora.Colors.prismaticGreen.opacity(0.3)
                    ]
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Main content
            VStack(spacing: 0) {
                // Header with date and view toggle
                viewModeHeader
                    .padding(.top, 48)

                // Task feed or empty state
                if filteredTasks.isEmpty && filteredRecentlyCompleted.isEmpty {
                    EmptyTasksView()
                        .padding(.top, 60)
                } else {
                    if effectiveDisplayMode == .smartList {
                        listTaskFeed
                    } else {
                        kanbanTaskFeed
                    }
                }
            }

            // Aurora celebration overlays
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
                        _ = withAnimation(.spring(response: 0.4)) {
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
        .padding(.horizontal, CosmicWidget.Spacing.screenPadding)
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
                                delay: CosmicMotion.Stagger.standard * Double(inProgressTasks.count + 1),
                                direction: .fromBottom
                            )
                    }

                    // Done section (completed tasks)
                    if !filteredRecentlyCompleted.isEmpty {
                        doneSection
                            .staggeredReveal(
                                isVisible: hasInitiallyLoaded,
                                delay: CosmicMotion.Stagger.standard * Double(filteredTasks.count + 1),
                                direction: .fromBottom
                            )
                    }

                    // Bottom spacer
                    Spacer(minLength: 120)
                        .id("bottom")
                }
                .padding(.horizontal, CosmicWidget.Spacing.screenPadding)
                .padding(.top, CosmicWidget.Spacing.md)
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
            .padding(.horizontal, CosmicWidget.Spacing.screenPadding)
            .padding(.top, CosmicWidget.Spacing.md)
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
        .padding(.bottom, CosmicWidget.Spacing.sm)
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
        .padding(.bottom, CosmicWidget.Spacing.sm)
    }

    // MARK: - Aurora Done Section

    private var doneSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.sm) {
            KanbanSectionHeader(section: .done, count: filteredRecentlyCompleted.count)

            // Completed task rows (aurora constellation style)
            ForEach(filteredRecentlyCompleted) { task in
                ConstellationTaskRow(task: task) {
                    AuroraSoundEngine.shared.play(.buttonTap)
                    viewModel.uncompleteTask(task)
                }
            }
        }
        .padding(.bottom, Aurora.Spacing.md)
        // Achievement aurora glow
        .background {
            ZStack {
                // Primary achievement glow
                RoundedRectangle(cornerRadius: 16)
                    .fill(Aurora.Colors.prismaticGreen.opacity(0.04))
                    .blur(radius: 20)
                    .offset(y: 10)

                // Secondary golden achievement shimmer
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Aurora.Colors.cosmicGold.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 15)
            }
        }
    }

    // MARK: - Constellation Completed Section (Legacy)

    private var constellationCompletedSection: some View {
        VStack(alignment: .leading, spacing: CosmicWidget.Spacing.sm) {
            // Section header with aurora glow
            HStack(spacing: CosmicWidget.Spacing.sm) {
                // Constellation icon
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CosmicWidget.Widget.mint)

                Text("Completed")
                    .font(CosmicWidget.Typography.caption)
                    .foregroundStyle(CosmicWidget.Text.secondary)

                // Count badge
                Text("\(filteredRecentlyCompleted.count)")
                    .font(CosmicWidget.Typography.meta)
                    .foregroundStyle(CosmicWidget.Widget.mint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(CosmicWidget.Widget.mint.opacity(0.15))
                    }
            }
            .padding(.horizontal, CosmicWidget.Spacing.sm)

            // Completed task rows (fade to constellation)
            ForEach(filteredRecentlyCompleted) { task in
                ConstellationTaskRow(task: task) {
                    viewModel.uncompleteTask(task)
                }
            }
        }
        .padding(.bottom, CosmicWidget.Spacing.md)
        // Achievement aurora glow
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicWidget.Widget.mint.opacity(0.03))
                .blur(radius: 20)
                .offset(y: 10)
        }
    }

    // MARK: - Aurora Celebration Overlays

    @ViewBuilder
    private var celebrationOverlays: some View {
        // Aurora supernova burst for major celebrations
        if showConfetti {
            ZStack {
                // Aurora confetti
                AuroraConfettiShower(
                    isActive: .constant(true),
                    particleCount: 80,
                    colors: Aurora.Gradients.auroraSpectrum
                )
                .ignoresSafeArea()

                // Central supernova burst
                AuroraSupernovaBurst(
                    isActive: .constant(true),
                    particleCount: 32,
                    color: Aurora.Colors.cosmicGold
                )
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3)
            }
            .onAppear {
                AuroraSoundEngine.shared.celebration()
                AuroraHaptics.celebration()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showConfetti = false
                }
            }
        }

        // Points animations
        PointsAnimationContainer(animations: $pointsAnimations)

        // AI Creation Animation with Aurora effects
        if showAICreationAnimation {
            ZStack {
                AITaskCreationAnimation {
                    showAICreationAnimation = false
                }
                // Aurora mini burst
                AuroraMiniBurst(color: Aurora.Colors.electricCyan, particleCount: 12)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
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

        // Aurora-style staggered reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(AuroraMotion.Spring.fluidMorph) {
                hasInitiallyLoaded = true
            }
        }
    }

    private func completeTask(_ task: TaskItem) {
        // Aurora completion feedback
        AuroraSoundEngine.shared.taskComplete()
        AuroraHaptics.dopamineBurst()

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

// MARK: - Aurora Dynamic Nebula Background

struct DynamicNebulaBackground: View {
    let productivityLevel: Double
    let hasOverdueTasks: Bool

    @State private var nebulaPhase: CGFloat = 0
    @State private var auroraWave: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Aurora color shifts based on productivity
    private var primaryColor: Color {
        if hasOverdueTasks {
            return Aurora.Colors.warning.opacity(0.15)
        }
        // Shift from violet to cyan to green as productivity increases
        let warmth = productivityLevel
        if warmth < 0.3 {
            return Aurora.Colors.borealisViolet.opacity(0.12)
        } else if warmth < 0.7 {
            return Aurora.Colors.electricCyan.opacity(0.15)
        } else {
            return Aurora.Colors.prismaticGreen.opacity(0.18)
        }
    }

    private var secondaryColor: Color {
        if hasOverdueTasks {
            return Aurora.Colors.error.opacity(0.08)
        }
        return Aurora.Colors.prismaticGreen.opacity(0.08 * productivityLevel)
    }

    private var tertiaryColor: Color {
        return Aurora.Colors.stellarMagenta.opacity(0.06 * (1 - productivityLevel))
    }

    var body: some View {
        ZStack {
            // Base aurora void
            Aurora.Colors.voidDeep
                .ignoresSafeArea()

            // Primary aurora nebula
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

            // Secondary aurora (shifts with productivity)
            RadialGradient(
                colors: [
                    secondaryColor,
                    Color.clear
                ],
                center: UnitPoint(
                    x: 0.8 + (nebulaPhase * 0.1),
                    y: 0.3 + (auroraWave * 0.1)
                ),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Tertiary aurora glow (bottom)
            RadialGradient(
                colors: [
                    tertiaryColor,
                    Color.clear
                ],
                center: UnitPoint(
                    x: 0.2 - (nebulaPhase * 0.05),
                    y: 0.9
                ),
                startRadius: 0,
                endRadius: 250
            )
            .ignoresSafeArea()

            // Aurora star field
            if !reduceMotion {
                AuroraStarField(starCount: 40, twinkleSpeed: 3.0)
                    .opacity(0.5)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                nebulaPhase = 1
            }
            withAnimation(
                .easeInOut(duration: 12)
                .repeatForever(autoreverses: true)
            ) {
                auroraWave = 1
            }
        }
    }
}

// MARK: - Aurora Constellation Task Row

struct ConstellationTaskRow: View {
    let task: TaskItem
    let onUncomplete: () -> Void

    @State private var starTwinkle: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Aurora.Spacing.sm) {
            // Aurora star constellation point
            ZStack {
                // Outer aurora glow
                SwiftUI.Circle()
                    .fill(Aurora.Colors.prismaticGreen.opacity(0.4))
                    .frame(width: 20, height: 20)
                    .blur(radius: 6 + (starTwinkle * 4))
                    .scaleEffect(1 + (glowPulse * 0.2))

                // Inner glow ring
                SwiftUI.Circle()
                    .stroke(
                        Aurora.Colors.prismaticGreen.opacity(0.6),
                        lineWidth: 1
                    )
                    .frame(width: 14, height: 14)
                    .scaleEffect(1 + (starTwinkle * 0.1))

                // Core star with gradient
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Aurora.Colors.cosmicGold, Aurora.Colors.prismaticGreen],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(0.9 + (starTwinkle * 0.15))
            }

            // Title (ethereal, achieved)
            Text(task.title)
                .font(Aurora.Typography.body)
                .foregroundStyle(Aurora.Colors.textTertiary)
                .strikethrough(true, color: Aurora.Colors.prismaticGreen.opacity(0.4))
                .lineLimit(1)

            Spacer()

            // Restore button with Aurora glow
            Button {
                AuroraSoundEngine.shared.play(.buttonTap)
                AuroraHaptics.light()
                onUncomplete()
            } label: {
                Text("Restore")
                    .font(Aurora.Typography.meta)
                    .foregroundStyle(Aurora.Colors.electricCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(Aurora.Colors.electricCyan.opacity(0.1))
                            .overlay {
                                Capsule()
                                    .strokeBorder(Aurora.Colors.electricCyan.opacity(0.3), lineWidth: 0.5)
                            }
                    }
            }
        }
        .padding(.horizontal, Aurora.Spacing.md)
        .padding(.vertical, Aurora.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Aurora.Radius.card)
                .fill(Aurora.Colors.voidNebula.opacity(0.6))
                .overlay {
                    // Subtle achievement aurora shimmer
                    RoundedRectangle(cornerRadius: Aurora.Radius.card)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Aurora.Colors.prismaticGreen.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
        }
        .onAppear {
            guard !reduceMotion else { return }
            // Star twinkle animation
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                starTwinkle = 1
            }
            // Glow pulse animation
            withAnimation(
                .easeInOut(duration: AuroraMotion.Duration.glowPulse)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = 1
            }
        }
    }
}

// MARK: - Aurora Kanban Column

struct KanbanColumn: View {
    let section: KanbanSection
    let tasks: [TaskItem]
    let onTaskTap: (TaskItem) -> Void
    let onTaskComplete: (TaskItem) -> Void
    var onStartFocus: ((TaskItem, Int) -> Void)?
    var onSnooze: ((TaskItem) -> Void)?
    var onDelete: ((TaskItem) -> Void)?

    @State private var headerGlow: CGFloat = 0
    @Environment(\.responsiveLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            // Aurora column header
            columnHeader

            // Tasks in column
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(tasks) { task in
                        TaskCardV4(
                            task: task,
                            onTap: {
                                AuroraSoundEngine.shared.play(.buttonTap)
                                onTaskTap(task)
                            },
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
        HStack(spacing: Aurora.Spacing.sm) {
            // Aurora energy status indicator
            ZStack {
                // Outer glow
                SwiftUI.Circle()
                    .fill(section.color.opacity(0.4))
                    .frame(width: 14, height: 14)
                    .blur(radius: 4 + (headerGlow * 2))

                // Core
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [Aurora.Colors.stellarWhite, section.color],
                            center: .center,
                            startRadius: 0,
                            endRadius: 6
                        )
                    )
                    .frame(width: 10, height: 10)
            }

            Text(section.rawValue)
                .font(Aurora.Typography.headline)
                .foregroundStyle(Aurora.Colors.textPrimary)

            Spacer()

            // Aurora count badge
            Text("\(tasks.count)")
                .font(Aurora.Typography.callout.weight(.semibold))
                .foregroundStyle(section.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(section.color.opacity(0.12))
                        .overlay {
                            Capsule()
                                .strokeBorder(section.color.opacity(0.3), lineWidth: 0.5)
                        }
                )
        }
        .padding(.horizontal, Aurora.Spacing.md)
        .padding(.vertical, Aurora.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Aurora.Radius.card, style: .continuous)
                .fill(Aurora.Colors.voidNebula)
                .overlay {
                    // Subtle section glow
                    RoundedRectangle(cornerRadius: Aurora.Radius.card, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [section.color.opacity(0.08), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Aurora.Radius.card, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [section.color.opacity(0.3), section.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: AuroraMotion.Duration.glowPulse)
                .repeatForever(autoreverses: true)
            ) {
                headerGlow = 1
            }
        }
    }

    private var emptyColumnPlaceholder: some View {
        VStack(spacing: Aurora.Spacing.sm) {
            // Aurora-styled empty icon
            ZStack {
                SwiftUI.Circle()
                    .fill(section.color.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)

                Image(systemName: section.icon)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Aurora.Colors.textTertiary)
            }

            Text("No tasks")
                .font(Aurora.Typography.callout)
                .foregroundStyle(Aurora.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background {
            RoundedRectangle(cornerRadius: Aurora.Radius.card, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .foregroundStyle(section.color.opacity(0.2))
        }
    }
}

// MARK: - Chat Schedule Picker Sheet

struct ChatSchedulePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Date) -> Void

    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: CosmicWidget.Spacing.lg) {
                DatePicker(
                    "Schedule",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(CosmicWidget.Widget.electricCyan)

                Button {
                    onSelect(selectedDate)
                    dismiss()
                } label: {
                    Text("Set Schedule")
                        .font(CosmicWidget.Typography.title3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CosmicWidget.Spacing.md)
                        .background(CosmicWidget.Widget.electricCyanGradient)
                        .clipShape(RoundedRectangle(cornerRadius: CosmicWidget.Radius.large))
                }
            }
            .padding(CosmicWidget.Spacing.screenPadding)
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
            VStack(spacing: CosmicWidget.Spacing.md) {
                ForEach(1...3, id: \.self) { priority in
                    Button {
                        HapticsService.shared.selectionFeedback()
                        onSelect(priority)
                        dismiss()
                    } label: {
                        HStack(spacing: CosmicWidget.Spacing.md) {
                            // Stars
                            HStack(spacing: 4) {
                                ForEach(0..<priority, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(CosmicWidget.Widget.gold)
                                }
                                ForEach(0..<(3 - priority), id: \.self) { _ in
                                    Image(systemName: "star")
                                        .font(.system(size: 18))
                                        .foregroundStyle(CosmicWidget.Text.tertiary)
                                }
                            }

                            Spacer()

                            // Label
                            Text(priorityLabel(priority))
                                .font(CosmicWidget.Typography.body)
                                .foregroundStyle(CosmicWidget.Text.primary)
                        }
                        .padding(CosmicWidget.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CosmicWidget.Radius.card)
                                .fill(CosmicWidget.Void.nebula.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(CosmicWidget.Spacing.screenPadding)
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
                VStack(alignment: .leading, spacing: CosmicWidget.Spacing.lg) {
                    // Title
                    Text(task.title)
                        .font(CosmicWidget.Typography.title2)
                        .foregroundStyle(CosmicWidget.Text.primary)

                    // Metadata
                    VStack(alignment: .leading, spacing: CosmicWidget.Spacing.sm) {
                        if task.starRating > 0 {
                            HStack(spacing: CosmicWidget.Spacing.sm) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(CosmicWidget.Widget.gold)
                                Text("Priority: \(task.starRating)/3")
                                    .font(CosmicWidget.Typography.body)
                                    .foregroundStyle(CosmicWidget.Text.secondary)
                            }
                        }

                        if let scheduled = task.scheduledTime {
                            HStack(spacing: CosmicWidget.Spacing.sm) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(CosmicWidget.Widget.teal)
                                Text("Scheduled: \(scheduled.formatted(date: .abbreviated, time: .shortened))")
                                    .font(CosmicWidget.Typography.body)
                                    .foregroundStyle(CosmicWidget.Text.secondary)
                            }
                        }

                        HStack(spacing: CosmicWidget.Spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundStyle(CosmicWidget.Text.tertiary)
                            Text("Created: \(task.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(CosmicWidget.Typography.body)
                                .foregroundStyle(CosmicWidget.Text.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(CosmicWidget.Spacing.screenPadding)
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
                            .foregroundStyle(CosmicWidget.Text.tertiary)
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
