//
//  Friendship.swift
//  Veloce
//
//  Friendship Model - Friend connections and requests
//  Part of Velocity Circles social feature
//

import Foundation

// MARK: - Friendship Status
enum FriendshipStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case accepted
    case declined
    case blocked

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Friends"
        case .declined: return "Declined"
        case .blocked: return "Blocked"
        }
    }
}

// MARK: - Friendship Model
struct Friendship: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let requesterId: UUID
    let addresseeId: UUID
    var status: FriendshipStatus
    let createdAt: Date?
    var updatedAt: Date?

    // Joined user data (populated from queries)
    var requester: FriendProfile?
    var addressee: FriendProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case requester
        case addressee
    }

    // Get the other user in this friendship (relative to current user)
    func otherUser(currentUserId: UUID) -> FriendProfile? {
        if requesterId == currentUserId {
            return addressee
        } else {
            return requester
        }
    }

    // Check if current user is the requester
    func isRequester(currentUserId: UUID) -> Bool {
        requesterId == currentUserId
    }
}

// MARK: - Friend Profile (Lightweight user info for display)
struct FriendProfile: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var username: String?
    var fullName: String?
    var avatarUrl: String?
    var currentStreak: Int?
    var currentLevel: Int?
    var totalPoints: Int?
    var tasksCompletedToday: Int?

    var displayName: String {
        fullName ?? username ?? "User"
    }

    var atUsername: String? {
        username.map { "@\($0)" }
    }

    /// Convenience alias for tasksCompletedToday
    var todayTasksCompleted: Int? {
        tasksCompletedToday
    }

    /// Whether user was recently active (stub - would need real data)
    var isActiveNow: Bool {
        // In a real app, this would check last activity timestamp
        false
    }

    /// Focus minutes today (stub - would need real data)
    var todayFocusMinutes: Int? {
        nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case currentStreak = "current_streak"
        case currentLevel = "current_level"
        case totalPoints = "total_points"
        case tasksCompletedToday = "tasks_completed_today"
    }
}

// MARK: - Friend Request (For creating new requests)
struct FriendRequest: Codable, Sendable {
    let requesterId: UUID
    let addresseeId: UUID
    let status: String

    init(requesterId: UUID, addresseeId: UUID) {
        self.requesterId = requesterId
        self.addresseeId = addresseeId
        self.status = "pending"
    }

    enum CodingKeys: String, CodingKey {
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
    }
}

// MARK: - Friendship Update (For accepting/declining)
struct FriendshipUpdate: Codable, Sendable {
    let status: String
    let updatedAt: Date

    init(status: FriendshipStatus) {
        self.status = status.rawValue
        self.updatedAt = .now
    }

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}
