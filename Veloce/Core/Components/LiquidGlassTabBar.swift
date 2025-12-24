//
//  LiquidGlassTabBar.swift
//  Veloce
//
//  iOS 26 Native Liquid Glass Tab Bar
//  Follows Apple's Liquid Glass Design Guidelines from WWDC 2025
//
//  Key Principles Applied:
//  - GlassEffectContainer for optimized multi-element rendering
//  - .glassEffect(.regular.interactive()) for navigation layer
//  - No custom shadows (Liquid Glass has built-in shadow layers)
//  - No over-tinting (reserve for primary actions only)
//  - .glassEffectID for fluid morphing animations
//  - System handles adaptive light/dark behavior
//

import SwiftUI

// MARK: - Liquid Glass Tab Bar

/// Native iOS 26 Liquid Glass floating pill tab bar
/// Uses GlassEffectContainer with proper morphing animations per Apple guidelines
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabBarNamespace

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        // GlassEffectContainer optimizes rendering for multiple glass elements
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    LiquidGlassTabItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: tabBarNamespace
                    ) {
                        selectTab(tab)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        // Apply Liquid Glass to the entire pill container
        // Using .regular variant (default) - most versatile, works in any context
        // .interactive() enables proper touch feedback on iOS
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding(.horizontal, 24)
        // No custom shadows - Liquid Glass has built-in adaptive shadow layers
        // that respond to content underneath automatically
        .animation(
            reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.8),
            value: selectedTab
        )
    }

    private func selectTab(_ tab: AppTab) {
        guard selectedTab != tab else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            selectedTab = tab
        }
        HapticsService.shared.tabSwitch()
    }
}

// MARK: - Liquid Glass Tab Item

/// Individual tab item with Liquid Glass morphing selection indicator
struct LiquidGlassTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Dynamic width based on selection state
    private var itemWidth: CGFloat {
        isSelected ? 68 : 44
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                // Icon with SF Symbol effects
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: isSelected ? 17 : 19, weight: isSelected ? .semibold : .medium))
                    // Let system handle foreground color adaptation
                    // Selected: uses primary, Unselected: uses secondary
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    // Bounce effect on selection
                    .symbolEffect(.bounce.up.byLayer, value: isSelected)
                    // Smooth symbol replacement transition
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))

                // Label appears when selected - minimal text
                if isSelected {
                    Text(tab.title)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.7).combined(with: .opacity),
                            removal: .scale(scale: 0.7).combined(with: .opacity)
                        ))
                }
            }
            .frame(width: itemWidth, height: 42)
            .background {
                if isSelected {
                    // Selected indicator morphs between tabs using glassEffectID
                    // This creates the fluid Liquid Glass morphing animation
                    Capsule()
                        .fill(.quaternary) // Subtle fill, glass handles the rest
                        .matchedGeometryEffect(id: "selectedIndicator", in: namespace)
                        .glassEffectID("selectedIndicator", in: namespace)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(LiquidGlassItemButtonStyle())
        // Accessibility
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to \(tab.title)")
    }
}

// MARK: - Tab Button Style

/// Minimal button style - Liquid Glass handles visual feedback
private struct LiquidGlassItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Subtle scale on press - glass handles the glow feedback
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Compact Variant

/// Compact version for smaller screens or when keyboard is active
/// Uses icon-only design with Liquid Glass
struct LiquidGlassTabBarCompact: View {
    @Binding var selectedTab: AppTab
    @Namespace private var compactNamespace

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 16) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                        HapticsService.shared.tabSwitch()
                    } label: {
                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                            .symbolEffect(.bounce.up, value: selectedTab == tab)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

// MARK: - Minimized Tab Bar

/// Ultra-minimal tab bar that can appear during scroll
/// Uses tab bar minimization behavior from iOS 26
struct LiquidGlassTabBarMinimal: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 24) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        SwiftUI.Circle()
                            .fill(selectedTab == tab ? .primary : .tertiary)
                            .frame(width: 6, height: 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - Preview

#Preview("Liquid Glass Tab Bar") {
    struct PreviewContainer: View {
        @State private var selectedTab: AppTab = .tasks

        var body: some View {
            ZStack {
                // Rich content background to show glass effect
                LinearGradient(
                    colors: [
                        Color(hex: "1a1a2e"),
                        Color(hex: "16213e"),
                        Color(hex: "0f0f23")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Sample content behind glass
                VStack {
                    ForEach(0..<8) { i in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .frame(height: 60)
                            .padding(.horizontal)
                    }
                }

                VStack {
                    // Page content indicator
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: selectedTab.selectedIcon)
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(.primary)
                            .symbolEffect(.bounce, value: selectedTab)

                        Text(selectedTab.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
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
    VStack(spacing: 32) {
        ForEach(AppTab.allCases, id: \.self) { tab in
            LiquidGlassTabBar(selectedTab: .constant(tab))
        }
    }
    .padding()
    .background(Color(hex: "0f0f23"))
    .preferredColorScheme(.dark)
}

#Preview("Compact Tab Bar") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()

        VStack {
            Spacer()
            LiquidGlassTabBarCompact(selectedTab: .constant(.tasks))
                .padding(.bottom, 20)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Minimal Tab Bar") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()

        VStack {
            Spacer()
            LiquidGlassTabBarMinimal(selectedTab: .constant(.focus))
                .padding(.bottom, 20)
        }
    }
    .preferredColorScheme(.dark)
}
