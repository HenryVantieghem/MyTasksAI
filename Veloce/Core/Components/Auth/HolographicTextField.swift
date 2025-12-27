//
//  HolographicTextField.swift
//  MyTasksAI
//
//  Holographic Text Field - Premium Input Component
//  Ultra-premium glass morphism with prismatic shifting borders,
//  floating labels, icon glow effects, and delightful micro-animations.
//  Designed to feel like Apple paid a billion dollars for this.
//

import SwiftUI

// MARK: - Holographic Text Field

struct HolographicTextField: View {
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
    @State private var borderPhase: Double = 0
    @State private var iconGlowPhase: Double = 0
    @State private var appearScale: CGFloat = 0.95

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Premium prismatic colors
    private let prismaticColors: [Color] = [
        Color(red: 0.55, green: 0.35, blue: 1.0),   // Deep violet
        Color(red: 0.35, green: 0.55, blue: 1.0),   // Electric blue
        Color(red: 0.25, green: 0.85, blue: 0.95),  // Cyan plasma
        Color(red: 0.55, green: 0.95, blue: 0.85),  // Seafoam
        Color(red: 0.95, green: 0.55, blue: 0.85),  // Rose quartz
    ]

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
        VStack(alignment: .leading, spacing: 6) {
            // Main field container
            HStack(spacing: 14) {
                // Leading icon with glow
                holographicIcon

                // Text field with floating label
                ZStack(alignment: .leading) {
                    floatingLabel
                    textFieldContent
                }

                // Trailing elements
                trailingElements
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(glassBackground)
            .overlay(prismaticBorder)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: shadowColor, radius: isFocused ? 20 : 10, y: isFocused ? 6 : 3)
            .scaleEffect(appearScale)

            // Error message
            if case .invalid(let message) = validation {
                errorMessage(message)
            }
        }
        .onChange(of: isFocused) { _, focused in
            updateFloatingLabel()
            onFocusChange?(focused)
            if focused && !reduceMotion {
                startFocusAnimations()
            } else {
                stopFocusAnimations()
            }
        }
        .onChange(of: text) { _, _ in
            updateFloatingLabel()
        }
        .onAppear {
            updateFloatingLabel(animated: false)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appearScale = 1.0
            }
        }
    }

    // MARK: - Holographic Icon

    private var holographicIcon: some View {
        ZStack {
            // Glow aura when focused
            if isFocused {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.4 * (0.7 + iconGlowPhase * 0.3)),
                                accentColor.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 28
                        )
                    )
                    .frame(width: 56, height: 56)
                    .blur(radius: 8)
            }

            // Icon container
            ZStack {
                // Glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 42, height: 42)

                // Overlay tint
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(isFocused ? 0.25 : 0.12),
                                accentColor.opacity(isFocused ? 0.15 : 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                // Prismatic border
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: isFocused ? [
                                accentColor.opacity(0.6),
                                prismaticColors[1].opacity(0.4),
                                accentColor.opacity(0.3),
                                prismaticColors[2].opacity(0.4),
                                accentColor.opacity(0.6)
                            ] : [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.08)
                            ],
                            center: .center,
                            angle: .degrees(borderPhase * 60)
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 42, height: 42)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(iconColor)
                    .shadow(color: isFocused ? accentColor.opacity(0.5) : .clear, radius: 4)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }

    // MARK: - Floating Label

    private var floatingLabel: some View {
        Text(placeholder)
            .font(.system(size: labelScale == 1 ? 16 : 11, weight: labelScale == 1 ? .regular : .medium))
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
        .foregroundStyle(.white)
        .focused($isFocused)
        .keyboardType(keyboardType)
        .textContentType(textContentType)
        .submitLabel(submitLabel)
        .tint(accentColor)
        .onSubmit {
            onSubmit?()
        }
        .offset(y: shouldFloatLabel ? 7 : 0)
    }

    // MARK: - Trailing Elements

    @ViewBuilder
    private var trailingElements: some View {
        HStack(spacing: 10) {
            // Secure toggle
            if isSecure {
                Button {
                    HapticsService.shared.selectionFeedback()
                    showSecureText.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 32, height: 32)

                        Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
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
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 26, height: 26)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 26, height: 26)
                    .rotationEffect(.degrees(borderPhase * 360))
            }

        case .valid:
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.auroraGreen.opacity(0.25),
                                Theme.CelestialColors.auroraGreen.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)

                Circle()
                    .stroke(Theme.CelestialColors.auroraGreen.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 30, height: 30)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
            }
            .transition(.scale.combined(with: .opacity))

        case .invalid:
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.errorNebula.opacity(0.25),
                                Theme.CelestialColors.errorNebula.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)

                Circle()
                    .stroke(Theme.CelestialColors.errorNebula.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 30, height: 30)

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.errorNebula)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)

            // Deep void overlay
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.04, blue: 0.08).opacity(isFocused ? 0.85 : 0.75),
                            Color(red: 0.02, green: 0.02, blue: 0.06).opacity(isFocused ? 0.7 : 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Focus glow
            if isFocused {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .leading,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
            }
        }
    }

    // MARK: - Prismatic Border

    private var prismaticBorder: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(
                AngularGradient(
                    colors: isFocused ? [
                        accentColor.opacity(0.8),
                        prismaticColors[1].opacity(0.5),
                        prismaticColors[2].opacity(0.4),
                        accentColor.opacity(0.3),
                        prismaticColors[3].opacity(0.4),
                        accentColor.opacity(0.8)
                    ] : [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.1),
                        accentColor.opacity(0.15),
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.2)
                    ],
                    center: .center,
                    angle: .degrees(borderPhase * 60)
                ),
                lineWidth: isFocused ? 1.5 : 1
            )
    }

    // MARK: - Error Message

    private func errorMessage(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))

            Text(message)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Theme.CelestialColors.errorNebula)
        .padding(.leading, 60)
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
        default: return prismaticColors[0]
        }
    }

    private var iconColor: Color {
        if isFocused {
            return accentColor
        }
        switch validation {
        case .valid: return Theme.CelestialColors.auroraGreen
        case .invalid: return Theme.CelestialColors.errorNebula
        default: return Color.white.opacity(0.55)
        }
    }

    private var labelColor: Color {
        if isFocused {
            return accentColor.opacity(0.9)
        }
        return Color.white.opacity(0.4)
    }

    private var shadowColor: Color {
        if isFocused {
            return accentColor.opacity(0.3)
        }
        return Color.black.opacity(0.25)
    }

    // MARK: - Helpers

    private func updateFloatingLabel(animated: Bool = true) {
        let action = {
            if shouldFloatLabel {
                labelOffset = -15
                labelScale = 0.75
            } else {
                labelOffset = 0
                labelScale = 1.0
            }
        }

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                action()
            }
        } else {
            action()
        }
    }

    private func startFocusAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            borderPhase = 6
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            iconGlowPhase = 1
        }
    }

    private func stopFocusAnimations() {
        borderPhase = 0
        iconGlowPhase = 0
    }
}

// MARK: - Holographic Password Strength

struct HolographicPasswordStrength: View {
    let strength: PasswordStrength
    let password: String

    @State private var animatedProgress: CGFloat = 0
    @State private var glowPhase: Double = 0

    private let prismaticColors: [Color] = [
        Color(red: 0.55, green: 0.35, blue: 1.0),
        Color(red: 0.35, green: 0.55, blue: 1.0),
        Color(red: 0.25, green: 0.85, blue: 0.95),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    // Progress fill with gradient
                    Capsule()
                        .fill(strengthGradient)
                        .frame(width: geometry.size.width * animatedProgress, height: 8)

                    // Glow tip
                    if animatedProgress > 0 {
                        Circle()
                            .fill(strengthColor)
                            .frame(width: 14, height: 14)
                            .blur(radius: 6)
                            .position(x: geometry.size.width * animatedProgress, y: 4)
                            .opacity(0.6 + glowPhase * 0.4)
                    }
                }
            }
            .frame(height: 8)

            // Strength label and dots
            HStack {
                Text(strength.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(strengthColor)

                Spacer()

                // Prismatic dots
                HStack(spacing: 5) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(
                                index < strengthLevel ?
                                    LinearGradient(
                                        colors: [strengthColor, strengthColor.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ) :
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(
                                        index < strengthLevel ? strengthColor.opacity(0.5) : Color.white.opacity(0.1),
                                        lineWidth: 0.5
                                    )
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .onAppear {
            updateProgress()
            startGlowAnimation()
        }
        .onChange(of: password) { _, _ in
            updateProgress()
        }
    }

    private func updateProgress() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            animatedProgress = CGFloat(strength.rawValue) / 4.0
        }
    }

    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }
    }

    private var strengthLevel: Int {
        strength.rawValue
    }

    private var strengthColor: Color {
        strength.color
    }

    private var strengthGradient: LinearGradient {
        LinearGradient(
            colors: [strengthColor, strengthColor.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Preview

#Preview("Holographic Text Fields") {
    struct FieldDemo: View {
        @State private var email = ""
        @State private var emailWithValue = "user@example.com"
        @State private var password = ""
        @State private var showPassword = false

        var body: some View {
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Empty field
                        HolographicTextField(
                            text: $email,
                            placeholder: "Email",
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )

                        // Field with value - valid
                        HolographicTextField(
                            text: $emailWithValue,
                            placeholder: "Email",
                            icon: "envelope.fill",
                            validation: .valid
                        )

                        // Password field
                        HolographicTextField(
                            text: $password,
                            placeholder: "Password",
                            icon: "lock.fill",
                            isSecure: true,
                            showSecureText: $showPassword
                        )

                        // Invalid field
                        HolographicTextField(
                            text: .constant("invalid"),
                            placeholder: "Email",
                            icon: "envelope.fill",
                            validation: .invalid("Please enter a valid email")
                        )

                        // Password strength indicator
                        if !password.isEmpty {
                            HolographicPasswordStrength(
                                strength: password.count > 12 ? .strong :
                                    password.count > 8 ? .good :
                                    password.count > 6 ? .fair : .weak,
                                password: password
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
    }

    return FieldDemo()
}
