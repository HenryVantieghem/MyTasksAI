//
//  AmbientParticleField.swift
//  Veloce
//
//  Ambient Floating Particle Field
//  Gentle floating particles for atmospheric depth
//  Used in splash screen and auth backgrounds
//

import SwiftUI

// MARK: - Particle Density

enum ParticleDensity: Int {
    case sparse = 15
    case standard = 25
    case dense = 40
}

// MARK: - Ambient Particle

struct AmbientParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let driftSpeed: Double
    let swayAmplitude: CGFloat
    let swayFrequency: Double
    let color: Color
}

// MARK: - Ambient Particle Field

/// Floating ambient particles for atmospheric depth
struct AmbientParticleField: View {
    let density: ParticleDensity
    let colors: [Color]
    var bounds: CGSize = .zero

    @State private var particles: [AmbientParticle] = []
    @State private var animationPhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Default ethereal colors
    static let etherealColors: [Color] = [
        .white,
        Color(red: 0.75, green: 0.55, blue: 0.90), // softPurple
        Color(red: 0.55, green: 0.85, blue: 0.95), // softCyan
        Color(red: 0.95, green: 0.65, blue: 0.80), // softPink
    ]

    init(
        density: ParticleDensity = .standard,
        colors: [Color] = etherealColors,
        bounds: CGSize = .zero
    ) {
        self.density = density
        self.colors = colors
        self.bounds = bounds
    }

    var body: some View {
        GeometryReader { geometry in
            let effectiveBounds = bounds == .zero ? geometry.size : bounds

            Canvas { context, size in
                for particle in particles {
                    let phase = animationPhase * particle.driftSpeed

                    // Vertical drift (upward)
                    let driftY = particle.position.y - (phase * 50).truncatingRemainder(dividingBy: size.height + 100)
                    let wrappedY = driftY < -50 ? size.height + 50 + driftY : driftY

                    // Horizontal sway
                    let swayX = particle.position.x + sin(phase * particle.swayFrequency) * particle.swayAmplitude

                    // Opacity modulation
                    let twinkle = 0.7 + sin(phase * 2 + Double(particle.position.x)) * 0.3
                    let opacity = particle.baseOpacity * twinkle

                    // Draw particle
                    let rect = CGRect(
                        x: swayX - particle.size / 2,
                        y: wrappedY - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.opacity = opacity
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particle.color)
                    )

                    // Add subtle glow for larger particles
                    if particle.size > 2 {
                        let glowRect = CGRect(
                            x: swayX - particle.size,
                            y: wrappedY - particle.size,
                            width: particle.size * 2,
                            height: particle.size * 2
                        )
                        context.opacity = opacity * 0.3
                        context.fill(
                            Circle().path(in: glowRect),
                            with: .color(particle.color)
                        )
                    }
                }
            }
            .onAppear {
                generateParticles(in: effectiveBounds)
                if !reduceMotion {
                    startAnimation()
                }
            }
            .onChange(of: effectiveBounds) { _, newBounds in
                generateParticles(in: newBounds)
            }
        }
    }

    private func generateParticles(in bounds: CGSize) {
        guard bounds.width > 0, bounds.height > 0 else { return }

        particles = (0..<density.rawValue).map { index in
            // Golden ratio distribution (seed value used implicitly via index)
            _ = Double(index) * 1.618

            return AmbientParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: CGFloat.random(in: 0...bounds.height)
                ),
                size: CGFloat.random(in: 1...3),
                baseOpacity: Double.random(in: 0.2...0.5),
                driftSpeed: Double.random(in: 0.3...0.8),
                swayAmplitude: CGFloat.random(in: 5...20),
                swayFrequency: Double.random(in: 0.5...1.5),
                color: colors[index % colors.count]
            )
        }
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            animationPhase = 60
        }
    }
}

// MARK: - Ethereal Particle Burst

/// Particle burst effect for celebrations/transitions
struct EtherealParticleBurst: View {
    let center: CGPoint
    let colors: [Color]
    var particleCount: Int = 24

    @State private var particles: [BurstParticle] = []
    @State private var isAnimating = false

    struct BurstParticle: Identifiable {
        let id = UUID()
        let color: Color
        let size: CGFloat
        let angle: Double
        let distance: CGFloat
        var offset: CGSize = .zero
        var opacity: Double = 1.0
    }

    var body: some View {
        GeometryReader { geometry in
            let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: center.x + particle.offset.width - screenCenter.x,
                                y: center.y + particle.offset.height - screenCenter.y)
                        .opacity(particle.opacity)
                        .blur(radius: particle.size * 0.15)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            generateBurst()
            animateBurst()
        }
    }

    private func generateBurst() {
        particles = (0..<particleCount).map { index in
            let angle = (Double(index) / Double(particleCount)) * 2 * .pi
            let distance = CGFloat.random(in: 80...180)

            return BurstParticle(
                color: colors[index % colors.count],
                size: CGFloat.random(in: 4...12),
                angle: angle,
                distance: distance
            )
        }
    }

    private func animateBurst() {
        // Expand outward
        withAnimation(.easeOut(duration: 0.6)) {
            for index in particles.indices {
                let angle = particles[index].angle
                let distance = particles[index].distance
                particles[index].offset = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
            }
        }

        // Fade out
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            for index in particles.indices {
                particles[index].opacity = 0
            }
        }
    }
}

// MARK: - Floating Motes

/// Subtle floating motes that orbit around a center point
struct FloatingMotes: View {
    let centerSize: CGFloat
    let colors: [Color]
    var moteCount: Int = 8

    @State private var phase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<moteCount, id: \.self) { index in
                moteView(index: index)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = 12
            }
        }
    }

    private func moteView(index: Int) -> some View {
        let seed = Double(index) * 1.618
        let baseAngle = seed * .pi * 2 / Double(moteCount)
        let radius = centerSize * (0.40 + sin(seed * 2.1) * 0.10)
        let size = centerSize * (0.018 + sin(seed * 1.7) * 0.008)
        let speed = 0.5 + sin(seed * 1.3) * 0.3

        let currentAngle = baseAngle + phase * speed
        let x = cos(currentAngle) * radius
        let y = sin(currentAngle) * radius * 0.6 // Elliptical

        return Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.9),
                        colors[index % colors.count].opacity(0.4 + sin(phase * .pi + Double(index)) * 0.3),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size
                )
            )
            .frame(width: size * 2, height: size * 2)
            .offset(x: x, y: y)
            .blur(radius: size * 0.2)
    }
}

// MARK: - Previews

#Preview("Ambient Particle Field") {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        AmbientParticleField(density: .standard)
    }
}

#Preview("Ambient Particle Field - Dense") {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        AmbientParticleField(density: .dense)
    }
}

#Preview("Floating Motes") {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        FloatingMotes(
            centerSize: 200,
            colors: AmbientParticleField.etherealColors
        )
    }
}
