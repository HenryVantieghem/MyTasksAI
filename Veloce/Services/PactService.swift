//
//  PactService.swift
//  Veloce
//
//  Pact Service - Manages mutual accountability pacts
//  If one person fails, both lose the streak
//

import Foundation
import Supabase

// MARK: - Pact Service

@MainActor
@Observable
final class PactService {
    // MARK: Singleton
    static let shared = PactService()

    // MARK: State
    var activePacts: [Pact] = []
    var pendingPacts: [Pact] = []      // Pacts awaiting my acceptance
    var sentPacts: [Pact] = []          // Pacts I've sent, awaiting partner
    var brokenPacts: [Pact] = []        // Recently broken pacts
    var isLoading = false
    var error: String?

    // MARK: Dependencies
    private let supabase = SupabaseService.shared

    // MARK: Computed
    var pendingCount: Int { pendingPacts.count }
    var activeCount: Int { activePacts.count }
    var hasActivePacts: Bool { !activePacts.isEmpty }
    var hasPendingInvitations: Bool { !pendingPacts.isEmpty }

    // MARK: Initialization
    private init() {}

    // MARK: - Load All Pacts

    /// Load all pacts for the current user
    func loadPacts() async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else {
                throw PactServiceError.notAuthenticated
            }

            // Fetch all pacts where user is involved
            let response: [Pact] = try await client
                .from("pacts")
                .select("""
                    *,
                    initiator:users!pacts_initiator_id_fkey(id, username, full_name, avatar_url, current_streak, current_level, total_points),
                    partner:users!pacts_partner_id_fkey(id, username, full_name, avatar_url, current_streak, current_level, total_points)
                """)
                .or("initiator_id.eq.\(userId),partner_id.eq.\(userId)")
                .order("created_at", ascending: false)
                .execute()
                .value

            // Categorize pacts
            activePacts = response.filter { $0.status == .active }
            pendingPacts = response.filter { $0.status == .pending && $0.partnerId == userId }
            sentPacts = response.filter { $0.status == .pending && $0.initiatorId == userId }
            brokenPacts = response.filter { $0.status == .broken }

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Create Pact

    /// Create a new pact with a friend
    func createPact(
        partnerId: UUID,
        commitmentType: PactCommitmentType,
        targetValue: Int,
        customDescription: String? = nil
    ) async throws -> Pact {
        guard supabase.isConfigured else {
            throw PactServiceError.notConfigured
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw PactServiceError.notAuthenticated
            }

            // Check if pact already exists with this partner
            let existing: [Pact] = try await client
                .from("pacts")
                .select()
                .or("and(initiator_id.eq.\(currentUserId),partner_id.eq.\(partnerId)),and(initiator_id.eq.\(partnerId),partner_id.eq.\(currentUserId))")
                .in("status", values: ["pending", "active"])
                .execute()
                .value

            if !existing.isEmpty {
                throw PactServiceError.pactAlreadyExists
            }

            // Create pact request
            let request = CreatePactRequest(
                initiatorId: currentUserId,
                partnerId: partnerId,
                commitmentType: commitmentType,
                targetValue: targetValue,
                customDescription: customDescription
            )

            let pact: Pact = try await client
                .from("pacts")
                .insert(request)
                .select("""
                    *,
                    initiator:users!pacts_initiator_id_fkey(id, username, full_name, avatar_url, current_streak, current_level, total_points),
                    partner:users!pacts_partner_id_fkey(id, username, full_name, avatar_url, current_streak, current_level, total_points)
                """)
                .single()
                .execute()
                .value

            // Log activity
            try await logActivity(pactId: pact.id, userId: currentUserId, type: .created)

            // Reload pacts
            try await loadPacts()

            return pact

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Accept Pact

    /// Accept a pending pact invitation
    func acceptPact(_ pactId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw PactServiceError.notAuthenticated
            }

            let update = UpdatePactRequest(status: .active, acceptedAt: .now)
            try await client
                .from("pacts")
                .update(update)
                .eq("id", value: pactId)
                .eq("partner_id", value: currentUserId)  // Only partner can accept
                .eq("status", value: "pending")
                .execute()

            // Log activity
            try await logActivity(pactId: pactId, userId: currentUserId, type: .accepted)

            // Reload pacts
            try await loadPacts()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Decline Pact

    /// Decline a pending pact invitation
    func declinePact(_ pactId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw PactServiceError.notAuthenticated
            }

            // Delete the pact (declined pacts are removed)
            try await client
                .from("pacts")
                .delete()
                .eq("id", value: pactId)
                .eq("partner_id", value: currentUserId)
                .eq("status", value: "pending")
                .execute()

            // Reload pacts
            try await loadPacts()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Cancel Pact

    /// Cancel a pact I initiated (while still pending)
    func cancelPact(_ pactId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw PactServiceError.notAuthenticated
            }

            try await client
                .from("pacts")
                .delete()
                .eq("id", value: pactId)
                .eq("initiator_id", value: currentUserId)
                .eq("status", value: "pending")
                .execute()

            // Reload pacts
            try await loadPacts()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - End Pact

    /// Mutually end an active pact (no streak break)
    func endPact(_ pactId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw PactServiceError.notAuthenticated
            }

            let update = UpdatePactRequest(status: .completed)
            try await client
                .from("pacts")
                .update(update)
                .eq("id", value: pactId)
                .eq("status", value: "active")
                .execute()

            // Log activity
            try await logActivity(pactId: pactId, userId: currentUserId, type: .completed)

            // Reload pacts
            try await loadPacts()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Record Progress

    /// Record that user completed their daily commitment
    func recordProgress(pactId: UUID, completed: Bool) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw PactServiceError.notAuthenticated
            }

            // Find the pact
            guard let pact = activePacts.first(where: { $0.id == pactId }) else {
                throw PactServiceError.pactNotFound
            }

            // Determine which field to update
            let isInitiator = pact.initiatorId == currentUserId

            var update: UpdatePactRequest
            if isInitiator {
                update = UpdatePactRequest(initiatorCompletedToday: completed)
            } else {
                update = UpdatePactRequest(partnerCompletedToday: completed)
            }

            try await client
                .from("pacts")
                .update(update)
                .eq("id", value: pactId)
                .execute()

            // Log activity if completed
            if completed {
                try await logActivity(pactId: pactId, userId: currentUserId, type: .progress)
            }

            // Reload pacts
            try await loadPacts()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Check Completion Status

    /// Check if user has met their pact commitment for today
    func checkDailyCompletion(for commitmentType: PactCommitmentType, targetValue: Int, currentValue: Int) -> Bool {
        return currentValue >= targetValue
    }

    /// Check and update all active pacts for task completion
    func checkTaskPactProgress(tasksCompletedToday: Int) async {
        for pact in activePacts {
            if pact.commitmentType == .dailyTasks {
                let completed = checkDailyCompletion(
                    for: pact.commitmentType,
                    targetValue: pact.targetValue,
                    currentValue: tasksCompletedToday
                )

                do {
                    // Get current user ID
                    let client = try supabase.getClient()
                    guard let currentUserId = try await client.auth.session.user.id as UUID? else { continue }

                    // Only update if status changed
                    let currentlyCompleted = pact.hasCurrentUserCompletedToday(currentUserId: currentUserId)
                    if completed && !currentlyCompleted {
                        try await recordProgress(pactId: pact.id, completed: true)
                    }
                } catch {
                    print("Error updating pact progress: \(error)")
                }
            }
        }
    }

    /// Check and update all active pacts for focus time
    func checkFocusPactProgress(focusMinutesToday: Int) async {
        for pact in activePacts {
            if pact.commitmentType == .focusTime {
                let completed = checkDailyCompletion(
                    for: pact.commitmentType,
                    targetValue: pact.targetValue,
                    currentValue: focusMinutesToday
                )

                do {
                    let client = try supabase.getClient()
                    guard let currentUserId = try await client.auth.session.user.id as UUID? else { continue }

                    let currentlyCompleted = pact.hasCurrentUserCompletedToday(currentUserId: currentUserId)
                    if completed && !currentlyCompleted {
                        try await recordProgress(pactId: pact.id, completed: true)
                    }
                } catch {
                    print("Error updating pact progress: \(error)")
                }
            }
        }
    }

    // MARK: - Activate Shield

    /// Activate Pact Shield power-up to protect both users for one day
    func activateShield(pactId: UUID) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            guard let currentUserId = try await client.auth.session.user.id as UUID? else {
                throw PactServiceError.notAuthenticated
            }

            let update = UpdatePactRequest(shieldActive: true)
            try await client
                .from("pacts")
                .update(update)
                .eq("id", value: pactId)
                .eq("status", value: "active")
                .execute()

            // Log activity
            try await logActivity(pactId: pactId, userId: currentUserId, type: .shieldUsed)

            // Reload pacts
            try await loadPacts()

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Get Pact

    /// Get a specific pact by ID
    func getPact(_ pactId: UUID) -> Pact? {
        return activePacts.first(where: { $0.id == pactId })
            ?? pendingPacts.first(where: { $0.id == pactId })
            ?? sentPacts.first(where: { $0.id == pactId })
            ?? brokenPacts.first(where: { $0.id == pactId })
    }

    // MARK: - Activity Logging

    /// Log pact activity
    private func logActivity(pactId: UUID, userId: UUID, type: PactActivityType, details: [String: String]? = nil) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()

            struct ActivityLog: Codable {
                let pactId: UUID
                let userId: UUID
                let activityType: String
                let details: [String: String]?

                enum CodingKeys: String, CodingKey {
                    case pactId = "pact_id"
                    case userId = "user_id"
                    case activityType = "activity_type"
                    case details
                }
            }

            let log = ActivityLog(
                pactId: pactId,
                userId: userId,
                activityType: type.rawValue,
                details: details
            )

            try await client
                .from("pact_activity")
                .insert(log)
                .execute()

        } catch {
            // Don't throw - activity logging is secondary
            print("Failed to log pact activity: \(error)")
        }
    }

    // MARK: - Real-time Updates

    private var realtimeChannel: RealtimeChannelV2?

    /// Subscribe to real-time pact updates
    func subscribeToUpdates() async {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            let channel = client.realtimeV2.channel("pacts_\(userId)")

            let changes = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "pacts"
            )

            try await channel.subscribeWithError()

            Task {
                for await _ in changes {
                    // Reload pacts when any change occurs
                    try? await self.loadPacts()
                }
            }

            realtimeChannel = channel

        } catch {
            print("Failed to subscribe to pact updates: \(error)")
        }
    }

    /// Unsubscribe from real-time updates
    func unsubscribe() async {
        await realtimeChannel?.unsubscribe()
        realtimeChannel = nil
    }
}

// MARK: - Errors

enum PactServiceError: LocalizedError {
    case notAuthenticated
    case notConfigured
    case pactAlreadyExists
    case pactNotFound
    case notPactMember
    case invalidStatus

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to manage pacts"
        case .notConfigured:
            return "Service is not configured"
        case .pactAlreadyExists:
            return "You already have a pact with this person"
        case .pactNotFound:
            return "Pact not found"
        case .notPactMember:
            return "You are not a member of this pact"
        case .invalidStatus:
            return "Invalid pact status for this action"
        }
    }
}
