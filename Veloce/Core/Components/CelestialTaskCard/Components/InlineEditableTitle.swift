//
//  InlineEditableTitle.swift
//  Veloce
//
//  Tap-to-edit title component with auto-save
//

import SwiftUI

// MARK: - Inline Editable Title

struct InlineEditableTitle: View {
    @Binding var title: String
    let taskTypeColor: Color
    let onSave: (String) -> Void

    @State private var isEditing = false
    @State private var editedText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditing {
                TextField("Task title", text: $editedText)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.CelestialColors.starWhite)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        saveAndDismiss()
                    }
                    .onAppear {
                        isFocused = true
                    }

                // Save/Cancel buttons
                HStack(spacing: 12) {
                    Button(action: cancelEdit) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.CelestialColors.starDim)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: saveAndDismiss) {
                        Text("Save")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(taskTypeColor)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
                .padding(.top, 4)
            } else {
                Button(action: startEditing) {
                    HStack {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.CelestialColors.starWhite)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.CelestialColors.starGhost)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func startEditing() {
        editedText = title
        isEditing = true
        HapticsService.shared.selectionFeedback()
    }

    private func saveAndDismiss() {
        guard !editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cancelEdit()
            return
        }

        title = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(title)
        isEditing = false
        isFocused = false
        HapticsService.shared.impact(.light)
    }

    private func cancelEdit() {
        editedText = title
        isEditing = false
        isFocused = false
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack {
            InlineEditableTitle(
                title: .constant("Sample Task Title"),
                taskTypeColor: Theme.TaskCardColors.create,
                onSave: { newTitle in
                    print("Saved: \(newTitle)")
                }
            )
            .padding()
        }
    }
}
