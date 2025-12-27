//
//  MilestoneCelebrationView.swift
//  Veloce
//
//  Full-screen celebration overlay for unlocking gems and reaching milestones
//  Confetti, gem reveal, XP animation
//

import SwiftUI

struct MilestoneCelebrationView: View {
    let milestone: MilestoneType
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var gemScale: CGFloat = 0
    @State private var gemRotation: Double = 0
    @State private var ringsScale: CGFloat = 0.5
    @State private var xpCounterValue: Int = 0
    @State private var confettiTrigger = false
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Confetti
            if confettiTrigger {
                ConfettiView(colors: milestone.confettiColors)
                    .ignoresSafeArea()
            }

            VStack(spacing: 32) {
                Spacer()

                // Celebration header
                if showContent {
                    Text(milestone.celebrationTitle)
                        .font(.system(size: 14, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(milestone.accentColor)
                        .textCase(.uppercase)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Gem/Achievement reveal
                ZStack {
                    // Expanding rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                milestone.accentColor.opacity(0.3 - Double(index) * 0.1),
                                lineWidth: 2
                            )
                            .frame(width: 140 + CGFloat(index) * 40, height: 140 + CGFloat(index) * 40)
                            .scaleEffect(ringsScale)
                    }

                    // Gem reveal
                    FocusGemView(
                        gemType: milestone.gemType,
                        isEarned: true,
                        size: 120
                    )
                    .scaleEffect(gemScale)
                    .rotation3DEffect(.degrees(gemRotation), axis: (x: 0, y: 1, z: 0))
                }
                .frame(height: 220)

                // Achievement name
                if showContent {
                    VStack(spacing: 8) {
                        Text(milestone.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(milestone.description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // XP Reward
                if showContent {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.aiAmber)

                        Text("+\(xpCounterValue)")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.aiAmber, Theme.Colors.aiOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .contentTransition(.numericText())

                        Text("XP")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(milestone.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .opacity(buttonOpacity)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            animateCelebration()
        }
    }

    // MARK: - Animation Sequence

    private func animateCelebration() {
        // 1. Ring expansion
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            ringsScale = 1.5
        }

        // 2. Gem pop
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
            gemScale = 1.0
        }

        // 3. Gem rotation flourish
        withAnimation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.3)) {
            gemRotation = 360
        }

        // 4. Content reveal
        withAnimation(.spring(response: 0.5).delay(0.5)) {
            showContent = true
        }

        // 5. Confetti burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            confettiTrigger = true
            HapticsService.shared.celebration()
        }

        // 6. XP counter animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            animateXPCounter()
        }

        // 7. Button appear
        withAnimation(.easeOut(duration: 0.3).delay(1.2)) {
            buttonOpacity = 1.0
        }
    }

    private func animateXPCounter() {
        let target = milestone.xpReward
        let duration: Double = 0.8
        let steps = 20
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                withAnimation(.none) {
                    xpCounterValue = Int(Double(target) * Double(step) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Milestone Type

enum MilestoneType {
    case gemUnlocked(FocusGemType)
    case streakMilestone(Int)
    case hoursMilestone(Int)

    var title: String {
        switch self {
        case .gemUnlocked(let gem):
            return gem.rawValue
        case .streakMilestone(let days):
            return "\(days)-Day Streak!"
        case .hoursMilestone(let hours):
            return "\(hours) Hours Focused!"
        }
    }

    var description: String {
        switch self {
        case .gemUnlocked(let gem):
            return gem.requirement
        case .streakMilestone(let days):
            return "You've maintained focus for \(days) consecutive days"
        case .hoursMilestone(let hours):
            return "You've accumulated \(hours) total hours of deep focus"
        }
    }

    var celebrationTitle: String {
        switch self {
        case .gemUnlocked:
            return "GEM UNLOCKED"
        case .streakMilestone:
            return "STREAK MILESTONE"
        case .hoursMilestone:
            return "HOURS MILESTONE"
        }
    }

    var gemType: FocusGemType {
        switch self {
        case .gemUnlocked(let gem):
            return gem
        case .streakMilestone(let days):
            if days >= 30 { return .diamond }
            else if days >= 7 { return .ruby }
            else { return .sapphire }
        case .hoursMilestone(let hours):
            if hours >= 100 { return .amethyst }
            else if hours >= 50 { return .emerald }
            else { return .sapphire }
        }
    }

    var accentColor: Color {
        gemType.color
    }

    var xpReward: Int {
        switch self {
        case .gemUnlocked(let gem):
            switch gem {
            case .sapphire: return 100
            case .emerald: return 250
            case .ruby: return 500
            case .diamond: return 1000
            case .amethyst: return 750
            }
        case .streakMilestone(let days):
            return days * 50
        case .hoursMilestone(let hours):
            return hours * 10
        }
    }

    var confettiColors: [Color] {
        [gemType.color, gemType.secondaryColor, .white, Theme.Colors.aiAmber]
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let colors: [Color]

    @State private var particles: [MilestoneConfettiParticle] = []

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x - particle.size / 2,
                    y: particle.position.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size * 0.6
                )

                context.rotate(by: particle.rotation)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 2),
                    with: .color(particle.color.opacity(particle.opacity))
                )
                context.rotate(by: -particle.rotation)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }

    private func generateParticles() {
        particles = (0..<60).map { _ in
            MilestoneConfettiParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 50...350),
                    y: -20
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -100...100),
                    y: CGFloat.random(in: 200...400)
                ),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 6...12),
                rotation: .degrees(Double.random(in: 0...360)),
                rotationSpeed: Double.random(in: -180...180),
                opacity: 1.0
            )
        }
    }

    private func animateParticles() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x / 60
                particles[i].position.y += particles[i].velocity.y / 60
                particles[i].velocity.y += 200 / 60 // gravity
                particles[i].rotation += .degrees(particles[i].rotationSpeed / 60)
                particles[i].opacity -= 0.005
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            timer.invalidate()
        }
    }
}

private struct MilestoneConfettiParticle {
    var position: CGPoint
    var velocity: CGPoint
    let color: Color
    let size: CGFloat
    var rotation: Angle
    let rotationSpeed: Double
    var opacity: Double
}

// MARK: - Preview

#Preview {
    MilestoneCelebrationView(
        milestone: .gemUnlocked(.ruby)
    ) {
        print("Dismissed")
    }
}
