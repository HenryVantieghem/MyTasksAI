//
//  EnergyCore.swift
//  MyTasksAI
//
//  Energy Core - Power Meter Visualization
//  A glowing orb that fills based on task point potential
//  Replaces star ratings with an energy/power metaphor
//

import SwiftUI

// MARK: - Energy Core View

struct EnergyCore: View {
    let energyState: EnergyState
    let potentialPoints: Int
    let taskTypeColor: Color
    let isCompleted: Bool
    var size: CGFloat = DesignTokens.EnergyCore.size
    var onTap: (() -> Void)? = nil

    @State private var breathePhase: CGFloat = 0
    @State private var pulsePhase: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var isImploding: Bool = false
    @State private var completionScale: CGFloat = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack {
                // Outer glow layer
                outerGlow

                // Background ring
                backgroundRing

                // Energy fill orb
                energyOrb

                // Inner highlight
                innerHighlight

                // Orbiting particles (max energy only)
                if energyState.hasParticles && !reduceMotion && !isCompleted {
                    orbitingParticles
                }

                // Completion checkmark overlay
                if isCompleted {
                    completionCheckmark
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(isImploding ? 0.3 : completionScale)
        }
        .buttonStyle(.plain)
        .contentShape(SwiftUI.Circle())
        .onAppear {
            startAnimations()
        }
        .onChange(of: isCompleted) { _, completed in
            if completed {
                triggerCompletionAnimation()
            }
        }
        .accessibilityLabel("\(potentialPoints) potential points")
        .accessibilityHint("Tap to toggle completion")
    }

    // MARK: - Subviews

    private var outerGlow: some View {
        SwiftUI.Circle()
            .fill(glowColor.opacity(energyState.glowIntensity * glowMultiplier))
            .blur(radius: DesignTokens.EnergyCore.glowRadius + (pulsePhase * 4))
            .scaleEffect(1.3 + (pulsePhase * 0.15))
    }

    private var backgroundRing: some View {
        SwiftUI.Circle()
            .stroke(
                Theme.EnergyColors.ringInner,
                lineWidth: DesignTokens.EnergyCore.ringInnerWidth
            )
            .overlay(
                // Charged ring for high energy
                SwiftUI.Circle()
                    .stroke(
                        energyState == .high || energyState == .max
                            ? Theme.EnergyColors.ringCharged
                            : Color.clear,
                        lineWidth: DesignTokens.EnergyCore.ringOuterWidth
                    )
                    .scaleEffect(1.15)
                    .opacity(pulsePhase * 0.8)
            )
    }

    private var energyOrb: some View {
        SwiftUI.Circle()
            .fill(energyFillGradient)
            .mask(energyFillMask)
            .overlay(
                // Shimmer effect for high energy
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .clear,
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(rotationAngle * 0.5))
                    .opacity(energyState == .max ? 0.8 : 0.3)
            )
            .scaleEffect(1 + (breathePhase * 0.05))
    }

    private var energyFillMask: some View {
        GeometryReader { geo in
            let fillHeight = geo.size.height * energyState.fillPercentage

            VStack(spacing: 0) {
                // Empty space
                Color.clear
                    .frame(height: geo.size.height - fillHeight)

                // Filled area with wave effect
                Rectangle()
                    .fill(Color.white)
                    .frame(height: fillHeight)
                    .mask(
                        // Liquid wave effect at top
                        VStack(spacing: 0) {
                            WaveShape(phase: breathePhase * (CGFloat.pi * 2), amplitude: 2)
                                .fill(Color.white)
                                .frame(height: 6)
                            Rectangle()
                                .fill(Color.white)
                        }
                    )
            }
        }
        .clipShape(SwiftUI.Circle())
    }

    private var innerHighlight: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.4),
                        .white.opacity(0.1),
                        .clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: size * 0.6
                )
            )
            .scaleEffect(0.85)
            .offset(x: -size * 0.1, y: -size * 0.1)
    }

    private var orbitingParticles: some View {
        ForEach(0..<DesignTokens.EnergyCore.particleCount, id: \.self) { index in
            let angle = (Double(index) / Double(DesignTokens.EnergyCore.particleCount)) * 360 + rotationAngle
            let colorIndex = index % Theme.EnergyColors.particleColors.count

            SwiftUI.Circle()
                .fill(Theme.EnergyColors.particleColors[colorIndex])
                .frame(
                    width: DesignTokens.EnergyCore.particleSize,
                    height: DesignTokens.EnergyCore.particleSize
                )
                .shadow(color: Theme.EnergyColors.particleColors[colorIndex].opacity(0.8), radius: 4)
                .offset(
                    x: cos(angle * .pi / 180) * size * DesignTokens.EnergyCore.orbitRadius * 0.5,
                    y: sin(angle * .pi / 180) * size * DesignTokens.EnergyCore.orbitRadius * 0.5
                )
        }
    }

    private var completionCheckmark: some View {
        ZStack {
            // Success glow background
            SwiftUI.Circle()
                .fill(Theme.CelestialColors.successNebula.opacity(0.3))

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(Theme.CelestialColors.successNebula)
                .scaleEffect(completionScale)
        }
    }

    // MARK: - Computed Properties

    private var energyFillGradient: LinearGradient {
        switch energyState {
        case .low:
            return Theme.EnergyColors.lowFill
        case .medium:
            return Theme.EnergyColors.mediumFill
        case .high:
            return Theme.EnergyColors.highFill
        case .max:
            return Theme.EnergyColors.maxFill
        }
    }

    private var glowColor: Color {
        switch energyState {
        case .low: return Theme.EnergyColors.glowDim
        case .medium: return Theme.EnergyColors.glowMedium
        case .high: return Theme.EnergyColors.glowBright
        case .max: return Theme.EnergyColors.glowMax
        }
    }

    private var glowMultiplier: Double {
        if isCompleted { return 0.3 }
        return 1.0 + (pulsePhase * 0.3)
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Breathing animation (medium energy)
        if energyState.isBreathing || energyState == .low {
            withAnimation(
                .easeInOut(duration: DesignTokens.EnergyCore.breatheDuration)
                .repeatForever(autoreverses: true)
            ) {
                breathePhase = 1
            }
        }

        // Pulse animation (high/max energy)
        if energyState.isPulsing {
            withAnimation(
                .easeInOut(duration: DesignTokens.EnergyCore.pulseDuration)
                .repeatForever(autoreverses: true)
            ) {
                pulsePhase = 1
            }
        }

        // Particle orbit (max energy)
        if energyState.hasParticles {
            withAnimation(
                .linear(duration: DesignTokens.EnergyCore.orbitDuration)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
        }
    }

    private func triggerCompletionAnimation() {
        HapticsService.shared.success()

        // Implosion
        withAnimation(.easeIn(duration: DesignTokens.EnergyCore.implosionDuration)) {
            isImploding = true
        }

        // Bounce back with checkmark
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.EnergyCore.implosionDuration) {
            isImploding = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                completionScale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    completionScale = 1
                }
            }
        }
    }
}

// MARK: - Wave Shape

/// Liquid wave effect for the energy fill top edge
private struct WaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.height))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 4 + phase)
            let y = rect.height / 2 + amplitude * CGFloat(sine)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Energy Points Badge

/// Companion badge showing "+X" points potential
struct EnergyPointsBadge: View {
    let points: Int
    let energyState: EnergyState
    let isEarned: Bool

    @State private var glowPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            Text("+\(points)")
                .font(.system(size: 12, weight: .bold, design: .rounded))

            // Energy bolt icon
            Image(systemName: "bolt.fill")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(badgeTextColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeBackground)
        .clipShape(Capsule())
        .shadow(
            color: isEarned ? Theme.TaskCardColors.startHere.opacity(0.4 + glowPhase * 0.2) : .clear,
            radius: isEarned ? 6 + glowPhase * 2 : 0
        )
        .onAppear {
            if isEarned && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
            }
        }
    }

    private var badgeTextColor: Color {
        if isEarned {
            return .white
        }
        return Theme.CelestialColors.starDim
    }

    private var badgeBackground: some View {
        Group {
            if isEarned {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.TaskCardColors.startHere,
                                Theme.TaskCardColors.startHere.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Energy States") {
    VStack(spacing: 24) {
        Text("Energy Core States")
            .font(.headline)
            .foregroundStyle(.white)

        HStack(spacing: 32) {
            VStack {
                EnergyCore(
                    energyState: .low,
                    potentialPoints: 15,
                    taskTypeColor: Theme.TaskCardColors.coordinate,
                    isCompleted: false
                )
                Text("Low")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                EnergyPointsBadge(points: 15, energyState: .low, isEarned: false)
            }

            VStack {
                EnergyCore(
                    energyState: .medium,
                    potentialPoints: 35,
                    taskTypeColor: Theme.TaskCardColors.communicate,
                    isCompleted: false
                )
                Text("Medium")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                EnergyPointsBadge(points: 35, energyState: .medium, isEarned: false)
            }

            VStack {
                EnergyCore(
                    energyState: .high,
                    potentialPoints: 60,
                    taskTypeColor: Theme.TaskCardColors.create,
                    isCompleted: false
                )
                Text("High")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                EnergyPointsBadge(points: 60, energyState: .high, isEarned: false)
            }

            VStack {
                EnergyCore(
                    energyState: .max,
                    potentialPoints: 85,
                    taskTypeColor: Theme.TaskCardColors.consume,
                    isCompleted: false
                )
                Text("Max")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                EnergyPointsBadge(points: 85, energyState: .max, isEarned: true)
            }
        }

        Divider()
            .background(.white.opacity(0.2))

        Text("Completed State")
            .font(.headline)
            .foregroundStyle(.white)

        EnergyCore(
            energyState: .high,
            potentialPoints: 60,
            taskTypeColor: Theme.TaskCardColors.create,
            isCompleted: true,
            size: 36
        )
    }
    .padding(32)
    .background(Theme.CelestialColors.void)
}
