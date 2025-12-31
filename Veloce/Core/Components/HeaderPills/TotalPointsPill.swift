//
//  TotalPointsPill.swift
//  Veloce
//
//  Total Points Pill - Premium XP Display
//  Shows total points with animated counter and gold star
//

import SwiftUI

// MARK: - Total Points Pill

/// Premium points display pill with animated counter and glow effects
/// Shows total XP with gold star icon, pulses when points increase
struct TotalPointsPill: View {
    let points: Int
    var onTap: (() -> Void)? = nil

    // Track point changes for animation
    @State private var displayedPoints: Int = 0
    @State private var isGlowing: Bool = false
    @State private var starRotation: Double = 0

    // Gold gradient colors
    private let goldGradient = LinearGradient(
        colors: [
            Color(hex: "FFD700"),
            Color(hex: "FFA500"),
            Color(hex: "FFD700")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap?()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                // Gold star icon
                Image(systemName: "star.fill")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(goldGradient)
                    .rotationEffect(.degrees(starRotation))
                    .symbolEffect(.bounce, value: isGlowing)

                // Points counter
                Text(formattedPoints)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                // XP label
                Text("XP")
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                // Glow effect when points increase
                if isGlowing {
                    Capsule()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FFD700").opacity(0.3),
                                    Color(hex: "FFA500").opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .blur(radius: 8)
                }
            }
            .glassEffect(.regular, in: Capsule())
        }
        .buttonStyle(PointsPillButtonStyle())
        .onAppear {
            displayedPoints = points
        }
        .onChange(of: points) { oldValue, newValue in
            if newValue > oldValue {
                animatePointsIncrease(from: oldValue, to: newValue)
            } else {
                displayedPoints = newValue
            }
        }
    }

    // MARK: - Formatting

    private var formattedPoints: String {
        if displayedPoints >= 10000 {
            let k = Double(displayedPoints) / 1000.0
            return String(format: "%.1fK", k)
        } else {
            return NumberFormatter.localizedString(
                from: NSNumber(value: displayedPoints),
                number: .decimal
            )
        }
    }

    // MARK: - Animation

    private func animatePointsIncrease(from oldValue: Int, to newValue: Int) {
        // Trigger glow and haptic
        withAnimation(.easeOut(duration: 0.2)) {
            isGlowing = true
        }
        HapticsService.shared.pointsEarned(amount: newValue - oldValue)

        // Animate star rotation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            starRotation += 360
        }

        // Animate counter
        let difference = newValue - oldValue
        let steps = min(20, max(5, difference))
        let stepDuration = 0.8 / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                let progress = Double(i + 1) / Double(steps)
                let easedProgress = easeOutCubic(progress)
                withAnimation(.easeOut(duration: stepDuration)) {
                    displayedPoints = oldValue + Int(Double(difference) * easedProgress)
                }
            }
        }

        // Final value and fade glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            displayedPoints = newValue
            withAnimation(.easeIn(duration: 0.3)) {
                isGlowing = false
            }
        }
    }

    private func easeOutCubic(_ x: Double) -> Double {
        return 1 - pow(1 - x, 3)
    }
}

// MARK: - Button Style

private struct PointsPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Compact Variant

/// Smaller version for tight spaces
struct CompactPointsPill: View {
    let points: Int
    var onTap: (() -> Void)? = nil

    private let goldGradient = LinearGradient(
        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onTap?()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(goldGradient)

                Text(formatPoints(points))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .glassEffect(.regular, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func formatPoints(_ value: Int) -> String {
        if value >= 10000 {
            return String(format: "%.1fK", Double(value) / 1000.0)
        }
        return "\(value)"
    }
}

// MARK: - Preview

#Preview("Total Points Pill") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 30) {
            TotalPointsPill(points: 12450)

            TotalPointsPill(points: 850)

            TotalPointsPill(points: 125000)

            CompactPointsPill(points: 5200)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Animated Counter") {
    struct PreviewContainer: View {
        @State private var points = 1000

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 30) {
                    TotalPointsPill(points: points)

                    Button("Add 50 Points") {
                        points += 50
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Add 500 Points") {
                        points += 500
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    return PreviewContainer()
        .preferredColorScheme(.dark)
}
