//
//  AIThinkingIndicator.swift
//  MyTasksAI
//
//  Claude Code-inspired AI Thinking Indicator
//  Beautiful animated gradient orb with status text
//

import SwiftUI
import Combine

// MARK: - AI Thinking Indicator
struct AIThinkingIndicator: View {
    var size: CGFloat = 24
    var showText: Bool = true
    var style: AIIndicatorStyle = .thinking

    @State private var rotation: Double = 0
    @State private var colorPhase: CGFloat = 0
    @State private var pulse: CGFloat = 1

    // AI gradient colors (Claude Code inspired: orange → purple → blue)
    private let gradientColors: [Color] = [
        Theme.Colors.aiOrange,
        Theme.Colors.aiPurple,
        Theme.Colors.aiBlue,
        Theme.Colors.aiCyan
    ]

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Animated orb
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                currentColor.opacity(0.4),
                                currentColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.2,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)
                    .scaleEffect(pulse)

                // Main rotating gradient orb
                Circle()
                    .fill(
                        AngularGradient(
                            colors: gradientColors + [gradientColors[0]],
                            center: .center,
                            startAngle: .degrees(rotation),
                            endAngle: .degrees(rotation + 360)
                        )
                    )
                    .frame(width: size, height: size)

                // Inner highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: size * 0.25
                        )
                    )
                    .frame(width: size, height: size)
            }

            // Status text
            if showText {
                Text(style.text)
                    .font(Theme.Typography.caption1Medium)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [currentColor, nextColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private var currentColor: Color {
        let index = Int(colorPhase * CGFloat(gradientColors.count)) % gradientColors.count
        return gradientColors[index]
    }

    private var nextColor: Color {
        let index = (Int(colorPhase * CGFloat(gradientColors.count)) + 1) % gradientColors.count
        return gradientColors[index]
    }

    private func startAnimations() {
        // Rotation animation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        // Color phase animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            colorPhase = 1
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulse = 1.15
        }
    }
}

// MARK: - AI Indicator Style
enum AIIndicatorStyle {
    case thinking
    case manifesting
    case processing
    case analyzing
    case generating

    var text: String {
        switch self {
        case .thinking: return "AI thinking..."
        case .manifesting: return "AI manifesting..."
        case .processing: return "Processing..."
        case .analyzing: return "Analyzing..."
        case .generating: return "Generating..."
        }
    }

    var icon: String {
        switch self {
        case .thinking: return "brain.head.profile"
        case .manifesting: return "sparkles"
        case .processing: return "gearshape.2"
        case .analyzing: return "magnifyingglass"
        case .generating: return "wand.and.stars"
        }
    }

    // Claude Code-like rotating messages
    static var rotatingMessages: [String] {
        [
            "AI thinking...",
            "AI manifesting...",
            "Processing insights...",
            "Analyzing task...",
            "Generating advice...",
            "Crafting suggestions...",
            "Computing estimates...",
            "Considering context..."
        ]
    }
}

// MARK: - Animated AI Status (Claude Code Style)
/// Displays rotating status messages with gradient animation
struct AnimatedAIStatus: View {
    @State private var currentMessageIndex = 0
    @State private var opacity: Double = 1
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    private let messages = AIIndicatorStyle.rotatingMessages

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Animated orb
            ClaudeCodeOrb(size: 20)

            // Rotating text
            Text(messages[currentMessageIndex])
                .font(Theme.Typography.caption1Medium)
                .foregroundStyle(
                    LinearGradient(
                        colors: Theme.Colors.aiGradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(opacity)
                .animation(.easeInOut(duration: 0.3), value: opacity)
        }
        .onReceive(timer) { _ in
            withAnimation {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
                withAnimation {
                    opacity = 1
                }
            }
        }
    }
}

// MARK: - Claude Code Orb
/// The iconic Claude Code animated gradient orb
struct ClaudeCodeOrb: View {
    var size: CGFloat = 24
    var glowIntensity: CGFloat = 1.0

    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1
    @State private var innerRotation: Double = 0

    var body: some View {
        ZStack {
            // Outer glow (pulsing)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.5 * glowIntensity),
                            Theme.Colors.aiBlue.opacity(0.2 * glowIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size
                    )
                )
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(pulse)

            // Main gradient ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: Theme.Colors.aiGradient + [Theme.Colors.aiGradient.first!],
                        center: .center
                    ),
                    lineWidth: size * 0.12
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))

            // Inner fill with counter-rotation
            Circle()
                .fill(
                    AngularGradient(
                        colors: Theme.Colors.aiGradient.reversed() + [Theme.Colors.aiGradient.last!],
                        center: .center
                    )
                )
                .frame(width: size * 0.6, height: size * 0.6)
                .rotationEffect(.degrees(innerRotation))

            // Center highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.2
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)
        }
        .onAppear {
            // Clockwise rotation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            // Counter-clockwise inner rotation
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = 1.2
            }
        }
    }
}

// MARK: - Inline AI Typing Indicator
/// Shows when AI is generating inline content (like Claude Code)
struct InlineAITypingIndicator: View {
    @State private var dotScale: [CGFloat] = [1, 1, 1]
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    @State private var currentDot = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiOrange, Theme.Colors.aiPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 6, height: 6)
                    .scaleEffect(dotScale[index])
            }
        }
        .onReceive(timer) { _ in
            let nextDot = (currentDot + 1) % 3
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                dotScale[currentDot] = 1
                dotScale[nextDot] = 1.5
            }
            currentDot = nextDot
        }
    }
}

// MARK: - Compact AI Indicator
/// Smaller inline indicator for task rows
struct CompactAIIndicator: View {
    var isProcessing: Bool = true
    var size: CGFloat = 16

    @State private var rotation: Double = 0

    var body: some View {
        if isProcessing {
            Circle()
                .fill(
                    AngularGradient(
                        colors: Theme.Colors.aiGradient + [Theme.Colors.aiGradient[0]],
                        center: .center
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.8))
                .foregroundStyle(Theme.Colors.aiPurple)
        }
    }
}

// MARK: - AI Processing Badge
/// Badge to show AI status on task cards
struct AIProcessingBadge: View {
    let state: AIProcessingState
    var compact: Bool = true

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Group {
                switch state {
                case .idle:
                    EmptyView()

                case .queued:
                    Image(systemName: "hourglass")
                        .foregroundStyle(Theme.Colors.textTertiary)

                case .processing:
                    CompactAIIndicator(isProcessing: true, size: 14)

                case .completed:
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.Colors.aiPurple)

                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.Colors.warning)
                }
            }
            .font(.system(size: compact ? 12 : 14))

            if !compact && !state.statusText.isEmpty {
                Text(state.statusText)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(
            Capsule()
                .fill(Theme.Colors.cardBackgroundSecondary)
        )
        .opacity(state == .idle ? 0 : 1)
    }
}

// MARK: - AI Shimmer Text
/// Text with animated shimmer effect
struct AIShimmerText: View {
    let text: String
    var font: Font = Theme.Typography.caption1

    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiOrange,
                        Theme.Colors.aiPurple,
                        Theme.Colors.aiBlue,
                        Theme.Colors.aiPurple,
                        Theme.Colors.aiOrange
                    ],
                    startPoint: UnitPoint(x: shimmerPhase - 1, y: 0),
                    endPoint: UnitPoint(x: shimmerPhase, y: 0)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerPhase = 2
                }
            }
    }
}

// MARK: - Processing Queue Indicator
/// Shows number of items in AI processing queue
struct ProcessingQueueIndicator: View {
    let count: Int
    var showWifi: Bool = true

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if showWifi {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }

            AIShimmerText(
                text: "Processing \(count) queued item\(count == 1 ? "" : "s")...",
                font: Theme.Typography.footnote
            )

            CompactAIIndicator(isProcessing: true, size: 14)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .liquidGlass(cornerRadius: Theme.Radius.pill)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        IridescentBackground()

        VStack(spacing: 30) {
            Text("AI Indicators")
                .font(Theme.Typography.title2)

            AIThinkingIndicator(size: 32, style: .thinking)

            AIThinkingIndicator(size: 24, style: .manifesting)

            Divider()

            HStack(spacing: 20) {
                AIProcessingBadge(state: .processing)
                AIProcessingBadge(state: .completed(AIAdvice(taskId: UUID(), advice: "Test", priority: "medium", estimatedMinutes: 30)))
                AIProcessingBadge(state: .queued)
            }

            Divider()

            ProcessingQueueIndicator(count: 3)

            Divider()

            AIShimmerText(text: "AI is thinking...", font: Theme.Typography.headline)
        }
        .padding()
    }
}
