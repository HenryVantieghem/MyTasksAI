//
//  TaskCelebrations.swift
//  MyTasksAI
//
//  Micro-Interactions - Task Celebration Animations
//  Binding-based gold bursts, particle showers, and XP animations
//

import SwiftUI

// MARK: - Simple Confetti (Binding-based)

/// Simple confetti animation triggered by binding
struct SimpleConfetti: View {
    @Binding var isActive: Bool
    var particleCount: Int = 50
    var colors: [Color] = [
        Color(hex: "8B5CF6"),
        Color(hex: "3B82F6"),
        Color(hex: "06B6D4"),
        Color(hex: "FFD700"),
        Color(hex: "10B981")
    ]

    @State private var particles: [SimpleConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                SimpleConfettiPiece(particle: particle)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                generateParticles()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isActive = false
                    particles = []
                }
            }
        }
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { i in
            SimpleConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .white,
                x: CGFloat.random(in: -150...150),
                y: CGFloat.random(in: -300 ... -100),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.2),
                delay: Double.random(in: 0...0.3)
            )
        }
    }
}

struct SimpleConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let delay: Double
}

struct SimpleConfettiPiece: View {
    let particle: SimpleConfettiParticle

    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var currentRotation: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: 8 * particle.scale, height: 12 * particle.scale)
            .rotationEffect(.degrees(currentRotation))
            .offset(x: particle.x, y: particle.y + yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2).delay(particle.delay)) {
                    yOffset = 400
                    opacity = 0
                }
                withAnimation(.linear(duration: 2).delay(particle.delay)) {
                    currentRotation = particle.rotation + 720
                }
            }
    }
}

// MARK: - Gold Burst Effect

struct GoldBurstEffect: View {
    @Binding var isActive: Bool

    @State private var particles: [GoldParticle] = []
    @State private var ringScale: CGFloat = 0
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            // Central ring burst
            SwiftUI.Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 100 * ringScale, height: 100 * ringScale)
                .opacity(ringOpacity)

            // Particles
            ForEach(particles) { particle in
                GoldParticlePiece(particle: particle)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerBurst()
            }
        }
    }

    private func triggerBurst() {
        // Ring animation
        withAnimation(.easeOut(duration: 0.5)) {
            ringScale = 1.5
            ringOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
            ringOpacity = 0
        }

        // Generate particles
        particles = (0..<20).map { i in
            let angle = (Double(i) / 20) * 2 * .pi
            return GoldParticle(
                id: i,
                angle: angle,
                distance: CGFloat.random(in: 50...100),
                size: CGFloat.random(in: 4...10)
            )
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isActive = false
            particles = []
            ringScale = 0
        }
    }
}

struct GoldParticle: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
}

struct GoldParticlePiece: View {
    let particle: GoldParticle

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500").opacity(0.5), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: particle.size
                )
            )
            .frame(width: particle.size * 2, height: particle.size * 2)
            .offset(
                x: cos(particle.angle) * offset,
                y: sin(particle.angle) * offset
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    offset = particle.distance
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Particle Shower (Level Up)

struct ParticleShower: View {
    @Binding var isActive: Bool

    @State private var particles: [ShowerParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ShowerParticlePiece(particle: particle, screenHeight: geo.size.height)
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                generateShower()
            }
        }
    }

    private func generateShower() {
        // Use a default width for particle distribution
        let screenWidth: CGFloat = 400
        particles = (0..<100).map { i in
            ShowerParticle(
                id: i,
                x: CGFloat.random(in: 0...screenWidth),
                delay: Double.random(in: 0...1),
                speed: Double.random(in: 1...2),
                size: CGFloat.random(in: 3...8),
                color: [
                    Color(hex: "8B5CF6"),
                    Color(hex: "3B82F6"),
                    Color(hex: "06B6D4"),
                    Color(hex: "FFD700")
                ].randomElement() ?? .white
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isActive = false
            particles = []
        }
    }
}

struct ShowerParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let delay: Double
    let speed: Double
    let size: CGFloat
    let color: Color
}

struct ShowerParticlePiece: View {
    let particle: ShowerParticle
    let screenHeight: CGFloat

    @State private var yOffset: CGFloat = -50
    @State private var opacity: Double = 0

    var body: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [particle.color, particle.color.opacity(0.3), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: particle.size
                )
            )
            .frame(width: particle.size * 2, height: particle.size * 2)
            .position(x: particle.x, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 0.2).delay(particle.delay)) {
                    opacity = 1
                }
                withAnimation(.linear(duration: particle.speed).delay(particle.delay)) {
                    yOffset = screenHeight + 50
                }
                withAnimation(.linear(duration: 0.3).delay(particle.delay + particle.speed - 0.3)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Floating Text (XP Gain)

struct FloatingXPText: View {
    let points: Int
    @Binding var isActive: Bool

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text("+\(points) XP")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 8)
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    animate()
                }
            }
    }

    private func animate() {
        // Reset
        offset = 0
        opacity = 0
        scale = 0.5

        // Animate in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            opacity = 1
            scale = 1.2
        }

        withAnimation(.spring(response: 0.2).delay(0.1)) {
            scale = 1
        }

        // Float up and fade
        withAnimation(.easeOut(duration: 1).delay(0.3)) {
            offset = -80
        }

        withAnimation(.easeOut(duration: 0.5).delay(1)) {
            opacity = 0
        }

        // Reset state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isActive = false
        }
    }
}

// MARK: - Task Complete Celebration

struct TaskCompleteCelebration: View {
    @Binding var isActive: Bool
    let points: Int

    @State private var showGoldBurst = false
    @State private var showXP = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            GoldBurstEffect(isActive: $showGoldBurst)
            FloatingXPText(points: points, isActive: $showXP)
            SimpleConfetti(isActive: $showConfetti, particleCount: 30)
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerCelebration()
            }
        }
    }

    private func triggerCelebration() {
        HapticsService.shared.celebration()

        showGoldBurst = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showXP = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isActive = false
        }
    }
}

// MARK: - Rank Up Celebration (Circles)

struct RankUpCelebration: View {
    @Binding var isActive: Bool
    let oldRank: Int
    let newRank: Int

    @State private var showRankChange = false
    @State private var showSparkBurst = false
    @State private var sparkParticles: [SparkParticle] = []
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var numberScale: CGFloat = 2
    @State private var numberOpacity: Double = 0

    var body: some View {
        ZStack {
            // Spark burst
            ForEach(sparkParticles) { particle in
                SparkParticlePiece(particle: particle)
            }

            // Animated rings
            ForEach(0..<3, id: \.self) { i in
                SwiftUI.Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFD700").opacity(1 - Double(i) * 0.3),
                                Color(hex: "FFA500").opacity(1 - Double(i) * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3 - CGFloat(i)
                    )
                    .frame(width: (80 + CGFloat(i * 20)) * ringScale)
                    .opacity(ringOpacity)
            }

            // Rank number
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)

                HStack(spacing: 0) {
                    Text("#")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("\(newRank)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .contentTransition(.numericText())
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Text("Moved up \(oldRank - newRank) spot\(oldRank - newRank > 1 ? "s" : "")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .scaleEffect(numberScale)
            .opacity(numberOpacity)
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerRankUp()
            }
        }
    }

    private func triggerRankUp() {
        HapticsService.shared.celebration()

        // Generate spark particles
        sparkParticles = (0..<24).map { i in
            SparkParticle(
                id: i,
                angle: (Double(i) / 24) * 2 * .pi,
                distance: CGFloat.random(in: 80...140),
                delay: Double.random(in: 0...0.2)
            )
        }

        // Animate rings
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            ringScale = 1.2
            ringOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            ringOpacity = 0
        }

        // Animate number
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            numberScale = 1
            numberOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
            numberOpacity = 0
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isActive = false
            sparkParticles = []
            ringScale = 0.5
            numberScale = 2
        }
    }
}

struct SparkParticle: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let delay: Double
}

struct SparkParticlePiece: View {
    let particle: SparkParticle

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var trailLength: CGFloat = 20

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500").opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: trailLength)
            .rotationEffect(.radians(particle.angle + .pi / 2))
            .offset(
                x: cos(particle.angle) * offset,
                y: sin(particle.angle) * offset
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(particle.delay)) {
                    offset = particle.distance
                    trailLength = 30
                }
                withAnimation(.easeOut(duration: 0.3).delay(particle.delay + 0.4)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Milestone Toast

struct MilestoneToast: View {
    @Binding var isActive: Bool
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    @State private var slideOffset: CGFloat = -100
    @State private var opacity: Double = 0
    @State private var iconPulse: CGFloat = 0.8

    var body: some View {
        VStack {
            HStack(spacing: 16) {
                // Icon with glow
                ZStack {
                    SwiftUI.Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .blur(radius: 10)
                        .scaleEffect(1 + iconPulse * 0.2)

                    SwiftUI.Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(color)
                        .scaleEffect(iconPulse)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [color.opacity(0.5), color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal, 20)

            Spacer()
        }
        .offset(y: slideOffset)
        .opacity(opacity)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                showToast()
            }
        }
    }

    private func showToast() {
        HapticsService.shared.success()

        // Slide in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            slideOffset = 60  // Below safe area
            opacity = 1
        }

        // Icon pulse
        withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
            iconPulse = 1.1
        }

        // Slide out
        withAnimation(.easeInOut(duration: 0.4).delay(3)) {
            slideOffset = -100
            opacity = 0
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            isActive = false
            iconPulse = 0.8
        }
    }
}

// MARK: - Challenge Won Celebration

struct ChallengeWonCelebration: View {
    @Binding var isActive: Bool
    let xpEarned: Int

    @State private var showTrophy = false
    @State private var showConfetti = false
    @State private var trophyScale: CGFloat = 0
    @State private var trophyGlow: CGFloat = 0
    @State private var showXP = false

    var body: some View {
        ZStack {
            // Confetti
            SimpleConfetti(
                isActive: $showConfetti,
                particleCount: 80,
                colors: [
                    Color(hex: "FFD700"),
                    Color(hex: "FFA500"),
                    Color(hex: "8B5CF6"),
                    Color(hex: "10B981"),
                    Color(hex: "3B82F6")
                ]
            )

            // Trophy with glow
            ZStack {
                // Glow
                Image(systemName: "trophy.fill")
                    .font(.system(size: 100, weight: .medium))
                    .foregroundStyle(Color(hex: "FFD700"))
                    .blur(radius: 30)
                    .opacity(trophyGlow)

                // Trophy
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 20)
            }
            .scaleEffect(trophyScale)

            // XP
            FloatingXPText(points: xpEarned, isActive: $showXP)
                .offset(y: 80)
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerCelebration()
            }
        }
    }

    private func triggerCelebration() {
        HapticsService.shared.celebration()

        // Trophy entrance
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            trophyScale = 1
        }

        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            trophyGlow = 0.8
        }

        // Confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showConfetti = true
        }

        // XP
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showXP = true
        }

        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                trophyScale = 0
            }
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isActive = false
            trophyGlow = 0
        }
    }
}

// MARK: - Friend Request Accepted Celebration

struct FriendAcceptedCelebration: View {
    @Binding var isActive: Bool

    @State private var showBurst = false
    @State private var heartScale: CGFloat = 0
    @State private var heartGlow: CGFloat = 0
    @State private var showSparkles = false
    @State private var sparkles: [SparkleParticle] = []

    var body: some View {
        ZStack {
            // Sparkles
            ForEach(sparkles) { sparkle in
                SparklePiece(sparkle: sparkle)
            }

            // Heart with glow
            ZStack {
                // Glow
                Image(systemName: "heart.fill")
                    .font(.system(size: 70, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .blur(radius: 20)
                    .opacity(heartGlow)

                // Heart
                Image(systemName: "heart.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(heartScale)
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerCelebration()
            }
        }
    }

    private func triggerCelebration() {
        HapticsService.shared.success()

        // Generate sparkles
        sparkles = (0..<16).map { i in
            SparkleParticle(
                id: i,
                angle: (Double(i) / 16) * 2 * .pi,
                distance: CGFloat.random(in: 60...100),
                delay: Double.random(in: 0...0.15)
            )
        }

        // Heart entrance
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            heartScale = 1.3
        }

        withAnimation(.spring(response: 0.2).delay(0.2)) {
            heartScale = 1
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 0.8).repeatCount(2, autoreverses: true)) {
            heartGlow = 0.8
        }

        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                heartScale = 0
            }
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isActive = false
            sparkles = []
            heartGlow = 0
        }
    }
}

struct SparkleParticle: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let delay: Double
}

struct SparklePiece: View {
    let sparkle: SparkleParticle

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Theme.Colors.aiPurple)
            .rotationEffect(.degrees(rotation))
            .offset(
                x: cos(sparkle.angle) * offset,
                y: sin(sparkle.angle) * offset
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(sparkle.delay)) {
                    offset = sparkle.distance
                    rotation = 360
                }
                withAnimation(.easeOut(duration: 0.3).delay(sparkle.delay + 0.3)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Button("Confetti") {
                // Trigger confetti
            }

            Button("Gold Burst") {
                // Trigger gold burst
            }

            Button("Level Up") {
                // Trigger particle shower
            }
        }
    }
}

#Preview("Milestone Toast") {
    ZStack {
        Color.black.ignoresSafeArea()
        MilestoneToast(
            isActive: .constant(true),
            icon: "flame.fill",
            title: "7-Day Streak!",
            subtitle: "You're on fire! Keep it going.",
            color: .orange
        )
    }
}

#Preview("Rank Up") {
    ZStack {
        Color.black.ignoresSafeArea()
        RankUpCelebration(
            isActive: .constant(true),
            oldRank: 5,
            newRank: 3
        )
    }
}
