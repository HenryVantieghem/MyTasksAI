//
//  CelestialTextField.swift
//  Veloce
//
//  Living Cosmos Text Field Component
//  Premium text input with celestial glass styling, floating label,
//  validation feedback, and nebula glow effects
//

import SwiftUI

// MARK: - Celestial Text Field

struct CelestialTextField: View {
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
    @State private var glowPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            HStack(spacing: Theme.Spacing.md) {
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
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 14)
            .background(fieldBackground)
            .overlay(fieldBorder)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: shadowColor, radius: isFocused ? 16 : 8, y: isFocused ? 4 : 2)

            // Error message
            if case .invalid(let message) = validation {
                errorMessage(message)
            }
        }
        .onChange(of: isFocused) { _, focused in
            updateFloatingLabel()
            onFocusChange?(focused)
            if focused && !reduceMotion {
                withAnimation(LivingCosmos.Animations.plasmaPulse) {
                    glowPhase = 1
                }
            } else {
                glowPhase = 0
            }
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
            // Nebula glow behind icon when focused
            if isFocused {
                SwiftUI.Circle()
                    .fill(accentColor.opacity(0.25))
                    .frame(width: 40, height: 40)
                    .blur(radius: 8)
            }

            // Icon container
            ZStack {
                SwiftUI.Circle()
                    .fill(accentColor.opacity(isFocused ? 0.15 : 0.08))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }
        }
        .animation(LivingCosmos.Animations.quick, value: isFocused)
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
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(Theme.CelestialColors.starWhite)
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
        HStack(spacing: Theme.Spacing.sm) {
            // Secure toggle
            if isSecure {
                Button {
                    HapticsService.shared.selectionFeedback()
                    showSecureText.toggle()
                } label: {
                    Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
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
                .tint(Theme.Colors.aiPurple)

        case .valid:
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.auroraGreen.opacity(0.2))
                    .frame(width: 28, height: 28)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
            }
            .transition(.scale.combined(with: .opacity))

        case .invalid:
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.errorNebula.opacity(0.2))
                    .frame(width: 28, height: 28)

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.errorNebula)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Field Background

    private var fieldBackground: some View {
        ZStack {
            // Base glass fill
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)

            // Void overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.abyss.opacity(isFocused ? 0.7 : 0.6),
                            Theme.CelestialColors.void.opacity(isFocused ? 0.5 : 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Focus nebula glow
            if isFocused {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.08),
                                Color.clear
                            ],
                            center: .leading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
            }
        }
    }

    // MARK: - Field Border

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(borderGradient, lineWidth: isFocused ? 1.5 : 1)
    }

    private var borderGradient: LinearGradient {
        if isFocused {
            return LinearGradient(
                colors: [
                    accentColor.opacity(0.8),
                    accentColor.opacity(0.4),
                    Theme.CelestialColors.starGhost.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.08),
                    Theme.CelestialColors.starGhost.opacity(0.1)
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
                .font(.system(size: 11))

            Text(message)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Theme.CelestialColors.errorNebula)
        .padding(.leading, 52) // Align with text field content
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Computed Properties

    private var shouldFloatLabel: Bool {
        isFocused || !text.isEmpty
    }

    private var accentColor: Color {
        switch validation {
        case .valid: return Theme.CelestialColors.auroraGreen
        case .invalid: return Theme.CelestialColors.errorNebula
        default: return Theme.Colors.aiPurple
        }
    }

    private var iconColor: Color {
        if isFocused {
            return accentColor
        }
        switch validation {
        case .valid: return Theme.CelestialColors.auroraGreen
        case .invalid: return Theme.CelestialColors.errorNebula
        default: return Theme.CelestialColors.starDim
        }
    }

    private var labelColor: Color {
        if isFocused {
            return accentColor
        }
        return Theme.CelestialColors.starGhost
    }

    private var shadowColor: Color {
        if isFocused {
            return accentColor.opacity(0.25)
        }
        return Color.black.opacity(0.2)
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
            withAnimation(LivingCosmos.Animations.spring) {
                action()
            }
        } else {
            action()
        }
    }
}

// MARK: - Celestial Password Strength

struct CelestialPasswordStrength: View {
    let strength: PasswordStrength
    let password: String

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Theme.CelestialColors.void.opacity(0.6))
                        .frame(height: 6)

                    // Progress fill
                    Capsule()
                        .fill(strengthGradient)
                        .frame(width: geometry.size.width * animatedProgress, height: 6)

                    // Glow tip
                    if animatedProgress > 0 {
                        SwiftUI.Circle()
                            .fill(strengthColor)
                            .frame(width: 10, height: 10)
                            .blur(radius: 4)
                            .position(x: geometry.size.width * animatedProgress, y: 3)
                    }
                }
            }
            .frame(height: 6)

            // Strength label and hints
            HStack {
                Text(strength.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(strengthColor)

                Spacer()

                // Constellation dots
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        SwiftUI.Circle()
                            .fill(index < strengthLevel ? strengthColor : Theme.CelestialColors.starGhost.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .onAppear {
            updateProgress()
        }
        .onChange(of: password) { _, _ in
            updateProgress()
        }
    }

    private func updateProgress() {
        withAnimation(LivingCosmos.Animations.spring) {
            // Progress based on strength level (weak=0.25, fair=0.5, good=0.75, strong=1.0)
            animatedProgress = CGFloat(strength.rawValue) / 4.0
        }
    }

    private var strengthLevel: Int {
        // Map to 4-dot display: weak=1, fair=2, good=3, strong=4
        strength.rawValue
    }

    private var strengthColor: Color {
        strength.color
    }

    private var strengthGradient: LinearGradient {
        LinearGradient(
            colors: [strengthColor, strengthColor.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Preview

#Preview("Celestial Text Fields") {
    struct TextFieldDemo: View {
        @State private var email = ""
        @State private var emailWithValue = "user@example.com"
        @State private var password = ""
        @State private var showPassword = false

        var body: some View {
            ZStack {
                VoidBackground.auth

                ScrollView {
                    VStack(spacing: 20) {
                        // Empty field
                        CelestialTextField(
                            text: $email,
                            placeholder: "Email",
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )

                        // Field with value - valid
                        CelestialTextField(
                            text: $emailWithValue,
                            placeholder: "Email",
                            icon: "envelope.fill",
                            validation: .valid
                        )

                        // Password field
                        CelestialTextField(
                            text: $password,
                            placeholder: "Password",
                            icon: "lock.fill",
                            isSecure: true,
                            showSecureText: $showPassword
                        )

                        // Invalid field
                        CelestialTextField(
                            text: .constant("invalid"),
                            placeholder: "Email",
                            icon: "envelope.fill",
                            validation: .invalid("Please enter a valid email")
                        )

                        // Password strength indicator
                        if !password.isEmpty {
                            CelestialPasswordStrength(
                                strength: password.count > 12 ? .strong :
                                    password.count > 8 ? .good :
                                    password.count > 6 ? .fair : .weak,
                                password: password
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    return TextFieldDemo()
}
