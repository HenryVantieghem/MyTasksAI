//
//  PactDetailView.swift
//  Veloce
//
//  Pact Detail View - Full view of a pact with streak visualization,
//  history, milestones, and actions
//

import SwiftUI

// MARK: - Pact Detail View

struct PactDetailView: View {
    let pact: Pact
    let currentUserId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var pactService = PactService.shared
    @State private var showEndConfirmation = false
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.CelestialColors.void
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Streak hero
                        streakHero
                            .padding(.top, 20)

                        // Today's status
                        todayStatus

                        // Partner info
                        partnerSection

                        // Stats grid
                        statsGrid

                        // Milestones
                        if !pact.milestonesReached.isEmpty {
                            milestonesSection
                        }

                        // Actions
                        actionsSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Pact Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
            .confirmationDialog(
                "End Pact",
                isPresented: $showEndConfirmation,
                titleVisibility: .visible
            ) {
                Button("End Pact", role: .destructive) {
                    endPact()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will end the pact without breaking your streak. Both of you will keep your progress.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Streak Hero

    private var streakHero: some View {
        VStack(spacing: 16) {
            // Large flame with streak count
            ZStack {
                // Glow effect
                Circle()
                    .fill(streakColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                // Flame icon
                Image(systemName: pact.currentStreak > 7 ? "flame.fill" : "flame")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(streakGradient)
                    .symbolEffect(.bounce, value: pact.bothCompletedToday)

                // Streak number
                Text("\(pact.currentStreak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: 50)
            }

            // Label
            VStack(spacing: 4) {
                Text("Day Streak")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                if let next = pact.nextMilestone, let days = pact.daysUntilNextMilestone {
                    Text("\(days) days until \(next)-day milestone")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Best streak
            if pact.longestStreak > pact.currentStreak {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12))
                    Text("Best: \(pact.longestStreak) days")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Theme.Colors.streakGold)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
    }

    private var streakColor: Color {
        switch pact.currentStreak {
        case 0: return .gray
        case 1...6: return .orange
        case 7...29: return Theme.Colors.streakGold
        case 30...99: return Theme.Colors.completionMint
        default: return Theme.Colors.aiPurple
        }
    }

    private var streakGradient: LinearGradient {
        switch pact.currentStreak {
        case 0:
            return LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .bottom, endPoint: .top)
        case 1...6:
            return LinearGradient(colors: [.red, .orange, .yellow], startPoint: .bottom, endPoint: .top)
        case 7...29:
            return LinearGradient(colors: [.orange, Theme.Colors.streakGold], startPoint: .bottom, endPoint: .top)
        case 30...99:
            return LinearGradient(colors: [Theme.Colors.streakGold, Theme.Colors.completionMint], startPoint: .bottom, endPoint: .top)
        default:
            return LinearGradient(colors: [Theme.Colors.aiPurple, .cyan], startPoint: .bottom, endPoint: .top)
        }
    }

    // MARK: - Today's Status

    private var todayStatus: some View {
        VStack(spacing: 12) {
            Text("Today's Progress")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 20) {
                // You
                VStack(spacing: 8) {
                    statusCircle(completed: pact.hasCurrentUserCompletedToday(currentUserId: currentUserId))
                    Text("You")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Connection
                Rectangle()
                    .fill(
                        pact.bothCompletedToday
                            ? Theme.Colors.completionMint
                            : .white.opacity(0.2)
                    )
                    .frame(width: 60, height: 2)

                // Partner
                VStack(spacing: 8) {
                    statusCircle(completed: pact.hasPartnerCompletedToday(currentUserId: currentUserId))
                    Text(partner?.displayName ?? "Partner")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            // Status message
            Text(statusMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(statusColor)
                .padding(.top, 4)
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statusCircle(completed: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(completed ? Theme.Colors.completionMint : .white.opacity(0.2), lineWidth: 3)
                .frame(width: 50, height: 50)

            if completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.completionMint)
            } else {
                Image(systemName: "hourglass")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var statusMessage: String {
        let status = pact.statusForUser(currentUserId: currentUserId)
        switch status {
        case .bothDone: return "You both completed today!"
        case .waitingOnPartner: return "Waiting on your partner..."
        case .waitingOnYou: return "Your turn! Don't let them down."
        case .neitherDone: return "Neither of you has completed yet"
        case .inactive: return "Pact is not active"
        }
    }

    private var statusColor: Color {
        let status = pact.statusForUser(currentUserId: currentUserId)
        switch status {
        case .bothDone: return Theme.Colors.completionMint
        case .waitingOnPartner: return .blue
        case .waitingOnYou: return .orange
        case .neitherDone: return .white.opacity(0.5)
        case .inactive: return .gray
        }
    }

    // MARK: - Partner Section

    private var partnerSection: some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(partnerInitials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Pact with \(partner?.displayName ?? "Partner")")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Text(pact.commitmentDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Shield indicator
            if pact.shieldActive {
                Image(systemName: "shield.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            PactStatCard(
                icon: "calendar",
                value: "\(daysSinceStart)",
                label: "Days Active"
            )

            PactStatCard(
                icon: "star.fill",
                value: "\(pact.xpEarned)",
                label: "XP Earned"
            )

            PactStatCard(
                icon: "trophy.fill",
                value: "\(pact.longestStreak)",
                label: "Best Streak"
            )

            PactStatCard(
                icon: "flag.fill",
                value: "\(pact.milestonesReached.count)",
                label: "Milestones"
            )
        }
    }

    private var daysSinceStart: Int {
        guard let createdAt = pact.createdAt else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        return max(days, 1)
    }

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones Reached")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 10) {
                ForEach(pact.milestonesReached, id: \.self) { days in
                    PactMilestoneBadge(days: days)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 10) {
            // End pact button
            Button {
                showEndConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("End Pact")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            Text("Ending the pact won't affect your streak history")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Helpers

    private var partner: FriendProfile? {
        pact.partnerProfile(currentUserId: currentUserId)
    }

    private var partnerInitials: String {
        let name = partner?.displayName ?? "??"
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func endPact() {
        isProcessing = true
        Task {
            do {
                try await pactService.endPact(pact.id)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to end pact: \(error)")
                isProcessing = false
            }
        }
    }
}

// MARK: - Pact Stat Card

private struct PactStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.Colors.aiPurple)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Pact Milestone Badge

private struct PactMilestoneBadge: View {
    let days: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badgeIcon)
                .font(.system(size: 12))

            Text("\(days)")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(badgeColor.opacity(0.15), in: Capsule())
    }

    private var badgeIcon: String {
        switch days {
        case 7: return "star.fill"
        case 30: return "flame.fill"
        case 100: return "crown.fill"
        default: return "flag.fill"
        }
    }

    private var badgeColor: Color {
        switch days {
        case 7: return .orange
        case 30: return Theme.Colors.streakGold
        case 100: return Theme.Colors.aiPurple
        default: return .white
        }
    }
}

// MARK: - Preview

#Preview {
    PactDetailView(
        pact: Pact(
            id: UUID(),
            initiatorId: UUID(),
            partnerId: UUID(),
            commitmentType: .dailyTasks,
            targetValue: 3,
            customDescription: nil,
            status: .active,
            acceptedAt: .now,
            brokenAt: nil,
            brokenByUserId: nil,
            currentStreak: 12,
            longestStreak: 15,
            initiatorCompletedToday: true,
            partnerCompletedToday: false,
            lastCheckedDate: nil,
            shieldActive: false,
            shieldUsedAt: nil,
            xpEarned: 850,
            milestonesReached: [7],
            createdAt: Calendar.current.date(byAdding: .day, value: -15, to: .now),
            updatedAt: nil,
            initiator: nil,
            partner: FriendProfile(
                id: UUID(),
                username: "sarah",
                fullName: "Sarah Smith",
                avatarUrl: nil,
                currentStreak: 8,
                currentLevel: 4,
                totalPoints: 800,
                tasksCompletedToday: 2
            )
        ),
        currentUserId: UUID()
    )
}
