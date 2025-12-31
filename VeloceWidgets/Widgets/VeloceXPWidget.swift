//
//  VeloceXPWidget.swift
//  VeloceWidgets
//
//  XP Progress Widget - Living Cosmos Design
//  Ethereal level badge with golden XP progress
//  Gamification at a glance with celebratory effects
//

import WidgetKit
import SwiftUI

// MARK: - XP Widget

struct VeloceXPWidget: Widget {
    let kind: String = "VeloceXPWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: XPTimelineProvider()) { entry in
            XPWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCosmicBackground(
                        showStars: true,
                        showGlow: true,
                        glowIntensity: entry.isCloseToLevelUp ? 0.5 : 0.35
                    )
                }
        }
        .configurationDisplayName("XP Progress")
        .description("Track your level and experience points")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Provider

struct XPTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> XPEntry {
        XPEntry(
            date: Date(),
            level: 12,
            currentXP: 2450,
            xpForCurrentLevel: 1600,
            xpForNextLevel: 2500,
            totalXP: 14450,
            streak: 7,
            tasksCompletedToday: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (XPEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<XPEntry>) -> Void) {
        let stats = loadStats()

        let level = stats?.currentLevel ?? 1
        let totalXP = stats?.totalPoints ?? 0

        // Calculate XP thresholds (level = sqrt(xp/100))
        let xpForCurrentLevel = level * level * 100
        let xpForNextLevel = (level + 1) * (level + 1) * 100
        let currentXP = totalXP - xpForCurrentLevel

        let entry = XPEntry(
            date: Date(),
            level: level,
            currentXP: max(0, currentXP),
            xpForCurrentLevel: xpForCurrentLevel,
            xpForNextLevel: xpForNextLevel,
            totalXP: totalXP,
            streak: stats?.currentStreak ?? 0,
            tasksCompletedToday: stats?.tasksCompletedToday ?? 0
        )

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
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

struct XPEntry: TimelineEntry {
    let date: Date
    let level: Int
    let currentXP: Int
    let xpForCurrentLevel: Int
    let xpForNextLevel: Int
    let totalXP: Int
    let streak: Int
    let tasksCompletedToday: Int

    var xpNeededForLevel: Int {
        xpForNextLevel - xpForCurrentLevel
    }

    var progress: Double {
        guard xpNeededForLevel > 0 else { return 0 }
        return min(1.0, Double(currentXP) / Double(xpNeededForLevel))
    }

    var isCloseToLevelUp: Bool {
        progress >= 0.85
    }

    var xpToNextLevel: Int {
        max(0, xpNeededForLevel - currentXP)
    }

    var tierName: String {
        switch level {
        case 1...9: return "Novice"
        case 10...24: return "Apprentice"
        case 25...49: return "Expert"
        case 50...99: return "Master"
        default: return "Legend"
        }
    }

    var tierColor: Color {
        switch level {
        case 1...9: return WidgetUtopian.Colors.emerald
        case 10...24: return WidgetUtopian.Colors.electric
        case 25...49: return WidgetUtopian.Colors.gold
        case 50...99: return WidgetUtopian.Colors.rose
        default: return WidgetUtopian.Colors.violet
        }
    }
}

// MARK: - Widget View

struct XPWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: XPEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        Link(destination: URL(string: "veloce://momentum")!) {
            VStack(spacing: 10) {
                // Level badge
                LevelBadge(level: entry.level, size: .medium)

                // XP info
                VStack(spacing: 4) {
                    Text(formatXP(entry.totalXP))
                        .font(WidgetUtopian.Typography.mediumNumber)
                        .foregroundStyle(WidgetUtopian.Colors.textPrimary)

                    Text("Total XP")
                        .font(WidgetUtopian.Typography.micro)
                        .foregroundStyle(WidgetUtopian.Colors.textTertiary)
                }

                // Progress to next level
                VStack(spacing: 4) {
                    XPProgressBar(
                        currentXP: entry.currentXP,
                        requiredXP: entry.xpNeededForLevel,
                        height: 6
                    )

                    HStack {
                        Text("\(entry.xpToNextLevel) to Lv \(entry.level + 1)")
                            .font(WidgetUtopian.Typography.micro)
                            .foregroundStyle(WidgetUtopian.Colors.textQuaternary)

                        Spacer()

                        if entry.isCloseToLevelUp {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundStyle(WidgetUtopian.Colors.gold)
                        }
                    }
                }

                // Streak indicator if active
                if entry.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(entry.streak)")
                            .font(WidgetUtopian.Typography.micro)
                    }
                    .foregroundStyle(WidgetUtopian.Colors.flameInner)
                }
            }
            .padding(14)
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        Link(destination: URL(string: "veloce://momentum")!) {
            HStack(spacing: 16) {
                // Left: Level badge with tier info
                VStack(spacing: 8) {
                    LevelBadge(level: entry.level, size: .large)

                    VStack(spacing: 2) {
                        Text(entry.tierName)
                            .font(WidgetUtopian.Typography.caption)
                            .foregroundStyle(entry.tierColor)

                        Text("Level \(entry.level)")
                            .font(WidgetUtopian.Typography.micro)
                            .foregroundStyle(WidgetUtopian.Colors.textTertiary)
                    }
                }
                .frame(width: 80)

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                WidgetUtopian.Colors.glassBorder.opacity(0),
                                WidgetUtopian.Colors.gold.opacity(0.3),
                                WidgetUtopian.Colors.glassBorder.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Right: XP details
                VStack(alignment: .leading, spacing: 10) {
                    // Total XP with star accent
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(WidgetUtopian.Colors.gold.opacity(0.2))
                                .frame(width: 28, height: 28)

                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(WidgetUtopian.Colors.gold)
                        }

                        VStack(alignment: .leading, spacing: 0) {
                            Text(formatXP(entry.totalXP))
                                .font(WidgetUtopian.Typography.mediumNumber)
                                .foregroundStyle(WidgetUtopian.Colors.textPrimary)

                            Text("Total XP earned")
                                .font(WidgetUtopian.Typography.micro)
                                .foregroundStyle(WidgetUtopian.Colors.textTertiary)
                        }
                    }

                    // Progress bar with labels
                    VStack(spacing: 4) {
                        XPProgressBar(
                            currentXP: entry.currentXP,
                            requiredXP: entry.xpNeededForLevel,
                            height: 8
                        )

                        HStack {
                            Text("\(entry.currentXP) / \(entry.xpNeededForLevel)")
                                .font(WidgetUtopian.Typography.micro)
                                .foregroundStyle(WidgetUtopian.Colors.textTertiary)

                            Spacer()

                            if entry.isCloseToLevelUp {
                                HStack(spacing: 3) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 9))
                                    Text("Almost there!")
                                        .font(WidgetUtopian.Typography.micro)
                                }
                                .foregroundStyle(WidgetUtopian.Colors.gold)
                            } else {
                                Text("\(entry.xpToNextLevel) to go")
                                    .font(WidgetUtopian.Typography.micro)
                                    .foregroundStyle(WidgetUtopian.Colors.textQuaternary)
                            }
                        }
                    }

                    // Stats row
                    HStack(spacing: 12) {
                        if entry.streak > 0 {
                            WidgetStatPill(
                                icon: "flame.fill",
                                value: "\(entry.streak)",
                                color: WidgetUtopian.Colors.flameInner
                            )
                        }

                        WidgetStatPill(
                            icon: "checkmark.circle.fill",
                            value: "\(entry.tasksCompletedToday)",
                            color: WidgetUtopian.Colors.success
                        )

                        Spacer()
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Helpers

    private func formatXP(_ xp: Int) -> String {
        if xp >= 10000 {
            return String(format: "%.1fk", Double(xp) / 1000)
        } else if xp >= 1000 {
            return String(format: "%.1fk", Double(xp) / 1000)
        }
        return "\(xp)"
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    VeloceXPWidget()
} timeline: {
    XPEntry(
        date: Date(),
        level: 12,
        currentXP: 650,
        xpForCurrentLevel: 1600,
        xpForNextLevel: 2500,
        totalXP: 2250,
        streak: 7,
        tasksCompletedToday: 5
    )
}

#Preview("Small - Close to Level Up", as: .systemSmall) {
    VeloceXPWidget()
} timeline: {
    XPEntry(
        date: Date(),
        level: 24,
        currentXP: 2350,
        xpForCurrentLevel: 5600,
        xpForNextLevel: 6250,
        totalXP: 7950,
        streak: 14,
        tasksCompletedToday: 8
    )
}

#Preview("Medium", as: .systemMedium) {
    VeloceXPWidget()
} timeline: {
    XPEntry(
        date: Date(),
        level: 12,
        currentXP: 650,
        xpForCurrentLevel: 1600,
        xpForNextLevel: 2500,
        totalXP: 2250,
        streak: 7,
        tasksCompletedToday: 5
    )
}

#Preview("Medium - Legend Tier", as: .systemMedium) {
    VeloceXPWidget()
} timeline: {
    XPEntry(
        date: Date(),
        level: 100,
        currentXP: 8500,
        xpForCurrentLevel: 1000000,
        xpForNextLevel: 1020100,
        totalXP: 1008500,
        streak: 365,
        tasksCompletedToday: 12
    )
}
