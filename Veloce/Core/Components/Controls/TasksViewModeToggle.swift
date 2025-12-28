//
//  TasksViewModeToggle.swift
//  Veloce
//
//  Liquid Glass Toggle for Smart List vs Kanban View
//  Features: matchedGeometryEffect indicator, glass capsule, smooth transitions
//

import SwiftUI

// MARK: - Tasks Display Mode

enum TasksDisplayMode: String, CaseIterable {
    case smartList = "list"
    case kanban = "board"

    var icon: String {
        switch self {
        case .smartList: return "list.bullet"
        case .kanban: return "rectangle.split.3x1"
        }
    }

    var label: String {
        switch self {
        case .smartList: return "List"
        case .kanban: return "Board"
        }
    }
}

// MARK: - Tasks View Mode Toggle

struct TasksViewModeToggle: View {
    @Binding var mode: TasksDisplayMode
    @Namespace private var animation

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TasksDisplayMode.allCases, id: \.self) { displayMode in
                toggleButton(for: displayMode)
            }
        }
        .padding(4)
        .background {
            if reduceTransparency {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            Color.clear,
                            Theme.AdaptiveColors.aiPrimary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .adaptiveGlassCapsule()
    }

    // MARK: - Toggle Button

    @ViewBuilder
    private func toggleButton(for displayMode: TasksDisplayMode) -> some View {
        let isSelected = mode == displayMode

        Button {
            if mode != displayMode {
                HapticsService.shared.selectionFeedback()
                withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)) {
                    mode = displayMode
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: displayMode.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(displayMode.label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    selectionIndicator
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection Indicator

    private var selectionIndicator: some View {
        ZStack {
            if reduceTransparency {
                Capsule()
                    .fill(Theme.AdaptiveColors.aiPrimary.opacity(0.2))
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.AdaptiveColors.aiPrimary.opacity(0.15),
                                Theme.AdaptiveColors.aiSecondary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Theme.AdaptiveColors.aiPrimary.opacity(0.4),
                            Theme.AdaptiveColors.aiSecondary.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        }
        .matchedGeometryEffect(id: "modeIndicator", in: animation)
    }
}

// MARK: - Compact Variant (Icon Only)

struct TasksViewModeToggleCompact: View {
    @Binding var mode: TasksDisplayMode
    @Namespace private var animation

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TasksDisplayMode.allCases, id: \.self) { displayMode in
                let isSelected = mode == displayMode

                Button {
                    if mode != displayMode {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)) {
                            mode = displayMode
                        }
                    }
                } label: {
                    Image(systemName: displayMode.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isSelected ? .primary : .tertiary)
                        .frame(width: 36, height: 32)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.AdaptiveColors.aiPrimary.opacity(0.15))
                                    .matchedGeometryEffect(id: "compactIndicator", in: animation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
        }
    }
}

// MARK: - Preview

#Preview("View Mode Toggle") {
    struct PreviewContainer: View {
        @State private var mode: TasksDisplayMode = .smartList
        @State private var compactMode: TasksDisplayMode = .kanban

        var body: some View {
            ZStack {
                Theme.CelestialColors.void.ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("View Mode Toggle")
                        .font(.headline)
                        .foregroundStyle(.white)

                    TasksViewModeToggle(mode: $mode)

                    Text("Current: \(mode.label)")
                        .foregroundStyle(.secondary)

                    Divider()
                        .background(.white.opacity(0.2))

                    Text("Compact Variant")
                        .font(.headline)
                        .foregroundStyle(.white)

                    TasksViewModeToggleCompact(mode: $compactMode)

                    Text("Current: \(compactMode.label)")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }

    return PreviewContainer()
        .preferredColorScheme(.dark)
}
