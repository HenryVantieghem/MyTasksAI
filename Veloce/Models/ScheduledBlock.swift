//
//  ScheduledBlock.swift
//  Veloce
//
//  Scheduled Block Model - AI-suggested time blocks
//  Part of AI Scheduling feature
//

import Foundation
import SwiftUI

// MARK: - Block Type
enum BlockType: String, Codable, Sendable, CaseIterable {
    case task
    case focus
    case `break`
    case buffer

    var displayName: String {
        switch self {
        case .task: return "Task"
        case .focus: return "Focus Time"
        case .break: return "Break"
        case .buffer: return "Buffer"
        }
    }

    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .focus: return "brain.head.profile"
        case .break: return "cup.and.saucer"
        case .buffer: return "clock.arrow.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .task: return Theme.Colors.aiPurple
        case .focus: return Theme.Colors.aiBlue
        case .break: return .green
        case .buffer: return .gray
        }
    }
}

// MARK: - Block Status
enum BlockStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case accepted
    case declined
    case completed
    case missed

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Scheduled"
        case .declined: return "Declined"
        case .completed: return "Completed"
        case .missed: return "Missed"
        }
    }
}

// MARK: - Scheduled Block
struct ScheduledBlock: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let userId: UUID
    var taskId: UUID?
    var startTime: Date
    var endTime: Date
    let blockType: BlockType
    var isAiSuggested: Bool
    var confidenceScore: Float
    var status: BlockStatus
    var calendarEventId: String?
    let createdAt: Date?
    var updatedAt: Date?

    // Joined task data
    var task: TaskItem?

    var duration: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var confidencePercentage: Int {
        Int(confidenceScore * 100)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case taskId = "task_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case blockType = "block_type"
        case isAiSuggested = "is_ai_suggested"
        case confidenceScore = "confidence_score"
        case status
        case calendarEventId = "calendar_event_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ScheduledBlock, rhs: ScheduledBlock) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Scheduling Preferences
struct SchedulingPreferences: Codable, Sendable {
    var autoSchedule: Bool
    var bufferMinutes: Int
    var focusHoursStart: Int  // 9 = 9 AM
    var focusHoursEnd: Int    // 17 = 5 PM
    var maxTasksPerDay: Int
    var preferMorningForHardTasks: Bool
    var pomodoroEnabled: Bool
    var pomodoroDuration: Int
    var breakDuration: Int

    static var `default`: SchedulingPreferences {
        SchedulingPreferences(
            autoSchedule: false,
            bufferMinutes: 15,
            focusHoursStart: 9,
            focusHoursEnd: 17,
            maxTasksPerDay: 8,
            preferMorningForHardTasks: true,
            pomodoroEnabled: false,
            pomodoroDuration: 25,
            breakDuration: 5
        )
    }

    enum CodingKeys: String, CodingKey {
        case autoSchedule = "auto_schedule"
        case bufferMinutes = "buffer_minutes"
        case focusHoursStart = "focus_hours_start"
        case focusHoursEnd = "focus_hours_end"
        case maxTasksPerDay = "max_tasks_per_day"
        case preferMorningForHardTasks = "prefer_morning_for_hard_tasks"
        case pomodoroEnabled = "pomodoro_enabled"
        case pomodoroDuration = "pomodoro_duration"
        case breakDuration = "break_duration"
    }
}

// MARK: - Scheduling Feedback
struct SchedulingFeedback: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let blockId: UUID
    let feedbackType: FeedbackType
    var originalTime: Date?
    var newTime: Date?
    var reason: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case blockId = "block_id"
        case feedbackType = "feedback_type"
        case originalTime = "original_time"
        case newTime = "new_time"
        case reason
        case createdAt = "created_at"
    }
}

enum FeedbackType: String, Codable, Sendable {
    case accepted
    case declined
    case rescheduled
    case completedEarly = "completed_early"
    case completedLate = "completed_late"
    case notStarted = "not_started"
}

// MARK: - Create Block Request
struct CreateBlockRequest: Codable, Sendable {
    let userId: UUID
    let taskId: UUID?
    let startTime: Date
    let endTime: Date
    let blockType: String
    let isAiSuggested: Bool
    let confidenceScore: Float
    let status: String

    init(userId: UUID, taskId: UUID? = nil, startTime: Date, endTime: Date, blockType: BlockType, isAiSuggested: Bool = false, confidence: Float = 0) {
        self.userId = userId
        self.taskId = taskId
        self.startTime = startTime
        self.endTime = endTime
        self.blockType = blockType.rawValue
        self.isAiSuggested = isAiSuggested
        self.confidenceScore = confidence
        self.status = "pending"
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case taskId = "task_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case blockType = "block_type"
        case isAiSuggested = "is_ai_suggested"
        case confidenceScore = "confidence_score"
        case status
    }
}

// MARK: - AI Schedule Suggestion
struct ScheduleSuggestion: Codable, Sendable {
    let taskId: UUID
    let suggestedStart: Date
    let suggestedEnd: Date
    let confidence: Float
    let reasoning: String?
}
