//
//  OrbitingThoughtParticles.swift
//  MyTasksAI
//
//  Orbiting particle system with 8 particles in 2 tilted planes
//  Particles leave trails, speed up over time, and occasionally spark
//

import SwiftUI

// MARK: - Orbiting Thought Particles

struct OrbitingThoughtParticles: View {
    let radius: CGFloat
    let isActive: Bool
    let phase: CGFloat // 0 to 1 for animation progress

    @State private var rotationPlane1: Double = 0
    @State private var rotationPlane2: Double = 0
    @State private var sparkIndices: Set<Int> = []
    @State private var speedMultiplier: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let particleCount = 8
    private let particlesPerPlane = 4
    private let planeTilt1: Double = 15 // degrees
    private let planeTilt2: Double = -15 // degrees
    private let gradientColors = Theme.TaskCardColors.iridescent

    var body: some View {
        ZStack {
            // Plane 1 - tilted 15° forward
            ForEach(0..<particlesPerPlane, id: \.self) { index in
                particleWithTrail(
                    index: index,
                    rotation: rotationPlane1,
                    tilt: planeTilt1,
                    planeOffset: 0
                )
            }

            // Plane 2 - tilted 15° backward
            ForEach(0..<particlesPerPlane, id: \.self) { index in
                particleWithTrail(
                    index: index + particlesPerPlane,
                    rotation: rotationPlane2,
                    tilt: planeTilt2,
                    planeOffset: 45 // Offset by 45° from plane 1
                )
            }
        }
        .frame(width: radius * 2.5, height: radius * 2.5)
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

    // MARK: - Particle with Trail

    private func particleWithTrail(
        index: Int,
        rotation: Double,
        tilt: Double,
        planeOffset: Double
    ) -> some View {
        let baseAngle = (Double(index % particlesPerPlane) / Double(particlesPerPlane)) * 360 + planeOffset
        let currentAngle = baseAngle + rotation
        let isSparking = sparkIndices.contains(index)
        let particleColor = gradientColors[index % gradientColors.count]

        return ZStack {
            // Trail (3 fading copies behind)
            ForEach(1..<4) { trailIndex in
                let trailAngle = currentAngle - Double(trailIndex) * 15
                Circle()
                    .fill(particleColor.opacity(0.3 / Double(trailIndex)))
                    .frame(width: 4, height: 4)
                    .blur(radius: CGFloat(trailIndex))
                    .offset(particleOffset(angle: trailAngle, tilt: tilt))
            }

            // Main particle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, particleColor],
                        center: .center,
                        startRadius: 0,
                        endRadius: 3
                    )
                )
                .frame(width: 6, height: 6)
                .shadow(color: particleColor.opacity(0.8), radius: isSparking ? 8 : 2)
                .scaleEffect(isSparking ? 1.8 : 1.0)
                .offset(particleOffset(angle: currentAngle, tilt: tilt))

            // Spark burst when active
            if isSparking {
                SparkBurst(color: particleColor)
                    .offset(particleOffset(angle: currentAngle, tilt: tilt))
            }
        }
        .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0))
    }

    // MARK: - Calculate Particle Offset

    private func particleOffset(angle: Double, tilt: Double) -> CGSize {
        let radians = angle * .pi / 180
        let x = cos(radians) * radius
        let y = sin(radians) * radius * cos(tilt * .pi / 180) // Perspective compression
        return CGSize(width: x, height: y)
    }

    // MARK: - Animation Control

    private func startAnimation() {
        guard !reduceMotion else {
            rotationPlane1 = 0
            rotationPlane2 = 0
            return
        }

        // Speed ramp up over time
        withAnimation(.easeIn(duration: 1.0)) {
            speedMultiplier = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 1.5)) {
                speedMultiplier = 2.0
            }
        }

        // Plane 1 rotation (faster)
        withAnimation(.linear(duration: 2.5 / speedMultiplier).repeatForever(autoreverses: false)) {
            rotationPlane1 = 360
        }

        // Plane 2 rotation (slightly slower, opposite direction feel)
        withAnimation(.linear(duration: 3.0 / speedMultiplier).repeatForever(autoreverses: false)) {
            rotationPlane2 = -360
        }

        // Random sparks
        startRandomSparks()
    }

    private func startRandomSparks() {
        guard !reduceMotion else { return }

        func triggerSpark() {
            guard isActive else { return }

            let randomIndex = Int.random(in: 0..<particleCount)

            _ = withAnimation(.easeOut(duration: 0.1)) {
                sparkIndices.insert(randomIndex)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    _ = sparkIndices.remove(randomIndex)
                }
            }

            // Schedule next spark
            let delay = Double.random(in: 0.3...0.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                triggerSpark()
            }
        }

        // Start first spark after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            triggerSpark()
        }
    }

    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            speedMultiplier = 1.0
        }
        rotationPlane1 = 0
        rotationPlane2 = 0
        sparkIndices.removeAll()
    }
}

// MARK: - Spark Burst Effect

struct SparkBurst: View {
    let color: Color
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            // Main burst
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 20, height: 20)
                .scaleEffect(scale)
                .opacity(opacity)

            // Inner glow
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: 10, height: 10)
                .scaleEffect(scale * 0.8)
                .opacity(opacity)
                .blur(radius: 2)

            // Sparkle rays
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(color)
                    .frame(width: 1, height: 8)
                    .offset(y: -10 * scale)
                    .rotationEffect(.degrees(Double(index) * 90))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 2
                opacity = 0
            }
        }
    }
}

// MARK: - Thought Particle (Individual)

struct ThoughtParticle: View {
    let color: Color
    let size: CGFloat
    let hasSpark: Bool

    var body: some View {
        ZStack {
            // Glow halo
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: size * 2, height: size * 2)
                .blur(radius: size / 2)

            // Core particle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, color],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Orbiting Thought Particles")
                .font(.headline)
                .foregroundStyle(.white)

            OrbitingThoughtParticles(radius: 80, isActive: true, phase: 0.5)
        }
    }
}
