//
//  CirclesTabContent.swift
//  Veloce
//
//  Circles Tab Content - Your accountability groups
//  Circle cards with member avatars, stats, and active challenges
//

import SwiftUI

// MARK: - Circles Tab Content

struct CirclesTabContent: View {
    let circleService: CircleService
    var onCircleSelected: (Circle) -> Void
    var onCreateCircle: () -> Void
    var onJoinCircle: () -> Void

    @State private var selectedFilter: CirclesContentFilter = .all

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Filter and sort
                filterBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Circles grid or list
                if circleService.circles.isEmpty {
                    emptyCirclesState
                } else {
                    circlesList
                }
            }
            .padding(.bottom, 120)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack {
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CirclesContentFilter.allCases) { filter in
                        filterPill(for: filter)
                    }
                }
            }

            Spacer()
        }
    }

    private func filterPill(for filter: CirclesContentFilter) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11, weight: .semibold))

                Text(filter.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(selectedFilter == filter ? .white : Theme.CelestialColors.starDim)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(selectedFilter == filter ? Theme.Colors.aiPurple : Color.white.opacity(0.05))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Circles List

    private var circlesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredCircles) { circle in
                EnhancedCircleCard(circle: circle)
                    .onTapGesture {
                        onCircleSelected(circle)
                    }
            }
        }
        .padding(.horizontal, 20)
    }

    private var filteredCircles: [Circle] {
        switch selectedFilter {
        case .all:
            return circleService.circles
        case .active:
            return circleService.circles.filter { $0.circleStreak > 0 }
        case .owned:
            return circleService.circles.filter { isOwner(of: $0) }
        }
    }

    private func isOwner(of circle: Circle) -> Bool {
        // Would check if current user is owner
        circle.members?.contains { $0.role == .owner } ?? false
    }

    // MARK: - Empty State

    private var emptyCirclesState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Illustration
            ZStack {
                ForEach(0..<3) { i in
                    SwiftUI.Circle()
                        .stroke(Theme.Colors.aiPurple.opacity(0.1 + Double(i) * 0.05), lineWidth: 1)
                        .frame(width: CGFloat(60 + i * 25), height: CGFloat(60 + i * 25))
                }

                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Create your first circle")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Invite friends and stay accountable together")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            HStack(spacing: 12) {
                Button(action: onCreateCircle) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Create")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.aiPurple, in: Capsule())
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 4)
                }

                Button(action: onJoinCircle) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 14, weight: .bold))
                        Text("Join")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .strokeBorder(Theme.Colors.aiPurple, lineWidth: 2)
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xxl)
    }
}

// MARK: - Circles Content Filter

enum CirclesContentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case owned = "My Circles"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "circle.hexagongrid"
        case .active: return "bolt"
        case .owned: return "crown"
        }
    }
}

// MARK: - Enhanced Circle Card

struct EnhancedCircleCard: View {
    let circle: Circle

    @State private var glowPhase: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                // Circle avatar
                ZStack {
                    // Glow for active circles
                    if circle.circleStreak > 0 && !reduceMotion {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.aiPurple.opacity(0.2 * glowPhase))
                            .frame(width: 64, height: 64)
                            .blur(radius: 10)
                    }

                    SwiftUI.Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)

                    Text(circle.name.prefix(2).uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    // Member avatars stack
                    HStack(spacing: -8) {
                        ForEach(0..<min(4, circle.memberCount), id: \.self) { i in
                            SwiftUI.Circle()
                                .fill(Theme.CelestialColors.nebulaDust)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    SwiftUI.Circle()
                                        .stroke(Theme.CelestialColors.void, lineWidth: 2)
                                }
                        }

                        if circle.memberCount > 4 {
                            ZStack {
                                SwiftUI.Circle()
                                    .fill(Theme.Colors.aiPurple.opacity(0.3))
                                    .frame(width: 24, height: 24)

                                Text("+\(circle.memberCount - 4)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Theme.Colors.aiPurple)
                            }
                            .overlay {
                                SwiftUI.Circle()
                                    .stroke(Theme.CelestialColors.void, lineWidth: 2)
                            }
                        }

                        Text("\(circle.memberCount) members")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starGhost)
                            .padding(.leading, 8)
                    }
                }

                Spacer()

                // Stats column
                VStack(alignment: .trailing, spacing: 6) {
                    // Streak
                    if circle.circleStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                            Text("\(circle.circleStreak)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Theme.Colors.streakOrange)
                    }

                    // XP
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("\(circle.circleXp)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Theme.Colors.xp)
                }
            }

            // Active challenge indicator
            if hasActiveChallenge {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))

                    Text("Circle Challenge Active")
                        .font(.system(size: 12, weight: .semibold))

                    Spacer()

                    Text("2h left")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.CelestialColors.urgencyNear)
                }
                .foregroundStyle(Theme.CelestialColors.solarFlare)
                .padding(10)
                .background(Theme.CelestialColors.solarFlare.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }

            // Description if available
            if let description = circle.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            circle.circleStreak > 0
                            ? Theme.Colors.aiPurple.opacity(0.3)
                            : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: circle.circleStreak > 0 ? Theme.Colors.aiPurple.opacity(0.15) : Color.clear, radius: 16)
        .onAppear {
            guard !reduceMotion, circle.circleStreak > 0 else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }

    private var hasActiveChallenge: Bool {
        // Would check for active challenges
        false
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        CirclesTabContent(
            circleService: CircleService.shared,
            onCircleSelected: { _ in },
            onCreateCircle: { },
            onJoinCircle: { }
        )
    }
}
