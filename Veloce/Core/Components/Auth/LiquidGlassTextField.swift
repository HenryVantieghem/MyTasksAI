//
//  LiquidGlassTextField.swift
//  Veloce
//
//  Pure Native iOS 26 Text Field Components
//  Uses standard TextField with native Liquid Glass styling
//
//  Architecture:
//  - Standard TextField/SecureField
//  - Native glass background via adaptiveGlass()
//  - System validation states
//

import SwiftUI

// MARK: - Liquid Glass TextField

struct LiquidGlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String?
    let isSecure: Bool
    let validation: GlassValidationState
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let submitLabel: SubmitLabel
    let autocapitalization: TextInputAutocapitalization

    @Binding var showSecureText: Bool
    var onFocusChange: ((Bool) -> Void)?
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        placeholder: String,
        icon: String? = nil,
        isSecure: Bool = false,
        validation: GlassValidationState = .idle,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        submitLabel: SubmitLabel = .next,
        autocapitalization: TextInputAutocapitalization = .sentences,
        showSecureText: Binding<Bool> = .constant(false),
        onFocusChange: ((Bool) -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
        self.validation = validation
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.submitLabel = submitLabel
        self.autocapitalization = autocapitalization
        self._showSecureText = showSecureText
        self.onFocusChange = onFocusChange
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Main text field container
            HStack(spacing: 12) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isFocused ? accentColor : .secondary)
                        .frame(width: 24)
                }

                // Text field
                textFieldView
                    .frame(maxWidth: .infinity)

                // Validation indicator
                validationIndicator

                // Secure text toggle
                if isSecure {
                    secureToggle
                }
            }
            .frame(height: 48)
            .padding(.horizontal, 16)
            .background(fieldBackground)
            .overlay(fieldBorder)
            .animation(.spring(response: 0.3), value: isFocused)
            .animation(.spring(response: 0.3), value: validation)

            // Error message
            if case .invalid(let message) = validation {
                errorMessage(message)
            }
        }
        .onChange(of: isFocused) { _, newValue in
            onFocusChange?(newValue)
            if newValue {
                HapticsService.shared.lightImpact()
            }
        }
    }

    // MARK: - Text Field View

    @ViewBuilder
    private var textFieldView: some View {
        Group {
            if isSecure && !showSecureText {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.body)
        .foregroundStyle(.primary)
        .tint(accentColor)
        .keyboardType(keyboardType)
        .textContentType(textContentType)
        .textInputAutocapitalization(autocapitalization)
        .submitLabel(submitLabel)
        .focused($isFocused)
        .onSubmit {
            onSubmit?()
        }
    }

    // MARK: - Validation Indicator

    @ViewBuilder
    private var validationIndicator: some View {
        switch validation {
        case .idle:
            EmptyView()

        case .validating:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                .scaleEffect(0.7)

        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.auroraGreen)
                .transition(.scale.combined(with: .opacity))

        case .invalid:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.red)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Secure Toggle

    private var secureToggle: some View {
        Button {
            HapticsService.shared.lightImpact()
            showSecureText.toggle()
        } label: {
            Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Field Background

    @ViewBuilder
    private var fieldBackground: some View {
        let cornerRadius: CGFloat = 12
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(isFocused ? accentColor.opacity(0.1) : Color.clear),
                    in: shape
                )
        } else {
            shape
                .fill(.ultraThinMaterial)
                .overlay {
                    if isFocused {
                        shape.fill(accentColor.opacity(0.05))
                    }
                }
        }
    }

    // MARK: - Field Border

    @ViewBuilder
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isFocused ? accentColor : borderColor,
                lineWidth: isFocused ? 1.5 : 0.5
            )
    }

    // MARK: - Error Message

    @ViewBuilder
    private func errorMessage(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)

            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.red.opacity(0.9))
        .padding(.leading, icon != nil ? 52 : 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Colors

    private var accentColor: Color {
        LiquidGlassDesignSystem.VibrantAccents.electricCyan
    }

    private var borderColor: Color {
        switch validation {
        case .valid:
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        case .invalid:
            return .red
        default:
            return .white.opacity(0.2)
        }
    }
}

// MARK: - Password Strength Indicator

struct LiquidGlassPasswordStrength: View {
    let strength: PasswordStrength
    let password: String

    enum PasswordStrength: Int, CaseIterable {
        case weak = 1
        case fair = 2
        case good = 3
        case strong = 4

        var label: String {
            switch self {
            case .weak: return "Weak"
            case .fair: return "Fair"
            case .good: return "Good"
            case .strong: return "Strong"
            }
        }

        var color: Color {
            switch self {
            case .weak: return .red
            case .fair: return .orange
            case .good: return LiquidGlassDesignSystem.VibrantAccents.solarGold
            case .strong: return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
            }
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Progress bars
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            index < strength.rawValue
                            ? strength.color
                            : Color.white.opacity(0.15)
                        )
                        .frame(height: 4)
                }
            }
            .frame(maxWidth: 100)

            // Label
            Text(strength.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(strength.color)
        }
        .animation(.easeInOut(duration: 0.2), value: strength)
    }
}

// MARK: - Preview

#Preview("Native Text Fields") {
    struct PreviewWrapper: View {
        @State private var email = ""
        @State private var password = "test123"
        @State private var showPassword = false
        @State private var validEmail = "user@example.com"

        var body: some View {
            ZStack {
                LiquidGlassDesignSystem.Void.cosmos
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Native Liquid Glass Text Fields")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    // Empty state
                    LiquidGlassTextField(
                        text: $email,
                        placeholder: "Email",
                        icon: "envelope.fill",
                        validation: .idle,
                        keyboardType: .emailAddress
                    )

                    // Valid state
                    LiquidGlassTextField(
                        text: $validEmail,
                        placeholder: "Email",
                        icon: "envelope.fill",
                        validation: .valid
                    )

                    // Invalid state
                    LiquidGlassTextField(
                        text: .constant("invalid-email"),
                        placeholder: "Email",
                        icon: "envelope.fill",
                        validation: .invalid("Please enter a valid email")
                    )

                    // Password with strength
                    VStack(spacing: 10) {
                        LiquidGlassTextField(
                            text: $password,
                            placeholder: "Password",
                            icon: "lock.fill",
                            isSecure: true,
                            showSecureText: $showPassword
                        )

                        LiquidGlassPasswordStrength(
                            strength: .fair,
                            password: password
                        )
                    }
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}
