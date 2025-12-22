//
//  ExtractedTask.swift
//  Veloce
//
//  Extracted Task Model
//  Represents a task extracted from brain dump by AI
//

import Foundation

// MARK: - Extracted Task

struct ExtractedTask: Identifiable, Codable, Sendable {
    let id: UUID
    var title: String
    var estimatedMinutes: Int
    var priority: ExtractedPriority
    var category: String?
    var suggestion: String?
    var relatedPerson: String?
    var dueContext: String? // "Monday", "this week", "soon"

    // UI State (not from AI)
    var isSelected: Bool = true

    init(
        id: UUID = UUID(),
        title: String,
        estimatedMinutes: Int = 30,
        priority: ExtractedPriority = .medium,
        category: String? = nil,
        suggestion: String? = nil,
        relatedPerson: String? = nil,
        dueContext: String? = nil
    ) {
        self.id = id
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.priority = priority
        self.category = category
        self.suggestion = suggestion
        self.relatedPerson = relatedPerson
        self.dueContext = dueContext
    }

    enum CodingKeys: String, CodingKey {
        case id, title, estimatedMinutes, priority, category
        case suggestion, relatedPerson, dueContext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        estimatedMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedMinutes) ?? 30
        priority = try container.decodeIfPresent(ExtractedPriority.self, forKey: .priority) ?? .medium
        category = try container.decodeIfPresent(String.self, forKey: .category)
        suggestion = try container.decodeIfPresent(String.self, forKey: .suggestion)
        relatedPerson = try container.decodeIfPresent(String.self, forKey: .relatedPerson)
        dueContext = try container.decodeIfPresent(String.self, forKey: .dueContext)
        isSelected = true
    }
}

// MARK: - Extracted Priority

enum ExtractedPriority: String, Codable, Sendable {
    case high
    case medium
    case low

    var starRating: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }

    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "yellow"
        case .low: return "green"
        }
    }
}

// MARK: - Brain Dump Response

struct BrainDumpResponse: Codable, Sendable {
    let tasks: [ExtractedTask]
    let overallMood: String?
    let gentleObservation: String?
    let detectedThemes: [String]?

    enum CodingKeys: String, CodingKey {
        case tasks
        case overallMood = "overall_mood"
        case gentleObservation = "gentle_observation"
        case detectedThemes = "detected_themes"
    }
}

// MARK: - Brain Dump State

enum BrainDumpState: Equatable {
    case input
    case processing
    case results
    case error(String)

    static func == (lhs: BrainDumpState, rhs: BrainDumpState) -> Bool {
        switch (lhs, rhs) {
        case (.input, .input): return true
        case (.processing, .processing): return true
        case (.results, .results): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}
