//
//  Task.swift
//  MyTasksAI
//
//  Main Task Model - SwiftData + Supabase compatible
//  Represents a user task with AI enhancements
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Task Item Model
@Model
final class TaskItem {
    // MARK: Core Properties
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    // MARK: User Reference
    var userId: UUID?

    // MARK: AI Properties
    var aiAdvice: String?
    var estimatedMinutes: Int?
    var aiPriority: String?
    var aiProcessedAt: Date?
    var aiSources: [String]?
    var aiThoughtProcess: String?
    var aiGeneratedPrompt: String?

    // MARK: Scheduling
    var scheduledTime: Date?
    var duration: Int?
    var reminderEnabled: Bool
    var calendarEventId: String?
    var scheduleSuggestion: Data?  // JSON encoded ScheduleSuggestion

    // MARK: Context
    var contextNotes: String?
    var category: String?

    // MARK: Gamification
    var pointsEarned: Int
    var completedOnTime: Bool?
    var sortOrder: Int

    // MARK: Priority (Sam Altman Style)
    var starRating: Int  // 1 = *, 2 = **, 3 = ***

    // MARK: Tracking
    var actualMinutes: Int?

    // MARK: Recurring
    var recurringType: String?  // RecurringType.rawValue

    // MARK: Initialization
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        completedAt: Date? = nil,
        userId: UUID? = nil,
        aiAdvice: String? = nil,
        estimatedMinutes: Int? = nil,
        aiPriority: String? = "medium",
        aiProcessedAt: Date? = nil,
        aiSources: [String]? = nil,
        aiThoughtProcess: String? = nil,
        aiGeneratedPrompt: String? = nil,
        scheduledTime: Date? = nil,
        duration: Int? = nil,
        reminderEnabled: Bool = false,
        calendarEventId: String? = nil,
        scheduleSuggestion: Data? = nil,
        contextNotes: String? = nil,
        category: String? = nil,
        pointsEarned: Int = 0,
        completedOnTime: Bool? = nil,
        sortOrder: Int = 0,
        starRating: Int = 2,
        actualMinutes: Int? = nil,
        recurringType: String? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.userId = userId
        self.aiAdvice = aiAdvice
        self.estimatedMinutes = estimatedMinutes
        self.aiPriority = aiPriority
        self.aiProcessedAt = aiProcessedAt
        self.aiSources = aiSources
        self.aiThoughtProcess = aiThoughtProcess
        self.aiGeneratedPrompt = aiGeneratedPrompt
        self.scheduledTime = scheduledTime
        self.duration = duration
        self.reminderEnabled = reminderEnabled
        self.calendarEventId = calendarEventId
        self.scheduleSuggestion = scheduleSuggestion
        self.contextNotes = contextNotes
        self.category = category
        self.pointsEarned = pointsEarned
        self.completedOnTime = completedOnTime
        self.sortOrder = sortOrder
        self.starRating = starRating
        self.actualMinutes = actualMinutes
        self.recurringType = recurringType
    }
}

// MARK: - Computed Properties
extension TaskItem {
    /// Priority as enum
    var priority: TaskPriority {
        TaskPriority(rawValue: starRating) ?? .medium
    }

    /// AI Priority as TaskPriority enum
    var aiPriorityEnum: TaskPriority? {
        guard let aiPriority else { return nil }
        switch aiPriority.lowercased() {
        case "low": return .low
        case "medium": return .medium
        case "high": return .high
        default: return .medium
        }
    }

    /// Check if task has AI processing
    var hasAIProcessing: Bool {
        aiAdvice != nil || aiThoughtProcess != nil
    }

    /// Check if task is scheduled
    var isScheduled: Bool {
        scheduledTime != nil
    }

    /// Check if task is overdue
    var isOverdue: Bool {
        guard let scheduled = scheduledTime else { return false }
        return !isCompleted && scheduled < Date()
    }

    /// Formatted time estimate
    var estimatedTimeFormatted: String? {
        guard let minutes = estimatedMinutes else { return nil }
        return minutes.formattedDuration
    }

    /// Time until scheduled
    var timeUntilScheduled: TimeInterval? {
        guard let scheduled = scheduledTime else { return nil }
        return scheduled.timeIntervalSinceNow
    }

    /// Priority color based on AI priority or star rating
    var priorityColor: Color {
        if let aiPriority = aiPriority?.lowercased() {
            switch aiPriority {
            case "high": return Theme.Colors.error
            case "medium": return Theme.Colors.warning
            case "low": return Theme.Colors.success
            default: return Theme.Colors.textSecondary
            }
        }
        return priority.color
    }

    /// Priority icon
    var priorityIcon: String {
        if let aiPriority = aiPriority?.lowercased() {
            switch aiPriority {
            case "high": return "exclamationmark.triangle.fill"
            case "medium": return "equal.circle.fill"
            case "low": return "arrow.down.circle.fill"
            default: return "circle.fill"
            }
        }
        return priority.icon
    }

    /// Priority as star string (Sam Altman style)
    var priorityStars: String {
        String(repeating: "★", count: starRating)
    }

    /// Alias for contextNotes (for compatibility)
    var notes: String? {
        get { contextNotes }
        set { contextNotes = newValue }
    }

    /// Priority enum (alias for priority)
    var priorityEnum: TaskPriority {
        priority
    }

    /// Recurring type as enum
    var recurring: RecurringType {
        guard let recurringType else { return .once }
        return RecurringType(rawValue: recurringType) ?? .once
    }

    /// Formatted scheduled date string
    var scheduledDateFormatted: String? {
        guard let scheduledTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: scheduledTime)
    }

    /// Formatted scheduled time string
    var scheduledTimeFormatted: String? {
        guard let scheduledTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
    }
}

// MARK: - Methods
extension TaskItem {
    /// Set recurring type
    func setRecurring(_ type: RecurringType) {
        recurringType = type.rawValue
        updatedAt = .now
    }

    /// Mark task as completed
    func complete() {
        isCompleted = true
        completedAt = .now
        updatedAt = .now

        // Check if completed on time
        if let scheduled = scheduledTime {
            completedOnTime = Date() <= scheduled
        }

        // Calculate points
        var points = DesignTokens.Gamification.pointsTaskComplete
        if completedOnTime == true {
            points += DesignTokens.Gamification.pointsOnTimeBonus
        }
        pointsEarned = points
    }

    /// Mark task as incomplete
    func uncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = .now
        completedOnTime = nil
        pointsEarned = 0
    }

    /// Update from Supabase response
    func update(from supabaseTask: SupabaseTask) {
        title = supabaseTask.title
        isCompleted = supabaseTask.isCompleted
        aiAdvice = supabaseTask.aiAdvice
        estimatedMinutes = supabaseTask.estimatedMinutes
        aiPriority = supabaseTask.aiPriority
        aiProcessedAt = supabaseTask.aiProcessedAt
        aiSources = supabaseTask.aiSources
        aiThoughtProcess = supabaseTask.aiThoughtProcess
        scheduledTime = supabaseTask.scheduledTime
        duration = supabaseTask.duration
        reminderEnabled = supabaseTask.reminderEnabled
        calendarEventId = supabaseTask.calendarEventId
        pointsEarned = supabaseTask.pointsEarned ?? 0
        completedOnTime = supabaseTask.completedOnTime
        sortOrder = supabaseTask.sortOrder ?? 0
        starRating = supabaseTask.starRating ?? 2
        actualMinutes = supabaseTask.actualMinutes
        contextNotes = supabaseTask.contextNotes
        aiGeneratedPrompt = supabaseTask.aiGeneratedPrompt
        updatedAt = supabaseTask.updatedAt ?? .now
        completedAt = supabaseTask.completedAt
    }

    /// Create TaskItem from Supabase task
    convenience init(from supabaseTask: SupabaseTask) {
        self.init(
            id: supabaseTask.id,
            title: supabaseTask.title,
            isCompleted: supabaseTask.isCompleted,
            createdAt: supabaseTask.createdAt ?? .now,
            updatedAt: supabaseTask.updatedAt ?? .now,
            completedAt: supabaseTask.completedAt,
            userId: supabaseTask.userId,
            aiAdvice: supabaseTask.aiAdvice,
            estimatedMinutes: supabaseTask.estimatedMinutes,
            aiPriority: supabaseTask.aiPriority,
            aiProcessedAt: supabaseTask.aiProcessedAt,
            aiSources: supabaseTask.aiSources,
            aiThoughtProcess: supabaseTask.aiThoughtProcess,
            aiGeneratedPrompt: supabaseTask.aiGeneratedPrompt,
            scheduledTime: supabaseTask.scheduledTime,
            duration: supabaseTask.duration,
            reminderEnabled: supabaseTask.reminderEnabled,
            calendarEventId: supabaseTask.calendarEventId,
            contextNotes: supabaseTask.contextNotes,
            pointsEarned: supabaseTask.pointsEarned ?? 0,
            completedOnTime: supabaseTask.completedOnTime,
            sortOrder: supabaseTask.sortOrder ?? 0,
            starRating: supabaseTask.starRating ?? 2,
            actualMinutes: supabaseTask.actualMinutes
        )
    }

    /// Convert to Supabase task for syncing
    func toSupabase(userId: UUID) -> SupabaseTask {
        SupabaseTask(from: self, userId: userId)
    }
}

// MARK: - TaskPriority Extension
extension TaskPriority {
    init?(rawValue: Int) {
        switch rawValue {
        case 1: self = .low
        case 2: self = .medium
        case 3: self = .high
        default: return nil
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "equal.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .low: return Theme.Colors.success
        case .medium: return Theme.Colors.warning
        case .high: return Theme.Colors.error
        }
    }
}

// MARK: - Supabase Task DTO
struct SupabaseTask: Codable, Sendable {
    let id: UUID
    let userId: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date?
    var completedAt: Date?
    var aiAdvice: String?
    var estimatedMinutes: Int?
    var aiPriority: String?
    var aiProcessedAt: Date?
    var aiSources: [String]?
    var aiThoughtProcess: String?
    var scheduledTime: Date?
    var duration: Int?
    var reminderEnabled: Bool
    var calendarEventId: String?
    var pointsEarned: Int?
    var completedOnTime: Bool?
    var sortOrder: Int?
    var updatedAt: Date?
    var aiGeneratedPrompt: String?
    var scheduleSuggestion: ScheduleSuggestion?
    var contextNotes: String?
    var starRating: Int?
    var actualMinutes: Int?

    init(from taskItem: TaskItem, userId: UUID) {
        self.id = taskItem.id
        self.userId = userId
        self.title = taskItem.title
        self.isCompleted = taskItem.isCompleted
        self.createdAt = taskItem.createdAt
        self.completedAt = taskItem.completedAt
        self.aiAdvice = taskItem.aiAdvice
        self.estimatedMinutes = taskItem.estimatedMinutes
        self.aiPriority = taskItem.aiPriority
        self.aiProcessedAt = taskItem.aiProcessedAt
        self.aiSources = taskItem.aiSources
        self.aiThoughtProcess = taskItem.aiThoughtProcess
        self.scheduledTime = taskItem.scheduledTime
        self.duration = taskItem.duration
        self.reminderEnabled = taskItem.reminderEnabled
        self.calendarEventId = taskItem.calendarEventId
        self.pointsEarned = taskItem.pointsEarned
        self.completedOnTime = taskItem.completedOnTime
        self.sortOrder = taskItem.sortOrder
        self.updatedAt = taskItem.updatedAt
        self.aiGeneratedPrompt = taskItem.aiGeneratedPrompt
        self.contextNotes = taskItem.contextNotes
        self.starRating = taskItem.starRating
        self.actualMinutes = taskItem.actualMinutes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case aiAdvice = "ai_advice"
        case estimatedMinutes = "estimated_minutes"
        case aiPriority = "ai_priority"
        case aiProcessedAt = "ai_processed_at"
        case aiSources = "ai_sources"
        case aiThoughtProcess = "ai_thought_process"
        case scheduledTime = "scheduled_time"
        case duration
        case reminderEnabled = "reminder_enabled"
        case calendarEventId = "calendar_event_id"
        case pointsEarned = "points_earned"
        case completedOnTime = "completed_on_time"
        case sortOrder = "sort_order"
        case updatedAt = "updated_at"
        case aiGeneratedPrompt = "ai_generated_prompt"
        case scheduleSuggestion = "schedule_suggestion"
        case contextNotes = "context_notes"
        case starRating = "star_rating"
        case actualMinutes = "actual_minutes"
    }
}

// MARK: - Schedule Suggestion
// Note: ScheduleSuggestion is defined in TaskReflection.swift to avoid duplication
