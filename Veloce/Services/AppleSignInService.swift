//
//  AppleSignInService.swift
//  Veloce
//
//  Apple Sign In Service - Authentication with Apple
//  Handles Sign in with Apple flow and Supabase integration
//

import Foundation
import AuthenticationServices
import CryptoKit
import Supabase
import Auth

// MARK: - Apple Sign In Service

@MainActor
@Observable
final class AppleSignInService: NSObject {
    // MARK: Singleton
    static let shared = AppleSignInService()

    // MARK: State
    private(set) var isSigningIn: Bool = false
    private(set) var lastError: String?

    // MARK: Callbacks
    private var signInContinuation: CheckedContinuation<AppleSignInResult, Error>?

    // MARK: Nonce
    private var currentNonce: String?

    // MARK: Initialization
    private override init() {
        super.init()
    }

    // MARK: - Sign In

    /// Initiate Sign in with Apple
    func signIn() async throws -> AppleSignInResult {
        isSigningIn = true
        lastError = nil

        defer { isSigningIn = false }

        // Generate nonce for security
        let nonce = generateNonce()
        currentNonce = nonce

        return try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email, .fullName]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    /// Sign in with Supabase using Apple credential
    func signInWithSupabase(idToken: String, nonce: String) async throws {
        let supabase = SupabaseService.shared.supabase

        try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    // MARK: - Credential Check

    /// Check if existing Apple credential is still valid
    func checkCredentialState(userId: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userId) { state, _ in
                continuation.resume(returning: state)
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
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce")
                }
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
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                signInContinuation?.resume(throwing: AppleSignInError.invalidCredential)
                signInContinuation = nil
                return
            }

            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                signInContinuation?.resume(throwing: AppleSignInError.noIdentityToken)
                signInContinuation = nil
                return
            }

            // Build result
            let result = AppleSignInResult(
                userId: credential.user,
                email: credential.email,
                fullName: buildFullName(from: credential.fullName),
                identityToken: identityToken,
                authorizationCode: credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) },
                nonce: currentNonce
            )

            signInContinuation?.resume(returning: result)
            signInContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            lastError = error.localizedDescription

            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    signInContinuation?.resume(throwing: AppleSignInError.cancelled)
                case .failed:
                    signInContinuation?.resume(throwing: AppleSignInError.failed(error.localizedDescription))
                case .invalidResponse:
                    signInContinuation?.resume(throwing: AppleSignInError.invalidResponse)
                case .notHandled:
                    signInContinuation?.resume(throwing: AppleSignInError.notHandled)
                case .notInteractive:
                    signInContinuation?.resume(throwing: AppleSignInError.failed("Authorization not interactive"))
                case .unknown:
                    signInContinuation?.resume(throwing: AppleSignInError.unknown)
                default:
                    signInContinuation?.resume(throwing: AppleSignInError.unknown)
                }
            } else {
                signInContinuation?.resume(throwing: error)
            }

            signInContinuation = nil
        }
    }

    private func buildFullName(from nameComponents: PersonNameComponents?) -> String? {
        guard let components = nameComponents else { return nil }

        var parts: [String] = []
        if let givenName = components.givenName {
            parts.append(givenName)
        }
        if let familyName = components.familyName {
            parts.append(familyName)
        }

        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

// MARK: - Apple Sign In Result

struct AppleSignInResult: Sendable {
    let userId: String
    let email: String?
    let fullName: String?
    let identityToken: String
    let authorizationCode: String?
    let nonce: String?
}

// MARK: - Apple Sign In Error

enum AppleSignInError: Error, LocalizedError {
    case cancelled
    case failed(String)
    case invalidCredential
    case invalidResponse
    case noIdentityToken
    case notHandled
    case unknown

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Sign in was cancelled"
        case .failed(let message):
            return "Sign in failed: \(message)"
        case .invalidCredential:
            return "Invalid credential received"
        case .invalidResponse:
            return "Invalid response from Apple"
        case .noIdentityToken:
            return "No identity token received"
        case .notHandled:
            return "Authorization request not handled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
