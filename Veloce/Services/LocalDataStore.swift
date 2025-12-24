//
//  LocalDataStore.swift
//  Veloce
//
//  Local-First Data Access Layer
//  Provides fast, synchronous access to SwiftData with caching
//

import Foundation
import SwiftData

// MARK: - Local Data Store

@MainActor
@Observable
final class LocalDataStore {
    // MARK: Singleton
    static let shared = LocalDataStore()

    // MARK: Dependencies
    private var modelContext: ModelContext?

    // MARK: Cache State
    private var taskCache: [UUID: TaskItem] = [:]
    private var goalCache: [UUID: Goal] = [:]
    private var userCache: User?
    private var cacheTimestamp: Date?

    // MARK: Configuration
    private let cacheInvalidationInterval: TimeInterval = 60 // 1 minute

    // MARK: State
    private(set) var isInitialized: Bool = false
    private(set) var lastSaveDate: Date?
    private(set) var pendingOperations: Int = 0

    // MARK: Initialization

    private init() {}

    /// Initialize with model context
    func initialize(context: ModelContext) {
        self.modelContext = context
        self.isInitialized = true
        refreshCache()
    }

    // MARK: - Cache Management

    /// Refresh all caches from SwiftData
    func refreshCache() {
        guard let context = modelContext else { return }

        do {
            // Load tasks
            let taskDescriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt, order: .reverse)]
            )
            let tasks = try context.fetch(taskDescriptor)
            taskCache = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

            // Load goals
            let goalDescriptor = FetchDescriptor<Goal>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let goals = try context.fetch(goalDescriptor)
            goalCache = Dictionary(uniqueKeysWithValues: goals.map { ($0.id, $0) })

            // Load user (if exists)
            let userDescriptor = FetchDescriptor<User>()
            userCache = try context.fetch(userDescriptor).first

            cacheTimestamp = Date()
        } catch {
            print("LocalDataStore: Cache refresh failed: \(error)")
        }
    }

    /// Invalidate cache if stale
    private func validateCache() {
        guard let timestamp = cacheTimestamp else {
            refreshCache()
            return
        }

        if Date().timeIntervalSince(timestamp) > cacheInvalidationInterval {
            refreshCache()
        }
    }

    // MARK: - Task Operations (Fast, Synchronous)

    /// Get all tasks (from cache)
    var allTasks: [TaskItem] {
        validateCache()
        return Array(taskCache.values).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Get incomplete tasks
    var incompleteTasks: [TaskItem] {
        allTasks.filter { !$0.isCompleted }
    }

    /// Get completed tasks
    var completedTasks: [TaskItem] {
        allTasks.filter { $0.isCompleted }
    }

    /// Get today's tasks
    var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allTasks.filter {
            if let scheduled = $0.scheduledTime {
                return calendar.isDate(scheduled, inSameDayAs: today)
            }
            return calendar.isDate($0.createdAt, inSameDayAs: today)
        }
    }

    /// Get task by ID (O(1) lookup)
    func task(id: UUID) -> TaskItem? {
        taskCache[id]
    }

    /// Create task locally
    @discardableResult
    func createTask(_ task: TaskItem) -> TaskItem {
        guard let context = modelContext else { return task }

        context.insert(task)
        taskCache[task.id] = task
        saveContext()
        return task
    }

    /// Update task locally
    func updateTask(_ task: TaskItem) {
        task.updatedAt = Date()
        taskCache[task.id] = task
        saveContext()
    }

    /// Delete task locally
    func deleteTask(_ task: TaskItem) {
        guard let context = modelContext else { return }

        context.delete(task)
        taskCache.removeValue(forKey: task.id)
        saveContext()
    }

    /// Delete task by ID
    func deleteTask(id: UUID) {
        guard let task = taskCache[id] else { return }
        deleteTask(task)
    }

    /// Complete task
    func completeTask(_ task: TaskItem, points: Int = 0) {
        task.isCompleted = true
        task.completedAt = Date()
        task.pointsEarned = points
        task.updatedAt = Date()
        taskCache[task.id] = task
        saveContext()
    }

    /// Uncomplete task
    func uncompleteTask(_ task: TaskItem) {
        task.isCompleted = false
        task.completedAt = nil
        task.pointsEarned = 0
        task.updatedAt = Date()
        taskCache[task.id] = task
        saveContext()
    }

    // MARK: - Goal Operations

    /// Get all goals
    var allGoals: [Goal] {
        validateCache()
        return Array(goalCache.values).sorted { $0.createdAt > $1.createdAt }
    }

    /// Get active goals
    var activeGoals: [Goal] {
        allGoals.filter { !$0.isCompleted }
    }

    /// Get goal by ID
    func goal(id: UUID) -> Goal? {
        goalCache[id]
    }

    /// Create goal locally
    @discardableResult
    func createGoal(_ goal: Goal) -> Goal {
        guard let context = modelContext else { return goal }

        context.insert(goal)
        goalCache[goal.id] = goal
        saveContext()
        return goal
    }

    /// Update goal locally
    func updateGoal(_ goal: Goal) {
        goal.updatedAt = Date()
        goalCache[goal.id] = goal
        saveContext()
    }

    /// Delete goal locally
    func deleteGoal(_ goal: Goal) {
        guard let context = modelContext else { return }

        context.delete(goal)
        goalCache.removeValue(forKey: goal.id)
        saveContext()
    }

    // MARK: - User Operations

    /// Get current user
    var currentUser: User? {
        validateCache()
        return userCache
    }

    /// Update user locally
    func updateUser(_ user: User) {
        user.updatedAt = Date()
        userCache = user
        saveContext()
    }

    // MARK: - Batch Operations

    /// Update multiple tasks efficiently
    func updateTasks(_ tasks: [TaskItem]) {
        let now = Date()
        for task in tasks {
            task.updatedAt = now
            taskCache[task.id] = task
        }
        saveContext()
    }

    /// Delete multiple tasks
    func deleteTasks(_ tasks: [TaskItem]) {
        guard let context = modelContext else { return }

        for task in tasks {
            context.delete(task)
            taskCache.removeValue(forKey: task.id)
        }
        saveContext()
    }

    /// Reorder tasks
    func reorderTasks(_ orderedTasks: [TaskItem]) {
        for (index, task) in orderedTasks.enumerated() {
            task.sortOrder = index
            task.updatedAt = Date()
            taskCache[task.id] = task
        }
        saveContext()
    }

    // MARK: - Statistics (Fast Computed)

    /// Total tasks count
    var totalTasksCount: Int { taskCache.count }

    /// Incomplete tasks count
    var incompleteTasksCount: Int { taskCache.values.filter { !$0.isCompleted }.count }

    /// Today's completed count
    var todayCompletedCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return taskCache.values.filter {
            guard $0.isCompleted, let completedAt = $0.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: today)
        }.count
    }

    /// Total points earned today
    var todayPointsEarned: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return taskCache.values
            .filter {
                guard $0.isCompleted, let completedAt = $0.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: today)
            }
            .reduce(0) { $0 + $1.pointsEarned }
    }

    // MARK: - Context Management

    /// Save context with error handling
    private func saveContext() {
        guard let context = modelContext else { return }

        pendingOperations += 1
        defer { pendingOperations -= 1 }

        do {
            try context.save()
            lastSaveDate = Date()
        } catch {
            print("LocalDataStore: Save failed: \(error)")
        }
    }

    /// Force save
    func forceSave() {
        saveContext()
    }

    /// Check if there are unsaved changes
    var hasUnsavedChanges: Bool {
        modelContext?.hasChanges ?? false
    }
}

// MARK: - Query Helpers

extension LocalDataStore {
    /// Search tasks by title
    func searchTasks(query: String) -> [TaskItem] {
        guard !query.isEmpty else { return allTasks }
        let lowercased = query.lowercased()
        return allTasks.filter {
            $0.title.lowercased().contains(lowercased) ||
            ($0.contextNotes?.lowercased().contains(lowercased) ?? false)
        }
    }

    /// Get tasks for date range
    func tasks(from startDate: Date, to endDate: Date) -> [TaskItem] {
        allTasks.filter {
            guard let scheduled = $0.scheduledTime else { return false }
            return scheduled >= startDate && scheduled <= endDate
        }
    }

    /// Get high priority tasks (star rating >= 3)
    var highPriorityTasks: [TaskItem] {
        incompleteTasks.filter { $0.starRating >= 3 }
    }

    /// Get overdue tasks
    var overdueTasks: [TaskItem] {
        let now = Date()
        return incompleteTasks.filter {
            guard let scheduled = $0.scheduledTime else { return false }
            return scheduled < now
        }
    }
}
