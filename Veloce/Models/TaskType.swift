//
//  TaskType.swift
//  MyTasksAI
//
//  Task Type Classification - Auto-detected by AI
//  Categorizes tasks by cognitive load and work type
//

import Foundation
import SwiftUI

// MARK: - Task Type

/// Task classification based on cognitive requirements
/// Used by AI to suggest optimal scheduling and resources
enum TaskType: String, Codable, Sendable, CaseIterable {
    case create      // High cognitive: writing, coding, designing
    case communicate // Medium: emails, calls, meetings
    case consume     // Learning: reading, courses, videos
    case coordinate  // Quick admin: scheduling, organizing

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .create: return "Create"
        case .communicate: return "Communicate"
        case .consume: return "Learn"
        case .coordinate: return "Coordinate"
        }
    }

    /// Short label for compact displays (keyboard accessory, etc.)
    var shortLabel: String {
        switch self {
        case .create: return "Create"
        case .communicate: return "Chat"
        case .consume: return "Learn"
        case .coordinate: return "Admin"
        }
    }

    var icon: String {
        switch self {
        case .create: return "paintbrush.pointed"
        case .communicate: return "bubble.left.and.bubble.right"
        case .consume: return "book"
        case .coordinate: return "arrow.triangle.branch"
        }
    }

    var color: Color {
        switch self {
        case .create: return Theme.Colors.aiPurple
        case .communicate: return Theme.Colors.aiBlue
        case .consume: return Theme.Colors.aiGreen
        case .coordinate: return Theme.Colors.aiOrange
        }
    }

    // MARK: - AI Suggestions

    /// Suggested duration in minutes based on task type
    var suggestedDuration: Int {
        switch self {
        case .create: return 90
        case .communicate: return 30
        case .consume: return 45
        case .coordinate: return 15
        }
    }

    /// Best time of day for this task type
    var optimalTimeOfDay: String {
        switch self {
        case .create: return "morning"
        case .communicate: return "afternoon"
        case .consume: return "flexible"
        case .coordinate: return "interstitial"
        }
    }

    /// Required energy level
    var energyLevel: String {
        switch self {
        case .create: return "high"
        case .communicate: return "medium"
        case .consume: return "medium"
        case .coordinate: return "low"
        }
    }

    /// Description for AI context
    var aiDescription: String {
        switch self {
        case .create:
            return "Creative, high-cognitive task requiring focus and deep work"
        case .communicate:
            return "Interpersonal task involving others, needs clear communication"
        case .consume:
            return "Learning-focused task for absorbing new information"
        case .coordinate:
            return "Administrative task for organizing and managing"
        }
    }
}

// MARK: - Task Resource Type

/// Types of resources that can help with a task
enum TaskResourceType: String, Codable, Sendable {
    case youtube
    case article
    case documentation
    case tool

    var icon: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .article: return "doc.text"
        case .documentation: return "book.closed"
        case .tool: return "wrench.and.screwdriver"
        }
    }

    var color: Color {
        switch self {
        case .youtube: return .red
        case .article: return Theme.Colors.aiBlue
        case .documentation: return Theme.Colors.aiOrange
        case .tool: return Theme.Colors.aiPurple
        }
    }

    var displayName: String {
        switch self {
        case .youtube: return "Video"
        case .article: return "Article"
        case .documentation: return "Docs"
        case .tool: return "Tool"
        }
    }
}

// MARK: - Task Resource

/// External resource recommended for a task
struct TaskResource: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let title: String
    let url: String
    let source: String
    let type: TaskResourceType
    let duration: String?  // "8 min" for videos
    let reasoning: String?

    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        source: String,
        type: TaskResourceType,
        duration: String? = nil,
        reasoning: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.source = source
        self.type = type
        self.duration = duration
        self.reasoning = reasoning
    }
}

// MARK: - Schedule Rank

/// Ranking for schedule suggestions
enum ScheduleRank: String, Codable, Sendable {
    case best
    case good
    case okay

    var emoji: String {
        switch self {
        case .best: return "⭐"
        case .good: return "👍"
        case .okay: return "👌"
        }
    }

    var label: String {
        switch self {
        case .best: return "BEST:"
        case .good: return "GOOD:"
        case .okay: return "OKAY:"
        }
    }

    var color: Color {
        switch self {
        case .best: return Theme.Colors.success
        case .good: return Theme.Colors.aiBlue
        case .okay: return Theme.Colors.textSecondary
        }
    }
}

// MARK: - Genius Schedule Suggestion

/// AI-generated schedule suggestion with ranking
struct GeniusScheduleSuggestion: Codable, Identifiable, Sendable {
    let id: UUID
    let rank: ScheduleRank
    let date: Date
    let reason: String

    init(
        id: UUID = UUID(),
        rank: ScheduleRank,
        date: Date,
        reason: String
    ) {
        self.id = id
        self.rank = rank
        self.date = date
        self.reason = reason
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else {
            formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Mentor Advice

/// AI mentor's comprehensive advice for a task
struct MentorAdvice: Codable, Sendable {
    let mainAdvice: String
    let thoughtProcess: String
    let potentialBlocker: String?
    let quickTip: String

    enum CodingKeys: String, CodingKey {
        case mainAdvice = "main_advice"
        case thoughtProcess = "thought_process"
        case potentialBlocker = "potential_blocker"
        case quickTip = "quick_tip"
    }
}

// MARK: - Execution Step

/// A single step in task execution breakdown
struct ExecutionStep: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let description: String
    let estimatedMinutes: Int
    var isCompleted: Bool
    let orderIndex: Int
    let reasoning: String?

    init(
        id: UUID = UUID(),
        description: String,
        estimatedMinutes: Int,
        isCompleted: Bool = false,
        orderIndex: Int,
        reasoning: String? = nil
    ) {
        self.id = id
        self.description = description
        self.estimatedMinutes = estimatedMinutes
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
        self.reasoning = reasoning
    }

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case estimatedMinutes = "estimated_minutes"
        case isCompleted = "is_completed"
        case orderIndex = "order_index"
        case reasoning
    }
}

// MARK: - Genius Task Analysis

/// Complete AI analysis for a task
struct GeniusTaskAnalysis: Codable, Sendable {
    let taskType: TaskType
    let estimatedMinutes: Int
    let mentorAdvice: MentorAdvice
    let executionSteps: [ExecutionStep]
    let resources: [TaskResource]
    let scheduleSuggestions: [GeniusScheduleSuggestion]?

    enum CodingKeys: String, CodingKey {
        case taskType = "task_type"
        case estimatedMinutes = "estimated_minutes"
        case mentorAdvice = "mentor_advice"
        case executionSteps = "execution_steps"
        case resources
        case scheduleSuggestions = "schedule_suggestions"
    }
}

// MARK: - User Patterns

/// User's productivity patterns for AI personalization
struct UserPatterns: Codable, Sendable {
    let preferredLearningStyle: String?
    let peakProductivityHours: String?
    let bestDays: [String]?
    let avgDurationByType: [String: Int]?

    init(
        preferredLearningStyle: String? = nil,
        peakProductivityHours: String? = nil,
        bestDays: [String]? = nil,
        avgDurationByType: [String: Int]? = nil
    ) {
        self.preferredLearningStyle = preferredLearningStyle
        self.peakProductivityHours = peakProductivityHours
        self.bestDays = bestDays
        self.avgDurationByType = avgDurationByType
    }

    enum CodingKeys: String, CodingKey {
        case preferredLearningStyle = "preferred_learning_style"
        case peakProductivityHours = "peak_productivity_hours"
        case bestDays = "best_days"
        case avgDurationByType = "avg_duration_by_type"
    }
}
