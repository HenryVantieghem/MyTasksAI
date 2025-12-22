//
//  VeloceMotivationWidget.swift
//  VeloceWidgets
//
//  Motivation Widget - Aurora Design System
//  Ethereal cosmic quotes with crystalline glass styling
//  Beautiful inspiration with twinkling starfield
//

import WidgetKit
import SwiftUI

// MARK: - Motivation Widget

struct VeloceMotivationWidget: Widget {
    let kind: String = "VeloceMotivationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MotivationTimelineProvider()) { entry in
            MotivationWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCosmicBackground(showStars: true, showAurora: true, auroraIntensity: 0.35, starCount: 20)
                }
        }
        .configurationDisplayName("Daily Motivation")
        .description("Start your day with inspiration")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct MotivationTimelineProvider: TimelineProvider {
    private let quotes: [MotivationQuote] = [
        MotivationQuote(
            text: "The secret of getting ahead is getting started.",
            author: "Mark Twain",
            icon: "rocket.fill"
        ),
        MotivationQuote(
            text: "Small steps lead to giant leaps.",
            author: "MyTasksAI",
            icon: "figure.walk"
        ),
        MotivationQuote(
            text: "Focus on progress, not perfection.",
            author: "Unknown",
            icon: "chart.line.uptrend.xyaxis"
        ),
        MotivationQuote(
            text: "Your future is created by what you do today.",
            author: "Robert Kiyosaki",
            icon: "calendar.badge.clock"
        ),
        MotivationQuote(
            text: "Done is better than perfect.",
            author: "Sheryl Sandberg",
            icon: "checkmark.circle.fill"
        ),
        MotivationQuote(
            text: "Break it down. Build it up. Get it done.",
            author: "MyTasksAI",
            icon: "square.stack.3d.up.fill"
        ),
        MotivationQuote(
            text: "Productivity is never an accident.",
            author: "Paul J. Meyer",
            icon: "bolt.fill"
        ),
        MotivationQuote(
            text: "Start where you are. Use what you have.",
            author: "Arthur Ashe",
            icon: "star.fill"
        )
    ]

    func placeholder(in context: Context) -> MotivationEntry {
        MotivationEntry(
            date: Date(),
            quote: quotes[0],
            tasksCompleted: 5,
            greeting: "Good morning"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MotivationEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MotivationEntry>) -> Void) {
        var entries: [MotivationEntry] = []
        let now = Date()

        // Create entries for next 8 hours (new quote every hour)
        for hour in 0..<8 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hour, to: now)!
            let quoteIndex = (Calendar.current.component(.hour, from: entryDate) + Calendar.current.component(.day, from: entryDate)) % quotes.count

            let stats = loadStats()
            let entry = MotivationEntry(
                date: entryDate,
                quote: quotes[quoteIndex],
                tasksCompleted: stats?.tasksCompletedToday ?? 0,
                greeting: greetingForTime(entryDate)
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
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

    private func greetingForTime(_ date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }
}

// MARK: - Quote Model

struct MotivationQuote: Codable {
    let text: String
    let author: String
    let icon: String
}

// MARK: - Entry

struct MotivationEntry: TimelineEntry {
    let date: Date
    let quote: MotivationQuote
    let tasksCompleted: Int
    let greeting: String
}

// MARK: - Widget View

struct MotivationWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MotivationEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        case .accessoryRectangular:
            rectangularAccessory
        default:
            mediumWidget
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with aurora glow
            HStack {
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    WidgetAurora.Colors.violet.opacity(0.4),
                                    WidgetAurora.Colors.electric.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 48, height: 48)
                        .blur(radius: 4)

                    // Icon container
                    Circle()
                        .fill(WidgetAurora.Colors.glassBase)
                        .overlay(
                            Circle()
                                .stroke(WidgetAurora.Colors.glassBorder, lineWidth: 0.5)
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: entry.quote.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [WidgetAurora.Colors.violet, WidgetAurora.Colors.electric],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Spacer()

                // Tasks completed badge
                if entry.tasksCompleted > 0 {
                    WidgetStatPill(
                        icon: "checkmark.circle.fill",
                        value: "\(entry.tasksCompleted) done",
                        color: WidgetAurora.Colors.success
                    )
                }
            }

            Spacer()

            // Quote with editorial styling
            VStack(alignment: .leading, spacing: 6) {
                Text("\"\(entry.quote.text)\"")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(WidgetAurora.Colors.textPrimary)
                    .lineLimit(3)
                    .lineSpacing(2)

                Text("— \(entry.quote.author)")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)
            }
        }
        .padding(16)
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with aurora orb
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.greeting)
                        .font(WidgetAurora.Typography.caption)
                        .foregroundStyle(WidgetAurora.Colors.textTertiary)

                    Text("Stay Focused")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(WidgetAurora.Colors.textPrimary)
                }

                Spacer()

                // Mini aurora orb
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    WidgetAurora.Colors.violet.opacity(0.4),
                                    WidgetAurora.Colors.electric.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                        .blur(radius: 6)

                    // Orb body
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    WidgetAurora.Colors.violet,
                                    WidgetAurora.Colors.purple,
                                    WidgetAurora.Colors.electric
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: WidgetAurora.Colors.violet.opacity(0.5), radius: 8)

                    // Sparkle icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }
            }

            // Divider with aurora gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            WidgetAurora.Colors.violet.opacity(0.4),
                            WidgetAurora.Colors.electric.opacity(0.2),
                            WidgetAurora.Colors.glassBorder.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Spacer()

            // Quote section with glass styling
            VStack(alignment: .leading, spacing: 10) {
                // Opening quote mark
                Image(systemName: "quote.opening")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(WidgetAurora.Colors.violet)

                // Quote text
                Text(entry.quote.text)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(WidgetAurora.Colors.textPrimary)
                    .lineSpacing(4)

                // Author and icon
                HStack {
                    Text("— \(entry.quote.author)")
                        .font(WidgetAurora.Typography.subheadline)
                        .foregroundStyle(WidgetAurora.Colors.textTertiary)

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(WidgetAurora.Colors.glassBase)
                            .overlay(
                                Circle()
                                    .stroke(WidgetAurora.Colors.glassBorder, lineWidth: 0.5)
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: entry.quote.icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(WidgetAurora.Colors.violet)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: WidgetAurora.Layout.cornerRadius)
                    .fill(WidgetAurora.Colors.glassBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: WidgetAurora.Layout.cornerRadius)
                            .stroke(WidgetAurora.Gradients.glassBorder, lineWidth: 0.5)
                    )
            )

            Spacer()

            // Quick stats with aurora styling
            HStack(spacing: 16) {
                WidgetStatPill(
                    icon: "checkmark.circle.fill",
                    value: "\(entry.tasksCompleted)",
                    color: WidgetAurora.Colors.success
                )

                WidgetStatPill(
                    icon: "flame.fill",
                    value: "7",
                    color: WidgetAurora.Colors.flameInner
                )

                WidgetStatPill(
                    icon: "star.fill",
                    value: "Lv 12",
                    color: WidgetAurora.Colors.gold
                )

                Spacer()
            }
        }
        .padding(16)
    }

    // MARK: - Rectangular Accessory

    private var rectangularAccessory: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 8))
                Text("Daily Motivation")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.secondary)

            Text(entry.quote.text)
                .font(.system(size: 12))
                .lineLimit(2)
        }
    }
}

// MARK: - Preview

#Preview("Medium", as: .systemMedium) {
    VeloceMotivationWidget()
} timeline: {
    MotivationEntry(
        date: Date(),
        quote: MotivationQuote(text: "The secret of getting ahead is getting started.", author: "Mark Twain", icon: "rocket.fill"),
        tasksCompleted: 5,
        greeting: "Good morning"
    )
}

#Preview("Large", as: .systemLarge) {
    VeloceMotivationWidget()
} timeline: {
    MotivationEntry(
        date: Date(),
        quote: MotivationQuote(text: "Small steps lead to giant leaps.", author: "MyTasksAI", icon: "figure.walk"),
        tasksCompleted: 3,
        greeting: "Good afternoon"
    )
}

#Preview("Rectangular", as: .accessoryRectangular) {
    VeloceMotivationWidget()
} timeline: {
    MotivationEntry(
        date: Date(),
        quote: MotivationQuote(text: "Focus on progress, not perfection.", author: "Unknown", icon: "chart.line.uptrend.xyaxis"),
        tasksCompleted: 2,
        greeting: "Good evening"
    )
}
