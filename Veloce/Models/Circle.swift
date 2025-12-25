//
//  Circle.swift
//  Veloce
//
//  Circle Model - Accountability groups for Velocity Circles
//  Social productivity feature for friend groups
//

import Foundation
import SwiftUI

// MARK: - Circle Role
enum CircleRole: String, Codable, Sendable, CaseIterable {
    case owner
    case admin
    case member

    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }

    var canInvite: Bool {
        self == .owner || self == .admin
    }

    var canRemoveMembers: Bool {
        self == .owner || self == .admin
    }

    var canEditCircle: Bool {
        self == .owner || self == .admin
    }
}

// MARK: - Circle Visibility
enum CircleVisibility: String, Codable, Sendable, CaseIterable {
    case full      // See task titles and details
    case momentum  // See % progress, streaks, levels
    case minimal   // Only see if active today

    var displayName: String {
        switch self {
        case .full: return "Full Details"
        case .momentum: return "Momentum Only"
        case .minimal: return "Active Status"
        }
    }

    var description: String {
        switch self {
        case .full: return "Friends can see your task titles"
        case .momentum: return "Friends see your progress & streaks"
        case .minimal: return "Friends only see if you're active"
        }
    }

    var icon: String {
        switch self {
        case .full: return "eye"
        case .momentum: return "flame"
        case .minimal: return "circle.fill"
        }
    }
}

// MARK: - Circle Activity Type
enum CircleActivityType: String, Codable, Sendable, CaseIterable {
    case taskCompleted = "task_completed"
    case streakMilestone = "streak_milestone"
    case levelUp = "level_up"
    case achievement
    case goalProgress = "goal_progress"
    case joined

    var displayName: String {
        switch self {
        case .taskCompleted: return "Task Completed"
        case .streakMilestone: return "Streak Milestone"
        case .levelUp: return "Level Up"
        case .achievement: return "Achievement"
        case .goalProgress: return "Goal Progress"
        case .joined: return "Joined Circle"
        }
    }

    var icon: String {
        switch self {
        case .taskCompleted: return "checkmark.circle.fill"
        case .streakMilestone: return "flame.fill"
        case .levelUp: return "arrow.up.circle.fill"
        case .achievement: return "trophy.fill"
        case .goalProgress: return "target"
        case .joined: return "person.badge.plus"
        }
    }

    var color: Color {
        switch self {
        case .taskCompleted: return .green
        case .streakMilestone: return .orange
        case .levelUp: return .purple
        case .achievement: return .yellow
        case .goalProgress: return .blue
        case .joined: return .cyan
        }
    }
}

// MARK: - Circle Model (renamed to avoid SwiftUI.Circle conflict)
struct SocialCircle: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    let inviteCode: String
    let createdBy: UUID
    var maxMembers: Int
    var circleStreak: Int
    var circleXp: Int
    var avatarUrl: String?
    let createdAt: Date?
    var updatedAt: Date?

    // Joined data (populated from queries)
    var members: [CircleMember]?
    var recentActivity: [CircleActivity]?
    var creator: FriendProfile?

    var memberCount: Int {
        members?.count ?? 0
    }

    var isFull: Bool {
        memberCount >= maxMembers
    }

    var formattedInviteCode: String {
        inviteCode.uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case maxMembers = "max_members"
        case circleStreak = "circle_streak"
        case circleXp = "circle_xp"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case members
        case recentActivity = "recent_activity"
        case creator
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SocialCircle, rhs: SocialCircle) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Circle Member
struct CircleMember: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let circleId: UUID
    let userId: UUID
    var role: CircleRole
    var visibility: CircleVisibility
    let joinedAt: Date?

    // Joined user data
    var user: FriendProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case circleId = "circle_id"
        case userId = "user_id"
        case role
        case visibility
        case joinedAt = "joined_at"
        case user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CircleMember, rhs: CircleMember) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Circle Activity
struct CircleActivity: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let circleId: UUID
    let userId: UUID
    let activityType: CircleActivityType
    var pointsEarned: Int
    var message: String?
    var metadata: [String: String]?
    let createdAt: Date?

    // Joined user data
    var user: FriendProfile?

    var formattedTime: String {
        guard let createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: .now)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case circleId = "circle_id"
        case userId = "user_id"
        case activityType = "activity_type"
        case pointsEarned = "points_earned"
        case message
        case metadata
        case createdAt = "created_at"
        case user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CircleActivity, rhs: CircleActivity) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Create Circle Request
struct CreateCircleRequest: Codable, Sendable {
    let name: String
    let description: String?
    let createdBy: UUID
    let maxMembers: Int

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case createdBy = "created_by"
        case maxMembers = "max_members"
    }
}

// MARK: - Join Circle Request
struct JoinCircleMemberRequest: Codable, Sendable {
    let circleId: UUID
    let userId: UUID
    let role: String
    let visibility: String

    init(circleId: UUID, userId: UUID, role: CircleRole = .member, visibility: CircleVisibility = .momentum) {
        self.circleId = circleId
        self.userId = userId
        self.role = role.rawValue
        self.visibility = visibility.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case circleId = "circle_id"
        case userId = "user_id"
        case role
        case visibility
    }
}

// MARK: - Post Activity Request
struct PostActivityRequest: Codable, Sendable {
    let circleId: UUID
    let userId: UUID
    let activityType: String
    let pointsEarned: Int
    let message: String?

    init(circleId: UUID, userId: UUID, type: CircleActivityType, points: Int, message: String? = nil) {
        self.circleId = circleId
        self.userId = userId
        self.activityType = type.rawValue
        self.pointsEarned = points
        self.message = message
    }

    enum CodingKeys: String, CodingKey {
        case circleId = "circle_id"
        case userId = "user_id"
        case activityType = "activity_type"
        case pointsEarned = "points_earned"
        case message
    }
}
