//
//  TasksViewModel.swift
//  Veloce
//
//  Tasks View Model - Task Management
//  CRUD operations, filtering, sorting, and AI integration
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Task Filter

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case scheduled = "Scheduled"
    case completed = "Completed"

    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .today: return "sun.max"
        case .scheduled: return "calendar"
        case .completed: return "checkmark.circle"
        }
    }
}

// MARK: - Task Sort

enum TaskSort: String, CaseIterable {
    case manual = "Manual"
    case priority = "Priority"
    case dueDate = "Due Date"
    case created = "Created"

    var icon: String {
        switch self {
        case .manual: return "line.3.horizontal"
        case .priority: return "star"
        case .dueDate: return "calendar"
        case .created: return "clock"
        }
    }
}

// MARK: - Tasks View Model

@MainActor
@Observable
final class TasksViewModel {
    // MARK: State
    private(set) var tasks: [TaskItem] = []
    private(set) var isLoading: Bool = false
    private(set) var error: String?

    // MARK: Filters
    var currentFilter: TaskFilter = .all
    var currentSort: TaskSort = .manual
    var searchQuery: String = ""

    // MARK: Selection
    var selectedTask: TaskItem?

    // MARK: Services
    private let ai = AIService.shared
    let gamification = GamificationService.shared
    private let sync = SyncService.shared
    private let haptics = HapticsService.shared
    private let widget = WidgetSyncService.shared

    // MARK: Context
    private var modelContext: ModelContext?

    // MARK: Filtered Tasks
    var filteredTasks: [TaskItem] {
        var result = tasks

        // Apply filter
        switch currentFilter {
        case .all:
            result = result.filter { !$0.isCompleted }
        case .today:
            let calendar = Calendar.current
            result = result.filter { task in
                !task.isCompleted && (
                    task.scheduledTime.map { calendar.isDateInToday($0) } ?? false ||
                    calendar.isDateInToday(task.createdAt)
                )
            }
        case .scheduled:
            result = result.filter { !$0.isCompleted && $0.scheduledTime != nil }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        // Apply search
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply sort
        switch currentSort {
        case .manual:
            result = result.sorted { $0.sortOrder < $1.sortOrder }
        case .priority:
            result = result.sorted { $0.starRating > $1.starRating }
        case .dueDate:
            result = result.sorted {
                ($0.scheduledTime ?? .distantFuture) < ($1.scheduledTime ?? .distantFuture)
            }
        case .created:
            result = result.sorted { $0.createdAt > $1.createdAt }
        }

        return result
    }

    // MARK: Statistics
    var totalTasks: Int { tasks.count }
    var completedTasks: Int { tasks.filter { $0.isCompleted }.count }
    var pendingTasks: Int { tasks.filter { !$0.isCompleted }.count }
    var todayCompleted: Int {
        let calendar = Calendar.current
        return tasks.filter { task in
            task.isCompleted &&
            task.completedAt.map { calendar.isDateInToday($0) } ?? false
        }.count
    }

    // MARK: Initialization
    init() {}

    // MARK: - Setup

    func setup(context: ModelContext) {
        self.modelContext = context
        loadTasks()
    }

    // MARK: - Load Tasks

    func loadTasks() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        do {
            tasks = try context.fetch(descriptor)
            updateWidgets()
        } catch {
            self.error = error.localizedDescription
            tasks = []
        }
    }

    // MARK: - Create Task

    func createTask(title: String, processWithAI: Bool = true) {
        guard let context = modelContext else { return }

        let task = TaskItem(
            title: title,
            userId: SupabaseService.shared.currentUserId ?? UUID()
        )

        // Set sort order
        task.sortOrder = (tasks.map(\.sortOrder).max() ?? 0) + 1

        context.insert(task)
        tasks.append(task)

        do {
            try context.save()
            haptics.impact()

            // Process with AI in background
            if processWithAI && ai.isConfigured {
                Task {
                    await processTaskWithAI(task)
                }
            }

            // Sync to remote
            Task {
                try? await sync.syncTask(task)
            }

            updateWidgets()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Add an existing TaskItem
    func addTaskItem(_ task: TaskItem) {
        guard let context = modelContext else { return }

        task.sortOrder = (tasks.map(\.sortOrder).max() ?? 0) + 1
        context.insert(task)
        tasks.append(task)

        do {
            try context.save()
            updateWidgets()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Update Task

    func updateTask(_ task: TaskItem) {
        task.updatedAt = Date()

        do {
            try modelContext?.save()

            // Sync to remote
            Task {
                try? await sync.syncTask(task)
            }

            updateWidgets()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Toggle Completion

    func toggleCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.updatedAt = Date()

        if task.isCompleted {
            task.completedAt = Date()

            // Calculate and award points
            let points = gamification.calculatePoints(for: task)
            task.pointsEarned = points
            gamification.recordTaskCompletion()
            _ = gamification.awardPoints(points)

            haptics.taskComplete()

            // Check pact progress for task-based pacts
            Task {
                await checkPactProgress()
            }
        } else {
            task.completedAt = nil
            task.pointsEarned = 0
        }

        do {
            try modelContext?.save()

            // Sync to remote
            Task {
                try? await sync.syncTask(task)
            }

            updateWidgets()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Pact Progress

    /// Check and update pact progress based on tasks completed today
    private func checkPactProgress() async {
        let completedToday = todayCompleted
        await PactService.shared.checkTaskPactProgress(tasksCompletedToday: completedToday)
    }

    // MARK: - Delete Task

    func deleteTask(_ task: TaskItem) {
        guard let context = modelContext else { return }

        let taskId = task.id
        context.delete(task)
        tasks.removeAll { $0.id == taskId }

        do {
            try context.save()

            // Delete from remote
            Task {
                try? await sync.deleteTask(taskId)
            }

            updateWidgets()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Delete tasks at offsets
    func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = filteredTasks[index]
            deleteTask(task)
        }
    }

    // MARK: - Reorder Tasks

    func moveTasks(from source: IndexSet, to destination: Int) {
        var reorderedTasks = filteredTasks
        reorderedTasks.move(fromOffsets: source, toOffset: destination)

        // Update sort orders
        for (index, task) in reorderedTasks.enumerated() {
            task.sortOrder = index
        }

        try? modelContext?.save()
        loadTasks()
    }

    // MARK: - Task Actions

    /// Duplicate a task
    func duplicateTask(_ task: TaskItem) {
        guard let context = modelContext else { return }

        let duplicate = TaskItem(
            title: "\(task.title) (copy)",
            estimatedMinutes: task.estimatedMinutes,
            scheduledTime: task.scheduledTime,
            contextNotes: task.contextNotes,
            category: task.category,
            starRating: task.starRating
        )

        context.insert(duplicate)
        tasks.insert(duplicate, at: 0)

        do {
            try context.save()
            haptics.impact()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Snooze a task to tomorrow
    func snoozeTask(_ task: TaskItem) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        task.scheduledTime = Calendar.current.startOfDay(for: tomorrow).addingTimeInterval(9 * 3600) // 9 AM
        task.updatedAt = Date()

        try? modelContext?.save()
        haptics.softImpact()
    }

    /// Reprocess AI for a task
    func reprocessAI(for task: TaskItem) {
        Task {
            await processTaskWithAI(task)
        }
    }

    // MARK: - AI Processing

    func processTaskWithAI(_ task: TaskItem) async {
        guard ai.isConfigured else { return }

        do {
            let advice = try await ai.processTask(task)

            // Update task with AI data
            task.aiAdvice = advice.advice
            task.aiPriority = advice.priority
            task.estimatedMinutes = advice.estimatedMinutes
            task.aiThoughtProcess = advice.thoughtProcess
            task.aiSources = advice.sources
            task.aiProcessedAt = Date()
            task.updatedAt = Date()

            try modelContext?.save()

            // Sync to remote
            try? await sync.syncTask(task)
        } catch {
            print("AI processing failed: \(error)")
        }
    }

    /// Generate sub-tasks for a task
    func generateSubTasks(for task: TaskItem) async throws -> [SubTask] {
        let result = try await ai.generateSubTasks(for: task)
        return result.subTasks
    }

    // MARK: - Brain Dump

    func processBrainDump(_ text: String) async throws -> [TaskItem] {
        let parsedTasks = try await ai.processBrainDump(text)

        var createdTasks: [TaskItem] = []

        for parsed in parsedTasks {
            let task = TaskItem(
                title: parsed.title,
                userId: SupabaseService.shared.currentUserId ?? UUID()
            )

            task.aiPriority = parsed.priority
            task.estimatedMinutes = parsed.estimatedMinutes
            task.sortOrder = (tasks.map(\.sortOrder).max() ?? 0) + 1

            modelContext?.insert(task)
            tasks.append(task)
            createdTasks.append(task)
        }

        try modelContext?.save()
        updateWidgets()

        return createdTasks
    }

    // MARK: - Star Rating (Sam Altman Style)

    func setStarRating(_ task: TaskItem, rating: Int) {
        task.starRating = min(max(rating, 1), 3)
        task.updatedAt = Date()

        try? modelContext?.save()
        haptics.selectionFeedback()

        Task {
            try? await sync.syncTask(task)
        }
    }

    // MARK: - Helpers

    private func updateWidgets() {
        let incompleteTasks = tasks.filter { !$0.isCompleted }
        widget.shareTasks(incompleteTasks)

        widget.shareStats(
            tasksCompletedToday: todayCompleted,
            dailyGoal: gamification.dailyGoal,
            currentStreak: gamification.currentStreak,
            totalPoints: gamification.totalPoints,
            currentLevel: gamification.currentLevel
        )
    }

    func clearError() {
        error = nil
    }
}
