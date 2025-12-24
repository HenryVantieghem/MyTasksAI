//
//  GlassTextField.swift
//  Veloce
//
//  Glass Morphic Text Field
//  Enhanced input with focus glow and validation states
//

import SwiftUI

// MARK: - Glass TextField

struct GlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    var validation: ValidationState = .idle
    @Binding var showSecureText: Bool

    @FocusState private var isFocused: Bool
    @State private var glowOpacity: Double = 0

    init(
        text: Binding<String>,
        placeholder: String,
        icon: String,
        isSecure: Bool = false,
        validation: ValidationState = .idle,
        showSecureText: Binding<Bool> = .constant(false)
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
        self.validation = validation
        self._showSecureText = showSecureText
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            // Text field
            Group {
                if isSecure && !showSecureText {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Colors.textPrimary)
            .focused($isFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            // Trailing content
            trailingContent
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md + 4)
        .background(glassBackground)
        .overlay(borderOverlay)
        .overlay(glowOverlay)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .onChange(of: isFocused) { _, focused in
            withAnimation(Theme.Animation.fast) {
                glowOpacity = focused ? 0.5 : 0
            }
        }
    }

    // MARK: - Icon Color

    private var iconColor: Color {
        switch validation {
        case .valid:
            return Theme.Colors.success
        case .invalid:
            return Theme.Colors.error
        default:
            return isFocused ? Theme.Colors.accent : Theme.Colors.textSecondary
        }
    }

    // MARK: - Trailing Content

    @ViewBuilder
    private var trailingContent: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Validation indicator
            if case .valid = validation {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.success)
                    .transition(.scale.combined(with: .opacity))
            } else if case .invalid = validation {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.error)
                    .transition(.scale.combined(with: .opacity))
            }

            // Show/hide password button
            if isSecure {
                Button {
                    showSecureText.toggle()
                    HapticsService.shared.selectionFeedback()
                } label: {
                    Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(Theme.Animation.spring, value: validation)
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.lg)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Theme.Colors.glassBackground.opacity(0.15))
            )
    }

    // MARK: - Border Overlay

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.lg)
            .stroke(borderGradient, lineWidth: isFocused ? 1.5 : 0.5)
    }

    private var borderGradient: LinearGradient {
        let color: Color = {
            switch validation {
            case .valid:
                return Theme.Colors.success
            case .invalid:
                return Theme.Colors.error
            default:
                return isFocused ? Theme.Colors.accent : Theme.Colors.glassBorder
            }
        }()

        return LinearGradient(
            colors: [color.opacity(0.8), color.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Glow Overlay

    private var glowOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.lg)
            .stroke(Theme.Colors.accent, lineWidth: 2)
            .blur(radius: 8)
            .opacity(glowOpacity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GlassTextField(
            text: .constant(""),
            placeholder: "Email",
            icon: "envelope.fill",
            validation: .idle
        )

        GlassTextField(
            text: .constant("test@example.com"),
            placeholder: "Email",
            icon: "envelope.fill",
            validation: .valid
        )

        GlassTextField(
            text: .constant("invalid"),
            placeholder: "Email",
            icon: "envelope.fill",
            validation: .invalid("Invalid email")
        )

        GlassTextField(
            text: .constant("password123"),
            placeholder: "Password",
            icon: "lock.fill",
            isSecure: true,
            showSecureText: .constant(false)
        )
    }
    .padding()
    .background(AnimatedAuthBackground())
}
