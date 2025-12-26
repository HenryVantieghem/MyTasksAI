//
//  CosmicOnboardingViewModel.swift
//  Veloce
//
//  Cosmic Onboarding View Model
//  Manages state for the 11-step celestial onboarding journey
//

import SwiftUI
import EventKit
import UserNotifications
import FamilyControls

// MARK: - Onboarding Goal Category

enum OnboardingGoalCategory: String, CaseIterable, Identifiable {
    case career = "Career"
    case health = "Health"
    case learning = "Learning"
    case creative = "Creative"
    case financial = "Financial"
    case personal = "Personal"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .career: return "briefcase.fill"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .creative: return "paintbrush.fill"
        case .financial: return "dollarsign.circle.fill"
        case .personal: return "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .career: return Theme.Colors.aiPurple
        case .health: return Theme.CelestialColors.auroraGreen
        case .learning: return Theme.Colors.aiBlue
        case .creative: return Theme.CelestialColors.solarFlare
        case .financial: return Theme.Colors.xp
        case .personal: return Theme.CelestialColors.plasmaCore
        }
    }
}

// MARK: - Goal Duration

enum GoalDuration: String, CaseIterable, Identifiable {
    case oneMonth = "1 Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case oneYear = "1 Year"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        }
    }

    var shortLabel: String {
        switch self {
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        }
    }
}

// MARK: - Cosmic Onboarding View Model

@MainActor
@Observable
final class CosmicOnboardingViewModel {

    // MARK: - Permission States
    var calendarGranted: Bool = false
    var notificationsGranted: Bool = false
    var screenTimeGranted: Bool = false

    // MARK: - Goal Setup
    var selectedCategory: OnboardingGoalCategory?
    var goalDescription: String = ""
    var selectedDuration: GoalDuration = .threeMonths
    var aiEnhancedGoal: String?
    var generatedActionItems: [String] = []
    var isEnhancingGoal: Bool = false

    // MARK: - User Info
    var userName: String = ""

    // MARK: - Daily/Weekly Goals (from existing system)
    var dailyTaskGoal: Int = 5
    var weeklyTaskGoal: Int = 25

    // MARK: - Completion Handler
    var onComplete: (() -> Void)?

    // MARK: - Services
    private let eventStore = EKEventStore()

    // MARK: - Computed Properties

    var goalSummary: String {
        if let category = selectedCategory, !goalDescription.isEmpty {
            return "\(category.rawValue): \(goalDescription)"
        } else if let category = selectedCategory {
            return "Focus on \(category.rawValue.lowercased())"
        }
        return "Start your productivity journey"
    }

    var canProceedFromGoal: Bool {
        selectedCategory != nil
    }

    // MARK: - Initialization

    init() {
        loadUserName()
        checkExistingPermissions()
    }

    private func loadUserName() {
        Task {
            if let userId = await SupabaseService.shared.getCurrentUserId() {
                do {
                    let user = try await SupabaseService.shared.fetchUser(id: userId)
                    userName = user.fullName ?? ""
                } catch {
                    print("Failed to load user name: \(error)")
                }
            }
        }
    }

    private func checkExistingPermissions() {
        // Check calendar
        let calendarStatus = EKEventStore.authorizationStatus(for: .event)
        calendarGranted = calendarStatus == .fullAccess

        // Check notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.notificationsGranted = settings.authorizationStatus == .authorized
            }
        }

        // Check screen time (FamilyControls)
        let center = AuthorizationCenter.shared
        screenTimeGranted = center.authorizationStatus == .approved
    }

    // MARK: - Permission Requests

    func requestCalendarPermission() async {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                calendarGranted = granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                calendarGranted = granted
            }

            if calendarGranted {
                HapticsService.shared.success()
            }
        } catch {
            print("Calendar permission error: \(error)")
            calendarGranted = false
        }
    }

    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            notificationsGranted = granted

            if granted {
                HapticsService.shared.success()
            }
        } catch {
            print("Notification permission error: \(error)")
            notificationsGranted = false
        }
    }

    func requestScreenTimePermission() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            screenTimeGranted = AuthorizationCenter.shared.authorizationStatus == .approved

            if screenTimeGranted {
                HapticsService.shared.success()
            }
        } catch {
            print("Screen Time permission error: \(error)")
            screenTimeGranted = false
        }
    }

    // MARK: - Goal Enhancement

    func enhanceGoalWithAI() async {
        guard !goalDescription.isEmpty, let category = selectedCategory else { return }

        isEnhancingGoal = true

        // Simulate AI enhancement (in production, call AIService)
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Generate SMART goal
        let smartGoal = generateSMARTGoal(from: goalDescription, category: category)
        aiEnhancedGoal = smartGoal

        // Generate action items
        generatedActionItems = generateActionItems(for: category, goal: goalDescription)

        isEnhancingGoal = false
        HapticsService.shared.success()
    }

    private func generateSMARTGoal(from description: String, category: OnboardingGoalCategory) -> String {
        // In production, this would use AIService
        let timeframe = selectedDuration.rawValue.lowercased()

        switch category {
        case .career:
            return "Within \(timeframe), I will \(description.lowercased()) by dedicating focused time each day and tracking my progress weekly."
        case .health:
            return "Over the next \(timeframe), I will achieve \(description.lowercased()) through consistent daily habits and measurable milestones."
        case .learning:
            return "In the next \(timeframe), I will master \(description.lowercased()) by completing structured learning sessions and practical projects."
        case .creative:
            return "Within \(timeframe), I will complete \(description.lowercased()) by setting weekly creative goals and sharing my progress."
        case .financial:
            return "Over \(timeframe), I will accomplish \(description.lowercased()) by creating actionable steps and reviewing progress monthly."
        case .personal:
            return "In the next \(timeframe), I will \(description.lowercased()) through intentional daily actions and reflection."
        }
    }

    private func generateActionItems(for category: OnboardingGoalCategory, goal: String) -> [String] {
        // In production, this would use AIService
        switch category {
        case .career:
            return [
                "Schedule 1 hour daily for focused work",
                "Set up weekly progress reviews",
                "Connect with mentors in your field"
            ]
        case .health:
            return [
                "Start with 15-minute daily sessions",
                "Track your metrics weekly",
                "Build a support system"
            ]
        case .learning:
            return [
                "Create a structured learning schedule",
                "Practice actively, not just passively",
                "Test your knowledge regularly"
            ]
        case .creative:
            return [
                "Set aside dedicated creative time",
                "Start small and iterate",
                "Share your work for feedback"
            ]
        case .financial:
            return [
                "Track all expenses for one week",
                "Set up automatic savings",
                "Review progress monthly"
            ]
        case .personal:
            return [
                "Define what success looks like",
                "Build daily micro-habits",
                "Reflect on progress weekly"
            ]
        }
    }

    // MARK: - Completion

    func completeOnboarding() {
        // Save goal to Supabase/local storage
        saveGoal()

        // Mark onboarding complete
        saveOnboardingComplete()

        // Trigger completion callback
        onComplete?()
    }

    private func saveGoal() {
        guard selectedCategory != nil else { return }

        Task {
            if let userId = await SupabaseService.shared.getCurrentUserId() {
                // Update user with daily/weekly goals
                try? await SupabaseService.shared.updateUser(id: userId, updates: [
                    "daily_task_goal": AnyEncodable(dailyTaskGoal),
                    "weekly_task_goal": AnyEncodable(weeklyTaskGoal)
                ])

                // In production, you'd also save the goal itself
            }
        }
    }

    private func saveOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "cosmic_onboarding_completed")
        UserDefaults.standard.set(Date(), forKey: "onboarding_completed_date")
    }
}
