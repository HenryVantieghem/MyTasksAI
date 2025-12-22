//
//  GoalMilestone.swift
//  MyTasksAI
//
//  Goal Milestone Model - SwiftData + Supabase compatible
//  Represents checkpoints within a goal's roadmap
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Goal Milestone Model
@Model
final class GoalMilestone {
    // MARK: Core Properties
    var id: UUID
    var goalId: UUID
    var userId: UUID?
    var title: String
    var milestoneDescription: String?

    // MARK: Scheduling
    var targetDate: Date?
    var sortOrder: Int

    // MARK: Progress
    var isCompleted: Bool
    var completedAt: Date?

    // MARK: Gamification
    var pointsValue: Int

    // MARK: AI Generation
    var aiGenerated: Bool
    var aiReasoning: String?
    var successIndicator: String?

    // MARK: Timestamps
    var createdAt: Date
    var updatedAt: Date

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        goalId: UUID,
        userId: UUID? = nil,
        title: String,
        milestoneDescription: String? = nil,
        targetDate: Date? = nil,
        sortOrder: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        pointsValue: Int = 50,
        aiGenerated: Bool = false,
        aiReasoning: String? = nil,
        successIndicator: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.goalId = goalId
        self.userId = userId
        self.title = title
        self.milestoneDescription = milestoneDescription
        self.targetDate = targetDate
        self.sortOrder = sortOrder
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.pointsValue = pointsValue
        self.aiGenerated = aiGenerated
        self.aiReasoning = aiReasoning
        self.successIndicator = successIndicator
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
extension GoalMilestone {
    /// Is milestone overdue
    var isOverdue: Bool {
        guard let targetDate, !isCompleted else { return false }
        return targetDate < Date()
    }

    /// Days remaining until target date
    var daysRemaining: Int? {
        guard let targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day
    }

    /// Days until or since target date (negative if overdue)
    var daysFromTarget: Int? {
        daysRemaining
    }

    /// Formatted days remaining string
    var daysRemainingFormatted: String {
        guard let days = daysRemaining else { return "No deadline" }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        if days == -1 { return "1 day overdue" }
        if days < 0 { return "\(abs(days)) days overdue" }
        return "\(days) days left"
    }

    /// Status color based on completion and due date
    var statusColor: Color {
        if isCompleted {
            return Theme.Colors.success
        } else if isOverdue {
            return Theme.Colors.error
        } else if let days = daysRemaining, days <= 3 {
            return Theme.Colors.warning
        }
        return Theme.Colors.textSecondary
    }

    /// Icon based on status
    var statusIcon: String {
        if isCompleted {
            return "checkmark.circle.fill"
        } else if isOverdue {
            return "exclamationmark.circle.fill"
        }
        return "circle"
    }
}

// MARK: - Methods
extension GoalMilestone {
    /// Mark milestone as completed
    func complete() {
        isCompleted = true
        completedAt = .now
        updatedAt = .now
    }

    /// Uncomplete milestone (revert)
    func uncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = .now
    }

    /// Toggle completion status
    func toggleCompletion() {
        if isCompleted {
            uncomplete()
        } else {
            complete()
        }
    }

    /// Update from Supabase
    func update(from supabaseMilestone: SupabaseGoalMilestone) {
        title = supabaseMilestone.title
        milestoneDescription = supabaseMilestone.description
        targetDate = supabaseMilestone.targetDate
        sortOrder = supabaseMilestone.sortOrder ?? 0
        isCompleted = supabaseMilestone.isCompleted ?? false
        completedAt = supabaseMilestone.completedAt
        pointsValue = supabaseMilestone.pointsValue ?? 50
        aiGenerated = supabaseMilestone.aiGenerated ?? false
        aiReasoning = supabaseMilestone.aiReasoning
        updatedAt = supabaseMilestone.updatedAt ?? .now
    }

    /// Create from Supabase milestone
    convenience init(from supabaseMilestone: SupabaseGoalMilestone) {
        self.init(
            id: supabaseMilestone.id,
            goalId: supabaseMilestone.goalId,
            userId: supabaseMilestone.userId,
            title: supabaseMilestone.title,
            milestoneDescription: supabaseMilestone.description,
            targetDate: supabaseMilestone.targetDate,
            sortOrder: supabaseMilestone.sortOrder ?? 0,
            isCompleted: supabaseMilestone.isCompleted ?? false,
            completedAt: supabaseMilestone.completedAt,
            pointsValue: supabaseMilestone.pointsValue ?? 50,
            aiGenerated: supabaseMilestone.aiGenerated ?? false,
            aiReasoning: supabaseMilestone.aiReasoning,
            createdAt: supabaseMilestone.createdAt ?? .now,
            updatedAt: supabaseMilestone.updatedAt ?? .now
        )
    }

    /// Convert to Supabase milestone for syncing
    func toSupabase(userId: UUID) -> SupabaseGoalMilestone {
        SupabaseGoalMilestone(from: self, userId: userId)
    }
}

// MARK: - Supabase Goal Milestone DTO
struct SupabaseGoalMilestone: Codable, Sendable {
    let id: UUID
    let goalId: UUID
    let userId: UUID
    var title: String
    var description: String?
    var targetDate: Date?
    var sortOrder: Int?
    var isCompleted: Bool?
    var completedAt: Date?
    var pointsValue: Int?
    var aiGenerated: Bool?
    var aiReasoning: String?
    var createdAt: Date?
    var updatedAt: Date?

    init(from milestone: GoalMilestone, userId: UUID) {
        self.id = milestone.id
        self.goalId = milestone.goalId
        self.userId = userId
        self.title = milestone.title
        self.description = milestone.milestoneDescription
        self.targetDate = milestone.targetDate
        self.sortOrder = milestone.sortOrder
        self.isCompleted = milestone.isCompleted
        self.completedAt = milestone.completedAt
        self.pointsValue = milestone.pointsValue
        self.aiGenerated = milestone.aiGenerated
        self.aiReasoning = milestone.aiReasoning
        self.createdAt = milestone.createdAt
        self.updatedAt = milestone.updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case userId = "user_id"
        case title
        case description
        case targetDate = "target_date"
        case sortOrder = "sort_order"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case pointsValue = "points_value"
        case aiGenerated = "ai_generated"
        case aiReasoning = "ai_reasoning"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Milestone Collection Extensions
extension Array where Element == GoalMilestone {
    /// Count of completed milestones
    var completedCount: Int {
        filter(\.isCompleted).count
    }

    /// Progress as a percentage (0.0 - 1.0)
    var progress: Double {
        guard !isEmpty else { return 0 }
        return Double(completedCount) / Double(count)
    }

    /// Progress string (e.g., "3/8")
    var progressString: String {
        "\(completedCount)/\(count)"
    }

    /// Total points value of all milestones
    var totalPointsValue: Int {
        reduce(0) { $0 + $1.pointsValue }
    }

    /// Points earned from completed milestones
    var earnedPoints: Int {
        filter(\.isCompleted).reduce(0) { $0 + $1.pointsValue }
    }

    /// Sorted by sort order
    var sorted: [GoalMilestone] {
        sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Next incomplete milestone
    var nextMilestone: GoalMilestone? {
        sorted.first { !$0.isCompleted }
    }

    /// Overdue milestones
    var overdue: [GoalMilestone] {
        filter(\.isOverdue)
    }

    /// Due soon (within 3 days)
    var dueSoon: [GoalMilestone] {
        filter { milestone in
            guard let days = milestone.daysRemaining, !milestone.isCompleted else { return false }
            return days >= 0 && days <= 3
        }
    }
}
