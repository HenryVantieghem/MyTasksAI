//
//  AIThinkingOverlay.swift
//  Veloce
//
//  Premium AI Thinking Animation - Card-Level Polish
//  Shows a refined "AI processing" animation directly on task cards
//  after creation, lasting 3 seconds before gracefully fading away.
//
//  Inspired by Apple's premium animation philosophy:
//  Purposeful, refined, and enhances the moment.
//

import SwiftUI

// MARK: - AI Thinking Phase

/// Visual phases of the AI thinking animation
enum AIThinkingPhase: Int, CaseIterable {
    case analyzing = 0
    case processing = 1
    case optimizing = 2

    var message: String {
        switch self {
        case .analyzing: return "Analyzing"
        case .processing: return "Processing"
        case .optimizing: return "Optimizing"
        }
    }

    var icon: String {
        switch self {
        case .analyzing: return "eye"
        case .processing: return "brain"
        case .optimizing: return "sparkles"
        }
    }
}

// MARK: - AI Thinking Overlay

/// Premium AI thinking animation for task cards
/// Shows animated thinking dots, phase text, and premium glow
struct AIThinkingOverlay: View {
    let isActive: Bool
    var duration: TimeInterval = 3.0
    var onComplete: (() -> Void)?

    @State private var currentPhase: AIThinkingPhase = .analyzing
    @State private var dotPhase: Int = 0
    @State private var orbScale: CGFloat = 0.8
    @State private var orbRotation: Double = 0
    @State private var glowPulse: CGFloat = 1.0
    @State private var textOpacity: Double = 0
    @State private var showCheckmark: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.responsiveLayout) private var layout

    private var phaseTimer: Timer? = nil

    // Responsive sizes
    private var orbSize: CGFloat {
        layout.deviceType.isTablet ? 48 : 36
    }

    private var iconSize: CGFloat {
        layout.deviceType.isTablet ? 18 : 14
    }

    var body: some View {
        ZStack {
            // Frosted glass background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    // AI gradient tint
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.aiPurple.opacity(0.08),
                                    Theme.Colors.aiCyan.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    // Premium glow border
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Theme.Colors.aiPurple.opacity(0.4 * glowPulse),
                                    Theme.Colors.aiCyan.opacity(0.3 * glowPulse),
                                    Theme.Colors.aiPink.opacity(0.3 * glowPulse),
                                    Theme.Colors.aiPurple.opacity(0.4 * glowPulse)
                                ],
                                center: .center,
                                angle: .degrees(orbRotation)
                            ),
                            lineWidth: 1.5
                        )
                }

            // Content
            HStack(spacing: layout.spacing) {
                // Animated orb
                aiOrb
                    .frame(width: orbSize, height: orbSize)

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    // Phase text with dots
                    HStack(spacing: 4) {
                        Text(showCheckmark ? "Done" : currentPhase.message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)

                        if !showCheckmark {
                            // Animated dots
                            thinkingDots
                        }
                    }

                    // Subtitle
                    Text(showCheckmark ? "Task optimized" : "AI is enhancing your task")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .opacity(textOpacity)

                Spacer()
            }
            .padding(.horizontal, layout.cardPadding)
            .padding(.vertical, layout.cardPadding - 4)
        }
        .opacity(isActive ? 1 : 0)
        .scaleEffect(isActive ? 1 : 0.9)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isActive)
        .onChange(of: isActive) { _, active in
            if active {
                startAnimation()
            } else {
                resetAnimation()
            }
        }
    }

    // MARK: - AI Orb

    private var aiOrb: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.4),
                            Theme.Colors.aiCyan.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: orbSize / 1.5
                    )
                )
                .frame(width: orbSize * 1.5, height: orbSize * 1.5)
                .blur(radius: 8)
                .scaleEffect(glowPulse)

            // Rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Colors.aiPurple,
                            Theme.Colors.aiCyan,
                            Theme.Colors.aiPink,
                            Theme.Colors.aiPurple
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: orbSize - 4, height: orbSize - 4)
                .rotationEffect(.degrees(orbRotation))

            // Inner orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.8),
                            Theme.Colors.aiPurple.opacity(0.4)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: orbSize / 3
                    )
                )
                .frame(width: orbSize - 12, height: orbSize - 12)
                .scaleEffect(orbScale)

            // Icon or checkmark
            Group {
                if showCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: currentPhase.icon)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCheckmark)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPhase)
        }
    }

    // MARK: - Thinking Dots

    private var thinkingDots: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.Colors.aiPurple)
                    .frame(width: 4, height: 4)
                    .opacity(dotPhase == index ? 1.0 : 0.3)
                    .scaleEffect(dotPhase == index ? 1.2 : 0.8)
            }
        }
    }

    // MARK: - Animation Control

    private func startAnimation() {
        guard !reduceMotion else {
            // Simplified for accessibility
            textOpacity = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                showCheckmark = true
                HapticsService.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete?()
                }
            }
            return
        }

        // Reset state
        currentPhase = .analyzing
        showCheckmark = false
        dotPhase = 0
        orbScale = 0.8
        glowPulse = 1.0

        // Fade in text
        withAnimation(.easeOut(duration: 0.3)) {
            textOpacity = 1
        }

        // Orb scale animation
        withAnimation(.easeOut(duration: 0.4)) {
            orbScale = 1.0
        }

        // Continuous orb rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            orbRotation = 360
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowPulse = 1.15
        }

        // Dot animation timer
        let dotTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotPhase = (dotPhase + 1) % 3
            }
        }

        // Phase progression
        let phaseDuration = duration / Double(AIThinkingPhase.allCases.count + 1)

        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration) {
            withAnimation(.spring(response: 0.3)) {
                currentPhase = .processing
            }
            HapticsService.shared.lightImpact()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * 2) {
            withAnimation(.spring(response: 0.3)) {
                currentPhase = .optimizing
            }
            HapticsService.shared.lightImpact()
        }

        // Completion
        DispatchQueue.main.asyncAfter(deadline: .now() + duration - 0.5) {
            dotTimer.invalidate()

            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showCheckmark = true
            }
            HapticsService.shared.success()

            // Signal completion after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete?()
            }
        }
    }

    private func resetAnimation() {
        textOpacity = 0
        currentPhase = .analyzing
        showCheckmark = false
        dotPhase = 0
        orbScale = 0.8
        orbRotation = 0
        glowPulse = 1.0
    }
}

// MARK: - AI Thinking Card Modifier

/// Apply AI thinking overlay to a task card
struct AIThinkingCardModifier: ViewModifier {
    @Binding var isThinking: Bool
    let duration: TimeInterval
    var onComplete: (() -> Void)?

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isThinking ? 2 : 0)
                .opacity(isThinking ? 0.3 : 1)

            if isThinking {
                AIThinkingOverlay(
                    isActive: isThinking,
                    duration: duration,
                    onComplete: {
                        withAnimation(.spring(response: 0.4)) {
                            isThinking = false
                        }
                        onComplete?()
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity.animation(.easeOut(duration: 0.2))
                ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isThinking)
    }
}

extension View {
    /// Add AI thinking overlay animation to a card
    func aiThinkingOverlay(
        isThinking: Binding<Bool>,
        duration: TimeInterval = 3.0,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        modifier(AIThinkingCardModifier(
            isThinking: isThinking,
            duration: duration,
            onComplete: onComplete
        ))
    }
}

// MARK: - Standalone AI Thinking Badge

/// Compact AI thinking badge for inline use
struct AIThinkingBadge: View {
    let isActive: Bool

    @State private var dotPhase: Int = 0
    @State private var glowPulse: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            // Mini orb
            ZStack {
                Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .blur(radius: 4)
                    .scaleEffect(glowPulse)

                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }

            Text("AI")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Colors.aiPurple)

            // Dots
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Theme.Colors.aiPurple)
                        .frame(width: 3, height: 3)
                        .opacity(dotPhase == index ? 1.0 : 0.3)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.Colors.aiPurple.opacity(0.12))
                .overlay {
                    Capsule()
                        .stroke(Theme.Colors.aiPurple.opacity(0.25), lineWidth: 0.5)
                }
        }
        .opacity(isActive ? 1 : 0)
        .scaleEffect(isActive ? 1 : 0.8)
        .onChange(of: isActive) { _, active in
            if active && !reduceMotion {
                startAnimation()
            }
        }
        .onAppear {
            if isActive && !reduceMotion {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            glowPulse = 1.1
        }

        Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { timer in
            guard isActive else {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.15)) {
                dotPhase = (dotPhase + 1) % 3
            }
        }
    }
}

// MARK: - Preview

#Preview("AI Thinking Overlay") {
    struct PreviewWrapper: View {
        @State private var isThinking = true

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Card with overlay
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Write quarterly report")
                            .font(.headline)
                        Text("Due tomorrow at 9 AM")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .aiThinkingOverlay(isThinking: $isThinking) {
                        print("AI thinking complete!")
                    }
                    .padding(.horizontal)

                    // Badge
                    AIThinkingBadge(isActive: isThinking)

                    // Toggle
                    Button(isThinking ? "Stop Thinking" : "Start Thinking") {
                        isThinking.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("AI Thinking Badge") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            AIThinkingBadge(isActive: true)

            Text("Task Card Content")
                .foregroundStyle(.white)
        }
    }
}
