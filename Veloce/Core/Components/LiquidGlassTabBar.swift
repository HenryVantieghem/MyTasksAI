//
//  LiquidGlassTabBar.swift
//  Veloce
//
//  Premium Liquid Glass Tab Bar with Native iOS 26 APIs
//  Inspired by Apple's Liquid Glass Design Guidelines (WWDC 2025)
//  5 tabs: Tasks, Plan, Grow, Flow, Journal
//
//  Note: Circles is now part of Grow tab (Stats/Goals/Circles segments)
//

import SwiftUI

// MARK: - Liquid Glass Tab Bar

/// Premium floating pill tab bar with liquid glass effect
/// Uses compatibility layer for iOS 17+ support
/// Responsive: Scales touch targets and spacing for iPad
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabBarNamespace

    @Environment(\.responsiveLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // Responsive spacing between tabs
    private var tabSpacing: CGFloat {
        layout.deviceType.isTablet ? 4 : 2
    }

    var body: some View {
        HStack(spacing: tabSpacing) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                LiquidGlassTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: tabBarNamespace,
                    layout: layout
                ) {
                    selectTab(tab)
                }
            }
        }
        .padding(.horizontal, layout.spacing / 2)
        .padding(.vertical, layout.deviceType.isTablet ? 14 : 10)
        // 🌟 LIQUID GLASS: Apple Music-style interactive glass with premium feel
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .overlay {
            // Premium glass highlight border
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.4),
                            .white.opacity(0.2),
                            .white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
        // Premium iridescent glow for Apple-level polish
        .premiumGlowCapsule(
            style: .iridescent,
            intensity: .whisper,
            animated: !reduceMotion
        )
        .shadow(
            color: Color.black.opacity(0.25),
            radius: 16,
            x: 0,
            y: 8
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 6,
            x: 0,
            y: 3
        )
        .padding(.horizontal, layout.screenPadding)
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
        // ✨ Premium magnetic snap haptic for tab switches
        HapticsService.shared.magneticSnap()
    }
}

// MARK: - Liquid Glass Tab Item

/// Individual tab item with morphing selection indicator
/// Responsive: Scales touch targets for iPad ergonomics
struct LiquidGlassTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let layout: ResponsiveLayout
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Dynamic width based on selection state AND device - responsive for iPad
    private var itemWidth: CGFloat {
        let baseWidth = layout.tabItemWidth
        return isSelected ? baseWidth * 1.25 : baseWidth
    }

    // Responsive icon sizes
    private var iconSize: CGFloat {
        layout.tabIconSize
    }

    // Responsive item height
    private var itemHeight: CGFloat {
        layout.minTouchTarget + (layout.deviceType.isTablet ? 8 : 0)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: layout.deviceType.isTablet ? 4 : 3) {
                // Icon with SF Symbol effects - responsive sizing
                tabIcon
                    .font(.system(size: isSelected ? iconSize - 2 : iconSize, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? iconGradient : AnyShapeStyle(.secondary))
                    .symbolEffect(.bounce, value: isSelected)

                // Label appears when selected - responsive font
                if isSelected {
                    Text(tab.title)
                        .dynamicTypeFont(base: 9, weight: .semibold, design: .rounded)
                        .foregroundStyle(Veloce.Colors.textPrimary)
                        .lineLimit(1)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.7).combined(with: .opacity),
                            removal: .scale(scale: 0.7).combined(with: .opacity)
                        ))
                }
            }
            .frame(width: itemWidth, height: itemHeight)
            .background {
                if isSelected {
                    // 🌟 LIQUID GLASS: Selected indicator with interactive glass
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Veloce.Colors.surfaceCard.opacity(0.9),
                                    Veloce.Colors.surfaceCard.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            // Inner glass highlight
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.15),
                                            .clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        }
                        .overlay {
                            // Refined glass border
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Veloce.Colors.glassHighlight.opacity(0.8),
                                            Veloce.Colors.glassBorder.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        .matchedGeometryEffect(id: "selectedIndicator", in: namespace)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(LiquidGlassItemButtonStyle())
        .iPadHoverEffect(.highlight)
        // Accessibility
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to \(tab.title)")
    }

    private var tabIcon: some View {
        Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
    }

    private var iconGradient: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [Veloce.Colors.accentPrimary, Veloce.Colors.accentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Tab Button Style

/// Minimal button style with subtle press feedback
private struct LiquidGlassItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Compact Variant

/// Compact version for smaller screens or when keyboard is active
struct LiquidGlassTabBarCompact: View {
    @Binding var selectedTab: AppTab
    @Namespace private var compactNamespace

    var body: some View {
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
                        .symbolEffect(.bounce, value: selectedTab == tab)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        // 🌟 LIQUID GLASS: Compact interactive glass
        .glassEffect(
            .regular.interactive(true),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }
}

// MARK: - Minimized Tab Bar

/// Ultra-minimal tab bar that can appear during scroll
struct LiquidGlassTabBarMinimal: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 20) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                    HapticsService.shared.selectionFeedback()
                } label: {
                    SwiftUI.Circle()
                        .fill(selectedTab == tab ? Veloce.Colors.accentPrimary : Veloce.Colors.textTertiary)
                        .frame(width: 6, height: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        // 🌟 LIQUID GLASS: Minimal interactive glass
        .glassEffect(
            .regular.interactive(true),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    .white.opacity(0.15),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
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
                        Veloce.Colors.voidBlack,
                        Veloce.Colors.surfaceElevated
                    ],
                    startPoint: .top,
                    endPoint: .bottom
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
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: selectedTab.selectedIcon)
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(Veloce.Colors.textPrimary)
                            .symbolEffect(.bounce, value: selectedTab)

                        Text(selectedTab.title)
                            .font(Veloce.Typography.displayLarge)
                            .foregroundStyle(Veloce.Colors.textPrimary)
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
    .background(Veloce.Colors.voidBlack)
    .preferredColorScheme(.dark)
}

#Preview("Compact Tab Bar") {
    ZStack {
        Veloce.Colors.voidBlack.ignoresSafeArea()

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
        Veloce.Colors.voidBlack.ignoresSafeArea()

        VStack {
            Spacer()
            LiquidGlassTabBarMinimal(selectedTab: .constant(.flow))
                .padding(.bottom, 20)
        }
    }
    .preferredColorScheme(.dark)
}
