//
//  StreakMomentumView.swift
//  Veloce
//
//  Cosmic Flow Momentum Indicator
//  Displays active momentum/streak state with animated flame visualization
//

import SwiftUI

// MARK: - Momentum Indicator (Compact)

struct MomentumIndicator: View {
    let state: MomentumState
    @State private var flamePhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 6) {
            // Flame icon with animation
            ZStack {
                // Glow background
                if state.isActive {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Celebration.flameInner.opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .scaleEffect(pulseScale)
                }

                // Flame
                StreakFlameShape(phase: flamePhase, intensity: state.flameIntensity)
                    .fill(
                        LinearGradient(
                            colors: flameColors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 24, height: 28)
                    .shadow(color: Theme.Celebration.flameMid.opacity(0.6), radius: 6)
            }

            // Streak count and multiplier
            if state.isActive {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(state.streakCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Celebration.flameInner)

                    if !state.displayMultiplier.isEmpty {
                        Text(state.displayMultiplier)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.Celebration.starGold)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            if state.isActive {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Theme.Celebration.flameInner.opacity(0.3),
                                        Theme.Celebration.flameMid.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: state.isActive) { _, isActive in
            if isActive {
                startAnimations()
            }
        }
    }

    private var flameColors: [Color] {
        if state.flameIntensity >= 1.0 {
            // Maximum intensity - white hot core
            return [
                Theme.Celebration.flameCore,
                Theme.Celebration.flameInner,
                Theme.Celebration.flameMid,
                Theme.Celebration.flameOuter
            ]
        } else if state.flameIntensity >= 0.5 {
            // Medium intensity
            return [
                Theme.Celebration.flameInner,
                Theme.Celebration.flameMid,
                Theme.Celebration.flameOuter,
                Color.clear
            ]
        } else {
            // Low intensity - dim ember
            return [
                Theme.Celebration.flameMid.opacity(0.7),
                Theme.Celebration.flameOuter.opacity(0.5),
                Color.clear,
                Color.clear
            ]
        }
    }

    private func startAnimations() {
        guard state.isActive else { return }

        // Flame flicker
        withAnimation(
            .easeInOut(duration: 0.4)
            .repeatForever(autoreverses: true)
        ) {
            flamePhase = 1.0
        }

        // Pulse glow
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.15
        }
    }
}

// MARK: - Flame Shape

struct StreakFlameShape: Shape {
    var phase: CGFloat
    var intensity: Double

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let midX = rect.midX

        // Flame flicker offset
        let flickerOffset = sin(phase * .pi) * 3 * intensity

        // Base of flame
        path.move(to: CGPoint(x: midX - width * 0.3, y: height))

        // Left curve
        path.addQuadCurve(
            to: CGPoint(x: midX - width * 0.15 + flickerOffset, y: height * 0.5),
            control: CGPoint(x: midX - width * 0.4 - flickerOffset, y: height * 0.7)
        )

        // Top curve (tip)
        path.addQuadCurve(
            to: CGPoint(x: midX + flickerOffset, y: 0),
            control: CGPoint(x: midX - width * 0.1, y: height * 0.2)
        )

        // Right side down
        path.addQuadCurve(
            to: CGPoint(x: midX + width * 0.15 - flickerOffset, y: height * 0.5),
            control: CGPoint(x: midX + width * 0.1, y: height * 0.2)
        )

        // Back to base
        path.addQuadCurve(
            to: CGPoint(x: midX + width * 0.3, y: height),
            control: CGPoint(x: midX + width * 0.4 + flickerOffset, y: height * 0.7)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Momentum Badge (For Header)

struct MomentumBadge: View {
    @State private var state: MomentumState
    @State private var showTooltip = false

    init(state: MomentumState) {
        self._state = State(initialValue: state)
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                showTooltip.toggle()
            }

            // Auto-hide tooltip
            if showTooltip {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation {
                        showTooltip = false
                    }
                }
            }
        } label: {
            MomentumIndicator(state: state)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showTooltip && state.isActive {
                MomentumTooltip(state: state)
                    .offset(y: 50)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .onReceive(CelebrationEngine.shared.momentumChanged) { newState in
            withAnimation(.spring(response: 0.4)) {
                state = newState
            }
        }
    }
}

// MARK: - Momentum Tooltip

struct MomentumTooltip: View {
    let state: MomentumState

    var body: some View {
        VStack(spacing: 4) {
            Text("Cosmic Flow")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Celebration.flameInner)

            Text("\(state.streakCount) tasks in a row")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            if !state.displayMultiplier.isEmpty {
                Text("\(state.displayMultiplier) XP bonus!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Celebration.starGold)
            }

            // Time remaining indicator
            if let remaining = state.comboTimeRemaining {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(formatTimeRemaining(remaining))
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            Theme.Celebration.flameMid.opacity(0.2),
                            lineWidth: 1
                        )
                }
        }
    }

    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Momentum Activation Banner

struct MomentumActivationBanner: View {
    @Binding var isShowing: Bool
    let streakCount: Int

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                // Animated flame
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Celebration.flameInner.opacity(0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.Celebration.flameCore,
                                    Theme.Celebration.flameInner,
                                    Theme.Celebration.flameMid
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .shadow(color: Theme.Celebration.flameInner.opacity(0.8), radius: 8)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("COSMIC FLOW")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.Celebration.flameInner,
                                    Theme.Celebration.starGold
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("\(streakCount) tasks completed • XP bonus active!")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Theme.Celebration.flameInner.opacity(0.4),
                                        Theme.Celebration.flameMid.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: Theme.Celebration.flameMid.opacity(0.3), radius: 20, y: 10)
            }
            .padding(.horizontal, 20)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }

                // Auto-dismiss after 2 seconds
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                        scale = 0.9
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Momentum Progress Ring

struct MomentumProgressRing: View {
    let state: MomentumState

    @State private var animatedProgress: CGFloat = 0
    @State private var glowOpacity: Double = 0

    private var progress: CGFloat {
        guard let remaining = state.comboTimeRemaining else { return 0 }
        let total: TimeInterval = 30 * 60 // 30 minutes
        return CGFloat(remaining / total)
    }

    var body: some View {
        ZStack {
            // Background ring
            SwiftUI.Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 3)

            // Progress ring
            SwiftUI.Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Celebration.flameOuter,
                            Theme.Celebration.flameMid,
                            Theme.Celebration.flameInner,
                            Theme.Celebration.flameCore
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.Celebration.flameInner.opacity(glowOpacity), radius: 4)

            // Center content
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Celebration.flameInner)

                Text("\(state.streakCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 56, height: 56)
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            animatedProgress = progress

            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                glowOpacity = 0.8
            }
        }
    }
}

// MARK: - Extension for Time Remaining

extension MomentumState {
    var comboTimeRemaining: TimeInterval? {
        guard isActive, let lastTime = lastCompletionTime else { return nil }
        let elapsed = Date().timeIntervalSince(lastTime)
        let remaining = Self.decayInterval - elapsed
        return remaining > 0 ? remaining : nil
    }
}

// MARK: - Preview

#Preview("Momentum Indicator") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Inactive state
            MomentumIndicator(state: MomentumState())

            // Low momentum
            MomentumIndicator(state: {
                var state = MomentumState()
                state.streakCount = 2
                state.flameIntensity = 0.3
                return state
            }())

            // Active momentum
            MomentumIndicator(state: {
                var state = MomentumState()
                state.isActive = true
                state.streakCount = 5
                state.multiplier = 1.5
                state.flameIntensity = 0.75
                return state
            }())

            // Maximum momentum
            MomentumIndicator(state: {
                var state = MomentumState()
                state.isActive = true
                state.streakCount = 10
                state.multiplier = 2.0
                state.flameIntensity = 1.0
                return state
            }())
        }
    }
}

#Preview("Momentum Banner") {
    ZStack {
        Color.black.ignoresSafeArea()

        MomentumActivationBanner(isShowing: .constant(true), streakCount: 5)
    }
}
