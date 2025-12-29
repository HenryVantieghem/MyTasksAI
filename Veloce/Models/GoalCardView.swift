//
//  GoalCardView.swift
//  MyTasksAI
//
//  Beautiful Liquid Glass goal cards inspired by Interactive Snippets
//

import SwiftUI
import WidgetKit
import AppIntents

struct GoalCardView: View {
    let goal: Goal
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack {
                Image(systemName: goal.themeIcon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .widgetAccentable()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .widgetAccentable()
                    
                    if let description = goal.displayDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            
            // Progress section
            VStack(alignment: .leading, spacing: 8) {
                // Main progress bar with glass effect
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth, height: 8)
                        .widgetAccentable()
                }
                
                // Stats row
                HStack(spacing: 16) {
                    Label("\(goal.formattedProgress)", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    if goal.milestoneCount > 0 {
                        Label(goal.milestoneProgressString, systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                            .widgetAccentable()
                    }
                    
                    Spacer()
                    
                    if let days = goal.daysRemaining {
                        Text("\(days) days")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                            .widgetAccentable()
                    }
                }
            }
            
            // Action buttons row (like the snippet buttons)
            HStack(spacing: 8) {
                Button(intent: CheckInGoalIntent(goalId: goal.id)) {
                    Label("Check-In", systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.glass)
                .widgetAccentable()
                
                Button(intent: ViewGoalIntent(goalId: goal.id)) {
                    Text("Open")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.glass)
                .widgetAccentable()
            }
        }
        .padding(16)
        .background {
            // The magic gradient that makes it pop!
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: goal.themeColor.opacity(0.4), radius: 12, y: 6)
        }
        .glassEffect(.regular.tint(goal.themeColor).interactive(), in: .rect(cornerRadius: 20))
    }
    
    // MARK: - Computed Properties
    
    private var progressWidth: CGFloat {
        // Assuming a card width of ~300, adjust as needed
        return 260 * goal.progress
    }
    
    private var gradientColors: [Color] {
        let baseColor = goal.themeColor
        return [
            baseColor.opacity(0.8),
            baseColor.opacity(0.6),
            baseColor.opacity(0.5)
        ]
    }
}

// MARK: - Compact Card Style (for widgets)

struct GoalCardCompactView: View {
    let goal: Goal
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: goal.themeIcon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .widgetAccentable()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .widgetAccentable()
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Progress indicator
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.2))
                            .frame(width: 80, height: 4)
                        
                        Capsule()
                            .fill(.white)
                            .frame(width: 80 * goal.progress, height: 4)
                            .widgetAccentable()
                    }
                    
                    Text(goal.formattedProgress)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            goal.themeColor.opacity(0.8),
                            goal.themeColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .glassEffect(.regular.tint(goal.themeColor), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Hero Card Style (for featured goals)

struct GoalCardHeroView: View {
    let goal: Goal
    @Namespace private var glassNamespace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top section with icon and title
            HStack(alignment: .top, spacing: 12) {
                // Large icon with glass effect
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: goal.themeIcon)
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                .glassEffectID("icon", in: glassNamespace)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    
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
            
            // Progress section with numbers
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(goal.progress * 100))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("%")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                }
                
                // Progress bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressBarWidth, height: 12)
                }
                .glassEffect(.regular, in: .capsule)
                .glassEffectID("progress", in: glassNamespace)
            }
            
            // Stats grid
            HStack(spacing: 12) {
                if goal.milestoneCount > 0 {
                    StatBadge(
                        icon: "flag.fill",
                        value: "\(goal.completedMilestoneCount)/\(goal.milestoneCount)",
                        label: "Milestones"
                    )
                }
                
                if let days = goal.daysRemaining {
                    StatBadge(
                        icon: "calendar",
                        value: "\(days)",
                        label: "Days Left"
                    )
                }
                
                if goal.checkInStreak > 0 {
                    StatBadge(
                        icon: "flame.fill",
                        value: "\(goal.checkInStreak)",
                        label: "Streak"
                    )
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            goal.themeColor,
                            goal.themeColor.opacity(0.8),
                            goal.themeColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: goal.themeColor.opacity(0.5), radius: 20, y: 10)
        }
        .glassEffect(.regular.tint(goal.themeColor).interactive(), in: .rect(cornerRadius: 24))
    }
    
    private var progressBarWidth: CGFloat {
        // Assuming card width of ~350
        return 310 * goal.progress
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview("Standard Card") {
    GoalCardView(
        goal: Goal(
            title: "Launch My Startup",
            goalDescription: "Build and launch my first software product",
            targetDate: Date().addingTimeInterval(60 * 60 * 24 * 90),
            category: GoalCategory.career.rawValue,
            timeframe: GoalTimeframe.horizon.rawValue,
            progress: 0.67,
            checkInStreak: 12,
            milestoneCount: 8,
            completedMilestoneCount: 5
        )
    )
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("Compact Card") {
    GoalCardCompactView(
        goal: Goal(
            title: "Complete iOS Course",
            category: GoalCategory.education.rawValue,
            progress: 0.45
        )
    )
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("Hero Card") {
    ScrollView {
        GoalCardHeroView(
            goal: Goal(
                title: "Get Fit for Summer",
                goalDescription: "Transform my health and fitness by building consistent workout habits",
                targetDate: Date().addingTimeInterval(60 * 60 * 24 * 120),
                category: GoalCategory.health.rawValue,
                timeframe: GoalTimeframe.horizon.rawValue,
                progress: 0.34,
                checkInStreak: 7,
                milestoneCount: 10,
                completedMilestoneCount: 3
            )
        )
        .padding()
    }
    .background(Color.gray.opacity(0.2))
}
