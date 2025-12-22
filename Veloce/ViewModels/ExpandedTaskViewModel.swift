//
//  ExpandedTaskViewModel.swift
//  MyTasksAI
//
//  ViewModel for expanded task card AI state
//  Manages genius-level AI features
//

import Foundation
import EventKit

// MARK: - Expanded Task ViewModel

@MainActor
@Observable
final class ExpandedTaskViewModel {
    // MARK: - Loading States
    var isLoadingMentor = false
    var isLoadingSchedule = false
    var isLoadingResources = false

    // MARK: - AI Data
    var mentorAdvice: MentorAdvice?
    var aiBreakdown: [ExecutionStep] = []
    var aiResources: [TaskResource] = []
    var scheduleSuggestions: [GeniusScheduleSuggestion] = []
    var userAverageForType: Int?

    // MARK: - Error State
    var errorMessage: String?

    // MARK: - Calendar
    private let eventStore = EKEventStore()
    private var calendarAccessGranted = false

    // MARK: - Services
    private var geminiService: GeminiService { GeminiService.shared }

    // MARK: - Initialization
    init() {
        Task {
            await requestCalendarAccess()
        }
    }

    // MARK: - Calendar Access

    private func requestCalendarAccess() async {
        do {
            calendarAccessGranted = try await eventStore.requestFullAccessToEvents()
        } catch {
            calendarAccessGranted = false
        }
    }

    // MARK: - AI Mentor

    /// Generate initial mentor advice for a task
    func generateMentorAdvice(for task: TaskItem) async {
        guard !isLoadingMentor else { return }
        isLoadingMentor = true
        errorMessage = nil

        do {
            let analysis = try await geminiService.generateGeniusAnalysis(
                title: task.title,
                notes: task.contextNotes,
                context: nil
            )

            mentorAdvice = analysis.mentorAdvice
            aiBreakdown = analysis.executionSteps
            aiResources = analysis.resources

            // Update task with quick tip
            task.aiQuickTip = analysis.mentorAdvice.quickTip
            task.taskTypeRaw = analysis.taskType.rawValue
            task.estimatedMinutes = analysis.estimatedMinutes
            task.aiProcessedAt = .now
            task.updatedAt = .now

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMentor = false
    }

    /// Regenerate mentor advice with fresh analysis
    func regenerateMentorAdvice(for task: TaskItem) async {
        mentorAdvice = nil
        aiBreakdown = []
        aiResources = []
        await generateMentorAdvice(for: task)
    }

    // MARK: - Schedule Suggestions

    /// Generate smart schedule suggestions based on calendar
    func generateScheduleSuggestions(for task: TaskItem) async {
        guard !isLoadingSchedule else { return }
        isLoadingSchedule = true

        do {
            // Fetch calendar events for next 7 days
            let calendarEvents = await fetchUpcomingCalendarEvents()

            let suggestions = try await geminiService.generateScheduleSuggestions(
                task: task,
                calendar: calendarEvents,
                userPatterns: nil
            )

            scheduleSuggestions = suggestions

        } catch {
            scheduleSuggestions = generateFallbackSuggestions(for: task)
        }

        isLoadingSchedule = false
    }

    /// Fetch calendar events for the next 7 days
    private func fetchUpcomingCalendarEvents() async -> [CalendarEventInfo] {
        guard calendarAccessGranted else { return [] }

        let calendars = eventStore.calendars(for: .event)
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        return events.map { event in
            CalendarEventInfo(
                title: event.title ?? "Untitled",
                start: event.startDate,
                end: event.endDate
            )
        }
    }

    /// Generate fallback suggestions when AI fails
    private func generateFallbackSuggestions(for task: TaskItem) -> [GeniusScheduleSuggestion] {
        let calendar = Calendar.current
        let now = Date()

        var suggestions: [GeniusScheduleSuggestion] = []

        // Best: Tomorrow morning
        if let tomorrow9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: now)!) {
            suggestions.append(GeniusScheduleSuggestion(
                rank: .best,
                date: tomorrow9am,
                reason: "Morning focus time, fresh start"
            ))
        }

        // Good: Today afternoon
        if let today2pm = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now), today2pm > now {
            suggestions.append(GeniusScheduleSuggestion(
                rank: .good,
                date: today2pm,
                reason: "Afternoon productivity window"
            ))
        }

        // Okay: Tomorrow afternoon
        if let tomorrow2pm = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: now)!) {
            suggestions.append(GeniusScheduleSuggestion(
                rank: .okay,
                date: tomorrow2pm,
                reason: "Flexible afternoon slot"
            ))
        }

        return suggestions
    }

    // MARK: - Schedule Task

    /// Schedule a task at the suggested time
    func scheduleTask(_ task: TaskItem, at suggestion: GeniusScheduleSuggestion) {
        task.scheduledTime = suggestion.date
        task.updatedAt = .now

        HapticsService.shared.successFeedback()
    }

    // MARK: - Time Blocking

    /// Block time on calendar for a task
    func blockTime(for task: TaskItem, at date: Date, duration: Int) async {
        guard calendarAccessGranted else {
            errorMessage = "Calendar access required"
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "🎯 \(task.title)"
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: date)
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Add reminder 15 min before
        event.addAlarm(EKAlarm(relativeOffset: -15 * 60))

        do {
            try eventStore.save(event, span: .thisEvent)

            // Update task
            task.scheduledTime = date
            task.duration = duration
            task.calendarEventId = event.eventIdentifier
            task.updatedAt = .now

            HapticsService.shared.successFeedback()
        } catch {
            errorMessage = "Failed to create calendar event"
        }
    }

    // MARK: - Execution Steps

    /// Toggle completion of an execution step
    func toggleStepCompletion(at index: Int) {
        guard index < aiBreakdown.count else { return }
        aiBreakdown[index].isCompleted.toggle()
        HapticsService.shared.selectionFeedback()
    }
}

// MARK: - Calendar Event Info

struct CalendarEventInfo: Sendable {
    let title: String
    let start: Date
    let end: Date
}
