//
//  JourneyOnboardingViewModel.swift
//  MyTasksAI
//
//  Journey Through the Cosmos - Onboarding ViewModel
//  State management for the 5-step premium onboarding experience
//

import SwiftUI
import Observation
import UserNotifications

// MARK: - Onboarding Realm

enum OnboardingRealm: Int, CaseIterable, Identifiable {
    case welcome = 0
    case missionControl = 1
    case goalSetting = 2
    case powers = 3
    case launch = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .missionControl: return "Features"
        case .goalSetting: return "Goals"
        case .powers: return "Powers"
        case .launch: return "Launch"
        }
    }
}

// MARK: - Journey Onboarding ViewModel

@MainActor
@Observable
final class JourneyOnboardingViewModel {

    // MARK: - Navigation State

    var currentRealm: OnboardingRealm = .welcome
    var isTransitioning: Bool = false

    // MARK: - User Data (from sign up)

    var userName: String = ""
    var userFirstName: String {
        let components = userName.components(separatedBy: " ")
        return components.first ?? "Explorer"
    }

    // MARK: - Goal Settings (Step 3)

    var dailyTaskGoal: Int = 5
    var weeklyTaskGoal: Int = 25

    static let dailyGoalOptions = [3, 5, 7, 10]
    static let weeklyGoalOptions = [15, 25, 35, 50]

    // MARK: - Permission States (Step 4)

    var notificationsRequested: Bool = false
    var notificationsGranted: Bool = false
    var calendarRequested: Bool = false
    var calendarGranted: Bool = false

    // MARK: - Animation States

    var showContent: Bool = false
    var orbIntensity: Double = 1.0

    // MARK: - Completion Handler

    var onComplete: (() -> Void)?

    // MARK: - Initialization

    init() {
        Task {
            await loadUserName()
        }
    }

    // MARK: - Navigation

    func nextRealm() {
        guard let nextIndex = OnboardingRealm(rawValue: currentRealm.rawValue + 1) else {
            return
        }

        isTransitioning = true
        HapticsService.shared.selectionFeedback()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            currentRealm = nextIndex
        }

        // Reset transition flag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isTransitioning = false
        }
    }

    func previousRealm() {
        guard let prevIndex = OnboardingRealm(rawValue: currentRealm.rawValue - 1) else {
            return
        }

        isTransitioning = true
        HapticsService.shared.selectionFeedback()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            currentRealm = prevIndex
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isTransitioning = false
        }
    }

    func goToRealm(_ realm: OnboardingRealm) {
        guard realm.rawValue <= currentRealm.rawValue else { return } // Can only go back

        isTransitioning = true
        HapticsService.shared.selectionFeedback()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            currentRealm = realm
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isTransitioning = false
        }
    }

    var canGoBack: Bool {
        currentRealm.rawValue > 0
    }

    var canSkip: Bool {
        currentRealm != .launch
    }

    var progress: Double {
        Double(currentRealm.rawValue) / Double(OnboardingRealm.allCases.count - 1)
    }

    // MARK: - Goal Selection

    func selectDailyGoal(_ goal: Int) {
        HapticsService.shared.selectionFeedback()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            dailyTaskGoal = goal
            // Pulse orb based on goal magnitude
            orbIntensity = 1.0 + (Double(goal) / 30.0) * 0.3
        }

        // Reset orb intensity
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.orbIntensity = 1.0
            }
        }
    }

    func selectWeeklyGoal(_ goal: Int) {
        HapticsService.shared.selectionFeedback()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            weeklyTaskGoal = goal
            orbIntensity = 1.0 + (Double(goal) / 100.0) * 0.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.orbIntensity = 1.0
            }
        }
    }

    // MARK: - Permissions

    func requestNotifications() async {
        notificationsRequested = true
        // Request notification permission
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                notificationsGranted = granted
                HapticsService.shared.selectionFeedback()
            }
        } catch {
            await MainActor.run {
                notificationsGranted = false
            }
        }
    }

    func skipNotifications() {
        notificationsRequested = true
        notificationsGranted = false
        HapticsService.shared.selectionFeedback()
    }

    func requestCalendar() async {
        calendarRequested = true
        // Request calendar permission
        let eventStore = EKEventStore()
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                calendarGranted = granted
                HapticsService.shared.selectionFeedback()
            }
        } catch {
            await MainActor.run {
                calendarGranted = false
            }
        }
    }

    func skipCalendar() {
        calendarRequested = true
        calendarGranted = false
        HapticsService.shared.selectionFeedback()
    }

    var permissionsComplete: Bool {
        notificationsRequested && calendarRequested
    }

    // MARK: - Completion

    func completeOnboarding() {
        HapticsService.shared.celebration()

        Task {
            await saveGoals()
            saveOnboardingComplete()
            onComplete?()
        }
    }

    private func saveGoals() async {
        // Save locally first
        UserDefaults.standard.set(dailyTaskGoal, forKey: "dailyTaskGoal")
        UserDefaults.standard.set(weeklyTaskGoal, forKey: "weeklyTaskGoal")

        // Then save to Supabase
        if let userId = await SupabaseService.shared.getCurrentUserId() {
            try? await SupabaseService.shared.updateUser(id: userId, updates: [
                "daily_task_goal": AnyEncodable(dailyTaskGoal),
                "weekly_task_goal": AnyEncodable(weeklyTaskGoal)
            ])
        }
    }

    private func saveOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "journey_onboarding_completed")
        UserDefaults.standard.set(Date(), forKey: "onboarding_completed_date")
    }

    // MARK: - Data Loading

    private func loadUserName() async {
        if let userId = await SupabaseService.shared.getCurrentUserId() {
            if let user = try? await SupabaseService.shared.fetchUser(id: userId) {
                await MainActor.run {
                    userName = user.fullName ?? "Explorer"
                }
            }
        }
    }

    // MARK: - Summary Data

    var goalSummary: String {
        "\(dailyTaskGoal) tasks/day • \(weeklyTaskGoal) tasks/week"
    }

    var permissionsSummary: [String] {
        var summary: [String] = []
        if notificationsGranted {
            summary.append("Notifications enabled")
        }
        if calendarGranted {
            summary.append("Calendar synced")
        }
        return summary
    }
}

// MARK: - EKEventStore Extension

import EventKit

extension EKEventStore {
    func requestFullAccessToEvents() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            if #available(iOS 17.0, *) {
                requestFullAccessToEvents { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            } else {
                requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
}
