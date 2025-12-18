//
//  AppleNotesCheckbox.swift
//  MyTasksAI
//
//  Apple Notes-style checkbox component
//  Hollow circle when unchecked, filled with checkmark when checked
//

import SwiftUI

// MARK: - Apple Notes Checkbox

struct AppleNotesCheckbox: View {
    let isChecked: Bool
    let onToggle: () -> Void

    @State private var animationProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Configuration
    private let size: CGFloat = 22
    private let strokeWidth: CGFloat = 1.5
    private let checkmarkScale: CGFloat = 0.45

    var body: some View {
        Button(action: performToggle) {
            ZStack {
                // Outer circle
                Circle()
                    .stroke(
                        isChecked ? Theme.Colors.success : Theme.Colors.textTertiary.opacity(0.5),
                        lineWidth: strokeWidth
                    )
                    .frame(width: size, height: size)

                // Fill when checked
                if isChecked {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: size - strokeWidth * 2, height: size - strokeWidth * 2)
                        .scaleEffect(animationProgress)

                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: size * checkmarkScale, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(animationProgress)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onChange(of: isChecked) { _, newValue in
            if newValue {
                animateIn()
            } else {
                animationProgress = 0
            }
        }
        .onAppear {
            // Set initial state without animation
            animationProgress = isChecked ? 1 : 0
        }
        .accessibilityLabel(isChecked ? "Completed" : "Not completed")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to toggle completion")
    }

    // MARK: - Animation

    private func performToggle() {
        HapticsService.shared.selectionFeedback()
        onToggle()
    }

    private func animateIn() {
        guard !reduceMotion else {
            animationProgress = 1
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            animationProgress = 1
        }
    }
}

// MARK: - Compact Variant (for toolbar)

struct AppleNotesCheckboxIcon: View {
    let isActive: Bool

    private let size: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    isActive ? Theme.Colors.accent : Theme.Colors.textSecondary,
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)

            if isActive {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.2))
                    .frame(width: size - 4, height: size - 4)
            }
        }
    }
}

// MARK: - Preview

#Preview("Unchecked") {
    AppleNotesCheckbox(isChecked: false) {
        print("Toggled")
    }
    .padding()
}

#Preview("Checked") {
    AppleNotesCheckbox(isChecked: true) {
        print("Toggled")
    }
    .padding()
}

#Preview("Interactive") {
    struct PreviewWrapper: View {
        @State private var isChecked = false

        var body: some View {
            VStack(spacing: 20) {
                AppleNotesCheckbox(isChecked: isChecked) {
                    isChecked.toggle()
                }

                Text(isChecked ? "Checked" : "Unchecked")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
