//
//  GeminiService.swift
//  Veloce
//
//  Gemini AI Service - Core AI Integration
//  Handles all AI-powered features using Google's Gemini API
//

import Foundation

// MARK: - Gemini Service

@MainActor
@Observable
final class GeminiService {
    // MARK: Singleton
    static let shared = GeminiService()

    // MARK: State
    private(set) var isConfigured: Bool = false
    private(set) var isProcessing: Bool = false
    private(set) var lastError: String?

    // MARK: Configuration
    private var apiKey: String?
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let modelName = "gemini-1.5-flash"

    // MARK: Rate Limiting
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 0.5  // 500ms between requests

    // MARK: Initialization
    private init() {}

    // MARK: - Configuration

    /// Configure the service with an API key
    func configure(apiKey: String) {
        self.apiKey = apiKey
        self.isConfigured = true
        self.lastError = nil
    }

    /// Check if service is ready for use
    var isReady: Bool {
        isConfigured && apiKey != nil && !apiKey!.isEmpty
    }

    // MARK: - Core Generation Method

    /// Generate text response from Gemini
    /// - Parameters:
    ///   - prompt: The prompt to send to Gemini
    ///   - temperature: Controls randomness (0.0 - 1.0)
    ///   - maxTokens: Maximum tokens in response
    /// - Returns: Generated text response
    func generateText(
        prompt: String,
        temperature: Double = 0.7,
        maxTokens: Int = 2048
    ) async throws -> String {
        guard isReady else {
            throw GeminiError.notConfigured
        }

        // Rate limiting
        await enforceRateLimit()

        isProcessing = true
        defer { isProcessing = false }

        let request = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: prompt)],
                    role: "user"
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: temperature,
                maxOutputTokens: maxTokens,
                responseMimeType: nil
            )
        )

        let response: GeminiResponse = try await performRequest(
            endpoint: "models/\(modelName):generateContent",
            body: request
        )

        if let error = response.error {
            let message = error.message ?? "Unknown API error"
            lastError = message
            throw GeminiError.apiError(message)
        }

        guard let text = response.candidates?.first?.content?.parts.first?.text else {
            throw GeminiError.emptyResponse
        }

        return text
    }

    /// Generate JSON response from Gemini
    /// - Parameters:
    ///   - prompt: The prompt to send
    ///   - temperature: Controls randomness
    /// - Returns: Raw JSON string (caller should parse)
    func generateJSON(
        prompt: String,
        temperature: Double = 0.3
    ) async throws -> String {
        let jsonPrompt = """
        \(prompt)

        IMPORTANT: Respond ONLY with valid JSON. No markdown, no code blocks, just the raw JSON object.
        """

        let response = try await generateText(
            prompt: jsonPrompt,
            temperature: temperature,
            maxTokens: 4096
        )

        // Clean response if wrapped in markdown
        return cleanJSONResponse(response)
    }

    // MARK: - Task Analysis

    /// Analyze a task and provide AI advice
    func analyzeTask(
        title: String,
        notes: String? = nil,
        context: String? = nil
    ) async throws -> AIResponse {
        let notesSection = notes.map { "Notes: \($0)" } ?? ""
        let contextSection = context.map { "Context: \($0)" } ?? ""

        let prompt = """
        You are a productivity expert. Analyze this task and provide helpful advice.

        Task: \(title)
        \(notesSection)
        \(contextSection)

        Provide:
        1. Brief, actionable advice (2-3 sentences)
        2. Priority level (low, medium, high) based on typical urgency
        3. Estimated time in minutes (be realistic)
        4. Your thought process explaining your reasoning
        5. 3-5 sub-tasks to break this down (if applicable)
        6. YouTube search queries that would help learn skills for this task

        Respond in this exact JSON format:
        {
            "advice": "Your actionable advice here",
            "priority": "medium",
            "estimated_minutes": 45,
            "thought_process": "Brief explanation of your reasoning",
            "sub_tasks": [
                {"title": "First step", "estimated_minutes": 10, "reasoning": "Why this step"}
            ],
            "youtube_resources": [
                {"search_query": "how to X tutorial", "relevance_score": 0.9, "reasoning": "Why helpful"}
            ],
            "schedule_suggestion": {
                "suggested_time_of_day": "morning",
                "reasoning": "Best time because...",
                "energy_level": "high",
                "optimal_duration": 45
            }
        }
        """

        let jsonResponse = try await generateJSON(prompt: prompt)

        guard let data = jsonResponse.data(using: .utf8) else {
            throw GeminiError.parsingFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(AIResponse.self, from: data)
        } catch {
            // Try to extract what we can
            return try parsePartialResponse(jsonResponse)
        }
    }

    /// Quick priority assessment
    func assessPriority(taskTitle: String) async throws -> TaskPriority {
        let prompt = """
        Assess the priority of this task based on typical urgency and importance.
        Task: \(taskTitle)

        Respond with ONLY one word: low, medium, or high
        """

        let response = try await generateText(prompt: prompt, temperature: 0.3, maxTokens: 10)
        let cleaned = response.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        switch cleaned {
        case "high": return .high
        case "low": return .low
        default: return .medium
        }
    }

    /// Estimate time for a task
    func estimateTime(
        taskTitle: String,
        context: String? = nil
    ) async throws -> Int {
        let contextSection = context.map { "Context: \($0)" } ?? ""

        let prompt = """
        Estimate how many minutes this task would take for an average person.
        Task: \(taskTitle)
        \(contextSection)

        Respond with ONLY a number (minutes). Be realistic. Examples:
        - Simple email: 10
        - Report writing: 60
        - Major project: 240

        Your answer (just the number):
        """

        let response = try await generateText(prompt: prompt, temperature: 0.3, maxTokens: 10)

        // Extract number from response
        let numbers = response.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()

        guard let minutes = Int(numbers), minutes > 0 else {
            return 30  // Default fallback
        }

        return min(max(minutes, 5), 480)  // Clamp between 5 min and 8 hours
    }

    // MARK: - Brain Dump Processing

    /// Process a brain dump into structured tasks
    func processBrainDump(_ text: String) async throws -> [ParsedTask] {
        let prompt = """
        Parse this brain dump into structured tasks. Extract each distinct task or todo item.

        Brain dump:
        \(text)

        For each task, provide:
        - title: Clear, actionable task title (start with a verb)
        - priority: low, medium, or high
        - estimated_minutes: realistic time estimate
        - category: work, personal, health, learning, other

        Respond as JSON array:
        [
            {
                "title": "Task title",
                "priority": "medium",
                "estimated_minutes": 30,
                "category": "work"
            }
        ]
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.5)

        guard let data = jsonResponse.data(using: .utf8) else {
            throw GeminiError.parsingFailed
        }

        let decoder = JSONDecoder()
        return try decoder.decode([ParsedTask].self, from: data)
    }

    // MARK: - Private Helpers

    private func performRequest<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T
    ) async throws -> R {
        guard let apiKey else {
            throw GeminiError.notConfigured
        }

        guard let url = URL(string: "\(baseURL)/\(endpoint)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let errorMessage = errorResponse.error?.message {
                throw GeminiError.apiError(errorMessage)
            }
            throw GeminiError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(R.self, from: data)
    }

    private func enforceRateLimit() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minRequestInterval {
                try? await Task.sleep(nanoseconds: UInt64((minRequestInterval - elapsed) * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }

    private func cleanJSONResponse(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }

        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parsePartialResponse(_ json: String) throws -> AIResponse {
        // Try to extract basic fields even if full parsing fails
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.parsingFailed
        }

        let advice = dict["advice"] as? String ?? "Unable to parse AI response"
        let priority = dict["priority"] as? String
        let minutes = dict["estimated_minutes"] as? Int ?? dict["estimatedMinutes"] as? Int
        let thoughtProcess = dict["thought_process"] as? String ?? dict["thoughtProcess"] as? String

        return AIResponse(
            advice: advice,
            priority: priority,
            estimatedMinutes: minutes,
            sources: nil,
            thoughtProcess: thoughtProcess,
            subTasks: nil,
            youtubeResources: nil,
            scheduleSuggestion: nil
        )
    }
}

// MARK: - Parsed Task Model

struct ParsedTask: Codable, Sendable {
    let title: String
    let priority: String?
    let estimatedMinutes: Int?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case title
        case priority
        case estimatedMinutes = "estimated_minutes"
        case category
    }

    var priorityEnum: TaskPriority {
        switch priority?.lowercased() {
        case "high": return .high
        case "low": return .low
        default: return .medium
        }
    }
}

// MARK: - Gemini Error Types

enum GeminiError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case networkError(Error)
    case httpError(Int)
    case apiError(String)
    case emptyResponse
    case parsingFailed
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Gemini API is not configured. Please add your API key."
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .emptyResponse:
            return "Empty response from AI"
        case .parsingFailed:
            return "Failed to parse AI response"
        case .rateLimited:
            return "Rate limited. Please try again in a moment."
        }
    }
}

// MARK: - Configuration Extension

extension GeminiService {
    /// Load API key from environment or configuration
    func loadConfiguration() {
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            configure(apiKey: envKey)
            return
        }

        // Try UserDefaults (for development)
        if let storedKey = UserDefaults.standard.string(forKey: "gemini_api_key"),
           !storedKey.isEmpty {
            configure(apiKey: storedKey)
            return
        }

        // Not configured - will need to be set via configure()
        isConfigured = false
    }

    /// Store API key (for development/testing)
    func storeAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "gemini_api_key")
        configure(apiKey: key)
    }
}
