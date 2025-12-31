//
//  VelocityScoreOrb.swift
//  Veloce
//
//  Velocity Score Orb - Animated display of productivity health score
//  Glassmorphic orb with animated score reveal and breakdown
//

import SwiftUI

// MARK: - Velocity Score Orb

struct VelocityScoreOrb: View {
    let score: VelocityScore
    var showBreakdown: Bool = false

    @State private var animatedScore: Int = 0
    @State private var ringProgress: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var isExpanded = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Main Orb
            ZStack {
                // Outer glow
                orbGlow

                // Ring track
                orbRing

                // Center content
                orbCenter
            }
            .frame(width: 200, height: 200)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }

            // Score Breakdown
            if showBreakdown || isExpanded {
                scoreBreakdown
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Orb Glow

    private var orbGlow: some View {
        ZStack {
            // Outer atmospheric glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            score.color.opacity(0.4 * glowIntensity),
                            score.color.opacity(0.2 * glowIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 20)

            // Inner pulse
            SwiftUI.Circle()
                .fill(score.color.opacity(0.2))
                .frame(width: 180, height: 180)
                .blur(radius: 15)
                .scaleEffect(1 + (glowIntensity * 0.1))
        }
    }

    // MARK: - Orb Ring

    private var orbRing: some View {
        ZStack {
            // Track
            SwiftUI.Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 160, height: 160)

            // Progress ring
            SwiftUI.Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    score.gradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))

            // Rotating sparkle
            if !reduceMotion {
                Image(systemName: "sparkle")
                    .dynamicTypeFont(base: 12, weight: .bold)
                    .foregroundStyle(score.color)
                    .offset(y: -80)
                    .rotationEffect(.degrees(rotationAngle))
                    .opacity(ringProgress > 0.5 ? 1 : 0)
            }
        }
    }

    // MARK: - Orb Center

    private var orbCenter: some View {
        VStack(spacing: 4) {
            // Score number
            Text("\(animatedScore)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(score.gradient)
                .contentTransition(.numericText())

            // Tier label
            HStack(spacing: 4) {
                Image(systemName: score.tier.icon)
                    .dynamicTypeFont(base: 12, weight: .semibold)
                Text(score.tierLabel)
                    .dynamicTypeFont(base: 12, weight: .semibold)
            }
            .foregroundStyle(score.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(score.color.opacity(0.15))
            }

            // Message
            Text(score.message)
                .dynamicTypeFont(base: 11)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 120)
        }
    }

    // MARK: - Score Breakdown

    private var scoreBreakdown: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(ScoreBreakdown.from(score)) { breakdown in
                HStack(spacing: Theme.Spacing.md) {
                    // Icon
                    Image(systemName: breakdown.icon)
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(breakdown.color)
                        .frame(width: 24)

                    // Label
                    Text(breakdown.category)
                        .dynamicTypeFont(base: 13, weight: .medium)
                        .foregroundStyle(.primary)

                    Spacer()

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(breakdown.color)
                                .frame(width: geo.size.width * breakdown.percentage)
                        }
                    }
                    .frame(width: 80, height: 8)

                    // Score
                    Text(breakdown.displayScore)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(breakdown.color)
                        .frame(width: 24, alignment: .trailing)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Animation

    private func animateIn() {
        if reduceMotion {
            animatedScore = score.total
            ringProgress = Double(score.total) / 100.0
            glowIntensity = 1.0
            return
        }

        // Animate score count up
        let duration = 1.2
        let steps = 30
        let stepDuration = duration / Double(steps)
        let scoreIncrement = Double(score.total) / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                animatedScore = Int(scoreIncrement * Double(i + 1))
            }
        }

        // Animate ring
        withAnimation(.easeOut(duration: 1.2)) {
            ringProgress = Double(score.total) / 100.0
        }

        // Animate glow
        withAnimation(.easeOut(duration: 0.8)) {
            glowIntensity = 1.0
        }

        // Continuous sparkle rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

// MARK: - Compact Velocity Score

struct VelocityScoreCompact: View {
    let score: VelocityScore

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Mini orb
            ZStack {
                SwiftUI.Circle()
                    .fill(score.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                SwiftUI.Circle()
                    .trim(from: 0, to: Double(score.total) / 100.0)
                    .stroke(score.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                Text("\(score.total)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(score.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Velocity Score")
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: score.tier.icon)
                        .dynamicTypeFont(base: 10)
                    Text(score.tierLabel)
                        .dynamicTypeFont(base: 12, weight: .semibold)
                }
                .foregroundStyle(score.color)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .dynamicTypeFont(base: 12, weight: .semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Shareable Velocity Card

struct ShareableVelocityCard: View {
    let score: VelocityScore
    let userName: String
    let weekLabel: String

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .dynamicTypeFont(base: 24)
                    .foregroundStyle(Theme.Colors.accent)

                Text("Veloce")
                    .dynamicTypeFont(base: 20, weight: .bold)

                Spacer()

                Text(weekLabel)
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(.secondary)
            }

            // Score display
            VStack(spacing: Theme.Spacing.sm) {
                Text("\(score.total)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(score.gradient)

                HStack(spacing: 6) {
                    Image(systemName: score.tier.icon)
                    Text(score.tierLabel)
                }
                .dynamicTypeFont(base: 16, weight: .semibold)
                .foregroundStyle(score.color)
            }

            // User name
            Text(userName)
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.secondary)

            Divider()

            // Breakdown
            HStack(spacing: Theme.Spacing.lg) {
                scoreItem(icon: "flame.fill", value: Int(score.streakScore), color: .orange)
                scoreItem(icon: "checkmark.circle.fill", value: Int(score.completionScore), color: .green)
                scoreItem(icon: "timer", value: Int(score.focusScore), color: .blue)
                scoreItem(icon: "clock.fill", value: Int(score.onTimeScore), color: .purple)
            }
        }
        .padding(Theme.Spacing.xl)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(score.gradient, lineWidth: 2)
        }
        .frame(width: 300)
    }

    private func scoreItem(icon: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .dynamicTypeFont(base: 16)
                .foregroundStyle(color)

            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Velocity Score Detail Sheet

struct VelocityScoreDetailSheet: View {
    let score: VelocityScore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.momentum

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Main Orb
                        VelocityScoreOrb(score: score, showBreakdown: false)
                            .padding(.top, Theme.Spacing.lg)

                        // Message card
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: score.tier.icon)
                                .dynamicTypeFont(base: 24)
                                .foregroundStyle(score.color)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(score.tierLabel)
                                    .dynamicTypeFont(base: 16, weight: .bold)
                                Text(score.message)
                                    .dynamicTypeFont(base: 14)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(Theme.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(score.color.opacity(0.1))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(score.color.opacity(0.3), lineWidth: 1)
                        }

                        // Score Breakdown
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Text("Score Breakdown")
                                .dynamicTypeFont(base: 17, weight: .semibold)

                            ForEach(ScoreBreakdown.from(score)) { breakdown in
                                HStack(spacing: Theme.Spacing.md) {
                                    Image(systemName: breakdown.icon)
                                        .dynamicTypeFont(base: 18)
                                        .foregroundStyle(breakdown.color)
                                        .frame(width: 28)

                                    Text(breakdown.category)
                                        .dynamicTypeFont(base: 15, weight: .medium)

                                    Spacer()

                                    // Progress bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.1))

                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(breakdown.color)
                                                .frame(width: geo.size.width * breakdown.percentage)
                                        }
                                    }
                                    .frame(width: 100, height: 8)

                                    Text("\(breakdown.displayScore)/25")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(breakdown.color)
                                        .frame(width: 50, alignment: .trailing)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(Theme.Spacing.lg)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        }
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))

                        // Tips to improve
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                Text("Tips to Improve")
                                    .dynamicTypeFont(base: 15, weight: .semibold)
                            }

                            improvementTips
                        }
                        .padding(Theme.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.yellow.opacity(0.1))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        }

                        Spacer()
                            .frame(height: 60)
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                }
            }
            .navigationTitle("Velocity Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var improvementTips: some View {
        let tips = generateTips()
        VStack(alignment: .leading, spacing: 8) {
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(.yellow)
                    Text(tip)
                        .dynamicTypeFont(base: 13)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private func generateTips() -> [String] {
        var tips: [String] = []

        if score.streakScore < 15 {
            tips.append("Complete tasks daily to build your streak")
        }
        if score.completionScore < 15 {
            tips.append("Focus on finishing more tasks this week")
        }
        if score.focusScore < 15 {
            tips.append("Use Focus Mode for deep work sessions")
        }
        if score.onTimeScore < 15 {
            tips.append("Schedule tasks and complete them on time")
        }

        if tips.isEmpty {
            tips.append("Keep up the great work!")
        }

        return tips
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        VelocityScoreOrb(
            score: VelocityScore(
                currentStreak: 7,
                longestStreak: 14,
                tasksCompletedThisWeek: 20,
                weeklyGoal: 25,
                focusMinutesThisWeek: 180,
                focusGoalMinutes: 300,
                tasksOnTime: 15,
                totalTasksCompleted: 20
            ),
            showBreakdown: true
        )

        VelocityScoreCompact(
            score: VelocityScore(
                currentStreak: 7,
                longestStreak: 14,
                tasksCompletedThisWeek: 20,
                weeklyGoal: 25,
                focusMinutesThisWeek: 180,
                focusGoalMinutes: 300,
                tasksOnTime: 15,
                totalTasksCompleted: 20
            )
        )
        .padding(.horizontal)
    }
    .preferredColorScheme(.dark)
}
