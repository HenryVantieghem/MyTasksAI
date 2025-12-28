//
//  CirclesContentView.swift
//  Veloce
//
//  Premium Circles & Friends Experience
//  Ultra-refined social accountability with Liquid Glass design
//  Beautiful animations, premium cards, and seamless interactions
//

import SwiftUI

// MARK: - Circles Content View

struct CirclesContentView: View {
    // MARK: State
    @Environment(\.responsiveLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var friendService: FriendService { FriendService.shared }
    private var circleService: CircleService { CircleService.shared }

    @State private var showAddFriend = false
    @State private var showCreateCircle = false
    @State private var showJoinCircle = false
    @State private var selectedCircle: SocialCircle?
    @State private var selectedFriend: Friendship?
    @State private var isLoading = false
    @State private var showFriendRequests = false

    // Animation state
    @State private var appearPhase: Double = 0
    @State private var pulsePhase: Double = 0
    @State private var gradientRotation: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Friend Requests Banner
                if friendService.pendingCount > 0 {
                    friendRequestsBanner
                        .padding(.horizontal, layout.screenPadding)
                        .padding(.bottom, 20)
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                }

                // Circles Section
                circlesSection
                    .padding(.bottom, 28)

                // Friends Section
                friendsSection
                    .padding(.bottom, 28)

                // Activity Feed
                if !circleService.circles.isEmpty {
                    activityFeedSection
                        .padding(.bottom, 28)
                }

                // Empty State
                if circleService.circles.isEmpty && friendService.friends.isEmpty && !isLoading {
                    emptyStateView
                        .padding(.horizontal, layout.screenPadding)
                }

                Spacer(minLength: layout.bottomSafeArea + 20)
            }
            .padding(.top, 16)
        }
        .refreshable {
            await loadData()
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showCreateCircle) {
            CreateCircleSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: showCreateCircle) { wasShowing, isShowing in
            if wasShowing && !isShowing {
                Task { try? await circleService.loadCircles() }
            }
        }
        .onChange(of: showJoinCircle) { wasShowing, isShowing in
            if wasShowing && !isShowing {
                Task { try? await circleService.loadCircles() }
            }
        }
        .sheet(isPresented: $showJoinCircle) {
            JoinCircleSheet()
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(item: $selectedCircle) { circle in
            CircleDetailView(circle: circle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFriendRequests) {
            FriendRequestsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await loadData()
            startAnimations()
        }
    }

    // MARK: - Friend Requests Banner

    private var friendRequestsBanner: some View {
        Button {
            showFriendRequests = true
            HapticsService.shared.impact(.light)
        } label: {
            HStack(spacing: 14) {
                // Animated icon container
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(
                            Theme.Colors.aiPurple.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 48, height: 48)
                        .scaleEffect(1 + pulsePhase * 0.1)
                        .opacity(1 - pulsePhase * 0.5)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.Colors.aiPurple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Friend Requests")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("\(friendService.pendingCount) people want to connect")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()

                // Count badge
                Text("\(friendService.pendingCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Theme.Colors.aiPurple)
                            .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 8)
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple.opacity(0.4), Theme.Colors.aiPurple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(PremiumCardButtonStyle())
    }

    // MARK: - Circles Section

    private var circlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Circles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text(circleService.circles.isEmpty ? "Create or join a circle" : "\(circleService.circles.count) active")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()

                Button {
                    showCreateCircle = true
                    HapticsService.shared.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Create")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.aiPurple.opacity(0.15))
                            .overlay {
                                Capsule()
                                    .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(PremiumPillButtonStyle())
            }
            .padding(.horizontal, layout.screenPadding)

            if circleService.circles.isEmpty {
                // Empty circles - action cards
                circleActionCards
            } else {
                // Circle cards carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Array(circleService.circles.enumerated()), id: \.element.id) { index, circle in
                            PremiumCircleCard(circle: circle) {
                                selectedCircle = circle
                                HapticsService.shared.impact(.light)
                            }
                            .opacity(appearPhase)
                            .offset(y: (1 - appearPhase) * 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.08),
                                value: appearPhase
                            )
                        }
                    }
                    .padding(.horizontal, layout.screenPadding)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Circle Action Cards

    private var circleActionCards: some View {
        HStack(spacing: 12) {
            // Create Card
            Button {
                showCreateCircle = true
                HapticsService.shared.impact(.medium)
            } label: {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.Colors.aiPurple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }

                    VStack(spacing: 4) {
                        Text("Create")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.CelestialColors.starWhite)

                        Text("Start a new circle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.CelestialColors.abyss)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Theme.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(PremiumCardButtonStyle())

            // Join Card
            Button {
                showJoinCircle = true
                HapticsService.shared.impact(.medium)
            } label: {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.CelestialColors.plasmaCore.opacity(0.3), Theme.CelestialColors.plasmaCore.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.CelestialColors.plasmaCore)
                    }

                    VStack(spacing: 4) {
                        Text("Join")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.CelestialColors.starWhite)

                        Text("Enter invite code")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.CelestialColors.abyss)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Theme.CelestialColors.plasmaCore.opacity(0.2), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(PremiumCardButtonStyle())
        }
        .padding(.horizontal, layout.screenPadding)
    }

    // MARK: - Friends Section

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Friends")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text(friendService.friends.isEmpty ? "Add friends to compete" : "\(friendService.friendCount) connected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()

                Button {
                    showAddFriend = true
                    HapticsService.shared.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Theme.CelestialColors.auroraGreen.opacity(0.15))
                            .overlay {
                                Capsule()
                                    .stroke(Theme.CelestialColors.auroraGreen.opacity(0.3), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(PremiumPillButtonStyle())
            }
            .padding(.horizontal, layout.screenPadding)

            if friendService.friends.isEmpty {
                // Empty state
                emptyFriendsCard
            } else {
                // Friends list
                VStack(spacing: 10) {
                    ForEach(Array(friendService.friends.enumerated()), id: \.element.id) { index, friendship in
                        PremiumFriendCard(friendship: friendship)
                            .padding(.horizontal, layout.screenPadding)
                            .opacity(appearPhase)
                            .offset(y: (1 - appearPhase) * 15)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.06 + 0.2),
                                value: appearPhase
                            )
                    }
                }
            }
        }
    }

    private var emptyFriendsCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Animated rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Theme.CelestialColors.starGhost.opacity(0.3), lineWidth: 1)
                        .frame(width: 60 + CGFloat(i) * 20)
                        .scaleEffect(1 + pulsePhase * 0.05 * CGFloat(i + 1))
                        .opacity(0.5 - Double(i) * 0.15)
                }

                Image(systemName: "person.2")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            .frame(height: 100)

            VStack(spacing: 6) {
                Text("No friends yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Add friends to see their progress and compete on leaderboards")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Button {
                showAddFriend = true
                HapticsService.shared.impact(.medium)
            } label: {
                Text("Find Friends")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .fill(Theme.CelestialColors.auroraGreen)
                            .shadow(color: Theme.CelestialColors.auroraGreen.opacity(0.4), radius: 12)
                    }
            }
            .buttonStyle(PremiumPillButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.CelestialColors.abyss.opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                }
        }
        .padding(.horizontal, layout.screenPadding)
    }

    // MARK: - Activity Feed Section

    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()

                Text("From your circles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
            .padding(.horizontal, layout.screenPadding)

            // Activity items
            VStack(spacing: 0) {
                ForEach(Array(recentActivities.prefix(5).enumerated()), id: \.element.id) { index, activity in
                    ActivityFeedItem(activity: activity)

                    if index < min(4, recentActivities.count - 1) {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.CelestialColors.abyss.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
            }
            .padding(.horizontal, layout.screenPadding)
        }
    }

    private var recentActivities: [CircleActivity] {
        circleService.circles.flatMap { $0.recentActivity ?? [] }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 28) {
            // Animated illustration
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.aiPurple.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(1 + pulsePhase * 0.1)

                // Orbiting elements
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Theme.Colors.aiPurple.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: -50)
                        .rotationEffect(.degrees(gradientRotation + Double(i) * 120))
                }

                // Center icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 20)

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 200)

            VStack(spacing: 12) {
                Text("Build Your Circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Connect with friends, join circles, and\nachieve your goals together")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    showCreateCircle = true
                    HapticsService.shared.impact(.medium)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create a Circle")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.Colors.aiPurple)
                            .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 16)
                    }
                }
                .buttonStyle(PremiumCardButtonStyle())

                Button {
                    showAddFriend = true
                    HapticsService.shared.impact(.light)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                        Text("Add Friends")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(PremiumCardButtonStyle())
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.CelestialColors.abyss.opacity(0.4))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        do {
            try await friendService.loadFriendships()
            try await circleService.loadCircles()
        } catch {
            print("Error loading circles data: \(error)")
        }
        isLoading = false

        // Trigger appear animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            appearPhase = 1
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }

        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
    }
}

// MARK: - Premium Circle Card

struct PremiumCircleCard: View {
    let circle: SocialCircle
    let onTap: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var circleInitials: String {
        let words = circle.name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(circle.name.prefix(2)).uppercased()
    }

    private var accentColor: Color {
        // Generate consistent color from circle name
        let hash = abs(circle.name.hashValue)
        let colors: [Color] = [
            Theme.Colors.aiPurple,
            Theme.Colors.aiBlue,
            Theme.CelestialColors.plasmaCore,
            Theme.CelestialColors.auroraGreen,
            Color(red: 0.98, green: 0.45, blue: 0.65)
        ]
        return colors[hash % colors.count]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with avatar and stats
                HStack(spacing: 14) {
                    // Circle avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .shadow(color: accentColor.opacity(0.4), radius: 12)

                        Text(circleInitials)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(circle.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.CelestialColors.starWhite)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Label("\(circle.memberCount)", systemImage: "person.2.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.CelestialColors.starDim)

                            if circle.circleStreak > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.orange)
                                    Text("\(circle.circleStreak)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.CelestialColors.starDim)
                                }
                            }
                        }
                    }
                }

                // Member avatars row
                if let members = circle.members, !members.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(Array(members.prefix(4).enumerated()), id: \.element.id) { index, member in
                            MiniAvatarView(
                                name: member.user?.displayName ?? "?",
                                color: memberColor(for: index)
                            )
                            .zIndex(Double(4 - index))
                        }

                        if members.count > 4 {
                            Text("+\(members.count - 4)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                                .frame(width: 28, height: 28)
                                .background {
                                    Circle()
                                        .fill(Theme.CelestialColors.nebulaDust)
                                        .overlay {
                                            Circle()
                                                .stroke(Theme.CelestialColors.abyss, lineWidth: 2)
                                        }
                                }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.CelestialColors.starGhost)
                    }
                }
            }
            .padding(18)
            .frame(width: 260)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.CelestialColors.abyss)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.3), accentColor.opacity(0.1), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
            }
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private func memberColor(for index: Int) -> Color {
        let colors: [Color] = [
            Theme.Colors.aiPurple,
            Theme.CelestialColors.plasmaCore,
            Theme.CelestialColors.auroraGreen,
            Theme.Colors.aiPink
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Mini Avatar View

struct MiniAvatarView: View {
    let name: String
    let color: Color

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background {
                Circle()
                    .fill(color)
                    .overlay {
                        Circle()
                            .stroke(Theme.CelestialColors.abyss, lineWidth: 2)
                    }
            }
    }
}

// MARK: - Premium Friend Card

struct PremiumFriendCard: View {
    let friendship: Friendship

    @State private var isPressed = false

    private var friendProfile: FriendProfile? {
        guard let currentUserId = SupabaseService.shared.currentUserId else { return nil }
        return friendship.otherUser(currentUserId: currentUserId)
    }

    var body: some View {
        if let friend = friendProfile {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [avatarColor, avatarColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Text(String(friend.displayName.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    // Online indicator
                    Circle()
                        .fill(Theme.CelestialColors.auroraGreen)
                        .frame(width: 12, height: 12)
                        .overlay {
                            Circle()
                                .stroke(Theme.CelestialColors.abyss, lineWidth: 2)
                        }
                        .offset(x: 16, y: 16)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    if let username = friend.username {
                        Text("@\(username)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }

                Spacer()

                // Stats
                HStack(spacing: 16) {
                    // Streak
                    if let streak = friend.currentStreak, streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                            Text("\(streak)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.CelestialColors.starWhite)
                        }
                    }

                    // Level
                    if let level = friend.currentLevel {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.aiGold)
                            Text("Lv\(level)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                        }
                    }
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.CelestialColors.abyss.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
            }
            .scaleEffect(isPressed ? 0.98 : 1)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = pressing
                }
            }, perform: {})
        }
    }

    private var avatarColor: Color {
        guard let name = friendProfile?.displayName else { return .gray }
        let hash = abs(name.hashValue)
        let colors: [Color] = [
            Theme.Colors.aiPurple,
            Theme.Colors.aiBlue,
            Theme.CelestialColors.plasmaCore,
            Theme.CelestialColors.auroraGreen,
            Theme.Colors.aiPink
        ]
        return colors[hash % colors.count]
    }
}

// MARK: - Activity Feed Item

struct ActivityFeedItem: View {
    let activity: CircleActivity

    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(activity.activityType.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.activityType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(activity.activityType.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(activity.user?.displayName ?? "Someone")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text(activity.activityType.displayName.lowercased())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                if let message = activity.message {
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Time and points
            VStack(alignment: .trailing, spacing: 3) {
                Text(activity.formattedTime)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starGhost)

                if activity.pointsEarned > 0 {
                    Text("+\(activity.pointsEarned)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Button Styles

struct PremiumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PremiumPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ZStack {
            Theme.CelestialColors.void.ignoresSafeArea()
            CirclesContentView()
        }
    }
    .preferredColorScheme(.dark)
}
