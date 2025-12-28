//
//  JournalCanvasView.swift
//  Veloce
//
//  Version-adaptive journal canvas that uses PaperKit on iOS 26+
//  and falls back to TextEditor + PencilKit on earlier versions
//

import SwiftUI
#if canImport(PaperKit)
import PaperKit
#endif

/// Adaptive journal canvas that automatically uses the best available framework
/// - iOS 26+: Full PaperKit with drawing, shapes, markup
/// - Pre-iOS 26: TextEditor with optional PencilKit drawing overlay
struct JournalCanvasView: View {
    @Binding var currentText: String
    @Binding var isEditing: Bool
    var journalEntry: JournalEntry?
    var onFocusChange: ((Bool) -> Void)?
    var onContentChange: (() -> Void)?

    @Environment(\.responsiveLayout) private var layout

    // PaperKit state (iOS 26+ only)
    #if canImport(PaperKit)
    @State private var paperMarkup = PaperMarkup()
    #endif

    var body: some View {
        Group {
            #if canImport(PaperKit)
            if #available(iOS 26.0, *) {
                paperKitCanvas
            } else {
                legacyCanvas
            }
            #else
            legacyCanvas
            #endif
        }
    }

    // MARK: - PaperKit Canvas (iOS 26+)

    #if canImport(PaperKit)
    @available(iOS 26.0, *)
    private var paperKitCanvas: some View {
        PaperKitView(
            paperMarkup: $paperMarkup,
            isEditing: $isEditing,
            backgroundColor: .clear,
            onFocusChange: { focused in
                withAnimation(Theme.Animation.spring) {
                    isEditing = focused
                }
                onFocusChange?(focused)
            },
            onContentChange: { markup in
                // Update the journal entry with PaperKit data
                // This triggers auto-save via onChange in parent
                onContentChange?()
            }
        )
        .frame(minHeight: layout.deviceType.isTablet ? 500 : 400)
        .onAppear {
            loadPaperKitContent()
        }
    }

    @available(iOS 26.0, *)
    private func loadPaperKitContent() {
        if let entry = journalEntry, entry.usesPaperKit {
            paperMarkup = entry.getPaperMarkup()
        } else if let entry = journalEntry {
            // Migrate legacy content to PaperKit
            // For now, just start fresh with PaperKit
            paperMarkup = PaperMarkup()
            // TODO: Add text content from legacy entry
        }
    }
    #endif

    // MARK: - Legacy Canvas (Pre-iOS 26)

    private var legacyCanvas: some View {
        LegacyJournalEditor(
            text: $currentText,
            isEditing: $isEditing,
            placeholder: "What's on your mind?"
        )
        .onChange(of: currentText) { _, _ in
            onContentChange?()
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
