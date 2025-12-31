//
//  LiquidGlassAuthViews.swift
//  MyTasksAI
//
//  Premium Liquid Glass Authentication & Onboarding Views
//  Sign In, Sign Up, and Onboarding with native iOS 26 glass effects
//

import SwiftUI

// MARK: - Liquid Glass Sign In View

struct LiquidGlassSignInView: View {
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: SignInField?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onSignIn: (String, String) async throws -> Void
    let onSignUpTapped: () -> Void
    let onForgotPassword: () -> Void
    
    enum SignInField {
        case email, password
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium cosmic background with stars
                cosmicBackground
                
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section with ethereal orb
                        heroSection
                            .padding(.top, geometry.safeAreaInsets.top + 40)
                            .padding(.bottom, 60)
                        
                        // Glass form container
                        VStack(spacing: 20) {
                            // Email field
                            LiquidGlassTextField(
                                text: $email,
                                placeholder: "Email",
                                icon: "envelope",
                                onSubmit: {
                                    focusedField = .password
                                }
                            )
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)

                            // Password field
                            LiquidGlassSecureField(
                                placeholder: "Password",
                                text: $password,
                                isFocused: focusedField == .email,
                                onSubmit: {
                                    Task { await signIn() }
                                }
                            )
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            
                            // Forgot password
                            HStack {
                                Spacer()
                                Button(action: onForgotPassword) {
                                    Text("Forgot Password?")
                                        .dynamicTypeFont(base: 14, weight: .medium)
                                        .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                                }
                            }
                            
                            // Sign in button
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(height: 56)
                            } else {
                                LiquidGlassButton.primary("Sign In", icon: "arrow.right") {
                                    Task { await signIn() }
                                }
                            }
                            
                            // Error message
                            if showError {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .dynamicTypeFont(base: 14)
                                    Text(errorMessage)
                                        .dynamicTypeFont(base: 14)
                                }
                                .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.nebulaPink)
                                .padding(12)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 1)
                                Text("or")
                                    .dynamicTypeFont(base: 14)
                                    .foregroundStyle(.white.opacity(0.5))
                                Rectangle()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Sign up button
                            LiquidGlassButton.secondary("Create Account") {
                                onSignUpTapped()
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .ignoresSafeArea()
    }
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Ethereal orb
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                EtherealOrb(
                    size: .large,
                    state: .active,
                    isAnimating: true,
                    intensity: 1.0,
                    showGlow: true
                )
            }
            
            // Title
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .dynamicTypeFont(base: 36, weight: .thin)
                    .foregroundStyle(.white)
                
                Text("Sign in to continue your journey")
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
    
    private var cosmicBackground: some View {
        ZStack {
            // Base void gradient
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.01, blue: 0.02),
                    Color(red: 0.02, green: 0.02, blue: 0.035),
                    Color(red: 0.03, green: 0.02, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Nebula accents
            RadialGradient(
                colors: [
                    LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.15),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            
            RadialGradient(
                colors: [
                    LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.1),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 350
            )
            
            // Star field (simplified)
            CosmicStarField(starCount: 30)
        }
    }
    
    private func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            showError(message: "Please enter your email and password")
            return
        }
        
        isLoading = true
        showError = false
        
        do {
            try await onSignIn(email, password)
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func showError(message: String) {
        errorMessage = message
        withAnimation(LiquidGlassDesignSystem.Springs.ui) {
            showError = true
        }
        
        HapticsService.shared.error()

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                showError = false
            }
        }
    }
}

// MARK: - Liquid Glass Sign Up View

struct LiquidGlassSignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: SignUpField?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var acceptedTerms = false
    
    let onSignUp: (String, String, String) async throws -> Void
    let onSignInTapped: () -> Void
    
    enum SignUpField {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium cosmic background
                cosmicBackground
                
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section
                        heroSection
                            .padding(.top, geometry.safeAreaInsets.top + 40)
                            .padding(.bottom, 40)
                        
                        // Glass form container
                        VStack(spacing: 20) {
                            // Name field
                            LiquidGlassTextField(
                                text: $name,
                                placeholder: "Full Name",
                                icon: "person",
                                onSubmit: {
                                    focusedField = .email
                                }
                            )
                            .textContentType(.name)
                            .focused($focusedField, equals: .name)
                            
                            // Email field
                            LiquidGlassTextField(
                                text: $email,
                                placeholder: "Email",
                                icon: "envelope",
                                onSubmit: {
                                    focusedField = .password
                                }
                            )
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)

                            // Password field
                            LiquidGlassSecureField(
                                placeholder: "Password",
                                text: $password,
                                isFocused: focusedField == .email,
                                onSubmit: {
                                    focusedField = .confirmPassword
                                }
                            )
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            
                            // Confirm password field
                            LiquidGlassSecureField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                isFocused: focusedField == .confirmPassword,
                                onSubmit: {
                                    Task { await signUp() }
                                }
                            )
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            
                            // Terms acceptance
                            LiquidGlassToggleRow(
                                title: "Accept Terms & Privacy",
                                subtitle: "By creating an account, you agree to our Terms of Service and Privacy Policy",
                                icon: "checkmark.shield.fill",
                                color: LiquidGlassDesignSystem.VibrantAccents.auroraGreen,
                                isOn: $acceptedTerms
                            )
                            
                            // Sign up button
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(height: 56)
                            } else {
                                LiquidGlassButton.primary("Create Account", icon: "sparkles") {
                                    Task { await signUp() }
                                }
                                .disabled(!acceptedTerms)
                                .opacity(acceptedTerms ? 1 : 0.5)
                            }
                            
                            // Error message
                            if showError {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .dynamicTypeFont(base: 14)
                                    Text(errorMessage)
                                        .dynamicTypeFont(base: 14)
                                }
                                .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.nebulaPink)
                                .padding(12)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 1)
                                Text("or")
                                    .dynamicTypeFont(base: 14)
                                    .foregroundStyle(.white.opacity(0.5))
                                Rectangle()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Sign in button
                            LiquidGlassButton.secondary("Sign In to Existing Account") {
                                onSignInTapped()
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .ignoresSafeArea()
    }
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Ethereal orb
            ZStack {
                // Multi-layer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidGlassDesignSystem.VibrantAccents.auroraGreen.opacity(0.25),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 25)
                
                EtherealOrb(
                    size: .large,
                    state: .active,
                    isAnimating: true,
                    intensity: 1.0,
                    showGlow: true
                )
            }
            
            // Title
            VStack(spacing: 8) {
                Text("Begin Your Journey")
                    .dynamicTypeFont(base: 36, weight: .thin)
                    .foregroundStyle(.white)
                
                Text("Create your account to unlock peak productivity")
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var cosmicBackground: some View {
        ZStack {
            // Base void gradient
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.01, blue: 0.02),
                    Color(red: 0.02, green: 0.02, blue: 0.035),
                    Color(red: 0.03, green: 0.02, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Nebula accents
            RadialGradient(
                colors: [
                    LiquidGlassDesignSystem.VibrantAccents.auroraGreen.opacity(0.12),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            
            RadialGradient(
                colors: [
                    LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.1),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 350
            )
            
            // Star field
            CosmicStarField(starCount: 30)
        }
    }
    
    private func signUp() async {
        // Validation
        guard !name.isEmpty else {
            showError(message: "Please enter your name")
            return
        }
        
        guard !email.isEmpty else {
            showError(message: "Please enter your email")
            return
        }
        
        guard !password.isEmpty else {
            showError(message: "Please enter a password")
            return
        }
        
        guard password.count >= 8 else {
            showError(message: "Password must be at least 8 characters")
            return
        }
        
        guard password == confirmPassword else {
            showError(message: "Passwords don't match")
            return
        }
        
        guard acceptedTerms else {
            showError(message: "Please accept the Terms and Privacy Policy")
            return
        }
        
        isLoading = true
        showError = false
        
        do {
            try await onSignUp(name, email, password)
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func showError(message: String) {
        errorMessage = message
        withAnimation(LiquidGlassDesignSystem.Springs.ui) {
            showError = true
        }
        
        HapticsService.shared.error()

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                showError = false
            }
        }
    }
}

// MARK: - Liquid Glass Secure Field

/// Secure text field with show/hide toggle
struct LiquidGlassSecureField: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    let onSubmit: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .textContentType(.password)
                } else {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                }
            }
            .dynamicTypeFont(base: 17)
            .foregroundStyle(.white)
            .tint(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
            .submitLabel(.done)
            .onSubmit(onSubmit)
            
            Button {
                withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                    isVisible.toggle()
                }
                HapticsService.shared.lightImpact()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: isFocused ? [
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.6),
                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.4)
                        ] : [
                            .white.opacity(0.2),
                            .white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isFocused ? 1.5 : 0.5
                )
        }
        .shadow(
            color: isFocused ? LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.3) : .black.opacity(0.2),
            radius: isFocused ? 20 : 12,
            y: isFocused ? 10 : 6
        )
        .animation(LiquidGlassDesignSystem.Springs.ui, value: isFocused)
    }
}

// MARK: - Cosmic Star Field

struct CosmicStarField: View {
    let starCount: Int
    @State private var stars: [AuthCosmicStar] = []
    
    var body: some View {
        Canvas { context, size in
            for star in stars {
                let rect = CGRect(
                    x: star.position.x - star.size / 2,
                    y: star.position.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )
                
                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(star.baseOpacity))
                )
            }
        }
        .onAppear {
            stars = AuthCosmicStar.generateField(
                count: starCount,
                in: CGSize(width: 400, height: 900)
            )
        }
    }
}

// MARK: - Auth Cosmic Star Model

struct AuthCosmicStar: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let twinkleDelay: Double

    static func generateField(count: Int, in size: CGSize) -> [AuthCosmicStar] {
        (0..<count).map { _ in
            AuthCosmicStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1...2.5),
                baseOpacity: Double.random(in: 0.3...0.8),
                twinkleDelay: Double.random(in: 0...2)
            )
        }
    }
}

// MARK: - Previews

#Preview("Sign In") {
    LiquidGlassSignInView(
        onSignIn: { _, _ in
            try await Task.sleep(nanoseconds: 1_000_000_000)
        },
        onSignUpTapped: {},
        onForgotPassword: {}
    )
}

#Preview("Sign Up") {
    LiquidGlassSignUpView(
        onSignUp: { _, _, _ in
            try await Task.sleep(nanoseconds: 1_000_000_000)
        },
        onSignInTapped: {}
    )
}
