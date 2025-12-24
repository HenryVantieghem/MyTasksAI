//
//  PowerUp.swift
//  Veloce
//
//  Power-Up Model - Productivity Boosters
//  Collectible items that provide temporary advantages
//  Earned through achievements, streaks, and milestones
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Power-Up Type

enum PowerUpType: String, Codable, CaseIterable {
    case xpBoost = "xp_boost"           // 2x XP for 30 minutes
    case streakShield = "streak_shield" // Protect streak for 1 day
    case goalAccelerator = "goal_accelerator" // +50% goal progress for 1 day
    case focusForceField = "focus_force_field" // Guaranteed focus session
    case comboKeeper = "combo_keeper"   // Combo doesn't decay for 1 hour

    var displayName: String {
        switch self {
        case .xpBoost: return "XP Boost"
        case .streakShield: return "Streak Shield"
        case .goalAccelerator: return "Goal Accelerator"
        case .focusForceField: return "Focus Force Field"
        case .comboKeeper: return "Combo Keeper"
        }
    }

    var shortName: String {
        switch self {
        case .xpBoost: return "2x XP"
        case .streakShield: return "Shield"
        case .goalAccelerator: return "Accelerate"
        case .focusForceField: return "Focus"
        case .comboKeeper: return "Combo"
        }
    }

    var description: String {
        switch self {
        case .xpBoost:
            return "Double all XP earned for 30 minutes"
        case .streakShield:
            return "Protect your streak if you miss a day"
        case .goalAccelerator:
            return "Goal-linked tasks give +50% progress for 24 hours"
        case .focusForceField:
            return "Complete your next focus session without interruption"
        case .comboKeeper:
            return "Your combo won't decay for 1 hour"
        }
    }

    var icon: String {
        switch self {
        case .xpBoost: return "star.circle.fill"
        case .streakShield: return "shield.fill"
        case .goalAccelerator: return "bolt.circle.fill"
        case .focusForceField: return "brain.head.profile"
        case .comboKeeper: return "flame.circle.fill"
        }
    }

    var primaryColor: Color {
        switch self {
        case .xpBoost: return Color(red: 0.98, green: 0.75, blue: 0.25)
        case .streakShield: return Color(red: 0.42, green: 0.45, blue: 0.98)
        case .goalAccelerator: return Color(red: 0.20, green: 0.85, blue: 0.55)
        case .focusForceField: return Color(red: 0.58, green: 0.25, blue: 0.98)
        case .comboKeeper: return Color(red: 0.98, green: 0.55, blue: 0.25)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .xpBoost: return Color(red: 0.98, green: 0.55, blue: 0.25)
        case .streakShield: return Color(red: 0.20, green: 0.78, blue: 0.95)
        case .goalAccelerator: return Color(red: 0.20, green: 0.78, blue: 0.95)
        case .focusForceField: return Color(red: 0.42, green: 0.45, blue: 0.98)
        case .comboKeeper: return Color(red: 0.98, green: 0.35, blue: 0.20)
        }
    }

    var durationSeconds: TimeInterval {
        switch self {
        case .xpBoost: return 30 * 60           // 30 minutes
        case .streakShield: return 24 * 60 * 60 // 24 hours
        case .goalAccelerator: return 24 * 60 * 60 // 24 hours
        case .focusForceField: return 60 * 60   // 1 hour (or until focus session ends)
        case .comboKeeper: return 60 * 60       // 1 hour
        }
    }

    var durationText: String {
        switch self {
        case .xpBoost: return "30 min"
        case .streakShield: return "24 hours"
        case .goalAccelerator: return "24 hours"
        case .focusForceField: return "1 session"
        case .comboKeeper: return "1 hour"
        }
    }

    var maxQuantity: Int {
        3 // Max 3 of each type
    }

    var rarity: PowerUpRarity {
        switch self {
        case .xpBoost: return .common
        case .streakShield: return .rare
        case .goalAccelerator: return .rare
        case .focusForceField: return .epic
        case .comboKeeper: return .common
        }
    }
}

// MARK: - Power-Up Rarity

enum PowerUpRarity: String, Codable {
    case common
    case rare
    case epic
    case legendary

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .common: return .white
        case .rare: return Color(red: 0.42, green: 0.45, blue: 0.98)
        case .epic: return Color(red: 0.58, green: 0.25, blue: 0.98)
        case .legendary: return Color(red: 0.98, green: 0.75, blue: 0.25)
        }
    }

    var glowIntensity: Double {
        switch self {
        case .common: return 0.3
        case .rare: return 0.5
        case .epic: return 0.7
        case .legendary: return 1.0
        }
    }
}

// MARK: - Power-Up Source

enum PowerUpSource: String, Codable {
    case achievement = "achievement"
    case streak = "streak"
    case milestone = "milestone"
    case dailyLogin = "daily_login"
    case bossDefeat = "boss_defeat"
    case levelUp = "level_up"
    case purchase = "purchase"

    var displayName: String {
        switch self {
        case .achievement: return "Achievement Reward"
        case .streak: return "Streak Bonus"
        case .milestone: return "Milestone Reward"
        case .dailyLogin: return "Daily Login"
        case .bossDefeat: return "Boss Defeated"
        case .levelUp: return "Level Up Reward"
        case .purchase: return "Shop Purchase"
        }
    }
}

// MARK: - Power-Up Model

@Model
final class PowerUp {
    var id: UUID
    var userId: UUID?
    var type: String          // PowerUpType.rawValue
    var quantity: Int
    var isActive: Bool
    var activatedAt: Date?
    var expiresAt: Date?
    var earnedFrom: String?   // PowerUpSource.rawValue
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        type: PowerUpType,
        quantity: Int = 1,
        earnedFrom: PowerUpSource? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type.rawValue
        self.quantity = quantity
        self.isActive = false
        self.activatedAt = nil
        self.expiresAt = nil
        self.earnedFrom = earnedFrom?.rawValue
        self.createdAt = Date()
    }

    // MARK: Computed Properties

    var powerUpType: PowerUpType {
        PowerUpType(rawValue: type) ?? .xpBoost
    }

    var source: PowerUpSource? {
        guard let earnedFrom = earnedFrom else { return nil }
        return PowerUpSource(rawValue: earnedFrom)
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    var timeRemaining: TimeInterval {
        guard let expiresAt = expiresAt else { return 0 }
        return max(0, expiresAt.timeIntervalSince(Date()))
    }

    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        if remaining <= 0 { return "Expired" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    var canUse: Bool {
        quantity > 0 && !isActive
    }

    // MARK: Methods

    /// Activate this power-up
    func activate() {
        guard canUse else { return }

        quantity -= 1
        isActive = true
        activatedAt = Date()
        expiresAt = Date().addingTimeInterval(powerUpType.durationSeconds)
    }

    /// Deactivate this power-up (called when expired or used)
    func deactivate() {
        isActive = false
        activatedAt = nil
        expiresAt = nil
    }

    /// Add more of this power-up to inventory
    func addQuantity(_ amount: Int = 1) {
        quantity = min(quantity + amount, powerUpType.maxQuantity)
    }

    /// Check if this power-up should expire
    func checkExpiration() {
        if isActive && isExpired {
            deactivate()
        }
    }
}

// MARK: - Power-Up Inventory (Computed across all power-ups)

struct PowerUpInventory {
    let powerUps: [PowerUp]

    /// Get all power-ups of a specific type
    func powerUp(of type: PowerUpType) -> PowerUp? {
        powerUps.first { $0.powerUpType == type }
    }

    /// Get quantity of a specific power-up type
    func quantity(of type: PowerUpType) -> Int {
        powerUp(of: type)?.quantity ?? 0
    }

    /// Check if a power-up type is currently active
    func isActive(_ type: PowerUpType) -> Bool {
        guard let powerUp = powerUp(of: type) else { return false }
        return powerUp.isActive && !powerUp.isExpired
    }

    /// Get time remaining for an active power-up
    func timeRemaining(for type: PowerUpType) -> TimeInterval {
        guard let powerUp = powerUp(of: type), powerUp.isActive else { return 0 }
        return powerUp.timeRemaining
    }

    /// Get all active power-ups
    var activePowerUps: [PowerUp] {
        powerUps.filter { $0.isActive && !$0.isExpired }
    }

    /// Get total power-up count
    var totalCount: Int {
        powerUps.reduce(0) { $0 + $1.quantity }
    }

    /// Check if XP boost is active
    var hasXPBoost: Bool {
        isActive(.xpBoost)
    }

    /// Check if streak is protected
    var hasStreakShield: Bool {
        isActive(.streakShield)
    }

    /// Check if goal accelerator is active
    var hasGoalAccelerator: Bool {
        isActive(.goalAccelerator)
    }

    /// Check if focus force field is active
    var hasFocusForceField: Bool {
        isActive(.focusForceField)
    }

    /// Check if combo keeper is active
    var hasComboKeeper: Bool {
        isActive(.comboKeeper)
    }
}

// MARK: - Preview Helpers

extension PowerUp {
    static var xpBoostPreview: PowerUp {
        let powerUp = PowerUp(type: .xpBoost, quantity: 2, earnedFrom: .achievement)
        return powerUp
    }

    static var activeXPBoostPreview: PowerUp {
        let powerUp = PowerUp(type: .xpBoost, quantity: 1, earnedFrom: .streak)
        powerUp.isActive = true
        powerUp.activatedAt = Date().addingTimeInterval(-600) // 10 min ago
        powerUp.expiresAt = Date().addingTimeInterval(1200) // 20 min left
        return powerUp
    }

    static var streakShieldPreview: PowerUp {
        PowerUp(type: .streakShield, quantity: 1, earnedFrom: .streak)
    }

    static var allPreviews: [PowerUp] {
        [
            PowerUp(type: .xpBoost, quantity: 2, earnedFrom: .achievement),
            PowerUp(type: .streakShield, quantity: 1, earnedFrom: .streak),
            PowerUp(type: .goalAccelerator, quantity: 3, earnedFrom: .milestone),
            PowerUp(type: .focusForceField, quantity: 1, earnedFrom: .bossDefeat),
            PowerUp(type: .comboKeeper, quantity: 2, earnedFrom: .dailyLogin)
        ]
    }
}
