//
//  CosmicProgressBar.swift
//  Veloce
//
//  Living Cosmos Progress Bar Component
//  Animated progress indicator with plasma glow effects
//

import SwiftUI

// MARK: - Cosmic Progress Bar

struct CosmicProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    let showGlow: Bool
    let animated: Bool

    @State private var animatedProgress: Double = 0
    @State private var glowPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        progress: Double,
        color: Color = Theme.Colors.aiPurple,
        height: CGFloat = LivingCosmos.ProgressBar.height,
        showGlow: Bool = true,
        animated: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.color = color
        self.height = height
        self.showGlow = showGlow
        self.animated = animated
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                backgroundTrack

                // Progress fill
                progressFill(width: geometry.size.width)

                // Glow tip
                if showGlow && animatedProgress > 0.01 {
                    glowTip(at: geometry.size.width * animatedProgress)
                }
            }
        }
        .frame(height: height)
        .onAppear {
            if animated {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animatedProgress = progress
                }
                startGlowAnimation()
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            if animated {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animatedProgress = newValue
                }
            } else {
                animatedProgress = newValue
            }
        }
    }

    // MARK: - Background Track

    private var backgroundTrack: some View {
        Capsule()
            .fill(color.opacity(LivingCosmos.ProgressBar.backgroundOpacity))
    }

    // MARK: - Progress Fill

    private func progressFill(width: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: max(height, width * animatedProgress))
    }

    // MARK: - Glow Tip

    private func glowTip(at xPosition: CGFloat) -> some View {
        SwiftUI.Circle()
            .fill(color)
            .frame(width: height * 1.5, height: height * 1.5)
            .blur(radius: LivingCosmos.ProgressBar.glowRadius)
            .opacity(reduceMotion ? 0.5 : (0.5 + glowPhase * 0.3))
            .position(x: xPosition - height / 4, y: height / 2)
    }

    // MARK: - Animation

    private func startGlowAnimation() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }
    }
}

// MARK: - Cosmic Circular Progress

struct CosmicCircularProgress: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    let showLabel: Bool
    let labelFormat: LabelFormat

    enum LabelFormat {
        case percentage
        case fraction(total: Int)
        case custom(String)
    }

    @State private var animatedProgress: Double = 0
    @State private var glowPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        progress: Double,
        color: Color = Theme.Colors.aiPurple,
        lineWidth: CGFloat = 8,
        size: CGFloat = 80,
        showLabel: Bool = true,
        labelFormat: LabelFormat = .percentage
    ) {
        self.progress = max(0, min(1, progress))
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.showLabel = showLabel
        self.labelFormat = labelFormat
    }

    var body: some View {
        ZStack {
            // Background circle
            SwiftUI.Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress arc
            SwiftUI.Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.6), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Glow effect
            SwiftUI.Circle()
                .trim(from: max(0, animatedProgress - 0.1), to: animatedProgress)
                .stroke(color, lineWidth: lineWidth)
                .blur(radius: 4)
                .opacity(reduceMotion ? 0.3 : (0.3 + glowPhase * 0.2))
                .rotationEffect(.degrees(-90))

            // Label
            if showLabel {
                labelView
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
            startGlowAnimation()
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }

    @ViewBuilder
    private var labelView: some View {
        switch labelFormat {
        case .percentage:
            Text("\(Int(animatedProgress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starWhite)
        case .fraction(let total):
            VStack(spacing: 0) {
                Text("\(Int(animatedProgress * Double(total)))")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)
                Text("/\(total)")
                    .font(.system(size: size * 0.14, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
        case .custom(let text):
            Text(text)
                .font(.system(size: size * 0.18, weight: .semibold))
                .foregroundStyle(Theme.CelestialColors.starWhite)
        }
    }

    private func startGlowAnimation() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }
    }
}

// MARK: - Cosmic Level Progress

struct CosmicLevelProgress: View {
    let level: Int
    let currentXP: Int
    let requiredXP: Int
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Level badge
            HStack {
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: color.opacity(0.4), radius: 8)

                    Text("\(level)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Level \(level)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("\(currentXP) / \(requiredXP) XP")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()

                Text("Level \(level + 1)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            // Progress bar
            CosmicProgressBar(
                progress: Double(currentXP) / Double(requiredXP),
                color: color
            )
        }
    }
}

// MARK: - Preview

#Preview("Cosmic Progress Bars") {
    ZStack {
        VoidBackground.momentum

        VStack(spacing: Theme.Spacing.xl) {
            CosmicProgressBar(progress: 0.7, color: Theme.Colors.aiPurple)

            CosmicProgressBar(progress: 0.4, color: Theme.CelestialColors.auroraGreen, height: 12)

            CosmicProgressBar(progress: 1.0, color: Theme.Colors.xp)

            HStack(spacing: Theme.Spacing.xl) {
                CosmicCircularProgress(progress: 0.75, color: Theme.Colors.aiPurple)

                CosmicCircularProgress(
                    progress: 0.6,
                    color: Theme.CelestialColors.auroraGreen,
                    labelFormat: .fraction(total: 10)
                )
            }

            CosmicLevelProgress(
                level: 7,
                currentXP: 450,
                requiredXP: 1000,
                color: Theme.Colors.aiPurple
            )
            .padding()
            .celestialGlass()
        }
        .padding()
    }
}
