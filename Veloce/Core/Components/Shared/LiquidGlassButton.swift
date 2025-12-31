//
//  LiquidGlassButton.swift
//  Veloce
//
//  Pure Native iOS 26 Button Components
//  Uses Apple's native button styles and Liquid Glass APIs
//
//  Architecture:
//  - Primary: .borderedProminent with tint
//  - Secondary: Native glass with .glassEffect()
//  - Ghost: Plain with subtle glass on press
//

import SwiftUI

// MARK: - Button Style Enum

enum LiquidGlassButtonStyle {
    case primary
    case secondary
    case ghost
    case success
    case destructive
}

// MARK: - Primary Button (Native .borderedProminent)

struct LiquidGlassButton: View {
    let title: String
    let style: LiquidGlassButtonStyle
    let icon: String?
    let iconPosition: IconPosition
    let isLoading: Bool
    let isEnabled: Bool
    let fullWidth: Bool
    let action: () -> Void

    enum IconPosition {
        case leading
        case trailing
    }

    init(
        _ title: String,
        style: LiquidGlassButtonStyle = .primary,
        icon: String? = nil,
        iconPosition: IconPosition = .trailing,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            HapticsService.shared.impact(.medium)
            action()
        } label: {
            buttonLabel
        }
        .buttonStyle(nativeButtonStyle)
        .disabled(!isEnabled || isLoading)
    }

    // MARK: - Button Label

    @ViewBuilder
    private var buttonLabel: some View {
        HStack(spacing: 10) {
            if iconPosition == .leading, let icon = icon {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                    .scaleEffect(0.85)
                Text("Loading...")
                    .font(.body.weight(.medium))
            } else {
                Text(title)
                    .font(.headline)
            }

            if iconPosition == .trailing, let icon = icon, !isLoading {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(height: 50)
    }

    // MARK: - Native Button Style

    private var nativeButtonStyle: some ButtonStyle {
        switch style {
        case .primary:
            return AnyButtonStyle(NativePrimaryStyle(tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan))
        case .secondary:
            return AnyButtonStyle(NativeSecondaryStyle())
        case .ghost:
            return AnyButtonStyle(NativeGhostStyle())
        case .success:
            return AnyButtonStyle(NativePrimaryStyle(tint: LiquidGlassDesignSystem.VibrantAccents.auroraGreen))
        case .destructive:
            return AnyButtonStyle(NativePrimaryStyle(tint: .red))
        }
    }

    private var textColor: Color {
        switch style {
        case .primary, .success, .destructive:
            return .white
        case .secondary:
            return .primary
        case .ghost:
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        }
    }
}

// MARK: - Native Button Styles

/// Primary button style using solid tinted background
struct NativePrimaryStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .background(
                Capsule()
                    .fill(tint)
                    .shadow(color: tint.opacity(0.3), radius: configuration.isPressed ? 8 : 16, y: configuration.isPressed ? 2 : 8)
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

/// Secondary button style using native Liquid Glass
struct NativeSecondaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            .adaptiveGlassCapsule(interactive: true)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

/// Ghost button style - minimal with subtle glass on press
struct NativeGhostStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
            .padding(.horizontal, 16)
            .background {
                if configuration.isPressed {
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.5))
                }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Type Erasure for ButtonStyle

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Convenience Initializers

extension LiquidGlassButton {
    /// Primary CTA button
    static func primary(
        _ title: String,
        icon: String? = "arrow.right",
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> LiquidGlassButton {
        LiquidGlassButton(
            title,
            style: .primary,
            icon: icon,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// Secondary button with glass effect
    static func secondary(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> LiquidGlassButton {
        LiquidGlassButton(
            title,
            style: .secondary,
            icon: icon,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// Ghost button (minimal style)
    static func ghost(
        _ title: String,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        action: @escaping () -> Void
    ) -> LiquidGlassButton {
        LiquidGlassButton(
            title,
            style: .ghost,
            icon: icon,
            iconPosition: iconPosition,
            fullWidth: false,
            action: action
        )
    }

    /// Success button
    static func success(
        _ title: String,
        icon: String? = "checkmark",
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> LiquidGlassButton {
        LiquidGlassButton(
            title,
            style: .success,
            icon: icon,
            isLoading: isLoading,
            action: action
        )
    }
}

// MARK: - Small Button Variant

struct LiquidGlassButtonSmall: View {
    let title: String
    let style: LiquidGlassButtonStyle
    let icon: String?
    let action: () -> Void

    init(
        _ title: String,
        style: LiquidGlassButtonStyle = .secondary,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.lightImpact()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(style == .ghost ? LiquidGlassDesignSystem.VibrantAccents.electricCyan : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(smallButtonStyle)
    }

    private var smallButtonStyle: some ButtonStyle {
        switch style {
        case .primary:
            return AnyButtonStyle(SmallPrimaryStyle(tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan))
        case .secondary:
            return AnyButtonStyle(SmallSecondaryStyle())
        case .ghost:
            return AnyButtonStyle(NativeGhostStyle())
        case .success:
            return AnyButtonStyle(SmallPrimaryStyle(tint: LiquidGlassDesignSystem.VibrantAccents.auroraGreen))
        case .destructive:
            return AnyButtonStyle(SmallPrimaryStyle(tint: .red))
        }
    }
}

struct SmallPrimaryStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Capsule().fill(tint))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

struct SmallSecondaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .adaptiveGlassCapsule(interactive: true)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Icon-Only Button

struct LiquidGlassIconButton: View {
    let icon: String
    let size: CGFloat
    let tint: Color?
    let action: () -> Void

    init(
        icon: String,
        size: CGFloat = 44,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.lightImpact()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(tint ?? .primary)
                .frame(width: size, height: size)
        }
        .buttonStyle(IconButtonStyle(tint: tint))
    }
}

struct IconButtonStyle: ButtonStyle {
    let tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .adaptiveGlass(cornerRadius: 999, interactive: true)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Native Button Styles") {
    ZStack {
        LiquidGlassDesignSystem.Void.cosmos
            .ignoresSafeArea()

        VStack(spacing: 24) {
            Text("Native Liquid Glass Buttons")
                .font(.title2.bold())
                .foregroundStyle(.white)

            LiquidGlassButton.primary("Get Started") {
                print("Primary tapped")
            }

            LiquidGlassButton.secondary("Learn More", icon: "info.circle") {
                print("Secondary tapped")
            }

            LiquidGlassButton.success("Complete", icon: "checkmark.circle") {
                print("Success tapped")
            }

            LiquidGlassButton(
                "Delete",
                style: .destructive,
                icon: "trash",
                iconPosition: .leading
            ) {
                print("Destructive tapped")
            }

            HStack(spacing: 16) {
                LiquidGlassButton.ghost("Back", icon: "arrow.left", iconPosition: .leading) {
                    print("Ghost tapped")
                }

                Spacer()

                LiquidGlassButtonSmall("Skip", icon: "forward") {
                    print("Small tapped")
                }
            }

            HStack(spacing: 16) {
                LiquidGlassIconButton(icon: "xmark") {
                    print("Close")
                }

                LiquidGlassIconButton(icon: "heart.fill", tint: .pink) {
                    print("Heart")
                }

                LiquidGlassIconButton(icon: "plus", tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan) {
                    print("Add")
                }
            }
        }
        .padding()
    }
}
