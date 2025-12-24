//
//  KeyboardDismissButton.swift
//  Veloce
//
//  Reusable keyboard dismiss button with haptic feedback
//  Used in input bars across Tasks, Journal, and Dump pages
//

import SwiftUI

// MARK: - Keyboard Dismiss Button

struct KeyboardDismissButton: View {
    let onDismiss: () -> Void

    var body: some View {
        Button {
            HapticsService.shared.lightImpact()
            onDismiss()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    SwiftUI.Circle()
                        .fill(Theme.Colors.glassBackground.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
        .contentShape(SwiftUI.Circle())
        .accessibilityLabel("Dismiss keyboard")
        .accessibilityHint("Double tap to hide the keyboard")
    }
}

// MARK: - Preview

#Preview("Keyboard Dismiss Button") {
    ZStack {
        Theme.CelestialColors.void
            .ignoresSafeArea()

        KeyboardDismissButton {
            print("Keyboard dismissed")
        }
    }
}
