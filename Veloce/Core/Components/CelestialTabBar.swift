//
//  CelestialTabBar.swift
//  Veloce
//
//  Celestial Navigator - Revolutionary Morphing Tab Bar
//  iOS 26 Liquid Glass with fluid tab morphing animations
//

import SwiftUI

// MARK: - Celestial Tab Bar

/// Revolutionary floating tab bar with morphing Liquid Glass design
/// Selected tab expands to show label, unselected tabs collapse to icons
/// Uses GlassEffectContainer for optimized rendering and fluid morphing
struct CelestialTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var morphAnimation

    var body: some View {
        // Use GlassEffectContainer for optimized glass rendering
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    CelestialMorphingTabItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: morphAnimation
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                        HapticsService.shared.selectionFeedback()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .glassEffect(in: Capsule())
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
    }
}

// MARK: - Morphing Tab Item

/// Individual tab item that morphs between expanded (selected) and collapsed (unselected) states
/// Selected: Icon + Label, Unselected: Icon only
struct CelestialMorphingTabItem: View {
    let tab: MainTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    // MARK: State
    @State private var isPressed = false

    // MARK: Layout Constants
    private var itemWidth: CGFloat {
        isSelected ? 90 : 52
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isSelected ? 6 : 0) {
                // Icon
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .symbolEffect(.bounce.up, value: isSelected)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                // Label - morphs in/out with scale and opacity
                if isSelected {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .scale(scale: 0.5).combined(with: .opacity)
                            )
                        )
                }
            }
            .frame(width: itemWidth, height: 44)
            .background {
                // Selection indicator - uses solid fill, never glass on glass
                if isSelected {
                    Capsule()
                        .fill(.primary.opacity(0.12))
                        .matchedGeometryEffect(id: "morphSelection", in: namespace)
                }
            }
            .overlay {
                // Haptic glow effect on press
                if isPressed {
                    Capsule()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .blendMode(.plusLighter)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(MorphingTabButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Morphing Tab Button Style

/// Custom button style with press state feedback for haptic glow
private struct MorphingTabButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview("Celestial Navigator") {
    ZStack {
        // Sample gradient background
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.08, blue: 0.2)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            CelestialTabBar(selectedTab: .constant(.tasks))
                .padding(.bottom, 8)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Tab Selection Animation") {
    struct PreviewContainer: View {
        @State private var selectedTab: MainTab = .tasks

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Selected: \(selectedTab.rawValue)")
                        .foregroundStyle(.white)
                        .font(.headline)

                    Spacer()

                    CelestialTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 20)
                }
                .padding()
            }
        }
    }

    return PreviewContainer()
        .preferredColorScheme(.dark)
}
