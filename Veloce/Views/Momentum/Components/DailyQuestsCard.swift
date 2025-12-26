//
//  DailyQuestsCard.swift
//  Veloce
//
//  Daily Quests Card - Gamification Challenges Display
//  3 AI-generated daily quests with progress tracking and cosmic theming
//

import SwiftUI

// MARK: - Daily Quests Card

struct DailyQuestsCard: View {
    let challenges: [DailyChallenge]
    var onChallengeTap: ((DailyChallenge) -> Void)?

    @State private var shimmerPhase: Double = 0
    @State private var glowPulse: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var completedCount: Int {
        challenges.filter { $0.isCompleted }.count
    }

    private var allComplete: Bool {
        completedCount == challenges.count && !challenges.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection

            // Quest Cards
            VStack(spacing: 12) {
                ForEach(challenges, id: \.id) { challenge in
                    QuestRow(
                        challenge: challenge,
                        shimmerPhase: shimmerPhase,
                        glowPulse: glowPulse
                    )
                    .onTapGesture {
                        onChallengeTap?(challenge)
                    }
                }
            }

            // All complete celebration
            if allComplete {
                allCompleteCelebration
            }
        }
        .padding(20)
        .background(cardBackground)
        .onAppear {
            guard !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.75, blue: 0.25),
                                    Color(red: 0.98, green: 0.55, blue: 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)

                    Text("Daily Quests")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("\(completedCount)/\(challenges.count) completed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Spacer()

            // Time remaining indicator
            if let firstChallenge = challenges.first {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(firstChallenge.timeRemainingFormatted)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.4))
            }
        }
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 0.04, green: 0.04, blue: 0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                // Celebration glow when all complete
                allComplete ?
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.75, blue: 0.25).opacity(0.5),
                                Color(red: 0.20, green: 0.85, blue: 0.55).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 4)
                : nil
            )
    }

    // MARK: - All Complete Celebration

    @ViewBuilder
    private var allCompleteCelebration: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.85, blue: 0.55),
                            Color(red: 0.20, green: 0.78, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, options: .repeating.speed(0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text("All Quests Complete!")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("You've earned \(challenges.reduce(0) { $0 + $1.xpReward }) bonus XP")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 0.98, green: 0.75, blue: 0.25))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.85, blue: 0.55).opacity(0.15),
                            Color(red: 0.20, green: 0.78, blue: 0.95).opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            shimmerPhase = 1
        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPulse = 1
        }
    }
}

// MARK: - Quest Row

struct QuestRow: View {
    let challenge: DailyChallenge
    let shimmerPhase: Double
    let glowPulse: Double

    @State private var progressAnimated: Double = 0

    private var challengeType: DailyChallengeType {
        challenge.challengeType
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon with color
            questIcon

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Title row
                HStack {
                    Text(challenge.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(challenge.isCompleted ? Color.white.opacity(0.5) : .white)
                        .strikethrough(challenge.isCompleted)

                    Spacer()

                    // XP reward
                    HStack(spacing: 4) {
                        Text("+\(challenge.xpReward)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text("XP")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(
                        challenge.isCompleted
                        ? Color(red: 0.20, green: 0.85, blue: 0.55)
                        : Color(red: 0.98, green: 0.75, blue: 0.25)
                    )
                }

                // Description
                Text(challenge.challengeDescription)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))

                // Progress bar
                progressBar
            }
        }
        .padding(14)
        .background(rowBackground)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                progressAnimated = challenge.progress
            }
        }
        .onChange(of: challenge.progress) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                progressAnimated = newValue
            }
        }
    }

    // MARK: - Quest Icon

    @ViewBuilder
    private var questIcon: some View {
        ZStack {
            // Background glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            challengeType.color.opacity(challenge.isCompleted ? 0.3 : 0.4 * (0.8 + glowPulse * 0.4)),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 24
                    )
                )
                .frame(width: 48, height: 48)

            // Icon circle
            SwiftUI.Circle()
                .fill(
                    challenge.isCompleted
                    ? Color(red: 0.20, green: 0.85, blue: 0.55)
                    : challengeType.color
                )
                .frame(width: 40, height: 40)
                .overlay(
                    challenge.isCompleted
                    ? Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    : Image(systemName: challengeType.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: (challenge.isCompleted ? Color(red: 0.20, green: 0.85, blue: 0.55) : challengeType.color).opacity(0.4), radius: 8)
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.1))

                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: challenge.isCompleted
                                ? [Color(red: 0.20, green: 0.85, blue: 0.55), Color(red: 0.15, green: 0.75, blue: 0.45)]
                                : [challengeType.color, challengeType.color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progressAnimated)

                // Shimmer effect (when not complete)
                if !challenge.isCompleted && progressAnimated > 0 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: (geometry.size.width * progressAnimated - geometry.size.width * 0.3) * shimmerPhase)
                        .mask(
                            Capsule()
                                .frame(width: geometry.size.width * progressAnimated)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }
            }
        }
        .frame(height: 6)

        // Progress text
        HStack {
            Text("\(challenge.currentValue)/\(challenge.targetValue)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.4))

            Spacer()

            if challenge.isCompleted {
                Text("COMPLETE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.55))
            }
        }
    }

    // MARK: - Row Background

    @ViewBuilder
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        challenge.isCompleted
                        ? Color(red: 0.20, green: 0.85, blue: 0.55).opacity(0.3)
                        : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                DailyQuestsCard(challenges: DailyChallenge.previews)

                // With some completed
                DailyQuestsCard(challenges: {
                    let challenges = DailyChallenge.previews
                    challenges[0].updateProgress(newValue: 2)
                    challenges[1].updateProgress(newValue: 15)
                    return challenges
                }())

                // All complete
                DailyQuestsCard(challenges: {
                    let challenges = DailyChallenge.previews
                    challenges.forEach { $0.updateProgress(newValue: $0.targetValue) }
                    return challenges
                }())
            }
            .padding()
        }
    }
}
