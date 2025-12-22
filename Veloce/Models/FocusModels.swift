//
//  FocusModels.swift
//  Veloce
//
//  SwiftData models for Focus/App Blocking feature
//  Stores completed sessions, block lists, and scheduled sessions
//

import Foundation
import SwiftData

// MARK: - Focus Session (Completed Session History)

/// Records a completed focus session for history and gamification
@Model
final class FocusSessionRecord {
    // MARK: Identity

    var id: UUID
    var userId: UUID?

    // MARK: Session Details

    var title: String
    var sessionType: String  // FocusSessionType raw value
    var startedAt: Date
    var endedAt: Date?
    var scheduledDuration: Int  // seconds
    var actualDuration: Int?    // seconds
    var isDeepFocus: Bool
    var wasCompleted: Bool
    var wasCanceled: Bool

    // MARK: Linked Task

    var taskId: UUID?
    var taskTitle: String?

    // MARK: Blocking Details (serialized token data)

    var blockedAppsData: Data?
    var blockedCategoriesData: Data?

    // MARK: Gamification

    var pointsEarned: Int

    // MARK: Metadata

    var createdAt: Date

    // MARK: Initialization

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        title: String,
        sessionType: FocusSessionType = .timed,
        startedAt: Date = Date(),
        scheduledDuration: Int,
        isDeepFocus: Bool = false,
        taskId: UUID? = nil,
        taskTitle: String? = nil,
        blockedAppsData: Data? = nil,
        blockedCategoriesData: Data? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.sessionType = sessionType.rawValue
        self.startedAt = startedAt
        self.endedAt = nil
        self.scheduledDuration = scheduledDuration
        self.actualDuration = nil
        self.isDeepFocus = isDeepFocus
        self.wasCompleted = false
        self.wasCanceled = false
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.blockedAppsData = blockedAppsData
        self.blockedCategoriesData = blockedCategoriesData
        self.pointsEarned = 0
        self.createdAt = Date()
    }

    // MARK: Computed Properties

    /// Session type enum
    var type: FocusSessionType {
        FocusSessionType(rawValue: sessionType) ?? .timed
    }

    /// Duration in minutes
    var durationMinutes: Int {
        (actualDuration ?? scheduledDuration) / 60
    }

    /// Formatted duration string
    var formattedDuration: String {
        let minutes = durationMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    /// Complete the session
    func complete(pointsEarned: Int) {
        self.endedAt = Date()
        self.actualDuration = Int(Date().timeIntervalSince(startedAt))
        self.wasCompleted = true
        self.wasCanceled = false
        self.pointsEarned = pointsEarned
    }

    /// Cancel the session
    func cancel() {
        self.endedAt = Date()
        self.actualDuration = Int(Date().timeIntervalSince(startedAt))
        self.wasCompleted = false
        self.wasCanceled = true
        self.pointsEarned = 0
    }
}

// MARK: - Focus Block List (Saved Presets)

/// A saved block list preset that users can quickly apply
@Model
final class FocusBlockList {
    // MARK: Identity

    var id: UUID
    var userId: UUID?

    // MARK: List Details

    var name: String
    var listDescription: String?
    var iconName: String
    var colorHex: String
    var isDefault: Bool
    var isAllowList: Bool  // If true, blocks everything EXCEPT selected apps

    // MARK: Selection Data (serialized FamilyActivitySelection)

    var selectionData: Data?

    // MARK: Usage Stats

    var useCount: Int
    var lastUsedAt: Date?

    // MARK: Metadata

    var createdAt: Date
    var updatedAt: Date

    // MARK: Initialization

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        name: String,
        description: String? = nil,
        iconName: String = "shield.lefthalf.filled",
        colorHex: String = "#9440FA",
        isDefault: Bool = false,
        isAllowList: Bool = false,
        selectionData: Data? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.listDescription = description
        self.iconName = iconName
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.isAllowList = isAllowList
        self.selectionData = selectionData
        self.useCount = 0
        self.lastUsedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: Preset Factory

    /// Create "Work Mode" preset
    static func workModePreset() -> FocusBlockList {
        FocusBlockList(
            name: "Work Mode",
            description: "Block social media and entertainment during work",
            iconName: "briefcase.fill",
            colorHex: "#6B73F9"
        )
    }

    /// Create "Social Media Detox" preset
    static func socialMediaDetoxPreset() -> FocusBlockList {
        FocusBlockList(
            name: "Social Media Detox",
            description: "Block all social media apps",
            iconName: "bubble.left.and.bubble.right.fill",
            colorHex: "#FF6B6B"
        )
    }

    /// Create "Deep Work" preset
    static func deepWorkPreset() -> FocusBlockList {
        FocusBlockList(
            name: "Deep Work",
            description: "Block everything except essential apps",
            iconName: "brain.head.profile",
            colorHex: "#14CC8C",
            isAllowList: true
        )
    }

    // MARK: Methods

    /// Mark as used
    func markAsUsed() {
        useCount += 1
        lastUsedAt = Date()
        updatedAt = Date()
    }

    /// Update selection data
    func updateSelection(_ data: Data?) {
        selectionData = data
        updatedAt = Date()
    }
}

// MARK: - Scheduled Focus Session

/// A scheduled or recurring focus session
@Model
final class ScheduledFocusSession {
    // MARK: Identity

    var id: UUID
    var userId: UUID?

    // MARK: Schedule Details

    var title: String
    var startTime: Date  // For one-time schedules
    var startHour: Int   // Hour of day (0-23) for recurring
    var startMinute: Int // Minute (0-59) for recurring
    var duration: Int    // seconds
    var isRecurring: Bool
    var recurringDays: [Int]?  // 0 = Sunday, 6 = Saturday
    var recurringEndDate: Date?
    var isEnabled: Bool

    // MARK: Session Settings

    var isDeepFocus: Bool
    var blockListId: UUID?  // Reference to FocusBlockList

    // MARK: Metadata

    var createdAt: Date
    var updatedAt: Date
    var lastTriggeredAt: Date?

    // MARK: Initialization

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        title: String,
        startTime: Date = Date(),
        duration: Int = 25 * 60,
        isRecurring: Bool = false,
        recurringDays: [Int]? = nil,
        isDeepFocus: Bool = false,
        blockListId: UUID? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.startTime = startTime

        // Extract hour/minute for recurring
        let calendar = Calendar.current
        self.startHour = calendar.component(.hour, from: startTime)
        self.startMinute = calendar.component(.minute, from: startTime)

        self.duration = duration
        self.isRecurring = isRecurring
        self.recurringDays = recurringDays
        self.recurringEndDate = nil
        self.isEnabled = true
        self.isDeepFocus = isDeepFocus
        self.blockListId = blockListId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastTriggeredAt = nil
    }

    // MARK: Computed Properties

    /// Duration in minutes
    var durationMinutes: Int {
        duration / 60
    }

    /// Formatted start time
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    /// Formatted recurring days
    var formattedRecurringDays: String {
        guard let days = recurringDays, !days.isEmpty else {
            return "No days selected"
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = days.sorted()

        // Check for common patterns
        if sortedDays == [1, 2, 3, 4, 5] {
            return "Weekdays"
        }
        if sortedDays == [0, 6] {
            return "Weekends"
        }
        if sortedDays == [0, 1, 2, 3, 4, 5, 6] {
            return "Every day"
        }

        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }

    /// Next occurrence date
    var nextOccurrence: Date? {
        guard isEnabled else { return nil }

        if !isRecurring {
            return startTime > Date() ? startTime : nil
        }

        guard let days = recurringDays, !days.isEmpty else { return nil }

        let calendar = Calendar.current
        var nextDate = Date()

        // Find next matching day
        for _ in 0..<8 {  // Check up to a week ahead
            let weekday = calendar.component(.weekday, from: nextDate) - 1  // Convert to 0-based
            if days.contains(weekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: nextDate)
                components.hour = startHour
                components.minute = startMinute
                components.second = 0

                if let candidateDate = calendar.date(from: components),
                   candidateDate > Date() {
                    return candidateDate
                }
            }
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
        }

        return nil
    }
}

// MARK: - Focus Statistics (Computed)

/// Aggregated focus statistics for gamification and insights
struct FocusStatistics {
    var totalSessionsCompleted: Int = 0
    var totalMinutesFocused: Int = 0
    var deepFocusSessionsCompleted: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var averageSessionDuration: Int = 0  // minutes
    var mostUsedBlockList: String?
    var bestFocusDay: String?  // Day of week

    /// Calculate from session records
    static func calculate(from sessions: [FocusSessionRecord]) -> FocusStatistics {
        var stats = FocusStatistics()

        let completedSessions = sessions.filter { $0.wasCompleted }
        stats.totalSessionsCompleted = completedSessions.count

        let totalSeconds = completedSessions.reduce(0) { $0 + ($1.actualDuration ?? 0) }
        stats.totalMinutesFocused = totalSeconds / 60

        stats.deepFocusSessionsCompleted = completedSessions.filter { $0.isDeepFocus }.count

        if !completedSessions.isEmpty {
            stats.averageSessionDuration = stats.totalMinutesFocused / completedSessions.count
        }

        // Calculate streaks (consecutive days with at least one session)
        let calendar = Calendar.current
        var sessionDays = Set<DateComponents>()
        for session in completedSessions {
            let components = calendar.dateComponents([.year, .month, .day], from: session.startedAt)
            sessionDays.insert(components)
        }

        // Sort days and calculate streaks
        let sortedDays = sessionDays.compactMap { calendar.date(from: $0) }.sorted()
        var currentStreak = 0
        var maxStreak = 0
        var previousDate: Date?

        for date in sortedDays {
            if let prev = previousDate {
                let daysBetween = calendar.dateComponents([.day], from: prev, to: date).day ?? 0
                if daysBetween == 1 {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            maxStreak = max(maxStreak, currentStreak)
            previousDate = date
        }

        // Check if streak is current (includes today or yesterday)
        if let lastDay = sortedDays.last {
            let daysSinceLastSession = calendar.dateComponents([.day], from: lastDay, to: Date()).day ?? 0
            if daysSinceLastSession > 1 {
                currentStreak = 0
            }
        }

        stats.currentStreak = currentStreak
        stats.longestStreak = maxStreak

        return stats
    }
}
