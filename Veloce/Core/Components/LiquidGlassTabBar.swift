//
//  LiquidGlassTabBar.swift
//  Veloce
//
//  iOS 26 Native Liquid Glass Tab Bar
//  Uses GlassEffectContainer with proper morphing animations
//

import SwiftUI

// MARK: - Liquid Glass Tab Bar

/// Native iOS 26 Liquid Glass tab bar with morphing animations
/// Uses GlassEffectContainer for optimal rendering performance
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var glassNamespace

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    LiquidGlassTabItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: glassNamespace
                    ) {
                        selectTab(tab)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .glassEffect(.regular.interactive(), in: Capsule())
        .padding(.horizontal, 20)
        .shadow(color: Theme.CelestialColors.nebulaCore.opacity(0.25), radius: 24, y: 8)
        .animation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
    }

    private func selectTab(_ tab: MainTab) {
        guard selectedTab != tab else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedTab = tab
        }
        HapticsService.shared.tabSwitch()
    }
}

// MARK: - Liquid Glass Tab Item

struct LiquidGlassTabItem: View {
    let tab: MainTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tabColor: Color {
        switch tab {
        case .tasks: return Theme.CelestialColors.nebulaCore       // Purple
        case .calendar: return Theme.CelestialColors.nebulaGlow    // Blue
        case .focus: return Color(hex: "F59E0B")                   // Amber
        case .momentum: return Color(hex: "10B981")                // Green
        case .ai: return Theme.CelestialColors.nebulaEdge          // Cyan
        }
    }

    private var itemWidth: CGFloat {
        isSelected ? 72 : 48
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Icon with symbol effect
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: isSelected ? 18 : 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? tabColor : Theme.CelestialColors.starDim)
                        .symbolEffect(.bounce.up.byLayer, value: isSelected)
                        .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                }

                // Label appears when selected
                if isSelected {
                    Text(tab.rawValue)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(tabColor)
                        .lineLimit(1)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
            .frame(width: itemWidth, height: 44)
            .background {
                if isSelected {
                    // Selected background with glass effect
                    Capsule()
                        .fill(tabColor.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(tabColor.opacity(0.25), lineWidth: 1)
                        )
                        .matchedGeometryEffect(id: "selectedTab", in: namespace)
                        .glassEffectID("selectedTab", in: namespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(LiquidGlassTabButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to \(tab.rawValue)")
    }
}

// MARK: - Tab Button Style

private struct LiquidGlassTabButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Compact Variant

/// Compact version for smaller screens or when keyboard is active
struct LiquidGlassTabBarCompact: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 24) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    HapticsService.shared.tabSwitch()
                } label: {
                    Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        .symbolEffect(.bounce.up, value: selectedTab == tab)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive(), in: Capsule())
    }
}

// MARK: - Preview

#Preview("Liquid Glass Tab Bar") {
    struct PreviewContainer: View {
        @State private var selectedTab: MainTab = .tasks

        var body: some View {
            ZStack {
                VoidBackground.tasks

                VStack {
                    // Page content indicator
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: selectedTab.selectedIcon)
                            .font(.system(size: 72, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text(selectedTab.rawValue)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxHeight: .infinity)

                    // Tab bar
                    LiquidGlassTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 8)
                }
            }
        }
    }

    return PreviewContainer()
        .preferredColorScheme(.dark)
}

#Preview("Tab Bar States") {
    VStack(spacing: 40) {
        ForEach(MainTab.allCases, id: \.self) { tab in
            LiquidGlassTabBar(selectedTab: .constant(tab))
        }
    }
    .padding()
    .background(VoidBackground.tasks)
    .preferredColorScheme(.dark)
}

#Preview("Compact Tab Bar") {
    ZStack {
        VoidBackground.tasks

        VStack {
            Spacer()
            LiquidGlassTabBarCompact(selectedTab: .constant(.tasks))
                .padding(.bottom, 20)
        }
    }
    .preferredColorScheme(.dark)
}
