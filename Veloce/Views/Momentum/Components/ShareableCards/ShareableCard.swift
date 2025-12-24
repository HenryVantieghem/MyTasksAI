//
//  ShareableCard.swift
//  Veloce
//
//  Shareable Momentum Cards - Social Sharing Templates
//  Beautiful cards for sharing productivity achievements
//  Export as PNG for Instagram, TikTok, etc.
//

import SwiftUI

// MARK: - Shareable Card Type

enum ShareableCardType: String, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case streak = "streak"
    case achievement = "achievement"
    case universe = "universe"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily Recap"
        case .weekly: return "Weekly Summary"
        case .streak: return "Streak Card"
        case .achievement: return "Achievement"
        case .universe: return "My Universe"
        }
    }
}

// MARK: - Daily Recap Card

struct DailyRecapCard: View {
    let date: Date
    let tasksCompleted: Int
    let xpEarned: Int
    let focusMinutes: Int
    let streak: Int
    let level: Int

    private let cardSize = CGSize(width: 360, height: 640)

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            // Star field
            starField

            // Content
            VStack(spacing: 24) {
                // Header
                headerSection

                Spacer()

                // Main stats
                mainStats

                Spacer()

                // Footer
                footerSection
            }
            .padding(32)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.02, blue: 0.15),
                Color(red: 0.02, green: 0.02, blue: 0.08),
                Color(red: 0.01, green: 0.01, blue: 0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var starField: some View {
        Canvas { context, size in
            srand48(42)
            for _ in 0..<50 {
                let x = drand48() * size.width
                let y = drand48() * size.height
                let starSize = 1 + drand48() * 2
                let opacity = 0.3 + drand48() * 0.5

                let rect = CGRect(x: x, y: y, width: starSize, height: starSize)
                context.fill(SwiftUI.Circle().path(in: rect), with: .color(.white.opacity(opacity)))
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("DAILY RECAP")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.58, green: 0.25, blue: 0.98))
                .tracking(3)

            Text(date.formatted(date: .long, time: .omitted))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var mainStats: some View {
        VStack(spacing: 32) {
            // Central orb with tasks
            ZStack {
                // Glow
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                // Orb
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.58, green: 0.25, blue: 0.98),
                                Color(red: 0.42, green: 0.18, blue: 0.75)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.5), radius: 30)

                VStack(spacing: 4) {
                    Text("\(tasksCompleted)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("TASKS")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(2)
                }
            }

            // Stats grid
            HStack(spacing: 24) {
                statItem(value: "\(xpEarned)", label: "XP", color: Color(red: 0.98, green: 0.75, blue: 0.25))
                statItem(value: "\(focusMinutes)m", label: "FOCUS", color: Color(red: 0.42, green: 0.45, blue: 0.98))
                statItem(value: "\(streak)", label: "STREAK", color: Color(red: 0.98, green: 0.55, blue: 0.25))
            }
        }
    }

    @ViewBuilder
    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var footerSection: some View {
        VStack(spacing: 12) {
            // Level badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("Level \(level)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.58, green: 0.25, blue: 0.98))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.2))
            )

            // Branding
            HStack(spacing: 6) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 14))
                Text("Veloce")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - Weekly Momentum Card

struct WeeklyMomentumCard: View {
    let weekData: [Int]  // Tasks per day (7 days)
    let totalTasks: Int
    let totalXP: Int
    let streak: Int
    let level: Int
    let weekStartDate: Date

    private let cardSize = CGSize(width: 360, height: 640)

    private var weekEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
    }

    private var maxDayValue: Int {
        weekData.max() ?? 1
    }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Nebula effect
            nebulaBackground

            // Content
            VStack(spacing: 24) {
                headerSection

                Spacer()

                // Week visualization
                weekVisualization

                Spacer()

                // Stats
                statsRow

                // Footer
                footerSection
            }
            .padding(32)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.05, blue: 0.12),
                Color(red: 0.01, green: 0.02, blue: 0.06),
                Color(red: 0.01, green: 0.01, blue: 0.03)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private var nebulaBackground: some View {
        Canvas { context, size in
            // Purple nebula blob
            let purpleBlob = Path(ellipseIn: CGRect(x: -50, y: 100, width: 200, height: 150))
            context.fill(purpleBlob, with: .color(Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.15)))

            // Blue nebula blob
            let blueBlob = Path(ellipseIn: CGRect(x: size.width - 100, y: size.height - 200, width: 180, height: 140))
            context.fill(blueBlob, with: .color(Color(red: 0.42, green: 0.45, blue: 0.98).opacity(0.12)))
        }
        .blur(radius: 40)
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("WEEKLY MOMENTUM")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.98))
                .tracking(3)

            Text("\(weekStartDate.formatted(.dateTime.month().day())) - \(weekEndDate.formatted(.dateTime.month().day()))")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var weekVisualization: some View {
        VStack(spacing: 16) {
            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    let value = weekData[day]
                    let height = maxDayValue > 0 ? CGFloat(value) / CGFloat(maxDayValue) : 0

                    VStack(spacing: 6) {
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.42, green: 0.45, blue: 0.98),
                                        Color(red: 0.58, green: 0.25, blue: 0.98)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 32, height: max(8, 120 * height))
                            .shadow(color: Color(red: 0.42, green: 0.45, blue: 0.98).opacity(0.4), radius: 8)

                        // Day label
                        Text(dayLabel(for: day))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            // Total tasks
            Text("\(totalTasks) tasks completed")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func dayLabel(for index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(totalXP.formatted())")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.98, green: 0.75, blue: 0.25))
                Text("XP")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 30)

            VStack(spacing: 4) {
                Text("\(streak)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.98, green: 0.55, blue: 0.25))
                Text("STREAK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 30)

            VStack(spacing: 4) {
                Text("\(level)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.58, green: 0.25, blue: 0.98))
                Text("LEVEL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
        )
    }

    @ViewBuilder
    private var footerSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 14))
            Text("Veloce")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.4))
    }
}

// MARK: - Streak Card

struct StreakShareCard: View {
    let streak: Int
    let level: Int

    private let cardSize = CGSize(width: 360, height: 640)

    private var phoenixTier: PhoenixTier {
        PhoenixTier.forStreak(streak)
    }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Fire particles
            fireParticles

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Phoenix/flame visualization
                phoenixVisualization

                // Streak number
                VStack(spacing: 8) {
                    Text("\(streak)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [phoenixTier.primaryColor, phoenixTier.secondaryColor],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("DAY STREAK")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(3)
                }

                // Tier badge
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                    Text(phoenixTier.tierName.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(2)
                }
                .foregroundStyle(phoenixTier.primaryColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(phoenixTier.primaryColor.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(phoenixTier.primaryColor.opacity(0.3), lineWidth: 1)
                        )
                )

                Spacer()

                // Footer
                HStack(spacing: 6) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 14))
                    Text("Veloce")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.4))
            }
            .padding(32)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                phoenixTier.primaryColor.opacity(0.3),
                Color(red: 0.05, green: 0.02, blue: 0.02),
                Color(red: 0.02, green: 0.01, blue: 0.01)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private var fireParticles: some View {
        Canvas { context, size in
            srand48(Int(streak))
            for _ in 0..<30 {
                let x = size.width * 0.3 + drand48() * size.width * 0.4
                let y = size.height * 0.2 + drand48() * size.height * 0.4
                let particleSize = 2 + drand48() * 4
                let opacity = 0.2 + drand48() * 0.4

                let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)

                let colorChoice = drand48()
                let color: Color
                if colorChoice < 0.5 {
                    color = phoenixTier.primaryColor.opacity(opacity)
                } else {
                    color = phoenixTier.secondaryColor.opacity(opacity)
                }

                context.fill(SwiftUI.Circle().path(in: rect), with: .color(color))
            }
        }
        .blur(radius: 2)
    }

    @ViewBuilder
    private var phoenixVisualization: some View {
        ZStack {
            // Outer glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            phoenixTier.primaryColor.opacity(0.4),
                            phoenixTier.secondaryColor.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)

            // Flame icon
            Image(systemName: "flame.fill")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [phoenixTier.primaryColor, phoenixTier.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: phoenixTier.primaryColor.opacity(0.5), radius: 20)
        }
    }
}

// MARK: - Share Card Sheet

struct ShareCardSheet: View {
    let cardType: ShareableCardType
    let gamification: GamificationService

    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    cardPreview
                        .shadow(color: .black.opacity(0.3), radius: 20)

                    // Export button
                    Button {
                        exportCard()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Share")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.58, green: 0.25, blue: 0.98),
                                            Color(red: 0.42, green: 0.45, blue: 0.98)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 24)
            }
            .background(Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea())
            .navigationTitle("Share Card")
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

    @ViewBuilder
    private var cardPreview: some View {
        switch cardType {
        case .daily:
            DailyRecapCard(
                date: Date(),
                tasksCompleted: gamification.tasksCompletedToday,
                xpEarned: gamification.totalPoints,
                focusMinutes: gamification.focusMinutesTotal,
                streak: gamification.currentStreak,
                level: gamification.currentLevel
            )
            .scaleEffect(0.85)

        case .weekly:
            WeeklyMomentumCard(
                weekData: gamification.weeklyActivityData,
                totalTasks: gamification.weeklyActivityData.reduce(0, +),
                totalXP: gamification.totalPoints,
                streak: gamification.currentStreak,
                level: gamification.currentLevel,
                weekStartDate: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
            )
            .scaleEffect(0.85)

        case .streak:
            StreakShareCard(
                streak: gamification.currentStreak,
                level: gamification.currentLevel
            )
            .scaleEffect(0.85)

        default:
            DailyRecapCard(
                date: Date(),
                tasksCompleted: gamification.tasksCompletedToday,
                xpEarned: gamification.totalPoints,
                focusMinutes: gamification.focusMinutesTotal,
                streak: gamification.currentStreak,
                level: gamification.currentLevel
            )
            .scaleEffect(0.85)
        }
    }

    private func exportCard() {
        // TODO: Implement image export and share sheet
        isExporting = true
    }
}

// MARK: - Preview

#Preview("Daily") {
    DailyRecapCard(
        date: Date(),
        tasksCompleted: 12,
        xpEarned: 450,
        focusMinutes: 180,
        streak: 7,
        level: 15
    )
}

#Preview("Weekly") {
    WeeklyMomentumCard(
        weekData: [5, 8, 6, 10, 7, 3, 9],
        totalTasks: 48,
        totalXP: 2450,
        streak: 14,
        level: 18,
        weekStartDate: Date()
    )
}

#Preview("Streak") {
    StreakShareCard(
        streak: 45,
        level: 22
    )
}
