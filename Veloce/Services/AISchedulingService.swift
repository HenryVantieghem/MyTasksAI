//
//  AISchedulingService.swift
//  Veloce
//
//  AI Scheduling Service - Intelligent time-blocking
//  Uses Gemini to suggest optimal task scheduling
//

import Foundation
import Supabase

// MARK: - AI Scheduling Service

@MainActor
@Observable
final class AISchedulingService {
    // MARK: Singleton
    static let shared = AISchedulingService()

    // MARK: State
    var suggestedBlocks: [ScheduledBlock] = []
    var scheduledBlocks: [ScheduledBlock] = []
    var isAnalyzing = false
    var preferences: SchedulingPreferences = .default
    var error: String?

    // MARK: Dependencies
    private let supabase = SupabaseService.shared
    private let perplexity = PerplexityService.shared

    // MARK: Initialization
    private init() {}

    // MARK: - Load Scheduled Blocks

    func loadBlocks(for date: Date) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let response: [ScheduledBlock] = try await client
                .from("scheduled_blocks")
                .select("*, task:tasks(*)")
                .eq("user_id", value: userId)
                .gte("start_time", value: startOfDay.ISO8601Format())
                .lt("start_time", value: endOfDay.ISO8601Format())
                .order("start_time")
                .execute()
                .value

            scheduledBlocks = response
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Analyze and Suggest

    func analyzeAndSuggest(tasks: [TaskItem], for date: Date) async throws -> [ScheduledBlock] {
        guard supabase.isConfigured else { return [] }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return [] }

            // Filter unscheduled tasks
            let unscheduledTasks = tasks.filter { $0.scheduledTime == nil && !$0.isCompleted }

            guard !unscheduledTasks.isEmpty else { return [] }

            // Build prompt for Gemini
            let suggestions = try await generateSuggestions(tasks: unscheduledTasks, date: date)

            // Convert to blocks
            var blocks: [ScheduledBlock] = []
            for suggestion in suggestions {
                let block = ScheduledBlock(
                    id: UUID(),
                    userId: userId,
                    taskId: suggestion.taskId,
                    startTime: suggestion.suggestedStart,
                    endTime: suggestion.suggestedEnd,
                    blockType: .task,
                    isAiSuggested: true,
                    confidenceScore: suggestion.confidence,
                    status: .pending,
                    calendarEventId: nil,
                    createdAt: .now,
                    updatedAt: .now,
                    task: unscheduledTasks.first { $0.id == suggestion.taskId }
                )
                blocks.append(block)
            }

            suggestedBlocks = blocks
            return blocks
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Generate Suggestions with Gemini

    private func generateSuggestions(tasks: [TaskItem], date: Date) async throws -> [AIBlockSuggestion] {
        // Build task list for prompt
        let taskDescriptions = tasks.map { task -> String in
            let duration = task.estimatedMinutes ?? 30
            let priority = task.starRating
            return "- \(task.title) (duration: \(duration)min, priority: \(priority)/3)"
        }.joined(separator: "\n")

        let prompt = """
        Schedule these tasks optimally for \(date.formatted(date: .complete, time: .omitted)):

        Tasks:
        \(taskDescriptions)

        User preferences:
        - Focus hours: \(preferences.focusHoursStart):00 to \(preferences.focusHoursEnd):00
        - Buffer between tasks: \(preferences.bufferMinutes) minutes
        - Prefer hard tasks in morning: \(preferences.preferMorningForHardTasks)

        Return a JSON array with format:
        [{"task_index": 0, "start_hour": 9, "start_minute": 0, "confidence": 0.85}]

        Consider:
        1. Higher priority tasks earlier
        2. Energy levels throughout day
        3. Buffer time between tasks
        4. Don't schedule during lunch (12-13)
        """

        // Use Gemini to get suggestions
        // For now, use simple heuristic scheduling
        return generateHeuristicSchedule(tasks: tasks, date: date)
    }

    private func generateHeuristicSchedule(tasks: [TaskItem], date: Date) -> [AIBlockSuggestion] {
        var suggestions: [AIBlockSuggestion] = []
        let calendar = Calendar.current

        // Start at focus hours start
        var currentTime = calendar.date(
            bySettingHour: preferences.focusHoursStart,
            minute: 0,
            second: 0,
            of: date
        ) ?? date

        // Sort by priority (highest first)
        let sortedTasks = tasks.sorted { $0.starRating > $1.starRating }

        for task in sortedTasks {
            let duration = task.estimatedMinutes ?? 30
            let endTime = currentTime.addingTimeInterval(TimeInterval(duration * 60))

            // Skip lunch hour (12-13)
            let hour = calendar.component(.hour, from: currentTime)
            if hour == 12 {
                currentTime = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: date) ?? currentTime
            }

            // Check if within focus hours
            let endHour = calendar.component(.hour, from: endTime)
            guard endHour <= preferences.focusHoursEnd else { break }

            let suggestion = AIBlockSuggestion(
                taskId: task.id,
                suggestedStart: currentTime,
                suggestedEnd: endTime,
                confidence: calculateConfidence(for: task, at: currentTime),
                reasoning: nil
            )
            suggestions.append(suggestion)

            // Add buffer for next task
            currentTime = endTime.addingTimeInterval(TimeInterval(preferences.bufferMinutes * 60))
        }

        return suggestions
    }

    private func calculateConfidence(for task: TaskItem, at time: Date) -> Float {
        var confidence: Float = 0.7

        // Higher confidence for high priority tasks in morning
        let hour = Calendar.current.component(.hour, from: time)
        if task.starRating == 3 && hour < 12 {
            confidence += 0.15
        }

        // Lower confidence for tasks without estimates
        if task.estimatedMinutes == nil {
            confidence -= 0.1
        }

        return min(max(confidence, 0.5), 0.95)
    }

    // MARK: - Accept Suggestion

    func acceptSuggestion(_ block: ScheduledBlock) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            let request = CreateBlockRequest(
                userId: userId,
                taskId: block.taskId,
                startTime: block.startTime,
                endTime: block.endTime,
                blockType: block.blockType,
                isAiSuggested: true,
                confidence: block.confidenceScore
            )

            try await client
                .from("scheduled_blocks")
                .insert(request)
                .execute()

            // Remove from suggestions
            suggestedBlocks.removeAll { $0.id == block.id }

            // Reload blocks
            try await loadBlocks(for: block.startTime)

            // Record feedback
            try await recordFeedback(blockId: block.id, type: .accepted)

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Decline Suggestion

    func declineSuggestion(_ block: ScheduledBlock, reason: String? = nil) async throws {
        suggestedBlocks.removeAll { $0.id == block.id }
        try await recordFeedback(blockId: block.id, type: .declined, reason: reason)
    }

    // MARK: - Auto-Schedule Day

    func autoScheduleDay(_ date: Date, tasks: [TaskItem]) async throws -> [ScheduledBlock] {
        let suggestions = try await analyzeAndSuggest(tasks: tasks, for: date)

        // Accept all suggestions
        for block in suggestions {
            try await acceptSuggestion(block)
        }

        return scheduledBlocks
    }

    // MARK: - Update Block Status

    func updateBlockStatus(_ blockId: UUID, status: BlockStatus) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()

            try await client
                .from("scheduled_blocks")
                .update(["status": status.rawValue, "updated_at": Date().ISO8601Format()])
                .eq("id", value: blockId)
                .execute()

            // Update local state
            if let index = scheduledBlocks.firstIndex(where: { $0.id == blockId }) {
                scheduledBlocks[index].status = status
            }
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Record Feedback

    func recordFeedback(blockId: UUID, type: FeedbackType, reason: String? = nil) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            let feedback = CreateFeedbackRequest(
                userId: userId,
                blockId: blockId,
                feedbackType: type.rawValue,
                reason: reason
            )

            try await client
                .from("scheduling_feedback")
                .insert(feedback)
                .execute()
        } catch {
            // Don't throw - feedback is optional
            print("Failed to record feedback: \(error)")
        }
    }

    // MARK: - Delete Block

    func deleteBlock(_ blockId: UUID) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()

            try await client
                .from("scheduled_blocks")
                .delete()
                .eq("id", value: blockId)
                .execute()

            scheduledBlocks.removeAll { $0.id == blockId }
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
}
