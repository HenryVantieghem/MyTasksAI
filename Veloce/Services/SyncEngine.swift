//
//  SyncEngine.swift
//  Veloce
//
//  Robust Sync Engine with Offline Queue
//  Handles sync operations with retry, conflict resolution, and persistence
//

import Foundation
import SwiftData
import Combine

// MARK: - Sync Operation

struct SyncOperation: Codable, Identifiable {
    let id: UUID
    let type: OperationType
    let entityType: EntityType
    let entityId: UUID
    let payload: Data?
    let createdAt: Date
    var attempts: Int
    var lastAttempt: Date?
    var lastError: String?

    enum OperationType: String, Codable {
        case create
        case update
        case delete
    }

    enum EntityType: String, Codable {
        case task
        case goal
        case achievement
        case user
        case streak
    }

    init(
        type: OperationType,
        entityType: EntityType,
        entityId: UUID,
        payload: Data? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.entityType = entityType
        self.entityId = entityId
        self.payload = payload
        self.createdAt = Date()
        self.attempts = 0
        self.lastAttempt = nil
        self.lastError = nil
    }
}

// MARK: - Sync State

enum SyncState: Equatable {
    case idle
    case syncing(progress: Double)
    case success(syncedCount: Int)
    case error(message: String)
    case offline

    var isActive: Bool {
        if case .syncing = self { return true }
        return false
    }

    var displayText: String {
        switch self {
        case .idle:
            return "Ready to sync"
        case .syncing(let progress):
            return "Syncing... \(Int(progress * 100))%"
        case .success(let count):
            return count > 0 ? "Synced \(count) items" : "All synced"
        case .error(let message):
            return message
        case .offline:
            return "Offline mode"
        }
    }
}

// MARK: - Sync Engine

@MainActor
@Observable
final class SyncEngine {
    // MARK: Singleton
    static let shared = SyncEngine()

    // MARK: Dependencies
    private let supabase = SupabaseService.shared
    private let offlineManager = OfflineManager.shared
    private let localStore = LocalDataStore.shared

    // MARK: State
    private(set) var syncState: SyncState = .idle
    private(set) var pendingOperations: [SyncOperation] = []
    private(set) var lastSuccessfulSync: Date?
    private(set) var syncProgress: Double = 0
    private(set) var failedOperationsCount: Int = 0

    // MARK: Configuration
    private let maxRetryAttempts = 5
    private let retryDelays: [TimeInterval] = [1, 2, 5, 10, 30] // Exponential backoff
    private let batchSize = 20
    private let syncDebounce: TimeInterval = 2.0
    private let queuePersistenceKey = "veloce.sync.pendingQueue"

    // MARK: Internal State
    private var syncTask: Task<Void, Never>?
    private var debouncedSyncTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?

    // MARK: Initialization

    private init() {
        loadPendingQueue()
        setupNetworkObserver()
    }

    /// Initialize with model context
    func initialize(context: ModelContext) {
        self.modelContext = context
        localStore.initialize(context: context)
    }

    // MARK: - Network Observer

    private func setupNetworkObserver() {
        offlineManager.onConnectionRestored = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.processPendingQueue()
            }
        }

        offlineManager.onConnectionLost = { [weak self] in
            Task { @MainActor [weak self] in
                self?.syncState = .offline
            }
        }

        // Update state based on current connection
        if offlineManager.isOffline {
            syncState = .offline
        }
    }

    // MARK: - Queue Persistence

    private func loadPendingQueue() {
        guard let data = UserDefaults.standard.data(forKey: queuePersistenceKey),
              let operations = try? JSONDecoder().decode([SyncOperation].self, from: data) else {
            return
        }
        pendingOperations = operations
    }

    private func savePendingQueue() {
        guard let data = try? JSONEncoder().encode(pendingOperations) else { return }
        UserDefaults.standard.set(data, forKey: queuePersistenceKey)
    }

    // MARK: - Queue Operations

    /// Add operation to sync queue
    func enqueue(_ operation: SyncOperation) {
        // Remove duplicate operations for same entity
        pendingOperations.removeAll {
            $0.entityType == operation.entityType && $0.entityId == operation.entityId
        }
        pendingOperations.append(operation)
        savePendingQueue()

        // Trigger debounced sync
        scheduleDebouncedSync()
    }

    /// Queue task creation
    func queueTaskCreate(_ task: TaskItem, userId: UUID) {
        if let payload = try? JSONEncoder().encode(task.toSupabase(userId: userId)) {
            let operation = SyncOperation(
                type: .create,
                entityType: .task,
                entityId: task.id,
                payload: payload
            )
            enqueue(operation)
        }
    }

    /// Queue task update
    func queueTaskUpdate(_ task: TaskItem, userId: UUID) {
        if let payload = try? JSONEncoder().encode(task.toSupabase(userId: userId)) {
            let operation = SyncOperation(
                type: .update,
                entityType: .task,
                entityId: task.id,
                payload: payload
            )
            enqueue(operation)
        }
    }

    /// Queue task deletion
    func queueTaskDelete(taskId: UUID) {
        let operation = SyncOperation(
            type: .delete,
            entityType: .task,
            entityId: taskId
        )
        enqueue(operation)
    }

    /// Queue goal operations
    func queueGoalCreate(_ goal: Goal, userId: UUID) {
        if let payload = try? JSONEncoder().encode(goal.toSupabase(userId: userId)) {
            let operation = SyncOperation(
                type: .create,
                entityType: .goal,
                entityId: goal.id,
                payload: payload
            )
            enqueue(operation)
        }
    }

    func queueGoalUpdate(_ goal: Goal, userId: UUID) {
        if let payload = try? JSONEncoder().encode(goal.toSupabase(userId: userId)) {
            let operation = SyncOperation(
                type: .update,
                entityType: .goal,
                entityId: goal.id,
                payload: payload
            )
            enqueue(operation)
        }
    }

    func queueGoalDelete(goalId: UUID) {
        let operation = SyncOperation(
            type: .delete,
            entityType: .goal,
            entityId: goalId
        )
        enqueue(operation)
    }

    // MARK: - Debounced Sync

    private func scheduleDebouncedSync() {
        debouncedSyncTask?.cancel()
        debouncedSyncTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(syncDebounce * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await processPendingQueue()
        }
    }

    // MARK: - Process Queue

    /// Process all pending operations
    func processPendingQueue() async {
        guard offlineManager.isOnline else {
            syncState = .offline
            return
        }

        guard !pendingOperations.isEmpty else {
            syncState = .idle
            return
        }

        guard !syncState.isActive else { return }

        syncState = .syncing(progress: 0)
        var successCount = 0
        var failedCount = 0

        let operations = pendingOperations
        let total = operations.count

        for (index, operation) in operations.enumerated() {
            guard offlineManager.isOnline else {
                syncState = .offline
                return
            }

            syncProgress = Double(index) / Double(total)
            syncState = .syncing(progress: syncProgress)

            let success = await executeOperation(operation)

            if success {
                successCount += 1
                // Remove from queue
                pendingOperations.removeAll { $0.id == operation.id }
            } else {
                failedCount += 1
                // Update attempt count
                if let idx = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
                    pendingOperations[idx].attempts += 1
                    pendingOperations[idx].lastAttempt = Date()

                    // Remove if max retries exceeded
                    if pendingOperations[idx].attempts >= maxRetryAttempts {
                        pendingOperations.remove(at: idx)
                    }
                }
            }
        }

        savePendingQueue()
        failedOperationsCount = failedCount

        if failedCount > 0 {
            syncState = .error(message: "\(failedCount) operations failed")
        } else {
            syncState = .success(syncedCount: successCount)
            lastSuccessfulSync = Date()
        }

        // Reset to idle after delay
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .success = self.syncState {
                self.syncState = .idle
            }
        }
    }

    // MARK: - Execute Operation

    private func executeOperation(_ operation: SyncOperation) async -> Bool {
        do {
            switch operation.entityType {
            case .task:
                return try await executeTaskOperation(operation)
            case .goal:
                return try await executeGoalOperation(operation)
            case .achievement:
                return try await executeAchievementOperation(operation)
            case .user:
                return try await executeUserOperation(operation)
            case .streak:
                return try await executeStreakOperation(operation)
            }
        } catch {
            print("SyncEngine: Operation failed: \(error)")
            return false
        }
    }

    private func executeTaskOperation(_ operation: SyncOperation) async throws -> Bool {
        switch operation.type {
        case .create, .update:
            guard let payload = operation.payload,
                  let task = try? JSONDecoder().decode(SupabaseTask.self, from: payload) else {
                return false
            }
            try await supabase.syncTasks([task])
            return true

        case .delete:
            try await supabase.deleteTask(id: operation.entityId)
            return true
        }
    }

    private func executeGoalOperation(_ operation: SyncOperation) async throws -> Bool {
        switch operation.type {
        case .create:
            guard let payload = operation.payload,
                  let goal = try? JSONDecoder().decode(SupabaseGoal.self, from: payload) else {
                return false
            }
            _ = try await supabase.createGoal(goal)
            return true

        case .update:
            guard let payload = operation.payload,
                  let goal = try? JSONDecoder().decode(SupabaseGoal.self, from: payload) else {
                return false
            }
            try await supabase.updateGoal(goal)
            return true

        case .delete:
            try await supabase.deleteGoal(id: operation.entityId)
            return true
        }
    }

    private func executeAchievementOperation(_ operation: SyncOperation) async throws -> Bool {
        // Achievements are typically created server-side
        return true
    }

    private func executeUserOperation(_ operation: SyncOperation) async throws -> Bool {
        guard let payload = operation.payload,
              let user = try? JSONDecoder().decode(SupabaseUser.self, from: payload) else {
            return false
        }
        try await supabase.upsertUser(user)
        return true
    }

    private func executeStreakOperation(_ operation: SyncOperation) async throws -> Bool {
        // Streaks are handled separately
        return true
    }

    // MARK: - Full Sync

    /// Perform full bidirectional sync
    func performFullSync() async {
        guard let context = modelContext else { return }
        guard offlineManager.isOnline else {
            syncState = .offline
            return
        }

        syncState = .syncing(progress: 0)

        do {
            // First, process pending queue
            await processPendingQueue()

            // Then pull remote changes
            syncState = .syncing(progress: 0.3)
            try await syncTasks(context: context)

            syncState = .syncing(progress: 0.6)
            try await syncGoals(context: context)

            syncState = .syncing(progress: 0.9)
            try await syncAchievements(context: context)

            // Refresh local cache
            localStore.refreshCache()

            syncState = .success(syncedCount: 0)
            lastSuccessfulSync = Date()

        } catch {
            syncState = .error(message: error.localizedDescription)
        }

        // Reset to idle after delay
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .success = self.syncState {
                self.syncState = .idle
            }
        }
    }

    // MARK: - Entity Sync (Pull)

    private func syncTasks(context: ModelContext) async throws {
        let remoteTasks = try await supabase.fetchTasks()

        let descriptor = FetchDescriptor<TaskItem>()
        let localTasks = try context.fetch(descriptor)

        let remoteById = Dictionary(uniqueKeysWithValues: remoteTasks.map { ($0.id, $0) })
        let localById = Dictionary(uniqueKeysWithValues: localTasks.map { ($0.id, $0) })

        // Download remote tasks (if newer)
        for remoteTask in remoteTasks {
            if let localTask = localById[remoteTask.id] {
                let remoteUpdated = remoteTask.updatedAt ?? .distantPast
                if remoteUpdated > localTask.updatedAt {
                    updateLocalTask(localTask, from: remoteTask)
                }
            } else {
                // New remote task
                let newTask = TaskItem(from: remoteTask)
                context.insert(newTask)
            }
        }

        try context.save()
    }

    private func syncGoals(context: ModelContext) async throws {
        let remoteGoals = try await supabase.fetchGoals()

        let descriptor = FetchDescriptor<Goal>()
        let localGoals = try context.fetch(descriptor)

        let remoteById = Dictionary(uniqueKeysWithValues: remoteGoals.map { ($0.id, $0) })
        let localById = Dictionary(uniqueKeysWithValues: localGoals.map { ($0.id, $0) })

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

        try context.save()
    }

    private func syncAchievements(context: ModelContext) async throws {
        let remoteAchievements = try await supabase.fetchAchievements()

        let descriptor = FetchDescriptor<Achievement>()
        let localAchievements = try context.fetch(descriptor)

        let localTypes = Set(localAchievements.map { $0.type })

        for remoteAchievement in remoteAchievements {
            if !localTypes.contains(remoteAchievement.type) {
                let newAchievement = Achievement(type: remoteAchievement.type)
                newAchievement.unlockedAt = remoteAchievement.unlockedAt
                context.insert(newAchievement)
            }
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
        local.scheduledTime = remote.scheduledTime
        local.duration = remote.duration
        local.pointsEarned = remote.pointsEarned ?? 0
        local.sortOrder = remote.sortOrder ?? 0
        local.contextNotes = remote.contextNotes
        local.starRating = remote.starRating ?? 2
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
        local.updatedAt = remote.updatedAt ?? .now
    }

    // MARK: - Utility

    /// Get retry delay for attempt number
    func retryDelay(for attempt: Int) -> TimeInterval {
        guard attempt < retryDelays.count else { return retryDelays.last ?? 30 }
        return retryDelays[attempt]
    }

    /// Clear pending queue (use with caution)
    func clearPendingQueue() {
        pendingOperations.removeAll()
        savePendingQueue()
        failedOperationsCount = 0
    }

    /// Get pending count
    var pendingCount: Int { pendingOperations.count }

    /// Check if sync is needed
    var needsSync: Bool {
        !pendingOperations.isEmpty || (lastSuccessfulSync == nil)
    }
}
