//
//  CelestialTabBar.swift
//  Veloce
//
//  Custom Floating Tab Bar with Celestial Void Aesthetic
//  Replaces native TabView tab bar with premium glass styling
//

import SwiftUI

// MARK: - Celestial Tab Bar

/// Custom floating tab bar with nebula glass effect
struct CelestialTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                CelestialTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: tabAnimation
                ) {
                    withAnimation(Theme.Animation.spring) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 40)
        // Bottom padding handled by container (MainContainerView)
    }
}

// MARK: - Celestial Tab Item

/// Individual tab item with selection animation
struct CelestialTabItem: View {
    let tab: MainTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Selection glow background
                    if isSelected {
                        Circle()
                            .fill(AppColors.accentPrimary.opacity(0.2))
                            .blur(radius: 8)
                            .frame(width: 44, height: 44)
                            .matchedGeometryEffect(id: "glow", in: namespace)
                    }

                    // Icon
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected
                                ? AppColors.textPrimary
                                : AppColors.textTertiary
                        )
                        .frame(width: 44, height: 32)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }

                // Label
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(
                        isSelected
                            ? AppColors.textPrimary
                            : AppColors.textTertiary
                    )
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabItemButtonStyle())
    }
}

// MARK: - Tab Item Button Style

/// Custom button style for tab items without default press effects
private struct TabItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Celestial Tab Bar") {
    ZStack {
        AppColors.backgroundPrimary
            .ignoresSafeArea()

        VStack {
            Spacer()
            CelestialTabBar(selectedTab: .constant(.tasks))
        }
    }
    .preferredColorScheme(.dark)
}
