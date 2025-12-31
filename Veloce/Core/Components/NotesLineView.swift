//
//  NotesLineView.swift
//  MyTasksAI
//
//  Apple Notes-style line component
//  Editable text line with optional checkbox and priority stars
//

import SwiftUI

// MARK: - Notes Line View

struct NotesLineView: View {
    @Bindable var line: NotesLine
    let onTap: () -> Void
    let onTextChange: (String) -> Void
    let onCheckToggle: () -> Void
    @Binding var isFocused: Bool

    @State private var isTyping: Bool = false
    @State private var typingDebouncer: Timer?
    @FocusState private var textFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Configuration
    private let minHeight: CGFloat = 44
    private let horizontalPadding: CGFloat = 20

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox (if enabled)
            if line.hasCheckbox {
                AppleNotesCheckbox(isChecked: line.isChecked) {
                    onCheckToggle()
                }
            }

            // Stars indicator (if any)
            if line.starRating > 0 {
                starsIndicator
            }

            // Text content
            TextField("", text: Binding(
                get: { line.text },
                set: { newValue in
                    line.updateText(newValue)
                    onTextChange(newValue)
                    triggerTypingIndicator()
                }
            ), axis: .vertical)
            .font(Theme.Typography.body)
            .foregroundStyle(line.isChecked ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
            .strikethrough(line.isChecked, color: Theme.Colors.textTertiary)
            .focused($textFieldFocused)
            .submitLabel(.return)
            .lineLimit(1...10)
            .onChange(of: textFieldFocused) { _, newValue in
                isFocused = newValue
            }
            .onChange(of: isFocused) { _, newValue in
                textFieldFocused = newValue
            }

            Spacer(minLength: 0)

            // AI thinking indicator
            NotesLineAIIndicator(isTyping: isTyping, duration: 2.0)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: minHeight)
        .contentShape(Rectangle())
        .background(lineBackground)
        .onTapGesture {
            if line.hasContent && !isFocused {
                onTap()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(line.hasContent ? "Double tap to view details" : "")
        .accessibilityAddTraits(line.hasContent ? .isButton : [])
    }

    // MARK: - Subviews

    private var starsIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<line.starRating, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .dynamicTypeFont(base: 10)
                    .foregroundStyle(starColor)
            }
        }
    }

    private var lineBackground: some View {
        VStack(spacing: 0) {
            Spacer()
            Rectangle()
                .fill(Theme.Colors.divider.opacity(0.2))
                .frame(height: 0.5)
        }
    }

    // MARK: - Computed Properties

    private var starColor: Color {
        switch line.starRating {
        case 1: return Theme.Colors.textTertiary.opacity(0.7)
        case 2: return Theme.Colors.accent.opacity(0.8)
        case 3: return Theme.Colors.warning
        default: return Theme.Colors.textTertiary
        }
    }

    private var accessibilityLabel: String {
        var parts: [String] = []

        if line.hasCheckbox {
            parts.append(line.isChecked ? "Completed" : "Not completed")
        }

        if line.starRating > 0 {
            let priorityText = ["Low", "Medium", "High"][min(line.starRating - 1, 2)]
            parts.append("\(priorityText) priority")
        }

        if line.hasContent {
            parts.append(line.text)
        } else {
            parts.append("Empty line")
        }

        return parts.joined(separator: ", ")
    }

    // MARK: - Methods

    private func triggerTypingIndicator() {
        // Cancel previous debouncer
        typingDebouncer?.invalidate()

        // Show typing indicator
        isTyping = true

        // Hide after brief pause in typing
        typingDebouncer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            isTyping = false
        }
    }
}

// MARK: - Empty Line View (for new line creation)

struct EmptyNotesLineView: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    let onSubmit: () -> Void

    @FocusState private var textFieldFocused: Bool
    private let minHeight: CGFloat = 44
    private let horizontalPadding: CGFloat = 20

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .focused($textFieldFocused)
                .submitLabel(.return)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSubmit()
                    }
                }
                .lineLimit(1...3)
                .onChange(of: textFieldFocused) { _, newValue in
                    isFocused = newValue
                }
                .onChange(of: isFocused) { _, newValue in
                    textFieldFocused = newValue
                }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: minHeight)
        .background(
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Theme.Colors.divider.opacity(0.2))
                    .frame(height: 0.5)
            }
        )
    }
}

// MARK: - Preview

#Preview("With Checkbox") {
    struct PreviewWrapper: View {
        @State private var line = NotesLine(
            text: "Buy groceries",
            hasCheckbox: true,
            isChecked: false
        )
        @State private var isFocused = false

        var body: some View {
            NotesLineView(
                line: line,
                onTap: { print("Tapped") },
                onTextChange: { _ in },
                onCheckToggle: { line.toggleChecked() },
                isFocused: $isFocused
            )
            .background(Theme.Colors.background)
        }
    }
    return PreviewWrapper()
}

#Preview("With Stars") {
    struct PreviewWrapper: View {
        @State private var line = NotesLine(
            text: "Important meeting",
            hasCheckbox: false,
            starRating: 3
        )
        @State private var isFocused = false

        var body: some View {
            NotesLineView(
                line: line,
                onTap: { print("Tapped") },
                onTextChange: { _ in },
                onCheckToggle: { },
                isFocused: $isFocused
            )
            .background(Theme.Colors.background)
        }
    }
    return PreviewWrapper()
}

#Preview("Completed") {
    struct PreviewWrapper: View {
        @State private var line = NotesLine(
            text: "Review documents",
            hasCheckbox: true,
            isChecked: true
        )
        @State private var isFocused = false

        var body: some View {
            NotesLineView(
                line: line,
                onTap: { print("Tapped") },
                onTextChange: { _ in },
                onCheckToggle: { },
                isFocused: $isFocused
            )
            .background(Theme.Colors.background)
        }
    }
    return PreviewWrapper()
}

#Preview("Multiple Lines") {
    struct PreviewWrapper: View {
        @State private var lines = [
            NotesLine(text: "Buy groceries", hasCheckbox: true, starRating: 0),
            NotesLine(text: "Call mom", hasCheckbox: true, starRating: 2),
            NotesLine(text: "Finish project", hasCheckbox: true, starRating: 3),
            NotesLine(text: "Done task", hasCheckbox: true, isChecked: true)
        ]
        @State private var focusedId: UUID?

        var body: some View {
            VStack(spacing: 0) {
                ForEach(lines) { line in
                    NotesLineView(
                        line: line,
                        onTap: { print("Tapped: \(line.text)") },
                        onTextChange: { _ in },
                        onCheckToggle: { line.toggleChecked() },
                        isFocused: Binding(
                            get: { focusedId == line.id },
                            set: { if $0 { focusedId = line.id } }
                        )
                    )
                }
            }
            .background(Theme.Colors.background)
        }
    }
    return PreviewWrapper()
}
