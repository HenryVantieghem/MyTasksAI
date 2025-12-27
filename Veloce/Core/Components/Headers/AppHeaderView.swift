//
//  AppHeaderView.swift
//  Veloce
//
//  Universal header component appearing on every tab
//  Left: Velocity Score pill | Center: Tab title | Right: Profile button
//

import SwiftUI

struct AppHeaderView: View {
    let title: String
    @Binding var showProfile: Bool

    // Data sources
    private let gamification = GamificationService.shared

    // Sheet state
    @State private var showScoreDetail = false

    // Computed velocity score
    private var velocityScore: VelocityScore {
        VelocityScore(
            currentStreak: gamification.currentStreak,
            longestStreak: gamification.longestStreak,
            tasksCompletedThisWeek: gamification.weeklyActivityData.reduce(0, +),
            weeklyGoal: gamification.weeklyGoal,
            focusMinutesThisWeek: gamification.focusMinutesTotal,
            focusGoalMinutes: 5 * 60, // 5 hours default
            tasksOnTime: 0, // Would need to track from tasks
            totalTasksCompleted: gamification.tasksCompleted
        )
    }

    var body: some View {
        ZStack {
            // Center: Title
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            // Left & Right content
            HStack {
                // Left: Velocity Score Pill
                VelocityScorePill(
                    score: velocityScore.total,
                    tier: velocityScore.tier,
                    onTap: {
                        showScoreDetail = true
                    }
                )

                Spacer()

                // Right: Profile Button
                ProfileButton(onTap: {
                    showProfile = true
                })
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.black.opacity(0.4), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showScoreDetail) {
            VelocityScoreDetailSheet(score: velocityScore)
        }
    }
}

// MARK: - Profile Button

struct ProfileButton: View {
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    // User initial - would get from AppViewModel
                    Text("U")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            AppHeaderView(title: "Tasks", showProfile: .constant(false))
            Spacer()
        }
    }
}
