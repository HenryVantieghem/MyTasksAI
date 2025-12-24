//
//  ExecutionStepsModule.swift
//  MyTasksAI
//
//  AI-generated execution steps with progress tracking
//  Checklist interface with expandable reasoning
//

import SwiftUI

// MARK: - Execution Steps Module
struct ExecutionStepsModule: View {
    @Binding var steps: [ExecutionStep]
    let onStepToggled: (ExecutionStep) -> Void
    let onRefresh: () -> Void
    let isLoading: Bool

    private let accentColor = Theme.Colors.aiCyan

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            headerView

            // Content
            if isLoading {
                loadingView
            } else if steps.isEmpty {
                emptyStateView
            } else {
                stepsListView
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 14))
                    .foregroundStyle(accentColor)

                Text("EXECUTION STEPS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            // Progress indicator
            if !steps.isEmpty {
                Text(progressText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            // Refresh button
            Button {
                onRefresh()
                HapticsService.shared.selectionFeedback()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accentColor.opacity(0.7))
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
            }
            .disabled(isLoading)
        }
    }

    private var progressText: String {
        let completed = steps.filter { $0.isCompleted }.count
        return "\(completed)/\(steps.count)"
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: Theme.Spacing.sm) {
                    SwiftUI.Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 14)
                            .frame(maxWidth: index == 2 ? 150 : .infinity)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 60, height: 10)
                    }
                }
                .shimmer()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundStyle(accentColor.opacity(0.5))

            Text("No steps generated yet")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))

            Button {
                onRefresh()
            } label: {
                Text("Generate Steps")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
    }

    // MARK: - Steps List
    private var stepsListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                ExecutionStepRow(
                    step: binding(for: step),
                    isLast: index == steps.count - 1,
                    onToggle: { onStepToggled(step) }
                )
            }
        }
    }

    private func binding(for step: ExecutionStep) -> Binding<ExecutionStep> {
        guard let index = steps.firstIndex(where: { $0.id == step.id }) else {
            return .constant(step)
        }
        return $steps[index]
    }
}

// MARK: - Execution Step Row
struct ExecutionStepRow: View {
    @Binding var step: ExecutionStep
    let isLast: Bool
    let onToggle: () -> Void

    @State private var showReasoning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                // Checkbox with connector line
                VStack(spacing: 0) {
                    checkboxButton

                    if !isLast {
                        Rectangle()
                            .fill(step.isCompleted ? Theme.Colors.success.opacity(0.3) : Color.white.opacity(0.1))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 24)

                // Step content
                VStack(alignment: .leading, spacing: 6) {
                    // Description
                    Text(step.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .strikethrough(step.isCompleted)
                        .opacity(step.isCompleted ? 0.6 : 1)

                    // Meta info
                    HStack(spacing: Theme.Spacing.md) {
                        // Time estimate
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(step.estimatedMinutes) min")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.5))

                        // Expand reasoning button
                        if let reasoning = step.reasoning, !reasoning.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    showReasoning.toggle()
                                }
                                HapticsService.shared.selectionFeedback()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 9))
                                    Text("Why")
                                        .font(.system(size: 10, weight: .medium))
                                    Image(systemName: showReasoning ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundStyle(Theme.Colors.aiPurple)
                            }
                        }
                    }

                    // Reasoning (expandable)
                    if showReasoning, let reasoning = step.reasoning {
                        Text(reasoning)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.aiPurple.opacity(0.8))
                            .padding(.top, 4)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.bottom, isLast ? 0 : Theme.Spacing.md)
            }
        }
    }

    private var checkboxButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onToggle()
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            ZStack {
                SwiftUI.Circle()
                    .strokeBorder(
                        step.isCompleted ? Theme.Colors.success : Color.white.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 24, height: 24)

                if step.isCompleted {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        ExecutionStepsModule(
            steps: .constant([
                ExecutionStep(
                    id: UUID(),
                    description: "Open the project in Xcode",
                    estimatedMinutes: 2,
                    isCompleted: true,
                    orderIndex: 0,
                    reasoning: "Start by launching your development environment"
                ),
                ExecutionStep(
                    id: UUID(),
                    description: "Review the current implementation",
                    estimatedMinutes: 10,
                    isCompleted: false,
                    orderIndex: 1,
                    reasoning: "Understanding existing code prevents duplication"
                ),
                ExecutionStep(
                    id: UUID(),
                    description: "Write the new feature code",
                    estimatedMinutes: 25,
                    isCompleted: false,
                    orderIndex: 2,
                    reasoning: nil
                )
            ]),
            onStepToggled: { _ in },
            onRefresh: { },
            isLoading: false
        )
        .padding()
    }
}
