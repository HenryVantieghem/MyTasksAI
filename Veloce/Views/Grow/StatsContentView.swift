//
//  StatsContentView.swift
//  Veloce
//
//  Stats segment for Grow tab
//  Displays velocity score, stats grid, streaks, and level progress
//

import SwiftUI

struct StatsContentView: View {
    let velocityScore: Double
    let streak: Int
    let longestStreak: Int
    let tasksCompleted: Int
    let tasksCompletedToday: Int
    let dailyGoal: Int
    let focusHours: Double
    let completionRate: Double
    let level: Int
    let totalPoints: Int
    let levelProgress: Double

    @Environment(\.responsiveLayout) private var layout
    @State private var hasAnimated = false

    // Adaptive columns based on device
    private var gridColumns: [GridItem] {
        let columnCount: Int
        switch layout.deviceType {
        case .iPhoneSE, .iPhoneStandard, .iPhoneProMax:
            columnCount = 2
        case .iPadMini, .iPad:
            columnCount = 3
        case .iPadPro11, .iPadPro13:
            columnCount = layout.isLandscape ? 4 : 3
        }
        return Array(repeating: GridItem(.flexible(), spacing: layout.spacing), count: columnCount)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: layout.spacing * 1.5) {
                // Velocity Circle (Hero)
                velocityCircle
                    .padding(.top, layout.spacing)

                // Stats Grid - adaptive columns
                statsGrid

                // Weekly Trend
                weeklyTrendCard

                // Streaks Section
                if streak > 0 {
                    streaksCard
                }

                Spacer(minLength: layout.bottomSafeArea)
            }
            .padding(.horizontal, layout.screenPadding)
            .maxWidthConstrained()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                hasAnimated = true
            }
        }
    }

    // MARK: - Velocity Circle

    // Responsive circle size based on device
    private var circleSize: CGFloat {
        switch layout.deviceType {
        case .iPhoneSE: return 140
        case .iPhoneStandard: return 160
        case .iPhoneProMax: return 180
        case .iPadMini: return 200
        case .iPad, .iPadPro11: return 220
        case .iPadPro13: return 260
        }
    }

    private var velocityCircle: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: layout.deviceType.isTablet ? 10 : 8)
                .frame(width: circleSize, height: circleSize)

            // Progress ring
            Circle()
                .trim(from: 0, to: hasAnimated ? velocityScore / 100 : 0)
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: layout.deviceType.isTablet ? 10 : 8, lineCap: .round)
                )
                .frame(width: circleSize, height: circleSize)
                .rotationEffect(.degrees(-90))

            // Score display - Dynamic Type for accessibility
            VStack(spacing: 4) {
                Text("\(Int(velocityScore))")
                    .dynamicTypeFont(base: layout.deviceType.isTablet ? 56 : 48, weight: .thin, design: .rounded)
                    .foregroundStyle(.white)

                Text("VELOCITY")
                    .dynamicTypeFont(base: 11, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .tracking(2)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: layout.spacing) {
            QuickStatCard(
                value: "\(tasksCompletedToday)/\(dailyGoal)",
                label: "Today",
                progress: Double(tasksCompletedToday) / Double(max(dailyGoal, 1)),
                color: .green
            )

            QuickStatCard(
                value: "\(tasksCompleted)",
                label: "All Time",
                progress: min(Double(tasksCompleted) / 500, 1.0),
                color: .blue
            )

            QuickStatCard(
                value: String(format: "%.1fh", focusHours),
                label: "Focus",
                progress: min(focusHours / 40, 1.0),
                color: .purple
            )

            QuickStatCard(
                value: "\(Int(completionRate))%",
                label: "On Time",
                progress: completionRate / 100,
                color: .orange
            )
        }
    }

    // MARK: - Weekly Trend Card

    // Responsive bar width for weekly trend
    private var trendBarWidth: CGFloat {
        layout.deviceType.isTablet ? 36 : 28
    }

    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            Text("Weekly Trend")
                .dynamicTypeFont(base: 15, weight: .medium)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: layout.spacing * 0.75) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.aiPurple)
                            .frame(width: trendBarWidth, height: CGFloat.random(in: 20...80))

                        Text(day)
                            .dynamicTypeFont(base: 10, weight: .regular)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: layout.deviceType.isTablet ? 120 : 100, alignment: .bottom)
        }
        .padding(layout.cardPadding)
        .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streaks Card

    private var streaksCard: some View {
        VStack(spacing: layout.spacing) {
            HStack {
                Image(systemName: "flame.fill")
                    .dynamicTypeFont(base: 16, weight: .medium)
                    .foregroundStyle(.orange)
                Text("Current Streak")
                    .dynamicTypeFont(base: 16, weight: .regular)
                Spacer()
                Text("\(streak) days")
                    .dynamicTypeFont(base: 16, weight: .semibold)
            }

            Divider()
                .background(.white.opacity(0.1))

            HStack {
                Image(systemName: "trophy.fill")
                    .dynamicTypeFont(base: 16, weight: .medium)
                    .foregroundStyle(.yellow)
                Text("Longest Streak")
                    .dynamicTypeFont(base: 16, weight: .regular)
                Spacer()
                Text("\(longestStreak) days")
                    .dynamicTypeFont(base: 16, weight: .semibold)
            }
        }
        .padding(layout.cardPadding)
        .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let value: String
    let label: String
    let progress: Double
    let color: Color

    @Environment(\.responsiveLayout) private var layout
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing * 0.75) {
            Text(value)
                .dynamicTypeFont(base: 20, weight: .semibold)
                .foregroundStyle(.white)

            Text(label)
                .dynamicTypeFont(base: 12, weight: .regular)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.3))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * animatedProgress)
                }
            }
            .frame(height: layout.deviceType.isTablet ? 6 : 4)
        }
        .padding(layout.cardPadding)
        .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        StatsContentView(
            velocityScore: 67,
            streak: 12,
            longestStreak: 30,
            tasksCompleted: 127,
            tasksCompletedToday: 5,
            dailyGoal: 8,
            focusHours: 3.5,
            completionRate: 92,
            level: 5,
            totalPoints: 1250,
            levelProgress: 0.65
        )
    }
}
