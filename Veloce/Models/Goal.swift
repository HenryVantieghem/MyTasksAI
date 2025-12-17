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

    // MARK: Progress
    var isCompleted: Bool
    var progress: Double  // 0.0 - 1.0
    var completedAt: Date?

    // MARK: SMART Criteria
    var isSpecific: Bool
    var isMeasurable: Bool
    var isAchievable: Bool
    var isRelevant: Bool
    var isTimeBound: Bool

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
        isCompleted: Bool = false,
        progress: Double = 0,
        completedAt: Date? = nil,
        isSpecific: Bool = false,
        isMeasurable: Bool = false,
        isAchievable: Bool = false,
        isRelevant: Bool = false,
        isTimeBound: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.goalDescription = goalDescription
        self.targetDate = targetDate
        self.category = category
        self.isCompleted = isCompleted
        self.progress = progress
        self.completedAt = completedAt
        self.isSpecific = isSpecific
        self.isMeasurable = isMeasurable
        self.isAchievable = isAchievable
        self.isRelevant = isRelevant
        self.isTimeBound = isTimeBound
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
    var isCompleted: Bool?
    var progress: Double?
    var createdAt: Date?
    var completedAt: Date?
    var isSpecific: Bool?
    var isMeasurable: Bool?
    var isAchievable: Bool?
    var isRelevant: Bool?
    var isTimeBound: Bool?
    var updatedAt: Date?

    init(from goal: Goal, userId: UUID) {
        self.id = goal.id
        self.userId = userId
        self.title = goal.title
        self.description = goal.goalDescription
        self.targetDate = goal.targetDate
        self.category = goal.category
        self.isCompleted = goal.isCompleted
        self.progress = goal.progress
        self.createdAt = goal.createdAt
        self.completedAt = goal.completedAt
        self.isSpecific = goal.isSpecific
        self.isMeasurable = goal.isMeasurable
        self.isAchievable = goal.isAchievable
        self.isRelevant = goal.isRelevant
        self.isTimeBound = goal.isTimeBound
        self.updatedAt = goal.updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case targetDate = "target_date"
        case category
        case isCompleted = "is_completed"
        case progress
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case isSpecific = "is_specific"
        case isMeasurable = "is_measurable"
        case isAchievable = "is_achievable"
        case isRelevant = "is_relevant"
        case isTimeBound = "is_time_bound"
        case updatedAt = "updated_at"
    }
}
