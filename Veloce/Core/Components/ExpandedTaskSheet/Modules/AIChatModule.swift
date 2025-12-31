//
//  AIChatModule.swift
//  MyTasksAI
//
//  "Ask AI anything" chat module
//  Contextual chat about the specific task
//  Quick suggestion chips
//

import SwiftUI

// MARK: - AI Chat Module

struct AIChatModule: View {
    let task: TaskItem
    @Bindable var viewModel: GeniusSheetViewModel

    @FocusState private var isInputFocused: Bool

    private let accentColor = Theme.TaskCardColors.strategy

    private let quickSuggestions = [
        "How do I start?",
        "Break it down",
        "Why important?"
    ]

    var body: some View {
        ModuleCard(
            title: "ASK AI",
            icon: "bubble.left.and.bubble.right.fill",
            accentColor: accentColor
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Chat messages (if any)
                if !viewModel.chatMessages.isEmpty {
                    chatMessagesView
                }

                // AI thinking indicator
                if viewModel.isAIThinking {
                    aiThinkingView
                }

                // Input field
                chatInputField

                // Quick suggestions
                quickSuggestionsView
            }
        }
    }

    // MARK: - Chat Messages

    private var chatMessagesView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(viewModel.chatMessages) { message in
                chatBubble(message)
            }
        }
    }

    private func chatBubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == .user

        return HStack {
            if isUser { Spacer(minLength: 40) }

            Text(message.content)
                .dynamicTypeFont(base: 13, weight: .regular)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isUser
                                ? accentColor.opacity(0.25)
                                : Color.white.opacity(0.08)
                        )
                )

            if !isUser { Spacer(minLength: 40) }
        }
    }

    // MARK: - AI Thinking View

    private var aiThinkingView: some View {
        HStack(spacing: 8) {
            MiniThinkingOrb(isActive: true, size: 16)

            Text("AI is thinking...")
                .dynamicTypeFont(base: 12, weight: .medium)
                .foregroundStyle(.white.opacity(0.6))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Chat Input Field

    private var chatInputField: some View {
        HStack(spacing: 10) {
            TextField("Ask anything about this task...", text: $viewModel.chatInput)
                .dynamicTypeFont(base: 14)
                .foregroundStyle(.white)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .dynamicTypeFont(base: 26)
                    .foregroundStyle(
                        viewModel.chatInput.isEmpty
                            ? Color.white.opacity(0.3)
                            : accentColor
                    )
            }
            .disabled(viewModel.chatInput.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            isInputFocused
                                ? accentColor.opacity(0.4)
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Quick Suggestions

    private var quickSuggestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickSuggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.chatInput = suggestion
                        sendMessage()
                    } label: {
                        Text(suggestion)
                            .dynamicTypeFont(base: 12, weight: .medium)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Send Message

    private func sendMessage() {
        guard !viewModel.chatInput.isEmpty else { return }

        Task {
            await viewModel.sendChatMessage(viewModel.chatInput)
        }

        isInputFocused = false

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        AIChatModule(
            task: TaskItem(title: "Write quarterly report"),
            viewModel: {
                let vm = GeniusSheetViewModel()
                vm.chatMessages = [
                    ChatMessage(role: .user, content: "How do I start?"),
                    ChatMessage(role: .assistant, content: "Start by opening a blank document and writing just the title. That's your first 30-second action.")
                ]
                return vm
            }()
        )
        .padding()
    }
}
