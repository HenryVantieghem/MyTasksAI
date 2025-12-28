//
//  GlassConstellationProgress.swift
//  Veloce
//
//  Ultra-Premium Liquid Glass Constellation Progress Indicator
//  Features glass circle nodes, animated connecting lines, morphing transitions,
//  and pulsing glow effects for the current step.
//

import SwiftUI

// MARK: - Glass Constellation Progress

struct GlassConstellationProgress<Step: Identifiable & Equatable & CaseIterable>: View where Step.AllCases: RandomAccessCollection {
    let steps: Step.AllCases
    let currentStep: Step
    let namespace: Namespace.ID

    @State private var pulsePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentIndex: Int {
        steps.firstIndex(where: { $0 == currentStep }).flatMap { steps.distance(from: steps.startIndex, to: $0) } ?? 0
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                ConstellationNode(
                    isComplete: index < currentIndex,
                    isCurrent: index == currentIndex,
                    isFuture: index > currentIndex,
                    pulsePhase: pulsePhase,
                    namespace: namespace,
                    nodeId: "node_\(index)"
                )

                // Connecting line (except after last node)
                if index < steps.count - 1 {
                    ConstellationLine(
                        isComplete: index < currentIndex,
                        isCurrent: index == currentIndex
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .onAppear {
            startPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        guard !reduceMotion else { return }

        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            pulsePhase = 1
        }
    }
}

// MARK: - Constellation Node

private struct ConstellationNode: View {
    let isComplete: Bool
    let isCurrent: Bool
    let isFuture: Bool
    let pulsePhase: Double
    let namespace: Namespace.ID
    let nodeId: String

    private var nodeSize: CGFloat {
        isCurrent ? 10 : 6
    }

    private var nodeColor: Color {
        if isComplete {
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        } else if isCurrent {
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        } else {
            return Color.white.opacity(0.3)
        }
    }

    var body: some View {
        ZStack {
            // Outer glow for current node
            if isCurrent {
                Circle()
                    .fill(LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.4))
                    .frame(width: 18, height: 18)
                    .blur(radius: 4)
                    .scaleEffect(1 + pulsePhase * 0.15)
            }

            // Main node
            Circle()
                .fill(nodeColor)
                .frame(width: nodeSize, height: nodeSize)
                .overlay(
                    Circle()
                        .stroke(
                            isCurrent
                            ? LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.6)
                            : Color.clear,
                            lineWidth: 1
                        )
                        .scaleEffect(1.3)
                )
                .matchedGeometryEffect(id: nodeId, in: namespace)

            // Checkmark for completed nodes
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 4, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 20, height: 20)
        .animation(LiquidGlassDesignSystem.Springs.ui, value: isCurrent)
        .animation(LiquidGlassDesignSystem.Springs.ui, value: isComplete)
    }
}

// MARK: - Constellation Line

private struct ConstellationLine: View {
    let isComplete: Bool
    let isCurrent: Bool

    private var lineColor: Color {
        if isComplete {
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen.opacity(0.6)
        } else if isCurrent {
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.4)
        } else {
            return Color.white.opacity(0.15)
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(lineColor)
            .frame(width: 8, height: 2)
            .animation(LiquidGlassDesignSystem.Springs.ui, value: isComplete)
            .animation(LiquidGlassDesignSystem.Springs.ui, value: isCurrent)
    }
}

// MARK: - Compact Glass Progress (Alternative)

struct CompactGlassProgress<Step: Identifiable & Equatable & CaseIterable>: View where Step.AllCases: RandomAccessCollection {
    let steps: Step.AllCases
    let currentStep: Step

    private var currentIndex: Int {
        steps.firstIndex(where: { $0 == currentStep }).flatMap { steps.distance(from: steps.startIndex, to: $0) } ?? 0
    }

    private var progress: Double {
        Double(currentIndex) / Double(max(steps.count - 1, 1))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)

                // Progress fill with gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                                LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(LiquidGlassDesignSystem.Springs.focus, value: currentIndex)

                // Current position indicator
                Circle()
                    .fill(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                    .frame(width: 10, height: 10)
                    .shadow(color: LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.5), radius: 6)
                    .offset(x: geometry.size.width * progress - 5)
                    .animation(LiquidGlassDesignSystem.Springs.focus, value: currentIndex)
            }
        }
        .frame(height: 10)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Expanded Constellation Progress (For larger displays)

struct ExpandedConstellationProgress<Step: Identifiable & Equatable & CaseIterable & RawRepresentable & Hashable>: View
where Step.AllCases: RandomAccessCollection, Step.RawValue == Int {
    let steps: Step.AllCases
    let currentStep: Step
    let labels: [Step: String]

    @State private var pulsePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentIndex: Int {
        currentStep.rawValue
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 8) {
                    // Node
                    ExpandedNode(
                        isComplete: index < currentIndex,
                        isCurrent: index == currentIndex,
                        pulsePhase: pulsePhase
                    )

                    // Label (if provided)
                    if let label = labels[step] {
                        Text(label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(
                                index <= currentIndex
                                ? Color.white.opacity(0.8)
                                : Color.white.opacity(0.4)
                            )
                            .lineLimit(1)
                    }
                }

                // Connecting line
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(
                            index < currentIndex
                            ? LiquidGlassDesignSystem.VibrantAccents.auroraGreen.opacity(0.5)
                            : Color.white.opacity(0.15)
                        )
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .offset(y: -10) // Align with nodes
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .onAppear {
            startPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        guard !reduceMotion else { return }

        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            pulsePhase = 1
        }
    }
}

private struct ExpandedNode: View {
    let isComplete: Bool
    let isCurrent: Bool
    let pulsePhase: Double

    var body: some View {
        ZStack {
            // Glow for current
            if isCurrent {
                Circle()
                    .fill(LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .blur(radius: 4)
                    .scaleEffect(1 + pulsePhase * 0.2)
            }

            // Node
            Circle()
                .fill(
                    isComplete
                    ? LiquidGlassDesignSystem.VibrantAccents.auroraGreen
                    : (isCurrent ? LiquidGlassDesignSystem.VibrantAccents.electricCyan : Color.white.opacity(0.2))
                )
                .frame(width: isCurrent ? 14 : 10, height: isCurrent ? 14 : 10)

            // Checkmark
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Equatable Extension

private extension Equatable {
    func isEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

// MARK: - Preview

#Preview("Glass Constellation Progress") {
    struct PreviewWrapper: View {
        @State private var currentStep: CosmicOnboardingStep = .featureFocus
        @Namespace private var namespace

        var body: some View {
            ZStack {
                Theme.CelestialColors.voidDeep
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Glass Constellation Progress")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    GlassConstellationProgress(
                        steps: CosmicOnboardingStep.allCases,
                        currentStep: currentStep,
                        namespace: namespace
                    )

                    Button("Next Step") {
                        let allSteps = CosmicOnboardingStep.allCases
                        if let currentIndex = allSteps.firstIndex(of: currentStep),
                           currentIndex < allSteps.count - 1 {
                            withAnimation {
                                currentStep = allSteps[allSteps.index(after: currentIndex)]
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}
