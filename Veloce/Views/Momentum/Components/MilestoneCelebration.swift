//
//  MilestoneCelebration.swift
//  Veloce
//
//  Milestone Celebration Overlay - Full-Screen Achievement Moment
//  Dramatic celebration when users complete goal milestones
//  Features particles, cosmic effects, and satisfying animations
//

import SwiftUI

// MARK: - Milestone Celebration Overlay

struct MilestoneCelebration: View {
    let milestone: GoalMilestone
    let goal: Goal
    let xpEarned: Int
    var onDismiss: (() -> Void)?

    @State private var phase: CelebrationPhase = .entering
    @State private var particlePhase: Double = 0
    @State private var ringScale: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var checkmarkScale: Double = 0
    @State private var starBurst: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum CelebrationPhase {
        case entering, celebrating, content, exiting
    }

    private var planetType: GoalPlanetType {
        GoalPlanetType.from(category: goal.category)
    }

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(phase == .exiting ? 0 : 0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Particle explosion
            if !reduceMotion {
                particleExplosion
            }

            // Ring burst
            ringBurst

            // Main content
            VStack(spacing: 32) {
                Spacer()

                // Milestone icon with planet ring
                milestoneIcon

                // Text content
                textContent

                // XP reward
                xpReward

                Spacer()

                // Dismiss button
                dismissButton
            }
            .padding(32)
            .opacity(contentOpacity)
        }
        .onAppear {
            if reduceMotion {
                showInstantly()
            } else {
                startCelebration()
            }
        }
    }

    // MARK: - Particle Explosion

    @ViewBuilder
    private var particleExplosion: some View {
        Canvas { context, size in
            srand48(42)

            let particleCount = 60
            for i in 0..<particleCount {
                let baseAngle = Double(i) / Double(particleCount) * 2 * .pi
                let angleOffset = drand48() * 0.3 - 0.15
                let angle = baseAngle + angleOffset

                let maxRadius = min(size.width, size.height) * 0.5
                let progress = min(1.0, particlePhase * (1 + drand48() * 0.3))
                let radius = maxRadius * progress

                let x = size.width / 2 + cos(angle) * radius
                let y = size.height / 2 + sin(angle) * radius

                let particleSize = 4 + drand48() * 4
                let opacity = max(0, 1 - progress * 0.8) * (0.5 + drand48() * 0.5)

                let rect = CGRect(
                    x: x - particleSize/2,
                    y: y - particleSize/2,
                    width: particleSize,
                    height: particleSize
                )

                let colorChoice = Int(drand48() * 3)
                let color: Color
                switch colorChoice {
                case 0: color = planetType.primaryColor.opacity(opacity)
                case 1: color = planetType.secondaryColor.opacity(opacity)
                default: color = Color.white.opacity(opacity * 0.7)
                }

                context.fill(SwiftUI.Circle().path(in: rect), with: .color(color))
            }
        }
    }

    // MARK: - Ring Burst

    @ViewBuilder
    private var ringBurst: some View {
        ZStack {
            // Multiple expanding rings
            ForEach(0..<4, id: \.self) { ring in
                SwiftUI.Circle()
                    .stroke(
                        planetType.primaryColor.opacity(max(0, 0.6 - Double(ring) * 0.15 - ringScale * 0.4)),
                        lineWidth: max(1, 4 - Double(ring))
                    )
                    .frame(
                        width: 100 + CGFloat(ring * 40) + CGFloat(ringScale * 200),
                        height: 100 + CGFloat(ring * 40) + CGFloat(ringScale * 200)
                    )
            }

            // Central glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetType.primaryColor.opacity(glowIntensity * 0.6),
                            planetType.secondaryColor.opacity(glowIntensity * 0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 20)
        }
    }

    // MARK: - Milestone Icon

    @ViewBuilder
    private var milestoneIcon: some View {
        ZStack {
            // Outer glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetType.primaryColor.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 15)

            // Star burst rays
            ForEach(0..<8, id: \.self) { ray in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                planetType.primaryColor.opacity(0.4 * starBurst),
                                Color.clear
                            ],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 80 * starBurst)
                    .offset(y: -60)
                    .rotationEffect(.degrees(Double(ray) * 45))
            }

            // Planet ring (showing milestone = new ring earned)
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [
                            planetType.primaryColor.opacity(0.8),
                            planetType.secondaryColor.opacity(0.5),
                            planetType.primaryColor.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 130, height: 35)
                .rotation3DEffect(.degrees(75), axis: (x: 1, y: 0, z: 0))
                .offset(y: 5)

            // Main circle (planet)
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetType.primaryColor,
                            planetType.secondaryColor,
                            planetType.secondaryColor.opacity(0.8)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 90, height: 90)
                .shadow(color: planetType.primaryColor.opacity(0.5), radius: 20)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(checkmarkScale)
        }
    }

    // MARK: - Text Content

    @ViewBuilder
    private var textContent: some View {
        VStack(spacing: 16) {
            // Milestone label
            Text("MILESTONE COMPLETE")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(planetType.primaryColor)
                .tracking(2)

            // Milestone title
            Text(milestone.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            // Goal name
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(planetType.primaryColor)

                Text(goal.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            // Progress indicator
            if goal.completedMilestoneCount < goal.milestoneCount {
                HStack(spacing: 4) {
                    ForEach(0..<goal.milestoneCount, id: \.self) { i in
                        SwiftUI.Circle()
                            .fill(
                                i < goal.completedMilestoneCount
                                ? planetType.primaryColor
                                : Color.white.opacity(0.2)
                            )
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 8)
            } else {
                // All milestones complete!
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                    Text("All milestones complete!")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color(red: 0.98, green: 0.75, blue: 0.25))
                .padding(.top, 8)
            }
        }
    }

    // MARK: - XP Reward

    @ViewBuilder
    private var xpReward: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 20))
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
                .symbolEffect(.bounce, options: .repeating.speed(0.5))

            Text("+\(xpEarned) XP")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.75, blue: 0.25),
                            Color(red: 0.98, green: 0.55, blue: 0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color(red: 0.98, green: 0.75, blue: 0.25).opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.98, green: 0.75, blue: 0.25).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Dismiss Button

    @ViewBuilder
    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Continue")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [planetType.primaryColor, planetType.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: planetType.primaryColor.opacity(0.4), radius: 15)
                )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 32)
    }

    // MARK: - Animation Logic

    private func startCelebration() {
        phase = .entering

        // Haptic feedback
        HapticsService.shared.milestoneReached()

        // Ring burst
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            ringScale = 1.0
        }

        // Glow
        withAnimation(.easeOut(duration: 0.4)) {
            glowIntensity = 1.0
        }

        // Particles
        withAnimation(.easeOut(duration: 1.2)) {
            particlePhase = 1.0
        }

        // Content
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            contentOpacity = 1.0
        }

        // Checkmark
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.4)) {
            checkmarkScale = 1.0
        }

        // Star burst
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            starBurst = 1.0
        }

        phase = .content
    }

    private func showInstantly() {
        ringScale = 1.0
        glowIntensity = 1.0
        particlePhase = 1.0
        contentOpacity = 1.0
        checkmarkScale = 1.0
        starBurst = 1.0
        phase = .content
    }

    private func dismiss() {
        phase = .exiting

        withAnimation(.easeIn(duration: 0.3)) {
            contentOpacity = 0
            glowIntensity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Level Up Celebration

struct LevelUpCelebration: View {
    let previousLevel: Int
    let newLevel: Int
    let totalPoints: Int
    var onDismiss: (() -> Void)?

    @State private var circleScale: Double = 0
    @State private var numberScale: Double = 0
    @State private var glowPhase: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var particlePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var levelColor: Color {
        if newLevel >= 50 {
            return Color(red: 0.98, green: 0.75, blue: 0.25) // Gold
        } else if newLevel >= 20 {
            return Color(red: 0.58, green: 0.25, blue: 0.98) // Purple
        } else if newLevel >= 10 {
            return Color(red: 0.42, green: 0.45, blue: 0.98) // Blue
        } else {
            return Color(red: 0.20, green: 0.78, blue: 0.95) // Cyan
        }
    }

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Particles
            if !reduceMotion {
                levelUpParticles
            }

            // Content
            VStack(spacing: 40) {
                Spacer()

                // Level orb
                levelOrb

                // Text
                VStack(spacing: 12) {
                    Text("LEVEL UP!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(levelColor)
                        .tracking(3)

                    Text("Level \(newLevel)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [levelColor, levelColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("\(totalPoints.formatted()) Total XP")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .opacity(contentOpacity)

                Spacer()

                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(levelColor)
                                .shadow(color: levelColor.opacity(0.4), radius: 15)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            if reduceMotion {
                showInstantly()
            } else {
                startAnimation()
            }
        }
    }

    @ViewBuilder
    private var levelOrb: some View {
        ZStack {
            // Glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            levelColor.opacity(0.5 * glowPhase),
                            levelColor.opacity(0.2 * glowPhase),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 20)

            // Main orb
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            levelColor,
                            levelColor.opacity(0.7),
                            levelColor.opacity(0.5)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(circleScale)
                .shadow(color: levelColor.opacity(0.5), radius: 30)

            // Level number
            Text("\(newLevel)")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .scaleEffect(numberScale)
        }
    }

    @ViewBuilder
    private var levelUpParticles: some View {
        Canvas { context, size in
            srand48(123)

            let particleCount = 40
            for i in 0..<particleCount {
                let angle = Double(i) / Double(particleCount) * 2 * .pi + drand48() * 0.2
                let maxRadius = min(size.width, size.height) * 0.45
                let radius = maxRadius * particlePhase * (0.7 + drand48() * 0.3)

                let x = size.width / 2 + cos(angle) * radius
                let y = size.height / 2 + sin(angle) * radius

                let particleSize = 3 + drand48() * 3
                let opacity = max(0, 1 - particlePhase * 0.7) * (0.6 + drand48() * 0.4)

                let rect = CGRect(
                    x: x - particleSize/2,
                    y: y - particleSize/2,
                    width: particleSize,
                    height: particleSize
                )

                context.fill(SwiftUI.Circle().path(in: rect), with: .color(levelColor.opacity(opacity)))
            }
        }
    }

    private func startAnimation() {
        HapticsService.shared.levelUp()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            circleScale = 1.0
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.2)) {
            numberScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.5)) {
            glowPhase = 1.0
        }

        withAnimation(.easeOut(duration: 1.0)) {
            particlePhase = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            contentOpacity = 1.0
        }
    }

    private func showInstantly() {
        circleScale = 1.0
        numberScale = 1.0
        glowPhase = 1.0
        particlePhase = 1.0
        contentOpacity = 1.0
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.3)) {
            contentOpacity = 0
            glowPhase = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        let sampleGoalId = UUID()
        MilestoneCelebration(
            milestone: GoalMilestone(
                goalId: sampleGoalId,
                title: "Complete Swift Basics Course",
                isCompleted: true,
                completedAt: Date()
            ),
            goal: Goal(title: "Learn Swift", timeframe: GoalTimeframe.milestone.rawValue),
            xpEarned: 150
        )
    }
}

#Preview("Level Up") {
    LevelUpCelebration(
        previousLevel: 9,
        newLevel: 10,
        totalPoints: 2500
    )
}
