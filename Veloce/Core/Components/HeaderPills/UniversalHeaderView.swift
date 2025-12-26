//
//  UniversalHeaderView.swift
//  Veloce
//
//  Universal Header View
//  Persistent header across ALL tabs with total points and settings pills
//

import SwiftUI

// MARK: - Universal Header View

/// Universal header displayed on ALL 5 main tabs
/// Shows total points (left), title (center), settings (right)
struct UniversalHeaderView: View {
    let title: String
    @Binding var showStatsSheet: Bool
    @Binding var showSettingsSheet: Bool

    // Access gamification data
    private let gamification = GamificationService.shared

    // Optional user info
    var userName: String? = nil
    var avatarUrl: String? = nil

    @State private var showContent = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Points pill (left) - Shows total XP with gold star
            TotalPointsPill(points: gamification.totalPoints) {
                showStatsSheet = true
            }

            Spacer()

            // Title (center) - Editorial thin typography
            Text(title)
                .font(Theme.Typography.displaySmall)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            // Settings pill (right) - User avatar/settings
            SettingsPillView(
                avatarUrl: avatarUrl,
                userName: userName,
                transparent: false
            ) {
                HapticsService.shared.selectionFeedback()
                showSettingsSheet = true
            }
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.95)
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Compact Header Variant

/// Compact header for scrolled states or tight spaces
struct CompactHeaderView: View {
    let title: String
    @Binding var showStatsSheet: Bool
    @Binding var showSettingsSheet: Bool

    private let gamification = GamificationService.shared

    var userName: String? = nil
    var avatarUrl: String? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Compact points pill
            CompactPointsPill(points: gamification.totalPoints) {
                showStatsSheet = true
            }

            Spacer()

            // Title - smaller for compact
            Text(title)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // Settings pill
            SettingsPillView(
                avatarUrl: avatarUrl,
                userName: userName
            ) {
                HapticsService.shared.selectionFeedback()
                showSettingsSheet = true
            }
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Header with Streak Badge

/// Alternative header showing streak alongside points
struct HeaderWithStreak: View {
    let title: String
    @Binding var showStatsSheet: Bool
    @Binding var showSettingsSheet: Bool

    private let gamification = GamificationService.shared

    var userName: String? = nil
    var avatarUrl: String? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Points pill
            TotalPointsPill(points: gamification.totalPoints) {
                showStatsSheet = true
            }

            // Streak badge (only if active)
            if gamification.currentStreak > 0 {
                StreakIndicator(days: gamification.currentStreak)
            }

            Spacer()

            // Title
            Text(title)
                .font(Theme.Typography.displaySmall)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            // Settings pill
            SettingsPillView(
                avatarUrl: avatarUrl,
                userName: userName,
                transparent: false
            ) {
                HapticsService.shared.selectionFeedback()
                showSettingsSheet = true
            }
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
    }
}

// MARK: - Streak Indicator

/// Small streak badge to show alongside points
struct StreakIndicator: View {
    let days: Int

    @State private var isFlaming = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isFlaming ? 1.1 : 1.0)

            Text("\(days)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: Capsule())
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                isFlaming = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Universal Header") {
    VStack(spacing: 0) {
        UniversalHeaderView(
            title: "Tasks",
            showStatsSheet: .constant(false),
            showSettingsSheet: .constant(false),
            userName: "John"
        )
        .padding(.top, 60)

        Spacer()
    }
    .background(Theme.CelestialColors.void)
    .preferredColorScheme(.dark)
}

#Preview("Compact Header") {
    VStack(spacing: 0) {
        CompactHeaderView(
            title: "Calendar",
            showStatsSheet: .constant(false),
            showSettingsSheet: .constant(false)
        )
        .padding(.top, 60)

        Spacer()
    }
    .background(Theme.CelestialColors.void)
    .preferredColorScheme(.dark)
}

#Preview("Header with Streak") {
    VStack(spacing: 0) {
        HeaderWithStreak(
            title: "Momentum",
            showStatsSheet: .constant(false),
            showSettingsSheet: .constant(false)
        )
        .padding(.top, 60)

        Spacer()
    }
    .background(Theme.CelestialColors.void)
    .preferredColorScheme(.dark)
}

#Preview("All Header Variants") {
    VStack(spacing: 40) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Universal Header")
                .font(.caption)
                .foregroundStyle(.secondary)
            UniversalHeaderView(
                title: "Tasks",
                showStatsSheet: .constant(false),
                showSettingsSheet: .constant(false)
            )
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Compact Header")
                .font(.caption)
                .foregroundStyle(.secondary)
            CompactHeaderView(
                title: "Calendar",
                showStatsSheet: .constant(false),
                showSettingsSheet: .constant(false)
            )
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Header with Streak")
                .font(.caption)
                .foregroundStyle(.secondary)
            HeaderWithStreak(
                title: "Momentum",
                showStatsSheet: .constant(false),
                showSettingsSheet: .constant(false)
            )
        }

        Spacer()
    }
    .padding(.top, 60)
    .background(Theme.CelestialColors.void)
    .preferredColorScheme(.dark)
}
