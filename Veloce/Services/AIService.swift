//
//  AIService.swift
//  Veloce
//
//  AI Service - High-level AI Operations Facade
//  Coordinates between PerplexityService and queue for seamless AI integration
//

import Foundation

// MARK: - AI Service

@MainActor
@Observable
final class AIService {
    // MARK: Singleton
    static let shared = AIService()

    // MARK: Dependencies
    private let perplexity = PerplexityService.shared
    private let queue = AIProcessingQueue.shared

    // MARK: State
    private(set) var isConfigured: Bool = false
    private(set) var processingTasks: Set<UUID> = []

    // MARK: Initialization
    private init() {}

    // MARK: - Configuration

    /// Configure AI service with API key
    func configure(apiKey: String) {
        perplexity.configure(apiKey: apiKey)
        isConfigured = perplexity.isConfigured
    }

    /// Load configuration from storage
    func loadConfiguration() {
        perplexity.loadConfiguration()
        isConfigured = perplexity.isConfigured
    }

    // MARK: - Task Processing

    /// Process a single task with AI
    func processTask(
        _ task: TaskItem,
        priority: AIProcessingQueue.Priority = .normal
    ) async throws -> AIAdvice {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }

        processingTasks.insert(task.id)
        defer { processingTasks.remove(task.id) }

        // Analyze the task
        let response = try await perplexity.analyzeTask(
            title: task.title,
            notes: task.notes,
            context: task.contextNotes
        )

        // Create advice from response
        let advice = AIAdvice(
            taskId: task.id,
            advice: response.advice,
            priority: response.priority,
            estimatedMinutes: response.estimatedMinutes,
            sources: response.sources,
            thoughtProcess: response.thoughtProcess
        )

        return advice
    }

    /// Queue task for background processing
    func queueTask(_ task: TaskItem, priority: AIProcessingQueue.Priority = .normal) {
        queue.enqueue(taskId: task.id, priority: priority)
    }

    /// Process all queued tasks
    func processQueue() async {
        await queue.processQueue { taskId in
            // This would be called for each task
            // In real implementation, fetch task from storage and process
            print("Processing task: \(taskId)")
        }
    }

    /// Check if task is being processed
    func isProcessing(_ taskId: UUID) -> Bool {
        processingTasks.contains(taskId)
    }

    // MARK: - Quick Operations

    /// Get quick priority assessment
    func assessPriority(for title: String) async throws -> TaskPriority {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }
        return try await perplexity.assessPriority(taskTitle: title)
    }

    /// Get time estimate
    func estimateTime(for title: String, context: String? = nil) async throws -> Int {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }
        return try await perplexity.estimateTime(taskTitle: title, context: context)
    }

    /// Process brain dump text into tasks
    func processBrainDump(_ text: String) async throws -> [ParsedTask] {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }
        return try await perplexity.processBrainDump(text)
    }

    // MARK: - Sub-Task Breakdown

    /// Generate sub-task breakdown for a task
    func generateSubTasks(
        for task: TaskItem
    ) async throws -> (subTasks: [SubTask], thoughtProcess: String) {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }

        return try await perplexity.generateSubTaskBreakdown(
            taskTitle: task.title,
            context: task.contextNotes,
            estimatedMinutes: task.estimatedMinutes
        )
    }

    // MARK: - YouTube Resources

    /// Find YouTube learning resources for a task
    func findYouTubeResources(
        for task: TaskItem,
        maxResults: Int = 3
    ) async throws -> [YouTubeResource] {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }

        let searchResources = try await perplexity.generateYouTubeSearchQueries(
            taskTitle: task.title,
            context: task.contextNotes,
            maxQueries: maxResults
        )
        // Convert YouTubeSearchResource to YouTubeResource format
        return searchResources.prefix(maxResults).map { resource in
            YouTubeResource(
                videoId: resource.searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? resource.searchQuery,
                title: resource.displayTitle,
                channelName: "YouTube Search",
                relevanceScore: resource.relevanceScore
            )
        }
    }

    // MARK: - Schedule Suggestions

    /// Generate schedule suggestion for a task
    func suggestSchedule(
        for task: TaskItem,
        freeSlots: [DateInterval],
        userPatterns: UserProductivityProfile?
    ) async throws -> ScheduleSuggestion {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }

        return try await perplexity.generateScheduleSuggestion(
            taskTitle: task.title,
            estimatedMinutes: task.estimatedMinutes,
            freeSlots: freeSlots,
            userPatterns: userPatterns
        )
    }

    // MARK: - Reflections

    /// Generate reflection tips after task completion
    func generateReflectionTips(
        for task: TaskItem,
        difficultyRating: Int,
        wasEstimateAccurate: Bool?,
        actualMinutes: Int?
    ) async throws -> [String] {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }

        return try await perplexity.generateReflectionTips(
            taskTitle: task.title,
            difficultyRating: difficultyRating,
            wasEstimateAccurate: wasEstimateAccurate,
            actualMinutes: actualMinutes,
            estimatedMinutes: task.estimatedMinutes
        )
    }

    // MARK: - Batch Processing

    /// Process multiple tasks (with rate limiting)
    func processTasks(_ tasks: [TaskItem]) async throws -> [UUID: AIAdvice] {
        var results: [UUID: AIAdvice] = [:]

        for task in tasks {
            do {
                let advice = try await processTask(task)
                results[task.id] = advice

                // Small delay between requests to respect rate limits
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                print("Failed to process task \(task.id): \(error)")
                // Continue with other tasks
            }
        }

        return results
    }
}

// MARK: - AI Service Error

enum AIServiceError: Error, LocalizedError {
    case notConfigured
    case taskNotFound
    case processingFailed(String)
    case queueFull

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI service is not configured. Please add your API key."
        case .taskNotFound:
            return "Task not found"
        case .processingFailed(let reason):
            return "AI processing failed: \(reason)"
        case .queueFull:
            return "Processing queue is full. Please try again later."
        }
    }
}
