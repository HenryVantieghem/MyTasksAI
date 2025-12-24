//
//  AIAdvice.swift
//  MyTasksAI
//
//  AI Advice Model
//  Represents AI-generated advice and insights for tasks
//

import Foundation
import SwiftUI

// MARK: - AI Advice
struct AIAdvice: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    let taskId: UUID
    let advice: String
    let priority: String?
    let estimatedMinutes: Int?
    let sources: [String]?
    let thoughtProcess: String?
    let generatedPrompt: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        taskId: UUID,
        advice: String,
        priority: String? = nil,
        estimatedMinutes: Int? = nil,
        sources: [String]? = nil,
        thoughtProcess: String? = nil,
        generatedPrompt: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.taskId = taskId
        self.advice = advice
        self.priority = priority
        self.estimatedMinutes = estimatedMinutes
        self.sources = sources
        self.thoughtProcess = thoughtProcess
        self.generatedPrompt = generatedPrompt
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties
extension AIAdvice {
    /// Priority as enum
    var priorityEnum: TaskPriority? {
        guard let priority else { return nil }
        switch priority.lowercased() {
        case "low": return .low
        case "medium": return .medium
        case "high": return .high
        default: return nil
        }
    }

    /// Formatted estimate
    var estimatedTimeFormatted: String? {
        guard let minutes = estimatedMinutes else { return nil }
        return minutes.formattedDuration
    }

    /// Has sources
    var hasSources: Bool {
        guard let sources else { return false }
        return !sources.isEmpty
    }

    /// Has thought process
    var hasThoughtProcess: Bool {
        guard let thoughtProcess else { return false }
        return !thoughtProcess.isEmpty
    }
}

// MARK: - AI Response
/// Response structure from Gemini API
struct AIResponse: Codable, Sendable {
    let advice: String
    let priority: String?
    let estimatedMinutes: Int?
    let sources: [String]?
    let thoughtProcess: String?
    let subTasks: [AISubTask]?
    let youtubeResources: [AIYouTubeResource]?
    let scheduleSuggestion: AIScheduleSuggestion?

    enum CodingKeys: String, CodingKey {
        case advice
        case priority
        case estimatedMinutes = "estimated_minutes"
        case sources
        case thoughtProcess = "thought_process"
        case subTasks = "sub_tasks"
        case youtubeResources = "youtube_resources"
        case scheduleSuggestion = "schedule_suggestion"
    }
}

// MARK: - AI Sub Task
struct AISubTask: Codable, Sendable {
    let title: String
    let estimatedMinutes: Int?
    let reasoning: String?

    enum CodingKeys: String, CodingKey {
        case title
        case estimatedMinutes = "estimated_minutes"
        case reasoning
    }
}

// MARK: - AI YouTube Resource
struct AIYouTubeResource: Codable, Sendable {
    let searchQuery: String
    let relevanceScore: Double?
    let reasoning: String?

    enum CodingKeys: String, CodingKey {
        case searchQuery = "search_query"
        case relevanceScore = "relevance_score"
        case reasoning
    }
}

// MARK: - AI Schedule Suggestion
struct AIScheduleSuggestion: Codable, Sendable {
    let suggestedTimeOfDay: String?
    let reasoning: String?
    let energyLevel: String?
    let optimalDuration: Int?

    enum CodingKeys: String, CodingKey {
        case suggestedTimeOfDay = "suggested_time_of_day"
        case reasoning
        case energyLevel = "energy_level"
        case optimalDuration = "optimal_duration"
    }
}

// MARK: - AI Processing State
enum AIProcessingState: Equatable, Sendable {
    case idle
    case queued
    case processing
    case completed(AIAdvice)
    case failed(String)

    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }

    var advice: AIAdvice? {
        if case .completed(let advice) = self { return advice }
        return nil
    }

    var error: String? {
        if case .failed(let error) = self { return error }
        return nil
    }

    var statusText: String {
        switch self {
        case .idle: return ""
        case .queued: return "Queued"
        case .processing: return "Processing"
        case .completed: return "Complete"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Gemini Request/Response Models
struct GeminiRequest: Codable, Sendable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?

    enum CodingKeys: String, CodingKey {
        case contents
        case generationConfig = "generation_config"
    }
}

struct GeminiContent: Codable, Sendable {
    let parts: [GeminiPart]
    let role: String?
}

struct GeminiPart: Codable, Sendable {
    let text: String
}

struct GeminiGenerationConfig: Codable, Sendable {
    let temperature: Double?
    let maxOutputTokens: Int?
    let responseMimeType: String?

    enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens = "max_output_tokens"
        case responseMimeType = "response_mime_type"
    }
}

struct GeminiResponse: Codable, Sendable {
    let candidates: [GeminiCandidate]?
    let error: GeminiAPIError?
}

struct GeminiCandidate: Codable, Sendable {
    let content: GeminiContent?
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case finishReason = "finish_reason"
    }
}

/// Represents error response from Gemini API (distinct from PerplexityError enum for app errors)
struct GeminiAPIError: Codable, Sendable {
    let code: Int?
    let message: String?
    let status: String?
}
