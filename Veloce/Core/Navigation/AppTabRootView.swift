//
//  AppTabRootView.swift
//  Veloce
//
//  Content switching view based on selected tab
//  Returns the appropriate view for each tab destination
//

import SwiftUI
import SwiftData

/// View that renders content based on the selected tab
struct AppTabRootView: View {
    let tab: AppTab

    // ViewModels passed from parent
    let chatTasksViewModel: ChatTasksViewModel
    let calendarViewModel: CalendarViewModel
    let tasksViewModel: TasksViewModel

    // Task selection callback
    var onTaskSelected: ((TaskItem) -> Void)?

    // Input bar bindings (for tasks tab)
    @Binding var taskInputText: String
    @FocusState.Binding var isTaskInputFocused: Bool
    var completedTasksToday: Int
    var onSubmit: () -> Void
    var onSchedule: () -> Void
    var onPriority: () -> Void
    var onAI: () -> Void

    var body: some View {
        switch tab {
        case .tasks:
            tasksContent

        case .calendar:
            EnhancedCalendarView(viewModel: calendarViewModel)

        case .focus:
            FocusTabView()

        // Note: Circles removed from tabs - accessed via CirclesPill
        case .momentum:
            MomentumTabViewRedesign()

        case .journal:
            JournalTabView(tasksViewModel: tasksViewModel)
        }
    }

    // MARK: - Tasks Tab Content

    @ViewBuilder
    private var tasksContent: some View {
        NavigationStack {
            ChatTasksView(
                viewModel: chatTasksViewModel,
                onTaskSelected: { task in
                    onTaskSelected?(task)
                }
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    FloatingInputBar(
                        text: $taskInputText,
                        isFocused: $isTaskInputFocused,
                        completedTasksToday: completedTasksToday,
                        currentStreak: GamificationService.shared.currentStreak,
                        isFirstTaskOfDay: chatTasksViewModel.tasks.filter { !$0.isCompleted }.isEmpty,
                        onSubmit: onSubmit,
                        onSchedule: onSchedule,
                        onPriority: onPriority,
                        onAI: onAI
                    )
                    // Spacer for tab bar height
                    Spacer()
                        .frame(height: 90)
                }
            }
        }
    }
}

// MARK: - Simplified Content View (Alternative Pattern)

/// Simpler content switching without complex bindings
/// Use this pattern when you don't need input bar integration at tab level
struct AppTabContentView: View {
    let tab: AppTab

    var body: some View {
        switch tab {
        case .tasks:
            // Placeholder - actual implementation in MainContainerView
            Text("Tasks")

        case .calendar:
            // Placeholder - actual implementation in MainContainerView
            Text("Calendar")

        case .focus:
            FocusTabView()

        // Note: Circles removed from tabs - accessed via CirclesPill
        case .momentum:
            MomentumTabViewRedesign()

        case .journal:
            // Placeholder - actual implementation in MainContainerView
            Text("Journal")
        }
    }
}
