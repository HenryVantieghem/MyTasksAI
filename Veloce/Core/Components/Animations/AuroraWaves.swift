//
//  AuroraWaves.swift
//  MyTasksAI
//
//  Background atmosphere with radial waves emanating outward
//  Colors shift through AI palette with sine-wave distortion
//  Creates "ripple in space-time" effect
//

import SwiftUI

// MARK: - Aurora Waves

struct AuroraWaves: View {
    let size: CGFloat
    let isActive: Bool

    @State private var wavePhase: CGFloat = 0
    @State private var colorPhase: CGFloat = 0
    @State private var expansionPhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let waveCount = 5
    private let gradientColors = Theme.TaskCardColors.iridescent

    var body: some View {
        ZStack {
            ForEach(0..<waveCount, id: \.self) { index in
                waveRing(at: index)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isActive) { _, active in
            if active {
                startAnimation()
            } else {
                resetAnimation()
            }
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
    }

    // MARK: - Wave Ring

    private func waveRing(at index: Int) -> some View {
        let baseRadius = CGFloat(index + 1) / CGFloat(waveCount + 1)
        let waveOffset = CGFloat(index) * 0.2
        let distortedRadius = baseRadius + sin((wavePhase + waveOffset) * .pi * 2) * 0.03

        // Color shifting based on phase and index
        let colorIndex = Int((colorPhase * CGFloat(gradientColors.count) + CGFloat(index))) % gradientColors.count
        let nextColorIndex = (colorIndex + 1) % gradientColors.count
        let colorProgress = (colorPhase * CGFloat(gradientColors.count)).truncatingRemainder(dividingBy: 1)

        let waveColor = interpolateColor(
            from: gradientColors[colorIndex],
            to: gradientColors[nextColorIndex],
            progress: colorProgress
        )

        // Expansion effect - waves grow outward
        let expansionOffset = expansionPhase * 0.1 * CGFloat(index)

        return SwiftUI.Circle()
            .stroke(
                RadialGradient(
                    colors: [
                        waveColor.opacity(0.4 - Double(index) * 0.06),
                        waveColor.opacity(0.1)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * distortedRadius / 2
                ),
                lineWidth: 3 - CGFloat(index) * 0.4
            )
            .frame(
                width: size * (distortedRadius + expansionOffset),
                height: size * (distortedRadius + expansionOffset)
            )
            .blur(radius: 2 + CGFloat(index))
    }

    // MARK: - Color Interpolation

    private func interpolateColor(from: Color, to: Color, progress: CGFloat) -> Color {
        // Simple interpolation using opacity blend
        // In production, you'd extract RGB components
        return from.opacity(1 - progress)
    }

    // MARK: - Animation Control

    private func startAnimation() {
        guard !reduceMotion else {
            wavePhase = 0.5
            colorPhase = 0
            expansionPhase = 0.5
            return
        }

        // Wave distortion
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            wavePhase = 1
        }

        // Color cycling
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            colorPhase = 1
        }

        // Expansion pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            expansionPhase = 1
        }
    }

    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            wavePhase = 0
            colorPhase = 0
            expansionPhase = 0
        }
    }
}

// MARK: - Aurora Gradient Background

struct AuroraGradientBackground: View {
    let isActive: Bool

    @State private var gradientAngle: Double = 0
    @State private var intensity: CGFloat = 0.3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let colors = Theme.TaskCardColors.iridescent

    var body: some View {
        ZStack {
            // Base dark
            Color.black

            // Animated aurora gradient
            AngularGradient(
                colors: colors.map { $0.opacity(intensity) } + [colors[0].opacity(intensity)],
                center: .center,
                startAngle: .degrees(gradientAngle),
                endAngle: .degrees(gradientAngle + 360)
            )
            .blur(radius: 60)

            // Vignette overlay
            RadialGradient(
                colors: [.clear, .black.opacity(0.7)],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
        .onChange(of: isActive) { _, active in
            if active {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        guard !reduceMotion else {
            intensity = 0.5
            return
        }

        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            gradientAngle = 360
        }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            intensity = 0.5
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            intensity = 0.3
        }
    }
}

// MARK: - Cosmic Ripple Effect

struct CosmicRipple: View {
    let color: Color
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.8

    var body: some View {
        SwiftUI.Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1)) {
                    scale = 2
                    opacity = 0
                }
            }
    }
}

// MARK: - Space-Time Distortion

struct SpaceTimeDistortion: View {
    let size: CGFloat
    let isActive: Bool

    @State private var distortionPhase: CGFloat = 0

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let maxRadius = min(canvasSize.width, canvasSize.height) / 2

            for i in 0..<20 {
                let progress = CGFloat(i) / 20
                let baseRadius = progress * maxRadius

                // Apply sine distortion
                let distortedRadius = baseRadius + sin((distortionPhase + progress * 4) * .pi * 2) * 5

                var path = Path()
                path.addArc(
                    center: center,
                    radius: distortedRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360),
                    clockwise: false
                )

                let alpha = 0.3 * (1 - progress)
                context.stroke(
                    path,
                    with: .color(Theme.TaskCardColors.strategy.opacity(alpha)),
                    lineWidth: 1
                )
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isActive) { _, active in
            if active && !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    distortionPhase = 1
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AuroraGradientBackground(isActive: true)

        VStack(spacing: 40) {
            Text("Aurora Waves")
                .font(.headline)
                .foregroundStyle(.white)

            AuroraWaves(size: 200, isActive: true)
        }
    }
}
