//
//  CalendarService.swift
//  Veloce
//
//  Calendar Service - EventKit Integration
//  Handles calendar sync, event creation, and free slot detection
//

import Foundation
import EventKit

// MARK: - Calendar Service

@MainActor
@Observable
final class CalendarService {
    // MARK: Singleton
    static let shared = CalendarService()

    // MARK: State
    private(set) var isAuthorized: Bool = false
    private(set) var calendars: [EKCalendar] = []
    private(set) var selectedCalendar: EKCalendar?
    private(set) var lastError: String?

    // MARK: EventKit
    private let eventStore = EKEventStore()

    // MARK: Initialization
    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Check current authorization status and load calendars if authorized
    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = status == .fullAccess || status == .writeOnly

        // Load calendars if already authorized
        if isAuthorized && selectedCalendar == nil {
            calendars = eventStore.calendars(for: .event)
                .filter { $0.allowsContentModifications }
            selectedCalendar = eventStore.defaultCalendarForNewEvents
        }
    }

    /// Request calendar access
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            isAuthorized = granted

            if granted {
                await loadCalendars()
            }

            return granted
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Load available calendars
    func loadCalendars() async {
        guard isAuthorized else { return }

        calendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }

        // Select default calendar
        if selectedCalendar == nil {
            selectedCalendar = eventStore.defaultCalendarForNewEvents
        }
    }

    /// Select calendar for task events
    func selectCalendar(_ calendar: EKCalendar) {
        selectedCalendar = calendar
    }

    // MARK: - Event Creation

    /// Create calendar event for a task
    func createEvent(
        for task: TaskItem,
        at date: Date,
        duration: Int? = nil
    ) async throws -> String {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = selectedCalendar else {
            throw CalendarError.noCalendarSelected
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.startDate = date
        event.endDate = Calendar.current.date(
            byAdding: .minute,
            value: duration ?? task.estimatedMinutes ?? 30,
            to: date
        )
        event.calendar = calendar

        // Add notes if available
        if let notes = task.notes {
            event.notes = notes
        }

        // Add reminder
        event.addAlarm(EKAlarm(relativeOffset: -15 * 60)) // 15 min before

        try eventStore.save(event, span: .thisEvent)

        return event.eventIdentifier
    }

    /// Update existing calendar event
    func updateEvent(
        eventId: String,
        title: String? = nil,
        startDate: Date? = nil,
        duration: Int? = nil
    ) async throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }

        if let title {
            event.title = title
        }

        if let startDate {
            event.startDate = startDate
            if let duration {
                event.endDate = Calendar.current.date(
                    byAdding: .minute,
                    value: duration,
                    to: startDate
                )
            }
        }

        try eventStore.save(event, span: .thisEvent)
    }

    /// Delete calendar event
    func deleteEvent(eventId: String) async throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }

        try eventStore.remove(event, span: .thisEvent)
    }

    /// Update calendar event time
    func updateEventTime(eventId: String, newTime: Date) async throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }

        // Calculate the duration from the original event
        let duration = event.endDate.timeIntervalSince(event.startDate)

        // Update to new time while preserving duration
        event.startDate = newTime
        event.endDate = newTime.addingTimeInterval(duration)

        try eventStore.save(event, span: .thisEvent)
    }

    // MARK: - Free Slot Detection

    /// Find free time slots for scheduling
    func findFreeSlots(
        from startDate: Date = Date(),
        to endDate: Date? = nil,
        minimumDuration: Int = 30,
        workingHoursOnly: Bool = true
    ) async -> [DateInterval] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let end = endDate ?? calendar.date(byAdding: .day, value: 7, to: startDate)!

        // Fetch existing events
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: end,
            calendars: nil
        )
        let events = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        // Find gaps between events
        var freeSlots: [DateInterval] = []
        var currentStart = startDate

        for event in events {
            // Check if there's a gap before this event
            if event.startDate > currentStart {
                let gap = DateInterval(start: currentStart, end: event.startDate)

                // Only include if it meets minimum duration
                if gap.duration >= Double(minimumDuration * 60) {
                    // Filter by working hours if needed
                    if workingHoursOnly {
                        if let workingSlot = filterWorkingHours(gap) {
                            freeSlots.append(workingSlot)
                        }
                    } else {
                        freeSlots.append(gap)
                    }
                }
            }

            // Move past this event
            if event.endDate > currentStart {
                currentStart = event.endDate
            }
        }

        // Add remaining time until end
        if currentStart < end {
            let finalGap = DateInterval(start: currentStart, end: end)
            if finalGap.duration >= Double(minimumDuration * 60) {
                if workingHoursOnly {
                    if let workingSlot = filterWorkingHours(finalGap) {
                        freeSlots.append(workingSlot)
                    }
                } else {
                    freeSlots.append(finalGap)
                }
            }
        }

        return freeSlots
    }

    /// Filter slot to working hours (9 AM - 6 PM)
    private func filterWorkingHours(_ slot: DateInterval) -> DateInterval? {
        let calendar = Calendar.current

        let startHour = calendar.component(.hour, from: slot.start)
        let endHour = calendar.component(.hour, from: slot.end)

        // Working hours: 9 AM to 6 PM
        let workStart = 9
        let workEnd = 18

        // Skip if completely outside working hours
        if startHour >= workEnd || endHour <= workStart {
            return nil
        }

        // Adjust start if before work hours
        var adjustedStart = slot.start
        if startHour < workStart {
            adjustedStart = calendar.date(
                bySettingHour: workStart,
                minute: 0,
                second: 0,
                of: slot.start
            )!
        }

        // Adjust end if after work hours
        var adjustedEnd = slot.end
        if endHour > workEnd {
            adjustedEnd = calendar.date(
                bySettingHour: workEnd,
                minute: 0,
                second: 0,
                of: slot.end
            )!
        }

        guard adjustedStart < adjustedEnd else { return nil }

        return DateInterval(start: adjustedStart, end: adjustedEnd)
    }

    // MARK: - Event Queries

    /// Fetch events for a specific day
    func eventsForDay(_ date: Date) async -> [EKEvent] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    /// Fetch events for a date range
    func events(from start: Date, to end: Date) async -> [EKEvent] {
        guard isAuthorized else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    /// Check if a time slot is available
    func isSlotAvailable(start: Date, duration: Int) async -> Bool {
        guard isAuthorized else { return false }

        let end = Calendar.current.date(byAdding: .minute, value: duration, to: start)!

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        let conflicts = eventStore.events(matching: predicate)
        return conflicts.isEmpty
    }
}

// MARK: - Calendar Error

enum CalendarError: Error, LocalizedError {
    case notAuthorized
    case noCalendarSelected
    case eventNotFound
    case saveFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized"
        case .noCalendarSelected:
            return "No calendar selected"
        case .eventNotFound:
            return "Event not found"
        case .saveFailed(let error):
            return "Failed to save event: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete event: \(error.localizedDescription)"
        }
    }
}

// MARK: - EKEvent Extension

extension EKEvent {
    /// Duration in minutes
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    /// Formatted time range
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}
