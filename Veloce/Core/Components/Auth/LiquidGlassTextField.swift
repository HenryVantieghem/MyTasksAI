//
//  LiquidGlassTextField.swift
//  Veloce
//
//  Ultra-Premium Liquid Glass Text Field Component
//  Features native iOS 26 glass effects, floating labels,
//  prismatic borders, and real-time validation with premium haptics.
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
    @State private var borderRotation: Double = 0
    @State private var iconGlowPulse: Double = 0
    @State private var labelOffset: CGFloat = 0
    @State private var labelScale: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    // MARK: - Computed Properties

    private var shouldShowFloatingLabel: Bool {
        isFocused || !text.isEmpty
    }

    private var currentTint: Color {
        if isFocused {
            return LiquidGlassDesignSystem.GlassTints.interactive
        }
        return validation.tint
    }

    private var borderOpacity: Double {
        if isFocused {
            return LiquidGlassDesignSystem.GlassConfig.borderOpacityFocused
        }
        switch validation {
        case .valid, .invalid:
            return LiquidGlassDesignSystem.GlassConfig.borderOpacityPressed
        default:
            return LiquidGlassDesignSystem.GlassConfig.borderOpacityRest
        }
    }

    private var glowColor: Color {
        if isFocused {
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        }
        switch validation {
        case .valid:
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        case .invalid:
            return Color.red
        default:
            return .clear
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Main text field container
            HStack(spacing: 12) {
                // Icon container
                if let icon = icon {
                    iconContainer(systemName: icon)
                }

                // Text field with floating label
                ZStack(alignment: .leading) {
                    // Floating label
                    floatingLabel

                    // Actual text field
                    textFieldView
                }

                // Validation indicator
                validationIndicator

                // Secure text toggle
                if isSecure {
                    secureToggle
                }
            }
            .frame(height: LiquidGlassDesignSystem.Sizing.textFieldHeight)
            .padding(.horizontal, 16)
            .background(fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.cornerRadius))
            .overlay(fieldBorder)
            .shadow(
                color: glowColor.opacity(isFocused || validation != .idle ? 0.3 : 0),
                radius: 16,
                x: 0,
                y: 0
            )
            .animation(LiquidGlassDesignSystem.Springs.focus, value: isFocused)
            .animation(LiquidGlassDesignSystem.Springs.focus, value: validation)

            // Error message
            if case .invalid(let message) = validation {
                errorMessage(message)
            }
        }
        .onChange(of: isFocused) { _, newValue in
            onFocusChange?(newValue)
            updateLabelPosition()

            if newValue {
                HapticsService.shared.glassFocus()
            }
        }
        .onChange(of: text) { _, _ in
            updateLabelPosition()
        }
        .onAppear {
            updateLabelPosition()
            startAnimations()
        }
    }

    // MARK: - Icon Container

    @ViewBuilder
    private func iconContainer(systemName: String) -> some View {
        ZStack {
            // Glow circle (when focused)
            if isFocused && !reduceMotion {
                Circle()
                    .fill(LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .blur(radius: 8)
                    .scaleEffect(1 + iconGlowPulse * 0.15)
            }

            // Icon
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(
                    isFocused
                    ? LiquidGlassDesignSystem.VibrantAccents.electricCyan
                    : Color.white.opacity(0.5)
                )
        }
        .frame(width: 24)
        .animation(LiquidGlassDesignSystem.Springs.focus, value: isFocused)
    }

    // MARK: - Floating Label

    @ViewBuilder
    private var floatingLabel: some View {
        Text(placeholder)
            .font(.system(size: shouldShowFloatingLabel ? 11 : 16, weight: .medium))
            .foregroundStyle(
                isFocused
                ? LiquidGlassDesignSystem.VibrantAccents.electricCyan
                : Color.white.opacity(shouldShowFloatingLabel ? 0.6 : 0.4)
            )
            .offset(y: shouldShowFloatingLabel ? -14 : 0)
            .scaleEffect(shouldShowFloatingLabel ? 0.85 : 1.0, anchor: .leading)
            .allowsHitTesting(false)
            .animation(LiquidGlassDesignSystem.Springs.focus, value: shouldShowFloatingLabel)
    }

    // MARK: - Text Field View

    @ViewBuilder
    private var textFieldView: some View {
        Group {
            if isSecure && !showSecureText {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
            }
        }
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(.white)
        .tint(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
        .keyboardType(keyboardType)
        .textContentType(textContentType)
        .textInputAutocapitalization(autocapitalization)
        .submitLabel(submitLabel)
        .focused($isFocused)
        .onSubmit {
            onSubmit?()
        }
        .offset(y: shouldShowFloatingLabel ? 6 : 0)
        .animation(LiquidGlassDesignSystem.Springs.focus, value: shouldShowFloatingLabel)
    }

    // MARK: - Validation Indicator

    @ViewBuilder
    private var validationIndicator: some View {
        Group {
            switch validation {
            case .idle:
                EmptyView()

            case .validating:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan))
                    .scaleEffect(0.7)

            case .valid:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.auroraGreen)
                    .transition(.scale.combined(with: .opacity))

            case .invalid:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.red)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(LiquidGlassDesignSystem.Springs.ui, value: validation)
    }

    // MARK: - Secure Toggle

    @ViewBuilder
    private var secureToggle: some View {
        Button {
            HapticsService.shared.lightImpact()
            showSecureText.toggle()
        } label: {
            Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Field Background

    @ViewBuilder
    private var fieldBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.cornerRadius)
                .fill(.ultraThinMaterial)

            // Tint overlay
            RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.cornerRadius)
                .fill(currentTint)

            // Void overlay for depth
            RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.cornerRadius)
                .fill(Theme.CelestialColors.void.opacity(0.3))
        }
    }

    // MARK: - Field Border

    @ViewBuilder
    private var fieldBorder: some View {
        Group {
            if isFocused && !reduceMotion {
                // Animated prismatic border when focused
                RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.cornerRadius)
                    .stroke(
                        LiquidGlassDesignSystem.Gradients.prismaticBorder(rotation: borderRotation),
                        lineWidth: 1.5
                    )
            } else {
                // Standard glass border
                RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                validation.iconColor.opacity(borderOpacity),
                                Color.white.opacity(borderOpacity * 0.4),
                                Color.white.opacity(borderOpacity * 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
        }
    }

    // MARK: - Error Message

    @ViewBuilder
    private func errorMessage(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))

            Text(message)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Color.red.opacity(0.9))
        .padding(.leading, icon != nil ? 52 : 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Helpers

    private func updateLabelPosition() {
        withAnimation(LiquidGlassDesignSystem.Springs.focus) {
            if isFocused || !text.isEmpty {
                labelOffset = -14
                labelScale = 0.85
            } else {
                labelOffset = 0
                labelScale = 1.0
            }
        }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Border rotation animation
        withAnimation(
            .linear(duration: LiquidGlassDesignSystem.MorphAnimation.prismaticRotation)
            .repeatForever(autoreverses: false)
        ) {
            borderRotation = 360
        }

        // Icon glow pulse
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            iconGlowPulse = 1
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
            case .weak: return Color.red
            case .fair: return Color.orange
            case .good: return LiquidGlassDesignSystem.VibrantAccents.solarGold
            case .strong: return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
            }
        }

        var progress: Double {
            Double(rawValue) / Double(PasswordStrength.allCases.count)
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
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(strength.color)
        }
        .padding(.leading, 4)
        .animation(.easeInOut(duration: 0.2), value: strength)
    }
}

// MARK: - Preview

#Preview("Text Field States") {
    struct PreviewWrapper: View {
        @State private var email = ""
        @State private var password = "test123"
        @State private var showPassword = false
        @State private var validEmail = "user@example.com"

        var body: some View {
            ZStack {
                Theme.CelestialColors.voidDeep
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Liquid Glass Text Fields")
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

                    // Validating state
                    LiquidGlassTextField(
                        text: .constant("checking..."),
                        placeholder: "Username",
                        icon: "at",
                        validation: .validating
                    )
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}
