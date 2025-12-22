//
//  PomodoroModels.swift
//  Veloce
//
//  Shared Pomodoro Models
//  Used by main app and widget extension
//

import Foundation
import ActivityKit

// MARK: - Pomodoro State

public enum PomodoroState: String, Codable, Sendable, Hashable {
    case idle
    case running
    case paused
    case breakTime
    case completed
}

// MARK: - Pomodoro Session

public struct PomodoroSession: Codable, Sendable {
    public let id: UUID
    public let taskId: UUID?
    public let taskTitle: String
    public let totalSeconds: Int
    public var remainingSeconds: Int
    public var state: PomodoroState
    public let startedAt: Date
    public var pausedAt: Date?
    public var sessionsCompleted: Int

    public init(
        id: UUID = UUID(),
        taskId: UUID? = nil,
        taskTitle: String,
        totalSeconds: Int,
        remainingSeconds: Int,
        state: PomodoroState,
        startedAt: Date = Date(),
        pausedAt: Date? = nil,
        sessionsCompleted: Int = 0
    ) {
        self.id = id
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.totalSeconds = totalSeconds
        self.remainingSeconds = remainingSeconds
        self.state = state
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.sessionsCompleted = sessionsCompleted
    }

    public var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    public var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    public var endTime: Date {
        Date().addingTimeInterval(TimeInterval(remainingSeconds))
    }
}

// MARK: - Live Activity Attributes

public struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var remainingSeconds: Int
        public var state: PomodoroState
        public var endTime: Date

        public init(remainingSeconds: Int, state: PomodoroState, endTime: Date) {
            self.remainingSeconds = remainingSeconds
            self.state = state
            self.endTime = endTime
        }

        public var formattedTime: String {
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    public var taskTitle: String
    public var totalSeconds: Int

    public init(taskTitle: String, totalSeconds: Int) {
        self.taskTitle = taskTitle
        self.totalSeconds = totalSeconds
    }
}
