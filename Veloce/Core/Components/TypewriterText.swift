//
//  TypewriterText.swift
//  MyTasksAI
//
//  Character-by-character text reveal animation
//  Creates the magical "writing itself" effect for AI whispers
//

import SwiftUI

// MARK: - Typewriter Text

/// Text that reveals itself character by character like a typewriter
struct TypewriterText: View {
    let text: String
    let font: Font
    let color: Color
    let characterDelay: Double
    let onComplete: (() -> Void)?

    @State private var revealedCount: Int = 0
    @State private var isComplete: Bool = false

    init(
        _ text: String,
        font: Font = Theme.Typography.aiWhisper,
        color: Color = Theme.Colors.textSecondary,
        characterDelay: Double = 0.025,
        onComplete: (() -> Void)? = nil
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.characterDelay = characterDelay
        self.onComplete = onComplete
    }

    var body: some View {
        Text(visibleText)
            .font(font)
            .foregroundStyle(color)
            .task {
                await animateText()
            }
    }

    private var visibleText: String {
        String(text.prefix(revealedCount))
    }

    private func animateText() async {
        // Reset if text changes
        revealedCount = 0
        isComplete = false

        for i in 1...text.count {
            // Check for cancellation
            guard !Task.isCancelled else { return }

            // Small delay between characters
            try? await Task.sleep(for: .milliseconds(Int(characterDelay * 1000)))

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.05)) {
                    revealedCount = i
                }
            }
        }

        await MainActor.run {
            isComplete = true
            onComplete?()
        }
    }
}

// MARK: - Typewriter Text with Cursor

/// Typewriter text with a blinking cursor at the end
struct TypewriterTextWithCursor: View {
    let text: String
    let font: Font
    let color: Color
    let characterDelay: Double
    let showCursor: Bool

    @State private var revealedCount: Int = 0
    @State private var cursorVisible: Bool = true
    @State private var isTyping: Bool = true

    init(
        _ text: String,
        font: Font = Theme.Typography.aiWhisper,
        color: Color = Theme.Colors.textSecondary,
        characterDelay: Double = 0.025,
        showCursor: Bool = true
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.characterDelay = characterDelay
        self.showCursor = showCursor
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(visibleText)
                .font(font)
                .foregroundStyle(color)

            // Blinking cursor
            if showCursor && (isTyping || cursorVisible) {
                Text("|")
                    .font(font)
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .opacity(cursorVisible ? 1 : 0)
            }
        }
        .task {
            await animateText()
        }
        .task {
            await animateCursor()
        }
    }

    private var visibleText: String {
        String(text.prefix(revealedCount))
    }

    private func animateText() async {
        revealedCount = 0
        isTyping = true

        for i in 1...text.count {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(Int(characterDelay * 1000)))

            await MainActor.run {
                revealedCount = i
            }
        }

        await MainActor.run {
            isTyping = false
        }

        // Hide cursor after a delay
        try? await Task.sleep(for: .seconds(2))
        await MainActor.run {
            cursorVisible = false
        }
    }

    private func animateCursor() async {
        while !Task.isCancelled && isTyping {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                cursorVisible.toggle()
            }
        }
    }
}

// MARK: - Gradient Typewriter Text

/// Typewriter text with animated gradient fill (AI style)
struct GradientTypewriterText: View {
    let text: String
    let font: Font
    let characterDelay: Double

    @State private var revealedCount: Int = 0
    @State private var gradientPhase: CGFloat = 0

    init(
        _ text: String,
        font: Font = Theme.Typography.aiWhisper,
        characterDelay: Double = 0.03
    ) {
        self.text = text
        self.font = font
        self.characterDelay = characterDelay
    }

    var body: some View {
        Text(visibleText)
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiOrange,
                        Theme.Colors.aiPurple,
                        Theme.Colors.aiBlue
                    ],
                    startPoint: UnitPoint(x: gradientPhase, y: 0),
                    endPoint: UnitPoint(x: gradientPhase + 1, y: 1)
                )
            )
            .task {
                await animateText()
            }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    gradientPhase = 1
                }
            }
    }

    private var visibleText: String {
        String(text.prefix(revealedCount))
    }

    private func animateText() async {
        revealedCount = 0

        for i in 1...text.count {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(Int(characterDelay * 1000)))

            await MainActor.run {
                revealedCount = i
            }
        }
    }
}

// MARK: - Typewriter Text Modifier

/// View modifier to add typewriter effect to any text
struct TypewriterModifier: ViewModifier {
    let isActive: Bool
    let characterDelay: Double

    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(x: offset)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        opacity = 1
                        offset = 0
                    }
                } else {
                    opacity = 0
                    offset = 10
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(characterDelay)) {
                        opacity = 1
                        offset = 0
                    }
                }
            }
    }
}

extension View {
    /// Apply typewriter reveal animation
    func typewriterReveal(isActive: Bool = true, delay: Double = 0.3) -> some View {
        modifier(TypewriterModifier(isActive: isActive, characterDelay: delay))
    }
}

// MARK: - Staggered Text Reveal

/// Reveals multiple lines of text with staggered timing
struct StaggeredTextReveal: View {
    let lines: [String]
    let font: Font
    let color: Color
    let lineDelay: Double
    let characterDelay: Double

    @State private var visibleLines: Int = 0

    init(
        lines: [String],
        font: Font = Theme.Typography.aiWhisper,
        color: Color = Theme.Colors.textSecondary,
        lineDelay: Double = 0.5,
        characterDelay: Double = 0.02
    ) {
        self.lines = lines
        self.font = font
        self.color = color
        self.lineDelay = lineDelay
        self.characterDelay = characterDelay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if index < visibleLines {
                    TypewriterText(
                        line,
                        font: font,
                        color: color,
                        characterDelay: characterDelay
                    )
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
        }
        .task {
            await revealLines()
        }
    }

    private func revealLines() async {
        for i in 1...lines.count {
            guard !Task.isCancelled else { return }

            // Wait for line delay
            try? await Task.sleep(for: .milliseconds(Int(lineDelay * 1000)))

            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    visibleLines = i
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Typewriter Text") {
    VStack(alignment: .leading, spacing: 24) {
        Text("Typewriter Effects")
            .font(Theme.Typography.title2)

        TypewriterText(
            "This text types itself character by character...",
            font: Theme.Typography.body
        )

        Divider()

        TypewriterTextWithCursor(
            "AI is thinking about your task...",
            font: Theme.Typography.aiWhisper,
            color: Theme.Colors.aiPurple
        )

        Divider()

        GradientTypewriterText(
            "Gradient animated typewriter text!",
            font: Theme.Typography.headline
        )

        Divider()

        StaggeredTextReveal(
            lines: [
                "First, analyze the task...",
                "Then, break it into steps...",
                "Finally, estimate the time."
            ],
            lineDelay: 1.0
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
