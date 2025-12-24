//
//  CosmicFocusBackground.swift
//  Veloce
//
//  "Entering the Void" - Deep space focus background
//  Stars emerge as you focus, culminating in a supernova celebration
//

import SwiftUI

// MARK: - Cosmic Focus Background

/// The deep space background for focus mode
/// Stars slowly appear as timer runs, nebula glows pulse with breathing
struct CosmicFocusBackground: View {
    let progress: Double // 0.0 (just started) to 1.0 (complete)
    let isActive: Bool
    let isPaused: Bool

    @State private var stars: [FocusCosmicStar] = []
    @State private var nebulaPhase: Double = 0
    @State private var particlePhase: Double = 0
    @State private var breathingScale: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base void - absolute black
                Color(red: 0.01, green: 0.01, blue: 0.02)

                // Nebula layers
                nebulaLayer(in: geometry.size)

                // Star field
                starField(in: geometry.size)

                // Ambient particles (during focus)
                if isActive && !isPaused {
                    focusParticles(in: geometry.size)
                }

                // Central glow (intensifies with progress)
                centralGlow(in: geometry.size)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateStars()
            startAnimations()
        }
        .onChange(of: isActive) { _, active in
            if active {
                startAnimations()
            }
        }
    }

    // MARK: - Nebula Layer

    private func nebulaLayer(in size: CGSize) -> some View {
        ZStack {
            // Deep purple nebula - top right
            RadialGradient(
                colors: [
                    Color(red: 0.15, green: 0.05, blue: 0.25).opacity(0.4 * (0.3 + progress * 0.7)),
                    Color(red: 0.08, green: 0.02, blue: 0.15).opacity(0.2),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.15),
                startRadius: 0,
                endRadius: size.width * 0.6
            )

            // Amber nebula - bottom left (focus energy)
            RadialGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.05).opacity(0.3 * (0.2 + progress * 0.8)),
                    Color(red: 0.2, green: 0.1, blue: 0.02).opacity(0.15),
                    Color.clear
                ],
                center: UnitPoint(x: 0.2, y: 0.85),
                startRadius: 0,
                endRadius: size.width * 0.5
            )

            // Cyan nebula accent - center right
            RadialGradient(
                colors: [
                    Color(red: 0.05, green: 0.2, blue: 0.3).opacity(0.25 * progress),
                    Color.clear
                ],
                center: UnitPoint(x: 0.9, y: 0.5),
                startRadius: 0,
                endRadius: size.width * 0.4
            )
            .scaleEffect(breathingScale)
        }
    }

    // MARK: - Star Field

    private func starField(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            for star in stars {
                // Only show stars based on progress
                guard star.appearanceThreshold <= progress else { continue }

                let fadeIn = min(1.0, (progress - star.appearanceThreshold) / 0.1)
                let twinkle = star.isBright ? (0.7 + 0.3 * sin(nebulaPhase * star.twinkleSpeed)) : 1.0
                let opacity = star.baseOpacity * fadeIn * twinkle

                let starPath = Path(ellipseIn: CGRect(
                    x: star.position.x * canvasSize.width - star.size / 2,
                    y: star.position.y * canvasSize.height - star.size / 2,
                    width: star.size,
                    height: star.size
                ))

                // Star glow for bright stars
                if star.isBright && opacity > 0.3 {
                    context.fill(
                        starPath.strokedPath(StrokeStyle(lineWidth: star.size * 2)),
                        with: .color(star.color.opacity(opacity * 0.3))
                    )
                }

                context.fill(starPath, with: .color(star.color.opacity(opacity)))
            }
        }
    }

    // MARK: - Focus Particles

    private func focusParticles(in size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Particles drift inward toward center
                for i in 0..<20 {
                    let baseAngle = Double(i) / 20.0 * .pi * 2
                    let angle = baseAngle + time * 0.1
                    let radius = 0.3 + 0.2 * sin(time * 0.5 + Double(i))

                    let x = 0.5 + cos(angle) * radius
                    let y = 0.5 + sin(angle) * radius

                    let particleSize: CGFloat = 2 + CGFloat(sin(time + Double(i))) * 1
                    let opacity = 0.3 + 0.2 * sin(time * 2 + Double(i))

                    let particlePath = Path(ellipseIn: CGRect(
                        x: x * canvasSize.width - particleSize / 2,
                        y: y * canvasSize.height - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    ))

                    let color = i % 2 == 0
                        ? Color(red: 0.96, green: 0.62, blue: 0.14) // Amber
                        : Color(red: 0.18, green: 0.82, blue: 0.92) // Cyan

                    context.fill(particlePath, with: .color(color.opacity(opacity * progress)))
                }
            }
        }
    }

    // MARK: - Central Glow

    private func centralGlow(in size: CGSize) -> some View {
        ZStack {
            // Warm amber glow
            RadialGradient(
                colors: [
                    Color(red: 0.96, green: 0.62, blue: 0.14).opacity(0.15 * (0.3 + progress * 0.7)),
                    Color(red: 0.96, green: 0.4, blue: 0.1).opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: min(size.width, size.height) * 0.5
            )
            .scaleEffect(breathingScale)

            // Subtle cyan ring
            Circle()
                .stroke(
                    RadialGradient(
                        colors: [
                            Color(red: 0.18, green: 0.82, blue: 0.92).opacity(0.1 * progress),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 200
                    ),
                    lineWidth: 40
                )
                .frame(width: 300, height: 300)
                .blur(radius: 30)
        }
    }

    // MARK: - Star Generation

    private func generateStars() {
        stars = (0..<80).map { i in
            let isBright = i < 15
            return FocusCosmicStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1)
                ),
                size: isBright ? CGFloat.random(in: 2...4) : CGFloat.random(in: 1...2),
                baseOpacity: isBright ? Double.random(in: 0.6...1.0) : Double.random(in: 0.2...0.5),
                color: starColor(for: i),
                appearanceThreshold: Double(i) / 80.0 * 0.8, // Stars appear throughout session
                twinkleSpeed: Double.random(in: 1...3),
                isBright: isBright
            )
        }
    }

    private func starColor(for index: Int) -> Color {
        switch index % 5 {
        case 0: return .white
        case 1: return Color(red: 1.0, green: 0.95, blue: 0.8) // Warm white
        case 2: return Color(red: 0.8, green: 0.9, blue: 1.0) // Cool white
        case 3: return Color(red: 0.96, green: 0.62, blue: 0.14) // Amber
        default: return Color(red: 0.18, green: 0.82, blue: 0.92) // Cyan
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Nebula breathing
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathingScale = 1.05
        }

        // Star twinkle phase
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            nebulaPhase += 0.05
        }
    }
}

// MARK: - Cosmic Star Model

struct FocusCosmicStar: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let color: Color
    let appearanceThreshold: Double // 0-1, when star appears based on progress
    let twinkleSpeed: Double
    let isBright: Bool
}

// MARK: - Supernova Celebration Background

/// Explosive celebration when focus session completes
struct SupernovaCelebrationBackground: View {
    @State private var explosionPhase: Double = 0
    @State private var ringExpansion: CGFloat = 0
    @State private var particleOpacity: Double = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base still shows through
                Color(red: 0.01, green: 0.01, blue: 0.02)

                // Explosion rings
                ForEach(0..<5) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.96, green: 0.62, blue: 0.14),
                                    Color(red: 0.18, green: 0.82, blue: 0.92),
                                    Color(red: 0.58, green: 0.25, blue: 0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3 - CGFloat(i) * 0.5
                        )
                        .frame(
                            width: 50 + ringExpansion * CGFloat(1 + i * 0.3),
                            height: 50 + ringExpansion * CGFloat(1 + i * 0.3)
                        )
                        .opacity(particleOpacity * (1 - Double(i) * 0.15))
                }

                // Central flash
                RadialGradient(
                    colors: [
                        Color.white.opacity(particleOpacity * 0.8),
                        Color(red: 0.96, green: 0.62, blue: 0.14).opacity(particleOpacity * 0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100 + ringExpansion * 0.3
                )

                // Particle burst
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)

                    for i in 0..<40 {
                        let angle = Double(i) / 40 * .pi * 2
                        let distance = ringExpansion * CGFloat.random(in: 0.3...1.0)

                        let x = center.x + cos(angle) * distance
                        let y = center.y + sin(angle) * distance

                        let particleSize: CGFloat = CGFloat.random(in: 2...6)

                        let particlePath = Path(ellipseIn: CGRect(
                            x: x - particleSize / 2,
                            y: y - particleSize / 2,
                            width: particleSize,
                            height: particleSize
                        ))

                        let colors: [Color] = [
                            .white,
                            Color(red: 0.96, green: 0.62, blue: 0.14),
                            Color(red: 0.18, green: 0.82, blue: 0.92),
                            Color(red: 0.98, green: 0.82, blue: 0.35)
                        ]

                        context.fill(
                            particlePath,
                            with: .color(colors[i % colors.count].opacity(particleOpacity))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            triggerSupernova()
        }
    }

    private func triggerSupernova() {
        // Rapid expansion
        withAnimation(.easeOut(duration: 1.0)) {
            ringExpansion = 400
        }

        // Fade out after peak
        withAnimation(.easeIn(duration: 0.8).delay(0.8)) {
            particleOpacity = 0
        }
    }
}

// MARK: - Preview

#Preview("Cosmic Background - Idle") {
    CosmicFocusBackground(progress: 0, isActive: false, isPaused: false)
}

#Preview("Cosmic Background - Midway") {
    CosmicFocusBackground(progress: 0.5, isActive: true, isPaused: false)
}

#Preview("Cosmic Background - Complete") {
    CosmicFocusBackground(progress: 1.0, isActive: true, isPaused: false)
}

#Preview("Supernova Celebration") {
    SupernovaCelebrationBackground()
}
