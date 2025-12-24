//
//  DailyBriefService.swift
//  Veloce
//
//  Daily Brief Service - Generates morning productivity summary
//  Provides one-tap schedule acceptance for the day
//

import Foundation
import SwiftData
import UserNotifications

// MARK: - Daily Brief Service

@MainActor
@Observable
final class DailyBriefService {
    // MARK: Singleton
    static let shared = DailyBriefService()

    // MARK: State
    private(set) var todaysBrief: DailyBrief?
    private(set) var isLoading = false

    // MARK: Dependencies
    private var modelContext: ModelContext?
    private let patternService = PatternLearningService.shared
    private let schedulingService = AISchedulingService.shared

    // MARK: Settings
    var briefTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date()
    var isEnabled = true

    // MARK: Initialization
    private init() {}

    // MARK: - Setup

    func setup(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Generate Brief

    /// Generate today's daily brief
    func generateBrief(tasks: [TaskItem], user: User) async -> DailyBrief {
        isLoading = true
        defer { isLoading = false }

        let today = Date()
        let calendar = Calendar.current

        // Filter tasks for today
        let todaysTasks = tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: today) && !task.isCompleted
        }

        // Get unscheduled priority tasks
        let unscheduledTasks = tasks.filter { task in
            task.scheduledTime == nil && !task.isCompleted
        }.sorted { $0.starRating > $1.starRating }

        // Calculate velocity score
        let velocityScore = calculateVelocityScore(user: user, tasks: tasks)

        // Get AI scheduling suggestions for unscheduled tasks
        let suggestedSchedule = await generateSuggestedSchedule(
            unscheduledTasks: Array(unscheduledTasks.prefix(5)),
            existingTasks: todaysTasks
        )

        // Get personalized insight
        let insight = patternService.getPersonalizedInsight() ?? "Have a productive day!"

        // Build the brief
        let brief = DailyBrief(
            date: today,
            greeting: generateGreeting(for: user),
            velocityScore: velocityScore,
            scheduledTasksCount: todaysTasks.count,
            priorityTasks: Array(todaysTasks.sorted { $0.starRating > $1.starRating }.prefix(3)),
            suggestedSchedule: suggestedSchedule,
            insight: insight,
            streakStatus: getStreakStatus(user: user),
            focusSuggestion: getFocusSuggestion()
        )

        todaysBrief = brief
        return brief
    }

    // MARK: - Accept Schedule

    /// Accept all suggested schedules
    func acceptSuggestedSchedule() async throws {
        guard let brief = todaysBrief else { return }

        for suggestion in brief.suggestedSchedule {
            // Update task with suggested time
            if let task = suggestion.task {
                task.scheduledTime = suggestion.suggestedTime
                task.estimatedMinutes = suggestion.durationMinutes
            }
        }

        // Save changes
        try modelContext?.save()

        // Record feedback for pattern learning
        patternService.recordSuggestionFeedback(
            suggestionType: PatternLearningService.SuggestionType.schedule.rawValue,
            accepted: true
        )
    }

    // MARK: - Notifications

    /// Schedule morning brief notification
    func scheduleBriefNotification() async {
        guard isEnabled else { return }

        let center = UNUserNotificationCenter.current()

        // Request permission
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return }
        } catch {
            print("Notification permission error: \(error)")
            return
        }

        // Remove existing brief notifications
        center.removePendingNotificationRequests(withIdentifiers: ["daily-brief"])

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Your daily brief is ready. Tap to plan your day."
        content.sound = .default
        content.categoryIdentifier = "DAILY_BRIEF"

        // Schedule for brief time
        let components = Calendar.current.dateComponents([.hour, .minute], from: briefTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-brief",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Private Helpers

    private func generateGreeting(for user: User) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = user.firstName

        switch hour {
        case 5..<12:
            return "Good morning, \(name)"
        case 12..<17:
            return "Good afternoon, \(name)"
        case 17..<21:
            return "Good evening, \(name)"
        default:
            return "Hello, \(name)"
        }
    }

    private func calculateVelocityScore(user: User, tasks: [TaskItem]) -> Int {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()

        let tasksThisWeek = tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= weekStart && task.isCompleted
        }.count

        // Estimate focus minutes (would come from focus session tracking)
        let focusMinutes = 120 // Placeholder

        let score = VelocityScore.calculate(
            user: user,
            tasksThisWeek: tasksThisWeek,
            focusMinutesThisWeek: focusMinutes
        )

        return score.total
    }

    private func generateSuggestedSchedule(
        unscheduledTasks: [TaskItem],
        existingTasks: [TaskItem]
    ) async -> [DailyScheduleSuggestion] {
        var suggestions: [DailyScheduleSuggestion] = []
        let calendar = Calendar.current
        let today = Date()

        // Find available time slots
        var currentTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
        let endOfDay = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today

        // Get occupied slots
        let occupiedSlots = existingTasks.compactMap { task -> DateInterval? in
            guard let start = task.scheduledTime else { return nil }
            let duration = TimeInterval((task.estimatedMinutes ?? 30) * 60)
            return DateInterval(start: start, duration: duration)
        }

        for task in unscheduledTasks {
            // Find next available slot
            var foundSlot = false
            while currentTime < endOfDay && !foundSlot {
                let duration = TimeInterval((task.estimatedMinutes ?? 30) * 60)
                let proposedEnd = currentTime.addingTimeInterval(duration)

                // Check if slot is available
                let proposedSlot = DateInterval(start: currentTime, duration: duration)
                let isOccupied = occupiedSlots.contains { $0.intersects(proposedSlot) }

                // Skip lunch hour
                let hour = calendar.component(.hour, from: currentTime)
                let isLunch = hour == 12

                if !isOccupied && !isLunch {
                    let suggestion = DailyScheduleSuggestion(
                        task: task,
                        suggestedTime: currentTime,
                        durationMinutes: task.estimatedMinutes ?? 30,
                        confidence: calculateSuggestionConfidence(for: task, at: currentTime),
                        reason: generateSuggestionReason(for: task, at: currentTime)
                    )
                    suggestions.append(suggestion)
                    currentTime = proposedEnd.addingTimeInterval(15 * 60) // 15 min buffer
                    foundSlot = true
                } else {
                    currentTime = currentTime.addingTimeInterval(30 * 60)
                }
            }
        }

        return suggestions
    }

    private func calculateSuggestionConfidence(for task: TaskItem, at time: Date) -> Double {
        var confidence = 0.7
        let hour = Calendar.current.component(.hour, from: time)

        // Higher confidence for high priority in morning
        if task.starRating >= 3 && hour < 12 {
            confidence += 0.15
        }

        // Use pattern learning
        let multiplier = patternService.getSuggestionConfidenceMultiplier(for: "schedule")
        confidence *= multiplier

        return min(0.95, max(0.5, confidence))
    }

    private func generateSuggestionReason(for task: TaskItem, at time: Date) -> String {
        let hour = Calendar.current.component(.hour, from: time)

        if task.starRating >= 3 && hour < 12 {
            return "High priority - scheduled for peak focus hours"
        } else if hour >= 14 && hour < 16 {
            return "Good slot for focused work after lunch"
        } else {
            return "Available time slot"
        }
    }

    private func getStreakStatus(user: User) -> StreakStatus {
        if user.currentStreak == 0 {
            return .broken(message: "Start a new streak today!")
        } else if user.currentStreak >= user.longestStreak && user.currentStreak >= 7 {
            return .record(days: user.currentStreak)
        } else {
            return .active(days: user.currentStreak)
        }
    }

    private func getFocusSuggestion() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour < 10 {
            return "Morning is your peak focus time - start with deep work"
        } else if hour < 14 {
            return "Try a 25-min Pomodoro session"
        } else {
            return "Schedule a focus block before end of day"
        }
    }
}

// MARK: - Daily Brief Model

struct DailyBrief {
    let date: Date
    let greeting: String
    let velocityScore: Int
    let scheduledTasksCount: Int
    let priorityTasks: [TaskItem]
    let suggestedSchedule: [DailyScheduleSuggestion]
    let insight: String
    let streakStatus: StreakStatus
    let focusSuggestion: String

    var formattedDate: String {
        date.formatted(.dateTime.weekday(.wide).month().day())
    }

    var hasSuggestions: Bool {
        !suggestedSchedule.isEmpty
    }

    var summaryText: String {
        if scheduledTasksCount == 0 && suggestedSchedule.isEmpty {
            return "No tasks scheduled. Add some tasks to plan your day."
        } else if scheduledTasksCount == 0 {
            return "\(suggestedSchedule.count) tasks ready to schedule"
        } else {
            return "\(scheduledTasksCount) tasks scheduled, \(suggestedSchedule.count) suggestions"
        }
    }
}

// MARK: - Daily Schedule Suggestion

struct DailyScheduleSuggestion: Identifiable {
    let id = UUID()
    let task: TaskItem?
    let suggestedTime: Date
    let durationMinutes: Int
    let confidence: Double
    let reason: String

    var formattedTime: String {
        suggestedTime.formatted(.dateTime.hour().minute())
    }

    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}

// MARK: - Streak Status

enum StreakStatus {
    case active(days: Int)
    case record(days: Int)
    case broken(message: String)

    var icon: String {
        switch self {
        case .active: return "flame.fill"
        case .record: return "crown.fill"
        case .broken: return "flame"
        }
    }

    var message: String {
        switch self {
        case .active(let days):
            return "\(days) day streak - keep it going!"
        case .record(let days):
            return "Personal record: \(days) days!"
        case .broken(let message):
            return message
        }
    }
}
