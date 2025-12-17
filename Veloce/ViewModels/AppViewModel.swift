//
//  AppViewModel.swift
//  Veloce
//
//  App View Model - Main Application State
//  Coordinates app-wide state and navigation
//

import Foundation
import SwiftData
import Supabase
import Auth

// MARK: - App State

enum AppState: Equatable {
    case loading
    case unauthenticated
    case onboarding
    case authenticated
}

// MARK: - App View Model

@MainActor
@Observable
final class AppViewModel {
    // MARK: State
    private(set) var appState: AppState = .loading
    private(set) var currentUser: User?
    private(set) var isInitialized: Bool = false
    private(set) var error: String?

    // MARK: Services
    private let supabase = SupabaseService.shared
    private let gamification = GamificationService.shared
    private let sync = SyncService.shared
    private let ai = AIService.shared
    private let haptics = HapticsService.shared

    // MARK: Context
    private var modelContext: ModelContext?

    // MARK: Initialization
    init() {}

    // MARK: - Setup

    /// Initialize the app with model context
    func initialize(context: ModelContext) async {
        modelContext = context

        // Configure services
        configureServices()

        // Check authentication state
        await checkAuthenticationState()

        isInitialized = true
    }

    /// Configure all services
    private func configureServices() {
        // Configure Supabase
        supabase.configure()

        // Configure AI service
        ai.loadConfiguration()

        // Configure subscription service
        SubscriptionService.shared.configure()
    }

    // MARK: - Authentication

    /// Check current authentication state
    func checkAuthenticationState() async {
        appState = .loading

        guard let userId = await supabase.getCurrentUserId() else {
            appState = .unauthenticated
            return
        }

        // Fetch user profile
        do {
            let supabaseUser = try await supabase.fetchUser(id: userId)

            // Check if user needs onboarding
            if supabaseUser.fullName == nil || supabaseUser.fullName?.isEmpty == true {
                appState = .onboarding
                return
            }

            // Load or create local user
            await loadOrCreateLocalUser(from: supabaseUser)

            appState = .authenticated

            // Start background sync
            if let context = modelContext {
                Task {
                    await sync.performFullSync(context: context)
                }
            }
        } catch {
            // User authenticated but no profile - needs onboarding
            appState = .onboarding
        }
    }

    /// Load or create local user from Supabase user
    private func loadOrCreateLocalUser(from supabaseUser: SupabaseUser) async {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == supabaseUser.id }
        )

        do {
            let existingUsers = try context.fetch(descriptor)

            if let existingUser = existingUsers.first {
                currentUser = existingUser
                gamification.load(from: existingUser)
            } else {
                // Create new local user
                let newUser = User(from: supabaseUser)
                context.insert(newUser)
                try context.save()
                currentUser = newUser
                gamification.load(from: newUser)
            }
        } catch {
            print("Failed to load user: \(error)")
        }
    }

    // MARK: - State Transitions

    /// Complete onboarding
    func completeOnboarding(name: String, dailyGoal: Int = 5) async {
        guard let userId = await supabase.getCurrentUserId(),
              let _ = modelContext else { return }

        do {
            // Update remote profile
            try await supabase.updateUser(id: userId, updates: [
                "full_name": AnyEncodable(name),
                "daily_task_goal": AnyEncodable(dailyGoal)
            ])

            // Fetch updated user
            let updatedUser = try await supabase.fetchUser(id: userId)
            await loadOrCreateLocalUser(from: updatedUser)

            appState = .authenticated
            haptics.taskComplete()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Sign out
    func signOut() async {
        do {
            try await supabase.supabase.auth.signOut()
            currentUser = nil
            appState = .unauthenticated
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - User Updates

    /// Update user profile
    func updateUserProfile(
        name: String? = nil,
        dailyGoal: Int? = nil,
        weeklyGoal: Int? = nil
    ) async {
        guard let user = currentUser else { return }

        var updates: [String: AnyEncodable] = [:]

        if let name {
            user.fullName = name
            updates["full_name"] = AnyEncodable(name)
        }

        if let dailyGoal {
            user.dailyTaskGoal = dailyGoal
            updates["daily_task_goal"] = AnyEncodable(dailyGoal)
        }

        if let weeklyGoal {
            user.weeklyTaskGoal = weeklyGoal
            updates["weekly_task_goal"] = AnyEncodable(weeklyGoal)
        }

        // Save locally
        try? modelContext?.save()

        // Sync to remote
        if !updates.isEmpty {
            try? await supabase.updateUser(id: user.id, updates: updates)
        }
    }

    /// Save gamification updates
    func saveGamificationUpdates() async {
        guard var user = currentUser else { return }

        gamification.updateUser(&user)

        try? modelContext?.save()

        // Sync to remote
        try? await supabase.upsertUser(user.toSupabase())
    }

    // MARK: - Daily Reset

    /// Check and perform daily reset
    func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActive = currentUser?.lastActiveDate,
           !calendar.isDate(lastActive, inSameDayAs: today) {
            // New day - reset daily stats
            gamification.resetDaily()
        }

        // Update last active
        currentUser?.lastActiveDate = Date()
        try? modelContext?.save()
    }

    // MARK: - Error Handling

    /// Clear error
    func clearError() {
        error = nil
    }
}
