//
//  OnboardingViewModel.swift
//  Veloce
//
//  Onboarding View Model - User Setup Flow
//  Handles onboarding steps and initial configuration
//

import Foundation
import SwiftUI
import UserNotifications

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case goals = 1
    case focusAreas = 2
    case notifications = 3
    case complete = 4

    var title: String {
        switch self {
        case .welcome: return "Welcome to MyTasksAI"
        case .goals: return "Set your goals"
        case .focusAreas: return "What do you focus on?"
        case .notifications: return "Stay on track"
        case .complete: return "You're all set!"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return "Your AI-powered productivity companion"
        case .goals: return "How many tasks do you want to complete?"
        case .focusAreas: return "We'll tailor AI suggestions for you"
        case .notifications: return "Get reminders for your tasks"
        case .complete: return "Start being productive!"
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "sparkles"
        case .goals: return "target"
        case .focusAreas: return "square.grid.2x2"
        case .notifications: return "bell.badge"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Focus Area

enum FocusArea: String, CaseIterable, Identifiable {
    case work = "work"
    case personal = "personal"
    case health = "health"
    case learning = "learning"
    case creative = "creative"
    case finance = "finance"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health & Fitness"
        case .learning: return "Learning"
        case .creative: return "Creative"
        case .finance: return "Finance"
        }
    }

    var icon: String {
        switch self {
        case .work: return "briefcase"
        case .personal: return "house"
        case .health: return "heart"
        case .learning: return "book"
        case .creative: return "paintbrush"
        case .finance: return "dollarsign.circle"
        }
    }

    var color: Color {
        switch self {
        case .work: return Color(red: 0.3, green: 0.5, blue: 1.0)       // Blue
        case .personal: return Color(red: 0.6, green: 0.4, blue: 1.0)   // Purple
        case .health: return Color(red: 1.0, green: 0.4, blue: 0.5)     // Red/Pink
        case .learning: return Color(red: 0.2, green: 0.8, blue: 0.6)   // Green
        case .creative: return Color(red: 1.0, green: 0.6, blue: 0.2)   // Orange
        case .finance: return Color(red: 0.9, green: 0.75, blue: 0.2)   // Gold
        }
    }
}

// MARK: - Onboarding View Model

@MainActor
@Observable
final class OnboardingViewModel {
    // MARK: State
    private(set) var currentStep: OnboardingStep = .welcome
    private(set) var isLoading: Bool = false
    private(set) var error: String?

    // MARK: User Input
    var fullName: String = ""
    var dailyTaskGoal: Int = 5
    var weeklyTaskGoal: Int = 25
    var selectedFocusAreas: Set<FocusArea> = []

    // MARK: Permissions
    var notificationsGranted: Bool = false
    var calendarGranted: Bool = false

    // MARK: Services
    private let supabase = SupabaseService.shared
    private let calendar = CalendarService.shared
    private let haptics = HapticsService.shared

    // MARK: Callbacks
    var onComplete: (() -> Void)?

    // MARK: Computed Properties
    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    var canContinue: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .goals:
            return dailyTaskGoal > 0 && weeklyTaskGoal > 0
        case .focusAreas:
            return !selectedFocusAreas.isEmpty
        case .notifications:
            return true  // Optional step
        case .complete:
            return true
        }
    }

    var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    // MARK: Initialization
    init() {}

    // MARK: - Navigation

    func nextStep() {
        guard canContinue else { return }

        haptics.impact()

        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex < allSteps.count - 1 else {
            return
        }

        currentStep = allSteps[currentIndex + 1]

        // Handle step entry
        switch currentStep {
        case .complete:
            Task {
                await performOnboardingCompletion()
            }
        default:
            break
        }
    }

    func previousStep() {
        haptics.selectionFeedback()

        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }

        currentStep = allSteps[currentIndex - 1]
    }

    func goToStep(_ step: OnboardingStep) {
        currentStep = step
        haptics.selectionFeedback()
    }

    func skip() {
        nextStep()
    }

    // MARK: - Focus Areas

    func toggleFocusArea(_ area: FocusArea) {
        if selectedFocusAreas.contains(area) {
            selectedFocusAreas.remove(area)
        } else {
            selectedFocusAreas.insert(area)
        }
        haptics.selectionFeedback()
    }

    // MARK: - Goals

    func incrementDailyGoal() {
        dailyTaskGoal = min(dailyTaskGoal + 1, 20)
        haptics.selectionFeedback()
    }

    func decrementDailyGoal() {
        dailyTaskGoal = max(dailyTaskGoal - 1, 1)
        haptics.selectionFeedback()
    }

    func incrementWeeklyGoal() {
        weeklyTaskGoal = min(weeklyTaskGoal + 5, 100)
        haptics.selectionFeedback()
    }

    func decrementWeeklyGoal() {
        weeklyTaskGoal = max(weeklyTaskGoal - 5, 5)
        haptics.selectionFeedback()
    }

    // MARK: - Permissions

    func requestNotifications() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            notificationsGranted = granted
        } catch {
            notificationsGranted = false
        }

        haptics.impact()
    }

    func requestCalendar() async {
        calendarGranted = await calendar.requestAccess()
        haptics.impact()
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() {
        Task {
            await performOnboardingCompletion()
        }
    }

    private func performOnboardingCompletion() async {
        isLoading = true
        defer { isLoading = false }

        guard let userId = await supabase.getCurrentUserId() else {
            error = "Not authenticated"
            return
        }

        do {
            // Update user profile
            try await supabase.updateUser(id: userId, updates: [
                "full_name": AnyEncodable(fullName.trimmingCharacters(in: .whitespaces)),
                "daily_task_goal": AnyEncodable(dailyTaskGoal),
                "weekly_task_goal": AnyEncodable(weeklyTaskGoal),
                "notifications_enabled": AnyEncodable(notificationsGranted),
                "calendar_sync_enabled": AnyEncodable(calendarGranted)
            ])

            haptics.celebration()
            onComplete?()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func clearError() {
        error = nil
    }
}
