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

    // Environment
    @Environment(AppViewModel.self) private var appViewModel

    // Data sources
    private let gamification = GamificationService.shared
    @StateObject private var profileImageService = ProfileImageService.shared

    // Avatar state
    @State private var headerAvatarImage: UIImage?

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

    // User initial for fallback
    private var userInitial: String {
        if let name = appViewModel.currentUser?.fullName, !name.isEmpty {
            return String(name.prefix(1)).uppercased()
        }
        return "V"
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

                // Right: Profile Button with avatar
                ProfileButton(
                    onTap: {
                        showProfile = true
                    },
                    avatarImage: headerAvatarImage,
                    userInitial: userInitial
                )
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
        .onAppear {
            loadHeaderAvatar()
        }
        .onChange(of: profileImageService.lastAvatarUpdate) { _, _ in
            // Avatar was updated in profile sheet, refresh header avatar
            loadHeaderAvatar()
        }
    }

    // MARK: - Avatar Loading

    private func loadHeaderAvatar() {
        Task {
            if let userId = appViewModel.currentUser?.id.uuidString {
                headerAvatarImage = await profileImageService.fetchAvatar(for: userId)
            }
        }
    }
}

// MARK: - Profile Button

struct ProfileButton: View {
    let onTap: () -> Void
    var avatarImage: UIImage? = nil
    var userInitial: String = "V"

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Group {
                if let image = avatarImage {
                    // Show actual avatar image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    // Show gradient with user initial
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
                            Text(userInitial)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
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
                .environment(AppViewModel())
            Spacer()
        }
    }
}
