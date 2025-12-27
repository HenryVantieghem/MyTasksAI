//
//  ElegantCheckBubble.swift
//  Veloce
//
//  Things 3-style elegant open bubble checkbox
//  Clean, refined completion interaction
//

import SwiftUI

// MARK: - Elegant Check Bubble (Things 3 Style)

struct ElegantCheckBubble: View {
    let taskTypeColor: Color
    let isCompleted: Bool
    let onComplete: () -> Void

    @State private var isPressed = false
    @State private var completionPhase: CompletionPhase = .idle
    @State private var checkmarkProgress: CGFloat = 0
    @State private var particles: [BubbleParticle] = []

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
                // Particle burst layer
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.offset.width, y: particle.offset.height)
                        .opacity(particle.opacity)
                }

                // Main bubble
                bubbleShape

                // Checkmark
                if completionPhase == .completed || isCompleted {
                    checkmark
                }
            }
            .frame(width: bubbleSize + 16, height: bubbleSize + 16) // Tap target padding
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isCompleted {
                completionPhase = .completed
                checkmarkProgress = 1
            }
        }
        .onChange(of: isCompleted) { _, newValue in
            if newValue && completionPhase == .idle {
                // External completion triggered
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    completionPhase = .completed
                    checkmarkProgress = 1
                }
            } else if !newValue {
                completionPhase = .idle
                checkmarkProgress = 0
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

        // Haptic feedback
        HapticsService.shared.impact(.light)

        if reduceMotion {
            // Simplified completion for reduced motion
            completionPhase = .completed
            checkmarkProgress = 1
            onComplete()
            return
        }

        // Animated completion sequence
        animateCompletion()
    }

    private func animateCompletion() {
        // T+0ms: Fill begins
        withAnimation(.easeOut(duration: 0.1)) {
            completionPhase = .filling
        }

        // T+100ms: Scale bounce + checkmark starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                completionPhase = .completed
            }

            withAnimation(.easeOut(duration: 0.15)) {
                checkmarkProgress = 1
            }

            // Trigger particle burst
            createParticleBurst()
        }

        // T+200ms: Call completion callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onComplete()
        }
    }

    private func createParticleBurst() {
        guard !reduceMotion else { return }

        let particleCount = 6
        var newParticles: [BubbleParticle] = []

        for i in 0..<particleCount {
            let angle = (Double(i) / Double(particleCount)) * 2 * .pi
            let particle = BubbleParticle(
                id: UUID(),
                color: taskTypeColor.opacity(0.8),
                size: CGFloat.random(in: 2...4),
                offset: .zero,
                targetOffset: CGSize(
                    width: cos(angle) * 20,
                    height: sin(angle) * 20
                ),
                opacity: 1.0
            )
            newParticles.append(particle)
        }

        particles = newParticles

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.3)) {
            for i in particles.indices {
                particles[i].offset = particles[i].targetOffset
                particles[i].opacity = 0
            }
        }

        // Clean up particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            particles = []
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
