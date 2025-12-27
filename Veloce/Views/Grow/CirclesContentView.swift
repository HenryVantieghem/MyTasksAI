//
//  CirclesContentView.swift
//  Veloce
//
//  Circles segment for Grow tab
//  Social accountability groups and friend management
//  Adapted from CirclesTabView to work as embedded content
//

import SwiftUI

struct CirclesContentView: View {
    // MARK: State
    private var friendService: FriendService { FriendService.shared }
    private var circleService: CircleService { CircleService.shared }
    @State private var showAddFriend = false
    @State private var showCreateCircle = false
    @State private var showJoinCircle = false
    @State private var selectedCircle: SocialCircle?
    @State private var isLoading = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Friend Requests Banner (if any pending)
                if friendService.pendingCount > 0 {
                    friendRequestsBanner
                }

                // My Circles Section
                circlesSection

                // Friends Section
                friendsSection

                // Weekly Leaderboard
                if !friendService.friends.isEmpty {
                    leaderboardSection
                }

                // Empty state if needed
                if circleService.circles.isEmpty && friendService.friends.isEmpty {
                    emptyStateView
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCreateCircle) {
            CreateCircleSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showJoinCircle) {
            JoinCircleSheet()
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedCircle) { circle in
            CircleDetailView(circle: circle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Friend Requests Banner

    private var friendRequestsBanner: some View {
        NavigationLink {
            FriendRequestsView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.aiPurple.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Friend Requests")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("\(friendService.pendingCount) pending")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Text("\(friendService.pendingCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.aiPurple, in: Capsule())
            }
            .padding(14)
            .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Circles Section

    private var circlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Circles")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    showCreateCircle = true
                } label: {
                    Label("Create", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            if circleService.circles.isEmpty {
                // Empty circles prompt
                HStack(spacing: 10) {
                    Button {
                        showCreateCircle = true
                    } label: {
                        Text("Create")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.Colors.aiPurple, in: Capsule())
                    }

                    Button {
                        showJoinCircle = true
                    } label: {
                        Text("Join")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Colors.aiPurple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(circleService.circles) { circle in
                        CircleRowCard(circle: circle) {
                            selectedCircle = circle
                        }
                    }
                }
            }
        }
    }

    // MARK: - Friends Section

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friends")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    showAddFriend = true
                } label: {
                    Label("Add", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            if friendService.friends.isEmpty {
                Text("No friends yet. Add friends to see their progress!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(friendService.friends) { friendship in
                        FriendRowCard(friendship: friendship)
                    }
                }
            }
        }
    }

    // MARK: - Leaderboard Section

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Leaderboard")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                ForEach(Array(friendService.friends.prefix(3).enumerated()), id: \.element.id) { index, friendship in
                    let profile = friendProfile(from: friendship)
                    LeaderboardRow(
                        rank: index + 1,
                        name: profile?.displayName ?? "Friend",
                        tasks: profile?.tasksCompletedToday ?? 0,
                        isYou: false
                    )
                }

                // Add current user
                LeaderboardRow(
                    rank: 2,
                    name: "You",
                    tasks: GamificationService.shared.weeklyActivityData.reduce(0, +),
                    isYou: true
                )
            }
            .padding(16)
            .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func friendProfile(from friendship: Friendship) -> FriendProfile? {
        guard let currentUserId = SupabaseService.shared.currentUserId else { return nil }
        return friendship.otherUser(currentUserId: currentUserId)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))

            Text("Connect with friends")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.6))

            Text("Add friends to compete on leaderboards and join circles for group accountability")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddFriend = true
            } label: {
                Text("Add Friends")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.aiPurple, in: Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        // Services handle their own data loading
        isLoading = false
    }
}

// MARK: - Circle Row Card

struct CircleRowCard: View {
    let circle: SocialCircle
    let onTap: () -> Void

    private var circleInitial: String {
        String(circle.name.prefix(1)).uppercased()
    }

    private var latestActivityText: String? {
        guard let activity = circle.recentActivity?.first else { return nil }
        return activity.message ?? activity.activityType.displayName
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Circle avatar
                Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(circleInitial)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Theme.Colors.aiPurple)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(circle.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)

                        Text("• \(circle.memberCount) members")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let activity = latestActivityText {
                        Text(activity)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Friend Row Card

struct FriendRowCard: View {
    let friendship: Friendship

    private var friendProfile: FriendProfile? {
        guard let currentUserId = SupabaseService.shared.currentUserId else { return nil }
        return friendship.otherUser(currentUserId: currentUserId)
    }

    var body: some View {
        if let friend = friendProfile {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(friend.displayName.prefix(1)))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    )

                Text(friend.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("\(friend.currentStreak ?? 0)")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }

                    Text("\(friend.tasksCompletedToday ?? 0) tasks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let tasks: Int
    var isYou: Bool = false

    private var rankIcon: String {
        switch rank {
        case 1: return "medal.fill" // Gold would be better but using medal
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "\(rank)"
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white
        }
    }

    var body: some View {
        HStack {
            // Rank
            if rank <= 3 {
                Image(systemName: rankIcon)
                    .font(.title3)
                    .foregroundStyle(rankColor)
                    .frame(width: 30)
            } else {
                Text("\(rank)")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 30)
            }

            Text(name)
                .font(.subheadline)
                .fontWeight(isYou ? .semibold : .regular)
                .foregroundStyle(.white)

            if isYou {
                Text("(You)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.aiPurple)
            }

            Spacer()

            Text("\(tasks) tasks")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            Color.black.ignoresSafeArea()
            CirclesContentView()
        }
    }
}
