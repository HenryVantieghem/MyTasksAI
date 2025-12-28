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

    // MARK: Psychology-Based Features
    var actionSteps: Data?  // JSON encoded [GoalActionStep] - User's own steps
    var goalNotes: Data?  // JSON encoded [GoalNote] - User's progress notes
    var whyItMatters: String?  // Personal motivation (Implementation Intentions)
    var ifThenPlans: Data?  // JSON encoded [IfThenPlan] - WOOP obstacle plans
    var commitmentStatement: String?  // Public commitment device
    var visualizationNotes: String?  // Mental contrasting from WOOP

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
        actionSteps: Data? = nil,
        goalNotes: Data? = nil,
        whyItMatters: String? = nil,
        ifThenPlans: Data? = nil,
        commitmentStatement: String? = nil,
        visualizationNotes: String? = nil,
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
        self.actionSteps = actionSteps
        self.goalNotes = goalNotes
        self.whyItMatters = whyItMatters
        self.ifThenPlans = ifThenPlans
        self.commitmentStatement = commitmentStatement
        self.visualizationNotes = visualizationNotes
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
    var decodedRoadmap: GoalRoadmap? {
        guard let data = aiRoadmap else { return nil }
        return try? JSONDecoder().decode(GoalRoadmap.self, from: data)
    }

    /// Decoded progress history
    var decodedProgressHistory: [ProgressSnapshot] {
        guard let data = progressHistory else { return [] }
        return (try? JSONDecoder().decode([ProgressSnapshot].self, from: data)) ?? []
    }

    /// Decoded action steps
    var decodedActionSteps: [GoalActionStep] {
        guard let data = actionSteps else { return [] }
        return (try? JSONDecoder().decode([GoalActionStep].self, from: data)) ?? []
    }

    /// Decoded notes
    var decodedNotes: [GoalNote] {
        guard let data = goalNotes else { return [] }
        return (try? JSONDecoder().decode([GoalNote].self, from: data)) ?? []
    }

    /// Decoded if-then plans
    var decodedIfThenPlans: [IfThenPlan] {
        guard let data = ifThenPlans else { return [] }
        return (try? JSONDecoder().decode([IfThenPlan].self, from: data)) ?? []
    }

    /// Action steps completion progress
    var actionStepsProgress: Double {
        let steps = decodedActionSteps
        guard !steps.isEmpty else { return 0 }
        return Double(steps.filter(\.isCompleted).count) / Double(steps.count)
    }

    /// Has personal motivation set
    var hasPersonalMotivation: Bool {
        whyItMatters != nil && !(whyItMatters?.isEmpty ?? true)
    }

    /// Has obstacle plans
    var hasObstaclePlans: Bool {
        !decodedIfThenPlans.isEmpty
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
        aiRoadmap = try JSONEncoder().encode(roadmap)
        milestoneCount = roadmap.totalMilestones
        updatedAt = .now
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

    // MARK: - Psychology Features Methods

    /// Add a new action step
    func addActionStep(_ step: GoalActionStep) {
        var steps = decodedActionSteps
        steps.append(step)
        actionSteps = try? JSONEncoder().encode(steps)
        updatedAt = .now
    }

    /// Toggle action step completion
    func toggleActionStep(_ stepId: UUID) {
        var steps = decodedActionSteps
        if let index = steps.firstIndex(where: { $0.id == stepId }) {
            steps[index].isCompleted.toggle()
            steps[index].completedAt = steps[index].isCompleted ? .now : nil
            actionSteps = try? JSONEncoder().encode(steps)
            updatedAt = .now
        }
    }

    /// Remove action step
    func removeActionStep(_ stepId: UUID) {
        var steps = decodedActionSteps
        steps.removeAll { $0.id == stepId }
        actionSteps = try? JSONEncoder().encode(steps)
        updatedAt = .now
    }

    /// Add a note
    func addNote(_ note: GoalNote) {
        var notes = decodedNotes
        notes.insert(note, at: 0) // Most recent first
        goalNotes = try? JSONEncoder().encode(notes)
        updatedAt = .now
    }

    /// Remove a note
    func removeNote(_ noteId: UUID) {
        var notes = decodedNotes
        notes.removeAll { $0.id == noteId }
        goalNotes = try? JSONEncoder().encode(notes)
        updatedAt = .now
    }

    /// Add an if-then plan
    func addIfThenPlan(_ plan: IfThenPlan) {
        var plans = decodedIfThenPlans
        plans.append(plan)
        ifThenPlans = try? JSONEncoder().encode(plans)
        updatedAt = .now
    }

    /// Remove an if-then plan
    func removeIfThenPlan(_ planId: UUID) {
        var plans = decodedIfThenPlans
        plans.removeAll { $0.id == planId }
        ifThenPlans = try? JSONEncoder().encode(plans)
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

// MARK: - Psychology-Based Feature Models

/// Action step for breaking down goals (Implementation Intentions)
struct GoalActionStep: Codable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = .now,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

/// Note for tracking thoughts and progress
struct GoalNote: Codable, Identifiable, Sendable {
    var id: UUID
    var content: String
    var mood: NoteMood?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        mood: NoteMood? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.content = content
        self.mood = mood
        self.createdAt = createdAt
    }

    enum NoteMood: String, Codable, CaseIterable, Sendable {
        case motivated = "motivated"
        case focused = "focused"
        case challenged = "challenged"
        case stuck = "stuck"
        case celebrating = "celebrating"

        var icon: String {
            switch self {
            case .motivated: return "flame.fill"
            case .focused: return "target"
            case .challenged: return "figure.climbing"
            case .stuck: return "pause.circle.fill"
            case .celebrating: return "party.popper.fill"
            }
        }

        var color: Color {
            switch self {
            case .motivated: return .orange
            case .focused: return Theme.Colors.aiCyan
            case .challenged: return Theme.Colors.warning
            case .stuck: return Theme.Colors.error
            case .celebrating: return Theme.Colors.success
            }
        }
    }
}

/// If-Then Plan for obstacles (WOOP methodology)
struct IfThenPlan: Codable, Identifiable, Sendable {
    var id: UUID
    var obstacle: String  // "If this happens..."
    var response: String  // "Then I will..."
    var timesUsed: Int
    var lastUsedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        obstacle: String,
        response: String,
        timesUsed: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.obstacle = obstacle
        self.response = response
        self.timesUsed = timesUsed
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }
}

/// Progress snapshot for history
struct ProgressSnapshot: Codable, Sendable, Identifiable {
    var id: UUID
    var date: Date
    var progress: Double
    var completedMilestones: Int
    var totalMilestones: Int
    var notes: String?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        progress: Double,
        completedMilestones: Int = 0,
        totalMilestones: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.progress = progress
        self.completedMilestones = completedMilestones
        self.totalMilestones = totalMilestones
        self.notes = notes
    }
}
