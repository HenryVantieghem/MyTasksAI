//
//  AIGuidanceWhisper.swift
//  MyTasksAI
//
//  AI Guidance Whisper - Playful 3-Sentence Motivation
//  Inline coaching that appears on uncompleted tasks
//  Tone: Playful & Motivating - like a supportive friend
//

import SwiftUI

// MARK: - AI Guidance Whisper View

struct AIGuidanceWhisper: View {
    let guidance: String
    let isExpanded: Bool
    var onTap: (() -> Void)? = nil

    @State private var sparklePhase: CGFloat = 0
    @State private var revealedCharacters: Int = 0
    @State private var hasAnimatedIn: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let typewriterSpeed: Double = 0.02

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                // Sparkle icon
                sparkleIcon

                // Guidance text
                guidanceText
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .background(whisperBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Subviews

    private var sparkleIcon: some View {
        ZStack {
            // Glow background
            Circle()
                .fill(Theme.Colors.aiPurple.opacity(0.15))
                .frame(width: 24, height: 24)
                .blur(radius: 4)
                .scaleEffect(1 + sparklePhase * 0.2)

            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(1 + sparklePhase * 0.1)
        }
        .frame(width: 24, height: 24)
    }

    private var guidanceText: some View {
        Group {
            if reduceMotion || hasAnimatedIn {
                // Show full text immediately
                Text(guidance)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .lineLimit(isExpanded ? nil : 3)
                    .multilineTextAlignment(.leading)
            } else {
                // Typewriter effect
                Text(String(guidance.prefix(revealedCharacters)))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .lineLimit(isExpanded ? nil : 3)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var whisperBackground: some View {
        ZStack {
            // Frosted glass base
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.white.opacity(0.04))

            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.08),
                            Theme.Colors.aiCyan.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Border
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.2),
                            Theme.Colors.aiCyan.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Sparkle breathing
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                sparklePhase = 1
            }

            // Typewriter effect (only on first appearance)
            if !hasAnimatedIn {
                typewriterReveal()
            }
        } else {
            hasAnimatedIn = true
        }
    }

    private func typewriterReveal() {
        let totalCharacters = guidance.count
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: typewriterSpeed, repeats: true) { timer in
            if currentIndex <= totalCharacters {
                revealedCharacters = currentIndex
                currentIndex += 1
            } else {
                timer.invalidate()
                hasAnimatedIn = true
            }
        }
    }
}

// MARK: - AI Guidance Generator

/// Generates playful, motivating 3-sentence guidance for tasks
enum AIGuidanceGenerator {

    /// Generate guidance for a task (used when AI guidance is not available)
    static func generateFallback(for taskTitle: String, taskType: TaskType) -> String {
        let encouragements = [
            ("You've totally got this!", "Just take the first tiny step.", "Your future self is already thanking you."),
            ("This one's going to feel great when it's done!", "Start with what you know.", "You're more ready than you think."),
            ("Let's make it happen!", "Break it into bite-sized pieces.", "Every task completed is a win."),
            ("Time to shine!", "Focus on progress, not perfection.", "You're building momentum with every step."),
            ("Ready to crush it?", "The hardest part is starting.", "Once you begin, you'll find your flow.")
        ]

        let taskTypeHints: [TaskType: [String]] = [
            .create: [
                "Open a blank doc and just write one sentence.",
                "Start with a rough draft - polish comes later.",
                "Let your creativity flow without judgment first."
            ],
            .communicate: [
                "A quick message is better than a perfect one.",
                "Just hit send - you can follow up if needed.",
                "Keep it simple and genuine."
            ],
            .consume: [
                "Set a timer for just 10 minutes to start.",
                "Take notes as you go - it helps retention.",
                "Focus on the key takeaways, not every detail."
            ],
            .coordinate: [
                "Make a quick checklist to stay organized.",
                "Tackle the easiest item first for momentum.",
                "Done is better than perfect for admin tasks."
            ]
        ]

        let randomEncouragement = encouragements.randomElement()!
        let taskHint = taskTypeHints[taskType]?.randomElement() ?? "Take it one step at a time."

        return "\(randomEncouragement.0) \(taskHint) \(randomEncouragement.2)"
    }

    /// Time-aware greeting prefixes for guidance
    static func timeAwareOpener() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<7:
            return "Early bird energy!"
        case 7..<12:
            return "Morning momentum!"
        case 12..<14:
            return "Midday power!"
        case 14..<17:
            return "Afternoon focus!"
        case 17..<21:
            return "Evening push!"
        case 21..<24, 0..<5:
            return "Night owl mode!"
        default:
            return "Let's go!"
        }
    }
}

// MARK: - Compact AI Chip

/// Smaller AI indicator for when full guidance isn't shown
struct AIGuidanceChip: View {
    let hasGuidance: Bool

    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))

            Text("AI")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(
            LinearGradient(
                colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Theme.Colors.aiPurple.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 0.5)
                )
        )
        .scaleEffect(1 + pulsePhase * 0.05)
        .opacity(hasGuidance ? 1 : 0.5)
        .onAppear {
            if hasGuidance && !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulsePhase = 1
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("AI Guidance Whisper") {
    VStack(spacing: 24) {
        Text("AI Guidance Whisper")
            .font(.headline)
            .foregroundStyle(.white)

        AIGuidanceWhisper(
            guidance: "You've totally got this! Just open a blank doc and write one sentence. Your future self is already thanking you.",
            isExpanded: false
        )
        .padding(.horizontal)

        AIGuidanceWhisper(
            guidance: "Time to make it happen! This email doesn't need to be perfect - just genuine. Hit send and move on to the next thing.",
            isExpanded: true
        )
        .padding(.horizontal)

        Divider()
            .background(.white.opacity(0.2))

        Text("AI Chip")
            .font(.headline)
            .foregroundStyle(.white)

        HStack(spacing: 16) {
            AIGuidanceChip(hasGuidance: true)
            AIGuidanceChip(hasGuidance: false)
        }

        Divider()
            .background(.white.opacity(0.2))

        Text("Generated Fallbacks")
            .font(.headline)
            .foregroundStyle(.white)

        VStack(alignment: .leading, spacing: 8) {
            Text("Create task:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(AIGuidanceGenerator.generateFallback(for: "Write report", taskType: .create))
                .font(.caption)
                .foregroundStyle(.white)

            Text("Communicate task:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(AIGuidanceGenerator.generateFallback(for: "Email client", taskType: .communicate))
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal)
    }
    .padding(32)
    .background(Theme.CelestialColors.void)
}
