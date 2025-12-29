//
//  PactCardView.swift
//  Veloce
//
//  Pact Card View - Displays a mutual accountability pact
//  Shows partner, streak, and today's status
//

import SwiftUI

// MARK: - Pact Card View

struct PactCardView: View {
    let pact: Pact
    let currentUserId: UUID

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Partner Avatar
            partnerAvatar

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Partner name and commitment
                HStack {
                    Text(partnerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    // Streak badge
                    streakBadge
                }

                // Commitment description
                Text(pact.commitmentDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)

                // Today's status
                statusIndicator
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusBorderColor.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
    }

    // MARK: - Partner Avatar

    private var partnerAvatar: some View {
        ZStack {
            // Outer ring based on status
            Circle()
                .stroke(statusColor, lineWidth: 2)
                .frame(width: 50, height: 50)

            // Avatar or initials
            if let avatarUrl = partner?.avatarUrl, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }

            // Status indicator dot
            Circle()
                .fill(statusColor)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.3), lineWidth: 2)
                )
                .offset(x: 18, y: 18)
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .overlay(
                Text(partnerInitials)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            )
    }

    // MARK: - Streak Badge

    private var streakBadge: some View {
        HStack(spacing: 4) {
            // Flame icon with intensity
            Image(systemName: pact.currentStreak > 7 ? "flame.fill" : "flame")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(streakColor)
                .symbolEffect(.pulse, options: .repeating, value: pact.bothCompletedToday)

            Text("\(pact.currentStreak)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(streakColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(streakColor.opacity(0.15), in: Capsule())
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

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 6) {
            // Status icon
            Image(systemName: userStatus.icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(statusColor)

            // Status text
            Text(userStatus.displayText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(statusColor)

            Spacer()

            // Progress toward today's goal (if not both done)
            if userStatus != .bothDone && userStatus != .inactive {
                progressIndicator
            }

            // Shield indicator if active
            if pact.shieldActive {
                Image(systemName: "shield.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }
        }
        .padding(.top, 4)
    }

    private var progressIndicator: some View {
        HStack(spacing: 4) {
            // You
            Circle()
                .fill(pact.hasCurrentUserCompletedToday(currentUserId: currentUserId) ? Theme.Colors.completionMint : .gray.opacity(0.3))
                .frame(width: 8, height: 8)

            // Partner
            Circle()
                .fill(pact.hasPartnerCompletedToday(currentUserId: currentUserId) ? Theme.Colors.completionMint : .gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Computed Properties

    private var partner: FriendProfile? {
        pact.partnerProfile(currentUserId: currentUserId)
    }

    private var partnerName: String {
        partner?.displayName ?? "Partner"
    }

    private var partnerInitials: String {
        let name = partnerName
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }

    private var userStatus: PactUserStatus {
        pact.statusForUser(currentUserId: currentUserId)
    }

    private var statusColor: Color {
        switch userStatus {
        case .bothDone: return Theme.Colors.completionMint
        case .waitingOnPartner: return .blue
        case .waitingOnYou: return .orange
        case .neitherDone: return .gray
        case .inactive: return .gray
        }
    }

    private var statusBorderColor: Color {
        if pact.bothCompletedToday {
            return Theme.Colors.completionMint
        } else if userStatus == .waitingOnYou {
            return .orange
        }
        return .clear
    }
}

// MARK: - Pact Invitation Banner

struct PactInvitationBanner: View {
    let pact: Pact
    let currentUserId: UUID
    let onAccept: () -> Void
    let onDecline: () -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Initiator avatar
                initiatorAvatar

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(initiatorName) wants to start a Pact!")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(pact.commitmentDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    isProcessing = true
                    onDecline()
                } label: {
                    Text("Decline")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .glassEffect(.regular, in: Capsule())
                .disabled(isProcessing)

                Button {
                    isProcessing = true
                    onAccept()
                } label: {
                    Text("Accept Pact")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.aiPurple, in: Capsule())
                }
                .disabled(isProcessing)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
        )
    }

    private var initiatorAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .overlay(
                Text(initiatorInitials)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            )
    }

    private var initiator: FriendProfile? {
        pact.initiator
    }

    private var initiatorName: String {
        initiator?.displayName ?? "Someone"
    }

    private var initiatorInitials: String {
        let name = initiatorName
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

// MARK: - Pact Status Indicator (Compact)

struct PactStatusIndicator: View {
    let pact: Pact
    let currentUserId: UUID

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10, weight: .medium))

            Text(statusText)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.15), in: Capsule())
    }

    private var userStatus: PactUserStatus {
        pact.statusForUser(currentUserId: currentUserId)
    }

    private var statusIcon: String {
        if pact.shieldActive {
            return "shield.fill"
        }
        return userStatus.icon
    }

    private var statusText: String {
        if pact.shieldActive {
            return "Protected"
        }
        return userStatus.displayText
    }

    private var statusColor: Color {
        if pact.shieldActive {
            return Theme.Colors.aiPurple
        }
        switch userStatus {
        case .bothDone: return Theme.Colors.completionMint
        case .waitingOnPartner: return .blue
        case .waitingOnYou: return .orange
        case .neitherDone: return .gray
        case .inactive: return .gray
        }
    }
}

// MARK: - Pact Streak Flame

struct PactStreakFlame: View {
    let streak: Int
    let isAnimated: Bool

    var body: some View {
        HStack(spacing: 6) {
            // Flame with gradient based on streak
            Image(systemName: streak > 7 ? "flame.fill" : "flame")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(flameGradient)
                .symbolEffect(.bounce, value: isAnimated)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(streak)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("day streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var flameGradient: LinearGradient {
        switch streak {
        case 0:
            return LinearGradient(colors: [.gray], startPoint: .bottom, endPoint: .top)
        case 1...6:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top)
        case 7...29:
            return LinearGradient(colors: [.orange, Theme.Colors.streakGold], startPoint: .bottom, endPoint: .top)
        case 30...99:
            return LinearGradient(colors: [Theme.Colors.streakGold, Theme.Colors.completionMint], startPoint: .bottom, endPoint: .top)
        default:
            return LinearGradient(colors: [Theme.Colors.aiPurple, .cyan], startPoint: .bottom, endPoint: .top)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            PactCardView(
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
                    longestStreak: 12,
                    initiatorCompletedToday: true,
                    partnerCompletedToday: false,
                    lastCheckedDate: nil,
                    shieldActive: false,
                    shieldUsedAt: nil,
                    xpEarned: 500,
                    milestonesReached: [7],
                    createdAt: .now,
                    updatedAt: nil,
                    initiator: FriendProfile(
                        id: UUID(),
                        username: "john",
                        fullName: "John Doe",
                        avatarUrl: nil,
                        currentStreak: 10,
                        currentLevel: 5,
                        totalPoints: 1000,
                        tasksCompletedToday: 3
                    ),
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
            .padding(.horizontal)

            PactStreakFlame(streak: 12, isAnimated: true)
        }
    }
}
