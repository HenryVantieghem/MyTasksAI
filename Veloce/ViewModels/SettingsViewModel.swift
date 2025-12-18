//
//  SettingsViewModel.swift
//  Veloce
//
//  Settings View Model - User Preferences Management
//  Handles app settings, notifications, sync, and account
//

import Foundation
import SwiftData
import Supabase
import Auth

// MARK: - Settings View Model

@MainActor
@Observable
final class SettingsViewModel {
    // MARK: State
    private(set) var isLoading: Bool = false
    var error: String?

    // MARK: User Settings
    var fullName: String = ""
    var email: String = ""
    var dailyTaskGoal: Int = 5
    var weeklyTaskGoal: Int = 25

    // MARK: App Settings
    var notificationsEnabled: Bool = true
    var calendarSyncEnabled: Bool = false
    var hapticsEnabled: Bool = true
    var theme: AppTheme = .auto

    // MARK: AI Settings
    var aiEnabled: Bool = true
    var autoProcessTasks: Bool = true

    // MARK: Services
    private let supabase = SupabaseService.shared
    private let calendar = CalendarService.shared
    private let subscription = SubscriptionService.shared
    private let haptics = HapticsService.shared

    // MARK: Context
    private var modelContext: ModelContext?
    private var user: User?

    // MARK: Initialization
    init() {}

    // MARK: - Setup

    func setup(context: ModelContext, user: User?) {
        self.modelContext = context
        self.user = user

        if let user {
            loadFromUser(user)
        }
    }

    private func loadFromUser(_ user: User) {
        fullName = user.fullName ?? ""
        email = user.email ?? ""
        dailyTaskGoal = user.dailyTaskGoal
        weeklyTaskGoal = user.weeklyTaskGoal
        notificationsEnabled = user.notificationsEnabled
        calendarSyncEnabled = user.calendarSyncEnabled
        hapticsEnabled = user.hapticsEnabled
        theme = AppTheme(rawValue: user.theme) ?? .auto
    }

    // MARK: - Save Settings

    func saveProfile() async {
        guard let user else { return }

        isLoading = true
        defer { isLoading = false }

        user.fullName = fullName
        user.dailyTaskGoal = dailyTaskGoal
        user.weeklyTaskGoal = weeklyTaskGoal

        try? modelContext?.save()

        do {
            try await supabase.updateUser(id: user.id, updates: [
                "full_name": AnyEncodable(fullName),
                "daily_task_goal": AnyEncodable(dailyTaskGoal),
                "weekly_task_goal": AnyEncodable(weeklyTaskGoal)
            ])

            haptics.taskComplete()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveNotificationSettings() async {
        guard let user else { return }

        user.notificationsEnabled = notificationsEnabled

        try? modelContext?.save()

        do {
            try await supabase.updateUser(id: user.id, updates: [
                "notifications_enabled": AnyEncodable(notificationsEnabled)
            ])
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveCalendarSettings() async {
        guard let user else { return }

        // Request calendar access if enabling
        if calendarSyncEnabled && !calendar.isAuthorized {
            let granted = await calendar.requestAccess()
            if !granted {
                calendarSyncEnabled = false
                error = "Calendar access denied. Please enable in Settings."
                return
            }
        }

        user.calendarSyncEnabled = calendarSyncEnabled

        try? modelContext?.save()

        do {
            try await supabase.updateUser(id: user.id, updates: [
                "calendar_sync_enabled": AnyEncodable(calendarSyncEnabled)
            ])
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveHapticsSettings() {
        guard let user else { return }

        user.hapticsEnabled = hapticsEnabled

        try? modelContext?.save()

        // Trigger a haptic if enabling
        if hapticsEnabled {
            haptics.impact()
        }

        Task {
            try? await supabase.updateUser(id: user.id, updates: [
                "haptics_enabled": AnyEncodable(hapticsEnabled)
            ])
        }
    }

    func saveThemeSettings() async {
        guard let user else { return }

        user.theme = theme.rawValue

        try? modelContext?.save()

        do {
            try await supabase.updateUser(id: user.id, updates: [
                "theme": AnyEncodable(theme.rawValue)
            ])
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Subscription

    var isProUser: Bool {
        subscription.isProUser
    }

    func openManageSubscription() {
        subscription.openManageSubscriptions()
    }

    func restorePurchases() async throws {
        try await subscription.restorePurchases()
    }

    // MARK: - Account Actions

    func signOut() async {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            try await client.auth.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteAccount() async throws {
        guard supabase.isConfigured else {
            throw SettingsError.notConfigured
        }

        // Clear local data first
        clearLocalData()

        // Delete account from Supabase (deletes all user data and signs out)
        try await supabase.deleteAccount()
    }

    // MARK: - Data Management

    func exportData() async throws -> Data {
        guard let context = modelContext else {
            throw SettingsError.noContext
        }

        guard let userId = user?.id ?? supabase.currentUserId else {
            throw SettingsError.noContext
        }

        // Fetch all user data
        let tasksDescriptor = FetchDescriptor<TaskItem>()
        let goalsDescriptor = FetchDescriptor<Goal>()
        let achievementsDescriptor = FetchDescriptor<Achievement>()

        let tasks = try context.fetch(tasksDescriptor)
        let goals = try context.fetch(goalsDescriptor)
        let achievements = try context.fetch(achievementsDescriptor)

        // Create export structure
        let export = DataExport(
            exportDate: Date(),
            tasks: tasks.map { $0.toSupabase(userId: userId) },
            goals: goals.map { $0.toSupabase(userId: userId) },
            achievements: achievements.map { $0.toSupabase(userId: userId) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(export)
    }

    func clearLocalData() {
        guard let context = modelContext else { return }

        let tasksDescriptor = FetchDescriptor<TaskItem>()
        let goalsDescriptor = FetchDescriptor<Goal>()

        do {
            let tasks = try context.fetch(tasksDescriptor)
            let goals = try context.fetch(goalsDescriptor)

            for task in tasks {
                context.delete(task)
            }

            for goal in goals {
                context.delete(goal)
            }

            try context.save()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func clearError() {
        error = nil
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case auto = "auto"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .auto: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .auto: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - Data Export

struct DataExport: Codable {
    let exportDate: Date
    let tasks: [SupabaseTask]
    let goals: [SupabaseGoal]
    let achievements: [SupabaseAchievement]
}

// MARK: - Settings Error

enum SettingsError: Error, LocalizedError {
    case noContext
    case saveFailed
    case exportFailed
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .noContext:
            return "Data context not available"
        case .saveFailed:
            return "Failed to save settings"
        case .exportFailed:
            return "Failed to export data"
        case .notConfigured:
            return "Supabase is not configured"
        }
    }
}
