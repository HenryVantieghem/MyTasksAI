//
//  ConfettiBurst.swift
//  MyTasksAI
//
//  Celebration Animations
//  Confetti bursts for streaks, level ups, and special achievements
//

import SwiftUI

// MARK: - Confetti Burst

/// Full-screen confetti celebration
struct ConfettiBurst: View {
    let particleCount: Int
    let colors: [Color]
    let duration: Double

    @State private var particles: [BurstConfettiParticle] = []
    @State private var isAnimating = false

    init(
        particleCount: Int = 50,
        colors: [Color] = [
            Theme.Colors.iridescentPink,
            Theme.Colors.iridescentCyan,
            Theme.Colors.iridescentYellow,
            Theme.Colors.iridescentLavender,
            Theme.Colors.iridescentMint
        ],
        duration: Double = 2.5
    ) {
        self.particleCount = particleCount
        self.colors = colors
        self.duration = duration
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startAnimation()
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            BurstConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -50,
                targetY: size.height + 100,
                rotation: Double.random(in: 0...360),
                targetRotation: Double.random(in: 720...1440),
                scale: CGFloat.random(in: 0.5...1.2),
                color: colors.randomElement() ?? Theme.Colors.accent,
                shape: ConfettiShape.allCases.randomElement() ?? .rectangle,
                delay: Double.random(in: 0...0.5),
                horizontalDrift: CGFloat.random(in: -100...100)
            )
        }
    }

    private func startAnimation() {
        isAnimating = true

        // Trigger haptic
        HapticsService.shared.celebration()
    }
}

// MARK: - Confetti Particle (Burst version)

struct BurstConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var targetY: CGFloat
    var rotation: Double
    var targetRotation: Double
    var scale: CGFloat
    let color: Color
    let shape: ConfettiShape
    let delay: Double
    let horizontalDrift: CGFloat
}

enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
    case star
}

// MARK: - Confetti Piece View

struct ConfettiPiece: View {
    let particle: BurstConfettiParticle

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    @State private var hasStarted = false

    var body: some View {
        confettiShape
            .frame(width: 10 * particle.scale, height: 14 * particle.scale)
            .rotationEffect(.degrees(rotation))
            .rotation3DEffect(.degrees(rotation * 0.5), axis: (x: 1, y: 0, z: 0))
            .offset(x: particle.x + offset.width, y: particle.y + offset.height)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                    withAnimation(.easeOut(duration: 2.0)) {
                        offset = CGSize(
                            width: particle.horizontalDrift,
                            height: particle.targetY
                        )
                        rotation = particle.targetRotation
                    }

                    withAnimation(.easeIn(duration: 0.5).delay(1.5)) {
                        opacity = 0
                    }
                }
            }
    }

    @ViewBuilder
    private var confettiShape: some View {
        switch particle.shape {
        case .rectangle:
            RoundedRectangle(cornerRadius: 2)
                .fill(particle.color)
        case .circle:
            SwiftUI.Circle()
                .fill(particle.color)
        case .triangle:
            Triangle()
                .fill(particle.color)
        case .star:
            ConfettiStar(points: 4, innerRatio: 0.4)
                .fill(particle.color)
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Star Shape (Confetti version)

struct ConfettiStar: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio

        var path = Path()
        let pointCount = points * 2

        for i in 0..<pointCount {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CoreGraphics.cos(angle) * radius,
                y: center.y + CoreGraphics.sin(angle) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Streak Celebration

/// Specialized celebration for streak milestones
struct StreakCelebration: View {
    let streakDays: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var numberScale: CGFloat = 0.5

    private var streakTitle: String {
        switch streakDays {
        case 7: return "Week Streak!"
        case 30: return "Month Streak!"
        case 100: return "Century Streak!"
        case 365: return "Year Streak!"
        default: return "\(streakDays) Day Streak!"
        }
    }

    private var streakEmoji: String {
        switch streakDays {
        case 7: return "🎉"
        case 30: return "🏆"
        case 100: return "💎"
        case 365: return "👑"
        default: return "🔥"
        }
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Confetti
            if showConfetti {
                ConfettiBurst(
                    particleCount: streakDays >= 30 ? 80 : 50,
                    colors: streakDays >= 100 ? [
                        Theme.Colors.gold,
                        Theme.Colors.aiOrange,
                        Theme.Colors.iridescentYellow
                    ] : [
                        Theme.Colors.iridescentPink,
                        Theme.Colors.iridescentCyan,
                        Theme.Colors.iridescentYellow,
                        Theme.Colors.iridescentMint
                    ]
                )
            }

            // Content card
            if showContent {
                VStack(spacing: 24) {
                    // Emoji (decorative - fixed size is OK for emoji)
                    Text(streakEmoji)
                        .dynamicTypeFont(base: 72)
                        .scaleEffect(numberScale)
                        .accessibilityHidden(true)

                    // Streak number with fire
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.largeTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.fire, Theme.Colors.aiOrange],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .accessibilityHidden(true)

                        Text("\(streakDays)")
                            .font(.system(.largeTitle, design: .default, weight: .black))
                            .foregroundStyle(Theme.Colors.fire)
                            .accessibilityLabel("\(streakDays) day streak")
                    }

                    // Title
                    Text(streakTitle)
                        .font(.system(.title2, design: .default, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    // Subtitle
                    Text("You're on fire! Keep up the momentum.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)

                    // Dismiss button
                    Button {
                        dismiss()
                    } label: {
                        Text("Awesome!")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Colors.accent, Theme.Colors.aiOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                    .accessibilityLabel("Dismiss celebration")
                }
                .padding(32)
                .frame(maxWidth: 320)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Theme.Colors.aiOrange.opacity(0.3), radius: 30, y: 10)
                )
                .transition(.scale.combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Streak celebration! \(streakDays) day streak. \(streakTitle). You're on fire! Keep up the momentum.")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
                showConfetti = true
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
                numberScale = 1.0
            }

            // Special haptic pattern for milestones
            if streakDays >= 30 {
                HapticsService.shared.levelUp()
            } else {
                HapticsService.shared.celebration()
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showContent = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Simple Level Up Celebration

/// Simple celebration for leveling up
struct SimpleLevelUpCelebration: View {
    let newLevel: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var ringScale: CGFloat = 0.5
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Confetti with XP colors
            if showConfetti {
                ConfettiBurst(
                    particleCount: 60,
                    colors: [
                        Theme.Colors.xp,
                        Theme.Colors.aiPurple,
                        Theme.Colors.iridescentLavender,
                        Theme.Colors.aiBlue
                    ]
                )
            }

            // Content card
            if showContent {
                VStack(spacing: 20) {
                    // Level badge with rings
                    ZStack {
                        // Outer ring
                        SwiftUI.Circle()
                            .stroke(
                                LinearGradient(
                                    colors: Theme.Colors.aiGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(ringRotation))
                            .scaleEffect(ringScale)
                            .accessibilityHidden(true)

                        // Inner circle
                        SwiftUI.Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(ringScale)
                            .accessibilityHidden(true)

                        // Level number
                        Text("\(newLevel)")
                            .font(.system(.largeTitle, design: .default, weight: .black))
                            .foregroundStyle(.white)
                            .scaleEffect(ringScale)
                            .accessibilityLabel("Level \(newLevel)")
                    }

                    // Title
                    Text("Level Up!")
                        .font(.system(.title, design: .default, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .accessibilityAddTraits(.isHeader)

                    // Subtitle
                    Text("You've reached Level \(newLevel)!")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    // New perks unlocked (if any)
                    if newLevel % 5 == 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(Theme.Colors.aiOrange)
                            Text("New rewards unlocked!")
                                .font(Theme.Typography.callout)
                                .foregroundStyle(Theme.Colors.aiOrange)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.aiOrange.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    // Dismiss button
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                    .accessibilityLabel("Dismiss celebration")
                }
                .padding(32)
                .frame(maxWidth: 320)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Level up celebration! You've reached level \(newLevel). \(newLevel % 5 == 0 ? "New rewards unlocked!" : "")")
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Theme.Colors.aiPurple.opacity(0.3), radius: 30, y: 10)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
                showConfetti = true
            }

            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
                ringScale = 1.0
            }

            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            HapticsService.shared.levelUp()
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showContent = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Confetti Burst") {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        ConfettiBurst()
    }
}

#Preview("Streak Celebration") {
    StreakCelebration(streakDays: 30) {
        print("Dismissed")
    }
}

#Preview("Level Up Celebration") {
    SimpleLevelUpCelebration(newLevel: 10) {
        print("Dismissed")
    }
}
