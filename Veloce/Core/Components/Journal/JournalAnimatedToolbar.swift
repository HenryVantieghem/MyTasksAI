//
//  JournalAnimatedToolbar.swift
//  Veloce
//
//  Animated toolbar that slides up when journal editing begins
//  Features spring animation, word count, mic button, and keyboard dismiss
//

import SwiftUI

/// Animated toolbar that appears when user starts editing the journal
/// Slides up from bottom with spring animation
struct JournalAnimatedToolbar: View {
    let isVisible: Bool
    let wordCount: Int
    let onMicTap: () -> Void
    let onKeyboardDismiss: () -> Void
    var onInsertMarkup: (() -> Void)?

    @Environment(\.responsiveLayout) private var layout

    // Animation configuration
    private let springResponse: Double = 0.4
    private let springDamping: Double = 0.75
    private let slideOffset: CGFloat = 120

    private var toolbarButtonSize: CGFloat {
        layout.deviceType.isTablet ? 48 : 40
    }

    var body: some View {
        HStack(spacing: layout.spacing) {
            // Word count (left side)
            wordCountLabel

            Spacer()

            // Markup insertion button (placeholder for iOS 26+ PaperKit)
            // Currently disabled until PaperKit is available
            // markupInsertButton

            // Voice input button
            micButton

            // Keyboard dismiss button
            keyboardButton
        }
        .padding(.horizontal, layout.screenPadding)
        .padding(.vertical, layout.spacing)
        .padding(.bottom, Theme.Spacing.floatingTabBarClearance)
        .background(toolbarBackground)
        .offset(y: isVisible ? 0 : slideOffset)
        .opacity(isVisible ? 1 : 0)
        .animation(
            .spring(response: springResponse, dampingFraction: springDamping),
            value: isVisible
        )
    }

    // MARK: - Components

    @ViewBuilder
    private var wordCountLabel: some View {
        if wordCount > 0 {
            Text("\(wordCount) words")
                .dynamicTypeFont(base: 12, weight: .regular)
                .foregroundStyle(.white.opacity(0.35))
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
        }
    }

    // Note: Markup insertion button for PaperKit will be added when iOS 26 is available
    // private var markupInsertButton: some View { ... }

    private var micButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onMicTap()
        } label: {
            Image(systemName: "mic.fill")
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(Theme.Colors.aiBlue)
                .frame(width: toolbarButtonSize, height: toolbarButtonSize)
                .background {
                    Circle()
                        .fill(.white.opacity(0.08))
                }
        }
        .buttonStyle(.plain)
        .iPadHoverEffect(.highlight)
    }

    private var keyboardButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onKeyboardDismiss()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: toolbarButtonSize, height: toolbarButtonSize)
                .background {
                    Circle()
                        .fill(.white.opacity(0.08))
                }
        }
        .buttonStyle(.plain)
        .iPadHoverEffect(.highlight)
    }

    private var toolbarBackground: some View {
        LinearGradient(
            colors: [
                Theme.CelestialColors.void.opacity(0.95),
                Theme.CelestialColors.void
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Preview

#Preview("Toolbar - Visible") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
            JournalAnimatedToolbar(
                isVisible: true,
                wordCount: 42,
                onMicTap: {},
                onKeyboardDismiss: {},
                onInsertMarkup: {}
            )
        }
    }
}

#Preview("Toolbar - Hidden") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
            JournalAnimatedToolbar(
                isVisible: false,
                wordCount: 0,
                onMicTap: {},
                onKeyboardDismiss: {},
                onInsertMarkup: {}
            )
        }
    }
}

#Preview("Toolbar - Animation") {
    struct AnimationDemo: View {
        @State private var isVisible = false

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Button("Toggle Toolbar") {
                        isVisible.toggle()
                    }
                    .foregroundStyle(.white)
                    .padding()

                    Spacer()

                    JournalAnimatedToolbar(
                        isVisible: isVisible,
                        wordCount: 156,
                        onMicTap: {},
                        onKeyboardDismiss: {},
                        onInsertMarkup: {}
                    )
                }
            }
        }
    }

    return AnimationDemo()
}
