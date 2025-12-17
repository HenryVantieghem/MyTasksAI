//
//  AuthView.swift
//  Veloce
//
//  Authentication View - Sign In / Sign Up Flow
//  Beautiful glass morphism design with Apple & Google sign-in
//

import SwiftUI
import AuthenticationServices

// MARK: - Auth View

struct AuthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = AuthViewModel()
    @State private var showEmailSignIn = false
    @State private var showError = false

    var body: some View {
        ZStack {
            // Background
            IridescentBackground(intensity: 0.6)
                .ignoresSafeArea()

            // Content
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // Logo & Title
                headerSection

                Spacer()

                // Auth buttons
                authButtonsSection

                // Terms
                termsSection
                    .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
        }
        .onChange(of: viewModel.error) { _, newValue in
            showError = newValue != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error ?? "")
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInSheet(viewModel: viewModel)
        }
        .task {
            // Connect auth success to app state refresh
            viewModel.onAuthSuccess = {
                Task {
                    await appViewModel.checkAuthenticationState()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Animated logo
            ZStack {
                IridescentOrb(size: 120)
                    .blur(radius: 30)

                Image(systemName: "sparkles")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(Theme.Colors.accent)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Veloce")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("AI-Powered Productivity")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Auth Buttons Section

    private var authButtonsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Sign in with Apple
            SignInWithAppleButton(
                onRequest: { request in
                    viewModel.configureAppleSignIn(request)
                },
                onCompletion: { result in
                    Task {
                        await viewModel.handleAppleSignIn(result)
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: DesignTokens.Height.button)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.button))

            // Sign in with Google
            Button {
                Task {
                    await viewModel.signInWithGoogle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text("Continue with Google")
                        .font(Theme.Typography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Height.button)
                .background(Theme.Colors.cardBackground)
                .foregroundStyle(Theme.Colors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.button))
            }

            // Divider
            HStack {
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                Text("or")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.sm)

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
            }

            // Email sign in
            Button {
                showEmailSignIn = true
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                    Text("Continue with Email")
                        .font(Theme.Typography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Height.button)
                .foregroundStyle(Theme.Colors.accent)
            }
            .buttonStyle(.secondary)
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Theme.Colors.accent)
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.Colors.background.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            }
        }
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("By continuing, you agree to our")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            HStack(spacing: Theme.Spacing.xs) {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)

                Text("and")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Button("Privacy Policy") {
                    // Open privacy
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)
            }
        }
    }
}

// MARK: - Email Sign In Sheet

struct EmailSignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AuthViewModel

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email, password, confirmPassword
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Mode toggle
                        Picker("Mode", selection: $isSignUp) {
                            Text("Sign In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(.segmented)

                        // Form fields
                        VStack(spacing: Theme.Spacing.md) {
                            // Email
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Email")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)

                                TextField("your@email.com", text: $email)
                                    .textFieldStyle(GlassTextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                            }

                            // Password
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Password")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)

                                SecureField("••••••••", text: $password)
                                    .textFieldStyle(GlassTextFieldStyle())
                                    .textContentType(isSignUp ? .newPassword : .password)
                                    .focused($focusedField, equals: .password)
                            }

                            // Confirm password (sign up only)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Confirm Password")
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.Colors.textSecondary)

                                    SecureField("••••••••", text: $confirmPassword)
                                        .textFieldStyle(GlassTextFieldStyle())
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                }
                            }
                        }

                        // Submit button
                        Button {
                            Task {
                                if isSignUp {
                                    guard password == confirmPassword else {
                                        viewModel.error = "Passwords don't match"
                                        return
                                    }
                                    await viewModel.signUp(email: email, password: password)
                                } else {
                                    await viewModel.signIn(email: email, password: password)
                                }

                                if viewModel.error == nil {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.primary)
                        .disabled(!isValid || viewModel.isLoading)

                        // Forgot password (sign in only)
                        if !isSignUp {
                            Button("Forgot Password?") {
                                Task {
                                    await viewModel.resetPassword(email: email)
                                }
                            }
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.accent)
                        }

                        Spacer()
                    }
                    .padding(Theme.Spacing.screenPadding)
                }
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var isValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 8  // Match AuthViewModel validation

        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        }
        return emailValid && passwordValid
    }
}

// MARK: - Preview
// Note: IridescentOrb is defined in Core/Design/IridescentGlow.swift

#Preview {
    AuthView()
}
