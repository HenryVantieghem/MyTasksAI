//
//  FloatingInputBar.swift
//  Veloce
//
//  Premium Floating Input Bar
//  iOS 26 Liquid Glass with expanding focus, AI toggle, and orb send button
//

import SwiftUI

// MARK: - Input Bar Metrics

private enum InputBarMetrics {
    static let baseHeight: CGFloat = 56
    static let expandedHeight: CGFloat = 76
    static let horizontalPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 28
    static let buttonSize: CGFloat = 40
    static let orbButtonSize: CGFloat = 44
    static let iconSize: CGFloat = 18
}

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
    var onVoiceInput: (() -> Void)? = nil

    // AI processing state
    @State private var isAIEnabled: Bool = true
    @State private var isAIProcessing: Bool = false

    // Voice input state
    @State private var isRecordingVoice: Bool = false

    // Animation states
    @State private var showQuickActions = false
    @State private var sendOrbPulse: CGFloat = 1.0
    @State private var aiSparkleRotation: Double = 0
    @State private var aiSparkleScale: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Gradient colors for orb send button
    private let orbGradient = LinearGradient(
        colors: [
            Color(hex: "8B5CF6"),
            Color(hex: "6366F1"),
            Color(hex: "3B82F6")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 12) {
            // Time-aware greeting (only when not focused)
            if !isFocused {
                TimeAwareGreeting(
                    completedTasksToday: completedTasksToday,
                    currentStreak: currentStreak,
                    isFirstTaskOfDay: isFirstTaskOfDay
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Quick actions menu (expandable above input)
            if showQuickActions {
                quickActionsMenu
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Main floating input container
            mainInputContainer
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.md)
        .animation(Theme.Animation.spring, value: isFocused)
        .animation(Theme.Animation.springBouncy, value: showQuickActions)
        .onAppear {
            startAnimations()
        }
        .onChange(of: canSend) { _, hasText in
            if hasText {
                startSendOrbPulse()
            }
        }
    }

    // MARK: - Main Input Container

    private var mainInputContainer: some View {
        HStack(spacing: 12) {
            // Voice input button (replaces plus button)
            voiceInputButton

            // Text field with expanding behavior
            expandingTextField

            // Right side controls
            HStack(spacing: 8) {
                // AI toggle button
                aiToggleButton

                // Send orb button
                if canSend {
                    sendOrbButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, InputBarMetrics.horizontalPadding)
        .padding(.vertical, isFocused ? 16 : 10)
        .frame(minHeight: isFocused ? InputBarMetrics.expandedHeight : InputBarMetrics.baseHeight)
        .background {
            // AI processing shimmer
            if isAIProcessing {
                aiProcessingBackground
            }
        }
        // 🌟 LIQUID GLASS: Interactive glass with tint for premium Claude mobile feel
        .glassEffect(
            .regular
                .tint(isFocused ? Color(hex: "8B5CF6").opacity(0.08) : .clear)
                .interactive(true),
            in: RoundedRectangle(cornerRadius: InputBarMetrics.cornerRadius)
        )
        .overlay {
            // Focus glow border with enhanced glass reflection
            if isFocused {
                RoundedRectangle(cornerRadius: InputBarMetrics.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.6),
                                Color(hex: "3B82F6").opacity(0.4),
                                Color(hex: "06B6D4").opacity(0.3),
                                .white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .blur(radius: 0.5)
            } else {
                // Subtle glass border when not focused
                RoundedRectangle(cornerRadius: InputBarMetrics.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.25),
                                .white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        }
        .shadow(
            color: canSend ? Color(hex: "8B5CF6").opacity(0.4) : .black.opacity(0.1),
            radius: isFocused ? 24 : 16,
            y: isFocused ? 8 : 4
        )
    }

    // MARK: - Voice Input Button

    private var voiceInputButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isRecordingVoice.toggle()
            }
            onVoiceInput?()
        } label: {
            ZStack {
                // Recording pulse animation
                if isRecordingVoice {
                    SwiftUI.Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: InputBarMetrics.buttonSize + 8, height: InputBarMetrics.buttonSize + 8)
                        .scaleEffect(isRecordingVoice ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                            value: isRecordingVoice
                        )
                }

                SwiftUI.Circle()
                    .fill(isRecordingVoice
                        ? Color.red.opacity(0.15)
                        : Color.white.opacity(0.08))
                    .frame(width: InputBarMetrics.buttonSize, height: InputBarMetrics.buttonSize)

                Image(systemName: isRecordingVoice ? "stop.fill" : "mic.fill")
                    .font(.system(size: InputBarMetrics.iconSize, weight: .medium))
                    .foregroundStyle(isRecordingVoice
                        ? Color.red
                        : Color.secondary)
                    .scaleEffect(isRecordingVoice ? 0.9 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .contentShape(SwiftUI.Circle())
        .accessibilityLabel(isRecordingVoice ? "Stop recording" : "Voice input")
        .accessibilityHint("Tap to record voice input for task creation")
    }

    // MARK: - Plus Button (Quick Actions)

    private var plusButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(Theme.Animation.springBouncy) {
                showQuickActions.toggle()
            }
        } label: {
            ZStack {
                SwiftUI.Circle()
                    .fill(showQuickActions
                        ? Color(hex: "8B5CF6").opacity(0.2)
                        : Color.white.opacity(0.08))
                    .frame(width: InputBarMetrics.buttonSize, height: InputBarMetrics.buttonSize)

                Image(systemName: "plus")
                    .font(.system(size: InputBarMetrics.iconSize, weight: .semibold))
                    .foregroundStyle(showQuickActions
                        ? Color(hex: "8B5CF6")
                        : Color.secondary)
                    .rotationEffect(.degrees(showQuickActions ? 45 : 0))
            }
        }
        .buttonStyle(.plain)
        .contentShape(SwiftUI.Circle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showQuickActions)
    }

    // MARK: - Expanding Text Field

    private var expandingTextField: some View {
        TextField("", text: $text, prompt: placeholderText, axis: .vertical)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.primary)
            .lineLimit(isFocused ? 1...6 : 1...2)
            .focused($isFocused)
            .submitLabel(.send)
            .onSubmit {
                if canSend {
                    submitTask()
                }
            }
            .tint(Color(hex: "8B5CF6"))
    }

    private var placeholderText: Text {
        Text("What's on your mind?")
            .font(.system(size: 16, weight: .thin))
            .italic()
            .foregroundStyle(.secondary.opacity(0.7))
    }

    // MARK: - AI Toggle Button

    private var aiToggleButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAIEnabled.toggle()
            }
            if isAIEnabled {
                triggerAISparkle()
            }
        } label: {
            ZStack {
                // Background glow when enabled
                if isAIEnabled {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "8B5CF6").opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 48, height: 48)
                        .blur(radius: 4)
                }

                // Button circle
                SwiftUI.Circle()
                    .fill(isAIEnabled
                        ? Color(hex: "8B5CF6").opacity(0.15)
                        : Color.white.opacity(0.05))
                    .frame(width: InputBarMetrics.buttonSize, height: InputBarMetrics.buttonSize)

                // Sparkles icon
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        isAIEnabled
                            ? LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "06B6D4")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.secondary.opacity(0.5), Color.secondary.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .rotationEffect(.degrees(aiSparkleRotation))
                    .scaleEffect(aiSparkleScale)
            }
        }
        .buttonStyle(.plain)
        .contentShape(SwiftUI.Circle())
        .accessibilityLabel(isAIEnabled ? "AI enabled" : "AI disabled")
        .accessibilityHint("Toggle AI task processing")
    }

    // MARK: - Send Orb Button

    private var sendOrbButton: some View {
        Button {
            submitTask()
        } label: {
            ZStack {
                // Outer glow
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.4),
                                Color(hex: "3B82F6").opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .blur(radius: 6)
                    .scaleEffect(sendOrbPulse)

                // Main orb
                SwiftUI.Circle()
                    .fill(orbGradient)
                    .frame(width: InputBarMetrics.orbButtonSize, height: InputBarMetrics.orbButtonSize)
                    .overlay {
                        // Inner highlight
                        SwiftUI.Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear
                                    ],
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 20
                                )
                            )
                    }
                    .scaleEffect(sendOrbPulse)

                // Arrow icon
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(OrbSendButtonStyle())
        .accessibilityLabel("Send task")
    }

    // MARK: - Quick Actions Menu

    private var quickActionsMenu: some View {
        HStack(spacing: 10) {
            InputQuickActionChip(
                icon: "calendar",
                label: "Schedule",
                color: Color(hex: "3B82F6")
            ) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onSchedule()
            }

            InputQuickActionChip(
                icon: "bolt.fill",
                label: "Priority",
                color: Color(hex: "F59E0B")
            ) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onPriority()
            }

            InputQuickActionChip(
                icon: "wand.and.stars",
                label: "AI Magic",
                color: Color(hex: "8B5CF6")
            ) {
                HapticsService.shared.selectionFeedback()
                withAnimation { showQuickActions = false }
                onAI()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        // 🌟 LIQUID GLASS: Interactive glass with subtle tint
        .glassEffect(
            .regular.interactive(true),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    // MARK: - AI Processing Background

    private var aiProcessingBackground: some View {
        RoundedRectangle(cornerRadius: InputBarMetrics.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "8B5CF6").opacity(0.1),
                        Color(hex: "06B6D4").opacity(0.05),
                        Color(hex: "8B5CF6").opacity(0.1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .blur(radius: 8)
    }

    // MARK: - Actions

    private func submitTask() {
        guard canSend else { return }

        if isAIEnabled {
            // Show AI processing animation
            withAnimation(.easeOut(duration: 0.2)) {
                isAIProcessing = true
            }
            HapticsService.shared.aiProcessingStart()
        } else {
            HapticsService.shared.impact()
        }

        onSubmit()

        // Reset AI processing state after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                isAIProcessing = false
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }
        // Animations triggered on demand
    }

    private func startSendOrbPulse() {
        guard !reduceMotion else { return }

        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            sendOrbPulse = 1.08
        }
    }

    private func triggerAISparkle() {
        guard !reduceMotion else { return }

        // Rotation animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            aiSparkleRotation += 180
        }

        // Scale bounce
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            aiSparkleScale = 1.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                aiSparkleScale = 1.0
            }
        }
    }
}

// MARK: - Orb Send Button Style

private struct OrbSendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Input Quick Action Chip

private struct InputQuickActionChip: View {
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
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.25), lineWidth: 0.5)
                    )
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Preview

#Preview("Floating Input Bar") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

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
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Input Bar - Focused") {
    struct PreviewWrapper: View {
        @State private var text = "Write quarterly report for Q4 review"
        @FocusState private var isFocused: Bool

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Spacer()

                    FloatingInputBar(
                        text: $text,
                        isFocused: $isFocused,
                        completedTasksToday: 3,
                        currentStreak: 14,
                        isFirstTaskOfDay: false,
                        onSubmit: { },
                        onSchedule: { },
                        onPriority: { },
                        onAI: { }
                    )
                }
            }
            .onAppear { isFocused = true }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Input Bar States") {
    VStack(spacing: 40) {
        // Empty state
        VStack(alignment: .leading, spacing: 8) {
            Text("Empty State")
                .font(.caption)
                .foregroundStyle(.secondary)

            InputBarPreview(text: "", showSend: false)
        }

        // With text
        VStack(alignment: .leading, spacing: 8) {
            Text("With Text")
                .font(.caption)
                .foregroundStyle(.secondary)

            InputBarPreview(text: "Write quarterly report", showSend: true)
        }
    }
    .padding(32)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

// Static preview helper
private struct InputBarPreview: View {
    let text: String
    let showSend: Bool

    private let orbGradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1"), Color(hex: "3B82F6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        HStack(spacing: 12) {
            // Plus
            SwiftUI.Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                )

            // Text
            Text(text.isEmpty ? "What's on your mind?" : text)
                .font(text.isEmpty
                    ? .system(size: 16, weight: .thin).italic()
                    : .system(size: 16, weight: .regular))
                .foregroundStyle(text.isEmpty ? Color.secondary.opacity(0.7) : Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // AI toggle
            SwiftUI.Circle()
                .fill(Color(hex: "8B5CF6").opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "06B6D4")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            // Send
            if showSend {
                SwiftUI.Circle()
                    .fill(orbGradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(height: 56)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}
