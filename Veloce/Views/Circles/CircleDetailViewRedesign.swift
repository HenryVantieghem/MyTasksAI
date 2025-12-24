//
//  CircleDetailViewRedesign.swift
//  Veloce
//
//  Circle Detail - Full circle view with members, leaderboard, activity feed
//  Real-time updates with emoji reactions and live presence indicators
//

import SwiftUI

// MARK: - Circle Detail View Redesign

struct CircleDetailViewRedesign: View {
    let circle: Circle

    @Environment(\.dismiss) private var dismiss
    @State private var circleService = CircleService.shared
    @State private var activity: [CircleActivity] = []
    @State private var selectedTab: CircleDetailTab = .members
    @State private var showInviteSheet = false
    @State private var showSettings = false
    @State private var isLoading = true

    // Animation
    @State private var headerGlow: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    circleHeader

                    // Tab selector
                    tabSelector

                    // Tab content
                    tabContent
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Theme.CelestialColors.void.ignoresSafeArea())
            .navigationTitle(circle.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showInviteSheet = true
                        } label: {
                            Label("Invite Members", systemImage: "person.badge.plus")
                        }

                        Button {
                            UIPasteboard.general.string = circle.formattedInviteCode
                        } label: {
                            Label("Copy Invite Code", systemImage: "doc.on.doc")
                        }

                        if isAdmin {
                            Divider()

                            Button {
                                showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            leaveCircle()
                        } label: {
                            Label("Leave Circle", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }
                }
            }
            .sheet(isPresented: $showInviteSheet) {
                CircleInviteSheet(circle: circle)
                    .presentationDetents([.medium])
            }
            .task {
                await loadData()
                startAnimations()
            }
        }
    }

    // MARK: - Header

    private var circleHeader: some View {
        VStack(spacing: 16) {
            // Circle avatar with orbital rings
            ZStack {
                // Orbital rings
                if !reduceMotion {
                    ForEach(0..<2) { i in
                        SwiftUI.Circle()
                            .stroke(Theme.Colors.aiPurple.opacity(0.1 + Double(i) * 0.05), lineWidth: 1)
                            .frame(width: CGFloat(100 + i * 20), height: CGFloat(100 + i * 20))
                    }
                }

                // Main avatar
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Text(circle.name.prefix(2).uppercased())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                // Glow
                if !reduceMotion {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiPurple.opacity(0.2 * headerGlow))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                }
            }

            // Name and description
            VStack(spacing: 6) {
                Text(circle.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if let description = circle.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .multilineTextAlignment(.center)
                }
            }

            // Stats row
            HStack(spacing: 24) {
                circleStat(value: "\(circle.memberCount)", label: "Members", icon: "person.2.fill")
                circleStat(value: "\(circle.circleStreak)", label: "Streak", icon: "flame.fill", color: Theme.Colors.streakOrange)
                circleStat(value: "\(circle.circleXp)", label: "XP", icon: "star.fill", color: Theme.Colors.xp)
            }

            // Active challenge badge if any
            if hasActiveChallenge {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))

                    Text("Active Challenge")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Theme.CelestialColors.solarFlare)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.CelestialColors.solarFlare.opacity(0.15), in: Capsule())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                }
        }
    }

    private func circleStat(value: String, label: String, icon: String, color: Color = Theme.Colors.aiPurple) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.CelestialColors.starGhost)
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(CircleDetailTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))

                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == tab ? Theme.Colors.aiPurple : Theme.CelestialColors.starGhost)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.aiPurple.opacity(0.15))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .members:
            membersTab
        case .leaderboard:
            leaderboardTab
        case .activity:
            activityTab
        case .challenges:
            challengesTab
        }
    }

    // MARK: - Members Tab

    private var membersTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Members")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()

                Button {
                    showInviteSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Invite")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            if let members = circle.members {
                VStack(spacing: 8) {
                    ForEach(members) { member in
                        if let user = member.user {
                            CircleMemberRow(member: member, user: user)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Leaderboard Tab

    private var leaderboardTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Circle Leaderboard")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            if let members = circle.members?.sorted(by: { ($0.user?.totalPoints ?? 0) > ($1.user?.totalPoints ?? 0) }) {
                VStack(spacing: 8) {
                    ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                        if let user = member.user {
                            CircleLeaderboardRow(rank: index + 1, user: user)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Activity Tab

    private var activityTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Theme.Colors.aiPurple)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if activity.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Theme.CelestialColors.starGhost)

                    Text("No activity yet")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(activity) { item in
                        CircleActivityRow(activity: item)
                    }
                }
            }
        }
    }

    // MARK: - Challenges Tab

    private var challengesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Circle Challenges")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()

                Button {
                    // Create circle challenge
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                        Text("New")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.CelestialColors.solarFlare)
                }
            }

            // Placeholder for circle challenges
            VStack(spacing: 12) {
                Image(systemName: "trophy")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.CelestialColors.starGhost)

                Text("No circle challenges yet")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starDim)

                Button {
                    // Create challenge
                } label: {
                    Text("Start a Circle Challenge")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.CelestialColors.solarFlare, in: Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Helpers

    private var isAdmin: Bool {
        circle.members?.contains { $0.role == .owner || $0.role == .admin } ?? false
    }

    private var hasActiveChallenge: Bool {
        // Would check for active challenges in this circle
        false
    }

    private func loadData() async {
        isLoading = true
        activity = (try? await circleService.loadActivity(for: circle.id)) ?? []
        isLoading = false
    }

    private func startAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            headerGlow = 1
        }
    }

    private func leaveCircle() {
        Task {
            try? await circleService.leaveCircle(circle.id)
            dismiss()
        }
    }
}

// MARK: - Circle Detail Tab

enum CircleDetailTab: String, CaseIterable, Identifiable {
    case members = "Members"
    case leaderboard = "Ranks"
    case activity = "Activity"
    case challenges = "Challenges"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .members: return "person.2"
        case .leaderboard: return "chart.bar"
        case .activity: return "bubble.left.and.bubble.right"
        case .challenges: return "trophy"
        }
    }
}

// MARK: - Circle Member Row

struct CircleMemberRow: View {
    let member: CircleMember
    let user: FriendProfile

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with online indicator
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.nebulaDust)
                    .frame(width: 44, height: 44)

                Text(user.displayName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starDim)

                if user.isActiveNow {
                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.auroraGreen)
                        .frame(width: 12, height: 12)
                        .overlay {
                            SwiftUI.Circle()
                                .stroke(Theme.CelestialColors.void, lineWidth: 2)
                        }
                        .offset(x: 16, y: 16)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    // Role badge
                    if member.role != .member {
                        Text(member.role.displayName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(member.role == .owner ? Theme.Colors.xp : Theme.Colors.aiPurple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                (member.role == .owner ? Theme.Colors.xp : Theme.Colors.aiPurple).opacity(0.15),
                                in: Capsule()
                            )
                    }
                }

                if let streak = user.currentStreak, streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(streak) day streak")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Theme.Colors.streakOrange)
                }
            }

            Spacer()

            // XP
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(user.totalPoints ?? 0)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.xp)

                Text("XP")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Circle Leaderboard Row

struct CircleLeaderboardRow: View {
    let rank: Int
    let user: FriendProfile

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    SwiftUI.Circle()
                        .fill(rankGradient)
                        .frame(width: 32, height: 32)
                }

                Text("\(rank)")
                    .font(.system(size: rank <= 3 ? 14 : 13, weight: .bold, design: .rounded))
                    .foregroundStyle(rank <= 3 ? .white : Theme.CelestialColors.starGhost)
            }
            .frame(width: 32)

            // Avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.nebulaDust)
                    .frame(width: 40, height: 40)

                Text(user.displayName.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            // Name
            Text(user.displayName)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Spacer()

            // XP
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.xp)

                Text("\(user.totalPoints ?? 0)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(rank <= 3 ? rankColor.opacity(0.1) : Color.white.opacity(0.03))
        }
    }

    private var rankGradient: LinearGradient {
        LinearGradient(colors: rankColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var rankColors: [Color] {
        switch rank {
        case 1: return [Color(red: 0.98, green: 0.75, blue: 0.25), Color(red: 0.85, green: 0.55, blue: 0.15)]
        case 2: return [Color(red: 0.75, green: 0.75, blue: 0.80), Color(red: 0.55, green: 0.55, blue: 0.60)]
        case 3: return [Color(red: 0.80, green: 0.50, blue: 0.20), Color(red: 0.60, green: 0.35, blue: 0.12)]
        default: return [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore]
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 0.98, green: 0.75, blue: 0.25)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.80)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return Theme.Colors.aiPurple
        }
    }
}

// MARK: - Circle Activity Row

struct CircleActivityRow: View {
    let activity: CircleActivity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                SwiftUI.Circle()
                    .fill(activity.activityType.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: activity.activityType.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(activity.activityType.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                // User and action
                HStack(spacing: 4) {
                    Text(activity.user?.displayName ?? "User")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text(activity.message ?? activity.activityType.defaultMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                // Points earned
                if activity.pointsEarned > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("+\(activity.pointsEarned) XP")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.xp)
                }

                // Time
                Text(activity.formattedTime)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Circle Invite Sheet

struct CircleInviteSheet: View {
    let circle: Circle
    @Environment(\.dismiss) private var dismiss

    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Invite code display
                VStack(spacing: 12) {
                    Text("Invite Code")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Text(circle.formattedInviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.aiPurple)
                        .tracking(4)

                    Button {
                        UIPasteboard.general.string = circle.formattedInviteCode
                        copied = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy Code")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(copied ? Theme.CelestialColors.auroraGreen : Theme.Colors.aiPurple, in: Capsule())
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                }

                // Share options
                VStack(spacing: 12) {
                    Text("Or share directly")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    ShareLink(
                        item: "Join my productivity circle \"\(circle.name)\" on Veloce! Use code: \(circle.formattedInviteCode)",
                        subject: Text("Join my circle on Veloce"),
                        message: Text("Let's stay accountable together!")
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Invite")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(Theme.CelestialColors.void.ignoresSafeArea())
            .navigationTitle("Invite to \(circle.name)")
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

// MARK: - Circle Activity Type Extensions

extension CircleActivityType {
    var defaultMessage: String {
        switch self {
        case .taskCompleted: return "completed a task"
        case .streakMilestone: return "hit a streak milestone"
        case .levelUp: return "leveled up"
        case .achievement: return "earned an achievement"
        case .goalProgress: return "made progress on a goal"
        case .joined: return "joined the circle"
        }
    }
}

// MARK: - Preview

#Preview {
    CircleDetailViewRedesign(
        circle: Circle(
            id: UUID(),
            name: "Productivity Squad",
            description: "Stay focused and accountable together",
            inviteCode: "ABC123",
            createdBy: UUID(),
            maxMembers: 5,
            circleStreak: 7,
            circleXp: 1250,
            avatarUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            members: nil,
            recentActivity: nil,
            creator: nil
        )
    )
}
