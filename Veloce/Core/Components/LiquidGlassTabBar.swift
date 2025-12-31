//
//  LiquidGlassTabBar.swift
//  Veloce
//
//  Pure Native iOS 26 Tab Bar
//  Uses native TabView with Liquid Glass system styling
//
//  Architecture:
//  - Native TabView for automatic Liquid Glass on iOS 26
//  - Custom floating pill tab bar for enhanced design
//  - tabBarMinimizationBehavior for content focus
//

import SwiftUI

// MARK: - Native Tab Bar (Uses System Liquid Glass)

/// Native TabView wrapper that gets automatic Liquid Glass on iOS 26
struct NativeGlassTabView<Content: View>: View {
    @Binding var selection: AppTab
    @ViewBuilder let content: () -> Content

    var body: some View {
        TabView(selection: $selection) {
            content()
        }
    }
}

// MARK: - Floating Pill Tab Bar

/// Custom floating pill tab bar with native glass styling
/// This provides more design control while still using native APIs
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabBarNamespace

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabItem(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(tabBarBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
        .padding(.horizontal, 20)
        .animation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.7), value: selectedTab)
    }

    // MARK: - Tab Item

    @ViewBuilder
    private func tabItem(for tab: AppTab) -> some View {
        Button {
            guard selectedTab != tab else { return }
            HapticsService.shared.lightImpact()
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: selectedTab == tab ? 18 : 20, weight: selectedTab == tab ? .semibold : .medium))
                    .symbolEffect(.bounce, value: selectedTab == tab)

                if selectedTab == tab {
                    Text(tab.title)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.7).combined(with: .opacity),
                            removal: .scale(scale: 0.7).combined(with: .opacity)
                        ))
                }
            }
            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
            .frame(width: selectedTab == tab ? 70 : 50, height: 44)
            .background {
                if selectedTab == tab {
                    Capsule()
                        .fill(LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.15))
                        .overlay {
                            Capsule()
                                .stroke(LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.3), lineWidth: 0.5)
                        }
                        .matchedGeometryEffect(id: "selectedIndicator", in: tabBarNamespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
    }

    // MARK: - Tab Bar Background

    @ViewBuilder
    private var tabBarBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: Capsule())
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Compact Tab Bar Variant

/// Compact version for smaller screens or when keyboard is active
struct LiquidGlassTabBarCompact: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 24) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    HapticsService.shared.lightImpact()
                    selectedTab = tab
                } label: {
                    Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        .symbolEffect(.bounce, value: selectedTab == tab)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(compactBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }

    @ViewBuilder
    private var compactBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: Capsule())
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Minimal Tab Bar (Dots)

/// Ultra-minimal tab bar with dots
struct LiquidGlassTabBarMinimal: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 24) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    HapticsService.shared.lightImpact()
                    selectedTab = tab
                } label: {
                    Circle()
                        .fill(
                            selectedTab == tab
                            ? LiquidGlassDesignSystem.VibrantAccents.electricCyan
                            : Color.secondary.opacity(0.5)
                        )
                        .frame(width: 6, height: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(minimalBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    @ViewBuilder
    private var minimalBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: Capsule())
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Preview

#Preview("Native Glass Tab Bar") {
    struct PreviewContainer: View {
        @State private var selectedTab: AppTab = .tasks

        var body: some View {
            ZStack {
                LiquidGlassDesignSystem.Void.cosmos
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Current tab display
                    VStack(spacing: 16) {
                        Image(systemName: selectedTab.selectedIcon)
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                            .symbolEffect(.bounce, value: selectedTab)

                        Text(selectedTab.title)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    // Tab bar
                    LiquidGlassTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 8)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewContainer()
}

#Preview("Tab Bar Variants") {
    VStack(spacing: 32) {
        LiquidGlassTabBar(selectedTab: .constant(.tasks))
        LiquidGlassTabBarCompact(selectedTab: .constant(.plan))
        LiquidGlassTabBarMinimal(selectedTab: .constant(.flow))
    }
    .padding()
    .background(LiquidGlassDesignSystem.Void.cosmos)
    .preferredColorScheme(.dark)
}
