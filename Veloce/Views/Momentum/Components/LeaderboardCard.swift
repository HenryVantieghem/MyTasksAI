//
//  LeaderboardCard.swift
//  Veloce
//
//  Leaderboard Card & Sheet - Anonymous Productivity Rankings
//  Weekly/Monthly leaderboards with cosmic theming
//  Shows XP, streaks, tasks completed, and focus time
//

import SwiftUI

// MARK: - Leaderboard Category

enum LeaderboardCategory: String, CaseIterable, Identifiable {
    case xp = "xp"
    case streak = "streak"
    case tasks = "tasks"
    case focus = "focus"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .xp: return "XP Earned"
        case .streak: return "Streak"
        case .tasks: return "Tasks"
        case .focus: return "Focus Time"
        }
    }

    var icon: String {
        switch self {
        case .xp: return "star.fill"
        case .streak: return "flame.fill"
        case .tasks: return "checkmark.circle.fill"
        case .focus: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .xp: return Color(red: 0.58, green: 0.25, blue: 0.98)
        case .streak: return Color(red: 0.98, green: 0.55, blue: 0.25)
        case .tasks: return Color(red: 0.20, green: 0.85, blue: 0.55)
        case .focus: return Color(red: 0.42, green: 0.45, blue: 0.98)
        }
    }

    var valueFormatter: (Int) -> String {
        switch self {
        case .xp: return { "\($0.formatted()) XP" }
        case .streak: return { "\($0) days" }
        case .tasks: return { "\($0) tasks" }
        case .focus: return { "\($0 / 60)h \($0 % 60)m" }
        }
    }
}

// MARK: - Leaderboard Time Period

enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "all_time"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let rank: Int
    let anonymousName: String
    let value: Int
    let isCurrentUser: Bool
    let previousRank: Int?  // For movement indicator

    var rankChange: Int? {
        guard let previous = previousRank else { return nil }
        return previous - rank  // Positive = moved up
    }

    var rankIcon: String? {
        guard let change = rankChange else { return nil }
        if change > 0 { return "arrow.up" }
        if change < 0 { return "arrow.down" }
        return nil
    }

    var rankColor: Color? {
        guard let change = rankChange else { return nil }
        if change > 0 { return Color(red: 0.20, green: 0.85, blue: 0.55) }
        if change < 0 { return Color(red: 0.98, green: 0.35, blue: 0.20) }
        return nil
    }
}

// MARK: - Leaderboard Card (Compact)

struct LeaderboardCard: View {
    let category: LeaderboardCategory
    let userRank: Int
    let userValue: Int
    let totalParticipants: Int
    var onTap: (() -> Void)?

    @State private var glowPhase: Double = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(category.color)

                    Text(category.displayName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.3))
                }

                // Rank display
                HStack(alignment: .bottom, spacing: 8) {
                    // Rank number with glow
                    ZStack {
                        if userRank <= 3 && !reduceMotion {
                            SwiftUI.Circle()
                                .fill(category.color.opacity(0.3 * glowPhase))
                                .frame(width: 60, height: 60)
                                .blur(radius: 10)
                        }

                        Text("#\(userRank)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(
                                userRank <= 3
                                ? LinearGradient(
                                    colors: [category.color, category.color.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.valueFormatter(userValue))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("of \(totalParticipants.formatted()) users")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }

                    Spacer()

                    // Medal for top 3
                    if userRank <= 3 {
                        medalIcon(for: userRank)
                    }
                }
            }
            .padding(16)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }

    @ViewBuilder
    private func medalIcon(for rank: Int) -> some View {
        let (icon, colors): (String, [Color]) = {
            switch rank {
            case 1: return ("medal.fill", [Color(red: 0.98, green: 0.75, blue: 0.25), Color(red: 0.85, green: 0.65, blue: 0.20)])
            case 2: return ("medal.fill", [Color(red: 0.75, green: 0.75, blue: 0.78), Color(red: 0.60, green: 0.60, blue: 0.65)])
            case 3: return ("medal.fill", [Color(red: 0.80, green: 0.50, blue: 0.20), Color(red: 0.65, green: 0.40, blue: 0.15)])
            default: return ("", [])
            }
        }()

        Image(systemName: icon)
            .font(.system(size: 28))
            .foregroundStyle(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .symbolEffect(.bounce, options: .repeating.speed(0.3))
    }

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        userRank <= 3
                        ? category.color.opacity(0.3)
                        : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Leaderboard Sheet

struct LeaderboardSheet: View {
    @State private var selectedCategory: LeaderboardCategory = .xp
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    @State private var entries: [LeaderboardEntry] = LeaderboardEntry.mockData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Picker
                categoryPicker

                // Period Picker
                periodPicker

                // Leaderboard List
                leaderboardList
            }
            .background(Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea())
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(red: 0.58, green: 0.25, blue: 0.98))
                }
            }
        }
    }

    // MARK: - Category Picker

    @ViewBuilder
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LeaderboardCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12, weight: .bold))

                            Text(category.displayName)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(
                            selectedCategory == category
                            ? .white
                            : Color.white.opacity(0.5)
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    selectedCategory == category
                                    ? category.color
                                    : Color.white.opacity(0.08)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Period Picker

    @ViewBuilder
    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardPeriod.allCases) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.displayName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            selectedPeriod == period
                            ? .white
                            : Color.white.opacity(0.5)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedPeriod == period
                            ? selectedCategory.color.opacity(0.3)
                            : Color.clear
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
    }

    // MARK: - Leaderboard List

    @ViewBuilder
    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(entries) { entry in
                    LeaderboardRow(
                        entry: entry,
                        category: selectedCategory
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let category: LeaderboardCategory

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    medalBackground(for: entry.rank)
                }

                Text("\(entry.rank)")
                    .font(.system(size: entry.rank <= 3 ? 16 : 14, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.rank <= 3 ? .white : Color.white.opacity(0.6))
            }
            .frame(width: 36, height: 36)

            // Name and movement
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.anonymousName)
                        .font(.system(size: 15, weight: entry.isCurrentUser ? .bold : .medium, design: .rounded))
                        .foregroundStyle(entry.isCurrentUser ? category.color : .white)

                    if entry.isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(category.color)
                            )
                    }
                }

                // Movement indicator
                if let icon = entry.rankIcon, let color = entry.rankColor, let change = entry.rankChange {
                    HStack(spacing: 2) {
                        Image(systemName: icon)
                            .font(.system(size: 10, weight: .bold))
                        Text("\(abs(change))")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(color)
                }
            }

            Spacer()

            // Value
            Text(category.valueFormatter(entry.value))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(entry.isCurrentUser ? category.color : Color.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    entry.isCurrentUser
                    ? category.color.opacity(0.15)
                    : Color.white.opacity(0.03)
                )
                .overlay(
                    entry.isCurrentUser
                    ? RoundedRectangle(cornerRadius: 12)
                        .stroke(category.color.opacity(0.3), lineWidth: 1)
                    : nil
                )
        )
    }

    @ViewBuilder
    private func medalBackground(for rank: Int) -> some View {
        let colors: [Color] = {
            switch rank {
            case 1: return [Color(red: 0.98, green: 0.75, blue: 0.25), Color(red: 0.85, green: 0.55, blue: 0.15)]
            case 2: return [Color(red: 0.75, green: 0.75, blue: 0.80), Color(red: 0.55, green: 0.55, blue: 0.60)]
            case 3: return [Color(red: 0.80, green: 0.50, blue: 0.20), Color(red: 0.60, green: 0.35, blue: 0.12)]
            default: return [Color.clear]
            }
        }()

        SwiftUI.Circle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Mock Data

extension LeaderboardEntry {
    static let mockData: [LeaderboardEntry] = [
        LeaderboardEntry(id: UUID(), rank: 1, anonymousName: "CosmicExplorer", value: 12450, isCurrentUser: false, previousRank: 1),
        LeaderboardEntry(id: UUID(), rank: 2, anonymousName: "NebulaHunter", value: 11200, isCurrentUser: false, previousRank: 4),
        LeaderboardEntry(id: UUID(), rank: 3, anonymousName: "StarForger", value: 10800, isCurrentUser: false, previousRank: 2),
        LeaderboardEntry(id: UUID(), rank: 4, anonymousName: "VoidWalker", value: 9650, isCurrentUser: true, previousRank: 6),
        LeaderboardEntry(id: UUID(), rank: 5, anonymousName: "GalaxyRider", value: 8900, isCurrentUser: false, previousRank: 5),
        LeaderboardEntry(id: UUID(), rank: 6, anonymousName: "PulsarPilot", value: 8200, isCurrentUser: false, previousRank: 3),
        LeaderboardEntry(id: UUID(), rank: 7, anonymousName: "QuasarQueen", value: 7800, isCurrentUser: false, previousRank: 8),
        LeaderboardEntry(id: UUID(), rank: 8, anonymousName: "DarkMatter", value: 7100, isCurrentUser: false, previousRank: 7),
        LeaderboardEntry(id: UUID(), rank: 9, anonymousName: "EventHorizon", value: 6500, isCurrentUser: false, previousRank: 10),
        LeaderboardEntry(id: UUID(), rank: 10, anonymousName: "StellarSage", value: 5900, isCurrentUser: false, previousRank: 9)
    ]
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            LeaderboardCard(
                category: .xp,
                userRank: 4,
                userValue: 9650,
                totalParticipants: 1234
            )

            LeaderboardCard(
                category: .streak,
                userRank: 1,
                userValue: 45,
                totalParticipants: 1234
            )
        }
        .padding()
    }
}

#Preview("Sheet") {
    LeaderboardSheet()
}
