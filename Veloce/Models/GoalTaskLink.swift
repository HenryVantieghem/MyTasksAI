//
//  GoalTaskLink.swift
//  MyTasksAI
//
//  Goal-Task Linking Model - SwiftData + Supabase compatible
//  Connects tasks to goals with type classification and approval flow
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Goal Task Link Model
@Model
final class GoalTaskLink {
    // MARK: Core Properties
    var id: UUID
    var goalId: UUID
    var taskId: UUID
    var milestoneId: UUID?  // Optional: task linked to specific milestone

    // MARK: Classification
    var linkType: String  // GoalTaskLinkType.rawValue

    // MARK: Approval Flow (for AI suggestions)
    var isApproved: Bool
    var isPending: Bool  // Awaiting user approval
    var isRejected: Bool

    // MARK: Timestamps
    var createdAt: Date
    var approvedAt: Date?

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        goalId: UUID,
        taskId: UUID,
        milestoneId: UUID? = nil,
        linkType: GoalTaskLinkType = .directAction,
        isApproved: Bool = true,
        isPending: Bool = false,
        isRejected: Bool = false,
        createdAt: Date = .now,
        approvedAt: Date? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.taskId = taskId
        self.milestoneId = milestoneId
        self.linkType = linkType.rawValue
        self.isApproved = isApproved
        self.isPending = isPending
        self.isRejected = isRejected
        self.createdAt = createdAt
        self.approvedAt = isApproved ? (approvedAt ?? .now) : nil
    }
}

// MARK: - Computed Properties
extension GoalTaskLink {
    /// Link type as enum
    var linkTypeEnum: GoalTaskLinkType {
        GoalTaskLinkType(rawValue: linkType) ?? .directAction
    }

    /// Is this an AI-generated suggestion awaiting approval
    var isAISuggestion: Bool {
        isPending && !isApproved && !isRejected
    }

    /// Status for display
    var status: GoalTaskLinkStatus {
        if isRejected { return .rejected }
        if isPending { return .pending }
        if isApproved { return .approved }
        return .pending
    }
}

// MARK: - Methods
extension GoalTaskLink {
    /// Approve this link (for AI suggestions)
    func approve() {
        isApproved = true
        isPending = false
        isRejected = false
        approvedAt = .now
    }

    /// Reject this link (for AI suggestions)
    func reject() {
        isRejected = true
        isPending = false
        isApproved = false
    }

    /// Convert to Supabase DTO for syncing
    func toSupabase() -> SupabaseGoalTaskLink {
        SupabaseGoalTaskLink(from: self)
    }
}

// MARK: - Goal Task Link Type
enum GoalTaskLinkType: String, Codable, Sendable, CaseIterable {
    case directAction = "direct_action"  // Task directly advances the goal
    case habit = "habit"                  // Recurring task supporting the goal
    case milestone = "milestone"          // Task is a key milestone checkpoint
    case preparation = "preparation"      // Prep work required before main work

    var displayName: String {
        switch self {
        case .directAction: return "Direct Action"
        case .habit: return "Habit"
        case .milestone: return "Milestone"
        case .preparation: return "Preparation"
        }
    }

    var description: String {
        switch self {
        case .directAction:
            return "This task directly advances your goal"
        case .habit:
            return "A recurring habit that supports your goal"
        case .milestone:
            return "A key checkpoint in your goal journey"
        case .preparation:
            return "Preparation work needed before main tasks"
        }
    }

    var icon: String {
        switch self {
        case .directAction: return "arrow.right.circle.fill"
        case .habit: return "repeat.circle.fill"
        case .milestone: return "flag.circle.fill"
        case .preparation: return "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .directAction: return Theme.Colors.aiBlue
        case .habit: return Theme.Colors.aiGreen
        case .milestone: return Theme.Colors.aiPurple
        case .preparation: return Theme.Colors.warning
        }
    }

    /// Weight for progress calculation (milestones count more)
    var progressWeight: Double {
        switch self {
        case .directAction: return 1.0
        case .habit: return 0.5  // Habits are ongoing, less weight per completion
        case .milestone: return 2.0
        case .preparation: return 0.5
        }
    }
}

// MARK: - Goal Task Link Status
enum GoalTaskLinkStatus: String, Codable, Sendable {
    case pending   // AI suggested, awaiting approval
    case approved  // User approved
    case rejected  // User rejected

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.badge.questionmark"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending: return Theme.Colors.warning
        case .approved: return Theme.Colors.success
        case .rejected: return Theme.Colors.error
        }
    }
}

// MARK: - Supabase Goal Task Link DTO
struct SupabaseGoalTaskLink: Codable, Sendable {
    let id: UUID
    let goalId: UUID
    let taskId: UUID
    var milestoneId: UUID?
    var linkType: String
    var isApproved: Bool?
    var isPending: Bool?
    var isRejected: Bool?
    var createdAt: Date?
    var approvedAt: Date?

    init(from link: GoalTaskLink) {
        self.id = link.id
        self.goalId = link.goalId
        self.taskId = link.taskId
        self.milestoneId = link.milestoneId
        self.linkType = link.linkType
        self.isApproved = link.isApproved
        self.isPending = link.isPending
        self.isRejected = link.isRejected
        self.createdAt = link.createdAt
        self.approvedAt = link.approvedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case taskId = "task_id"
        case milestoneId = "milestone_id"
        case linkType = "link_type"
        case isApproved = "is_approved"
        case isPending = "is_pending"
        case isRejected = "is_rejected"
        case createdAt = "created_at"
        case approvedAt = "approved_at"
    }
}

// MARK: - Pending Task Suggestion
/// Represents an AI-suggested task before it's created
struct PendingTaskSuggestion: Identifiable, Codable, Sendable {
    let id: UUID
    let title: String
    let estimatedMinutes: Int?
    let linkType: GoalTaskLinkType
    let milestoneId: UUID?
    let aiReasoning: String?
    let priority: String?
    let suggestedSchedule: String?  // e.g., "morning", "daily", "weekdays"
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        title: String,
        estimatedMinutes: Int? = nil,
        linkType: GoalTaskLinkType = .directAction,
        milestoneId: UUID? = nil,
        aiReasoning: String? = nil,
        priority: String? = nil,
        suggestedSchedule: String? = nil,
        isSelected: Bool = true
    ) {
        self.id = id
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.linkType = linkType
        self.milestoneId = milestoneId
        self.aiReasoning = aiReasoning
        self.priority = priority
        self.suggestedSchedule = suggestedSchedule
        self.isSelected = isSelected
    }
}

// MARK: - Goal Task Link Collection Extensions
extension Array where Element == GoalTaskLink {
    /// Filter by type
    func ofType(_ type: GoalTaskLinkType) -> [GoalTaskLink] {
        filter { $0.linkTypeEnum == type }
    }

    /// Approved links only
    var approved: [GoalTaskLink] {
        filter(\.isApproved)
    }

    /// Pending links only (awaiting approval)
    var pending: [GoalTaskLink] {
        filter(\.isPending)
    }

    /// Links for a specific goal
    func forGoal(_ goalId: UUID) -> [GoalTaskLink] {
        filter { $0.goalId == goalId }
    }

    /// Links for a specific milestone
    func forMilestone(_ milestoneId: UUID) -> [GoalTaskLink] {
        filter { $0.milestoneId == milestoneId }
    }

    /// Count by type
    func count(ofType type: GoalTaskLinkType) -> Int {
        ofType(type).count
    }
}
