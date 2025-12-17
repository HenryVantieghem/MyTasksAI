//
//  SyncService.swift
//  Veloce
//
//  Sync Service - Local/Remote Data Synchronization
//  Handles bidirectional sync between SwiftData and Supabase
//

import Foundation
import SwiftData

// MARK: - Sync Service

@MainActor
@Observable
final class SyncService {
    // MARK: Singleton
    static let shared = SyncService()

    // MARK: Dependencies
    private let supabase = SupabaseService.shared

    // MARK: State
    private(set) var isSyncing: Bool = false
    private(set) var lastSyncDate: Date?
    private(set) var syncError: String?
    private(set) var pendingChanges: Int = 0

    // MARK: Configuration
    private let syncDebounceInterval: TimeInterval = 2.0
    private var syncTask: Task<Void, Never>?

    // MARK: Initialization
    private init() {}

    // MARK: - Full Sync

    /// Perform full sync with server
    func performFullSync(context: ModelContext) async {
        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        defer {
            isSyncing = false
            lastSyncDate = Date()
        }

        do {
            // Sync tasks
            try await syncTasks(context: context)

            // Sync goals
            try await syncGoals(context: context)

            // Sync achievements
            try await syncAchievements(context: context)

            // Sync user profile
            try await syncUserProfile(context: context)

        } catch {
            syncError = error.localizedDescription
            print("Sync failed: \(error)")
        }
    }

    // MARK: - Task Sync

    /// Sync tasks between local and remote
    private func syncTasks(context: ModelContext) async throws {
        // Fetch remote tasks
        let remoteTasks = try await supabase.fetchTasks()

        // Fetch local tasks
        let descriptor = FetchDescriptor<TaskItem>()
        let localTasks = try context.fetch(descriptor)

        // Create lookup maps
        let remoteById = Dictionary(uniqueKeysWithValues: remoteTasks.map { ($0.id, $0) })
        let localById = Dictionary(uniqueKeysWithValues: localTasks.map { ($0.id, $0) })

        // Get current user ID for uploads
        guard let userId = await supabase.getCurrentUserId() else { return }

        // Process remote tasks (download)
        for remoteTask in remoteTasks {
            if let localTask = localById[remoteTask.id] {
                // Update local if remote is newer
                let remoteUpdated = remoteTask.updatedAt ?? .distantPast
                if remoteUpdated > localTask.updatedAt {
                    updateLocalTask(localTask, from: remoteTask)
                }
            } else {
                // Create new local task
                let newTask = TaskItem(from: remoteTask)
                context.insert(newTask)
            }
        }

        // Process local tasks (upload)
        var tasksToUpload: [SupabaseTask] = []

        for localTask in localTasks {
            if let remoteTask = remoteById[localTask.id] {
                // Upload if local is newer
                let remoteUpdated = remoteTask.updatedAt ?? .distantPast
                if localTask.updatedAt > remoteUpdated {
                    tasksToUpload.append(localTask.toSupabase(userId: userId))
                }
            } else {
                // New local task - upload
                tasksToUpload.append(localTask.toSupabase(userId: userId))
            }
        }

        // Batch upload
        if !tasksToUpload.isEmpty {
            try await supabase.syncTasks(tasksToUpload)
        }

        try context.save()
    }

    /// Sync goals
    private func syncGoals(context: ModelContext) async throws {
        let remoteGoals = try await supabase.fetchGoals()

        let descriptor = FetchDescriptor<Goal>()
        let localGoals = try context.fetch(descriptor)

        // Get current user ID for uploads
        guard let userId = await supabase.getCurrentUserId() else { return }

        let remoteById = Dictionary(uniqueKeysWithValues: remoteGoals.map { ($0.id, $0) })
        let localById = Dictionary(uniqueKeysWithValues: localGoals.map { ($0.id, $0) })

        // Download remote goals
        for remoteGoal in remoteGoals {
            if let localGoal = localById[remoteGoal.id] {
                let remoteUpdated = remoteGoal.updatedAt ?? .distantPast
                if remoteUpdated > localGoal.updatedAt {
                    updateLocalGoal(localGoal, from: remoteGoal)
                }
            } else {
                let newGoal = Goal(from: remoteGoal)
                context.insert(newGoal)
            }
        }

        // Upload local goals
        for localGoal in localGoals {
            if remoteById[localGoal.id] == nil {
                _ = try await supabase.createGoal(localGoal.toSupabase(userId: userId))
            }
        }

        try context.save()
    }

    /// Sync achievements
    private func syncAchievements(context: ModelContext) async throws {
        let remoteAchievements = try await supabase.fetchAchievements()

        let descriptor = FetchDescriptor<Achievement>()
        let localAchievements = try context.fetch(descriptor)

        let localTypeStrings = Set(localAchievements.map { $0.type })

        // Download new achievements
        for remoteAchievement in remoteAchievements {
            if !localTypeStrings.contains(remoteAchievement.type) {
                let newAchievement = Achievement(type: remoteAchievement.type)
                newAchievement.unlockedAt = remoteAchievement.unlockedAt
                context.insert(newAchievement)
            }
        }

        try context.save()
    }

    /// Sync user profile
    private func syncUserProfile(context: ModelContext) async throws {
        guard let userId = await supabase.getCurrentUserId() else { return }

        let remoteUser = try await supabase.fetchUser(id: userId)

        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userId }
        )
        let localUsers = try context.fetch(descriptor)

        if let localUser = localUsers.first {
            // Update local from remote
            updateLocalUser(localUser, from: remoteUser)
        } else {
            // Create local user
            let newUser = User(from: remoteUser)
            context.insert(newUser)
        }

        try context.save()
    }

    // MARK: - Update Helpers

    private func updateLocalTask(_ local: TaskItem, from remote: SupabaseTask) {
        local.title = remote.title
        local.isCompleted = remote.isCompleted
        local.completedAt = remote.completedAt
        local.aiAdvice = remote.aiAdvice
        local.estimatedMinutes = remote.estimatedMinutes
        local.aiPriority = remote.aiPriority
        local.aiProcessedAt = remote.aiProcessedAt
        local.aiSources = remote.aiSources
        local.aiThoughtProcess = remote.aiThoughtProcess
        local.scheduledTime = remote.scheduledTime
        local.duration = remote.duration
        local.reminderEnabled = remote.reminderEnabled
        local.calendarEventId = remote.calendarEventId
        local.pointsEarned = remote.pointsEarned ?? 0
        local.completedOnTime = remote.completedOnTime
        local.sortOrder = remote.sortOrder ?? 0
        local.contextNotes = remote.contextNotes
        local.starRating = remote.starRating ?? 2
        local.actualMinutes = remote.actualMinutes
        local.updatedAt = remote.updatedAt ?? .now
    }

    private func updateLocalGoal(_ local: Goal, from remote: SupabaseGoal) {
        local.title = remote.title
        local.goalDescription = remote.description
        local.targetDate = remote.targetDate
        local.category = remote.category
        local.isCompleted = remote.isCompleted ?? false
        local.progress = remote.progress ?? 0
        local.completedAt = remote.completedAt
        local.isSpecific = remote.isSpecific ?? false
        local.isMeasurable = remote.isMeasurable ?? false
        local.isAchievable = remote.isAchievable ?? false
        local.isRelevant = remote.isRelevant ?? false
        local.isTimeBound = remote.isTimeBound ?? false
        local.updatedAt = remote.updatedAt ?? .now
    }

    private func updateLocalUser(_ local: User, from remote: SupabaseUser) {
        local.email = remote.email
        local.fullName = remote.fullName
        local.avatarUrl = remote.avatarUrl
        local.totalPoints = remote.totalPoints ?? 0
        local.currentLevel = remote.currentLevel ?? 1
        local.currentStreak = remote.currentStreak ?? 0
        local.longestStreak = remote.longestStreak ?? 0
        local.tasksCompleted = remote.tasksCompleted ?? 0
        local.tasksCompletedOnTime = remote.tasksCompletedOnTime ?? 0
        local.dailyTaskGoal = remote.dailyTaskGoal ?? 5
        local.weeklyTaskGoal = remote.weeklyTaskGoal ?? 25
        local.notificationsEnabled = remote.notificationsEnabled ?? true
        local.calendarSyncEnabled = remote.calendarSyncEnabled ?? false
        local.hapticsEnabled = remote.hapticsEnabled ?? true
        local.theme = remote.theme ?? "auto"
        local.updatedAt = remote.updatedAt ?? .now
    }

    // MARK: - Debounced Sync

    /// Queue a sync (debounced)
    func queueSync(context: ModelContext) {
        pendingChanges += 1

        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(syncDebounceInterval * 1_000_000_000))

            if !Task.isCancelled {
                await performFullSync(context: context)
                pendingChanges = 0
            }
        }
    }

    // MARK: - Single Item Sync

    /// Sync single task to remote
    func syncTask(_ task: TaskItem) async throws {
        guard let userId = await supabase.getCurrentUserId() else { return }
        try await supabase.updateTask(task.toSupabase(userId: userId))
    }

    /// Sync single goal to remote
    func syncGoal(_ goal: Goal) async throws {
        guard let userId = await supabase.getCurrentUserId() else { return }
        try await supabase.updateGoal(goal.toSupabase(userId: userId))
    }

    /// Delete task from remote
    func deleteTask(_ taskId: UUID) async throws {
        try await supabase.deleteTask(id: taskId)
    }

    /// Delete goal from remote
    func deleteGoal(_ goalId: UUID) async throws {
        try await supabase.deleteGoal(id: goalId)
    }
}

// MARK: - Sync Error

enum SyncError: Error, LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case conflictError
    case dataCorruption

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .conflictError:
            return "Data conflict detected"
        case .dataCorruption:
            return "Data corruption detected"
        }
    }
}
