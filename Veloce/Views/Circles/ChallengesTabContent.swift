//
//  ChallengesTabContent.swift
//  Veloce
//
//  Challenges - The Competitive Arena
//  Send challenges, track progress, celebrate victories
//
//  Design: Pulsing challenge cards with real-time progress bars
//  and celebration effects for winners
//

import SwiftUI

// MARK: - Challenge Type

enum ChallengeType: String, CaseIterable, Identifiable {
    case taskCompletion = "task_completion"
    case focusTime = "focus_time"
    case streak = "streak"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .taskCompletion: return "Task Sprint"
        case .focusTime: return "Focus Marathon"
        case .streak: return "Streak Builder"
        case .custom: return "Custom Challenge"
        }
    }

    var icon: String {
        switch self {
        case .taskCompletion: return "checkmark.circle.fill"
        case .focusTime: return "timer"
        case .streak: return "flame.fill"
        case .custom: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .taskCompletion: return Theme.CelestialColors.auroraGreen
        case .focusTime: return Theme.CelestialColors.plasmaCore
        case .streak: return Theme.Colors.streakOrange
        case .custom: return Theme.Colors.aiPurple
        }
    }

    var description: String {
        switch self {
        case .taskCompletion: return "Complete the most tasks"
        case .focusTime: return "Accumulate focus time"
        case .streak: return "Build consecutive days"
        case .custom: return "Define your own rules"
        }
    }

    var unitLabel: String {
        switch self {
        case .taskCompletion: return "tasks"
        case .focusTime: return "minutes"
        case .streak: return "days"
        case .custom: return "points"
        }
    }
}

// MARK: - Challenge Status

enum ChallengeStatus: String {
    case pending = "pending"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

// MARK: - Challenge Model

struct Challenge: Identifiable {
    let id: UUID
    let creatorId: UUID
    let creatorName: String
    let challengeType: ChallengeType
    let title: String
    let description: String?
    let targetValue: Int
    let durationHours: Int
    let stakes: String?
    let status: ChallengeStatus
    let winnerId: UUID?
    let xpReward: Int
    let circleId: UUID?
    let startsAt: Date?
    let endsAt: Date?
    let createdAt: Date
    let participants: [ChallengeParticipant]

    var isIncoming: Bool {
        // Challenge sent to current user that's pending
        status == .pending && participants.contains { $0.userId != creatorId && $0.status == "pending" }
    }

    var isActive: Bool {
        status == .active
    }

    var timeRemaining: TimeInterval? {
        guard let endsAt = endsAt else { return nil }
        return endsAt.timeIntervalSince(Date())
    }

    var formattedTimeRemaining: String {
        guard let remaining = timeRemaining, remaining > 0 else { return "Ended" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 24 {
            return "\(hours / 24)d \(hours % 24)h"
        }
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Challenge Participant

struct ChallengeParticipant: Identifiable {
    let id: UUID
    let challengeId: UUID
    let userId: UUID
    let userName: String
    let avatarUrl: String?
    var status: String
    var currentProgress: Int
    var completedAt: Date?
    var isWinner: Bool

    var progressPercentage: Double {
        // This would be calculated based on challenge target
        min(1.0, Double(currentProgress) / 100.0)
    }
}

// MARK: - Challenges Tab Content

struct ChallengesTabContent: View {
    var onChallengeSelected: (Challenge) -> Void
    var onCreateChallenge: () -> Void

    @State private var selectedFilter: ChallengesFilter = .all
    @State private var challenges: [Challenge] = Challenge.mockData
    @State private var showCelebration = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Filter pills
                filterPills
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Incoming challenges section
                if !incomingChallenges.isEmpty {
                    incomingSection
                }

                // Active challenges section
                if !activeChallenges.isEmpty {
                    activeSection
                }

                // Completed challenges section
                if !completedChallenges.isEmpty && selectedFilter != .active {
                    completedSection
                }

                // Empty state
                if filteredChallenges.isEmpty {
                    emptyChallengesState
                }

                // Challenge type picker (for creating new)
                challengeTypePicker
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 120)
        }
        .overlay {
            if showCelebration {
                ChallengeCelebrationOverlay(onDismiss: { showCelebration = false })
            }
        }
    }

    // MARK: - Filtered Challenges

    private var filteredChallenges: [Challenge] {
        switch selectedFilter {
        case .all: return challenges
        case .incoming: return incomingChallenges
        case .active: return activeChallenges
        case .completed: return completedChallenges
        }
    }

    private var incomingChallenges: [Challenge] {
        challenges.filter { $0.isIncoming }
    }

    private var activeChallenges: [Challenge] {
        challenges.filter { $0.isActive }
    }

    private var completedChallenges: [Challenge] {
        challenges.filter { $0.status == .completed }
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChallengesFilter.allCases) { filter in
                    filterPill(for: filter)
                }
            }
        }
    }

    private func filterPill(for filter: ChallengesFilter) -> some View {
        let count = countFor(filter)

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.displayName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(selectedFilter == filter ? filter.color : Theme.CelestialColors.starGhost)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(selectedFilter == filter ? .white.opacity(0.2) : Color.white.opacity(0.1))
                        }
                }
            }
            .foregroundStyle(selectedFilter == filter ? .white : Theme.CelestialColors.starDim)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(selectedFilter == filter ? filter.color : Color.white.opacity(0.05))
            }
        }
        .buttonStyle(.plain)
    }

    private func countFor(_ filter: ChallengesFilter) -> Int {
        switch filter {
        case .all: return challenges.count
        case .incoming: return incomingChallenges.count
        case .active: return activeChallenges.count
        case .completed: return completedChallenges.count
        }
    }

    // MARK: - Incoming Section

    private var incomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(Theme.CelestialColors.solarFlare)

                Text("Incoming Challenges")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(incomingChallenges) { challenge in
                        IncomingChallengeCard(
                            challenge: challenge,
                            onAccept: { acceptChallenge(challenge) },
                            onDecline: { declineChallenge(challenge) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Active Section

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Theme.CelestialColors.plasmaCore)

                Text("Active Challenges")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(activeChallenges) { challenge in
                    ActiveChallengeCard(challenge: challenge)
                        .onTapGesture {
                            onChallengeSelected(challenge)
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Completed Section

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.Colors.xp)

                Text("Completed")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(completedChallenges) { challenge in
                    CompletedChallengeRow(challenge: challenge)
                        .onTapGesture {
                            onChallengeSelected(challenge)
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Challenge Type Picker

    private var challengeTypePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start a Challenge")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ChallengeType.allCases) { type in
                    ChallengeTypeCard(type: type) {
                        onCreateChallenge()
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyChallengesState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                // Orbital rings
                ForEach(0..<3) { i in
                    SwiftUI.Circle()
                        .stroke(Theme.CelestialColors.solarFlare.opacity(0.1 + Double(i) * 0.05), lineWidth: 1)
                        .frame(width: CGFloat(50 + i * 25), height: CGFloat(50 + i * 25))
                }

                Image(systemName: "trophy.fill")
                    .dynamicTypeFont(base: 28, weight: .light)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.CelestialColors.solarFlare, Theme.Colors.xp],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No challenges yet")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Challenge a friend to stay accountable and earn bonus XP")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onCreateChallenge) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("Send a Challenge")
                }
                .dynamicTypeFont(base: 15, weight: .semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.CelestialColors.solarFlare, in: Capsule())
                .shadow(color: Theme.CelestialColors.solarFlare.opacity(0.4), radius: 12, y: 4)
            }
        }
        .padding(.vertical, Theme.Spacing.xxl)
    }

    // MARK: - Actions

    private func acceptChallenge(_ challenge: Challenge) {
        // TODO: Accept challenge via service
    }

    private func declineChallenge(_ challenge: Challenge) {
        // TODO: Decline challenge via service
    }
}

// MARK: - Challenges Filter

enum ChallengesFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case incoming = "Incoming"
    case active = "Active"
    case completed = "Completed"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .all: return Theme.Colors.aiPurple
        case .incoming: return Theme.CelestialColors.solarFlare
        case .active: return Theme.CelestialColors.plasmaCore
        case .completed: return Theme.CelestialColors.auroraGreen
        }
    }
}

// MARK: - Incoming Challenge Card

struct IncomingChallengeCard: View {
    let challenge: Challenge
    var onAccept: () -> Void
    var onDecline: () -> Void

    @State private var pulsePhase: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Challenge type icon
                ZStack {
                    SwiftUI.Circle()
                        .fill(challenge.challengeType.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: challenge.challengeType.icon)
                        .dynamicTypeFont(base: 18, weight: .semibold)
                        .foregroundStyle(challenge.challengeType.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("from \(challenge.creatorName)")
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()
            }

            // Challenge details
            HStack(spacing: 16) {
                detailItem(icon: "target", value: "\(challenge.targetValue)", label: challenge.challengeType.unitLabel)
                detailItem(icon: "clock", value: "\(challenge.durationHours)h", label: "duration")
                detailItem(icon: "star.fill", value: "+\(challenge.xpReward)", label: "XP", color: Theme.Colors.xp)
            }

            // Stakes if any
            if let stakes = challenge.stakes, !stakes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .dynamicTypeFont(base: 10)
                    Text("Stakes: \(stakes)")
                        .dynamicTypeFont(base: 12, weight: .medium)
                }
                .foregroundStyle(Theme.CelestialColors.solarFlare)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Text("Decline")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .dynamicTypeFont(base: 12)
                        Text("Accept")
                    }
                    .dynamicTypeFont(base: 14, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.CelestialColors.solarFlare, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.CelestialColors.solarFlare.opacity(0.3 * pulsePhase), lineWidth: 2)
                }
        }
        .shadow(color: Theme.CelestialColors.solarFlare.opacity(0.2), radius: 16)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsePhase = 1
            }
        }
    }

    private func detailItem(icon: String, value: String, label: String, color: Color = Theme.CelestialColors.starDim) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 10)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundStyle(color)

            Text(label)
                .dynamicTypeFont(base: 10)
                .foregroundStyle(Theme.CelestialColors.starGhost)
        }
    }
}

// MARK: - Active Challenge Card

struct ActiveChallengeCard: View {
    let challenge: Challenge

    @State private var progressAnimation: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Type badge
                HStack(spacing: 6) {
                    Image(systemName: challenge.challengeType.icon)
                        .dynamicTypeFont(base: 12, weight: .bold)

                    Text(challenge.challengeType.displayName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(challenge.challengeType.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(challenge.challengeType.color.opacity(0.15), in: Capsule())

                Spacer()

                // Time remaining
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .dynamicTypeFont(base: 11)

                    Text(challenge.formattedTimeRemaining)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(timeRemainingColor)
            }

            // Title
            Text(challenge.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Participants progress
            VStack(spacing: 10) {
                ForEach(challenge.participants.sorted { $0.currentProgress > $1.currentProgress }) { participant in
                    ParticipantProgressRow(
                        participant: participant,
                        targetValue: challenge.targetValue,
                        color: challenge.challengeType.color
                    )
                }
            }

            // XP reward
            HStack {
                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .dynamicTypeFont(base: 11)
                    Text("Winner gets +\(challenge.xpReward) XP")
                        .dynamicTypeFont(base: 12, weight: .medium)
                }
                .foregroundStyle(Theme.Colors.xp)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(challenge.challengeType.color.opacity(0.2), lineWidth: 1)
                }
        }
    }

    private var timeRemainingColor: Color {
        guard let remaining = challenge.timeRemaining else { return Theme.CelestialColors.starGhost }
        if remaining < 3600 { return Theme.CelestialColors.urgencyCritical }
        if remaining < 3600 * 6 { return Theme.CelestialColors.urgencyNear }
        return Theme.CelestialColors.starDim
    }
}

// MARK: - Participant Progress Row

struct ParticipantProgressRow: View {
    let participant: ChallengeParticipant
    let targetValue: Int
    let color: Color

    @State private var animatedProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: CGFloat {
        CGFloat(participant.currentProgress) / CGFloat(max(targetValue, 1))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.nebulaDust)
                    .frame(width: 32, height: 32)

                Text(participant.userName.prefix(1).uppercased())
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starDim)

                // Leader crown
                if participant.currentProgress > 0 && isLeading {
                    Image(systemName: "crown.fill")
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(Theme.Colors.xp)
                        .offset(y: -20)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(participant.userName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Spacer()

                    Text("\(participant.currentProgress)/\(targetValue)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(color)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedProgress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    animatedProgress = min(1, progress)
                }
            } else {
                animatedProgress = min(1, progress)
            }
        }
    }

    private var isLeading: Bool {
        // Would check against other participants
        true
    }
}

// MARK: - Completed Challenge Row

struct CompletedChallengeRow: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                SwiftUI.Circle()
                    .fill(challenge.challengeType.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: challenge.challengeType.icon)
                    .dynamicTypeFont(base: 18)
                    .foregroundStyle(challenge.challengeType.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if let winner = challenge.participants.first(where: { $0.isWinner }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .dynamicTypeFont(base: 10)
                        Text(winner.userName)
                            .dynamicTypeFont(base: 12)
                    }
                    .foregroundStyle(Theme.Colors.xp)
                }
            }

            Spacer()

            // Result indicator
            if challenge.participants.first(where: { $0.isWinner })?.userId == getCurrentUserId() {
                Text("WON")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.Colors.xp)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.xp.opacity(0.15), in: Capsule())
            } else {
                Text("2nd")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        }
    }

    private func getCurrentUserId() -> UUID {
        UUID() // TODO: Get from auth
    }
}

// MARK: - Challenge Type Card

struct ChallengeTypeCard: View {
    let type: ChallengeType
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Icon
                ZStack {
                    SwiftUI.Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .dynamicTypeFont(base: 20, weight: .semibold)
                        .foregroundStyle(type.color)
                }

                Text(type.displayName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text(type.description)
                    .dynamicTypeFont(base: 11)
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(type.color.opacity(isPressed ? 0.5 : 0.15), lineWidth: 1)
                    }
            }
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Challenge Celebration Overlay

struct ChallengeCelebrationOverlay: View {
    var onDismiss: () -> Void

    @State private var showContent = false
    @State private var confettiActive = false

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            // Content
            VStack(spacing: 24) {
                // Trophy with glow
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { i in
                        SwiftUI.Circle()
                            .stroke(Theme.Colors.xp.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                            .frame(width: CGFloat(100 + i * 40), height: CGFloat(100 + i * 40))
                            .scaleEffect(showContent ? 1 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.1), value: showContent)
                    }

                    Image(systemName: "trophy.fill")
                        .dynamicTypeFont(base: 60)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.75, blue: 0.25), Color(red: 0.85, green: 0.55, blue: 0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(showContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)
                }

                VStack(spacing: 8) {
                    Text("CHALLENGE WON!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.Colors.xp)

                    Text("+250 XP")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.spring(response: 0.5).delay(0.3), value: showContent)

                Button("Awesome!") {
                    onDismiss()
                }
                .dynamicTypeFont(base: 16, weight: .bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(Theme.Colors.xp, in: Capsule())
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.5), value: showContent)
            }
        }
        .onAppear {
            showContent = true
            confettiActive = true
        }
    }
}

// MARK: - Challenge Detail Sheet

struct ChallengeDetailSheet: View {
    let challenge: Challenge
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Challenge header
                    challengeHeader

                    // Participants
                    participantsSection

                    // Stats
                    statsSection
                }
                .padding()
            }
            .background(Theme.CelestialColors.void.ignoresSafeArea())
            .navigationTitle(challenge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
        }
    }

    private var challengeHeader: some View {
        VStack(spacing: 16) {
            // Type icon
            ZStack {
                SwiftUI.Circle()
                    .fill(challenge.challengeType.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: challenge.challengeType.icon)
                    .dynamicTypeFont(base: 36, weight: .semibold)
                    .foregroundStyle(challenge.challengeType.color)
            }

            // Challenge details
            VStack(spacing: 8) {
                Text(challenge.challengeType.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(challenge.challengeType.color)

                if let description = challenge.description {
                    Text(description)
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .multilineTextAlignment(.center)
                }
            }

            // Key stats
            HStack(spacing: 24) {
                statItem(icon: "target", value: "\(challenge.targetValue)", label: challenge.challengeType.unitLabel)
                statItem(icon: "clock", value: "\(challenge.durationHours)h", label: "duration")
                statItem(icon: "star.fill", value: "+\(challenge.xpReward)", label: "XP reward")
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
    }

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            ForEach(challenge.participants) { participant in
                ParticipantProgressRow(
                    participant: participant,
                    targetValue: challenge.targetValue,
                    color: challenge.challengeType.color
                )
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenge Stats")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            // Add more stats as needed
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 12)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Theme.CelestialColors.starWhite)

            Text(label)
                .dynamicTypeFont(base: 11)
                .foregroundStyle(Theme.CelestialColors.starGhost)
        }
    }
}

// MARK: - Mock Data

extension Challenge {
    static let mockData: [Challenge] = [
        Challenge(
            id: UUID(),
            creatorId: UUID(),
            creatorName: "Alex",
            challengeType: .taskCompletion,
            title: "10 Task Sprint",
            description: "Complete 10 tasks before midnight",
            targetValue: 10,
            durationHours: 24,
            stakes: "Loser buys coffee",
            status: .pending,
            winnerId: nil,
            xpReward: 150,
            circleId: nil,
            startsAt: nil,
            endsAt: nil,
            createdAt: Date(),
            participants: [
                ChallengeParticipant(id: UUID(), challengeId: UUID(), userId: UUID(), userName: "Alex", avatarUrl: nil, status: "accepted", currentProgress: 0, completedAt: nil, isWinner: false),
                ChallengeParticipant(id: UUID(), challengeId: UUID(), userId: UUID(), userName: "You", avatarUrl: nil, status: "pending", currentProgress: 0, completedAt: nil, isWinner: false)
            ]
        ),
        Challenge(
            id: UUID(),
            creatorId: UUID(),
            creatorName: "Jordan",
            challengeType: .focusTime,
            title: "2 Hour Focus Battle",
            description: nil,
            targetValue: 120,
            durationHours: 48,
            stakes: nil,
            status: .active,
            winnerId: nil,
            xpReward: 200,
            circleId: nil,
            startsAt: Date().addingTimeInterval(-3600),
            endsAt: Date().addingTimeInterval(3600 * 47),
            createdAt: Date().addingTimeInterval(-3600),
            participants: [
                ChallengeParticipant(id: UUID(), challengeId: UUID(), userId: UUID(), userName: "Jordan", avatarUrl: nil, status: "accepted", currentProgress: 45, completedAt: nil, isWinner: false),
                ChallengeParticipant(id: UUID(), challengeId: UUID(), userId: UUID(), userName: "You", avatarUrl: nil, status: "accepted", currentProgress: 62, completedAt: nil, isWinner: false)
            ]
        ),
        Challenge(
            id: UUID(),
            creatorId: UUID(),
            creatorName: "Sam",
            challengeType: .streak,
            title: "7-Day Streak Challenge",
            description: nil,
            targetValue: 7,
            durationHours: 168,
            stakes: nil,
            status: .completed,
            winnerId: UUID(),
            xpReward: 300,
            circleId: nil,
            startsAt: Date().addingTimeInterval(-86400 * 7),
            endsAt: Date().addingTimeInterval(-3600),
            createdAt: Date().addingTimeInterval(-86400 * 7),
            participants: [
                ChallengeParticipant(id: UUID(), challengeId: UUID(), userId: UUID(), userName: "Sam", avatarUrl: nil, status: "accepted", currentProgress: 5, completedAt: nil, isWinner: false),
                ChallengeParticipant(id: UUID(), challengeId: UUID(), userId: UUID(), userName: "You", avatarUrl: nil, status: "accepted", currentProgress: 7, completedAt: Date(), isWinner: true)
            ]
        )
    ]
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ChallengesTabContent(
            onChallengeSelected: { _ in },
            onCreateChallenge: { }
        )
    }
}
