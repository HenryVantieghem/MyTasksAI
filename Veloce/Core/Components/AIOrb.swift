//
//  AIOrb.swift
//  Veloce
//
//  AI Orb Component
//  Reusable animated orb for AI presence across the app
//  Breathing, thinking, pulsing, and idle animation styles
//

import SwiftUI

// MARK: - AI Orb Animation Style

enum AIOrbAnimationStyle {
    /// Gentle breathing effect (scale 1.0 → 1.1, 2s cycle)
    case breathing

    /// Active thinking with rotation and particles
    case thinking

    /// Fast glow pulse for quick processing
    case pulse

    /// Subtle idle state with minimal animation
    case idle

    /// No animation
    case none
}

// MARK: - AI Orb View

struct AIOrb: View {
    let size: VoidDesign.OrbSize
    let animationStyle: AIOrbAnimationStyle
    let showParticles: Bool
    let showRings: Bool

    // Animation states
    @State private var orbScale: CGFloat = 1.0
    @State private var orbRotation: Double = 0
    @State private var glowOpacity: Double = 0.5
    @State private var ringScale: CGFloat = 0.8
    @State private var particleOffset: CGFloat = 0

    init(
        size: VoidDesign.OrbSize = .medium,
        animationStyle: AIOrbAnimationStyle = .breathing,
        showParticles: Bool = false,
        showRings: Bool = true
    ) {
        self.size = size
        self.animationStyle = animationStyle
        self.showParticles = showParticles
        self.showRings = showRings
    }

    var body: some View {
        ZStack {
            // Outer glow rings
            if showRings {
                glowRings
            }

            // Main glow blur
            mainGlow

            // Inner orb
            innerOrb

            // Floating particles
            if showParticles {
                floatingParticles
            }
        }
        .frame(width: containerSize, height: containerSize)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Computed Properties

    private var orbDiameter: CGFloat {
        size.rawValue
    }

    private var containerSize: CGFloat {
        orbDiameter * 2.5
    }

    private var ringBaseSize: CGFloat {
        orbDiameter * 1.75
    }

    private var glowSize: CGFloat {
        orbDiameter * 2.5
    }

    // MARK: - Glow Rings

    private var glowRings: some View {
        ForEach(0..<3, id: \.self) { index in
            SwiftUI.Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.3 - Double(index) * 0.08),
                            Theme.Colors.aiBlue.opacity(0.2 - Double(index) * 0.05),
                            Theme.Colors.aiCyan.opacity(0.1 - Double(index) * 0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: ringLineWidth
                )
                .frame(
                    width: ringBaseSize + CGFloat(index) * ringSpacing,
                    height: ringBaseSize + CGFloat(index) * ringSpacing
                )
                .scaleEffect(ringScale + CGFloat(index) * 0.1)
                .opacity(0.5 - Double(index) * 0.15)
                .rotationEffect(.degrees(orbRotation + Double(index * 30)))
        }
    }

    private var ringLineWidth: CGFloat {
        switch size {
        case .tiny, .small: return 0.5
        case .medium: return 1
        case .large, .hero, .massive: return 1.5
        }
    }

    private var ringSpacing: CGFloat {
        switch size {
        case .tiny, .small: return 12
        case .medium: return 25
        case .large: return 35
        case .hero, .massive: return 50
        }
    }

    // MARK: - Main Glow

    private var mainGlow: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Theme.Colors.aiPurple.opacity(0.4),
                        Theme.Colors.aiBlue.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: orbDiameter * 0.25,
                    endRadius: glowSize * 0.5
                )
            )
            .frame(width: glowSize, height: glowSize)
            .blur(radius: orbDiameter * 0.5)
            .opacity(glowOpacity)
    }

    // MARK: - Inner Orb

    private var innerOrb: some View {
        ZStack {
            // Gradient orb
            SwiftUI.Circle()
                .fill(VoidDesign.orbGradient)
                .frame(width: orbDiameter, height: orbDiameter)

            // Shine overlay
            SwiftUI.Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: orbDiameter, height: orbDiameter)

            // Inner icon (only for medium+ sizes)
            if size.rawValue >= VoidDesign.OrbSize.medium.rawValue {
                Image(systemName: "sparkles")
                    .font(.system(size: orbDiameter * 0.35, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .scaleEffect(orbScale)
        .rotationEffect(.degrees(-orbRotation * 0.5))
    }

    // MARK: - Floating Particles

    private var floatingParticles: some View {
        ForEach(0..<particleCount, id: \.self) { index in
            SwiftUI.Circle()
                .fill(particleColor(for: index))
                .frame(width: particleSize(for: index))
                .offset(
                    x: cos(Double(index) * .pi * 2 / Double(particleCount) + particleOffset) * particleOrbitRadius,
                    y: sin(Double(index) * .pi * 2 / Double(particleCount) + particleOffset) * particleOrbitRadius
                )
                .opacity(0.7)
        }
    }

    private var particleCount: Int {
        switch size {
        case .tiny, .small: return 4
        case .medium: return 6
        case .large, .hero, .massive: return 8
        }
    }

    private var particleOrbitRadius: CGFloat {
        orbDiameter * 0.9
    }

    private func particleSize(for index: Int) -> CGFloat {
        let baseSize: CGFloat = switch size {
        case .tiny, .small: 2
        case .medium: 4
        case .large: 5
        case .hero, .massive: 7
        }
        return baseSize + CGFloat.random(in: 0...2)
    }

    private func particleColor(for index: Int) -> Color {
        let colors = [
            Theme.Colors.aiPurple,
            Theme.Colors.aiBlue,
            Theme.Colors.aiCyan,
            Theme.Colors.aiPink
        ]
        return colors[index % colors.count]
    }

    // MARK: - Animations

    private func startAnimations() {
        switch animationStyle {
        case .breathing:
            startBreathingAnimation()

        case .thinking:
            startThinkingAnimation()

        case .pulse:
            startPulseAnimation()

        case .idle:
            startIdleAnimation()

        case .none:
            break
        }
    }

    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            orbScale = 1.1
            glowOpacity = 0.7
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            ringScale = 1.0
        }
    }

    private func startThinkingAnimation() {
        // Orb breathing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            orbScale = 1.1
        }
        // Orb rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            orbRotation = 360
        }
        // Glow pulsing
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
        // Ring expansion
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            ringScale = 1.0
        }
        // Particles orbit
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            particleOffset = .pi * 2
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            orbScale = 1.15
            glowOpacity = 0.9
        }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            ringScale = 1.1
        }
    }

    private func startIdleAnimation() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            orbScale = 1.03
            glowOpacity = 0.55
        }
    }
}

// MARK: - Mini AI Orb

/// Simplified orb for small spaces (badges, indicators)
struct MiniAIOrb: View {
    let size: CGFloat
    let animated: Bool

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8

    init(size: CGFloat = 12, animated: Bool = true) {
        self.size = size
        self.animated = animated
    }

    var body: some View {
        ZStack {
            // Glow
            SwiftUI.Circle()
                .fill(Theme.Colors.aiPurple.opacity(0.4))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.3)

            // Orb
            SwiftUI.Circle()
                .fill(VoidDesign.orbGradient)
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.1
                    opacity = 1.0
                }
            }
        }
    }
}

// MARK: - AI Orb Indicator

/// Status indicator with AI orb styling
struct AIStatusIndicator: View {
    let isActive: Bool
    let size: CGFloat

    @State private var pulse: CGFloat = 1.0

    init(isActive: Bool = true, size: CGFloat = 8) {
        self.isActive = isActive
        self.size = size
    }

    var body: some View {
        SwiftUI.Circle()
            .fill(isActive ? Theme.Colors.aiPurple : Theme.Colors.textTertiary)
            .frame(width: size, height: size)
            .scaleEffect(pulse)
            .shadow(color: (isActive ? Theme.Colors.aiPurple : Color.clear).opacity(0.5), radius: 4)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        pulse = 1.3
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview("AI Orb Sizes") {
    ScrollView {
        VStack(spacing: 60) {
            Group {
                Text("Tiny")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                AIOrb(size: .tiny, animationStyle: .breathing, showParticles: false, showRings: false)

                Text("Small")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                AIOrb(size: .small, animationStyle: .breathing, showRings: true)

                Text("Medium - Thinking")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                AIOrb(size: .medium, animationStyle: .thinking, showParticles: true)

                Text("Large - Pulse")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                AIOrb(size: .large, animationStyle: .pulse)

                Text("Hero - Thinking")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                AIOrb(size: .hero, animationStyle: .thinking, showParticles: true)
            }
        }
        .padding(.vertical, 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(white: 0.02))
}

#Preview("Mini Orbs") {
    HStack(spacing: 20) {
        MiniAIOrb(size: 8)
        MiniAIOrb(size: 12)
        MiniAIOrb(size: 16)
        AIStatusIndicator(isActive: true)
        AIStatusIndicator(isActive: false)
    }
    .padding(40)
    .background(Color(white: 0.02))
}
