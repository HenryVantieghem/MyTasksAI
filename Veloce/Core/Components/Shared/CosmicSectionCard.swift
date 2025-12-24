//
//  CosmicSectionCard.swift
//  Veloce
//
//  Living Cosmos Section Card Component
//  Reusable container for grouped settings/content with celestial styling
//

import SwiftUI

// MARK: - Cosmic Section Card

struct CosmicSectionCard<Content: View>: View {
    let header: String?
    let headerIcon: String?
    let headerIconColor: Color
    let accentColor: Color?
    let isFloating: Bool
    let content: Content

    init(
        header: String? = nil,
        headerIcon: String? = nil,
        headerIconColor: Color = Theme.CelestialColors.starDim,
        accentColor: Color? = nil,
        isFloating: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.headerIcon = headerIcon
        self.headerIconColor = headerIconColor
        self.accentColor = accentColor
        self.isFloating = isFloating
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            if let header {
                CosmicSectionHeader(header, icon: headerIcon, iconColor: headerIconColor)
            }

            // Content card
            if isFloating {
                content
                    .floatingIsland(accentColor: accentColor ?? Theme.Colors.aiPurple)
            } else {
                content
                    .celestialGlass(accentColor: accentColor)
            }
        }
    }
}

// MARK: - Cosmic Info Card

struct CosmicInfoCard: View {
    let icon: String
    let iconColor: Color
    let message: String
    let style: InfoStyle

    enum InfoStyle {
        case info
        case success
        case warning
        case tip
    }

    init(
        icon: String? = nil,
        message: String,
        style: InfoStyle = .info
    ) {
        self.message = message
        self.style = style

        switch style {
        case .info:
            self.icon = icon ?? "info.circle.fill"
            self.iconColor = Theme.Colors.aiBlue
        case .success:
            self.icon = icon ?? "checkmark.circle.fill"
            self.iconColor = Theme.CelestialColors.auroraGreen
        case .warning:
            self.icon = icon ?? "exclamationmark.triangle.fill"
            self.iconColor = Theme.CelestialColors.warningNebula
        case .tip:
            self.icon = icon ?? "lightbulb.fill"
            self.iconColor = Theme.Colors.xp
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(iconColor.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(iconColor.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

// MARK: - Cosmic Stat Card

struct CosmicStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let trend: Trend?

    enum Trend {
        case up
        case down
        case neutral
    }

    init(
        icon: String,
        iconColor: Color,
        value: String,
        label: String,
        trend: Trend? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.value = value
        self.label = label
        self.trend = trend
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Icon
            ZStack {
                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .blur(radius: 8)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            // Value with trend
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if let trend {
                    trendIndicator(trend)
                }
            }

            // Label
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .celestialGlass(accentColor: iconColor, padding: Theme.Spacing.md)
    }

    @ViewBuilder
    private func trendIndicator(_ trend: Trend) -> some View {
        switch trend {
        case .up:
            Image(systemName: "arrow.up")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.CelestialColors.auroraGreen)
        case .down:
            Image(systemName: "arrow.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.CelestialColors.errorNebula)
        case .neutral:
            Image(systemName: "minus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
    }
}

// MARK: - Cosmic Empty State

struct CosmicEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.1))
                    .frame(width: 80, height: 80)

                SwiftUI.Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .blur(radius: 12)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }

            // Text
            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
            }

            // Action button
            if let actionTitle, let action {
                CosmicButton(actionTitle, style: .primary, icon: "plus") {
                    action()
                }
                .frame(width: 200)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Preview

#Preview("Cosmic Section Cards") {
    ZStack {
        VoidBackground.settings

        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                CosmicSectionCard(header: "Preferences", headerIcon: "gearshape.fill") {
                    VStack(spacing: 0) {
                        CosmicToggleRow(
                            icon: "bell.fill",
                            iconColor: Theme.Colors.accent,
                            title: "Notifications",
                            isOn: .constant(true)
                        )
                        CosmicDivider()
                        CosmicToggleRow(
                            icon: "hand.tap.fill",
                            iconColor: Theme.Colors.aiPurple,
                            title: "Haptics",
                            isOn: .constant(false)
                        )
                    }
                }

                CosmicInfoCard(message: "Your data stays private and secure", style: .tip)

                HStack(spacing: Theme.Spacing.md) {
                    CosmicStatCard(
                        icon: "checkmark.circle.fill",
                        iconColor: Theme.CelestialColors.auroraGreen,
                        value: "12",
                        label: "Completed",
                        trend: .up
                    )

                    CosmicStatCard(
                        icon: "flame.fill",
                        iconColor: Theme.Colors.xp,
                        value: "7",
                        label: "Day Streak"
                    )
                }

                CosmicEmptyState(
                    icon: "tray",
                    title: "No Tasks Yet",
                    message: "Add your first task to get started",
                    actionTitle: "Add Task"
                ) {}
            }
            .padding()
        }
    }
}
