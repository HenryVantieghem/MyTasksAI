//
//  GamificationService.swift
//  Veloce
//
//  Gamification Service - Points, Levels, Streaks, Achievements
//  Complete gamification system with combos, challenges, and power-ups
//  Handles all gamification logic to keep users engaged
//

import Foundation
import UIKit

// MARK: - Combo Tier

enum ComboTierLevel: Int, CaseIterable {
    case none = 0
    case x1 = 1
    case x1_5 = 2
    case x2 = 3
    case x3 = 4

    var multiplier: Double {
        switch self {
        case .none: return 1.0
        case .x1: return 1.0
        case .x1_5: return 1.5
        case .x2: return 2.0
        case .x3: return 3.0
        }
    }

    static func forCount(_ count: Int) -> ComboTierLevel {
        switch count {
        case 0: return .none
        case 1: return .x1
        case 2...3: return .x1_5
        case 4...5: return .x2
        default: return .x3
        }
    }
}

// MARK: - Gamification Service

@MainActor
@Observable
final class GamificationService {
    // MARK: Singleton
    static let shared = GamificationService()

    // MARK: Dependencies
    private let haptics = HapticsService.shared

    // MARK: Core State
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

    // MARK: Combo System
    private(set) var currentCombo: Int = 0
    private(set) var comboMultiplier: Double = 1.0
    private(set) var lastTaskCompletedAt: Date?
    private(set) var comboDecayTimer: Timer?
    private let comboDecayInterval: TimeInterval = 30 * 60 // 30 minutes

    /// Current combo tier based on combo count
    var comboTier: ComboTierLevel {
        ComboTierLevel.forCount(currentCombo)
    }

    /// Time remaining until combo decays (nil if no active combo)
    var comboTimeRemaining: TimeInterval? {
        guard currentCombo > 0, let lastCompleted = lastTaskCompletedAt else { return nil }
        let elapsed = Date().timeIntervalSince(lastCompleted)
        let remaining = comboDecayInterval - elapsed
        return remaining > 0 ? remaining : nil
    }

    // MARK: Power-Up State
    private(set) var hasActiveXPBoost: Bool = false
    private(set) var hasActiveStreakShield: Bool = false
    private(set) var hasActiveGoalAccelerator: Bool = false
    private(set) var hasActiveComboKeeper: Bool = false
    private(set) var xpBoostExpiresAt: Date?
    private(set) var streakShieldExpiresAt: Date?
    private(set) var goalAcceleratorExpiresAt: Date?
    private(set) var comboKeeperExpiresAt: Date?

    // MARK: Extended Stats (for Achievement Arena)
    private(set) var focusMinutesTotal: Int = 0
    private(set) var weeklyActivityData: [Int] = [0, 0, 0, 0, 0, 0, 0]  // Last 7 days
    private(set) var previousWeekData: [Int] = [0, 0, 0, 0, 0, 0, 0]    // Week before

    /// Total tasks completed (alias for MomentumTabView)
    var totalTasksCompleted: Int { tasksCompleted }

    /// Focus hours (converted from minutes)
    var focusHours: Double { Double(focusMinutesTotal) / 60.0 }

    /// Latest AI-generated productivity insight
    private(set) var latestInsight: String? = "You're 23% more productive in the morning. Schedule important tasks then!"

    // MARK: Initialization
    private init() {
        setupComboDecayCheck()
    }

    // MARK: - Combo Decay Timer

    private func setupComboDecayCheck() {
        // Check combo decay every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.checkComboDecay()
                self?.checkPowerUpExpiration()
            }
        }
    }

    private func checkComboDecay() {
        guard currentCombo > 0, let lastCompleted = lastTaskCompletedAt else { return }

        // Don't decay if combo keeper is active
        if hasActiveComboKeeper { return }

        let elapsed = Date().timeIntervalSince(lastCompleted)
        if elapsed >= comboDecayInterval {
            resetCombo()
        }
    }

    private func resetCombo() {
        currentCombo = 0
        comboMultiplier = 1.0
        lastTaskCompletedAt = nil
    }

    // MARK: - Power-Up Activation

    func activatePowerUp(_ type: PowerUpType) {
        switch type {
        case .xpBoost:
            hasActiveXPBoost = true
            xpBoostExpiresAt = Date().addingTimeInterval(type.durationSeconds)
        case .streakShield:
            hasActiveStreakShield = true
            streakShieldExpiresAt = Date().addingTimeInterval(type.durationSeconds)
        case .goalAccelerator:
            hasActiveGoalAccelerator = true
            goalAcceleratorExpiresAt = Date().addingTimeInterval(type.durationSeconds)
        case .focusForceField:
            // Handled by FocusService
            break
        case .comboKeeper:
            hasActiveComboKeeper = true
            comboKeeperExpiresAt = Date().addingTimeInterval(type.durationSeconds)
        }

        haptics.impact(.heavy)
    }

    private func checkPowerUpExpiration() {
        let now = Date()

        if hasActiveXPBoost, let expires = xpBoostExpiresAt, now > expires {
            hasActiveXPBoost = false
            xpBoostExpiresAt = nil
        }

        if hasActiveStreakShield, let expires = streakShieldExpiresAt, now > expires {
            hasActiveStreakShield = false
            streakShieldExpiresAt = nil
        }

        if hasActiveGoalAccelerator, let expires = goalAcceleratorExpiresAt, now > expires {
            hasActiveGoalAccelerator = false
            goalAcceleratorExpiresAt = nil
        }

        if hasActiveComboKeeper, let expires = comboKeeperExpiresAt, now > expires {
            hasActiveComboKeeper = false
            comboKeeperExpiresAt = nil
        }
    }

    // MARK: - Point Calculations

    /// Base points for completing a task
    private let baseTaskPoints = 10

    /// Goal-linked task bonus multiplier
    private let goalLinkBonus: Double = 0.5

    /// Calculate points for completing a task
    func calculatePoints(
        for task: TaskItem,
        completedOnTime: Bool = true,
        withStreak: Bool = true,
        isGoalLinked: Bool = false
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
            let streakMultiplier = min(1.0 + Double(currentStreak) * 0.1, 2.0)
            points = Int(Double(points) * streakMultiplier)
        }

        // Combo multiplier
        points = Int(Double(points) * comboTier.multiplier)

        // Goal-linked bonus
        if isGoalLinked {
            points = Int(Double(points) * (1.0 + goalLinkBonus))

            // Additional bonus if goal accelerator is active
            if hasActiveGoalAccelerator {
                points = Int(Double(points) * 1.5)
            }
        }

        // XP Boost power-up (2x)
        if hasActiveXPBoost {
            points *= 2
        }

        // Estimated time bonus (longer tasks = more points)
        if let minutes = task.estimatedMinutes {
            points += minutes / 10
        }

        return points
    }

    /// Increment combo on task completion
    func incrementCombo() {
        currentCombo += 1
        comboMultiplier = comboTier.multiplier
        lastTaskCompletedAt = Date()

        // Haptic feedback for combo increase
        if currentCombo >= 4 {
            haptics.impact(.heavy)
        } else if currentCombo >= 2 {
            haptics.impact(.medium)
        } else {
            haptics.impact(.light)
        }
    }

    /// Get total multiplier including all active bonuses
    var totalMultiplier: Double {
        var multiplier = comboTier.multiplier

        if hasActiveXPBoost {
            multiplier *= 2.0
        }

        if currentStreak > 0 {
            multiplier *= min(1.0 + Double(currentStreak) * 0.1, 2.0)
        }

        return multiplier
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

    /// Daily task completion rate (0.0 - 1.0)
    var completionRate: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(tasksCompletedToday) / Double(dailyGoal))
    }

    /// Velocity score (0-100) - composite productivity health metric
    var velocityScore: Double {
        // Streak Score (0-25): current vs longest streak
        let streakRatio = longestStreak > 0 ? Double(currentStreak) / Double(max(longestStreak, 7)) : 0
        let streakScore = min(25, streakRatio * 25)

        // Completion Score (0-25): weekly progress
        let weeklyProgress = weeklyGoal > 0 ? Double(tasksCompleted % weeklyGoal) / Double(weeklyGoal) : 0
        let completionScore = min(25, weeklyProgress * 25)

        // Focus Score (0-25): focus hours this week (goal: 5 hours)
        let focusGoalHours = 5.0
        let focusRatio = focusHours / focusGoalHours
        let focusScoreValue = min(25, focusRatio * 25)

        // On-Time Score (0-25): completion rate as proxy
        let onTimeScore = min(25, completionRate * 25)

        return streakScore + completionScore + focusScoreValue + onTimeScore
    }

    // MARK: - Streak System

    /// Update streak on task completion (enhanced with combo)
    func recordTaskCompletion(isGoalLinked: Bool = false) {
        tasksCompleted += 1
        tasksCompletedToday += 1

        // Increment combo
        incrementCombo()

        // Check if daily goal met
        if tasksCompletedToday >= dailyGoal {
            incrementStreak()
        }

        // Check achievements
        checkAchievements()

        // Check combo achievements
        checkComboAchievements()
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
    /// Uses streak shield if available
    @discardableResult
    func breakStreak() -> Bool {
        // Check if streak shield is active
        if hasActiveStreakShield {
            hasActiveStreakShield = false
            streakShieldExpiresAt = nil
            haptics.impact(.heavy)
            // Streak protected!
            return true
        }

        currentStreak = 0
        tasksCompletedToday = 0
        resetCombo()
        return false
    }

    /// Check combo-related achievements
    private func checkComboAchievements() {
        // Award bonus points for high combos
        if currentCombo == 5 {
            // First x2 combo
            totalPoints += 25
        } else if currentCombo == 10 {
            // Sustained x3 combo
            totalPoints += 50
        }
    }

    /// Reset daily counter (call at midnight)
    func resetDaily() {
        let previousCount = tasksCompletedToday

        // Check if yesterday's goal was met
        if previousCount < dailyGoal {
            breakStreak()
        }

        // Shift weekly data
        previousWeekData = weeklyActivityData
        weeklyActivityData = Array(weeklyActivityData.dropFirst()) + [0]

        tasksCompletedToday = 0
    }

    /// Record focus time
    func recordFocusTime(minutes: Int) {
        focusMinutesTotal += minutes

        // Check focus achievements
        if focusMinutesTotal >= 60 && !unlockedAchievements.contains(.focusHour) {
            unlockAchievement(.focusHour)
        }
    }

    /// Update today's activity in weekly data
    func recordDailyActivity(tasksCompleted count: Int) {
        if !weeklyActivityData.isEmpty {
            weeklyActivityData[weeklyActivityData.count - 1] = count
        }
    }

    /// Update AI insight
    func updateInsight(_ insight: String) {
        latestInsight = insight
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
        // Focus achievements
        case .focusFirst: return 50
        case .focusHour: return 100
        case .deepFocusMaster: return 500
        case .distractionFree: return 1000
        case .focusStreak: return 250
        }
    }
}
