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
            // Tasks Tab
            TasksPageView(viewModel: tasksViewModel)
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
        .tint(Theme.Colors.accent)
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

            Image(systemName: "checkmark.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text(emptyStateMessage)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }

    private var emptyStateMessage: String {
        switch viewModel.currentFilter {
        case .all: return "No tasks yet.\nTap + to add your first task!"
        case .today: return "No tasks for today.\nEnjoy your day!"
        case .scheduled: return "No scheduled tasks.\nSchedule tasks for better planning."
        case .completed: return "No completed tasks yet.\nStart checking off your tasks!"
        }
    }

    private var addButton: some View {
        Button {
            showAddTask = true
            HapticsService.shared.impact()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.accent, Theme.Colors.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: TaskItem
    @Bindable var viewModel: TasksViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Checkbox
                Button {
                    viewModel.toggleCompletion(task)
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(task.isCompleted ? Theme.Colors.success : Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(Theme.Typography.body)
                        .foregroundStyle(task.isCompleted ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)

                    HStack(spacing: Theme.Spacing.sm) {
                        // Star rating
                        if task.starRating > 0 {
                            Text(String(repeating: "*", count: task.starRating))
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Colors.warning)
                        }

                        // Time estimate
                        if let minutes = task.estimatedMinutes {
                            Label("\(minutes)m", systemImage: "clock")
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        // AI processed indicator
                        if task.aiProcessedAt != nil {
                            Image(systemName: "sparkles")
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Colors.aiPurple)
                        }
                    }
                }

                Spacer()

                // Priority indicator
                Circle()
                    .fill(task.priorityEnum.color)
                    .frame(width: 8, height: 8)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            TaskDetailSheet(task: task, viewModel: viewModel)
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(Theme.Typography.caption1)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Theme.Colors.accent : Theme.Colors.glassBackground)
            .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Main Stats Bar

struct MainStatsBar: View {
    let completed: Int
    let total: Int
    let streak: Int
    let points: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            MainStatItem(icon: "checkmark.circle", value: "\(completed)/\(total)", label: "Today")
            MainStatItem(icon: "flame", value: "\(streak)", label: "Streak")
            MainStatItem(icon: "star", value: "\(points)", label: "Points")
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

struct MainStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.accent)
                Text(value)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
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
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(viewModel.selectedDate, format: .dateTime.month().year())
                        .font(Theme.Typography.headline)

                    Spacer()

                    Button {
                        viewModel.goToNext()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
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

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date, format: .dateTime.weekday(.short))
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Text(date, format: .dateTime.day())
                    .font(Theme.Typography.body)
                    .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? Theme.Colors.accent : Color.clear)
                    .clipShape(Circle())

                if hasEvents {
                    Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct ScheduledTaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack {
            if let time = task.scheduledTime {
                Text(time, format: .dateTime.hour().minute())
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(width: 60)
            }

            Text(task.title)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
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
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No goals yet")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Set SMART goals to stay focused on what matters.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
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

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(goal.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.success)
                }
            }

            if let description = goal.goalDescription {
                Text(description)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.glassBorder)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.accent)
                        .frame(width: geo.size.width * goal.progress, height: 4)
                }
            }
            .frame(height: 4)

            Text("\(Int(goal.progress * 100))% complete")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
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
