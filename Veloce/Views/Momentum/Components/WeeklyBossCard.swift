//
//  WeeklyBossCard.swift
//  Veloce
//
//  Weekly Boss Card - Epic Boss Battle Visualization
//  Dramatic boss health display with cosmic effects,
//  attack animations, and victory celebrations
//

import SwiftUI

// MARK: - Weekly Boss Card

struct WeeklyBossCard: View {
    let boss: WeeklyBoss
    var onAttack: (() -> Void)?

    @State private var healthBarWidth: CGFloat = 0
    @State private var pulsePhase: Double = 0
    @State private var glowIntensity: Double = 0.5
    @State private var shakeOffset: CGFloat = 0
    @State private var bossRotation: Double = 0
    @State private var particlePhase: Double = 0
    @State private var showDamageFlash: Bool = false
    @State private var lastHealth: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var appearance: BossAppearance { boss.bossAppearance }
    private var difficulty: BossDifficulty { boss.bossDifficulty }

    var body: some View {
        VStack(spacing: 0) {
            // Header with difficulty badge
            headerSection

            // Boss visualization
            bossVisualization

            // Health bar
            healthBarSection

            // Stats and combat log
            statsSection

            // Attack button (if not defeated)
            if !boss.isDefeated && !boss.isExpired {
                attackButton
            }

            // Victory/Defeat state
            if boss.isDefeated {
                victorySection
            } else if boss.isExpired {
                expiredSection
            }
        }
        .padding(20)
        .background(cardBackground)
        .onAppear {
            lastHealth = boss.currentHealth
            guard !reduceMotion else { return }
            startAnimations()
        }
        .onChange(of: boss.currentHealth) { oldValue, newValue in
            if newValue < oldValue && !reduceMotion {
                triggerDamageAnimation()
            }
            lastHealth = newValue
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(appearance.primaryColor)

                    Text("Weekly Boss")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1.5)
                }

                Text(boss.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [appearance.primaryColor, appearance.secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Spacer()

            // Difficulty badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(difficulty.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(difficulty.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(difficulty.color.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(difficulty.color.opacity(0.4), lineWidth: 1)
                            )
                    )

                Text(boss.timeRemainingFormatted)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Boss Visualization

    @ViewBuilder
    private var bossVisualization: some View {
        ZStack {
            // Background aura
            bossAura

            // Particle effects
            if !boss.isDefeated && !reduceMotion {
                bossParticles
            }

            // Boss icon
            bossIcon

            // Damage flash overlay
            if showDamageFlash {
                SwiftUI.Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .transition(.opacity)
            }
        }
        .frame(height: 160)
        .offset(x: shakeOffset)
    }

    @ViewBuilder
    private var bossAura: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { ring in
                SwiftUI.Circle()
                    .stroke(
                        appearance.primaryColor.opacity(0.15 - Double(ring) * 0.04),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(100 + ring * 30), height: CGFloat(100 + ring * 30))
                    .scaleEffect(1 + pulsePhase * 0.05 * Double(ring + 1))
            }

            // Core glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            appearance.primaryColor.opacity(0.4 * glowIntensity),
                            appearance.secondaryColor.opacity(0.2 * glowIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)

            // Low health danger aura
            if boss.isLowHealth && !boss.isDefeated {
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.98, green: 0.35, blue: 0.20).opacity(0.3 * glowIntensity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 15)
            }
        }
    }

    @ViewBuilder
    private var bossParticles: some View {
        Canvas { context, size in
            srand48(42)

            for i in 0..<12 {
                let baseAngle = Double(i) / 12.0 * 2 * .pi
                let angle = baseAngle + particlePhase * 0.5 + sin(particlePhase * 2 + Double(i)) * 0.3
                let radius = 50 + drand48() * 20 + sin(particlePhase + Double(i)) * 10

                let x = size.width / 2 + cos(angle) * radius
                let y = size.height / 2 + sin(angle) * radius

                let particleSize = 3 + sin(particlePhase * 3 + Double(i)) * 2
                let opacity = 0.4 + sin(particlePhase * 2 + Double(i) * 0.5) * 0.3

                let rect = CGRect(
                    x: x - particleSize/2,
                    y: y - particleSize/2,
                    width: particleSize,
                    height: particleSize
                )

                let color = i % 2 == 0
                    ? appearance.primaryColor.opacity(opacity)
                    : appearance.secondaryColor.opacity(opacity)

                context.fill(SwiftUI.Circle().path(in: rect), with: .color(color))
            }
        }
    }

    @ViewBuilder
    private var bossIcon: some View {
        ZStack {
            // Icon background
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.15),
                            Color(red: 0.06, green: 0.06, blue: 0.08)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    SwiftUI.Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    appearance.primaryColor.opacity(0.6),
                                    appearance.secondaryColor.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: appearance.primaryColor.opacity(0.4), radius: 15)

            // Boss icon
            Image(systemName: appearance.icon)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [appearance.primaryColor, appearance.secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(boss.isDefeated ? 0 : bossRotation))
                .opacity(boss.isDefeated ? 0.4 : 1.0)
                .overlay {
                    if boss.isDefeated {
                        Image(systemName: "xmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color(red: 0.98, green: 0.35, blue: 0.20))
                    }
                }
        }
    }

    // MARK: - Health Bar Section

    @ViewBuilder
    private var healthBarSection: some View {
        VStack(spacing: 8) {
            // Health label
            HStack {
                Text("HP")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))

                Spacer()

                Text("\(boss.currentHealth) / \(boss.totalHealth)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(boss.isLowHealth ? Color(red: 0.98, green: 0.35, blue: 0.20) : .white)
                    .contentTransition(.numericText())
            }

            // Health bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))

                    // Health fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(healthGradient)
                        .frame(width: geometry.size.width * boss.healthProgress)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: boss.healthProgress)

                    // Damage section (difference from last health)
                    if showDamageFlash {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: geometry.size.width * boss.healthProgress)
                    }

                    // Critical health pulse
                    if boss.isCriticalHealth && !boss.isDefeated {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 0.98, green: 0.35, blue: 0.20), lineWidth: 2)
                            .scaleEffect(1 + pulsePhase * 0.05)
                            .opacity(0.5 + pulsePhase * 0.5)
                    }
                }
            }
            .frame(height: 12)

            // Taunt message
            if !boss.isDefeated && !boss.isExpired {
                Text("\"\(boss.currentTaunt)\"")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 16)
    }

    private var healthGradient: LinearGradient {
        if boss.isCriticalHealth {
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.35, blue: 0.20),
                    Color(red: 0.98, green: 0.55, blue: 0.25)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if boss.isLowHealth {
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.55, blue: 0.25),
                    Color(red: 0.98, green: 0.75, blue: 0.25)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [appearance.primaryColor, appearance.secondaryColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        HStack(spacing: 20) {
            statItem(
                icon: "bolt.fill",
                value: "\(boss.tasksDefeated)",
                label: "Hits",
                color: Color(red: 0.42, green: 0.45, blue: 0.98)
            )

            statItem(
                icon: "star.fill",
                value: "\(boss.criticalHits)",
                label: "Crits",
                color: Color(red: 0.98, green: 0.75, blue: 0.25)
            )

            statItem(
                icon: "gift.fill",
                value: "\(boss.xpReward)",
                label: "XP",
                color: Color(red: 0.58, green: 0.25, blue: 0.98)
            )
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Attack Button

    @ViewBuilder
    private var attackButton: some View {
        Button {
            onAttack?()
            if !reduceMotion {
                triggerDamageAnimation()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))

                Text("ATTACK")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [appearance.primaryColor, appearance.secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: appearance.primaryColor.opacity(0.4), radius: 10)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 20)
    }

    // MARK: - Victory Section

    @ViewBuilder
    private var victorySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
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

                Text("VICTORY!")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.75, blue: 0.25),
                                Color(red: 0.20, green: 0.85, blue: 0.55)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Text(appearance.defeatMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)

            // Rewards
            HStack(spacing: 16) {
                rewardBadge(icon: "star.fill", value: "+\(boss.xpReward)", label: "XP")
                rewardBadge(icon: "plus.circle.fill", value: "+\(boss.calculateBonusXP())", label: "Bonus")
            }
            .padding(.top, 8)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private func rewardBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 0.98, green: 0.75, blue: 0.25))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(red: 0.98, green: 0.75, blue: 0.25).opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.98, green: 0.75, blue: 0.25).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Expired Section

    @ViewBuilder
    private var expiredSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 24))
                .foregroundStyle(Color(red: 0.98, green: 0.35, blue: 0.20))

            Text("Time's Up!")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.98, green: 0.35, blue: 0.20))

            Text("The boss escaped. Try again next week!")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(.top, 20)
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(red: 0.04, green: 0.04, blue: 0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                appearance.primaryColor.opacity(0.3),
                                appearance.secondaryColor.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: appearance.primaryColor.opacity(0.2), radius: 20, x: 0, y: 10)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }

        // Glow intensity
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 1
        }

        // Boss subtle rotation
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            bossRotation = 5
        }

        // Particles
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            particlePhase = 2 * .pi
        }
    }

    private func triggerDamageAnimation() {
        // Flash
        withAnimation(.easeOut(duration: 0.1)) {
            showDamageFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.2)) {
                showDamageFlash = false
            }
        }

        // Shake
        withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                shakeOffset = -8
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                shakeOffset = 0
            }
        }
    }
}

// MARK: - Compact Boss Badge

struct CompactBossBadge: View {
    let boss: WeeklyBoss

    @State private var pulsePhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var appearance: BossAppearance { boss.bossAppearance }

    var body: some View {
        HStack(spacing: 10) {
            // Boss icon
            ZStack {
                SwiftUI.Circle()
                    .fill(appearance.primaryColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: appearance.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(appearance.primaryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(boss.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Health bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [appearance.primaryColor, appearance.secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * boss.healthProgress)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            // Health text
            Text("\(Int(boss.healthProgress * 100))%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(boss.isLowHealth ? Color(red: 0.98, green: 0.35, blue: 0.20) : Color.white.opacity(0.6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appearance.primaryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                WeeklyBossCard(boss: WeeklyBoss.preview)

                WeeklyBossCard(boss: WeeklyBoss.lowHealthPreview)

                WeeklyBossCard(boss: WeeklyBoss.defeatedPreview)

                // Compact badges
                VStack(spacing: 12) {
                    CompactBossBadge(boss: WeeklyBoss.preview)
                    CompactBossBadge(boss: WeeklyBoss.lowHealthPreview)
                }
            }
            .padding()
        }
    }
}
