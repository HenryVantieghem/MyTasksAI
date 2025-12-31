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
    @State private var pactService = PactService.shared
    @State private var showAddFriend = false
    @State private var showCreateCircle = false
    @State private var showJoinCircle = false
    @State private var showCreatePact = false
    @State private var selectedCircle: SocialCircle?
    @State private var selectedPact: Pact?
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            // Living Cosmos background
            VoidBackground.circles

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Pact Invitations Banner (if any pending)
                    if pactService.hasPendingInvitations {
                        pactInvitationsBanner
                    }

                    // Friend Requests Banner (if any pending)
                    if friendService.pendingCount > 0 {
                        friendRequestsBanner
                    }

                    // My Pacts Section (NEW - Top priority)
                    pactsSection

                    // My Circles Section
                    circlesSection

                    // Friends Section
                    friendsSection

                    // Empty state if needed
                    if circleService.circles.isEmpty && friendService.friends.isEmpty && pactService.activePacts.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.universalHeaderHeight + Theme.Spacing.md)
                .padding(.bottom, 120) // Space for tab bar
            }
            .refreshable {
                await refreshData()
            }
            .overlay(alignment: .bottomTrailing) {
                fabButton
            }
        }
        .preferredColorScheme(.dark)
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
        .sheet(isPresented: $showCreatePact) {
            CreatePactSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedPact) { pact in
            PactDetailView(pact: pact, currentUserId: getCurrentUserId())
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Pact Invitations Banner

    private var pactInvitationsBanner: some View {
        VStack(spacing: 10) {
            ForEach(pactService.pendingPacts) { pact in
                PactInvitationBanner(
                    pact: pact,
                    currentUserId: getCurrentUserId(),
                    onAccept: {
                        Task {
                            try? await pactService.acceptPact(pact.id)
                        }
                    },
                    onDecline: {
                        Task {
                            try? await pactService.declinePact(pact.id)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Pacts Section

    private var pactsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("My Pacts")
                    .dynamicTypeFont(base: 20, weight: .bold)
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if pactService.hasActivePacts {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .dynamicTypeFont(base: 12)
                        Text("\(pactService.activeCount)")
                            .dynamicTypeFont(base: 14, weight: .semibold)
                    }
                    .foregroundStyle(.orange)
                }

                Spacer()

                if !friendService.friends.isEmpty {
                    Button {
                        showCreatePact = true
                    } label: {
                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 16, weight: .semibold)
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }
                }
            }

            if pactService.activePacts.isEmpty && pactService.sentPacts.isEmpty {
                // Empty pacts state
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "link.circle")
                        .dynamicTypeFont(base: 36, weight: .light)
                        .foregroundStyle(.white.opacity(0.3))

                    VStack(spacing: 4) {
                        Text("No pacts yet")
                            .dynamicTypeFont(base: 15, weight: .medium)
                            .foregroundStyle(.white.opacity(0.6))

                        Text("Start a mutual accountability streak with a friend")
                            .dynamicTypeFont(base: 13)
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }

                    if !friendService.friends.isEmpty {
                        Button {
                            showCreatePact = true
                        } label: {
                            Text("Start a Pact")
                                .dynamicTypeFont(base: 14, weight: .semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Theme.Colors.aiPurple, in: Capsule())
                        }
                    } else {
                        Text("Add friends first to start a pact")
                            .dynamicTypeFont(base: 12)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
            } else {
                // Active pacts
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(pactService.activePacts) { pact in
                        PactCardView(pact: pact, currentUserId: getCurrentUserId())
                            .onTapGesture {
                                selectedPact = pact
                            }
                    }

                    // Sent pacts (pending acceptance)
                    ForEach(pactService.sentPacts) { pact in
                        SentPactCard(pact: pact, currentUserId: getCurrentUserId())
                    }
                }
            }
        }
    }

    // MARK: - Friend Requests Banner (Liquid Glass)

    private var friendRequestsBanner: some View {
        NavigationLink {
            FriendRequestsView()
        } label: {
            HStack(spacing: 14) {
                // Icon with accent
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiPurple.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "person.badge.plus")
                        .dynamicTypeFont(base: 18, weight: .medium)
                        .foregroundStyle(Theme.Colors.aiPurple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Friend Requests")
                        .dynamicTypeFont(base: 15, weight: .semibold)
                        .foregroundStyle(.white)

                    Text("\(friendService.pendingCount) pending")
                        .dynamicTypeFont(base: 13, weight: .medium)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Badge with count
                Text("\(friendService.pendingCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.aiPurple, in: Capsule())
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Circles Section

    private var circlesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("My Circles")
                    .dynamicTypeFont(base: 20, weight: .bold)
                    .foregroundStyle(Theme.CelestialColors.starWhite)

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
                            .dynamicTypeFont(base: 16, weight: .semibold)
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }
                }
            }

            if circleService.circles.isEmpty {
                // Empty circles state with Liquid Glass
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "person.3")
                        .dynamicTypeFont(base: 36, weight: .light)
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No circles yet")
                        .dynamicTypeFont(base: 15, weight: .medium)
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(spacing: 10) {
                        Button {
                            showCreateCircle = true
                        } label: {
                            Text("Create")
                                .dynamicTypeFont(base: 14, weight: .semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Theme.Colors.aiPurple, in: Capsule())
                        }

                        Button {
                            showJoinCircle = true
                        } label: {
                            Text("Join")
                                .dynamicTypeFont(base: 14, weight: .semibold)
                                .foregroundStyle(Theme.Colors.aiPurple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                        .glassEffect(.regular, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal, 20)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
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
                    .dynamicTypeFont(base: 20, weight: .bold)
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("(\(friendService.friendCount))")
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(Theme.CelestialColors.starGhost)

                Spacer()

                Button {
                    showAddFriend = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .dynamicTypeFont(base: 16, weight: .semibold)
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            if friendService.friends.isEmpty {
                // Empty friends state
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Add friends to see their progress")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Button {
                        showAddFriend = true
                    } label: {
                        Label("Find Friends", systemImage: "magnifyingglass")
                            .dynamicTypeFont(base: 14, weight: .semibold)
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
                .dynamicTypeFont(base: 60, weight: .ultraLight)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Theme.Spacing.xs) {
                Text("Welcome to Circles")
                    .dynamicTypeFont(base: 24, weight: .bold)
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Connect with friends and stay accountable together")
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, Theme.Spacing.xxl)
    }

    // MARK: - FAB Button (Liquid Glass)

    private var fabButton: some View {
        Menu {
            Button {
                showCreatePact = true
            } label: {
                Label("Start a Pact", systemImage: "link.badge.plus")
            }

            Divider()

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
                // Accent background
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.3))
                    .frame(width: 56, height: 56)

                Image(systemName: "plus")
                    .dynamicTypeFont(base: 22, weight: .semibold)
                    .foregroundStyle(.white)
            }
            .glassEffect(.regular, in: SwiftUI.Circle())
            .shadow(color: Theme.Colors.aiPurple.opacity(0.3), radius: 12, y: 4)
        }
        .padding(.trailing, Theme.Spacing.lg)
        .padding(.bottom, 100)
    }

    // MARK: - Helpers

    private func loadData() async {
        do {
            try await friendService.loadFriendships()
            try await circleService.loadCircles()
            try await pactService.loadPacts()
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
        SupabaseService.shared.currentUserId ?? UUID()
    }
}

// MARK: - Circle Card View (Liquid Glass)

struct CircleCardView: View {
    let circle: SocialCircle

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Circle avatar with gradient
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Text(circle.name.prefix(2).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(circle.name)
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .dynamicTypeFont(base: 11)
                        Text("\(circle.memberCount)")
                            .dynamicTypeFont(base: 12, weight: .medium)
                    }
                    .foregroundStyle(.white.opacity(0.5))

                    if circle.circleStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .dynamicTypeFont(base: 11)
                            Text("\(circle.circleStreak)")
                                .dynamicTypeFont(base: 12, weight: .semibold)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .dynamicTypeFont(base: 12, weight: .semibold)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
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
                    .fill(Theme.CelestialColors.void)
                    .frame(width: 44, height: 44)

                Text(friend.displayName.prefix(1).uppercased())
                    .dynamicTypeFont(base: 18, weight: .semibold)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .dynamicTypeFont(base: 15, weight: .medium)
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if let username = friend.atUsername {
                    Text(username)
                        .dynamicTypeFont(base: 13)
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }
            }

            Spacer()

            // Streak indicator
            if let streak = friend.currentStreak, streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .dynamicTypeFont(base: 12)
                    Text("\(streak)")
                        .dynamicTypeFont(base: 13, weight: .semibold)
                }
                .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Sent Pact Card (Pending Acceptance)

struct SentPactCard: View {
    let pact: Pact
    let currentUserId: UUID

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Partner Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text(partnerInitials)
                        .dynamicTypeFont(base: 14, weight: .bold)
                        .foregroundStyle(.white.opacity(0.7))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Pact with \(partnerName)")
                    .dynamicTypeFont(base: 15, weight: .medium)
                    .foregroundStyle(.white.opacity(0.8))

                Text("Waiting for acceptance...")
                    .dynamicTypeFont(base: 13)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Image(systemName: "hourglass")
                .dynamicTypeFont(base: 14)
                .foregroundStyle(.yellow.opacity(0.6))
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .opacity(0.7)
    }

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
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Preview

#Preview {
    CirclesTabView()
}
