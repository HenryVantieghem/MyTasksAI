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
    var onSubmit: (String) -> Void

    var body: some View {
        switch tab {
        case .tasks:
            tasksContent

        case .plan:
            EnhancedCalendarView(viewModel: calendarViewModel)

        case .grow:
            GrowView()

        case .flow:
            FocusTabView()

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
                    TaskInputBarV2(
                        text: $taskInputText,
                        isFocused: $isTaskInputFocused,
                        onSubmit: onSubmit,
                        onVoiceInput: nil
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
            // Placeholder - actual implementation in MainTabView
            Text("Tasks")

        case .plan:
            // Placeholder - actual implementation in MainTabView
            Text("Plan")

        case .grow:
            GrowView()

        case .flow:
            FocusTabView()

        case .journal:
            // Placeholder - actual implementation in MainTabView
            Text("Journal")
        }
    }
}
