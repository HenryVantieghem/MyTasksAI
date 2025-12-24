//
//  GeminiService+CognitiveProductivity.swift
//  Veloce
//
//  Extension for cognitive productivity AI features
//  Sub-task breakdown, YouTube resources, schedule suggestions, reflections
//

import Foundation

// MARK: - Cognitive Productivity Extension

extension GeminiService {

    // MARK: - Sub-Task Breakdown (Claude Code Style)

    /// Generates AI-powered sub-task breakdown for a given task
    /// - Parameters:
    ///   - taskTitle: The main task title
    ///   - context: Optional context notes from user
    ///   - estimatedMinutes: Optional estimated duration
    /// - Returns: Array of SubTask objects with AI reasoning
    func generateSubTaskBreakdown(
        taskTitle: String,
        context: String? = nil,
        estimatedMinutes: Int? = nil
    ) async throws -> (subTasks: [SubTask], thoughtProcess: String) {
        let contextSection = context.map { "Context: \($0)" } ?? ""
        let timeSection = estimatedMinutes.map { "Estimated time: \($0) minutes" } ?? ""

        let prompt = """
        You are a productivity expert. Break down this task into 3-7 actionable sub-tasks.

        Task: \(taskTitle)
        \(contextSection)
        \(timeSection)

        For each sub-task, provide:
        1. A clear, actionable title (start with a verb)
        2. Estimated minutes (realistic, 5-60 min each)
        3. Brief AI reasoning for why this step is needed

        Also provide your thought process explaining:
        - Why you structured the breakdown this way
        - What patterns or best practices you applied
        - Any dependencies between steps

        Respond in this JSON format:
        {
            "subTasks": [
                {
                    "title": "Step title",
                    "estimatedMinutes": 15,
                    "aiReasoning": "Why this step matters"
                }
            ],
            "thoughtProcess": "Explanation of the breakdown approach..."
        }
        """

        let response = try await generateText(prompt: prompt)

        // Parse JSON response
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let subTasksArray = json["subTasks"] as? [[String: Any]],
              let thoughtProcess = json["thoughtProcess"] as? String else {
            // Fallback to pattern-based generation
            return generateFallbackBreakdown(for: taskTitle, estimatedMinutes: estimatedMinutes)
        }

        var subTasks: [SubTask] = []
        for (index, item) in subTasksArray.enumerated() {
            if let title = item["title"] as? String,
               let minutes = item["estimatedMinutes"] as? Int {
                let reasoning = item["aiReasoning"] as? String
                subTasks.append(SubTask(
                    title: title,
                    estimatedMinutes: minutes,
                    status: .pending,
                    orderIndex: index + 1,
                    aiReasoning: reasoning
                ))
            }
        }

        return (subTasks, thoughtProcess)
    }

    /// Fallback breakdown when AI parsing fails
    private func generateFallbackBreakdown(
        for taskTitle: String,
        estimatedMinutes: Int?
    ) -> (subTasks: [SubTask], thoughtProcess: String) {
        let total = estimatedMinutes ?? 60
        let taskWords = taskTitle.lowercased()

        if taskWords.contains("report") || taskWords.contains("presentation") || taskWords.contains("document") {
            return (
                [
                    SubTask(title: "Research and gather data", estimatedMinutes: max(10, total / 5), status: .pending, orderIndex: 1, aiReasoning: "Start with data collection to inform content"),
                    SubTask(title: "Create outline/structure", estimatedMinutes: max(10, total / 6), status: .pending, orderIndex: 2, aiReasoning: "Structure before detailed content"),
                    SubTask(title: "Write main content", estimatedMinutes: max(15, total / 3), status: .pending, orderIndex: 3, aiReasoning: "Core work requiring focused attention"),
                    SubTask(title: "Add visuals/formatting", estimatedMinutes: max(10, total / 5), status: .pending, orderIndex: 4, aiReasoning: "Visual polish improves impact"),
                    SubTask(title: "Review and finalize", estimatedMinutes: max(10, total / 6), status: .pending, orderIndex: 5, aiReasoning: "Quality check before completion")
                ],
                "Recognized this as a document creation task. Applied the research → outline → content → visuals → review pattern commonly used in professional writing."
            )
        } else if taskWords.contains("meeting") || taskWords.contains("call") || taskWords.contains("presentation") {
            return (
                [
                    SubTask(title: "Prepare agenda points", estimatedMinutes: 10, status: .pending, orderIndex: 1, aiReasoning: "Clear agenda ensures productive meeting"),
                    SubTask(title: "Gather relevant materials", estimatedMinutes: 15, status: .pending, orderIndex: 2, aiReasoning: "Being prepared builds confidence"),
                    SubTask(title: "Review attendee context", estimatedMinutes: 5, status: .pending, orderIndex: 3, aiReasoning: "Understanding audience improves communication"),
                    SubTask(title: "Conduct meeting/call", estimatedMinutes: max(30, total / 2), status: .pending, orderIndex: 4, aiReasoning: "Main activity")
                ],
                "Identified as a meeting/collaboration task. Breaking into preparation and execution phases for maximum effectiveness."
            )
        } else if taskWords.contains("code") || taskWords.contains("develop") || taskWords.contains("build") || taskWords.contains("fix") {
            return (
                [
                    SubTask(title: "Understand requirements", estimatedMinutes: max(10, total / 6), status: .pending, orderIndex: 1, aiReasoning: "Clarity prevents rework"),
                    SubTask(title: "Plan implementation approach", estimatedMinutes: max(10, total / 6), status: .pending, orderIndex: 2, aiReasoning: "Design before code"),
                    SubTask(title: "Implement core functionality", estimatedMinutes: max(20, total / 3), status: .pending, orderIndex: 3, aiReasoning: "Main development work"),
                    SubTask(title: "Test and debug", estimatedMinutes: max(15, total / 4), status: .pending, orderIndex: 4, aiReasoning: "Quality assurance"),
                    SubTask(title: "Review and refactor", estimatedMinutes: max(10, total / 6), status: .pending, orderIndex: 5, aiReasoning: "Clean code for maintainability")
                ],
                "Identified as a development task. Applied the understand → plan → implement → test → refine workflow common in software engineering."
            )
        } else {
            return (
                [
                    SubTask(title: "Define clear objectives", estimatedMinutes: max(5, total / 8), status: .pending, orderIndex: 1, aiReasoning: "Clarity on goals improves focus"),
                    SubTask(title: "Gather resources/information", estimatedMinutes: max(10, total / 5), status: .pending, orderIndex: 2, aiReasoning: "Preparation enables efficiency"),
                    SubTask(title: "Execute main work", estimatedMinutes: max(20, total / 2), status: .pending, orderIndex: 3, aiReasoning: "Core activity"),
                    SubTask(title: "Review and finalize", estimatedMinutes: max(10, total / 5), status: .pending, orderIndex: 4, aiReasoning: "Quality check before marking complete")
                ],
                "Created a general task breakdown following the define → prepare → execute → review pattern that applies to most productivity work."
            )
        }
    }

    // MARK: - Thought Process Generation

    /// Generates AI reasoning explanation for task breakdown
    func generateThoughtProcess(
        taskTitle: String,
        subTasks: [SubTask],
        estimatedMinutes: Int?
    ) async throws -> String {
        let subTaskList = subTasks.enumerated().map { "\($0.offset + 1). \($0.element.title) (\($0.element.estimatedMinutes ?? 0) min)" }.joined(separator: "\n")

        let prompt = """
        Explain your reasoning for breaking down this task:

        Task: \(taskTitle)
        Total estimated time: \(estimatedMinutes ?? 0) minutes

        Sub-tasks:
        \(subTaskList)

        Explain in 2-3 sentences:
        1. Why this structure makes sense
        2. What productivity principles you applied
        3. Any patterns you recognized from similar tasks

        Keep it conversational and helpful, like a productivity coach.
        """

        return try await generateText(prompt: prompt)
    }

    // MARK: - YouTube Search Queries (Smart Hybrid Approach)

    /// Generate smart YouTube search queries for CelestialTaskCard
    /// Uses AI to create relevant search queries that deep-link to YouTube search results
    func generateYouTubeSearchQueries(
        taskTitle: String,
        context: String? = nil,
        maxQueries: Int = 3
    ) async throws -> [YouTubeSearchResource] {
        let contextSection = context.map { "Additional context: \($0)" } ?? ""

        let prompt = """
        Generate \(maxQueries) YouTube search queries that would help someone complete this task.

        TASK: "\(taskTitle)"
        \(contextSection)

        For each search query:
        1. Create a specific, well-crafted YouTube search query (what someone would type)
        2. A short display title for the UI (2-4 words)
        3. Brief reasoning for why this search would help
        4. Relevance score 0.0-1.0

        Respond in this exact JSON format:
        {
            "queries": [
                {
                    "search_query": "how to write project proposal step by step tutorial",
                    "display_title": "Proposal Writing",
                    "reasoning": "Covers structure and key components",
                    "relevance_score": 0.9
                }
            ]
        }

        IMPORTANT:
        - Search queries should be specific and actionable
        - Include tutorial-style terms (how to, guide, tips, tutorial)
        - Order by relevance (most helpful first)
        - Focus on skill-building, not entertainment
        - Think about what a beginner would need to learn
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.5)

        guard let data = jsonResponse.data(using: .utf8) else {
            // Fallback to pattern-based resources
            return YouTubeSearchResource.fallbacks(for: taskTitle)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let response = try decoder.decode(YouTubeSearchQueryResponse.self, from: data)

            return response.queries.prefix(maxQueries).map { item in
                YouTubeSearchResource(
                    searchQuery: item.searchQuery,
                    displayTitle: item.displayTitle,
                    reasoning: item.reasoning,
                    relevanceScore: item.relevanceScore,
                    createdAt: Date()
                )
            }
        } catch {
            // Fallback to pattern-based resources
            return YouTubeSearchResource.fallbacks(for: taskTitle)
        }
    }

    // MARK: - YouTube Learning Resources (Legacy)

    /// Finds relevant YouTube tutorials for a task (legacy method)
    @available(*, deprecated, message: "Use generateYouTubeSearchQueries instead")
    func findYouTubeResources(
        taskTitle: String,
        context: String? = nil,
        maxResults: Int = 3
    ) async throws -> [YouTubeResource] {
        let contextSection = context.map { "Additional context: \($0)" } ?? ""

        let prompt = """
        Find YouTube tutorial recommendations for someone who needs to: \(taskTitle)
        \(contextSection)

        Suggest \(maxResults) specific video topics that would help. For each:
        1. A realistic video title
        2. The type of channel that would make this (e.g., "TED-Ed", "Skillshare", industry expert)
        3. Estimated duration in seconds (typical tutorials are 5-20 minutes)
        4. Relevance score 0.0-1.0

        Respond in JSON format:
        {
            "videos": [
                {
                    "title": "Video title",
                    "channelName": "Channel Name",
                    "durationSeconds": 720,
                    "relevanceScore": 0.9
                }
            ]
        }
        """

        let response = try await generateText(prompt: prompt)

        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let videos = json["videos"] as? [[String: Any]] else {
            return []
        }

        var resources: [YouTubeResource] = []
        for video in videos.prefix(maxResults) {
            if let title = video["title"] as? String {
                resources.append(YouTubeResource(
                    videoId: UUID().uuidString, // Placeholder - would be real YouTube ID
                    title: title,
                    channelName: video["channelName"] as? String,
                    durationSeconds: video["durationSeconds"] as? Int,
                    viewCount: nil,
                    thumbnailURL: nil,
                    relevanceScore: video["relevanceScore"] as? Double
                ))
            }
        }

        return resources
    }

    // MARK: - Smart Schedule Suggestion

    /// Generates optimal schedule suggestion based on user patterns and calendar
    func generateScheduleSuggestion(
        taskTitle: String,
        estimatedMinutes: Int?,
        freeSlots: [DateInterval],
        userPatterns: UserProductivityPatterns?
    ) async throws -> ScheduleSuggestion {
        let duration = estimatedMinutes ?? 30
        let slotsDescription = freeSlots.prefix(5).map { interval in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: interval.start)
        }.joined(separator: ", ")

        let patternsDescription: String
        if let patterns = userPatterns,
           let energyPatterns = patterns.energyPatterns {
            let sorted = energyPatterns.sorted { $0.value > $1.value }
            patternsDescription = "User is most productive during: \(sorted.first?.key ?? "morning")"
        } else {
            patternsDescription = "No user productivity patterns available yet"
        }

        let prompt = """
        Suggest the best time to schedule this task:

        Task: \(taskTitle)
        Duration: \(duration) minutes
        Available slots: \(slotsDescription)
        User patterns: \(patternsDescription)

        Consider:
        1. Task complexity (higher focus tasks → morning)
        2. Duration (longer tasks → uninterrupted slots)
        3. User's energy patterns

        Respond with JSON:
        {
            "suggestedSlotIndex": 0,
            "reason": "Why this time is optimal",
            "confidence": 0.85,
            "alternativeSlotIndices": [1, 2]
        }
        """

        let response = try await generateText(prompt: prompt)

        // Parse or use defaults
        let defaultSlot = freeSlots.first?.start ?? Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        if let data = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            let slotIndex = json["suggestedSlotIndex"] as? Int ?? 0
            let reason = json["reason"] as? String ?? "This time slot works well for focused work."
            let confidence = json["confidence"] as? Double ?? 0.75
            let alternativeIndices = json["alternativeSlotIndices"] as? [Int] ?? []

            let suggestedTime = slotIndex < freeSlots.count ? freeSlots[slotIndex].start : defaultSlot
            let alternatives = alternativeIndices.compactMap { index -> Date? in
                guard index < freeSlots.count else { return nil }
                return freeSlots[index].start
            }

            return ScheduleSuggestion(
                suggestedTime: suggestedTime,
                reason: reason,
                confidence: confidence,
                alternativeTimes: alternatives.isEmpty ? nil : alternatives,
                conflictingEvents: nil
            )
        }

        // Fallback suggestion
        return ScheduleSuggestion(
            suggestedTime: defaultSlot,
            reason: "Your calendar is free at this time.",
            confidence: 0.7,
            alternativeTimes: freeSlots.dropFirst().prefix(2).map { $0.start },
            conflictingEvents: nil
        )
    }

    // MARK: - Reflection Tips Generation

    /// Generates personalized tips based on task completion reflection
    func generateReflectionTips(
        taskTitle: String,
        difficultyRating: Int,
        wasEstimateAccurate: Bool?,
        actualMinutes: Int?,
        estimatedMinutes: Int?,
        previousReflections: [TaskReflection]? = nil
    ) async throws -> [String] {
        let accuracyNote: String
        if let accurate = wasEstimateAccurate {
            if accurate {
                accuracyNote = "The time estimate was accurate."
            } else if let actual = actualMinutes, let estimated = estimatedMinutes {
                let diff = actual - estimated
                accuracyNote = "Task took \(abs(diff)) minutes \(diff > 0 ? "longer" : "shorter") than estimated."
            } else {
                accuracyNote = "The time estimate was not accurate."
            }
        } else {
            accuracyNote = "No estimate was provided."
        }

        let prompt = """
        Based on this task completion:

        Task: \(taskTitle)
        Difficulty rating: \(difficultyRating)/5
        \(accuracyNote)

        Generate 3-4 helpful tips for next time. Tips should be:
        - Actionable and specific
        - Based on the difficulty and accuracy data
        - Encouraging but practical

        Respond as JSON array:
        ["tip 1", "tip 2", "tip 3"]
        """

        let response = try await generateText(prompt: prompt)

        if let data = response.data(using: .utf8),
           let tips = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return tips
        }

        // Fallback tips based on difficulty
        return generateFallbackTips(difficultyRating: difficultyRating, wasEstimateAccurate: wasEstimateAccurate)
    }

    private func generateFallbackTips(difficultyRating: Int, wasEstimateAccurate: Bool?) -> [String] {
        var tips: [String] = []

        if difficultyRating >= 4 {
            tips.append("Break challenging tasks into smaller sub-tasks next time")
            tips.append("Consider scheduling more buffer time for difficult work")
        } else if difficultyRating <= 2 {
            tips.append("You handled this well - trust your process")
        }

        if wasEstimateAccurate == false {
            tips.append("Track actual time more often to improve future estimates")
        } else if wasEstimateAccurate == true {
            tips.append("Your estimation skills are improving - keep it up!")
        }

        tips.append("Review your approach before starting similar tasks")

        return tips
    }

    // MARK: - Context Suggestions

    /// Suggests questions to help user provide better context
    func suggestContextQuestions(taskTitle: String) async throws -> [String] {
        let prompt = """
        For the task "\(taskTitle)", suggest 3 clarifying questions that would help provide better context.

        Questions should help understand:
        - The goal/purpose
        - Who it's for
        - Any constraints or requirements

        Respond as JSON array: ["question 1?", "question 2?", "question 3?"]
        """

        let response = try await generateText(prompt: prompt)

        if let data = response.data(using: .utf8),
           let questions = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return questions
        }

        // Fallback questions
        return [
            "What is the main goal of this task?",
            "Who is this for or who will see the result?",
            "Are there any specific requirements or constraints?"
        ]
    }
}

// MARK: - Integration Notes
/*
 IMPORTANT: Connect this extension to your existing GeminiService

 The methods in this extension use `generateText(prompt:)` which should
 call your existing Gemini API method. You have a few options:

 OPTION 1: If you have an existing `generate()` or similar method
 ---------------------------------------------------------------
 Add this helper method to bridge the calls:

     private func generateText(prompt: String) async throws -> String {
         // Call your existing method, e.g.:
         return try await generate(prompt: prompt, task: nil).text
     }

 OPTION 2: If using GoogleGenerativeAI SDK directly
 --------------------------------------------------
 Add this implementation:

     private func generateText(prompt: String) async throws -> String {
         let model = GenerativeModel(name: "gemini-pro", apiKey: apiKey)
         let response = try await model.generateContent(prompt)
         return response.text ?? ""
     }

 OPTION 3: Use the methods standalone
 ------------------------------------
 Replace calls to `generateText(prompt:)` with your existing service calls.

 The fallback methods (generateFallbackBreakdown, generateFallbackTips, etc.)
 work without AI and provide sensible defaults based on pattern matching.
*/

// MARK: - Error Types

enum CognitiveProductivityError: Error, LocalizedError {
    case aiNotConfigured
    case parsingFailed
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .aiNotConfigured:
            return "AI service is not configured"
        case .parsingFailed:
            return "Failed to parse AI response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI"
        }
    }
}
