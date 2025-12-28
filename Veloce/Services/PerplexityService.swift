//
//  PerplexityService.swift
//  Veloce
//
//  Perplexity Sonar AI Service - Core AI Integration
//  Handles all AI-powered features using Perplexity's Sonar API
//

import Foundation

// MARK: - Perplexity Service

@MainActor
@Observable
final class PerplexityService {
    // MARK: Singleton
    static let shared = PerplexityService()

    // MARK: State
    private(set) var isConfigured: Bool = false
    private(set) var isProcessing: Bool = false
    private(set) var lastError: String?

    // MARK: Configuration
    private var apiKey: String?
    private let baseURL = "https://api.perplexity.ai"
    private let modelName = "sonar"  // Using sonar model (lightweight, fast)

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

    /// Generate text response from Perplexity Sonar
    /// - Parameters:
    ///   - prompt: The prompt to send to Perplexity
    ///   - systemPrompt: Optional system prompt for context
    ///   - temperature: Controls randomness (0.0 - 2.0)
    ///   - maxTokens: Maximum tokens in response
    ///   - enableSearch: Whether to enable web search (default: true)
    /// - Returns: Generated text response and optional citations
    func generateText(
        prompt: String,
        systemPrompt: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        enableSearch: Bool = true
    ) async throws -> (text: String, citations: [String]?) {
        guard isReady else {
            throw PerplexityError.notConfigured
        }

        // Rate limiting
        await enforceRateLimit()

        isProcessing = true
        defer { isProcessing = false }

        var messages: [PerplexityMessage] = []

        // Add system prompt if provided
        if let system = systemPrompt {
            messages.append(PerplexityMessage(role: "system", content: system))
        } else {
            messages.append(PerplexityMessage(role: "system", content: "You are a helpful productivity assistant."))
        }

        // Add user message
        messages.append(PerplexityMessage(role: "user", content: prompt))

        let request = PerplexityRequest(
            model: modelName,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            returnCitations: true,
            returnRelatedQuestions: false
        )

        let response: PerplexityResponse = try await performRequest(body: request)

        guard let choice = response.choices.first else {
            throw PerplexityError.emptyResponse
        }

        return (text: choice.message.content, citations: response.citations)
    }

    /// Generate JSON response from Perplexity
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

        let (response, _) = try await generateText(
            prompt: jsonPrompt,
            temperature: temperature,
            maxTokens: 4096,
            enableSearch: false  // Disable search for structured JSON responses
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
            throw PerplexityError.parsingFailed
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

        let (response, _) = try await generateText(prompt: prompt, temperature: 0.3, maxTokens: 10)
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

        let (response, _) = try await generateText(prompt: prompt, temperature: 0.3, maxTokens: 10)

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
            throw PerplexityError.parsingFailed
        }

        let decoder = JSONDecoder()
        return try decoder.decode([ParsedTask].self, from: data)
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

// MARK: - Private Helpers Extension

extension PerplexityService {
    // MARK: - Private Helpers

    private func performRequest<T: Encodable, R: Decodable>(
        body: T
    ) async throws -> R {
        guard let apiKey else {
            logError("API key not configured")
            throw PerplexityError.notConfigured
        }

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            logError("Invalid URL: \(baseURL)/chat/completions")
            throw PerplexityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30  // 30 second timeout

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)

        logDebug("Making request to: /chat/completions")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            logError("Network error: \(error.localizedDescription)")
            throw PerplexityError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            logError("Invalid response type")
            throw PerplexityError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        logDebug("Response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            // Log response body for debugging
            if let responseBody = String(data: data, encoding: .utf8) {
                logError("Error response (\(httpResponse.statusCode)): \(responseBody.prefix(500))")
            }

            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(PerplexityErrorResponse.self, from: data) {
                throw PerplexityError.apiError(errorResponse.error.message)
            }
            throw PerplexityError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            if let responseBody = String(data: data, encoding: .utf8) {
                logError("Parse error. Response: \(responseBody.prefix(500))")
            }
            throw PerplexityError.parsingFailed
        }
    }

    // MARK: - Logging Helpers

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[PerplexityService] \(message)")
        #endif
    }

    private func logError(_ message: String) {
        print("[PerplexityService ERROR] \(message)")
        lastError = message
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
            throw PerplexityError.parsingFailed
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

// MARK: - Perplexity Request/Response Models

struct PerplexityRequest: Encodable {
    let model: String
    let messages: [PerplexityMessage]
    let temperature: Double?
    let maxTokens: Int?
    let returnCitations: Bool?
    let returnRelatedQuestions: Bool?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
        case returnCitations = "return_citations"
        case returnRelatedQuestions = "return_related_questions"
    }
}

struct PerplexityMessage: Codable {
    let role: String
    let content: String
}

struct PerplexityResponse: Decodable {
    let id: String
    let model: String
    let choices: [PerplexityChoice]
    let usage: PerplexityUsage?
    let citations: [String]?
}

struct PerplexityChoice: Decodable {
    let index: Int
    let message: PerplexityMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct PerplexityUsage: Decodable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct PerplexityErrorResponse: Decodable {
    let error: PerplexityAPIError
}

struct PerplexityAPIError: Decodable {
    let message: String
    let type: String?
    let code: String?
}

// MARK: - Perplexity Error Types

enum PerplexityError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case networkError(Error)
    case httpError(Int)
    case apiError(String)
    case emptyResponse
    case parsingFailed
    case rateLimited
    case timeout

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI not configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid API configuration. Please contact support."
        case .networkError(let error):
            return networkErrorMessage(error)
        case .httpError(let code):
            return httpErrorMessage(code)
        case .apiError(let message):
            return userFriendlyAPIError(message)
        case .emptyResponse:
            return "AI returned no response. Please try again."
        case .parsingFailed:
            return "Couldn't understand AI response. Please try rephrasing."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .timeout:
            return "Request timed out. Check your connection and try again."
        }
    }

    /// User-friendly HTTP error messages
    private func httpErrorMessage(_ code: Int) -> String {
        switch code {
        case 400:
            return "Invalid request. Please try rephrasing your input."
        case 401:
            return "API key is invalid or expired. Please check your settings."
        case 403:
            return "Access denied. Your API key may not have proper permissions."
        case 404:
            return "AI service not found. Please try again later."
        case 429:
            return "Too many requests. Please wait a moment and try again."
        case 500...599:
            return "AI service is temporarily unavailable. Please try again later."
        default:
            return "Connection error (code \(code)). Please try again."
        }
    }

    /// User-friendly network error messages
    private func networkErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
            return "No internet connection. Please check your network."
        case NSURLErrorTimedOut:
            return "Request timed out. Check your connection and try again."
        case NSURLErrorNetworkConnectionLost:
            return "Connection lost. Please try again."
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return "Cannot reach AI service. Please check your connection."
        case NSURLErrorSecureConnectionFailed:
            return "Secure connection failed. Please try again."
        default:
            return "Network error. Please check your connection."
        }
    }

    /// User-friendly API error messages
    private func userFriendlyAPIError(_ message: String) -> String {
        let lowercased = message.lowercased()

        if lowercased.contains("quota") || lowercased.contains("limit") {
            return "API quota exceeded. Please try again later."
        } else if lowercased.contains("invalid") && lowercased.contains("key") {
            return "Invalid API key. Please check your settings."
        } else if lowercased.contains("safety") || lowercased.contains("blocked") {
            return "Content was filtered. Please try different input."
        } else if lowercased.contains("model") && lowercased.contains("not found") {
            return "AI model unavailable. Please try again later."
        } else {
            // Return a cleaned version of the message
            return "AI error: \(message.prefix(100))"
        }
    }

    /// Indicates if the error is retryable
    var isRetryable: Bool {
        switch self {
        case .networkError, .httpError(500...599), .rateLimited, .timeout, .emptyResponse:
            return true
        case .httpError(429):
            return true
        default:
            return false
        }
    }
}

// MARK: - Genius Task Analysis

extension PerplexityService {
    /// Generate comprehensive genius-level analysis for a task
    func generateGeniusAnalysis(
        title: String,
        notes: String? = nil,
        context: String? = nil,
        userPatterns: UserPatterns? = nil
    ) async throws -> GeniusTaskAnalysis {
        let notesSection = notes.map { "Notes: \($0)" } ?? ""
        let contextSection = context.map { "Context: \($0)" } ?? ""
        let patternsSection = userPatterns.map { """
            User Patterns:
            - Learning style: \($0.preferredLearningStyle ?? "not specified")
            - Peak hours: \($0.peakProductivityHours ?? "not specified")
            """ } ?? ""

        let prompt = """
        You are a world-class productivity mentor and task execution expert. Analyze this task and provide genius-level guidance.

        TASK: "\(title)"
        \(notesSection)
        \(contextSection)
        \(patternsSection)

        Respond in this exact JSON format:
        {
            "task_type": "CREATE|COMMUNICATE|CONSUME|COORDINATE",
            "estimated_minutes": <number>,
            "mentor_advice": {
                "main_advice": "<2-3 sentence personalized strategy for crushing this task>",
                "thought_process": "<your reasoning for this advice>",
                "potential_blocker": "<one thing that might get in the way, or null>",
                "quick_tip": "<one-liner tip for the collapsed card view>"
            },
            "execution_steps": [
                {"description": "<step>", "estimated_minutes": <number>, "order_index": <number>, "is_completed": false}
            ],
            "resources": [
                {
                    "title": "<resource title>",
                    "url": "<actual working URL>",
                    "source": "<YouTube/Article/Docs/Tool>",
                    "type": "youtube|article|documentation|tool",
                    "duration": "<duration if video, e.g. '8 min'>",
                    "reasoning": "<why this helps>"
                }
            ]
        }

        TASK TYPE RULES:
        - CREATE: High cognitive work (writing, coding, designing, building) - needs deep focus
        - COMMUNICATE: Interpersonal tasks (emails, calls, meetings) - needs social energy
        - CONSUME: Learning tasks (reading, courses, research) - can be fragmented
        - COORDINATE: Admin tasks (scheduling, organizing, quick todos) - interstitial work

        IMPORTANT:
        - Make the FIRST execution step the "START HERE" moment - smallest possible action to build momentum
        - Resources should be REAL, WORKING URLs to actual YouTube videos, articles, or tools
        - For YouTube, search for actual tutorials relevant to the task
        - Be specific and actionable, not generic
        - Keep execution steps to 3-5 maximum
        - Keep resources to 2-4 maximum
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.5)

        guard let data = jsonResponse.data(using: .utf8) else {
            throw PerplexityError.parsingFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(GeniusTaskAnalysis.self, from: data)
    }

    /// Generate smart schedule suggestions based on calendar
    func generateScheduleSuggestions(
        task: TaskItem,
        calendar: [CalendarEventInfo],
        userPatterns: UserPatterns?
    ) async throws -> [GeniusScheduleSuggestion] {
        let calendarText = calendar.prefix(20).map { event in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM d, h:mm a"
            return "- \(event.title): \(formatter.string(from: event.start)) to \(formatter.string(from: event.end))"
        }.joined(separator: "\n")

        let prompt = """
        You are a scheduling genius. Find the 3 best times to do this task.

        TASK: "\(task.title)"
        TASK TYPE: \(task.taskType.rawValue.uppercased())
        ESTIMATED DURATION: \(task.estimatedMinutes ?? 30) minutes

        CALENDAR (next 7 days):
        \(calendarText.isEmpty ? "No events scheduled" : calendarText)

        SCHEDULING RULES:
        - CREATE tasks: Morning (8-11am), 90+ min blocks, no meetings before
        - COMMUNICATE tasks: After lunch (1-4pm), can batch with other meetings
        - CONSUME tasks: Flexible, can use 30-min gaps
        - COORDINATE tasks: Interstitial, quick 15-min slots between meetings

        TODAY IS: \(Date().formatted(date: .complete, time: .omitted))

        Respond in this exact JSON format:
        {
            "suggestions": [
                {
                    "rank": "best|good|okay",
                    "date": "<ISO 8601 date string>",
                    "reason": "<why this slot is good, 10 words max>"
                }
            ]
        }

        IMPORTANT:
        - Suggest times in the NEXT 7 days only
        - Best slot should be clearly superior
        - Avoid conflicts with existing calendar events
        - Consider task type when suggesting time of day
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.4)

        guard let data = jsonResponse.data(using: .utf8) else {
            throw PerplexityError.parsingFailed
        }

        // Parse the response
        let response = try JSONDecoder().decode(ScheduleResponseWrapper.self, from: data)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

        return response.suggestions.compactMap { suggestion in
            guard let date = formatter.date(from: suggestion.date) ?? parseFlexibleDate(suggestion.date) else {
                return nil
            }
            return GeniusScheduleSuggestion(
                rank: ScheduleRank(rawValue: suggestion.rank) ?? .okay,
                date: date,
                reason: suggestion.reason
            )
        }
    }

    /// Parse various date formats from AI response
    private func parseFlexibleDate(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm",
            "MMM d, yyyy h:mm a"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}

// MARK: - Schedule Response Wrapper

private struct ScheduleResponseWrapper: Decodable {
    let suggestions: [ScheduleSuggestionDTO]
}

private struct ScheduleSuggestionDTO: Decodable {
    let rank: String
    let date: String
    let reason: String
}

// MARK: - Configuration Extension

extension PerplexityService {
    /// Load API key from Secrets.plist or fallback sources
    func loadConfiguration() {
        // Try Secrets.plist first (primary source)
        if let apiKey = loadFromSecretsPlist("PERPLEXITY_API_KEY") {
            configure(apiKey: apiKey)
            return
        }

        // Try environment variable
        if let envKey = ProcessInfo.processInfo.environment["PERPLEXITY_API_KEY"] {
            configure(apiKey: envKey)
            return
        }

        // Try UserDefaults (for development)
        if let storedKey = UserDefaults.standard.string(forKey: "perplexity_api_key"),
           !storedKey.isEmpty {
            configure(apiKey: storedKey)
            return
        }

        // Not configured - will need to be set via configure()
        isConfigured = false
    }

    /// Load a value from Secrets.plist
    private func loadFromSecretsPlist(_ key: String) -> String? {
        // Try bundle path first
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let value = plist[key] as? String,
           !value.isEmpty,
           !value.contains("YOUR_") {
            return value
        }

        // Try URL resource approach
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let plist = NSDictionary(contentsOf: url),
           let value = plist[key] as? String,
           !value.isEmpty,
           !value.contains("YOUR_") {
            return value
        }

        return nil
    }

    /// Store API key (for development/testing)
    func storeAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "perplexity_api_key")
        configure(apiKey: key)
    }
}

// MARK: - Celestial Task Card AI Methods

extension PerplexityService {

    /// Generate comprehensive strategy for CelestialTaskCard
    /// Returns rich AI guidance with overview, key points, actionable steps, and obstacles
    func generateCelestialStrategy(task: TaskItem) async throws -> CelestialAIStrategy {
        let notesSection = task.notes.map { "Notes: \($0)" } ?? ""
        let dueDateSection = task.scheduledTime.map {
            "Due: \($0.formatted(date: .abbreviated, time: .omitted))"
        } ?? ""
        let prioritySection = "Priority: \(task.priorityStars)"

        let prompt = """
        You are a world-class productivity mentor and task execution expert. Provide comprehensive, actionable guidance for completing this task.

        TASK: "\(task.title)"
        TYPE: \(task.taskType.displayName) (create/communicate/consume/coordinate)
        \(prioritySection)
        \(notesSection)
        \(dueDateSection)

        Provide:
        1. An overview (2-3 sentences) explaining your strategic approach to this task
        2. 3-5 key strategy points as bullet points
        3. 3-5 specific actionable steps (FIRST step must take < 2 minutes to build momentum)
        4. 2-3 potential obstacles or blockers to watch out for
        5. Realistic time estimate in minutes
        6. Your thought process explaining your reasoning

        Respond in this exact JSON format:
        {
            "overview": "Strategic approach to this task (2-3 sentences)...",
            "key_points": [
                "Key strategy point 1",
                "Key strategy point 2",
                "Key strategy point 3"
            ],
            "actionable_steps": [
                "First tiny step (<2 min) to build momentum",
                "Second step...",
                "Third step..."
            ],
            "potential_obstacles": [
                "Potential blocker 1",
                "Potential blocker 2"
            ],
            "estimated_minutes": 45,
            "thought_process": "My reasoning for this approach..."
        }

        IMPORTANT GUIDELINES:
        - Be specific and personalized to THIS task, not generic advice
        - First actionable step must be tiny and immediate (open app, write first line, etc.)
        - Consider task type when structuring advice:
          * CREATE tasks: need deep focus blocks, minimize distractions
          * COMMUNICATE tasks: clarity and preparation are key
          * CONSUME tasks: active engagement beats passive reading
          * COORDINATE tasks: batch similar tasks, set time limits
        - Keep language concise but actionable
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.6)

        guard let data = jsonResponse.data(using: .utf8) else {
            throw PerplexityError.parsingFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let response = try decoder.decode(CelestialStrategyResponse.self, from: data)

            return CelestialAIStrategy(
                taskId: task.id,
                overview: response.overview,
                keyPoints: response.keyPoints,
                actionableSteps: response.actionableSteps,
                potentialObstacles: response.potentialObstacles,
                estimatedMinutes: response.estimatedMinutes,
                thoughtProcess: response.thoughtProcess,
                generatedAt: Date(),
                expiresAt: Date().addingTimeInterval(4 * 60 * 60) // 4 hours
            )
        } catch {
            // Return fallback strategy on parsing failure
            return CelestialAIStrategy.fallback(for: task)
        }
    }

    /// Estimate task duration with confidence level and reasoning
    /// Returns detailed estimate for CelestialTaskCard header
    func estimateDuration(task: TaskItem) async throws -> (minutes: Int, confidence: String, reasoning: String) {
        let notesSection = task.notes.map { "Notes: \($0)" } ?? ""

        let prompt = """
        Estimate how long this task will take for an average person.

        TASK: "\(task.title)"
        TYPE: \(task.taskType.displayName)
        \(notesSection)

        Consider:
        - Task complexity and scope
        - Typical time for similar tasks
        - Required preparation and follow-up

        Respond in this exact JSON format:
        {
            "minutes": 45,
            "confidence": "high|medium|low",
            "reasoning": "Brief explanation of your estimate (1-2 sentences)"
        }

        GUIDELINES:
        - high confidence: Clear, well-defined task (e.g., "reply to email")
        - medium confidence: Some unknowns but reasonable scope
        - low confidence: Vague or complex task with many unknowns
        - Be realistic - most tasks take longer than expected
        - Round to sensible numbers (5, 10, 15, 20, 30, 45, 60, 90, 120)
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.4)

        guard let data = jsonResponse.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback based on task type
            return estimateDurationFallback(for: task)
        }

        let minutes = json["minutes"] as? Int ?? 30
        let confidence = json["confidence"] as? String ?? "medium"
        let reasoning = json["reasoning"] as? String ?? "Estimated based on task type and complexity."

        return (
            minutes: min(max(minutes, 5), 480),  // Clamp 5 min to 8 hours
            confidence: confidence,
            reasoning: reasoning
        )
    }

    /// Fallback duration estimate based on task type
    private func estimateDurationFallback(for task: TaskItem) -> (minutes: Int, confidence: String, reasoning: String) {
        switch task.taskType {
        case .create:
            return (90, "medium", "Creative tasks typically need 60-120 minutes of focused time")
        case .communicate:
            return (30, "medium", "Communication tasks usually take 15-45 minutes with preparation")
        case .consume:
            return (45, "medium", "Learning tasks work well in 30-60 minute focused sessions")
        case .coordinate:
            return (15, "high", "Administrative tasks are typically quick, 10-20 minutes")
        }
    }
}

// MARK: - Goal Genius AI Methods

extension PerplexityService {

    /// Transform a vague goal into a SMART goal
    /// - Parameters:
    ///   - title: The original goal title
    ///   - description: Optional description
    ///   - category: Goal category
    ///   - timeframe: Goal timeframe (sprint/milestone/horizon)
    /// - Returns: GoalRefinement with SMART analysis
    func refineGoalToSMART(
        title: String,
        description: String?,
        category: GoalCategory?,
        timeframe: GoalTimeframe
    ) async throws -> GoalRefinement {
        let descSection = description.map { "Description: \($0)" } ?? ""
        let categorySection = category.map { "Category: \($0.displayName)" } ?? ""

        let prompt = """
        You are a world-class productivity coach and goal-setting expert. Transform this vague goal into a crystal-clear SMART goal.

        GOAL: "\(title)"
        \(descSection)
        \(categorySection)
        TIMEFRAME: \(timeframe.displayName) (\(timeframe.subtitle))

        Make it:
        - Specific: Clear and well-defined, no ambiguity
        - Measurable: Quantifiable success metrics (numbers, percentages, deliverables)
        - Achievable: Realistic given the \(timeframe.subtitle) timeframe
        - Relevant: Connected to broader life/career goals
        - Time-bound: With clear deadline and milestone checkpoints

        Respond in this exact JSON format:
        {
            "refined_title": "Specific, action-oriented title (max 60 chars)",
            "refined_description": "Detailed description with context and motivation (2-3 sentences)",
            "success_metrics": ["Metric 1 with number", "Metric 2 with number", "Metric 3"],
            "potential_obstacles": ["Specific obstacle 1", "Specific obstacle 2"],
            "motivational_quote": "An inspiring quote relevant to this specific goal journey",
            "smart_analysis": {
                "specific": "Why it's specific and clear",
                "measurable": "How to measure success",
                "achievable": "Why it's realistic for this timeframe",
                "relevant": "Why it matters to the person",
                "time_bound": "Timeline breakdown with checkpoints"
            }
        }

        IMPORTANT:
        - Be specific and personalized, not generic
        - Include actual numbers and metrics
        - The quote should feel hand-picked for this goal
        - Success metrics should be trackable weekly
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.6)

        guard let data = jsonResponse.data(using: .utf8) else {
            throw PerplexityError.parsingFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(GoalRefinement.self, from: data)
        } catch {
            // Try fallback parsing for partial responses
            logError("GoalRefinement decode failed: \(error). Attempting fallback parsing...")
            return try parsePartialGoalRefinement(jsonResponse, originalTitle: title)
        }
    }

    /// Fallback parser for GoalRefinement when standard decoding fails
    private func parsePartialGoalRefinement(_ json: String, originalTitle: String) throws -> GoalRefinement {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PerplexityError.parsingFailed
        }

        // Extract what we can from the response
        let refinedTitle = dict["refined_title"] as? String ?? originalTitle
        let refinedDescription = dict["refined_description"] as? String
        let successMetrics = dict["success_metrics"] as? [String]
        let potentialObstacles = dict["potential_obstacles"] as? [String]
        let motivationalQuote = dict["motivational_quote"] as? String

        // Try to parse SMART analysis
        var smartAnalysis: SMARTAnalysis? = nil
        if let smartDict = dict["smart_analysis"] as? [String: Any] {
            smartAnalysis = SMARTAnalysis(
                specific: smartDict["specific"] as? String,
                measurable: smartDict["measurable"] as? String,
                achievable: smartDict["achievable"] as? String,
                relevant: smartDict["relevant"] as? String,
                timeBound: smartDict["time_bound"] as? String
            )
        }

        return GoalRefinement(
            refinedTitle: refinedTitle,
            refinedDescription: refinedDescription,
            successMetrics: successMetrics,
            potentialObstacles: potentialObstacles,
            motivationalQuote: motivationalQuote,
            smartAnalysis: smartAnalysis
        )
    }

    /// Generate a comprehensive roadmap with milestones for achieving a goal
    /// - Parameters:
    ///   - goal: The goal to create roadmap for
    ///   - userPatterns: Optional user productivity patterns
    /// - Returns: GoalRoadmap with phases, milestones, habits, and tasks
    func generateGoalRoadmap(
        goal: Goal,
        userPatterns: UserPatterns?
    ) async throws -> GoalRoadmap {
        let timeframe = goal.timeframeEnum ?? .milestone
        let patternsSection = userPatterns.map { """
            User Patterns:
            - Learning style: \($0.preferredLearningStyle ?? "not specified")
            - Peak hours: \($0.peakProductivityHours ?? "not specified")
            - Best days: \($0.bestDays?.joined(separator: ", ") ?? "not specified")
            """ } ?? ""

        let daysUntilDeadline = goal.daysRemaining ?? timeframe.defaultDurationDays

        let prompt = """
        You are a strategic planning genius and productivity architect. Create a detailed roadmap to achieve this goal.

        GOAL: "\(goal.displayTitle)"
        DESCRIPTION: \(goal.displayDescription ?? "No description")
        CATEGORY: \(goal.categoryEnum?.displayName ?? "General")
        TIMEFRAME: \(timeframe.displayName) (\(timeframe.subtitle))
        DAYS UNTIL DEADLINE: \(daysUntilDeadline)
        TARGET DATE: \(goal.targetDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
        \(patternsSection)

        Create a phased roadmap appropriate for this timeframe:
        - Sprint (1-2 weeks): 1 phase with focused daily execution
        - Milestone (1-3 months): 2-3 phases with bi-weekly checkpoints
        - Horizon (3-12 months): 4-6 phases with monthly milestones

        Respond in this exact JSON format:
        {
            "phases": [
                {
                    "name": "Phase 1: Foundation",
                    "start_week": 1,
                    "end_week": 2,
                    "milestones": [
                        {
                            "title": "Clear milestone title",
                            "description": "What this achieves",
                            "target_days_from_start": 7,
                            "success_indicator": "How to know it's done",
                            "points_value": 50
                        }
                    ],
                    "daily_habits": [
                        {
                            "title": "Daily habit title (verb + action)",
                            "frequency": "daily|weekdays|weekly",
                            "duration_minutes": 15,
                            "best_time": "morning|afternoon|evening",
                            "reasoning": "Why this habit supports the goal"
                        }
                    ],
                    "one_time_tasks": [
                        {
                            "title": "Task title (verb + specific action)",
                            "estimated_minutes": 30,
                            "priority": "high|medium|low",
                            "reasoning": "Why this task matters"
                        }
                    ],
                    "phase_obstacles": ["Potential blocker for this phase"]
                }
            ],
            "total_estimated_hours": 40,
            "success_probability": 0.85,
            "coaching_notes": "Personalized advice for this journey (2-3 sentences)"
        }

        RULES:
        - Each phase should have 1-3 milestones
        - Include 1-3 daily habits per phase
        - Include 3-5 one-time tasks per phase
        - Tasks should be specific and actionable
        - Habits should be small (5-30 min) and sustainable
        - Points should reflect effort (25-100 per milestone)
        - success_probability should be realistic (0.6-0.95)
        - Phases should build on each other logically
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.5)

        guard let data = jsonResponse.data(using: .utf8) else {
            throw PerplexityError.parsingFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(GoalRoadmap.self, from: data)
    }

    /// Generate weekly check-in coaching for a goal
    /// - Parameters:
    ///   - goal: The goal being tracked
    ///   - recentProgress: Current progress (0.0-1.0)
    ///   - completedMilestones: Number of completed milestones
    ///   - totalMilestones: Total number of milestones
    ///   - blockers: User-reported blockers (optional)
    /// - Returns: WeeklyCheckIn with coaching response
    func generateWeeklyCheckIn(
        goal: Goal,
        recentProgress: Double,
        completedMilestones: Int,
        totalMilestones: Int,
        blockers: [String]?
    ) async throws -> WeeklyCheckIn {
        let timeframe = goal.timeframeEnum ?? .milestone
        let blockersSection = blockers.map { "BLOCKERS REPORTED: \($0.joined(separator: ", "))" } ?? ""

        let prompt = """
        You are an empathetic productivity coach conducting a weekly check-in with someone working on their goal.

        GOAL: "\(goal.displayTitle)"
        TIMEFRAME: \(timeframe.displayName)
        PROGRESS: \(Int(recentProgress * 100))%
        MILESTONES: \(completedMilestones)/\(totalMilestones) completed
        DAYS REMAINING: \(goal.daysRemaining ?? 0)
        CHECK-IN STREAK: \(goal.checkInStreak) weeks
        \(blockersSection)

        Provide a coaching response that:
        1. Acknowledges their emotional state and effort
        2. Assesses progress honestly but kindly
        3. Gives specific, actionable advice for next week
        4. Suggests a small habit adjustment if helpful
        5. Provides genuine motivation
        6. Predicts potential obstacles

        Respond in this exact JSON format:
        {
            "emotional_response": "Warm acknowledgment of their effort and state (1-2 sentences)",
            "progress_assessment": "on_track|ahead|behind|at_risk",
            "week_focus": "This week, focus on... (specific actionable advice)",
            "habit_tweak": {
                "current": "What they might be doing",
                "suggested": "Small adjustment suggestion",
                "reasoning": "Why this helps"
            },
            "motivation": "Encouraging message personalized to their progress (1-2 sentences)",
            "next_week_obstacles": ["Specific predicted blocker 1", "Specific predicted blocker 2"],
            "celebration_worthy": true/false,
            "action_items": ["Specific action 1", "Specific action 2", "Specific action 3"]
        }

        TONE GUIDELINES:
        - If ahead: Celebrate but warn against complacency
        - If on_track: Encourage steady progress
        - If behind: Acknowledge difficulty, offer specific recovery path
        - If at_risk: Honest but hopeful, suggest scope adjustment if needed

        Be warm, specific, and avoid generic advice. Reference their actual goal and progress.
        """

        let jsonResponse = try await generateJSON(prompt: prompt, temperature: 0.7)

        guard let data = jsonResponse.data(using: .utf8) else {
            throw PerplexityError.parsingFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(WeeklyCheckIn.self, from: data)
    }
}
