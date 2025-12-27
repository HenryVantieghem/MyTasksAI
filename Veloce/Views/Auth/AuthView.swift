//
//  AuthView.swift
//  Veloce
//
//  Authentication View - Living Cosmos Design
//  Premium auth experience with celestial void background, animated logo,
//  nebula effects, and staggered reveal animations.
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
    @State private var orbState: OrbState = .dormant
    @State private var triggerSuccessBurst = false
    @State private var logoIntensity: Double = 1.0
    @FocusState private var focusedField: AuthField?

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
                // Living Cosmos void background with orb
                VoidBackground.auth

                // Success burst effect
                if triggerSuccessBurst {
                    SuccessLogoBurst(
                        size: logoSize(for: geometry),
                        shouldBurst: $triggerSuccessBurst
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: logoYPosition(for: geometry)
                    )
                }

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Spacer for logo
                        Spacer(minLength: logoSpacerHeight(for: geometry))

                        // Logo & Title
                        headerSection
                            .staggeredReveal(index: 0, isVisible: showContent)

                        Spacer(minLength: Theme.Spacing.xl)

                        // Auth form
                        authFormSection
                            .staggeredReveal(index: 1, isVisible: showContent)

                        Spacer(minLength: Theme.Spacing.lg)

                        // Terms
                        termsSection
                            .staggeredReveal(index: 2, isVisible: showContent)
                            .padding(.bottom, Theme.Spacing.xl)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            // Tap anywhere to dismiss keyboard
            .onTapGesture {
                focusedField = nil
            }
        }
        .onAppear {
            withAnimation(LivingCosmos.Animations.portalOpen.delay(0.3)) {
                showContent = true
            }
        }
        .onChange(of: viewModel.authState) { _, newValue in
            handleAuthStateChange(newValue)
        }
        .onChange(of: focusedField) { _, newField in
            updateOrbState(for: newField)
            updateLogoIntensity(for: newField)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                viewModel.clearError()
                if orbState == .error {
                    orbState = .dormant
                }
                withAnimation(LivingCosmos.Animations.spring) {
                    logoIntensity = 1.0
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

    // MARK: - Logo State

    private var logoScale: CGFloat {
        switch orbState {
        case .processing: return 1.05
        case .success: return 1.1
        case .error: return 0.95
        case .active, .aware: return 1.02
        default: return 1.0
        }
    }

    private var logoOpacity: Double {
        switch orbState {
        case .error: return 0.7
        default: return 1.0
        }
    }

    private func updateLogoIntensity(for field: AuthField?) {
        withAnimation(LivingCosmos.Animations.spring) {
            if field != nil {
                logoIntensity = 1.2
            } else {
                logoIntensity = 1.0
            }
        }
    }

    // MARK: - Layout Calculations

    private func logoSize(for geometry: GeometryProxy) -> LogoSize {
        let height = geometry.size.height
        if height < 700 {
            return .large // 120pt for smaller screens
        } else {
            return .hero // 200pt for larger screens
        }
    }

    private func logoYPosition(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        if height < 700 {
            return height * 0.16
        } else {
            return height * 0.18
        }
    }

    private func logoSpacerHeight(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        if height < 700 {
            return 160
        } else if height < 850 {
            return 200
        } else {
            return 240
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Cosmic display typography
            Text("Veloce")
                .font(.system(size: 42, weight: .thin, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.CelestialColors.starWhite, Theme.CelestialColors.starWhite.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Infinite Momentum")
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(Theme.CelestialColors.starDim)
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
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                // Email field
                CelestialTextField(
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
                CelestialTextField(
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

            // Sign in button
            CosmicButton(
                "Sign In",
                style: .primary,
                icon: "arrow.right",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSignIn
            ) {
                signIn()
            }

            // Secondary actions
            VStack(spacing: Theme.Spacing.md) {
                CosmicLinkButton("Forgot Password?", color: Theme.CelestialColors.starDim) {
                    withAnimation(LivingCosmos.Animations.spring) {
                        currentScreen = .forgotPassword
                    }
                }

                HStack(spacing: Theme.Spacing.xs) {
                    Text("Don't have an account?")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    CosmicLinkButton("Sign Up") {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(LivingCosmos.Animations.spring) {
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
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                // Name field (optional)
                CelestialTextField(
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
                CelestialTextField(
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
                CelestialTextField(
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
                VStack(spacing: Theme.Spacing.sm) {
                    CelestialTextField(
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

                    // Celestial password strength
                    if !viewModel.password.isEmpty {
                        CelestialPasswordStrength(
                            strength: viewModel.passwordStrength,
                            password: viewModel.password
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Confirm password
                CelestialTextField(
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
            .animation(LivingCosmos.Animations.spring, value: viewModel.password.isEmpty)

            // Sign up button
            CosmicButton(
                "Create Account",
                style: .primary,
                icon: "sparkles",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSignUp
            ) {
                signUp()
            }

            // Back to sign in
            HStack(spacing: Theme.Spacing.xs) {
                Text("Already have an account?")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.CelestialColors.starDim)

                CosmicLinkButton("Sign In") {
                    HapticsService.shared.selectionFeedback()
                    withAnimation(LivingCosmos.Animations.spring) {
                        currentScreen = .signIn
                        viewModel.clearForm()
                    }
                }
            }
        }
    }

    // MARK: - Forgot Password Form

    private var forgotPasswordForm: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Icon with nebula glow
            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 12)

                SwiftUI.Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .overlay {
                        SwiftUI.Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Theme.Colors.aiPurple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }

                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("Reset Password")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                Text("Enter your email and we'll send you a link to reset your password")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .multilineTextAlignment(.center)
            }

            // Email field
            CelestialTextField(
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

            // Send button
            CosmicButton(
                "Send Reset Link",
                style: .primary,
                icon: "paperplane.fill",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.emailValidation.isValid
            ) {
                resetPassword()
            }

            // Back to sign in
            CosmicButton("Back to Sign In", style: .ghost, icon: "arrow.left", iconPosition: .leading) {
                HapticsService.shared.selectionFeedback()
                withAnimation(LivingCosmos.Animations.spring) {
                    currentScreen = .signIn
                    viewModel.clearForm()
                }
            }
        }
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("By continuing, you agree to our")
                .font(.system(size: 12))
                .foregroundStyle(Theme.CelestialColors.starGhost)

            HStack(spacing: Theme.Spacing.xs) {
                CosmicLinkButton("Terms of Service", color: Theme.Colors.aiPurple.opacity(0.8)) {
                    // Open terms
                }

                Text("and")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.starGhost)

                CosmicLinkButton("Privacy Policy", color: Theme.Colors.aiPurple.opacity(0.8)) {
                    // Open privacy
                }
            }
        }
    }

    // MARK: - Actions

    private func signIn() {
        focusedField = nil
        orbState = .processing
        Task {
            await viewModel.signInWithEmail()
        }
    }

    private func signUp() {
        focusedField = nil
        orbState = .processing
        Task {
            await viewModel.signUpWithEmail()
        }
    }

    private func resetPassword() {
        focusedField = nil
        orbState = .processing
        Task {
            await viewModel.sendPasswordReset()
        }
    }

    // MARK: - Orb State Management

    private func updateOrbState(for field: AuthField?) {
        withAnimation(LivingCosmos.Animations.spring) {
            if field != nil {
                orbState = .aware
            } else if !viewModel.email.isEmpty || !viewModel.password.isEmpty {
                orbState = .active
            } else {
                orbState = .dormant
            }
        }
    }

    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .success:
            orbState = .success
            // Trigger the success burst animation
            HapticsService.shared.celebration()
            withAnimation(LivingCosmos.Animations.spring) {
                triggerSuccessBurst = true
            }
        case .error(let message):
            orbState = .error
            viewModel.error = message
            showError = true
            HapticsService.shared.error()
        case .signingIn, .signingUp:
            orbState = .processing
        case .idle:
            if focusedField != nil {
                orbState = .aware
            } else {
                orbState = .dormant
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
