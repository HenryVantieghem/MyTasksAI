//
//  AppLogoView.swift
//  MyTasksAI
//
//  Animated Logo - Apple Intelligence inspired
//  A flowing orbital symbol suggesting infinite productivity
//

import SwiftUI

// MARK: - App Logo View

struct AppLogoView: View {
    let size: LogoSize
    var isAnimating: Bool = true
    var showParticles: Bool = true

    @State private var rotationPhase: Double = 0
    @State private var breathingPhase: Double = 0
    @State private var glowPhase: Double = 0
    @State private var particlePhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Outer glow layer
            if size.showGlow {
                outerGlow
            }

            // Particle system (large sizes only)
            if showParticles && size.showParticles && !reduceMotion {
                ParticleField(phase: particlePhase, size: size.dimension)
            }

            // Main logo shape
            logoShape

            // Inner highlight
            innerHighlight
        }
        .frame(width: size.dimension, height: size.dimension)
        .onAppear {
            guard isAnimating && !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Logo Shape

    private var logoShape: some View {
        TimelineView(.animation(minimumInterval: 1/60, paused: !isAnimating || reduceMotion)) { timeline in
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let radius = min(canvasSize.width, canvasSize.height) * 0.35
                let strokeWidth = radius * 0.18
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Create the infinity-orbital path
                let path = createOrbitalPath(center: center, radius: radius, time: time)

                // Gradient colors with animated rotation
                let gradientAngle = Angle(degrees: rotationPhase)
                let gradient = Gradient(colors: [
                    Color(hex: "8B5CF6"), // Purple
                    Color(hex: "6366F1"), // Indigo
                    Color(hex: "3B82F6"), // Blue
                    Color(hex: "0EA5E9"), // Sky
                    Color(hex: "06B6D4"), // Cyan
                    Color(hex: "14B8A6"), // Teal
                    Color(hex: "06B6D4"), // Cyan
                    Color(hex: "3B82F6"), // Blue
                    Color(hex: "8B5CF6"), // Purple
                ])

                // Draw the glowing stroke
                let shading = GraphicsContext.Shading.conicGradient(
                    gradient,
                    center: center,
                    angle: gradientAngle
                )

                // Outer glow stroke
                context.stroke(
                    path,
                    with: shading,
                    style: StrokeStyle(
                        lineWidth: strokeWidth + 4,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // Apply blur for glow effect
                context.addFilter(.blur(radius: strokeWidth * 0.5))
                context.stroke(
                    path,
                    with: shading,
                    style: StrokeStyle(
                        lineWidth: strokeWidth * 1.5,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // Reset filter for crisp main stroke
                context.addFilter(.blur(radius: 0))

                // Main stroke
                context.stroke(
                    path,
                    with: shading,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // Inner bright core
                context.blendMode = .plusLighter
                context.opacity = 0.4
                context.stroke(
                    path,
                    with: .color(.white),
                    style: StrokeStyle(
                        lineWidth: strokeWidth * 0.3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .scaleEffect(1.0 + breathingPhase * 0.03)
    }

    // MARK: - Outer Glow

    private var outerGlow: some View {
        ZStack {
            // Primary glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "8B5CF6").opacity(0.3 + glowPhase * 0.1),
                            Color(hex: "3B82F6").opacity(0.2 + glowPhase * 0.05),
                            Color(hex: "06B6D4").opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size.dimension * 0.2,
                        endRadius: size.dimension * 0.6
                    )
                )
                .frame(width: size.dimension * 1.4, height: size.dimension * 1.4)
                .blur(radius: size.dimension * 0.15)

            // Secondary atmospheric glow
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "8B5CF6").opacity(0.15),
                            Color(hex: "06B6D4").opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.dimension * 1.2, height: size.dimension * 0.8)
                .blur(radius: size.dimension * 0.2)
                .rotationEffect(.degrees(rotationPhase * 0.5))
        }
    }

    // MARK: - Inner Highlight

    private var innerHighlight: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.15 + glowPhase * 0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.dimension * 0.25
                )
            )
            .frame(width: size.dimension * 0.5, height: size.dimension * 0.5)
            .blur(radius: size.dimension * 0.05)
    }

    // MARK: - Path Creation

    private func createOrbitalPath(center: CGPoint, radius: CGFloat, time: TimeInterval) -> Path {
        var path = Path()

        // Create a flowing infinity-orbital shape
        // Inspired by Apple Intelligence but unique
        let segments = 200
        let flowSpeed = isAnimating && !reduceMotion ? time * 0.3 : 0

        for i in 0...segments {
            let t = Double(i) / Double(segments) * 2 * .pi

            // Lemniscate of Bernoulli (infinity curve) with orbital modulation
            let scale = radius
            let a = 1.0

            // Base infinity shape
            let denominator = 1 + pow(sin(t), 2)
            var x = a * cos(t) / denominator
            var y = a * sin(t) * cos(t) / denominator

            // Add flowing wave modulation
            let waveAmplitude = 0.08
            let waveFrequency = 3.0
            let wave = sin(t * waveFrequency + flowSpeed) * waveAmplitude

            // Apply wave perpendicular to the curve
            let normalX = -sin(t)
            let normalY = cos(t)
            x += normalX * wave
            y += normalY * wave

            // Scale and center
            let point = CGPoint(
                x: center.x + x * scale,
                y: center.y + y * scale
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

    // MARK: - Animations

    private func startAnimations() {
        // Gradient rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationPhase = 360
        }

        // Breathing scale
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breathingPhase = 1
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }

        // Particle phase
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            particlePhase = 1
        }
    }
}

// MARK: - Particle Field

struct ParticleField: View {
    let phase: Double
    let size: CGFloat

    private let particleCount = 12

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                ParticleView(
                    index: index,
                    totalCount: particleCount,
                    phase: phase,
                    fieldSize: size
                )
            }
        }
    }
}

struct ParticleView: View {
    let index: Int
    let totalCount: Int
    let phase: Double
    let fieldSize: CGFloat

    private var particleConfig: ParticleConfig {
        let seed = Double(index)
        let baseAngle = (seed / Double(totalCount)) * 2 * .pi
        let orbitRadius = fieldSize * (0.35 + sin(seed * 1.7) * 0.15)
        let particleSize = fieldSize * (0.02 + sin(seed * 2.3) * 0.01)
        let speed = 0.5 + sin(seed * 1.3) * 0.3
        let opacity = 0.4 + sin(seed * 2.1) * 0.3

        return ParticleConfig(
            baseAngle: baseAngle,
            orbitRadius: orbitRadius,
            particleSize: particleSize,
            speed: speed,
            opacity: opacity
        )
    }

    var body: some View {
        let config = particleConfig
        let currentAngle = config.baseAngle + phase * 2 * .pi * config.speed
        let x = cos(currentAngle) * config.orbitRadius
        let y = sin(currentAngle) * config.orbitRadius * 0.6 // Elliptical orbit

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(config.opacity),
                        Color(hex: "06B6D4").opacity(config.opacity * 0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: config.particleSize
                )
            )
            .frame(width: config.particleSize * 2, height: config.particleSize * 2)
            .offset(x: x, y: y)
            .blur(radius: config.particleSize * 0.3)
    }
}

struct ParticleConfig {
    let baseAngle: Double
    let orbitRadius: CGFloat
    let particleSize: CGFloat
    let speed: Double
    let opacity: Double
}

// MARK: - Logo Size

enum LogoSize {
    case tiny      // 24pt - Tab bar, small icons
    case small     // 40pt - Navigation, buttons
    case medium    // 80pt - Cards, headers
    case large     // 120pt - Splash, onboarding
    case hero      // 200pt - Auth screen hero

    var dimension: CGFloat {
        switch self {
        case .tiny: return 24
        case .small: return 40
        case .medium: return 80
        case .large: return 120
        case .hero: return 200
        }
    }

    var showGlow: Bool {
        switch self {
        case .tiny, .small: return false
        case .medium, .large, .hero: return true
        }
    }

    var showParticles: Bool {
        switch self {
        case .tiny, .small, .medium: return false
        case .large, .hero: return true
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            AppLogoView(size: .hero)

            HStack(spacing: 30) {
                AppLogoView(size: .large)
                AppLogoView(size: .medium)
            }

            HStack(spacing: 20) {
                AppLogoView(size: .small)
                AppLogoView(size: .tiny)
            }
        }
    }
}
