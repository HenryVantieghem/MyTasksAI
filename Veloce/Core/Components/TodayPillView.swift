//
//  TodayPillView.swift
//  Veloce
//
//  Living Cosmos - Orbital Date Ring
//  Dates orbit in a cosmic arc, Today pulses with solar corona,
//  swipe feels like planetary flyby
//

import SwiftUI
import Foundation

// MARK: - Orbital Metrics

private enum OrbitalMetrics {
    /// Standard ring height
    static let ringHeight: CGFloat = 48
    /// Sun (today) size
    static let sunSize: CGFloat = 8
    /// Corona outer size
    static let coronaSize: CGFloat = 24
    /// Planet (other dates) size
    static let planetSize: CGFloat = 6
    /// Orbit ring radius
    static let orbitRadius: CGFloat = 14
    /// Swipe threshold
    static let swipeThreshold: CGFloat = 50
    /// Flyby animation duration
    static let flybyDuration: Double = 0.35
}

// MARK: - Orbital Date Ring

struct TodayPillView: View {
    @Binding var selectedDate: Date

    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false
    @State private var coronaPhase: CGFloat = 0
    @State private var orbitPhase: CGFloat = 0
    @State private var flybyScale: CGFloat = 1
    @State private var flybyRotation: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Orbital navigation left
            orbitalNavButton(direction: -1)

            // Central orbital display
            orbitalDateDisplay

            // Orbital navigation right
            orbitalNavButton(direction: 1)
        }
        .frame(height: OrbitalMetrics.ringHeight)
        .onAppear {
            startOrbitalAnimations()
        }
    }

    // MARK: - Orbital Date Display

    private var orbitalDateDisplay: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Orbital indicator
            orbitalIndicator

            // Date text
            Text(displayText)
                .font(Theme.Typography.cosmosTitle)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(orbitalBackground)
        .clipShape(Capsule())
        .overlay(orbitalBorder)
        .scaleEffect(flybyScale)
        .rotation3DEffect(.degrees(flybyRotation), axis: (x: 0, y: 1, z: 0))
        .offset(x: dragOffset)
        .gesture(swipeGesture)
        .accessibilityLabel(accessibilityDateLabel)
        .accessibilityHint("Swipe left or right to change day")
    }

    // MARK: - Orbital Indicator

    private var orbitalIndicator: some View {
        ZStack {
            if isToday {
                // Solar corona for today
                solarCorona
            } else {
                // Planet for other dates
                planetIndicator
            }
        }
        .frame(width: OrbitalMetrics.coronaSize, height: OrbitalMetrics.coronaSize)
    }

    private var solarCorona: some View {
        ZStack {
            // Outer corona flares
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare.opacity(0.6),
                                Theme.CelestialColors.solarFlare.opacity(0)
                            ],
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 12, height: 2)
                    .offset(x: 8)
                    .rotationEffect(.degrees(Double(i) * 60 + coronaPhase * 30))
                    .opacity(reduceMotion ? 0.6 : 0.4 + Darwin.sin(coronaPhase + Double(i)) * 0.3)
            }

            // Corona glow
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.solarFlare.opacity(0.4),
                            Theme.CelestialColors.solarFlare.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 14
                    )
                )
                .scaleEffect(reduceMotion ? 1 : 1 + sin(coronaPhase * 2) * 0.1)

            // Sun core
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            Theme.CelestialColors.solarFlare
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 5
                    )
                )
                .frame(width: OrbitalMetrics.sunSize, height: OrbitalMetrics.sunSize)

            // Highlight
            SwiftUI.Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 3, height: 3)
                .offset(x: -1, y: -1)
        }
    }

    private var planetIndicator: some View {
        ZStack {
            // Orbit ring
            SwiftUI.Circle()
                .stroke(Theme.CelestialColors.starDim.opacity(0.3), lineWidth: 1)
                .frame(width: OrbitalMetrics.orbitRadius * 2, height: OrbitalMetrics.orbitRadius * 2)

            // Planet
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.starWhite,
                            Theme.CelestialColors.nebulaCore
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: OrbitalMetrics.planetSize, height: OrbitalMetrics.planetSize)
                .offset(y: -OrbitalMetrics.orbitRadius)
                .rotationEffect(.degrees(orbitPhase * 360))
        }
    }

    // MARK: - Orbital Background

    private var orbitalBackground: some View {
        ZStack {
            // Deep void base
            Theme.CelestialColors.abyss

            // Nebula glow based on date
            if isToday {
                RadialGradient(
                    colors: [
                        Theme.CelestialColors.solarFlare.opacity(0.15),
                        Color.clear
                    ],
                    center: .leading,
                    startRadius: 0,
                    endRadius: 80
                )
            } else {
                RadialGradient(
                    colors: [
                        Theme.CelestialColors.nebulaCore.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 60
                )
            }
        }
    }

    private var orbitalBorder: some View {
        Capsule()
            .strokeBorder(
                LinearGradient(
                    colors: isToday ? [
                        Theme.CelestialColors.solarFlare.opacity(0.5),
                        Theme.CelestialColors.solarFlare.opacity(0.2),
                        Theme.CelestialColors.nebulaEdge.opacity(0.1)
                    ] : [
                        Theme.CelestialColors.nebulaEdge.opacity(0.3),
                        Theme.CelestialColors.starDim.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Navigation Button

    private func orbitalNavButton(direction: Int) -> some View {
        Button {
            navigateToDate(offset: direction)
        } label: {
            ZStack {
                // Orbit trail
                SwiftUI.Circle()
                    .stroke(
                        Theme.CelestialColors.starDim.opacity(0.2),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                    .frame(width: 32, height: 32)

                // Arrow
                Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(Theme.CelestialColors.starWhite)
            }
        }
        .buttonStyle(OrbitalButtonStyle())
        .frame(width: 40, height: OrbitalMetrics.ringHeight)
        .contentShape(Rectangle())
        .accessibilityLabel(direction < 0 ? "Previous day" : "Next day")
    }

    // MARK: - Computed Properties

    private var displayText: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            let dayDiff = Calendar.current.dateComponents([.day], from: Date(), to: selectedDate).day ?? 0

            if abs(dayDiff) < 7 {
                formatter.dateFormat = "EEEE"
            } else {
                formatter.dateFormat = "MMM d"
            }

            return formatter.string(from: selectedDate)
        }
    }

    private var accessibilityDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimating else { return }

                // Planetary resistance effect
                let resistance: CGFloat = 0.6
                dragOffset = value.translation.width * resistance

                // Tilt effect during drag
                if !reduceMotion {
                    flybyRotation = Double(dragOffset) * 0.1
                }
            }
            .onEnded { value in
                guard !isAnimating else { return }

                if value.translation.width < -OrbitalMetrics.swipeThreshold {
                    navigateToDate(offset: 1)
                } else if value.translation.width > OrbitalMetrics.swipeThreshold {
                    navigateToDate(offset: -1)
                } else {
                    // Snap back
                    withAnimation(Theme.Animation.stellarBounce) {
                        dragOffset = 0
                        flybyRotation = 0
                    }
                }
            }
    }

    // MARK: - Navigation

    private func navigateToDate(offset: Int) {
        guard !isAnimating else { return }

        isAnimating = true
        HapticsService.shared.selectionFeedback()

        if reduceMotion {
            // Simple transition
            if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
                selectedDate = newDate
            }
            dragOffset = 0
            flybyRotation = 0
            isAnimating = false
        } else {
            // Planetary flyby effect
            let flyDirection: CGFloat = offset > 0 ? -1 : 1

            // Phase 1: Flyby out
            withAnimation(.easeIn(duration: OrbitalMetrics.flybyDuration * 0.4)) {
                dragOffset = flyDirection * 80
                flybyScale = 0.85
                flybyRotation = Double(flyDirection) * 15
            }

            // Phase 2: Update and flyby in
            DispatchQueue.main.asyncAfter(deadline: .now() + OrbitalMetrics.flybyDuration * 0.4) {
                if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
                    selectedDate = newDate
                }

                // Position on opposite side
                dragOffset = -flyDirection * 80
                flybyRotation = Double(-flyDirection) * 15

                // Animate in
                withAnimation(Theme.Animation.stellarBounce) {
                    dragOffset = 0
                    flybyScale = 1
                    flybyRotation = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
            }
        }
    }

    // MARK: - Animations

    private func startOrbitalAnimations() {
        guard !reduceMotion else { return }

        // Corona pulse
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            coronaPhase = 1
        }

        // Orbit rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            orbitPhase = 1
        }
    }
}

// MARK: - Orbital Button Style

struct OrbitalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Compact Orbital Pill (Alternative)

struct CompactOrbitalPill: View {
    @Binding var selectedDate: Date

    @State private var sunPulse: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Mini orbital indicator
            ZStack {
                if isToday {
                    // Mini sun
                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.solarFlare)
                        .frame(width: 6, height: 6)
                        .shadow(color: Theme.CelestialColors.solarFlare.opacity(0.5), radius: 4)
                        .scaleEffect(reduceMotion ? 1 : 1 + sunPulse * 0.2)
                } else {
                    // Mini planet
                    SwiftUI.Circle()
                        .fill(Theme.CelestialColors.starWhite)
                        .frame(width: 5, height: 5)
                }
            }

            Text(compactDisplayText)
                .font(Theme.Typography.cosmosMeta)
                .foregroundStyle(Theme.CelestialColors.starWhite)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(Theme.CelestialColors.abyss.opacity(0.8))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isToday
                                ? Theme.CelestialColors.solarFlare.opacity(0.3)
                                : Theme.CelestialColors.starDim.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                sunPulse = 1
            }
        }
    }

    private var compactDisplayText: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: selectedDate)
        }
    }
}

// MARK: - Preview

#Preview("Orbital Date Ring - Today") {
    struct PreviewWrapper: View {
        @State private var date = Date()

        var body: some View {
            VStack(spacing: 40) {
                TodayPillView(selectedDate: $date)

                CompactOrbitalPill(selectedDate: $date)

                Text("Selected: \(date.formatted(date: .complete, time: .omitted))")
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.CelestialColors.void)
        }
    }
    return PreviewWrapper()
}

#Preview("Orbital Date Ring - Yesterday") {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    return TodayPillView(selectedDate: .constant(yesterday))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.CelestialColors.void)
}

#Preview("Orbital Date Ring - Week Ago") {
    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    return TodayPillView(selectedDate: .constant(weekAgo))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.CelestialColors.void)
}
