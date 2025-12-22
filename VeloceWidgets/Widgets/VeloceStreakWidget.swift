//
//  VeloceStreakWidget.swift
//  VeloceWidgets
//
//  Streak Widget - Aurora Design System
//  Ethereal flame with cosmic aurora glow
//  Shows productivity streak with gamification
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
                        showAurora: true,
                        auroraIntensity: entry.streak > 7 ? 0.45 : 0.35
                    )
                }
        }
        .configurationDisplayName("Streak Flame")
        .description("Keep your productivity streak alive!")
        .supportedFamilies([.systemSmall, .accessoryCircular])
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

    var flameIntensity: AuroraFlame.FlameIntensity {
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

    var accentColor: Color {
        switch streak {
        case 0: return WidgetAurora.Colors.textQuaternary
        case 1...6: return WidgetAurora.Colors.flameInner
        case 7...13: return WidgetAurora.Colors.flameMid
        case 14...29: return WidgetAurora.Colors.rose
        default: return WidgetAurora.Colors.violet
        }
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
        case .accessoryCircular:
            circularAccessory
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(spacing: 8) {
            // Aurora flame with glow
            AuroraFlame(intensity: entry.flameIntensity, size: 48)

            // Streak count with aurora styling
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.streak)")
                        .font(WidgetAurora.Typography.largeNumber)
                        .foregroundStyle(WidgetAurora.Colors.textPrimary)

                    Text(entry.streak == 1 ? "day" : "days")
                        .font(WidgetAurora.Typography.caption)
                        .foregroundStyle(WidgetAurora.Colors.textTertiary)
                }

                // Motivation text with glow
                Text(entry.motivationText)
                    .font(WidgetAurora.Typography.micro)
                    .foregroundStyle(entry.accentColor)
                    .shadow(color: entry.accentColor.opacity(0.4), radius: 3)
            }

            // Level badge with aurora styling
            if entry.streak > 0 {
                HStack(spacing: 12) {
                    // Level
                    WidgetStatPill(
                        icon: "star.fill",
                        value: "Lv \(entry.level)",
                        color: WidgetAurora.Colors.gold
                    )

                    // XP
                    WidgetStatPill(
                        icon: "sparkle",
                        value: formatXP(entry.xp),
                        color: WidgetAurora.Colors.electric
                    )
                }
            }
        }
        .padding(14)
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
    StreakEntry(date: Date(), streak: 1, longestStreak: 1, level: 2, xp: 150)
}

#Preview("Small - Active", as: .systemSmall) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 7, longestStreak: 14, level: 12, xp: 2450)
}

#Preview("Small - Blazing", as: .systemSmall) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 21, longestStreak: 21, level: 25, xp: 8500)
}

#Preview("Small - Legendary", as: .systemSmall) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 45, longestStreak: 45, level: 42, xp: 25000)
}

#Preview("Circular", as: .accessoryCircular) {
    VeloceStreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 7, longestStreak: 14, level: 12, xp: 2450)
}
