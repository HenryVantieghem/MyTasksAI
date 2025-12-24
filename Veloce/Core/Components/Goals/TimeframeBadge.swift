//
//  TimeframeBadge.swift
//  MyTasksAI
//
//  Timeframe Badge Component
//  Displays Sprint/Milestone/Horizon with icon and color
//

import SwiftUI

// MARK: - Timeframe Badge
struct TimeframeBadge: View {
    let timeframe: GoalTimeframe
    var size: BadgeSize = .regular
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: size.spacing) {
            Image(systemName: timeframe.icon)
                .font(.system(size: size.iconSize, weight: .semibold))

            if showLabel {
                Text(timeframe.displayName)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
        }
        .foregroundStyle(timeframe.color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(timeframe.color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(timeframe.color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Badge Size
extension TimeframeBadge {
    enum BadgeSize {
        case compact
        case regular
        case large

        var iconSize: CGFloat {
            switch self {
            case .compact: return 10
            case .regular: return 12
            case .large: return 14
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .compact: return 10
            case .regular: return 12
            case .large: return 14
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return 6
            case .regular: return 10
            case .large: return 14
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact: return 3
            case .regular: return 5
            case .large: return 7
            }
        }

        var spacing: CGFloat {
            switch self {
            case .compact: return 3
            case .regular: return 4
            case .large: return 6
            }
        }
    }
}

// MARK: - Days Remaining Pill
struct DaysRemainingPill: View {
    let days: Int
    var isOverdue: Bool = false

    private var displayText: String {
        if days < 0 {
            return "\(abs(days))d overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "1 day left"
        } else {
            return "\(days) days left"
        }
    }

    private var pillColor: Color {
        if days < 0 || isOverdue {
            return Theme.Colors.error
        } else if days <= 3 {
            return Theme.Colors.warning
        } else if days <= 7 {
            return Theme.Colors.aiCyan
        }
        return Theme.Colors.textTertiary
    }

    var body: some View {
        HStack(spacing: 4) {
            if days < 0 || isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
            } else if days <= 3 {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
            }

            Text(displayText)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(pillColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(pillColor.opacity(0.12))
        )
    }
}

// MARK: - Milestone Progress Bar
struct MilestoneProgressBar: View {
    let completed: Int
    let total: Int
    var accentColor: Color = Theme.Colors.aiPurple

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Milestones")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer()

                Text("\(completed)/\(total)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(progress >= 1.0 ? Theme.Colors.success : Theme.Colors.textSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geometry.size.width * progress), height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)

                    // Milestone dots
                    if total > 0 && total <= 10 {
                        ForEach(0..<total, id: \.self) { index in
                            let position = Double(index + 1) / Double(total)
                            SwiftUI.Circle()
                                .fill(index < completed ? accentColor : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .overlay(
                                    SwiftUI.Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                                .position(
                                    x: geometry.size.width * position,
                                    y: 3
                                )
                        }
                    }
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Linked Tasks Summary
struct LinkedTasksSummary: View {
    let count: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("\(count) linked tasks")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()

            Text("\(Int(progress * 100))% done")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(progress >= 1.0 ? Theme.Colors.success : Theme.Colors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Previews
#Preview("Timeframe Badges") {
    VStack(spacing: 16) {
        ForEach(GoalTimeframe.allCases, id: \.rawValue) { timeframe in
            HStack(spacing: 12) {
                TimeframeBadge(timeframe: timeframe, size: .compact)
                TimeframeBadge(timeframe: timeframe, size: .regular)
                TimeframeBadge(timeframe: timeframe, size: .large)
            }
        }
    }
    .padding()
    .background(Theme.CelestialColors.void)
}

#Preview("Days Remaining") {
    VStack(spacing: 12) {
        DaysRemainingPill(days: -3)
        DaysRemainingPill(days: 0)
        DaysRemainingPill(days: 1)
        DaysRemainingPill(days: 3)
        DaysRemainingPill(days: 14)
    }
    .padding()
    .background(Theme.CelestialColors.void)
}

#Preview("Milestone Progress") {
    VStack(spacing: 20) {
        MilestoneProgressBar(completed: 0, total: 5)
        MilestoneProgressBar(completed: 2, total: 5)
        MilestoneProgressBar(completed: 5, total: 5)
    }
    .padding()
    .background(Theme.CelestialColors.void)
}
