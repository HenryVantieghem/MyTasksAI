//
//  QuickActionBar.swift
//  Veloce
//
//  Prominent action bar for task detail sheet
//  Complete, Focus, Schedule - quick actions
//

import SwiftUI

// MARK: - Quick Action Bar

struct QuickActionBar: View {
    let taskTypeColor: Color
    let isCompleted: Bool
    let onComplete: () -> Void
    let onFocus: () -> Void
    let onSchedule: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // Complete button (primary when not completed)
            SmartActionButton(
                title: isCompleted ? "Completed" : "Complete",
                icon: "checkmark",
                color: Theme.CelestialColors.auroraGreen,
                isPrimary: !isCompleted,
                isDisabled: isCompleted,
                action: onComplete
            )
            .accessibilityLabel(isCompleted ? "Task completed" : "Mark task as complete")
            .accessibilityHint(isCompleted ? "" : "Double tap to complete this task")

            // Focus button
            SmartActionButton(
                title: "Focus",
                icon: "scope",
                color: taskTypeColor,
                isPrimary: false,
                isDisabled: isCompleted,
                action: onFocus
            )
            .accessibilityLabel("Start focus session")
            .accessibilityHint("Double tap to start a focused work session on this task")

            // Schedule button
            SmartActionButton(
                title: "Schedule",
                icon: "calendar.badge.clock",
                color: Theme.CelestialColors.plasmaCore,
                isPrimary: false,
                isDisabled: isCompleted,
                action: onSchedule
            )
            .accessibilityLabel("Schedule task")
            .accessibilityHint("Double tap to set a time for this task")
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Smart Action Button

struct SmartActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isPrimary: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            HapticsService.shared.impact(isPrimary ? .medium : .light)
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 13, weight: .semibold)

                Text(title)
                    .font(.system(size: 13, weight: isPrimary ? .bold : .semibold))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(background)
            .overlay(border)
            .clipShape(Capsule())
        }
        .buttonStyle(SmartActionButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    private var foregroundColor: Color {
        if isPrimary {
            return Theme.CelestialColors.void
        }
        return color
    }

    private var background: some View {
        Group {
            if isPrimary {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else {
                Capsule()
                    .fill(color.opacity(0.15))
            }
        }
    }

    private var border: some View {
        Group {
            if !isPrimary {
                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Button Style

struct SmartActionButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack(spacing: 24) {
            QuickActionBar(
                taskTypeColor: Theme.TaskCardColors.create,
                isCompleted: false,
                onComplete: { print("Complete") },
                onFocus: { print("Focus") },
                onSchedule: { print("Schedule") }
            )
            .padding(.horizontal)

            QuickActionBar(
                taskTypeColor: Theme.TaskCardColors.communicate,
                isCompleted: true,
                onComplete: {},
                onFocus: {},
                onSchedule: {}
            )
            .padding(.horizontal)
        }
    }
}
