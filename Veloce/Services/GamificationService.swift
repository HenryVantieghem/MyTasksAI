//
//  GamificationService.swift
//  Veloce
//
//  Gamification Service - Points, Levels, Streaks, Achievements
//  Handles all gamification logic to keep users engaged
//

import Foundation

// MARK: - Gamification Service

@MainActor
@Observable
final class GamificationService {
    // MARK: Singleton
    static let shared = GamificationService()

    // MARK: Dependencies
    private let haptics = HapticsService.shared

    // MARK: State
    private(set) var totalPoints: Int = 0
    private(set) var currentLevel: Int = 1
    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    private(set) var tasksCompleted: Int = 0
    private(set) var tasksCompletedToday: Int = 0
    private(set) var dailyGoal: Int = 5
    private(set) var weeklyGoal: Int = 25
    private(set) var unlockedAchievements: Set<AchievementType> = []
    private(set) var pendingAchievements: [AchievementType] = []

    // MARK: Initialization
    private init() {}

    // MARK: - Point Calculations

    /// Base points for completing a task
    private let baseTaskPoints = 10

    /// Calculate points for completing a task
    func calculatePoints(
        for task: TaskItem,
        completedOnTime: Bool = true,
        withStreak: Bool = true
    ) -> Int {
        var points = baseTaskPoints

        // Priority bonus
        let priority = task.priorityEnum
        switch priority {
        case .high: points += 15
        case .medium: points += 5
        case .low: points += 0
        }

        // Star rating bonus (Sam Altman style)
        points += task.starRating * 5

        // On-time bonus
        if completedOnTime {
            points += 5
        }

        // Streak multiplier
        if withStreak && currentStreak > 0 {
            let multiplier = min(1.0 + Double(currentStreak) * 0.1, 2.0)
            points = Int(Double(points) * multiplier)
        }

        // Estimated time bonus (longer tasks = more points)
        if let minutes = task.estimatedMinutes {
            points += minutes / 10
        }

        return points
    }

    /// Award points and check for level up
    func awardPoints(_ points: Int) -> LevelUpResult? {
        let previousLevel = currentLevel
        totalPoints += points

        // Check for level up
        let newLevel = calculateLevel(for: totalPoints)

        if newLevel > previousLevel {
            currentLevel = newLevel
            haptics.levelUp()
            return LevelUpResult(
                previousLevel: previousLevel,
                newLevel: newLevel,
                pointsRequired: pointsForLevel(newLevel),
                totalPoints: totalPoints
            )
        }

        return nil
    }

    // MARK: - Level System

    /// Points required for each level (exponential curve)
    func pointsForLevel(_ level: Int) -> Int {
        // Level 1: 0, Level 2: 100, Level 3: 250, Level 4: 450...
        return level <= 1 ? 0 : Int(50 * pow(Double(level), 1.5))
    }

    /// Calculate level from total points
    func calculateLevel(for points: Int) -> Int {
        var level = 1
        while pointsForLevel(level + 1) <= points {
            level += 1
        }
        return level
    }

    /// Progress to next level (0.0 - 1.0)
    var levelProgress: Double {
        let currentLevelPoints = pointsForLevel(currentLevel)
        let nextLevelPoints = pointsForLevel(currentLevel + 1)
        let progressPoints = totalPoints - currentLevelPoints
        let requiredPoints = nextLevelPoints - currentLevelPoints

        guard requiredPoints > 0 else { return 1.0 }
        return min(1.0, Double(progressPoints) / Double(requiredPoints))
    }

    /// Points needed for next level
    var pointsToNextLevel: Int {
        pointsForLevel(currentLevel + 1) - totalPoints
    }

    // MARK: - Streak System

    /// Update streak on task completion
    func recordTaskCompletion() {
        tasksCompleted += 1
        tasksCompletedToday += 1

        // Check if daily goal met
        if tasksCompletedToday >= dailyGoal {
            incrementStreak()
        }

        // Check achievements
        checkAchievements()
    }

    /// Increment streak
    private func incrementStreak() {
        currentStreak += 1

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        // Streak milestones
        if currentStreak == 7 {
            unlockAchievement(.weekStreak)
        } else if currentStreak == 30 {
            unlockAchievement(.monthStreak)
        } else if currentStreak == 100 {
            unlockAchievement(.centuryStreak)
        }

        haptics.streakAchieved()
    }

    /// Break streak (called when daily goal not met)
    func breakStreak() {
        currentStreak = 0
        tasksCompletedToday = 0
    }

    /// Reset daily counter (call at midnight)
    func resetDaily() {
        let previousCount = tasksCompletedToday

        // Check if yesterday's goal was met
        if previousCount < dailyGoal {
            breakStreak()
        }

        tasksCompletedToday = 0
    }

    // MARK: - Achievement System

    /// Check and unlock achievements
    private func checkAchievements() {
        // Task count achievements
        if tasksCompleted >= 1 && !unlockedAchievements.contains(.firstTask) {
            unlockAchievement(.firstTask)
        }

        if tasksCompleted >= 10 && !unlockedAchievements.contains(.tenTasks) {
            unlockAchievement(.tenTasks)
        }

        if tasksCompleted >= 100 && !unlockedAchievements.contains(.hundredTasks) {
            unlockAchievement(.hundredTasks)
        }

        if tasksCompleted >= 1000 && !unlockedAchievements.contains(.thousandTasks) {
            unlockAchievement(.thousandTasks)
        }

        // Level achievements
        if currentLevel >= 5 && !unlockedAchievements.contains(.levelFive) {
            unlockAchievement(.levelFive)
        }

        if currentLevel >= 10 && !unlockedAchievements.contains(.levelTen) {
            unlockAchievement(.levelTen)
        }

        // Daily achievements
        if tasksCompletedToday >= 10 && !unlockedAchievements.contains(.productiveDay) {
            unlockAchievement(.productiveDay)
        }
    }

    /// Unlock an achievement
    func unlockAchievement(_ type: AchievementType) {
        guard !unlockedAchievements.contains(type) else { return }

        unlockedAchievements.insert(type)
        pendingAchievements.append(type)

        // Award bonus points
        totalPoints += type.bonusPoints

        haptics.achievementUnlocked()
    }

    /// Acknowledge pending achievement (after showing to user)
    func acknowledgePendingAchievement() -> AchievementType? {
        guard !pendingAchievements.isEmpty else { return nil }
        return pendingAchievements.removeFirst()
    }

    /// Check if achievement is unlocked
    func isUnlocked(_ type: AchievementType) -> Bool {
        unlockedAchievements.contains(type)
    }

    /// Get progress toward an achievement
    func progress(for type: AchievementType) -> Double {
        switch type {
        case .firstTask:
            return tasksCompleted >= 1 ? 1.0 : 0.0
        case .tenTasks:
            return min(1.0, Double(tasksCompleted) / 10.0)
        case .hundredTasks:
            return min(1.0, Double(tasksCompleted) / 100.0)
        case .thousandTasks:
            return min(1.0, Double(tasksCompleted) / 1000.0)
        case .weekStreak:
            return min(1.0, Double(currentStreak) / 7.0)
        case .monthStreak:
            return min(1.0, Double(currentStreak) / 30.0)
        case .centuryStreak:
            return min(1.0, Double(currentStreak) / 100.0)
        case .productiveDay:
            return min(1.0, Double(tasksCompletedToday) / 10.0)
        case .levelFive:
            return min(1.0, Double(currentLevel) / 5.0)
        case .levelTen:
            return min(1.0, Double(currentLevel) / 10.0)
        default:
            return 0.0
        }
    }

    // MARK: - Sync with User Data

    /// Load from user data
    func load(from user: User) {
        totalPoints = user.totalPoints
        currentLevel = user.currentLevel
        currentStreak = user.currentStreak
        longestStreak = user.longestStreak
        tasksCompleted = user.tasksCompleted
        dailyGoal = user.dailyTaskGoal
        weeklyGoal = user.weeklyTaskGoal
    }

    /// Update user with current gamification data
    func updateUser(_ user: inout User) {
        user.totalPoints = totalPoints
        user.currentLevel = currentLevel
        user.currentStreak = currentStreak
        user.longestStreak = longestStreak
        user.tasksCompleted = tasksCompleted
    }
}

// MARK: - Level Up Result

struct LevelUpResult {
    let previousLevel: Int
    let newLevel: Int
    let pointsRequired: Int
    let totalPoints: Int

    var levelsGained: Int {
        newLevel - previousLevel
    }
}

// MARK: - Achievement Extension

extension AchievementType {
    var bonusPoints: Int {
        switch self {
        case .firstTask: return 50
        case .firstStreak: return 75
        case .tenTasks, .tasksBronze: return 100
        case .tasksSilver: return 250
        case .hundredTasks, .tasksGold: return 500
        case .thousandTasks, .tasksDiamond: return 2000
        case .streakBronze: return 100
        case .weekStreak, .streakSilver: return 200
        case .monthStreak, .streakGold: return 1000
        case .centuryStreak, .streakDiamond: return 5000
        case .productiveDay: return 150
        case .levelFive: return 300
        case .levelTen: return 750
        case .earlyBird: return 100
        case .nightOwl: return 100
        case .weekendWarrior: return 200
        case .perfectWeek: return 500
        case .aiExplorer: return 100
        case .aiCollaborator: return 150
        case .brainDumpMaster: return 200
        case .reflectionGuru: return 250
        case .goalSetter: return 100
        case .goalAchiever: return 300
        }
    }
}
