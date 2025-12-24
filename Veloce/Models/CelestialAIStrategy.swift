//
//  CelestialAIStrategy.swift
//  Veloce
//
//  Rich AI strategy model for CelestialTaskCard
//  Contains comprehensive task guidance with key points, steps, and obstacles
//

import Foundation

// MARK: - Celestial AI Strategy

struct CelestialAIStrategy: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let taskId: UUID

    // Core Strategy Content (2-3 paragraphs)
    let overview: String              // Main strategic approach (2-3 sentences)
    let keyPoints: [String]           // 3-5 bullet points
    let actionableSteps: [String]     // Specific next actions (first one < 2 min)
    let potentialObstacles: [String]? // Warnings/blockers to watch

    // Meta
    let estimatedMinutes: Int?
    let thoughtProcess: String?       // AI reasoning
    let generatedAt: Date

    // Caching TTL (4 hours default)
    var expiresAt: Date

    // MARK: - Computed Properties

    var isExpired: Bool {
        Date() > expiresAt
    }

    /// Formatted strategy for display
    var formattedStrategy: String {
        var result = overview + "\n\n"

        result += "Key Strategy Points:\n"
        result += keyPoints.map { "• \($0)" }.joined(separator: "\n")

        result += "\n\nActionable Steps:\n"
        result += actionableSteps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        if let obstacles = potentialObstacles, !obstacles.isEmpty {
            result += "\n\nWatch Out For:\n"
            result += obstacles.map { "⚠️ \($0)" }.joined(separator: "\n")
        }

        return result
    }

    /// Brief summary for collapsed view
    var briefSummary: String {
        let firstSentence = overview.components(separatedBy: ". ").first ?? overview
        return firstSentence + (firstSentence.hasSuffix(".") ? "" : ".")
    }

    /// Total estimated time including all steps
    var formattedDuration: String? {
        guard let minutes = estimatedMinutes else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        taskId: UUID,
        overview: String,
        keyPoints: [String],
        actionableSteps: [String],
        potentialObstacles: [String]? = nil,
        estimatedMinutes: Int? = nil,
        thoughtProcess: String? = nil,
        generatedAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.overview = overview
        self.keyPoints = keyPoints
        self.actionableSteps = actionableSteps
        self.potentialObstacles = potentialObstacles
        self.estimatedMinutes = estimatedMinutes
        self.thoughtProcess = thoughtProcess
        self.generatedAt = generatedAt
        self.expiresAt = expiresAt ?? Date().addingTimeInterval(4 * 60 * 60) // 4 hours default
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case overview
        case keyPoints = "key_points"
        case actionableSteps = "actionable_steps"
        case potentialObstacles = "potential_obstacles"
        case estimatedMinutes = "estimated_minutes"
        case thoughtProcess = "thought_process"
        case generatedAt = "generated_at"
        case expiresAt = "expires_at"
    }
}

// MARK: - Gemini Response Model

/// Response model for parsing Gemini JSON output
struct CelestialStrategyResponse: Decodable, Sendable {
    let overview: String
    let keyPoints: [String]
    let actionableSteps: [String]
    let potentialObstacles: [String]?
    let estimatedMinutes: Int?
    let thoughtProcess: String?

    enum CodingKeys: String, CodingKey {
        case overview
        case keyPoints = "key_points"
        case actionableSteps = "actionable_steps"
        case potentialObstacles = "potential_obstacles"
        case estimatedMinutes = "estimated_minutes"
        case thoughtProcess = "thought_process"
    }
}

// MARK: - Fallback Strategy Factory

extension CelestialAIStrategy {

    /// Create a fallback strategy based on task type when AI is unavailable
    static func fallback(for task: TaskItem) -> CelestialAIStrategy {
        let taskType = task.taskType

        let overview: String
        let keyPoints: [String]
        let actionableSteps: [String]
        let obstacles: [String]
        let duration: Int

        switch taskType {
        case .create:
            overview = "Creative work like '\(task.title)' requires sustained focus and an uninterrupted environment. Block out distractions and commit to at least 90 minutes of deep work for optimal flow state."
            keyPoints = [
                "Creative tasks need longer uninterrupted blocks",
                "Morning hours often yield best creative output",
                "Silence notifications and close unnecessary tabs",
                "Start with the easiest part to build momentum"
            ]
            actionableSteps = [
                "Open the relevant document/tool (30 seconds)",
                "Write just the first line or make the first mark",
                "Set a 25-minute timer and work without stopping",
                "Take a 5-minute break, then continue"
            ]
            obstacles = [
                "Perfectionism - aim for 'good enough' first draft",
                "Research rabbit holes - set a research time limit"
            ]
            duration = 90

        case .communicate:
            overview = "Communication tasks benefit from clear preparation and focused execution. Prepare your key points before starting to prevent unnecessary back-and-forth."
            keyPoints = [
                "Clarity prevents follow-up clarifications",
                "Batch similar communications together",
                "Use templates for recurring messages",
                "Set specific response windows"
            ]
            actionableSteps = [
                "List 3 key points you need to convey",
                "Draft the core message (under 5 minutes)",
                "Review for clarity and brevity",
                "Send and set a reminder for follow-up if needed"
            ]
            obstacles = [
                "Over-explaining - keep it concise",
                "Waiting for perfect timing - done is better than perfect"
            ]
            duration = 30

        case .consume:
            overview = "Learning tasks like '\(task.title)' require active engagement. Passive reading rarely sticks - take notes and create connections to existing knowledge."
            keyPoints = [
                "Active engagement beats passive consumption",
                "Take brief notes to improve retention",
                "Connect new info to things you already know",
                "Teach someone else to solidify understanding"
            ]
            actionableSteps = [
                "Set a clear learning objective before starting",
                "Read/watch for 20 minutes with focused attention",
                "Write 3 key takeaways in your own words",
                "Identify one immediate application"
            ]
            obstacles = [
                "Information overload - limit scope",
                "Passive consumption - engage actively"
            ]
            duration = 45

        case .coordinate:
            overview = "Administrative tasks are best batched together for efficiency. '\(task.title)' benefits from quick, decisive action rather than overthinking."
            keyPoints = [
                "Batch similar admin tasks together",
                "Set time limits to prevent overthinking",
                "Use checklists for recurring processes",
                "Automate or delegate when possible"
            ]
            actionableSteps = [
                "Gather all necessary information first (2 min)",
                "Make decisions quickly - most are reversible",
                "Complete the task without interruption",
                "Document any follow-up items immediately"
            ]
            obstacles = [
                "Overthinking simple decisions",
                "Context switching - batch similar tasks"
            ]
            duration = 15
        }

        return CelestialAIStrategy(
            taskId: task.id,
            overview: overview,
            keyPoints: keyPoints,
            actionableSteps: actionableSteps,
            potentialObstacles: obstacles,
            estimatedMinutes: duration,
            thoughtProcess: "Pattern-based strategy for \(taskType.displayName) tasks (offline fallback)",
            generatedAt: Date(),
            expiresAt: Date().addingTimeInterval(60 * 60) // 1 hour for fallback
        )
    }
}
