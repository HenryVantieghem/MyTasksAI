//
//  CompactFlowPill.swift
//  Veloce
//
//  Ultra-compact Liquid Glass section toggle for Flow page
//  Apple-inspired minimal design with premium animations
//

import SwiftUI

// MARK: - Compact Flow Pill

struct CompactFlowPill: View {
    @Binding var selected: FocusSection

    @Namespace private var pillNamespace
    @State private var isPressed: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Design Tokens

    private let pillHeight: CGFloat = 36
    private let innerPadding: CGFloat = 3
    private let iconSize: CGFloat = 13
    private let textSize: CGFloat = 12
    private let segmentVerticalPadding: CGFloat = 7
    private let segmentHorizontalPadding: CGFloat = 14
    private let innerCornerRadius: CGFloat = 13

    var body: some View {
        HStack(spacing: 2) {
            ForEach([FocusSection.timer, .blocking], id: \.self) { section in
                pillSegment(for: section)
            }
        }
        .padding(innerPadding)
        .frame(height: pillHeight)
        .glassEffect(
            .regular.interactive(true),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.25),
                            .white.opacity(0.08),
                            .white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
    }

    // MARK: - Pill Segment

    @ViewBuilder
    private func pillSegment(for section: FocusSection) -> some View {
        let isSelected = selected == section

        Button {
            guard selected != section else { return }

            if !reduceMotion {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selected = section
                }
            } else {
                selected = section
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: iconSize, weight: isSelected ? .semibold : .medium))
                    .symbolRenderingMode(.hierarchical)

                Text(section.rawValue)
                    .font(.system(size: textSize, weight: .semibold))
                    .tracking(0.2)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            .padding(.vertical, segmentVerticalPadding)
            .padding(.horizontal, segmentHorizontalPadding)
            .background {
                if isSelected {
                    selectedBackground(for: section)
                }
            }
        }
        .buttonStyle(PillSegmentButtonStyle())
    }

    // MARK: - Selected Background

    @ViewBuilder
    private func selectedBackground(for section: FocusSection) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: section.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.35),
                                .white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: section.accentColor.opacity(0.4), radius: 6, y: 2)
            .matchedGeometryEffect(id: "pillSelection", in: pillNamespace)
    }
}

// MARK: - Pill Segment Button Style

private struct PillSegmentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - FocusSection Extension

extension FocusSection {
    var gradientColors: [Color] {
        switch self {
        case .timer:
            return [Theme.Colors.aiAmber, Theme.Colors.aiOrange]
        case .blocking:
            return [Theme.Colors.aiCyan, Theme.Colors.aiBlue]
        }
    }

    var accentColor: Color {
        switch self {
        case .timer:
            return Theme.Colors.aiAmber
        case .blocking:
            return Theme.Colors.aiCyan
        }
    }
}

// MARK: - Preview

#Preview("Compact Flow Pill") {
    ZStack {
        LinearGradient(
            colors: [
                Theme.CelestialColors.voidDeep,
                Theme.CelestialColors.void,
                Theme.CelestialColors.abyss
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            CompactFlowPill(selected: .constant(.timer))
            CompactFlowPill(selected: .constant(.blocking))

            // Size comparison
            VStack(spacing: 8) {
                Text("Height: 36pt")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                CompactFlowPill(selected: .constant(.timer))
                    .frame(width: 200)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
