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

    // MARK: Task Type (AI-detected)
    var taskTypeRaw: String?  // TaskType.rawValue
    var aiQuickTip: String?   // One-liner for collapsed card

    // MARK: Gamification
    var pointsEarned: Int
    var completedOnTime: Bool?
    var sortOrder: Int

    // MARK: Priority (Sam Altman Style)
    var starRating: Int  // 1 = *, 2 = **, 3 = ***

    // MARK: Tracking
    var actualMinutes: Int?
    var timesRescheduled: Int?
    var emotionalBlocker: String?

    // MARK: Recurring
    var recurringType: String?  // RecurringType.rawValue
    var recurringDays: [Int]?  // 0-6 for Sun-Sat (for custom recurring)
    var recurringEndDate: Date?  // Optional end date for recurring tasks
    var recurringParentId: UUID?  // Links recurring instances to parent task
    var lastRecurrenceDate: Date?  // When the last recurring instance was created

    // MARK: App Blocking
    var enableAppBlocking: Bool  // Whether to block apps during this task
    var blockedAppsData: Data?   // FamilyActivitySelection encoded data

    // MARK: Tiimo Visual Customization
    var taskIcon: String?        // SF Symbol name for custom icon
    var taskEmoji: String?       // Emoji for task personalization
    var taskColorHex: String?    // Custom color hex code override

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
        taskTypeRaw: String? = nil,
        aiQuickTip: String? = nil,
        pointsEarned: Int = 0,
        completedOnTime: Bool? = nil,
        sortOrder: Int = 0,
        starRating: Int = 2,
        actualMinutes: Int? = nil,
        recurringType: String? = nil,
        recurringDays: [Int]? = nil,
        recurringEndDate: Date? = nil,
        recurringParentId: UUID? = nil,
        lastRecurrenceDate: Date? = nil,
        enableAppBlocking: Bool = false,
        blockedAppsData: Data? = nil,
        taskIcon: String? = nil,
        taskEmoji: String? = nil,
        taskColorHex: String? = nil
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
        self.taskTypeRaw = taskTypeRaw
        self.aiQuickTip = aiQuickTip
        self.pointsEarned = pointsEarned
        self.completedOnTime = completedOnTime
        self.sortOrder = sortOrder
        self.starRating = starRating
        self.actualMinutes = actualMinutes
        self.recurringType = recurringType
        self.recurringDays = recurringDays
        self.recurringEndDate = recurringEndDate
        self.recurringParentId = recurringParentId
        self.lastRecurrenceDate = lastRecurrenceDate
        self.enableAppBlocking = enableAppBlocking
        self.blockedAppsData = blockedAppsData
        self.taskIcon = taskIcon
        self.taskEmoji = taskEmoji
        self.taskColorHex = taskColorHex
    }
}

// MARK: - Computed Properties
extension TaskItem {
    /// Priority as enum
    var priority: TaskPriority {
        TaskPriority(rawValue: starRating) ?? .medium
    }

    /// Task type as enum
    var taskType: TaskType {
        get {
            guard let raw = taskTypeRaw else { return .coordinate }
            return TaskType(rawValue: raw) ?? .coordinate
        }
        set {
            taskTypeRaw = newValue.rawValue
        }
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

    /// Energy level for power meter visualization (0.0 - 1.0)
    /// Calculated from potential points before completion
    var energyLevel: Double {
        let potentialPoints = calculatePotentialPoints()
        // Map points (10-100) to energy level (0.0-1.0)
        let normalizedPoints = Double(potentialPoints - 10) / 90.0
        return min(max(normalizedPoints, 0.0), 1.0)
    }

    /// Potential points for this task (used by Energy Core)
    var potentialPoints: Int {
        calculatePotentialPoints()
    }

    /// Energy state for visual rendering
    var energyState: EnergyState {
        let points = calculatePotentialPoints()
        if points <= DesignTokens.EnergyCore.lowThreshold {
            return .low
        } else if points <= DesignTokens.EnergyCore.mediumThreshold {
            return .medium
        } else if points <= DesignTokens.EnergyCore.highThreshold {
            return .high
        } else {
            return .max
        }
    }

    /// Calculate potential points from task properties
    private func calculatePotentialPoints() -> Int {
        var points = DesignTokens.Gamification.pointsTaskComplete // Base 10

        // Priority bonus
        switch starRating {
        case 3: points += 15  // High priority
        case 2: points += 5   // Medium priority
        default: break        // Low priority, no bonus
        }

        // Star rating bonus (5 per star)
        points += starRating * 5

        // AI processing bonus
        if hasAIProcessing { points += 5 }

        // Scheduled bonus
        if isScheduled { points += 5 }

        // Time estimate bonus (longer tasks = more points)
        if let minutes = estimatedMinutes {
            points += min(minutes / 10, 20) // Cap at +20
        }

        // Overdue penalty (reduce visual appeal)
        if isOverdue { points = max(points - 10, 10) }

        return min(points, 100) // Cap at 100
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

    /// Extended recurring type for UI
    var recurringExtended: RecurringTypeExtended {
        guard let recurringType else { return .once }
        return RecurringTypeExtended(rawValue: recurringType) ?? .once
    }

    /// Whether this is a recurring task
    var isRecurring: Bool {
        recurringType != nil && recurringType != "once"
    }

    /// Whether this task can create the next recurring instance
    var canCreateNextRecurrence: Bool {
        guard isRecurring else { return false }
        guard isCompleted else { return false }

        // Check end date
        if let endDate = recurringEndDate, Date() > endDate {
            return false
        }

        return true
    }

    /// Formatted recurring days string
    var recurringDaysFormatted: String? {
        guard let days = recurringDays, !days.isEmpty else { return nil }
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days.sorted().compactMap { $0 >= 0 && $0 <= 6 ? dayNames[$0] : nil }.joined(separator: ", ")
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

    /// Set extended recurring type with options
    func setRecurringExtended(
        type: RecurringTypeExtended,
        customDays: Set<Int>? = nil,
        endDate: Date? = nil
    ) {
        recurringType = type.rawValue
        recurringDays = customDays != nil ? Array(customDays!).sorted() : nil
        recurringEndDate = endDate
        updatedAt = .now
    }

    /// Calculate next occurrence date based on recurring settings
    func calculateNextOccurrenceDate() -> Date? {
        guard isRecurring else { return nil }

        let calendar = Calendar.current
        let baseDate = completedAt ?? Date()

        switch recurringExtended {
        case .once:
            return nil

        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: baseDate)

        case .weekdays:
            var nextDate = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
            let weekday = calendar.component(.weekday, from: nextDate)
            // Skip to Monday if on weekend
            if weekday == 1 { // Sunday
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            } else if weekday == 7 { // Saturday
                nextDate = calendar.date(byAdding: .day, value: 2, to: nextDate) ?? nextDate
            }
            return nextDate

        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate)

        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: baseDate)

        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: baseDate)

        case .custom:
            guard let days = recurringDays, !days.isEmpty else { return nil }
            // Find next matching day
            var searchDate = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
            for _ in 0..<7 {
                let weekday = calendar.component(.weekday, from: searchDate) - 1 // Convert to 0-6
                if days.contains(weekday) {
                    return searchDate
                }
                searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate) ?? searchDate
            }
            return nil
        }
    }

    /// Create a new task instance for the next recurrence
    func createRecurringInstance() -> TaskItem? {
        guard canCreateNextRecurrence else { return nil }
        guard let nextDate = calculateNextOccurrenceDate() else { return nil }

        // Check if past end date
        if let endDate = recurringEndDate, nextDate > endDate {
            return nil
        }

        let newTask = TaskItem(
            title: title,
            isCompleted: false,
            userId: userId,
            estimatedMinutes: estimatedMinutes,
            scheduledTime: nextDate,
            duration: duration,
            reminderEnabled: reminderEnabled,
            contextNotes: contextNotes,
            category: category,
            taskTypeRaw: taskTypeRaw,
            starRating: starRating,
            recurringType: recurringType,
            recurringDays: recurringDays,
            recurringEndDate: recurringEndDate,
            recurringParentId: recurringParentId ?? id // Link to parent
        )

        // Update this task's last recurrence date
        lastRecurrenceDate = Date()
        updatedAt = .now

        return newTask
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

// MARK: - Energy State
/// Visual state for the Energy Core power meter
enum EnergyState: String, CaseIterable {
    case low      // 10-25 points - dim, dormant
    case medium   // 26-50 points - breathing glow
    case high     // 51-75 points - pulsing, bright
    case max      // 76-100 points - overflow, particles

    /// Fill percentage for the energy orb
    var fillPercentage: CGFloat {
        switch self {
        case .low: return 0.25
        case .medium: return 0.50
        case .high: return 0.75
        case .max: return 1.0
        }
    }

    /// Should show breathing animation
    var isBreathing: Bool {
        self == .medium
    }

    /// Should show pulse animation
    var isPulsing: Bool {
        self == .high || self == .max
    }

    /// Should show orbiting particles
    var hasParticles: Bool {
        self == .max
    }

    /// Glow intensity multiplier
    var glowIntensity: Double {
        switch self {
        case .low: return 0.2
        case .medium: return 0.4
        case .high: return 0.6
        case .max: return 1.0
        }
    }
}
