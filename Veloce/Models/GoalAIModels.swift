//
//  GoalAIModels.swift
//  MyTasksAI
//
//  AI Response Models for Goal Genius Features
//  SMART refinement, roadmap generation, and weekly coaching
//

import Foundation
@preconcurrency import SwiftUI

// MARK: - Goal Refinement (SMART Analysis)
/// Result of AI refining a vague goal into a SMART goal
struct GoalRefinement: Codable, Sendable {
    let refinedTitle: String
    let refinedDescription: String
    let successMetrics: [String]
    let potentialObstacles: [String]
    let motivationalQuote: String
    let smartAnalysis: SMARTAnalysis

    enum CodingKeys: String, CodingKey {
        case refinedTitle = "refined_title"
        case refinedDescription = "refined_description"
        case successMetrics = "success_metrics"
        case potentialObstacles = "potential_obstacles"
        case motivationalQuote = "motivational_quote"
        case smartAnalysis = "smart_analysis"
    }
}

/// Breakdown of how goal meets SMART criteria
struct SMARTAnalysis: Codable, Sendable {
    let specific: String
    let measurable: String
    let achievable: String
    let relevant: String
    let timeBound: String

    enum CodingKeys: String, CodingKey {
        case specific
        case measurable
        case achievable
        case relevant
        case timeBound = "time_bound"
    }
}

// MARK: - Goal Roadmap
/// Complete AI-generated roadmap for achieving a goal
struct GoalRoadmap: Codable, Sendable {
    let phases: [RoadmapPhase]
    let totalEstimatedHours: Double
    let successProbability: Double
    let coachingNotes: String

    enum CodingKeys: String, CodingKey {
        case phases
        case totalEstimatedHours = "total_estimated_hours"
        case successProbability = "success_probability"
        case coachingNotes = "coaching_notes"
    }

    /// Total milestone count across all phases
    var totalMilestones: Int {
        phases.reduce(0) { $0 + $1.milestones.count }
    }

    /// Total habit count across all phases
    var totalHabits: Int {
        phases.reduce(0) { $0 + $1.dailyHabits.count }
    }

    /// Total task count across all phases
    var totalTasks: Int {
        phases.reduce(0) { $0 + $1.oneTimeTasks.count }
    }
}

/// A phase within the goal roadmap
struct RoadmapPhase: Codable, Sendable, Identifiable {
    let name: String
    let startWeek: Int
    let endWeek: Int
    let milestones: [RoadmapMilestone]
    let dailyHabits: [RoadmapHabit]
    let oneTimeTasks: [RoadmapTask]
    let phaseObstacles: [String]

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name
        case startWeek = "start_week"
        case endWeek = "end_week"
        case milestones
        case dailyHabits = "daily_habits"
        case oneTimeTasks = "one_time_tasks"
        case phaseObstacles = "phase_obstacles"
    }

    /// Duration in weeks
    var durationWeeks: Int {
        endWeek - startWeek + 1
    }

    /// Total items in this phase
    var totalItems: Int {
        milestones.count + dailyHabits.count + oneTimeTasks.count
    }
}

/// A milestone within a roadmap phase
struct RoadmapMilestone: Codable, Sendable, Identifiable {
    let title: String
    let description: String
    let targetDaysFromStart: Int
    let successIndicator: String
    let pointsValue: Int

    var id: String { title }

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case targetDaysFromStart = "target_days_from_start"
        case successIndicator = "success_indicator"
        case pointsValue = "points_value"
    }

    /// Calculate target date from goal start date
    func targetDate(from startDate: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: targetDaysFromStart, to: startDate) ?? startDate
    }
}

/// A habit suggestion within a roadmap phase
struct RoadmapHabit: Codable, Sendable, Identifiable {
    let title: String
    let frequency: String  // "daily", "weekdays", "weekly"
    let durationMinutes: Int
    let bestTime: String  // "morning", "afternoon", "evening"
    let reasoning: String?

    var id: String { title }

    enum CodingKeys: String, CodingKey {
        case title
        case frequency
        case durationMinutes = "duration_minutes"
        case bestTime = "best_time"
        case reasoning
    }

    /// Frequency as RecurringType
    var recurringType: String {
        switch frequency.lowercased() {
        case "daily": return "daily"
        case "weekdays": return "custom"  // Mon-Fri
        case "weekly": return "weekly"
        default: return "daily"
        }
    }

    /// Weekdays array for custom recurring
    var weekdays: [Int]? {
        if frequency.lowercased() == "weekdays" {
            return [1, 2, 3, 4, 5]  // Mon-Fri (0 = Sunday)
        }
        return nil
    }
}

/// A one-time task within a roadmap phase
struct RoadmapTask: Codable, Sendable, Identifiable {
    let title: String
    let estimatedMinutes: Int
    let priority: String  // "high", "medium", "low"
    let reasoning: String?

    var id: String { title }

    enum CodingKeys: String, CodingKey {
        case title
        case estimatedMinutes = "estimated_minutes"
        case priority
        case reasoning
    }

    /// Priority as star rating (1-3)
    var starRating: Int {
        switch priority.lowercased() {
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 2
        }
    }
}

// MARK: - Weekly Check-In
/// Result of AI weekly coaching check-in
struct WeeklyCheckIn: Codable, Sendable {
    let emotionalResponse: String
    let progressAssessment: ProgressAssessment
    let weekFocus: String
    let habitTweak: HabitTweak?
    let motivation: String
    let nextWeekObstacles: [String]
    let celebrationWorthy: Bool
    let actionItems: [String]?

    enum CodingKeys: String, CodingKey {
        case emotionalResponse = "emotional_response"
        case progressAssessment = "progress_assessment"
        case weekFocus = "week_focus"
        case habitTweak = "habit_tweak"
        case motivation
        case nextWeekObstacles = "next_week_obstacles"
        case celebrationWorthy = "celebration_worthy"
        case actionItems = "action_items"
    }
}

/// Assessment of goal progress status
enum ProgressAssessment: String, Codable, Sendable {
    case onTrack = "on_track"
    case ahead = "ahead"
    case behind = "behind"
    case atRisk = "at_risk"

    var displayName: String {
        switch self {
        case .onTrack: return "On Track"
        case .ahead: return "Ahead of Schedule"
        case .behind: return "Behind Schedule"
        case .atRisk: return "At Risk"
        }
    }

    var icon: String {
        switch self {
        case .onTrack: return "checkmark.circle.fill"
        case .ahead: return "arrow.up.circle.fill"
        case .behind: return "clock.arrow.circlepath"
        case .atRisk: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .onTrack: return Theme.Colors.success
        case .ahead: return Theme.Colors.aiCyan
        case .behind: return Theme.Colors.warning
        case .atRisk: return Theme.Colors.error
        }
    }
}

/// Suggestion to tweak a habit
struct HabitTweak: Codable, Sendable {
    let current: String
    let suggested: String
    let reasoning: String?
}

// MARK: - Goal Check-In Record
/// Record of a weekly check-in for a goal
struct GoalCheckInRecord: Codable, Sendable, Identifiable {
    let id: UUID
    let goalId: UUID
    let checkInDate: Date
    let progressAtCheckIn: Double
    let blockersReported: [String]?
    let aiResponse: WeeklyCheckIn?
    let userNotes: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        goalId: UUID,
        checkInDate: Date = .now,
        progressAtCheckIn: Double,
        blockersReported: [String]? = nil,
        aiResponse: WeeklyCheckIn? = nil,
        userNotes: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.goalId = goalId
        self.checkInDate = checkInDate
        self.progressAtCheckIn = progressAtCheckIn
        self.blockersReported = blockersReported
        self.aiResponse = aiResponse
        self.userNotes = userNotes
        self.createdAt = createdAt
    }
}

// MARK: - Supabase Goal Check-In DTO
struct SupabaseGoalCheckIn: Codable, Sendable {
    let id: UUID
    let goalId: UUID
    let userId: UUID
    let checkinDate: Date
    var progressAtCheckin: Double?
    var blockersReported: [String]?
    var aiResponse: Data?  // JSON encoded WeeklyCheckIn
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case userId = "user_id"
        case checkinDate = "checkin_date"
        case progressAtCheckin = "progress_at_checkin"
        case blockersReported = "blockers_reported"
        case aiResponse = "ai_response"
        case createdAt = "created_at"
    }
}

// MARK: - AI Goal Analysis Request
/// Input for goal AI analysis
struct GoalAnalysisRequest: Sendable {
    let title: String
    let description: String?
    let category: GoalCategory?
    let timeframe: GoalTimeframe
    let targetDate: Date?
    let userPatterns: UserPatterns?

    struct UserPatterns: Codable, Sendable {
        let preferredLearningStyle: String?
        let peakProductivityHours: String?
        let bestDays: [String]?
        let avgDurationByType: [String: Int]?
    }
}

// MARK: - Roadmap Generation Options
/// Options for customizing roadmap generation
struct RoadmapGenerationOptions: Sendable {
    let includeHabits: Bool
    let includeTasks: Bool
    let maxMilestonesPerPhase: Int
    let maxHabitsPerPhase: Int
    let maxTasksPerPhase: Int
    let focusAreas: [String]?

    init(
        includeHabits: Bool = true,
        includeTasks: Bool = true,
        maxMilestonesPerPhase: Int = 3,
        maxHabitsPerPhase: Int = 3,
        maxTasksPerPhase: Int = 5,
        focusAreas: [String]? = nil
    ) {
        self.includeHabits = includeHabits
        self.includeTasks = includeTasks
        self.maxMilestonesPerPhase = maxMilestonesPerPhase
        self.maxHabitsPerPhase = maxHabitsPerPhase
        self.maxTasksPerPhase = maxTasksPerPhase
        self.focusAreas = focusAreas
    }
}
