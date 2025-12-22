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
            Circle()
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
        Circle()
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
        Circle()
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
