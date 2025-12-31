//
//  LiquidGlassTabBar.swift
//  Veloce
//
//  Aurora Design System - Navigation Constellation
//  Premium floating pill tab bar with iOS 26 Liquid Glass
//  Aurora beam shoots between tabs, pulsing cyan glow, particle trails
//
//  5 tabs: Tasks, Plan, Grow, Flow, Journal
//

import SwiftUI

// MARK: - Aurora Navigation Constellation

/// Premium floating pill tab bar with Aurora Design System
/// Navigation layer with prismatic glass and constellation effects
/// Responsive: Scales touch targets and spacing for iPad
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabBarNamespace

    @Environment(\.responsiveLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // Track previous tab for aurora beam animation
    @State private var previousTab: AppTab?
    @State private var beamAnimating = false

    // Responsive spacing between tabs
    private var tabSpacing: CGFloat {
        layout.deviceType.isTablet ? 4 : 2
    }

    var body: some View {
        ZStack {
            // Aurora beam effect between tabs
            if beamAnimating && !reduceMotion {
                AuroraTabBeam(
                    from: previousTab ?? selectedTab,
                    to: selectedTab,
                    namespace: tabBarNamespace
                )
            }

            HStack(spacing: tabSpacing) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    AuroraTabItem(
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
            .background {
                // Subtle aurora glow behind tab bar
                Capsule()
                    .fill(Aurora.Colors.voidNebula.opacity(0.6))
                    .blur(radius: 20)
                    .offset(y: 4)
            }
            // Aurora glass effect with prismatic edge
            .auroraGlass(in: Capsule())
            .overlay {
                // Prismatic edge highlight
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Aurora.Colors.electricCyan.opacity(0.3),
                                Aurora.Colors.borealisViolet.opacity(0.2),
                                Aurora.Colors.stellarMagenta.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            // Cosmic depth shadow
            .shadow(
                color: Aurora.Colors.electricCyan.opacity(0.15),
                radius: 20,
                x: 0,
                y: 8
            )
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 20,
                x: 0,
                y: 10
            )
        }
        .padding(.horizontal, layout.screenPadding)
        .animation(
            reduceMotion ? .none : AuroraMotion.Spring.ui,
            value: selectedTab
        )
    }

    private func selectTab(_ tab: AppTab) {
        guard selectedTab != tab else { return }

        previousTab = selectedTab

        // Trigger beam animation
        beamAnimating = true

        withAnimation(AuroraMotion.Spring.ui) {
            selectedTab = tab
        }

        // Aurora haptics and sound
        AuroraHaptics.light()
        AuroraSoundEngine.shared.play(.tabSwitch)

        // Reset beam after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            beamAnimating = false
        }
    }
}

// MARK: - Aurora Tab Item

/// Individual tab item with aurora glow and constellation effects
/// Pulsing cyan glow when selected, particle trails on interaction
struct AuroraTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let layout: ResponsiveLayout
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var glowPulse: CGFloat = 0.5

    // Dynamic width based on selection state AND device
    private var itemWidth: CGFloat {
        let baseWidth = layout.tabItemWidth
        return isSelected ? baseWidth * 1.25 : baseWidth
    }

    private var iconSize: CGFloat {
        layout.tabIconSize
    }

    private var itemHeight: CGFloat {
        layout.minTouchTarget + (layout.deviceType.isTablet ? 8 : 0)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Aurora glow halo for selected tab
                if isSelected && !reduceMotion {
                    Circle()
                        .fill(Aurora.Colors.electricCyan.opacity(0.3 * glowPulse))
                        .frame(width: itemWidth * 0.8, height: itemWidth * 0.8)
                        .blur(radius: 12)
                        .scaleEffect(1.2 + glowPulse * 0.2)
                }

                VStack(spacing: layout.deviceType.isTablet ? 4 : 3) {
                    // Icon with aurora glow
                    ZStack {
                        // Glow layer behind icon
                        if isSelected {
                            tabIcon
                                .font(.system(size: iconSize, weight: .semibold))
                                .foregroundStyle(Aurora.Colors.electricCyan)
                                .blur(radius: 4)
                                .opacity(0.6)
                        }

                        tabIcon
                            .font(.system(size: isSelected ? iconSize - 2 : iconSize, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? iconGradient : AnyShapeStyle(Aurora.Colors.textTertiary))
                            .symbolEffect(.bounce, value: isSelected)
                    }

                    // Label appears when selected
                    if isSelected {
                        Text(tab.title)
                            .font(Aurora.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Aurora.Colors.textPrimary)
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
                        // Selected indicator with aurora gradient
                        Capsule()
                            .fill(Aurora.Colors.voidNebula.opacity(0.6))
                            .overlay {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Aurora.Colors.electricCyan.opacity(0.15),
                                                Aurora.Colors.borealisViolet.opacity(0.08),
                                                Color.clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Aurora.Colors.electricCyan.opacity(0.4),
                                                Aurora.Colors.borealisViolet.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .matchedGeometryEffect(id: "selectedIndicator", in: namespace)
                    }
                }
                .contentShape(.capsule)
            }
        }
        .buttonStyle(.cosmicTap)
        .iPadHoverEffect(.highlight)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to \(tab.title)")
        .onAppear {
            if isSelected && !reduceMotion {
                startGlowPulse()
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue && !reduceMotion {
                startGlowPulse()
            }
        }
    }

    private var tabIcon: some View {
        Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
    }

    /// Aurora AI gradient for selected icon (Cyan → Violet)
    private var iconGradient: AnyShapeStyle {
        AnyShapeStyle(Aurora.Gradients.aiGradient)
    }

    private func startGlowPulse() {
        withAnimation(
            .easeInOut(duration: AuroraMotion.Duration.glowPulse)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = 1.0
        }
    }
}

// MARK: - Aurora Tab Beam

/// Animated light beam that shoots between tabs on selection
struct AuroraTabBeam: View {
    let from: AppTab
    let to: AppTab
    let namespace: Namespace.ID

    @State private var beamProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let fromIndex = CGFloat(AppTab.allCases.firstIndex(of: from) ?? 0)
            let toIndex = CGFloat(AppTab.allCases.firstIndex(of: to) ?? 0)
            let tabCount = CGFloat(AppTab.allCases.count)
            let tabWidth = geometry.size.width / tabCount

            let startX = fromIndex * tabWidth + tabWidth / 2
            let endX = toIndex * tabWidth + tabWidth / 2
            let currentX = startX + (endX - startX) * beamProgress

            // Aurora beam
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Aurora.Colors.electricCyan,
                            Aurora.Colors.electricCyan.opacity(0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .position(x: currentX, y: geometry.size.height / 2)
                .blur(radius: 8)

            // Trail particles
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Aurora.Colors.electricCyan.opacity(0.3 - Double(i) * 0.1))
                    .frame(width: 8 - CGFloat(i) * 2, height: 8 - CGFloat(i) * 2)
                    .position(
                        x: startX + (currentX - startX) * (1 - CGFloat(i) * 0.15),
                        y: geometry.size.height / 2
                    )
                    .blur(radius: 2)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35)) {
                beamProgress = 1.0
            }
        }
    }
}


// MARK: - Aurora Compact Variant

/// Compact version for smaller screens or when keyboard is active
struct LiquidGlassTabBarCompact: View {
    @Binding var selectedTab: AppTab
    @Namespace private var compactNamespace

    var body: some View {
        HStack(spacing: Aurora.Spacing.lg) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(AuroraMotion.Spring.ui) {
                        selectedTab = tab
                    }
                    AuroraHaptics.light()
                    AuroraSoundEngine.shared.play(.tabSwitch)
                } label: {
                    ZStack {
                        // Glow for selected
                        if selectedTab == tab {
                            Circle()
                                .fill(Aurora.Colors.electricCyan.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .blur(radius: 6)
                        }

                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(
                                selectedTab == tab
                                    ? AnyShapeStyle(Aurora.Gradients.aiGradient)
                                    : AnyShapeStyle(Aurora.Colors.textTertiary)
                            )
                            .symbolEffect(.bounce, value: selectedTab == tab)
                            .frame(width: 32, height: 32)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Aurora.Spacing.xl)
        .padding(.vertical, Aurora.Spacing.md)
        .auroraGlass(in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.electricCyan.opacity(0.3),
                            Aurora.Colors.borealisViolet.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: Aurora.Colors.electricCyan.opacity(0.1), radius: 12, y: 4)
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }
}

// MARK: - Aurora Minimal Tab Bar

/// Ultra-minimal tab bar with aurora dots that can appear during scroll
struct LiquidGlassTabBarMinimal: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: Aurora.Spacing.xl) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(AuroraMotion.Spring.ui) {
                        selectedTab = tab
                    }
                    AuroraHaptics.light()
                } label: {
                    ZStack {
                        // Glow for selected
                        if selectedTab == tab {
                            SwiftUI.Circle()
                                .fill(Aurora.Colors.electricCyan.opacity(0.4))
                                .frame(width: 12, height: 12)
                                .blur(radius: 4)
                        }

                        SwiftUI.Circle()
                            .fill(
                                selectedTab == tab
                                    ? Aurora.Colors.electricCyan
                                    : Aurora.Colors.textTertiary.opacity(0.5)
                            )
                            .frame(width: 6, height: 6)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .auroraGlass(in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(
                    Aurora.Colors.electricCyan.opacity(0.15),
                    lineWidth: 0.5
                )
        }
        .shadow(color: Aurora.Colors.electricCyan.opacity(0.1), radius: 8, y: 2)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview("Aurora Navigation Constellation") {
    struct PreviewContainer: View {
        @State private var selectedTab: AppTab = .tasks

        var body: some View {
            ZStack {
                // Aurora cosmic void background
                Aurora.Colors.voidCosmos
                    .ignoresSafeArea()

                // Subtle aurora waves
                AuroraAnimatedWaveBackground()
                    .ignoresSafeArea()
                    .opacity(0.3)

                // Sample content cards behind glass
                VStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Aurora.Colors.voidNebula)
                            .frame(height: 80)
                            .overlay(alignment: .leading) {
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 16,
                                    bottomLeadingRadius: 16,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 0
                                )
                                .fill([
                                    Aurora.Colors.categoryWork,
                                    Aurora.Colors.categoryPersonal,
                                    Aurora.Colors.categoryCreative,
                                    Aurora.Colors.categoryLearning,
                                    Aurora.Colors.categoryHealth,
                                    Aurora.Colors.electricCyan
                                ][i % 6])
                                .frame(width: 4)
                            }
                            .padding(.horizontal, Aurora.Spacing.screenPadding)
                    }
                }

                VStack {
                    Spacer()

                    VStack(spacing: Aurora.Spacing.md) {
                        ZStack {
                            // Glow behind icon
                            Image(systemName: selectedTab.selectedIcon)
                                .dynamicTypeFont(base: 56, weight: .light)
                                .foregroundStyle(Aurora.Colors.electricCyan)
                                .blur(radius: 12)
                                .opacity(0.5)

                            Image(systemName: selectedTab.selectedIcon)
                                .dynamicTypeFont(base: 56, weight: .light)
                                .foregroundStyle(Aurora.Gradients.aiGradient)
                                .symbolEffect(.bounce, value: selectedTab)
                        }

                        Text(selectedTab.title)
                            .font(Aurora.Typography.title2)
                            .foregroundStyle(Aurora.Colors.textPrimary)
                    }
                    .frame(maxHeight: .infinity)

                    // Tab bar with Aurora constellation
                    LiquidGlassTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 8)
                }
            }
        }
    }

    return PreviewContainer()
}

#Preview("Tab Bar States") {
    VStack(spacing: 32) {
        ForEach(AppTab.allCases, id: \.self) { tab in
            LiquidGlassTabBar(selectedTab: .constant(tab))
        }
    }
    .padding()
    .background(Aurora.Colors.voidCosmos)
}

#Preview("Compact Tab Bar") {
    ZStack {
        Aurora.Colors.voidCosmos.ignoresSafeArea()

        VStack {
            Spacer()
            LiquidGlassTabBarCompact(selectedTab: .constant(.tasks))
                .padding(.bottom, 20)
        }
    }
}

#Preview("Minimal Tab Bar") {
    ZStack {
        Aurora.Colors.voidCosmos.ignoresSafeArea()

        VStack {
            Spacer()
            LiquidGlassTabBarMinimal(selectedTab: .constant(.flow))
                .padding(.bottom, 20)
        }
    }
}
