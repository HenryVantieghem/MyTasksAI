//
//  PatternLearningService.swift
//  Veloce
//
//  Pattern Learning Service - Tracks and analyzes user behavior patterns
//  Enables personalized AI suggestions by learning from user actions
//

import Foundation
import SwiftData

// MARK: - Pattern Learning Service

@MainActor
@Observable
final class PatternLearningService {
    // MARK: Singleton
    static let shared = PatternLearningService()

    // MARK: State
    private(set) var currentPattern: UserPattern?
    private(set) var isLoaded = false

    // MARK: Dependencies
    private var modelContext: ModelContext?

    // MARK: Caches
    private var recentCompletions: [(hour: Int, weekday: Int, timestamp: Date)] = []
    private var suggestionFeedback: [(type: String, accepted: Bool, timestamp: Date)] = []

    // MARK: Initialization
    private init() {}

    // MARK: - Setup

    func setup(context: ModelContext, userId: UUID) {
        self.modelContext = context
        loadOrCreatePattern(userId: userId)
    }

    private func loadOrCreatePattern(userId: UUID) {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<UserPattern>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            let patterns = try context.fetch(descriptor)
            if let existing = patterns.first {
                currentPattern = existing
            } else {
                let newPattern = UserPattern(userId: userId)
                context.insert(newPattern)
                try context.save()
                currentPattern = newPattern
            }
            isLoaded = true
        } catch {
            print("Failed to load user pattern: \(error)")
        }
    }

    // MARK: - Track Events

    /// Record a task completion for pattern analysis
    func recordTaskCompletion(
        task: TaskItem,
        actualMinutes: Int? = nil
    ) {
        guard let pattern = currentPattern else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date()) - 1 // 0-indexed

        // Track completion time
        recentCompletions.append((hour: hour, weekday: weekday, timestamp: .now))

        // Keep only last 100 completions
        if recentCompletions.count > 100 {
            recentCompletions.removeFirst()
        }

        // Update hourly rates
        var hourlyRates = pattern.hourlyCompletionRates
        let currentRate = hourlyRates[hour] ?? 0
        hourlyRates[hour] = currentRate + 1
        pattern.hourlyCompletionRates = hourlyRates

        // Update weekday rates
        var weekdayRates = pattern.weekdayCompletionRates
        let currentWeekdayRate = weekdayRates[weekday] ?? 0
        weekdayRates[weekday] = currentWeekdayRate + 1
        pattern.weekdayCompletionRates = weekdayRates

        // Update estimate accuracy if we have actual time
        if let actual = actualMinutes, let estimated = task.estimatedMinutes, estimated > 0 {
            let ratio = Double(actual) / Double(estimated)
            // Running average
            let oldRatio = pattern.estimateAccuracyRatio
            pattern.estimateAccuracyRatio = (oldRatio * 0.9) + (ratio * 0.1)
        }

        // Recalculate peak hours
        recalculatePeakHours()

        pattern.updatedAt = .now
        savePattern()
    }

    /// Record AI suggestion feedback
    func recordSuggestionFeedback(
        suggestionType: String,
        accepted: Bool
    ) {
        guard let pattern = currentPattern else { return }

        pattern.totalSuggestionsShown += 1
        if accepted {
            pattern.suggestionsAccepted += 1
        } else {
            pattern.suggestionsRejected += 1
        }

        // Track by type
        suggestionFeedback.append((type: suggestionType, accepted: accepted, timestamp: .now))

        // Update type-specific acceptance rates
        var typeRates = pattern.suggestionAcceptanceByType
        let typeAcceptances = suggestionFeedback.filter { $0.type == suggestionType && $0.accepted }.count
        let typeTotal = suggestionFeedback.filter { $0.type == suggestionType }.count
        typeRates[suggestionType] = typeTotal > 0 ? Double(typeAcceptances) / Double(typeTotal) : 0.5
        pattern.suggestionAcceptanceByType = typeRates

        pattern.updatedAt = .now
        savePattern()
    }

    /// Record focus session
    func recordFocusSession(
        mode: String,
        durationMinutes: Int,
        completed: Bool
    ) {
        guard let pattern = currentPattern else { return }

        // Update preferred focus mode based on usage
        pattern.preferredFocusMode = mode

        // Update average duration (running average)
        let oldAvg = pattern.averageFocusDurationMinutes
        pattern.averageFocusDurationMinutes = (oldAvg * 4 + durationMinutes) / 5

        // Update completion rate (running average)
        let completionValue = completed ? 1.0 : 0.0
        pattern.focusCompletionRate = (pattern.focusCompletionRate * 0.9) + (completionValue * 0.1)

        pattern.updatedAt = .now
        savePattern()
    }

    /// Record scheduling behavior
    func recordSchedulingBehavior(
        scheduledHour: Int,
        wasRescheduled: Bool,
        bufferToNextTask: Int?
    ) {
        guard let pattern = currentPattern else { return }

        // Determine preferred time of day
        if scheduledHour < 12 {
            pattern.preferredSchedulingTime = "morning"
        } else if scheduledHour < 17 {
            pattern.preferredSchedulingTime = "afternoon"
        } else {
            pattern.preferredSchedulingTime = "evening"
        }

        // Update reschedule tendency
        let rescheduleValue = wasRescheduled ? 1.0 : 0.0
        pattern.rescheduleTendency = (pattern.rescheduleTendency * 0.9) + (rescheduleValue * 0.1)

        // Update buffer preference
        if let buffer = bufferToNextTask {
            let oldBuffer = pattern.averageBufferMinutes
            pattern.averageBufferMinutes = (oldBuffer * 4 + buffer) / 5
        }

        pattern.updatedAt = .now
        savePattern()
    }

    /// Record streak break
    func recordStreakBreak() {
        guard let pattern = currentPattern else { return }

        let weekday = Calendar.current.component(.weekday, from: Date()) - 1

        // Track which days tend to break streaks
        var breakDays = pattern.streakBreakDays
        if !breakDays.contains(weekday) && breakDays.count < 3 {
            breakDays.append(weekday)
            pattern.streakBreakDays = breakDays
        }

        pattern.updatedAt = .now
        savePattern()
    }

    // MARK: - Get Insights

    /// Get personalized productivity patterns for AI
    func getProductivityPatterns() -> UserProductivityPatterns {
        guard let pattern = currentPattern else {
            return .defaults
        }
        return UserProductivityPatterns(from: pattern)
    }

    /// Get suggestion confidence adjustment based on user's acceptance patterns
    func getSuggestionConfidenceMultiplier(for type: String) -> Double {
        guard let pattern = currentPattern else { return 1.0 }

        let typeAcceptance = pattern.suggestionAcceptanceByType[type] ?? 0.5
        _ = pattern.suggestionAcceptanceRate  // Overall rate available for future use

        // If user generally accepts this type more, boost confidence
        // If they reject it, lower confidence
        return 0.8 + (typeAcceptance * 0.4)
    }

    /// Get optimal scheduling hour for a task
    func getOptimalSchedulingHour(for priority: Int) -> Int {
        guard let pattern = currentPattern else { return 9 }

        // High priority tasks go to peak hours
        if priority >= 3 {
            return pattern.peakProductivityHours.first ?? 9
        }

        // Medium priority goes to secondary peak
        if priority == 2 {
            return pattern.peakProductivityHours.dropFirst().first ?? 14
        }

        // Low priority goes to off-peak
        return 15
    }

    /// Get personalized insight text
    func getPersonalizedInsight() -> String? {
        guard let pattern = currentPattern, isLoaded else { return nil }

        // Return different insights based on data availability
        let totalTasks = pattern.hourlyCompletionRates.values.reduce(0, +)

        if totalTasks < 10 {
            return "Complete more tasks to unlock personalized insights"
        }

        // Rotate through different insights
        let insights = [
            pattern.productivityInsight,
            pattern.estimateAccuracyDescription,
            pattern.focusRecommendation
        ]

        // Pick based on day of week for variety
        let dayIndex = Calendar.current.component(.weekday, from: Date()) % insights.count
        return insights[dayIndex]
    }

    // MARK: - Private Helpers

    private func recalculatePeakHours() {
        guard let pattern = currentPattern else { return }

        // Sort hours by completion rate
        let sortedHours = pattern.hourlyCompletionRates
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }

        if !sortedHours.isEmpty {
            pattern.peakProductivityHours = Array(sortedHours)
        }
    }

    private func savePattern() {
        guard let context = modelContext else { return }

        do {
            try context.save()
        } catch {
            print("Failed to save pattern: \(error)")
        }
    }
}

// MARK: - Suggestion Types

extension PatternLearningService {
    enum SuggestionType: String {
        case schedule = "schedule"
        case priority = "priority"
        case duration = "duration"
        case breakdown = "breakdown"
        case focus = "focus"
    }
}
