//
//  AuroraWaveBackground.swift
//  Veloce
//
//  Aurora Wave Background - Living, Flowing Light Ribbons
//  3-layer wave system that responds to app state
//

import SwiftUI

// MARK: - Aurora Wave Background

/// A living background of flowing aurora light ribbons
/// Responds to productivity state and time of day
public struct AuroraWaveBackground: View {

    // MARK: - State

    /// Intensity of the aurora effect (0.0 - 1.0)
    let intensity: CGFloat

    /// Whether to show ambient particles
    let showParticles: Bool

    /// Custom color override (defaults to time-of-day)
    let customColors: [Color]?

    /// Animation speed multiplier
    let speedMultiplier: CGFloat

    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    @State private var phase3: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initialization

    public init(
        intensity: CGFloat = 0.4,
        showParticles: Bool = true,
        customColors: [Color]? = nil,
        speedMultiplier: CGFloat = 1.0
    ) {
        self.intensity = intensity
        self.showParticles = showParticles
        self.customColors = customColors
        self.speedMultiplier = speedMultiplier
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base void gradient
                Aurora.Gradients.voidGradient
                    .ignoresSafeArea()

                if !reduceMotion {
                    // Layer 3 (Slowest, deepest)
                    waveLayer(
                        geometry: geometry,
                        phase: phase3,
                        amplitude: 100,
                        colors: waveColors.reversed(),
                        blur: Aurora.Blur.bloom,
                        opacity: intensity * 0.15
                    )

                    // Layer 2 (Medium)
                    waveLayer(
                        geometry: geometry,
                        phase: phase2,
                        amplitude: 80,
                        colors: waveColors,
                        blur: Aurora.Blur.auroraWave,
                        opacity: intensity * 0.25
                    )

                    // Layer 1 (Fastest, most prominent)
                    waveLayer(
                        geometry: geometry,
                        phase: phase1,
                        amplitude: 60,
                        colors: waveColors,
                        blur: Aurora.Blur.heavy,
                        opacity: intensity * 0.35
                    )

                    // Ambient particles
                    if showParticles {
                        AuroraStarField(count: Aurora.Particles.stars)
                            .opacity(intensity * 0.6)
                    }
                } else {
                    // Reduced motion: static gradient orbs
                    staticAuroraOrbs(geometry: geometry)
                }
            }
        }
    }

    // MARK: - Wave Colors

    private var waveColors: [Color] {
        customColors ?? Aurora.Gradients.timeOfDayAurora()
    }

    // MARK: - Wave Layer

    @ViewBuilder
    private func waveLayer(
        geometry: GeometryProxy,
        phase: CGFloat,
        amplitude: CGFloat,
        colors: [Color],
        blur: CGFloat,
        opacity: CGFloat
    ) -> some View {
        AuroraWaveShape(
            phase: phase,
            amplitude: amplitude,
            frequency: 1.5
        )
        .fill(
            LinearGradient(
                colors: colors.map { $0.opacity(opacity) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .blur(radius: blur)
        .blendMode(.screen)
        .frame(height: geometry.size.height * 0.6)
        .offset(y: geometry.size.height * 0.3)
    }

    // MARK: - Static Fallback

    @ViewBuilder
    private func staticAuroraOrbs(geometry: GeometryProxy) -> some View {
        ZStack {
            // Top-left orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [waveColors.first ?? Aurora.Colors.electricCyan, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -50)
                .opacity(intensity * 0.3)

            // Bottom-right orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [waveColors.last ?? Aurora.Colors.borealisViolet, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 150, y: geometry.size.height * 0.5)
                .opacity(intensity * 0.25)
        }
        .blur(radius: Aurora.Blur.heavy)
    }
}

// MARK: - Aurora Wave Shape

struct AuroraWaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let midHeight = height / 2

        path.move(to: CGPoint(x: 0, y: height))

        // Create wave using sine function
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * .pi * 2) + (phase * .pi * 2))
            let y = midHeight + (sine * amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Close the path
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Aurora Star Field

struct AuroraStarField: View {
    let count: Int

    @State private var stars: [AuroraStar] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(star.color)
                        .frame(width: star.size, height: star.size)
                        .opacity(star.opacity)
                        .position(star.position)
                        .blur(radius: star.size * 0.3)
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
            }
        }
    }

    private func generateStars(in size: CGSize) {
        stars = (0..<count).map { _ in
            AuroraStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...0.8),
                color: [
                    Aurora.Colors.stellarWhite,
                    Aurora.Colors.electricCyan.opacity(0.7),
                    Aurora.Colors.borealisViolet.opacity(0.5)
                ].randomElement()!
            )
        }
    }
}

struct AuroraStar: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let color: Color
}

// MARK: - Animated Wave Background

/// Wave background with automatic animation
public struct AuroraAnimatedWaveBackground: View {

    let intensity: CGFloat
    let showParticles: Bool
    let customColors: [Color]?

    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    @State private var phase3: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        intensity: CGFloat = 0.4,
        showParticles: Bool = true,
        customColors: [Color]? = nil
    ) {
        self.intensity = intensity
        self.showParticles = showParticles
        self.customColors = customColors
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base void
                Aurora.Colors.voidCosmos
                    .ignoresSafeArea()

                if !reduceMotion {
                    // Layer 3 - Slow
                    waveLayer(
                        geometry: geometry,
                        phase: phase3,
                        amplitude: 100,
                        blur: 80,
                        opacity: intensity * 0.15
                    )

                    // Layer 2 - Medium
                    waveLayer(
                        geometry: geometry,
                        phase: phase2,
                        amplitude: 80,
                        blur: 60,
                        opacity: intensity * 0.25
                    )

                    // Layer 1 - Fast
                    waveLayer(
                        geometry: geometry,
                        phase: phase1,
                        amplitude: 60,
                        blur: 40,
                        opacity: intensity * 0.35
                    )

                    // Stars
                    if showParticles {
                        AuroraStarField(count: Aurora.Particles.stars)
                            .opacity(0.5)
                    }
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private var waveColors: [Color] {
        customColors ?? Aurora.Gradients.timeOfDayAurora()
    }

    @ViewBuilder
    private func waveLayer(
        geometry: GeometryProxy,
        phase: CGFloat,
        amplitude: CGFloat,
        blur: CGFloat,
        opacity: CGFloat
    ) -> some View {
        AuroraWaveShape(phase: phase, amplitude: amplitude, frequency: 1.5)
            .fill(
                LinearGradient(
                    colors: waveColors.map { $0.opacity(opacity) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blur(radius: blur)
            .blendMode(.screen)
            .frame(height: geometry.size.height * 0.6)
            .offset(y: geometry.size.height * 0.3)
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Layer 1 - Fast (12s)
        withAnimation(
            .linear(duration: AuroraMotion.Duration.auroraWaveFast)
            .repeatForever(autoreverses: false)
        ) {
            phase1 = 1
        }

        // Layer 2 - Medium (18s)
        withAnimation(
            .linear(duration: AuroraMotion.Duration.auroraWaveMedium)
            .repeatForever(autoreverses: false)
        ) {
            phase2 = 1
        }

        // Layer 3 - Slow (25s)
        withAnimation(
            .linear(duration: AuroraMotion.Duration.auroraWaveSlow)
            .repeatForever(autoreverses: false)
        ) {
            phase3 = 1
        }
    }
}

// MARK: - Productivity State Extension

extension AuroraAnimatedWaveBackground {

    /// Create wave background based on productivity state
    public static func forProductivityState(
        taskCount: Int,
        completedToday: Int
    ) -> AuroraAnimatedWaveBackground {

        let intensity: CGFloat
        let colors: [Color]?

        if taskCount == 0 {
            // Empty - pure void with hints
            intensity = 0.15
            colors = [Aurora.Colors.borealisViolet.opacity(0.5)]
        } else if completedToday == 0 {
            // Low activity
            intensity = 0.25
            colors = [Aurora.Colors.borealisViolet, Aurora.Colors.deepPlasma]
        } else if completedToday < taskCount / 2 {
            // Active
            intensity = 0.4
            colors = nil // Time-of-day default
        } else {
            // High achievement
            intensity = 0.6
            colors = [
                Aurora.Colors.cosmicGold,
                Aurora.Colors.prismaticGreen,
                Aurora.Colors.electricCyan
            ]
        }

        return AuroraAnimatedWaveBackground(
            intensity: intensity,
            showParticles: true,
            customColors: colors
        )
    }
}

// MARK: - View Extension

extension View {

    /// Apply aurora wave background
    public func auroraWaveBackground(
        intensity: CGFloat = 0.4,
        showParticles: Bool = true
    ) -> some View {
        self.background(
            AuroraAnimatedWaveBackground(
                intensity: intensity,
                showParticles: showParticles
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Preview

#Preview("Aurora Wave Background") {
    ZStack {
        AuroraAnimatedWaveBackground(intensity: 0.5)

        VStack {
            Text("Aurora Waves")
                .font(Aurora.Typography.title1)
                .foregroundStyle(Aurora.Colors.textPrimary)

            Text("Living, breathing background")
                .font(Aurora.Typography.callout)
                .foregroundStyle(Aurora.Colors.textSecondary)
        }
    }
}

#Preview("Productivity States") {
    TabView {
        // Empty
        ZStack {
            AuroraAnimatedWaveBackground.forProductivityState(taskCount: 0, completedToday: 0)
            Text("Empty State").foregroundStyle(.white)
        }
        .tabItem { Text("Empty") }

        // Low
        ZStack {
            AuroraAnimatedWaveBackground.forProductivityState(taskCount: 5, completedToday: 0)
            Text("Low Activity").foregroundStyle(.white)
        }
        .tabItem { Text("Low") }

        // Active
        ZStack {
            AuroraAnimatedWaveBackground.forProductivityState(taskCount: 10, completedToday: 3)
            Text("Active").foregroundStyle(.white)
        }
        .tabItem { Text("Active") }

        // High
        ZStack {
            AuroraAnimatedWaveBackground.forProductivityState(taskCount: 10, completedToday: 8)
            Text("High Achievement").foregroundStyle(.white)
        }
        .tabItem { Text("High") }
    }
}
