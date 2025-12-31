//
//  EditableTaskTitle.swift
//  MyTasksAI
//
//  Inline editable task title component
//  Tap to edit, return to save
//

import SwiftUI

// MARK: - Editable Task Title
struct EditableTaskTitle: View {
    @Binding var title: String
    let onCommit: (String) -> Void
    let isCompleted: Bool

    @FocusState private var isFocused: Bool
    @State private var editingTitle: String = ""
    @State private var isEditing: Bool = false

    init(
        title: Binding<String>,
        onCommit: @escaping (String) -> Void,
        isCompleted: Bool = false
    ) {
        self._title = title
        self.onCommit = onCommit
        self.isCompleted = isCompleted
    }

    var body: some View {
        Group {
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
    }

    // MARK: - Display View
    private var displayView: some View {
        HStack(spacing: 8) {
            Text(title)
                .dynamicTypeFont(base: 18, weight: .semibold)
                .foregroundStyle(.white)
                .strikethrough(isCompleted)
                .opacity(isCompleted ? 0.6 : 1)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // Edit hint icon
            Image(systemName: "pencil")
                .dynamicTypeFont(base: 12)
                .foregroundStyle(.white.opacity(0.3))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            startEditing()
        }
    }

    // MARK: - Editing View
    private var editingView: some View {
        HStack(spacing: 8) {
            TextField("Task title", text: $editingTitle, axis: .vertical)
                .dynamicTypeFont(base: 18, weight: .semibold)
                .foregroundStyle(.white)
                .focused($isFocused)
                .onSubmit {
                    commitEdit()
                }
                .submitLabel(.done)
                .lineLimit(1...3)

            // Save button
            Button {
                commitEdit()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .dynamicTypeFont(base: 24)
                    .foregroundStyle(Theme.Colors.success)
            }

            // Cancel button
            Button {
                cancelEdit()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .dynamicTypeFont(base: 24)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions
    private func startEditing() {
        guard !isCompleted else { return }
        editingTitle = title
        isEditing = true
        isFocused = true
        HapticsService.shared.selectionFeedback()
    }

    private func commitEdit() {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            cancelEdit()
            return
        }

        if trimmed != title {
            title = trimmed
            onCommit(trimmed)
            HapticsService.shared.softImpact()
        }

        isEditing = false
        isFocused = false
    }

    private func cancelEdit() {
        editingTitle = title
        isEditing = false
        isFocused = false
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        VStack(spacing: 32) {
            EditableTaskTitle(
                title: .constant("Complete the quarterly report"),
                onCommit: { print("Saved: \($0)") },
                isCompleted: false
            )

            EditableTaskTitle(
                title: .constant("Finished task"),
                onCommit: { print("Saved: \($0)") },
                isCompleted: true
            )
        }
        .padding()
    }
}
