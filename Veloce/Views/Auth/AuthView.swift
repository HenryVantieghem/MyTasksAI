//
//  AuthView.swift
//  Veloce
//
//  Authentication View - Apple Intelligence-Inspired Design
//  Premium auth experience with animated logo, flowing aurora,
//  and crystalline glass components.
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
        case email, password, confirmPassword, name
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Celestial Aurora background
                AuroraBackground.auth

                // Animated Logo - The new hero element
                ZStack {
                    // Success burst effect
                    if triggerSuccessBurst {
                        SuccessLogoBurst(
                            size: logoSize(for: geometry),
                            shouldBurst: $triggerSuccessBurst
                        )
                    } else {
                        // Main animated logo
                        AppLogoView(
                            size: logoSize(for: geometry),
                            isAnimating: true,
                            showParticles: orbState == .processing || orbState == .active
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    }
                }
                .position(
                    x: geometry.size.width / 2,
                    y: logoYPosition(for: geometry)
                )

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Aurora.Layout.spacingXL) {
                        // Spacer for logo
                        Spacer(minLength: logoSpacerHeight(for: geometry))

                        // Logo & Title
                        headerSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : -20)

                        Spacer(minLength: Aurora.Layout.spacingLarge)

                        // Auth form
                        authFormSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)

                        Spacer(minLength: Aurora.Layout.spacing)

                        // Terms
                        termsSection
                            .opacity(showContent ? 1 : 0)
                            .padding(.bottom, Aurora.Layout.spacingXL)
                    }
                    .padding(.horizontal, Aurora.Layout.screenPadding)
                }
            }
        }
        .onAppear {
            withAnimation(Aurora.Animation.spring.delay(0.3)) {
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
        VStack(spacing: Aurora.Layout.spacingSmall) {
            // Editorial thin typography - no circular rings
            Text("MyTasksAI")
                .font(.system(size: 42, weight: .thin, design: .default))
                .foregroundStyle(AppColors.textPrimary)

            Text("AI-Powered Productivity")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Auth Form Section

    @ViewBuilder
    private var authFormSection: some View {
        VStack(spacing: Aurora.Layout.spacingLarge) {
            switch currentScreen {
            case .signIn:
                signInForm
            case .signUp:
                signUpForm
            case .forgotPassword:
                forgotPasswordForm
            }
        }
        .animation(Aurora.Animation.spring, value: currentScreen)
    }

    // MARK: - Sign In Form

    private var signInForm: some View {
        VStack(spacing: Aurora.Layout.spacingLarge) {
            VStack(spacing: Aurora.Layout.spacing) {
                // Email field
                CrystallineTextField(
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
                CrystallineTextField(
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
            AuroraButton(
                "Sign In",
                style: .primary,
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSignIn
            ) {
                signIn()
            }

            // Secondary actions
            VStack(spacing: Aurora.Layout.spacing) {
                AuroraLinkButton("Forgot Password?", color: Aurora.Colors.textTertiary) {
                    withAnimation(Aurora.Animation.spring) {
                        currentScreen = .forgotPassword
                    }
                }

                HStack(spacing: Aurora.Layout.spacingTiny) {
                    Text("Don't have an account?")
                        .font(.system(size: 15))
                        .foregroundStyle(Aurora.Colors.textSecondary)

                    AuroraLinkButton("Sign Up") {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(Aurora.Animation.spring) {
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
        VStack(spacing: Aurora.Layout.spacingLarge) {
            VStack(spacing: Aurora.Layout.spacing) {
                // Name field (optional)
                CrystallineTextField(
                    text: $viewModel.fullName,
                    placeholder: "Full Name (optional)",
                    icon: "person.fill",
                    textContentType: .name,
                    submitLabel: .next,
                    onFocusChange: { focused in
                        if focused { focusedField = .name }
                    },
                    onSubmit: { focusedField = .email }
                )
                .focused($focusedField, equals: .name)

                // Email field
                CrystallineTextField(
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
                VStack(spacing: Aurora.Layout.spacingSmall) {
                    CrystallineTextField(
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

                    // Constellation password strength
                    if !viewModel.password.isEmpty {
                        ConstellationPasswordStrength(
                            strength: viewModel.passwordStrength,
                            password: viewModel.password
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Confirm password
                CrystallineTextField(
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
            .animation(Aurora.Animation.spring, value: viewModel.password.isEmpty)

            // Sign up button
            AuroraButton(
                "Create Account",
                style: .primary,
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSignUp
            ) {
                signUp()
            }

            // Back to sign in
            HStack(spacing: Aurora.Layout.spacingTiny) {
                Text("Already have an account?")
                    .font(.system(size: 15))
                    .foregroundStyle(Aurora.Colors.textSecondary)

                AuroraLinkButton("Sign In") {
                    HapticsService.shared.selectionFeedback()
                    withAnimation(Aurora.Animation.spring) {
                        currentScreen = .signIn
                        viewModel.clearForm()
                    }
                }
            }
        }
    }

    // MARK: - Forgot Password Form

    private var forgotPasswordForm: some View {
        VStack(spacing: Aurora.Layout.spacingLarge) {
            // Icon with aurora glow
            ZStack {
                Circle()
                    .fill(Aurora.Colors.electric.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 12)

                Circle()
                    .fill(Aurora.Colors.cosmicSurface)
                    .frame(width: 80, height: 80)

                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Aurora.Colors.electric)
            }

            VStack(spacing: Aurora.Layout.spacingTiny) {
                Text("Reset Password")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Text("Enter your email and we'll send you a link to reset your password")
                    .font(.system(size: 15))
                    .foregroundStyle(Aurora.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Email field
            CrystallineTextField(
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
            AuroraButton(
                "Send Reset Link",
                style: .primary,
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.emailValidation.isValid
            ) {
                resetPassword()
            }

            // Back to sign in
            AuroraButton("Back to Sign In", style: .ghost, icon: "arrow.left") {
                HapticsService.shared.selectionFeedback()
                withAnimation(Aurora.Animation.spring) {
                    currentScreen = .signIn
                    viewModel.clearForm()
                }
            }
        }
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: Aurora.Layout.spacingTiny) {
            Text("By continuing, you agree to our")
                .font(.system(size: 12))
                .foregroundStyle(Aurora.Colors.textQuaternary)

            HStack(spacing: Aurora.Layout.spacingTiny) {
                AuroraLinkButton("Terms of Service", color: Aurora.Colors.electric.opacity(0.8)) {
                    // Open terms
                }

                Text("and")
                    .font(.system(size: 12))
                    .foregroundStyle(Aurora.Colors.textQuaternary)

                AuroraLinkButton("Privacy Policy", color: Aurora.Colors.electric.opacity(0.8)) {
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
        withAnimation(Aurora.Animation.spring) {
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
