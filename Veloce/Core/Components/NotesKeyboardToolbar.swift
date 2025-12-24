//
//  NotesKeyboardToolbar.swift
//  MyTasksAI
//
//  Apple Notes-style keyboard toolbar
//  Checkbox toggle, star priority, and keyboard dismiss
//

import SwiftUI

// MARK: - Notes Keyboard Toolbar

struct NotesKeyboardToolbar: View {
    let hasCheckbox: Bool
    let starRating: Int
    let onCheckboxToggle: () -> Void
    let onStarsToggle: () -> Void
    let onDismiss: () -> Void

    // MARK: Configuration
    private let toolbarHeight: CGFloat = 44
    private let buttonSize: CGFloat = 36
    private let iconSize: CGFloat = 18

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Checkbox button
            toolbarButton(
                icon: hasCheckbox ? "checkmark.circle.fill" : "circle",
                isActive: hasCheckbox,
                accessibilityLabel: hasCheckbox ? "Remove checkbox" : "Add checkbox"
            ) {
                HapticsService.shared.selectionFeedback()
                onCheckboxToggle()
            }

            // Stars button
            starsButton

            Spacer()

            // Done button
            Button {
                HapticsService.shared.lightImpact()
                onDismiss()
            } label: {
                Text("Done")
                    .font(Theme.Typography.bodyBold)
                    .foregroundStyle(Theme.Colors.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss keyboard")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(height: toolbarHeight)
        .background(toolbarBackground)
    }

    // MARK: - Subviews

    private var starsButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            onStarsToggle()
        } label: {
            HStack(spacing: 2) {
                Image(systemName: starRating > 0 ? "star.fill" : "star")
                    .font(.system(size: iconSize))
                    .foregroundStyle(starRating > 0 ? starColor : Theme.Colors.textSecondary)

                if starRating > 0 {
                    Text("\(starRating)")
                        .font(Theme.Typography.caption1Medium)
                        .foregroundStyle(starColor)
                }
            }
            .frame(width: buttonSize + (starRating > 0 ? 12 : 0), height: buttonSize)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(starRating > 0 ? starColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(starAccessibilityLabel)
        .accessibilityHint("Tap to cycle priority")
    }

    private func toolbarButton(
        icon: String,
        isActive: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(isActive ? Theme.Colors.accent : Theme.Colors.textSecondary)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(isActive ? Theme.Colors.accent.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var toolbarBackground: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Colors.divider)
                .frame(height: 0.5)

            Rectangle()
                .fill(Theme.Colors.backgroundSecondary)
        }
    }

    // MARK: - Computed Properties

    private var starColor: Color {
        switch starRating {
        case 1: return Theme.Colors.textTertiary
        case 2: return Theme.Colors.accent
        case 3: return Theme.Colors.warning
        default: return Theme.Colors.textSecondary
        }
    }

    private var starAccessibilityLabel: String {
        switch starRating {
        case 0: return "No priority, tap to add"
        case 1: return "Low priority"
        case 2: return "Medium priority"
        case 3: return "High priority"
        default: return "Priority"
        }
    }
}

// MARK: - Keyboard Toolbar Container

/// Wrapper to position toolbar above keyboard
struct KeyboardToolbarContainer<Content: View>: View {
    @Binding var isKeyboardVisible: Bool
    let hasCheckbox: Bool
    let starRating: Int
    let onCheckboxToggle: () -> Void
    let onStarsToggle: () -> Void
    let onDismiss: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        content
            .safeAreaInset(edge: .bottom) {
                if isKeyboardVisible {
                    NotesKeyboardToolbar(
                        hasCheckbox: hasCheckbox,
                        starRating: starRating,
                        onCheckboxToggle: onCheckboxToggle,
                        onStarsToggle: onStarsToggle,
                        onDismiss: onDismiss
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(Theme.Animation.fast, value: isKeyboardVisible)
    }
}

// MARK: - Keyboard Visibility Observer

/// Observable class to track keyboard visibility
@Observable
final class KeyboardObserver {
    var isVisible: Bool = false
    var keyboardHeight: CGFloat = 0

    init() {
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardFrame.height
            }
            self.isVisible = true
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isVisible = false
            self.keyboardHeight = 0
        }
    }
}

// MARK: - Preview

#Preview("Default") {
    VStack {
        Spacer()
        NotesKeyboardToolbar(
            hasCheckbox: false,
            starRating: 0,
            onCheckboxToggle: { print("Checkbox toggled") },
            onStarsToggle: { print("Stars toggled") },
            onDismiss: { print("Dismissed") }
        )
    }
    .background(Theme.Colors.background)
}

#Preview("With Checkbox") {
    VStack {
        Spacer()
        NotesKeyboardToolbar(
            hasCheckbox: true,
            starRating: 0,
            onCheckboxToggle: { },
            onStarsToggle: { },
            onDismiss: { }
        )
    }
    .background(Theme.Colors.background)
}

#Preview("With Stars") {
    VStack {
        Spacer()
        NotesKeyboardToolbar(
            hasCheckbox: false,
            starRating: 2,
            onCheckboxToggle: { },
            onStarsToggle: { },
            onDismiss: { }
        )
    }
    .background(Theme.Colors.background)
}

#Preview("Full State") {
    VStack {
        Spacer()
        NotesKeyboardToolbar(
            hasCheckbox: true,
            starRating: 3,
            onCheckboxToggle: { },
            onStarsToggle: { },
            onDismiss: { }
        )
    }
    .background(Theme.Colors.background)
}

#Preview("Interactive") {
    struct PreviewWrapper: View {
        @State private var hasCheckbox = false
        @State private var starRating = 0

        var body: some View {
            VStack {
                Text("Checkbox: \(hasCheckbox ? "Yes" : "No")")
                Text("Stars: \(starRating)")

                Spacer()

                NotesKeyboardToolbar(
                    hasCheckbox: hasCheckbox,
                    starRating: starRating,
                    onCheckboxToggle: { hasCheckbox.toggle() },
                    onStarsToggle: { starRating = (starRating + 1) % 4 },
                    onDismiss: { print("Done") }
                )
            }
            .padding()
            .background(Theme.Colors.background)
        }
    }
    return PreviewWrapper()
}
