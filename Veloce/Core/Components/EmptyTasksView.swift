//
//  EmptyTasksView.swift
//  Veloce
//
//  Minimal Empty State - Clean and understated
//

import SwiftUI

// MARK: - Empty Tasks View

struct EmptyTasksView: View {
    @State private var showContent = false
    @State private var iconPulse = false
    @State private var arrowBounce = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main content
            VStack(spacing: Theme.Spacing.xl) {
                // Icon with gentle pulse
                Image(systemName: "checkmark.circle.dashed")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(Theme.Colors.textTertiary.opacity(0.6))
                    .scaleEffect(iconPulse ? 1.04 : 1.0)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)

                // Text stack
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Ready when you are")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Your tasks will appear here")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 12)
            }

            Spacer()

            // Arrow pointing to input bar
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary.opacity(0.4))
                    .offset(y: arrowBounce ? 4 : 0)
            }
            .opacity(showContent ? 1 : 0)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Icon pulse every 3 seconds
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
            .delay(1.5)
        ) {
            iconPulse = true
        }

        // Arrow bounce
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            arrowBounce = true
        }
    }
}

// MARK: - Preview

#Preview("Minimal Empty State") {
    ZStack {
        Theme.CelestialColors.void
            .ignoresSafeArea()

        EmptyTasksView()
    }
}
