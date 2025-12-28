//
//  TasksKanbanView.swift
//  Veloce
//
//  Horizontal Scrolling Kanban Board for Tasks
//  Features: 3 columns (In Progress, To Do, Done), drag-and-drop reordering
//

import SwiftUI

// MARK: - Tasks Kanban View

struct TasksKanbanView: View {
    @Binding var tasks: [TaskItem]
    let onTaskTap: (TaskItem) -> Void
    let onToggleComplete: (TaskItem) -> Void
    var onStartFocus: ((TaskItem, Int) -> Void)?
    var onSnooze: ((TaskItem) -> Void)?
    var onDelete: ((TaskItem) -> Void)?

    @Environment(\.responsiveLayout) private var layout
    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: - Computed Properties

    private var inProgressTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted && $0.isInProgress }
    }

    private var toDoTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted && !$0.isInProgress }
    }

    private var doneTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
    }

    private func tasksForSection(_ section: TaskSection) -> [TaskItem] {
        switch section {
        case .inProgress: return inProgressTasks
        case .toDo: return toDoTasks
        case .done: return doneTasks
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: layout.spacing * 1.5) {
                ForEach(TaskSection.allCases) { section in
                    KanbanColumnView(
                        section: section,
                        tasks: tasksForSection(section),
                        onTaskTap: onTaskTap,
                        onToggleComplete: onToggleComplete,
                        onTaskDrop: handleTaskDrop,
                        onStartFocus: onStartFocus,
                        onSnooze: onSnooze,
                        onDelete: onDelete
                    )
                }
            }
            .padding(.horizontal, layout.cardPadding)
            .padding(.top, layout.spacing)
        }
        .scrollTargetBehavior(.viewAligned)
    }

    // MARK: - Handle Task Drop

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
                task.isCompleted = true
                task.isInProgress = false
            }
        }
    }
}

// MARK: - TaskItem Extension for In Progress

extension TaskItem {
    /// Tracks if task is actively being worked on
    /// This can be stored in UserDefaults or as a transient property
    var isInProgress: Bool {
        get {
            UserDefaults.standard.bool(forKey: "task_inProgress_\(id.uuidString)")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "task_inProgress_\(id.uuidString)")
        }
    }
}

// MARK: - Preview

#Preview("Kanban View") {
    struct PreviewContainer: View {
        @State private var tasks: [TaskItem] = {
            var tasks: [TaskItem] = []

            // In Progress tasks
            let ip1 = TaskItem(title: "Design system updates")
            ip1.estimatedMinutes = 60
            ip1.starRating = 3
            ip1.isInProgress = true
            tasks.append(ip1)

            // To Do tasks
            let td1 = TaskItem(title: "Review pull requests")
            td1.estimatedMinutes = 30
            td1.starRating = 2
            tasks.append(td1)

            let td2 = TaskItem(title: "Write documentation")
            td2.estimatedMinutes = 45
            td2.starRating = 1
            tasks.append(td2)

            let td3 = TaskItem(title: "Team sync meeting")
            td3.estimatedMinutes = 25
            td3.starRating = 2
            td3.scheduledTime = Date().addingTimeInterval(3600)
            tasks.append(td3)

            // Done tasks
            let d1 = TaskItem(title: "Morning standup")
            d1.estimatedMinutes = 15
            d1.isCompleted = true
            tasks.append(d1)

            return tasks
        }()

        var body: some View {
            TasksKanbanView(
                tasks: $tasks,
                onTaskTap: { _ in },
                onToggleComplete: { task in
                    task.isCompleted.toggle()
                },
                onStartFocus: { _, _ in },
                onSnooze: { _ in },
                onDelete: { _ in }
            )
            .frame(maxHeight: .infinity)
            .background(Theme.CelestialColors.void.ignoresSafeArea())
        }
    }

    return PreviewContainer()
        .preferredColorScheme(.dark)
}
