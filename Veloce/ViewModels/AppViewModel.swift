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
    case freeTrialWelcome  // First screen for new users
    case unauthenticated
    case onboarding
    case paywall  // Show after trial expires
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

    /// Track if user prefers Sign Up or Sign In (set by FreeTrialWelcomeView)
    var preferSignUp: Bool = true

    // MARK: UserDefaults Keys
    private let hasSeenWelcomeKey = "mytasksai_has_seen_welcome"

    /// Whether user has seen the welcome screen
    var hasSeenWelcome: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenWelcomeKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenWelcomeKey) }
    }

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
        Task {
            await SubscriptionService.shared.configure()
        }
    }

    // MARK: - Authentication

    /// Check current authentication state
    func checkAuthenticationState() async {
        #if DEBUG
        print("🔵 [AppViewModel] checkAuthenticationState() called")
        #endif

        appState = .loading

        guard let userId = await supabase.getCurrentUserId() else {
            #if DEBUG
            print("🔵 [AppViewModel] No user ID found")
            #endif

            // Check if user has seen the welcome screen
            if !hasSeenWelcome {
                #if DEBUG
                print("🔵 [AppViewModel] First time user → .freeTrialWelcome")
                #endif
                appState = .freeTrialWelcome
            } else {
                #if DEBUG
                print("🔵 [AppViewModel] Returning user → .unauthenticated")
                #endif
                appState = .unauthenticated
            }
            return
        }

        #if DEBUG
        print("🔵 [AppViewModel] User ID: \(userId)")
        #endif

        // Fetch user profile
        do {
            let supabaseUser = try await supabase.fetchUser(id: userId)

            #if DEBUG
            print("🔵 [AppViewModel] Fetched user - dailyTaskGoal: \(supabaseUser.dailyTaskGoal ?? 0)")
            #endif

            // Check if user needs onboarding (check if goals are set, meaning they completed onboarding)
            if supabaseUser.dailyTaskGoal == nil || supabaseUser.dailyTaskGoal == 0 {
                #if DEBUG
                print("🔵 [AppViewModel] No daily goal set → .onboarding")
                #endif
                appState = .onboarding
                return
            }

            // Load or create local user
            await loadOrCreateLocalUser(from: supabaseUser)

            // Check subscription status
            let subscription = SubscriptionService.shared
            await subscription.checkSubscriptionStatus()

            #if DEBUG
            print("🔵 [AppViewModel] Subscription check complete - shouldShowPaywall: \(subscription.shouldShowPaywall)")
            #endif

            // If trial expired and not subscribed, show paywall
            if subscription.shouldShowPaywall {
                #if DEBUG
                print("🔵 [AppViewModel] Showing paywall → .paywall")
                #endif
                appState = .paywall
                return
            }

            #if DEBUG
            print("🔵 [AppViewModel] User has access → .authenticated")
            #endif
            appState = .authenticated

            // Start background sync
            if let context = modelContext {
                Task {
                    await sync.performFullSync(context: context)
                }
            }
        } catch {
            #if DEBUG
            print("🔵 [AppViewModel] Error fetching profile: \(error) → .onboarding")
            #endif
            // User authenticated but no profile - needs onboarding
            appState = .onboarding
        }
    }

    /// Handle subscription completed - transition to authenticated
    func handleSubscriptionCompleted() {
        #if DEBUG
        print("🔵 [AppViewModel] handleSubscriptionCompleted() → .authenticated")
        #endif
        appState = .authenticated
    }

    /// Handle user continuing from Free Trial welcome screen
    /// - Parameter toSignUp: If true, user tapped "Start Free Trial" (go to Sign Up). If false, user tapped "Sign In"
    func handleWelcomeContinue(toSignUp: Bool) {
        #if DEBUG
        print("🔵 [AppViewModel] handleWelcomeContinue(toSignUp: \(toSignUp))")
        #endif

        hasSeenWelcome = true
        preferSignUp = toSignUp
        appState = .unauthenticated
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
        guard supabase.isConfigured else {
            currentUser = nil
            appState = .unauthenticated
            return
        }

        do {
            let client = try supabase.getClient()
            try await client.auth.signOut()
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
