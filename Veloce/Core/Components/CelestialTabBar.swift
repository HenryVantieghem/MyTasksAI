//
//  CelestialTabBar.swift
//  Veloce
//
//  Unified Orb Navigator - Apple Music Style Tab Bar
//  iOS 26 Liquid Glass with central decorative orb and fluid morphing
//

import SwiftUI

// MARK: - Celestial Tab Bar

/// Revolutionary unified tab bar with central glowing orb
/// Single continuous glass effect with orb as the focal point
/// Selected tab expands with glow, unselected tabs are compact icons
struct CelestialTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var morphAnimation

    // Streak/energy state (controls orb glow intensity)
    var streakDays: Int = 0
    var recentPointsEarned: Bool = false

    // MARK: Animation States
    @State private var orbBreathScale: CGFloat = 1.0
    @State private var orbGlowOpacity: Double = 0.6
    @State private var pointsPulse: Bool = false

    // Gradient colors for orb
    private let orbColors: [Color] = [
        Color(hex: "8B5CF6"),
        Color(hex: "6366F1"),
        Color(hex: "3B82F6"),
        Color(hex: "06B6D4"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            // Left tabs: Tasks, Calendar
            HStack(spacing: 4) {
                ForEach([MainTab.tasks, MainTab.calendar], id: \.self) { tab in
                    OrbNavigatorTabItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: morphAnimation
                    ) {
                        selectTab(tab)
                    }
                }
            }

            Spacer()

            // Central Orb - Decorative breathing element
            CentralNavigatorOrb(
                streakDays: streakDays,
                breathScale: orbBreathScale,
                glowOpacity: orbGlowOpacity,
                isPulsing: pointsPulse
            )
            .frame(width: 44, height: 44)

            Spacer()

            // Right tabs: Focus, Momentum, AI
            HStack(spacing: 4) {
                ForEach([MainTab.focus, MainTab.momentum, MainTab.ai], id: \.self) { tab in
                    OrbNavigatorTabItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: morphAnimation
                    ) {
                        selectTab(tab)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            // Single unified glass background
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: orbColors[0].opacity(0.15), radius: 20, y: 5)
                .shadow(color: .black.opacity(0.2), radius: 15, y: 8)
        }
        .glassEffect(in: Capsule())
        .padding(.horizontal, 20)
        .onAppear {
            startOrbAnimations()
        }
        .onChange(of: recentPointsEarned) { _, earned in
            if earned {
                triggerPointsPulse()
            }
        }
    }

    // MARK: - Actions

    private func selectTab(_ tab: MainTab) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selectedTab = tab
        }
        HapticsService.shared.tabSwitch()
    }

    private func startOrbAnimations() {
        // Continuous breathing animation
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            orbBreathScale = 1.08
        }

        // Glow pulsing (more intense with streak)
        let glowIntensity = min(0.9, 0.5 + Double(streakDays) * 0.02)
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            orbGlowOpacity = glowIntensity
        }
    }

    private func triggerPointsPulse() {
        withAnimation(.easeOut(duration: 0.15)) {
            pointsPulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                pointsPulse = false
            }
        }
    }
}

// MARK: - Central Navigator Orb

/// Decorative orb in the center of the tab bar
/// Breathes continuously and responds to streak/points state
struct CentralNavigatorOrb: View {
    let streakDays: Int
    let breathScale: CGFloat
    let glowOpacity: Double
    let isPulsing: Bool

    private let gradientColors: [Color] = [
        Color(hex: "8B5CF6"),
        Color(hex: "6366F1"),
        Color(hex: "3B82F6"),
        Color(hex: "06B6D4"),
        Color(hex: "14B8A6"),
    ]

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            gradientColors[1].opacity(glowOpacity * 0.5),
                            gradientColors[2].opacity(glowOpacity * 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 28
                    )
                )
                .frame(width: 56, height: 56)
                .blur(radius: 4)
                .scaleEffect(isPulsing ? 1.3 : breathScale)

            // Core orb with angular gradient
            Circle()
                .fill(
                    AngularGradient(
                        colors: gradientColors + [gradientColors[0]],
                        center: .center
                    )
                )
                .frame(width: 22, height: 22)
                .scaleEffect(breathScale)

            // Inner white core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 14, height: 14)
                .scaleEffect(isPulsing ? 1.4 : breathScale)

            // Top highlight
            Ellipse()
                .fill(Color.white.opacity(0.6))
                .frame(width: 6, height: 3)
                .offset(x: -2, y: -5)
                .blur(radius: 1)

            // Streak indicator ring
            if streakDays > 0 {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.orange.opacity(0.8),
                                Color.red.opacity(0.6),
                                Color.orange.opacity(0.8)
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 28, height: 28)
                    .scaleEffect(breathScale)
                    .opacity(min(1.0, Double(streakDays) / 7.0))
            }
        }
    }
}

// MARK: - Navigator Tab Item

/// Individual tab item with compact icon design
/// Selected tab shows icon + label with glow background
struct OrbNavigatorTabItem: View {
    let tab: MainTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isPressed = false

    // Display name
    private var displayName: String {
        tab.rawValue
    }

    // Compact width for icons, expanded for selected
    private var itemWidth: CGFloat {
        isSelected ? 72 : 44
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Icon
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: isSelected ? 18 : 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .symbolEffect(.bounce.up, value: isSelected)
                    .scaleEffect(isSelected ? 1.15 : 1.0)

                // Label - only visible when selected
                if isSelected {
                    Text(displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(width: itemWidth, height: 44)
            .background {
                // Selection glow
                if isSelected {
                    Capsule()
                        .fill(
                            RadialGradient(
                                colors: [
                                    tabAccentColor.opacity(0.25),
                                    tabAccentColor.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .matchedGeometryEffect(id: "tabGlow", in: namespace)
                }
            }
            .overlay {
                // Press glow
                if isPressed {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .blendMode(.plusLighter)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(NavigatorTabButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }

    // Tab-specific accent colors
    private var tabAccentColor: Color {
        switch tab {
        case .tasks: return Color(hex: "8B5CF6")     // Purple
        case .calendar: return Color(hex: "3B82F6") // Blue
        case .focus: return Color(hex: "F59E0B")    // Amber (timer)
        case .momentum: return Color(hex: "10B981") // Emerald
        case .ai: return Color(hex: "06B6D4")       // Cyan
        }
    }
}

// MARK: - Navigator Tab Button Style

private struct NavigatorTabButtonStyle: ButtonStyle {
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

#Preview("Unified Orb Navigator") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.02, blue: 0.04),
                Color(red: 0.08, green: 0.06, blue: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            CelestialTabBar(
                selectedTab: .constant(.tasks),
                streakDays: 7
            )
            .padding(.bottom, 8)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Navigator with Streak") {
    struct PreviewContainer: View {
        @State private var selectedTab: MainTab = .momentum

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Selected: \(selectedTab.rawValue)")
                        .foregroundStyle(.white)
                        .font(.headline)

                    Text("7-day streak active")
                        .foregroundStyle(.orange)
                        .font(.caption)

                    Spacer()

                    CelestialTabBar(
                        selectedTab: $selectedTab,
                        streakDays: 7,
                        recentPointsEarned: false
                    )
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
    }

    return PreviewContainer()
        .preferredColorScheme(.dark)
}

#Preview("All Tabs") {
    struct PreviewContainer: View {
        @State private var selectedTab: MainTab = .tasks

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    // Tab content simulation
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
