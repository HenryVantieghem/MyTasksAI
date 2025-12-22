//
//  AuroraButton.swift
//  Veloce
//
//  Aurora Button
//  Premium CTA button with flowing gradient animation,
//  press feedback, and state-aware visual effects.
//

import SwiftUI

// MARK: - Aurora Button Style

enum AuroraButtonStyle {
    case primary      // Full gradient, prominent
    case secondary    // Glass background, accent border
    case ghost        // Text only, minimal
}

// MARK: - Aurora Button

struct AuroraButton: View {
    let title: String
    let style: AuroraButtonStyle
    let isLoading: Bool
    let isEnabled: Bool
    let icon: String?
    let action: () -> Void

    @State private var isPressed: Bool = false
    @State private var gradientOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0.3

    init(
        _ title: String,
        style: AuroraButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            HapticsService.shared.impact()
            action()
        } label: {
            ZStack {
                // Background based on style
                buttonBackground

                // Content
                buttonContent
            }
            .frame(height: buttonHeight)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(Aurora.Animation.quick, value: isPressed)
        .animation(Aurora.Animation.spring, value: isEnabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            if style == .primary {
                startGradientAnimation()
            }
        }
    }

    // MARK: - Button Height

    private var buttonHeight: CGFloat {
        style == .ghost ? Aurora.Size.buttonHeightSmall : Aurora.Size.buttonHeight
    }

    // MARK: - Button Background

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            primaryBackground

        case .secondary:
            secondaryBackground

        case .ghost:
            Color.clear
        }
    }

    private var primaryBackground: some View {
        ZStack {
            // Outer glow
            Capsule()
                .fill(Aurora.Colors.violet.opacity(glowOpacity))
                .blur(radius: 12)
                .offset(y: 6)

            // Animated gradient
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.violet,
                            Aurora.Colors.purple,
                            Aurora.Colors.electric,
                            Aurora.Colors.violet
                        ],
                        startPoint: UnitPoint(x: gradientOffset, y: 0),
                        endPoint: UnitPoint(x: gradientOffset + 1, y: 1)
                    )
                )

            // Top highlight
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )

            // Press overlay
            if isPressed {
                Capsule()
                    .fill(Color.white.opacity(0.1))
            }
        }
        .shadow(color: Aurora.Colors.violet.opacity(0.4), radius: isPressed ? 8 : 16, y: isPressed ? 3 : 6)
    }

    private var secondaryBackground: some View {
        ZStack {
            // Glass fill
            Capsule()
                .fill(Aurora.Colors.glassBase)

            // Gradient overlay
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.cosmicSurface.opacity(0.6),
                            Aurora.Colors.cosmicDeep.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Border
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.electric.opacity(0.5),
                            Aurora.Colors.glassBorder,
                            Aurora.Colors.glassBorder.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // Press overlay
            if isPressed {
                Capsule()
                    .fill(Aurora.Colors.electric.opacity(0.1))
            }
        }
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
    }

    // MARK: - Button Content

    private var buttonContent: some View {
        HStack(spacing: Aurora.Layout.spacingSmall) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: contentColor))
                    .scaleEffect(0.9)
            } else {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .foregroundStyle(contentColor)
        .frame(maxWidth: style == .ghost ? nil : .infinity)
    }

    private var contentColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Aurora.Colors.textPrimary
        case .ghost:
            return Aurora.Colors.electric
        }
    }

    // MARK: - Animations

    private func startGradientAnimation() {
        // Flowing gradient
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            gradientOffset = 1
        }

        // Glow pulsing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.5
        }
    }
}

// MARK: - Aurora Link Button

/// Simple text link button for secondary actions
struct AuroraLinkButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    init(
        _ title: String,
        color: Color = Aurora.Colors.electric,
        action: @escaping () -> Void
    ) {
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
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Aurora Icon Button

/// Circular icon button
struct AuroraIconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @State private var isPressed: Bool = false

    init(
        icon: String,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(Aurora.Colors.glassBase)

                Circle()
                    .stroke(Aurora.Gradients.glassBorder, lineWidth: 1)

                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(Aurora.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("Aurora Buttons") {
    VStack(spacing: 24) {
        // Primary buttons
        AuroraButton("Sign In", style: .primary) { }

        AuroraButton("Loading...", style: .primary, isLoading: true) { }

        AuroraButton("Disabled", style: .primary, isEnabled: false) { }

        AuroraButton("Continue", style: .primary, icon: "arrow.right") { }

        // Secondary buttons
        AuroraButton("Create Account", style: .secondary) { }

        AuroraButton("Skip", style: .secondary, icon: "chevron.right") { }

        // Ghost buttons
        HStack(spacing: 20) {
            AuroraButton("Back", style: .ghost, icon: "arrow.left") { }
            AuroraButton("Forgot Password?", style: .ghost) { }
        }

        // Link buttons
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.system(size: 15))
                .foregroundStyle(Aurora.Colors.textSecondary)

            AuroraLinkButton("Sign Up") { }
        }

        // Icon buttons
        HStack(spacing: 16) {
            AuroraIconButton(icon: "arrow.left") { }
            AuroraIconButton(icon: "xmark", size: 36) { }
            AuroraIconButton(icon: "info.circle") { }
        }
    }
    .padding()
    .background(AuroraBackground.auth)
}
