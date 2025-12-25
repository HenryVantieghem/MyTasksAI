//
//  ChallengeService.swift
//  Veloce
//
//  Challenge Service - Backend integration for social challenges
//  Handles creating, accepting, tracking, and completing challenges
//  with Supabase Realtime for live updates
//

import Foundation
import Supabase

// MARK: - Challenge Service

@MainActor
@Observable
final class ChallengeService {
    static let shared = ChallengeService()

    // State
    private(set) var challenges: [Challenge] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // Realtime subscription
    private var realtimeChannel: RealtimeChannelV2?

    private init() {}

    // MARK: - Load Challenges

    /// Load all challenges for the current user
    func loadChallenges() async throws {
        isLoading = true
        defer { isLoading = false }

        let supabase = SupabaseService.shared.supabase
        guard let userId = try? await supabase.auth.session.user.id else {
            throw ChallengeError.notAuthenticated
        }

        // Fetch challenges where user is creator or participant
        let createdChallenges: [ChallengeDTO] = try await supabase
            .from("challenges")
            .select("""
                *,
                participants:challenge_participants(
                    *,
                    user:users(id, full_name, username, avatar_url, total_points, current_level, current_streak)
                )
            """)
            .eq("creator_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        let participatingChallenges: [ChallengeDTO] = try await supabase
            .from("challenges")
            .select("""
                *,
                participants:challenge_participants(
                    *,
                    user:users(id, full_name, username, avatar_url, total_points, current_level, current_streak)
                )
            """)
            .neq("creator_id", value: userId.uuidString)
            .in("id", values: try await getParticipatingChallengeIds(userId: userId))
            .order("created_at", ascending: false)
            .execute()
            .value

        // Combine and dedupe
        var allChallenges = createdChallenges
        for challenge in participatingChallenges {
            if !allChallenges.contains(where: { $0.id == challenge.id }) {
                allChallenges.append(challenge)
            }
        }

        challenges = allChallenges.map { $0.toChallenge() }
    }

    private func getParticipatingChallengeIds(userId: UUID) async throws -> [String] {
        let supabase = SupabaseService.shared.supabase

        struct ParticipantRow: Decodable {
            let challengeId: UUID

            enum CodingKeys: String, CodingKey {
                case challengeId = "challenge_id"
            }
        }

        let participants: [ParticipantRow] = try await supabase
            .from("challenge_participants")
            .select("challenge_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return participants.map { $0.challengeId.uuidString }
    }

    // MARK: - Create Challenge

    /// Create a new challenge and invite participants
    func createChallenge(
        type: ChallengeType,
        title: String,
        description: String?,
        targetValue: Int,
        durationHours: Int,
        stakes: String?,
        participantIds: [UUID],
        circleId: UUID? = nil
    ) async throws -> Challenge {
        let supabase = SupabaseService.shared.supabase
        guard let userId = try? await supabase.auth.session.user.id else {
            throw ChallengeError.notAuthenticated
        }

        // Calculate XP reward based on difficulty
        let xpReward = calculateXPReward(targetValue: targetValue, durationHours: durationHours, type: type)

        // Insert challenge
        let newChallenge = ChallengeInsert(
            creatorId: userId,
            challengeType: type.rawValue,
            title: title,
            description: description,
            targetValue: targetValue,
            durationHours: durationHours,
            stakes: stakes,
            status: "pending",
            xpReward: xpReward,
            circleId: circleId
        )

        let insertedChallenge: ChallengeDTO = try await supabase
            .from("challenges")
            .insert(newChallenge)
            .select()
            .single()
            .execute()
            .value

        // Add creator as participant
        let creatorParticipant = ParticipantInsert(
            challengeId: insertedChallenge.id,
            userId: userId,
            status: "accepted"
        )

        try await supabase
            .from("challenge_participants")
            .insert(creatorParticipant)
            .execute()

        // Add invited participants
        for participantId in participantIds {
            let participant = ParticipantInsert(
                challengeId: insertedChallenge.id,
                userId: participantId,
                status: "pending"
            )

            try await supabase
                .from("challenge_participants")
                .insert(participant)
                .execute()

            // Create activity feed entry
            try await createActivityFeedEntry(
                userId: userId,
                actionType: "challenge_sent",
                targetUserId: participantId,
                challengeId: insertedChallenge.id,
                message: "challenged you to \(title)"
            )
        }

        // Reload challenges
        try await loadChallenges()

        return challenges.first { $0.id == insertedChallenge.id }!
    }

    // MARK: - Accept Challenge

    /// Accept an incoming challenge
    func acceptChallenge(_ challengeId: UUID) async throws {
        let supabase = SupabaseService.shared.supabase
        guard let userId = try? await supabase.auth.session.user.id else {
            throw ChallengeError.notAuthenticated
        }

        // Update participant status
        try await supabase
            .from("challenge_participants")
            .update(["status": "accepted", "updated_at": ISO8601DateFormatter().string(from: Date())])
            .eq("challenge_id", value: challengeId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Check if all participants accepted - if so, start challenge
        let pendingCount: Int = try await supabase
            .from("challenge_participants")
            .select("*", head: true, count: .exact)
            .eq("challenge_id", value: challengeId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .count ?? 0

        if pendingCount == 0 {
            // Start the challenge
            let startsAt = Date()
            let challenge = challenges.first { $0.id == challengeId }
            let endsAt = startsAt.addingTimeInterval(TimeInterval((challenge?.durationHours ?? 24) * 3600))

            try await supabase
                .from("challenges")
                .update([
                    "status": "active",
                    "starts_at": ISO8601DateFormatter().string(from: startsAt),
                    "ends_at": ISO8601DateFormatter().string(from: endsAt),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: challengeId.uuidString)
                .execute()
        }

        // Create activity
        try await createActivityFeedEntry(
            userId: userId,
            actionType: "challenge_accepted",
            challengeId: challengeId,
            message: "accepted a challenge"
        )

        try await loadChallenges()
    }

    // MARK: - Decline Challenge

    /// Decline an incoming challenge
    func declineChallenge(_ challengeId: UUID) async throws {
        let supabase = SupabaseService.shared.supabase
        guard let userId = try? await supabase.auth.session.user.id else {
            throw ChallengeError.notAuthenticated
        }

        try await supabase
            .from("challenge_participants")
            .update(["status": "declined", "updated_at": ISO8601DateFormatter().string(from: Date())])
            .eq("challenge_id", value: challengeId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()

        try await loadChallenges()
    }

    // MARK: - Update Progress

    /// Update the current user's progress in a challenge
    func updateProgress(challengeId: UUID, newProgress: Int) async throws {
        let supabase = SupabaseService.shared.supabase
        guard let userId = try? await supabase.auth.session.user.id else {
            throw ChallengeError.notAuthenticated
        }

        let progressUpdate = ParticipantProgressUpdate(
            currentProgress: newProgress,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("challenge_participants")
            .update(progressUpdate)
            .eq("challenge_id", value: challengeId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Check if challenge is complete
        try await checkChallengeCompletion(challengeId: challengeId)
    }

    // MARK: - Check Completion

    private func checkChallengeCompletion(challengeId: UUID) async throws {
        let supabase = SupabaseService.shared.supabase

        guard let challenge = challenges.first(where: { $0.id == challengeId }),
              let endsAt = challenge.endsAt,
              Date() >= endsAt || hasReachedTarget(challenge) else {
            return
        }

        // Find winner (highest progress)
        let winner = challenge.participants.max { $0.currentProgress < $1.currentProgress }

        guard let winnerId = winner?.userId else { return }

        // Update challenge as completed
        let completionUpdate = ChallengeCompletionUpdate(
            status: "completed",
            winnerId: winnerId.uuidString,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("challenges")
            .update(completionUpdate)
            .eq("id", value: challengeId.uuidString)
            .execute()

        // Mark winner
        let winnerUpdate = ParticipantWinnerUpdate(
            isWinner: true,
            completedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await supabase
            .from("challenge_participants")
            .update(winnerUpdate)
            .eq("challenge_id", value: challengeId.uuidString)
            .eq("user_id", value: winnerId.uuidString)
            .execute()

        // Award XP to winner
        try await awardXP(userId: winnerId, amount: challenge.xpReward, reason: "challenge_won")

        // Create activity
        try await createActivityFeedEntry(
            userId: winnerId,
            actionType: "challenge_won",
            challengeId: challengeId,
            pointsEarned: challenge.xpReward,
            message: "won \(challenge.title)!"
        )

        try await loadChallenges()
    }

    private func hasReachedTarget(_ challenge: Challenge) -> Bool {
        challenge.participants.contains { $0.currentProgress >= challenge.targetValue }
    }

    // MARK: - Realtime Subscription

    /// Subscribe to realtime updates for challenges
    func subscribeToRealtimeUpdates() async {
        let supabase = SupabaseService.shared.supabase

        realtimeChannel = supabase.realtimeV2.channel("challenges")

        _ = await realtimeChannel?.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "challenge_participants"
        ) { [weak self] _ in
            Task {
                try? await self?.loadChallenges()
            }
        }

        _ = await realtimeChannel?.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "challenges"
        ) { [weak self] _ in
            Task {
                try? await self?.loadChallenges()
            }
        }

        try? await realtimeChannel?.subscribeWithError()
    }

    /// Unsubscribe from realtime updates
    func unsubscribeFromRealtimeUpdates() async {
        await realtimeChannel?.unsubscribe()
        realtimeChannel = nil
    }

    // MARK: - Helpers

    private func calculateXPReward(targetValue: Int, durationHours: Int, type: ChallengeType) -> Int {
        let baseXP = 50
        let valueMultiplier = targetValue / 5
        let durationMultiplier = durationHours / 24
        return baseXP + (valueMultiplier * 10) + (durationMultiplier * 25)
    }

    private func awardXP(userId: UUID, amount: Int, reason: String) async throws {
        let supabase = SupabaseService.shared.supabase

        // Get current XP
        struct UserXP: Decodable {
            let totalPoints: Int

            enum CodingKeys: String, CodingKey {
                case totalPoints = "total_points"
            }
        }

        let user: UserXP = try await supabase
            .from("users")
            .select("total_points")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Update XP
        try await supabase
            .from("users")
            .update(["total_points": user.totalPoints + amount])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    private func createActivityFeedEntry(
        userId: UUID,
        actionType: String,
        targetUserId: UUID? = nil,
        challengeId: UUID? = nil,
        circleId: UUID? = nil,
        pointsEarned: Int = 0,
        message: String? = nil
    ) async throws {
        let supabase = SupabaseService.shared.supabase

        let activity = ActivityFeedInsert(
            userId: userId,
            actionType: actionType,
            targetUserId: targetUserId,
            challengeId: challengeId,
            circleId: circleId,
            pointsEarned: pointsEarned,
            message: message
        )

        try await supabase
            .from("activity_feed")
            .insert(activity)
            .execute()
    }

    // MARK: - Incoming Challenges Count

    var incomingChallengesCount: Int {
        challenges.filter { $0.isIncoming }.count
    }

    var activeChallengesCount: Int {
        challenges.filter { $0.isActive }.count
    }
}

// MARK: - Challenge Error

enum ChallengeError: LocalizedError {
    case notAuthenticated
    case challengeNotFound
    case invalidState

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to access challenges"
        case .challengeNotFound: return "Challenge not found"
        case .invalidState: return "Invalid challenge state"
        }
    }
}

// MARK: - DTOs

private struct ChallengeDTO: Decodable {
    let id: UUID
    let creatorId: UUID
    let challengeType: String
    let title: String
    let description: String?
    let targetValue: Int
    let durationHours: Int
    let stakes: String?
    let status: String
    let winnerId: UUID?
    let xpReward: Int
    let circleId: UUID?
    let startsAt: Date?
    let endsAt: Date?
    let createdAt: Date
    let participants: [ParticipantDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case challengeType = "challenge_type"
        case title
        case description
        case targetValue = "target_value"
        case durationHours = "duration_hours"
        case stakes
        case status
        case winnerId = "winner_id"
        case xpReward = "xp_reward"
        case circleId = "circle_id"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case createdAt = "created_at"
        case participants
    }

    func toChallenge() -> Challenge {
        Challenge(
            id: id,
            creatorId: creatorId,
            creatorName: participants?.first { $0.userId == creatorId }?.user?.fullName ?? "Unknown",
            challengeType: ChallengeType(rawValue: challengeType) ?? .custom,
            title: title,
            description: description,
            targetValue: targetValue,
            durationHours: durationHours,
            stakes: stakes,
            status: ChallengeStatus(rawValue: status) ?? .pending,
            winnerId: winnerId,
            xpReward: xpReward,
            circleId: circleId,
            startsAt: startsAt,
            endsAt: endsAt,
            createdAt: createdAt,
            participants: participants?.map { $0.toParticipant() } ?? []
        )
    }
}

private struct ParticipantDTO: Decodable {
    let id: UUID
    let challengeId: UUID
    let userId: UUID
    let status: String
    let currentProgress: Int
    let completedAt: Date?
    let isWinner: Bool
    let user: UserDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case userId = "user_id"
        case status
        case currentProgress = "current_progress"
        case completedAt = "completed_at"
        case isWinner = "is_winner"
        case user
    }

    func toParticipant() -> ChallengeParticipant {
        ChallengeParticipant(
            id: id,
            challengeId: challengeId,
            userId: userId,
            userName: user?.fullName ?? user?.username ?? "User",
            avatarUrl: user?.avatarUrl,
            status: status,
            currentProgress: currentProgress,
            completedAt: completedAt,
            isWinner: isWinner
        )
    }
}

private struct UserDTO: Decodable {
    let id: UUID
    let fullName: String?
    let username: String?
    let avatarUrl: String?
    let totalPoints: Int?
    let currentLevel: Int?
    let currentStreak: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case username
        case avatarUrl = "avatar_url"
        case totalPoints = "total_points"
        case currentLevel = "current_level"
        case currentStreak = "current_streak"
    }
}

private struct ChallengeInsert: Encodable {
    let creatorId: UUID
    let challengeType: String
    let title: String
    let description: String?
    let targetValue: Int
    let durationHours: Int
    let stakes: String?
    let status: String
    let xpReward: Int
    let circleId: UUID?

    enum CodingKeys: String, CodingKey {
        case creatorId = "creator_id"
        case challengeType = "challenge_type"
        case title
        case description
        case targetValue = "target_value"
        case durationHours = "duration_hours"
        case stakes
        case status
        case xpReward = "xp_reward"
        case circleId = "circle_id"
    }
}

private struct ParticipantInsert: Encodable {
    let challengeId: UUID
    let userId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case userId = "user_id"
        case status
    }
}

private struct ActivityFeedInsert: Encodable {
    let userId: UUID
    let actionType: String
    let targetUserId: UUID?
    let challengeId: UUID?
    let circleId: UUID?
    let pointsEarned: Int
    let message: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case actionType = "action_type"
        case targetUserId = "target_user_id"
        case challengeId = "challenge_id"
        case circleId = "circle_id"
        case pointsEarned = "points_earned"
        case message
    }
}

// MARK: - Update Structs

private struct ParticipantProgressUpdate: Encodable {
    let currentProgress: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case currentProgress = "current_progress"
        case updatedAt = "updated_at"
    }
}

private struct ChallengeCompletionUpdate: Encodable {
    let status: String
    let winnerId: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case winnerId = "winner_id"
        case updatedAt = "updated_at"
    }
}

private struct ParticipantWinnerUpdate: Encodable {
    let isWinner: Bool
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case isWinner = "is_winner"
        case completedAt = "completed_at"
    }
}
