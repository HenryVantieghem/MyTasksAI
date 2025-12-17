//
//  AIProcessingQueue.swift
//  Veloce
//
//  AI Processing Queue - Background Task Processing
//  Manages queue of tasks waiting for AI processing
//

import Foundation

// MARK: - AI Processing Queue

@MainActor
@Observable
final class AIProcessingQueue {
    // MARK: Singleton
    static let shared = AIProcessingQueue()

    // MARK: State
    private(set) var isProcessing: Bool = false
    private(set) var pendingCount: Int = 0
    private(set) var processedCount: Int = 0
    private(set) var failedCount: Int = 0

    // MARK: Queue
    private var highPriorityQueue: [QueueItem] = []
    private var normalQueue: [QueueItem] = []
    private var lowPriorityQueue: [QueueItem] = []

    // MARK: Configuration
    private let maxConcurrent = 3
    private let maxQueueSize = 100
    private var activeCount = 0

    // MARK: Initialization
    private init() {}

    // MARK: - Priority

    enum Priority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Queue Item

    struct QueueItem: Identifiable, Equatable {
        let id: UUID
        let taskId: UUID
        let priority: Priority
        let addedAt: Date
        var attempts: Int = 0

        static func == (lhs: QueueItem, rhs: QueueItem) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - Queue Operations

    /// Add task to processing queue
    func enqueue(taskId: UUID, priority: Priority = .normal) {
        guard totalCount < maxQueueSize else {
            print("Queue full, rejecting task: \(taskId)")
            return
        }

        let item = QueueItem(
            id: UUID(),
            taskId: taskId,
            priority: priority,
            addedAt: Date()
        )

        switch priority {
        case .high:
            highPriorityQueue.append(item)
        case .normal:
            normalQueue.append(item)
        case .low:
            lowPriorityQueue.append(item)
        }

        updatePendingCount()
    }

    /// Remove task from queue
    func dequeue(taskId: UUID) {
        highPriorityQueue.removeAll { $0.taskId == taskId }
        normalQueue.removeAll { $0.taskId == taskId }
        lowPriorityQueue.removeAll { $0.taskId == taskId }
        updatePendingCount()
    }

    /// Get next item to process (respects priority)
    func getNext() -> QueueItem? {
        if let item = highPriorityQueue.first {
            highPriorityQueue.removeFirst()
            updatePendingCount()
            return item
        }

        if let item = normalQueue.first {
            normalQueue.removeFirst()
            updatePendingCount()
            return item
        }

        if let item = lowPriorityQueue.first {
            lowPriorityQueue.removeFirst()
            updatePendingCount()
            return item
        }

        return nil
    }

    /// Check if task is in queue
    func isQueued(taskId: UUID) -> Bool {
        highPriorityQueue.contains { $0.taskId == taskId } ||
        normalQueue.contains { $0.taskId == taskId } ||
        lowPriorityQueue.contains { $0.taskId == taskId }
    }

    /// Get position of task in queue
    func position(of taskId: UUID) -> Int? {
        var position = 0

        for item in highPriorityQueue {
            if item.taskId == taskId { return position }
            position += 1
        }

        for item in normalQueue {
            if item.taskId == taskId { return position }
            position += 1
        }

        for item in lowPriorityQueue {
            if item.taskId == taskId { return position }
            position += 1
        }

        return nil
    }

    // MARK: - Processing

    /// Process all queued items
    func processQueue(handler: @escaping (UUID) async -> Void) async {
        guard !isProcessing else { return }

        isProcessing = true
        defer { isProcessing = false }

        while let item = getNext() {
            // Wait if at max concurrent
            while activeCount >= maxConcurrent {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }

            activeCount += 1

            Task {
                await handler(item.taskId)
                await MainActor.run {
                    self.activeCount -= 1
                    self.processedCount += 1
                }
            }
        }

        // Wait for all active tasks to complete
        while activeCount > 0 {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    /// Process single item with retry
    func processWithRetry(
        taskId: UUID,
        maxAttempts: Int = 3,
        handler: @escaping (UUID) async throws -> Void
    ) async {
        var attempts = 0

        while attempts < maxAttempts {
            do {
                try await handler(taskId)
                processedCount += 1
                return
            } catch {
                attempts += 1
                print("Attempt \(attempts) failed for task \(taskId): \(error)")

                if attempts < maxAttempts {
                    // Exponential backoff
                    let delay = UInt64(pow(2.0, Double(attempts))) * 1_000_000_000
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }

        failedCount += 1
    }

    // MARK: - Queue Management

    /// Clear all queues
    func clearAll() {
        highPriorityQueue.removeAll()
        normalQueue.removeAll()
        lowPriorityQueue.removeAll()
        updatePendingCount()
    }

    /// Clear failed items and retry
    func retryFailed() {
        failedCount = 0
    }

    /// Get queue statistics
    var statistics: QueueStatistics {
        QueueStatistics(
            pending: pendingCount,
            processed: processedCount,
            failed: failedCount,
            highPriority: highPriorityQueue.count,
            normalPriority: normalQueue.count,
            lowPriority: lowPriorityQueue.count
        )
    }

    // MARK: - Private Helpers

    private var totalCount: Int {
        highPriorityQueue.count + normalQueue.count + lowPriorityQueue.count
    }

    private func updatePendingCount() {
        pendingCount = totalCount
    }
}

// MARK: - Queue Statistics

struct QueueStatistics {
    let pending: Int
    let processed: Int
    let failed: Int
    let highPriority: Int
    let normalPriority: Int
    let lowPriority: Int

    var successRate: Double {
        guard processed + failed > 0 else { return 1.0 }
        return Double(processed) / Double(processed + failed)
    }
}
