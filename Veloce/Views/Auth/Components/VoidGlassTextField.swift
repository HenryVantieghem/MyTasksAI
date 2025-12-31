//
//  VoidGlassTextField.swift
//  Veloce
//
//  Void Glass Text Field
//  Stunning text input with void aesthetic and AI glow
//

import SwiftUI

// MARK: - Void Glass Text Field

struct VoidGlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    var validation: ValidationState = .idle
    @Binding var showSecureText: Bool

    @FocusState private var isFocused: Bool
    @State private var glowOpacity: Double = 0.2

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
            // Icon with glow
            iconView

            // Text field
            textFieldView

            // Trailing elements
            trailingView
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md + 2)
        .background(fieldBackground)
        .overlay(fieldBorder)
        .shadow(color: glowColor.opacity(glowOpacity * 0.3), radius: 12, y: 4)
        .animation(Theme.Animation.quickSpring, value: isFocused)
        .animation(Theme.Animation.quickSpring, value: validation)
        .onChange(of: isFocused) { _, focused in
            withAnimation(.easeInOut(duration: 0.3)) {
                glowOpacity = focused ? 0.4 : 0.2
            }
        }
    }

    // MARK: - Icon View

    private var iconView: some View {
        ZStack {
            if isFocused {
                SwiftUI.Circle()
                    .fill(glowColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .blur(radius: 6)
            }

            Image(systemName: icon)
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
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
        .dynamicTypeFont(base: 16, weight: .regular)
        .foregroundStyle(VoidDesign.Colors.textPrimary)
        .focused($isFocused)
        .tint(Theme.Colors.aiPurple)
    }

    // MARK: - Trailing View

    @ViewBuilder
    private var trailingView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Secure toggle
            if isSecure {
                Button {
                    HapticsService.shared.selectionFeedback()
                    showSecureText.toggle()
                } label: {
                    Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // Validation indicator
            if validation != .idle {
                validationIndicator
            }
        }
    }

    // MARK: - Validation Indicator

    private var validationIndicator: some View {
        Group {
            switch validation {
            case .valid:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.Colors.success)
            case .invalid:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Theme.Colors.error)
            case .validating:
                ProgressView()
                    .scaleEffect(0.8)
            case .idle:
                EmptyView()
            }
        }
        .dynamicTypeFont(base: 16)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Field Background

    private var fieldBackground: some View {
        ZStack {
            // Base material for blur effect
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(.ultraThinMaterial)

            // Darker overlay for better visibility
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            VoidDesign.Colors.voidSurface.opacity(0.7),
                            VoidDesign.Colors.voidDeep.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle inner highlight for depth
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .padding(1)
        }
    }

    // MARK: - Field Border

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
            .stroke(
                LinearGradient(
                    colors: [
                        glowColor.opacity(isFocused ? 0.7 : 0.45),
                        glowColor.opacity(isFocused ? 0.5 : 0.25),
                        Color.white.opacity(isFocused ? 0.2 : 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isFocused ? 1.5 : 1
            )
    }

    // MARK: - Colors

    private var glowColor: Color {
        switch validation {
        case .valid: return Theme.Colors.success
        case .invalid: return Theme.Colors.error
        case .validating: return Theme.Colors.aiBlue
        case .idle: return Theme.Colors.aiPurple
        }
    }

    private var iconColor: Color {
        if isFocused {
            return glowColor
        }
        switch validation {
        case .valid: return Theme.Colors.success
        case .invalid: return Theme.Colors.error
        case .validating: return Theme.Colors.aiBlue
        case .idle: return Theme.Colors.textSecondary
        }
    }
}

// MARK: - Void Auth Button

struct VoidAuthButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var glowOpacity: Double = 0.3

    var body: some View {
        Button {
            HapticsService.shared.impact()
            action()
        } label: {
            ZStack {
                // Glow
                Capsule()
                    .fill(Theme.Colors.aiPurple.opacity(glowOpacity))
                    .blur(radius: 15)
                    .offset(y: 6)

                // Button content
                HStack(spacing: Theme.Spacing.sm) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Text(title)
                            .dynamicTypeFont(base: 17, weight: .semibold)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 6)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
        .scaleEffect(isEnabled ? 1 : 0.98)
        .animation(Theme.Animation.quickSpring, value: isEnabled)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.5
            }
        }
    }
}

// MARK: - Void Password Strength Indicator

struct VoidPasswordStrengthIndicator: View {
    let strength: PasswordStrength
    let password: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Strength bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(VoidDesign.Colors.voidSurface)
                        .frame(height: 6)

                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(strengthGradient)
                        .frame(width: geometry.size.width * strengthProgress, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: strength)

                    // Glow at tip
                    SwiftUI.Circle()
                        .fill(strengthColor)
                        .frame(width: 10, height: 10)
                        .blur(radius: 4)
                        .offset(x: geometry.size.width * strengthProgress - 5)
                        .opacity(strengthProgress > 0 ? 0.8 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: strength)
                }
            }
            .frame(height: 6)

            // Label
            HStack(spacing: Theme.Spacing.xs) {
                SwiftUI.Circle()
                    .fill(strengthColor)
                    .frame(width: 6, height: 6)

                Text(strengthLabel)
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(strengthColor)
            }
        }
        .padding(.top, Theme.Spacing.xs)
    }

    private var strengthProgress: CGFloat {
        switch strength {
        case .weak: return 0.25
        case .fair: return 0.5
        case .good: return 0.75
        case .strong: return 1.0
        }
    }

    private var strengthColor: Color {
        switch strength {
        case .weak: return Theme.Colors.error
        case .fair: return Theme.Colors.warning
        case .good: return Theme.Colors.aiBlue
        case .strong: return Theme.Colors.success
        }
    }

    private var strengthGradient: LinearGradient {
        switch strength {
        case .weak:
            return LinearGradient(colors: [Theme.Colors.error, Theme.Colors.error], startPoint: .leading, endPoint: .trailing)
        case .fair:
            return LinearGradient(colors: [Theme.Colors.error, Theme.Colors.warning], startPoint: .leading, endPoint: .trailing)
        case .good:
            return LinearGradient(colors: [Theme.Colors.warning, Theme.Colors.aiBlue], startPoint: .leading, endPoint: .trailing)
        case .strong:
            return LinearGradient(colors: [Theme.Colors.aiBlue, Theme.Colors.success, Theme.Colors.aiCyan], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var strengthLabel: String {
        switch strength {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        VoidGlassTextField(
            text: .constant(""),
            placeholder: "Email",
            icon: "envelope.fill"
        )

        VoidGlassTextField(
            text: .constant("test@example.com"),
            placeholder: "Email",
            icon: "envelope.fill",
            validation: .valid
        )

        VoidAuthButton(
            title: "Sign In",
            isLoading: false,
            isEnabled: true
        ) { }

        VoidPasswordStrengthIndicator(
            strength: .good,
            password: "Test123!"
        )
    }
    .padding()
    .background(VoidBackground.auth)
}
