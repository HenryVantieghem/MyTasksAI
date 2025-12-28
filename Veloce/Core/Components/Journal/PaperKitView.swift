//
//  PaperKitView.swift
//  Veloce
//
//  UIViewControllerRepresentable wrapper for Apple's PaperKit framework (iOS 26+)
//  Provides Notes-like drawing, shapes, and markup capabilities for journal entries
//

import SwiftUI

#if canImport(PaperKit)
import PaperKit

/// SwiftUI wrapper for PaperMarkupViewController (iOS 26+)
/// Provides full markup experience with drawing, shapes, text boxes, and more
@available(iOS 26.0, *)
struct PaperKitView: UIViewControllerRepresentable {
    @Binding var paperMarkup: PaperMarkup
    @Binding var isEditing: Bool
    var backgroundColor: UIColor = .clear
    var onFocusChange: ((Bool) -> Void)?
    var onContentChange: ((PaperMarkup) -> Void)?

    func makeUIViewController(context: Context) -> PaperMarkupViewController {
        let controller = PaperMarkupViewController()
        controller.delegate = context.coordinator
        controller.paperMarkup = paperMarkup
        controller.view.backgroundColor = backgroundColor

        // Configure for journal aesthetics - dark mode cosmic theme
        controller.overrideUserInterfaceStyle = .dark

        return controller
    }

    func updateUIViewController(_ controller: PaperMarkupViewController, context: Context) {
        // Sync markup data if externally changed
        if controller.paperMarkup != paperMarkup {
            controller.paperMarkup = paperMarkup
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PaperMarkupViewControllerDelegate {
        var parent: PaperKitView

        init(_ parent: PaperKitView) {
            self.parent = parent
        }

        func paperMarkupViewControllerDidChange(_ controller: PaperMarkupViewController) {
            parent.paperMarkup = controller.paperMarkup
            parent.onContentChange?(controller.paperMarkup)
        }

        func paperMarkupViewControllerDidBeginEditing(_ controller: PaperMarkupViewController) {
            parent.isEditing = true
            parent.onFocusChange?(true)
        }

        func paperMarkupViewControllerDidEndEditing(_ controller: PaperMarkupViewController) {
            parent.isEditing = false
            parent.onFocusChange?(false)
        }
    }
}

// MARK: - PaperKit View Modifier

@available(iOS 26.0, *)
extension View {
    /// Apply PaperKit styling to views
    func paperKitStyle() -> some View {
        self
            .preferredColorScheme(.dark)
    }
}

#endif

// MARK: - Fallback for Pre-iOS 26

/// Fallback editor for iOS versions before 26
/// Uses existing TextEditor + PencilKit combination
struct LegacyJournalEditor: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    @FocusState private var isFocused: Bool
    var placeholder: String = "What's on your mind?"

    @Environment(\.responsiveLayout) private var layout

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .dynamicTypeFont(base: 18, weight: .regular, design: .serif)
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }

            // Text editor
            TextEditor(text: $text)
                .font(.system(size: layout.deviceType.isTablet ? 20 : 18, weight: .regular, design: .serif))
                .foregroundStyle(.white.opacity(0.9))
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .frame(minHeight: layout.deviceType.isTablet ? 500 : 400)
                .lineSpacing(layout.deviceType.isTablet ? 10 : 8)
        }
        .onChange(of: isFocused) { _, focused in
            withAnimation(Theme.Animation.spring) {
                isEditing = focused
            }
        }
        .onTapGesture {
            isFocused = true
        }
    }
}

// MARK: - Preview

#Preview("Legacy Editor") {
    ZStack {
        Color.black.ignoresSafeArea()

        LegacyJournalEditor(
            text: .constant(""),
            isEditing: .constant(false)
        )
        .padding()
    }
}
