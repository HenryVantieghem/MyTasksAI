//
//  GoalWidget.swift
//  MyTasksAI
//
//  Widgets with Liquid Glass (like Interactive Snippets)
//

import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry

struct GoalEntry: TimelineEntry {
    let date: Date
    let goal: Goal
}

// MARK: - Widget Provider

struct GoalProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(
            date: Date(),
            goal: placeholderGoal
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        let entry = GoalEntry(
            date: Date(),
            goal: placeholderGoal
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        // Fetch user's current goal
        // For now, using placeholder
        let entry = GoalEntry(
            date: Date(),
            goal: placeholderGoal
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private var placeholderGoal: Goal {
        Goal(
            title: "Launch Startup",
            goalDescription: "Build and launch my first product",
            targetDate: Date().addingTimeInterval(60 * 60 * 24 * 90),
            category: GoalCategory.career.rawValue,
            timeframe: GoalTimeframe.horizon.rawValue,
            progress: 0.67,
            checkInStreak: 12,
            milestoneCount: 8,
            completedMilestoneCount: 5
        )
    }
}

// MARK: - Widget Entry View

struct GoalWidgetEntryView: View {
    var entry: GoalEntry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallGoalWidget(goal: entry.goal)
        case .systemMedium:
            MediumGoalWidget(goal: entry.goal)
        case .systemLarge:
            LargeGoalWidget(goal: entry.goal)
        case .accessoryCircular:
            CircularGoalWidget(goal: entry.goal)
        case .accessoryRectangular:
            RectangularGoalWidget(goal: entry.goal)
        default:
            MediumGoalWidget(goal: entry.goal)
        }
    }
}

// MARK: - Small Widget (System Small)

struct SmallGoalWidget: View {
    let goal: Goal
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            Image(systemName: goal.themeIcon)
                .font(.title)
                .foregroundStyle(.white)
                .widgetAccentable()
            
            Spacer()
            
            // Title
            Text(goal.displayTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .widgetAccentable()
                .lineLimit(2)
            
            // Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(goal.progress * 100))%")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .widgetAccentable()
                
                // Mini progress bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(.white)
                        .frame(width: progressWidth, height: 4)
                        .widgetAccentable()
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            gradientBackground
        }
    }
    
    private var progressWidth: CGFloat {
        130 * goal.progress // Approximate width
    }
    
    private var gradientBackground: some View {
        LinearGradient(
            colors: [
                goal.themeColor,
                goal.themeColor.opacity(0.8),
                goal.themeColor.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Medium Widget (System Medium)

struct MediumGoalWidget: View {
    let goal: Goal
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Progress Ring
            AnimatedProgressRing(
                progress: goal.progress,
                color: .white,
                lineWidth: 8
            )
            .frame(width: 80, height: 80)
            .widgetAccentable()
            
            // Right: Details
            VStack(alignment: .leading, spacing: 8) {
                // Icon + Title
                HStack(spacing: 8) {
                    Image(systemName: goal.themeIcon)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .widgetAccentable()
                    
                    Text(goal.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .widgetAccentable()
                        .lineLimit(1)
                }
                
                // Description
                if let description = goal.displayDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Stats
                HStack(spacing: 12) {
                    if goal.milestoneCount > 0 {
                        Label(goal.milestoneProgressString, systemImage: "flag.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                            .widgetAccentable()
                    }
                    
                    if let days = goal.daysRemaining {
                        Label("\(days)d", systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    if goal.checkInStreak > 0 {
                        Label("\(goal.checkInStreak)", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                            .widgetAccentable()
                    }
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    goal.themeColor,
                    goal.themeColor.opacity(0.8),
                    goal.themeColor.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Large Widget (System Large)

struct LargeGoalWidget: View {
    let goal: Goal
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: goal.themeIcon)
                    .font(.title)
                    .foregroundStyle(.white)
                    .widgetAccentable()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .widgetAccentable()
                    
                    if let category = goal.categoryEnum {
                        Text(category.displayName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Spacer()
            }
            
            // Description
            if let description = goal.displayDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
            }
            
            // Progress section
            VStack(alignment: .leading, spacing: 12) {
                // Big progress number
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(goal.progress * 100))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .widgetAccentable()
                    
                    Text("%")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                }
                
                // Progress bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(.white)
                        .frame(width: progressWidth, height: 12)
                        .widgetAccentable()
                }
            }
            
            Spacer()
            
            // Stats row
            HStack(spacing: 12) {
                if goal.milestoneCount > 0 {
                    MiniStatBadge(
                        icon: "flag.fill",
                        value: goal.milestoneProgressString,
                        label: "Milestones"
                    )
                }
                
                if let days = goal.daysRemaining {
                    MiniStatBadge(
                        icon: "calendar",
                        value: "\(days)",
                        label: "Days"
                    )
                }
                
                if goal.checkInStreak > 0 {
                    MiniStatBadge(
                        icon: "flame.fill",
                        value: "\(goal.checkInStreak)",
                        label: "Streak"
                    )
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    goal.themeColor,
                    goal.themeColor.opacity(0.8),
                    goal.themeColor.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var progressWidth: CGFloat {
        300 * goal.progress // Approximate
    }
}

// MARK: - Circular Widget (Apple Watch / Lock Screen)

struct CircularGoalWidget: View {
    let goal: Goal
    
    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(lineWidth: 4)
                .opacity(0.2)
            
            Circle()
                .trim(from: 0, to: goal.progress)
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Progress percentage
            Text("\(Int(goal.progress * 100))%")
                .font(.system(.caption, design: .rounded, weight: .bold))
        }
        .widgetAccentable()
    }
}

// MARK: - Rectangular Widget (Lock Screen)

struct RectangularGoalWidget: View {
    let goal: Goal
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: goal.themeIcon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption.weight(.semibold))
                    
                    if let days = goal.daysRemaining {
                        Text("· \(days)d left")
                            .font(.caption2)
                    }
                }
            }
        }
        .widgetAccentable()
    }
}

// MARK: - Supporting Views

struct MiniStatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(.white)
            .widgetAccentable()
            
            Text(label)
                .dynamicTypeFont(base: 9)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.15))
        }
    }
}

// MARK: - Widget Configuration

struct GoalWidget: Widget {
    let kind: String = "GoalWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalProvider()) { entry in
            GoalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Goal Progress")
        .description("Track your most important goal")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular
        ])
        .containerBackgroundRemovable(true) // Enable tinted mode!
    }
}

// MARK: - Widget Bundle
// NOTE: @main removed - GoalWidget should be in a separate Widget Extension target
// When you create a Widget Extension, add @main back to this bundle
struct GoalWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoalWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    GoalWidget()
} timeline: {
    GoalEntry(
        date: Date(),
        goal: Goal(
            title: "Launch Startup",
            category: GoalCategory.career.rawValue,
            timeframe: GoalTimeframe.horizon.rawValue,
            progress: 0.67
        )
    )
}

#Preview("Medium", as: .systemMedium) {
    GoalWidget()
} timeline: {
    GoalEntry(
        date: Date(),
        goal: Goal(
            title: "Get Fit for Summer",
            goalDescription: "Build consistent workout habits",
            targetDate: Date().addingTimeInterval(60 * 60 * 24 * 90),
            category: GoalCategory.health.rawValue,
            timeframe: GoalTimeframe.horizon.rawValue,
            progress: 0.45,
            checkInStreak: 7,
            milestoneCount: 10,
            completedMilestoneCount: 4
        )
    )
}

#Preview("Large", as: .systemLarge) {
    GoalWidget()
} timeline: {
    GoalEntry(
        date: Date(),
        goal: Goal(
            title: "Complete iOS Course",
            goalDescription: "Master SwiftUI and build amazing apps",
            targetDate: Date().addingTimeInterval(60 * 60 * 24 * 60),
            category: GoalCategory.education.rawValue,
            timeframe: GoalTimeframe.milestone.rawValue,
            progress: 0.78,
            checkInStreak: 15,
            milestoneCount: 12,
            completedMilestoneCount: 9
        )
    )
}
