//
//  GoalTimeframe.swift
//  MyTasksAI
//
//  Three-Tier Goal Horizon System
//  Sprint (tactical) → Milestone (strategic) → Horizon (visionary)
//

import Foundation
import SwiftUI

// MARK: - Goal Timeframe
/// Strategic planning horizons for goal-setting
enum GoalTimeframe: String, Codable, Sendable, CaseIterable {
    case sprint      // 1-2 weeks - Quick wins, momentum builders
    case milestone   // 1-3 months - Project-based goals
    case horizon     // 3-12 months - Long-term vision

    // MARK: Display Properties

    var displayName: String {
        switch self {
        case .sprint: return "Sprint"
        case .milestone: return "Milestone"
        case .horizon: return "Horizon"
        }
    }

    var subtitle: String {
        switch self {
        case .sprint: return "1-2 weeks"
        case .milestone: return "1-3 months"
        case .horizon: return "3-12 months"
        }
    }

    var detailedDescription: String {
        switch self {
        case .sprint:
            return "Quick wins and momentum builders. Perfect for breaking down larger goals into actionable chunks."
        case .milestone:
            return "Project-based goals with clear deliverables. Ideal for skill development and medium-term achievements."
        case .horizon:
            return "Long-term vision and life direction. These shape your journey and inform your milestones and sprints."
        }
    }

    var icon: String {
        switch self {
        case .sprint: return "bolt.fill"
        case .milestone: return "flag.fill"
        case .horizon: return "mountain.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .sprint: return Theme.Colors.aiCyan
        case .milestone: return Theme.Colors.aiBlue
        case .horizon: return Theme.Colors.aiPurple
        }
    }

    // MARK: Duration Configuration

    /// Suggested duration range in days
    var suggestedDurationDays: ClosedRange<Int> {
        switch self {
        case .sprint: return 7...14
        case .milestone: return 30...90
        case .horizon: return 90...365
        }
    }

    /// Default duration in days when creating a new goal
    var defaultDurationDays: Int {
        switch self {
        case .sprint: return 7
        case .milestone: return 30
        case .horizon: return 90
        }
    }

    /// Minimum duration in days
    var minDurationDays: Int {
        switch self {
        case .sprint: return 3
        case .milestone: return 14
        case .horizon: return 60
        }
    }

    /// Maximum duration in days
    var maxDurationDays: Int {
        switch self {
        case .sprint: return 21
        case .milestone: return 120
        case .horizon: return 730  // 2 years
        }
    }

    // MARK: Gamification

    /// Points multiplier for completing goals of this timeframe
    var pointsMultiplier: Double {
        switch self {
        case .sprint: return 1.0
        case .milestone: return 1.5
        case .horizon: return 2.0
        }
    }

    /// Base points for completing a goal of this timeframe
    var baseCompletionPoints: Int {
        switch self {
        case .sprint: return 50
        case .milestone: return 100
        case .horizon: return 200
        }
    }

    // MARK: AI Configuration

    /// Number of phases AI should generate for roadmap
    var suggestedPhaseCount: Int {
        switch self {
        case .sprint: return 1
        case .milestone: return 3
        case .horizon: return 6
        }
    }

    /// How often to suggest check-ins
    var checkInFrequency: CheckInFrequency {
        switch self {
        case .sprint: return .everyFewDays
        case .milestone: return .weekly
        case .horizon: return .biweekly
        }
    }

    // MARK: Computed Helpers

    /// Calculate default target date from now
    func defaultTargetDate(from startDate: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: defaultDurationDays, to: startDate) ?? startDate
    }

    /// Check if a duration (in days) is valid for this timeframe
    func isValidDuration(_ days: Int) -> Bool {
        days >= minDurationDays && days <= maxDurationDays
    }

    /// Gradient for visual effects
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Check-In Frequency
enum CheckInFrequency: String, Codable, Sendable {
    case everyFewDays = "every_few_days"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .everyFewDays: return "Every few days"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        }
    }

    /// Days between check-ins
    var intervalDays: Int {
        switch self {
        case .everyFewDays: return 3
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        }
    }

    /// Calculate next check-in date from last check-in
    func nextCheckInDate(from lastCheckIn: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: intervalDays, to: lastCheckIn) ?? lastCheckIn
    }
}

// MARK: - Goal Priority (Urgency Assessment)
enum GoalPriority: String, Codable, Sendable, CaseIterable {
    case low
    case medium
    case high
    case critical

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var icon: String {
        switch self {
        case .low: return "circle"
        case .medium: return "circle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .low: return Theme.Colors.textTertiary
        case .medium: return Theme.Colors.aiBlue
        case .high: return Theme.Colors.warning
        case .critical: return Theme.Colors.error
        }
    }
}
