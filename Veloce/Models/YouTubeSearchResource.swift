//
//  YouTubeSearchResource.swift
//  Veloce
//
//  AI-generated YouTube search query model for smart hybrid approach
//  Deep-links to YouTube search results (not individual videos)
//

import Foundation
import UIKit

// MARK: - YouTube Search Resource

/// Represents an AI-generated YouTube search query (not a specific video)
struct YouTubeSearchResource: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let searchQuery: String        // "how to write project proposal template"
    let displayTitle: String       // "Proposal Writing Basics"
    let reasoning: String?         // Why this search helps
    let relevanceScore: Double?    // 0.0-1.0
    let createdAt: Date

    var taskId: UUID?

    // MARK: - YouTube URLs

    /// YouTube app deep-link for search results
    var youtubeAppURL: URL? {
        guard let encoded = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "youtube://results?search_query=\(encoded)")
    }

    /// YouTube web URL fallback
    var youtubeWebURL: URL? {
        guard let encoded = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://www.youtube.com/results?search_query=\(encoded)")
    }

    /// Open in YouTube (app if available, web fallback)
    @MainActor
    func openInYouTube() {
        if let appURL = youtubeAppURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = youtubeWebURL {
            UIApplication.shared.open(webURL)
        }
    }

    // MARK: - Display Helpers

    /// Relevance label for UI
    var relevanceLabel: String? {
        guard let score = relevanceScore else { return nil }
        switch score {
        case 0.9...1.0: return "Highly relevant"
        case 0.7..<0.9: return "Very relevant"
        case 0.5..<0.7: return "Relevant"
        default: return "Suggested"
        }
    }

    /// Icon based on relevance
    var relevanceIcon: String {
        guard let score = relevanceScore else { return "magnifyingglass" }
        switch score {
        case 0.8...1.0: return "star.fill"
        case 0.6..<0.8: return "star.leadinghalf.filled"
        default: return "magnifyingglass"
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        searchQuery: String,
        displayTitle: String,
        reasoning: String? = nil,
        relevanceScore: Double? = nil,
        createdAt: Date = Date(),
        taskId: UUID? = nil
    ) {
        self.id = id
        self.searchQuery = searchQuery
        self.displayTitle = displayTitle
        self.reasoning = reasoning
        self.relevanceScore = relevanceScore
        self.createdAt = createdAt
        self.taskId = taskId
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case searchQuery = "search_query"
        case displayTitle = "display_title"
        case reasoning
        case relevanceScore = "relevance_score"
        case createdAt = "created_at"
        case taskId = "task_id"
    }
}

// MARK: - Fallback Factory

extension YouTubeSearchResource {

    /// Generate fallback search resources based on task keywords
    static func fallbacks(for taskTitle: String, taskId: UUID? = nil) -> [YouTubeSearchResource] {
        let taskWords = taskTitle.lowercased()
        var resources: [YouTubeSearchResource] = []

        // Presentation/slides
        if taskWords.contains("presentation") || taskWords.contains("slides") || taskWords.contains("powerpoint") {
            resources.append(YouTubeSearchResource(
                searchQuery: "how to create effective presentation slides tips",
                displayTitle: "Presentation Design Tips",
                reasoning: "Learn visual design principles for impactful slides",
                relevanceScore: 0.9,
                taskId: taskId
            ))
            resources.append(YouTubeSearchResource(
                searchQuery: "presentation structure storytelling business",
                displayTitle: "Presentation Storytelling",
                reasoning: "Structure your message for maximum impact",
                relevanceScore: 0.85,
                taskId: taskId
            ))
        }

        // Report/document
        if taskWords.contains("report") || taskWords.contains("document") || taskWords.contains("write") {
            resources.append(YouTubeSearchResource(
                searchQuery: "professional report writing tutorial structure",
                displayTitle: "Report Writing Guide",
                reasoning: "Structure and clarity tips for professional documents",
                relevanceScore: 0.9,
                taskId: taskId
            ))
        }

        // Meeting/call
        if taskWords.contains("meeting") || taskWords.contains("call") {
            resources.append(YouTubeSearchResource(
                searchQuery: "effective meeting preparation agenda tips",
                displayTitle: "Meeting Preparation",
                reasoning: "Prepare agendas for productive meetings",
                relevanceScore: 0.85,
                taskId: taskId
            ))
        }

        // Email
        if taskWords.contains("email") || taskWords.contains("reply") {
            resources.append(YouTubeSearchResource(
                searchQuery: "professional email writing tips templates",
                displayTitle: "Email Writing Tips",
                reasoning: "Write clear, professional emails",
                relevanceScore: 0.85,
                taskId: taskId
            ))
        }

        // Code/develop
        if taskWords.contains("code") || taskWords.contains("develop") || taskWords.contains("bug") || taskWords.contains("feature") {
            resources.append(YouTubeSearchResource(
                searchQuery: "coding productivity tips developer workflow",
                displayTitle: "Developer Productivity",
                reasoning: "Optimize your coding workflow",
                relevanceScore: 0.8,
                taskId: taskId
            ))
        }

        // Generic fallback if no keywords match
        if resources.isEmpty {
            resources.append(YouTubeSearchResource(
                searchQuery: "\(taskTitle) tutorial how to guide",
                displayTitle: "Task Tutorial",
                reasoning: "General guidance for this type of task",
                relevanceScore: 0.7,
                taskId: taskId
            ))
            resources.append(YouTubeSearchResource(
                searchQuery: "productivity tips get things done focus",
                displayTitle: "Productivity Tips",
                reasoning: "General productivity techniques",
                relevanceScore: 0.6,
                taskId: taskId
            ))
        }

        return Array(resources.prefix(3))
    }
}

// MARK: - Gemini Response Model

/// Response model for parsing Gemini JSON output
struct YouTubeSearchQueryResponse: Decodable, Sendable {
    let queries: [YouTubeSearchQueryItem]

    struct YouTubeSearchQueryItem: Decodable, Sendable {
        let searchQuery: String
        let displayTitle: String
        let reasoning: String?
        let relevanceScore: Double?

        enum CodingKeys: String, CodingKey {
            case searchQuery = "search_query"
            case displayTitle = "display_title"
            case reasoning
            case relevanceScore = "relevance_score"
        }
    }
}
