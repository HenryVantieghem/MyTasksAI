//
//  FriendsTabContent.swift
//  Veloce
//
//  Friends Tab - Your Productivity Squad
//  Large avatar cards with live stats, online indicators, and leaderboard toggle
//
//  Design: Orbital friend cards with plasma-core energy indicators
//

import SwiftUI

// MARK: - Friends Tab Content

struct FriendsTabContent: View {
    let friendService: FriendService
    @Binding var leaderboardMode: Bool
    var onFriendSelected: (FriendProfile) -> Void
    var onShowLeaderboard: () -> Void

    @State private var selectedFilter: FriendsFilter = .all
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // View toggle and filter
                viewModeToggle
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Content based on mode
                if leaderboardMode {
                    leaderboardView
                } else {
                    friendCardsGrid
                }

                // Empty state
                if filteredFriends.isEmpty && !friendService.isLoading {
                    emptyFriendsState
                }
            }
            .padding(.bottom, 120)
        }
    }

    // MARK: - Filtered Friends

    private var filteredFriends: [Friendship] {
        var friends = friendService.friends

        // Apply search
        if !searchText.isEmpty {
            friends = friends.filter { friendship in
                let friend = friendship.otherUser(currentUserId: getCurrentUserId())
                return friend?.displayName.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            friends = friends.filter { friendship in
                let friend = friendship.otherUser(currentUserId: getCurrentUserId())
                return friend?.isActiveNow ?? false
            }
        case .topStreak:
            friends = friends.sorted { f1, f2 in
                let s1 = f1.otherUser(currentUserId: getCurrentUserId())?.currentStreak ?? 0
                let s2 = f2.otherUser(currentUserId: getCurrentUserId())?.currentStreak ?? 0
                return s1 > s2
            }
        }

        return friends
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: 12) {
            // Cards / Leaderboard toggle
            HStack(spacing: 0) {
                toggleButton(icon: "square.grid.2x2", isSelected: !leaderboardMode) {
                    withAnimation(.spring(response: 0.3)) {
                        leaderboardMode = false
                    }
                }

                toggleButton(icon: "list.number", isSelected: leaderboardMode) {
                    withAnimation(.spring(response: 0.3)) {
                        leaderboardMode = true
                    }
                }
            }
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            Spacer()

            // Filter menu
            Menu {
                ForEach(FriendsFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack {
                            Text(filter.displayName)
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedFilter.icon)
                        .font(.system(size: 12, weight: .semibold))

                    Text(selectedFilter.displayName)
                        .font(.system(size: 13, weight: .medium))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Theme.CelestialColors.starDim)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05), in: Capsule())
            }
        }
    }

    private func toggleButton(icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starGhost)
                .frame(width: 40, height: 36)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.CelestialColors.plasmaCore.opacity(0.3))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Friend Cards Grid

    private var friendCardsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(filteredFriends) { friendship in
                if let friend = friendship.otherUser(currentUserId: getCurrentUserId()) {
                    FriendCard(friend: friend)
                        .onTapGesture {
                            onFriendSelected(friend)
                        }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Leaderboard View

    private var leaderboardView: some View {
        VStack(spacing: 0) {
            // Leaderboard header
            FriendsLeaderboardHeader(onExpand: onShowLeaderboard)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            // Top 3 podium
            FriendsLeaderboardPodium(friends: topThreeFriends)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Rest of leaderboard
            VStack(spacing: 4) {
                ForEach(Array(rankedFriends.dropFirst(3).enumerated()), id: \.element.id) { index, friendship in
                    if let friend = friendship.otherUser(currentUserId: getCurrentUserId()) {
                        FriendLeaderboardRow(
                            rank: index + 4,
                            friend: friend,
                            isCurrentUser: false
                        )
                        .onTapGesture {
                            onFriendSelected(friend)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var rankedFriends: [Friendship] {
        friendService.friends.sorted { f1, f2 in
            let xp1 = f1.otherUser(currentUserId: getCurrentUserId())?.totalPoints ?? 0
            let xp2 = f2.otherUser(currentUserId: getCurrentUserId())?.totalPoints ?? 0
            return xp1 > xp2
        }
    }

    private var topThreeFriends: [FriendProfile] {
        Array(rankedFriends.prefix(3)).compactMap {
            $0.otherUser(currentUserId: getCurrentUserId())
        }
    }

    // MARK: - Empty State

    private var emptyFriendsState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Orbital illustration
            ZStack {
                ForEach(0..<3) { i in
                    SwiftUI.Circle()
                        .stroke(Theme.CelestialColors.plasmaCore.opacity(0.1 + Double(i) * 0.05), lineWidth: 1)
                        .frame(width: CGFloat(60 + i * 30), height: CGFloat(60 + i * 30))
                }

                Image(systemName: "person.2.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.CelestialColors.plasmaCore, Theme.Colors.aiPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Productivity is better together")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Add friends to compete, collaborate, and stay accountable")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, Theme.Spacing.xxl)
    }

    private func getCurrentUserId() -> UUID {
        // TODO: Get from auth service
        UUID()
    }
}

// MARK: - Friends Filter

enum FriendsFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active Now"
    case topStreak = "Top Streaks"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "person.2"
        case .active: return "circle.fill"
        case .topStreak: return "flame"
        }
    }
}

// MARK: - Friend Card

struct FriendCard: View {
    let friend: FriendProfile

    @State private var glowPhase: CGFloat = 0.5
    @State private var isHovered = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            // Avatar with level ring and online indicator
            ZStack {
                // Level progress ring
                SwiftUI.Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 72, height: 72)

                SwiftUI.Circle()
                    .trim(from: 0, to: levelProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                // Avatar
                if let avatarUrl = friend.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        avatarPlaceholder
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(SwiftUI.Circle())
                } else {
                    avatarPlaceholder
                }

                // Online indicator
                if friend.isActiveNow {
                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.auroraGreen)
                        .frame(width: 14, height: 14)
                        .overlay {
                            SwiftUI.Circle()
                                .stroke(.black, lineWidth: 2)
                        }
                        .offset(x: 26, y: 26)

                    // Glow for active users
                    if !reduceMotion {
                        SwiftUI.Circle()
                            .fill(Theme.CelestialColors.auroraGreen.opacity(0.3 * glowPhase))
                            .frame(width: 18, height: 18)
                            .blur(radius: 4)
                            .offset(x: 26, y: 26)
                    }
                }
            }

            // Name
            Text(friend.displayName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .lineLimit(1)

            // Level badge
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.xp)

                Text("Lv. \(friend.currentLevel ?? 1)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            // Today's stats
            HStack(spacing: 12) {
                statItem(value: "\(friend.todayTasksCompleted ?? 0)", icon: "checkmark.circle", color: Theme.CelestialColors.auroraGreen)
                statItem(value: formatFocusTime(friend.todayFocusMinutes ?? 0), icon: "timer", color: Theme.CelestialColors.plasmaCore)
            }

            // Streak badge if active
            if let streak = friend.currentStreak, streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.streakOrange)

                    Text("\(streak) day streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.streakOrange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.Colors.streakOrange.opacity(0.15), in: Capsule())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            friend.isActiveNow
                            ? Theme.CelestialColors.auroraGreen.opacity(0.3)
                            : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: friend.isActiveNow ? Theme.CelestialColors.auroraGreen.opacity(0.2) : Color.clear, radius: 12)
        .scaleEffect(isHovered ? 1.02 : 1)
        .onAppear {
            guard !reduceMotion, friend.isActiveNow else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.CelestialColors.plasmaCore.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)

            Text(friend.displayName.prefix(1).uppercased())
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)
        }
    }

    private var levelProgress: CGFloat {
        // Placeholder - calculate actual level progress
        CGFloat(Double(friend.totalPoints ?? 0).truncatingRemainder(dividingBy: 1000) / 1000)
    }

    private func statItem(value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
    }

    private func formatFocusTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Leaderboard Header

struct FriendsLeaderboardHeader: View {
    var onExpand: () -> Void

    @State private var selectedMetric: LeaderboardCategory = .xp
    @State private var selectedPeriod: LeaderboardPeriod = .weekly

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Leaderboard")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()

                Button(action: onExpand) {
                    HStack(spacing: 4) {
                        Text("Full View")
                            .font(.system(size: 13, weight: .medium))

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            // Metric selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeaderboardCategory.allCases) { category in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMetric = category
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 11, weight: .bold))

                                Text(category.displayName)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(selectedMetric == category ? .white : Theme.CelestialColors.starDim)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(selectedMetric == category ? category.color : Color.white.opacity(0.05))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Period selector
            HStack(spacing: 0) {
                ForEach(LeaderboardPeriod.allCases) { period in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.displayName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedPeriod == period ? .white : Theme.CelestialColors.starGhost)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                if selectedPeriod == period {
                                    Capsule()
                                        .fill(selectedMetric.color.opacity(0.3))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.white.opacity(0.05), in: Capsule())
        }
    }
}

// MARK: - Leaderboard Podium

struct FriendsLeaderboardPodium: View {
    let friends: [FriendProfile]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 2nd place
            if friends.count > 1 {
                podiumSpot(friend: friends[1], rank: 2, height: 80)
            }

            // 1st place
            if friends.count > 0 {
                podiumSpot(friend: friends[0], rank: 1, height: 100)
            }

            // 3rd place
            if friends.count > 2 {
                podiumSpot(friend: friends[2], rank: 3, height: 60)
            }
        }
    }

    private func podiumSpot(friend: FriendProfile, rank: Int, height: CGFloat) -> some View {
        let colors = rankColors(for: rank)

        return VStack(spacing: 8) {
            // Crown for 1st
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.75, blue: 0.25), Color(red: 0.85, green: 0.55, blue: 0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.98, green: 0.75, blue: 0.25).opacity(0.5), radius: 8)
            }

            // Avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: rank == 1 ? 64 : 52, height: rank == 1 ? 64 : 52)

                Text(friend.displayName.prefix(1).uppercased())
                    .font(.system(size: rank == 1 ? 24 : 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: colors[0].opacity(0.4), radius: 12)

            // Name
            Text(friend.displayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .lineLimit(1)

            // XP
            Text("\(friend.totalPoints ?? 0) XP")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starDim)

            // Podium
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(colors: colors.map { $0.opacity(0.3) }, startPoint: .top, endPoint: .bottom)
                )
                .frame(height: height)
                .overlay(alignment: .top) {
                    Text("\(rank)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(colors[0])
                        .padding(.top, 8)
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func rankColors(for rank: Int) -> [Color] {
        switch rank {
        case 1: return [Color(red: 0.98, green: 0.75, blue: 0.25), Color(red: 0.85, green: 0.55, blue: 0.15)]
        case 2: return [Color(red: 0.75, green: 0.75, blue: 0.80), Color(red: 0.55, green: 0.55, blue: 0.60)]
        case 3: return [Color(red: 0.80, green: 0.50, blue: 0.20), Color(red: 0.60, green: 0.35, blue: 0.12)]
        default: return [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore]
        }
    }
}

// MARK: - Leaderboard Row

struct FriendLeaderboardRow: View {
    let rank: Int
    let friend: FriendProfile
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starGhost)
                .frame(width: 28)

            // Avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.nebulaDust)
                    .frame(width: 40, height: 40)

                Text(friend.displayName.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(friend.displayName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.aiPurple, in: Capsule())
                    }
                }

                if let streak = friend.currentStreak, streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(streak)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.streakOrange)
                }
            }

            Spacer()

            // XP
            Text("\(friend.totalPoints ?? 0) XP")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.Colors.xp)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Theme.Colors.aiPurple.opacity(0.1) : Color.white.opacity(0.03))
        }
    }
}

// MARK: - Friends Leaderboard Sheet

struct FriendsLeaderboardSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LeaderboardSheet()
                .navigationTitle("Friends Leaderboard")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        FriendsTabContent(
            friendService: FriendService.shared,
            leaderboardMode: .constant(false),
            onFriendSelected: { _ in },
            onShowLeaderboard: { }
        )
    }
}
