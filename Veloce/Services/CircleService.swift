//
//  CircleService.swift
//  Veloce
//
//  Circle Service - Manages accountability circles
//  Part of Velocity Circles social feature
//

import Foundation
import Supabase

// MARK: - Circle Service

@MainActor
@Observable
final class CircleService {
    // MARK: Singleton
    static let shared = CircleService()

    // MARK: State
    var circles: [Circle] = []
    var currentCircle: Circle?
    var isLoading = false
    var error: String?

    // MARK: Dependencies
    private let supabase = SupabaseService.shared

    // MARK: Initialization
    private init() {}

    // MARK: - Load Circles

    /// Load all circles the user is a member of
    func loadCircles() async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw CircleServiceError.notAuthenticated
            }

            // First get circle IDs where user is a member
            let memberships: [CircleMember] = try await client
                .from("circle_members")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            let circleIds = memberships.map { $0.circleId }

            guard !circleIds.isEmpty else {
                circles = []
                return
            }

            // Fetch circles with members
            let response: [Circle] = try await client
                .from("circles")
                .select("""
                    *,
                    members:circle_members(
                        *,
                        user:users(id, username, full_name, avatar_url, current_streak, current_level)
                    ),
                    creator:users!circles_created_by_fkey(id, username, full_name, avatar_url)
                """)
                .in("id", values: circleIds)
                .order("created_at", ascending: false)
                .execute()
                .value

            circles = response

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Create Circle

    /// Create a new circle
    func createCircle(name: String, description: String? = nil, maxMembers: Int = 5) async throws -> Circle {
        guard supabase.isConfigured else {
            throw CircleServiceError.notConfigured
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw CircleServiceError.notAuthenticated
            }

            // Create the circle
            let request = CreateCircleRequest(
                name: name,
                description: description,
                createdBy: userId,
                maxMembers: maxMembers
            )

            let newCircle: Circle = try await client
                .from("circles")
                .insert(request)
                .select()
                .single()
                .execute()
                .value

            // Add creator as owner member
            let memberRequest = JoinCircleMemberRequest(
                circleId: newCircle.id,
                userId: userId,
                role: .owner,
                visibility: .momentum
            )

            try await client
                .from("circle_members")
                .insert(memberRequest)
                .execute()

            // Post join activity
            try await postActivity(
                circleId: newCircle.id,
                type: .joined,
                points: 10,
                message: "Created the circle"
            )

            // Reload circles
            try await loadCircles()

            return newCircle

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Join by Invite Code

    /// Join a circle using an invite code
    func joinByInviteCode(_ code: String) async throws -> Circle {
        guard supabase.isConfigured else {
            throw CircleServiceError.notConfigured
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw CircleServiceError.notAuthenticated
            }

            // Find circle by invite code
            let normalizedCode = code.lowercased().trimmingCharacters(in: .whitespaces)
            let circles: [Circle] = try await client
                .from("circles")
                .select("*, members:circle_members(*)")
                .eq("invite_code", value: normalizedCode)
                .limit(1)
                .execute()
                .value

            guard let circle = circles.first else {
                throw CircleServiceError.invalidInviteCode
            }

            // Check if already a member
            let existingMember = circle.members?.first { $0.userId == userId }
            if existingMember != nil {
                throw CircleServiceError.alreadyMember
            }

            // Check if circle is full
            if circle.isFull {
                throw CircleServiceError.circleFull
            }

            // Join the circle
            let memberRequest = JoinCircleMemberRequest(
                circleId: circle.id,
                userId: userId,
                role: .member,
                visibility: .momentum
            )

            try await client
                .from("circle_members")
                .insert(memberRequest)
                .execute()

            // Post join activity
            try await postActivity(
                circleId: circle.id,
                type: .joined,
                points: 5,
                message: "Joined the circle"
            )

            // Reload circles
            try await loadCircles()

            return circle

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Leave Circle

    /// Leave a circle
    func leaveCircle(_ circleId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw CircleServiceError.notAuthenticated
            }

            // Delete membership
            try await client
                .from("circle_members")
                .delete()
                .eq("circle_id", value: circleId)
                .eq("user_id", value: userId)
                .execute()

            // Reload circles
            try await loadCircles()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Invite Friend

    /// Invite a friend to a circle (they still need to join)
    func inviteFriend(_ userId: UUID, to circleId: UUID) async throws {
        // For now, just return the invite code
        // In future: send push notification or in-app invite
        guard let circle = circles.first(where: { $0.id == circleId }) else {
            throw CircleServiceError.circleNotFound
        }

        // Could send notification here
        print("Invite friend \(userId) to circle with code: \(circle.inviteCode)")
    }

    // MARK: - Load Activity Feed

    /// Load activity feed for a circle
    func loadActivity(for circleId: UUID, limit: Int = 50) async throws -> [CircleActivity] {
        guard supabase.isConfigured else { return [] }

        do {
            let client = try supabase.getClient()

            let response: [CircleActivity] = try await client
                .from("circle_activity")
                .select("""
                    *,
                    user:users(id, username, full_name, avatar_url, current_streak, current_level)
                """)
                .eq("circle_id", value: circleId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            return response

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Post Activity

    /// Post an activity to all user's circles
    func postActivity(circleId: UUID, type: CircleActivityType, points: Int, message: String? = nil) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw CircleServiceError.notAuthenticated
            }

            let request = PostActivityRequest(
                circleId: circleId,
                userId: userId,
                type: type,
                points: points,
                message: message
            )

            try await client
                .from("circle_activity")
                .insert(request)
                .execute()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    /// Post activity to all circles user belongs to
    func broadcastActivity(type: CircleActivityType, points: Int, message: String? = nil) async throws {
        guard supabase.isConfigured else { return }

        // Post to each circle
        for circle in circles {
            try await postActivity(circleId: circle.id, type: type, points: points, message: message)
        }
    }

    // MARK: - Update Visibility

    /// Update visibility settings for a circle membership
    func updateVisibility(circleId: UUID, visibility: CircleVisibility) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw CircleServiceError.notAuthenticated
            }

            try await client
                .from("circle_members")
                .update(["visibility": visibility.rawValue])
                .eq("circle_id", value: circleId)
                .eq("user_id", value: userId)
                .execute()

            // Reload circles
            try await loadCircles()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Delete Circle

    /// Delete a circle (owner only)
    func deleteCircle(_ circleId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()

            try await client
                .from("circles")
                .delete()
                .eq("id", value: circleId)
                .execute()

            // Reload circles
            try await loadCircles()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
}

// MARK: - Errors

enum CircleServiceError: LocalizedError {
    case notAuthenticated
    case notConfigured
    case invalidInviteCode
    case alreadyMember
    case circleFull
    case circleNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to manage circles"
        case .notConfigured:
            return "Service not configured"
        case .invalidInviteCode:
            return "Invalid invite code"
        case .alreadyMember:
            return "You're already a member of this circle"
        case .circleFull:
            return "This circle has reached its member limit"
        case .circleNotFound:
            return "Circle not found"
        }
    }
}
