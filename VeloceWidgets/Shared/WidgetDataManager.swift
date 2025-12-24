//
//  WidgetDataManager.swift
//  VeloceWidgets
//
//  Widget Data Manager - App Groups Integration
//  Manages shared data between main app and widgets
//  Handles encoding/decoding and timeline refreshes
//

import Foundation
import WidgetKit

// MARK: - App Group Constants

enum WidgetAppGroup {
    static let identifier = "group.com.veloce.app"

    static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    // Storage keys
    enum Keys {
        static let tasks = "widget_tasks"
        static let stats = "widget_stats"
        static let focusSession = "widget_focus_session"
        static let calendarEvents = "widget_calendar_events"
    }
}

// MARK: - Widget Data Manager

/// Manages data sharing between the main app and widgets via App Groups
/// Call these methods from the main app when data changes
public enum WidgetDataManager {

    // MARK: - Tasks

    /// Updates the widget with current task data
    /// - Parameters:
    ///   - tasks: Array of tasks to display in widgets
    ///   - completedCount: Number of completed tasks today
    ///   - totalCount: Total number of tasks today
    public static func updateTasks(_ tasks: [WidgetTaskData], completedCount: Int, totalCount: Int) {
        guard let defaults = WidgetAppGroup.userDefaults else { return }

        let widgetTasks = tasks.map { task in
            WidgetTaskItem(
                id: task.id,
                title: task.title,
                isCompleted: task.isCompleted,
                priority: task.priority,
                scheduledTime: task.scheduledTime,
                starRating: task.starRating
            )
        }

        if let encoded = try? JSONEncoder().encode(widgetTasks) {
            defaults.set(encoded, forKey: WidgetAppGroup.Keys.tasks)
        }

        // Refresh widgets
        WidgetCenter.shared.reloadTimelines(ofKind: "VeloceTasksWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "VeloceQuickAddWidget")
    }

    // MARK: - Stats

    /// Updates the widget with current user stats
    public static func updateStats(
        tasksCompletedToday: Int,
        dailyGoal: Int,
        currentStreak: Int,
        longestStreak: Int,
        totalPoints: Int,
        currentLevel: Int,
        xpEarnedToday: Int = 0
    ) {
        guard let defaults = WidgetAppGroup.userDefaults else { return }

        let stats = WidgetStatsData(
            tasksCompletedToday: tasksCompletedToday,
            dailyGoal: dailyGoal,
            currentStreak: currentStreak,
            totalPoints: totalPoints,
            currentLevel: currentLevel
        )

        if let encoded = try? JSONEncoder().encode(stats) {
            defaults.set(encoded, forKey: WidgetAppGroup.Keys.stats)
        }

        // Refresh related widgets
        WidgetCenter.shared.reloadTimelines(ofKind: "VeloceProgressWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "VeloceStreakWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "VeloceXPWidget")
    }

    // MARK: - Focus Session

    /// Updates the widget with active focus session
    public static func updateFocusSession(_ session: WidgetFocusSessionData?) {
        guard let defaults = WidgetAppGroup.userDefaults else { return }

        if let session = session {
            let widgetSession = WidgetFocusSession(
                id: session.id,
                title: session.title,
                duration: session.duration,
                startTime: session.startTime,
                endTime: session.endTime,
                isDeepFocus: session.isDeepFocus
            )

            if let encoded = try? JSONEncoder().encode(widgetSession) {
                defaults.set(encoded, forKey: WidgetAppGroup.Keys.focusSession)
            }
        } else {
            defaults.removeObject(forKey: WidgetAppGroup.Keys.focusSession)
        }

        // Refresh focus widget
        WidgetCenter.shared.reloadTimelines(ofKind: "VeloceFocusWidget")
    }

    // MARK: - Calendar Events

    /// Updates the widget with today's calendar events
    public static func updateCalendarEvents(_ events: [WidgetCalendarEventData]) {
        guard let defaults = WidgetAppGroup.userDefaults else { return }

        let widgetEvents = events.map { event in
            WidgetCalendarEvent(
                id: event.id,
                title: event.title,
                time: event.time,
                colorHex: event.colorHex,
                isTask: event.isTask
            )
        }

        if let encoded = try? JSONEncoder().encode(widgetEvents) {
            defaults.set(encoded, forKey: WidgetAppGroup.Keys.calendarEvents)
        }

        // Refresh calendar widget
        WidgetCenter.shared.reloadTimelines(ofKind: "VeloceCalendarWidget")
    }

    // MARK: - Refresh All

    /// Forces a refresh of all widget timelines
    public static func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Input Data Models (from main app)

/// Task data to send to widgets
public struct WidgetTaskData {
    public let id: UUID
    public let title: String
    public let isCompleted: Bool
    public let priority: String
    public let scheduledTime: String?
    public let starRating: Int?

    public init(
        id: UUID,
        title: String,
        isCompleted: Bool,
        priority: String,
        scheduledTime: String? = nil,
        starRating: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.scheduledTime = scheduledTime
        self.starRating = starRating
    }
}

/// Focus session data to send to widgets
public struct WidgetFocusSessionData {
    public let id: UUID
    public let title: String
    public let duration: Int
    public let startTime: Date
    public let endTime: Date
    public let isDeepFocus: Bool

    public init(
        id: UUID,
        title: String,
        duration: Int,
        startTime: Date,
        endTime: Date,
        isDeepFocus: Bool
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.isDeepFocus = isDeepFocus
    }
}

/// Calendar event data to send to widgets
public struct WidgetCalendarEventData {
    public let id: UUID
    public let title: String
    public let time: String
    public let colorHex: String?
    public let isTask: Bool

    public init(
        id: UUID,
        title: String,
        time: String,
        colorHex: String? = nil,
        isTask: Bool
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.colorHex = colorHex
        self.isTask = isTask
    }
}

// MARK: - Extension for Main App Integration

extension WidgetDataManager {

    /// Convenience method to update all widget data at once
    /// Call this after significant app state changes
    public static func syncAllData(
        tasks: [WidgetTaskData],
        completedCount: Int,
        totalCount: Int,
        stats: (tasksToday: Int, goal: Int, streak: Int, longestStreak: Int, points: Int, level: Int),
        focusSession: WidgetFocusSessionData?,
        calendarEvents: [WidgetCalendarEventData]
    ) {
        updateTasks(tasks, completedCount: completedCount, totalCount: totalCount)
        updateStats(
            tasksCompletedToday: stats.tasksToday,
            dailyGoal: stats.goal,
            currentStreak: stats.streak,
            longestStreak: stats.longestStreak,
            totalPoints: stats.points,
            currentLevel: stats.level
        )
        updateFocusSession(focusSession)
        updateCalendarEvents(calendarEvents)
    }
}
