//
//  CelestialTabBar.swift
//  Veloce
//
//  Minimal Liquid Glass Tab Bar
//  iOS 26 Glass effect with elegant animations - NO center orb
//

import SwiftUI

// MARK: - Celestial Tab Bar

/// Minimal unified tab bar with liquid glass effect
/// Single continuous glass pill, no center orb
struct CelestialTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var morphAnimation

    var streakDays: Int = 0
    var recentPointsEarned: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                MinimalTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: morphAnimation
                ) {
                    selectTab(tab)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: Capsule())
        .padding(.horizontal, 24)
        .shadow(color: Theme.Colors.aiPurple.opacity(0.2), radius: 20, y: 5)
    }

    private func selectTab(_ tab: MainTab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTab = tab
        }
        HapticsService.shared.tabSwitch()
    }
}

// MARK: - Minimal Tab Item

struct MinimalTabItem: View {
    let tab: MainTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isPressed = false

    private var displayName: String {
        tab.rawValue
    }

    private var itemWidth: CGFloat {
        isSelected ? 80 : 52
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: isSelected ? 18 : 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .symbolEffect(.bounce.up, value: isSelected)

                if isSelected {
                    Text(displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(width: itemWidth, height: 48)
            .background {
                if isSelected {
                    Capsule()
                        .fill(tabAccentColor.opacity(0.2))
                        .matchedGeometryEffect(id: "selectedBg", in: namespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(TabButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }

    private var tabAccentColor: Color {
        switch tab {
        case .tasks: return Theme.Colors.aiPurple
        case .calendar: return Theme.Colors.aiBlue
        case .focus: return Theme.Colors.aiAmber
        case .momentum: return Theme.Colors.aiGreen
        case .ai: return Theme.Colors.aiCyan
        }
    }
}

// MARK: - Tab Button Style

private struct TabButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview("Minimal Glass Tab Bar") {
    ZStack {
        VoidBackground.tasks

        VStack {
            Spacer()
            CelestialTabBar(selectedTab: .constant(.tasks))
                .padding(.bottom, 8)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("All Tabs") {
    struct PreviewContainer: View {
        @State private var selectedTab: MainTab = .tasks

        var body: some View {
            ZStack {
                VoidBackground.tasks

                VStack {
                    ForEach(MainTab.allCases, id: \.self) { tab in
                        if selectedTab == tab {
                            VStack {
                                Image(systemName: tab.selectedIcon)
                                    .font(.system(size: 60))
                                Text(tab.rawValue)
                                    .font(.title)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }

                    CelestialTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 8)
                }
            }
        }
    }

    return PreviewContainer()
        .preferredColorScheme(.dark)
}
