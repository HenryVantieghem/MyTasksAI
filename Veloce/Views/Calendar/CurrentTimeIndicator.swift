//
//  CurrentTimeIndicator.swift
//  MyTasksAI
//
//  Current Time Indicator - The cosmic beacon
//  A pulsing NOW marker that guides the user through their day
//

import SwiftUI

// MARK: - Current Time Indicator

struct CurrentTimeIndicator: View {
    let height: CGFloat

    @State private var pulsePhase: CGFloat = 0
    @State private var glowIntensity: CGFloat = 0
    @State private var particlePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Celestial cyan - the signature color
    private let beaconColor = Color(red: 0.024, green: 0.714, blue: 0.831) // #06B6D4

    var body: some View {
        ZStack {
            // Vertical beam of light
            verticalBeam

            // Central beacon
            beacon

            // Floating particles
            if !reduceMotion {
                particles
            }

            // NOW label
            nowLabel
        }
        .frame(width: 80, height: height)
        .onAppear {
            guard !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Vertical Beam

    private var verticalBeam: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        beaconColor.opacity(0),
                        beaconColor.opacity(0.1 + glowIntensity * 0.1),
                        beaconColor.opacity(0.3 + glowIntensity * 0.2),
                        beaconColor.opacity(0.1 + glowIntensity * 0.1),
                        beaconColor.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2 + glowIntensity * 2)
            .blur(radius: 1 + glowIntensity)
    }

    // MARK: - Central Beacon

    private var beacon: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        beaconColor.opacity(0.2 - Double(ring) * 0.05),
                        lineWidth: 1
                    )
                    .frame(
                        width: 20 + CGFloat(ring) * 12 + pulsePhase * 8,
                        height: 20 + CGFloat(ring) * 12 + pulsePhase * 8
                    )
                    .blur(radius: CGFloat(ring) * 2)
            }

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            beaconColor,
                            beaconColor.opacity(0.5),
                            beaconColor.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20 + glowIntensity * 10
                    )
                )
                .frame(width: 40 + glowIntensity * 20, height: 40 + glowIntensity * 20)
                .blur(radius: 8)

            // Bright core
            Circle()
                .fill(beaconColor)
                .frame(width: 8, height: 8)
                .shadow(color: beaconColor, radius: 4 + glowIntensity * 4)

            // White hot center
            Circle()
                .fill(.white)
                .frame(width: 4, height: 4)
                .blur(radius: 1)
        }
        .scaleEffect(1 + pulsePhase * 0.05)
    }

    // MARK: - Floating Particles

    private var particles: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                TimeParticle(
                    index: index,
                    phase: particlePhase,
                    color: beaconColor
                )
            }
        }
    }

    // MARK: - NOW Label

    private var nowLabel: some View {
        VStack {
            Spacer()

            Text("NOW")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(beaconColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(beaconColor.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(beaconColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .offset(y: -20)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }

        // Glow intensity
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 1
        }

        // Particle orbit
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            particlePhase = 1
        }
    }
}

// MARK: - Time Particle

struct TimeParticle: View {
    let index: Int
    let phase: CGFloat
    let color: Color

    private var config: TimeParticleConfig {
        let seed = Double(index)
        let baseAngle = (seed / 6) * 2 * .pi
        let orbitRadius: CGFloat = 25 + CGFloat(sin(seed * 1.7)) * 10
        let size: CGFloat = 2 + CGFloat(sin(seed * 2.3))
        let speed = 0.8 + sin(seed * 1.3) * 0.4

        return TimeParticleConfig(
            baseAngle: baseAngle,
            orbitRadius: orbitRadius,
            size: size,
            speed: speed
        )
    }

    var body: some View {
        let cfg = config
        let currentAngle = cfg.baseAngle + Double(phase) * 2 * .pi * cfg.speed
        let x = cos(currentAngle) * cfg.orbitRadius
        let y = sin(currentAngle) * cfg.orbitRadius * 0.3 // Flattened orbit

        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0.3), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: cfg.size
                )
            )
            .frame(width: cfg.size * 2, height: cfg.size * 2)
            .offset(x: x, y: y)
            .blur(radius: 0.5)
    }
}

struct TimeParticleConfig {
    let baseAngle: Double
    let orbitRadius: CGFloat
    let size: CGFloat
    let speed: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        CurrentTimeIndicator(height: 300)
    }
}
