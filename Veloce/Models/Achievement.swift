//
//  Achievement.swift
//  MyTasksAI
//
//  Achievement Model - SwiftData + Supabase compatible
//  Represents user achievements and badges
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Achievement Model
@Model
final class Achievement {
    // MARK: Core Properties
    var id: UUID
    var userId: UUID?
    var type: String  // AchievementType.rawValue
    var unlockedAt: Date?
    var acknowledged: Bool
    var progress: Double?

    // MARK: Timestamps
    var createdAt: Date

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        type: String,
        unlockedAt: Date? = nil,
        acknowledged: Bool = false,
        progress: Double? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.unlockedAt = unlockedAt
        self.acknowledged = acknowledged
        self.progress = progress
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties
extension Achievement {
    /// Achievement type as enum
    var typeEnum: AchievementType? {
        AchievementType(rawValue: type)
    }

    /// Is unlocked
    var isUnlocked: Bool {
        unlockedAt != nil
    }

    /// Display title
    var title: String {
        typeEnum?.title ?? type
    }

    /// Display description
    var achievementDescription: String {
        typeEnum?.achievementDescription ?? ""
    }

    /// Icon name
    var icon: String {
        typeEnum?.icon ?? "star.fill"
    }

    /// Badge color
    var color: Color {
        typeEnum?.color ?? Theme.Colors.accent
    }

    /// Points awarded
    var points: Int {
        typeEnum?.points ?? 0
    }
}

// MARK: - Methods
extension Achievement {
    /// Unlock the achievement
    func unlock() {
        guard unlockedAt == nil else { return }
        unlockedAt = .now
    }

    /// Acknowledge the achievement
    func acknowledge() {
        acknowledged = true
    }

    /// Update from Supabase
    func update(from supabaseAchievement: SupabaseAchievement) {
        type = supabaseAchievement.type
        unlockedAt = supabaseAchievement.unlockedAt
        acknowledged = supabaseAchievement.acknowledged ?? false
        progress = supabaseAchievement.progress
    }

    /// Convert to Supabase achievement for syncing
    func toSupabase(userId: UUID) -> SupabaseAchievement {
        SupabaseAchievement(from: self, userId: userId)
    }
}

// MARK: - Achievement Type
enum AchievementType: String, Codable, CaseIterable, Sendable {
    // Task Milestones
    case firstTask = "first_task"
    case tasksBronze = "tasks_bronze"       // 10 tasks
    case tasksSilver = "tasks_silver"       // 50 tasks
    case tasksGold = "tasks_gold"           // 100 tasks
    case tasksDiamond = "tasks_diamond"     // 500 tasks

    // Streak Milestones
    case firstStreak = "first_streak"
    case streakBronze = "streak_bronze"     // 3 days
    case streakSilver = "streak_silver"     // 7 days
    case streakGold = "streak_gold"         // 30 days
    case streakDiamond = "streak_diamond"   // 100 days

    // Special Achievements
    case earlyBird = "early_bird"           // Complete task before 8am
    case nightOwl = "night_owl"             // Complete task after 10pm
    case perfectWeek = "perfect_week"       // All daily goals met for 7 days
    case aiExplorer = "ai_explorer"         // View AI advice 10 times
    case goalSetter = "goal_setter"         // Set first goal
    case goalAchiever = "goal_achiever"     // Complete first goal

    // Legacy Aliases (for backward compatibility with GamificationService)
    case tenTasks = "ten_tasks"
    case hundredTasks = "hundred_tasks"
    case thousandTasks = "thousand_tasks"
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    case centuryStreak = "century_streak"
    case levelFive = "level_five"
    case levelTen = "level_ten"
    case productiveDay = "productive_day"

    // Additional Special Achievements
    case weekendWarrior = "weekend_warrior"
    case aiCollaborator = "ai_collaborator"
    case brainDumpMaster = "brain_dump_master"
    case reflectionGuru = "reflection_guru"

    // Focus Mode Achievements
    case focusFirst = "focus_first"             // Complete first focus session with blocking
    case focusHour = "focus_hour"               // Complete a 1-hour focus session
    case deepFocusMaster = "deep_focus_master"  // Complete 10 Deep Focus sessions
    case distractionFree = "distraction_free"   // Complete 50 focus sessions with blocking
    case focusStreak = "focus_streak"           // Use focus mode 7 days in a row

    // Pact Achievements
    case pactFirst = "pact_first"               // Start your first pact
    case pactWeek = "pact_week"                 // 7-day mutual pact streak
    case pactMonth = "pact_month"               // 30-day mutual pact streak
    case pactCentury = "pact_century"           // 100-day mutual pact streak (legendary)
    case pactMaster = "pact_master"             // Complete 5 pacts successfully

    var title: String {
        switch self {
        case .firstTask: return "Getting Started"
        case .tasksBronze, .tenTasks: return "Task Apprentice"
        case .tasksSilver: return "Task Master"
        case .tasksGold, .hundredTasks: return "Task Champion"
        case .tasksDiamond, .thousandTasks: return "Task Legend"
        case .firstStreak: return "On a Roll"
        case .streakBronze: return "Streak Starter"
        case .streakSilver, .weekStreak: return "Streak Keeper"
        case .streakGold, .monthStreak: return "Streak Master"
        case .streakDiamond, .centuryStreak: return "Streak Legend"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .perfectWeek: return "Perfect Week"
        case .aiExplorer: return "AI Explorer"
        case .goalSetter: return "Goal Setter"
        case .goalAchiever: return "Goal Achiever"
        case .levelFive: return "Level 5"
        case .levelTen: return "Level 10"
        case .productiveDay: return "Productive Day"
        case .weekendWarrior: return "Weekend Warrior"
        case .aiCollaborator: return "AI Collaborator"
        case .brainDumpMaster: return "Brain Dump Master"
        case .reflectionGuru: return "Reflection Guru"
        case .focusFirst: return "Focus Starter"
        case .focusHour: return "Deep Concentration"
        case .deepFocusMaster: return "Deep Focus Master"
        case .distractionFree: return "Distraction Free"
        case .focusStreak: return "Focus Streak"
        case .pactFirst: return "Pact Partner"
        case .pactWeek: return "Pact Keeper"
        case .pactMonth: return "Pact Champion"
        case .pactCentury: return "Pact Legend"
        case .pactMaster: return "Pact Master"
        }
    }

    var achievementDescription: String {
        switch self {
        case .firstTask: return "Complete your first task"
        case .tasksBronze, .tenTasks: return "Complete 10 tasks"
        case .tasksSilver: return "Complete 50 tasks"
        case .tasksGold, .hundredTasks: return "Complete 100 tasks"
        case .tasksDiamond, .thousandTasks: return "Complete 500 tasks"
        case .firstStreak: return "Complete tasks 2 days in a row"
        case .streakBronze: return "Maintain a 3-day streak"
        case .streakSilver, .weekStreak: return "Maintain a 7-day streak"
        case .streakGold, .monthStreak: return "Maintain a 30-day streak"
        case .streakDiamond, .centuryStreak: return "Maintain a 100-day streak"
        case .earlyBird: return "Complete a task before 8 AM"
        case .nightOwl: return "Complete a task after 10 PM"
        case .perfectWeek: return "Meet daily goals for 7 consecutive days"
        case .aiExplorer: return "View AI advice 10 times"
        case .goalSetter: return "Set your first goal"
        case .goalAchiever: return "Complete your first goal"
        case .levelFive: return "Reach level 5"
        case .levelTen: return "Reach level 10"
        case .productiveDay: return "Complete 10 tasks in a single day"
        case .weekendWarrior: return "Complete tasks on both Saturday and Sunday"
        case .aiCollaborator: return "Use AI assistance for 25 tasks"
        case .brainDumpMaster: return "Add 20 tasks in a single session"
        case .reflectionGuru: return "Review your daily reflection 10 times"
        case .focusFirst: return "Complete your first focus session with app blocking"
        case .focusHour: return "Complete a 1-hour focus session with app blocking"
        case .deepFocusMaster: return "Complete 10 Deep Focus sessions (unbreakable)"
        case .distractionFree: return "Complete 50 focus sessions with app blocking"
        case .focusStreak: return "Use focus mode 7 days in a row"
        case .pactFirst: return "Start your first mutual accountability pact"
        case .pactWeek: return "Maintain a 7-day mutual pact streak"
        case .pactMonth: return "Maintain a 30-day mutual pact streak"
        case .pactCentury: return "Achieve a legendary 100-day mutual pact streak"
        case .pactMaster: return "Complete 5 pacts successfully"
        }
    }

    var icon: String {
        switch self {
        case .firstTask: return "checkmark.circle.fill"
        case .tasksBronze, .tasksSilver, .tasksGold, .tasksDiamond,
             .tenTasks, .hundredTasks, .thousandTasks:
            return "checkmark.seal.fill"
        case .firstStreak, .streakBronze, .streakSilver, .streakGold, .streakDiamond,
             .weekStreak, .monthStreak, .centuryStreak:
            return "flame.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .perfectWeek: return "calendar.badge.checkmark"
        case .aiExplorer: return "sparkles"
        case .goalSetter: return "target"
        case .goalAchiever: return "trophy.fill"
        case .levelFive, .levelTen: return "star.fill"
        case .productiveDay: return "bolt.fill"
        case .weekendWarrior: return "sun.max.fill"
        case .aiCollaborator: return "cpu"
        case .brainDumpMaster: return "brain"
        case .reflectionGuru: return "text.book.closed.fill"
        case .focusFirst: return "shield.lefthalf.filled"
        case .focusHour: return "hourglass"
        case .deepFocusMaster: return "lock.shield.fill"
        case .distractionFree: return "shield.checkered"
        case .focusStreak: return "flame.circle.fill"
        case .pactFirst: return "person.2.fill"
        case .pactWeek: return "person.2.badge.gearshape.fill"
        case .pactMonth: return "person.2.badge.plus"
        case .pactCentury: return "crown.fill"
        case .pactMaster: return "medal.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstTask, .firstStreak, .goalSetter:
            return Theme.Colors.success
        case .tasksBronze, .streakBronze, .tenTasks:
            return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .tasksSilver, .streakSilver, .weekStreak:
            return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .tasksGold, .streakGold, .perfectWeek, .hundredTasks, .monthStreak:
            return Color(red: 1.0, green: 0.84, blue: 0)
        case .tasksDiamond, .streakDiamond, .thousandTasks, .centuryStreak:
            return Theme.Colors.aiPurple
        case .earlyBird:
            return Theme.Colors.warning
        case .nightOwl:
            return Theme.Colors.aiBlue
        case .aiExplorer:
            return Theme.Colors.aiCyan
        case .goalAchiever:
            return Theme.Colors.accent
        case .levelFive:
            return Theme.Colors.info
        case .levelTen:
            return Theme.Colors.aiGold
        case .productiveDay:
            return Theme.Colors.success
        case .weekendWarrior:
            return Theme.Colors.warning
        case .aiCollaborator:
            return Theme.Colors.aiCyan
        case .brainDumpMaster:
            return Theme.Colors.aiPink
        case .reflectionGuru:
            return Theme.Colors.aiBlue
        case .focusFirst:
            return Theme.Colors.aiPurple
        case .focusHour:
            return Theme.Colors.aiCyan
        case .deepFocusMaster:
            return Color(red: 0.98, green: 0.35, blue: 0.40)  // Error nebula red
        case .distractionFree:
            return Theme.Colors.aiGold
        case .focusStreak:
            return Theme.Colors.aiOrange
        case .pactFirst:
            return Theme.Colors.aiPurple
        case .pactWeek:
            return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze
        case .pactMonth:
            return Theme.Colors.aiGold
        case .pactCentury:
            return Theme.Colors.aiPink  // Legendary pink
        case .pactMaster:
            return Theme.Colors.completionMint
        }
    }

    var points: Int {
        switch self {
        case .firstTask, .firstStreak, .goalSetter:
            return 50
        case .tasksBronze, .streakBronze, .tenTasks:
            return 100
        case .tasksSilver, .streakSilver, .weekStreak:
            return 250
        case .tasksGold, .streakGold, .hundredTasks, .monthStreak:
            return 500
        case .tasksDiamond, .streakDiamond, .thousandTasks, .centuryStreak:
            return 1000
        case .earlyBird, .nightOwl:
            return 25
        case .perfectWeek:
            return 200
        case .aiExplorer:
            return 50
        case .goalAchiever:
            return 150
        case .levelFive:
            return 200
        case .levelTen:
            return 500
        case .productiveDay:
            return 100
        case .weekendWarrior:
            return 75
        case .aiCollaborator:
            return 150
        case .brainDumpMaster:
            return 100
        case .reflectionGuru:
            return 125
        case .focusFirst:
            return 50
        case .focusHour:
            return 100
        case .deepFocusMaster:
            return 500
        case .distractionFree:
            return 1000
        case .focusStreak:
            return 250
        case .pactFirst:
            return 100
        case .pactWeek:
            return 250
        case .pactMonth:
            return 750
        case .pactCentury:
            return 2000
        case .pactMaster:
            return 500
        }
    }

    /// Threshold for unlocking
    var threshold: Int {
        switch self {
        case .firstTask: return 1
        case .tasksBronze: return 10
        case .tasksSilver: return 50
        case .tasksGold: return 100
        case .tasksDiamond: return 500
        case .firstStreak: return 2
        case .streakBronze: return 3
        case .streakSilver: return 7
        case .streakGold: return 30
        case .streakDiamond: return 100
        case .aiExplorer: return 10
        case .focusFirst: return 1
        case .focusHour: return 1
        case .deepFocusMaster: return 10
        case .distractionFree: return 50
        case .focusStreak: return 7
        case .pactFirst: return 1
        case .pactWeek: return 7
        case .pactMonth: return 30
        case .pactCentury: return 100
        case .pactMaster: return 5
        default: return 1
        }
    }
}

// MARK: - Supabase Achievement DTO
struct SupabaseAchievement: Codable, Sendable {
    let id: UUID
    let userId: UUID
    var type: String
    var unlockedAt: Date?
    var acknowledged: Bool?
    var progress: Double?
    var createdAt: Date?

    init(from achievement: Achievement, userId: UUID) {
        self.id = achievement.id
        self.userId = userId
        self.type = achievement.type
        self.unlockedAt = achievement.unlockedAt
        self.acknowledged = achievement.acknowledged
        self.progress = achievement.progress
        self.createdAt = achievement.createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case unlockedAt = "unlocked_at"
        case acknowledged
        case progress
        case createdAt = "created_at"
    }
}
