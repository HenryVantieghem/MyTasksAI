//
//  WeeklyBoss.swift
//  Veloce
//
//  Weekly Boss Model - Epic Boss Battles for Productivity
//  Each week you face a boss themed around your most important goal
//  Defeat it by completing tasks and milestones for epic rewards
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Boss Appearance (Theme)

enum BossAppearance: String, Codable, CaseIterable {
    case deadlineDragon = "deadline_dragon"       // Career
    case procrastinationPhoenix = "procrastination_phoenix" // Health
    case knowledgeKraken = "knowledge_kraken"     // Learning
    case budgetBehemoth = "budget_behemoth"       // Finance
    case chaosChimera = "chaos_chimera"           // Relationships
    case creativeCerberus = "creative_cerberus"   // Creative
    case shadowSerpent = "shadow_serpent"         // Personal
    case voidVanguard = "void_vanguard"           // Other/Default

    var displayName: String {
        switch self {
        case .deadlineDragon: return "The Deadline Dragon"
        case .procrastinationPhoenix: return "The Procrastination Phoenix"
        case .knowledgeKraken: return "The Knowledge Kraken"
        case .budgetBehemoth: return "The Budget Behemoth"
        case .chaosChimera: return "The Chaos Chimera"
        case .creativeCerberus: return "The Creative Cerberus"
        case .shadowSerpent: return "The Shadow Serpent"
        case .voidVanguard: return "The Void Vanguard"
        }
    }

    var icon: String {
        switch self {
        case .deadlineDragon: return "flame.fill"
        case .procrastinationPhoenix: return "bird.fill"
        case .knowledgeKraken: return "brain.head.profile"
        case .budgetBehemoth: return "chart.line.uptrend.xyaxis"
        case .chaosChimera: return "person.2.fill"
        case .creativeCerberus: return "paintpalette.fill"
        case .shadowSerpent: return "moon.stars.fill"
        case .voidVanguard: return "sparkles"
        }
    }

    var primaryColor: Color {
        switch self {
        case .deadlineDragon: return Color(red: 0.98, green: 0.35, blue: 0.20)
        case .procrastinationPhoenix: return Color(red: 0.20, green: 0.85, blue: 0.55)
        case .knowledgeKraken: return Color(red: 0.58, green: 0.25, blue: 0.98)
        case .budgetBehemoth: return Color(red: 0.98, green: 0.75, blue: 0.25)
        case .chaosChimera: return Color(red: 0.98, green: 0.45, blue: 0.65)
        case .creativeCerberus: return Color(red: 0.98, green: 0.55, blue: 0.25)
        case .shadowSerpent: return Color(red: 0.20, green: 0.78, blue: 0.95)
        case .voidVanguard: return Color(red: 0.42, green: 0.45, blue: 0.98)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .deadlineDragon: return Color(red: 0.98, green: 0.55, blue: 0.25)
        case .procrastinationPhoenix: return Color(red: 0.20, green: 0.78, blue: 0.95)
        case .knowledgeKraken: return Color(red: 0.42, green: 0.45, blue: 0.98)
        case .budgetBehemoth: return Color(red: 0.98, green: 0.55, blue: 0.25)
        case .chaosChimera: return Color(red: 0.98, green: 0.35, blue: 0.45)
        case .creativeCerberus: return Color(red: 0.98, green: 0.75, blue: 0.25)
        case .shadowSerpent: return Color(red: 0.42, green: 0.45, blue: 0.98)
        case .voidVanguard: return Color(red: 0.58, green: 0.25, blue: 0.98)
        }
    }

    var tauntMessages: [String] {
        switch self {
        case .deadlineDragon:
            return [
                "Your deadlines fuel my flames!",
                "Tick tock... time slips away...",
                "Another task undone, another victory for me!"
            ]
        case .procrastinationPhoenix:
            return [
                "Why do today what you can put off forever?",
                "Rest now... there's always tomorrow...",
                "Your motivation feeds my rebirth!"
            ]
        case .knowledgeKraken:
            return [
                "Your confusion is my power!",
                "The depths of ignorance are endless...",
                "Each unlearned lesson strengthens me!"
            ]
        case .budgetBehemoth:
            return [
                "Your finances are in chaos!",
                "Spend now, regret later...",
                "Every impulse purchase makes me grow!"
            ]
        case .chaosChimera:
            return [
                "Relationships crumble around you!",
                "Isolation is my domain...",
                "Your disconnection empowers me!"
            ]
        case .creativeCerberus:
            return [
                "Your creativity withers!",
                "Blank pages are my feast...",
                "Each abandoned project feeds me!"
            ]
        case .shadowSerpent:
            return [
                "Your goals slip into shadow...",
                "Personal growth? A distant dream...",
                "Self-improvement is futile!"
            ]
        case .voidVanguard:
            return [
                "The void consumes all progress!",
                "Your efforts are meaningless...",
                "Entropy always wins!"
            ]
        }
    }

    var defeatMessage: String {
        switch self {
        case .deadlineDragon: return "You've conquered the flames of deadlines!"
        case .procrastinationPhoenix: return "Procrastination has been defeated!"
        case .knowledgeKraken: return "Knowledge triumphs over ignorance!"
        case .budgetBehemoth: return "Financial discipline prevails!"
        case .chaosChimera: return "Harmony overcomes chaos!"
        case .creativeCerberus: return "Creativity flows freely once more!"
        case .shadowSerpent: return "Personal growth illuminates the shadow!"
        case .voidVanguard: return "You've filled the void with purpose!"
        }
    }

    static func from(goalCategory: String?) -> BossAppearance {
        guard let category = goalCategory?.lowercased() else { return .voidVanguard }
        switch category {
        case "career": return .deadlineDragon
        case "health": return .procrastinationPhoenix
        case "learning": return .knowledgeKraken
        case "finance": return .budgetBehemoth
        case "relationships": return .chaosChimera
        case "creative": return .creativeCerberus
        case "personal": return .shadowSerpent
        default: return .voidVanguard
        }
    }
}

// MARK: - Boss Difficulty

enum BossDifficulty: String, Codable, CaseIterable {
    case normal = "normal"
    case hard = "hard"
    case nightmare = "nightmare"

    var healthMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .hard: return 1.5
        case .nightmare: return 2.0
        }
    }

    var xpMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .hard: return 1.5
        case .nightmare: return 2.5
        }
    }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .hard: return "Hard"
        case .nightmare: return "Nightmare"
        }
    }

    var color: Color {
        switch self {
        case .normal: return .white
        case .hard: return Color(red: 0.98, green: 0.55, blue: 0.25)
        case .nightmare: return Color(red: 0.98, green: 0.35, blue: 0.20)
        }
    }
}

// MARK: - Weekly Boss Model

@Model
final class WeeklyBoss {
    var id: UUID
    var userId: UUID?
    var name: String
    var appearance: String  // BossAppearance.rawValue
    var difficulty: String  // BossDifficulty.rawValue
    var totalHealth: Int
    var currentHealth: Int
    var damageDealt: Int
    var xpReward: Int
    var linkedGoalId: UUID?
    var weekStart: Date
    var isDefeated: Bool
    var defeatedAt: Date?
    var criticalHits: Int   // Milestone completions
    var tasksDefeated: Int  // Regular task completions
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        name: String,
        appearance: BossAppearance,
        difficulty: BossDifficulty = .normal,
        baseHealth: Int = 20,
        xpReward: Int = 200,
        linkedGoalId: UUID? = nil,
        weekStart: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.appearance = appearance.rawValue
        self.difficulty = difficulty.rawValue
        let calculatedHealth = Int(Double(baseHealth) * difficulty.healthMultiplier)
        self.totalHealth = calculatedHealth
        self.currentHealth = calculatedHealth
        self.damageDealt = 0
        self.xpReward = Int(Double(xpReward) * difficulty.xpMultiplier)
        self.linkedGoalId = linkedGoalId
        self.weekStart = weekStart ?? Self.startOfWeek()
        self.isDefeated = false
        self.defeatedAt = nil
        self.criticalHits = 0
        self.tasksDefeated = 0
        self.createdAt = Date()
    }

    // MARK: Computed Properties

    var bossAppearance: BossAppearance {
        BossAppearance(rawValue: appearance) ?? .voidVanguard
    }

    var bossDifficulty: BossDifficulty {
        BossDifficulty(rawValue: difficulty) ?? .normal
    }

    var healthProgress: Double {
        guard totalHealth > 0 else { return 0 }
        return Double(currentHealth) / Double(totalHealth)
    }

    var damageProgress: Double {
        1.0 - healthProgress
    }

    var isLowHealth: Bool {
        healthProgress < 0.25
    }

    var isCriticalHealth: Bool {
        healthProgress < 0.1
    }

    var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    var timeRemaining: TimeInterval {
        weekEnd.timeIntervalSince(Date())
    }

    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        if remaining <= 0 { return "Expired" }

        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600

        if days > 0 {
            return "\(days)d \(hours)h left"
        } else {
            let minutes = (Int(remaining) % 3600) / 60
            return "\(hours)h \(minutes)m left"
        }
    }

    var isExpired: Bool {
        Date() > weekEnd && !isDefeated
    }

    var currentTaunt: String {
        let taunts = bossAppearance.tauntMessages
        let index = abs(currentHealth.hashValue) % taunts.count
        return taunts[index]
    }

    // MARK: Combat Methods

    /// Deal damage to the boss from a regular task completion
    func dealDamage(_ amount: Int = 1) -> Int {
        let damage = amount
        currentHealth = max(0, currentHealth - damage)
        damageDealt += damage
        tasksDefeated += 1

        if currentHealth == 0 && !isDefeated {
            isDefeated = true
            defeatedAt = Date()
        }

        return damage
    }

    /// Deal critical hit damage (from milestone completion)
    func dealCriticalHit(_ amount: Int = 2) -> Int {
        let damage = amount
        currentHealth = max(0, currentHealth - damage)
        damageDealt += damage
        criticalHits += 1

        if currentHealth == 0 && !isDefeated {
            isDefeated = true
            defeatedAt = Date()
        }

        return damage
    }

    /// Calculate bonus XP based on performance
    func calculateBonusXP() -> Int {
        var bonus = 0

        // Speed bonus (defeated early in the week)
        if isDefeated {
            let timeToDefeat = defeatedAt?.timeIntervalSince(weekStart) ?? 0
            let daysToDefeat = timeToDefeat / 86400
            if daysToDefeat < 3 {
                bonus += 50 // Speed bonus
            } else if daysToDefeat < 5 {
                bonus += 25
            }
        }

        // Critical hit bonus
        bonus += criticalHits * 10

        // Overkill bonus (if more damage dealt than required)
        if damageDealt > totalHealth {
            bonus += min((damageDealt - totalHealth) * 5, 100)
        }

        return bonus
    }

    // MARK: Factory Methods

    static func generateWeeklyBoss(for goal: Goal?, weeklyTarget: Int = 20, difficulty: BossDifficulty = .normal) -> WeeklyBoss {
        let appearance: BossAppearance
        let name: String
        let linkedGoalId: UUID?

        if let goal = goal {
            appearance = BossAppearance.from(goalCategory: goal.category)
            name = appearance.displayName
            linkedGoalId = goal.id
        } else {
            appearance = .voidVanguard
            name = "The Void Vanguard"
            linkedGoalId = nil
        }

        // Base health scales with weekly target
        let baseHealth = max(10, weeklyTarget)

        // XP reward scales with difficulty and target
        let baseXP = 100 + (weeklyTarget * 5)

        return WeeklyBoss(
            name: name,
            appearance: appearance,
            difficulty: difficulty,
            baseHealth: baseHealth,
            xpReward: baseXP,
            linkedGoalId: linkedGoalId
        )
    }

    // MARK: Helpers

    private static func startOfWeek() -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    }
}

// MARK: - Preview Helpers

extension WeeklyBoss {
    static var preview: WeeklyBoss {
        let boss = WeeklyBoss(
            name: "The Deadline Dragon",
            appearance: .deadlineDragon,
            difficulty: .normal,
            baseHealth: 20,
            xpReward: 200
        )
        boss.currentHealth = 12 // 60% health remaining
        boss.tasksDefeated = 6
        boss.criticalHits = 1
        return boss
    }

    static var lowHealthPreview: WeeklyBoss {
        let boss = WeeklyBoss(
            name: "The Knowledge Kraken",
            appearance: .knowledgeKraken,
            difficulty: .hard,
            baseHealth: 30,
            xpReward: 300
        )
        boss.currentHealth = 3 // 10% health remaining
        boss.tasksDefeated = 24
        boss.criticalHits = 3
        return boss
    }

    static var defeatedPreview: WeeklyBoss {
        let boss = WeeklyBoss(
            name: "The Procrastination Phoenix",
            appearance: .procrastinationPhoenix,
            difficulty: .nightmare,
            baseHealth: 40,
            xpReward: 500
        )
        boss.currentHealth = 0
        boss.isDefeated = true
        boss.defeatedAt = Date()
        boss.tasksDefeated = 35
        boss.criticalHits = 5
        return boss
    }
}
