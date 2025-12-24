//
//  CalendarViewModel.swift
//  Veloce
//
//  Calendar View Model - Calendar Integration
//  Handles calendar display, event management, and scheduling
//

import Foundation
import EventKit
import SwiftData

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var icon: String {
        switch self {
        case .day: return "square"
        case .week: return "rectangle.split.3x1"
        case .month: return "calendar"
        }
    }
}

// MARK: - Calendar View Model

@MainActor
@Observable
final class CalendarViewModel {
    // MARK: State
    private(set) var isLoading: Bool = false
    private(set) var error: String?
    private(set) var isAuthorized: Bool = false

    // MARK: Calendar Data
    private(set) var events: [EKEvent] = []
    private(set) var scheduledTasks: [TaskItem] = []
    private(set) var freeSlots: [DateInterval] = []

    // MARK: View State
    var selectedDate: Date = Date()
    var viewMode: CalendarViewMode = .week

    // MARK: Services
    private let calendar = CalendarService.shared
    private let ai = AIService.shared
    private let haptics = HapticsService.shared

    // MARK: Context
    private var modelContext: ModelContext?

    // MARK: Computed Properties
    var dateRange: (start: Date, end: Date) {
        let cal = Calendar.current

        switch viewMode {
        case .day:
            let start = cal.startOfDay(for: selectedDate)
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .week:
            let start = cal.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
            let end = cal.date(byAdding: .day, value: 7, to: start)!
            return (start, end)

        case .month:
            let start = cal.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
            let end = cal.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
            return (start, end)
        }
    }

    // MARK: Initialization
    init() {}

    // MARK: - Setup

    func setup(context: ModelContext) {
        self.modelContext = context
        isAuthorized = calendar.isAuthorized

        if isAuthorized {
            Task {
                await loadData()
            }
        }
    }

    // MARK: - Authorization

    func requestAccess() async {
        isAuthorized = await calendar.requestAccess()

        if isAuthorized {
            await loadData()
        }
    }

    // MARK: - Load Data

    func loadData() async {
        guard isAuthorized else { return }

        isLoading = true
        defer { isLoading = false }

        // Load calendar events
        events = await calendar.events(
            from: dateRange.start,
            to: dateRange.end
        )

        // Load scheduled tasks
        loadScheduledTasks()

        // Find free slots
        freeSlots = await calendar.findFreeSlots(
            from: Date(),
            to: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            minimumDuration: 30
        )
    }

    private func loadScheduledTasks() {
        guard let context = modelContext else { return }

        let start = dateRange.start
        let end = dateRange.end

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.scheduledTime != nil &&
                !task.isCompleted
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )

        do {
            let allScheduled = try context.fetch(descriptor)

            // Filter to date range
            scheduledTasks = allScheduled.filter { task in
                guard let time = task.scheduledTime else { return false }
                return time >= start && time < end
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Navigation

    func goToToday() {
        selectedDate = Date()
        Task {
            await loadData()
        }
        haptics.selectionFeedback()
    }

    func goToPrevious() {
        let cal = Calendar.current

        switch viewMode {
        case .day:
            selectedDate = cal.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = cal.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = cal.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }

        Task {
            await loadData()
        }
        haptics.selectionFeedback()
    }

    func goToNext() {
        let cal = Calendar.current

        switch viewMode {
        case .day:
            selectedDate = cal.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = cal.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = cal.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }

        Task {
            await loadData()
        }
        haptics.selectionFeedback()
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        Task {
            await loadData()
        }
        haptics.selectionFeedback()
    }

    // MARK: - Schedule Task

    func scheduleTask(_ task: TaskItem, at date: Date) async throws {
        // Update task
        task.scheduledTime = date
        task.updatedAt = Date()

        try modelContext?.save()

        // Create calendar event
        if calendar.isAuthorized {
            let eventId = try await calendar.createEvent(
                for: task,
                at: date,
                duration: task.estimatedMinutes ?? 30
            )
            task.calendarEventId = eventId
            try modelContext?.save()
        }

        await loadData()
        haptics.taskComplete()
    }

    func unscheduleTask(_ task: TaskItem) async throws {
        // Remove calendar event
        if let eventId = task.calendarEventId {
            try await calendar.deleteEvent(eventId: eventId)
        }

        // Update task
        task.scheduledTime = nil
        task.calendarEventId = nil
        task.updatedAt = Date()

        try modelContext?.save()

        await loadData()
        haptics.impact()
    }

    func updateCalendarEvent(eventId: String, newTime: Date) async {
        do {
            try await calendar.updateEventTime(eventId: eventId, newTime: newTime)
            await loadData()
            haptics.success()
        } catch {
            self.error = "Failed to update calendar event: \(error.localizedDescription)"
        }
    }

    // MARK: - AI Scheduling

    func suggestSchedule(
        for task: TaskItem,
        userPatterns: UserProductivityPatterns?
    ) async throws -> ScheduleSuggestion {
        return try await ai.suggestSchedule(
            for: task,
            freeSlots: freeSlots,
            userPatterns: userPatterns
        )
    }

    // MARK: - Tasks for Date

    func tasks(for date: Date) -> [TaskItem] {
        let cal = Calendar.current
        return scheduledTasks.filter { task in
            guard let time = task.scheduledTime else { return false }
            return cal.isDate(time, inSameDayAs: date)
        }
    }

    func events(for date: Date) -> [EKEvent] {
        let cal = Calendar.current
        return events.filter { event in
            cal.isDate(event.startDate, inSameDayAs: date)
        }
    }

    // MARK: - Week Days

    var weekDays: [Date] {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate

        return (0..<7).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: start)
        }
    }

    // MARK: - Month Days

    var monthDays: [[Date?]] {
        let cal = Calendar.current

        guard let monthInterval = cal.dateInterval(of: .month, for: selectedDate) else {
            return []
        }

        let firstDay = monthInterval.start
        let firstWeekday = cal.component(.weekday, from: firstDay)
        let daysInMonth = cal.range(of: .day, in: .month, for: selectedDate)?.count ?? 30

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []

        // Add empty days for first week
        for _ in 1..<firstWeekday {
            currentWeek.append(nil)
        }

        // Add days of the month
        for day in 1...daysInMonth {
            if let date = cal.date(bySetting: .day, value: day, of: firstDay) {
                currentWeek.append(date)

                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
        }

        // Add remaining empty days
        while currentWeek.count < 7 && !currentWeek.isEmpty {
            currentWeek.append(nil)
        }

        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }

        return weeks
    }

    // MARK: - Helpers

    func clearError() {
        error = nil
    }
}
