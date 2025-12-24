//
//  User.swift
//  MyTasksAI
//
//  User Model - SwiftData + Supabase compatible
//  Represents a user profile with gamification stats
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - User Model
@Model
final class User {
    // MARK: Core Properties
    var id: UUID
    var email: String?
    var fullName: String?
    var username: String?
    var avatarUrl: String?

    // MARK: Gamification
    var totalPoints: Int
    var currentLevel: Int
    var currentStreak: Int
    var longestStreak: Int
    var tasksCompleted: Int
    var tasksCompletedOnTime: Int

    // MARK: Goals
    var dailyTaskGoal: Int
    var weeklyTaskGoal: Int

    // MARK: Settings
    var notificationsEnabled: Bool
    var calendarSyncEnabled: Bool
    var hapticsEnabled: Bool
    var theme: String  // "auto", "light", "dark"

    // MARK: Timestamps
    var lastActiveDate: Date?
    var createdAt: Date
    var updatedAt: Date

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        email: String? = nil,
        fullName: String? = nil,
        username: String? = nil,
        avatarUrl: String? = nil,
        totalPoints: Int = 0,
        currentLevel: Int = 1,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        tasksCompleted: Int = 0,
        tasksCompletedOnTime: Int = 0,
        dailyTaskGoal: Int = 5,
        weeklyTaskGoal: Int = 25,
        notificationsEnabled: Bool = true,
        calendarSyncEnabled: Bool = false,
        hapticsEnabled: Bool = true,
        theme: String = "auto",
        lastActiveDate: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.username = username
        self.avatarUrl = avatarUrl
        self.totalPoints = totalPoints
        self.currentLevel = currentLevel
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.tasksCompleted = tasksCompleted
        self.tasksCompletedOnTime = tasksCompletedOnTime
        self.dailyTaskGoal = dailyTaskGoal
        self.weeklyTaskGoal = weeklyTaskGoal
        self.notificationsEnabled = notificationsEnabled
        self.calendarSyncEnabled = calendarSyncEnabled
        self.hapticsEnabled = hapticsEnabled
        self.theme = theme
        self.lastActiveDate = lastActiveDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
extension User {
    /// Display name (full name, username, or email)
    var displayName: String {
        fullName ?? username ?? email ?? "User"
    }

    /// First name only
    var firstName: String {
        fullName?.components(separatedBy: " ").first ?? "User"
    }

    /// Level title based on current level
    var levelTitle: String {
        switch currentLevel {
        case 1: return "Beginner"
        case 2: return "Novice"
        case 3: return "Learner"
        case 4: return "Practitioner"
        case 5: return "Skilled"
        case 6: return "Advanced"
        case 7: return "Expert"
        case 8: return "Master"
        case 9: return "Legend"
        case 10...: return "Grandmaster"
        default: return "Beginner"
        }
    }

    /// Achievement count (placeholder)
    var achievementCount: Int { 0 }

    /// Level progress (0.0 - 1.0)
    var levelProgress: Double {
        DesignTokens.Gamification.progressToNextLevel(points: totalPoints)
    }

    /// Points needed for next level
    var pointsToNextLevel: Int {
        _ = DesignTokens.Gamification.pointsForLevel(currentLevel - 1)
        let nextLevelPoints = DesignTokens.Gamification.pointsForLevel(currentLevel)
        return max(0, nextLevelPoints - totalPoints)
    }

    /// Task completion rate
    var completionRate: Double {
        guard tasksCompleted > 0 else { return 0 }
        return Double(tasksCompletedOnTime) / Double(tasksCompleted)
    }

    /// Formatted completion rate
    var formattedCompletionRate: String {
        "\(Int(completionRate * 100))%"
    }

    /// Streak badge color
    var streakColor: Color {
        switch currentStreak {
        case 0..<DesignTokens.Gamification.streakBronze:
            return Theme.Colors.textSecondary
        case DesignTokens.Gamification.streakBronze..<DesignTokens.Gamification.streakSilver:
            return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze
        case DesignTokens.Gamification.streakSilver..<DesignTokens.Gamification.streakGold:
            return Color(red: 0.75, green: 0.75, blue: 0.75)  // Silver
        case DesignTokens.Gamification.streakGold..<DesignTokens.Gamification.streakDiamond:
            return Color(red: 1.0, green: 0.84, blue: 0)  // Gold
        default:
            return Theme.Colors.aiPurple  // Diamond
        }
    }

    /// Theme as ColorScheme
    var colorScheme: ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - Methods
extension User {
    /// Add points and update level
    func addPoints(_ points: Int) {
        totalPoints += points
        let newLevel = DesignTokens.Gamification.level(for: totalPoints)
        if newLevel > currentLevel {
            currentLevel = newLevel
        }
        updatedAt = .now
    }

    /// Update streak
    func updateStreak(metGoalToday: Bool) {
        if metGoalToday {
            currentStreak += 1
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else {
            currentStreak = 0
        }
        lastActiveDate = .now
        updatedAt = .now
    }

    /// Record task completion
    func recordTaskCompletion(onTime: Bool) {
        tasksCompleted += 1
        if onTime {
            tasksCompletedOnTime += 1
        }
        updatedAt = .now
    }

    /// Update from Supabase
    func update(from supabaseUser: SupabaseUser) {
        email = supabaseUser.email
        fullName = supabaseUser.fullName
        username = supabaseUser.username
        avatarUrl = supabaseUser.avatarUrl
        totalPoints = supabaseUser.totalPoints ?? 0
        currentLevel = supabaseUser.currentLevel ?? 1
        currentStreak = supabaseUser.currentStreak ?? 0
        longestStreak = supabaseUser.longestStreak ?? 0
        tasksCompleted = supabaseUser.tasksCompleted ?? 0
        tasksCompletedOnTime = supabaseUser.tasksCompletedOnTime ?? 0
        dailyTaskGoal = supabaseUser.dailyTaskGoal ?? 5
        weeklyTaskGoal = supabaseUser.weeklyTaskGoal ?? 25
        notificationsEnabled = supabaseUser.notificationsEnabled ?? true
        calendarSyncEnabled = supabaseUser.calendarSyncEnabled ?? false
        hapticsEnabled = supabaseUser.hapticsEnabled ?? true
        theme = supabaseUser.theme ?? "auto"
        lastActiveDate = supabaseUser.lastActiveDate
        updatedAt = supabaseUser.updatedAt ?? .now
    }

    /// Create User from Supabase user
    convenience init(from supabaseUser: SupabaseUser) {
        self.init(
            id: supabaseUser.id,
            email: supabaseUser.email,
            fullName: supabaseUser.fullName,
            username: supabaseUser.username,
            avatarUrl: supabaseUser.avatarUrl,
            totalPoints: supabaseUser.totalPoints ?? 0,
            currentLevel: supabaseUser.currentLevel ?? 1,
            currentStreak: supabaseUser.currentStreak ?? 0,
            longestStreak: supabaseUser.longestStreak ?? 0,
            tasksCompleted: supabaseUser.tasksCompleted ?? 0,
            tasksCompletedOnTime: supabaseUser.tasksCompletedOnTime ?? 0,
            dailyTaskGoal: supabaseUser.dailyTaskGoal ?? 5,
            weeklyTaskGoal: supabaseUser.weeklyTaskGoal ?? 25,
            notificationsEnabled: supabaseUser.notificationsEnabled ?? true,
            calendarSyncEnabled: supabaseUser.calendarSyncEnabled ?? false,
            hapticsEnabled: supabaseUser.hapticsEnabled ?? true,
            theme: supabaseUser.theme ?? "auto",
            lastActiveDate: supabaseUser.lastActiveDate,
            createdAt: supabaseUser.createdAt ?? .now,
            updatedAt: supabaseUser.updatedAt ?? .now
        )
    }

    /// Convert to Supabase user for syncing
    func toSupabase() -> SupabaseUser {
        SupabaseUser(from: self)
    }
}

// MARK: - Supabase User DTO
struct SupabaseUser: Codable, Sendable {
    let id: UUID
    var email: String?
    var fullName: String?
    var username: String?
    var avatarUrl: String?
    var totalPoints: Int?
    var currentLevel: Int?
    var currentStreak: Int?
    var longestStreak: Int?
    var lastActiveDate: Date?
    var tasksCompleted: Int?
    var tasksCompletedOnTime: Int?
    var dailyTaskGoal: Int?
    var weeklyTaskGoal: Int?
    var notificationsEnabled: Bool?
    var calendarSyncEnabled: Bool?
    var hapticsEnabled: Bool?
    var theme: String?
    var createdAt: Date?
    var updatedAt: Date?

    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.fullName = user.fullName
        self.username = user.username
        self.avatarUrl = user.avatarUrl
        self.totalPoints = user.totalPoints
        self.currentLevel = user.currentLevel
        self.currentStreak = user.currentStreak
        self.longestStreak = user.longestStreak
        self.lastActiveDate = user.lastActiveDate
        self.tasksCompleted = user.tasksCompleted
        self.tasksCompletedOnTime = user.tasksCompletedOnTime
        self.dailyTaskGoal = user.dailyTaskGoal
        self.weeklyTaskGoal = user.weeklyTaskGoal
        self.notificationsEnabled = user.notificationsEnabled
        self.calendarSyncEnabled = user.calendarSyncEnabled
        self.hapticsEnabled = user.hapticsEnabled
        self.theme = user.theme
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case username
        case avatarUrl = "avatar_url"
        case totalPoints = "total_points"
        case currentLevel = "current_level"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActiveDate = "last_active_date"
        case tasksCompleted = "tasks_completed"
        case tasksCompletedOnTime = "tasks_completed_on_time"
        case dailyTaskGoal = "daily_task_goal"
        case weeklyTaskGoal = "weekly_task_goal"
        case notificationsEnabled = "notifications_enabled"
        case calendarSyncEnabled = "calendar_sync_enabled"
        case hapticsEnabled = "haptics_enabled"
        case theme
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
