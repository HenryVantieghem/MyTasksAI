//
//  AIPromptCard.swift
//  Veloce
//
//  Ready-to-use AI prompt generator card
//  Users can copy this prompt to any AI assistant (ChatGPT, Claude, etc.)
//

import SwiftUI

struct AIPromptCard: View {
    let taskTitle: String
    let contextNotes: String?
    let estimatedMinutes: Int?
    let priority: TaskPriority
    let previousLearnings: [String]?

    @State private var generatedPrompt: String = ""
    @State private var isLoading: Bool = false
    @State private var showCopiedFeedback: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            headerView

            // Prompt content
            promptContentView

            // Action buttons
            actionButtonsView
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.aiPurple.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.aiPurple.opacity(0.2))
                }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            generatePrompt()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: contextNotes) { _, _ in
            generatePrompt()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.Colors.aiPurple)
                .dynamicTypeFont(base: 18)

            Text("AI Prompt")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.primaryText)

            Spacer()

            // Refresh button
            Button {
                generatePrompt()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.5 : 1)
        }
    }

    // MARK: - Prompt Content

    private var promptContentView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Description
            Text("Copy this prompt to any AI assistant:")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)

            // Prompt text
            if isLoading {
                loadingView
            } else {
                promptTextView
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Generating prompt...")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
        }
    }

    private var promptTextView: some View {
        ScrollView {
            Text(generatedPrompt)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.Colors.primaryText)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 200)
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .strokeBorder(Theme.Colors.glassBorder.opacity(0.2))
                }
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Copy button (prominent)
            Button {
                copyToClipboard()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                    Text(showCopiedFeedback ? "Copied!" : "Copy Prompt")
                }
                .font(Theme.Typography.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(generatedPrompt.isEmpty)

            // Share button
            ShareLink(item: generatedPrompt) {
                Image(systemName: "square.and.arrow.up")
                    .font(Theme.Typography.headline)
            }
            .buttonStyle(.glass)
            .disabled(generatedPrompt.isEmpty)
        }
    }

    // MARK: - Actions

    private func generatePrompt() {
        isLoading = true

        // Generate the prompt using the template
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            generatedPrompt = AIPromptTemplate.generate(
                taskTitle: taskTitle,
                contextNotes: contextNotes,
                estimatedMinutes: estimatedMinutes,
                priority: priority,
                previousLearnings: previousLearnings
            )
            isLoading = false
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = generatedPrompt

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Show feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCopiedFeedback = true
        }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

// MARK: - Compact Version for Quick Access

struct AIPromptQuickButton: View {
    let taskTitle: String
    let contextNotes: String?
    let estimatedMinutes: Int?
    let priority: TaskPriority

    @State private var showingFullPrompt: Bool = false

    var body: some View {
        Button {
            showingFullPrompt = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.Colors.aiPurple)
                Text("Get AI Prompt")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Theme.Colors.aiPurple.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .strokeBorder(Theme.Colors.aiPurple.opacity(0.15))
                    }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingFullPrompt) {
            AIPromptSheet(
                taskTitle: taskTitle,
                contextNotes: contextNotes,
                estimatedMinutes: estimatedMinutes,
                priority: priority
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Full Prompt Sheet

struct AIPromptSheet: View {
    @Environment(\.dismiss) private var dismiss

    let taskTitle: String
    let contextNotes: String?
    let estimatedMinutes: Int?
    let priority: TaskPriority

    var body: some View {
        NavigationStack {
            ScrollView {
                AIPromptCard(
                    taskTitle: taskTitle,
                    contextNotes: contextNotes,
                    estimatedMinutes: estimatedMinutes,
                    priority: priority,
                    previousLearnings: nil
                )
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("AI Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AIPromptCard(
                taskTitle: "Finish quarterly report",
                contextNotes: "This is for the board meeting on Friday",
                estimatedMinutes: 45,
                priority: .high,
                previousLearnings: ["Start with data first", "Use bullet points for clarity"]
            )

            AIPromptQuickButton(
                taskTitle: "Review pull request",
                contextNotes: nil,
                estimatedMinutes: 20,
                priority: .medium
            )
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
