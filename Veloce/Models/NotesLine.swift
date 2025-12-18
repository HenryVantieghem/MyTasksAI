//
//  NotesLine.swift
//  MyTasksAI
//
//  Daily notes line model - Apple Notes style free-form task capture
//  Each line represents a potential task with optional checkbox and priority
//

import Foundation
import SwiftData

// MARK: - Notes Line Model

@Model
final class NotesLine {
    // MARK: Core Properties
    var id: UUID
    var text: String
    var date: Date  // Which day this line belongs to (normalized to midnight)
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    // MARK: Task Properties
    var hasCheckbox: Bool
    var isChecked: Bool
    var starRating: Int  // 0 = none, 1-3 = priority stars

    // MARK: Linked Task
    /// Optional link to a full TaskItem for AI processing and detail sheet
    var linkedTaskId: UUID?

    // MARK: User Reference
    var userId: UUID?

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        text: String = "",
        date: Date = .now,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        hasCheckbox: Bool = false,
        isChecked: Bool = false,
        starRating: Int = 0,
        linkedTaskId: UUID? = nil,
        userId: UUID? = nil
    ) {
        self.id = id
        self.text = text
        self.date = Calendar.current.startOfDay(for: date)  // Normalize to midnight
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.hasCheckbox = hasCheckbox
        self.isChecked = isChecked
        self.starRating = starRating
        self.linkedTaskId = linkedTaskId
        self.userId = userId
    }

    // MARK: Computed Properties

    /// Whether this line represents a task (has checkbox or stars)
    var isTask: Bool {
        hasCheckbox || starRating > 0
    }

    /// Whether this line has any content
    var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Display-friendly star string
    var starsDisplay: String {
        String(repeating: "★", count: starRating)
    }

    /// Priority based on star rating
    var priority: TaskPriority {
        switch starRating {
        case 1: return .low
        case 2: return .medium
        case 3: return .high
        default: return .medium
        }
    }

    // MARK: Methods

    /// Toggle the checkbox state
    func toggleCheckbox() {
        hasCheckbox.toggle()
        updatedAt = .now
    }

    /// Toggle the checked state
    func toggleChecked() {
        isChecked.toggle()
        updatedAt = .now
    }

    /// Cycle through star ratings (0 → 1 → 2 → 3 → 0)
    func cycleStars() {
        starRating = (starRating + 1) % 4
        updatedAt = .now
    }

    /// Set star rating directly
    func setStars(_ rating: Int) {
        starRating = max(0, min(3, rating))
        updatedAt = .now
    }

    /// Update text content
    func updateText(_ newText: String) {
        text = newText
        updatedAt = .now
    }
}

// MARK: - Date Helpers

extension NotesLine {
    /// Check if this line belongs to a specific date
    func belongsTo(date: Date) -> Bool {
        Calendar.current.isDate(self.date, inSameDayAs: date)
    }

    /// Format for display (Today, Yesterday, Tomorrow, or date)
    static func displayDate(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Supabase DTO

/// Data Transfer Object for Supabase sync
struct SupabaseNotesLine: Codable, Sendable {
    let id: UUID
    let text: String
    let date: Date
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
    let hasCheckbox: Bool
    let isChecked: Bool
    let starRating: Int
    let linkedTaskId: UUID?
    let userId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case date
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case hasCheckbox = "has_checkbox"
        case isChecked = "is_checked"
        case starRating = "star_rating"
        case linkedTaskId = "linked_task_id"
        case userId = "user_id"
    }

    init(from line: NotesLine) {
        self.id = line.id
        self.text = line.text
        self.date = line.date
        self.sortOrder = line.sortOrder
        self.createdAt = line.createdAt
        self.updatedAt = line.updatedAt
        self.hasCheckbox = line.hasCheckbox
        self.isChecked = line.isChecked
        self.starRating = line.starRating
        self.linkedTaskId = line.linkedTaskId
        self.userId = line.userId
    }
}
