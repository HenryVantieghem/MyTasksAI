//
//  MainContainerView.swift
//  Veloce
//
//  Main Container View - Tab-based Navigation
//  Primary navigation structure for authenticated users
//

import SwiftUI
import SwiftData

// MARK: - Main Tab

enum MainTab: String, CaseIterable {
    case tasks = "Tasks"
    case calendar = "Calendar"
    case goals = "Goals"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .tasks: return "checkmark.circle"
        case .calendar: return "calendar"
        case .goals: return "target"
        case .settings: return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .tasks: return "checkmark.circle.fill"
        case .calendar: return "calendar"
        case .goals: return "target"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Main Container View

struct MainContainerView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: MainTab = .tasks
    @State private var tasksViewModel = TasksViewModel()
    @State private var calendarViewModel = CalendarViewModel()
    @State private var settingsViewModel = SettingsViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tasks Tab - Apple Notes-style open sheet
            NavigationStack {
                NotesStyleTasksView(viewModel: tasksViewModel)
                    .navigationTitle("Tasks")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    // Filter options
                                } label: {
                                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                                }

                                Button {
                                    // Brain dump
                                } label: {
                                    Label("Brain Dump", systemImage: "brain.head.profile")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(NotesTheme.Colors.primary)
                            }
                        }
                    }
            }
            .tabItem {
                Label(MainTab.tasks.rawValue, systemImage: selectedTab == .tasks ? MainTab.tasks.selectedIcon : MainTab.tasks.icon)
            }
            .tag(MainTab.tasks)

            // Calendar Tab
            CalendarPageView(viewModel: calendarViewModel)
                .tabItem {
                    Label(MainTab.calendar.rawValue, systemImage: MainTab.calendar.icon)
                }
                .tag(MainTab.calendar)

            // Goals Tab
            GoalsPageView()
                .tabItem {
                    Label(MainTab.goals.rawValue, systemImage: MainTab.goals.icon)
                }
                .tag(MainTab.goals)

            // Settings Tab
            SettingsPageView(viewModel: settingsViewModel)
                .tabItem {
                    Label(MainTab.settings.rawValue, systemImage: selectedTab == .settings ? MainTab.settings.selectedIcon : MainTab.settings.icon)
                }
                .tag(MainTab.settings)
        }
        .tint(Color(red: 0.757, green: 0.373, blue: 0.235)) // Claude warm orange
        .onAppear {
            setupViewModels()
        }
    }

    private func setupViewModels() {
        tasksViewModel.setup(context: modelContext)
        calendarViewModel.setup(context: modelContext)
        settingsViewModel.setup(context: modelContext, user: appViewModel.currentUser)
    }
}

// MARK: - Tasks Page View

struct TasksPageView: View {
    @Bindable var viewModel: TasksViewModel
    @State private var showAddTask = false
    @State private var showBrainDump = false
    @State private var newTaskTitle = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                IridescentBackground(intensity: 0.3)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats bar
                    MainStatsBar(
                        completed: viewModel.todayCompleted,
                        total: GamificationService.shared.dailyGoal,
                        streak: GamificationService.shared.currentStreak,
                        points: GamificationService.shared.totalPoints
                    )
                    .padding(.horizontal, Theme.Spacing.md)

                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    title: filter.rawValue,
                                    icon: filter.icon,
                                    isSelected: viewModel.currentFilter == filter
                                ) {
                                    viewModel.currentFilter = filter
                                    HapticsService.shared.selectionFeedback()
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    .padding(.vertical, Theme.Spacing.sm)

                    // Task list
                    if viewModel.filteredTasks.isEmpty {
                        emptyState
                    } else {
                        taskList
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding(Theme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showBrainDump = true
                    } label: {
                        Image(systemName: "brain.head.profile")
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showBrainDump) {
                BrainDumpSheet(
                    isPresented: $showBrainDump,
                    onTasksCreated: { tasks in
                        for parsedTask in tasks {
                            viewModel.createTask(title: parsedTask.title)
                        }
                    }
                )
            }
        }
    }

    private var taskList: some View {
        List {
            ForEach(viewModel.filteredTasks) { task in
                TaskRow(task: task, viewModel: viewModel)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete(perform: viewModel.deleteTasks)
            .onMove(perform: viewModel.moveTasks)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Animated empty state illustration
            AnimatedEmptyStateIcon(icon: emptyStateIcon)
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.sm) {
                Text(emptyStateTitle)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(emptyStateSubtitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            .fadeIn(delay: 0.2)

            // CTA Button for empty states
            if showEmptyStateCTA {
                ShimmerCTAButton(
                    title: emptyStateCTAText,
                    action: {
                        showAddTask = true
                        HapticsService.shared.impact(.medium)
                    }
                )
                .padding(.top, Theme.Spacing.md)
                .scaleIn(delay: 0.4)
            }

            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(emptyStateTitle). \(emptyStateSubtitle)")
    }

    private var emptyStateIcon: String {
        switch viewModel.currentFilter {
        case .all: return "tray"
        case .today: return "sun.max"
        case .scheduled: return "calendar.badge.clock"
        case .completed: return "checkmark.circle"
        }
    }

    private var emptyStateTitle: String {
        switch viewModel.currentFilter {
        case .all: return "No tasks yet"
        case .today: return "All clear for today!"
        case .scheduled: return "Nothing scheduled"
        case .completed: return "Nothing completed yet"
        }
    }

    private var emptyStateSubtitle: String {
        switch viewModel.currentFilter {
        case .all: return "Add your first task to get started"
        case .today: return "Enjoy your free time or add some tasks"
        case .scheduled: return "Schedule tasks to plan your day better"
        case .completed: return "Complete tasks to see them here"
        }
    }

    private var showEmptyStateCTA: Bool {
        viewModel.currentFilter == .all || viewModel.currentFilter == .today
    }

    private var emptyStateCTAText: String {
        "Add Task"
    }

    private var addButton: some View {
        PremiumFAB(
            isEmpty: viewModel.filteredTasks.isEmpty,
            action: {
                showAddTask = true
                HapticsService.shared.impact(.medium)
            }
        )
    }
}

// MARK: - Premium Floating Action Button

struct PremiumFAB: View {
    let isEmpty: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var floatPhase: CGFloat = 0
    @State private var glowPhase: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow ring (intensifies when empty)
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Theme.Colors.accent.opacity(isEmpty ? 0.6 : 0.3),
                                Theme.Colors.accentSecondary.opacity(isEmpty ? 0.4 : 0.2),
                                Theme.Colors.aiCyan.opacity(isEmpty ? 0.3 : 0.1),
                                Theme.Colors.accent.opacity(isEmpty ? 0.6 : 0.3)
                            ],
                            center: .center,
                            angle: .degrees(rotationAngle)
                        ),
                        lineWidth: isEmpty ? 3 : 2
                    )
                    .frame(width: 68, height: 68)
                    .blur(radius: isEmpty ? 6 : 4)
                    .scaleEffect(1 + glowPhase * (isEmpty ? 0.15 : 0.08))

                // Glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.4),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                // Gradient fill
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accent.opacity(0.9),
                                Theme.Colors.accentSecondary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
            }
            .frame(width: 68, height: 68)
            .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(isPressed ? 1.1 : 1.0)
            .offset(y: reduceMotion ? 0 : -floatPhase * 3)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
        }, onRelease: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        })
        .onAppear {
            guard !reduceMotion else { return }

            // Floating animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                floatPhase = 1
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }

            // Ring rotation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
        .accessibilityLabel("Add new task")
        .accessibilityHint("Double tap to create a new task")
    }
}

// MARK: - Press Events Modifier

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Scale Button Style (for tap feedback)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Animated Empty State Icon

struct AnimatedEmptyStateIcon: View {
    let icon: String

    @State private var floatOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var sparkleOpacity: [Double] = [0.3, 0.5, 0.7, 0.4, 0.6]
    @State private var sparklePositions: [CGPoint] = [
        CGPoint(x: -40, y: -30),
        CGPoint(x: 45, y: -25),
        CGPoint(x: -35, y: 35),
        CGPoint(x: 50, y: 30),
        CGPoint(x: 0, y: -50)
    ]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.accent.opacity(0.15),
                            Theme.Colors.accent.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)

            // Orbiting sparkles
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat([8, 10, 6, 12, 9][index])))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue, Theme.Colors.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(sparkleOpacity[index])
                    .offset(
                        x: sparklePositions[index].x,
                        y: sparklePositions[index].y + (reduceMotion ? 0 : floatOffset * CGFloat([0.8, -0.6, 0.5, -0.7, 0.9][index]))
                    )
            }

            // Main icon with floating animation
            ZStack {
                // Icon glow
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Theme.Colors.accent.opacity(0.3))
                    .blur(radius: 8)

                // Main icon
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accent,
                                Theme.Colors.accentSecondary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.byLayer, options: .repeating)
            }
            .offset(y: reduceMotion ? 0 : floatOffset * 5)
            .rotationEffect(.degrees(reduceMotion ? 0 : rotationAngle))
        }
        .frame(height: 120)
        .onAppear {
            guard !reduceMotion else { return }

            // Floating animation
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatOffset = 1
            }

            // Subtle rotation
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                rotationAngle = 3
            }

            // Sparkle opacity animation
            for i in 0..<5 {
                withAnimation(.easeInOut(duration: Double([2.0, 2.5, 1.8, 2.2, 2.7][i])).repeatForever(autoreverses: true).delay(Double(i) * 0.3)) {
                    sparkleOpacity[i] = [0.8, 1.0, 0.9, 0.7, 0.85][i]
                }
            }
        }
    }
}

// MARK: - Shimmer CTA Button

struct ShimmerCTAButton: View {
    let title: String
    let action: () -> Void

    @State private var shimmerOffset: CGFloat = -200
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                Text(title)
            }
            .font(Theme.Typography.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background {
                ZStack {
                    // Base gradient
                    Capsule()
                        .fill(Theme.Colors.accentGradient)

                    // Shimmer overlay
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(Capsule())
                }
            }
            .clipShape(Capsule())
            .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 12, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents(
            onPress: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = true
                }
            },
            onRelease: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        )
        .onAppear {
            guard !reduceMotion else { return }
            // Shimmer animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false).delay(1)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: TaskItem
    @Bindable var viewModel: TasksViewModel
    @State private var showDetail = false
    @State private var checkScale: CGFloat = 1.0
    @State private var checkOpacity: Double = 1.0
    @State private var strikethroughProgress: CGFloat = 0
    @State private var sparkleRotation: Double = 0
    @State private var isAppearing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var priorityColor: Color {
        switch task.priorityEnum {
        case .high: return Theme.Colors.error
        case .medium: return Theme.Colors.warning
        case .low: return Theme.Colors.textTertiary.opacity(0.5)
        }
    }

    var body: some View {
        Button {
            showDetail = true
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 0) {
                // Priority accent border
                RoundedRectangle(cornerRadius: 2)
                    .fill(priorityColor)
                    .frame(width: 4)
                    .padding(.vertical, 8)

                HStack(spacing: Theme.Spacing.md) {
                    // Animated Checkbox
                    Button {
                        toggleWithAnimation()
                    } label: {
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(task.isCompleted ? Theme.Colors.success : Theme.Colors.textTertiary.opacity(0.4), lineWidth: 2)
                                .frame(width: 26, height: 26)

                            // Filled background when complete
                            Circle()
                                .fill(task.isCompleted ? Theme.Colors.success : Color.clear)
                                .frame(width: 22, height: 22)
                                .scaleEffect(task.isCompleted ? 1 : 0)

                            // Checkmark
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .scaleEffect(task.isCompleted ? 1 : 0)
                                .opacity(task.isCompleted ? 1 : 0)
                        }
                        .scaleEffect(checkScale)
                        .opacity(checkOpacity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
                    .accessibilityHint("Double tap to toggle task completion")

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        // Title with animated strikethrough
                        Text(task.title)
                            .font(Theme.Typography.body)
                            .foregroundStyle(task.isCompleted ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                            .strikethrough(task.isCompleted, color: Theme.Colors.textTertiary)
                            .lineLimit(2)

                        // Metadata row
                        HStack(spacing: Theme.Spacing.sm) {
                            // Star rating with gold shimmer
                            if task.starRating > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<task.starRating, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                    }
                                }
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.Colors.gold, Theme.Colors.warning],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .accessibilityLabel("\(task.starRating) star priority")
                            }

                            // Time estimate pill
                            if let minutes = task.estimatedMinutes {
                                HStack(spacing: 3) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 9))
                                    Text("\(minutes)m")
                                        .font(Theme.Typography.caption2)
                                }
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.glassBackground)
                                .clipShape(Capsule())
                                .accessibilityLabel("Estimated \(minutes) minutes")
                            }

                            // AI sparkle indicator with subtle rotation
                            if task.aiProcessedAt != nil {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .rotationEffect(.degrees(sparkleRotation))
                                    .accessibilityLabel("AI enhanced")
                            }
                        }
                    }

                    Spacer()

                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary.opacity(0.5))
                }
                .padding(.leading, Theme.Spacing.md)
                .padding(.trailing, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
            }
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.2),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(TaskRowButtonStyle())
        .contentShape(Rectangle())
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 10)
        .onAppear {
            // Stagger entrance
            guard !reduceMotion else {
                isAppearing = true
                return
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isAppearing = true
            }
            // Sparkle rotation
            if task.aiProcessedAt != nil {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    sparkleRotation = 15
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(taskAccessibilityLabel)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(task.isCompleted ? [.isButton] : [.isButton])
        .sheet(isPresented: $showDetail) {
            TaskDetailSheet(task: task, viewModel: viewModel)
        }
    }

    private func toggleWithAnimation() {
        let wasCompleted = task.isCompleted

        if reduceMotion {
            viewModel.toggleCompletion(task)
            return
        }

        // Bounce animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            checkScale = 1.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.toggleCompletion(task)

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                checkScale = 1.0
            }
        }

        // Haptic feedback
        if !wasCompleted {
            HapticsService.shared.impact(.medium)
        } else {
            HapticsService.shared.selectionFeedback()
        }

        let message = wasCompleted ? "Task marked incomplete" : "Task completed"
        AccessibilityAnnouncement.announce(message)
    }

    private var taskAccessibilityLabel: String {
        var parts: [String] = []

        if task.isCompleted {
            parts.append("Completed:")
        }

        parts.append(task.title)

        if task.starRating > 0 {
            parts.append("\(task.starRating) star priority")
        }

        if let minutes = task.estimatedMinutes {
            parts.append("estimated \(minutes) minutes")
        }

        if task.aiProcessedAt != nil {
            parts.append("AI enhanced")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Task Row Button Style

struct TaskRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)
                Text(title)
                    .font(isSelected ? Theme.Typography.caption1Medium : Theme.Typography.caption1)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
            .background {
                ZStack {
                    if isSelected {
                        // Selected: gradient fill with glow
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accent, Theme.Colors.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 8, x: 0, y: 2)
                    } else {
                        // Unselected: glass effect
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.3),
                                                .white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )
                    }
                }
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(FilterPillButtonStyle())
        .accessibilityLabel("\(title) filter")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to filter by \(title.lowercased())")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

struct FilterPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Main Stats Bar

struct MainStatsBar: View {
    let completed: Int
    let total: Int
    let streak: Int
    let points: Int

    @State private var animatedCompleted: Int = 0
    @State private var animatedStreak: Int = 0
    @State private var animatedPoints: Int = 0
    @State private var hasAnimated = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }

    private var isGoalComplete: Bool {
        completed >= total && total > 0
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Today's Progress with Ring
            TodayProgressStat(
                completed: animatedCompleted,
                total: total,
                progress: progress,
                isComplete: isGoalComplete
            )

            // Divider
            Rectangle()
                .fill(Theme.Colors.glassBorder)
                .frame(width: 1, height: 40)

            // Streak with Flame
            StreakStat(streak: animatedStreak)

            // Divider
            Rectangle()
                .fill(Theme.Colors.glassBorder)
                .frame(width: 1, height: 40)

            // Points
            PointsStat(points: animatedPoints)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25),
                                    .white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        }
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true

            if reduceMotion {
                animatedCompleted = completed
                animatedStreak = streak
                animatedPoints = points
            } else {
                // Animate counts
                animateCount(to: completed, updating: $animatedCompleted, duration: 0.6)
                animateCount(to: streak, updating: $animatedStreak, duration: 0.8)
                animateCount(to: points, updating: $animatedPoints, duration: 1.0)
            }
        }
        .onChange(of: completed) { _, newValue in
            if reduceMotion {
                animatedCompleted = newValue
            } else {
                animateCount(to: newValue, updating: $animatedCompleted, duration: 0.3)
            }
        }
        .onChange(of: streak) { _, newValue in
            if reduceMotion {
                animatedStreak = newValue
            } else {
                animateCount(to: newValue, updating: $animatedStreak, duration: 0.3)
            }
        }
        .onChange(of: points) { _, newValue in
            if reduceMotion {
                animatedPoints = newValue
            } else {
                animateCount(to: newValue, updating: $animatedPoints, duration: 0.5)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily progress: \(completed) of \(total) tasks, \(streak) day streak, \(points) points")
    }

    private func animateCount(to target: Int, updating binding: Binding<Int>, duration: Double) {
        let steps = 20
        let interval = duration / Double(steps)
        let increment = Double(target - binding.wrappedValue) / Double(steps)
        var current = Double(binding.wrappedValue)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                current += increment
                binding.wrappedValue = Int(current.rounded())
            }
        }
        // Ensure final value
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            binding.wrappedValue = target
        }
    }
}

// MARK: - Today Progress Stat

struct TodayProgressStat: View {
    let completed: Int
    let total: Int
    let progress: Double
    let isComplete: Bool

    @State private var ringProgress: Double = 0
    @State private var celebratePulse: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Progress Ring
            ZStack {
                // Track
                Circle()
                    .stroke(Theme.Colors.textTertiary.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)

                // Progress
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        isComplete ?
                        LinearGradient(colors: [Theme.Colors.success, Theme.Colors.aiCyan], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Theme.Colors.accent, Theme.Colors.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                // Checkmark when complete
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Colors.success)
                        .scaleEffect(celebratePulse ? 1.2 : 1.0)
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(completed)/\(total)")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
                Text("Today")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                ringProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                ringProgress = newValue
            }
        }
        .onChange(of: isComplete) { _, newValue in
            guard newValue, !reduceMotion else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                celebratePulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    celebratePulse = false
                }
            }
        }
    }
}

// MARK: - Streak Stat

struct StreakStat: View {
    let streak: Int

    @State private var flameWiggle: Double = 0
    @State private var glowIntensity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isOnFire: Bool { streak >= 3 }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                // Glow effect for active streaks
                if isOnFire {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.fire.opacity(0.4))
                        .blur(radius: 6)
                        .scaleEffect(1.0 + glowIntensity * 0.3)
                }

                Image(systemName: isOnFire ? "flame.fill" : "flame")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isOnFire ?
                        LinearGradient(colors: [Theme.Colors.fire, Theme.Colors.streakOrange, Theme.Colors.warning], startPoint: .bottom, endPoint: .top) :
                            LinearGradient(colors: [Theme.Colors.textTertiary], startPoint: .bottom, endPoint: .top)
                    )
                    .rotationEffect(.degrees(flameWiggle))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak)")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
                Text(streak == 1 ? "Day" : "Days")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard isOnFire, !reduceMotion else { return }
            // Flame wiggle
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                flameWiggle = 5
            }
            // Glow pulse
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowIntensity = 1
            }
        }
    }
}

// MARK: - Points Stat

struct PointsStat: View {
    let points: Int

    @State private var starRotation: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                // Background glow
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.xp.opacity(0.3))
                    .blur(radius: 4)

                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.gold, Theme.Colors.xp],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(starRotation))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(points)")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
                Text("XP")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                starRotation = 10
            }
        }
    }
}

// MARK: - Add Task Sheet

struct AddTaskSheet: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                TextField("What do you need to do?", text: $title, axis: .vertical)
                    .font(Theme.Typography.body)
                    .focused($isFocused)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.glassBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .padding(.horizontal, Theme.Spacing.md)

                Spacer()
            }
            .padding(.top, Theme.Spacing.lg)
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !title.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.createTask(title: title.trimmingCharacters(in: .whitespaces))
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Calendar Page View

struct CalendarPageView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                IridescentBackground(intensity: 0.3)
                    .ignoresSafeArea()

                VStack {
                    if !viewModel.isAuthorized {
                        calendarPermissionView
                    } else {
                        calendarContent
                    }
                }
            }
            .navigationTitle("Calendar")
        }
    }

    private var calendarPermissionView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("Calendar Access Required")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Enable calendar access to sync your tasks with your schedule.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button("Enable Calendar Access") {
                Task {
                    await viewModel.requestAccess()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Theme.Spacing.xl)
    }

    private var calendarContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Calendar header
                HStack {
                    Button {
                        viewModel.goToPrevious()
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Previous month")

                    Spacer()

                    Text(viewModel.selectedDate, format: .dateTime.month().year())
                        .font(Theme.Typography.headline)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Button {
                        viewModel.goToNext()
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Next month")
                }
                .padding(.horizontal, Theme.Spacing.md)

                // Week days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.weekDays, id: \.self) { date in
                        CalendarDayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            hasEvents: !viewModel.tasks(for: date).isEmpty
                        ) {
                            viewModel.selectDate(date)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)

                // Day's tasks
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Scheduled Tasks")
                        .font(Theme.Typography.headline)
                        .padding(.horizontal, Theme.Spacing.md)

                    if viewModel.scheduledTasks.isEmpty {
                        Text("No tasks scheduled")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .padding(Theme.Spacing.md)
                    } else {
                        ForEach(viewModel.scheduledTasks) { task in
                            ScheduledTaskRow(task: task)
                                .padding(.horizontal, Theme.Spacing.md)
                        }
                    }
                }
            }
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let action: () -> Void

    @State private var todayPulse: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button {
            action()
            HapticsService.shared.selectionFeedback()
        } label: {
            VStack(spacing: 4) {
                Text(date, format: .dateTime.weekday(.short))
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)

                ZStack {
                    // Glow for today
                    if isToday && !isSelected {
                        Circle()
                            .fill(Theme.Colors.accent.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .blur(radius: 4)
                            .scaleEffect(todayPulse ? 1.1 : 1.0)
                    }

                    // Background
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(colors: [Theme.Colors.accent, Theme.Colors.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 36, height: 36)

                    // Glass effect for selected
                    if isSelected {
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .frame(width: 36, height: 36)
                    }

                    // Today ring
                    if isToday && !isSelected {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.Colors.accent, Theme.Colors.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 36, height: 36)
                    }

                    // Day number
                    Text(date, format: .dateTime.day())
                        .font(isToday || isSelected ? Theme.Typography.bodyBold : Theme.Typography.body)
                        .foregroundStyle(isSelected ? .white : (isToday ? Theme.Colors.accent : Theme.Colors.textPrimary))
                }
                .shadow(color: isSelected ? Theme.Colors.accent.opacity(0.3) : .clear, radius: 6, x: 0, y: 2)

                // Event indicator
                if hasEvents {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(isSelected ? .white : Theme.Colors.accent)
                            .frame(width: 5, height: 5)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Color.clear
                        .frame(width: 5, height: 5)
                }
            }
        }
        .buttonStyle(CalendarCellButtonStyle())
        .onAppear {
            guard isToday, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                todayPulse = true
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to view this day")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        var label = formatter.string(from: date)

        if isToday {
            label = "Today, \(label)"
        }

        if hasEvents {
            label += ", has tasks"
        }

        return label
    }
}

struct CalendarCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ScheduledTaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Time pill
            if let time = task.scheduledTime {
                Text(time, format: .dateTime.hour().minute())
                    .font(Theme.Typography.caption1Medium)
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.accent.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(task.title)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary.opacity(0.5))
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Theme.Colors.glassBorder, lineWidth: 0.5)
                )
        }
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Goals Page View

struct GoalsPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]

    var body: some View {
        NavigationStack {
            ZStack {
                IridescentBackground(intensity: 0.3)
                    .ignoresSafeArea()

                if goals.isEmpty {
                    emptyState
                } else {
                    goalsList
                }
            }
            .navigationTitle("Goals")
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "target")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accent.opacity(0.6), Theme.Colors.accentSecondary.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse.byLayer, options: .repeating)
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.sm) {
                Text("No goals yet")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Set SMART goals to stay focused on what matters.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // CTA Button
            Button {
                // TODO: Show add goal sheet
                HapticsService.shared.impact(.medium)
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Goal")
                }
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.accentGradient)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, Theme.Spacing.md)
        }
        .padding(Theme.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No goals yet. Set SMART goals to stay focused on what matters.")
    }

    private var goalsList: some View {
        List {
            ForEach(goals) { goal in
                GoalRow(goal: goal)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct GoalRow: View {
    let goal: Goal

    @State private var animatedProgress: Double = 0
    @State private var isAppearing = false
    @State private var completedScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progressColor: LinearGradient {
        if goal.isCompleted {
            return LinearGradient(colors: [Theme.Colors.success, Theme.Colors.aiCyan], startPoint: .leading, endPoint: .trailing)
        } else if goal.progress >= 0.7 {
            return LinearGradient(colors: [Theme.Colors.accent, Theme.Colors.success], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [Theme.Colors.accent, Theme.Colors.accentSecondary], startPoint: .leading, endPoint: .trailing)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(goal.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(goal.isCompleted ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                    .strikethrough(goal.isCompleted, color: Theme.Colors.textTertiary)

                Spacer()

                if goal.isCompleted {
                    ZStack {
                        // Glow
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.Colors.success.opacity(0.3))
                            .blur(radius: 4)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.success, Theme.Colors.aiCyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(completedScale)
                } else {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.textTertiary.opacity(0.2), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        Circle()
                            .trim(from: 0, to: animatedProgress)
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(animatedProgress * 100))")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }

            if let description = goal.goalDescription {
                Text(description)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            // Animated progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.Colors.textTertiary.opacity(0.15))
                        .frame(height: 6)

                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: geo.size.width * animatedProgress, height: 6)
                        .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(Int(animatedProgress * 100))% complete")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .contentTransition(.numericText())

                Spacer()

                if let targetDate = goal.targetDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(targetDate, format: .dateTime.month().day())
                            .font(Theme.Typography.caption2)
                    }
                    .foregroundStyle(goal.isOverdue ? Theme.Colors.error : Theme.Colors.textTertiary)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(
                            goal.isCompleted ?
                            LinearGradient(colors: [Theme.Colors.success.opacity(0.3), Theme.Colors.success.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 0.5
                        )
                )
        }
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 10)
        .onAppear {
            if reduceMotion {
                animatedProgress = goal.progress
                isAppearing = true
                return
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isAppearing = true
            }

            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = goal.progress
            }

            if goal.isCompleted {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.5)) {
                    completedScale = 1.15
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.7)) {
                    completedScale = 1.0
                }
            }
        }
        .onChange(of: goal.progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Settings Page View

struct SettingsPageView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.Colors.accent)

                        VStack(alignment: .leading) {
                            Text(viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName)
                                .font(Theme.Typography.headline)
                            Text(viewModel.email)
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }

                // Goals Section
                Section("Daily Goals") {
                    Stepper("Daily: \(viewModel.dailyTaskGoal) tasks", value: $viewModel.dailyTaskGoal, in: 1...20)
                    Stepper("Weekly: \(viewModel.weeklyTaskGoal) tasks", value: $viewModel.weeklyTaskGoal, in: 5...100, step: 5)
                }

                // Preferences Section
                Section("Preferences") {
                    Toggle("Notifications", isOn: $viewModel.notificationsEnabled)
                    Toggle("Calendar Sync", isOn: $viewModel.calendarSyncEnabled)
                    Toggle("Haptic Feedback", isOn: $viewModel.hapticsEnabled)

                    Picker("Theme", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }

                // Subscription Section
                Section("Subscription") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(viewModel.isProUser ? "Pro" : "Free")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    if !viewModel.isProUser {
                        Button("Upgrade to Pro") {
                            // Show paywall
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            try? await viewModel.restorePurchases()
                        }
                    }
                }

                // Account Section
                Section("Account") {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            await appViewModel.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview

#Preview {
    MainContainerView()
        .environment(AppViewModel())
}
