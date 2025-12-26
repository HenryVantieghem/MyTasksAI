//
//  TaskCardPreloadService.swift
//  Veloce
//
//  Preload service for CelestialTaskCard ViewModels
//  Loads AI data in background for instant sheet opening
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Preload Status

enum PreloadStatus: Equatable {
    case notStarted
    case loading
    case completed
    case failed(String)

    static func == (lhs: PreloadStatus, rhs: PreloadStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted): return true
        case (.loading, .loading): return true
        case (.completed, .completed): return true
        case (.failed(let l), .failed(let r)): return l == r
        default: return false
        }
    }
}

// MARK: - Task Card Preload Service

@MainActor
@Observable
final class TaskCardPreloadService {

    // MARK: - Singleton

    static let shared = TaskCardPreloadService()

    // MARK: - Private State

    private var preloadedViewModels: [UUID: CelestialTaskCardViewModel] = [:]
    private var preloadStatus: [UUID: PreloadStatus] = [:]
    private var preloadQueue: Set<UUID> = []

    // Configuration
    private let maxCachedViewModels = 10
    private let preloadBatchSize = 3

    private init() {}

    // MARK: - Public API

    /// Preload data for a task in the background
    /// Call this when tasks appear on screen to warm up the cache
    func preload(task: TaskItem) async {
        // Skip if already loaded or loading
        guard preloadStatus[task.id] != .loading,
              preloadStatus[task.id] != .completed else {
            return
        }

        preloadStatus[task.id] = .loading

        // Create ViewModel and load data in background
        let viewModel = CelestialTaskCardViewModel(task: task)

        do {
            // Load all data with a timeout to prevent blocking
            try await withTimeout(seconds: 8) {
                await viewModel.loadAllData()
            }

            // Cache the preloaded ViewModel
            preloadedViewModels[task.id] = viewModel
            preloadStatus[task.id] = .completed

            // Clean up old entries if over limit
            cleanupOldEntries()
        } catch {
            preloadStatus[task.id] = .failed(error.localizedDescription)
            print("TaskCardPreloadService: Failed to preload task \(task.id): \(error.localizedDescription)")
        }
    }

    /// Preload multiple tasks (e.g., visible tasks in list)
    func preloadBatch(tasks: [TaskItem]) async {
        // Filter to tasks not already loaded
        let tasksToPreload = tasks.filter { task in
            preloadStatus[task.id] != .loading &&
            preloadStatus[task.id] != .completed
        }

        // Limit batch size to prevent overwhelming the system
        let batch = Array(tasksToPreload.prefix(preloadBatchSize))

        // Load in parallel with limited concurrency
        await withTaskGroup(of: Void.self) { group in
            for task in batch {
                group.addTask { [weak self] in
                    await self?.preload(task: task)
                }
            }
        }
    }

    /// Get a preloaded ViewModel if available, otherwise create a new one
    func getViewModel(for task: TaskItem) -> CelestialTaskCardViewModel {
        // Return cached ViewModel if available
        if let cached = preloadedViewModels[task.id] {
            return cached
        }

        // Create new ViewModel and trigger background load
        let viewModel = CelestialTaskCardViewModel(task: task)

        // Start loading in background
        Task {
            await viewModel.loadAllData()
            preloadedViewModels[task.id] = viewModel
            preloadStatus[task.id] = .completed
        }

        return viewModel
    }

    /// Check if a task's data is preloaded and ready
    func isPreloaded(taskId: UUID) -> Bool {
        preloadStatus[taskId] == .completed && preloadedViewModels[taskId] != nil
    }

    /// Get preload progress for a task
    func preloadProgress(for taskId: UUID) -> PreloadStatus {
        preloadStatus[taskId] ?? .notStarted
    }

    /// Clear cache for a specific task (call after task is modified)
    func invalidate(taskId: UUID) {
        preloadedViewModels.removeValue(forKey: taskId)
        preloadStatus.removeValue(forKey: taskId)
    }

    /// Clear all cached ViewModels
    func clearAll() {
        preloadedViewModels.removeAll()
        preloadStatus.removeAll()
        preloadQueue.removeAll()
    }

    // MARK: - Private Methods

    private func cleanupOldEntries() {
        guard preloadedViewModels.count > maxCachedViewModels else { return }

        // Remove oldest entries (FIFO)
        let entriesToRemove = preloadedViewModels.count - maxCachedViewModels
        let keysToRemove = Array(preloadedViewModels.keys.prefix(entriesToRemove))

        for key in keysToRemove {
            preloadedViewModels.removeValue(forKey: key)
            preloadStatus.removeValue(forKey: key)
        }
    }

    /// Execute async work with a timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw PreloadError.timeout
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Preload Error

enum PreloadError: Error, LocalizedError {
    case timeout
    case cancelled

    var errorDescription: String? {
        switch self {
        case .timeout: return "Preload operation timed out"
        case .cancelled: return "Preload operation was cancelled"
        }
    }
}

// MARK: - View Extension for Preloading

extension View {
    /// Preload task card data when this view appears
    func preloadTaskCard(_ task: TaskItem) -> some View {
        self.onAppear {
            Task {
                await TaskCardPreloadService.shared.preload(task: task)
            }
        }
    }

    /// Preload multiple task cards when this view appears
    func preloadTaskCards(_ tasks: [TaskItem]) -> some View {
        self.onAppear {
            Task {
                await TaskCardPreloadService.shared.preloadBatch(tasks: tasks)
            }
        }
    }
}
