//
//  UnifiedAIHubView.swift
//  Veloce
//
//  Unified AI Hub - 4 Modes in One Tab
//  Combines Journal, Brain Dump (Process), Chat, and Feed
//

import SwiftUI
import SwiftData

// MARK: - AI Hub Mode

enum AIHubMode: String, CaseIterable {
    case journal = "Journal"
    case process = "Process"
    case chat = "Chat"
    case feed = "Feed"

    var icon: String {
        switch self {
        case .journal: return "book"
        case .process: return "brain"
        case .chat: return "bubble.left.and.bubble.right"
        case .feed: return "newspaper"
        }
    }

    var description: String {
        switch self {
        case .journal: return "Daily thoughts & reflections"
        case .process: return "Brain dump → Tasks"
        case .chat: return "AI conversation"
        case .feed: return "Insights & recommendations"
        }
    }
}

// MARK: - Unified AI Hub View

struct UnifiedAIHubView: View {
    var tasksViewModel: TasksViewModel
    @State private var selectedMode: AIHubMode = .journal
    @State private var journalViewModel = JournalViewModel()
    @State private var brainDumpViewModel = BrainDumpViewModel()

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Background
            VoidBackground.ai

            VStack(spacing: 0) {
                // Mode Toggle
                modeToggle
                    .padding(.top, Theme.Spacing.universalHeaderHeight)
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                    .padding(.bottom, Theme.Spacing.md)

                // Content based on selected mode
                TabView(selection: $selectedMode) {
                    JournalModeView(viewModel: journalViewModel, tasksViewModel: tasksViewModel)
                        .tag(AIHubMode.journal)

                    ProcessModeView(viewModel: brainDumpViewModel)
                        .tag(AIHubMode.process)

                    ChatModeView()
                        .tag(AIHubMode.chat)

                    FeedModeView()
                        .tag(AIHubMode.feed)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .preferredColorScheme(.dark)
        .task {
            journalViewModel.setup(context: modelContext)
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 4) {
            ForEach(AIHubMode.allCases, id: \.self) { mode in
                Button {
                    HapticsService.shared.selectionFeedback()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12, weight: selectedMode == mode ? .semibold : .regular))
                        if selectedMode == mode {
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundStyle(selectedMode == mode ? .white : .white.opacity(0.5))
                    .padding(.horizontal, selectedMode == mode ? 14 : 10)
                    .padding(.vertical, 8)
                    .background {
                        if selectedMode == mode {
                            Capsule()
                                .fill(Theme.Colors.aiPurple.opacity(0.4))
                        } else {
                            Capsule()
                                .fill(.white.opacity(0.05))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Journal Mode View

struct JournalModeView: View {
    @Bindable var viewModel: JournalViewModel
    @Bindable var tasksViewModel: TasksViewModel
    @State private var selectedDate: Date = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Date navigation
                TodayPillView(selectedDate: $selectedDate)
                    .padding(.horizontal, Theme.Spacing.screenPadding)

                // Journal entry area
                JournalEntryCard(viewModel: viewModel, date: selectedDate)
                    .padding(.horizontal, Theme.Spacing.screenPadding)

                // AI Reflection (if available)
                if let reflection = viewModel.currentReflection {
                    AIReflectionCard(reflection: reflection)
                        .padding(.horizontal, Theme.Spacing.screenPadding)
                }
            }
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Journal Entry Card

struct JournalEntryCard: View {
    @Bindable var viewModel: JournalViewModel
    let date: Date
    @State private var entryText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What's on your mind?")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            TextEditor(text: $entryText)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .frame(minHeight: 200)

            // Action buttons
            HStack(spacing: 12) {
                ActionPill(icon: "photo", label: "Photo")
                ActionPill(icon: "pencil.tip", label: "Draw")
                ActionPill(icon: "mic.fill", label: "Voice")
                Spacer()
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - AI Reflection Card

struct AIReflectionCard: View {
    let reflection: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.aiPurple)

            VStack(alignment: .leading, spacing: 8) {
                Text(reflection)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))

                Button {
                    // Action
                } label: {
                    Text("Create Focus Block")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.aiPurple.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Action Pill

struct ActionPill: View {
    let icon: String
    let label: String

    var body: some View {
        Button {
            HapticsService.shared.lightImpact()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(.white.opacity(0.1))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Process Mode View (Brain Dump)

struct ProcessModeView: View {
    var viewModel: BrainDumpViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Input area
            VStack(spacing: Theme.Spacing.md) {
                Text("Let it all out...")
                    .font(.system(size: 24, weight: .thin))
                    .foregroundStyle(.white.opacity(0.6))

                TextEditor(text: Binding(
                    get: { viewModel.inputText },
                    set: { viewModel.inputText = $0 }
                ))
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(height: 200)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, Theme.Spacing.screenPadding)
            }

            // Process button
            Button {
                HapticsService.shared.impact()
                Task {
                    await viewModel.processBrainDump()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(viewModel.isProcessing ? "Processing..." : "Process Thoughts")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
            .opacity(viewModel.inputText.isEmpty ? 0.5 : 1)
            .padding(.horizontal, Theme.Spacing.screenPadding)

            Spacer()
        }
        .padding(.bottom, 100)
    }
}

// MARK: - Chat Mode View

struct ChatModeView: View {
    @State private var messages: [AIHubChatMessage] = []
    @State private var inputText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
                .padding(.bottom, 100)
            }

            // Input bar
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $inputText)
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
                .disabled(inputText.isEmpty)
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.vertical, Theme.Spacing.md)
            .background(.ultraThinMaterial)
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let userMessage = AIHubChatMessage(role: .user, content: inputText)
        messages.append(userMessage)
        inputText = ""

        // Simulate AI response
        Task {
            try? await Task.sleep(for: .seconds(1))
            let aiMessage = AIHubChatMessage(
                role: .assistant,
                content: "I understand you're asking about that. Let me help you break this down into actionable steps..."
            )
            await MainActor.run {
                messages.append(aiMessage)
            }
        }
    }
}

// MARK: - Chat Message

struct AIHubChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String

    enum ChatRole {
        case user
        case assistant
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: AIHubChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            Text(message.content)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            message.role == .user
                            ? Theme.Colors.aiPurple.opacity(0.3)
                            : .white.opacity(0.1)
                        )
                }

            if message.role == .assistant { Spacer() }
        }
    }
}

// MARK: - Feed Mode View

struct FeedModeView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                // Sample content cards
                ContentCard(
                    icon: "play.rectangle.fill",
                    title: "Deep Work Strategies",
                    subtitle: "Based on your journal entries",
                    duration: "12 min",
                    type: .video
                )

                ContentCard(
                    icon: "doc.text",
                    title: "Time Blocking Techniques",
                    subtitle: "Recommended for you",
                    duration: "5 min read",
                    type: .article
                )

                ContentCard(
                    icon: "lightbulb.fill",
                    title: "Your Productivity Insight",
                    subtitle: "You're 23% more productive on Tuesdays",
                    duration: nil,
                    type: .insight
                )
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Content Card

struct ContentCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let duration: String?
    let type: ContentType

    enum ContentType {
        case video, article, insight
    }

    var accentColor: Color {
        switch type {
        case .video: return .red
        case .article: return Theme.Colors.aiBlue
        case .insight: return Theme.Colors.aiGold
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.15))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            if let duration = duration {
                Text(duration)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    UnifiedAIHubView(tasksViewModel: TasksViewModel())
        .modelContainer(for: [TaskItem.self, NotesLine.self], inMemory: true)
}
