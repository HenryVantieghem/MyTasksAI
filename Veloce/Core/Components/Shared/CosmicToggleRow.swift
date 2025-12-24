//
//  CosmicToggleRow.swift
//  Veloce
//
//  Living Cosmos Toggle Row Component
//  Settings-style toggle with celestial styling
//

import SwiftUI

// MARK: - Cosmic Toggle Row

struct CosmicToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.onChange = onChange
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon container
            iconContainer

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

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.Colors.aiPurple)
                .onChange(of: isOn) { _, newValue in
                    HapticsService.shared.selectionFeedback()
                    onChange?(newValue)
                }
        }
        .padding(.horizontal, LivingCosmos.Controls.rowPadding)
        .frame(minHeight: LivingCosmos.Controls.rowHeight)
    }

    private var iconContainer: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: LivingCosmos.Controls.iconContainerSize, height: LivingCosmos.Controls.iconContainerSize)

            // Subtle glow when on
            if isOn {
                SwiftUI.Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: LivingCosmos.Controls.iconContainerSize, height: LivingCosmos.Controls.iconContainerSize)
                    .blur(radius: 8)
            }

            Image(systemName: icon)
                .font(.system(size: LivingCosmos.Controls.iconSize, weight: .medium))
                .foregroundStyle(iconColor)
        }
    }
}

// MARK: - Cosmic Navigation Row

struct CosmicNavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let value: String?
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.action = action
    }

    var body: some View {
        Button(action: action) {
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

                // Value or chevron
                if let value {
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
            .padding(.horizontal, LivingCosmos.Controls.rowPadding)
            .frame(minHeight: LivingCosmos.Controls.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(LivingCosmos.Animations.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Cosmic Divider

struct CosmicDivider: View {
    let inset: CGFloat

    init(inset: CGFloat = LivingCosmos.Controls.dividerInset) {
        self.inset = inset
    }

    var body: some View {
        Rectangle()
            .fill(Theme.CelestialColors.starGhost.opacity(0.3))
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

// MARK: - Preview

#Preview("Cosmic Toggle Rows") {
    ZStack {
        VoidBackground.settings

        VStack(spacing: 0) {
            CosmicToggleRow(
                icon: "bell.fill",
                iconColor: Theme.Colors.accent,
                title: "Notifications",
                subtitle: "Receive task reminders",
                isOn: .constant(true)
            )

            CosmicDivider()

            CosmicToggleRow(
                icon: "hand.tap.fill",
                iconColor: Theme.Colors.aiPurple,
                title: "Haptic Feedback",
                isOn: .constant(false)
            )

            CosmicDivider()

            CosmicNavigationRow(
                icon: "crown.fill",
                iconColor: Theme.Colors.xp,
                title: "Subscription",
                value: "Pro"
            ) {}

            CosmicDivider()

            CosmicNavigationRow(
                icon: "rectangle.portrait.and.arrow.right",
                iconColor: Theme.Colors.warning,
                title: "Sign Out"
            ) {}
        }
        .celestialGlass()
        .padding()
    }
}
