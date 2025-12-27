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
            // Center: Title - Ultra-thin elegant typography (MyTasksAI brand style)
            Text(title)
                .font(Theme.Typography.pageTitle)
                .foregroundStyle(.white)
                .tracking(1.5)

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
    @State private var glowPhase: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Glow opacity based on animation phase
    private var glowOpacity: Double {
        reduceMotion ? 0.35 : (glowPhase ? 0.5 : 0.25)
    }

    // Glow color (purple to match AI theme)
    private let glowColor = Theme.Colors.aiPurple

    var body: some View {
        Button(action: onTap) {
            Group {
                if let image = avatarImage {
                    // Show actual avatar image with gradient border
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Theme.Colors.aiPurple.opacity(0.6), Theme.Colors.aiBlue.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
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
                                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                        )
                }
            }
            // Purple glow effect (layered for depth)
            .shadow(color: glowColor.opacity(glowOpacity), radius: 8, x: 0, y: 0)
            .shadow(color: glowColor.opacity(glowOpacity * 0.4), radius: 14, x: 0, y: 2)
        }
        .buttonStyle(PillButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        .onAppear {
            startGlowAnimation()
        }
    }

    private func startGlowAnimation() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowPhase = true
        }
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
