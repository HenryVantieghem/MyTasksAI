//
//  AuthViewModel.swift
//  Veloce
//
//  Auth View Model - Authentication State Management
//  Handles sign in, sign up, and authentication flows
//

import Foundation
import Supabase
import Auth
import AuthenticationServices
import CryptoKit

// MARK: - Auth State

enum AuthState: Equatable {
    case idle
    case signingIn
    case signingUp
    case success
    case error(String)
}

// MARK: - Auth Method

enum AuthMethod: String, CaseIterable {
    case apple = "apple"
    case google = "google"
    case email = "email"

    var displayName: String {
        switch self {
        case .apple: return "Sign in with Apple"
        case .google: return "Sign in with Google"
        case .email: return "Sign in with Email"
        }
    }

    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .email: return "envelope.fill"
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
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var fullName: String = ""

    // MARK: Apple Sign In
    private var currentNonce: String?

    // MARK: Services
    private let appleSignIn = AppleSignInService.shared
    private let googleSignIn = GoogleSignInService.shared
    private let supabase = SupabaseService.shared
    private let haptics = HapticsService.shared

    // MARK: Callbacks
    var onAuthSuccess: (() -> Void)?

    // MARK: Initialization
    init() {}

    // MARK: - Apple Sign In (Native Button Support)

    /// Configure Apple Sign In request
    func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = generateNonce()
        currentNonce = nonce
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)
    }

    /// Handle Apple Sign In completion
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                error = "Failed to get Apple credentials"
                return
            }

            authState = .signingIn
            isLoading = true
            defer { isLoading = false }

            do {
                try await appleSignIn.signInWithSupabase(idToken: idTokenString, nonce: nonce)
                authState = .success
                haptics.taskComplete()
                onAuthSuccess?()
            } catch {
                self.error = error.localizedDescription
                authState = .error(error.localizedDescription)
                haptics.error()
            }

        case .failure(let authError):
            if (authError as NSError).code == ASAuthorizationError.canceled.rawValue {
                authState = .idle
            } else {
                error = authError.localizedDescription
                authState = .error(authError.localizedDescription)
                haptics.error()
            }
        }
    }

    // MARK: - Nonce Generation

    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Apple Sign In (Existing)

    /// Sign in with Apple
    func signInWithApple() async {
        authState = .signingIn
        isLoading = true

        defer { isLoading = false }

        do {
            let result = try await appleSignIn.signIn()

            // Sign in with Supabase using Apple credential
            if let nonce = result.nonce {
                try await appleSignIn.signInWithSupabase(
                    idToken: result.identityToken,
                    nonce: nonce
                )
            }

            authState = .success
            haptics.taskComplete()
            onAuthSuccess?()
        } catch let error as AppleSignInError {
            if case .cancelled = error {
                authState = .idle
            } else {
                authState = .error(error.localizedDescription)
                haptics.error()
            }
        } catch {
            authState = .error(error.localizedDescription)
            haptics.error()
        }
    }

    // MARK: - Google Sign In

    /// Sign in with Google
    func signInWithGoogle() async {
        authState = .signingIn
        isLoading = true

        defer { isLoading = false }

        do {
            try await googleSignIn.signIn()

            authState = .success
            haptics.taskComplete()
            onAuthSuccess?()
        } catch {
            authState = .error(error.localizedDescription)
            haptics.error()
        }
    }

    // MARK: - Email Sign In

    /// Sign in with email and password
    func signInWithEmail() async {
        guard validateEmail() else {
            authState = .error("Please enter a valid email address")
            return
        }

        guard !password.isEmpty else {
            authState = .error("Please enter your password")
            return
        }

        authState = .signingIn
        isLoading = true

        defer { isLoading = false }

        do {
            try await supabase.supabase.auth.signIn(
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
        guard validateEmail() else {
            authState = .error("Please enter a valid email address")
            return
        }

        guard password.count >= 8 else {
            authState = .error("Password must be at least 8 characters")
            return
        }

        guard password == confirmPassword else {
            authState = .error("Passwords don't match")
            return
        }

        authState = .signingUp
        isLoading = true

        defer { isLoading = false }

        do {
            try await supabase.supabase.auth.signUp(
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
        guard validateEmail() else {
            authState = .error("Please enter a valid email address")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.supabase.auth.resetPasswordForEmail(email)

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
        do {
            try await supabase.supabase.auth.signOut()
            authState = .idle
            clearForm()
        } catch {
            authState = .error(error.localizedDescription)
        }
    }

    // MARK: - Validation

    /// Validate email format
    private func validateEmail() -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    /// Check if form is valid for sign in
    var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty
    }

    /// Check if form is valid for sign up
    var canSignUp: Bool {
        !email.isEmpty && password.count >= 8 && password == confirmPassword
    }

    // MARK: - Helpers

    /// Clear form
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
    }

    /// Clear error
    func clearError() {
        if case .error = authState {
            authState = .idle
        }
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
