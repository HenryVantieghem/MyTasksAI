//
//  SingularityCore.swift
//  MyTasksAI
//
//  The central morphing orb of the AI consciousness animation
//  Starts as a point of light and expands with quantum fluctuation
//

import SwiftUI

// MARK: - Singularity Core

struct SingularityCore: View {
    let size: CGFloat
    let isActive: Bool

    @State private var rotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var glowIntensity: CGFloat = 0.5
    @State private var morphPhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let gradientColors = Theme.TaskCardColors.iridescent

    var body: some View {
        ZStack {
            // Outer glow halo
            outerGlow

            // Main orb with angular gradient
            mainOrb

            // Inner core with counter-rotation
            innerCore

            // Top highlight (3D effect)
            topHighlight

            // Center sparkle
            centerSparkle
        }
        .scaleEffect(scale)
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

    // MARK: - Outer Glow

    private var outerGlow: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Theme.TaskCardColors.strategy.opacity(0.5 * glowIntensity),
                        Theme.TaskCardColors.resources.opacity(0.3 * glowIntensity),
                        .clear
                    ],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.8
                )
            )
            .frame(width: size * 1.6, height: size * 1.6)
            .blur(radius: 8)
    }

    // MARK: - Main Orb

    private var mainOrb: some View {
        SwiftUI.Circle()
            .fill(
                AngularGradient(
                    colors: gradientColors + [gradientColors[0]],
                    center: .center,
                    startAngle: .degrees(rotation),
                    endAngle: .degrees(rotation + 360)
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 1)
            // Subtle morph effect using scale
            .scaleEffect(x: 1 + (sin(morphPhase * .pi * 2) * 0.03),
                        y: 1 + (cos(morphPhase * .pi * 2) * 0.03))
    }

    // MARK: - Inner Core

    private var innerCore: some View {
        SwiftUI.Circle()
            .fill(
                AngularGradient(
                    colors: gradientColors.reversed() + [gradientColors.last!],
                    center: .center,
                    startAngle: .degrees(innerRotation),
                    endAngle: .degrees(innerRotation + 360)
                )
            )
            .frame(width: size * 0.6, height: size * 0.6)
            .blur(radius: 2)
    }

    // MARK: - Top Highlight

    private var topHighlight: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.7),
                        Color.white.opacity(0.3),
                        .clear
                    ],
                    center: UnitPoint(x: 0.3, y: 0.3),
                    startRadius: 0,
                    endRadius: size * 0.25
                )
            )
            .frame(width: size * 0.5, height: size * 0.5)
            .offset(x: -size * 0.1, y: -size * 0.1)
    }

    // MARK: - Center Sparkle

    private var centerSparkle: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.3, weight: .light))
            .foregroundStyle(.white.opacity(0.8 + (glowIntensity * 0.2)))
            .rotationEffect(.degrees(rotation * 0.5))
    }

    // MARK: - Animation Control

    private func startAnimation() {
        guard !reduceMotion else {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1
                glowIntensity = 1
            }
            return
        }

        // Scale in with spring
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1
        }

        // Fast rotation (720 deg/sec feel)
        withAnimation(Theme.GeniusAnimation.singularityRotation) {
            rotation = 360
        }

        // Counter-rotation for inner core
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            innerRotation = -360
        }

        // Glow pulse
        withAnimation(Theme.GeniusAnimation.glowPulse) {
            glowIntensity = 1
        }

        // Morph phase
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            morphPhase = 1
        }
    }

    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.3
            glowIntensity = 0.5
        }
        rotation = 0
        innerRotation = 0
        morphPhase = 0
    }
}

// MARK: - Singularity Core Expanded (for bloom effect)

struct SingularityCoreExpanded: View {
    let size: CGFloat
    let expansion: CGFloat // 0 to 1, where 1 is fully expanded

    private let gradientColors = Theme.TaskCardColors.iridescent

    var body: some View {
        ZStack {
            // Shockwave ring
            SwiftUI.Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.TaskCardColors.startHere,
                            Theme.TaskCardColors.strategy
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3 * (1 - expansion)
                )
                .frame(width: size * (1 + expansion * 3), height: size * (1 + expansion * 3))
                .opacity(1 - expansion)

            // Core fade out
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.8 * (1 - expansion)),
                            Theme.TaskCardColors.strategy.opacity(0.5 * (1 - expansion)),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(1 + expansion * 0.5)
                .opacity(1 - expansion)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Singularity Core")
                .font(.headline)
                .foregroundStyle(.white)

            SingularityCore(size: 80, isActive: true)

            SingularityCoreExpanded(size: 60, expansion: 0.3)
        }
    }
}
