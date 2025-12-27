//
//  SharedTaskService.swift
//  Veloce
//
//  Shared Task Service - Manages collaborative task sharing between friends
//  Part of Velocity Circles social feature
//

import Foundation
import Supabase

// MARK: - Shared Task Service

@MainActor
@Observable
final class SharedTaskService {
    // MARK: Singleton
    static let shared = SharedTaskService()

    // MARK: State
    var incomingInvitations: [SharedTask] = []   // Pending invitations TO me
    var sentInvitations: [SharedTask] = []        // Pending invitations FROM me
    var sharedWithMe: [SharedTask] = []           // Accepted tasks shared with me
    var tasksIShared: [SharedTask] = []           // Accepted tasks I shared with others
    var leaderboard: [LeaderboardEntry] = []      // Friend leaderboard
    var isLoading = false
    var error: String?

    // MARK: Dependencies
    private let supabase = SupabaseService.shared

    // MARK: Computed
    var pendingCount: Int { incomingInvitations.count }
    var activeSharedCount: Int { sharedWithMe.count + tasksIShared.count }

    // MARK: Initialization
    private init() {}

    // MARK: - Load All Shared Tasks

    /// Load all shared tasks for the current user
    func loadSharedTasks() async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw SharedTaskServiceError.notAuthenticated
            }

            // Fetch all shared tasks where user is involved
            let response: [SharedTask] = try await client
                .from("shared_tasks")
                .select("""
                    *,
                    tasks!shared_tasks_task_id_fkey(
                        id, title, is_completed, scheduled_time, estimated_minutes,
                        star_rating, task_icon, task_emoji, task_color_hex, completed_at, points_earned
                    ),
                    inviter:users!shared_tasks_inviter_id_fkey(
                        id, username, full_name, avatar_url, current_streak, current_level, total_points
                    ),
                    invitee:users!shared_tasks_invitee_id_fkey(
                        id, username, full_name, avatar_url, current_streak, current_level, total_points
                    )
                """)
                .or("inviter_id.eq.\(userId),invitee_id.eq.\(userId)")
                .order("invited_at", ascending: false)
                .execute()
                .value

            // Categorize shared tasks
            incomingInvitations = response.filter { $0.status == .pending && $0.inviteeId == userId }
            sentInvitations = response.filter { $0.status == .pending && $0.inviterId == userId }
            sharedWithMe = response.filter { $0.status == .accepted && $0.inviteeId == userId }
            tasksIShared = response.filter { $0.status == .accepted && $0.inviterId == userId }

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Invite Friend to Task

    /// Invite a friend to collaborate on a task
    func inviteFriendToTask(taskId: UUID, friendId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw SharedTaskServiceError.notAuthenticated
            }

            // Check if already shared with this friend
            let existing: [SharedTask] = try await client
                .from("shared_tasks")
                .select()
                .eq("task_id", value: taskId)
                .eq("invitee_id", value: friendId)
                .execute()
                .value

            if !existing.isEmpty {
                throw SharedTaskServiceError.alreadyShared
            }

            // Create shared task invitation
            let request = CreateSharedTaskRequest(
                taskId: taskId,
                inviterId: currentUserId,
                inviteeId: friendId
            )
            try await client
                .from("shared_tasks")
                .insert(request)
                .execute()

            // Update task's sharing status
            try await client
                .from("tasks")
                .update(["is_shared": true])
                .eq("id", value: taskId)
                .execute()

            // Reload shared tasks
            try await loadSharedTasks()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Respond to Invitation

    /// Accept or decline a task sharing invitation
    func respondToInvitation(_ sharedTaskId: UUID, accept: Bool) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()

            let update = SharedTaskUpdate(status: accept ? .accepted : .declined)
            try await client
                .from("shared_tasks")
                .update(update)
                .eq("id", value: sharedTaskId)
                .execute()

            // Update shared_with_count on the task
            if accept {
                // Find the task ID for this shared task
                let sharedTask = incomingInvitations.first { $0.id == sharedTaskId }
                if let taskId = sharedTask?.taskId {
                    // Get current count and increment
                    let countResponse: [[String: Int]] = try await client
                        .from("tasks")
                        .select("shared_with_count")
                        .eq("id", value: taskId)
                        .limit(1)
                        .execute()
                        .value

                    let currentCount = countResponse.first?["shared_with_count"] ?? 0
                    try await client
                        .from("tasks")
                        .update(["shared_with_count": currentCount + 1])
                        .eq("id", value: taskId)
                        .execute()
                }
            }

            // Reload shared tasks
            try await loadSharedTasks()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Cancel Invitation

    /// Cancel a sent task invitation (before response)
    func cancelInvitation(_ sharedTaskId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()

            try await client
                .from("shared_tasks")
                .delete()
                .eq("id", value: sharedTaskId)
                .execute()

            // Reload shared tasks
            try await loadSharedTasks()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Remove Collaborator

    /// Remove a collaborator from a shared task
    func removeCollaborator(_ sharedTaskId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()

            // Get the shared task to update the count
            let sharedTask = tasksIShared.first { $0.id == sharedTaskId } ??
                             sharedWithMe.first { $0.id == sharedTaskId }

            try await client
                .from("shared_tasks")
                .delete()
                .eq("id", value: sharedTaskId)
                .execute()

            // Update shared_with_count on the task
            if let taskId = sharedTask?.taskId {
                let countResponse: [[String: Int]] = try await client
                    .from("tasks")
                    .select("shared_with_count")
                    .eq("id", value: taskId)
                    .limit(1)
                    .execute()
                    .value

                let currentCount = countResponse.first?["shared_with_count"] ?? 1
                let newCount = max(0, currentCount - 1)

                // Update shared_with_count
                try await client
                    .from("tasks")
                    .update(["shared_with_count": newCount])
                    .eq("id", value: taskId)
                    .execute()

                // Update is_shared flag
                try await client
                    .from("tasks")
                    .update(["is_shared": newCount > 0])
                    .eq("id", value: taskId)
                    .execute()
            }

            // Reload shared tasks
            try await loadSharedTasks()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Get Collaborators for Task

    /// Get all collaborators for a specific task
    func getCollaborators(forTask taskId: UUID) async throws -> [FriendProfile] {
        guard supabase.isConfigured else { return [] }

        do {
            let client = try supabase.getClient()

            let response: [SharedTask] = try await client
                .from("shared_tasks")
                .select("""
                    *,
                    invitee:users!shared_tasks_invitee_id_fkey(
                        id, username, full_name, avatar_url, current_streak, current_level
                    )
                """)
                .eq("task_id", value: taskId)
                .eq("status", value: "accepted")
                .execute()
                .value

            return response.compactMap { $0.invitee }
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Load Friend Leaderboard

    /// Load leaderboard data for friends
    func loadLeaderboard(period: LeaderboardPeriod = .week) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw SharedTaskServiceError.notAuthenticated
            }

            // Get friend IDs first
            let friendships: [Friendship] = try await client
                .from("friendships")
                .select("requester_id, addressee_id")
                .eq("status", value: "accepted")
                .or("requester_id.eq.\(userId),addressee_id.eq.\(userId)")
                .execute()
                .value

            // Extract friend IDs
            var friendIds = Set<UUID>()
            for friendship in friendships {
                if friendship.requesterId == userId {
                    friendIds.insert(friendship.addresseeId)
                } else {
                    friendIds.insert(friendship.requesterId)
                }
            }
            friendIds.insert(userId)  // Include self

            guard !friendIds.isEmpty else {
                leaderboard = []
                return
            }

            // Query the friend_leaderboard view
            let friendIdStrings = friendIds.map { $0.uuidString }
            var entries: [LeaderboardEntry] = try await client
                .from("friend_leaderboard")
                .select()
                .in("id", values: friendIdStrings)
                .order(period.sortKey, ascending: false)
                .execute()
                .value

            // Add rank and mark current user
            for (index, _) in entries.enumerated() {
                entries[index].rank = index + 1
                entries[index].isCurrentUser = entries[index].id == userId
                // For now, no rank change data (would need historical tracking)
                entries[index].rankChange = 0
            }

            leaderboard = entries

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Notify Task Completion

    /// Notify collaborators when a shared task is completed
    func notifyTaskCompletion(taskId: UUID) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw SharedTaskServiceError.notAuthenticated
            }

            // Get all collaborators for this task
            let sharedTasks: [SharedTask] = try await client
                .from("shared_tasks")
                .select("""
                    *,
                    inviter:users!shared_tasks_inviter_id_fkey(id),
                    invitee:users!shared_tasks_invitee_id_fkey(id)
                """)
                .eq("task_id", value: taskId)
                .eq("status", value: "accepted")
                .execute()
                .value

            // This is where push notifications would be sent
            // For now, we rely on real-time subscriptions in the app
            // Future: Add push notification integration here

            // The sync_shared_task_completion trigger in the database
            // handles the completion sync logic

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Check if Task is Shared with Friend

    /// Check if a specific task is already shared with a friend
    func isTaskSharedWith(taskId: UUID, friendId: UUID) async throws -> Bool {
        guard supabase.isConfigured else { return false }

        do {
            let client = try supabase.getClient()

            let response: [SharedTask] = try await client
                .from("shared_tasks")
                .select("id")
                .eq("task_id", value: taskId)
                .eq("invitee_id", value: friendId)
                .limit(1)
                .execute()
                .value

            return !response.isEmpty
        } catch {
            return false
        }
    }
}

// MARK: - Errors

enum SharedTaskServiceError: LocalizedError {
    case notAuthenticated
    case alreadyShared
    case taskNotFound
    case notTaskOwner
    case invitationNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to share tasks"
        case .alreadyShared:
            return "This task is already shared with this friend"
        case .taskNotFound:
            return "Task not found"
        case .notTaskOwner:
            return "You can only share tasks you own"
        case .invitationNotFound:
            return "Invitation not found"
        }
    }
}
