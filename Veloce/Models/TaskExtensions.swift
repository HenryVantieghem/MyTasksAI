//
//  TaskExtensions.swift
//  Veloce
//
//  AI Productivity Extensions for TaskItem
//  Adds cognitive productivity features inspired by Sam Altman's system
//

import Foundation

// MARK: - TaskItem AI Extensions

/// Extended TaskItem properties for the cognitive productivity system
/// These are stored in separate related tables and loaded on-demand
struct TaskAIEnhancements: Codable, Sendable {
    // AI-generated content
    var aiGeneratedPrompt: String?      // Ready-to-use AI prompt for task
    var aiThoughtProcess: String?       // AI's reasoning explanation
    var contextNotes: String?           // User-provided context for AI

    // Related collections (loaded separately)
    var subTasks: [SubTask]
    var youtubeResources: [YouTubeResource]
    var reflections: [TaskReflection]

    // Scheduling
    var scheduleSuggestion: ScheduleSuggestion?

    // Completion tracking
    var actualMinutes: Int?             // Real time spent
    var completedAt: Date?              // When task was completed

    // Priority (Sam Altman style)
    var starRating: Int                 // 1-3 stars (* ** ***)

    init(
        aiGeneratedPrompt: String? = nil,
        aiThoughtProcess: String? = nil,
        contextNotes: String? = nil,
        subTasks: [SubTask] = [],
        youtubeResources: [YouTubeResource] = [],
        reflections: [TaskReflection] = [],
        scheduleSuggestion: ScheduleSuggestion? = nil,
        actualMinutes: Int? = nil,
        completedAt: Date? = nil,
        starRating: Int = 1
    ) {
        self.aiGeneratedPrompt = aiGeneratedPrompt
        self.aiThoughtProcess = aiThoughtProcess
        self.contextNotes = contextNotes
        self.subTasks = subTasks
        self.youtubeResources = youtubeResources
        self.reflections = reflections
        self.scheduleSuggestion = scheduleSuggestion
        self.actualMinutes = actualMinutes
        self.completedAt = completedAt
        self.starRating = starRating
    }
}

// MARK: - Supabase Coding Keys

extension TaskAIEnhancements {
    enum CodingKeys: String, CodingKey {
        case aiGeneratedPrompt = "ai_generated_prompt"
        case aiThoughtProcess = "ai_thought_process"
        case contextNotes = "context_notes"
        case subTasks = "sub_tasks"
        case youtubeResources = "youtube_resources"
        case reflections
        case scheduleSuggestion = "schedule_suggestion"
        case actualMinutes = "actual_minutes"
        case completedAt = "completed_at"
        case starRating = "star_rating"
    }
}

// MARK: - Task Priority (Sam Altman Style)

/// Sam Altman's star priority system
enum TaskPriority: Int, Codable, Sendable, CaseIterable {
    case low = 1      // *
    case medium = 2   // **
    case high = 3     // ***

    var stars: String {
        String(repeating: "*", count: rawValue)
    }

    var displayStars: String {
        switch self {
        case .low: return "★☆☆"
        case .medium: return "★★☆"
        case .high: return "★★★"
        }
    }

    var label: String {
        switch self {
        case .low: return "Low Priority"
        case .medium: return "Medium Priority"
        case .high: return "High Priority"
        }
    }

    /// Parse priority from text prefix
    /// - Returns: Tuple of (priority, cleanedText)
    static func parse(from text: String) -> (priority: TaskPriority, cleanedText: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("***") {
            return (.high, String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces))
        } else if trimmed.hasPrefix("**") {
            return (.medium, String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces))
        } else if trimmed.hasPrefix("*") {
            return (.low, String(trimmed.dropFirst(1)).trimmingCharacters(in: .whitespaces))
        }

        // Default to medium priority (normal task)
        return (.medium, trimmed)
    }
}

// MARK: - Recurring Type

/// Task recurring frequency
enum RecurringType: String, Codable, Sendable, CaseIterable {
    case once = "once"
    case daily = "daily"
    case weekly = "weekly"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .once: return "Once"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .once: return "1.circle"
        case .daily: return "calendar.day.timeline.left"
        case .weekly: return "calendar"
        case .custom: return "gearshape"
        }
    }
}

// MARK: - Brain Dump Parser

/// Parses multi-line brain dump input into tasks
struct BrainDumpParser {

    /// Parsed task from brain dump
    struct ParsedTask: Sendable {
        let title: String
        let priority: TaskPriority
        let lineNumber: Int
    }

    /// Parse multi-line text into tasks (Sam Altman style)
    /// Each line becomes a task, * prefix indicates priority
    static func parse(_ text: String) -> [ParsedTask] {
        let lines = text.components(separatedBy: .newlines)
        var tasks: [ParsedTask] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines
            guard !trimmed.isEmpty else { continue }

            // Parse priority from stars
            let (priority, cleanedTitle) = TaskPriority.parse(from: trimmed)

            // Skip if no actual content after removing stars
            guard !cleanedTitle.isEmpty else { continue }

            tasks.append(ParsedTask(
                title: cleanedTitle,
                priority: priority,
                lineNumber: index + 1
            ))
        }

        return tasks
    }
}

// MARK: - AI Prompt Template

/// Template for generating AI prompts for tasks
struct AIPromptTemplate {

    /// Generate a comprehensive prompt for task completion
    static func generate(
        taskTitle: String,
        contextNotes: String?,
        estimatedMinutes: Int?,
        priority: TaskPriority,
        previousLearnings: [String]? = nil
    ) -> String {
        var prompt = """
        I need to complete: "\(taskTitle)"

        """

        // Add context if provided
        if let context = contextNotes, !context.isEmpty {
            prompt += """

            Context:
            \(context)

            """
        }

        // Add task details
        prompt += """

        Details:
        - Priority: \(priority.label)
        """

        if let minutes = estimatedMinutes {
            prompt += "\n- Estimated time: \(minutes) minutes"
        }

        // Add learnings from similar past tasks
        if let learnings = previousLearnings, !learnings.isEmpty {
            prompt += "\n\nLearnings from similar tasks:"
            for learning in learnings {
                prompt += "\n- \(learning)"
            }
        }

        // Add request
        prompt += """


        Please help me:
        1. Break this into 3-5 actionable steps
        2. Identify potential blockers or challenges
        3. Suggest the most efficient approach
        4. Recommend resources if helpful

        Keep your response practical and actionable.
        """

        return prompt
    }
}

// MARK: - Time Formatting Helpers

extension Int {
    /// Format minutes as readable duration
    var formattedDuration: String {
        if self >= 60 {
            let hours = self / 60
            let minutes = self % 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(self)m"
    }
}

// MARK: - SubTask Progress Helpers

extension Array where Element == SubTask {
    /// Formatted progress string with percentage
    var progressDisplay: String {
        let completed = filter { $0.status == .completed }.count
        let percentage = isEmpty ? 0 : Int((Double(completed) / Double(count)) * 100)
        return "\(completed)/\(count) (\(percentage)%)"
    }

    /// Time remaining for incomplete tasks
    var formattedRemainingTime: String? {
        let remaining = remainingMinutes
        guard remaining > 0 else { return nil }
        return remaining.formattedDuration
    }
}
