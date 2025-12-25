//
//  ChatTasksViewModel.swift
//  Veloce
//
//  Chat Tasks View Model
//  Manages chat-style task creation and completion
//

import Foundation
import SwiftData

// MARK: - Chat Tasks View Model

@MainActor
@Observable
final class ChatTasksViewModel: TaskActionDelegate {
    // MARK: State
    private(set) var tasks: [TaskItem] = []
    private(set) var isLoading: Bool = false

    // MARK: Services
    let gamification = GamificationService.shared
    private let haptics = HapticsService.shared

    // MARK: Context
    private var modelContext: ModelContext?

    // MARK: - Computed Properties

    /// Tasks sorted for chat view (oldest at top, newest at bottom)
    var sortedTasks: [TaskItem] {
        tasks
            .filter { !$0.isCompleted }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Recently completed tasks (last 5)
    var recentlyCompleted: [TaskItem] {
        tasks
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    /// All tasks count
    var totalCount: Int {
        tasks.count
    }

    /// Active tasks count
    var activeCount: Int {
        sortedTasks.count
    }

    // MARK: - Setup

    func setup(context: ModelContext) {
        self.modelContext = context
        loadTasks()
    }

    // MARK: - Load Tasks

    func loadTasks() {
        guard let context = modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            tasks = try context.fetch(descriptor)
        } catch {
            print("Failed to load tasks: \(error)")
            tasks = []
        }
    }

    // MARK: - Create Task

    func createTask(title: String, priority: Int = 2) async {
        guard let context = modelContext else { return }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        // Create task
        let task = TaskItem(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
        task.starRating = priority

        // Insert into context
        context.insert(task)

        // Add to local array
        tasks.append(task)

        // Save context
        do {
            try context.save()
            haptics.impact()
        } catch {
            print("Failed to save task: \(error)")
        }
    }

    // MARK: - Complete Task

    /// Complete a task and return points awarded
    func completeTask(_ task: TaskItem) -> Int {
        guard let context = modelContext else { return 0 }

        // Toggle completion
        task.isCompleted = true
        task.completedAt = Date()

        // Calculate points
        var points = DesignTokens.Gamification.taskComplete

        // Bonus for on-time completion
        if let scheduled = task.scheduledTime, Date() <= scheduled {
            points += DesignTokens.Gamification.onTimeBonus
        }

        // Priority bonus
        if task.starRating >= 3 {
            points += 5
        }

        // Award points
        _ = gamification.awardPoints(points)
        gamification.recordTaskCompletion()

        // Haptic feedback
        haptics.celebration()

        // Save
        do {
            try context.save()
        } catch {
            print("Failed to save task completion: \(error)")
        }

        return points
    }

    // MARK: - Uncomplete Task

    func uncompleteTask(_ task: TaskItem) {
        guard let context = modelContext else { return }

        task.isCompleted = false
        task.completedAt = nil

        haptics.selectionFeedback()

        do {
            try context.save()
        } catch {
            print("Failed to save task: \(error)")
        }
    }

    // MARK: - Delete Task

    func deleteTask(_ task: TaskItem) {
        guard let context = modelContext else { return }

        context.delete(task)
        tasks.removeAll { $0.id == task.id }

        haptics.impact()

        do {
            try context.save()
        } catch {
            print("Failed to delete task: \(error)")
        }
    }

    // MARK: - Update Task

    func updateTask(_ task: TaskItem, title: String? = nil, priority: Int? = nil, scheduledTime: Date? = nil) {
        guard let context = modelContext else { return }

        if let title = title {
            task.title = title
        }
        if let priority = priority {
            task.starRating = priority
        }
        if let scheduledTime = scheduledTime {
            task.scheduledTime = scheduledTime
        }

        do {
            try context.save()
        } catch {
            print("Failed to update task: \(error)")
        }
    }

    // MARK: - Toggle Completion

    func toggleCompletion(_ task: TaskItem) {
        guard let context = modelContext else { return }

        if task.isCompleted {
            // Uncomplete
            task.isCompleted = false
            task.completedAt = nil
        } else {
            // Complete
            task.isCompleted = true
            task.completedAt = Date()

            // Record gamification
            gamification.recordTaskCompletion()
        }

        haptics.selectionFeedback()

        do {
            try context.save()
        } catch {
            print("Failed to toggle completion: \(error)")
        }
    }

    // MARK: - Duplicate Task

    func duplicateTask(_ task: TaskItem) {
        guard let context = modelContext else { return }

        let duplicate = TaskItem(title: task.title + " (copy)")
        duplicate.starRating = task.starRating
        duplicate.scheduledTime = task.scheduledTime
        duplicate.duration = task.duration
        duplicate.contextNotes = task.contextNotes
        // Note: isRecurring is computed from recurringType
        duplicate.recurringType = task.recurringType
        duplicate.recurringDays = task.recurringDays

        context.insert(duplicate)
        tasks.append(duplicate)

        haptics.impact()

        do {
            try context.save()
        } catch {
            print("Failed to duplicate task: \(error)")
        }
    }

    // MARK: - Snooze Task

    func snoozeTask(_ task: TaskItem) {
        guard let context = modelContext else { return }

        // Snooze to tomorrow at 9 AM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 9
        components.minute = 0

        if let snoozeDate = Calendar.current.date(from: components) {
            task.scheduledTime = snoozeDate
            task.updatedAt = Date()
        }

        haptics.softImpact()

        do {
            try context.save()
        } catch {
            print("Failed to snooze task: \(error)")
        }
    }

    // MARK: - TaskActionDelegate Conformance

    nonisolated func taskDidComplete(_ task: TaskItem) {
        let taskId = task.persistentModelID
        Task { @MainActor in
            guard let context = self.modelContext,
                  let fetchedTask = context.model(for: taskId) as? TaskItem else { return }
            _ = completeTask(fetchedTask)
        }
    }

    nonisolated func taskDidDelete(_ task: TaskItem) {
        let taskId = task.persistentModelID
        Task { @MainActor in
            guard let context = self.modelContext,
                  let fetchedTask = context.model(for: taskId) as? TaskItem else { return }
            deleteTask(fetchedTask)
        }
    }

    nonisolated func taskDidDuplicate(_ task: TaskItem) {
        let taskId = task.persistentModelID
        Task { @MainActor in
            guard let context = self.modelContext,
                  let fetchedTask = context.model(for: taskId) as? TaskItem else { return }
            duplicateTask(fetchedTask)
        }
    }

    nonisolated func taskDidSnooze(_ task: TaskItem) {
        let taskId = task.persistentModelID
        Task { @MainActor in
            guard let context = self.modelContext,
                  let fetchedTask = context.model(for: taskId) as? TaskItem else { return }
            snoozeTask(fetchedTask)
        }
    }
}
