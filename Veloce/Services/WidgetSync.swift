//
//  WidgetSync.swift
//  Veloce
//
//  Widget Sync Service - Share Data with Widgets
//  Handles data sharing between main app and widget extensions
//

import Foundation
import WidgetKit

// MARK: - Widget Sync Service

@MainActor
final class WidgetSyncService {
    // MARK: Singleton
    static let shared = WidgetSyncService()

    // MARK: Configuration
    private let appGroupId = "group.com.veloce.app"  // Replace with actual app group ID
    private let tasksKey = "widget_tasks"
    private let statsKey = "widget_stats"
    private let lastUpdateKey = "widget_last_update"

    // MARK: Shared Container
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    // MARK: Initialization
    private init() {}

    // MARK: - Task Data

    /// Share tasks with widget
    func shareTasks(_ tasks: [TaskItem]) {
        guard let defaults = sharedDefaults else { return }

        let widgetTasks = tasks.prefix(10).map { task in
            WidgetTask(
                id: task.id,
                title: task.title,
                isCompleted: task.isCompleted,
                priority: task.aiPriority,
                estimatedMinutes: task.estimatedMinutes,
                scheduledTime: task.scheduledTime,
                starRating: task.starRating
            )
        }

        if let encoded = try? JSONEncoder().encode(widgetTasks) {
            defaults.set(encoded, forKey: tasksKey)
            defaults.set(Date(), forKey: lastUpdateKey)
        }

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Share stats with widget
    func shareStats(
        tasksCompletedToday: Int,
        dailyGoal: Int,
        currentStreak: Int,
        totalPoints: Int,
        currentLevel: Int
    ) {
        guard let defaults = sharedDefaults else { return }

        let stats = WidgetStats(
            tasksCompletedToday: tasksCompletedToday,
            dailyGoal: dailyGoal,
            currentStreak: currentStreak,
            totalPoints: totalPoints,
            currentLevel: currentLevel,
            lastUpdated: Date()
        )

        if let encoded = try? JSONEncoder().encode(stats) {
            defaults.set(encoded, forKey: statsKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Get tasks for widget display
    func getTasks() -> [WidgetTask] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: tasksKey),
              let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) else {
            return []
        }
        return tasks
    }

    /// Get stats for widget display
    func getStats() -> WidgetStats? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: statsKey),
              let stats = try? JSONDecoder().decode(WidgetStats.self, from: data) else {
            return nil
        }
        return stats
    }

    /// Get last update date
    func getLastUpdateDate() -> Date? {
        sharedDefaults?.object(forKey: lastUpdateKey) as? Date
    }

    // MARK: - Widget Reload

    /// Force reload all widgets
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Reload specific widget kind
    func reloadWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    // MARK: - Clear Data

    /// Clear shared data
    func clearSharedData() {
        guard let defaults = sharedDefaults else { return }
        defaults.removeObject(forKey: tasksKey)
        defaults.removeObject(forKey: statsKey)
        defaults.removeObject(forKey: lastUpdateKey)

        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Widget Task Model

struct WidgetTask: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let priority: String?
    let estimatedMinutes: Int?
    let scheduledTime: Date?
    let starRating: Int?

    var priorityColor: String {
        switch priority?.lowercased() {
        case "high": return "red"
        case "medium": return "orange"
        case "low": return "green"
        default: return "gray"
        }
    }

    var starDisplay: String {
        String(repeating: "*", count: starRating ?? 2)
    }
}

// MARK: - Widget Stats Model

struct WidgetStats: Codable, Sendable {
    let tasksCompletedToday: Int
    let dailyGoal: Int
    let currentStreak: Int
    let totalPoints: Int
    let currentLevel: Int
    let lastUpdated: Date

    var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(tasksCompletedToday) / Double(dailyGoal))
    }

    var isGoalMet: Bool {
        tasksCompletedToday >= dailyGoal
    }

    var progressText: String {
        "\(tasksCompletedToday)/\(dailyGoal)"
    }
}

// MARK: - Widget Kind Constants

enum WidgetKind {
    static let tasks = "VeloceTasksWidget"
    static let stats = "VeloceStatsWidget"
    static let streak = "VeloceStreakWidget"
    static let quickAdd = "VeloceQuickAddWidget"
}
