//
//  VelocityScore.swift
//  Veloce
//
//  Velocity Score - Single productivity health number (0-100)
//  Combines multiple metrics into one shareable score
//

import Foundation
import SwiftUI

// MARK: - Velocity Score

struct VelocityScore {
    // MARK: Components
    let streakScore: Double        // 0-25 points
    let completionScore: Double    // 0-25 points
    let focusScore: Double         // 0-25 points
    let onTimeScore: Double        // 0-25 points

    // MARK: Computed Properties

    /// Total velocity score (0-100)
    var total: Int {
        Int(streakScore + completionScore + focusScore + onTimeScore)
    }

    /// Score tier
    var tier: ScoreTier {
        switch total {
        case 90...100: return .legendary
        case 75..<90: return .excellent
        case 60..<75: return .good
        case 40..<60: return .building
        case 20..<40: return .starting
        default: return .beginning
        }
    }

    /// Color for the score
    var color: Color {
        tier.color
    }

    /// Gradient for the score display
    var gradient: LinearGradient {
        tier.gradient
    }

    /// Encouraging message based on score
    var message: String {
        tier.message
    }

    /// Short label for the tier
    var tierLabel: String {
        tier.label
    }

    // MARK: Initialization

    init(
        currentStreak: Int,
        longestStreak: Int,
        tasksCompletedThisWeek: Int,
        weeklyGoal: Int,
        focusMinutesThisWeek: Int,
        focusGoalMinutes: Int,
        tasksOnTime: Int,
        totalTasksCompleted: Int
    ) {
        // Streak Score (0-25)
        // Based on current streak relative to personal best
        let streakRatio = longestStreak > 0 ? Double(currentStreak) / Double(max(longestStreak, 7)) : 0
        self.streakScore = min(25, streakRatio * 25)

        // Completion Score (0-25)
        // Based on weekly task completion rate
        let completionRatio = weeklyGoal > 0 ? Double(tasksCompletedThisWeek) / Double(weeklyGoal) : 0
        self.completionScore = min(25, completionRatio * 25)

        // Focus Score (0-25)
        // Based on focus time this week
        let focusRatio = focusGoalMinutes > 0 ? Double(focusMinutesThisWeek) / Double(focusGoalMinutes) : 0
        self.focusScore = min(25, focusRatio * 25)

        // On-Time Score (0-25)
        // Based on completing tasks by their scheduled time
        let onTimeRatio = totalTasksCompleted > 0 ? Double(tasksOnTime) / Double(totalTasksCompleted) : 0.5
        self.onTimeScore = min(25, onTimeRatio * 25)
    }

    /// Create from user data
    static func calculate(
        user: User,
        tasksThisWeek: Int,
        focusMinutesThisWeek: Int
    ) -> VelocityScore {
        VelocityScore(
            currentStreak: user.currentStreak,
            longestStreak: user.longestStreak,
            tasksCompletedThisWeek: tasksThisWeek,
            weeklyGoal: user.weeklyTaskGoal,
            focusMinutesThisWeek: focusMinutesThisWeek,
            focusGoalMinutes: 5 * 60, // 5 hours default goal
            tasksOnTime: user.tasksCompletedOnTime,
            totalTasksCompleted: user.tasksCompleted
        )
    }
}

// MARK: - Score Tier

enum ScoreTier: String, CaseIterable {
    case beginning = "Beginning"
    case starting = "Starting"
    case building = "Building"
    case good = "Good"
    case excellent = "Excellent"
    case legendary = "Legendary"

    var label: String { rawValue }

    var color: Color {
        switch self {
        case .beginning: return .gray
        case .starting: return .blue
        case .building: return .green
        case .good: return .yellow
        case .excellent: return .orange
        case .legendary: return .purple
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .beginning:
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .starting:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .building:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .good:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .excellent:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .legendary:
            return LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var message: String {
        switch self {
        case .beginning:
            return "Every journey starts somewhere"
        case .starting:
            return "You're building momentum"
        case .building:
            return "Great progress this week!"
        case .good:
            return "You're on fire! Keep it up"
        case .excellent:
            return "Outstanding performance!"
        case .legendary:
            return "Legendary productivity master!"
        }
    }

    var icon: String {
        switch self {
        case .beginning: return "leaf"
        case .starting: return "flame"
        case .building: return "bolt"
        case .good: return "star"
        case .excellent: return "crown"
        case .legendary: return "crown.fill"
        }
    }

    /// Filled icon variant for premium display
    var iconFilled: String {
        switch self {
        case .beginning: return "leaf.fill"
        case .starting: return "flame.fill"
        case .building: return "bolt.fill"
        case .good: return "star.fill"
        case .excellent: return "crown.fill"
        case .legendary: return "crown.fill"
        }
    }
}

// MARK: - Weekly Score History

struct WeeklyScoreSnapshot: Codable, Identifiable {
    let id: UUID
    let weekStartDate: Date
    let score: Int
    let streakScore: Double
    let completionScore: Double
    let focusScore: Double
    let onTimeScore: Double

    init(from velocityScore: VelocityScore, weekStart: Date) {
        self.id = UUID()
        self.weekStartDate = weekStart
        self.score = velocityScore.total
        self.streakScore = velocityScore.streakScore
        self.completionScore = velocityScore.completionScore
        self.focusScore = velocityScore.focusScore
        self.onTimeScore = velocityScore.onTimeScore
    }
}

// MARK: - Score Breakdown View Model

struct ScoreBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let icon: String
    let score: Double
    let maxScore: Double = 25
    let color: Color

    var percentage: Double {
        score / maxScore
    }

    var displayScore: String {
        String(format: "%.0f", score)
    }

    static func from(_ velocityScore: VelocityScore) -> [ScoreBreakdown] {
        [
            ScoreBreakdown(
                category: "Streak",
                icon: "flame.fill",
                score: velocityScore.streakScore,
                color: .orange
            ),
            ScoreBreakdown(
                category: "Completion",
                icon: "checkmark.circle.fill",
                score: velocityScore.completionScore,
                color: .green
            ),
            ScoreBreakdown(
                category: "Focus",
                icon: "timer",
                score: velocityScore.focusScore,
                color: .blue
            ),
            ScoreBreakdown(
                category: "On-Time",
                icon: "clock.fill",
                score: velocityScore.onTimeScore,
                color: .purple
            )
        ]
    }
}
