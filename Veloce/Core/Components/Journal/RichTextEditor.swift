//
//  RichTextEditor.swift
//  Veloce
//
//  Rich Text Editor - Apple Notes style text editing
//  Supports bold, italic, underline, headers, lists, and checklists
//

import SwiftUI
import UIKit

// MARK: - Rich Text Editor

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    @Binding var activeFormats: Set<TextFormattingStyle>

    var placeholder: String = "Start writing..."
    var onTextChange: ((NSAttributedString) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let textView = RichUITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsEditingTextAttributes = true

        // Styling
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.white
        textView.tintColor = UIColor(Theme.Colors.accent)
        textView.keyboardAppearance = .dark

        // Set initial content
        if attributedText.length > 0 {
            textView.attributedText = attributedText
        } else {
            textView.text = ""
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Only update if the text has actually changed to avoid cursor jumping
        if textView.attributedText != attributedText {
            let currentSelection = textView.selectedRange
            textView.attributedText = attributedText
            // Restore selection if valid
            if currentSelection.location <= attributedText.length {
                textView.selectedRange = currentSelection
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText ?? NSAttributedString()
            parent.onTextChange?(parent.attributedText)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange

            // Update active formats based on selection
            updateActiveFormats(textView: textView)
        }

        private func updateActiveFormats(textView: UITextView) {
            guard textView.selectedRange.length > 0 else {
                // For cursor position, check typing attributes
                let typingAttrs = textView.typingAttributes
                parent.activeFormats = getFormats(from: typingAttrs)
                return
            }

            // Get attributes at selection
            let range = textView.selectedRange
            guard range.location < textView.attributedText.length else { return }

            var attrs: [NSAttributedString.Key: Any] = [:]
            textView.attributedText.enumerateAttributes(
                in: range,
                options: []
            ) { attributes, _, _ in
                attrs = attributes
            }

            parent.activeFormats = getFormats(from: attrs)
        }

        private func getFormats(from attrs: [NSAttributedString.Key: Any]) -> Set<TextFormattingStyle> {
            var formats: Set<TextFormattingStyle> = []

            if let font = attrs[.font] as? UIFont {
                if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    formats.insert(.bold)
                }
                if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                    formats.insert(.italic)
                }
            }

            if let underline = attrs[.underlineStyle] as? Int, underline != 0 {
                formats.insert(.underline)
            }

            if let strikethrough = attrs[.strikethroughStyle] as? Int, strikethrough != 0 {
                formats.insert(.strikethrough)
            }

            return formats
        }
    }
}

// MARK: - Custom UITextView

private class RichUITextView: UITextView {
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(toggleBold)),
            UIKeyCommand(input: "i", modifierFlags: .command, action: #selector(toggleItalic)),
            UIKeyCommand(input: "u", modifierFlags: .command, action: #selector(toggleUnderlineStyle))
        ]
    }

    @objc private func toggleBold() {
        toggleTrait(.traitBold)
    }

    @objc private func toggleItalic() {
        toggleTrait(.traitItalic)
    }

    @objc private func toggleUnderlineStyle() {
        if let currentUnderline = typingAttributes[.underlineStyle] as? Int, currentUnderline != 0 {
            typingAttributes[.underlineStyle] = 0
        } else {
            typingAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        if selectedRange.length > 0 {
            let mutableText = NSMutableAttributedString(attributedString: attributedText)
            let currentValue = mutableText.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) as? Int ?? 0
            let newValue = currentValue != 0 ? 0 : NSUnderlineStyle.single.rawValue
            mutableText.addAttribute(.underlineStyle, value: newValue, range: selectedRange)
            attributedText = mutableText
        }
    }

    private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let currentFont = typingAttributes[.font] as? UIFont else { return }

        var newTraits = currentFont.fontDescriptor.symbolicTraits
        if newTraits.contains(trait) {
            newTraits.remove(trait)
        } else {
            newTraits.insert(trait)
        }

        if let newDescriptor = currentFont.fontDescriptor.withSymbolicTraits(newTraits) {
            let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
            typingAttributes[.font] = newFont

            if selectedRange.length > 0 {
                let mutableText = NSMutableAttributedString(attributedString: attributedText)
                mutableText.addAttribute(.font, value: newFont, range: selectedRange)
                attributedText = mutableText
            }
        }
    }
}

// MARK: - Rich Text Editor View Model

@Observable
class RichTextEditorViewModel {
    var attributedText: NSAttributedString = NSAttributedString()
    var selectedRange: NSRange = NSRange(location: 0, length: 0)
    var activeFormats: Set<TextFormattingStyle> = []

    // MARK: Formatting Actions

    func applyFormat(_ format: TextFormattingStyle) {
        HapticsService.shared.selectionFeedback()

        switch format {
        case .bold:
            toggleFontTrait(.traitBold)
        case .italic:
            toggleFontTrait(.traitItalic)
        case .underline:
            toggleAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue)
        case .strikethrough:
            toggleAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue)
        case .header1:
            applyHeader(size: 28, weight: .bold)
        case .header2:
            applyHeader(size: 22, weight: .semibold)
        case .header3:
            applyHeader(size: 18, weight: .medium)
        case .bulletList:
            insertBullet()
        case .numberedList:
            insertNumber()
        case .checklist:
            insertChecklist()
        }
    }

    private func toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard selectedRange.length > 0 else { return }

        let mutableText = NSMutableAttributedString(attributedString: attributedText)

        mutableText.enumerateAttribute(.font, in: selectedRange, options: []) { value, range, _ in
            guard let font = value as? UIFont else { return }

            var newTraits = font.fontDescriptor.symbolicTraits
            if newTraits.contains(trait) {
                newTraits.remove(trait)
            } else {
                newTraits.insert(trait)
            }

            if let newDescriptor = font.fontDescriptor.withSymbolicTraits(newTraits) {
                let newFont = UIFont(descriptor: newDescriptor, size: font.pointSize)
                mutableText.addAttribute(.font, value: newFont, range: range)
            }
        }

        attributedText = mutableText
        updateActiveFormats()
    }

    private func toggleAttribute(_ key: NSAttributedString.Key, value: Int) {
        guard selectedRange.length > 0 else { return }

        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let currentValue = mutableText.attribute(key, at: selectedRange.location, effectiveRange: nil) as? Int ?? 0
        let newValue = currentValue != 0 ? 0 : value
        mutableText.addAttribute(key, value: newValue, range: selectedRange)
        attributedText = mutableText
        updateActiveFormats()
    }

    private func applyHeader(size: CGFloat, weight: UIFont.Weight) {
        guard selectedRange.length > 0 else { return }

        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let headerFont = UIFont.systemFont(ofSize: size, weight: weight)
        mutableText.addAttribute(.font, value: headerFont, range: selectedRange)
        attributedText = mutableText
    }

    private func insertBullet() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let bullet = NSAttributedString(string: "\n\u{2022} ", attributes: defaultAttributes())
        mutableText.insert(bullet, at: selectedRange.location)
        attributedText = mutableText
    }

    private func insertNumber() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let number = NSAttributedString(string: "\n1. ", attributes: defaultAttributes())
        mutableText.insert(number, at: selectedRange.location)
        attributedText = mutableText
    }

    private func insertChecklist() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let checkbox = NSAttributedString(string: "\n\u{2610} ", attributes: defaultAttributes())
        mutableText.insert(checkbox, at: selectedRange.location)
        attributedText = mutableText
    }

    private func defaultAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.white
        ]
    }

    private func updateActiveFormats() {
        guard selectedRange.location < attributedText.length else {
            activeFormats = []
            return
        }

        var formats: Set<TextFormattingStyle> = []
        let effectiveRange = NSRange(location: selectedRange.location, length: min(1, attributedText.length - selectedRange.location))

        attributedText.enumerateAttributes(in: effectiveRange, options: []) { attrs, _, _ in
            if let font = attrs[.font] as? UIFont {
                if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    formats.insert(.bold)
                }
                if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                    formats.insert(.italic)
                }
            }
            if let underline = attrs[.underlineStyle] as? Int, underline != 0 {
                formats.insert(.underline)
            }
            if let strikethrough = attrs[.strikethroughStyle] as? Int, strikethrough != 0 {
                formats.insert(.strikethrough)
            }
        }

        activeFormats = formats
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var viewModel = RichTextEditorViewModel()

        var body: some View {
            VStack {
                RichTextEditor(
                    attributedText: .init(
                        get: { viewModel.attributedText },
                        set: { viewModel.attributedText = $0 }
                    ),
                    selectedRange: .init(
                        get: { viewModel.selectedRange },
                        set: { viewModel.selectedRange = $0 }
                    ),
                    activeFormats: .init(
                        get: { viewModel.activeFormats },
                        set: { viewModel.activeFormats = $0 }
                    )
                )
                .frame(height: 300)
            }
            .background { VoidBackground.journal }
        }
    }
    return PreviewWrapper()
}
