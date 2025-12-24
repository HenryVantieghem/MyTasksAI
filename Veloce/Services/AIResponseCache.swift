//
//  AIResponseCache.swift
//  Veloce
//
//  In-memory cache for AI responses to reduce API calls
//  Default TTL: 4 hours for strategies, 2 hours for YouTube queries
//

import Foundation

// MARK: - AI Response Cache

@MainActor
@Observable
final class AIResponseCache {
    static let shared = AIResponseCache()

    // MARK: - Cache Storage

    private var strategyCache: [UUID: CelestialAIStrategy] = [:]
    private var youtubeCache: [UUID: [YouTubeSearchResource]] = [:]
    private var durationCache: [UUID: DurationEstimate] = [:]

    // MARK: - Types

    struct DurationEstimate: Sendable {
        let minutes: Int
        let confidence: String
        let reasoning: String?
        let generatedAt: Date

        var isExpired: Bool {
            Date().timeIntervalSince(generatedAt) > 4 * 60 * 60 // 4 hours
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Strategy Cache

    /// Get cached strategy for a task
    func getStrategy(for taskId: UUID) -> CelestialAIStrategy? {
        guard let cached = strategyCache[taskId] else { return nil }

        // Check expiration
        if cached.isExpired {
            strategyCache.removeValue(forKey: taskId)
            return nil
        }

        return cached
    }

    /// Cache a strategy for a task
    func setStrategy(_ strategy: CelestialAIStrategy, for taskId: UUID) {
        strategyCache[taskId] = strategy
    }

    /// Check if strategy exists and is valid
    func hasValidStrategy(for taskId: UUID) -> Bool {
        guard let cached = strategyCache[taskId] else { return false }
        return !cached.isExpired
    }

    // MARK: - YouTube Cache

    /// Get cached YouTube search resources for a task
    func getYouTubeSearches(for taskId: UUID) -> [YouTubeSearchResource]? {
        youtubeCache[taskId]
    }

    /// Cache YouTube search resources for a task
    func setYouTubeSearches(_ searches: [YouTubeSearchResource], for taskId: UUID) {
        youtubeCache[taskId] = searches
    }

    /// Check if YouTube cache exists
    func hasYouTubeSearches(for taskId: UUID) -> Bool {
        guard let searches = youtubeCache[taskId] else { return false }
        return !searches.isEmpty
    }

    // MARK: - Duration Cache

    /// Get cached duration estimate for a task
    func getDuration(for taskId: UUID) -> DurationEstimate? {
        guard let cached = durationCache[taskId] else { return nil }

        if cached.isExpired {
            durationCache.removeValue(forKey: taskId)
            return nil
        }

        return cached
    }

    /// Cache duration estimate for a task
    func setDuration(
        _ minutes: Int,
        confidence: String,
        reasoning: String? = nil,
        for taskId: UUID
    ) {
        durationCache[taskId] = DurationEstimate(
            minutes: minutes,
            confidence: confidence,
            reasoning: reasoning,
            generatedAt: Date()
        )
    }

    /// Check if duration cache exists and is valid
    func hasValidDuration(for taskId: UUID) -> Bool {
        guard let cached = durationCache[taskId] else { return false }
        return !cached.isExpired
    }

    // MARK: - Cache Management

    /// Invalidate all caches for a specific task
    func invalidate(taskId: UUID) {
        strategyCache.removeValue(forKey: taskId)
        youtubeCache.removeValue(forKey: taskId)
        durationCache.removeValue(forKey: taskId)
    }

    /// Clear all caches
    func clearAll() {
        strategyCache.removeAll()
        youtubeCache.removeAll()
        durationCache.removeAll()
    }

    /// Clear expired entries from all caches
    func clearExpired() {
        // Clear expired strategies
        for (taskId, strategy) in strategyCache where strategy.isExpired {
            strategyCache.removeValue(forKey: taskId)
        }

        // Clear expired durations
        for (taskId, duration) in durationCache where duration.isExpired {
            durationCache.removeValue(forKey: taskId)
        }

        // YouTube cache doesn't expire (cleared on task invalidation)
    }

    // MARK: - Statistics

    /// Number of cached strategies
    var strategyCacheCount: Int {
        strategyCache.count
    }

    /// Number of cached YouTube resources
    var youtubeCacheCount: Int {
        youtubeCache.count
    }

    /// Number of cached duration estimates
    var durationCacheCount: Int {
        durationCache.count
    }

    /// Total cache size
    var totalCacheCount: Int {
        strategyCacheCount + youtubeCacheCount + durationCacheCount
    }
}
