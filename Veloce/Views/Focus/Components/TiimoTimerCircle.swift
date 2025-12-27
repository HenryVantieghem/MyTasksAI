//
//  TiimoTimerCircle.swift
//  Veloce
//
//  Tiimo-inspired visual timer that makes time tangible
//  Circular progress with time segments, breathing glow, orbiting dot
//

import SwiftUI

struct TiimoTimerCircle: View {
    let mode: QuickFocusMode
    let isActive: Bool
    let progress: Double
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval

    // Animation states
    @State private var breathingScale: CGFloat = 1
    @State private var glowPulse: Double = 0.5
    @State private var ringRotation: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Dimensions
    private let outerGlowSize: CGFloat = 280
    private let progressRingSize: CGFloat = 240
    private let innerOrbSize: CGFloat = 180
    private let progressStrokeWidth: CGFloat = 12

    var body: some View {
        ZStack {
            // Layer 1: Outer breathing glow
            outerGlow

            // Layer 2: Time segments ring (Tiimo-style)
            timeSegmentsRing

            // Layer 3: Progress track background
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: progressStrokeWidth)
                .frame(width: progressRingSize, height: progressRingSize)

            // Layer 4: Progress ring with gradient
            progressRing

            // Layer 5: Rotating outer accent ring
            rotatingAccentRing

            // Layer 6: Inner glass orb
            innerGlassOrb

            // Layer 7: Time display + mode icon
            timeDisplay

            // Layer 8: Orbiting position dot
            orbitingDot
        }
        .frame(width: outerGlowSize, height: outerGlowSize)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Outer Glow

    private var outerGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        mode.accentColor.opacity(0.25 * glowPulse),
                        mode.accentColor.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 60,
                    endRadius: 160
                )
            )
            .frame(width: outerGlowSize, height: outerGlowSize)
            .blur(radius: 30)
            .scaleEffect(breathingScale)
    }

    // MARK: - Time Segments Ring (Tiimo Innovation)

    private var timeSegmentsRing: some View {
        TimeSegmentsRing(
            totalMinutes: Int(totalTime / 60),
            elapsedMinutes: Int((totalTime - timeRemaining) / 60),
            accentColor: mode.accentColor,
            segmentCount: segmentCount
        )
        .frame(width: progressRingSize + 20, height: progressRingSize + 20)
    }

    private var segmentCount: Int {
        let minutes = Int(totalTime / 60)
        if minutes <= 30 {
            return minutes // One segment per minute
        } else if minutes <= 60 {
            return minutes / 5 // One segment per 5 minutes
        } else {
            return 12 // One segment per ~7.5 minutes for longer sessions
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                AngularGradient(
                    colors: [
                        mode.accentColor,
                        mode.accentColor.opacity(0.8),
                        mode.accentColor.opacity(0.6)
                    ],
                    center: .center,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270)
                ),
                style: StrokeStyle(lineWidth: progressStrokeWidth, lineCap: .round)
            )
            .frame(width: progressRingSize, height: progressRingSize)
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 1), value: progress)
    }

    // MARK: - Rotating Accent Ring

    private var rotatingAccentRing: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        mode.accentColor.opacity(0.5),
                        .clear,
                        .clear,
                        mode.accentColor.opacity(0.5)
                    ],
                    center: .center
                ),
                lineWidth: 2
            )
            .frame(width: progressRingSize + 16, height: progressRingSize + 16)
            .rotationEffect(.degrees(ringRotation))
    }

    // MARK: - Inner Glass Orb

    private var innerGlassOrb: some View {
        ZStack {
            // Glass background
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: innerOrbSize, height: innerOrbSize)

            // Top-left specular highlight
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.25), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: innerOrbSize, height: innerOrbSize)

            // Inner stroke
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: innerOrbSize, height: innerOrbSize)
        }
    }

    // MARK: - Time Display

    private var timeDisplay: some View {
        VStack(spacing: 4) {
            // Time
            Text(formattedTime)
                .font(.system(size: 52, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            // Mode label
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 12))
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var formattedTime: String {
        let absTime = abs(timeRemaining)
        let minutes = Int(absTime) / 60
        let seconds = Int(absTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Orbiting Dot

    private var orbitingDot: some View {
        Circle()
            .fill(mode.accentColor)
            .frame(width: 16, height: 16)
            .shadow(color: mode.accentColor.opacity(0.8), radius: 10)
            .offset(y: -(progressRingSize / 2))
            .rotationEffect(.degrees(360 * progress - 90))
            .animation(.linear(duration: 0.5), value: progress)
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Breathing scale
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathingScale = 1.05
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            glowPulse = 1.0
        }

        // Ring rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }
}

// MARK: - Time Segments Ring

struct TimeSegmentsRing: View {
    let totalMinutes: Int
    let elapsedMinutes: Int
    let accentColor: Color
    let segmentCount: Int

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2 - 8

            ZStack {
                ForEach(0..<segmentCount, id: \.self) { index in
                    segmentMark(
                        index: index,
                        center: center,
                        radius: radius
                    )
                }
            }
        }
    }

    private func segmentMark(index: Int, center: CGPoint, radius: CGFloat) -> some View {
        let angle = (Double(index) / Double(segmentCount)) * 360 - 90
        let segmentMinutes = totalMinutes / segmentCount
        let segmentElapsed = index * segmentMinutes

        let isPast = segmentElapsed < elapsedMinutes
        let isCurrent = segmentElapsed <= elapsedMinutes && (segmentElapsed + segmentMinutes) > elapsedMinutes

        return Circle()
            .fill(segmentColor(isPast: isPast, isCurrent: isCurrent))
            .frame(width: isCurrent ? 6 : 4, height: isCurrent ? 6 : 4)
            .offset(x: radius * cos(angle * .pi / 180), y: radius * sin(angle * .pi / 180))
            .animation(.easeInOut(duration: 0.3), value: elapsedMinutes)
    }

    private func segmentColor(isPast: Bool, isCurrent: Bool) -> Color {
        if isCurrent {
            return accentColor
        } else if isPast {
            return accentColor.opacity(0.6)
        } else {
            return Color.white.opacity(0.2)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            TiimoTimerCircle(
                mode: .pomodoro,
                isActive: true,
                progress: 0.4,
                timeRemaining: 15 * 60,
                totalTime: 25 * 60
            )

            TiimoTimerCircle(
                mode: .deepWork,
                isActive: false,
                progress: 0.7,
                timeRemaining: 27 * 60,
                totalTime: 90 * 60
            )
        }
    }
    .preferredColorScheme(.dark)
}
