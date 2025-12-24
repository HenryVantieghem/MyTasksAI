//
//  StatsBottomSheet.swift
//  Veloce
//
//  Stats Bottom Sheet
//  Full gamification stats with visualizations
//

import SwiftUI

// MARK: - Stats Bottom Sheet

struct StatsBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let gamification = GamificationService.shared

    @State private var showContent = false
    @State private var animatedProgress: Double = 0

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xl) {
                    // Level section
                    levelSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Stats grid
                    statsGrid
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Daily progress
                    dailyProgressSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Weekly streak
                    weeklyStreakSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(Theme.Spacing.screenPadding)
            }
            .background(sheetBackground)
            .navigationTitle("Your Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.1)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 1).delay(0.3)) {
                animatedProgress = gamification.levelProgress
            }
        }
    }

    // MARK: - Level Section

    private var levelSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Level badge with glow
            ZStack {
                // Glow
                SwiftUI.Circle()
                    .fill(Theme.Colors.iridescentGradientLinear)
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)
                    .opacity(0.5)

                // Badge
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.iridescentGradientLinear)
                        .frame(width: 80, height: 80)

                    Text("\(gamification.currentLevel)")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                }
            }

            // Level title
            Text(levelTitle)
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.textPrimary)

            // Progress to next level
            VStack(spacing: Theme.Spacing.xs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Theme.Colors.glassBackground)
                            .frame(height: 8)

                        // Progress
                        Capsule()
                            .fill(Theme.Colors.accentGradient)
                            .frame(width: geo.size.width * animatedProgress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(gamification.totalPoints) XP")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()

                    Text("\(gamification.pointsToNextLevel) XP to Level \(gamification.currentLevel + 1)")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(.vertical, Theme.Spacing.lg)
        .glassCard()
    }

    private var levelTitle: String {
        switch gamification.currentLevel {
        case 1...3: return "Beginner"
        case 4...6: return "Apprentice"
        case 7...10: return "Expert"
        case 11...15: return "Master"
        case 16...20: return "Champion"
        default: return "Legend"
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
            StatCard(
                icon: "flame.fill",
                iconColor: Theme.Colors.streakOrange,
                value: "\(gamification.currentStreak)",
                label: "Day Streak"
            )

            StatCard(
                icon: "checkmark.circle.fill",
                iconColor: Theme.Colors.success,
                value: "\(gamification.tasksCompletedToday)",
                label: "Today"
            )

            StatCard(
                icon: "star.fill",
                iconColor: Theme.Colors.xp,
                value: formatNumber(gamification.totalPoints),
                label: "Total XP"
            )

            StatCard(
                icon: "percent",
                iconColor: Theme.Colors.accent,
                value: "\(Int(gamification.completionRate * 100))%",
                label: "Completion"
            )
        }
    }

    // MARK: - Daily Progress Section

    private var dailyProgressSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Daily Goal")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.lg) {
                // Progress ring
                ZStack {
                    SwiftUI.Circle()
                        .stroke(Theme.Colors.glassBackground, lineWidth: 8)
                        .frame(width: 80, height: 80)

                    SwiftUI.Circle()
                        .trim(from: 0, to: min(Double(gamification.tasksCompletedToday) / Double(gamification.dailyGoal), 1.0))
                        .stroke(Theme.Colors.accentGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(gamification.tasksCompletedToday)")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("/ \(gamification.dailyGoal)")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    if gamification.tasksCompletedToday >= gamification.dailyGoal {
                        Label("Goal reached!", systemImage: "checkmark.seal.fill")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.success)
                    } else {
                        Text("\(gamification.dailyGoal - gamification.tasksCompletedToday) more to go")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }

                    Text("Complete \(gamification.dailyGoal) tasks daily to maintain your streak")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()
            }
        }
        .padding(Theme.Spacing.lg)
        .glassCard()
    }

    // MARK: - Weekly Streak Section

    private var weeklyStreakSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("This Week")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: Theme.Spacing.xs) {
                        SwiftUI.Circle()
                            .fill(dayCompleted(day) ? AnyShapeStyle(Theme.Colors.accentGradient) : AnyShapeStyle(Theme.Colors.glassBackground))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if dayCompleted(day) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }

                        Text(dayLabel(day))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Theme.Spacing.lg)
        .glassCard()
    }

    // MARK: - Helpers

    private func dayCompleted(_ offset: Int) -> Bool {
        // Simplified: assume streak covers recent days
        return offset < gamification.currentStreak && offset < 7
    }

    private func dayLabel(_ offset: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -6 + offset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }

    // MARK: - Background

    private var sheetBackground: some View {
        Theme.Colors.background
            .ignoresSafeArea()
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(label)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .glassCard()
    }
}

// MARK: - Glass Card Modifier

extension View {
    func glassCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .stroke(Theme.Colors.glassBorder.opacity(0.2), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    StatsBottomSheet()
}
