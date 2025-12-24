//
//  DailyChallenge.swift
//  Veloce
//
//  Daily Challenge Model - AI-Generated Productivity Quests
//  3 daily challenges that integrate with goals and drive engagement
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Daily Challenge Type

enum DailyChallengeType: String, Codable, CaseIterable {
    case goalSprint = "goal_sprint"        // Make progress on a specific goal
    case focusPower = "focus_power"        // Complete X minutes of focused work
    case momentumBuilder = "momentum"      // Complete X tasks before noon
    case milestonePush = "milestone"       // Complete a milestone on any goal
    case streakExtender = "streak"         // Maintain your streak today
    case earlyBird = "early_bird"          // Complete a task before 9 AM
    case taskMaster = "task_master"        // Complete X tasks today
    case deepWork = "deep_work"            // Complete a 45+ minute focus session

    var title: String {
        switch self {
        case .goalSprint: return "Goal Sprint"
        case .focusPower: return "Focus Power"
        case .momentumBuilder: return "Momentum Builder"
        case .milestonePush: return "Milestone Push"
        case .streakExtender: return "Streak Keeper"
        case .earlyBird: return "Early Bird"
        case .taskMaster: return "Task Master"
        case .deepWork: return "Deep Work"
        }
    }

    var icon: String {
        switch self {
        case .goalSprint: return "flag.fill"
        case .focusPower: return "bolt.fill"
        case .momentumBuilder: return "sunrise.fill"
        case .milestonePush: return "star.circle.fill"
        case .streakExtender: return "flame.fill"
        case .earlyBird: return "bird.fill"
        case .taskMaster: return "checkmark.circle.fill"
        case .deepWork: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .goalSprint: return Color(red: 0.23, green: 0.51, blue: 0.96)
        case .focusPower: return Color(red: 0.98, green: 0.55, blue: 0.25)
        case .momentumBuilder: return Color(red: 0.98, green: 0.75, blue: 0.25)
        case .milestonePush: return Color(red: 0.58, green: 0.25, blue: 0.98)
        case .streakExtender: return Color(red: 0.98, green: 0.40, blue: 0.20)
        case .earlyBird: return Color(red: 0.20, green: 0.85, blue: 0.55)
        case .taskMaster: return Color(red: 0.20, green: 0.78, blue: 0.95)
        case .deepWork: return Color(red: 0.65, green: 0.35, blue: 0.98)
        }
    }

    var baseXPReward: Int {
        switch self {
        case .goalSprint: return 50
        case .focusPower: return 40
        case .momentumBuilder: return 35
        case .milestonePush: return 75
        case .streakExtender: return 30
        case .earlyBird: return 25
        case .taskMaster: return 45
        case .deepWork: return 60
        }
    }
}

// MARK: - Daily Challenge Model

@Model
final class DailyChallenge {
    var id: UUID
    var userId: UUID?
    var type: String  // ChallengeType.rawValue
    var title: String
    var challengeDescription: String
    var targetValue: Int
    var currentValue: Int
    var xpReward: Int
    var linkedGoalId: UUID?
    var expiresAt: Date
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        type: DailyChallengeType,
        title: String,
        description: String,
        targetValue: Int,
        xpReward: Int? = nil,
        linkedGoalId: UUID? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type.rawValue
        self.title = title
        self.challengeDescription = description
        self.targetValue = targetValue
        self.currentValue = 0
        self.xpReward = xpReward ?? type.baseXPReward
        self.linkedGoalId = linkedGoalId
        self.expiresAt = expiresAt ?? Self.endOfDay()
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = Date()
    }

    // MARK: Computed Properties

    var challengeType: DailyChallengeType {
        DailyChallengeType(rawValue: type) ?? .taskMaster
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, Double(currentValue) / Double(targetValue))
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var timeRemaining: TimeInterval {
        expiresAt.timeIntervalSince(Date())
    }

    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        if remaining <= 0 { return "Expired" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }

    // MARK: Methods

    func updateProgress(newValue: Int) {
        currentValue = min(newValue, targetValue)
        if currentValue >= targetValue && !isCompleted {
            isCompleted = true
            completedAt = Date()
        }
    }

    func incrementProgress(by amount: Int = 1) {
        updateProgress(newValue: currentValue + amount)
    }

    // MARK: Helpers

    private static func endOfDay() -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
    }

    // MARK: Factory Methods

    static func generateDailyChallenges(for goals: [Goal], streak: Int) -> [DailyChallenge] {
        var challenges: [DailyChallenge] = []

        // Challenge 1: Goal-linked (if active goals exist)
        if let priorityGoal = goals.first(where: { !$0.isCompleted }) {
            challenges.append(DailyChallenge(
                type: .goalSprint,
                title: "Sprint: \(priorityGoal.title.prefix(20))",
                description: "Make progress on your goal today",
                targetValue: 2, // 2 linked tasks
                linkedGoalId: priorityGoal.id
            ))
        } else {
            challenges.append(DailyChallenge(
                type: .taskMaster,
                title: "Complete 5 Tasks",
                description: "Finish 5 tasks to build momentum",
                targetValue: 5
            ))
        }

        // Challenge 2: Focus or early bird based on time
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            challenges.append(DailyChallenge(
                type: .earlyBird,
                title: "Early Bird",
                description: "Complete a task before noon",
                targetValue: 1
            ))
        } else {
            challenges.append(DailyChallenge(
                type: .focusPower,
                title: "Focus Session",
                description: "Complete 30 minutes of focused work",
                targetValue: 30
            ))
        }

        // Challenge 3: Streak-based
        if streak > 0 {
            challenges.append(DailyChallenge(
                type: .streakExtender,
                title: "Keep the Fire",
                description: "Complete your daily goal to extend your \(streak)-day streak",
                targetValue: 1,
                xpReward: 30 + streak * 2 // Bonus for longer streaks
            ))
        } else {
            challenges.append(DailyChallenge(
                type: .momentumBuilder,
                title: "Morning Momentum",
                description: "Complete 3 tasks before the day ends",
                targetValue: 3
            ))
        }

        return challenges
    }
}

// MARK: - Preview Helpers

extension DailyChallenge {
    static var previews: [DailyChallenge] {
        [
            DailyChallenge(
                type: .goalSprint,
                title: "Sprint: Learn SwiftUI",
                description: "Make progress on your goal today",
                targetValue: 2,
                xpReward: 50
            ),
            DailyChallenge(
                type: .focusPower,
                title: "Focus Session",
                description: "Complete 30 minutes of focused work",
                targetValue: 30,
                xpReward: 40
            ),
            DailyChallenge(
                type: .streakExtender,
                title: "Keep the Fire",
                description: "Maintain your 7-day streak",
                targetValue: 1,
                xpReward: 44
            )
        ]
    }
}
