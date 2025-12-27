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

    @State private var hasAnimated = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Velocity Circle (Hero)
                velocityCircle
                    .padding(.top, 20)

                // Stats Grid
                statsGrid

                // Weekly Trend
                weeklyTrendCard

                // Streaks Section
                if streak > 0 {
                    streaksCard
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                hasAnimated = true
            }
        }
    }

    // MARK: - Velocity Circle

    private var velocityCircle: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 160, height: 160)

            // Progress ring
            Circle()
                .trim(from: 0, to: hasAnimated ? velocityScore / 100 : 0)
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))

            // Score display
            VStack(spacing: 4) {
                Text("\(Int(velocityScore))")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)

                Text("VELOCITY")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(2)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
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

    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.aiPurple)
                            .frame(width: 28, height: CGFloat.random(in: 20...80))

                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 100, alignment: .bottom)
        }
        .padding(20)
        .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streaks Card

    private var streaksCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Current Streak")
                Spacer()
                Text("\(streak) days")
                    .fontWeight(.semibold)
            }

            Divider()
                .background(.white.opacity(0.1))

            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Longest Streak")
                Spacer()
                Text("\(longestStreak) days")
                    .fontWeight(.semibold)
            }
        }
        .padding(20)
        .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let value: String
    let label: String
    let progress: Double
    let color: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
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
            .frame(height: 4)
        }
        .padding(16)
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
