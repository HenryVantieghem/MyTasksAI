//
//  JournalCanvasView.swift
//  Veloce
//
//  Version-adaptive journal canvas
//  Currently uses TextEditor, prepared for PaperKit integration (iOS 26+)
//

import SwiftUI

/// Adaptive journal canvas
/// Uses TextEditor for text input with clean cosmic void aesthetic
/// PaperKit support will be added when the API becomes available
struct JournalCanvasView: View {
    @Binding var currentText: String
    @Binding var isEditing: Bool
    var journalEntry: JournalEntry?
    var onFocusChange: ((Bool) -> Void)?
    var onContentChange: (() -> Void)?

    @Environment(\.responsiveLayout) private var layout

    var body: some View {
        LegacyJournalEditor(
            text: $currentText,
            isEditing: $isEditing,
            placeholder: "What's on your mind?"
        )
        .onChange(of: currentText) { _, _ in
            onContentChange?()
        }
        .onChange(of: isEditing) { _, focused in
            onFocusChange?(focused)
        }
    }
}

// MARK: - Tap-to-Focus Wrapper

/// Wrapper that adds tap gesture to focus the journal canvas
struct TapToFocusJournalCanvas: View {
    @Binding var currentText: String
    @Binding var isEditing: Bool
    var journalEntry: JournalEntry?
    var onFocusChange: ((Bool) -> Void)?
    var onContentChange: (() -> Void)?

    @Environment(\.responsiveLayout) private var layout

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tap target area for when not editing
            if !isEditing {
                tapPrompt
                    .onTapGesture {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(Theme.Animation.spring) {
                            isEditing = true
                        }
                        onFocusChange?(true)
                    }
            }

            // Actual canvas
            JournalCanvasView(
                currentText: $currentText,
                isEditing: $isEditing,
                journalEntry: journalEntry,
                onFocusChange: onFocusChange,
                onContentChange: onContentChange
            )
        }
    }

    private var tapPrompt: some View {
        Group {
            if currentText.isEmpty {
                HStack {
                    Text("Tap to start writing...")
                        .dynamicTypeFont(base: 16, weight: .regular)
                        .foregroundStyle(.white.opacity(0.35))
                        .italic()
                    Spacer()
                }
                .padding(.vertical, layout.spacing)
            }
        }
    }
}

// MARK: - Preview

#Preview("Journal Canvas - Empty") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            JournalCanvasView(
                currentText: .constant(""),
                isEditing: .constant(false)
            )
            .padding()
        }
    }
}

#Preview("Journal Canvas - With Content") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            JournalCanvasView(
                currentText: .constant("Today was a productive day. I managed to complete all my tasks and even had time to work on some personal projects.\n\nThe weather was beautiful, which always helps with motivation."),
                isEditing: .constant(true)
            )
            .padding()
        }
    }
}

#Preview("Tap to Focus Canvas") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            TapToFocusJournalCanvas(
                currentText: .constant(""),
                isEditing: .constant(false)
            )
            .padding()
        }
    }
}
