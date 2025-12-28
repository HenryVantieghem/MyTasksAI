//
//  BlockingTabBar.swift
//  Veloce
//
//  Compact horizontal tab bar for App Blocking section
//  Liquid Glass styled with smooth selection animation
//

import SwiftUI

// MARK: - Blocking Tab Bar

struct BlockingTabBar: View {
    @Binding var selectedTab: BlockingTab

    @Namespace private var tabNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Design tokens
    private let tabHeight: CGFloat = 32
    private let tabSpacing: CGFloat = 4
    private let horizontalPadding: CGFloat = 12
    private let cornerRadius: CGFloat = 10

    var body: some View {
        HStack(spacing: tabSpacing) {
            ForEach(BlockingTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .glassEffect(
            .regular.interactive(true),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.2),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(for tab: BlockingTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            guard selectedTab != tab else { return }

            if !reduceMotion {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedTab = tab
                }
            } else {
                selectedTab = tab
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))

                Text(tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, horizontalPadding)
            .frame(height: tabHeight)
            .background {
                if isSelected {
                    selectedBackground(for: tab)
                }
            }
        }
        .buttonStyle(TabButtonStyle())
    }

    // MARK: - Selected Background

    @ViewBuilder
    private func selectedBackground(for tab: BlockingTab) -> some View {
        Capsule()
            .fill(Theme.Colors.aiCyan.opacity(0.3))
            .overlay {
                Capsule()
                    .stroke(Theme.Colors.aiCyan.opacity(0.4), lineWidth: 0.5)
            }
            .shadow(color: Theme.Colors.aiCyan.opacity(0.25), radius: 4, y: 1)
            .matchedGeometryEffect(id: "tabSelection", in: tabNamespace)
    }
}

// MARK: - Tab Button Style

private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Blocking Tab Extension

extension BlockingTab {
    var icon: String {
        switch self {
        case .overview: return "chart.pie.fill"
        case .schedules: return "calendar"
        case .groups: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Compact Blocking Tab Bar (Alternative - Segmented Style)

struct CompactBlockingSegments: View {
    @Binding var selectedTab: BlockingTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BlockingTab.allCases, id: \.self) { tab in
                segmentButton(for: tab)

                if tab != BlockingTab.allCases.last {
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 1, height: 20)
                }
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.5))
        }
    }

    @ViewBuilder
    private func segmentButton(for tab: BlockingTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedTab = tab
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            Text(tab.title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Theme.Colors.aiCyan : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Blocking Tab Bar") {
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
            Text("Capsule Style")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            BlockingTabBar(selectedTab: .constant(.overview))

            BlockingTabBar(selectedTab: .constant(.schedules))

            BlockingTabBar(selectedTab: .constant(.groups))

            Divider()
                .background(.white.opacity(0.2))

            Text("Segmented Style")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            CompactBlockingSegments(selectedTab: .constant(.overview))
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
