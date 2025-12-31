//
//  LiquidGlassAuthView.swift
//  Veloce
//
//  Utopian Design System - Authentication Experience
//  "Cosmic Consciousness Awakening"
//  Living orb that recognizes you, portal-style sign-in effects,
//  Utopian wave backgrounds, and prismatic glass forms.
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
                // Utopian wave background
                AuroraAnimatedWaveBackground(
                    intensity: 0.35,
                    showParticles: false,
                    customColors: [UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.focusActive]
                )
                .ignoresSafeArea()

                // Utopian firefly particles
                if !reduceMotion {
                    AuroraFireflyField(
                        count: 30,
                        colors: [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.aiPurple]
                    )
                    .opacity(showContent ? 0.5 : 0)
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
                withAnimation(CosmicMotion.Springs.ui) {
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
        // Utopian prismatic halo rings
        ForEach(0..<4) { index in
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            UtopianDesignFallback.Colors.focusActive.opacity(0.25 - Double(index) * 0.05),
                            UtopianDesignFallback.Colors.aiPurple.opacity(0.2 - Double(index) * 0.04),
                            UtopianDesignFallback.Colors.aiPurple.opacity(0.15 - Double(index) * 0.03),
                            UtopianDesignFallback.Colors.focusActive.opacity(0.25 - Double(index) * 0.05)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.5 - CGFloat(index) * 0.2
                )
                .frame(
                    width: CGFloat(130 + index * 35),
                    height: CGFloat(130 + index * 35)
                )
                .blur(radius: CGFloat(index) * 0.5)
                .opacity(orbIntensity > 1.2 ? 0.9 : 0.5)
                .scaleEffect(orbIntensity > 1.2 ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: orbIntensity)
        }
    }

    // MARK: - Utopian Header Section

    private var headerSection: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.sm) {
            Text("MyTasksAI")
                .font(UtopianDesignFallback.Typography.display)
                .tracking(3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: UtopianDesignFallback.Colors.focusActive.opacity(0.3), radius: 20)

            Text("AI-POWERED PRODUCTIVITY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [UtopianDesignFallback.Colors.focusActive.opacity(0.6), UtopianDesignFallback.Colors.aiPurple.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    // MARK: - Glass Form Container

    @ViewBuilder
    private var glassFormContainer: some View {
        GlassEffectContainer {
            VStack(spacing: CosmicWidget.Spacing.relaxed) {
                // Form content with morphing
                formContent
                    .animation(CosmicMotion.Springs.morph, value: currentScreen)

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
        VStack(spacing: CosmicWidget.Spacing.formField) {
            switch currentScreen {
            case .signIn:
                signInFields
            case .signUp:
                signUpFields
            case .forgotPassword:
                forgotPasswordFields
            }
        }
        .padding(CosmicWidget.Spacing.comfortable)
        .liquidGlassCard(cornerRadius: 20, tint: CosmicWidget.Widget.electricCyan.opacity(0.1))
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

    // MARK: - Utopian Forgot Password Fields

    @ViewBuilder
    private var forgotPasswordFields: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.lg) {
            // Utopian icon with glow
            ZStack {
                // Multi-layer glow bloom
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                UtopianDesignFallback.Colors.aiPurple.opacity(0.4),
                                UtopianDesignFallback.Colors.focusActive.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                // Glass circle
                Group {
                    if #available(iOS 26.0, *) {
                        Color.clear
                            .frame(width: 88, height: 88)
                            .glassEffect(.regular, in: Circle())
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 88, height: 88)
                    }
                }

                Image(systemName: "envelope.badge.shield.half.filled")
                    .dynamicTypeFont(base: 34, weight: .light)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: UtopianDesignFallback.Spacing.xs) {
                Text("Reset Password")
                    .font(UtopianDesignFallback.Typography.title2)
                    .foregroundStyle(.white)

                Text("Enter your email and we'll send you a link to reset your password")
                    .font(UtopianDesignFallback.Typography.body)
                    .foregroundStyle(.white.opacity(0.7))
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

    // MARK: - Utopian Secondary Actions

    @ViewBuilder
    private var secondaryActions: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.md) {
            switch currentScreen {
            case .signIn:
                Button {
                    switchScreen(to: .forgotPassword)
                } label: {
                    Text("Forgot Password?")
                        .font(UtopianDesignFallback.Typography.callout)
                        .foregroundStyle(.white.opacity(0.5))
                }

                HStack(spacing: 6) {
                    Text("Don't have an account?")
                        .font(UtopianDesignFallback.Typography.callout)
                        .foregroundStyle(.white.opacity(0.5))

                    Button {
                        switchScreen(to: .signUp)
                    } label: {
                        Text("Sign Up")
                            .dynamicTypeFont(base: 15, weight: .semibold)
                            .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
                    }
                }

            case .signUp:
                HStack(spacing: 6) {
                    Text("Already have an account?")
                        .font(UtopianDesignFallback.Typography.callout)
                        .foregroundStyle(.white.opacity(0.5))

                    Button {
                        switchScreen(to: .signIn)
                    } label: {
                        Text("Sign In")
                            .dynamicTypeFont(base: 15, weight: .semibold)
                            .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
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

    // MARK: - Utopian Terms Section

    private var termsSection: some View {
        VStack(spacing: 6) {
            Text("By continuing, you agree to our")
                .font(UtopianDesignFallback.Typography.caption2)
                .foregroundStyle(.white.opacity(0.3))

            HStack(spacing: 6) {
                Button("Terms of Service") {}
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple.opacity(0.8))

                Text("and")
                    .font(UtopianDesignFallback.Typography.caption2)
                    .foregroundStyle(.white.opacity(0.3))

                Button("Privacy Policy") {}
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple.opacity(0.8))
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

    // MARK: - Utopian Actions

    private func signIn() {
        focusedField = nil
        AuroraSoundEngine.shared.play(.aiProcessing)
        HapticsService.shared.impact(.medium)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.signInWithEmail()
        }
    }

    private func signUp() {
        focusedField = nil
        AuroraSoundEngine.shared.play(.aiProcessing)
        HapticsService.shared.impact(.medium)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.signUpWithEmail()
        }
    }

    private func resetPassword() {
        focusedField = nil
        AuroraSoundEngine.shared.play(.tabSwitch)
        HapticsService.shared.impact(.light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            orbIntensity = 1.5
        }
        Task {
            await viewModel.sendPasswordReset()
        }
    }

    private func switchScreen(to screen: AuthScreen) {
        AuroraSoundEngine.shared.play(.dismiss)
        HapticsService.shared.selectionFeedback()
        focusedField = nil

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentScreen = screen
            viewModel.clearForm()
        }
    }

    // MARK: - Utopian State Handling

    private func updateOrbState(for field: AuthField?) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
            // Epic portal opening celebration
            AuroraSoundEngine.shared.portalOpen()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                orbIntensity = 1.8
                orbState = .celebration
            }

        case .error(let message):
            viewModel.error = message
            showError = true
            AuroraSoundEngine.shared.play(.error)
            HapticsService.shared.notification(.error)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                orbIntensity = 0.55
                orbState = .idle
            }

        case .signingIn, .signingUp:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                orbIntensity = 1.45
                orbState = .active
            }

        case .idle:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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

// MARK: - Utopian Auth Particle Field (Legacy - now using AuroraFireflyField)

private struct AuthGlassParticleField: View {
    let bounds: CGSize

    @State private var particles: [AuthGlassParticle] = []
    @State private var floatPhase: Double = 0

    private let etherealColors: [Color] = [
        UtopianDesignFallback.Colors.focusActive,
        UtopianDesignFallback.Colors.aiPurple,
        UtopianDesignFallback.Colors.aiPurple,
        UtopianDesignFallback.Colors.completed
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
