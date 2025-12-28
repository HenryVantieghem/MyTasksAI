//
//  GlassCheckBubble.swift
//  Veloce
//
//  Ultra-Premium Glass Checkbox - iOS 26 Liquid Glass Edition
//  Features: Glass lensing effect, epic particle burst, ripple shockwave,
//  5-phase haptic crescendo, card-level celebration trigger
//

import SwiftUI

// MARK: - Glass Check Bubble (Liquid Glass Edition)

struct GlassCheckBubble: View {
    let taskTypeColor: Color
    let isCompleted: Bool
    let onComplete: () -> Void
    var onTriggerCardCelebration: (() -> Void)?

    // Animation states
    @State private var isPressed = false
    @State private var completionPhase: CompletionPhase = .idle
    @State private var fillProgress: CGFloat = 0
    @State private var checkmarkProgress: CGFloat = 0
    @State private var bounceScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0
    @State private var particles: [GlassParticle] = []
    @State private var ringShockwaveScale: CGFloat = 0.3
    @State private var ringShockwaveOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // Sizing
    private let bubbleSize: CGFloat = 28
    private let borderWidth: CGFloat = 1.5
    private let tapTargetSize: CGFloat = 44

    enum CompletionPhase: Int, CaseIterable {
        case idle = 0
        case anticipation = 1      // T+0ms: Press down
        case filling = 2           // T+50ms: Color fill
        case checkmarkDraw = 3     // T+100ms: Stroke animation
        case bounce = 4            // T+150ms: Scale overshoot
        case particleBurst = 5     // T+200ms: Particles fly
        case settle = 6            // T+350ms: Final state
    }

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Layer 0: Outer ambient glow
                outerGlow

                // Layer 1: Ring shockwave (on completion)
                ringShockwave

                // Layer 2: Particle burst
                particleLayer

                // Layer 3: Main glass bubble
                glassBubble

                // Layer 4: Checkmark
                if shouldShowCheckmark {
                    animatedCheckmark
                }
            }
            .frame(width: tapTargetSize, height: tapTargetSize)
            .scaleEffect(bounceScale)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(pressGesture)
        .onAppear(perform: syncWithCompletionState)
        .onChange(of: isCompleted, handleCompletionChange)
        .accessibilityLabel(isCompleted ? "Completed" : "Mark as complete")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isCompleted ? "Task is already completed" : "Double tap to mark as complete")
    }

    // MARK: - Outer Glow

    private var outerGlow: some View {
        Circle()
            .fill(glowColor)
            .frame(width: bubbleSize * 2.5, height: bubbleSize * 2.5)
            .blur(radius: 12)
            .opacity(glowIntensity * 0.5)
    }

    private var glowColor: Color {
        isCompleted ? Theme.CelestialColors.auroraGreen : taskTypeColor
    }

    // MARK: - Ring Shockwave

    private var ringShockwave: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [taskTypeColor, taskTypeColor.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3 * (1.0 - ringShockwaveScale / 4.0)
            )
            .frame(width: bubbleSize * ringShockwaveScale, height: bubbleSize * ringShockwaveScale)
            .opacity(ringShockwaveOpacity)
    }

    // MARK: - Particle Layer

    private var particleLayer: some View {
        ForEach(particles) { particle in
            particleView(for: particle)
        }
    }

    @ViewBuilder
    private func particleView(for particle: GlassParticle) -> some View {
        switch particle.shape {
        case .circle:
            Circle()
                .fill(particleGradient(for: particle))
                .frame(width: particle.size, height: particle.size)
                .offset(x: particle.offset.width, y: particle.offset.height)
                .opacity(particle.opacity)
                .blur(radius: particle.blur)

        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: particle.size * 0.8))
                .foregroundStyle(particle.color)
                .offset(x: particle.offset.width, y: particle.offset.height)
                .opacity(particle.opacity)
                .rotationEffect(.degrees(particle.rotation))

        case .sparkle:
            Image(systemName: "sparkle")
                .font(.system(size: particle.size))
                .foregroundStyle(particle.color)
                .offset(x: particle.offset.width, y: particle.offset.height)
                .opacity(particle.opacity)
                .rotationEffect(.degrees(particle.rotation))
        }
    }

    private func particleGradient(for particle: GlassParticle) -> RadialGradient {
        RadialGradient(
            colors: [.white, particle.color, particle.color.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: particle.size / 2
        )
    }

    // MARK: - Glass Bubble

    private var glassBubble: some View {
        ZStack {
            // Layer A: Glass material background
            glassBackground

            // Layer B: Fill progress (animated)
            fillLayer

            // Layer C: Gradient border
            gradientBorder

            // Layer D: Inner highlight (lensing effect)
            innerHighlight

            // Layer E: Press state overlay
            if isPressed {
                Circle()
                    .fill(taskTypeColor.opacity(0.25))
                    .frame(width: bubbleSize, height: bubbleSize)
            }
        }
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isPressed)
    }

    @ViewBuilder
    private var glassBackground: some View {
        if reduceTransparency {
            // Solid background for accessibility
            Circle()
                .fill(Theme.CelestialColors.abyss)
                .frame(width: bubbleSize, height: bubbleSize)
        } else {
            // Glass material
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: bubbleSize, height: bubbleSize)
        }
    }

    private var fillLayer: some View {
        Circle()
            .fill(fillColor)
            .frame(width: bubbleSize, height: bubbleSize)
            .scaleEffect(fillProgress)
            .opacity(fillProgress > 0 ? 1 : 0)
    }

    private var fillColor: Color {
        isCompleted ? Theme.CelestialColors.auroraGreen : taskTypeColor
    }

    private var gradientBorder: some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        (isCompleted ? Theme.CelestialColors.auroraGreen : taskTypeColor),
                        (isCompleted ? Theme.CelestialColors.auroraGreen : taskTypeColor).opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: borderWidth
            )
            .frame(width: bubbleSize, height: bubbleSize)
    }

    private var innerHighlight: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.white.opacity(0.15), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
            )
            .frame(width: bubbleSize - 4, height: bubbleSize - 4)
            .offset(x: -2, y: -2)
            .opacity(reduceTransparency ? 0 : 1)
    }

    // MARK: - Checkmark

    private var shouldShowCheckmark: Bool {
        completionPhase.rawValue >= CompletionPhase.checkmarkDraw.rawValue || isCompleted
    }

    private var animatedCheckmark: some View {
        CheckmarkShape()
            .trim(from: 0, to: checkmarkProgress)
            .stroke(
                Theme.CelestialColors.void,
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 11, height: 9)
            .offset(y: -0.5)
    }

    // MARK: - Gestures

    private var pressGesture: some Gesture {
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
    }

    // MARK: - State Management

    private func syncWithCompletionState() {
        if isCompleted {
            completionPhase = .settle
            checkmarkProgress = 1
            fillProgress = 1
            glowIntensity = 0.25
        }
    }

    private func handleCompletionChange(oldValue: Bool, newValue: Bool) {
        if newValue && completionPhase == .idle {
            // External completion - skip animation
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                completionPhase = .settle
                checkmarkProgress = 1
                fillProgress = 1
                glowIntensity = 0.25
            }
        } else if !newValue {
            // Reset to idle
            completionPhase = .idle
            checkmarkProgress = 0
            fillProgress = 0
            glowIntensity = 0
            ringShockwaveScale = 0.3
            ringShockwaveOpacity = 0
        }
    }

    // MARK: - Tap Handler

    private func handleTap() {
        guard !isCompleted else { return }

        if reduceMotion {
            performReducedMotionCompletion()
            return
        }

        animateEpicCompletion()
    }

    private func performReducedMotionCompletion() {
        HapticsService.shared.notification(.success)
        completionPhase = .settle
        checkmarkProgress = 1
        fillProgress = 1
        glowIntensity = 0.25
        onComplete()

        // Announce for VoiceOver
        announceCompletion()
    }

    // MARK: - Epic Completion Animation

    private func animateEpicCompletion() {
        // T+0ms: Anticipation phase
        completionPhase = .anticipation
        withAnimation(.easeOut(duration: 0.05)) {
            bounceScale = 0.92
        }
        HapticsService.shared.impact(.soft) // Phase 1: Soft anticipation tap

        // T+50ms: Fill animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            completionPhase = .filling
            withAnimation(.easeOut(duration: 0.1)) {
                fillProgress = 1.0
            }
        }

        // T+100ms: Checkmark stroke draw + medium haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completionPhase = .checkmarkDraw
            withAnimation(.easeOut(duration: 0.15)) {
                checkmarkProgress = 1.0
            }
            HapticsService.shared.impact(.medium) // Phase 2: Medium confirmation
        }

        // T+150ms: Bounce scale overshoot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            completionPhase = .bounce
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                bounceScale = 1.2
                glowIntensity = 1.0
            }
        }

        // T+200ms: Particle burst + ring shockwave + trigger card celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completionPhase = .particleBurst
            createEpicParticleBurst()
            animateRingShockwave()

            // Trigger card-level celebration
            onTriggerCardCelebration?()

            // Epic haptic crescendo (Phase 3-5)
            HapticsService.shared.epicTaskComplete()

            // Bounce settle
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                bounceScale = 1.0
            }
        }

        // T+350ms: Settle phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            completionPhase = .settle

            // Trigger completion callback
            onComplete()
        }

        // T+500ms: Glow fade to resting state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.35)) {
                glowIntensity = 0.25
            }
        }

        // Cleanup particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            particles = []
        }
    }

    // MARK: - Ring Shockwave Animation

    private func animateRingShockwave() {
        ringShockwaveOpacity = 1.0

        withAnimation(.easeOut(duration: 0.4)) {
            ringShockwaveScale = 4.0
        }

        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            ringShockwaveOpacity = 0
        }
    }

    // MARK: - Epic Particle Burst

    private func createEpicParticleBurst() {
        guard !reduceMotion else { return }

        let particleCount = 16
        let goldRatio: Double = 0.3 // 30% gold/iridescent, 70% task-type
        var newParticles: [GlassParticle] = []

        for i in 0..<particleCount {
            let angle = (Double(i) / Double(particleCount)) * 2 * .pi + Double.random(in: -0.15...0.15)
            let distance = CGFloat.random(in: 60...100)
            let isGold = Double(i) / Double(particleCount) < goldRatio

            let particle = GlassParticle(
                id: UUID(),
                shape: randomParticleShape(),
                color: isGold ? randomGoldColor() : taskTypeColor,
                size: CGFloat.random(in: 6...14),
                offset: .zero,
                targetOffset: CGSize(
                    width: CGFloat(cos(angle)) * distance,
                    height: CGFloat(sin(angle)) * distance
                ),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                blur: 0
            )
            newParticles.append(particle)
        }

        particles = newParticles

        // Animate particles outward with physics
        withAnimation(.easeOut(duration: 0.5)) {
            for i in particles.indices {
                particles[i].offset = particles[i].targetOffset
                particles[i].rotation += Double.random(in: -180...180)
            }
        }

        // Add gravity curve (particles fall slightly)
        withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
            for i in particles.indices {
                particles[i].offset.height += CGFloat.random(in: 20...40)
                particles[i].blur = 2
            }
        }

        // Fade out
        withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
            for i in particles.indices {
                particles[i].opacity = 0
            }
        }
    }

    private func randomParticleShape() -> GlassParticle.Shape {
        let random = Int.random(in: 0...10)
        if random < 5 { return .circle }
        if random < 8 { return .sparkle }
        return .star
    }

    private func randomGoldColor() -> Color {
        [
            Theme.Colors.gold,
            Theme.Colors.xp,
            Theme.CelestialLuminescence.celebrationGold,
            Theme.Colors.iridescentYellow
        ].randomElement() ?? Theme.Colors.gold
    }

    // MARK: - Accessibility

    private func announceCompletion() {
        let announcement = "Task completed"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// MARK: - Glass Particle Model

struct GlassParticle: Identifiable {
    let id: UUID
    let shape: Shape
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var targetOffset: CGSize
    var opacity: Double
    var rotation: Double
    var blur: CGFloat

    enum Shape {
        case circle
        case star
        case sparkle
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Glass Check Bubble")
                .font(Theme.Typography.cosmosTitle)
                .foregroundStyle(.white)

            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    GlassCheckBubble(
                        taskTypeColor: Theme.TaskCardColors.create,
                        isCompleted: false,
                        onComplete: { print("Create completed!") },
                        onTriggerCardCelebration: { print("Card celebration triggered!") }
                    )
                    Text("Create")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 8) {
                    GlassCheckBubble(
                        taskTypeColor: Theme.TaskCardColors.communicate,
                        isCompleted: false,
                        onComplete: {},
                        onTriggerCardCelebration: {}
                    )
                    Text("Communicate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 8) {
                    GlassCheckBubble(
                        taskTypeColor: Theme.TaskCardColors.consume,
                        isCompleted: false,
                        onComplete: {},
                        onTriggerCardCelebration: {}
                    )
                    Text("Consume")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 8) {
                    GlassCheckBubble(
                        taskTypeColor: Theme.TaskCardColors.coordinate,
                        isCompleted: false,
                        onComplete: {},
                        onTriggerCardCelebration: {}
                    )
                    Text("Coordinate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Completed States")
                .font(Theme.Typography.cosmosSectionHeader)
                .foregroundStyle(.secondary)

            HStack(spacing: 32) {
                GlassCheckBubble(
                    taskTypeColor: Theme.TaskCardColors.create,
                    isCompleted: true,
                    onComplete: {},
                    onTriggerCardCelebration: {}
                )

                GlassCheckBubble(
                    taskTypeColor: Theme.TaskCardColors.communicate,
                    isCompleted: true,
                    onComplete: {},
                    onTriggerCardCelebration: {}
                )
            }
        }
    }
}
