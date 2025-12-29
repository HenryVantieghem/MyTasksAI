//
//  Pact.swift
//  Veloce
//
//  Pact Model - Mutual Accountability Streaks
//  If one person fails, both lose the streak
//

import Foundation

// MARK: - Pact Commitment Type
enum PactCommitmentType: String, Codable, Sendable, CaseIterable {
    case dailyTasks = "daily_tasks"
    case focusTime = "focus_time"
    case goalProgress = "goal_progress"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .dailyTasks: return "Daily Tasks"
        case .focusTime: return "Focus Time"
        case .goalProgress: return "Goal Progress"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .dailyTasks: return "checkmark.circle.fill"
        case .focusTime: return "timer"
        case .goalProgress: return "target"
        case .custom: return "sparkles"
        }
    }

    var unit: String {
        switch self {
        case .dailyTasks: return "tasks"
        case .focusTime: return "minutes"
        case .goalProgress: return "%"
        case .custom: return ""
        }
    }

    var defaultTarget: Int {
        switch self {
        case .dailyTasks: return 3
        case .focusTime: return 30
        case .goalProgress: return 10
        case .custom: return 1
        }
    }
}

// MARK: - Pact Status
enum PactStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case active
    case completed
    case broken

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .completed: return "Completed"
        case .broken: return "Broken"
        }
    }

    var color: String {
        switch self {
        case .pending: return "yellow"
        case .active: return "green"
        case .completed: return "blue"
        case .broken: return "red"
        }
    }
}

// MARK: - Pact Model
struct Pact: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let initiatorId: UUID
    let partnerId: UUID

    // The Commitment
    var commitmentType: PactCommitmentType
    var targetValue: Int
    var customDescription: String?

    // Status
    var status: PactStatus
    var acceptedAt: Date?
    var brokenAt: Date?
    var brokenByUserId: UUID?

    // The Mutual Streak
    var currentStreak: Int
    var longestStreak: Int
    var initiatorCompletedToday: Bool
    var partnerCompletedToday: Bool
    var lastCheckedDate: Date?

    // Protection
    var shieldActive: Bool
    var shieldUsedAt: Date?

    // Gamification
    var xpEarned: Int
    var milestonesReached: [Int]

    // Timestamps
    let createdAt: Date?
    var updatedAt: Date?

    // Joined user data (populated from queries)
    var initiator: FriendProfile?
    var partner: FriendProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case initiatorId = "initiator_id"
        case partnerId = "partner_id"
        case commitmentType = "commitment_type"
        case targetValue = "target_value"
        case customDescription = "custom_description"
        case status
        case acceptedAt = "accepted_at"
        case brokenAt = "broken_at"
        case brokenByUserId = "broken_by_user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case initiatorCompletedToday = "initiator_completed_today"
        case partnerCompletedToday = "partner_completed_today"
        case lastCheckedDate = "last_checked_date"
        case shieldActive = "shield_active"
        case shieldUsedAt = "shield_used_at"
        case xpEarned = "xp_earned"
        case milestonesReached = "milestones_reached"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case initiator
        case partner
    }

    // MARK: - Computed Properties

    /// Get the partner user profile (relative to current user)
    func partnerProfile(currentUserId: UUID) -> FriendProfile? {
        if initiatorId == currentUserId {
            return partner
        } else {
            return initiator
        }
    }

    /// Check if current user is the initiator
    func isInitiator(currentUserId: UUID) -> Bool {
        initiatorId == currentUserId
    }

    /// Check if current user has completed today
    func hasCurrentUserCompletedToday(currentUserId: UUID) -> Bool {
        if initiatorId == currentUserId {
            return initiatorCompletedToday
        } else {
            return partnerCompletedToday
        }
    }

    /// Check if partner has completed today
    func hasPartnerCompletedToday(currentUserId: UUID) -> Bool {
        if initiatorId == currentUserId {
            return partnerCompletedToday
        } else {
            return initiatorCompletedToday
        }
    }

    /// Check if both have completed today
    var bothCompletedToday: Bool {
        initiatorCompletedToday && partnerCompletedToday
    }

    /// Get the user who broke the pact
    func brokenByUser(currentUserId: UUID) -> String {
        guard let brokenByUserId else { return "Unknown" }
        if brokenByUserId == currentUserId {
            return "You"
        } else {
            return partnerProfile(currentUserId: currentUserId)?.displayName ?? "Partner"
        }
    }

    /// Commitment description
    var commitmentDescription: String {
        switch commitmentType {
        case .dailyTasks:
            return "Complete \(targetValue) task\(targetValue == 1 ? "" : "s") per day"
        case .focusTime:
            return "Focus for \(targetValue) minutes per day"
        case .goalProgress:
            return "Make \(targetValue)% progress on goal"
        case .custom:
            return customDescription ?? "Custom commitment"
        }
    }

    /// Status for display
    func statusForUser(currentUserId: UUID) -> PactUserStatus {
        guard status == .active else {
            return .inactive
        }

        let userCompleted = hasCurrentUserCompletedToday(currentUserId: currentUserId)
        let partnerCompleted = hasPartnerCompletedToday(currentUserId: currentUserId)

        if userCompleted && partnerCompleted {
            return .bothDone
        } else if userCompleted && !partnerCompleted {
            return .waitingOnPartner
        } else if !userCompleted && partnerCompleted {
            return .waitingOnYou
        } else {
            return .neitherDone
        }
    }

    /// Next milestone
    var nextMilestone: Int? {
        let milestones = [7, 30, 100]
        for milestone in milestones {
            if currentStreak < milestone {
                return milestone
            }
        }
        return nil
    }

    /// Days until next milestone
    var daysUntilNextMilestone: Int? {
        guard let next = nextMilestone else { return nil }
        return next - currentStreak
    }
}

// MARK: - Pact User Status
enum PactUserStatus: String, Sendable {
    case bothDone
    case waitingOnPartner
    case waitingOnYou
    case neitherDone
    case inactive

    var displayText: String {
        switch self {
        case .bothDone: return "Both done!"
        case .waitingOnPartner: return "Waiting on partner"
        case .waitingOnYou: return "Your turn!"
        case .neitherDone: return "Get started"
        case .inactive: return "Inactive"
        }
    }

    var icon: String {
        switch self {
        case .bothDone: return "checkmark.circle.fill"
        case .waitingOnPartner: return "hourglass"
        case .waitingOnYou: return "exclamationmark.circle.fill"
        case .neitherDone: return "circle"
        case .inactive: return "pause.circle"
        }
    }

    var color: String {
        switch self {
        case .bothDone: return "green"
        case .waitingOnPartner: return "blue"
        case .waitingOnYou: return "orange"
        case .neitherDone: return "gray"
        case .inactive: return "gray"
        }
    }
}

// MARK: - Create Pact Request
struct CreatePactRequest: Codable, Sendable {
    let initiatorId: UUID
    let partnerId: UUID
    let commitmentType: String
    let targetValue: Int
    let customDescription: String?
    let status: String

    init(
        initiatorId: UUID,
        partnerId: UUID,
        commitmentType: PactCommitmentType,
        targetValue: Int,
        customDescription: String? = nil
    ) {
        self.initiatorId = initiatorId
        self.partnerId = partnerId
        self.commitmentType = commitmentType.rawValue
        self.targetValue = targetValue
        self.customDescription = customDescription
        self.status = "pending"
    }

    enum CodingKeys: String, CodingKey {
        case initiatorId = "initiator_id"
        case partnerId = "partner_id"
        case commitmentType = "commitment_type"
        case targetValue = "target_value"
        case customDescription = "custom_description"
        case status
    }
}

// MARK: - Update Pact Request
struct UpdatePactRequest: Codable, Sendable {
    var status: String?
    var acceptedAt: Date?
    var initiatorCompletedToday: Bool?
    var partnerCompletedToday: Bool?
    var shieldActive: Bool?
    var updatedAt: Date

    init(
        status: PactStatus? = nil,
        acceptedAt: Date? = nil,
        initiatorCompletedToday: Bool? = nil,
        partnerCompletedToday: Bool? = nil,
        shieldActive: Bool? = nil
    ) {
        self.status = status?.rawValue
        self.acceptedAt = acceptedAt
        self.initiatorCompletedToday = initiatorCompletedToday
        self.partnerCompletedToday = partnerCompletedToday
        self.shieldActive = shieldActive
        self.updatedAt = .now
    }

    enum CodingKeys: String, CodingKey {
        case status
        case acceptedAt = "accepted_at"
        case initiatorCompletedToday = "initiator_completed_today"
        case partnerCompletedToday = "partner_completed_today"
        case shieldActive = "shield_active"
        case updatedAt = "updated_at"
    }
}

// MARK: - Pact Activity
struct PactActivity: Codable, Identifiable, Sendable {
    let id: UUID
    let pactId: UUID
    let userId: UUID
    let activityType: PactActivityType
    var details: [String: String]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case pactId = "pact_id"
        case userId = "user_id"
        case activityType = "activity_type"
        case details
        case createdAt = "created_at"
    }
}

enum PactActivityType: String, Codable, Sendable {
    case created
    case accepted
    case declined
    case progress
    case milestone
    case broken
    case completed
    case shieldUsed = "shield_used"

    var displayName: String {
        switch self {
        case .created: return "Created"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .progress: return "Progress"
        case .milestone: return "Milestone"
        case .broken: return "Broken"
        case .completed: return "Completed"
        case .shieldUsed: return "Shield Used"
        }
    }

    var icon: String {
        switch self {
        case .created: return "plus.circle.fill"
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .progress: return "arrow.up.circle.fill"
        case .milestone: return "star.fill"
        case .broken: return "heart.slash.fill"
        case .completed: return "flag.checkered"
        case .shieldUsed: return "shield.fill"
        }
    }
}
