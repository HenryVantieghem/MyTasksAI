//
//  EmptyTasksView.swift
//  Veloce
//
//  Empty Tasks View
//  Beautiful empty state for when there are no tasks
//

import SwiftUI

// MARK: - Empty Tasks View

struct EmptyTasksView: View {
    let onAddTask: () -> Void

    @State private var floatOffset: CGFloat = 0
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Animated icon
            animatedIcon
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            // Message
            VStack(spacing: Theme.Spacing.sm) {
                Text("Ready to conquer your day?")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Type your first task below to get started")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            // CTA button
            Button {
                HapticsService.shared.impact()
                onAddTask()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Add Your First Task")
                        .font(Theme.Typography.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    Capsule()
                        .fill(Theme.Colors.accentGradient)
                        .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 12, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)

            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.2)) {
                showContent = true
            }
            startFloatingAnimation()
        }
    }

    // MARK: - Animated Icon

    private var animatedIcon: some View {
        ZStack {
            // Glow
            SwiftUI.Circle()
                .fill(Theme.Colors.accentGradient)
                .frame(width: 120, height: 120)
                .blur(radius: 40)
                .opacity(0.4)

            // Icon container
            ZStack {
                // Background circles
                ForEach(0..<3, id: \.self) { index in
                    SwiftUI.Circle()
                        .stroke(Theme.Colors.accent.opacity(0.1 + Double(index) * 0.05), lineWidth: 1)
                        .frame(width: CGFloat(80 + index * 20), height: CGFloat(80 + index * 20))
                }

                // Main icon
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.aiPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.byLayer, options: .repeating)
            }
            .offset(y: floatOffset)
        }
    }

    // MARK: - Floating Animation

    private func startFloatingAnimation() {
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            floatOffset = -8
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        IridescentBackground(intensity: 0.4)

        EmptyTasksView {
            print("Add task tapped")
        }
    }
}
