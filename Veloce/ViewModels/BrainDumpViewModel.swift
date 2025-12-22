//
//  BrainDumpViewModel.swift
//  Veloce
//
//  Brain Dump View Model
//  Handles AI-powered extraction of tasks from unstructured thoughts
//

import Foundation
import SwiftData

// MARK: - Brain Dump View Model

@MainActor
@Observable
final class BrainDumpViewModel {
    // MARK: State
    private(set) var state: BrainDumpState = .input
    private(set) var extractedTasks: [ExtractedTask] = []
    private(set) var overallMood: String?
    private(set) var gentleObservation: String?
    private(set) var detectedThemes: [String] = []

    var inputText: String = ""
    var isProcessing: Bool { state == .processing }

    // MARK: Services
    private let gemini = GeminiService.shared
    private let haptics = HapticsService.shared

    // MARK: Context
    private var modelContext: ModelContext?

    // MARK: - Setup

    func setup(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Process Brain Dump

    func processBrainDump() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard gemini.isReady else {
            state = .error("AI not configured. Please add your API key in settings.")
            return
        }

        state = .processing
        haptics.impact()

        do {
            let response = try await extractTasksFromText(text)
            extractedTasks = response.tasks
            overallMood = response.overallMood
            gentleObservation = response.gentleObservation
            detectedThemes = response.detectedThemes ?? []

            // Mark all as selected by default
            for i in extractedTasks.indices {
                extractedTasks[i].isSelected = true
            }

            haptics.taskComplete()
            state = .results
        } catch {
            haptics.error()
            state = .error("Failed to process: \(error.localizedDescription)")
        }
    }

    // MARK: - Extract Tasks

    private func extractTasksFromText(_ text: String) async throws -> BrainDumpResponse {
        let prompt = """
        You are analyzing a brain dump - unstructured thoughts from someone clearing their mental load.

        Your job is to extract actionable tasks and understand the emotional context.

        RULES:
        1. Extract ONLY actionable items (things that can be done)
        2. Write task titles as clear actions (verb + object)
        3. Estimate time REALISTICALLY - add 40% buffer because humans underestimate
        4. Detect priority from urgency cues ("need to", "must", "deadline", "asap" = high)
        5. Note any emotional undertones (stress, overwhelm, avoidance, excitement)
        6. Identify people mentioned who could help
        7. Be warm and observant, not clinical

        INPUT:
        \(text)

        Respond ONLY with valid JSON in this exact format:
        {
          "tasks": [
            {
              "title": "Clear action title",
              "estimatedMinutes": 30,
              "priority": "high|medium|low",
              "category": "work|personal|health|finance|social|other",
              "suggestion": "Optional helpful tip or way to make this easier",
              "relatedPerson": "Name if someone was mentioned",
              "dueContext": "Monday|this week|soon|null"
            }
          ],
          "overall_mood": "Brief description of emotional state detected",
          "gentle_observation": "One caring, insightful observation about what you noticed",
          "detected_themes": ["theme1", "theme2"]
        }

        If no actionable tasks found, return empty tasks array.
        Be empathetic in your observation - you're a supportive friend, not a robot.
        """

        let response = try await gemini.generateText(
            prompt: prompt,
            temperature: 0.3,  // Lower for more consistent JSON
            maxTokens: 2048
        )

        // Parse JSON response
        return try parseResponse(response)
    }

    // MARK: - Parse Response

    private func parseResponse(_ response: String) throws -> BrainDumpResponse {
        // Clean response - remove markdown code blocks if present
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Find JSON bounds
        if let startIndex = cleanedResponse.firstIndex(of: "{"),
           let endIndex = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[startIndex...endIndex])
        }

        guard let data = cleanedResponse.data(using: .utf8) else {
            throw BrainDumpError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(BrainDumpResponse.self, from: data)
    }

    // MARK: - Task Selection

    func toggleTaskSelection(_ task: ExtractedTask) {
        if let index = extractedTasks.firstIndex(where: { $0.id == task.id }) {
            extractedTasks[index].isSelected.toggle()
            haptics.selectionFeedback()
        }
    }

    func selectAllTasks() {
        for i in extractedTasks.indices {
            extractedTasks[i].isSelected = true
        }
        haptics.selectionFeedback()
    }

    func deselectAllTasks() {
        for i in extractedTasks.indices {
            extractedTasks[i].isSelected = false
        }
        haptics.selectionFeedback()
    }

    // MARK: - Add Tasks

    func addSelectedTasksToList() async -> Int {
        guard let context = modelContext else { return 0 }

        let selectedTasks = extractedTasks.filter { $0.isSelected }
        var addedCount = 0

        for extracted in selectedTasks {
            let task = TaskItem(title: extracted.title)
            task.starRating = extracted.priority.starRating
            task.estimatedMinutes = extracted.estimatedMinutes
            task.category = extracted.category

            // Set due date if context provided
            if let dueContext = extracted.dueContext {
                task.scheduledTime = parseDueContext(dueContext)
            }

            context.insert(task)
            addedCount += 1
        }

        do {
            try context.save()
            haptics.celebration()
        } catch {
            print("Failed to save tasks: \(error)")
        }

        return addedCount
    }

    // MARK: - Parse Due Context

    private func parseDueContext(_ context: String) -> Date? {
        let lowercased = context.lowercased()
        let calendar = Calendar.current
        let now = Date()

        if lowercased.contains("today") {
            return now
        } else if lowercased.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        } else if lowercased.contains("monday") {
            return nextWeekday(.monday)
        } else if lowercased.contains("tuesday") {
            return nextWeekday(.tuesday)
        } else if lowercased.contains("wednesday") {
            return nextWeekday(.wednesday)
        } else if lowercased.contains("thursday") {
            return nextWeekday(.thursday)
        } else if lowercased.contains("friday") {
            return nextWeekday(.friday)
        } else if lowercased.contains("this week") {
            return calendar.date(byAdding: .day, value: 3, to: now)
        } else if lowercased.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        } else if lowercased.contains("soon") {
            return calendar.date(byAdding: .day, value: 2, to: now)
        }

        return nil
    }

    private func nextWeekday(_ weekday: Weekday) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = weekday.rawValue

        return calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        )
    }

    // MARK: - Reset

    func reset() {
        state = .input
        inputText = ""
        extractedTasks = []
        overallMood = nil
        gentleObservation = nil
        detectedThemes = []
    }

    func goBackToInput() {
        state = .input
        // Keep the text so user can edit and reprocess
    }

    // MARK: - Computed Properties

    var selectedCount: Int {
        extractedTasks.filter { $0.isSelected }.count
    }

    var totalEstimatedMinutes: Int {
        extractedTasks.filter { $0.isSelected }.reduce(0) { $0 + $1.estimatedMinutes }
    }

    var formattedEstimatedTime: String {
        let minutes = totalEstimatedMinutes
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

// MARK: - Weekday Enum

private enum Weekday: Int {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

// MARK: - Brain Dump Error

enum BrainDumpError: LocalizedError {
    case invalidResponse
    case noTasks
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Could not understand AI response"
        case .noTasks:
            return "No actionable tasks found"
        case .processingFailed:
            return "Processing failed"
        }
    }
}
