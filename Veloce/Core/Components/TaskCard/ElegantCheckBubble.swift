//
//  ElegantCheckBubble.swift
//  Veloce
//
//  Ultra-Premium Check Bubble - The Most Satisfying Checkbox
//  Features: Morphing ring, particle starburst, ripple wave, dopamine burst haptic
//

import SwiftUI

// MARK: - Elegant Check Bubble (Ultra-Premium Edition)

struct ElegantCheckBubble: View {
    let taskTypeColor: Color
    let isCompleted: Bool
    let onComplete: () -> Void

    @State private var isPressed = false
    @State private var completionPhase: CompletionPhase = .idle
    @State private var checkmarkProgress: CGFloat = 0
    @State private var particles: [BubbleParticle] = []

    // ✨ New premium animation states
    @State private var ringProgress: CGFloat = 0
    @State private var bounceScale: CGFloat = 1.0
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var sparkles: [SparkleParticle] = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let bubbleSize: CGFloat = 24
    private let borderWidth: CGFloat = 1.5

    enum CompletionPhase {
        case idle
        case filling
        case completed
    }

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Layer 0: Outer glow (success state)
                Circle()
                    .fill(Theme.CelestialColors.auroraGreen)
                    .frame(width: bubbleSize * 2.5, height: bubbleSize * 2.5)
                    .blur(radius: 12)
                    .opacity(glowOpacity * 0.4)

                // Layer 1: Ripple wave
                Circle()
                    .stroke(Theme.CelestialColors.auroraGreen.opacity(0.5), lineWidth: 2)
                    .frame(width: bubbleSize * rippleScale, height: bubbleSize * rippleScale)
                    .opacity(rippleOpacity)

                // Layer 2: Sparkle particles
                ForEach(sparkles) { sparkle in
                    Circle()
                        .fill(sparkle.color)
                        .frame(width: sparkle.size, height: sparkle.size)
                        .offset(x: sparkle.offset.width, y: sparkle.offset.height)
                        .opacity(sparkle.opacity)
                }

                // Layer 3: Main particle burst
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.offset.width, y: particle.offset.height)
                        .opacity(particle.opacity)
                }

                // Layer 4: Main bubble
                bubbleShape

                // Layer 5: Checkmark
                if completionPhase == .completed || isCompleted {
                    checkmark
                }
            }
            .frame(width: bubbleSize + 16, height: bubbleSize + 16)
            .scaleEffect(bounceScale)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isCompleted {
                        isPressed = true
                        HapticsService.shared.impact(.soft)
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .onAppear {
            if isCompleted {
                completionPhase = .completed
                checkmarkProgress = 1
                ringProgress = 1
            }
        }
        .onChange(of: isCompleted) { _, newValue in
            if newValue && completionPhase == .idle {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    completionPhase = .completed
                    checkmarkProgress = 1
                    ringProgress = 1
                }
            } else if !newValue {
                completionPhase = .idle
                checkmarkProgress = 0
                ringProgress = 0
                glowOpacity = 0
            }
        }
        .accessibilityLabel(isCompleted ? "Completed" : "Mark as complete")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Bubble Shape

    private var bubbleShape: some View {
        ZStack {
            // Background fill (animated on completion)
            Circle()
                .fill(fillColor)
                .frame(width: bubbleSize, height: bubbleSize)
                .scaleEffect(completionPhase == .filling ? 1.15 : 1.0)

            // Border ring
            Circle()
                .strokeBorder(
                    borderGradient,
                    lineWidth: borderWidth
                )
                .frame(width: bubbleSize, height: bubbleSize)

            // Pressed state overlay
            if isPressed {
                Circle()
                    .fill(taskTypeColor.opacity(0.3))
                    .frame(width: bubbleSize, height: bubbleSize)
            }
        }
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isPressed)
    }

    // MARK: - Checkmark

    private var checkmark: some View {
        CheckmarkShape()
            .trim(from: 0, to: checkmarkProgress)
            .stroke(
                checkmarkColor,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 10, height: 8)
            .offset(y: -0.5)
    }

    // MARK: - Computed Properties

    private var fillColor: Color {
        switch completionPhase {
        case .idle:
            return isPressed ? taskTypeColor.opacity(0.15) : Color.clear
        case .filling:
            return taskTypeColor
        case .completed:
            return isCompleted ? Theme.CelestialColors.auroraGreen : taskTypeColor
        }
    }

    private var borderGradient: LinearGradient {
        let color = isCompleted ? Theme.CelestialColors.auroraGreen : taskTypeColor
        return LinearGradient(
            colors: [color, color.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var checkmarkColor: Color {
        Theme.CelestialColors.void
    }

    // MARK: - Actions

    private func handleTap() {
        guard !isCompleted else { return }

        if reduceMotion {
            // Simplified completion for reduced motion
            HapticsService.shared.notification(.success)
            completionPhase = .completed
            checkmarkProgress = 1
            ringProgress = 1
            onComplete()
            return
        }

        // Ultra-premium animated completion sequence
        animateUltraPremiumCompletion()
    }

    private func animateUltraPremiumCompletion() {
        // Phase 1: Ring fill (0-150ms)
        withAnimation(.easeOut(duration: 0.15)) {
            ringProgress = 1.0
            completionPhase = .filling
        }

        // Phase 2: DOPAMINE BURST - The main event (150ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            // ✨ The magic haptic - pure euphoria
            HapticsService.shared.dopamineBurst()

            // Glow explosion
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                glowOpacity = 1.0
                completionPhase = .completed
            }

            // Bounce effect
            withAnimation(.spring(response: 0.12, dampingFraction: 0.35)) {
                bounceScale = 1.25
            }

            // Ripple wave
            withAnimation(.easeOut(duration: 0.45)) {
                rippleScale = 3.5
                rippleOpacity = 0.8
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
                rippleOpacity = 0
            }

            // Trigger all particle effects
            createUltraParticleBurst()
            createSparkles()
        }

        // Phase 3: Checkmark draw (180ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.2)) {
                checkmarkProgress = 1
            }
        }

        // Phase 4: Bounce settle (250ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                bounceScale = 1.0
            }
        }

        // Phase 5: Glow fade (500ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.35)) {
                glowOpacity = 0.25
            }
        }

        // Phase 6: Completion callback (200ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onComplete()
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            particles = []
            sparkles = []
        }
    }

    private func createUltraParticleBurst() {
        guard !reduceMotion else { return }

        let particleCount = 12
        var newParticles: [BubbleParticle] = []

        for i in 0..<particleCount {
            let angle = (Double(i) / Double(particleCount)) * 2 * .pi + Double.random(in: -0.2...0.2)
            let distance = CGFloat.random(in: 25...40)
            let particle = BubbleParticle(
                id: UUID(),
                color: i % 2 == 0 ? Theme.CelestialColors.auroraGreen : taskTypeColor,
                size: CGFloat.random(in: 3...6),
                offset: .zero,
                targetOffset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                opacity: 1.0
            )
            newParticles.append(particle)
        }

        particles = newParticles

        // Animate particles outward with easing
        withAnimation(.easeOut(duration: 0.4)) {
            for i in particles.indices {
                particles[i].offset = particles[i].targetOffset
            }
        }

        withAnimation(.easeOut(duration: 0.25).delay(0.15)) {
            for i in particles.indices {
                particles[i].opacity = 0
            }
        }
    }

    private func createSparkles() {
        guard !reduceMotion else { return }

        let sparkleCount = 8
        var newSparkles: [SparkleParticle] = []

        for i in 0..<sparkleCount {
            let angle = (Double(i) / Double(sparkleCount)) * 2 * .pi + .pi / Double(sparkleCount)
            let distance = CGFloat.random(in: 18...30)
            let sparkle = SparkleParticle(
                id: UUID(),
                color: .white,
                size: CGFloat.random(in: 2...4),
                offset: .zero,
                targetOffset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                opacity: 1.0,
                delay: Double.random(in: 0...0.08)
            )
            newSparkles.append(sparkle)
        }

        sparkles = newSparkles

        // Animate sparkles with slight delay
        for i in sparkles.indices {
            let delay = sparkles[i].delay
            withAnimation(.easeOut(duration: 0.35).delay(delay)) {
                sparkles[i].offset = sparkles[i].targetOffset
            }
            withAnimation(.easeOut(duration: 0.2).delay(delay + 0.2)) {
                sparkles[i].opacity = 0
            }
        }
    }
}

// MARK: - Checkmark Shape

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Draw checkmark: starts at left, goes down to bottom-center, then up to top-right
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.35, y: height))
        path.addLine(to: CGPoint(x: width, y: 0))

        return path
    }
}

// MARK: - Bubble Particle

struct BubbleParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var targetOffset: CGSize
    var opacity: Double
}

// MARK: - Sparkle Particle

struct SparkleParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var targetOffset: CGSize
    var opacity: Double
    var delay: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack(spacing: 32) {
            HStack(spacing: 24) {
                ElegantCheckBubble(
                    taskTypeColor: Theme.TaskCardColors.create,
                    isCompleted: false,
                    onComplete: { print("Completed!") }
                )

                ElegantCheckBubble(
                    taskTypeColor: Theme.TaskCardColors.communicate,
                    isCompleted: false,
                    onComplete: {}
                )

                ElegantCheckBubble(
                    taskTypeColor: Theme.TaskCardColors.consume,
                    isCompleted: false,
                    onComplete: {}
                )

                ElegantCheckBubble(
                    taskTypeColor: Theme.TaskCardColors.coordinate,
                    isCompleted: false,
                    onComplete: {}
                )
            }

            HStack(spacing: 24) {
                ElegantCheckBubble(
                    taskTypeColor: Theme.TaskCardColors.create,
                    isCompleted: true,
                    onComplete: {}
                )

                ElegantCheckBubble(
                    taskTypeColor: Theme.TaskCardColors.communicate,
                    isCompleted: true,
                    onComplete: {}
                )
            }
        }
    }
}
