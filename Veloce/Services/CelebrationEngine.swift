//
//  CelebrationEngine.swift
//  Veloce
//
//  Celebration Engine - Orchestrates dopamine-driven task completion celebrations
//  Makes completing tasks ADDICTIVE through coordinated visual, audio, and haptic feedback
//

import SwiftUI
import Combine

// MARK: - Celebration Level

enum CelebrationLevel: Int, CaseIterable, Comparable {
    case quick = 0      // Simple checkmark (≤3 min tasks)
    case normal = 1     // Particles + sound
    case important = 2  // Confetti + banner
    case milestone = 3  // Full screen supernova

    static func < (lhs: CelebrationLevel, rhs: CelebrationLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var xpAmount: Int {
        switch self {
        case .quick: return 10
        case .normal: return 25
        case .important: return 50
        case .milestone: return 100
        }
    }

    var duration: Double {
        switch self {
        case .quick: return 0.5
        case .normal: return 0.8
        case .important: return 1.5
        case .milestone: return 3.0
        }
    }

    var particleCount: Int {
        switch self {
        case .quick: return 12
        case .normal: return 30
        case .important: return 80
        case .milestone: return 150
        }
    }
}

// MARK: - Celebration Event

struct CelebrationEvent: Identifiable {
    let id = UUID()
    let level: CelebrationLevel
    let xpEarned: Int
    let multiplier: Double
    let position: CGPoint
    let message: String?
    let isPersonalBest: PersonalBest?
    let timestamp: Date = .now

    // Computed properties for display
    var displayXP: Int {
        Int(Double(xpEarned) * multiplier)
    }

    var hasMultiplier: Bool {
        multiplier > 1.0
    }
}

// MARK: - Personal Best

struct PersonalBest: Identifiable, Equatable {
    let id = UUID()
    let type: PersonalBestType
    let value: Int
    let previousValue: Int
    let achievedAt: Date = .now

    var improvement: Int {
        value - previousValue
    }
}

enum PersonalBestType: String, CaseIterable {
    case mostTasksInDay = "Most Tasks in a Day"
    case longestFocusStreak = "Longest Focus Streak"
    case mostXPInDay = "Most XP in a Day"
    case longestTaskStreak = "Longest Task Streak"
    case bestWeek = "Best Week"
    case fastestCompletion = "Fastest Completion"

    var icon: String {
        switch self {
        case .mostTasksInDay: return "checkmark.circle.fill"
        case .longestFocusStreak: return "flame.fill"
        case .mostXPInDay: return "star.fill"
        case .longestTaskStreak: return "bolt.fill"
        case .bestWeek: return "calendar.badge.checkmark"
        case .fastestCompletion: return "hare.fill"
        }
    }

    var color: Color {
        switch self {
        case .mostTasksInDay: return Theme.Celebration.successGlow
        case .longestFocusStreak: return Theme.Celebration.flameCore
        case .mostXPInDay: return Theme.Celebration.starGold
        case .longestTaskStreak: return Theme.Celebration.plasmaCore
        case .bestWeek: return Theme.Celebration.nebulaCore
        case .fastestCompletion: return Theme.Celebration.auroraGreen
        }
    }
}

// MARK: - Momentum State

struct MomentumState: Equatable {
    var isActive: Bool = false
    var streakCount: Int = 0
    var multiplier: Double = 1.0
    var lastCompletionTime: Date?
    var flameIntensity: Double = 0.0

    // Momentum activates at 3 tasks in a row
    static let activationThreshold = 3
    // Momentum decays after 30 minutes of inactivity
    static let decayInterval: TimeInterval = 30 * 60

    var displayMultiplier: String {
        if multiplier >= 2.0 {
            return "2×"
        } else if multiplier >= 1.5 {
            return "1.5×"
        } else if multiplier >= 1.25 {
            return "1.25×"
        }
        return ""
    }

    mutating func incrementStreak() {
        streakCount += 1
        lastCompletionTime = .now

        // Calculate multiplier based on streak
        switch streakCount {
        case 0..<3:
            isActive = false
            multiplier = 1.0
            flameIntensity = Double(streakCount) / 3.0
        case 3..<5:
            isActive = true
            multiplier = 1.25
            flameIntensity = 0.5
        case 5..<8:
            multiplier = 1.5
            flameIntensity = 0.75
        default:
            multiplier = 2.0
            flameIntensity = 1.0
        }
    }

    mutating func reset() {
        isActive = false
        streakCount = 0
        multiplier = 1.0
        flameIntensity = 0.0
        lastCompletionTime = nil
    }

    func shouldDecay() -> Bool {
        guard let lastTime = lastCompletionTime else { return false }
        return Date().timeIntervalSince(lastTime) >= Self.decayInterval
    }
}

// MARK: - Celebration Engine

@MainActor
@Observable
final class CelebrationEngine {
    // MARK: Singleton
    static let shared = CelebrationEngine()

    // MARK: Dependencies
    private let haptics = HapticsService.shared
    private let gamification = GamificationService.shared
    private let sounds = CelebrationSounds.shared
    private let personalBests = PersonalBestsService.shared

    // MARK: State
    private(set) var currentCelebration: CelebrationEvent?
    private(set) var momentumState = MomentumState()
    private(set) var pendingMilestone: CelebrationEvent?
    private(set) var showingMilestoneOverlay = false

    // MARK: Publishers
    let celebrationTriggered = PassthroughSubject<CelebrationEvent, Never>()
    let momentumChanged = PassthroughSubject<MomentumState, Never>()
    let personalBestAchieved = PassthroughSubject<PersonalBest, Never>()

    // MARK: Settings
    @AppStorage("celebrationSoundsEnabled") private var soundsEnabled = true
    @AppStorage("celebrationHapticsEnabled") private var hapticsEnabled = true
    @AppStorage("celebrationConfettiEnabled") private var confettiEnabled = true
    @AppStorage("celebrationIntensity") private var intensity: CelebrationIntensity = .medium

    // MARK: Decay Timer
    private var decayCheckTimer: Timer?

    // MARK: Initialization
    private init() {
        setupDecayTimer()
    }

    // MARK: - Core Celebration API

    /// Determine celebration level for a task
    func celebrationLevel(for task: TaskItem) -> CelebrationLevel {
        // Milestone check first (e.g., 100th task, achievement unlocked)
        if let _ = checkForMilestone(task: task) {
            return .milestone
        }

        // Important tasks (high priority or high star rating)
        if task.priorityEnum == .high || task.starRating >= 3 {
            return .important
        }

        // Quick tasks (estimated ≤3 minutes or very short title)
        if let minutes = task.estimatedMinutes, minutes <= 3 {
            return .quick
        }

        // Default: normal celebration
        return .normal
    }

    /// Execute celebration sequence for completing a task
    func celebrate(
        task: TaskItem,
        at position: CGPoint,
        baseXP: Int? = nil
    ) {
        let level = celebrationLevel(for: task)
        let xp = baseXP ?? level.xpAmount

        // Update momentum
        momentumState.incrementStreak()
        momentumChanged.send(momentumState)

        // Check for personal bests
        let personalBest = checkPersonalBests(after: task)

        // Determine final level (upgrade if personal best)
        let finalLevel: CelebrationLevel = personalBest != nil ? max(level, .important) : level

        // Create celebration event
        let event = CelebrationEvent(
            level: finalLevel,
            xpEarned: xp,
            multiplier: momentumState.multiplier,
            position: position,
            message: celebrationMessage(for: finalLevel, task: task),
            isPersonalBest: personalBest
        )

        // Execute celebration
        executeCelebration(event)

        // Publish for UI updates
        celebrationTriggered.send(event)

        if let best = personalBest {
            personalBestAchieved.send(best)
        }
    }

    /// Manual celebration trigger (for milestones, achievements, etc.)
    func celebrate(
        level: CelebrationLevel,
        xp: Int,
        at position: CGPoint,
        message: String? = nil
    ) {
        let event = CelebrationEvent(
            level: level,
            xpEarned: xp,
            multiplier: momentumState.multiplier,
            position: position,
            message: message,
            isPersonalBest: nil
        )

        executeCelebration(event)
        celebrationTriggered.send(event)
    }

    // MARK: - Celebration Execution

    private func executeCelebration(_ event: CelebrationEvent) {
        currentCelebration = event

        // Execute based on level
        switch event.level {
        case .quick:
            executeQuickCelebration(event)
        case .normal:
            executeNormalCelebration(event)
        case .important:
            executeImportantCelebration(event)
        case .milestone:
            executeMilestoneCelebration(event)
        }

        // Clear after duration
        Task {
            try? await Task.sleep(for: .seconds(event.level.duration))
            if currentCelebration?.id == event.id {
                currentCelebration = nil
            }
        }
    }

    private func executeQuickCelebration(_ event: CelebrationEvent) {
        // Light haptic
        if hapticsEnabled {
            haptics.impact(.light)
        }

        // Subtle pop sound
        if soundsEnabled && intensity != .low {
            sounds.playQuickPop()
        }
    }

    private func executeNormalCelebration(_ event: CelebrationEvent) {
        // Medium haptic with checkmark pattern
        if hapticsEnabled {
            haptics.taskCompleteEnhanced()
        }

        // Satisfying ding
        if soundsEnabled {
            sounds.playCompletionDing()
        }

        // Momentum streak sound if active
        if momentumState.isActive && soundsEnabled {
            sounds.playStreakContinue(count: momentumState.streakCount)
        }
    }

    private func executeImportantCelebration(_ event: CelebrationEvent) {
        // Success haptic pattern
        if hapticsEnabled {
            haptics.celebration()
        }

        // Triumphant chord
        if soundsEnabled {
            sounds.playImportantComplete()
        }

        // Combo haptic if high streak
        if momentumState.streakCount >= 5 {
            haptics.comboUp(comboCount: momentumState.streakCount)
        }
    }

    private func executeMilestoneCelebration(_ event: CelebrationEvent) {
        // Store for overlay
        pendingMilestone = event
        showingMilestoneOverlay = true

        // Maximum haptic
        if hapticsEnabled {
            haptics.achievementUnlocked()

            // Delayed secondary haptic for impact
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                haptics.levelUp()
            }
        }

        // Celebration fanfare
        if soundsEnabled {
            sounds.playMilestoneFanfare()
        }
    }

    // MARK: - Milestone Detection

    private func checkForMilestone(task: TaskItem) -> String? {
        let totalTasks = gamification.tasksCompleted + 1

        // Check for round number milestones
        let milestones = [10, 25, 50, 100, 250, 500, 1000]
        if milestones.contains(totalTasks) {
            return "\(totalTasks) Tasks Complete!"
        }

        // Check for level up
        let currentLevel = gamification.currentLevel
        let points = gamification.totalPoints + (task.pointsEarned ?? 0)
        let newLevel = gamification.calculateLevel(for: points)
        if newLevel > currentLevel {
            return "Level \(newLevel) Reached!"
        }

        // Check for streak milestones
        let streak = gamification.currentStreak
        let streakMilestones = [7, 14, 30, 60, 100]
        if streakMilestones.contains(streak + 1) {
            return "\(streak + 1) Day Streak!"
        }

        return nil
    }

    // MARK: - Personal Bests

    func checkPersonalBests(after task: TaskItem? = nil) -> PersonalBest? {
        return personalBests.checkForNewRecords(
            tasksToday: gamification.tasksCompletedToday + 1,
            xpToday: gamification.totalPoints,
            currentStreak: momentumState.streakCount,
            focusMinutes: gamification.focusMinutesTotal
        )
    }

    // MARK: - Momentum Management

    private func setupDecayTimer() {
        decayCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkMomentumDecay()
            }
        }
    }

    private func checkMomentumDecay() {
        if momentumState.shouldDecay() {
            let wasActive = momentumState.isActive
            momentumState.reset()
            momentumChanged.send(momentumState)

            // Subtle notification if was active
            if wasActive && soundsEnabled {
                sounds.playStreakBreak()
            }
        }
    }

    /// Force reset momentum (e.g., end of day)
    func resetMomentum() {
        momentumState.reset()
        momentumChanged.send(momentumState)
    }

    // MARK: - Celebration Messages

    private func celebrationMessage(for level: CelebrationLevel, task: TaskItem) -> String? {
        switch level {
        case .quick:
            return nil
        case .normal:
            return momentumState.isActive ? "Momentum!" : nil
        case .important:
            let messages = [
                "Crushed it!",
                "Great work!",
                "Outstanding!",
                "You're on fire!",
                "Stellar!",
                "Impressive!",
                "Keep dominating!"
            ]
            return messages.randomElement()
        case .milestone:
            return nil // Handled by milestone detection
        }
    }

    // MARK: - Overlay Dismissal

    func dismissMilestoneOverlay() {
        showingMilestoneOverlay = false
        pendingMilestone = nil
    }
}

// MARK: - Celebration Intensity

enum CelebrationIntensity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var particleMultiplier: Double {
        switch self {
        case .low: return 0.5
        case .medium: return 1.0
        case .high: return 1.5
        }
    }

    var soundVolume: Float {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.9
        }
    }
}

// MARK: - Theme Extension for Celebration Colors

extension Theme {
    struct Celebration {
        // Core celebration colors
        static let plasmaCore = Color(red: 0.4, green: 0.9, blue: 1.0)
        static let auroraGreen = Color(red: 0.2, green: 1.0, blue: 0.6)
        static let solarFlare = Color(red: 1.0, green: 0.7, blue: 0.3)
        static let supernovaWhite = Color(red: 1.0, green: 0.98, blue: 0.95)

        // Flame gradient for momentum
        static let flameCore = Color(red: 1.0, green: 0.95, blue: 0.85)
        static let flameInner = Color(red: 1.0, green: 0.75, blue: 0.20)
        static let flameMid = Color(red: 1.0, green: 0.45, blue: 0.15)
        static let flameOuter = Color(red: 0.90, green: 0.25, blue: 0.10)

        // XP and success
        static let starGold = Color(red: 1.0, green: 0.84, blue: 0.40)
        static let successGlow = Color(red: 0.20, green: 0.85, blue: 0.55)
        static let nebulaCore = Color(red: 0.58, green: 0.25, blue: 0.98)

        // Confetti palette
        static let confettiColors: [Color] = [
            Color(red: 0.98, green: 0.36, blue: 0.64), // Rose
            Color(red: 0.58, green: 0.22, blue: 0.88), // Purple
            Color(red: 0.24, green: 0.56, blue: 0.98), // Electric Blue
            Color(red: 0.14, green: 0.82, blue: 0.94), // Cyan
            Color(red: 0.20, green: 0.85, blue: 0.64), // Emerald
            Color(red: 1.0, green: 0.84, blue: 0.40),  // Gold
        ]

        // Gradient for XP popup
        static let xpGradient = LinearGradient(
            colors: [starGold, solarFlare],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Momentum flame gradient
        static let flameGradient = LinearGradient(
            colors: [flameCore, flameInner, flameMid, flameOuter],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}
