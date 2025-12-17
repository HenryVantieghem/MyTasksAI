//
//  GamificationPill.swift
//  MyTasksAI
//
//  Top-right Gamification Display
//  Shows streak, points, and level with beautiful animations
//

import SwiftUI

// MARK: - Gamification Pill
/// Compact pill showing user's gamification status
struct GamificationPill: View {
    let streak: Int
    let points: Int
    let level: Int
    var showLevel: Bool = true
    var compact: Bool = false
    var onTap: (() -> Void)? = nil

    @State private var isAnimating: Bool = false

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap?()
        } label: {
            HStack(spacing: compact ? Theme.Spacing.xs : Theme.Spacing.sm) {
                // Streak badge
                StreakBadge(streak: streak, compact: compact)

                if !compact {
                    Divider()
                        .frame(height: 20)
                }

                // Points display
                PointsDisplay(points: points, compact: compact)

                // Level badge (optional)
                if showLevel && !compact {
                    Divider()
                        .frame(height: 20)

                    LevelBadge(level: level)
                }
            }
            .padding(.horizontal, compact ? Theme.Spacing.sm : Theme.Spacing.md)
            .padding(.vertical, compact ? Theme.Spacing.xs : Theme.Spacing.sm)
            .liquidGlass(cornerRadius: Theme.Radius.pill)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak Badge
struct StreakBadge: View {
    let streak: Int
    var compact: Bool = false

    @State private var isFlaming: Bool = false

    private var hasStreak: Bool {
        streak > 0
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            // Fire icon
            Image(systemName: hasStreak ? "flame.fill" : "flame")
                .font(.system(size: compact ? 14 : 16))
                .foregroundStyle(
                    hasStreak
                        ? Theme.Colors.streakOrange
                        : Theme.Colors.textTertiary
                )
                .scaleEffect(isFlaming ? 1.1 : 1.0)
                .animation(
                    hasStreak
                        ? Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        : .default,
                    value: isFlaming
                )
                .onAppear {
                    if hasStreak {
                        isFlaming = true
                    }
                }

            // Streak count
            Text("\(streak)")
                .font(compact ? Theme.Typography.caption1Medium : Theme.Typography.subheadlineMedium)
                .foregroundStyle(
                    hasStreak
                        ? Theme.Colors.streakOrange
                        : Theme.Colors.textTertiary
                )
                .contentTransition(.numericText())
        }
    }
}

// MARK: - Points Display
struct PointsDisplay: View {
    let points: Int
    var compact: Bool = false
    var showIcon: Bool = true

    @State private var previousPoints: Int = 0
    @State private var showingGain: Bool = false
    @State private var gainAmount: Int = 0

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            if showIcon {
                Image(systemName: "star.fill")
                    .font(.system(size: compact ? 12 : 14))
                    .foregroundStyle(Theme.Colors.xp)
            }

            ZStack {
                // Main points
                Text(formatPoints(points))
                    .font(compact ? Theme.Typography.caption1Medium : Theme.Typography.subheadlineMedium)
                    .foregroundStyle(Theme.Colors.xp)
                    .contentTransition(.numericText())

                // Points gain animation
                if showingGain {
                    Text("+\(gainAmount)")
                        .font(Theme.Typography.caption1Medium)
                        .foregroundStyle(Theme.Colors.gold)
                        .offset(y: -20)
                        .opacity(showingGain ? 1 : 0)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                }
            }
        }
        .onChange(of: points) {
            if points > previousPoints {
                gainAmount = points - previousPoints
                withAnimation(Theme.Animation.spring) {
                    showingGain = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(Theme.Animation.quick) {
                        showingGain = false
                    }
                }
            }
            previousPoints = points
        }
    }

    private func formatPoints(_ points: Int) -> String {
        if points >= 10000 {
            return String(format: "%.1fK", Double(points) / 1000)
        } else if points >= 1000 {
            return "\(points / 1000).\(points % 1000 / 100)K"
        }
        return "\(points)"
    }
}

// MARK: - Level Badge
struct LevelBadge: View {
    let level: Int
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: Theme.Colors.iridescentGradient.prefix(3).map { $0 },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Level number
            Text("\(level)")
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Expanded Gamification Card
/// Larger card view for stats screen
struct GamificationCard: View {
    let user: User

    private var levelProgress: Double {
        let currentLevelPoints = DesignTokens.Gamification.pointsForLevel(user.currentLevel)
        let nextLevelPoints = DesignTokens.Gamification.pointsForLevel(user.currentLevel + 1)
        let pointsInLevel = user.totalPoints - currentLevelPoints
        let pointsNeeded = nextLevelPoints - currentLevelPoints
        return Double(pointsInLevel) / Double(pointsNeeded)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header with level
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Level \(user.currentLevel)")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(user.levelTitle)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                LevelBadge(level: user.currentLevel, size: 48)
            }

            // Level progress bar
            VStack(spacing: Theme.Spacing.xs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Theme.Colors.cardBackgroundSecondary)
                            .frame(height: 8)

                        // Fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: Theme.Colors.aiGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * levelProgress, height: 8)
                            .animation(Theme.Animation.spring, value: levelProgress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(user.totalPoints) XP")
                        .font(Theme.Typography.caption1Medium)
                        .foregroundStyle(Theme.Colors.xp)

                    Spacer()

                    Text("\(DesignTokens.Gamification.pointsForLevel(user.currentLevel + 1)) XP")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Divider()

            // Stats row
            HStack(spacing: 0) {
                StatColumn(
                    icon: "flame.fill",
                    value: "\(user.currentStreak)",
                    label: "Day Streak",
                    color: Theme.Colors.streakOrange
                )

                Divider()
                    .frame(height: 40)

                StatColumn(
                    icon: "checkmark.circle.fill",
                    value: "\(user.tasksCompleted)",
                    label: "Completed",
                    color: Theme.Colors.success
                )

                Divider()
                    .frame(height: 40)

                StatColumn(
                    icon: "trophy.fill",
                    value: "\(user.achievementCount)",
                    label: "Badges",
                    color: Theme.Colors.gold
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .liquidGlass(cornerRadius: Theme.Radius.xl)
    }
}

struct StatColumn: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = Theme.Colors.accent

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Points Gain Toast
/// Floating toast that appears when points are earned
struct PointsGainToast: View {
    let points: Int
    let message: String
    var isBonus: Bool = false

    @State private var isVisible: Bool = false
    @State private var offset: CGFloat = 50

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: isBonus ? "sparkles" : "star.fill")
                .font(.system(size: 18))
                .foregroundStyle(isBonus ? Theme.Colors.gold : Theme.Colors.xp)

            VStack(alignment: .leading, spacing: 2) {
                Text("+\(points) XP")
                    .font(Theme.Typography.subheadlineMedium)
                    .foregroundStyle(isBonus ? Theme.Colors.gold : Theme.Colors.xp)

                Text(message)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .liquidGlass(cornerRadius: Theme.Radius.lg)
        .opacity(isVisible ? 1 : 0)
        .offset(y: offset)
        .onAppear {
            withAnimation(Theme.Animation.bouncySpring) {
                isVisible = true
                offset = 0
            }

            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(Theme.Animation.quick) {
                    isVisible = false
                    offset = -50
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        IridescentBackground()

        ScrollView {
            VStack(spacing: 30) {
                Text("Gamification")
                    .font(Theme.Typography.title2)

                // Pills
                HStack(spacing: Theme.Spacing.md) {
                    GamificationPill(streak: 5, points: 420, level: 3)

                    GamificationPill(streak: 12, points: 1250, level: 5, compact: true)
                }

                // Individual components
                HStack(spacing: Theme.Spacing.xl) {
                    StreakBadge(streak: 7)
                    PointsDisplay(points: 1420)
                    LevelBadge(level: 5, size: 36)
                }

                Divider()

                // Full card (mock user)
                let mockUser = User()
                GamificationCard(user: mockUser)

                Divider()

                // Points toast
                PointsGainToast(
                    points: 15,
                    message: "Task completed on time!",
                    isBonus: true
                )
            }
            .padding()
        }
    }
}
