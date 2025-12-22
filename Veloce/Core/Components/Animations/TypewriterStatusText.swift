//
//  TypewriterStatusText.swift
//  MyTasksAI
//
//  Typewriter effect with character-by-character typing
//  Blinking cursor between messages
//  AI status messages with glow effect
//

import SwiftUI

// MARK: - Typewriter Status Text

struct TypewriterStatusText: View {
    let messages: [String]
    let isActive: Bool
    let onComplete: (() -> Void)?

    @State private var currentMessageIndex: Int = 0
    @State private var displayedText: String = ""
    @State private var showCursor: Bool = true
    @State private var isTyping: Bool = false
    @State private var glowIntensity: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let characterDelay: Double = 0.04
    private let messageDelay: Double = 0.8
    private let cursorBlinkInterval: Double = 0.5

    init(
        messages: [String] = [
            "Awakening...",
            "Perceiving your intent...",
            "Mapping neural pathways...",
            "Crystallizing insights...",
            "Manifesting genius..."
        ],
        isActive: Bool = true,
        onComplete: (() -> Void)? = nil
    ) {
        self.messages = messages
        self.isActive = isActive
        self.onComplete = onComplete
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(displayedText)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: Theme.TaskCardColors.strategy.opacity(glowIntensity), radius: 8)
                .shadow(color: Theme.TaskCardColors.strategy.opacity(glowIntensity * 0.5), radius: 16)

            // Blinking cursor
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 16)
                .opacity(showCursor && isTyping ? 1 : 0)
        }
        .onChange(of: isActive) { _, active in
            if active {
                startTypewriter()
            } else {
                resetTypewriter()
            }
        }
        .onAppear {
            if isActive {
                startTypewriter()
            }
            startCursorBlink()
        }
    }

    // MARK: - Typewriter Animation

    private func startTypewriter() {
        guard !messages.isEmpty else { return }

        if reduceMotion {
            // Show all messages instantly
            displayedText = messages.last ?? ""
            onComplete?()
            return
        }

        currentMessageIndex = 0
        displayedText = ""
        isTyping = true

        // Glow pulse
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }

        typeCurrentMessage()
    }

    private func typeCurrentMessage() {
        guard currentMessageIndex < messages.count else {
            isTyping = false
            onComplete?()
            return
        }

        let message = messages[currentMessageIndex]
        displayedText = ""

        typeCharacter(from: message, at: 0)
    }

    private func typeCharacter(from message: String, at index: Int) {
        guard index < message.count else {
            // Message complete, wait then move to next
            DispatchQueue.main.asyncAfter(deadline: .now() + messageDelay) {
                currentMessageIndex += 1
                typeCurrentMessage()
            }
            return
        }

        let stringIndex = message.index(message.startIndex, offsetBy: index)
        displayedText.append(message[stringIndex])

        // Generate haptic for certain characters
        if message[stringIndex] == "." || message[stringIndex] == "!" {
            HapticManager.shared.lightTap()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + characterDelay) {
            typeCharacter(from: message, at: index + 1)
        }
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: cursorBlinkInterval, repeats: true) { _ in
            showCursor.toggle()
        }
    }

    private func resetTypewriter() {
        isTyping = false
        displayedText = ""
        currentMessageIndex = 0
        withAnimation {
            glowIntensity = 0.5
        }
    }
}

// MARK: - Animated Status Pill

struct AnimatedStatusPill: View {
    let messages: [String]
    let isActive: Bool

    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text(messages[currentIndex])
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Theme.TaskCardColors.strategy.opacity(0.5),
                                        Theme.TaskCardColors.resources.opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .opacity(opacity)
            .onAppear {
                if isActive {
                    startCycling()
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    startCycling()
                }
            }
    }

    private func startCycling() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        func cycle() {
            guard isActive else { return }

            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentIndex = (currentIndex + 1) % messages.count

                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    cycle()
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            cycle()
        }
    }
}

// MARK: - Glowing Text

struct GlowingText: View {
    let text: String
    let color: Color
    let glowRadius: CGFloat

    @State private var glowPhase: CGFloat = 0

    var body: some View {
        Text(text)
            .foregroundStyle(.white)
            .shadow(color: color.opacity(0.5 + glowPhase * 0.5), radius: glowRadius)
            .shadow(color: color.opacity(0.3 + glowPhase * 0.3), radius: glowRadius * 2)
            .onAppear {
                if !UIAccessibility.isReduceMotionEnabled {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowPhase = 1
                    }
                }
            }
    }
}

// MARK: - Shimmer Loading Text

struct ShimmerLoadingText: View {
    let text: String

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        Text(text)
            .foregroundStyle(.white.opacity(0.5))
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.8),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: shimmerOffset * geometry.size.width * 1.5)
                    .mask(Text(text))
                }
            )
            .onAppear {
                if !UIAccessibility.isReduceMotionEnabled {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = 1
                    }
                }
            }
    }
}

// MARK: - Haptic Manager Helper

private enum HapticManager {
    static let shared = HapticHelper()

    class HapticHelper {
        private let lightGenerator = UIImpactFeedbackGenerator(style: .light)

        init() {
            lightGenerator.prepare()
        }

        func lightTap() {
            lightGenerator.impactOccurred()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Typewriter Status Text")
                .font(.headline)
                .foregroundStyle(.white)

            TypewriterStatusText(isActive: true)

            AnimatedStatusPill(
                messages: ["thinking", "analyzing", "strategizing", "✨"],
                isActive: true
            )

            GlowingText(
                text: "Genius Mode Active",
                color: Theme.TaskCardColors.strategy,
                glowRadius: 8
            )
            .font(.title2.bold())

            ShimmerLoadingText(text: "Loading insights...")
                .font(.subheadline)
        }
    }
}
