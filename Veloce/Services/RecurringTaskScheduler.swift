//
//  RecurringTaskScheduler.swift
//  MyTasksAI
//
//  Service for processing completed recurring tasks
//  Automatically creates next task instances when recurring tasks are completed
//

import Foundation
import SwiftData

// MARK: - Recurring Task Scheduler

@Observable
@MainActor
final class RecurringTaskScheduler {
    static let shared = RecurringTaskScheduler()

    private init() {}

    // MARK: - Process Completed Recurring Task

    /// Called when a recurring task is completed
    /// Creates the next recurring instance if applicable
    func processCompletedTask(_ task: TaskItem, in context: ModelContext) -> TaskItem? {
        guard task.canCreateNextRecurrence else { return nil }

        // Create next instance
        guard let newTask = task.createRecurringInstance() else { return nil }

        // Insert into context
        context.insert(newTask)

        return newTask
    }

    // MARK: - Check Pending Recurrences

    /// Check all completed recurring tasks and create any missing instances
    /// Call this on app launch and periodically
    func checkPendingRecurrences(in context: ModelContext) {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.isCompleted == true &&
                task.recurringType != nil &&
                task.recurringType != "once"
            }
        )

        do {
            let completedRecurringTasks = try context.fetch(descriptor)

            for task in completedRecurringTasks {
                // Check if next instance already exists
                if !hasExistingRecurrence(for: task, in: context) {
                    _ = processCompletedTask(task, in: context)
                }
            }

            try context.save()
        } catch {
            print("RecurringTaskScheduler: Error checking pending recurrences - \(error)")
        }
    }

    // MARK: - Check Existing Recurrence

    /// Check if a next recurring instance already exists for this task
    private func hasExistingRecurrence(for task: TaskItem, in context: ModelContext) -> Bool {
        let taskId = task.id
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { t in
                t.recurringParentId == taskId &&
                t.isCompleted == false
            }
        )

        do {
            let count = try context.fetchCount(descriptor)
            return count > 0
        } catch {
            return false
        }
    }

    // MARK: - Get Recurrence Chain

    /// Get all tasks in a recurring chain
    func getRecurrenceChain(for task: TaskItem, in context: ModelContext) -> [TaskItem] {
        let parentId = task.recurringParentId ?? task.id

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { t in
                t.id == parentId ||
                t.recurringParentId == parentId
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            return [task]
        }
    }

    // MARK: - Delete Recurring Chain

    /// Delete all tasks in a recurring chain
    func deleteRecurringChain(for task: TaskItem, in context: ModelContext) throws {
        let chain = getRecurrenceChain(for: task, in: context)

        for chainTask in chain {
            context.delete(chainTask)
        }

        try context.save()
    }

    // MARK: - Update Future Recurrences

    /// Update recurring settings for all future instances
    func updateFutureRecurrences(
        for task: TaskItem,
        type: RecurringTypeExtended,
        customDays: Set<Int>?,
        endDate: Date?,
        in context: ModelContext
    ) throws {
        let taskId = task.id

        // Update the current task
        task.setRecurringExtended(type: type, customDays: customDays, endDate: endDate)

        // Find and update future incomplete instances
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { t in
                t.recurringParentId == taskId &&
                t.isCompleted == false
            }
        )

        let futureInstances = try context.fetch(descriptor)

        for instance in futureInstances {
            instance.setRecurringExtended(type: type, customDays: customDays, endDate: endDate)
        }

        try context.save()
    }

    // MARK: - Statistics

    /// Get recurring task statistics
    func getRecurringStats(in context: ModelContext) -> RecurringStats {
        var activeCount = 0
        var completedInChainCount = 0
        var totalStreakDays = 0

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.recurringType != nil &&
                task.recurringType != "once"
            }
        )

        do {
            let recurringTasks = try context.fetch(descriptor)

            for task in recurringTasks {
                if !task.isCompleted {
                    activeCount += 1
                } else {
                    completedInChainCount += 1
                }
            }

            // Calculate longest streak (simplified)
            let completedTasks = recurringTasks.filter { $0.isCompleted }
            totalStreakDays = min(completedTasks.count, 30) // Cap at 30 for now

        } catch {
            print("RecurringTaskScheduler: Error getting stats - \(error)")
        }

        return RecurringStats(
            activeRecurringTasks: activeCount,
            completedInChain: completedInChainCount,
            currentStreak: totalStreakDays
        )
    }
}

// MARK: - Recurring Stats

struct RecurringStats {
    let activeRecurringTasks: Int
    let completedInChain: Int
    let currentStreak: Int
}
