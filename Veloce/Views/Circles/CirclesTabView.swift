//
//  CirclesTabView.swift
//  Veloce
//
//  Circles Tab View - Main view for Velocity Circles
//  Social accountability groups and friend management
//

import SwiftUI

// MARK: - Circles Tab View

struct CirclesTabView: View {
    // MARK: State
    @State private var friendService = FriendService.shared
    @State private var circleService = CircleService.shared
    @State private var showAddFriend = false
    @State private var showCreateCircle = false
    @State private var showJoinCircle = false
    @State private var selectedCircle: Circle?
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Friend Requests Banner (if any pending)
                    if friendService.pendingCount > 0 {
                        friendRequestsBanner
                    }

                    // My Circles Section
                    circlesSection

                    // Friends Section
                    friendsSection

                    // Empty state if needed
                    if circleService.circles.isEmpty && friendService.friends.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 120) // Space for tab bar
            }
            .refreshable {
                await refreshData()
            }
            .overlay(alignment: .bottomTrailing) {
                fabButton
            }
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
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiPurple.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Friend Requests")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("\(friendService.pendingCount) pending")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Circles Section

    private var circlesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("My Circles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                if !circleService.circles.isEmpty {
                    Menu {
                        Button {
                            showCreateCircle = true
                        } label: {
                            Label("Create Circle", systemImage: "plus.circle")
                        }

                        Button {
                            showJoinCircle = true
                        } label: {
                            Label("Join with Code", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }
                }
            }

            if circleService.circles.isEmpty {
                // Empty circles state
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "person.3")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text("No circles yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    HStack(spacing: Theme.Spacing.sm) {
                        Button {
                            showCreateCircle = true
                        } label: {
                            Text("Create")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.aiPurple, in: Capsule())
                        }

                        Button {
                            showJoinCircle = true
                        } label: {
                            Text("Join")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.aiPurple)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background {
                                    Capsule()
                                        .strokeBorder(Theme.Colors.aiPurple, lineWidth: 1.5)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xl)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            } else {
                // Circle cards
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(circleService.circles) { circle in
                        CircleCardView(circle: circle)
                            .onTapGesture {
                                selectedCircle = circle
                            }
                    }
                }
            }
        }
    }

    // MARK: - Friends Section

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Friends")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("(\(friendService.friendCount))")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer()

                Button {
                    showAddFriend = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            if friendService.friends.isEmpty {
                // Empty friends state
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Add friends to see their progress")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Button {
                        showAddFriend = true
                    } label: {
                        Label("Find Friends", systemImage: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
            } else {
                // Friend list
                LazyVStack(spacing: Theme.Spacing.xs) {
                    ForEach(friendService.friends) { friendship in
                        if let friend = friendship.otherUser(currentUserId: getCurrentUserId()) {
                            FriendRowView(friend: friend)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Theme.Spacing.xs) {
                Text("Welcome to Circles")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Connect with friends and stay accountable together")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, Theme.Spacing.xxl)
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Menu {
            Button {
                showAddFriend = true
            } label: {
                Label("Add Friend", systemImage: "person.badge.plus")
            }

            Button {
                showCreateCircle = true
            } label: {
                Label("Create Circle", systemImage: "plus.circle")
            }

            Button {
                showJoinCircle = true
            } label: {
                Label("Join Circle", systemImage: "link")
            }
        } label: {
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiPurple)
                    .frame(width: 56, height: 56)
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.trailing, Theme.Spacing.lg)
        .padding(.bottom, 100) // Above tab bar
    }

    // MARK: - Helpers

    private func loadData() async {
        do {
            try await friendService.loadFriendships()
            try await circleService.loadCircles()
        } catch {
            print("Error loading circles data: \(error)")
        }
    }

    private func refreshData() async {
        isRefreshing = true
        await loadData()
        isRefreshing = false
    }

    private func getCurrentUserId() -> UUID {
        // TODO: Get from auth service
        UUID()
    }
}

// MARK: - Circle Card View

struct CircleCardView: View {
    let circle: Circle

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Circle avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text(circle.name.prefix(2).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(circle.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: Theme.Spacing.sm) {
                    Label("\(circle.memberCount)", systemImage: "person.2")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    if circle.circleStreak > 0 {
                        Label("\(circle.circleStreak)", systemImage: "flame")
                            .font(.system(size: 13))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Friend Row View

struct FriendRowView: View {
    let friend: FriendProfile

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.backgroundSecondary)
                    .frame(width: 44, height: 44)

                Text(friend.displayName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.Colors.textPrimary)

                if let username = friend.atUsername {
                    Text(username)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer()

            // Streak indicator
            if let streak = friend.currentStreak, streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("\(streak)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    CirclesTabView()
}
