//
//  CosmicButton.swift
//  Veloce
//
//  Living Cosmos Button Component
//  Primary, secondary, and ghost button variants with celestial styling
//

import SwiftUI

// MARK: - Cosmic Button Style

enum CosmicButtonStyle {
    case primary
    case secondary
    case ghost
    case success
    case destructive
}

// MARK: - Cosmic Button

struct CosmicButton: View {
    let title: String
    let style: CosmicButtonStyle
    let icon: String?
    let iconPosition: IconPosition
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    enum IconPosition {
        case leading
        case trailing
    }

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        _ title: String,
        style: CosmicButtonStyle = .primary,
        icon: String? = nil,
        iconPosition: IconPosition = .trailing,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            HapticsService.shared.impact()
            action()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if iconPosition == .leading, let icon {
                    iconView(icon)
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .dynamicTypeFont(base: 16, weight: .semibold)
                }

                if iconPosition == .trailing, let icon, !isLoading {
                    iconView(icon)
                }
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: LivingCosmos.Button.height)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: LivingCosmos.Button.cornerRadius))
            .overlay(borderOverlay)
            .shadow(color: shadowColor, radius: shadowRadius, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
        .scaleEffect(isPressed ? LivingCosmos.Button.pressScale : 1)
        .animation(reduceMotion ? nil : LivingCosmos.Animations.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Icon View

    @ViewBuilder
    private func iconView(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: LivingCosmos.Button.iconSize, weight: .medium))
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LivingCosmos.Button.primaryGradient
        case .secondary:
            LivingCosmos.Button.secondaryBackground
        case .ghost:
            Color.clear
        case .success:
            LinearGradient(
                colors: [Theme.CelestialColors.auroraGreen, Theme.CelestialColors.auroraGreen.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .destructive:
            LinearGradient(
                colors: [Theme.CelestialColors.errorNebula, Theme.CelestialColors.errorNebula.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Border

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .ghost:
            RoundedRectangle(cornerRadius: LivingCosmos.Button.cornerRadius)
                .stroke(LivingCosmos.Button.ghostBorder, lineWidth: 1)
        case .secondary:
            RoundedRectangle(cornerRadius: LivingCosmos.Button.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        default:
            EmptyView()
        }
    }

    // MARK: - Colors

    private var textColor: Color {
        switch style {
        case .primary, .success, .destructive:
            return .white
        case .secondary:
            return Theme.CelestialColors.starWhite
        case .ghost:
            return Theme.CelestialColors.starDim
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return Theme.Colors.aiPurple.opacity(isPressed ? 0.4 : 0.3)
        case .success:
            return Theme.CelestialColors.auroraGreen.opacity(isPressed ? 0.4 : 0.3)
        case .destructive:
            return Theme.CelestialColors.errorNebula.opacity(isPressed ? 0.4 : 0.3)
        default:
            return Color.clear
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .success, .destructive:
            return isPressed ? 8 : 12
        default:
            return 0
        }
    }
}

// MARK: - Cosmic Link Button

struct CosmicLinkButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    init(_ title: String, color: Color = Theme.Colors.aiPurple, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            action()
        } label: {
            Text(title)
                .dynamicTypeFont(base: 15, weight: .medium)
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Cosmic Icon Button

struct CosmicIconButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ icon: String,
        color: Color = Theme.CelestialColors.starWhite,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color
        self.size = size
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.lightImpact()
            action()
        } label: {
            ZStack {
                SwiftUI.Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1)
        .animation(LivingCosmos.Animations.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("Cosmic Buttons") {
    ZStack {
        VoidBackground.tasks

        VStack(spacing: Theme.Spacing.lg) {
            CosmicButton("Primary Button", style: .primary, icon: "arrow.right") {}

            CosmicButton("Secondary Button", style: .secondary, icon: "chevron.right") {}

            CosmicButton("Ghost Button", style: .ghost) {}

            CosmicButton("Success Button", style: .success, icon: "checkmark") {}

            CosmicButton("Destructive", style: .destructive, icon: "trash") {}

            CosmicButton("Loading...", style: .primary, isLoading: true) {}

            CosmicButton("Disabled", style: .primary, isEnabled: false) {}

            HStack {
                CosmicLinkButton("Link Button") {}
                Spacer()
                CosmicIconButton("xmark.circle.fill") {}
            }
        }
        .padding()
    }
}
