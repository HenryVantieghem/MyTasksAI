//
//  FriendService.swift
//  Veloce
//
//  Friend Service - Manages friend connections and requests
//  Part of Velocity Circles social feature
//

import Foundation
import Supabase

// MARK: - Friend Service

@MainActor
@Observable
final class FriendService {
    // MARK: Singleton
    static let shared = FriendService()

    // MARK: State
    var friends: [Friendship] = []
    var pendingRequests: [Friendship] = []  // Requests TO me
    var sentRequests: [Friendship] = []     // Requests FROM me
    var isLoading = false
    var error: String?

    // MARK: Dependencies
    private let supabase = SupabaseService.shared

    // MARK: Computed
    var pendingCount: Int { pendingRequests.count }
    var friendCount: Int { friends.count }

    // MARK: Initialization
    private init() {}

    // MARK: - Load All Friendships

    /// Load all friendships for the current user
    func loadFriendships() async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw FriendServiceError.notAuthenticated
            }

            // Fetch all friendships where user is involved
            let response: [Friendship] = try await client
                .from("friendships")
                .select("""
                    *,
                    requester:users!friendships_requester_id_fkey(id, username, full_name, avatar_url, current_streak, current_level),
                    addressee:users!friendships_addressee_id_fkey(id, username, full_name, avatar_url, current_streak, current_level)
                """)
                .or("requester_id.eq.\(userId),addressee_id.eq.\(userId)")
                .order("created_at", ascending: false)
                .execute()
                .value

            // Categorize friendships
            friends = response.filter { $0.status == .accepted }
            pendingRequests = response.filter { $0.status == .pending && $0.addresseeId == userId }
            sentRequests = response.filter { $0.status == .pending && $0.requesterId == userId }

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Search Users

    /// Search for users by username
    func searchByUsername(_ username: String) async throws -> [FriendProfile] {
        guard supabase.isConfigured else { return [] }
        guard !username.isEmpty else { return [] }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw FriendServiceError.notAuthenticated
            }

            // Search by username (case-insensitive via username_lowercase)
            let searchTerm = username.lowercased()
            let response: [FriendProfile] = try await client
                .from("users")
                .select("id, username, full_name, avatar_url, current_streak, current_level")
                .ilike("username_lowercase", pattern: "%\(searchTerm)%")
                .neq("id", value: currentUserId)  // Exclude self
                .limit(10)
                .execute()
                .value

            return response
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Send Friend Request

    /// Send a friend request to another user
    func sendFriendRequest(to userId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw FriendServiceError.notAuthenticated
            }

            // Check if friendship already exists
            let existing: [Friendship] = try await client
                .from("friendships")
                .select()
                .or("and(requester_id.eq.\(currentUserId),addressee_id.eq.\(userId)),and(requester_id.eq.\(userId),addressee_id.eq.\(currentUserId))")
                .execute()
                .value

            if !existing.isEmpty {
                throw FriendServiceError.requestAlreadyExists
            }

            // Create friend request
            let request = FriendRequest(requesterId: currentUserId, addresseeId: userId)
            try await client
                .from("friendships")
                .insert(request)
                .execute()

            // Reload friendships
            try await loadFriendships()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Respond to Request

    /// Accept or decline a friend request
    func respondToRequest(_ friendshipId: UUID, accept: Bool) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()

            let update = FriendshipUpdate(status: accept ? .accepted : .declined)
            try await client
                .from("friendships")
                .update(update)
                .eq("id", value: friendshipId)
                .execute()

            // Reload friendships
            try await loadFriendships()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Remove Friend

    /// Remove a friend (delete friendship)
    func removeFriend(_ friendshipId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()

            try await client
                .from("friendships")
                .delete()
                .eq("id", value: friendshipId)
                .execute()

            // Reload friendships
            try await loadFriendships()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Cancel Request

    /// Cancel a sent friend request
    func cancelRequest(_ friendshipId: UUID) async throws {
        try await removeFriend(friendshipId)
    }

    // MARK: - Block User

    /// Block a user
    func blockUser(_ friendshipId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()

            let update = FriendshipUpdate(status: .blocked)
            try await client
                .from("friendships")
                .update(update)
                .eq("id", value: friendshipId)
                .execute()

            // Reload friendships
            try await loadFriendships()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Get Friend Profile

    /// Get detailed profile for a friend
    func getFriendProfile(_ userId: UUID) async throws -> FriendProfile? {
        guard supabase.isConfigured else { return nil }

        do {
            let client = try supabase.getClient()

            let response: [FriendProfile] = try await client
                .from("users")
                .select("id, username, full_name, avatar_url, current_streak, current_level, total_points")
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            return response.first
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
}

// MARK: - Errors

enum FriendServiceError: LocalizedError {
    case notAuthenticated
    case requestAlreadyExists
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to manage friends"
        case .requestAlreadyExists:
            return "A friend request already exists with this user"
        case .userNotFound:
            return "User not found"
        }
    }
}
