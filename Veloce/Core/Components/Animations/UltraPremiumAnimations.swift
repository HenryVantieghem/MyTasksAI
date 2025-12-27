//
//  UltraPremiumAnimations.swift
//  Veloce
//
//  Ultra-Premium Animations - Apple Award-Winning Delight
//  The most satisfying, delightful animations in any productivity app
//  Inspired by Apple's best - Camera, Weather, Maps, Apple Music
//

import SwiftUI

// MARK: - ✨ Ultra-Premium Checkbox (The Dopamine Machine)

/// A checkbox so satisfying users will want to complete tasks just to see it
/// Features: Morphing ring, particle starburst, ripple wave, synchronized haptics
struct UltraPremiumCheckbox: View {
    @Binding var isCompleted: Bool
    var accentColor: Color = Theme.CelestialColors.auroraGreen
    var size: CGFloat = 28
    var onComplete: (() -> Void)?

    // Animation states
    @State private var ringProgress: CGFloat = 0
    @State private var fillScale: CGFloat = 0
    @State private var checkmarkProgress: CGFloat = 0
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var showParticles = false
    @State private var bounceScale: CGFloat = 1.0
    @State private var isPressed = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Particle system
    @State private var particles: [StarburstParticle] = []

    var body: some View {
        Button {
            if !isCompleted {
                triggerCompletion()
            } else {
                uncomplete()
            }
        } label: {
            ZStack {
                // Layer 1: Outer glow (success state)
                Circle()
                    .fill(accentColor)
                    .frame(width: size * 1.8, height: size * 1.8)
                    .blur(radius: 15)
                    .opacity(glowOpacity * 0.5)

                // Layer 2: Ripple wave
                Circle()
                    .stroke(accentColor.opacity(0.4), lineWidth: 2)
                    .frame(width: size * rippleScale, height: size * rippleScale)
                    .opacity(rippleOpacity)

                // Layer 3: Particle starburst
                ForEach(particles) { particle in
                    StarburstParticlePiece(particle: particle, accentColor: accentColor)
                }

                // Layer 4: Background ring (morphing border)
                Circle()
                    .strokeBorder(
                        isCompleted || ringProgress > 0
                            ? accentColor.opacity(0.3 + ringProgress * 0.7)
                            : Color(.tertiaryLabel),
                        lineWidth: 2.5
                    )
                    .frame(width: size, height: size)

                // Layer 5: Progress ring (animated fill)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))

                // Layer 6: Fill circle
                Circle()
                    .fill(accentColor)
                    .frame(width: size - 4, height: size - 4)
                    .scaleEffect(fillScale)

                // Layer 7: Checkmark
                CheckmarkShape()
                    .trim(from: 0, to: checkmarkProgress)
                    .stroke(
                        Theme.CelestialColors.void,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: size * 0.45, height: size * 0.35)
                    .offset(y: 1)
                    .scaleEffect(checkmarkScale)
                    .opacity(isCompleted ? 1 : 0)
            }
            .frame(width: size * 2, height: size * 2)
            .contentShape(Circle().scale(1.5))
            .scaleEffect(bounceScale)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticsService.shared.impact(.soft)
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityLabel(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Completion Animation Sequence

    private func triggerCompletion() {
        guard !reduceMotion else {
            isCompleted = true
            HapticsService.shared.notification(.success)
            onComplete?()
            return
        }

        // Generate particles
        particles = (0..<16).map { i in
            let angle = (Double(i) / 16.0) * 2 * .pi + Double.random(in: -0.2...0.2)
            return StarburstParticle(
                id: i,
                angle: angle,
                distance: CGFloat.random(in: 35...55),
                size: CGFloat.random(in: 3...7),
                delay: Double.random(in: 0...0.08)
            )
        }

        // Phase 1: Ring fill (0ms - 200ms)
        withAnimation(.easeOut(duration: 0.2)) {
            ringProgress = 1.0
        }

        // Phase 2: Fill expansion + glow (150ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Haptic: The dopamine burst moment
            HapticsService.shared.dopamineBurst()

            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                fillScale = 1.0
                glowOpacity = 1.0
            }

            // Bounce effect
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                bounceScale = 1.15
            }

            // Ripple wave
            withAnimation(.easeOut(duration: 0.5)) {
                rippleScale = 3.0
                rippleOpacity = 0.8
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                rippleOpacity = 0
            }
        }

        // Phase 3: Checkmark draw (200ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isCompleted = true
            showParticles = true

            withAnimation(.easeOut(duration: 0.25)) {
                checkmarkProgress = 1.0
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                checkmarkScale = 1.0
            }
        }

        // Phase 4: Settle (300ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                bounceScale = 1.0
            }
        }

        // Phase 5: Glow fade (500ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                glowOpacity = 0.3
            }
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showParticles = false
            particles = []
            onComplete?()
        }
    }

    private func uncomplete() {
        HapticsService.shared.impact(.light)

        if reduceMotion {
            isCompleted = false
            ringProgress = 0
            fillScale = 0
            checkmarkProgress = 0
            checkmarkScale = 0.5
            return
        }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            fillScale = 0
            checkmarkProgress = 0
            checkmarkScale = 0.5
            glowOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.2)) {
            ringProgress = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isCompleted = false
        }
    }
}

// MARK: - Checkmark Shape

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let start = CGPoint(x: rect.minX, y: rect.midY)
        let middle = CGPoint(x: rect.width * 0.35, y: rect.maxY)
        let end = CGPoint(x: rect.maxX, y: rect.minY)

        path.move(to: start)
        path.addLine(to: middle)
        path.addLine(to: end)

        return path
    }
}

// MARK: - Starburst Particle

struct StarburstParticle: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let delay: Double
}

struct StarburstParticlePiece: View {
    let particle: StarburstParticle
    let accentColor: Color

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [accentColor, accentColor.opacity(0.5)],
                    center: .center,
                    startRadius: 0,
                    endRadius: particle.size
                )
            )
            .frame(width: particle.size, height: particle.size)
            .scaleEffect(scale)
            .offset(
                x: cos(particle.angle) * offset,
                y: sin(particle.angle) * offset
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(particle.delay)) {
                    offset = particle.distance
                    scale = 0.3
                }
                withAnimation(.easeOut(duration: 0.3).delay(particle.delay + 0.15)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - 🎉 Task Completion Orb Celebration

/// An explosive celebration for task completion
/// Features: Expanding rings, particle nova, floating XP, color wave
struct TaskCompletionOrbCelebration: View {
    @Binding var isActive: Bool
    let points: Int
    var accentColor: Color = Theme.CelestialColors.auroraGreen

    // Animation states
    @State private var rings: [CelebrationRing] = []
    @State private var novaParticles: [NovaParticle] = []
    @State private var showXP = false
    @State private var xpOffset: CGFloat = 0
    @State private var xpOpacity: Double = 0
    @State private var xpScale: CGFloat = 0.5
    @State private var coreScale: CGFloat = 0
    @State private var coreOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Layer 1: Ambient glow
            Circle()
                .fill(accentColor)
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .opacity(glowOpacity * 0.4)

            // Layer 2: Expanding rings
            ForEach(rings) { ring in
                CelebrationRingView(ring: ring, color: accentColor)
            }

            // Layer 3: Nova particles
            ForEach(novaParticles) { particle in
                NovaParticlePiece(particle: particle, color: accentColor)
            }

            // Layer 4: Central orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            accentColor,
                            accentColor.opacity(0.5)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
                .scaleEffect(coreScale)
                .opacity(coreOpacity)

            // Layer 5: Floating XP
            if showXP {
                Text("+\(points) XP")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "FFD700").opacity(0.6), radius: 10)
                    .offset(y: xpOffset)
                    .scaleEffect(xpScale)
                    .opacity(xpOpacity)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerCelebration()
            }
        }
    }

    private func triggerCelebration() {
        guard !reduceMotion else {
            HapticsService.shared.notification(.success)
            showXP = true
            xpOpacity = 1
            xpScale = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isActive = false
                showXP = false
            }
            return
        }

        // Generate rings
        rings = (0..<4).map { i in
            CelebrationRing(id: i, delay: Double(i) * 0.1)
        }

        // Generate nova particles
        novaParticles = (0..<24).map { i in
            let angle = (Double(i) / 24.0) * 2 * .pi
            return NovaParticle(
                id: i,
                angle: angle,
                distance: CGFloat.random(in: 80...140),
                size: CGFloat.random(in: 4...10),
                delay: Double.random(in: 0...0.15)
            )
        }

        // Haptic: Cosmic pulse
        HapticsService.shared.cosmicPulse()

        // Core orb appearance
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            coreScale = 1.2
            coreOpacity = 1
            glowOpacity = 1
        }

        // Core settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                coreScale = 1.0
            }
        }

        // XP animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showXP = true
            HapticsService.shared.sparkleCascade()

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                xpScale = 1.2
                xpOpacity = 1
            }

            withAnimation(.spring(response: 0.2).delay(0.15)) {
                xpScale = 1.0
            }

            withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
                xpOffset = -100
            }

            withAnimation(.easeOut(duration: 0.4).delay(1.0)) {
                xpOpacity = 0
            }
        }

        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                coreScale = 0
                coreOpacity = 0
                glowOpacity = 0
            }
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isActive = false
            showXP = false
            xpOffset = 0
            xpScale = 0.5
            rings = []
            novaParticles = []
        }
    }
}

// MARK: - Celebration Ring

struct CelebrationRing: Identifiable {
    let id: Int
    let delay: Double
}

struct CelebrationRingView: View {
    let ring: CelebrationRing
    let color: Color

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .stroke(
                color.opacity(0.6),
                lineWidth: 3 - CGFloat(ring.id) * 0.5
            )
            .frame(width: 80, height: 80)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(ring.delay)) {
                    scale = 2.5 + CGFloat(ring.id) * 0.3
                }
                withAnimation(.easeOut(duration: 0.4).delay(ring.delay + 0.25)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Nova Particle

struct NovaParticle: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let delay: Double
}

struct NovaParticlePiece: View {
    let particle: NovaParticle
    let color: Color

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: particle.size * 2)
            .rotationEffect(.radians(particle.angle + .pi / 2))
            .offset(
                x: cos(particle.angle) * offset,
                y: sin(particle.angle) * offset
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(particle.delay)) {
                    offset = particle.distance
                }
                withAnimation(.easeOut(duration: 0.3).delay(particle.delay + 0.25)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - 🌟 Delightful Button Style

/// A button style that feels premium on every press
/// Features: Scale feedback, haptic on press, glow pulse
struct DelightfulButtonStyle: ButtonStyle {
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    var scaleEffect: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticsService.shared.impact(hapticStyle)
                }
            }
    }
}

/// Soft button style for secondary actions
struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticsService.shared.impact(.soft)
                }
            }
    }
}

/// Bouncy button style for playful interactions
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.5), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticsService.shared.impact(.rigid)
                }
            }
    }
}

// MARK: - 🔄 Pull to Refresh Haptic Modifier

struct PullToRefreshHapticModifier: ViewModifier {
    let threshold: CGFloat
    @Binding var pullProgress: CGFloat

    @State private var hasTriggered = false

    func body(content: Content) -> some View {
        content
            .onChange(of: pullProgress) { _, newValue in
                if newValue >= threshold && !hasTriggered {
                    hasTriggered = true
                    HapticsService.shared.thresholdCrossed()
                } else if newValue < threshold * 0.5 {
                    hasTriggered = false
                }
            }
    }
}

// MARK: - 🎯 Swipe Threshold Feedback

struct SwipeThresholdModifier: ViewModifier {
    let threshold: CGFloat
    @Binding var swipeOffset: CGFloat
    let onThresholdCrossed: () -> Void

    @State private var hasPassedThreshold = false

    func body(content: Content) -> some View {
        content
            .onChange(of: swipeOffset) { _, newValue in
                let absValue = abs(newValue)
                if absValue >= threshold && !hasPassedThreshold {
                    hasPassedThreshold = true
                    HapticsService.shared.thresholdCrossed()
                    onThresholdCrossed()
                } else if absValue < threshold * 0.7 {
                    hasPassedThreshold = false
                }
            }
    }
}

// MARK: - 🌊 Continuous Scroll Haptic

struct ScrollHapticModifier: ViewModifier {
    let stepSize: CGFloat
    @Binding var scrollOffset: CGFloat

    @State private var lastHapticPosition: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onChange(of: scrollOffset) { _, newValue in
                let delta = abs(newValue - lastHapticPosition)
                if delta >= stepSize {
                    HapticsService.shared.selectionFeedback()
                    lastHapticPosition = newValue
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply delightful button style
    func delightfulButton(
        haptic: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        scale: CGFloat = 0.96
    ) -> some View {
        self.buttonStyle(DelightfulButtonStyle(hapticStyle: haptic, scaleEffect: scale))
    }

    /// Apply soft button style
    func softButton() -> some View {
        self.buttonStyle(SoftButtonStyle())
    }

    /// Apply bouncy button style
    func bouncyButton() -> some View {
        self.buttonStyle(BouncyButtonStyle())
    }

    /// Add pull to refresh haptic feedback
    func pullToRefreshHaptic(threshold: CGFloat = 100, progress: Binding<CGFloat>) -> some View {
        self.modifier(PullToRefreshHapticModifier(threshold: threshold, pullProgress: progress))
    }

    /// Add swipe threshold haptic feedback
    func swipeThresholdHaptic(
        threshold: CGFloat,
        offset: Binding<CGFloat>,
        onThreshold: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(SwipeThresholdModifier(
            threshold: threshold,
            swipeOffset: offset,
            onThresholdCrossed: onThreshold
        ))
    }
}

// MARK: - 💫 Floating Glow Effect

struct FloatingGlowEffect: View {
    let color: Color
    var intensity: Double = 0.6
    var size: CGFloat = 100

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0.4

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size / 3)
            .opacity(opacity * intensity)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 10
                    opacity = 0.6
                }
            }
    }
}

// MARK: - 🎪 Celebration Confetti Shower

struct CelebrationConfettiShower: View {
    @Binding var isActive: Bool
    var particleCount: Int = 60
    var colors: [Color] = [
        Theme.CelestialColors.auroraGreen,
        Theme.CelestialColors.plasmaCore,
        Theme.CelestialColors.solarFlare,
        Theme.CelestialColors.nebulaCore,
        Color(hex: "FFD700")
    ]

    @State private var confetti: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(confetti) { piece in
                    ConfettiPieceView(piece: piece, screenHeight: geo.size.height)
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                generateConfetti()
                HapticsService.shared.sparkleCascade()

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isActive = false
                    confetti = []
                }
            }
        }
    }

    private func generateConfetti() {
        confetti = (0..<particleCount).map { i in
            ConfettiPiece(
                id: i,
                color: colors.randomElement() ?? .white,
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                size: CGFloat.random(in: 4...10),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5),
                duration: Double.random(in: 2...3.5),
                wobbleAmplitude: CGFloat.random(in: 20...60)
            )
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let wobbleAmplitude: CGFloat
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat

    @State private var yOffset: CGFloat = -50
    @State private var currentRotation: Double = 0
    @State private var xWobble: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 1.5)
            .rotationEffect(.degrees(currentRotation))
            .position(x: piece.x + xWobble, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 0.2).delay(piece.delay)) {
                    opacity = 1
                }

                withAnimation(.linear(duration: piece.duration).delay(piece.delay)) {
                    yOffset = screenHeight + 100
                    currentRotation = piece.rotation + Double.random(in: 720...1080)
                }

                withAnimation(
                    .easeInOut(duration: 0.3)
                    .repeatForever(autoreverses: true)
                    .delay(piece.delay)
                ) {
                    xWobble = piece.wobbleAmplitude
                }

                withAnimation(.easeOut(duration: 0.5).delay(piece.delay + piece.duration - 0.5)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview("Ultra Premium Checkbox") {
    struct CheckboxDemo: View {
        @State private var isCompleted1 = false
        @State private var isCompleted2 = true
        @State private var isCompleted3 = false

        var body: some View {
            ZStack {
                Theme.CelestialColors.void.ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Ultra Premium Checkbox")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 60) {
                        VStack(spacing: 8) {
                            UltraPremiumCheckbox(isCompleted: $isCompleted1)
                            Text("Tap me!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 8) {
                            UltraPremiumCheckbox(
                                isCompleted: $isCompleted2,
                                accentColor: Theme.CelestialColors.plasmaCore
                            )
                            Text("Completed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 8) {
                            UltraPremiumCheckbox(
                                isCompleted: $isCompleted3,
                                accentColor: Theme.CelestialColors.nebulaCore,
                                size: 32
                            )
                            Text("Large")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    return CheckboxDemo()
}

#Preview("Orb Celebration") {
    struct CelebrationDemo: View {
        @State private var isActive = false

        var body: some View {
            ZStack {
                Theme.CelestialColors.void.ignoresSafeArea()

                TaskCompletionOrbCelebration(
                    isActive: $isActive,
                    points: 50
                )

                VStack {
                    Spacer()

                    Button("Celebrate!") {
                        isActive = true
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Theme.CelestialColors.nebulaCore)
                    .clipShape(Capsule())
                    .padding(.bottom, 50)
                }
            }
        }
    }

    return CelebrationDemo()
}

#Preview("Confetti Shower") {
    struct ConfettiDemo: View {
        @State private var isActive = false

        var body: some View {
            ZStack {
                Theme.CelestialColors.void.ignoresSafeArea()

                CelebrationConfettiShower(isActive: $isActive)

                Button("Rain Confetti!") {
                    isActive = true
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .background(Theme.CelestialColors.auroraGreen)
                .clipShape(Capsule())
            }
        }
    }

    return ConfettiDemo()
}
