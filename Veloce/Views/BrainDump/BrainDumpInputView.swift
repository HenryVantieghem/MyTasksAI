//
//  BrainDumpInputView.swift
//  Veloce
//
//  AI Assistant - Chat, Feed, and Brain Dump Modes
//  Premium conversational AI with content recommendations
//

import SwiftUI

// MARK: - AI Assistant Mode

enum AIAssistantMode: String, CaseIterable {
    case chat = "Chat"
    case feed = "Feed"
    case brainDump = "Brain Dump"

    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right"
        case .feed: return "square.stack"
        case .brainDump: return "brain.head.profile"
        }
    }
}

// MARK: - Brain Dump Input View (AI Assistant)

struct BrainDumpInputView: View {
    @Bindable var viewModel: BrainDumpViewModel

    @State private var selectedDate: Date = Date()
    @State private var selectedMode: AIAssistantMode = .brainDump
    @State private var chatInput: String = ""
    @FocusState private var isFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VoidBackground.brainDump

            VStack(spacing: 0) {
                // Date pill
                TodayPillView(selectedDate: $selectedDate)
                    .padding(.top, Theme.Spacing.universalHeaderHeight + 16)

                // Mode toggle
                modeToggle
                    .padding(.top, 16)

                // Content based on mode
                Group {
                    switch selectedMode {
                    case .chat:
                        chatModeView
                    case .feed:
                        feedModeView
                    case .brainDump:
                        brainDumpModeView
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedMode)
            }
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 4) {
            ForEach(AIAssistantMode.allCases, id: \.self) { mode in
                Button {
                    HapticsService.shared.selectionFeedback()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12, weight: .semibold))

                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(selectedMode == mode ? .primary : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        if selectedMode == mode {
                            Capsule()
                                .fill(Color(hex: "8B5CF6").opacity(0.2))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 20)
    }

    // MARK: - Chat Mode

    private var chatModeView: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Welcome message
                        AIChatBubble(
                            message: "Hi! I'm your AI productivity assistant. Ask me anything about your tasks, goals, or schedule.",
                            isAI: true
                        )
                        .id("welcome")

                        // Sample suggestions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Try asking:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)

                            ForEach([
                                "What should I focus on today?",
                                "Help me prioritize my tasks",
                                "Show my productivity patterns"
                            ], id: \.self) { suggestion in
                                SuggestionChip(text: suggestion) {
                                    chatInput = suggestion
                                    sendMessage()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }

            Spacer()

            // Chat input
            chatInputBar
        }
    }

    private var chatInputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask anything...", text: $chatInput)
                .font(.system(size: 16))
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                ZStack {
                    if chatInput.isEmpty {
                        SwiftUI.Circle()
                            .fill(Color.secondary.opacity(0.3))
                    } else {
                        SwiftUI.Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6"), Color(hex: "3B82F6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
            }
            .disabled(chatInput.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 20)
        .padding(.bottom, Theme.Spacing.floatingTabBarClearance)
    }

    private func sendMessage() {
        guard !chatInput.isEmpty else { return }
        HapticsService.shared.impact()
        // Process chat message
        chatInput = ""
    }

    // MARK: - Feed Mode

    private var feedModeView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                // AI-generated content recommendations
                ContentFeedCard(
                    type: .video,
                    title: "How to Focus Better",
                    description: "Based on your productivity patterns",
                    source: "YouTube",
                    duration: "12 min"
                )

                ContentFeedCard(
                    type: .article,
                    title: "The Science of Deep Work",
                    description: "Matches your focus goals",
                    source: "Medium",
                    duration: "5 min read"
                )

                ContentFeedCard(
                    type: .insight,
                    title: "Pattern Detected",
                    description: "You complete 40% more tasks when starting before 9am",
                    source: "AI Analysis",
                    actionLabel: "Set Morning Routine"
                )

                ContentFeedCard(
                    type: .video,
                    title: "Time Blocking Mastery",
                    description: "Recommended for your schedule",
                    source: "YouTube",
                    duration: "8 min"
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .padding(.bottom, Theme.Spacing.floatingTabBarClearance)
        }
    }

    // MARK: - Brain Dump Mode

    private var brainDumpModeView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                // Input area
                ZStack(alignment: .topLeading) {
                    if viewModel.inputText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's on your mind?")
                                .font(.system(size: 24, weight: .thin))
                                .italic()
                                .foregroundStyle(.secondary.opacity(0.6))

                            Text("Just let it all out...")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }

                    TextEditor(text: $viewModel.inputText)
                        .focused($isFocused)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.primary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 100, maxHeight: geometry.size.height * 0.5)
                        .padding(.horizontal, 20)
                }
                .padding(.horizontal, 4)

                Spacer()

                // Hint
                if !viewModel.inputText.isEmpty {
                    Text("AI will organize your thoughts into actionable tasks")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }

                // Process button
                if !viewModel.inputText.isEmpty {
                    processButton
                        .transition(.scale.combined(with: .opacity))
                        .padding(.top, 16)
                }

                Spacer()
                    .frame(height: Theme.Spacing.floatingTabBarClearance)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }

    private var processButton: some View {
        Button {
            HapticsService.shared.aiProcessingStart()
            Task { await viewModel.processBrainDump() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))

                Text("Process Thoughts")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background {
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "3B82F6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .blur(radius: 20)
                        .opacity(0.5)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "3B82F6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Chat Bubble

struct AIChatBubble: View {
    let message: String
    let isAI: Bool

    var body: some View {
        HStack {
            if !isAI { Spacer() }

            HStack(alignment: .top, spacing: 12) {
                if isAI {
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
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isAI ? Color(hex: "8B5CF6").opacity(0.1) : Color.white.opacity(0.1))
                    }
            }

            if isAI { Spacer() }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "8B5CF6"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(Color(hex: "8B5CF6").opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 1)
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Content Feed Card

struct ContentFeedCard: View {
    enum ContentType {
        case video, article, insight

        var icon: String {
            switch self {
            case .video: return "play.rectangle.fill"
            case .article: return "doc.text.fill"
            case .insight: return "lightbulb.fill"
            }
        }

        var color: Color {
            switch self {
            case .video: return Color(hex: "EF4444")
            case .article: return Color(hex: "3B82F6")
            case .insight: return Color(hex: "F59E0B")
            }
        }
    }

    let type: ContentType
    let title: String
    let description: String
    let source: String
    var duration: String? = nil
    var actionLabel: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(type.color)

                Text(source)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.color)

                Spacer()

                if let duration = duration {
                    Text(duration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            Text(description)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let actionLabel = actionLabel {
                Button { } label: {
                    Text(actionLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(type.color)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    BrainDumpInputView(viewModel: BrainDumpViewModel())
        .preferredColorScheme(.dark)
}
