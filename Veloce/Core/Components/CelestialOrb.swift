//
//  CelestialOrb.swift
//  Veloce
//
//  Celestial Orb
//  The sentient AI companion that guides users through auth and onboarding.
//  Features multi-layer construction, reactive states, and particle effects.
//

import SwiftUI

// MARK: - Celestial Orb

struct CelestialOrb: View {
    @Binding var state: OrbState
    let size: CGFloat
    let showRings: Bool
    let showParticles: Bool

    // Animation states
    @State private var orbScale: CGFloat = 1.0
    @State private var orbRotation: Double = 0
    @State private var glowOpacity: Double = 0.5
    @State private var glowScale: CGFloat = 1.0
    @State private var ringRotation: Double = 0
    @State private var ringScale: CGFloat = 0.9
    @State private var particleOffset: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var celebrationScale: CGFloat = 1.0
    @State private var celebrationOpacity: Double = 0

    init(
        state: Binding<OrbState>,
        size: CGFloat = Aurora.Size.orbHero,
        showRings: Bool = true,
        showParticles: Bool = false
    ) {
        self._state = state
        self.size = size
        self.showRings = showRings
        self.showParticles = showParticles
    }

    var body: some View {
        ZStack {
            // Layer 1: Outer glow halo
            outerGlow

            // Layer 2: Animated rings
            if showRings {
                orbRings
            }

            // Layer 3: Main glow blur
            mainGlow

            // Layer 4: Core orb
            coreOrb

            // Layer 5: Inner shine
            innerShine

            // Layer 6: Floating particles
            if showParticles || state == .processing || state == .celebration {
                floatingParticles
            }

            // Layer 7: Celebration burst
            if state == .celebration || state == .success {
                celebrationBurst
            }
        }
        .frame(width: containerSize, height: containerSize)
        .offset(x: shakeOffset)
        .onChange(of: state) { _, newState in
            animateToState(newState)
        }
        .onAppear {
            startBaseAnimations()
            animateToState(state)
        }
    }

    // MARK: - Computed Properties

    private var containerSize: CGFloat {
        size * 2.2
    }

    private var stateColor: Color {
        switch state {
        case .dormant, .aware, .active, .processing, .celebration:
            return Aurora.Colors.violet
        case .success:
            return Aurora.Colors.success
        case .error:
            return Aurora.Colors.error
        }
    }

    private var stateSecondaryColor: Color {
        switch state {
        case .dormant, .aware, .active, .processing, .celebration:
            return Aurora.Colors.cyan
        case .success:
            return Aurora.Colors.emerald
        case .error:
            return Aurora.Colors.rose
        }
    }

    // MARK: - Outer Glow

    private var outerGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        stateColor.opacity(0.3 * glowOpacity),
                        stateSecondaryColor.opacity(0.1 * glowOpacity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.3,
                    endRadius: size * 1.2
                )
            )
            .frame(width: size * 2.2, height: size * 2.2)
            .scaleEffect(glowScale)
    }

    // MARK: - Orb Rings

    private var orbRings: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                stateColor.opacity(0.35 - Double(index) * 0.08),
                                Aurora.Colors.electric.opacity(0.25 - Double(index) * 0.06),
                                stateSecondaryColor.opacity(0.30 - Double(index) * 0.07),
                                stateColor.opacity(0.35 - Double(index) * 0.08)
                            ],
                            center: .center,
                            angle: .degrees(ringRotation + Double(index * 40))
                        ),
                        lineWidth: ringLineWidth
                    )
                    .frame(
                        width: ringSize(for: index),
                        height: ringSize(for: index)
                    )
                    .scaleEffect(ringScale)
                    .rotationEffect(.degrees(ringRotation * (index.isMultiple(of: 2) ? 1 : -0.7)))
                    .opacity(0.6 - Double(index) * 0.15)
            }
        }
    }

    private var ringLineWidth: CGFloat {
        size >= 100 ? 1.5 : 1.0
    }

    private func ringSize(for index: Int) -> CGFloat {
        size * (1.4 + CGFloat(index) * 0.25)
    }

    // MARK: - Main Glow

    private var mainGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        stateColor.opacity(0.5),
                        Aurora.Colors.electric.opacity(0.3),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.7
                )
            )
            .frame(width: size * 1.5, height: size * 1.5)
            .blur(radius: size * 0.25)
            .opacity(glowOpacity)
    }

    // MARK: - Core Orb

    private var coreOrb: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [stateColor, Aurora.Colors.electric, stateSecondaryColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .scaleEffect(orbScale)
            .rotationEffect(.degrees(-orbRotation * 0.3))
            .shadow(color: stateColor.opacity(0.6), radius: size * 0.15, y: size * 0.03)
    }

    // MARK: - Inner Shine

    private var innerShine: some View {
        ZStack {
            // Top-left highlight
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            Color.white.opacity(0.15),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(orbScale)

            // Sparkle icon (for larger orbs)
            if size >= 60 {
                Image(systemName: sparkleIcon)
                    .font(.system(size: size * 0.35, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .scaleEffect(orbScale)
            }
        }
    }

    private var sparkleIcon: String {
        switch state {
        case .dormant: return "sparkle"
        case .aware: return "sparkles"
        case .active: return "sparkles"
        case .processing: return "arrow.trianglehead.2.clockwise"
        case .success: return "checkmark"
        case .error: return "exclamationmark"
        case .celebration: return "party.popper"
        }
    }

    // MARK: - Floating Particles

    private var floatingParticles: some View {
        ForEach(0..<particleCount, id: \.self) { index in
            Circle()
                .fill(particleColor(for: index))
                .frame(width: particleSize(for: index))
                .offset(particleOffset(for: index))
                .opacity(0.75)
                .blur(radius: 0.5)
        }
    }

    private var particleCount: Int {
        switch state {
        case .celebration: return 12
        case .processing: return 8
        case .success: return 6
        default: return showParticles ? 6 : 0
        }
    }

    private func particleSize(for index: Int) -> CGFloat {
        let base: CGFloat = size >= 100 ? 6 : 4
        return base + CGFloat.random(in: 0...3)
    }

    private func particleColor(for index: Int) -> Color {
        let colors = [Aurora.Colors.violet, Aurora.Colors.electric, Aurora.Colors.cyan, Aurora.Colors.emerald]
        return colors[index % colors.count]
    }

    private func particleOffset(for index: Int) -> CGSize {
        let angle = (Double(index) / Double(max(particleCount, 1))) * .pi * 2 + particleOffset
        let radius = size * (0.7 + sin(particleOffset * 2 + Double(index)) * 0.15)
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }

    // MARK: - Celebration Burst

    private var celebrationBurst: some View {
        ForEach(0..<8, id: \.self) { index in
            Circle()
                .fill(celebrationColor(for: index))
                .frame(width: size * 0.15)
                .offset(celebrationBurstOffset(for: index))
                .scaleEffect(celebrationScale)
                .opacity(celebrationOpacity)
        }
    }

    private func celebrationColor(for index: Int) -> Color {
        let colors = [Aurora.Colors.violet, Aurora.Colors.electric, Aurora.Colors.cyan, Aurora.Colors.emerald, Aurora.Colors.rose, Aurora.Colors.gold]
        return colors[index % colors.count]
    }

    private func celebrationBurstOffset(for index: Int) -> CGSize {
        let angle = (Double(index) / 8.0) * .pi * 2
        let radius = size * 1.5 * celebrationScale
        return CGSize(
            width: Foundation.cos(angle) * radius,
            height: Foundation.sin(angle) * radius
        )
    }

    // MARK: - Animations

    private func startBaseAnimations() {
        // Ring rotation (continuous)
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Particle orbit (continuous)
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            particleOffset = .pi * 2
        }
    }

    private func animateToState(_ newState: OrbState) {
        switch newState {
        case .dormant:
            animateDormant()
        case .aware:
            animateAware()
        case .active:
            animateActive()
        case .processing:
            animateProcessing()
        case .success:
            animateSuccess()
        case .error:
            animateError()
        case .celebration:
            animateCelebration()
        }
    }

    private func animateDormant() {
        withAnimation(Aurora.Animation.orbBreathing) {
            orbScale = 1.05
            glowOpacity = 0.45
            glowScale = 1.0
            ringScale = 0.92
        }
    }

    private func animateAware() {
        withAnimation(Aurora.Animation.spring) {
            orbScale = 1.08
            glowOpacity = 0.6
            glowScale = 1.05
            ringScale = 0.95
        }
    }

    private func animateActive() {
        withAnimation(Aurora.Animation.orbBreathing) {
            orbScale = 1.12
            glowOpacity = 0.75
            glowScale = 1.1
            ringScale = 1.0
        }
    }

    private func animateProcessing() {
        // Orb rotation
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            orbRotation = 360
        }
        // Pulsing glow
        withAnimation(Aurora.Animation.glowPulse) {
            glowOpacity = 0.85
            glowScale = 1.15
        }
        withAnimation(Aurora.Animation.spring) {
            orbScale = 1.1
            ringScale = 1.05
        }
    }

    private func animateSuccess() {
        // Quick scale up then settle
        withAnimation(Aurora.Animation.springSnappy) {
            orbScale = 1.2
            glowOpacity = 0.9
            glowScale = 1.2
        }

        // Celebration burst
        celebrationOpacity = 0
        celebrationScale = 0.5
        withAnimation(Aurora.Animation.spring) {
            celebrationOpacity = 0.8
            celebrationScale = 1.0
        }

        // Fade out burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(Aurora.Animation.slow) {
                celebrationOpacity = 0
                orbScale = 1.05
                glowScale = 1.0
            }
        }
    }

    private func animateError() {
        // Shake animation
        withAnimation(.easeInOut(duration: 0.08).repeatCount(5, autoreverses: true)) {
            shakeOffset = 8
        }

        // Red flash
        withAnimation(Aurora.Animation.quick) {
            glowOpacity = 0.9
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Aurora.Animation.spring) {
                shakeOffset = 0
                glowOpacity = 0.5
            }
        }
    }

    private func animateCelebration() {
        // Dramatic expansion
        withAnimation(Aurora.Animation.springGentle) {
            orbScale = 1.3
            glowOpacity = 1.0
            glowScale = 1.4
            ringScale = 1.2
        }

        // Burst particles outward
        celebrationOpacity = 0
        celebrationScale = 0.3
        withAnimation(Aurora.Animation.spring) {
            celebrationOpacity = 1.0
            celebrationScale = 1.5
        }

        // Continued celebration pulse
        withAnimation(Aurora.Animation.auroraPulse) {
            orbScale = 1.25
            glowScale = 1.35
        }
    }
}

// MARK: - Static Orb (Non-binding version)

struct StaticCelestialOrb: View {
    let state: OrbState
    let size: CGFloat
    let showRings: Bool
    let showParticles: Bool

    @State private var internalState: OrbState

    init(
        state: OrbState = .dormant,
        size: CGFloat = Aurora.Size.orbHero,
        showRings: Bool = true,
        showParticles: Bool = false
    ) {
        self.state = state
        self.size = size
        self.showRings = showRings
        self.showParticles = showParticles
        self._internalState = State(initialValue: state)
    }

    var body: some View {
        CelestialOrb(
            state: $internalState,
            size: size,
            showRings: showRings,
            showParticles: showParticles
        )
        .onChange(of: state) { _, newValue in
            internalState = newValue
        }
    }
}

// MARK: - Preview

#Preview("Celestial Orb States") {
    struct OrbDemo: View {
        @State private var orbState: OrbState = .dormant

        var body: some View {
            VStack(spacing: 40) {
                CelestialOrb(
                    state: $orbState,
                    size: 120,
                    showRings: true,
                    showParticles: orbState == .processing
                )

                Text(stateLabel)
                    .font(.headline)
                    .foregroundStyle(.white)

                // State buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        stateButton("Dormant", .dormant)
                        stateButton("Aware", .aware)
                        stateButton("Active", .active)
                        stateButton("Processing", .processing)
                        stateButton("Success", .success)
                        stateButton("Error", .error)
                        stateButton("Celebrate", .celebration)
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuroraBackground.auth)
        }

        private var stateLabel: String {
            switch orbState {
            case .dormant: return "Dormant - Subtle breathing"
            case .aware: return "Aware - User engaged"
            case .active: return "Active - User typing"
            case .processing: return "Processing - Auth in progress"
            case .success: return "Success - Auth complete!"
            case .error: return "Error - Auth failed"
            case .celebration: return "Celebration!"
            }
        }

        private func stateButton(_ label: String, _ state: OrbState) -> some View {
            Button {
                withAnimation {
                    orbState = state
                }
            } label: {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(orbState == state ? .white : .white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(orbState == state ? Aurora.Colors.violet : Aurora.Colors.glassBase)
                    )
            }
        }
    }

    return OrbDemo()
}

#Preview("Orb Sizes") {
    VStack(spacing: 60) {
        HStack(spacing: 40) {
            StaticCelestialOrb(state: .dormant, size: 40, showRings: false)
            StaticCelestialOrb(state: .active, size: 60, showRings: true)
        }

        StaticCelestialOrb(state: .processing, size: 100, showRings: true, showParticles: true)

        StaticCelestialOrb(state: .celebration, size: 140, showRings: true, showParticles: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Aurora.Colors.cosmicBlack)
}
