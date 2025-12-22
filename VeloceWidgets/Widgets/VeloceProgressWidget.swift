//
//  VeloceProgressWidget.swift
//  VeloceWidgets
//
//  Progress Widget - Aurora Design System
//  Ethereal cosmic progress ring with crystalline glass
//  Shows daily goal completion with aurora glow
//

import WidgetKit
import SwiftUI

// MARK: - Progress Widget

struct VeloceProgressWidget: Widget {
    let kind: String = "VeloceProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressTimelineProvider()) { entry in
            ProgressWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCosmicBackground(showStars: true, showAurora: true, auroraIntensity: 0.4)
                }
        }
        .configurationDisplayName("Daily Progress")
        .description("Track your daily goal with a beautiful aurora progress ring")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct ProgressTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(
            date: Date(),
            completed: 5,
            goal: 8,
            streak: 7,
            level: 12
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        let stats = loadStats()
        let entry = ProgressEntry(
            date: Date(),
            completed: stats?.tasksCompletedToday ?? 0,
            goal: stats?.dailyGoal ?? 5,
            streak: stats?.currentStreak ?? 0,
            level: stats?.currentLevel ?? 1
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
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

// MARK: - Stats Data

struct WidgetStatsData: Codable {
    let tasksCompletedToday: Int
    let dailyGoal: Int
    let currentStreak: Int
    let totalPoints: Int
    let currentLevel: Int
}

// MARK: - Entry

struct ProgressEntry: TimelineEntry {
    let date: Date
    let completed: Int
    let goal: Int
    let streak: Int
    let level: Int

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(completed) / Double(goal))
    }

    var isGoalMet: Bool {
        completed >= goal
    }
}

// MARK: - Widget View

struct ProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ProgressEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .accessoryCircular:
            circularAccessory
        case .accessoryRectangular:
            rectangularAccessory
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(spacing: 8) {
            // Main aurora progress ring
            ZStack {
                // Ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                WidgetAurora.Colors.violet.opacity(0.25),
                                WidgetAurora.Colors.electric.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 8)

                // Progress ring
                AuroraProgressRing(progress: entry.progress, size: 90, lineWidth: 9)

                // Center content
                VStack(spacing: 2) {
                    Text("\(entry.completed)")
                        .font(WidgetAurora.Typography.largeNumber)
                        .foregroundStyle(WidgetAurora.Colors.textPrimary)

                    Text("of \(entry.goal)")
                        .font(WidgetAurora.Typography.micro)
                        .foregroundStyle(WidgetAurora.Colors.textQuaternary)
                }
            }

            // Goal met indicator with aurora styling
            if entry.isGoalMet {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Goal achieved!")
                        .font(WidgetAurora.Typography.micro)
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [WidgetAurora.Colors.gold, WidgetAurora.Colors.flameInner],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: WidgetAurora.Colors.gold.opacity(0.4), radius: 4)
            }
        }
        .padding(12)
    }

    // MARK: - Circular Accessory (Lock Screen)

    private var circularAccessory: some View {
        ZStack {
            AccessoryWidgetBackground()

            // Custom gauge with aurora styling
            ZStack {
                // Background track
                Circle()
                    .stroke(.quaternary, lineWidth: 4)

                // Progress arc
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .cyan, .purple],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center number
                VStack(spacing: -2) {
                    Text("\(entry.completed)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    if entry.isGoalMet {
                        Image(systemName: "sparkle")
                            .font(.system(size: 8))
                    }
                }
            }
            .padding(4)
        }
    }

    // MARK: - Rectangular Accessory (Lock Screen)

    private var rectangularAccessory: some View {
        HStack(spacing: 10) {
            // Mini aurora progress ring
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .cyan, .purple],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                Text("\(entry.completed)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Progress")
                    .font(.system(size: 12, weight: .semibold))

                Text("\(entry.completed)/\(entry.goal) tasks")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if entry.streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text("\(entry.streak) day streak")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    VeloceProgressWidget()
} timeline: {
    ProgressEntry(date: Date(), completed: 5, goal: 8, streak: 7, level: 12)
}

#Preview("Small - Goal Met", as: .systemSmall) {
    VeloceProgressWidget()
} timeline: {
    ProgressEntry(date: Date(), completed: 8, goal: 8, streak: 14, level: 15)
}

#Preview("Circular", as: .accessoryCircular) {
    VeloceProgressWidget()
} timeline: {
    ProgressEntry(date: Date(), completed: 5, goal: 8, streak: 7, level: 12)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    VeloceProgressWidget()
} timeline: {
    ProgressEntry(date: Date(), completed: 5, goal: 8, streak: 7, level: 12)
}
