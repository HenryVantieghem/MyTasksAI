//
//  SharedTask.swift
//  Veloce
//
//  Shared Task Model - Collaborative task sharing between friends
//  Part of Velocity Circles social feature
//

import Foundation
import SwiftUI

// MARK: - Shared Task Status
enum SharedTaskStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case accepted
    case declined

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Collaborating"
        case .declined: return "Declined"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return Theme.CelestialColors.auroraGreen
        case .declined: return Theme.CelestialColors.errorNebula
        }
    }
}

// MARK: - Shared Task Model
struct SharedTask: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let taskId: UUID
    let inviterId: UUID
    let inviteeId: UUID
    var status: SharedTaskStatus
    let invitedAt: Date?
    var respondedAt: Date?
    let createdAt: Date?
    var updatedAt: Date?

    // Joined data (populated from queries)
    var task: SharedTaskInfo?
    var inviter: FriendProfile?
    var invitee: FriendProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case inviterId = "inviter_id"
        case inviteeId = "invitee_id"
        case status
        case invitedAt = "invited_at"
        case respondedAt = "responded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case task = "tasks"  // Supabase joins use table name
        case inviter
        case invitee
    }

    // Check if current user is the inviter
    func isInviter(currentUserId: UUID) -> Bool {
        inviterId == currentUserId
    }

    // Check if current user is the invitee
    func isInvitee(currentUserId: UUID) -> Bool {
        inviteeId == currentUserId
    }

    // Get the other user in this share (relative to current user)
    func otherUser(currentUserId: UUID) -> FriendProfile? {
        if inviterId == currentUserId {
            return invitee
        } else {
            return inviter
        }
    }

    // Time since invitation
    var timeSinceInvited: String {
        guard let invitedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: invitedAt, relativeTo: .now)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SharedTask, rhs: SharedTask) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Shared Task Info (Lightweight task data for display)
struct SharedTaskInfo: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var scheduledTime: Date?
    var estimatedMinutes: Int?
    var starRating: Int?
    var taskIcon: String?
    var taskEmoji: String?
    var taskColorHex: String?
    var completedAt: Date?
    var pointsEarned: Int?

    var displayIcon: String {
        taskIcon ?? taskEmoji ?? "checkmark.circle"
    }

    var priorityStars: String {
        String(repeating: "★", count: starRating ?? 2)
    }

    var estimatedTimeFormatted: String? {
        guard let minutes = estimatedMinutes else { return nil }
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }

    var accentColor: Color {
        if let hex = taskColorHex {
            return Color(hex: hex) ?? Theme.Colors.aiPurple
        }
        return Theme.Colors.aiPurple
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted = "is_completed"
        case scheduledTime = "scheduled_time"
        case estimatedMinutes = "estimated_minutes"
        case starRating = "star_rating"
        case taskIcon = "task_icon"
        case taskEmoji = "task_emoji"
        case taskColorHex = "task_color_hex"
        case completedAt = "completed_at"
        case pointsEarned = "points_earned"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SharedTaskInfo, rhs: SharedTaskInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Create Shared Task Request
struct CreateSharedTaskRequest: Codable, Sendable {
    let taskId: UUID
    let inviterId: UUID
    let inviteeId: UUID
    let status: String

    init(taskId: UUID, inviterId: UUID, inviteeId: UUID) {
        self.taskId = taskId
        self.inviterId = inviterId
        self.inviteeId = inviteeId
        self.status = "pending"
    }

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case inviterId = "inviter_id"
        case inviteeId = "invitee_id"
        case status
    }
}

// MARK: - Shared Task Response Update
struct SharedTaskUpdate: Codable, Sendable {
    let status: String
    let respondedAt: Date
    let updatedAt: Date

    init(status: SharedTaskStatus) {
        self.status = status.rawValue
        self.respondedAt = .now
        self.updatedAt = .now
    }

    enum CodingKeys: String, CodingKey {
        case status
        case respondedAt = "responded_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Leaderboard Entry (For friend rankings)
struct LeaderboardEntry: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var username: String?
    var fullName: String?
    var avatarUrl: String?
    var currentStreak: Int
    var currentLevel: Int
    var totalPoints: Int
    var tasksCompleted: Int
    var tasksCompletedToday: Int
    var weeklyPoints: Int
    var lastActiveDate: Date?

    // Computed for display
    var rank: Int = 0
    var rankChange: Int = 0  // Positive = moved up, negative = moved down
    var isCurrentUser: Bool = false

    var displayName: String {
        fullName ?? username ?? "User"
    }

    var atUsername: String? {
        username.map { "@\($0)" }
    }

    var isActiveToday: Bool {
        guard let lastActive = lastActiveDate else { return false }
        return Calendar.current.isDateInToday(lastActive)
    }

    var streakEmoji: String {
        if currentStreak >= 30 { return "🔥" }
        if currentStreak >= 7 { return "⚡" }
        if currentStreak >= 3 { return "✨" }
        return "🌱"
    }

    var levelBadge: String {
        switch currentLevel {
        case 0...5: return "🌑"  // Novice
        case 6...15: return "🌙"  // Intermediate
        case 16...30: return "⭐"  // Advanced
        case 31...50: return "🌟"  // Expert
        default: return "💫"  // Master
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case currentStreak = "current_streak"
        case currentLevel = "current_level"
        case totalPoints = "total_points"
        case tasksCompleted = "tasks_completed"
        case tasksCompletedToday = "tasks_completed_today"
        case weeklyPoints = "weekly_points"
        case lastActiveDate = "last_active_date"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Leaderboard Period
enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case allTime = "All Time"

    var id: String { rawValue }

    var sortKey: String {
        switch self {
        case .today: return "tasks_completed_today"
        case .week: return "weekly_points"
        case .month: return "total_points"  // Could add monthly_points column
        case .allTime: return "total_points"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .week: return "calendar.badge.clock"
        case .month: return "calendar"
        case .allTime: return "trophy.fill"
        }
    }
}

// MARK: - Sample Data (for previews)
extension SharedTask {
    static let sample = SharedTask(
        id: UUID(),
        taskId: UUID(),
        inviterId: UUID(),
        inviteeId: UUID(),
        status: .pending,
        invitedAt: .now.addingTimeInterval(-3600),
        respondedAt: nil,
        createdAt: .now.addingTimeInterval(-3600),
        updatedAt: nil,
        task: SharedTaskInfo.sample,
        inviter: FriendProfile(
            id: UUID(),
            username: "alex_dev",
            fullName: "Alex Chen",
            avatarUrl: nil,
            currentStreak: 7,
            currentLevel: 12,
            totalPoints: 2500,
            tasksCompletedToday: 5
        ),
        invitee: nil
    )
}

extension SharedTaskInfo {
    static let sample = SharedTaskInfo(
        id: UUID(),
        title: "Complete project proposal",
        isCompleted: false,
        scheduledTime: .now.addingTimeInterval(3600),
        estimatedMinutes: 45,
        starRating: 3,
        taskIcon: nil,
        taskEmoji: "📝",
        taskColorHex: nil,
        completedAt: nil,
        pointsEarned: nil
    )
}

extension LeaderboardEntry {
    static let samples: [LeaderboardEntry] = [
        LeaderboardEntry(
            id: UUID(),
            username: "speed_demon",
            fullName: "Sarah Kim",
            avatarUrl: nil,
            currentStreak: 45,
            currentLevel: 28,
            totalPoints: 12500,
            tasksCompleted: 342,
            tasksCompletedToday: 12,
            weeklyPoints: 850,
            lastActiveDate: .now,
            rank: 1,
            rankChange: 0,
            isCurrentUser: false
        ),
        LeaderboardEntry(
            id: UUID(),
            username: "focus_master",
            fullName: "Mike Johnson",
            avatarUrl: nil,
            currentStreak: 21,
            currentLevel: 22,
            totalPoints: 8900,
            tasksCompleted: 256,
            tasksCompletedToday: 8,
            weeklyPoints: 620,
            lastActiveDate: .now,
            rank: 2,
            rankChange: 1,
            isCurrentUser: true
        ),
        LeaderboardEntry(
            id: UUID(),
            username: "productivity_pro",
            fullName: "Emma Davis",
            avatarUrl: nil,
            currentStreak: 14,
            currentLevel: 19,
            totalPoints: 7200,
            tasksCompleted: 198,
            tasksCompletedToday: 6,
            weeklyPoints: 480,
            lastActiveDate: .now.addingTimeInterval(-86400),
            rank: 3,
            rankChange: -1,
            isCurrentUser: false
        )
    ]
}
