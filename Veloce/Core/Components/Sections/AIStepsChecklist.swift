//
//  AIStepsChecklist.swift
//  Veloce
//

import SwiftUI

struct AIStepsChecklist: View {
    let steps: [String]
    @State private var completedSteps: Set<Int> = []
    @State private var expandedSteps: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundStyle(Theme.Colors.aiPurple)
                Text("AI-Generated Steps")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(completedSteps.count)/\(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                StepRow(
                    index: index + 1,
                    text: step,
                    isCompleted: completedSteps.contains(index),
                    isExpanded: expandedSteps.contains(index),
                    onToggle: { toggleStep(index) },
                    onExpand: { toggleExpand(index) }
                )
            }
        }
        .padding()
        .voidCard()
    }

    private func toggleStep(_ index: Int) {
        withAnimation(.spring()) {
            if completedSteps.contains(index) {
                completedSteps.remove(index)
            } else {
                completedSteps.insert(index)
                HapticsService.shared.taskComplete()
            }
        }
    }

    private func toggleExpand(_ index: Int) {
        withAnimation(.spring()) {
            if expandedSteps.contains(index) {
                expandedSteps.remove(index)
            } else {
                expandedSteps.insert(index)
            }
        }
    }
}

struct StepRow: View {
    let index: Int
    let text: String
    let isCompleted: Bool
    let isExpanded: Bool
    var onToggle: () -> Void
    var onExpand: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Theme.Colors.success : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isCompleted {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    } else {
                        Text("\(index)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(isCompleted ? .white.opacity(0.5) : .white)
                .strikethrough(isCompleted)
                .lineLimit(isExpanded ? nil : 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onExpand)
        }
        .padding(.vertical, 4)
    }
}
