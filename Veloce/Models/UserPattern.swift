//
//  UserPattern.swift
//  Veloce
//
//  User Patterns Model - Tracks behavioral patterns for AI personalization
//  Enables "AI That Learns You" by recording user preferences and habits
//

import Foundation
import SwiftData

// MARK: - User Pattern Model

@Model
final class UserPattern {
    // MARK: Core Properties
    var id: UUID
    var userId: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: Productivity Patterns
    /// Most productive hours (0-23) based on task completion velocity
    var peakProductivityHours: [Int]

    /// Average tasks completed per hour of day
    var hourlyCompletionRates: [Int: Double]

    /// Day of week productivity (0=Sunday, 6=Saturday)
    var weekdayCompletionRates: [Int: Double]

    // MARK: Task Preferences
    /// Preferred task duration buckets (short: <15min, medium: 15-45min, long: >45min)
    var preferredDurationBucket: String

    /// Average actual vs estimated time ratio (1.0 = perfect estimates)
    var estimateAccuracyRatio: Double

    /// Types of tasks completed most (work, personal, health, etc)
    var topTaskCategories: [String]

    // MARK: AI Suggestion Feedback
    /// Total AI suggestions shown
    var totalSuggestionsShown: Int

    /// AI suggestions accepted
    var suggestionsAccepted: Int

    /// AI suggestions rejected
    var suggestionsRejected: Int

    /// Acceptance rate by suggestion type
    var suggestionAcceptanceByType: [String: Double]

    // MARK: Schedule Patterns
    /// Preferred scheduling times (morning, afternoon, evening)
    var preferredSchedulingTime: String

    /// Average buffer between tasks (minutes)
    var averageBufferMinutes: Int

    /// Tendency to reschedule (0.0 = never, 1.0 = always)
    var rescheduleTendency: Double

    // MARK: Focus Patterns
    /// Average focus session duration
    var averageFocusDurationMinutes: Int

    /// Most used focus mode
    var preferredFocusMode: String

    /// Focus sessions completed vs started ratio
    var focusCompletionRate: Double

    // MARK: Streak Behavior
    /// Typical streak length before break
    var averageStreakLength: Int

    /// Days most likely to break streak (0=Sunday)
    var streakBreakDays: [Int]

    /// Prefers grace days or strict streaks
    var prefersGraceDays: Bool

    // MARK: Initialization

    init(
        id: UUID = UUID(),
        userId: UUID,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        peakProductivityHours: [Int] = [9, 10, 11],
        hourlyCompletionRates: [Int: Double] = [:],
        weekdayCompletionRates: [Int: Double] = [:],
        preferredDurationBucket: String = "medium",
        estimateAccuracyRatio: Double = 1.0,
        topTaskCategories: [String] = [],
        totalSuggestionsShown: Int = 0,
        suggestionsAccepted: Int = 0,
        suggestionsRejected: Int = 0,
        suggestionAcceptanceByType: [String: Double] = [:],
        preferredSchedulingTime: String = "morning",
        averageBufferMinutes: Int = 15,
        rescheduleTendency: Double = 0.2,
        averageFocusDurationMinutes: Int = 25,
        preferredFocusMode: String = "pomodoro",
        focusCompletionRate: Double = 0.8,
        averageStreakLength: Int = 7,
        streakBreakDays: [Int] = [0, 6],
        prefersGraceDays: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.peakProductivityHours = peakProductivityHours
        self.hourlyCompletionRates = hourlyCompletionRates
        self.weekdayCompletionRates = weekdayCompletionRates
        self.preferredDurationBucket = preferredDurationBucket
        self.estimateAccuracyRatio = estimateAccuracyRatio
        self.topTaskCategories = topTaskCategories
        self.totalSuggestionsShown = totalSuggestionsShown
        self.suggestionsAccepted = suggestionsAccepted
        self.suggestionsRejected = suggestionsRejected
        self.suggestionAcceptanceByType = suggestionAcceptanceByType
        self.preferredSchedulingTime = preferredSchedulingTime
        self.averageBufferMinutes = averageBufferMinutes
        self.rescheduleTendency = rescheduleTendency
        self.averageFocusDurationMinutes = averageFocusDurationMinutes
        self.preferredFocusMode = preferredFocusMode
        self.focusCompletionRate = focusCompletionRate
        self.averageStreakLength = averageStreakLength
        self.streakBreakDays = streakBreakDays
        self.prefersGraceDays = prefersGraceDays
    }
}

// MARK: - Computed Properties

extension UserPattern {
    /// Overall AI suggestion acceptance rate
    var suggestionAcceptanceRate: Double {
        guard totalSuggestionsShown > 0 else { return 0.5 }
        return Double(suggestionsAccepted) / Double(totalSuggestionsShown)
    }

    /// Best hour for scheduling difficult tasks
    var bestHourForHardTasks: Int {
        peakProductivityHours.first ?? 9
    }

    /// Personalized productivity insight
    var productivityInsight: String {
        guard let bestHour = peakProductivityHours.first else {
            return "Complete more tasks to learn your patterns"
        }

        let timeString: String
        if bestHour < 12 {
            timeString = "morning (\(bestHour):00)"
        } else if bestHour < 17 {
            timeString = "afternoon (\(bestHour):00)"
        } else {
            timeString = "evening (\(bestHour):00)"
        }

        return "You're most productive in the \(timeString)"
    }

    /// Estimate accuracy description
    var estimateAccuracyDescription: String {
        switch estimateAccuracyRatio {
        case 0.8...1.2:
            return "Your time estimates are accurate"
        case 0.5..<0.8:
            return "You often finish faster than estimated"
        case 1.2...:
            return "Tasks often take longer than estimated"
        default:
            return "Keep tracking to improve estimates"
        }
    }

    /// Focus recommendation
    var focusRecommendation: String {
        if focusCompletionRate > 0.8 {
            return "Great focus! Try longer sessions"
        } else if focusCompletionRate > 0.5 {
            return "Try shorter focus blocks"
        } else {
            return "Start with 15-min focused bursts"
        }
    }
}

// MARK: - Pattern Event (for tracking)

struct PatternEvent: Codable {
    let eventType: PatternEventType
    let timestamp: Date
    let metadata: [String: String]

    enum PatternEventType: String, Codable {
        case taskCompleted
        case taskScheduled
        case taskRescheduled
        case suggestionAccepted
        case suggestionRejected
        case focusStarted
        case focusCompleted
        case focusAbandoned
        case streakBroken
        case streakMilestone
    }
}

// MARK: - User Productivity Patterns (for AI Service)

/// Lightweight snapshot of user productivity patterns for AI consumption
struct UserProductivityPatterns: Codable, Sendable {
    let peakHours: [Int]
    let preferredDuration: Int
    let estimateAccuracy: Double
    let suggestionAcceptance: Double
    let focusPreference: String

    init(from pattern: UserPattern) {
        self.peakHours = pattern.peakProductivityHours
        self.preferredDuration = pattern.averageFocusDurationMinutes
        self.estimateAccuracy = pattern.estimateAccuracyRatio
        self.suggestionAcceptance = pattern.suggestionAcceptanceRate
        self.focusPreference = pattern.preferredFocusMode
    }

    /// Default patterns for new users
    static var defaults: UserProductivityPatterns {
        UserProductivityPatterns(
            peakHours: [9, 10, 11],
            preferredDuration: 25,
            estimateAccuracy: 1.0,
            suggestionAcceptance: 0.5,
            focusPreference: "pomodoro"
        )
    }

    private init(
        peakHours: [Int],
        preferredDuration: Int,
        estimateAccuracy: Double,
        suggestionAcceptance: Double,
        focusPreference: String
    ) {
        self.peakHours = peakHours
        self.preferredDuration = preferredDuration
        self.estimateAccuracy = estimateAccuracy
        self.suggestionAcceptance = suggestionAcceptance
        self.focusPreference = focusPreference
    }
}
