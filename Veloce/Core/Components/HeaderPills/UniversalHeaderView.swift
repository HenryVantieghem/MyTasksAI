//
//  UniversalHeaderView.swift
//  Veloce
//
//  Universal Header View
//  Persistent header across all tabs with stats and settings pills
//

import SwiftUI

// MARK: - Universal Header View

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
        HStack(spacing: Theme.Spacing.sm) {
            // Stats pill (left) - transparent, inherits glass from parent
            GamificationPill(
                streak: gamification.currentStreak,
                points: gamification.totalPoints,
                level: gamification.currentLevel,
                transparent: true
            ) {
                showStatsSheet = true
            }

            // Title (center) - part of unified pill
            Text(title)
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            // Settings pill (right) - transparent, inherits glass from parent
            SettingsPillView(
                avatarUrl: avatarUrl,
                userName: userName,
                transparent: true
            ) {
                HapticsService.shared.selectionFeedback()
                showSettingsSheet = true
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .liquidGlass(cornerRadius: Theme.Radius.pill)  // Single unified glass container
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

struct CompactHeaderView: View {
    let title: String
    @Binding var showStatsSheet: Bool
    @Binding var showSettingsSheet: Bool

    private let gamification = GamificationService.shared

    var userName: String? = nil
    var avatarUrl: String? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Stats pill
            GamificationPill(
                streak: gamification.currentStreak,
                points: gamification.totalPoints,
                level: gamification.currentLevel
            ) {
                showStatsSheet = true
            }

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

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        UniversalHeaderView(
            title: "Tasks",
            showStatsSheet: .constant(false),
            showSettingsSheet: .constant(false),
            userName: "John"
        )

        Spacer()
    }
    .background(AppColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
