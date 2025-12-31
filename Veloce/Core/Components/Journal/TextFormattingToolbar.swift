//
//  TextFormattingToolbar.swift
//  Veloce
//
//  Text Formatting Toolbar - Apple Notes style formatting controls
//  Displays above keyboard for quick access to text styling
//

import SwiftUI

// MARK: - Text Formatting Toolbar

struct TextFormattingToolbar: View {
    @Binding var activeFormats: Set<TextFormattingStyle>
    let onFormatTap: (TextFormattingStyle) -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            // Formatting buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    // Text style group
                    formatGroup([.bold, .italic, .underline, .strikethrough])

                    Divider()
                        .frame(height: 24)
                        .opacity(0.3)

                    // Header group
                    formatGroup([.header1, .header2, .header3])

                    Divider()
                        .frame(height: 24)
                        .opacity(0.3)

                    // List group
                    formatGroup([.bulletList, .numberedList, .checklist])
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

            Spacer()

            // Dismiss button
            Button {
                HapticsService.shared.lightImpact()
                onDismiss()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .dynamicTypeFont(base: 18, weight: .medium)
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel("Dismiss keyboard")
        }
        .frame(height: 50)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.Colors.textTertiary.opacity(0.2))
                        .frame(height: 0.5)
                }
        }
    }

    // MARK: - Format Group

    @ViewBuilder
    private func formatGroup(_ formats: [TextFormattingStyle]) -> some View {
        ForEach(formats, id: \.self) { format in
            FormatButton(
                format: format,
                isActive: activeFormats.contains(format),
                action: { onFormatTap(format) }
            )
        }
    }
}

// MARK: - Format Button

struct FormatButton: View {
    let format: TextFormattingStyle
    let isActive: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: format.icon)
                .font(.system(size: 16, weight: isActive ? .bold : .regular))
                .foregroundStyle(isActive ? Theme.Colors.accent : Theme.Colors.textSecondary)
                .frame(width: 36, height: 36)
                .background {
                    if isActive {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.Colors.accent.opacity(0.15))
                    }
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(format.accessibilityLabel)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Accessibility

extension TextFormattingStyle {
    var accessibilityLabel: String {
        switch self {
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .strikethrough: return "Strikethrough"
        case .header1: return "Heading 1"
        case .header2: return "Heading 2"
        case .header3: return "Heading 3"
        case .bulletList: return "Bullet list"
        case .numberedList: return "Numbered list"
        case .checklist: return "Checklist"
        }
    }
}

// MARK: - Compact Formatting Toolbar

/// Compact version for inline use
struct CompactFormattingToolbar: View {
    @Binding var activeFormats: Set<TextFormattingStyle>
    let onFormatTap: (TextFormattingStyle) -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach([TextFormattingStyle.bold, .italic, .underline], id: \.self) { format in
                FormatButton(
                    format: format,
                    isActive: activeFormats.contains(format),
                    action: { onFormatTap(format) }
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Preview

#Preview("Formatting Toolbar") {
    struct PreviewWrapper: View {
        @State private var activeFormats: Set<TextFormattingStyle> = [.bold]

        var body: some View {
            VStack {
                Spacer()

                TextFormattingToolbar(
                    activeFormats: $activeFormats,
                    onFormatTap: { format in
                        if activeFormats.contains(format) {
                            activeFormats.remove(format)
                        } else {
                            activeFormats.insert(format)
                        }
                    },
                    onDismiss: {}
                )
            }
            .background { VoidBackground.standard }
        }
    }
    return PreviewWrapper()
}

#Preview("Compact Toolbar") {
    struct PreviewWrapper: View {
        @State private var activeFormats: Set<TextFormattingStyle> = []

        var body: some View {
            CompactFormattingToolbar(
                activeFormats: $activeFormats,
                onFormatTap: { format in
                    if activeFormats.contains(format) {
                        activeFormats.remove(format)
                    } else {
                        activeFormats.insert(format)
                    }
                }
            )
            .padding()
            .background { VoidBackground.standard }
        }
    }
    return PreviewWrapper()
}
