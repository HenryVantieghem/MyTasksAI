//
//  FriendsArenaView.swift
//  Veloce
//
//  The Cosmic Colosseum - Epic Friends Competition Arena
//  Where productivity legends are forged in stellar fire
//
//  Design: Galactic arena with orbital rankings, champion thrones,
//  streak fire trails, and live XP race visualization
//

import SwiftUI

// MARK: - Arena User Profile (Extended profile for arena display)

/// Extended profile with all displayable properties as stored values
struct ArenaUserProfile: Identifiable {
    let id: UUID
    var displayName: String
    var avatarUrl: String?
    var currentStreak: Int?
    var currentLevel: Int?
    var totalPoints: Int?
    var tasksCompletedToday: Int?
    var isActiveNow: Bool
    var todayFocusMinutes: Int?

    /// Convert from FriendProfile
    init(from profile: FriendProfile) {
        self.id = profile.id
        self.displayName = profile.displayName
        self.avatarUrl = profile.avatarUrl
        self.currentStreak = profile.currentStreak
        self.currentLevel = profile.currentLevel
        self.totalPoints = profile.totalPoints
        self.tasksCompletedToday = profile.tasksCompletedToday
        self.isActiveNow = profile.isActiveNow
        self.todayFocusMinutes = profile.todayFocusMinutes
    }

    /// Direct initializer for mock data
    init(
        id: UUID = UUID(),
        displayName: String,
        avatarUrl: String? = nil,
        currentStreak: Int? = nil,
        currentLevel: Int? = nil,
        totalPoints: Int? = nil,
        tasksCompletedToday: Int? = nil,
        isActiveNow: Bool = false,
        todayFocusMinutes: Int? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.currentStreak = currentStreak
        self.currentLevel = currentLevel
        self.totalPoints = totalPoints
        self.tasksCompletedToday = tasksCompletedToday
        self.isActiveNow = isActiveNow
        self.todayFocusMinutes = todayFocusMinutes
    }
}

// MARK: - Friends Arena View (Main Redesigned View)

struct FriendsArenaView: View {
    let friendService: FriendService
    @Binding var leaderboardMode: Bool
    var onFriendSelected: (FriendProfile) -> Void
    var onShowLeaderboard: () -> Void

    @State private var selectedRivalIndex: Int? = nil
    @State private var showVSBattle = false
    @State private var arenaRotation: Double = 0
    @State private var pulsePhase: CGFloat = 0
    @State private var selectedMetric: ArenaMetric = .xp
    @State private var selectedPeriod: ArenaPeriod = .weekly

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Mock current user for demo
    private var currentUser: ArenaUserProfile {
        ArenaUserProfile(
            id: UUID(),
            displayName: "You",
            avatarUrl: nil,
            currentStreak: 12,
            currentLevel: 24,
            totalPoints: 9650,
            tasksCompletedToday: 8,
            isActiveNow: true,
            todayFocusMinutes: 145
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // MARK: - Weekly Showdown Banner
                WeeklyShowdownBanner(
                    daysRemaining: 3,
                    yourRank: 4,
                    previousRank: 7,
                    topRivalName: "CosmicExplorer"
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // MARK: - Your Status Orb
                YourStatusOrb(
                    user: currentUser,
                    metric: selectedMetric,
                    rank: 4,
                    totalParticipants: 156
                )
                .padding(.top, 24)

                // MARK: - Metric Selector
                ArenaMetricSelector(
                    selectedMetric: $selectedMetric,
                    selectedPeriod: $selectedPeriod
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // MARK: - Champion Throne (Top 3)
                ChampionThrone(
                    champions: topThreeProfiles,
                    metric: selectedMetric,
                    onChampionTap: onFriendSelected
                )
                .padding(.top, 24)

                // MARK: - XP Race Track
                XPRaceTrack(
                    yourXP: currentUser.totalPoints ?? 0,
                    nextMilestone: 10000,
                    nearbyRivals: nearbyRivals
                )
                .padding(.horizontal, 20)
                .padding(.top, 32)

                // MARK: - Rival Cards
                VStack(spacing: 0) {
                    // Section Header
                    HStack {
                        Text("YOUR RIVALS")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(Color.white.opacity(0.4))

                        Spacer()

                        Button {
                            onShowLeaderboard()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Full Rankings")
                                    .font(.system(size: 12, weight: .semibold))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(ArenaColors.champion)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Rival Cards List
                    VStack(spacing: 8) {
                        ForEach(Array(rankedFriends.enumerated()), id: \.element.id) { index, friendship in
                            if let friend = friendship.otherUser(currentUserId: getCurrentUserId()) {
                                RivalCard(
                                    rank: index + 1,
                                    rival: friend,
                                    metric: selectedMetric,
                                    yourValue: metricValue(for: currentUser),
                                    isNearYou: abs(index + 1 - 4) <= 2,
                                    onTap: { onFriendSelected(friend) },
                                    onChallenge: { showVSBattle = true }
                                )
                            }
                        }

                        // Show mock data if no friends
                        if rankedFriends.isEmpty {
                            ForEach(MockRival.samples.indices, id: \.self) { index in
                                let rival = MockRival.samples[index]
                                RivalCardMock(
                                    rank: index + 1,
                                    rival: rival,
                                    metric: selectedMetric,
                                    yourValue: metricValue(for: currentUser),
                                    isNearYou: abs(index + 1 - 4) <= 2
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 32)

                Spacer(minLength: 120)
            }
        }
        .background(ArenaBackground())
        .onAppear {
            startAmbientAnimations()
        }
    }

    // MARK: - Data Helpers

    private var rankedFriends: [Friendship] {
        friendService.friends.sorted { f1, f2 in
            let v1 = metricValue(for: f1.otherUser(currentUserId: getCurrentUserId()))
            let v2 = metricValue(for: f2.otherUser(currentUserId: getCurrentUserId()))
            return v1 > v2
        }
    }

    private var topThreeProfiles: [FriendProfile] {
        if rankedFriends.isEmpty {
            return MockRival.samples.prefix(3).map { $0.toProfile() }
        }
        return Array(rankedFriends.prefix(3)).compactMap {
            $0.otherUser(currentUserId: getCurrentUserId())
        }
    }

    private var nearbyRivals: [(name: String, xp: Int, rank: Int)] {
        if rankedFriends.isEmpty {
            return MockRival.samples.prefix(5).enumerated().map { index, rival in
                (rival.name, rival.xp, index + 1)
            }
        }
        return rankedFriends.prefix(5).enumerated().compactMap { index, friendship in
            guard let friend = friendship.otherUser(currentUserId: getCurrentUserId()) else { return nil }
            return (friend.displayName, friend.totalPoints ?? 0, index + 1)
        }
    }

    private func metricValue(for profile: FriendProfile?) -> Int {
        guard let profile = profile else { return 0 }
        switch selectedMetric {
        case .xp: return profile.totalPoints ?? 0
        case .streak: return profile.currentStreak ?? 0
        case .tasks: return profile.tasksCompletedToday ?? 0
        case .focus: return profile.todayFocusMinutes ?? 0
        }
    }

    private func metricValue(for profile: ArenaUserProfile) -> Int {
        switch selectedMetric {
        case .xp: return profile.totalPoints ?? 0
        case .streak: return profile.currentStreak ?? 0
        case .tasks: return profile.tasksCompletedToday ?? 0
        case .focus: return profile.todayFocusMinutes ?? 0
        }
    }

    private func getCurrentUserId() -> UUID {
        UUID() // Placeholder
    }

    private func startAmbientAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            arenaRotation = 360
        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }
    }
}

// MARK: - Arena Colors

enum ArenaColors {
    // Champion colors
    static let champion = Color(red: 1.0, green: 0.84, blue: 0.0) // Pure gold
    static let championGlow = Color(red: 1.0, green: 0.75, blue: 0.2)

    // Rank colors
    static let gold = LinearGradient(
        colors: [Color(red: 1.0, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.65, blue: 0.15)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let silver = LinearGradient(
        colors: [Color(red: 0.85, green: 0.85, blue: 0.90), Color(red: 0.55, green: 0.55, blue: 0.65)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bronze = LinearGradient(
        colors: [Color(red: 0.85, green: 0.55, blue: 0.25), Color(red: 0.60, green: 0.35, blue: 0.15)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Metric colors
    static let xp = Color(red: 0.58, green: 0.25, blue: 0.98)
    static let streak = Color(red: 0.98, green: 0.45, blue: 0.15)
    static let tasks = Color(red: 0.20, green: 0.90, blue: 0.55)
    static let focus = Color(red: 0.35, green: 0.75, blue: 0.98)

    // Arena atmosphere
    static let voidDeep = Color(red: 0.01, green: 0.01, blue: 0.02)
    static let nebulaPurple = Color(red: 0.15, green: 0.05, blue: 0.25)
    static let cosmicCyan = Color(red: 0.0, green: 0.15, blue: 0.25)

    // Fire gradient for streaks
    static let fireGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.85, blue: 0.0),
            Color(red: 1.0, green: 0.55, blue: 0.0),
            Color(red: 1.0, green: 0.25, blue: 0.0)
        ],
        startPoint: .bottom, endPoint: .top
    )
}

// MARK: - Arena Metric Enum

enum ArenaMetric: String, CaseIterable, Identifiable {
    case xp, streak, tasks, focus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .xp: return "XP"
        case .streak: return "Streak"
        case .tasks: return "Tasks"
        case .focus: return "Focus"
        }
    }

    var icon: String {
        switch self {
        case .xp: return "star.fill"
        case .streak: return "flame.fill"
        case .tasks: return "checkmark.circle.fill"
        case .focus: return "brain.head.profile.fill"
        }
    }

    var color: Color {
        switch self {
        case .xp: return ArenaColors.xp
        case .streak: return ArenaColors.streak
        case .tasks: return ArenaColors.tasks
        case .focus: return ArenaColors.focus
        }
    }

    func format(_ value: Int) -> String {
        switch self {
        case .xp:
            if value >= 10000 { return String(format: "%.1fK", Double(value) / 1000) }
            return "\(value)"
        case .streak: return "\(value)d"
        case .tasks: return "\(value)"
        case .focus:
            if value >= 60 { return "\(value / 60)h \(value % 60)m" }
            return "\(value)m"
        }
    }
}

// MARK: - Arena Period Enum

enum ArenaPeriod: String, CaseIterable, Identifiable {
    case weekly, monthly, allTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Arena Background

struct ArenaBackground: View {
    @State private var gradientRotation: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Deep void base
            ArenaColors.voidDeep.ignoresSafeArea()

            // Nebula clouds
            GeometryReader { geo in
                ZStack {
                    // Purple nebula - top right
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ArenaColors.nebulaPurple.opacity(0.4),
                                    ArenaColors.nebulaPurple.opacity(0.1),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.6
                            )
                        )
                        .frame(width: geo.size.width * 1.2)
                        .offset(x: geo.size.width * 0.4, y: -geo.size.height * 0.1)
                        .blur(radius: 60)

                    // Cyan nebula - bottom left
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ArenaColors.cosmicCyan.opacity(0.3),
                                    ArenaColors.cosmicCyan.opacity(0.05),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.5
                            )
                        )
                        .frame(width: geo.size.width)
                        .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.5)
                        .blur(radius: 50)

                    // Subtle rotating gradient overlay
                    if !reduceMotion {
                        AngularGradient(
                            colors: [
                                .clear,
                                ArenaColors.xp.opacity(0.03),
                                .clear,
                                ArenaColors.champion.opacity(0.02),
                                .clear
                            ],
                            center: .center,
                            angle: .degrees(gradientRotation)
                        )
                        .ignoresSafeArea()
                        .blur(radius: 100)
                    }
                }
            }

            // Star field
            StarField()
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }
}

// MARK: - Star Field

struct StarField: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<50) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.4)))
                    .frame(width: CGFloat.random(in: 1...2.5))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
            }
        }
    }
}

// MARK: - Weekly Showdown Banner

struct WeeklyShowdownBanner: View {
    let daysRemaining: Int
    let yourRank: Int
    let previousRank: Int
    let topRivalName: String

    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var rankChange: Int { previousRank - yourRank }

    var body: some View {
        VStack(spacing: 0) {
            // Main banner
            HStack(spacing: 16) {
                // Trophy icon with glow
                ZStack {
                    if !reduceMotion {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(ArenaColors.champion)
                            .blur(radius: 8)
                            .scaleEffect(pulseScale)
                    }

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(ArenaColors.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("WEEKLY SHOWDOWN")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(ArenaColors.champion)

                    HStack(spacing: 8) {
                        Text("You're")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))

                        Text("#\(yourRank)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        // Rank change indicator
                        if rankChange != 0 {
                            HStack(spacing: 2) {
                                Image(systemName: rankChange > 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10, weight: .bold))
                                Text("\(abs(rankChange))")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(rankChange > 0 ? ArenaColors.tasks : Color.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill((rankChange > 0 ? ArenaColors.tasks : Color.red).opacity(0.2))
                            )
                        }
                    }
                }

                Spacer()

                // Days remaining
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(daysRemaining)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("days left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Shimmer effect
                    if !reduceMotion {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, ArenaColors.champion.opacity(0.15), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: 20))
                    }

                    // Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    ArenaColors.champion.opacity(0.5),
                                    ArenaColors.champion.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )

            // Rival callout
            HStack(spacing: 6) {
                Image(systemName: "person.fill.viewfinder")
                    .font(.system(size: 11))
                Text("Chasing: \(topRivalName)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, 8)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Your Status Orb

struct YourStatusOrb: View {
    let user: ArenaUserProfile
    let metric: ArenaMetric
    let rank: Int
    let totalParticipants: Int

    @State private var ringRotation: Double = 0
    @State private var glowIntensity: CGFloat = 0.5
    @State private var particlePhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var metricValue: Int {
        switch metric {
        case .xp: return user.totalPoints ?? 0
        case .streak: return user.currentStreak ?? 0
        case .tasks: return user.tasksCompletedToday ?? 0
        case .focus: return user.todayFocusMinutes ?? 0
        }
    }

    var body: some View {
        ZStack {
            // Outer glow rings
            if !reduceMotion {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            metric.color.opacity(0.1 - Double(i) * 0.03),
                            lineWidth: 1
                        )
                        .frame(width: 180 + CGFloat(i) * 30)
                        .rotationEffect(.degrees(ringRotation + Double(i) * 30))
                }
            }

            // Central orb background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            metric.color.opacity(0.3),
                            metric.color.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180)
                .blur(radius: 20)

            // Glass orb
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 150)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    metric.color.opacity(0.3),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: metric.color.opacity(0.4 * glowIntensity), radius: 20)

            // Content
            VStack(spacing: 4) {
                // Rank
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                // Main value
                Text(metric.format(metricValue))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                // Metric label
                HStack(spacing: 4) {
                    Image(systemName: metric.icon)
                        .font(.system(size: 11, weight: .bold))
                    Text(metric.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(metric.color)

                // Percentile
                let percentile = Int((1 - Double(rank) / Double(totalParticipants)) * 100)
                Text("Top \(percentile)%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
            }

            // Orbiting particles (if streak active)
            if let streak = user.currentStreak, streak > 0, !reduceMotion {
                ForEach(0..<min(streak, 5), id: \.self) { i in
                    Circle()
                        .fill(ArenaColors.streak)
                        .frame(width: 6)
                        .offset(x: 85)
                        .rotationEffect(.degrees(particlePhase + Double(i) * (360.0 / Double(min(streak, 5)))))
                        .shadow(color: ArenaColors.streak, radius: 4)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 1
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                particlePhase = 360
            }
        }
    }
}

// MARK: - Arena Metric Selector

struct ArenaMetricSelector: View {
    @Binding var selectedMetric: ArenaMetric
    @Binding var selectedPeriod: ArenaPeriod

    var body: some View {
        VStack(spacing: 12) {
            // Metric pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ArenaMetric.allCases) { metric in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMetric = metric
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: metric.icon)
                                    .font(.system(size: 12, weight: .bold))
                                    .symbolEffect(.bounce, value: selectedMetric == metric)

                                Text(metric.displayName)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(selectedMetric == metric ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedMetric == metric ? metric.color : Color.white.opacity(0.05))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedMetric == metric ? .clear : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Period selector
            HStack(spacing: 0) {
                ForEach(ArenaPeriod.allCases) { period in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.displayName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedPeriod == period ? .white : .white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedPeriod == period
                                ? Capsule().fill(selectedMetric.color.opacity(0.25))
                                : nil
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.white.opacity(0.05), in: Capsule())
        }
    }
}

// MARK: - Champion Throne (Top 3 Podium)

struct ChampionThrone: View {
    let champions: [FriendProfile]
    let metric: ArenaMetric
    var onChampionTap: ((FriendProfile) -> Void)?

    @State private var crownFloat: CGFloat = 0
    @State private var glowPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 2nd Place
            if champions.count > 1 {
                championPedestal(
                    champion: champions[1],
                    rank: 2,
                    pedestalHeight: 60,
                    avatarSize: 56,
                    gradient: ArenaColors.silver
                )
            }

            // 1st Place (Center, tallest)
            if champions.count > 0 {
                championPedestal(
                    champion: champions[0],
                    rank: 1,
                    pedestalHeight: 90,
                    avatarSize: 72,
                    gradient: ArenaColors.gold,
                    showCrown: true
                )
            }

            // 3rd Place
            if champions.count > 2 {
                championPedestal(
                    champion: champions[2],
                    rank: 3,
                    pedestalHeight: 40,
                    avatarSize: 48,
                    gradient: ArenaColors.bronze
                )
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                crownFloat = -5
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }

    @ViewBuilder
    private func championPedestal(
        champion: FriendProfile,
        rank: Int,
        pedestalHeight: CGFloat,
        avatarSize: CGFloat,
        gradient: LinearGradient,
        showCrown: Bool = false
    ) -> some View {
        let metricValue: Int = {
            switch metric {
            case .xp: return champion.totalPoints ?? 0
            case .streak: return champion.currentStreak ?? 0
            case .tasks: return champion.tasksCompletedToday ?? 0
            case .focus: return champion.todayFocusMinutes ?? 0
            }
        }()

        VStack(spacing: 8) {
            // Crown for 1st place
            if showCrown {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(ArenaColors.gold)
                    .shadow(color: ArenaColors.champion.opacity(0.8), radius: 8)
                    .offset(y: crownFloat)
            }

            // Avatar with glow
            Button {
                onChampionTap?(champion)
            } label: {
                ZStack {
                    // Glow
                    if !reduceMotion {
                        Circle()
                            .fill(gradient)
                            .frame(width: avatarSize + 16)
                            .blur(radius: 12)
                            .opacity(0.3 + 0.2 * glowPhase)
                    }

                    // Avatar circle
                    Circle()
                        .fill(gradient)
                        .frame(width: avatarSize)
                        .overlay(
                            Text(champion.displayName.prefix(1).uppercased())
                                .font(.system(size: avatarSize * 0.4, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                        )
                }
            }
            .buttonStyle(.plain)

            // Name
            Text(champion.displayName)
                .font(.system(size: rank == 1 ? 14 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            // Value
            HStack(spacing: 3) {
                Image(systemName: metric.icon)
                    .font(.system(size: 10))
                Text(metric.format(metricValue))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.6))

            // Pedestal
            ZStack {
                // Pedestal base
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: pedestalHeight)

                // Rank number
                Text("\(rank)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(gradient)
                    .offset(y: -pedestalHeight / 2 + 20)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - XP Race Track

struct XPRaceTrack: View {
    let yourXP: Int
    let nextMilestone: Int
    let nearbyRivals: [(name: String, xp: Int, rank: Int)]

    @State private var progress: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -100
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progressPercent: CGFloat {
        CGFloat(yourXP) / CGFloat(nextMilestone)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("XP RACE TO \(nextMilestone.formatted())")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.4))

                    Text("\(nextMilestone - yourXP) XP to go")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Your position marker
                HStack(spacing: 4) {
                    Circle()
                        .fill(ArenaColors.xp)
                        .frame(width: 8, height: 8)
                    Text("You")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Race track
            GeometryReader { geo in
                let trackWidth = geo.size.width

                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 24)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [ArenaColors.xp, ArenaColors.xp.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: trackWidth * progress, height: 24)

                    // Shimmer
                    if !reduceMotion {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.3), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60, height: 24)
                            .offset(x: shimmerOffset)
                            .mask(
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(width: trackWidth * progress, height: 24)
                            )
                    }

                    // Rival markers
                    ForEach(nearbyRivals.indices, id: \.self) { index in
                        let rival = nearbyRivals[index]
                        let rivalProgress = CGFloat(rival.xp) / CGFloat(nextMilestone)

                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Text("\(rival.rank)")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: trackWidth * min(rivalProgress, 0.98) - 5)
                    }

                    // Your marker (larger, on top)
                    Circle()
                        .fill(ArenaColors.xp)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                        .shadow(color: ArenaColors.xp.opacity(0.6), radius: 4)
                        .offset(x: trackWidth * min(progress, 0.98) - 8)
                }
            }
            .frame(height: 24)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1).delay(0.3)) {
                progress = progressPercent
            }
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false).delay(1.3)) {
                shimmerOffset = 400
            }
        }
    }
}

// MARK: - Rival Card

struct RivalCard: View {
    let rank: Int
    let rival: FriendProfile
    let metric: ArenaMetric
    let yourValue: Int
    let isNearYou: Bool
    var onTap: (() -> Void)?
    var onChallenge: (() -> Void)?

    @State private var isPressed = false

    private var rivalValue: Int {
        switch metric {
        case .xp: return rival.totalPoints ?? 0
        case .streak: return rival.currentStreak ?? 0
        case .tasks: return rival.tasksCompletedToday ?? 0
        case .focus: return rival.todayFocusMinutes ?? 0
        }
    }

    private var difference: Int { rivalValue - yourValue }
    private var isAhead: Bool { difference > 0 }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Rank
                ZStack {
                    if rank <= 3 {
                        Circle()
                            .fill(rankGradient(for: rank))
                            .frame(width: 32, height: 32)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 32, height: 32)
                    }

                    Text("\(rank)")
                        .font(.system(size: rank <= 3 ? 14 : 13, weight: .bold, design: .rounded))
                        .foregroundStyle(rank <= 3 ? .white : .white.opacity(0.5))
                }

                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [metric.color.opacity(0.3), metric.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Text(rival.displayName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))

                    // Online indicator
                    if rival.isActiveNow {
                        Circle()
                            .fill(ArenaColors.tasks)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .offset(x: 16, y: 16)
                    }
                }

                // Name and streak
                VStack(alignment: .leading, spacing: 3) {
                    Text(rival.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    // Streak badge if applicable
                    if let streak = rival.currentStreak, streak > 0 {
                        StreakFireBadge(days: streak, compact: true)
                    }
                }

                Spacer()

                // Value comparison
                VStack(alignment: .trailing, spacing: 3) {
                    Text(metric.format(rivalValue))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    // Difference
                    HStack(spacing: 3) {
                        Image(systemName: isAhead ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                        Text(metric.format(abs(difference)))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(isAhead ? Color.red.opacity(0.8) : ArenaColors.tasks)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isNearYou
                        ? metric.color.opacity(0.08)
                        : Color.white.opacity(0.03)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isNearYou
                                ? metric.color.opacity(0.2)
                                : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.spring(response: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private func rankGradient(for rank: Int) -> LinearGradient {
        switch rank {
        case 1: return ArenaColors.gold
        case 2: return ArenaColors.silver
        case 3: return ArenaColors.bronze
        default: return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Rival Card Mock (for empty state)

struct RivalCardMock: View {
    let rank: Int
    let rival: MockRival
    let metric: ArenaMetric
    let yourValue: Int
    let isNearYou: Bool

    private var rivalValue: Int {
        switch metric {
        case .xp: return rival.xp
        case .streak: return rival.streak
        case .tasks: return rival.tasks
        case .focus: return rival.focus
        }
    }

    private var difference: Int { rivalValue - yourValue }
    private var isAhead: Bool { difference > 0 }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankGradient(for: rank))
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 32, height: 32)
                }

                Text("\(rank)")
                    .font(.system(size: rank <= 3 ? 14 : 13, weight: .bold, design: .rounded))
                    .foregroundStyle(rank <= 3 ? .white : .white.opacity(0.5))
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [metric.color.opacity(0.3), metric.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(rival.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Name and streak
            VStack(alignment: .leading, spacing: 3) {
                Text(rival.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                if rival.streak > 0 {
                    StreakFireBadge(days: rival.streak, compact: true)
                }
            }

            Spacer()

            // Value comparison
            VStack(alignment: .trailing, spacing: 3) {
                Text(metric.format(rivalValue))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 3) {
                    Image(systemName: isAhead ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    Text(metric.format(abs(difference)))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(isAhead ? Color.red.opacity(0.8) : ArenaColors.tasks)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isNearYou
                    ? metric.color.opacity(0.08)
                    : Color.white.opacity(0.03)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isNearYou
                            ? metric.color.opacity(0.2)
                            : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
    }

    private func rankGradient(for rank: Int) -> LinearGradient {
        switch rank {
        case 1: return ArenaColors.gold
        case 2: return ArenaColors.silver
        case 3: return ArenaColors.bronze
        default: return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Streak Fire Badge

struct StreakFireBadge: View {
    let days: Int
    var compact: Bool = false

    @State private var flamePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: compact ? 3 : 5) {
            ZStack {
                // Glow
                if !reduceMotion && !compact {
                    Image(systemName: "flame.fill")
                        .font(.system(size: compact ? 10 : 14))
                        .foregroundStyle(ArenaColors.streak)
                        .blur(radius: 4)
                        .scaleEffect(1 + 0.1 * flamePhase)
                }

                Image(systemName: "flame.fill")
                    .font(.system(size: compact ? 10 : 14))
                    .foregroundStyle(ArenaColors.fireGradient)
            }

            Text("\(days)")
                .font(.system(size: compact ? 11 : 13, weight: .bold, design: .rounded))
                .foregroundStyle(ArenaColors.streak)

            if !compact {
                Text("day streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ArenaColors.streak.opacity(0.7))
            }
        }
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 3 : 5)
        .background(
            Capsule()
                .fill(ArenaColors.streak.opacity(0.15))
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                flamePhase = 1
            }
        }
    }
}

// MARK: - Mock Data

struct MockRival {
    let name: String
    let xp: Int
    let streak: Int
    let tasks: Int
    let focus: Int

    func toProfile() -> FriendProfile {
        FriendProfile(
            id: UUID(),
            username: name,
            fullName: name,
            avatarUrl: nil,
            currentStreak: streak,
            currentLevel: xp / 500,
            totalPoints: xp,
            tasksCompletedToday: tasks
        )
    }

    func toArenaProfile() -> ArenaUserProfile {
        ArenaUserProfile(
            id: UUID(),
            displayName: name,
            avatarUrl: nil,
            currentStreak: streak,
            currentLevel: xp / 500,
            totalPoints: xp,
            tasksCompletedToday: tasks,
            isActiveNow: Bool.random(),
            todayFocusMinutes: focus
        )
    }

    static let samples: [MockRival] = [
        MockRival(name: "CosmicExplorer", xp: 12450, streak: 45, tasks: 12, focus: 280),
        MockRival(name: "NebulaHunter", xp: 11200, streak: 32, tasks: 10, focus: 245),
        MockRival(name: "StarForger", xp: 10800, streak: 28, tasks: 9, focus: 210),
        MockRival(name: "GalaxyRider", xp: 8900, streak: 15, tasks: 7, focus: 180),
        MockRival(name: "PulsarPilot", xp: 8200, streak: 12, tasks: 6, focus: 165),
        MockRival(name: "QuasarQueen", xp: 7800, streak: 10, tasks: 5, focus: 150),
        MockRival(name: "DarkMatter", xp: 7100, streak: 8, tasks: 5, focus: 140),
        MockRival(name: "EventHorizon", xp: 6500, streak: 6, tasks: 4, focus: 120),
        MockRival(name: "StellarSage", xp: 5900, streak: 5, tasks: 4, focus: 110),
        MockRival(name: "VoidWalker", xp: 5200, streak: 3, tasks: 3, focus: 95)
    ]
}

// MARK: - VS Battle Sheet

struct VSBattleSheet: View {
    let you: ArenaUserProfile
    let rival: ArenaUserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var vsScale: CGFloat = 0
    @State private var leftSlide: CGFloat = -200
    @State private var rightSlide: CGFloat = 200
    @State private var statsRevealed = false
    @State private var sparkPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Epic background
            VSBattleBackground()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // VS Header
                HStack(spacing: 0) {
                    // You
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [ArenaColors.xp.opacity(0.4), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120)
                                .blur(radius: 20)

                            Circle()
                                .fill(ArenaColors.xp.opacity(0.2))
                                .frame(width: 80)
                                .overlay(
                                    Text(you.displayName.prefix(1).uppercased())
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                )
                                .overlay(Circle().stroke(ArenaColors.xp, lineWidth: 3))
                        }

                        Text("YOU")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(ArenaColors.xp)
                    }
                    .offset(x: leftSlide)

                    // VS Badge
                    ZStack {
                        // Sparks
                        if !reduceMotion {
                            ForEach(0..<8, id: \.self) { i in
                                Rectangle()
                                    .fill(ArenaColors.champion)
                                    .frame(width: 2, height: 15)
                                    .offset(y: -35)
                                    .rotationEffect(.degrees(Double(i) * 45 + sparkPhase * 30))
                                    .opacity(0.6)
                            }
                        }

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ArenaColors.champion, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: ArenaColors.champion.opacity(0.8), radius: 20)

                        Text("VS")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(vsScale)

                    // Rival
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.red.opacity(0.4), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120)
                                .blur(radius: 20)

                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 80)
                                .overlay(
                                    Text(rival.displayName.prefix(1).uppercased())
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                )
                                .overlay(Circle().stroke(Color.red, lineWidth: 3))
                        }

                        Text(rival.displayName.uppercased())
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(Color.red)
                            .lineLimit(1)
                    }
                    .offset(x: rightSlide)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Stats Comparison
                if statsRevealed {
                    VStack(spacing: 16) {
                        StatComparisonRow(
                            label: "XP Earned",
                            icon: "star.fill",
                            yourValue: you.totalPoints ?? 0,
                            rivalValue: rival.totalPoints ?? 0,
                            format: { "\($0)" },
                            color: ArenaColors.xp
                        )

                        StatComparisonRow(
                            label: "Current Streak",
                            icon: "flame.fill",
                            yourValue: you.currentStreak ?? 0,
                            rivalValue: rival.currentStreak ?? 0,
                            format: { "\($0) days" },
                            color: ArenaColors.streak
                        )

                        StatComparisonRow(
                            label: "Tasks Today",
                            icon: "checkmark.circle.fill",
                            yourValue: you.tasksCompletedToday ?? 0,
                            rivalValue: rival.tasksCompletedToday ?? 0,
                            format: { "\($0)" },
                            color: ArenaColors.tasks
                        )

                        StatComparisonRow(
                            label: "Focus Time",
                            icon: "brain.head.profile.fill",
                            yourValue: you.todayFocusMinutes ?? 0,
                            rivalValue: rival.todayFocusMinutes ?? 0,
                            format: { m in
                                if m >= 60 { return "\(m / 60)h \(m % 60)m" }
                                return "\(m)m"
                            },
                            color: ArenaColors.focus
                        )
                    }
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Challenge Button
                Button {
                    // Send challenge action
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("SEND CHALLENGE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [ArenaColors.champion, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: ArenaColors.champion.opacity(0.5), radius: 12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Animate entrance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                vsScale = 1
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2)) {
                leftSlide = 0
                rightSlide = 0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                statsRevealed = true
            }
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                sparkPhase = 1
            }
        }
    }
}

// MARK: - VS Battle Background

struct VSBattleBackground: View {
    @State private var leftGlow: CGFloat = 0.5
    @State private var rightGlow: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                // Left side (You - purple)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ArenaColors.xp.opacity(0.3 * leftGlow), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.6
                        )
                    )
                    .frame(width: geo.size.width * 1.2)
                    .offset(x: -geo.size.width * 0.5, y: geo.size.height * 0.2)
                    .blur(radius: 60)

                // Right side (Rival - red)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.3 * rightGlow), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.6
                        )
                    )
                    .frame(width: geo.size.width * 1.2)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.2)
                    .blur(radius: 60)

                // Center clash
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ArenaColors.champion.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.3
                        )
                    )
                    .frame(width: geo.size.width * 0.8)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                    .blur(radius: 40)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                leftGlow = 1
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                rightGlow = 1
            }
        }
    }
}

// MARK: - Stat Comparison Row

struct StatComparisonRow: View {
    let label: String
    let icon: String
    let yourValue: Int
    let rivalValue: Int
    let format: (Int) -> String
    let color: Color

    @State private var barProgress: CGFloat = 0

    private var youWinning: Bool { yourValue >= rivalValue }
    private var total: Int { max(yourValue + rivalValue, 1) }

    var body: some View {
        VStack(spacing: 8) {
            // Label
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            // Bar comparison
            HStack(spacing: 4) {
                // Your value
                Text(format(yourValue))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(youWinning ? ArenaColors.xp : .white.opacity(0.5))
                    .frame(width: 60, alignment: .trailing)

                // Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        // Your bar (from left)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ArenaColors.xp)
                            .frame(
                                width: geo.size.width * barProgress * CGFloat(yourValue) / CGFloat(total),
                                height: 8
                            )

                        // Rival bar (from right)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(
                                width: geo.size.width * barProgress * CGFloat(rivalValue) / CGFloat(total),
                                height: 8
                            )
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(height: 8)

                // Rival value
                Text(format(rivalValue))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(!youWinning ? Color.red : .white.opacity(0.5))
                    .frame(width: 60, alignment: .leading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                barProgress = 1
            }
        }
    }
}

// MARK: - Orbital Friends Ring (Bonus Component)

struct OrbitalFriendsRing: View {
    let friends: [FriendProfile]
    let yourRank: Int
    let selectedMetric: ArenaMetric

    @State private var rotation: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Orbital rings
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(
                        Color.white.opacity(0.05 + Double(ring) * 0.02),
                        lineWidth: 1
                    )
                    .frame(width: 160 + CGFloat(ring) * 60)
            }

            // Friends orbiting
            ForEach(Array(friends.prefix(8).enumerated()), id: \.element.id) { index, friend in
                let angle = Double(index) * (360.0 / Double(min(friends.count, 8)))
                let ringIndex = index % 3
                let radius: CGFloat = 80 + CGFloat(ringIndex) * 30

                OrbitalFriendDot(
                    friend: friend,
                    rank: index + 1,
                    color: selectedMetric.color
                )
                .offset(
                    x: radius * cos(CGFloat((angle + rotation) * .pi / 180)),
                    y: radius * sin(CGFloat((angle + rotation) * .pi / 180))
                )
            }

            // Center (You)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [selectedMetric.color.opacity(0.5), selectedMetric.color.opacity(0.1)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 60)
                .overlay(
                    VStack(spacing: 2) {
                        Text("#\(yourRank)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("YOU")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                )
                .overlay(Circle().stroke(selectedMetric.color, lineWidth: 2))
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Orbital Friend Dot

struct OrbitalFriendDot: View {
    let friend: FriendProfile
    let rank: Int
    let color: Color

    var body: some View {
        ZStack {
            // Glow for top 3
            if rank <= 3 {
                Circle()
                    .fill(rankColor.opacity(0.4))
                    .frame(width: 28)
                    .blur(radius: 6)
            }

            Circle()
                .fill(rank <= 3 ? rankColor : Color.white.opacity(0.15))
                .frame(width: 20)
                .overlay(
                    Text(friend.displayName.prefix(1).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.80)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return color
        }
    }
}

// MARK: - Friends Leaderboard Sheet

struct FriendsLeaderboardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: ArenaMetric = .xp
    @State private var selectedPeriod: ArenaPeriod = .weekly

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ArenaColors.voidDeep.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ArenaMetric.allCases) { metric in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = metric
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: metric.icon)
                                            .font(.system(size: 12, weight: .bold))
                                        Text(metric.displayName)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(selectedCategory == metric ? .white : .white.opacity(0.5))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == metric ? metric.color : Color.white.opacity(0.08))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)

                    // Period selector
                    HStack(spacing: 0) {
                        ForEach(ArenaPeriod.allCases) { period in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedPeriod = period
                                }
                            } label: {
                                Text(period.displayName)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(selectedPeriod == period ? .white : .white.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedPeriod == period
                                        ? Capsule().fill(selectedCategory.color.opacity(0.3))
                                        : nil
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color.white.opacity(0.05), in: Capsule())
                    .padding(.horizontal, 20)

                    // Leaderboard list
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(MockRival.samples.enumerated()), id: \.offset) { index, rival in
                                LeaderboardFullRow(
                                    rank: index + 1,
                                    name: rival.name,
                                    value: metricValue(for: rival),
                                    metric: selectedCategory,
                                    isCurrentUser: index == 3
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(ArenaColors.xp)
                }
            }
        }
    }

    private func metricValue(for rival: MockRival) -> Int {
        switch selectedCategory {
        case .xp: return rival.xp
        case .streak: return rival.streak
        case .tasks: return rival.tasks
        case .focus: return rival.focus
        }
    }
}

// MARK: - Leaderboard Full Row

struct LeaderboardFullRow: View {
    let rank: Int
    let name: String
    let value: Int
    let metric: ArenaMetric
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankGradient)
                        .frame(width: 36, height: 36)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 36, height: 36)
                }

                Text("\(rank)")
                    .font(.system(size: rank <= 3 ? 16 : 14, weight: .bold, design: .rounded))
                    .foregroundStyle(rank <= 3 ? .white : .white.opacity(0.6))
            }

            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [metric.color.opacity(0.3), metric.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text(name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                )

            // Name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 15, weight: isCurrentUser ? .bold : .medium, design: .rounded))
                        .foregroundStyle(isCurrentUser ? metric.color : .white)

                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(metric.color))
                    }
                }
            }

            Spacer()

            // Value
            Text(metric.format(value))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isCurrentUser ? metric.color : .white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentUser ? metric.color.opacity(0.12) : Color.white.opacity(0.03))
                .overlay(
                    isCurrentUser
                    ? RoundedRectangle(cornerRadius: 14).stroke(metric.color.opacity(0.3), lineWidth: 1)
                    : nil
                )
        )
    }

    private var rankGradient: LinearGradient {
        switch rank {
        case 1: return ArenaColors.gold
        case 2: return ArenaColors.silver
        case 3: return ArenaColors.bronze
        default: return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Previews

#Preview {
    FriendsArenaView(
        friendService: FriendService.shared,
        leaderboardMode: .constant(false),
        onFriendSelected: { _ in },
        onShowLeaderboard: { }
    )
    .preferredColorScheme(.dark)
}

#Preview("VS Battle") {
    VSBattleSheet(
        you: ArenaUserProfile(
            displayName: "You",
            currentStreak: 12,
            currentLevel: 24,
            totalPoints: 9650,
            tasksCompletedToday: 8,
            isActiveNow: true,
            todayFocusMinutes: 145
        ),
        rival: MockRival.samples[0].toArenaProfile()
    )
}

#Preview("Leaderboard Sheet") {
    FriendsLeaderboardSheet()
}
