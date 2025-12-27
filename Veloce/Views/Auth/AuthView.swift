//
//  AuthView.swift
//  MyTasksAI
//
//  Authentication View - Celestial Luminescence Design
//  A breathtaking auth experience with Ethereal Orb, holographic components,
//  prismatic effects, and staggered reveal animations.
//  Designed with premium elegance and refined interactions.
//

import SwiftUI

// MARK: - Auth Screen

enum AuthScreen: Equatable {
    case signIn
    case signUp
    case forgotPassword
}

// MARK: - Auth View

struct AuthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = AuthViewModel()
    @State private var currentScreen: AuthScreen
    @State private var showContent = false
    @State private var showError = false
    @State private var orbIntensity: Double = 1.0
    @State private var orbState: EtherealOrbState = .idle
    @State private var triggerSuccessBurst = false
    @FocusState private var focusedField: AuthField?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Ethereal color palette
    private let etherealColors: [Color] = [
        Color(red: 0.75, green: 0.55, blue: 0.90), // softPurple
        Color(red: 0.55, green: 0.85, blue: 0.95), // softCyan
        Color(red: 0.95, green: 0.65, blue: 0.80), // softPink
        Color(red: 0.70, green: 0.60, blue: 0.95), // softLavender
    ]

    /// Initialize with optional starting screen
    init(initialScreen: AuthScreen = .signUp) {
        _currentScreen = State(initialValue: initialScreen)
    }

    enum AuthField: Hashable {
        case email, password, confirmPassword, name, username
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cosmic void background (consistent across app)
                VoidBackground.auth

                // Ambient floating particles
                if !reduceMotion {
                    AmbientParticleField(
                        density: .standard,
                        colors: etherealColors,
                        bounds: geometry.size
                    )
                    .opacity(showContent ? 0.6 : 0)
                }

                // Ethereal Orb positioned at top
                EtherealOrb(
                    size: orbSize(for: geometry),
                    state: orbState,
                    isAnimating: true,
                    intensity: orbIntensity,
                    showGlow: true
                )
                .position(
                    x: geometry.size.width / 2,
                    y: orbYPosition(for: geometry)
                )
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.85)
                .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.2), value: showContent)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Spacer for orb
                        Spacer(minLength: orbSpacerHeight(for: geometry))

                        // Logo & Title
                        headerSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: showContent)

                        Spacer(minLength: 32)

                        // Auth form
                        authFormSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: showContent)

                        Spacer(minLength: 24)

                        // Terms
                        termsSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6), value: showContent)
                            .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
            // Tap anywhere to dismiss keyboard
            .onTapGesture {
                focusedField = nil
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
            }
        }
        .onChange(of: viewModel.authState) { _, newValue in
            handleAuthStateChange(newValue)
        }
        .onChange(of: focusedField) { _, newField in
            updateOrbIntensity(for: newField)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                viewModel.clearError()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    orbIntensity = 1.0
                }
            }
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
        .task {
            viewModel.onAuthSuccess = {
                Task {
                    await appViewModel.checkAuthenticationState()
                }
            }
        }
    }


    // MARK: - Orb State

    private func updateOrbIntensity(for field: AuthField?) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if field != nil {
                orbIntensity = 1.35
                orbState = .active
            } else {
                orbIntensity = 1.0
                orbState = .idle
            }
        }
    }

    // MARK: - Layout Calculations

    private func orbSize(for geometry: GeometryProxy) -> LogoSize {
        let height = geometry.size.height
        if height < 700 {
            return .large // 120pt for smaller screens
        } else {
            return .hero // 200pt for larger screens
        }
    }

    private func orbYPosition(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        if height < 700 {
            return height * 0.14
        } else {
            return height * 0.16
        }
    }

    private func orbSpacerHeight(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        if height < 700 {
            return 180
        } else if height < 850 {
            return 220
        } else {
            return 260
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 14) {
            // Refined thin typography
            Text("MyTasksAI")
                .font(.system(size: 46, weight: .thin, design: .default))
                .tracking(6)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("INTELLIGENT PRODUCTIVITY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(6)
                .foregroundStyle(Color.white.opacity(0.38))
        }
    }

    // MARK: - Auth Form Section

    @ViewBuilder
    private var authFormSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            switch currentScreen {
            case .signIn:
                signInForm
            case .signUp:
                signUpForm
            case .forgotPassword:
                forgotPasswordForm
            }
        }
        .animation(LivingCosmos.Animations.spring, value: currentScreen)
    }

    // MARK: - Sign In Form

    private var signInForm: some View {
        VStack(spacing: 24) {
            // Wrapped inner VStack with LiquidGlassStyle
            VStack(spacing: 16) {
                // Email field
                HolographicTextField(
                    text: $viewModel.email,
                    placeholder: "Email",
                    icon: "envelope.fill",
                    validation: mapValidationState(viewModel.emailValidation),
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    submitLabel: .next,
                    onFocusChange: { focused in
                        if focused { focusedField = .email }
                    },
                    onSubmit: { focusedField = .password }
                )
                .focused($focusedField, equals: .email)

                // Password field
                HolographicTextField(
                    text: $viewModel.password,
                    placeholder: "Password",
                    icon: "lock.fill",
                    isSecure: true,
                    textContentType: .password,
                    submitLabel: .go,
                    showSecureText: $viewModel.showPassword,
                    onFocusChange: { focused in
                        if focused { focusedField = .password }
                    },
                    onSubmit: { signIn() }
                )
                .focused($focusedField, equals: .password)
            }
            .padding(12)
            .background(
                LiquidGlassBackground(
                    cornerRadius: 18,
                    tint: LinearGradient(
                        colors: [Color.white.opacity(0.04), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    strokeColors: [Color.white.opacity(0.22), Color.white.opacity(0.08), Color.clear],
                    lineWidth: 0.75
                )
            )

            // Sign in button
            HolographicButton(
                "Sign In",
                style: .primary,
                icon: "arrow.right",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSignIn
            ) {
                signIn()
            }

            // Secondary actions
            VStack(spacing: 16) {
                HolographicLinkButton("Forgot Password?", color: Color.white.opacity(0.5)) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentScreen = .forgotPassword
                    }
                }

                HStack(spacing: 6) {
                    Text("Don't have an account?")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.45))

                    HolographicLinkButton("Sign Up") {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentScreen = .signUp
                            viewModel.clearForm()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sign Up Form

    private var signUpForm: some View {
        VStack(spacing: 24) {
            // Wrapped inner VStack with LiquidGlassStyle
            VStack(spacing: 16) {
                // Name field (optional)
                HolographicTextField(
                    text: $viewModel.fullName,
                    placeholder: "Full Name (optional)",
                    icon: "person.fill",
                    textContentType: .name,
                    submitLabel: .next,
                    onFocusChange: { focused in
                        if focused { focusedField = .name }
                    },
                    onSubmit: { focusedField = .username }
                )
                .focused($focusedField, equals: .name)

                // Username field (required for Circles)
                HolographicTextField(
                    text: $viewModel.username,
                    placeholder: "Username",
                    icon: "at",
                    validation: mapValidationState(viewModel.usernameValidation),
                    textContentType: .username,
                    submitLabel: .next,
                    onFocusChange: { focused in
                        if focused { focusedField = .username }
                    },
                    onSubmit: { focusedField = .email }
                )
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .username)

                // Email field
                HolographicTextField(
                    text: $viewModel.email,
                    placeholder: "Email",
                    icon: "envelope.fill",
                    validation: mapValidationState(viewModel.emailValidation),
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    submitLabel: .next,
                    onFocusChange: { focused in
                        if focused { focusedField = .email }
                    },
                    onSubmit: { focusedField = .password }
                )
                .focused($focusedField, equals: .email)

                // Password field with strength indicator
                VStack(spacing: 10) {
                    HolographicTextField(
                        text: $viewModel.password,
                        placeholder: "Password",
                        icon: "lock.fill",
                        isSecure: true,
                        textContentType: .newPassword,
                        submitLabel: .next,
                        showSecureText: $viewModel.showPassword,
                        onFocusChange: { focused in
                            if focused { focusedField = .password }
                        },
                        onSubmit: { focusedField = .confirmPassword }
                    )
                    .focused($focusedField, equals: .password)

                    // Holographic password strength
                    if !viewModel.password.isEmpty {
                        HolographicPasswordStrength(
                            strength: viewModel.passwordStrength,
                            password: viewModel.password
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Confirm password
                HolographicTextField(
                    text: $viewModel.confirmPassword,
                    placeholder: "Confirm Password",
                    icon: "lock.fill",
                    isSecure: true,
                    validation: confirmPasswordValidation,
                    textContentType: .newPassword,
                    submitLabel: .go,
                    showSecureText: $viewModel.showPassword,
                    onFocusChange: { focused in
                        if focused { focusedField = .confirmPassword }
                    },
                    onSubmit: { signUp() }
                )
                .focused($focusedField, equals: .confirmPassword)
            }
            .padding(12)
            .background(
                LiquidGlassBackground(
                    cornerRadius: 18,
                    tint: LinearGradient(
                        colors: [Color.white.opacity(0.04), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    strokeColors: [Color.white.opacity(0.22), Color.white.opacity(0.08), Color.clear],
                    lineWidth: 0.75
                )
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.password.isEmpty)

            // Sign up button
            HolographicButton(
                "Create Account",
                style: .primary,
                icon: "sparkles",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSignUp
            ) {
                signUp()
            }

            // Back to sign in
            HStack(spacing: 6) {
                Text("Already have an account?")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.45))

                HolographicLinkButton("Sign In") {
                    HapticsService.shared.selectionFeedback()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentScreen = .signIn
                        viewModel.clearForm()
                    }
                }
            }
        }
    }

    // MARK: - Forgot Password Form

    private var forgotPasswordForm: some View {
        VStack(spacing: 28) {
            // Premium icon with holographic glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.35),
                                Color(red: 0.25, green: 0.85, blue: 0.95).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)

                // Glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 88, height: 88)

                // Prismatic border
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.6),
                                Color(red: 0.35, green: 0.55, blue: 1.0).opacity(0.4),
                                Color(red: 0.25, green: 0.85, blue: 0.95).opacity(0.5),
                                Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.6)
                            ],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 88, height: 88)

                // Icon
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.35, blue: 1.0),
                                Color(red: 0.35, green: 0.55, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Reset Password")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Enter your email and we'll send you a link to reset your password")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            // Wrapped email field with LiquidGlassStyle
            VStack(spacing: 16) {
                HolographicTextField(
                    text: $viewModel.email,
                    placeholder: "Email",
                    icon: "envelope.fill",
                    validation: mapValidationState(viewModel.emailValidation),
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    submitLabel: .send,
                    onFocusChange: { focused in
                        if focused { focusedField = .email }
                    },
                    onSubmit: { resetPassword() }
                )
                .focused($focusedField, equals: .email)
            }
            .padding(12)
            .background(
                LiquidGlassBackground(
                    cornerRadius: 18,
                    tint: LinearGradient(
                        colors: [Color.white.opacity(0.04), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    strokeColors: [Color.white.opacity(0.22), Color.white.opacity(0.08), Color.clear],
                    lineWidth: 0.75
                )
            )

            // Send button
            HolographicButton(
                "Send Reset Link",
                style: .primary,
                icon: "paperplane.fill",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.emailValidation.isValid
            ) {
                resetPassword()
            }

            // Back to sign in
            HolographicButton("Back to Sign In", style: .ghost, icon: "arrow.left", iconPosition: .leading) {
                HapticsService.shared.selectionFeedback()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentScreen = .signIn
                    viewModel.clearForm()
                }
            }
        }
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: 6) {
            Text("By continuing, you agree to our")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.35))

            HStack(spacing: 6) {
                HolographicLinkButton("Terms of Service", color: Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.8)) {
                    // Open terms
                }

                Text("and")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.35))

                HolographicLinkButton("Privacy Policy", color: Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.8)) {
                    // Open privacy
                }
            }
        }
    }

    // MARK: - Actions

    private func signIn() {
        focusedField = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.signInWithEmail()
        }
    }

    private func signUp() {
        focusedField = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.signUpWithEmail()
        }
    }

    private func resetPassword() {
        focusedField = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.sendPasswordReset()
        }
    }

    // MARK: - Auth State Handling

    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .success:
            // Trigger success animation
            HapticsService.shared.celebration()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                orbIntensity = 1.8
                orbState = .celebration
                triggerSuccessBurst = true
            }
        case .error(let message):
            viewModel.error = message
            showError = true
            HapticsService.shared.error()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                orbIntensity = 0.55
                orbState = .idle
            }
        case .signingIn, .signingUp:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                orbIntensity = 1.45
                orbState = .active
            }
        case .idle:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                orbIntensity = focusedField != nil ? 1.35 : 1.0
                orbState = focusedField != nil ? .active : .idle
            }
        }
    }

    // MARK: - Helpers

    private var confirmPasswordValidation: ValidationState {
        guard !viewModel.confirmPassword.isEmpty else { return .idle }
        return viewModel.passwordsMatch ? .valid : .invalid("Passwords don't match")
    }

    /// Map ValidationState - returns input directly since it's the same type
    private func mapValidationState(_ state: ValidationState) -> ValidationState {
        return state
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environment(AppViewModel())
}
