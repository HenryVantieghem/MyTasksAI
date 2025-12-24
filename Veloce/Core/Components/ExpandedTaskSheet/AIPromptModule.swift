//
//  AIPromptModule.swift
//  Veloce
//
//  AI Prompt Generator for GeniusTaskSheet
//  Generates copyable prompts for ChatGPT/Claude
//

import SwiftUI

// MARK: - Prompt Style

enum AIPromptStyle: String, CaseIterable {
    case detailed = "Detailed"
    case quick = "Quick"
    case creative = "Creative"
    case coach = "Coach"

    var icon: String {
        switch self {
        case .detailed: return "doc.text"
        case .quick: return "bolt"
        case .creative: return "paintbrush"
        case .coach: return "figure.mind.and.body"
        }
    }

    var description: String {
        switch self {
        case .detailed: return "Step-by-step breakdown with time estimates"
        case .quick: return "Concise action items"
        case .creative: return "Novel approaches and ideas"
        case .coach: return "Motivational support"
        }
    }
}

// MARK: - AI Prompt Module

struct AIPromptModule: View {
    let task: TaskItem

    @State private var selectedStyle: AIPromptStyle = .detailed
    @State private var isExpanded: Bool = false
    @State private var showCopiedFeedback: Bool = false

    private var generatedPrompt: String {
        generatePrompt(for: task, style: selectedStyle)
    }

    var body: some View {
        ModuleCard(
            title: "AI PROMPT",
            icon: "sparkles",
            accentColor: Theme.Colors.aiPurple
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Style selector
                styleSelector

                // Prompt preview
                promptPreview

                // Copy button
                copyButton
            }
        }
    }

    // MARK: - Style Selector

    private var styleSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AIPromptStyle.allCases, id: \.self) { style in
                    Button {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedStyle = style
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: style.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(style.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(selectedStyle == style ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            if selectedStyle == style {
                                Capsule()
                                    .fill(Theme.Colors.aiPurple.opacity(0.4))
                            } else {
                                Capsule()
                                    .fill(.white.opacity(0.1))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Prompt Preview

    private var promptPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isExpanded ? generatedPrompt : truncatedPrompt)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(isExpanded ? nil : 4)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)

            if generatedPrompt.count > 150 {
                Button {
                    HapticsService.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.3))
        }
    }

    private var truncatedPrompt: String {
        if generatedPrompt.count > 150 {
            return String(generatedPrompt.prefix(150)) + "..."
        }
        return generatedPrompt
    }

    // MARK: - Copy Button

    private var copyButton: some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))

                Text(showCopiedFeedback ? "Copied!" : "Copy to Clipboard")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        showCopiedFeedback
                        ? Color.green.opacity(0.4)
                        : Theme.Colors.aiPurple.opacity(0.3)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func copyToClipboard() {
        UIPasteboard.general.string = generatedPrompt
        HapticsService.shared.impact()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCopiedFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showCopiedFeedback = false
            }
        }
    }

    // MARK: - Prompt Generation

    private func generatePrompt(for task: TaskItem, style: AIPromptStyle) -> String {
        let taskTitle = task.title
        let priority = task.priority.rawValue
        let taskType = task.taskType.displayName
        let estimatedTime = task.estimatedTimeFormatted ?? "unspecified duration"
        let description = task.aiAdvice ?? task.notes ?? ""

        switch style {
        case .detailed:
            return """
            I need to complete a task: "\(taskTitle)"

            Context:
            - Type: \(taskType) task
            - Priority: \(priority)
            - Estimated time: \(estimatedTime)
            \(description.isEmpty ? "" : "- Additional context: \(description)")

            Please help me by:
            1. Breaking this into smaller, actionable steps (each under 30 minutes)
            2. Providing a time estimate for each step
            3. Suggesting the best order to complete them
            4. Identifying any potential blockers or prerequisites
            5. Recommending the optimal time of day for each step

            Format your response as a numbered checklist I can follow.
            """

        case .quick:
            return """
            Quick task breakdown needed:

            Task: "\(taskTitle)" (\(priority) priority, \(taskType))

            Give me 3-5 concise action items to complete this. Keep each under one sentence. No explanations needed.
            """

        case .creative:
            return """
            I'm working on: "\(taskTitle)"

            This is a \(taskType) task with \(priority) priority.
            \(description.isEmpty ? "" : "Context: \(description)")

            Please suggest:
            1. Three unconventional approaches I might not have considered
            2. Creative ways to make this task more engaging
            3. How I could turn this into a learning opportunity
            4. Any innovative tools or techniques that could help

            Think outside the box!
            """

        case .coach:
            return """
            I need some motivation and guidance for this task:

            "\(taskTitle)"

            Priority: \(priority)
            Type: \(taskType)
            \(description.isEmpty ? "" : "What I know: \(description)")

            Please:
            1. Help me understand why this task matters
            2. Identify what might be holding me back
            3. Suggest a tiny first step I can take right now (under 2 minutes)
            4. Give me an encouraging perspective on completing this
            5. Share a relevant productivity insight or technique

            Be warm and supportive in your response.
            """
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        AIPromptModule(
            task: {
                let task = TaskItem(title: "Write quarterly business report")
                task.starRating = 3
                task.estimatedMinutes = 120
                task.taskTypeRaw = TaskType.create.rawValue
                task.aiAdvice = "Focus on key metrics and actionable insights."
                return task
            }()
        )
        .padding()
    }
}
