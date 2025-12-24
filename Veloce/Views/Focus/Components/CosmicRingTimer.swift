//
//  CosmicRingTimer.swift
//  Veloce
//
//  The Cosmic Ring - A mesmerizing focus timer
//  Large circular progress with gradient glow and breathing animations
//

import SwiftUI

// MARK: - Cosmic Ring Timer

/// The central focus timer with cosmic ring visualization
/// 280pt diameter, 12pt thick ring, amber to cyan gradient with glow
struct CosmicRingTimer: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let isActive: Bool
    let isPaused: Bool
    let mode: FocusTimerMode
    let statusText: String
    let onModeChange: () -> Void

    @State private var ringGlowPulse: Double = 0.5
    @State private var breathingScale: CGFloat = 1.0
    @State private var minutePulse: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        guard totalSeconds > 0 else { return 1.0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var isFlowState: Bool {
        mode == .flowState
    }

    var body: some View {
        ZStack {
            // Outer ambient glow
            outerGlow

            // Background track ring
            trackRing

            // Progress ring with gradient
            progressRing

            // Glow highlight on progress edge
            if isActive || progress < 1.0 {
                progressGlowEdge
            }

            // Center content
            centerContent
        }
        .frame(width: 300, height: 300)
        .scaleEffect(breathingScale)
        .onAppear {
            startAnimations()
        }
        .onChange(of: remainingSeconds) { oldValue, newValue in
            // Pulse on each minute
            if newValue % 60 == 0 && newValue != oldValue && newValue > 0 {
                triggerMinutePulse()
            }
        }
    }

    // MARK: - Outer Glow

    private var outerGlow: some View {
        ZStack {
            // Primary amber glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.96, green: 0.62, blue: 0.14).opacity(0.25 * ringGlowPulse),
                            Color(red: 0.96, green: 0.4, blue: 0.1).opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 25)

            // Secondary cyan accent
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.18, green: 0.82, blue: 0.92).opacity(0.15 * ringGlowPulse),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 160
                    )
                )
                .frame(width: 340, height: 340)
                .blur(radius: 20)
                .offset(x: 20, y: -20)
        }
    }

    // MARK: - Track Ring

    private var trackRing: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 12, lineCap: .round)
            )
            .frame(width: 260, height: 260)
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        Circle()
            .trim(from: 0, to: isFlowState ? 1.0 : progress)
            .stroke(
                AngularGradient(
                    colors: isFlowState ? flowStateColors : focusGradientColors,
                    center: .center,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270)
                ),
                style: StrokeStyle(lineWidth: 12, lineCap: .round)
            )
            .frame(width: 260, height: 260)
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 1), value: progress)
            .shadow(color: primaryGlowColor.opacity(0.5), radius: 8, x: 0, y: 0)
    }

    private var focusGradientColors: [Color] {
        [
            Color(red: 0.96, green: 0.62, blue: 0.14), // Cosmic Amber
            Color(red: 0.98, green: 0.55, blue: 0.22), // Orange
            Color(red: 0.35, green: 0.78, blue: 0.92), // Celestial Cyan
            Color(red: 0.18, green: 0.82, blue: 0.92)  // Bright Cyan
        ]
    }

    private var flowStateColors: [Color] {
        [
            Color(red: 0.58, green: 0.25, blue: 0.98), // Purple
            Color(red: 0.42, green: 0.45, blue: 0.98), // Blue
            Color(red: 0.18, green: 0.82, blue: 0.92), // Cyan
            Color(red: 0.58, green: 0.25, blue: 0.98)  // Purple (loop)
        ]
    }

    private var primaryGlowColor: Color {
        isFlowState
            ? Color(red: 0.58, green: 0.25, blue: 0.98)
            : Color(red: 0.96, green: 0.62, blue: 0.14)
    }

    // MARK: - Progress Glow Edge

    private var progressGlowEdge: some View {
        GeometryReader { geo in
            let radius: CGFloat = 130
            let angle = (1 - progress) * 360 - 90 // Start from top
            let radians = angle * .pi / 180
            let x = geo.size.width / 2 + cos(radians) * radius
            let y = geo.size.height / 2 + sin(radians) * radius

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryGlowColor,
                            primaryGlowColor.opacity(0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .position(x: x, y: y)
                .blur(radius: 5)
                .opacity(isFlowState ? 0.8 : (isActive ? 1.0 : 0.5))
        }
    }

    // MARK: - Center Content

    private var centerContent: some View {
        VStack(spacing: 8) {
            // Time display
            Text(isFlowState ? "∞" : formattedTime)
                .font(.system(size: isFlowState ? 64 : 72, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .scaleEffect(minutePulse)

            // Status text
            Text(statusText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 180)

            // Mode badge (tappable)
            Button(action: onModeChange) {
                HStack(spacing: 6) {
                    Image(systemName: mode.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(mode.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(primaryGlowColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(primaryGlowColor.opacity(0.15))
                        .overlay {
                            Capsule()
                                .stroke(primaryGlowColor.opacity(0.3), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(.plain)
            .disabled(isActive)
            .opacity(isActive ? 0.6 : 1.0)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            ringGlowPulse = 1.0
        }

        // Subtle breathing
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathingScale = 1.02
        }
    }

    private func triggerMinutePulse() {
        guard !reduceMotion else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            minutePulse = 1.05
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                minutePulse = 1.0
            }
        }

        // Haptic at minute mark
        HapticsService.shared.lightImpact()
    }
}

// MARK: - Break Time Ring Timer

/// Modified ring for break time display
struct BreakTimeRingTimer: View {
    let remainingSeconds: Int
    let totalSeconds: Int

    private var progress: Double {
        guard totalSeconds > 0 else { return 1.0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Soft green glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.22, green: 0.88, blue: 0.58).opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 25)

            // Track
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 10)
                .frame(width: 260, height: 260)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.88, blue: 0.58),
                            Color(red: 0.18, green: 0.72, blue: 0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 8) {
                Text(formattedTime)
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))

                Text("Break Time")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(red: 0.22, green: 0.88, blue: 0.58))

                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                    Text("Relax & Recharge")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Compact Ring Timer

/// Smaller ring for widgets or compact displays
struct CompactRingTimer: View {
    let progress: Double
    let timeString: String
    let isActive: Bool

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 6)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.62, blue: 0.14),
                            Color(red: 0.18, green: 0.82, blue: 0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Time
            Text(timeString)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 100, height: 100)
    }
}

// MARK: - Preview

#Preview("Cosmic Ring - Active") {
    ZStack {
        Color.black.ignoresSafeArea()
        CosmicRingTimer(
            remainingSeconds: 1234,
            totalSeconds: 1500,
            isActive: true,
            isPaused: false,
            mode: .pomodoro,
            statusText: "Deep in focus",
            onModeChange: {}
        )
    }
}

#Preview("Cosmic Ring - Flow State") {
    ZStack {
        Color.black.ignoresSafeArea()
        CosmicRingTimer(
            remainingSeconds: 0,
            totalSeconds: 0,
            isActive: true,
            isPaused: false,
            mode: .flowState,
            statusText: "In the flow",
            onModeChange: {}
        )
    }
}

#Preview("Break Time Ring") {
    ZStack {
        Color.black.ignoresSafeArea()
        BreakTimeRingTimer(
            remainingSeconds: 180,
            totalSeconds: 300
        )
    }
}
