//
//  AICompanionOrb.swift
//  MyTasksAI
//
//  Floating AI Companion - A persistent AI presence with personality
//  Watches, reacts, thinks, and celebrates with the user
//

import SwiftUI

// MARK: - AI Companion State

/// The various states of the AI companion
enum AICompanionState: Equatable {
    case idle           // Soft breathing glow
    case listening      // Perked up, ready to help
    case thinking       // Processing, spinning gradient
    case speaking       // Sharing insight
    case celebrating    // Task completed celebration
    case sleeping       // Dim, slow pulse (inactive/night mode)

    var scale: CGFloat {
        switch self {
        case .idle: return 1.0
        case .listening: return 1.15
        case .thinking: return 1.1
        case .speaking: return 1.05
        case .celebrating: return 1.3
        case .sleeping: return 0.9
        }
    }

    var glowIntensity: CGFloat {
        switch self {
        case .idle: return 0.4
        case .listening: return 0.6
        case .thinking: return 0.7
        case .speaking: return 0.5
        case .celebrating: return 1.0
        case .sleeping: return 0.15
        }
    }

    var rotationSpeed: Double {
        switch self {
        case .idle: return 8.0
        case .listening: return 4.0
        case .thinking: return 1.5
        case .speaking: return 6.0
        case .celebrating: return 0.5
        case .sleeping: return 16.0
        }
    }
}

// MARK: - AI Companion Orb

/// The main AI companion orb component
struct AICompanionOrb: View {
    @Binding var state: AICompanionState
    let size: CGFloat
    let onTap: (() -> Void)?

    @State private var rotation: Double = 0
    @State private var breathScale: CGFloat = 1.0
    @State private var celebrationParticles: Bool = false

    init(
        state: Binding<AICompanionState>,
        size: CGFloat = 32,
        onTap: (() -> Void)? = nil
    ) {
        self._state = state
        self.size = size
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                // Outer glow layer
                outerGlow

                // Main orb
                mainOrb

                // Inner highlight
                innerHighlight

                // Celebration particles
                if celebrationParticles {
                    CelebrationParticles(size: size)
                }
            }
            .frame(width: size * 2, height: size * 2)
            .scaleEffect(state.scale * breathScale)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: state)
        }
        .buttonStyle(.plain)
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
        }
        .task {
            await startAnimations()
        }
    }

    // MARK: - Layers

    private var outerGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Theme.Colors.aiPurple.opacity(state.glowIntensity * 0.6),
                        Theme.Colors.aiBlue.opacity(state.glowIntensity * 0.3),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.3,
                    endRadius: size * 1.2
                )
            )
            .frame(width: size * 2, height: size * 2)
            .blur(radius: 8)
    }

    private var mainOrb: some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: Theme.Colors.aiGradient + [Theme.Colors.aiGradient[0]],
                    center: .center,
                    startAngle: .degrees(rotation),
                    endAngle: .degrees(rotation + 360)
                )
            )
            .frame(width: size, height: size)
    }

    private var innerHighlight: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.2),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.35, y: 0.35),
                    startRadius: 0,
                    endRadius: size * 0.35
                )
            )
            .frame(width: size, height: size)
    }

    // MARK: - Animations

    private func startAnimations() async {
        // Rotation animation
        Task {
            while !Task.isCancelled {
                let duration = state.rotationSpeed
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                try? await Task.sleep(for: .seconds(duration))
                rotation = 0
            }
        }

        // Breathing animation
        Task {
            while !Task.isCancelled {
                let isActive = state != .sleeping
                let intensity: CGFloat = isActive ? 0.08 : 0.03
                let duration = isActive ? 2.0 : 4.0

                withAnimation(.easeInOut(duration: duration)) {
                    breathScale = 1.0 + intensity
                }
                try? await Task.sleep(for: .seconds(duration))

                withAnimation(.easeInOut(duration: duration)) {
                    breathScale = 1.0 - intensity * 0.5
                }
                try? await Task.sleep(for: .seconds(duration))
            }
        }
    }

    private func handleStateChange(_ newState: AICompanionState) {
        switch newState {
        case .celebrating:
            celebrationParticles = true
            HapticsService.shared.celebration()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                celebrationParticles = false
            }
        case .thinking:
            HapticsService.shared.softImpact()
        case .listening:
            HapticsService.shared.selectionFeedback()
        default:
            break
        }
    }
}

// MARK: - Celebration Particles

/// Particles that burst out during celebration
struct CelebrationParticles: View {
    let size: CGFloat

    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var angle: Double
        var distance: CGFloat
        var opacity: Double
        var scale: CGFloat
        let color: Color
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: 4, height: 4)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(
                        x: cos(particle.angle) * particle.distance,
                        y: sin(particle.angle) * particle.distance
                    )
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }

    private func createParticles() {
        particles = (0..<12).map { i in
            Particle(
                angle: Double(i) * (.pi * 2 / 12) + Double.random(in: -0.3...0.3),
                distance: 0,
                opacity: 1,
                scale: 1,
                color: Theme.Colors.aiGradient[i % 4]
            )
        }
    }

    private func animateParticles() {
        withAnimation(.easeOut(duration: 0.8)) {
            for i in particles.indices {
                particles[i].distance = CGFloat.random(in: 25...45)
                particles[i].opacity = 0
                particles[i].scale = 0.3
            }
        }
    }
}

// MARK: - Floating AI Companion

/// A positioned, floating version of the AI companion
struct FloatingAICompanion: View {
    @Binding var state: AICompanionState
    @Binding var isExpanded: Bool

    let position: FloatingPosition

    enum FloatingPosition {
        case bottomLeading
        case bottomTrailing
        case topLeading
        case topTrailing
    }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedCard
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity)
                    ))
            }

            AICompanionOrb(state: $state, size: 32) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
        }
        .padding(16)
    }

    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("Ask me anything...")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            // Quick prompts
            VStack(alignment: .leading, spacing: 8) {
                QuickPromptButton(
                    icon: "sun.max",
                    text: "What should I focus on?",
                    action: {}
                )

                QuickPromptButton(
                    icon: "clock",
                    text: "How am I doing today?",
                    action: {}
                )

                QuickPromptButton(
                    icon: "sparkle",
                    text: "Suggest my next task",
                    action: {}
                )
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Theme.Colors.aiPurple.opacity(0.15), radius: 20, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.Colors.glassBorder.opacity(0.3))
        )
        .padding(.bottom, 8)
    }
}

// MARK: - Quick Prompt Button

struct QuickPromptButton: View {
    let icon: String
    let text: String
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiBlue)

                Text(text)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.cardBackground.opacity(isPressed ? 0.8 : 0.5))
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("AI Companion Orb") {
    struct PreviewWrapper: View {
        @State private var state: AICompanionState = .idle
        @State private var isExpanded = false

        var body: some View {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("AI Companion States")
                        .font(Theme.Typography.title2)

                    // State buttons
                    HStack(spacing: 12) {
                        ForEach([
                            ("Idle", AICompanionState.idle),
                            ("Listen", AICompanionState.listening),
                            ("Think", AICompanionState.thinking),
                            ("Speak", AICompanionState.speaking),
                            ("Celebrate", AICompanionState.celebrating),
                            ("Sleep", AICompanionState.sleeping)
                        ], id: \.0) { name, newState in
                            Button(name) {
                                state = newState
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Spacer()

                    // Main orb
                    AICompanionOrb(state: $state, size: 48)

                    Spacer()

                    // Compact indicator
                    HStack(spacing: 20) {
                        VStack {
                            CompactAIIndicator(isProcessing: true)
                            Text("Processing")
                                .font(Theme.Typography.caption1)
                        }

                        VStack {
                            CompactAIIndicator(isProcessing: false)
                            Text("Done")
                                .font(Theme.Typography.caption1)
                        }
                    }
                }
                .padding()

                // Floating companion
                VStack {
                    Spacer()
                    HStack {
                        FloatingAICompanion(
                            state: $state,
                            isExpanded: $isExpanded,
                            position: .bottomLeading
                        )
                        Spacer()
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}
