//
//  VeloceStreakWidget.swift
//  VeloceWidgets
//
//  Streak Widget - Living Cosmos Design
//  Ethereal flame with cosmic utopian glow
//  Shows productivity streak with gamification
//  "Don't break the chain!" motivation
//

import WidgetKit
import SwiftUI

// MARK: - Streak Widget

struct VeloceStreakWidget: Widget {
    let kind: String = "VeloceStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCosmicBackground(
                        showStars: true,
                        showGlow: true,
                        glowIntensity: entry.streak > 7 ? 0.5 : 0.35
                    )
                }
        }
        .configurationDisplayName("Streak Flame")
        .description("Keep your productivity streak alive!")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

// MARK: - Timeline Provider

struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 7, longestStreak: 14, level: 12, xp: 2450)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let stats = loadStats()
        let entry = StreakEntry(
            date: Date(),
            streak: stats?.currentStreak ?? 0,
            longestStreak: 0, // Would come from user profile
            level: stats?.currentLevel ?? 1,
            xp: stats?.totalPoints ?? 0
        )

        // Update at midnight for streak check
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func loadStats() -> WidgetStatsData? {
        guard let defaults = UserDefaults(suiteName: "group.com.veloce.app"),
              let data = defaults.data(forKey: "widget_stats"),
              let stats = try? JSONDecoder().decode(WidgetStatsData.self, from: data) else {
            return nil
        }
        return stats
    }
}

// MARK: - Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let longestStreak: Int
    let level: Int
    let xp: Int
    let tasksCompletedToday: Int
    let dailyGoalMet: Bool

    init(date: Date, streak: Int, longestStreak: Int, level: Int, xp: Int, tasksCompletedToday: Int = 0, dailyGoalMet: Bool = false) {
        self.date = date
        self.streak = streak
        self.longestStreak = longestStreak
        self.level = level
        self.xp = xp
        self.tasksCompletedToday = tasksCompletedToday
        self.dailyGoalMet = dailyGoalMet
    }

    var flameIntensity: UtopianFlame.FlameIntensity {
        switch streak {
        case 0: return .none
        case 1...2: return .spark
        case 3...6: return .kindle
        case 7...13: return .flame
        case 14...29: return .blaze
        default: return .inferno
        }
    }

    var motivationText: String {
        switch streak {
        case 0: return "Start your streak!"
        case 1: return "Great start!"
        case 2...6: return "Keep it going!"
        case 7...13: return "On fire!"
        case 14...29: return "Unstoppable!"
        default: return "Legendary!"
        }
    }

    var streakWarning: String? {
        guard streak > 0 && !dailyGoalMet else { return nil }
        return "Complete today's goal!"
    }

    var accentColor: Color {
        switch streak {
        case 0: return WidgetUtopian.Colors.textQuaternary
        case 1...6: return WidgetUtopian.Colors.flameInner
        case 7...13: return WidgetUtopian.Colors.flameMid
        case 14...29: return WidgetUtopian.Colors.rose
        default: return WidgetUtopian.Colors.violet
        }
    }

    var streakTierName: String {
        switch streak {
        case 0: return "No Streak"
        case 1...2: return "Spark"
        case 3...6: return "Kindling"
        case 7...13: return "Flame"
        case 14...29: return "Blaze"
        case 30...99: return "Inferno"
        default: return "Phoenix"
        }
    }

    var isPersonalBest: Bool {
        streak > 0 && streak >= longestStreak
    }
}

// MARK: - Widget View

struct StreakWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StreakEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryCircular:
            circularAccessory
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        Link(destination: URL(string: "veloce://momentum")!) {
            VStack(spacing: 8) {
                // Utopian flame with glow
                UtopianFlame(intensity: entry.flameIntensity, size: 48)

                // Streak count with utopian styling
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.streak)")
                            .font(WidgetUtopian.Typography.largeNumber)
                            .foregroundStyle(WidgetUtopian.Colors.textPrimary)

                        Text(entry.streak == 1 ? "day" : "days")
                            .font(WidgetUtopian.Typography.caption)
                            .foregroundStyle(WidgetUtopian.Colors.textTertiary)
                    }

                    // Motivation text with glow
                    Text(entry.motivationText)
                        .font(WidgetUtopian.Typography.micro)
                        .foregroundStyle(entry.accentColor)
                        .shadow(color: entry.accentColor.opacity(0.4), radius: 3)
                }

                // Warning or stats
                if let warning = entry.streakWarning {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text(warning)
                            .font(WidgetUtopian.Typography.micro)
                    }
                    .foregroundStyle(WidgetUtopian.Colors.warning)
                } else if entry.streak > 0 {
                    HStack(spacing: 12) {
                        WidgetStatPill(
                            icon: "star.fill",
                            value: "Lv \(entry.level)",
                            color: WidgetUtopian.Colors.gold
                        )

                        WidgetStatPill(
                            icon: "sparkle",
                            value: formatXP(entry.xp),
                            color: WidgetUtopian.Colors.electric
                        )
                    }
                }
            }
            .padding(14)
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        Link(destination: URL(string: "veloce://momentum")!) {
            HStack(spacing: 20) {
                // Left: Large flame with tier info
                VStack(spacing: 8) {
                    UtopianFlame(intensity: entry.flameIntensity, size: 60)

                    VStack(spacing: 2) {
                        Text(entry.streakTierName)
                            .font(WidgetUtopian.Typography.caption)
                            .foregroundStyle(entry.accentColor)

                        if entry.isPersonalBest && entry.streak > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 9))
                                Text("Personal Best!")
                                    .font(WidgetUtopian.Typography.micro)
                            }
                            .foregroundStyle(WidgetUtopian.Colors.gold)
                        }
                    }
                }
                .frame(width: 90)

                // Divider with flame gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                WidgetUtopian.Colors.glassBorder.opacity(0),
                                entry.accentColor.opacity(0.4),
                                WidgetUtopian.Colors.glassBorder.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Right: Stats and motivation
                VStack(alignment: .leading, spacing: 10) {
                    // Main streak count
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(entry.streak)")
                            .font(WidgetUtopian.Typography.heroNumber)
                            .foregroundStyle(WidgetUtopian.Colors.textPrimary)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(entry.streak == 1 ? "day" : "days")
                                .font(WidgetUtopian.Typography.subheadline)
                                .foregroundStyle(WidgetUtopian.Colors.textSecondary)

                            Text("streak")
                                .font(WidgetUtopian.Typography.micro)
                                .foregroundStyle(WidgetUtopian.Colors.textQuaternary)
                        }
                    }

                    // Motivation or warning
                    if let warning = entry.streakWarning {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))

                            Text("Don't break the chain!")
                                .font(WidgetUtopian.Typography.body)
                        }
                        .foregroundStyle(WidgetUtopian.Colors.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(WidgetUtopian.Colors.warning.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(WidgetUtopian.Colors.warning.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                    } else {
                        Text(entry.motivationText)
                            .font(WidgetUtopian.Typography.body)
                            .foregroundStyle(entry.accentColor)
                            .shadow(color: entry.accentColor.opacity(0.3), radius: 2)
                    }

                    // Stats row
                    HStack(spacing: 10) {
                        WidgetStatPill(
                            icon: "star.fill",
                            value: "Lv \(entry.level)",
                            color: WidgetUtopian.Colors.gold
                        )

                        WidgetStatPill(
                            icon: "sparkle",
                            value: formatXP(entry.xp),
                            color: WidgetUtopian.Colors.electric
                        )

                        if entry.longestStreak > 0 {
                            WidgetStatPill(
                                icon: "trophy.fill",
                                value: "\(entry.longestStreak)",
                                color: WidgetUtopian.Colors.cyan
                            )
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - Circular Accessory

    private var circularAccessory: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(entry.streak > 0 ? .orange : .secondary)

                Text("\(entry.streak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
        }
    }

    // MARK: - Helpers

    private func formatXP(_ xp: Int) -> String {
        if xp >= 1000 {
            return String(format: "%.1fk", Double(xp) / 1000)
        }
        return "\(xp)"
    }
}

// MARK: - Preview

#Preview("Small - Starting", as: .systemSmall) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 1, longestStreak: 1, level: 2, xp: 150, tasksCompletedToday: 2, dailyGoalMet: true)
}

#Preview("Small - Warning", as: .systemSmall) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 7, longestStreak: 14, level: 12, xp: 2450, tasksCompletedToday: 2, dailyGoalMet: false)
}

#Preview("Small - Blazing", as: .systemSmall) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 21, longestStreak: 21, level: 25, xp: 8500, tasksCompletedToday: 6, dailyGoalMet: true)
}

#Preview("Medium - Active", as: .systemMedium) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 7, longestStreak: 14, level: 12, xp: 2450, tasksCompletedToday: 5, dailyGoalMet: true)
}

#Preview("Medium - Personal Best", as: .systemMedium) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 21, longestStreak: 21, level: 25, xp: 8500, tasksCompletedToday: 8, dailyGoalMet: true)
}

#Preview("Medium - Warning", as: .systemMedium) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 14, longestStreak: 30, level: 18, xp: 5200, tasksCompletedToday: 2, dailyGoalMet: false)
}

#Preview("Medium - Legendary", as: .systemMedium) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 100, longestStreak: 100, level: 50, xp: 35000, tasksCompletedToday: 10, dailyGoalMet: true)
}

#Preview("Circular", as: .accessoryCircular) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 7, longestStreak: 14, level: 12, xp: 2450, tasksCompletedToday: 5, dailyGoalMet: true)
}
