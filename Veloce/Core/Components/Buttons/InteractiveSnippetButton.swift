//
//  InteractiveSnippetButton.swift
//  Veloce
//
//  Interactive Snippets Design (WWDC 2025 Session 281)
//  Full-width labeled buttons with Liquid Glass styling
//

import SwiftUI

// MARK: - Interactive Snippet Button

/// A full-width interactive button following WWDC 2025 Interactive Snippets design.
/// Features Liquid Glass styling with aurora gradients and cosmic spring animations.
struct InteractiveSnippetButton: View {
    let icon: String
    let label: String
    let value: String
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        icon: String,
        label: String,
        value: String,
        accentColor: Color = Theme.CelestialColors.nebulaCore,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon with accent glow
                ZStack {
                    // Subtle glow behind icon
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .blur(radius: 8)

                    // Icon container
                    Image(systemName: icon)
                        .dynamicTypeFont(base: 16, weight: .semibold)
                        .foregroundStyle(accentColor)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle()
                                .fill(accentColor.opacity(0.12))
                        }
                }

                // Label and Value
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Text(value)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.6))
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md + 2)
            .background {
                // Glass background with accent gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.CelestialColors.voidDeep.opacity(0.4))
                    .overlay {
                        // Accent gradient overlay
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(isPressed ? 0.15 : 0.08),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .overlay {
                        // Border with accent
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.3),
                                        Theme.CelestialColors.starDim.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(
                reduceMotion ? .none : Theme.Animations.cosmicSpring,
                value: isPressed
            )
        }
        .buttonStyle(InteractiveSnippetButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Button Style

private struct InteractiveSnippetButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Compact Variant

/// A more compact version for inline use
struct InteractiveSnippetChip: View {
    let icon: String
    let value: String
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(accentColor)

                Text(value)
                    .dynamicTypeFont(base: 13, weight: .medium)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                Capsule()
                    .fill(accentColor.opacity(0.12))
                    .overlay {
                        Capsule()
                            .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
                    }
            }
            .glassEffect(.regular, in: Capsule())
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(InteractiveSnippetButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.voidDeep
            .ignoresSafeArea()

        VStack(spacing: 16) {
            InteractiveSnippetButton(
                icon: "clock.fill",
                label: "Time of Day",
                value: "Tomorrow 9:00 AM",
                accentColor: Theme.Colors.aiBlue
            ) {
                print("Time tapped")
            }

            InteractiveSnippetButton(
                icon: "timer",
                label: "Duration",
                value: "45 min",
                accentColor: Theme.CelestialColors.nebulaCore
            ) {
                print("Duration tapped")
            }

            InteractiveSnippetButton(
                icon: "arrow.trianglehead.2.clockwise.rotate.90",
                label: "Recurring",
                value: "Weekly",
                accentColor: Theme.Colors.aiAmber
            ) {
                print("Recurring tapped")
            }

            HStack(spacing: 12) {
                InteractiveSnippetChip(
                    icon: "clock",
                    value: "9 AM",
                    accentColor: Theme.Colors.aiBlue
                ) {}

                InteractiveSnippetChip(
                    icon: "timer",
                    value: "30m",
                    accentColor: Theme.CelestialColors.nebulaCore
                ) {}
            }
        }
        .padding()
    }
}
