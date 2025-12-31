//
//  ContextInputModule.swift
//  Veloce
//
//  Rich context input for AI enhancement
//  Helps users provide better context for smarter AI recommendations
//

import SwiftUI

struct ContextInputModule: View {
    @Binding var contextNotes: String
    @State private var isExpanded: Bool = false
    @State private var suggestedQuestions: [String] = []
    @State private var selectedTags: Set<ContextTag> = []
    @State private var isLoadingSuggestions: Bool = false

    let taskTitle: String
    let onContextUpdated: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            headerView

            if isExpanded {
                // Quick context tags
                quickTagsSection
                    .transition(.move(edge: .top).combined(with: .opacity))

                // Text input area
                textInputSection
                    .transition(.move(edge: .top).combined(with: .opacity))

                // AI suggested questions
                if !suggestedQuestions.isEmpty {
                    suggestionsSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.glassBorder.opacity(0.2))
                }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .onAppear {
            if !contextNotes.isEmpty {
                isExpanded = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
                if isExpanded && suggestedQuestions.isEmpty {
                    loadSuggestions()
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(Theme.Colors.accent)
                    .dynamicTypeFont(base: 16)

                Text("Add Context")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)

                Spacer()

                if !contextNotes.isEmpty {
                    Text("Has context")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.success)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(Theme.Colors.success.opacity(0.15))
                        }
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Tags

    private var quickTagsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Quick tags:")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)

            FlowLayout(spacing: Theme.Spacing.xs) {
                ForEach(ContextTag.allCases) { tag in
                    contextTagButton(tag)
                }
            }
        }
    }

    private func contextTagButton(_ tag: ContextTag) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedTags.contains(tag) {
                    selectedTags.remove(tag)
                    removeTagFromContext(tag)
                } else {
                    selectedTags.insert(tag)
                    addTagToContext(tag)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedTags.contains(tag) ? "checkmark" : "plus")
                    .dynamicTypeFont(base: 10, weight: .semibold)
                Text(tag.label)
                    .font(Theme.Typography.caption)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(selectedTags.contains(tag)
                          ? Theme.Colors.accent.opacity(0.2)
                          : Theme.Colors.glassBackground.opacity(0.5))
            }
            .overlay {
                Capsule()
                    .strokeBorder(selectedTags.contains(tag)
                                  ? Theme.Colors.accent.opacity(0.5)
                                  : Theme.Colors.glassBorder.opacity(0.3))
            }
        }
        .foregroundStyle(selectedTags.contains(tag)
                         ? Theme.Colors.accent
                         : Theme.Colors.secondaryText)
        .buttonStyle(.plain)
    }

    // MARK: - Text Input

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack(alignment: .topLeading) {
                if contextNotes.isEmpty {
                    Text("Add details to help AI understand your task better...")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.tertiaryText.opacity(0.5))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $contextNotes)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 150)
                    .onChange(of: contextNotes) { _, newValue in
                        onContextUpdated(newValue)
                    }
            }
            .padding(Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Theme.Colors.glassBackground.opacity(0.3))
            }

            // Character count
            HStack {
                Spacer()
                Text("\(contextNotes.count) characters")
                    .dynamicTypeFont(base: 10)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
        }
    }

    // MARK: - AI Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .font(.caption)
                Text("AI suggests asking:")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)

                if isLoadingSuggestions {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(suggestedQuestions, id: \.self) { question in
                    suggestionRow(question)
                }
            }
        }
    }

    private func suggestionRow(_ question: String) -> some View {
        Button {
            appendQuestionToContext(question)
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.aiPurple.opacity(0.7))

                Text(question)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.accent)
            }
            .padding(.vertical, Theme.Spacing.xs)
            .padding(.horizontal, Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Theme.Colors.aiPurple.opacity(0.05))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadSuggestions() {
        isLoadingSuggestions = true

        // Generate context-aware questions based on task title
        // In production, this would call PerplexityService
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            suggestedQuestions = generateLocalSuggestions()
            isLoadingSuggestions = false
        }
    }

    private func generateLocalSuggestions() -> [String] {
        // Smart local suggestions based on task keywords
        let lowercased = taskTitle.lowercased()

        var suggestions: [String] = []

        if lowercased.contains("meeting") || lowercased.contains("call") {
            suggestions.append("Who is the meeting with?")
            suggestions.append("What's the main agenda or goal?")
        } else if lowercased.contains("report") || lowercased.contains("document") {
            suggestions.append("Who is the audience for this?")
            suggestions.append("What's the deadline?")
        } else if lowercased.contains("email") || lowercased.contains("message") {
            suggestions.append("Who is this for?")
            suggestions.append("What's the key message?")
        } else if lowercased.contains("project") || lowercased.contains("task") {
            suggestions.append("What's the expected outcome?")
            suggestions.append("Are there any dependencies?")
        } else {
            suggestions.append("What's the goal of this task?")
            suggestions.append("Who is this for?")
            suggestions.append("What resources do you need?")
        }

        return suggestions
    }

    private func addTagToContext(_ tag: ContextTag) {
        let prefix = "\n[\(tag.label)]: "
        if !contextNotes.contains(prefix) {
            contextNotes += prefix
        }
        onContextUpdated(contextNotes)
    }

    private func removeTagFromContext(_ tag: ContextTag) {
        let prefix = "\n[\(tag.label)]: "
        contextNotes = contextNotes.replacingOccurrences(of: prefix, with: "")
        onContextUpdated(contextNotes)
    }

    private func appendQuestionToContext(_ question: String) {
        if !contextNotes.isEmpty && !contextNotes.hasSuffix("\n") {
            contextNotes += "\n"
        }
        contextNotes += "Q: \(question)\nA: "
        onContextUpdated(contextNotes)

        // Remove used suggestion
        withAnimation {
            suggestedQuestions.removeAll { $0 == question }
        }
    }
}

// MARK: - Context Tags

enum ContextTag: String, CaseIterable, Identifiable {
    case deadline = "deadline"
    case forWhom = "for_whom"
    case goal = "goal"
    case resources = "resources"
    case blockers = "blockers"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .deadline: return "Deadline"
        case .forWhom: return "For whom"
        case .goal: return "Goal"
        case .resources: return "Resources"
        case .blockers: return "Blockers"
        }
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ContextInputModule(
            contextNotes: .constant(""),
            taskTitle: "Finish quarterly report",
            onContextUpdated: { _ in }
        )
        .padding()
    }
    .background(Theme.Colors.background)
}
