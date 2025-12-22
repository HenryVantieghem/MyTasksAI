//
//  BloomCompletion.swift
//  MyTasksAI
//
//  Completion sequence animation - "The Bloom"
//  Shockwave expansion, particle scatter, ring shatter, starburst
//  Haptic crescendo with success notification
//

import SwiftUI

// MARK: - Bloom Completion

struct BloomCompletion: View {
    let size: CGFloat
    let onComplete: (() -> Void)?

    @State private var phase: BloomPhase = .idle
    @State private var shockwaveScale: CGFloat = 0.3
    @State private var shockwaveOpacity: Double = 1
    @State private var particleOffset: CGFloat = 0
    @State private var particleOpacity: Double = 1
    @State private var starburstScale: CGFloat = 0
    @State private var starburstRotation: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let gradientColors = Theme.TaskCardColors.iridescent
    private let particleCount = 16

    enum BloomPhase {
        case idle
        case anticipation
        case shockwave
        case scatter
        case starburst
        case checkmark
        case complete
    }

    var body: some View {
        ZStack {
            // Shockwave ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.TaskCardColors.startHere,
                            Theme.TaskCardColors.strategy
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4 * (1 - shockwaveScale / 3)
                )
                .frame(width: size * shockwaveScale, height: size * shockwaveScale)
                .opacity(shockwaveOpacity)

            // Inner shockwave glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.8),
                            Theme.TaskCardColors.startHere.opacity(0.5),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * shockwaveScale / 2
                    )
                )
                .frame(width: size * shockwaveScale * 0.8, height: size * shockwaveScale * 0.8)
                .opacity(shockwaveOpacity * 0.5)

            // Scatter particles
            ForEach(0..<particleCount, id: \.self) { index in
                scatterParticle(at: index)
            }

            // Starburst rays
            ForEach(0..<8, id: \.self) { index in
                starburstRay(at: index)
            }

            // Success checkmark
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Theme.TaskCardColors.startHere],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Theme.TaskCardColors.startHere.opacity(0.8), radius: 10)
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkOpacity)
        }
        .frame(width: size, height: size)
        .onAppear {
            startBloom()
        }
    }

    // MARK: - Scatter Particle

    private func scatterParticle(at index: Int) -> some View {
        let angle = Double(index) / Double(particleCount) * 360
        let color = gradientColors[index % gradientColors.count]
        let radians = angle * .pi / 180

        return Circle()
            .fill(
                RadialGradient(
                    colors: [.white, color],
                    center: .center,
                    startRadius: 0,
                    endRadius: 4
                )
            )
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.8), radius: 4)
            .offset(
                x: cos(radians) * particleOffset * size / 2,
                y: sin(radians) * particleOffset * size / 2
            )
            .opacity(particleOpacity)
    }

    // MARK: - Starburst Ray

    private func starburstRay(at index: Int) -> some View {
        let angle = Double(index) * 45 + starburstRotation

        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [.white, .white.opacity(0)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3, height: size * starburstScale * 0.4)
            .offset(y: -size * starburstScale * 0.2)
            .rotationEffect(.degrees(angle))
            .opacity(starburstScale > 0 ? 1 - starburstScale : 0)
    }

    // MARK: - Animation Sequence

    private func startBloom() {
        if reduceMotion {
            // Instant completion for reduced motion
            checkmarkScale = 1
            checkmarkOpacity = 1
            phase = .complete
            triggerSuccessHaptic()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete?()
            }
            return
        }

        phase = .anticipation

        // Brief pause for anticipation (100ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            triggerBuildingHaptic()
            startShockwave()
        }
    }

    private func startShockwave() {
        phase = .shockwave

        // Shockwave expands rapidly
        withAnimation(.easeOut(duration: 0.4)) {
            shockwaveScale = 3
            shockwaveOpacity = 0
        }

        // Start particle scatter slightly after shockwave begins
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startScatter()
        }
    }

    private func startScatter() {
        phase = .scatter

        // Particles fly outward
        withAnimation(.easeOut(duration: 0.5)) {
            particleOffset = 1.5
        }

        // Particles fade
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            particleOpacity = 0
        }

        // Start starburst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            startStarburst()
        }
    }

    private func startStarburst() {
        phase = .starburst
        triggerCrescendoHaptic()

        // Starburst expands and rotates
        withAnimation(.easeOut(duration: 0.4)) {
            starburstScale = 1
            starburstRotation = 45
        }

        // Show checkmark
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCheckmark()
        }
    }

    private func showCheckmark() {
        phase = .checkmark
        triggerSuccessHaptic()

        // Checkmark springs in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            checkmarkScale = 1
            checkmarkOpacity = 1
        }

        // Complete after checkmark settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            phase = .complete
            onComplete?()
        }
    }

    // MARK: - Haptic Feedback

    private func triggerBuildingHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func triggerCrescendoHaptic() {
        // Triple-tap crescendo
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            generator.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            generator.impactOccurred()
        }
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Mini Bloom (for inline completion)

struct MiniBloom: View {
    let color: Color
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1
    @State private var particleOffsets: [CGSize] = Array(repeating: .zero, count: 6)

    var body: some View {
        ZStack {
            // Central burst
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .scaleEffect(scale)
                .opacity(opacity)

            // Mini particles
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 3, height: 3)
                    .offset(particleOffsets[index])
                    .opacity(opacity)
            }
        }
        .onAppear {
            let angles = [0, 60, 120, 180, 240, 300].map { Double($0) * .pi / 180 }

            withAnimation(.easeOut(duration: 0.3)) {
                scale = 2
                for i in 0..<6 {
                    particleOffsets[i] = CGSize(
                        width: cos(angles[i]) * 15,
                        height: sin(angles[i]) * 15
                    )
                }
            }

            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Sparkle Explosion

struct SparkleExplosion: View {
    let count: Int
    let color: Color
    let size: CGFloat

    @State private var sparkles: [SparkleData] = []

    struct SparkleData: Identifiable {
        let id = UUID()
        var offset: CGSize = .zero
        var scale: CGFloat = 1
        var rotation: Double = 0
        var opacity: Double = 1
    }

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: 8))
                    .foregroundStyle(color)
                    .scaleEffect(sparkle.scale)
                    .rotationEffect(.degrees(sparkle.rotation))
                    .offset(sparkle.offset)
                    .opacity(sparkle.opacity)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            createSparkles()
            animateSparkles()
        }
    }

    private func createSparkles() {
        sparkles = (0..<count).map { _ in
            SparkleData()
        }
    }

    private func animateSparkles() {
        for i in sparkles.indices {
            let angle = Double.random(in: 0...360) * .pi / 180
            let distance = CGFloat.random(in: size * 0.3...size * 0.6)

            withAnimation(.easeOut(duration: Double.random(in: 0.4...0.7))) {
                sparkles[i].offset = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
                sparkles[i].scale = CGFloat.random(in: 0.5...1.5)
                sparkles[i].rotation = Double.random(in: -180...180)
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                sparkles[i].opacity = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            Text("Bloom Completion")
                .font(.headline)
                .foregroundStyle(.white)

            BloomCompletion(size: 150, onComplete: nil)
        }
    }
}
