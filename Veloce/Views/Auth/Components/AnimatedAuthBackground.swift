//
//  AnimatedAuthBackground.swift
//  Veloce
//
//  Animated Auth Background
//  Iridescent orbs with floating particles for auth screens
//

import SwiftUI

// MARK: - Animated Auth Background

struct AnimatedAuthBackground: View {
    @State private var phase: Double = 0
    @State private var particles: [FloatingParticle] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background
                Theme.Colors.background
                    .ignoresSafeArea()

                // Iridescent orbs
                ForEach(0..<3, id: \.self) { index in
                    IridescentOrb(size: geometry.size.width * CGFloat(0.8 - Double(index) * 0.15))
                        .offset(
                            x: reduceMotion ? 0 : cos(phase + Double(index) * .pi / 1.5) * 60,
                            y: reduceMotion ? CGFloat(index * 100 - 100) : sin(phase + Double(index) * .pi / 1.5) * 60 + CGFloat(index * 80 - 80)
                        )
                        .opacity(0.4 - Double(index) * 0.1)
                }

                // Floating particles
                if !reduceMotion {
                    ForEach(particles) { particle in
                        SwiftUI.Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .blur(radius: particle.size * 0.3)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startAnimations()
            }
        }
        .ignoresSafeArea()
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            FloatingParticle(
                x: CGFloat.random(in: -size.width/2...size.width/2),
                y: CGFloat.random(in: -size.height/2...size.height/2),
                size: CGFloat.random(in: 4...12),
                color: [Theme.Colors.aiPurple, Theme.Colors.aiBlue, Theme.Colors.aiCyan, Theme.Colors.aiPink].randomElement()!.opacity(0.3),
                opacity: Double.random(in: 0.2...0.5)
            )
        }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Orb animation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            phase = .pi * 2
        }

        // Particle drift
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].y -= 0.5
                particles[i].x += sin(particles[i].y * 0.01) * 0.3

                // Reset particles that go off screen
                if particles[i].y < -400 {
                    particles[i].y = 400
                    particles[i].x = CGFloat.random(in: -200...200)
                }
            }
        }
    }
}

// MARK: - Floating Particle

struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    var opacity: Double
}

// MARK: - Preview

#Preview {
    AnimatedAuthBackground()
}
