//
//  YouTubeResource.swift
//  Veloce
//
//  YouTube video resource model for task learning
//

import Foundation

/// Represents a YouTube video recommended for learning
struct YouTubeResource: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let videoId: String           // YouTube video ID
    let title: String
    let channelName: String?
    let durationSeconds: Int?
    let viewCount: Int?
    let thumbnailURL: String?
    let relevanceScore: Double?   // AI-calculated relevance (0.0 - 1.0)
    let createdAt: Date

    // Parent task reference
    var taskId: UUID?

    init(
        id: UUID = UUID(),
        videoId: String,
        title: String,
        channelName: String? = nil,
        durationSeconds: Int? = nil,
        viewCount: Int? = nil,
        thumbnailURL: String? = nil,
        relevanceScore: Double? = nil,
        createdAt: Date = Date(),
        taskId: UUID? = nil
    ) {
        self.id = id
        self.videoId = videoId
        self.title = title
        self.channelName = channelName
        self.durationSeconds = durationSeconds
        self.viewCount = viewCount
        self.thumbnailURL = thumbnailURL
        self.relevanceScore = relevanceScore
        self.createdAt = createdAt
        self.taskId = taskId
    }

    // MARK: - Computed Properties

    /// YouTube watch URL
    var watchURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(videoId)")
    }

    /// YouTube app deep link
    var appURL: URL? {
        URL(string: "youtube://watch?v=\(videoId)")
    }

    /// Formatted duration string (e.g., "12:34")
    var formattedDuration: String? {
        guard let seconds = durationSeconds else { return nil }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, remainingSeconds)
        }
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    /// Formatted view count (e.g., "2.3M views")
    var formattedViewCount: String? {
        guard let count = viewCount else { return nil }
        if count >= 1_000_000 {
            return String(format: "%.1fM views", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK views", Double(count) / 1_000)
        }
        return "\(count) views"
    }

    /// Relevance label based on score
    var relevanceLabel: String? {
        guard let score = relevanceScore else { return nil }
        switch score {
        case 0.8...1.0: return "Highly relevant"
        case 0.6..<0.8: return "Relevant"
        case 0.4..<0.6: return "Somewhat relevant"
        default: return nil
        }
    }
}

// MARK: - Supabase Coding Keys

extension YouTubeResource {
    enum CodingKeys: String, CodingKey {
        case id
        case videoId = "video_id"
        case title
        case channelName = "channel_name"
        case durationSeconds = "duration_seconds"
        case viewCount = "view_count"
        case thumbnailURL = "thumbnail_url"
        case relevanceScore = "relevance_score"
        case createdAt = "created_at"
        case taskId = "task_id"
    }
}
