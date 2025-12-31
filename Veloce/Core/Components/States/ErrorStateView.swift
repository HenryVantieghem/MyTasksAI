//
//  ErrorStateView.swift
//  Veloce
//
//  Error state component with retry action
//  Matches Living Cosmos aesthetic
//

import SwiftUI

// MARK: - Error State View

struct ErrorStateView: View {
    let message: String
    let retryAction: (() -> Void)?

    @State private var showContent = false
    @State private var iconShake = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Error icon with shake effect
            iconView

            // Text stack
            textStack

            // Retry button if action provided
            if let retryAction = retryAction {
                retryButton(action: retryAction)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            triggerShake()
        }
    }

    // MARK: - Subviews

    private var iconView: some View {
        ZStack {
            // Glow behind icon
            Circle()
                .fill(Theme.CelestialColors.errorNebula.opacity(0.2))
                .frame(width: 80, height: 80)
                .blur(radius: 12)

            // Icon
            Image(systemName: "exclamationmark.triangle")
                .dynamicTypeFont(base: 44, weight: .light)
                .foregroundStyle(Theme.CelestialColors.errorNebula)
                .offset(x: iconShake ? -3 : 0)
        }
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.8)
    }

    private var textStack: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Something went wrong")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(message)
                .dynamicTypeFont(base: 15, weight: .regular)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
    }

    private func retryButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticsService.shared.buttonTap()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .dynamicTypeFont(base: 14, weight: .semibold)

                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Theme.Colors.glassBackground)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 8)
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Animations

    private func triggerShake() {
        guard !reduceMotion else { return }

        // Quick shake effect
        withAnimation(.easeInOut(duration: 0.08).repeatCount(3, autoreverses: true)) {
            iconShake = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            iconShake = false
        }
    }
}

// MARK: - Convenience Initializers

extension ErrorStateView {
    /// Network error state
    static func network(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            message: "Unable to connect. Check your internet connection.",
            retryAction: retryAction
        )
    }

    /// Sync error state
    static func sync(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            message: "Failed to sync your data. Your changes are saved locally.",
            retryAction: retryAction
        )
    }

    /// Generic load error
    static func load(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            message: "Couldn't load this content. Please try again.",
            retryAction: retryAction
        )
    }
}

// MARK: - Inline Error Banner

/// Compact error banner for inline display
struct ErrorBanner: View {
    let message: String
    let dismissAction: (() -> Void)?

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .dynamicTypeFont(base: 18)
                .foregroundStyle(Theme.CelestialColors.errorNebula)

            Text(message)
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer()

            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark.circle.fill")
                        .dynamicTypeFont(base: 18)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.CelestialColors.errorNebula.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.CelestialColors.errorNebula.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Warning Banner

/// Warning banner for non-critical issues
struct WarningBanner: View {
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var isVisible = false

    init(message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .dynamicTypeFont(base: 18)
                .foregroundStyle(Theme.CelestialColors.warningNebula)

            Text(message)
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(Theme.CelestialColors.warningNebula)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.CelestialColors.warningNebula.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.CelestialColors.warningNebula.opacity(0.25), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Success Banner

/// Success banner for confirmations
struct SuccessBanner: View {
    let message: String

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .dynamicTypeFont(base: 18)
                .foregroundStyle(Theme.CelestialColors.successNebula)

            Text(message)
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.CelestialColors.successNebula.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.CelestialColors.successNebula.opacity(0.25), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Error State") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        ErrorStateView(
            message: "Unable to load your tasks. Please try again.",
            retryAction: {}
        )
    }
}

#Preview("Network Error") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        ErrorStateView.network(retryAction: {})
    }
}

#Preview("Error Banner") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        VStack {
            ErrorBanner(message: "Failed to save changes", dismissAction: {})
            Spacer()
        }
        .padding()
    }
}

#Preview("Warning Banner") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        VStack {
            WarningBanner(
                message: "Your subscription expires in 3 days",
                actionTitle: "Renew",
                action: {}
            )
            Spacer()
        }
        .padding()
    }
}

#Preview("Success Banner") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        VStack {
            SuccessBanner(message: "Changes saved successfully")
            Spacer()
        }
        .padding()
    }
}
