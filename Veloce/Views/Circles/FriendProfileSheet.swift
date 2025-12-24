//
//  FriendProfileSheet.swift
//  Veloce
//
//  Friend Profile - Full stats view with streak comparison and challenge button
//  Glassmorphic design with orbital avatar and achievement badges
//

import SwiftUI

// MARK: - Friend Profile Sheet

struct FriendProfileSheet: View {
    let friend: FriendProfile
    var onSendChallenge: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showRemoveConfirmation = false
    @State private var orbitPhase: CGFloat = 0
    @State private var glowPhase: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Mock data for comparison
    private let myStreak = 12
    private let myTotalXP = 2450
    private let myTasksToday = 8

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader
                        .padding(.top, 20)

                    // Quick stats
                    quickStatsRow

                    // Streak comparison
                    streakComparison

                    // Recent achievements
                    achievementsSection

                    // Activity feed
                    recentActivitySection

                    // Actions
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Theme.CelestialColors.void.ignoresSafeArea())
            .navigationTitle(friend.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
            .confirmationDialog(
                "Remove Friend",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    removeFriend()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove \(friend.displayName) from your friends?")
            }
            .onAppear {
                startAnimations()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Orbital avatar
            ZStack {
                // Orbital rings
                if !reduceMotion {
                    ForEach(0..<3) { i in
                        SwiftUI.Circle()
                            .stroke(
                                Theme.Colors.aiPurple.opacity(0.1 + Double(i) * 0.05),
                                lineWidth: 1
                            )
                            .frame(width: CGFloat(110 + i * 20), height: CGFloat(110 + i * 20))
                            .rotationEffect(.degrees(orbitPhase * (i % 2 == 0 ? 1 : -1) * 360))
                    }
                }

                // Level progress ring
                SwiftUI.Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 100, height: 100)

                SwiftUI.Circle()
                    .trim(from: 0, to: levelProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                // Avatar
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.CelestialColors.plasmaCore.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)

                    Text(friend.displayName.prefix(1).uppercased())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                }

                // Online indicator
                if friend.isActiveNow {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.CelestialColors.auroraGreen)
                            .frame(width: 18, height: 18)

                        if !reduceMotion {
                            SwiftUI.Circle()
                                .fill(Theme.CelestialColors.auroraGreen.opacity(0.3 * glowPhase))
                                .frame(width: 24, height: 24)
                                .blur(radius: 4)
                        }
                    }
                    .overlay {
                        SwiftUI.Circle()
                            .stroke(Theme.CelestialColors.void, lineWidth: 3)
                    }
                    .offset(x: 38, y: 38)
                }
            }

            // Name and username
            VStack(spacing: 4) {
                Text(friend.displayName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if let username = friend.atUsername {
                    Text(username)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }
            }

            // Level badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.xp)

                Text("Level \(friend.currentLevel ?? 1)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("•")
                    .foregroundStyle(Theme.CelestialColors.starGhost)

                Text("\(friend.totalPoints ?? 0) XP")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            // Status
            HStack(spacing: 6) {
                SwiftUI.Circle()
                    .fill(friend.isActiveNow ? Theme.CelestialColors.auroraGreen : Theme.CelestialColors.starGhost)
                    .frame(width: 8, height: 8)

                Text(friend.isActiveNow ? "Active now" : "Last active \(friend.formattedLastActive)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
        }
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            quickStat(
                icon: "checkmark.circle.fill",
                value: "\(friend.todayTasksCompleted ?? 0)",
                label: "Today",
                color: Theme.CelestialColors.auroraGreen
            )

            quickStat(
                icon: "timer",
                value: formatFocusTime(friend.todayFocusMinutes ?? 0),
                label: "Focus",
                color: Theme.CelestialColors.plasmaCore
            )

            quickStat(
                icon: "flame.fill",
                value: "\(friend.currentStreak ?? 0)",
                label: "Streak",
                color: Theme.Colors.streakOrange
            )

            quickStat(
                icon: "trophy.fill",
                value: "\(friend.challengesWon ?? 0)",
                label: "Wins",
                color: Theme.Colors.xp
            )
        }
    }

    private func quickStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                SwiftUI.Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }

            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak Comparison

    private var streakComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Battle")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            HStack(spacing: 20) {
                // Friend's streak
                VStack(spacing: 8) {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.streakOrange.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Text("\(friend.currentStreak ?? 0)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.Colors.streakOrange)
                    }

                    Text(friend.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                // VS
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.streakOrange)

                    Text("VS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }

                // Your streak
                VStack(spacing: 8) {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.aiPurple.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Text("\(myStreak)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }

                    Text("You")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
            }

            // Comparison result
            HStack {
                Spacer()

                if myStreak > (friend.currentStreak ?? 0) {
                    Label("You're ahead!", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                } else if myStreak < (friend.currentStreak ?? 0) {
                    Label("\(friend.displayName) is ahead", systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.streakOrange)
                } else {
                    Label("You're tied!", systemImage: "equal.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.plasmaCore)
                }

                Spacer()
            }
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Achievements")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()

                Text("View All")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    achievementBadge(icon: "flame.fill", title: "7-Day Streak", color: Theme.Colors.streakOrange)
                    achievementBadge(icon: "star.fill", title: "1000 XP", color: Theme.Colors.xp)
                    achievementBadge(icon: "checkmark.seal.fill", title: "50 Tasks", color: Theme.CelestialColors.auroraGreen)
                    achievementBadge(icon: "trophy.fill", title: "Challenge Victor", color: Theme.Colors.aiPurple)
                }
            }
        }
    }

    private func achievementBadge(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                SwiftUI.Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .lineLimit(1)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            VStack(spacing: 8) {
                activityRow(icon: "checkmark.circle.fill", text: "Completed \"Build feature\"", time: "2m ago", color: Theme.CelestialColors.auroraGreen)
                activityRow(icon: "timer", text: "Finished 45min focus session", time: "1h ago", color: Theme.CelestialColors.plasmaCore)
                activityRow(icon: "flame.fill", text: "Extended streak to \(friend.currentStreak ?? 0) days", time: "5h ago", color: Theme.Colors.streakOrange)
            }
        }
    }

    private func activityRow(icon: String, text: String, time: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15), in: SwiftUI.Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .lineLimit(1)

            Spacer()

            Text(time)
                .font(.system(size: 11))
                .foregroundStyle(Theme.CelestialColors.starGhost)
        }
        .padding(10)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Send challenge button
            Button(action: onSendChallenge) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16))

                    Text("Send Challenge")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Theme.CelestialColors.solarFlare, Theme.Colors.streakOrange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .shadow(color: Theme.CelestialColors.solarFlare.opacity(0.4), radius: 12, y: 4)
            }

            // Remove friend button
            Button {
                showRemoveConfirmation = true
            } label: {
                Text("Remove Friend")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.errorNebula)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private var levelProgress: CGFloat {
        CGFloat(Double(friend.totalPoints ?? 0).truncatingRemainder(dividingBy: 1000) / 1000)
    }

    private func formatFocusTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            orbitPhase = 1
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }
    }

    private func removeFriend() {
        // TODO: Remove friend via service
        dismiss()
    }
}

// MARK: - Friend Profile Extensions

extension FriendProfile {
    var formattedLastActive: String {
        // TODO: Add lastActiveDate to FriendProfile model when backend supports it
        "recently"
    }

    var challengesWon: Int? {
        // Placeholder - would come from backend
        3
    }
}

// MARK: - Preview

#Preview {
    FriendProfileSheet(
        friend: FriendProfile(
            id: UUID(),
            username: "alex_j",
            fullName: "Alex Johnson",
            avatarUrl: nil,
            currentStreak: 7,
            currentLevel: 5,
            totalPoints: 1250,
            tasksCompletedToday: 5
        ),
        onSendChallenge: { }
    )
}
