//
//  ConstellationProgressOrb.swift
//  MyTasksAI
//
//  Constellation Progress Visualization
//  Stars light up as you advance toward your goal
//

import SwiftUI

// MARK: - Constellation Progress Orb
struct ConstellationProgressOrb: View {
    let progress: Double
    var size: CGFloat = 60
    var accentColor: Color = Theme.Colors.aiPurple

    @State private var animationPhase: Double = 0
    @State private var stars: [ConstellationStar] = []
    @State private var glowIntensity: Double = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let starCount = 8

    var body: some View {
        ZStack {
            // Nebula background
            nebulaBackground

            // Star connections
            Canvas { context, canvasSize in
                drawConnections(context: context, size: canvasSize)
            }

            // Stars
            ForEach(stars.indices, id: \.self) { index in
                starView(for: stars[index], index: index)
            }

            // Center percentage
            centerLabel
        }
        .frame(width: size, height: size)
        .onAppear {
            generateStars()
            startAnimations()
        }
        .onChange(of: progress) { _, _ in
            updateStarActivity()
        }
    }

    // MARK: - Subviews

    private var nebulaBackground: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        accentColor.opacity(0.2 * glowIntensity),
                        Theme.CelestialColors.void
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .overlay(
                SwiftUI.Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.3),
                                accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    private var centerLabel: some View {
        Text("\(Int(progress * 100))%")
            .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .contentTransition(.numericText())
    }

    private func starView(for star: ConstellationStar, index: Int) -> some View {
        let position = starPosition(for: star)
        let isActive = star.isActive
        let twinkleOffset = reduceMotion ? 0 : sin(animationPhase + Double(index) * 0.5) * 0.2

        return SwiftUI.Circle()
            .fill(isActive ? accentColor : Color.white.opacity(0.3))
            .frame(width: starSize(for: star), height: starSize(for: star))
            .shadow(
                color: isActive ? accentColor.opacity(0.6 + twinkleOffset) : .clear,
                radius: isActive ? 4 : 0
            )
            .scaleEffect(isActive ? 1.0 + twinkleOffset * 0.3 : 0.7)
            .position(position)
            .animation(.easeInOut(duration: 0.5), value: isActive)
    }

    // MARK: - Drawing

    private func drawConnections(context: GraphicsContext, size: CGSize) {
        for i in 0..<stars.count {
            let nextIndex = (i + 1) % stars.count
            guard i < stars.count - 1 else { continue }

            let start = starPosition(for: stars[i], in: size)
            let end = starPosition(for: stars[nextIndex], in: size)

            let isActive = stars[i].isActive && stars[nextIndex].isActive

            var path = Path()
            path.move(to: start)
            path.addLine(to: end)

            context.stroke(
                path,
                with: .color(isActive ? accentColor.opacity(0.5) : Color.white.opacity(0.1)),
                lineWidth: isActive ? 1.5 : 0.5
            )
        }
    }

    // MARK: - Helpers

    private func generateStars() {
        stars = (0..<starCount).map { index in
            let angle = (Double(index) / Double(starCount)) * 2 * .pi - .pi / 2
            let radiusVariation = 0.3 + Double.random(in: 0...0.1)

            return ConstellationStar(
                id: UUID(),
                normalizedPosition: CGPoint(
                    x: 0.5 + cos(angle) * radiusVariation,
                    y: 0.5 + sin(angle) * radiusVariation
                ),
                isActive: Double(index) / Double(starCount) <= progress,
                size: Double.random(in: 0.8...1.2)
            )
        }
    }

    private func updateStarActivity() {
        for i in stars.indices {
            let threshold = Double(i) / Double(starCount)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                stars[i].isActive = threshold < progress
            }
        }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            animationPhase = 2 * .pi
        }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }

    private func starPosition(for star: ConstellationStar, in canvasSize: CGSize? = nil) -> CGPoint {
        let containerSize = canvasSize ?? CGSize(width: size, height: size)
        return CGPoint(
            x: star.normalizedPosition.x * containerSize.width,
            y: star.normalizedPosition.y * containerSize.height
        )
    }

    private func starSize(for star: ConstellationStar) -> CGFloat {
        size * 0.08 * star.size
    }
}

// MARK: - Constellation Star Model
struct ConstellationStar: Identifiable {
    let id: UUID
    let normalizedPosition: CGPoint  // 0-1 range
    var isActive: Bool
    let size: Double  // Relative size multiplier
}

// MARK: - Goal Progress Ring
/// Alternative progress visualization - clean circular progress ring
struct GoalProgressRing: View {
    let progress: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6
    var accentColor: Color = Theme.Colors.aiPurple

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            SwiftUI.Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            // Progress ring
            SwiftUI.Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [accentColor, accentColor.opacity(0.5), accentColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Percentage
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Goal Status Orb
/// Shows goal status with animated state
struct GoalStatusOrb: View {
    let goal: Goal
    var size: CGFloat = 60

    private var statusColor: Color {
        if goal.isCompleted {
            return Theme.Colors.success
        } else if goal.isOverdue {
            return Theme.Colors.error
        } else if goal.isCheckInDue {
            return Theme.Colors.warning
        }
        return goal.themeColor
    }

    private var statusIcon: String {
        if goal.isCompleted {
            return "checkmark"
        } else if goal.isOverdue {
            return "exclamationmark"
        } else if goal.isCheckInDue {
            return "bell.fill"
        }
        return goal.themeIcon
    }

    var body: some View {
        ZStack {
            // Use constellation for active goals, ring for completed
            if goal.isCompleted {
                GoalProgressRing(
                    progress: 1.0,
                    size: size,
                    accentColor: statusColor
                )
            } else {
                ConstellationProgressOrb(
                    progress: goal.progress,
                    size: size,
                    accentColor: statusColor
                )
            }

            // Overlay icon for special states
            if goal.isOverdue || goal.isCheckInDue {
                SwiftUI.Circle()
                    .fill(statusColor)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        Image(systemName: statusIcon)
                            .font(.system(size: size * 0.15, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: size * 0.35, y: -size * 0.35)
            }
        }
    }
}

// MARK: - Previews
#Preview("Constellation Progress") {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            ConstellationProgressOrb(progress: 0.0, size: 80)
            ConstellationProgressOrb(progress: 0.25, size: 80)
            ConstellationProgressOrb(progress: 0.5, size: 80)
        }
        HStack(spacing: 24) {
            ConstellationProgressOrb(progress: 0.75, size: 80, accentColor: Theme.Colors.aiCyan)
            ConstellationProgressOrb(progress: 1.0, size: 80, accentColor: Theme.Colors.success)
        }
    }
    .padding()
    .background(Theme.CelestialColors.void)
}

#Preview("Progress Ring") {
    HStack(spacing: 24) {
        GoalProgressRing(progress: 0.25, size: 60)
        GoalProgressRing(progress: 0.5, size: 60)
        GoalProgressRing(progress: 0.75, size: 60)
        GoalProgressRing(progress: 1.0, size: 60, accentColor: Theme.Colors.success)
    }
    .padding()
    .background(Theme.CelestialColors.void)
}
