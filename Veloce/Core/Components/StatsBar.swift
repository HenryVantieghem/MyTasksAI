//
//  StatsBar.swift
//  MyTasksAI
//
//  Amy-inspired Bottom Stats Bar
//  Shows task completion stats with beautiful glass styling
//

import SwiftUI

// MARK: - Stats Bar
/// Bottom stats bar similar to Amy's macro bar
struct StatsBar: View {
    let stats: [StatItem]
    var showTotalProgress: Bool = true
    var totalProgress: Double = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Progress bar (optional)
            if showTotalProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(Theme.Colors.cardBackgroundSecondary)
                            .frame(height: 4)

                        // Progress fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: Theme.Colors.aiGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(totalProgress, 1.0), height: 4)
                            .animation(Theme.Animation.spring, value: totalProgress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, Theme.Spacing.sm)
            }

            // Stats row
            HStack(spacing: 0) {
                ForEach(stats) { stat in
                    StatItemView(stat: stat)

                    if stat.id != stats.last?.id {
                        Divider()
                            .frame(height: 30)
                            .padding(.horizontal, Theme.Spacing.xs)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .liquidGlass(cornerRadius: Theme.Radius.xl)
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let stat: StatItem

    var body: some View {
        VStack(spacing: 2) {
            // Value
            Text(stat.formattedValue)
                .font(Theme.Typography.headline)
                .foregroundStyle(stat.color ?? Theme.Colors.textPrimary)
                .contentTransition(.numericText())

            // Label
            Text(stat.label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat Item Model
struct StatItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let format: StatFormat
    var color: Color? = nil
    var icon: String? = nil

    var formattedValue: String {
        switch format {
        case .integer:
            return "\(Int(value))"
        case .percentage:
            return "\(Int(value * 100))%"
        case .decimal(let places):
            return String(format: "%.\(places)f", value)
        case .time:
            let hours = Int(value) / 60
            let minutes = Int(value) % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(minutes)m"
        case .custom(let formatter):
            return formatter(value)
        }
    }

    enum StatFormat {
        case integer
        case percentage
        case decimal(Int)
        case time
        case custom((Double) -> String)
    }
}

// MARK: - Task Stats Bar
/// Specialized stats bar for task statistics
struct TaskStatsBar: View {
    let completed: Int
    let total: Int
    let streak: Int
    let points: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    private var stats: [StatItem] {
        [
            StatItem(
                label: "Done",
                value: Double(completed),
                format: .integer,
                color: Theme.Colors.success
            ),
            StatItem(
                label: "Remaining",
                value: Double(max(0, total - completed)),
                format: .integer
            ),
            StatItem(
                label: "Streak",
                value: Double(streak),
                format: .custom { val in "\(Int(val))d" },
                color: Theme.Colors.streakOrange
            ),
            StatItem(
                label: "Points",
                value: Double(points),
                format: .integer,
                color: Theme.Colors.xp
            )
        ]
    }

    var body: some View {
        StatsBar(
            stats: stats,
            showTotalProgress: true,
            totalProgress: progress
        )
    }
}

// MARK: - Compact Stats Row
/// Inline compact stats display
struct CompactStatsRow: View {
    let items: [(String, String, Color?)]

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: Theme.Spacing.xxs) {
                    Text(item.1)
                        .font(Theme.Typography.caption1Medium)
                        .foregroundStyle(item.2 ?? Theme.Colors.textPrimary)

                    Text(item.0)
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
        }
    }
}

// MARK: - Circular Progress Stat
/// Circular progress indicator with stat
struct CircularProgressStat: View {
    let value: Double
    let total: Double
    let label: String
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6
    var color: Color = Theme.Colors.accent

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(value / total, 1.0)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            ZStack {
                // Background track
                Circle()
                    .stroke(
                        Theme.Colors.cardBackgroundSecondary,
                        lineWidth: lineWidth
                    )

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.spring, value: progress)

                // Value text
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("/\(Int(total))")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .frame(width: size, height: size)

            // Label
            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Weekly Progress Bar
/// Horizontal weekly progress display
struct WeeklyProgressBar: View {
    let days: [DayProgress]

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(days) { day in
                    VStack(spacing: Theme.Spacing.xxs) {
                        // Progress bar
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(day.progress > 0 ? Theme.Colors.accent : Theme.Colors.cardBackgroundSecondary)
                                    .frame(height: geometry.size.height * min(day.progress, 1.0))
                            }
                        }
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.Colors.cardBackgroundSecondary)
                        )

                        // Day label
                        Text(day.label)
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(
                                day.isToday
                                    ? Theme.Colors.accent
                                    : Theme.Colors.textTertiary
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .liquidGlass(cornerRadius: Theme.Radius.md)
    }
}

struct DayProgress: Identifiable {
    let id = UUID()
    let label: String
    let progress: Double
    var isToday: Bool = false
}

// MARK: - Preview
#Preview {
    ZStack {
        IridescentBackground()

        VStack(spacing: 30) {
            Text("Stats Components")
                .font(Theme.Typography.title2)

            // Task stats bar
            TaskStatsBar(
                completed: 7,
                total: 10,
                streak: 5,
                points: 420
            )

            // Circular progress stats
            HStack(spacing: Theme.Spacing.xl) {
                CircularProgressStat(
                    value: 7,
                    total: 10,
                    label: "Tasks",
                    color: Theme.Colors.success
                )

                CircularProgressStat(
                    value: 3,
                    total: 5,
                    label: "Goals",
                    color: Theme.Colors.accent
                )

                CircularProgressStat(
                    value: 85,
                    total: 100,
                    label: "Focus",
                    color: Theme.Colors.aiPurple
                )
            }

            // Weekly progress
            WeeklyProgressBar(days: [
                DayProgress(label: "M", progress: 1.0),
                DayProgress(label: "T", progress: 0.8),
                DayProgress(label: "W", progress: 0.6),
                DayProgress(label: "T", progress: 1.0, isToday: true),
                DayProgress(label: "F", progress: 0),
                DayProgress(label: "S", progress: 0),
                DayProgress(label: "S", progress: 0)
            ])

            // Compact stats
            CompactStatsRow(items: [
                ("done", "7", Theme.Colors.success),
                ("streak", "5d", Theme.Colors.streakOrange),
                ("pts", "420", Theme.Colors.xp)
            ])
        }
        .padding()
    }
}
