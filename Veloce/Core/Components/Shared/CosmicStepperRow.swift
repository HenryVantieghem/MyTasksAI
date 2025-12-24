//
//  CosmicStepperRow.swift
//  Veloce
//
//  Living Cosmos Stepper Row Component
//  Settings-style stepper with celestial styling
//

import SwiftUI

// MARK: - Cosmic Stepper Row

struct CosmicStepperRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String?

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1,
        unit: String? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon container
            ZStack {
                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: LivingCosmos.Controls.iconContainerSize, height: LivingCosmos.Controls.iconContainerSize)

                Image(systemName: icon)
                    .font(.system(size: LivingCosmos.Controls.iconSize, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }

            Spacer()

            // Stepper controls
            stepperControls
        }
        .padding(.horizontal, LivingCosmos.Controls.rowPadding)
        .frame(minHeight: LivingCosmos.Controls.rowHeight)
    }

    private var stepperControls: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Minus button
            CosmicStepperButton(
                icon: "minus",
                isEnabled: value > range.lowerBound
            ) {
                if value > range.lowerBound {
                    value -= step
                    HapticsService.shared.selectionFeedback()
                }
            }

            // Value display
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.CelestialColors.starWhite)
                    .frame(minWidth: 32)

                if let unit {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }

            // Plus button
            CosmicStepperButton(
                icon: "plus",
                isEnabled: value < range.upperBound
            ) {
                if value < range.upperBound {
                    value += step
                    HapticsService.shared.selectionFeedback()
                }
            }
        }
    }
}

// MARK: - Cosmic Stepper Button

private struct CosmicStepperButton: View {
    let icon: String
    let isEnabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                SwiftUI.Circle()
                    .fill(isEnabled ? Theme.Colors.aiPurple.opacity(0.2) : Theme.CelestialColors.void)
                    .frame(width: 32, height: 32)

                if isEnabled {
                    SwiftUI.Circle()
                        .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
                        .frame(width: 32, height: 32)
                }

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isEnabled ? Theme.Colors.aiPurple : Theme.CelestialColors.starGhost)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.9 : 1)
        .animation(LivingCosmos.Animations.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if isEnabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Cosmic Slider Row

struct CosmicSliderRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    init(
        icon: String,
        iconColor: Color,
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double> = 0...100,
        step: Double = 1
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self._value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon container
                ZStack {
                    SwiftUI.Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: LivingCosmos.Controls.iconContainerSize, height: LivingCosmos.Controls.iconContainerSize)

                    Image(systemName: icon)
                        .font(.system(size: LivingCosmos.Controls.iconSize, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Spacer()

                Text("\(Int(value))")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(iconColor)
            }

            // Slider
            Slider(value: $value, in: range, step: step)
                .tint(iconColor)
                .onChange(of: value) { _, _ in
                    HapticsService.shared.selectionFeedback()
                }
        }
        .padding(.horizontal, LivingCosmos.Controls.rowPadding)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview("Cosmic Stepper Rows") {
    ZStack {
        VoidBackground.settings

        VStack(spacing: 0) {
            CosmicStepperRow(
                icon: "target",
                iconColor: Theme.Colors.success,
                title: "Daily Tasks",
                subtitle: "Your daily goal",
                value: .constant(5),
                range: 1...20
            )

            CosmicDivider()

            CosmicStepperRow(
                icon: "calendar",
                iconColor: Theme.Colors.aiCyan,
                title: "Weekly Tasks",
                value: .constant(25),
                range: 5...100,
                step: 5
            )

            CosmicDivider()

            CosmicStepperRow(
                icon: "clock",
                iconColor: Theme.Colors.aiAmber,
                title: "Focus Duration",
                value: .constant(25),
                range: 5...60,
                step: 5,
                unit: "min"
            )
        }
        .celestialGlass()
        .padding()
    }
}

#Preview("Cosmic Slider") {
    ZStack {
        VoidBackground.settings

        CosmicSliderRow(
            icon: "speaker.wave.3.fill",
            iconColor: Theme.Colors.aiPurple,
            title: "Volume",
            value: .constant(75)
        )
        .celestialGlass()
        .padding()
    }
}
