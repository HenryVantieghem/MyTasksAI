//
//  CirclesContentView.swift
//  Veloce
//
//  Utopian Design System - Social Dashboard
//  Circles & Friends with consistent Utopian styling
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
                // Animated aurora icon container
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(
                            UtopianDesignFallback.Colors.aiPurple.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 48, height: 48)
                        .scaleEffect(1 + pulsePhase * 0.1)
                        .opacity(1 - pulsePhase * 0.5)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [UtopianDesignFallback.Colors.aiPurple.opacity(0.3), UtopianDesignFallback.Colors.aiPurple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.2.fill")
                        .dynamicTypeFont(base: 18, weight: .semibold)
                        .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Friend Requests")
                        .font(UtopianDesignFallback.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("\(friendService.pendingCount) people want to connect")
                        .font(UtopianDesignFallback.Typography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Count badge with glow
                Text("\(friendService.pendingCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(UtopianDesignFallback.Colors.aiPurple)
                            .shadow(color: UtopianDesignFallback.Colors.aiPurple.opacity(0.5), radius: 8)
                    )

                Image(systemName: "chevron.right")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [UtopianDesignFallback.Colors.aiPurple.opacity(0.4), UtopianDesignFallback.Colors.aiPurple.opacity(0.1)],
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
            // Section Header with Utopian styling
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Circles")
                        .font(UtopianDesignFallback.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(circleService.circles.isEmpty ? "Create or join a circle" : "\(circleService.circles.count) active")
                        .font(UtopianDesignFallback.Typography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button {
                    showCreateCircle = true
                    HapticsService.shared.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 12, weight: .bold)
                        Text("Create")
                            .font(UtopianDesignFallback.Typography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.15))
                            .overlay {
                                Capsule()
                                    .stroke(UtopianDesignFallback.Colors.aiPurple.opacity(0.3), lineWidth: 1)
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
                                .spring(response: 0.3, dampingFraction: 0.8).delay(Double(index) * 0.08),
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
            // Create Card with Utopian styling
            Button {
                showCreateCircle = true
                HapticsService.shared.impact(.medium)
            } label: {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(UtopianDesignFallback.Colors.aiPurple)
                            .frame(width: 56, height: 56)
                            .blur(radius: 12)
                            .opacity(0.3)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [UtopianDesignFallback.Colors.aiPurple.opacity(0.3), UtopianDesignFallback.Colors.aiPurple.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "plus.circle.fill")
                            .dynamicTypeFont(base: 26)
                            .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                    }

                    VStack(spacing: 4) {
                        Text("Create")
                            .font(UtopianDesignFallback.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        Text("Start a new circle")
                            .font(UtopianDesignFallback.Typography.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(UtopianDesignFallback.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(PremiumCardButtonStyle())

            // Join Card with Utopian styling
            Button {
                showJoinCircle = true
                HapticsService.shared.impact(.medium)
            } label: {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(UtopianDesignFallback.Colors.focusActive)
                            .frame(width: 56, height: 56)
                            .blur(radius: 12)
                            .opacity(0.3)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [UtopianDesignFallback.Colors.focusActive.opacity(0.3), UtopianDesignFallback.Colors.aiPurple.opacity(0.8).opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "person.badge.plus")
                            .dynamicTypeFont(base: 24)
                            .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
                    }

                    VStack(spacing: 4) {
                        Text("Join")
                            .font(UtopianDesignFallback.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        Text("Enter invite code")
                            .font(UtopianDesignFallback.Typography.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(UtopianDesignFallback.Colors.focusActive.opacity(0.2), lineWidth: 1)
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
            // Section Header with Utopian styling
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Friends")
                        .font(UtopianDesignFallback.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(friendService.friends.isEmpty ? "Add friends to compete" : "\(friendService.friendCount) connected")
                        .font(UtopianDesignFallback.Typography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button {
                    showAddFriend = true
                    HapticsService.shared.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .dynamicTypeFont(base: 12, weight: .bold)
                        Text("Add")
                            .font(UtopianDesignFallback.Typography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(UtopianDesignFallback.Colors.completed)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(UtopianDesignFallback.Colors.completed.opacity(0.15))
                            .overlay {
                                Capsule()
                                    .stroke(UtopianDesignFallback.Colors.completed.opacity(0.3), lineWidth: 1)
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
                                .spring(response: 0.3, dampingFraction: 0.8).delay(Double(index) * 0.06 + 0.2),
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
                // Animated aurora rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(UtopianDesignFallback.Colors.completed.opacity(0.2), lineWidth: 1)
                        .frame(width: 60 + CGFloat(i) * 20)
                        .scaleEffect(1 + pulsePhase * 0.05 * CGFloat(i + 1))
                        .opacity(0.5 - Double(i) * 0.15)
                }

                Image(systemName: "person.2")
                    .dynamicTypeFont(base: 28, weight: .light)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(height: 100)

            VStack(spacing: 6) {
                Text("No friends yet")
                    .font(UtopianDesignFallback.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("Add friends to see their progress and compete on leaderboards")
                    .font(UtopianDesignFallback.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Button {
                showAddFriend = true
                HapticsService.shared.impact(.medium)
            } label: {
                Text("Find Friends")
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .fill(UtopianDesignFallback.Colors.completed)
                            .shadow(color: UtopianDesignFallback.Colors.completed.opacity(0.4), radius: 12)
                    }
            }
            .buttonStyle(PremiumPillButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.1).opacity(0.6))
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
                    .dynamicTypeFont(base: 20, weight: .bold)
                    .foregroundStyle(.white)

                Spacer()

                Text("From your circles")
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(.white.opacity(0.5))
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
                    .fill(Color.white.opacity(0.1).opacity(0.6))
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
                            colors: [UtopianDesignFallback.Colors.aiPurple.opacity(0.15), .clear],
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
                        .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: -50)
                        .rotationEffect(.degrees(gradientRotation + Double(i) * 120))
                }

                // Center icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.aiPurple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: UtopianDesignFallback.Colors.aiPurple.opacity(0.5), radius: 20)

                    Image(systemName: "person.3.fill")
                        .dynamicTypeFont(base: 32, weight: .medium)
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 200)

            VStack(spacing: 12) {
                Text("Build Your Circle")
                    .dynamicTypeFont(base: 24, weight: .bold)
                    .foregroundStyle(.white)

                Text("Connect with friends, join circles, and\nachieve your goals together")
                    .dynamicTypeFont(base: 15, weight: .medium)
                    .foregroundStyle(.white.opacity(0.7))
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
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(UtopianDesignFallback.Colors.aiPurple)
                            .shadow(color: UtopianDesignFallback.Colors.aiPurple.opacity(0.4), radius: 16)
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
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)
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
                .fill(Color.white.opacity(0.1).opacity(0.4))
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
            UtopianDesignFallback.Colors.aiPurple,
            UtopianDesignFallback.Colors.aiPurple.opacity(0.8),
            UtopianDesignFallback.Colors.focusActive,
            UtopianDesignFallback.Colors.completed,
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
                            .dynamicTypeFont(base: 17, weight: .semibold)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Label("\(circle.memberCount)", systemImage: "person.2.fill")
                                .dynamicTypeFont(base: 12, weight: .medium)
                                .foregroundStyle(.white.opacity(0.7))

                            if circle.circleStreak > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill")
                                        .dynamicTypeFont(base: 10)
                                        .foregroundStyle(.orange)
                                    Text("\(circle.circleStreak)")
                                        .dynamicTypeFont(base: 12, weight: .medium)
                                        .foregroundStyle(.white.opacity(0.7))
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
                                .dynamicTypeFont(base: 10, weight: .bold)
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 28, height: 28)
                                .background {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay {
                                            Circle()
                                                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                                        }
                                }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .dynamicTypeFont(base: 12, weight: .semibold)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(18)
            .frame(width: 260)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.1))
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
            UtopianDesignFallback.Colors.aiPurple,
            UtopianDesignFallback.Colors.focusActive,
            UtopianDesignFallback.Colors.completed,
            UtopianDesignFallback.Colors.aiPurple
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
            .dynamicTypeFont(base: 11, weight: .bold)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background {
                Circle()
                    .fill(color)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 2)
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
                        .dynamicTypeFont(base: 18, weight: .semibold)
                        .foregroundStyle(.white)

                    // Online indicator
                    Circle()
                        .fill(UtopianDesignFallback.Colors.completed)
                        .frame(width: 12, height: 12)
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        }
                        .offset(x: 16, y: 16)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .dynamicTypeFont(base: 16, weight: .semibold)
                        .foregroundStyle(.white)

                    if let username = friend.username {
                        Text("@\(username)")
                            .dynamicTypeFont(base: 13, weight: .medium)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                // Stats
                HStack(spacing: 16) {
                    // Streak
                    if let streak = friend.currentStreak, streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .dynamicTypeFont(base: 12)
                                .foregroundStyle(.orange)
                            Text("\(streak)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                    // Level
                    if let level = friend.currentLevel {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .dynamicTypeFont(base: 11)
                                .foregroundStyle(UtopianDesignFallback.Gamification.starGold)
                            Text("Lv\(level)")
                                .dynamicTypeFont(base: 13, weight: .medium)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.1).opacity(0.6))
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
            UtopianDesignFallback.Colors.aiPurple,
            UtopianDesignFallback.Colors.aiPurple.opacity(0.8),
            UtopianDesignFallback.Colors.focusActive,
            UtopianDesignFallback.Colors.completed,
            UtopianDesignFallback.Colors.aiPurple
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
                    .dynamicTypeFont(base: 16, weight: .medium)
                    .foregroundStyle(activity.activityType.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(activity.user?.displayName ?? "Someone")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white)

                    Text(activity.activityType.displayName.lowercased())
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(.white.opacity(0.7))
                }

                if let message = activity.message {
                    Text(message)
                        .dynamicTypeFont(base: 13, weight: .medium)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Time and points
            VStack(alignment: .trailing, spacing: 3) {
                Text(activity.formattedTime)
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(.white.opacity(0.5))

                if activity.pointsEarned > 0 {
                    Text("+\(activity.pointsEarned)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(UtopianDesignFallback.Colors.completed)
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
            UtopianGradients.background(for: Date())
                .ignoresSafeArea()
            CirclesContentView()
        }
    }
    .preferredColorScheme(.dark)
}
