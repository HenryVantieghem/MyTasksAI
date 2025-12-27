//
//  EmptyStateView.swift
//  Veloce
//
//  Reusable empty state component with consistent styling
//  Matches Living Cosmos aesthetic with subtle animations
//

import SwiftUI

// MARK: - Empty State Configuration

struct EmptyStateConfig {
    let icon: String
    let headline: String
    let subtext: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        headline: String,
        subtext: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.headline = headline
        self.subtext = subtext
        self.actionTitle = actionTitle
        self.action = action
    }
}

// MARK: - Preset Configurations

extension EmptyStateConfig {
    /// Calendar day with no tasks
    static func calendarDay(addAction: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "calendar.badge.plus",
            headline: "Nothing scheduled",
            subtext: "Tap + to add a task for this day",
            actionTitle: "Add Task",
            action: addAction
        )
    }

    /// Goals list empty
    static func goals(createAction: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "target",
            headline: "Set your first goal",
            subtext: "Goals help you stay focused on what matters",
            actionTitle: "Create Goal",
            action: createAction
        )
    }

    /// Circles list empty
    static func circles(createAction: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "person.2.circle",
            headline: "Better together",
            subtext: "Create a circle or join one with friends",
            actionTitle: "Create Circle",
            action: createAction
        )
    }

    /// Focus session history empty
    static func focusHistory(startAction: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "timer",
            headline: "No focus sessions yet",
            subtext: "Start a session to see your stats",
            actionTitle: "Start Focus",
            action: startAction
        )
    }

    /// Journal entries empty (shouldn't happen often)
    static var journal: EmptyStateConfig {
        EmptyStateConfig(
            icon: "book.closed",
            headline: "Your journal awaits",
            subtext: "Start writing above"
        )
    }

    /// Search with no results
    static var searchNoResults: EmptyStateConfig {
        EmptyStateConfig(
            icon: "magnifyingglass",
            headline: "No results",
            subtext: "Try a different search term"
        )
    }

    /// Generic empty list
    static var emptyList: EmptyStateConfig {
        EmptyStateConfig(
            icon: "tray",
            headline: "Nothing here yet",
            subtext: "Items will appear here when added"
        )
    }

    /// Offline state
    static var offline: EmptyStateConfig {
        EmptyStateConfig(
            icon: "wifi.slash",
            headline: "You're offline",
            subtext: "Connect to the internet to sync"
        )
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let config: EmptyStateConfig

    @State private var showContent = false
    @State private var iconPulse = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Icon with gentle pulse
            iconView

            // Text stack
            textStack

            // Optional action button
            if let actionTitle = config.actionTitle, let action = config.action {
                actionButton(title: actionTitle, action: action)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            startPulseAnimation()
        }
    }

    // MARK: - Subviews

    private var iconView: some View {
        Image(systemName: config.icon)
            .font(.system(size: 56, weight: .ultraLight))
            .foregroundStyle(Theme.Colors.textTertiary.opacity(0.6))
            .scaleEffect(iconPulse ? 1.04 : 1.0)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
    }

    private var textStack: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(config.headline)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(config.subtext)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
    }

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticsService.shared.buttonTap()
            action()
        }) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Veloce.Colors.accentPrimary, Veloce.Colors.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Veloce.Colors.accentPrimary.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 8)
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Animations

    private func startPulseAnimation() {
        guard !reduceMotion else { return }

        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
            .delay(1.5)
        ) {
            iconPulse = true
        }
    }
}

// MARK: - Preview

#Preview("Empty State - Calendar") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        EmptyStateView(config: .calendarDay(addAction: {}))
    }
}

#Preview("Empty State - Goals") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        EmptyStateView(config: .goals(createAction: {}))
    }
}

#Preview("Empty State - Circles") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        EmptyStateView(config: .circles(createAction: {}))
    }
}

#Preview("Empty State - Focus") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        EmptyStateView(config: .focusHistory(startAction: {}))
    }
}

#Preview("Empty State - Search") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        EmptyStateView(config: .searchNoResults)
    }
}
