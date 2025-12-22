//
//  AuthViewModel.swift
//  Veloce
//
//  Auth View Model - Authentication State Management
//  Handles email sign in, sign up, and authentication flows
//

import Foundation
import SwiftUI
import Supabase
import Auth

// MARK: - Auth State

enum AuthState: Equatable {
    case idle
    case signingIn
    case signingUp
    case success
    case error(String)
}

// MARK: - Validation State

enum ValidationState: Equatable {
    case idle
    case validating
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

// MARK: - Password Strength

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
        case .weak: return Theme.CelestialColors.errorNebula
        case .fair: return Theme.CelestialColors.warningNebula
        case .good: return Theme.CelestialColors.nebulaGlow
        case .strong: return Theme.CelestialColors.successNebula
        }
    }
}

// MARK: - Auth View Model

@MainActor
@Observable
final class AuthViewModel {
    // MARK: State
    private(set) var authState: AuthState = .idle
    private(set) var isLoading: Bool = false

    // MARK: Error
    var error: String?

    // MARK: Form State
    var email: String = "" {
        didSet { validateEmailRealTime() }
    }
    var password: String = "" {
        didSet { calculatePasswordStrength() }
    }
    var confirmPassword: String = ""
    var fullName: String = ""
    var showPassword: Bool = false

    // MARK: Validation State
    private(set) var emailValidation: ValidationState = .idle
    private(set) var passwordStrength: PasswordStrength = .weak

    // MARK: Services
    private let supabase = SupabaseService.shared
    private let haptics = HapticsService.shared

    // MARK: Callbacks
    var onAuthSuccess: (() -> Void)?

    // MARK: Initialization
    init() {}

    // MARK: - Email Validation

    /// Validate email format in real-time
    func validateEmailRealTime() {
        guard !email.isEmpty else {
            emailValidation = .idle
            return
        }

        emailValidation = .validating

        // Simple debounce - validate immediately for now
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        if email.range(of: emailRegex, options: .regularExpression) != nil {
            emailValidation = .valid
        } else {
            emailValidation = .invalid("Please enter a valid email")
        }
    }

    // MARK: - Password Strength

    /// Calculate password strength based on criteria
    func calculatePasswordStrength() {
        guard !password.isEmpty else {
            passwordStrength = .weak
            return
        }

        var score = 0

        // Length check
        if password.count >= 8 { score += 1 }

        // Uppercase check
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }

        // Number check
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }

        // Special character check
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }

        passwordStrength = PasswordStrength(rawValue: max(1, score)) ?? .weak
    }

    // MARK: - Email Sign In

    /// Sign in with email and password
    func signInWithEmail() async {
        guard emailValidation.isValid else {
            authState = .error("Please enter a valid email address")
            haptics.error()
            return
        }

        guard !password.isEmpty else {
            authState = .error("Please enter your password")
            haptics.error()
            return
        }

        guard supabase.isConfigured else {
            authState = .error(supabase.lastError ?? "Supabase is not configured. Please check your Secrets.plist file.")
            haptics.error()
            return
        }

        authState = .signingIn
        isLoading = true

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            try await client.auth.signIn(
                email: email,
                password: password
            )

            authState = .success
            haptics.taskComplete()
            onAuthSuccess?()
        } catch {
            authState = .error(error.localizedDescription)
            haptics.error()
        }
    }

    // MARK: - Email Sign Up

    /// Sign up with email and password
    func signUpWithEmail() async {
        guard emailValidation.isValid else {
            authState = .error("Please enter a valid email address")
            haptics.error()
            return
        }

        guard password.count >= 8 else {
            authState = .error("Password must be at least 8 characters")
            haptics.error()
            return
        }

        guard password == confirmPassword else {
            authState = .error("Passwords don't match")
            haptics.error()
            return
        }

        guard supabase.isConfigured else {
            authState = .error(supabase.lastError ?? "Supabase is not configured. Please check your Secrets.plist file.")
            haptics.error()
            return
        }

        authState = .signingUp
        isLoading = true

        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            try await client.auth.signUp(
                email: email,
                password: password,
                data: fullName.isEmpty ? nil : ["full_name": .string(fullName)]
            )

            authState = .success
            haptics.taskComplete()
            onAuthSuccess?()
        } catch {
            authState = .error(error.localizedDescription)
            haptics.error()
        }
    }

    // MARK: - Password Reset

    /// Send password reset email
    func sendPasswordReset() async {
        guard emailValidation.isValid else {
            authState = .error("Please enter a valid email address")
            haptics.error()
            return
        }

        guard supabase.isConfigured else {
            authState = .error(supabase.lastError ?? "Supabase is not configured. Please check your Secrets.plist file.")
            haptics.error()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = try supabase.getClient()
            try await client.auth.resetPasswordForEmail(email)

            // Show success message
            authState = .error("Password reset email sent. Check your inbox.")
            haptics.taskComplete()
        } catch {
            authState = .error(error.localizedDescription)
            haptics.error()
        }
    }

    // MARK: - Sign Out

    /// Sign out
    func signOut() async {
        guard supabase.isConfigured else {
            authState = .idle
            clearForm()
            return
        }

        do {
            let client = try supabase.getClient()
            try await client.auth.signOut()
            authState = .idle
            clearForm()
        } catch {
            authState = .error(error.localizedDescription)
        }
    }

    // MARK: - Validation

    /// Check if form is valid for sign in
    var canSignIn: Bool {
        emailValidation.isValid && !password.isEmpty
    }

    /// Check if form is valid for sign up
    var canSignUp: Bool {
        emailValidation.isValid && password.count >= 8 && password == confirmPassword
    }

    /// Check if password meets minimum requirements
    var passwordMeetsRequirements: Bool {
        password.count >= 8
    }

    /// Check if passwords match
    var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    // MARK: - Helpers

    /// Clear form
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        emailValidation = .idle
        passwordStrength = .weak
    }

    /// Clear error
    func clearError() {
        if case .error = authState {
            authState = .idle
        }
        error = nil
    }

    /// Reset state
    func reset() {
        authState = .idle
        clearForm()
    }

    // MARK: - Simple Email Methods (for EmailSignInSheet)

    /// Simple sign in with email and password
    func signIn(email: String, password: String) async {
        self.email = email
        self.password = password
        await signInWithEmail()
    }

    /// Simple sign up with email and password
    func signUp(email: String, password: String) async {
        self.email = email
        self.password = password
        self.confirmPassword = password
        await signUpWithEmail()
    }

    /// Simple password reset
    func resetPassword(email: String) async {
        self.email = email
        await sendPasswordReset()
    }
}
