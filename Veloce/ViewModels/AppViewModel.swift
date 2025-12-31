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
import Combine
import UIKit

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
    private let syncEngine = SyncEngine.shared
    private let localStore = LocalDataStore.shared
    private let offlineManager = OfflineManager.shared
    private let ai = AIService.shared
    private let haptics = HapticsService.shared
    private let subscription = SubscriptionService.shared

    // MARK: Context
    private var modelContext: ModelContext?

    // MARK: Scene Phase Tracking
    private var cancellables = Set<AnyCancellable>()

    // MARK: Initialization
    init() {
        setupTrialExpirationHandler()
        setupScenePhaseObserver()
    }

    /// Setup handler for when trial expires while app is in use
    private func setupTrialExpirationHandler() {
        subscription.onTrialExpired = { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }

                // Only show paywall if user was authenticated and not subscribed
                if self.appState == .authenticated && !self.subscription.isSubscribed {
                    #if DEBUG
                    print("🔵 [AppViewModel] Trial expired while in app → .paywall")
                    #endif
                    self.haptics.warning()
                    self.appState = .paywall
                }
            }
        }
    }

    /// Setup observer for app going to foreground
    private func setupScenePhaseObserver() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAppForeground()
                }
            }
            .store(in: &cancellables)
    }

    /// Called when app comes to foreground
    private func handleAppForeground() async {
        // Re-check subscription/trial status when app becomes active
        await subscription.checkSubscriptionStatus()

        // If trial expired and not subscribed, show paywall
        if appState == .authenticated && subscription.shouldShowPaywall {
            #if DEBUG
            print("🔵 [AppViewModel] App foreground - trial expired → .paywall")
            #endif
            haptics.warning()
            appState = .paywall
        }
    }

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

        // Initialize local-first data store and sync engine
        if let context = modelContext {
            localStore.initialize(context: context)
            syncEngine.initialize(context: context)
        }

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

            // Stop trial timer when not authenticated
            subscription.stopTrialExpirationTimer()

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

                // Start trial when user first authenticates (even before completing onboarding)
                await startTrialIfNeeded()

                appState = .onboarding
                return
            }

            // Load or create local user
            await loadOrCreateLocalUser(from: supabaseUser)

            // Load trial info from server (handles reinstall scenarios)
            await subscription.loadTrialFromSupabase()

            // Start trial if this is user's first time (trial not yet started)
            await startTrialIfNeeded()

            // Check subscription status
            await subscription.checkSubscriptionStatus()

            #if DEBUG
            print("🔵 [AppViewModel] Subscription check complete")
            print("🔵 [AppViewModel] - isSubscribed: \(subscription.isSubscribed)")
            print("🔵 [AppViewModel] - isInTrial: \(subscription.isInTrial)")
            print("🔵 [AppViewModel] - trialExpired: \(subscription.trialExpired)")
            print("🔵 [AppViewModel] - shouldShowPaywall: \(subscription.shouldShowPaywall)")
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

            // Start trial expiration timer
            subscription.startTrialExpirationTimer()

            // Start background sync with new sync engine
            Task {
                await syncEngine.performFullSync()
            }
        } catch {
            #if DEBUG
            print("🔵 [AppViewModel] Error fetching profile: \(error) → .onboarding")
            #endif

            // Start trial even if profile fetch failed
            await startTrialIfNeeded()

            // User authenticated but no profile - needs onboarding
            appState = .onboarding
        }
    }

    /// Start the free trial if user hasn't started one yet
    private func startTrialIfNeeded() async {
        // Only start trial if it hasn't been started yet
        if subscription.canStartFreeTrial {
            #if DEBUG
            print("🔵 [AppViewModel] Starting free trial for new user")
            #endif
            subscription.startFreeTrial()
        } else {
            #if DEBUG
            print("🔵 [AppViewModel] Trial already started or expired")
            #endif
            // Just refresh the trial status
            await subscription.checkSubscriptionStatus()
        }
    }

    /// Handle subscription completed - transition to authenticated
    func handleSubscriptionCompleted() {
        #if DEBUG
        print("🔵 [AppViewModel] handleSubscriptionCompleted() → .authenticated")
        #endif
        haptics.success()

        // Stop trial timer since user is now subscribed
        subscription.stopTrialExpirationTimer()

        appState = .authenticated
    }

    /// Force check subscription status and enforce paywall if needed
    /// Call this periodically or when app becomes active
    func enforceSubscriptionCheck() async {
        // Only check if user is authenticated
        guard appState == .authenticated else { return }

        await subscription.checkSubscriptionStatus()

        if subscription.shouldShowPaywall {
            #if DEBUG
            print("🔵 [AppViewModel] enforceSubscriptionCheck() - Trial expired → .paywall")
            #endif
            haptics.warning()
            appState = .paywall
        }
    }

    /// Check if user can access the app (not locked out by paywall)
    var canAccessApp: Bool {
        appState == .authenticated || appState == .onboarding
    }

    // MARK: - Trial Status (for UI display)

    /// Get trial days remaining (for UI display)
    var trialDaysRemaining: Int {
        subscription.trialDaysRemaining
    }

    /// Get trial hours remaining (for UI display)
    var trialHoursRemaining: Int {
        subscription.trialHoursRemaining
    }

    /// Check if user is currently in trial
    var isInTrial: Bool {
        subscription.isInTrial
    }

    /// Check if trial has expired
    var trialExpired: Bool {
        subscription.trialExpired
    }

    /// Get trial end date
    var trialEndDate: Date? {
        subscription.trialEndDate
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
        // Stop trial timer
        subscription.stopTrialExpirationTimer()

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

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        guard supabase.isConfigured else {
            throw NSError(domain: "AppViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase not configured"])
        }

        let client = try supabase.getClient()
        _ = try await client.auth.signIn(email: email, password: password)
        await checkAuthenticationState()
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
