//
//  CrystallineTextField.swift
//  Veloce
//
//  Crystalline Text Field
//  Premium text input with floating label, clean focus states,
//  validation feedback, and orb awareness integration.
//

import SwiftUI

// MARK: - Crystalline Text Field

struct CrystallineTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    var validation: ValidationState = .idle
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .done
    var onFocusChange: ((Bool) -> Void)? = nil
    var onSubmit: (() -> Void)? = nil
    @Binding var showSecureText: Bool

    @FocusState private var isFocused: Bool
    @State private var labelOffset: CGFloat = 0
    @State private var labelScale: CGFloat = 1.0

    init(
        text: Binding<String>,
        placeholder: String,
        icon: String,
        isSecure: Bool = false,
        validation: ValidationState = .idle,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        submitLabel: SubmitLabel = .done,
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
        self._showSecureText = showSecureText
        self.onFocusChange = onFocusChange
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main field container
            HStack(spacing: Aurora.Layout.spacing) {
                // Leading icon
                fieldIcon

                // Text field with floating label
                ZStack(alignment: .leading) {
                    // Floating label
                    floatingLabel

                    // Actual text field
                    textFieldContent
                }

                // Trailing elements
                trailingElements
            }
            .padding(.horizontal, Aurora.Layout.spacing)
            .padding(.vertical, 14)
            .background(fieldBackground)
            .overlay(fieldBorder)
            .clipShape(RoundedRectangle(cornerRadius: Aurora.Radius.textField))
            .shadow(color: shadowColor, radius: isFocused ? 12 : 6, y: isFocused ? 4 : 2)

            // Error message
            if case .invalid(let message) = validation {
                errorMessage(message)
            }
        }
        .onChange(of: isFocused) { _, focused in
            updateFloatingLabel()
            onFocusChange?(focused)
        }
        .onChange(of: text) { _, _ in
            updateFloatingLabel()
        }
        .onAppear {
            updateFloatingLabel(animated: false)
        }
    }

    // MARK: - Field Icon

    private var fieldIcon: some View {
        ZStack {
            // Glow behind icon when focused
            if isFocused {
                SwiftUI.Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .blur(radius: 6)
            }

            Image(systemName: icon)
                .dynamicTypeFont(base: 18, weight: .medium)
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
        }
        .animation(Aurora.Animation.quick, value: isFocused)
    }

    // MARK: - Floating Label

    private var floatingLabel: some View {
        Text(placeholder)
            .font(.system(size: labelScale == 1 ? 16 : 12, weight: .regular))
            .foregroundStyle(labelColor)
            .offset(y: labelOffset)
            .scaleEffect(labelScale, anchor: .leading)
            .allowsHitTesting(false)
    }

    // MARK: - Text Field Content

    @ViewBuilder
    private var textFieldContent: some View {
        Group {
            if isSecure && !showSecureText {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
            }
        }
        .dynamicTypeFont(base: 16, weight: .regular)
        .foregroundStyle(Aurora.Colors.textPrimary)
        .focused($isFocused)
        .keyboardType(keyboardType)
        .textContentType(textContentType)
        .submitLabel(submitLabel)
        .tint(accentColor)
        .onSubmit {
            onSubmit?()
        }
        .offset(y: shouldFloatLabel ? 6 : 0)
    }

    // MARK: - Trailing Elements

    @ViewBuilder
    private var trailingElements: some View {
        HStack(spacing: Aurora.Layout.spacingSmall) {
            // Secure toggle
            if isSecure {
                Button {
                    HapticsService.shared.selectionFeedback()
                    showSecureText.toggle()
                } label: {
                    Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(Aurora.Colors.textTertiary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }

            // Validation indicator
            validationIndicator
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
                .scaleEffect(0.8)
                .tint(Aurora.Colors.electric)

        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .dynamicTypeFont(base: 20)
                .foregroundStyle(Aurora.Colors.success)
                .transition(.scale.combined(with: .opacity))

        case .invalid:
            Image(systemName: "exclamationmark.circle.fill")
                .dynamicTypeFont(base: 20)
                .foregroundStyle(Aurora.Colors.error)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Field Background

    private var fieldBackground: some View {
        ZStack {
            // Base glass fill
            RoundedRectangle(cornerRadius: Aurora.Radius.textField)
                .fill(isFocused ? Aurora.Colors.glassFocused : Aurora.Colors.glassBase)

            // Subtle gradient
            RoundedRectangle(cornerRadius: Aurora.Radius.textField)
                .fill(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.cosmicSurface.opacity(isFocused ? 0.6 : 0.5),
                            Aurora.Colors.cosmicDeep.opacity(isFocused ? 0.4 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Focus glow
            if isFocused {
                RoundedRectangle(cornerRadius: Aurora.Radius.textField)
                    .fill(accentColor.opacity(0.03))
            }
        }
    }

    // MARK: - Field Border

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: Aurora.Radius.textField)
            .stroke(borderGradient, lineWidth: isFocused ? 1.5 : 1)
    }

    private var borderGradient: LinearGradient {
        if isFocused {
            return LinearGradient(
                colors: [
                    accentColor.opacity(0.8),
                    accentColor.opacity(0.4),
                    Aurora.Colors.glassBorder
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Aurora.Colors.glassHighlight.opacity(0.5),
                    Aurora.Colors.glassBorder,
                    Aurora.Colors.glassBorder.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Error Message

    private func errorMessage(_ message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .dynamicTypeFont(base: 11)

            Text(message)
                .dynamicTypeFont(base: 12, weight: .medium)
        }
        .foregroundStyle(Aurora.Colors.error)
        .padding(.leading, 44) // Align with text field content
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Computed Properties

    private var shouldFloatLabel: Bool {
        isFocused || !text.isEmpty
    }

    private var accentColor: Color {
        switch validation {
        case .valid: return Aurora.Colors.success
        case .invalid: return Aurora.Colors.error
        default: return Aurora.Colors.electric
        }
    }

    private var iconColor: Color {
        if isFocused {
            return accentColor
        }
        switch validation {
        case .valid: return Aurora.Colors.success
        case .invalid: return Aurora.Colors.error
        default: return Aurora.Colors.textTertiary
        }
    }

    private var labelColor: Color {
        if isFocused {
            return accentColor
        }
        return Aurora.Colors.textQuaternary
    }

    private var shadowColor: Color {
        if isFocused {
            return accentColor.opacity(0.2)
        }
        return Color.black.opacity(0.15)
    }

    // MARK: - Helpers

    private func updateFloatingLabel(animated: Bool = true) {
        let action = {
            if shouldFloatLabel {
                labelOffset = -14
                labelScale = 0.8
            } else {
                labelOffset = 0
                labelScale = 1.0
            }
        }

        if animated {
            withAnimation(Aurora.Animation.spring) {
                action()
            }
        } else {
            action()
        }
    }
}

// MARK: - Preview

#Preview("Crystalline Text Fields") {
    struct TextFieldDemo: View {
        @State private var email = ""
        @State private var emailWithValue = "user@example.com"
        @State private var password = ""
        @State private var showPassword = false

        var body: some View {
            VStack(spacing: 20) {
                // Empty field
                CrystallineTextField(
                    text: $email,
                    placeholder: "Email",
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )

                // Field with value - valid
                CrystallineTextField(
                    text: $emailWithValue,
                    placeholder: "Email",
                    icon: "envelope.fill",
                    validation: .valid
                )

                // Password field
                CrystallineTextField(
                    text: $password,
                    placeholder: "Password",
                    icon: "lock.fill",
                    isSecure: true,
                    showSecureText: $showPassword
                )

                // Invalid field
                CrystallineTextField(
                    text: .constant("invalid"),
                    placeholder: "Email",
                    icon: "envelope.fill",
                    validation: .invalid("Please enter a valid email")
                )

                // Validating field
                CrystallineTextField(
                    text: .constant("checking..."),
                    placeholder: "Username",
                    icon: "person.fill",
                    validation: .validating
                )
            }
            .padding()
            .background(AuroraBackground.auth)
        }
    }

    return TextFieldDemo()
}
