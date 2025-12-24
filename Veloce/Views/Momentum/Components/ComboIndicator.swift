//
//  ComboIndicator.swift
//  Veloce
//
//  Combo Indicator - Productivity Multiplier Visualization
//  Shows combo streak with escalating cosmic energy effects
//  Higher combos = more intense visual feedback
//

import SwiftUI

// MARK: - Combo Tier

enum ComboTier: Int, CaseIterable {
    case none = 0      // No combo
    case x1 = 1        // 1.0x - Base
    case x1_5 = 2      // 1.5x - Building momentum
    case x2 = 3        // 2.0x - On fire
    case x3 = 4        // 3.0x - Maximum power

    var multiplier: Double {
        switch self {
        case .none: return 1.0
        case .x1: return 1.0
        case .x1_5: return 1.5
        case .x2: return 2.0
        case .x3: return 3.0
        }
    }

    var displayText: String {
        switch self {
        case .none, .x1: return "1x"
        case .x1_5: return "1.5x"
        case .x2: return "2x"
        case .x3: return "3x"
        }
    }

    var label: String {
        switch self {
        case .none: return "Build Combo"
        case .x1: return "Keep Going"
        case .x1_5: return "Building Momentum"
        case .x2: return "On Fire!"
        case .x3: return "MAXIMUM POWER"
        }
    }

    var primaryColor: Color {
        switch self {
        case .none: return Color(red: 0.4, green: 0.4, blue: 0.45)
        case .x1: return Color(red: 0.42, green: 0.45, blue: 0.98)
        case .x1_5: return Color(red: 0.58, green: 0.25, blue: 0.98)
        case .x2: return Color(red: 0.98, green: 0.55, blue: 0.25)
        case .x3: return Color(red: 0.98, green: 0.35, blue: 0.25)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .none: return Color(red: 0.3, green: 0.3, blue: 0.35)
        case .x1: return Color(red: 0.20, green: 0.78, blue: 0.95)
        case .x1_5: return Color(red: 0.42, green: 0.45, blue: 0.98)
        case .x2: return Color(red: 0.98, green: 0.75, blue: 0.25)
        case .x3: return Color(red: 0.98, green: 0.55, blue: 0.25)
        }
    }

    var glowIntensity: Double {
        switch self {
        case .none: return 0.0
        case .x1: return 0.3
        case .x1_5: return 0.5
        case .x2: return 0.7
        case .x3: return 1.0
        }
    }

    var particleCount: Int {
        switch self {
        case .none: return 0
        case .x1: return 4
        case .x1_5: return 8
        case .x2: return 14
        case .x3: return 24
        }
    }

    var waveCount: Int {
        switch self {
        case .none: return 0
        case .x1: return 1
        case .x1_5: return 2
        case .x2: return 3
        case .x3: return 4
        }
    }

    static func forComboCount(_ count: Int) -> ComboTier {
        switch count {
        case 0: return .none
        case 1: return .x1
        case 2...3: return .x1_5
        case 4...5: return .x2
        default: return .x3
        }
    }
}

// MARK: - Combo Indicator

struct ComboIndicator: View {
    let comboCount: Int
    let multiplier: Double
    let timeRemaining: TimeInterval? // Time until combo decays
    var size: CGFloat = 100

    @State private var pulsePhase: Double = 0
    @State private var waveExpand: Double = 0
    @State private var particleOrbit: Double = 0
    @State private var glowIntensity: Double = 0.5
    @State private var numberScale: Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tier: ComboTier {
        ComboTier.forComboCount(comboCount)
    }

    var body: some View {
        ZStack {
            // Energy waves (expanding rings)
            if tier.waveCount > 0 && !reduceMotion {
                energyWaves
            }

            // Particle field
            if tier.particleCount > 0 && !reduceMotion {
                particleField
            }

            // Core glow
            coreGlow

            // Main indicator
            mainIndicator

            // Decay timer (if provided)
            if let time = timeRemaining, time > 0, tier.rawValue > 0 {
                decayTimer(remaining: time)
            }
        }
        .frame(width: size * 1.5, height: size * 1.5)
        .onAppear {
            guard !reduceMotion else { return }
            startAnimations()
        }
        .onChange(of: comboCount) { _, _ in
            // Bounce effect on combo change
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                numberScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    numberScale = 1.0
                }
            }
        }
    }

    // MARK: - Energy Waves

    @ViewBuilder
    private var energyWaves: some View {
        ForEach(0..<tier.waveCount, id: \.self) { wave in
            let delay = Double(wave) * 0.25
            let phase = (waveExpand + delay).truncatingRemainder(dividingBy: 1.0)

            SwiftUI.Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            tier.primaryColor.opacity((1 - phase) * 0.4),
                            tier.secondaryColor.opacity((1 - phase) * 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.02 * (1 - phase)
                )
                .frame(width: size * (0.6 + phase * 0.6), height: size * (0.6 + phase * 0.6))
        }
    }

    // MARK: - Particle Field

    @ViewBuilder
    private var particleField: some View {
        Canvas { context, canvasSize in
            srand48(42)

            for i in 0..<tier.particleCount {
                let baseAngle = Double(i) / Double(tier.particleCount) * 2 * .pi
                let angle = baseAngle + particleOrbit + sin(particleOrbit * 2 + Double(i)) * 0.3
                let radius = size * (0.35 + drand48() * 0.15)

                let x = canvasSize.width / 2 + cos(angle) * radius
                let y = canvasSize.height / 2 + sin(angle) * radius

                let particleSize = size * 0.025 * (0.8 + sin(particleOrbit * 3 + Double(i)) * 0.4)
                let opacity = 0.6 + sin(particleOrbit * 2 + Double(i) * 0.5) * 0.4

                let rect = CGRect(
                    x: x - particleSize/2,
                    y: y - particleSize/2,
                    width: particleSize,
                    height: particleSize
                )

                let color = i % 2 == 0 ? tier.primaryColor : tier.secondaryColor
                context.fill(Ellipse().path(in: rect), with: .color(color.opacity(opacity)))

                // Glow
                let glowRect = CGRect(
                    x: x - particleSize,
                    y: y - particleSize,
                    width: particleSize * 2,
                    height: particleSize * 2
                )
                context.fill(Ellipse().path(in: glowRect), with: .color(color.opacity(opacity * 0.3)))
            }
        }
    }

    // MARK: - Core Glow

    @ViewBuilder
    private var coreGlow: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        tier.primaryColor.opacity(tier.glowIntensity * glowIntensity),
                        tier.secondaryColor.opacity(tier.glowIntensity * glowIntensity * 0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.5
                )
            )
            .frame(width: size, height: size)
            .scaleEffect(1 + pulsePhase * 0.1)
    }

    // MARK: - Main Indicator

    @ViewBuilder
    private var mainIndicator: some View {
        ZStack {
            // Background circle
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.08, green: 0.08, blue: 0.12),
                            Color(red: 0.04, green: 0.04, blue: 0.06)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.65, height: size * 0.65)
                .overlay(
                    SwiftUI.Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    tier.primaryColor.opacity(0.6),
                                    tier.secondaryColor.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: tier.primaryColor.opacity(tier.glowIntensity * 0.5), radius: 15)

            // Combo content
            VStack(spacing: 2) {
                // Multiplier
                Text(tier.displayText)
                    .font(.system(size: size * 0.22, weight: .black, design: .rounded))
                    .foregroundStyle(
                        tier.rawValue >= ComboTier.x2.rawValue
                        ? LinearGradient(
                            colors: [tier.primaryColor, tier.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(numberScale)

                // Combo count
                Text("\(comboCount) combo")
                    .font(.system(size: size * 0.09, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))

                // Fire icons for high combos
                if tier.rawValue >= ComboTier.x2.rawValue {
                    HStack(spacing: 2) {
                        ForEach(0..<min(comboCount, 5), id: \.self) { _ in
                            Image(systemName: "flame.fill")
                                .font(.system(size: size * 0.06))
                                .foregroundStyle(tier.primaryColor)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    // MARK: - Decay Timer

    @ViewBuilder
    private func decayTimer(remaining: TimeInterval) -> some View {
        let progress = min(1.0, remaining / 1800) // 30 min max

        SwiftUI.Circle()
            .trim(from: 0, to: progress)
            .stroke(
                tier.primaryColor.opacity(0.4),
                style: StrokeStyle(lineWidth: size * 0.02, lineCap: .round)
            )
            .frame(width: size * 0.75, height: size * 0.75)
            .rotationEffect(.degrees(-90))

        // Time label
        VStack {
            Spacer()
            Text(formatTime(remaining))
                .font(.system(size: size * 0.07, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.4))
                .padding(.bottom, size * 0.05)
        }
        .frame(height: size * 1.2)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }

        // Wave expansion
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            waveExpand = 1
        }

        // Particle orbit
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            particleOrbit = 2 * .pi
        }

        // Glow intensity
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 1
        }
    }
}

// MARK: - Compact Combo Badge

struct CompactComboBadge: View {
    let comboCount: Int
    let multiplier: Double

    private var tier: ComboTier {
        ComboTier.forComboCount(comboCount)
    }

    var body: some View {
        HStack(spacing: 6) {
            if tier.rawValue >= ComboTier.x1_5.rawValue {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(tier.primaryColor)
            }

            Text(tier.displayText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(tier.rawValue > 0 ? tier.primaryColor : .white.opacity(0.5))

            if comboCount > 0 {
                Text("(\(comboCount))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(tier.primaryColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(tier.primaryColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Different combo tiers
            HStack(spacing: 30) {
                ComboIndicator(comboCount: 0, multiplier: 1.0, timeRemaining: nil, size: 80)
                ComboIndicator(comboCount: 2, multiplier: 1.5, timeRemaining: nil, size: 80)
                ComboIndicator(comboCount: 4, multiplier: 2.0, timeRemaining: nil, size: 80)
            }

            // Maximum combo
            ComboIndicator(comboCount: 8, multiplier: 3.0, timeRemaining: 1234, size: 140)

            // Compact badges
            HStack(spacing: 12) {
                CompactComboBadge(comboCount: 0, multiplier: 1.0)
                CompactComboBadge(comboCount: 3, multiplier: 1.5)
                CompactComboBadge(comboCount: 6, multiplier: 3.0)
            }
        }
    }
}
