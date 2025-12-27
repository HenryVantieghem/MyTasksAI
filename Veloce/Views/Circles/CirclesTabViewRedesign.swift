//
//  CirclesTabViewRedesign.swift
//  Veloce
//
//  Circles - Social Accountability Arena
//  Make productivity a team sport with friends, circles, and challenges
//
//  Design Philosophy: Competitive but friendly - celestial arcade meets social media
//  Visual Language: Orbiting avatars, pulsing challenge cards, live activity streams
//

import SwiftUI

// MARK: - Circles Tab Segment

enum CirclesTabSegment: String, CaseIterable, Identifiable {
    case friends = "Friends"
    case circles = "Circles"
    case challenges = "Challenges"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .friends: return "person.2.fill"
        case .circles: return "circle.hexagongrid.fill"
        case .challenges: return "trophy.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .friends: return Theme.CelestialColors.plasmaCore
        case .circles: return Theme.Colors.aiPurple
        case .challenges: return Theme.CelestialColors.solarFlare
        }
    }
}

// MARK: - Circles Tab View Redesign

struct CirclesTabViewRedesign: View {
    // Services
    @State private var friendService = FriendService.shared
    @State private var circleService = CircleService.shared

    // Tab state
    @State private var selectedTab: CirclesTabSegment = .friends

    // Sheet states
    @State private var showAddFriend = false
    @State private var showCreateCircle = false
    @State private var showJoinCircle = false
    @State private var showSendChallenge = false
    @State private var selectedFriend: FriendProfile?
    @State private var selectedCircle: SocialCircle?
    @State private var selectedChallenge: Challenge?

    // Leaderboard state
    @State private var showLeaderboard = false
    @State private var leaderboardMode = false

    // Animation states
    @State private var headerGlow: CGFloat = 0.5
    @State private var pulsePhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Cosmic background with dynamic glow based on tab
            CirclesCosmicBackground(accentColor: selectedTab.accentColor)

            VStack(spacing: 0) {
                // Header with XP badge
                circlesHeader

                // Animated tab selector
                tabSelector
                    .padding(.top, 8)

                // Tab content
                tabContent
            }

            // FAB based on current tab
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fabButton
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
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
        .sheet(isPresented: $showSendChallenge) {
            SendChallengeSheet(preselectedFriend: selectedFriend)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedFriend) { friend in
            FriendProfileSheet(friend: friend, onSendChallenge: {
                selectedFriend = friend
                showSendChallenge = true
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedCircle) { circle in
            CircleDetailViewRedesign(circle: circle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailSheet(challenge: challenge)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLeaderboard) {
            FriendsLeaderboardSheet()
        }
        .task {
            await loadData()
            startAnimations()
        }
    }

    // MARK: - Header

    private var circlesHeader: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            // Circles title with orbital rings
            ZStack {
                // Outer glow ring
                if !reduceMotion {
                    SwiftUI.Circle()
                        .stroke(selectedTab.accentColor.opacity(0.3 * headerGlow), lineWidth: 2)
                        .frame(width: 48, height: 48)
                        .scaleEffect(1 + (headerGlow * 0.1))
                }

                // Icon
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [selectedTab.accentColor, selectedTab.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Circles")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Spacer()

            // XP Badge with pulse
            xpBadge

            // Pending requests indicator
            if friendService.pendingCount > 0 {
                NavigationLink {
                    FriendRequestsView()
                } label: {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.aiPurple.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.Colors.aiPurple)

                        // Notification dot
                        SwiftUI.Circle()
                            .fill(Theme.CelestialColors.errorNebula)
                            .frame(width: 10, height: 10)
                            .offset(x: 12, y: -12)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    private var xpBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.Colors.xp)

            Text("2,450")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Theme.Colors.xp.opacity(0.15))
                .overlay {
                    Capsule()
                        .strokeBorder(Theme.Colors.xp.opacity(0.3), lineWidth: 1)
                }
        }
        .shadow(color: Theme.Colors.xp.opacity(0.3), radius: 8, y: 2)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(CirclesTabSegment.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
        .padding(.horizontal, 20)
    }

    private func tabButton(for tab: CirclesTabSegment) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(selectedTab == tab ? .white : Theme.CelestialColors.starDim)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if selectedTab == tab {
                    Capsule()
                        .fill(tab.accentColor)
                        .shadow(color: tab.accentColor.opacity(0.4), radius: 8, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            FriendsArenaView(
                friendService: friendService,
                leaderboardMode: $leaderboardMode,
                onFriendSelected: { friend in selectedFriend = friend },
                onShowLeaderboard: { showLeaderboard = true }
            )
            .tag(CirclesTabSegment.friends)

            CirclesTabContent(
                circleService: circleService,
                onCircleSelected: { circle in selectedCircle = circle },
                onCreateCircle: { showCreateCircle = true },
                onJoinCircle: { showJoinCircle = true }
            )
            .tag(CirclesTabSegment.circles)

            ChallengesTabContent(
                onChallengeSelected: { challenge in selectedChallenge = challenge },
                onCreateChallenge: { showSendChallenge = true }
            )
            .tag(CirclesTabSegment.challenges)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Menu {
            switch selectedTab {
            case .friends:
                Button {
                    showAddFriend = true
                } label: {
                    Label("Add Friend", systemImage: "person.badge.plus")
                }

                Button {
                    showSendChallenge = true
                } label: {
                    Label("Challenge a Friend", systemImage: "bolt.fill")
                }

            case .circles:
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

            case .challenges:
                Button {
                    showSendChallenge = true
                } label: {
                    Label("New Challenge", systemImage: "trophy")
                }
            }
        } label: {
            ZStack {
                // Outer glow ring
                SwiftUI.Circle()
                    .fill(selectedTab.accentColor.opacity(0.3))
                    .frame(width: 64, height: 64)
                    .blur(radius: 8)

                // Main button
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [selectedTab.accentColor, selectedTab.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: selectedTab.accentColor.opacity(0.5), radius: 12, y: 4)

                Image(systemName: fabIcon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var fabIcon: String {
        switch selectedTab {
        case .friends: return "person.badge.plus"
        case .circles: return "plus"
        case .challenges: return "bolt.fill"
        }
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

    private func startAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            headerGlow = 1
        }
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            pulsePhase = 1
        }
    }
}

// MARK: - Cosmic Background

struct CirclesCosmicBackground: View {
    let accentColor: Color

    @State private var starPositions: [CGPoint] = []
    @State private var orbitalPhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep void base
                Theme.CelestialColors.void
                    .ignoresSafeArea()

                // Accent gradient glow
                RadialGradient(
                    colors: [
                        accentColor.opacity(0.15),
                        accentColor.opacity(0.05),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.8
                )
                .ignoresSafeArea()

                // Secondary glow bottom left
                RadialGradient(
                    colors: [
                        Theme.Colors.aiPurple.opacity(0.1),
                        Color.clear
                    ],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.6
                )
                .ignoresSafeArea()

                // Subtle star field
                ForEach(0..<20, id: \.self) { i in
                    let pos = starPositions.indices.contains(i) ? starPositions[i] : CGPoint(x: 0, y: 0)
                    SwiftUI.Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                        .frame(width: CGFloat.random(in: 1...2.5))
                        .position(pos)
                }

                // Orbital ring decoration
                if !reduceMotion {
                    orbitalRings(in: geo.size)
                }
            }
            .onAppear {
                starPositions = (0..<20).map { _ in
                    CGPoint(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
                }

                if !reduceMotion {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        orbitalPhase = 1
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func orbitalRings(in size: CGSize) -> some View {
        SwiftUI.Circle()
            .stroke(accentColor.opacity(0.05), lineWidth: 1)
            .frame(width: size.width * 1.5)
            .rotationEffect(.degrees(orbitalPhase * 360))
            .offset(x: size.width * 0.3, y: -size.height * 0.2)

        SwiftUI.Circle()
            .stroke(Theme.Colors.aiPurple.opacity(0.03), lineWidth: 0.5)
            .frame(width: size.width * 2)
            .rotationEffect(.degrees(-orbitalPhase * 180))
            .offset(x: -size.width * 0.4, y: size.height * 0.3)
    }
}

// MARK: - Preview

#Preview {
    CirclesTabViewRedesign()
}
