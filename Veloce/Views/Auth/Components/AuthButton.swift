//
//  AuthButton.swift
//  Veloce
//
//  Auth Button
//  Glass morphic button with loading and success states
//

import SwiftUI

// MARK: - Auth Button Style

enum AuthButtonStyle {
    case primary
    case secondary
    case text
}

// MARK: - Auth Button

struct AuthButton: View {
    let title: String
    let style: AuthButtonStyle
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var isPressed: Bool = false
    @State private var showSuccess: Bool = false
    @State private var glowPhase: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    init(
        _ title: String,
        style: AuthButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
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
            ZStack {
                // Background
                background

                // Content
                HStack(spacing: Theme.Spacing.sm) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: contentColor))
                            .scaleEffect(0.9)
                    } else if showSuccess {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(contentColor)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text(title)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(contentColor)
                    }
                }
                .animation(Theme.Animation.spring, value: isLoading)
                .animation(Theme.Animation.spring, value: showSuccess)
            }
        }
        .buttonStyle(.plain)
        .frame(height: DesignTokens.Height.button)
        .scaleEffect(isPressed ? DesignTokens.Scale.pressed : 1)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(Theme.Animation.quickSpring, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(!isEnabled || isLoading)
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            primaryBackground
        case .secondary:
            secondaryBackground
        case .text:
            Color.clear
        }
    }

    private var primaryBackground: some View {
        ZStack {
            // Glow effect
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.accentGradient)
                .blur(radius: 12)
                .opacity(0.4)

            // Main button
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.accentGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }

    private var secondaryBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.lg)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.Colors.glassBorder.opacity(0.5), lineWidth: 1)
            )
    }

    // MARK: - Content Color

    private var contentColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Theme.Colors.textPrimary
        case .text:
            return Theme.Colors.accent
        }
    }

    // MARK: - Success Animation

    func triggerSuccess() {
        withAnimation(Theme.Animation.springBouncy) {
            showSuccess = true
        }
        HapticsService.shared.taskComplete()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                showSuccess = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AuthButton("Sign In", style: .primary) { }

        AuthButton("Sign In", style: .primary, isLoading: true) { }

        AuthButton("Create Account", style: .secondary) { }

        AuthButton("Forgot Password?", style: .text) { }

        AuthButton("Disabled", style: .primary, isEnabled: false) { }
    }
    .padding()
    .background(AnimatedAuthBackground())
}
