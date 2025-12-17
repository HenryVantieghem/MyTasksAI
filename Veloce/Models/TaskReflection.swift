//
//  TaskReflection.swift
//  Veloce
//
//  Post-completion reflection model for learning and improvement
//

import Foundation

/// Captures user reflections after completing a task
/// Used to build feedback loop for AI improvement
struct TaskReflection: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let taskId: UUID
    let userId: UUID?

    // Reflection content
    var difficultyRating: Int           // 1-5 stars
    var wasEstimateAccurate: Bool?      // Was AI time estimate accurate?
    var learnings: String?              // "What did you learn?"
    var tipsForNext: [String]?          // Tips for next time (AI + user)
    var actualMinutes: Int?             // Real time spent

    let createdAt: Date

    init(
        id: UUID = UUID(),
        taskId: UUID,
        userId: UUID? = nil,
        difficultyRating: Int,
        wasEstimateAccurate: Bool? = nil,
        learnings: String? = nil,
        tipsForNext: [String]? = nil,
        actualMinutes: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.userId = userId
        self.difficultyRating = difficultyRating
        self.wasEstimateAccurate = wasEstimateAccurate
        self.learnings = learnings
        self.tipsForNext = tipsForNext
        self.actualMinutes = actualMinutes
        self.createdAt = createdAt
    }
}

// MARK: - Supabase Coding Keys

extension TaskReflection {
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case userId = "user_id"
        case difficultyRating = "difficulty_rating"
        case wasEstimateAccurate = "was_estimate_accurate"
        case learnings
        case tipsForNext = "tips_for_next"
        case actualMinutes = "actual_minutes"
        case createdAt = "created_at"
    }
}

// MARK: - User Productivity Patterns

/// Aggregated user patterns for AI personalization
struct UserProductivityPatterns: Codable, Sendable {
    let id: UUID
    let userId: UUID

    // Energy patterns by time of day (0.0 - 1.0 productivity score)
    var energyPatterns: [String: Double]?  // {"morning": 0.8, "afternoon": 0.6, "evening": 0.4}

    // AI accuracy tracking
    var aiAccuracyScore: Double?           // Rolling average of estimate accuracy
    var completedTaskCount: Int

    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        energyPatterns: [String: Double]? = nil,
        aiAccuracyScore: Double? = nil,
        completedTaskCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.energyPatterns = energyPatterns
        self.aiAccuracyScore = aiAccuracyScore
        self.completedTaskCount = completedTaskCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Helper Methods

    /// Get best time of day for productivity
    var bestTimeOfDay: String? {
        energyPatterns?.max(by: { $0.value < $1.value })?.key
    }

    /// Get productivity score for a given time
    func productivityScore(for hour: Int) -> Double? {
        switch hour {
        case 5..<12:
            return energyPatterns?["morning"]
        case 12..<17:
            return energyPatterns?["afternoon"]
        case 17..<21:
            return energyPatterns?["evening"]
        default:
            return energyPatterns?["night"]
        }
    }
}

// MARK: - Supabase Coding Keys for UserProductivityPatterns

extension UserProductivityPatterns {
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case energyPatterns = "energy_patterns"
        case aiAccuracyScore = "ai_accuracy_score"
        case completedTaskCount = "completed_task_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Schedule Suggestion Model

/// AI-generated scheduling recommendation
struct ScheduleSuggestion: Codable, Sendable {
    let suggestedTime: Date
    let reason: String
    let confidence: Double            // 0.0 - 1.0
    let alternativeTimes: [Date]?
    let conflictingEvents: [String]?  // Names of conflicting calendar events

    var confidenceLabel: String {
        switch confidence {
        case 0.8...1.0: return "High confidence"
        case 0.6..<0.8: return "Moderate confidence"
        default: return "Low confidence"
        }
    }
}

extension ScheduleSuggestion {
    enum CodingKeys: String, CodingKey {
        case suggestedTime = "suggested_time"
        case reason
        case confidence
        case alternativeTimes = "alternative_times"
        case conflictingEvents = "conflicting_events"
    }
}
