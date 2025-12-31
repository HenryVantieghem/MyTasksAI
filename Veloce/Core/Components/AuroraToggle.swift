//
//  AuroraToggle.swift
//  Veloce
//
//  Aurora Toggle
//  Premium toggle switch with aurora gradient when enabled,
//  satisfying animations, and glass styling.
//

import SwiftUI

// MARK: - Aurora Toggle

struct AuroraToggle: View {
    @Binding var isOn: Bool
    let onToggle: ((Bool) -> Void)?

    @State private var dragOffset: CGFloat = 0

    private let trackWidth: CGFloat = 52
    private let trackHeight: CGFloat = 32
    private let thumbSize: CGFloat = 26
    private let thumbPadding: CGFloat = 3

    init(
        isOn: Binding<Bool>,
        onToggle: ((Bool) -> Void)? = nil
    ) {
        self._isOn = isOn
        self.onToggle = onToggle
    }

    var body: some View {
        ZStack {
            // Track background
            trackBackground

            // Thumb
            thumb
        }
        .frame(width: trackWidth, height: trackHeight)
        .gesture(tapGesture)
        .gesture(dragGesture)
    }

    // MARK: - Track Background

    private var trackBackground: some View {
        ZStack {
            // Base glass track
            Capsule()
                .fill(
                    isOn
                        ? AnyShapeStyle(Aurora.Gradients.auroraHorizontal)
                        : AnyShapeStyle(Aurora.Colors.cosmicSurface)
                )

            // Inner shadow when off
            if !isOn {
                Capsule()
                    .stroke(Aurora.Colors.glassInnerShadow, lineWidth: 1)
                    .blur(radius: 1)
                    .offset(y: 1)
                    .clipShape(Capsule())
            }

            // Glow when on
            if isOn {
                Capsule()
                    .fill(Aurora.Colors.violet.opacity(0.3))
                    .blur(radius: 8)
            }

            // Border
            Capsule()
                .stroke(
                    isOn
                        ? Aurora.Colors.electric.opacity(0.5)
                        : Aurora.Colors.glassBorder,
                    lineWidth: 1
                )
        }
        .shadow(
            color: isOn ? Aurora.Colors.violet.opacity(0.3) : Color.black.opacity(0.2),
            radius: isOn ? 8 : 4,
            y: 2
        )
        .animation(Aurora.Animation.spring, value: isOn)
    }

    // MARK: - Thumb

    private var thumb: some View {
        ZStack {
            // Thumb shadow
            SwiftUI.Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: thumbSize, height: thumbSize)
                .blur(radius: 2)
                .offset(y: 1)

            // Main thumb
            SwiftUI.Circle()
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)

            // Inner highlight
            SwiftUI.Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: thumbSize, height: thumbSize)

            // Colored dot when on
            if isOn {
                SwiftUI.Circle()
                    .fill(Aurora.Gradients.aurora)
                    .frame(width: 8, height: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .offset(x: thumbOffset + dragOffset)
        .animation(Aurora.Animation.spring, value: isOn)
        .animation(Aurora.Animation.quick, value: dragOffset)
    }

    private var thumbOffset: CGFloat {
        let travel = trackWidth - thumbSize - (thumbPadding * 2)
        return isOn ? travel / 2 : -travel / 2
    }

    // MARK: - Gestures

    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded {
                toggle()
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let maxOffset = (trackWidth - thumbSize - thumbPadding * 2) / 2
                dragOffset = max(-maxOffset, min(maxOffset, value.translation.width))
            }
            .onEnded { value in
                let shouldToggle = (isOn && value.translation.width < -10) ||
                                   (!isOn && value.translation.width > 10)

                withAnimation(Aurora.Animation.spring) {
                    dragOffset = 0
                }

                if shouldToggle {
                    toggle()
                }
            }
    }

    // MARK: - Toggle Action

    private func toggle() {
        HapticsService.shared.selectionFeedback()
        isOn.toggle()
        onToggle?(isOn)
    }
}

// MARK: - Aurora Toggle Row

/// Toggle with label and description
struct AuroraToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let onToggle: ((Bool) -> Void)?

    init(
        icon: String,
        title: String,
        description: String,
        isOn: Binding<Bool>,
        onToggle: ((Bool) -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self._isOn = isOn
        self.onToggle = onToggle
    }

    var body: some View {
        HStack(spacing: Aurora.Layout.spacing) {
            // Icon
            ZStack {
                SwiftUI.Circle()
                    .fill(isOn ? Aurora.Colors.violet.opacity(0.2) : Aurora.Colors.cosmicElevated)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .dynamicTypeFont(base: 18, weight: .medium)
                    .foregroundStyle(isOn ? Aurora.Colors.violet : Aurora.Colors.textTertiary)
            }
            .animation(Aurora.Animation.spring, value: isOn)

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Text(description)
                    .dynamicTypeFont(base: 13)
                    .foregroundStyle(Aurora.Colors.textTertiary)
                    .lineLimit(2)
            }

            Spacer()

            // Toggle
            AuroraToggle(isOn: $isOn, onToggle: onToggle)
        }
        .crystallineCard(isSelected: isOn, padding: Aurora.Layout.spacing)
    }
}

// MARK: - Preview

#Preview("Aurora Toggle") {
    struct ToggleDemo: View {
        @State private var toggle1 = false
        @State private var toggle2 = true
        @State private var notifications = false
        @State private var calendar = true

        var body: some View {
            VStack(spacing: 24) {
                // Standalone toggles
                HStack(spacing: 24) {
                    VStack {
                        AuroraToggle(isOn: $toggle1)
                        Text("Off")
                            .font(.caption)
                            .foregroundStyle(Aurora.Colors.textSecondary)
                    }

                    VStack {
                        AuroraToggle(isOn: $toggle2)
                        Text("On")
                            .font(.caption)
                            .foregroundStyle(Aurora.Colors.textSecondary)
                    }
                }

                Divider()
                    .background(Aurora.Colors.glassBorder)

                // Toggle rows
                AuroraToggleRow(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    description: "Get reminders for your tasks",
                    isOn: $notifications
                )

                AuroraToggleRow(
                    icon: "calendar",
                    title: "Calendar Sync",
                    description: "Sync tasks with your calendar",
                    isOn: $calendar
                )
            }
            .padding()
            .background(AuroraBackground.auth)
        }
    }

    return ToggleDemo()
}
