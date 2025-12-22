//
//  FloatingInputBar.swift
//  MyTasksAI
//
//  Floating Input Bar - Claude Mobile Inspired
//  Premium glass morphic input with time-aware greetings
//  Features: Plus menu, animated send, mic placeholder
//

import SwiftUI

// MARK: - Floating Input Bar

struct FloatingInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    let completedTasksToday: Int
    let currentStreak: Int
    let isFirstTaskOfDay: Bool

    let onSubmit: () -> Void
    let onSchedule: () -> Void
    let onPriority: () -> Void
    let onAI: () -> Void

    @State private var showQuickActions = false
    @State private var glowPhase: CGFloat = 0
    @State private var borderRotation: Double = 0

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: DesignTokens.InputBar.greetingSpacing) {
            // Time-aware greeting
            TimeAwareGreeting(
                completedTasksToday: completedTasksToday,
                currentStreak: currentStreak,
                isFirstTaskOfDay: isFirstTaskOfDay
            )

            // Quick actions menu (expandable above input)
            if showQuickActions {
                quickActionsMenu
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Main floating input container
            floatingContainer
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, DesignTokens.InputBar.bottomMargin)
        .animation(Theme.Animation.springBouncy, value: showQuickActions)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Floating Container

    private var floatingContainer: some View {
        HStack(spacing: DesignTokens.InputBar.elementSpacing) {
            // Plus button
            plusButton

            // Text field
            textFieldView

            // Right side controls
            HStack(spacing: Theme.Spacing.sm) {
                // Mic button (placeholder)
                if !canSend {
                    micButton
                        .transition(.scale.combined(with: .opacity))
                }

                // Send button
                if canSend {
                    sendButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: canSend)
        }
        .padding(.horizontal, DesignTokens.InputBar.horizontalPadding)
        .padding(.vertical, DesignTokens.InputBar.verticalPadding)
        .background(containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.InputBar.cornerRadius))
        .overlay(containerBorder)
        .shadow(
            color: Theme.InputBarColors.sendGlow.opacity(glowPhase * (isFocused ? 0.4 : 0.2)),
            radius: 16,
            y: 4
        )
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
                    .fill(showQuickActions
                        ? Theme.InputBarColors.plusActive
                        : Theme.InputBarColors.plusBackground)
                    .frame(
                        width: DesignTokens.InputBar.buttonSize,
                        height: DesignTokens.InputBar.buttonSize
                    )

                Image(systemName: "plus")
                    .font(.system(size: DesignTokens.InputBar.buttonIconSize, weight: .semibold))
                    .foregroundStyle(showQuickActions
                        ? Theme.Colors.aiPurple
                        : Theme.CelestialColors.starDim)
                    .rotationEffect(.degrees(showQuickActions ? 45 : 0))
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showQuickActions)
    }

    // MARK: - Text Field

    private var textFieldView: some View {
        TextField("What needs to be done?", text: $text, axis: .vertical)
            .font(.system(size: 16))
            .foregroundStyle(Theme.CelestialColors.starWhite)
            .lineLimit(1...4)
            .focused($isFocused)
            .submitLabel(.send)
            .onSubmit {
                if canSend {
                    submitTask()
                }
            }
            .tint(Theme.Colors.aiPurple)
    }

    // MARK: - Mic Button (Placeholder)

    private var micButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            // Future: Voice input
        } label: {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(
                        width: DesignTokens.InputBar.buttonSize,
                        height: DesignTokens.InputBar.buttonSize
                    )

                Image(systemName: "mic")
                    .font(.system(size: DesignTokens.InputBar.buttonIconSize, weight: .medium))
                    .foregroundStyle(Theme.InputBarColors.micInactive)
            }
        }
        .buttonStyle(.plain)
        .disabled(true) // Placeholder - disabled for now
        .opacity(0.5)
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            submitTask()
        } label: {
            ZStack {
                // Glow background
                Circle()
                    .fill(Theme.InputBarColors.sendGlow.opacity(0.3))
                    .frame(width: DesignTokens.InputBar.buttonSize + 8, height: DesignTokens.InputBar.buttonSize + 8)
                    .blur(radius: 8)

                // Button background
                Circle()
                    .fill(Theme.InputBarColors.sendGradient)
                    .frame(
                        width: DesignTokens.InputBar.buttonSize,
                        height: DesignTokens.InputBar.buttonSize
                    )

                // Arrow icon
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(SendButtonStyle())
    }

    // MARK: - Quick Actions Menu

    private var quickActionsMenu: some View {
        HStack(spacing: Theme.Spacing.sm) {
            FloatingQuickActionPill(
                icon: "calendar",
                label: "Schedule",
                color: Theme.Colors.aiBlue
            ) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onSchedule()
            }

            FloatingQuickActionPill(
                icon: "bolt.fill",
                label: "Priority",
                color: Theme.TaskCardColors.pointsGlow
            ) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onPriority()
            }

            FloatingQuickActionPill(
                icon: "sparkles",
                label: "AI Magic",
                color: Theme.Colors.aiPurple
            ) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onAI()
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Container Background

    private var containerBackground: some View {
        ZStack {
            // Frosted glass
            RoundedRectangle(cornerRadius: DesignTokens.InputBar.cornerRadius)
                .fill(.ultraThinMaterial)

            // Violet tint when focused
            if isFocused {
                RoundedRectangle(cornerRadius: DesignTokens.InputBar.cornerRadius)
                    .fill(Theme.Colors.aiPurple.opacity(0.05))
            }
        }
    }

    // MARK: - Container Border

    private var containerBorder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.InputBar.cornerRadius)
            .stroke(borderGradient, lineWidth: isFocused ? 1.5 : 1)
    }

    private var borderGradient: LinearGradient {
        if isFocused {
            return LinearGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.6),
                    Theme.Colors.aiCyan.opacity(0.3),
                    Theme.Colors.aiPurple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Actions

    private func submitTask() {
        guard canSend else { return }
        HapticsService.shared.impact()
        onSubmit()
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Subtle glow pulse
        withAnimation(.easeInOut(duration: DesignTokens.InputBar.glowDuration).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }
    }
}

// MARK: - Send Button Style

private struct SendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Quick Action Pill

fileprivate struct FloatingQuickActionPill: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("Floating Input Bar") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                Spacer()

                FloatingInputBar(
                    text: $text,
                    isFocused: $isFocused,
                    completedTasksToday: 5,
                    currentStreak: 7,
                    isFirstTaskOfDay: false,
                    onSubmit: { print("Submit: \(text)"); text = "" },
                    onSchedule: { print("Schedule") },
                    onPriority: { print("Priority") },
                    onAI: { print("AI Magic") }
                )
            }
            .background(Theme.CelestialColors.void)
        }
    }

    return PreviewWrapper()
}

#Preview("Input Bar States") {
    VStack(spacing: 32) {
        Text("Input Bar States")
            .font(.headline)
            .foregroundStyle(.white)

        // Empty state
        VStack(spacing: 8) {
            Text("Empty")
                .font(.caption)
                .foregroundStyle(.secondary)

            StaticInputPreview(text: "", isFocused: false)
        }

        // With text
        VStack(spacing: 8) {
            Text("With Text")
                .font(.caption)
                .foregroundStyle(.secondary)

            StaticInputPreview(text: "Write quarterly report", isFocused: true)
        }
    }
    .padding(32)
    .background(Theme.CelestialColors.void)
}

// Static preview helper
private struct StaticInputPreview: View {
    let text: String
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Plus
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                )

            // Text
            Text(text.isEmpty ? "What needs to be done?" : text)
                .font(.system(size: 16))
                .foregroundStyle(text.isEmpty ? Theme.CelestialColors.starGhost : .white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Send or Mic
            if !text.isEmpty {
                Circle()
                    .fill(Theme.InputBarColors.sendGradient)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )
            } else {
                Image(systemName: "mic")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.InputBarColors.micInactive)
                    .opacity(0.5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    isFocused
                        ? Theme.Colors.aiPurple.opacity(0.5)
                        : Color.white.opacity(0.1),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
    }
}
