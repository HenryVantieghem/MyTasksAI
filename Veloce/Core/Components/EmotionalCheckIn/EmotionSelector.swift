//
//  EmotionSelector.swift
//  MyTasksAI
//
//  Emotional Intelligence - Emotion Check-In
//  Soft, breathing emotion buttons with AI-powered responses
//

import SwiftUI

// MARK: - Emotion Type

enum EmotionType: String, CaseIterable {
    case energized = "Energized"
    case focused = "Focused"
    case calm = "Calm"
    case anxious = "Anxious"
    case tired = "Tired"
    case overwhelmed = "Overwhelmed"

    var icon: String {
        switch self {
        case .energized: return "bolt.fill"
        case .focused: return "scope"
        case .calm: return "leaf.fill"
        case .anxious: return "waveform.path"
        case .tired: return "moon.fill"
        case .overwhelmed: return "cloud.rain.fill"
        }
    }

    var color: Color {
        switch self {
        case .energized: return Color(hex: "FFD700")
        case .focused: return Color(hex: "8B5CF6")
        case .calm: return Color(hex: "10B981")
        case .anxious: return Color(hex: "F59E0B")
        case .tired: return Color(hex: "6366F1")
        case .overwhelmed: return Color(hex: "EF4444")
        }
    }

    var aiResponse: String {
        switch self {
        case .energized:
            return "Great energy! Let's channel that into your most important task. What's the one thing that would make today a win?"
        case .focused:
            return "You're in the zone. This is the perfect time to tackle deep work. I'll keep distractions to a minimum."
        case .calm:
            return "A peaceful mindset is perfect for thoughtful work. Consider tackling tasks that need careful attention."
        case .anxious:
            return "It's okay to feel this way. Let's break things into smaller steps. What's the tiniest next action you could take?"
        case .tired:
            return "Your energy matters. Consider focusing on lighter tasks or taking a proper break. Rest is productive too."
        case .overwhelmed:
            return "Let's take a breath together. We can reschedule some tasks. What absolutely must happen today?"
        }
    }
}

// MARK: - Emotion Selector

struct EmotionSelector: View {
    @Binding var selectedEmotion: EmotionType?
    let onSelect: (EmotionType) -> Void

    @State private var breathPhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            Text("How are you feeling?")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(EmotionType.allCases, id: \.self) { emotion in
                    EmotionButton(
                        emotion: emotion,
                        isSelected: selectedEmotion == emotion,
                        breathPhase: breathPhase
                    ) {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedEmotion = emotion
                        }
                        onSelect(emotion)
                    }
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathPhase = 1
            }
        }
    }
}

// MARK: - Emotion Button

struct EmotionButton: View {
    let emotion: EmotionType
    let isSelected: Bool
    let breathPhase: Double
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Glow when selected
                    if isSelected {
                        SwiftUI.Circle()
                            .fill(emotion.color.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .blur(radius: 12)
                            .scaleEffect(1 + breathPhase * 0.1)
                    }

                    // Main circle
                    SwiftUI.Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(colors: [emotion.color, emotion.color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            SwiftUI.Circle()
                                .stroke(
                                    isSelected ? emotion.color.opacity(0.5) : .white.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                        .scaleEffect(isSelected ? 1 + breathPhase * 0.05 : 1)

                    // Icon
                    Image(systemName: emotion.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                }

                Text(emotion.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Emotion Response Card

struct EmotionResponseCard: View {
    let emotion: EmotionType
    @State private var showResponse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                // AI indicator
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "06B6D4")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }

                Text("MyTasksAI")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            if showResponse {
                Text(emotion.aiResponse)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [emotion.color.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.3)) {
                showResponse = true
            }
        }
    }
}

// MARK: - Blocker Identifier

struct BlockerIdentifier: View {
    @Binding var selectedBlocker: TaskBlocker?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's making this hard?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                ForEach(TaskBlocker.allCases, id: \.self) { blocker in
                    BlockerOption(
                        blocker: blocker,
                        isSelected: selectedBlocker == blocker
                    ) {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(.spring(response: 0.3)) {
                            selectedBlocker = blocker
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Task Blocker

enum TaskBlocker: String, CaseIterable {
    case tooLarge = "It feels too big"
    case unclear = "I'm not sure where to start"
    case perfectionism = "I want it to be perfect"
    case energy = "I don't have the energy"
    case distracted = "I keep getting distracted"
    case other = "Something else"

    var icon: String {
        switch self {
        case .tooLarge: return "mountain.2"
        case .unclear: return "questionmark.circle"
        case .perfectionism: return "star.circle"
        case .energy: return "battery.25"
        case .distracted: return "bell.badge"
        case .other: return "ellipsis.circle"
        }
    }

    var suggestion: String {
        switch self {
        case .tooLarge:
            return "Let's break this into 5-minute pieces. What's the smallest first step?"
        case .unclear:
            return "That's okay! Sometimes we need to think before we act. What information do you need?"
        case .perfectionism:
            return "Done is better than perfect. What would 'good enough' look like?"
        case .energy:
            return "Your wellbeing matters. Consider a break or switching to a lighter task."
        case .distracted:
            return "Let's remove distractions. Try a 10-minute focused burst with your phone away."
        case .other:
            return "Whatever it is, it's valid. Would you like to reschedule this task?"
        }
    }
}

struct BlockerOption: View {
    let blocker: TaskBlocker
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: blocker.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                    .frame(width: 24)

                Text(blocker.rawValue)
                    .font(.system(size: 15))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.8))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "8B5CF6"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "8B5CF6").opacity(0.2) : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: "8B5CF6").opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 24) {
            EmotionSelector(selectedEmotion: .constant(.focused)) { _ in }

            EmotionResponseCard(emotion: .focused)
        }
        .padding()
    }
}
