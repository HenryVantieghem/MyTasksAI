//
//  ConstellationProgress.swift
//  Veloce
//
//  Constellation Progress Indicator
//  Beautiful star-based progress for onboarding journey
//

import SwiftUI

// MARK: - Constellation Progress

struct ConstellationProgress: View {
    let totalSteps: Int
    let currentStep: Int
    let completedSteps: Set<Int>

    @State private var lineProgress: [CGFloat]
    @State private var starPulse: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5

    init(totalSteps: Int, currentStep: Int, completedSteps: Set<Int> = []) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
        self.completedSteps = completedSteps
        self._lineProgress = State(initialValue: Array(repeating: 0, count: max(0, totalSteps - 1)))
    }

    var body: some View {
        GeometryReader { geometry in
            let spacing = geometry.size.width / CGFloat(totalSteps - 1)

            ZStack {
                // Connection lines
                ForEach(0..<totalSteps - 1, id: \.self) { index in
                    connectionLine(at: index, spacing: spacing)
                }

                // Stars
                ForEach(0..<totalSteps, id: \.self) { index in
                    constellationStar(at: index, spacing: spacing)
                }
            }
        }
        .frame(height: 50)
        .onAppear {
            animateLines()
            startStarPulse()
        }
        .onChange(of: currentStep) { _, _ in
            animateLines()
        }
    }

    // MARK: - Connection Line

    private func connectionLine(at index: Int, spacing: CGFloat) -> some View {
        let startX = CGFloat(index) * spacing
        let isCompleted = index < currentStep

        return ZStack {
            // Background line
            Path { path in
                path.move(to: CGPoint(x: startX, y: 25))
                path.addLine(to: CGPoint(x: startX + spacing, y: 25))
            }
            .stroke(
                Theme.Colors.glassBorder.opacity(0.3),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )

            // Animated progress line
            if isCompleted || index == currentStep - 1 {
                Path { path in
                    path.move(to: CGPoint(x: startX, y: 25))
                    path.addLine(to: CGPoint(x: startX + spacing, y: 25))
                }
                .trim(from: 0, to: index < lineProgress.count ? lineProgress[index] : 0)
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue, Theme.Colors.aiCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 4)
            }
        }
    }

    // MARK: - Constellation Star

    private func constellationStar(at index: Int, spacing: CGFloat) -> some View {
        let xPos = CGFloat(index) * spacing
        let state = starState(for: index)

        return ZStack {
            // Glow for current/completed
            if state != .upcoming {
                Circle()
                    .fill(starGlowColor(for: state))
                    .frame(width: 30, height: 30)
                    .blur(radius: 8)
                    .opacity(state == .current ? glowOpacity : 0.3)
            }

            // Star shape
            Circle()
                .fill(starFillColor(for: state))
                .frame(width: starSize(for: state))
                .overlay(
                    Circle()
                        .stroke(starBorderColor(for: state), lineWidth: state == .upcoming ? 1.5 : 0)
                )
                .scaleEffect(state == .current ? starPulse : 1.0)

            // Checkmark for completed
            if state == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Step number for upcoming
            if state == .upcoming {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .position(x: xPos, y: 25)
    }

    // MARK: - Star State

    private enum StarState {
        case completed, current, upcoming
    }

    private func starState(for index: Int) -> StarState {
        if index < currentStep || completedSteps.contains(index) {
            return .completed
        } else if index == currentStep {
            return .current
        }
        return .upcoming
    }

    // MARK: - Star Styling

    private func starSize(for state: StarState) -> CGFloat {
        switch state {
        case .completed: return 18
        case .current: return 22
        case .upcoming: return 16
        }
    }

    private func starFillColor(for state: StarState) -> Color {
        switch state {
        case .completed: return Theme.Colors.success
        case .current: return Theme.Colors.aiPurple
        case .upcoming: return Color.clear
        }
    }

    private func starBorderColor(for state: StarState) -> Color {
        switch state {
        case .completed, .current: return Color.clear
        case .upcoming: return Theme.Colors.glassBorder.opacity(0.5)
        }
    }

    private func starGlowColor(for state: StarState) -> Color {
        switch state {
        case .completed: return Theme.Colors.success
        case .current: return Theme.Colors.aiPurple
        case .upcoming: return Color.clear
        }
    }

    // MARK: - Animations

    private func animateLines() {
        for index in 0..<totalSteps - 1 {
            let shouldAnimate = index < currentStep
            let delay = Double(index) * 0.1

            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                if index < lineProgress.count {
                    lineProgress[index] = shouldAnimate ? 1.0 : 0
                }
            }
        }
    }

    private func startStarPulse() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            starPulse = 1.15
            glowOpacity = 0.8
        }
    }
}

// MARK: - Simple Constellation Progress

/// Simpler version that just takes current step index
struct SimpleConstellationProgress: View {
    let steps: [String]
    let currentIndex: Int

    var body: some View {
        ConstellationProgress(
            totalSteps: steps.count,
            currentStep: currentIndex,
            completedSteps: Set(0..<currentIndex)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        ConstellationProgress(totalSteps: 5, currentStep: 0)

        ConstellationProgress(totalSteps: 5, currentStep: 2)

        ConstellationProgress(totalSteps: 5, currentStep: 4)

        ConstellationProgress(totalSteps: 5, currentStep: 5, completedSteps: Set(0..<5))
    }
    .padding(.horizontal, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(VoidBackground.onboarding)
}
