//
//  PaperKitView.swift
//  Veloce
//
//  UIViewControllerRepresentable wrapper for Apple's PaperKit framework (iOS 26+)
//  Provides Notes-like drawing, shapes, and markup capabilities for journal entries
//
//  Note: PaperKit integration is prepared for iOS 26+ when the full API is available.
//  Until then, the legacy TextEditor fallback is used.
//

import SwiftUI
import PencilKit

// MARK: - PaperKit Available Check

/// Check if PaperKit is available (iOS 26+)
/// This is a placeholder until PaperKit becomes available
var isPaperKitAvailable: Bool {
    if #available(iOS 26.0, *) {
        // PaperKit will be available in iOS 26
        // For now, return false until we can test with actual SDK
        return false
    }
    return false
}

// MARK: - Legacy Journal Editor (Pre-iOS 26 and Fallback)

/// Fallback editor using TextEditor
/// Used for iOS versions before 26 or when PaperKit is unavailable
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

// MARK: - Drawing Canvas (PencilKit)

/// PencilKit-based drawing canvas for journal entries
/// This provides drawing capabilities until PaperKit is available
struct JournalDrawingOverlay: View {
    @Binding var drawing: PKDrawing
    @Binding var isDrawingMode: Bool
    @Environment(\.responsiveLayout) private var layout

    var body: some View {
        if isDrawingMode {
            DrawingCanvasRepresentable(drawing: $drawing)
                .frame(minHeight: layout.deviceType.isTablet ? 500 : 400)
                .transition(.opacity)
        }
    }
}

/// UIViewRepresentable for PKCanvasView
struct DrawingCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.overrideUserInterfaceStyle = .dark

        // Configure tool picker
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvasRepresentable

        init(_ parent: DrawingCanvasRepresentable) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
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

#Preview("Legacy Editor - With Text") {
    ZStack {
        Color.black.ignoresSafeArea()

        LegacyJournalEditor(
            text: .constant("Today was a great day for journaling. I've been thinking about..."),
            isEditing: .constant(true)
        )
        .padding()
    }
}
