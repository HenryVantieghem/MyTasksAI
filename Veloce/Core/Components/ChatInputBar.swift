//
//  ChatInputBar.swift
//  Veloce
//
//  Chat Input Bar
//  Claude-inspired glass morphic input for creating tasks
//

import SwiftUI

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void
    let onSchedule: () -> Void
    let onPriority: () -> Void
    let onAI: () -> Void

    @State private var showQuickActions = false
    @State private var glowOpacity: Double = 0.3
    @Environment(\.colorScheme) private var colorScheme

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Quick actions menu (expandable)
            if showQuickActions {
                quickActionsMenu
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Main input card
            HStack(spacing: Theme.Spacing.md) {
                // Plus button (opens quick actions)
                plusButton

                // Text input field
                textFieldView

                // Right side buttons
                HStack(spacing: Theme.Spacing.sm) {
                    // Microphone button (future voice input)
                    microphoneButton

                    // Send button
                    sendButton
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(inputCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xxl))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xxl)
                    .stroke(inputBorderGradient, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.aiPurple.opacity(glowOpacity * 0.3), radius: Theme.Spacing.screenPadding, y: Theme.Spacing.xs)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.sm)
        }
        .animation(Theme.Animation.springBouncy, value: showQuickActions)
        .onAppear {
            startGlowAnimation()
        }
    }

    // MARK: - Plus Button

    private var plusButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(Theme.Animation.springBouncy) {
                showQuickActions.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(showQuickActions ? Theme.Colors.accent.opacity(0.2) : Theme.Colors.glassBackground.opacity(0.3))
                    .frame(width: 32, height: 32)

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(showQuickActions ? Theme.Colors.accent : Theme.Colors.textSecondary)
                    .rotationEffect(.degrees(showQuickActions ? 45 : 0))
            }
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.springBouncy, value: showQuickActions)
    }

    // MARK: - Quick Actions Menu

    private var quickActionsMenu: some View {
        HStack(spacing: Theme.Spacing.md) {
            QuickActionPill(icon: "calendar", label: "Schedule", color: Theme.Colors.aiBlue) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onSchedule()
            }

            QuickActionPill(icon: "star.fill", label: "Priority", color: Theme.Colors.xp) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onPriority()
            }

            QuickActionPill(icon: "sparkles", label: "AI Magic", color: Theme.Colors.aiPurple) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onAI()
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.vertical, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Text Field View

    private var textFieldView: some View {
        TextField("What needs to be done?", text: $text, axis: .vertical)
            .font(.system(size: 16, weight: .regular))
            .lineLimit(1...6)
            .focused($isFocused)
            .submitLabel(.send)
            .onSubmit {
                if canSend {
                    onSubmit()
                }
            }
    }

    // MARK: - Microphone Button

    private var microphoneButton: some View {
        Button {
            HapticsService.shared.lightImpact()
            // Future: Voice input
        } label: {
            Image(systemName: "mic")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .opacity(canSend ? 0 : 1)
        .scaleEffect(canSend ? 0.5 : 1)
        .animation(Theme.Animation.quickSpring, value: canSend)
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            HapticsService.shared.impact()
            onSubmit()
        } label: {
            ZStack {
                // Glow effect when can send
                if canSend {
                    Circle()
                        .fill(Theme.Colors.accent.opacity(0.4))
                        .blur(radius: 10)
                        .frame(width: 40, height: 40)
                }

                // Button background
                Circle()
                    .fill(canSend ? AnyShapeStyle(Theme.Colors.accentGradient) : AnyShapeStyle(Theme.Colors.glassBackground.opacity(0.3)))
                    .frame(width: 32, height: 32)

                // Arrow icon
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(canSend ? .white : Theme.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(canSend ? 1 : 0.85)
        .animation(Theme.Animation.springBouncy, value: canSend)
        .disabled(!canSend)
    }

    // MARK: - Input Card Background

    private var inputCardBackground: some View {
        ZStack {
            // Base glass material
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xxl)
                .fill(.ultraThinMaterial)

            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xxl)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.glassBackground.opacity(colorScheme == .dark ? 0.3 : 0.1),
                            Theme.Colors.glassBackground.opacity(colorScheme == .dark ? 0.15 : 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    // MARK: - Input Border Gradient

    private var inputBorderGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Theme.Colors.glassBorder.opacity(colorScheme == .dark ? 0.4 : 0.3),
                Theme.Colors.glassBorder.opacity(colorScheme == .dark ? 0.15 : 0.1),
                Theme.Colors.aiPurple.opacity(isFocused ? 0.3 : 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Glow Animation

    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
    }
}

// MARK: - Quick Action Pill

struct QuickActionPill: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs + 2) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(Theme.Animation.quickSpring, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Legacy Quick Action Button (kept for compatibility)

struct QuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1)
        .animation(Theme.Animation.quickSpring, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    HapticsService.shared.selectionFeedback()
                }
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        ChatInputBar(
            text: .constant(""),
            isFocused: FocusState<Bool>().projectedValue,
            onSubmit: { },
            onSchedule: { },
            onPriority: { },
            onAI: { }
        )
    }
    .background(IridescentBackground(intensity: 0.4))
}
