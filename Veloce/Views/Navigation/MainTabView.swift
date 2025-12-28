//
//  MainTabView.swift
//  Veloce
//
//  Main Tab View - Primary navigation container
//  5 tabs: Tasks, Plan, Grow, Flow, Journal
//  Replaces MainContainerView's tab logic with standard TabView
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.responsiveLayout) private var layout

    // Tab state
    @State private var selectedTab: AppTab = .tasks

    // ViewModels
    @State private var tasksViewModel = TasksViewModel()
    @State private var calendarViewModel = CalendarViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var chatTasksViewModel = ChatTasksViewModel()

    // Sheet state
    @State private var showProfileSheet = false
    @State private var showBrainDumpSheet = false
    @State private var showSearchSheet = false

    // Input bar state (managed at container level)
    @State private var taskInputText = ""
    @FocusState private var isTaskInputFocused: Bool

    // Task card state (managed at container level) - using optional for .sheet(item:)
    @State private var selectedTaskForDetail: TaskItem?

    var body: some View {
        // Tab content with standard TabView
        TabView(selection: $selectedTab) {
            // Tasks Tab
            tasksTab
                .tabItem {
                    Label(AppTab.tasks.title, systemImage: selectedTab == .tasks ? AppTab.tasks.selectedIcon : AppTab.tasks.icon)
                }
                .tag(AppTab.tasks)

            // Plan Tab (Calendar)
            EnhancedCalendarView(viewModel: calendarViewModel)
                .tabItem {
                    Label(AppTab.plan.title, systemImage: selectedTab == .plan ? AppTab.plan.selectedIcon : AppTab.plan.icon)
                }
                .tag(AppTab.plan)

            // Grow Tab (Stats/Goals/Circles)
            GrowView()
                .tabItem {
                    Label(AppTab.grow.title, systemImage: selectedTab == .grow ? AppTab.grow.selectedIcon : AppTab.grow.icon)
                }
                .tag(AppTab.grow)

            // Flow Tab (Focus)
            FocusTabView()
                .tabItem {
                    Label(AppTab.flow.title, systemImage: selectedTab == .flow ? AppTab.flow.selectedIcon : AppTab.flow.icon)
                }
                .tag(AppTab.flow)

            // Journal Tab
            JournalTabView(tasksViewModel: tasksViewModel)
                .tabItem {
                    Label(AppTab.journal.title, systemImage: selectedTab == .journal ? AppTab.journal.selectedIcon : AppTab.journal.icon)
                }
                .tag(AppTab.journal)
        }
        .tint(.purple)
        // Full-featured Liquid Glass Task Detail Sheet - using .sheet(item:) for reliable presentation
        .sheet(item: $selectedTaskForDetail) { task in
            LiquidGlassTaskDetailSheet(
                task: task,
                onComplete: {
                    chatTasksViewModel.taskDidComplete(task)
                    selectedTaskForDetail = nil
                },
                onDuplicate: {
                    chatTasksViewModel.taskDidDuplicate(task)
                },
                onSnooze: { snoozeDate in
                    task.scheduledTime = snoozeDate
                    task.updatedAt = Date()
                    chatTasksViewModel.taskDidSnooze(task)
                },
                onDelete: {
                    chatTasksViewModel.taskDidDelete(task)
                    selectedTaskForDetail = nil
                },
                onSchedule: { scheduledDate in
                    chatTasksViewModel.updateTask(task, scheduledTime: scheduledDate)
                },
                onStartTimer: { taskItem in
                    selectedTaskForDetail = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedTab = .flow
                    }
                },
                onDismiss: {
                    selectedTaskForDetail = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground {
                Theme.CelestialColors.voidDeep
                    .ignoresSafeArea()
            }
        }
        .safeAreaInset(edge: .top) {
            AppHeaderView(
                title: selectedTab.title,
                showProfile: $showProfileSheet
            )
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(settingsViewModel: settingsViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .voidPresentationBackground()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
        // iPadOS 26 keyboard command handlers
        .handleCommands(
            selectedTab: $selectedTab,
            onNewTask: {
                // Focus the task input bar
                isTaskInputFocused = true
            },
            onBrainDump: {
                showBrainDumpSheet = true
            },
            onSearch: {
                showSearchSheet = true
            },
            onFocusMode: {
                selectedTab = .flow
            },
            onGoToToday: {
                calendarViewModel.goToToday()
            }
        )
        .onAppear {
            setupViewModels()
        }
    }

    // MARK: - Tasks Tab

    private var tasksTab: some View {
        NavigationStack {
            ChatTasksView(
                viewModel: chatTasksViewModel,
                onTaskSelected: { task in
                    if isTaskInputFocused {
                        isTaskInputFocused = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            presentTaskCard(task)
                        }
                    } else {
                        presentTaskCard(task)
                    }
                }
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    LiquidGlassTaskInputBar(
                        text: $taskInputText,
                        isFocused: $isTaskInputFocused,
                        onSubmit: { taskText in
                            createTaskFromInput(taskText)
                        },
                        onVoiceInput: {
                            // Voice recording handled internally
                            HapticsService.shared.lightImpact()
                        }
                    )
                    // Spacer for tab bar height (responsive)
                    Spacer()
                        .frame(height: layout.bottomSafeArea)
                }
            }
        }
    }


    // MARK: - Helper Methods

    private func presentTaskCard(_ task: TaskItem) {
        selectedTaskForDetail = task
        HapticsService.shared.impact(.medium)
    }

    private func createTaskFromInput(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            taskInputText = ""
            isTaskInputFocused = false
        }

        Task {
            await chatTasksViewModel.createTask(title: trimmedText, priority: 2)
        }
    }

    private func setupViewModels() {
        tasksViewModel.setup(context: modelContext)
        calendarViewModel.setup(context: modelContext)
        settingsViewModel.setup(context: modelContext, user: appViewModel.currentUser)
        chatTasksViewModel.setup(context: modelContext)

        Task {
            chatTasksViewModel.loadTasks()
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
