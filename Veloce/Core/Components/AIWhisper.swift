//
//  AIWhisper.swift
//  MyTasksAI
//
//  Inline AI Advice Component
//  Appears below tasks like handwritten margin notes with typewriter effect
//

import SwiftUI

// MARK: - AI Whisper

/// Inline AI advice that appears below tasks with typewriter animation
struct AIWhisper: View {
    let advice: String
    let estimatedMinutes: Int?
    let priority: String?
    let isAnimating: Bool
    let onTap: (() -> Void)?

    @State private var hasAppeared: Bool = false
    @State private var sparklePhase: CGFloat = 0

    init(
        advice: String,
        estimatedMinutes: Int? = nil,
        priority: String? = nil,
        isAnimating: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.advice = advice
        self.estimatedMinutes = estimatedMinutes
        self.priority = priority
        self.isAnimating = isAnimating
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(alignment: .top, spacing: 6) {
                // Sparkle icon with subtle pulse
                sparkleIcon

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Advice text with typewriter effect
                    if isAnimating && !hasAppeared {
                        TypewriterText(
                            advice,
                            font: Theme.Typography.aiWhisper,
                            color: Theme.Colors.textSecondary.opacity(0.75),
                            characterDelay: 0.02,
                            onComplete: { hasAppeared = true }
                        )
                        .lineLimit(2)
                    } else {
                        Text(advice)
                            .font(Theme.Typography.aiWhisper)
                            .foregroundStyle(Theme.Colors.textSecondary.opacity(0.75))
                            .lineLimit(2)
                    }

                    // Time and priority pills (if available)
                    if estimatedMinutes != nil || priority != nil {
                        metadataPills
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.leading, 36) // Align with task text (checkbox width + spacing)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                sparklePhase = 1
            }
        }
    }

    // MARK: - Sparkle Icon

    private var sparkleIcon: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiOrange.opacity(0.8),
                        Theme.Colors.aiPurple.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.3))
    }

    // MARK: - Metadata Pills

    private var metadataPills: some View {
        HStack(spacing: 6) {
            // Time estimate pill
            if let minutes = estimatedMinutes {
                WhisperPill(
                    icon: "clock",
                    text: "\(minutes)m",
                    color: Theme.Colors.aiBlue
                )
            }

            // Priority pill
            if let priority = priority {
                WhisperPill(
                    icon: priorityIcon(for: priority),
                    text: priority.capitalized,
                    color: priorityColor(for: priority)
                )
            }
        }
        .padding(.top, 2)
    }

    private func priorityIcon(for priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "minus.circle.fill"
        case "low": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }

    private func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return Theme.Colors.destructive
        case "medium": return Theme.Colors.warning
        case "low": return Theme.Colors.success
        default: return Theme.Colors.textTertiary
        }
    }
}

// MARK: - Whisper Pill

/// Small pill for metadata in AI whispers
struct WhisperPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .medium))

            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(color.opacity(0.8))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - AI Whisper Loading State

/// Shows when AI is processing a task
struct AIWhisperLoading: View {
    @State private var dotCount: Int = 0

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Spinning sparkle
            if #available(iOS 18.0, *) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: Theme.Colors.aiGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.rotate, options: .repeating.speed(0.5))
            } else {
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: Theme.Colors.aiGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Loading text with animated dots
            Text("Thinking" + String(repeating: ".", count: dotCount))
                .font(Theme.Typography.aiWhisper)
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.6))
        }
        .padding(.leading, 36)
        .task {
            await animateDots()
        }
    }

    private func animateDots() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(400))
            await MainActor.run {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

// MARK: - AI Suggestion Card

/// Proactive AI suggestion that appears below the task input
struct AISuggestionCard: View {
    let suggestion: String
    let reason: String
    let onAccept: () -> Void
    let onDismiss: () -> Void

    @State private var isVisible: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("Suggestion")
                    .font(Theme.Typography.caption1Medium)
                    .foregroundStyle(Theme.Colors.aiPurple)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            // Suggestion text
            Text(suggestion)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)

            // Reason
            Text(reason)
                .font(Theme.Typography.aiWhisper)
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.7))

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onAccept) {
                    Text("Add Task")
                        .font(Theme.Typography.pillText)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.accent)
                        )
                }

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(Theme.Typography.pillText)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .strokeBorder(Theme.Colors.textTertiary.opacity(0.3))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Colors.aiPurple.opacity(0.1), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiOrange.opacity(0.3),
                            Theme.Colors.aiPurple.opacity(0.3),
                            Theme.Colors.aiBlue.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview("AI Whisper") {
    VStack(alignment: .leading, spacing: 24) {
        Text("AI Whisper Variants")
            .font(Theme.Typography.title2)
            .padding(.horizontal)

        // Basic whisper
        VStack(alignment: .leading) {
            Text("Basic Whisper:")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textTertiary)

            AIWhisper(
                advice: "Consider breaking this into smaller steps for better focus.",
                isAnimating: true
            )
        }
        .padding(.horizontal)

        Divider()

        // Whisper with metadata
        VStack(alignment: .leading) {
            Text("With Metadata:")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textTertiary)

            AIWhisper(
                advice: "This task typically takes 30-45 minutes. Best done in the morning.",
                estimatedMinutes: 45,
                priority: "high",
                isAnimating: false
            )
        }
        .padding(.horizontal)

        Divider()

        // Loading state
        VStack(alignment: .leading) {
            Text("Loading State:")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textTertiary)

            AIWhisperLoading()
        }
        .padding(.horizontal)

        Divider()

        // Suggestion card
        VStack(alignment: .leading) {
            Text("Suggestion Card:")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textTertiary)

            AISuggestionCard(
                suggestion: "Review weekly report",
                reason: "You typically do this every Friday",
                onAccept: {},
                onDismiss: {}
            )
        }
        .padding(.horizontal)

        Spacer()
    }
    .padding(.vertical)
    .background(Theme.Colors.background)
}
