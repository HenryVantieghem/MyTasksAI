//
//  StreakFlameView.swift
//  Veloce
//
//  Animated streak flame display with intensity based on streak length
//  Higher streaks = more intense flame animation
//

import SwiftUI

struct StreakFlameView: View {
    let currentStreak: Int
    let bestStreak: Int
    let hasStreakShield: Bool

    @State private var flameScale: CGFloat = 1
    @State private var flameOffset: CGFloat = 0
    @State private var innerFlameOpacity: Double = 0.8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var flameIntensity: FlameIntensity {
        switch currentStreak {
        case 0: return .none
        case 1...2: return .spark
        case 3...6: return .small
        case 7...13: return .medium
        case 14...29: return .large
        default: return .inferno
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Flame icon with intensity
            flameIcon

            // Streak info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(currentStreak)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("day streak")
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(.white.opacity(0.7))
                }

                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .dynamicTypeFont(base: 11)
                        .foregroundStyle(Theme.Colors.aiAmber.opacity(0.7))

                    Text("Best: \(bestStreak) days")
                        .dynamicTypeFont(base: 12, weight: .medium)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            // Streak shield indicator
            if hasStreakShield {
                streakShieldBadge
            }
        }
        .padding(16)
        .glassEffect(
            .regular.tint(flameIntensity.glowColor.opacity(0.1)),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [flameIntensity.glowColor.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        }
        .onAppear {
            if !reduceMotion && currentStreak > 0 {
                startAnimations()
            }
        }
    }

    // MARK: - Flame Icon

    private var flameIcon: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            flameIntensity.glowColor.opacity(0.4),
                            flameIntensity.glowColor.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 70, height: 70)
                .blur(radius: flameIntensity.blurRadius)
                .scaleEffect(flameScale)

            // Flame layers
            ZStack {
                // Outer flame (orange)
                Image(systemName: flameIntensity.icon)
                    .dynamicTypeFont(base: 36, weight: .semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiOrange, Theme.Colors.aiAmber],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .offset(y: flameOffset)

                // Inner flame (yellow/white)
                if flameIntensity.hasInnerFlame {
                    Image(systemName: "flame.fill")
                        .dynamicTypeFont(base: 20, weight: .semibold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.aiAmber, .white],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .opacity(innerFlameOpacity)
                        .offset(y: flameOffset * 0.5 + 4)
                }
            }
            .shadow(color: flameIntensity.glowColor.opacity(0.5), radius: 8, y: 2)
        }
    }

    // MARK: - Streak Shield Badge

    private var streakShieldBadge: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.success.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "shield.checkered")
                    .dynamicTypeFont(base: 18, weight: .semibold)
                    .foregroundStyle(Theme.Colors.success)
            }

            Text("Protected")
                .dynamicTypeFont(base: 9, weight: .semibold)
                .foregroundStyle(Theme.Colors.success)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Flame scale breathing
        withAnimation(.easeInOut(duration: flameIntensity.animationSpeed).repeatForever(autoreverses: true)) {
            flameScale = 1 + flameIntensity.scaleAmplitude
        }

        // Flame flicker
        withAnimation(.easeInOut(duration: flameIntensity.animationSpeed * 0.5).repeatForever(autoreverses: true)) {
            flameOffset = -flameIntensity.flickerAmplitude
        }

        // Inner flame pulse
        withAnimation(.easeInOut(duration: flameIntensity.animationSpeed * 0.7).repeatForever(autoreverses: true)) {
            innerFlameOpacity = 1.0
        }
    }
}

// MARK: - Flame Intensity

enum FlameIntensity {
    case none, spark, small, medium, large, inferno

    var icon: String {
        switch self {
        case .none: return "flame"
        case .spark: return "flame"
        case .small: return "flame.fill"
        case .medium: return "flame.fill"
        case .large: return "flame.fill"
        case .inferno: return "flame.fill"
        }
    }

    var glowColor: Color {
        switch self {
        case .none: return .gray
        case .spark: return Theme.Colors.aiAmber.opacity(0.5)
        case .small: return Theme.Colors.aiAmber
        case .medium: return Theme.Colors.aiOrange
        case .large: return Color(red: 1, green: 0.3, blue: 0.1)
        case .inferno: return Color(red: 1, green: 0.2, blue: 0.3)
        }
    }

    var blurRadius: CGFloat {
        switch self {
        case .none: return 0
        case .spark: return 4
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        case .inferno: return 16
        }
    }

    var hasInnerFlame: Bool {
        switch self {
        case .none, .spark: return false
        default: return true
        }
    }

    var animationSpeed: Double {
        switch self {
        case .none: return 0
        case .spark: return 1.5
        case .small: return 1.2
        case .medium: return 1.0
        case .large: return 0.8
        case .inferno: return 0.5
        }
    }

    var scaleAmplitude: CGFloat {
        switch self {
        case .none: return 0
        case .spark: return 0.05
        case .small: return 0.08
        case .medium: return 0.12
        case .large: return 0.15
        case .inferno: return 0.2
        }
    }

    var flickerAmplitude: CGFloat {
        switch self {
        case .none: return 0
        case .spark: return 1
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        case .inferno: return 5
        }
    }
}

// MARK: - Compact Streak Badge

struct CompactStreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .dynamicTypeFont(base: 12, weight: .semibold)
                .foregroundStyle(
                    streak > 0
                        ? LinearGradient(colors: [Theme.Colors.aiOrange, Theme.Colors.aiAmber], startPoint: .bottom, endPoint: .top)
                        : LinearGradient(colors: [.gray, .gray], startPoint: .bottom, endPoint: .top)
                )

            Text("\(streak)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            StreakFlameView(currentStreak: 0, bestStreak: 12, hasStreakShield: false)

            StreakFlameView(currentStreak: 3, bestStreak: 12, hasStreakShield: false)

            StreakFlameView(currentStreak: 7, bestStreak: 12, hasStreakShield: true)

            StreakFlameView(currentStreak: 21, bestStreak: 21, hasStreakShield: true)

            HStack(spacing: 12) {
                CompactStreakBadge(streak: 0)
                CompactStreakBadge(streak: 5)
                CompactStreakBadge(streak: 14)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
