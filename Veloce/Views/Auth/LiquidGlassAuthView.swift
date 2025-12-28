//
//  LiquidGlassAuthView.swift
//  Veloce
//
//  Ultra-Premium Liquid Glass Authentication View
//  Features iOS 26 glass morphing transitions between sign-in/sign-up,
//  animated orb states, prismatic effects, and premium haptics.
//

import SwiftUI

// MARK: - Auth Screen

enum AuthScreen: Equatable {
    case signIn
    case signUp
    case forgotPassword
}

// MARK: - Liquid Glass Auth View

struct LiquidGlassAuthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = AuthViewModel()
    @State private var currentScreen: AuthScreen
    @State private var showContent = false
    @State private var orbIntensity: Double = 1.0
    @State private var orbState: EtherealOrbState = .idle
    @State private var showError = false

    @Namespace private var authNamespace
    @FocusState private var focusedField: AuthField?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum AuthField: Hashable {
        case email, password, confirmPassword, name, username
    }

    init(initialScreen: AuthScreen = .signUp) {
        _currentScreen = State(initialValue: initialScreen)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium void background
                VoidBackground.auth

                // Glass particle field
                if !reduceMotion {
                    AuthGlassParticleField(bounds: geometry.size)
                        .opacity(showContent ? 0.6 : 0)
                }

                // Hero Orb with glass effect
                heroOrb(in: geometry)

                // Content scroll
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Spacer for orb
                        Spacer(minLength: orbSpacerHeight(for: geometry))

                        // Header
                        headerSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: showContent)

                        Spacer(minLength: 32)

                        // Glass form container
                        glassFormContainer
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
            updateOrbState(for: newField)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                viewModel.clearError()
                withAnimation(LiquidGlassDesignSystem.Springs.ui) {
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

    // MARK: - Hero Orb

    @ViewBuilder
    private func heroOrb(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Glass halo rings (iOS 26 style)
            if showContent && !reduceMotion {
                glassHaloRings
            }

            // Main orb
            EtherealOrb(
                size: orbSize(for: geometry),
                state: orbState,
                isAnimating: true,
                intensity: orbIntensity,
                showGlow: true
            )
            .glassEffectID("heroOrb", in: authNamespace)
        }
        .position(
            x: geometry.size.width / 2,
            y: orbYPosition(for: geometry)
        )
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.85)
        .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.2), value: showContent)
    }

    @ViewBuilder
    private var glassHaloRings: some View {
        ForEach(0..<3) { index in
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.2 - Double(index) * 0.05),
                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.1 - Double(index) * 0.03),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(
                    width: CGFloat(140 + index * 40),
                    height: CGFloat(140 + index * 40)
                )
                .opacity(orbIntensity > 1.2 ? 0.8 : 0.4)
                .scaleEffect(orbIntensity > 1.2 ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: orbIntensity)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 14) {
            Text("MyTasksAI")
                .font(.system(size: 42, weight: .thin))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("AI-POWERED PRODUCTIVITY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.38))
        }
    }

    // MARK: - Glass Form Container

    @ViewBuilder
    private var glassFormContainer: some View {
        GlassEffectContainer {
            VStack(spacing: LiquidGlassDesignSystem.Spacing.relaxed) {
                // Form content with morphing
                formContent
                    .animation(LiquidGlassDesignSystem.Springs.morph, value: currentScreen)

                // Primary action button
                primaryActionButton

                // Secondary actions
                secondaryActions
            }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private var formContent: some View {
        VStack(spacing: LiquidGlassDesignSystem.Spacing.formField) {
            switch currentScreen {
            case .signIn:
                signInFields
            case .signUp:
                signUpFields
            case .forgotPassword:
                forgotPasswordFields
            }
        }
        .padding(LiquidGlassDesignSystem.Spacing.comfortable)
        .liquidGlassCard(cornerRadius: 20, tint: LiquidGlassDesignSystem.GlassTints.primary)
    }

    // MARK: - Sign In Fields

    @ViewBuilder
    private var signInFields: some View {
        Group {
            LiquidGlassTextField(
                text: $viewModel.email,
                placeholder: "Email",
                icon: "envelope.fill",
                validation: mapValidation(viewModel.emailValidation),
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                submitLabel: .next,
                onFocusChange: { if $0 { focusedField = .email } },
                onSubmit: { focusedField = .password }
            )
            .focused($focusedField, equals: .email)
            .glassMorphTransition(id: "email", namespace: authNamespace)

            LiquidGlassTextField(
                text: $viewModel.password,
                placeholder: "Password",
                icon: "lock.fill",
                isSecure: true,
                textContentType: .password,
                submitLabel: .go,
                showSecureText: $viewModel.showPassword,
                onFocusChange: { if $0 { focusedField = .password } },
                onSubmit: { signIn() }
            )
            .focused($focusedField, equals: .password)
            .glassMorphTransition(id: "password", namespace: authNamespace)
        }
    }

    // MARK: - Sign Up Fields

    @ViewBuilder
    private var signUpFields: some View {
        Group {
            LiquidGlassTextField(
                text: $viewModel.fullName,
                placeholder: "Full Name (optional)",
                icon: "person.fill",
                textContentType: .name,
                submitLabel: .next,
                onFocusChange: { if $0 { focusedField = .name } },
                onSubmit: { focusedField = .username }
            )
            .focused($focusedField, equals: .name)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .opacity
            ))

            LiquidGlassTextField(
                text: $viewModel.username,
                placeholder: "Username",
                icon: "at",
                validation: mapValidation(viewModel.usernameValidation),
                textContentType: .username,
                submitLabel: .next,
                autocapitalization: .never,
                onFocusChange: { if $0 { focusedField = .username } },
                onSubmit: { focusedField = .email }
            )
            .focused($focusedField, equals: .username)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .opacity
            ))

            LiquidGlassTextField(
                text: $viewModel.email,
                placeholder: "Email",
                icon: "envelope.fill",
                validation: mapValidation(viewModel.emailValidation),
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                submitLabel: .next,
                onFocusChange: { if $0 { focusedField = .email } },
                onSubmit: { focusedField = .password }
            )
            .focused($focusedField, equals: .email)
            .glassMorphTransition(id: "email", namespace: authNamespace)

            VStack(spacing: 10) {
                LiquidGlassTextField(
                    text: $viewModel.password,
                    placeholder: "Password",
                    icon: "lock.fill",
                    isSecure: true,
                    textContentType: .newPassword,
                    submitLabel: .next,
                    showSecureText: $viewModel.showPassword,
                    onFocusChange: { if $0 { focusedField = .password } },
                    onSubmit: { focusedField = .confirmPassword }
                )
                .focused($focusedField, equals: .password)
                .glassMorphTransition(id: "password", namespace: authNamespace)

                if !viewModel.password.isEmpty {
                    LiquidGlassPasswordStrength(
                        strength: mapPasswordStrength(viewModel.passwordStrength),
                        password: viewModel.password
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            LiquidGlassTextField(
                text: $viewModel.confirmPassword,
                placeholder: "Confirm Password",
                icon: "lock.fill",
                isSecure: true,
                validation: confirmPasswordValidation,
                textContentType: .newPassword,
                submitLabel: .go,
                showSecureText: $viewModel.showPassword,
                onFocusChange: { if $0 { focusedField = .confirmPassword } },
                onSubmit: { signUp() }
            )
            .focused($focusedField, equals: .confirmPassword)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }

    // MARK: - Forgot Password Fields

    @ViewBuilder
    private var forgotPasswordFields: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.35),
                                LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)

                Circle()
                    .liquidGlass(in: Circle())
                    .frame(width: 88, height: 88)

                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Theme.VibrantCelestial.aiGradient)
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

            LiquidGlassTextField(
                text: $viewModel.email,
                placeholder: "Email",
                icon: "envelope.fill",
                validation: mapValidation(viewModel.emailValidation),
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                submitLabel: .send,
                onFocusChange: { if $0 { focusedField = .email } },
                onSubmit: { resetPassword() }
            )
            .focused($focusedField, equals: .email)
            .glassMorphTransition(id: "email", namespace: authNamespace)
        }
    }

    // MARK: - Primary Action Button

    @ViewBuilder
    private var primaryActionButton: some View {
        switch currentScreen {
        case .signIn:
            LiquidGlassButton.primary(
                "Sign In",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSignIn
            ) {
                signIn()
            }

        case .signUp:
            LiquidGlassButton(
                "Create Account",
                style: .primary,
                icon: "sparkles",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSignUp
            ) {
                signUp()
            }

        case .forgotPassword:
            LiquidGlassButton(
                "Send Reset Link",
                style: .primary,
                icon: "paperplane.fill",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.emailValidation.isValid
            ) {
                resetPassword()
            }
        }
    }

    // MARK: - Secondary Actions

    @ViewBuilder
    private var secondaryActions: some View {
        VStack(spacing: 16) {
            switch currentScreen {
            case .signIn:
                Button {
                    switchScreen(to: .forgotPassword)
                } label: {
                    Text("Forgot Password?")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                HStack(spacing: 6) {
                    Text("Don't have an account?")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.45))

                    Button {
                        switchScreen(to: .signUp)
                    } label: {
                        Text("Sign Up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                    }
                }

            case .signUp:
                HStack(spacing: 6) {
                    Text("Already have an account?")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.45))

                    Button {
                        switchScreen(to: .signIn)
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                    }
                }

            case .forgotPassword:
                LiquidGlassButton.ghost(
                    "Back to Sign In",
                    icon: "arrow.left",
                    iconPosition: .leading
                ) {
                    switchScreen(to: .signIn)
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
                Button("Terms of Service") {}
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.8))

                Text("and")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.35))

                Button("Privacy Policy") {}
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.8))
            }
        }
    }

    // MARK: - Layout Calculations

    private func orbSize(for geometry: GeometryProxy) -> LogoSize {
        geometry.size.height < 700 ? .large : .hero
    }

    private func orbYPosition(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height < 700 ? geometry.size.height * 0.14 : geometry.size.height * 0.16
    }

    private func orbSpacerHeight(for geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        if height < 700 { return 180 }
        else if height < 850 { return 220 }
        else { return 260 }
    }

    // MARK: - Actions

    private func signIn() {
        focusedField = nil
        withAnimation(LiquidGlassDesignSystem.Springs.ui) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.signInWithEmail()
        }
    }

    private func signUp() {
        focusedField = nil
        withAnimation(LiquidGlassDesignSystem.Springs.ui) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.signUpWithEmail()
        }
    }

    private func resetPassword() {
        focusedField = nil
        withAnimation(LiquidGlassDesignSystem.Springs.ui) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.sendPasswordReset()
        }
    }

    private func switchScreen(to screen: AuthScreen) {
        HapticsService.shared.selectionFeedback()
        focusedField = nil

        withAnimation(LiquidGlassDesignSystem.Springs.morph) {
            currentScreen = screen
            viewModel.clearForm()
        }
    }

    // MARK: - State Handling

    private func updateOrbState(for field: AuthField?) {
        withAnimation(LiquidGlassDesignSystem.Springs.focus) {
            if field != nil {
                orbIntensity = 1.35
                orbState = .active
            } else {
                orbIntensity = 1.0
                orbState = .idle
            }
        }
    }

    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .success:
            HapticsService.shared.dopamineBurst()
            withAnimation(LiquidGlassDesignSystem.Springs.bouncy) {
                orbIntensity = 1.8
                orbState = .celebration
            }

        case .error(let message):
            viewModel.error = message
            showError = true
            HapticsService.shared.error()
            withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                orbIntensity = 0.55
                orbState = .idle
            }

        case .signingIn, .signingUp:
            withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                orbIntensity = 1.45
                orbState = .active
            }

        case .idle:
            withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                orbIntensity = focusedField != nil ? 1.35 : 1.0
                orbState = focusedField != nil ? .active : .idle
            }
        }
    }

    // MARK: - Validation Helpers

    private var confirmPasswordValidation: GlassValidationState {
        guard !viewModel.confirmPassword.isEmpty else { return .idle }
        return viewModel.passwordsMatch ? .valid : .invalid("Passwords don't match")
    }

    private func mapValidation(_ state: ValidationState) -> GlassValidationState {
        switch state {
        case .idle: return .idle
        case .validating: return .validating
        case .valid: return .valid
        case .invalid(let msg): return .invalid(msg)
        }
    }

    private func mapPasswordStrength(_ strength: PasswordStrength) -> LiquidGlassPasswordStrength.PasswordStrength {
        switch strength {
        case .weak: return .weak
        case .fair: return .fair
        case .good: return .good
        case .strong: return .strong
        }
    }
}

// MARK: - Auth Glass Particle Field (distinct from CosmicSplashScreen.GlassParticleField)

private struct AuthGlassParticleField: View {
    let bounds: CGSize

    @State private var particles: [AuthGlassParticle] = []
    @State private var floatPhase: Double = 0

    private let etherealColors: [Color] = [
        LiquidGlassDesignSystem.VibrantAccents.electricCyan,
        LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
        LiquidGlassDesignSystem.VibrantAccents.nebulaPink,
        LiquidGlassDesignSystem.VibrantAccents.auroraGreen
    ]

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let yOffset = sin(floatPhase + particle.phaseOffset) * particle.amplitude

                let center = CGPoint(
                    x: particle.position.x,
                    y: particle.position.y + yOffset
                )

                // Glass particle
                let rect = CGRect(
                    x: center.x - particle.size / 2,
                    y: center.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )

                // Core
                context.fill(
                    Circle().path(in: rect),
                    with: .color(particle.color.opacity(particle.opacity * 0.4))
                )

                // Glow
                let glowRect = rect.insetBy(dx: -particle.size * 0.3, dy: -particle.size * 0.3)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(particle.color.opacity(particle.opacity * 0.15))
                )
            }
        }
        .onAppear {
            generateParticles()
            startFloating()
        }
    }

    private func generateParticles() {
        particles = (0..<30).map { _ in
            AuthGlassParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: CGFloat.random(in: 0...bounds.height)
                ),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.7),
                color: etherealColors.randomElement() ?? .white,
                phaseOffset: Double.random(in: 0...(.pi * 2)),
                amplitude: CGFloat.random(in: 10...30)
            )
        }
    }

    private func startFloating() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            floatPhase = .pi * 2
        }
    }
}

private struct AuthGlassParticle {
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let color: Color
    let phaseOffset: Double
    let amplitude: CGFloat
}

// MARK: - Preview

#Preview {
    LiquidGlassAuthView(initialScreen: .signUp)
        .environment(AppViewModel())
}
