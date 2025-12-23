//
//  Goal.swift
//  MyTasksAI
//
//  Goal Model - SwiftData + Supabase compatible
//  Represents SMART goals with progress tracking
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Goal Model
@Model
final class Goal {
    // MARK: Core Properties
    var id: UUID
    var userId: UUID?
    var title: String
    var goalDescription: String?
    var targetDate: Date?
    var category: String?

    // MARK: Timeframe & Hierarchy
    var timeframe: String?  // GoalTimeframe.rawValue
    var parentGoalId: UUID?  // For linking sprints to horizons
    var sortOrder: Int

    // MARK: Progress
    var isCompleted: Bool
    var progress: Double  // 0.0 - 1.0
    var completedAt: Date?
    var progressHistory: Data?  // JSON encoded [ProgressSnapshot]

    // MARK: SMART Criteria
    var isSpecific: Bool
    var isMeasurable: Bool
    var isAchievable: Bool
    var isRelevant: Bool
    var isTimeBound: Bool

    // MARK: AI Analysis
    var aiRoadmap: Data?  // JSON encoded GoalRoadmap
    var aiRefinedTitle: String?
    var aiRefinedDescription: String?
    var aiObstacles: [String]?
    var aiSuccessMetrics: [String]?
    var aiMotivationalQuote: String?
    var aiAnalyzedAt: Date?

    // MARK: Coaching
    var lastCheckInDate: Date?
    var checkInStreak: Int
    var totalCheckIns: Int
    var nextCheckInSuggested: Date?

    // MARK: Gamification
    var pointsAwarded: Int
    var milestoneCount: Int
    var completedMilestoneCount: Int
    var linkedTaskCount: Int

    // MARK: Timestamps
    var createdAt: Date
    var updatedAt: Date

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        title: String,
        goalDescription: String? = nil,
        targetDate: Date? = nil,
        category: String? = nil,
        timeframe: String? = nil,
        parentGoalId: UUID? = nil,
        sortOrder: Int = 0,
        isCompleted: Bool = false,
        progress: Double = 0,
        completedAt: Date? = nil,
        progressHistory: Data? = nil,
        isSpecific: Bool = false,
        isMeasurable: Bool = false,
        isAchievable: Bool = false,
        isRelevant: Bool = false,
        isTimeBound: Bool = false,
        aiRoadmap: Data? = nil,
        aiRefinedTitle: String? = nil,
        aiRefinedDescription: String? = nil,
        aiObstacles: [String]? = nil,
        aiSuccessMetrics: [String]? = nil,
        aiMotivationalQuote: String? = nil,
        aiAnalyzedAt: Date? = nil,
        lastCheckInDate: Date? = nil,
        checkInStreak: Int = 0,
        totalCheckIns: Int = 0,
        nextCheckInSuggested: Date? = nil,
        pointsAwarded: Int = 0,
        milestoneCount: Int = 0,
        completedMilestoneCount: Int = 0,
        linkedTaskCount: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.goalDescription = goalDescription
        self.targetDate = targetDate
        self.category = category
        self.timeframe = timeframe
        self.parentGoalId = parentGoalId
        self.sortOrder = sortOrder
        self.isCompleted = isCompleted
        self.progress = progress
        self.completedAt = completedAt
        self.progressHistory = progressHistory
        self.isSpecific = isSpecific
        self.isMeasurable = isMeasurable
        self.isAchievable = isAchievable
        self.isRelevant = isRelevant
        self.isTimeBound = isTimeBound
        self.aiRoadmap = aiRoadmap
        self.aiRefinedTitle = aiRefinedTitle
        self.aiRefinedDescription = aiRefinedDescription
        self.aiObstacles = aiObstacles
        self.aiSuccessMetrics = aiSuccessMetrics
        self.aiMotivationalQuote = aiMotivationalQuote
        self.aiAnalyzedAt = aiAnalyzedAt
        self.lastCheckInDate = lastCheckInDate
        self.checkInStreak = checkInStreak
        self.totalCheckIns = totalCheckIns
        self.nextCheckInSuggested = nextCheckInSuggested
        self.pointsAwarded = pointsAwarded
        self.milestoneCount = milestoneCount
        self.completedMilestoneCount = completedMilestoneCount
        self.linkedTaskCount = linkedTaskCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
extension Goal {
    /// Category as enum
    var categoryEnum: GoalCategory? {
        guard let category else { return nil }
        return GoalCategory(rawValue: category)
    }

    /// Timeframe as enum
    var timeframeEnum: GoalTimeframe? {
        guard let timeframe else { return nil }
        return GoalTimeframe(rawValue: timeframe)
    }

    /// Display title (AI refined if available)
    var displayTitle: String {
        aiRefinedTitle ?? title
    }

    /// Display description (AI refined if available)
    var displayDescription: String? {
        aiRefinedDescription ?? goalDescription
    }

    /// Decoded AI roadmap
    nonisolated var decodedRoadmap: GoalRoadmap? {
        guard let data = aiRoadmap else { return nil }
        return try? JSONDecoder().decode(GoalRoadmap.self, from: data)
    }

    /// Decoded progress history
    nonisolated var decodedProgressHistory: [ProgressSnapshot] {
        guard let data = progressHistory else { return [] }
        return (try? JSONDecoder().decode([ProgressSnapshot].self, from: data)) ?? []
    }

    /// Has AI analysis been completed
    var hasAIAnalysis: Bool {
        aiAnalyzedAt != nil
    }

    /// Has AI roadmap been generated
    var hasRoadmap: Bool {
        aiRoadmap != nil
    }

    /// Milestone progress as a percentage (0.0 - 1.0)
    var milestoneProgress: Double {
        guard milestoneCount > 0 else { return 0 }
        return Double(completedMilestoneCount) / Double(milestoneCount)
    }

    /// Milestone progress string (e.g., "3/8")
    var milestoneProgressString: String {
        "\(completedMilestoneCount)/\(milestoneCount)"
    }

    /// Is check-in due
    var isCheckInDue: Bool {
        guard let nextCheckIn = nextCheckInSuggested else { return false }
        return nextCheckIn <= Date()
    }

    /// Days until next check-in
    var daysUntilCheckIn: Int? {
        guard let nextCheckIn = nextCheckInSuggested else { return nil }
        let components = Calendar.current.dateComponents([.day], from: Date(), to: nextCheckIn)
        return components.day
    }

    /// Timeframe color (falls back to category color)
    var themeColor: Color {
        timeframeEnum?.color ?? categoryEnum?.color ?? Theme.Colors.aiPurple
    }

    /// Timeframe icon (falls back to category icon)
    var themeIcon: String {
        timeframeEnum?.icon ?? categoryEnum?.icon ?? "target"
    }

    /// SMART score (0-5)
    var smartScore: Int {
        var score = 0
        if isSpecific { score += 1 }
        if isMeasurable { score += 1 }
        if isAchievable { score += 1 }
        if isRelevant { score += 1 }
        if isTimeBound { score += 1 }
        return score
    }

    /// SMART completion percentage
    var smartProgress: Double {
        Double(smartScore) / 5.0
    }

    /// Is goal overdue
    var isOverdue: Bool {
        guard let targetDate, !isCompleted else { return false }
        return targetDate < Date()
    }

    /// Days remaining
    var daysRemaining: Int? {
        guard let targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day
    }

    /// Formatted progress
    var formattedProgress: String {
        "\(Int(progress * 100))%"
    }

    /// Status color
    var statusColor: Color {
        if isCompleted {
            return Theme.Colors.success
        } else if isOverdue {
            return Theme.Colors.error
        } else if progress >= 0.5 {
            return Theme.Colors.warning
        }
        return Theme.Colors.textSecondary
    }
}

// MARK: - Methods
extension Goal {
    /// Update progress
    func updateProgress(_ newProgress: Double) {
        progress = min(max(newProgress, 0), 1)
        if progress >= 1.0 && !isCompleted {
            complete()
        }
        updatedAt = .now
    }

    /// Mark goal as completed
    func complete() {
        isCompleted = true
        progress = 1.0
        completedAt = .now
        updatedAt = .now
    }

    /// Set AI roadmap (encodes to Data)
    func setRoadmap(_ roadmap: GoalRoadmap) throws {
        aiRoadmap = try Self.encodeRoadmap(roadmap)
        milestoneCount = roadmap.totalMilestones
        updatedAt = .now
    }

    /// Helper to encode roadmap in nonisolated context
    nonisolated private static func encodeRoadmap(_ roadmap: GoalRoadmap) throws -> Data {
        try JSONEncoder().encode(roadmap)
    }

    /// Add progress snapshot
    func addProgressSnapshot(notes: String? = nil) {
        var history = decodedProgressHistory
        let snapshot = ProgressSnapshot(
            progress: progress,
            completedMilestones: completedMilestoneCount,
            totalMilestones: milestoneCount,
            notes: notes
        )
        history.append(snapshot)

        if let encoded = try? JSONEncoder().encode(history) {
            progressHistory = encoded
        }
        updatedAt = .now
    }

    /// Record a check-in
    func recordCheckIn() {
        totalCheckIns += 1

        // Update streak
        if let lastDate = lastCheckInDate {
            let daysSinceLastCheckIn = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSinceLastCheckIn <= (timeframeEnum?.checkInFrequency.intervalDays ?? 7) + 1 {
                checkInStreak += 1
            } else {
                checkInStreak = 1
            }
        } else {
            checkInStreak = 1
        }

        lastCheckInDate = .now

        // Calculate next check-in
        if let frequency = timeframeEnum?.checkInFrequency {
            nextCheckInSuggested = frequency.nextCheckInDate(from: .now)
        }

        updatedAt = .now
    }

    /// Update milestone counts
    func updateMilestoneCounts(completed: Int, total: Int) {
        completedMilestoneCount = completed
        milestoneCount = total

        // Auto-update progress based on milestones
        if total > 0 {
            progress = Double(completed) / Double(total)
            if progress >= 1.0 && !isCompleted {
                complete()
            }
        }

        updatedAt = .now
    }

    /// Update from Supabase
    func update(from supabaseGoal: SupabaseGoal) {
        title = supabaseGoal.title
        goalDescription = supabaseGoal.description
        targetDate = supabaseGoal.targetDate
        category = supabaseGoal.category
        isCompleted = supabaseGoal.isCompleted ?? false
        progress = supabaseGoal.progress ?? 0
        completedAt = supabaseGoal.completedAt
        isSpecific = supabaseGoal.isSpecific ?? false
        isMeasurable = supabaseGoal.isMeasurable ?? false
        isAchievable = supabaseGoal.isAchievable ?? false
        isRelevant = supabaseGoal.isRelevant ?? false
        isTimeBound = supabaseGoal.isTimeBound ?? false
        updatedAt = supabaseGoal.updatedAt ?? .now
    }

    /// Create Goal from Supabase goal
    convenience init(from supabaseGoal: SupabaseGoal) {
        self.init(
            id: supabaseGoal.id,
            userId: supabaseGoal.userId,
            title: supabaseGoal.title,
            goalDescription: supabaseGoal.description,
            targetDate: supabaseGoal.targetDate,
            category: supabaseGoal.category,
            isCompleted: supabaseGoal.isCompleted ?? false,
            progress: supabaseGoal.progress ?? 0,
            completedAt: supabaseGoal.completedAt,
            isSpecific: supabaseGoal.isSpecific ?? false,
            isMeasurable: supabaseGoal.isMeasurable ?? false,
            isAchievable: supabaseGoal.isAchievable ?? false,
            isRelevant: supabaseGoal.isRelevant ?? false,
            isTimeBound: supabaseGoal.isTimeBound ?? false,
            createdAt: supabaseGoal.createdAt ?? .now,
            updatedAt: supabaseGoal.updatedAt ?? .now
        )
    }

    /// Convert to Supabase goal for syncing
    func toSupabase(userId: UUID) -> SupabaseGoal {
        SupabaseGoal(from: self, userId: userId)
    }
}

// MARK: - Goal Category
enum GoalCategory: String, Codable, CaseIterable, Sendable {
    case career
    case health
    case personal
    case financial
    case education
    case relationships
    case other

    var displayName: String {
        switch self {
        case .career: return "Career"
        case .health: return "Health"
        case .personal: return "Personal"
        case .financial: return "Financial"
        case .education: return "Education"
        case .relationships: return "Relationships"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .career: return "briefcase.fill"
        case .health: return "heart.fill"
        case .personal: return "person.fill"
        case .financial: return "dollarsign.circle.fill"
        case .education: return "book.fill"
        case .relationships: return "person.2.fill"
        case .other: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .career: return Theme.Colors.aiBlue
        case .health: return Theme.Colors.success
        case .personal: return Theme.Colors.aiPurple
        case .financial: return Theme.Colors.warning
        case .education: return Theme.Colors.aiCyan
        case .relationships: return Theme.Colors.accent
        case .other: return Theme.Colors.textSecondary
        }
    }
}

// MARK: - Supabase Goal DTO
struct SupabaseGoal: Codable, Sendable {
    let id: UUID
    let userId: UUID
    var title: String
    var description: String?
    var targetDate: Date?
    var category: String?

    // Timeframe & Hierarchy
    var timeframe: String?
    var parentGoalId: UUID?
    var sortOrder: Int?

    // Progress
    var isCompleted: Bool?
    var progress: Double?
    var completedAt: Date?

    // SMART
    var isSpecific: Bool?
    var isMeasurable: Bool?
    var isAchievable: Bool?
    var isRelevant: Bool?
    var isTimeBound: Bool?

    // AI Analysis
    var aiRoadmap: Data?
    var aiRefinedTitle: String?
    var aiRefinedDescription: String?
    var aiObstacles: [String]?
    var aiSuccessMetrics: [String]?
    var aiMotivationalQuote: String?
    var aiAnalyzedAt: Date?

    // Coaching
    var lastCheckInDate: Date?
    var checkInStreak: Int?
    var totalCheckIns: Int?
    var nextCheckInSuggested: Date?

    // Gamification
    var pointsAwarded: Int?
    var milestoneCount: Int?
    var completedMilestoneCount: Int?
    var linkedTaskCount: Int?

    // Timestamps
    var createdAt: Date?
    var updatedAt: Date?

    init(from goal: Goal, userId: UUID) {
        self.id = goal.id
        self.userId = userId
        self.title = goal.title
        self.description = goal.goalDescription
        self.targetDate = goal.targetDate
        self.category = goal.category
        self.timeframe = goal.timeframe
        self.parentGoalId = goal.parentGoalId
        self.sortOrder = goal.sortOrder
        self.isCompleted = goal.isCompleted
        self.progress = goal.progress
        self.completedAt = goal.completedAt
        self.isSpecific = goal.isSpecific
        self.isMeasurable = goal.isMeasurable
        self.isAchievable = goal.isAchievable
        self.isRelevant = goal.isRelevant
        self.isTimeBound = goal.isTimeBound
        self.aiRoadmap = goal.aiRoadmap
        self.aiRefinedTitle = goal.aiRefinedTitle
        self.aiRefinedDescription = goal.aiRefinedDescription
        self.aiObstacles = goal.aiObstacles
        self.aiSuccessMetrics = goal.aiSuccessMetrics
        self.aiMotivationalQuote = goal.aiMotivationalQuote
        self.aiAnalyzedAt = goal.aiAnalyzedAt
        self.lastCheckInDate = goal.lastCheckInDate
        self.checkInStreak = goal.checkInStreak
        self.totalCheckIns = goal.totalCheckIns
        self.nextCheckInSuggested = goal.nextCheckInSuggested
        self.pointsAwarded = goal.pointsAwarded
        self.milestoneCount = goal.milestoneCount
        self.completedMilestoneCount = goal.completedMilestoneCount
        self.linkedTaskCount = goal.linkedTaskCount
        self.createdAt = goal.createdAt
        self.updatedAt = goal.updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case targetDate = "target_date"
        case category
        case timeframe
        case parentGoalId = "parent_goal_id"
        case sortOrder = "sort_order"
        case isCompleted = "is_completed"
        case progress
        case completedAt = "completed_at"
        case isSpecific = "is_specific"
        case isMeasurable = "is_measurable"
        case isAchievable = "is_achievable"
        case isRelevant = "is_relevant"
        case isTimeBound = "is_time_bound"
        case aiRoadmap = "ai_roadmap"
        case aiRefinedTitle = "ai_refined_title"
        case aiRefinedDescription = "ai_refined_description"
        case aiObstacles = "ai_obstacles"
        case aiSuccessMetrics = "ai_success_metrics"
        case aiMotivationalQuote = "ai_motivational_quote"
        case aiAnalyzedAt = "ai_analyzed_at"
        case lastCheckInDate = "last_check_in_date"
        case checkInStreak = "check_in_streak"
        case totalCheckIns = "total_check_ins"
        case nextCheckInSuggested = "next_check_in_suggested"
        case pointsAwarded = "points_awarded"
        case milestoneCount = "milestone_count"
        case completedMilestoneCount = "completed_milestone_count"
        case linkedTaskCount = "linked_task_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
