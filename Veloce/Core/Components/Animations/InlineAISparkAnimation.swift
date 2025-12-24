//
//  InlineAISparkAnimation.swift
//  MyTasksAI
//
//  Compact "Synaptic Spark" animation for inline AI regeneration
//  32px orb with liquid morphing, galaxy swirl, and micro-messages
//  Duration: 2 seconds
//

import SwiftUI

// MARK: - Inline AI Spark Animation

struct InlineAISparkAnimation: View {
    let isActive: Bool
    let size: CGFloat
    let onComplete: (() -> Void)?

    @State private var morphPhase: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var glowPulse: CGFloat = 0.5
    @State private var starParticles: [AISparkParticle] = []
    @State private var currentMessageIndex: Int = 0
    @State private var messageOpacity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let messages = ["thinking", "analyzing", "strategizing", "✨"]
    private let gradientColors = Theme.TaskCardColors.iridescent

    init(
        isActive: Bool = true,
        size: CGFloat = 32,
        onComplete: (() -> Void)? = nil
    ) {
        self.isActive = isActive
        self.size = size
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 6) {
            // Main orb
            ZStack {
                // Glow halo
                glowHalo

                // Galaxy swirl background
                galaxySwirl

                // Morphing orb surface
                morphingOrb

                // Internal star particles
                starField

                // Center sparkle
                centerSparkle
            }
            .frame(width: size, height: size)

            // Micro-message
            Text(messages[currentMessageIndex])
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .opacity(messageOpacity)
        }
        .onChange(of: isActive) { _, active in
            if active {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onAppear {
            createAISparkParticles()
            if isActive {
                startAnimation()
            }
        }
    }

    // MARK: - Glow Halo

    private var glowHalo: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Theme.TaskCardColors.strategy.opacity(0.4 * glowPulse),
                        Theme.TaskCardColors.resources.opacity(0.2 * glowPulse),
                        .clear
                    ],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.8
                )
            )
            .frame(width: size * 1.5, height: size * 1.5)
            .blur(radius: 4)
    }

    // MARK: - Galaxy Swirl

    private var galaxySwirl: some View {
        SwiftUI.Circle()
            .fill(
                AngularGradient(
                    colors: gradientColors.map { $0.opacity(0.6) } + [gradientColors[0].opacity(0.6)],
                    center: .center,
                    startAngle: .degrees(rotationAngle),
                    endAngle: .degrees(rotationAngle + 360)
                )
            )
            .frame(width: size * 0.9, height: size * 0.9)
            .blur(radius: 3)
    }

    // MARK: - Morphing Orb

    private var morphingOrb: some View {
        // Liquid morphing shape using scale distortion
        let scaleX = 1 + sin(morphPhase * .pi * 2) * 0.08
        let scaleY = 1 + cos(morphPhase * .pi * 2) * 0.08

        return SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.9),
                        Theme.TaskCardColors.strategy.opacity(0.7),
                        Theme.TaskCardColors.resources.opacity(0.5)
                    ],
                    center: UnitPoint(x: 0.3, y: 0.3),
                    startRadius: 0,
                    endRadius: size * 0.4
                )
            )
            .frame(width: size * 0.7, height: size * 0.7)
            .scaleEffect(x: scaleX, y: scaleY)
            .blur(radius: 1)
    }

    // MARK: - Star Field

    private var starField: some View {
        ZStack {
            ForEach(starParticles) { particle in
                SwiftUI.Circle()
                    .fill(.white)
                    .frame(width: particle.size, height: particle.size)
                    .offset(particle.offset)
                    .opacity(particle.opacity)
            }
        }
        .frame(width: size * 0.6, height: size * 0.6)
        .rotationEffect(.degrees(rotationAngle * 0.5))
    }

    // MARK: - Center Sparkle

    private var centerSparkle: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.3, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .scaleEffect(0.8 + glowPulse * 0.4)
    }

    // MARK: - Star Particles

    private func createAISparkParticles() {
        starParticles = (0..<8).map { i in
            let angle = Double(i) / 8 * .pi * 2
            let distance = CGFloat.random(in: 3...10)
            return AISparkParticle(
                id: i,
                offset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                size: CGFloat.random(in: 1...2),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }

    // MARK: - Animation Control

    private func startAnimation() {
        if reduceMotion {
            glowPulse = 1
            return
        }

        // Morphing
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            morphPhase = 1
        }

        // Rotation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            glowPulse = 1
        }

        // Star particle twinkling
        animateAISparkParticles()

        // Message cycling
        startMessageCycle()
    }

    private func animateAISparkParticles() {
        guard !reduceMotion else { return }

        for i in starParticles.indices {
            let delay = Double(i) * 0.1
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(delay)) {
                starParticles[i].opacity = starParticles[i].opacity > 0.5 ? 0.3 : 0.8
            }
        }
    }

    private func startMessageCycle() {
        guard !reduceMotion else { return }

        func cycle() {
            guard isActive else { return }

            // Fade out
            withAnimation(.easeOut(duration: 0.15)) {
                messageOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count

                // Fade in
                withAnimation(.easeIn(duration: 0.15)) {
                    messageOpacity = 1
                }

                // Schedule next cycle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    cycle()
                }
            }
        }

        // Start first cycle after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            cycle()
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            glowPulse = 0.5
        }
        morphPhase = 0
        rotationAngle = 0
    }
}

// MARK: - Star Particle Model

struct AISparkParticle: Identifiable {
    let id: Int
    var offset: CGSize
    var size: CGFloat
    var opacity: Double
}

// MARK: - Inline Spark Modifier

struct InlineSparkModifier: ViewModifier {
    @Binding var isProcessing: Bool
    let size: CGFloat

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isProcessing ? 0.3 : 1)

            if isProcessing {
                InlineAISparkAnimation(isActive: true, size: size)
            }
        }
    }
}

extension View {
    func inlineAIProcessing(
        isProcessing: Binding<Bool>,
        size: CGFloat = 32
    ) -> some View {
        modifier(InlineSparkModifier(isProcessing: isProcessing, size: size))
    }
}

// MARK: - Mini Thinking Orb

/// Even smaller orb for tight spaces (like list rows)
struct MiniThinkingOrb: View {
    let isActive: Bool
    let size: CGFloat

    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1

    var body: some View {
        ZStack {
            // Glow
            SwiftUI.Circle()
                .fill(Theme.TaskCardColors.strategy.opacity(0.3))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 2)
                .scaleEffect(pulse)

            // Gradient ring
            SwiftUI.Circle()
                .stroke(
                    AngularGradient(
                        colors: Theme.TaskCardColors.iridescent,
                        center: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))

            // Center dot
            SwiftUI.Circle()
                .fill(.white)
                .frame(width: size * 0.3, height: size * 0.3)
        }
        .frame(width: size, height: size)
        .onChange(of: isActive) { _, active in
            if active && !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulse = 1.2
                }
            }
        }
        .onAppear {
            if isActive && !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulse = 1.2
                }
            }
        }
    }
}

// MARK: - AI Badge with Animation

struct AIBadgeAnimated: View {
    let isProcessing: Bool

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        HStack(spacing: 3) {
            if isProcessing {
                MiniThinkingOrb(isActive: true, size: 12)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .medium))
            }

            Text(isProcessing ? "AI" : "AI")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.TaskCardColors.strategy,
                            Theme.TaskCardColors.resources
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    // Shimmer effect when processing
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: isProcessing ? shimmerOffset * 30 : -30)
                        .mask(Capsule())
                )
        )
        .onChange(of: isProcessing) { _, processing in
            if processing && !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1
                }
            } else {
                shimmerOffset = -1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Inline AI Spark Animation")
                .font(.headline)
                .foregroundStyle(.white)

            InlineAISparkAnimation(isActive: true, size: 32)

            Divider()
                .background(.white.opacity(0.3))
                .padding(.horizontal, 40)

            Text("Mini Thinking Orb")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            MiniThinkingOrb(isActive: true, size: 20)

            Divider()
                .background(.white.opacity(0.3))
                .padding(.horizontal, 40)

            Text("AI Badge Animated")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 16) {
                AIBadgeAnimated(isProcessing: false)
                AIBadgeAnimated(isProcessing: true)
            }
        }
    }
}
