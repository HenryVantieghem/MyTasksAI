//
//  PointsAnimation.swift
//  Veloce
//
//  Points Animation
//  Floating +X XP animation for task completion
//

import SwiftUI

// MARK: - Points Animation State

struct PointsAnimationState: Identifiable {
    let id = UUID()
    let points: Int
    let position: CGPoint
    var isBonus: Bool = false
}

// MARK: - Floating Points View

struct FloatingPointsView: View {
    let points: Int
    let startPosition: CGPoint
    var isBonus: Bool = false
    @Binding var isVisible: Bool

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("+\(points) XP")
            .font(.system(size: isBonus ? 24 : 20, weight: .bold, design: .default))
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.Colors.xp, Theme.Colors.gold],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Theme.Colors.xp.opacity(0.5), radius: 8, x: 0, y: 2)
            .scaleEffect(scale)
            .offset(y: offset)
            .opacity(opacity)
            .position(startPosition)
            .onAppear {
                animate()
            }
    }

    private func animate() {
        if reduceMotion {
            // Instant for reduce motion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isVisible = false
            }
            return
        }

        // Scale up
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = isBonus ? 1.3 : 1.1
        }

        // Scale normalize
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8).delay(0.2)) {
            scale = 1.0
        }

        // Float up
        withAnimation(.easeOut(duration: 1.2)) {
            offset = -80
        }

        // Fade out
        withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
            opacity = 0
        }

        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isVisible = false
        }
    }
}

// MARK: - Points Animation Container

struct PointsAnimationContainer: View {
    @Binding var animations: [PointsAnimationState]

    var body: some View {
        ZStack {
            ForEach(animations) { animation in
                FloatingPointsView(
                    points: animation.points,
                    startPosition: animation.position,
                    isBonus: animation.isBonus,
                    isVisible: Binding(
                        get: { animations.contains(where: { $0.id == animation.id }) },
                        set: { visible in
                            if !visible {
                                animations.removeAll { $0.id == animation.id }
                            }
                        }
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Points Burst

struct PointsBurst: View {
    let points: Int
    @Binding var isVisible: Bool

    @State private var particles: [PointsParticle] = []
    @State private var mainScale: CGFloat = 0
    @State private var mainOpacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main points display
                VStack(spacing: 4) {
                    Text("+\(points)")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.xp, Theme.Colors.gold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("XP")
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .scaleEffect(mainScale)
                .opacity(mainOpacity)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // Particles
                ForEach(particles) { particle in
                    SwiftUI.Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                animate(in: geometry)
            }
        }
    }

    private func animate(in geometry: GeometryProxy) {
        // Main number animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            mainScale = 1.2
            mainOpacity = 1
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.3)) {
            mainScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.3).delay(1.5)) {
            mainOpacity = 0
        }

        // Create particles
        createParticles(in: geometry)

        // Dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isVisible = false
        }
    }

    private func createParticles(in geometry: GeometryProxy) {
        let colors: [Color] = [
            Theme.Colors.xp,
            Theme.Colors.gold,
            Theme.Colors.iridescentPink,
            Theme.Colors.iridescentCyan
        ]

        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2

        particles = (0..<12).map { i in
            let angle = Double(i) * (360.0 / 12.0)
            let radians = angle * .pi / 180
            let distance: CGFloat = 60

            return PointsParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                position: CGPoint(
                    x: centerX + cos(radians) * distance,
                    y: centerY + sin(radians) * distance
                ),
                opacity: 0.8
            )
        }

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.5)) {
            for i in particles.indices {
                let angle = Double(i) * (360.0 / 12.0)
                let radians = angle * .pi / 180
                let distance: CGFloat = 120

                particles[i].position = CGPoint(
                    x: centerX + cos(radians) * distance,
                    y: centerY + sin(radians) * distance
                )
            }
        }

        // Fade particles
        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
            for i in particles.indices {
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Points Particle

struct PointsParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        IridescentBackground(intensity: 0.4)

        VStack {
            FloatingPointsView(
                points: 10,
                startPosition: CGPoint(x: 200, y: 400),
                isVisible: .constant(true)
            )
        }
    }
}
