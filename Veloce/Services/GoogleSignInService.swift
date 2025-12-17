//
//  GoogleSignInService.swift
//  Veloce
//
//  Google Sign In Service - Authentication with Google
//  Handles Sign in with Google flow and Supabase integration
//

import Foundation
import Supabase

// MARK: - Google Sign In Service

@MainActor
@Observable
final class GoogleSignInService {
    // MARK: Singleton
    static let shared = GoogleSignInService()

    // MARK: State
    private(set) var isSigningIn: Bool = false
    private(set) var lastError: String?

    // MARK: Configuration
    private let clientId = "YOUR_GOOGLE_CLIENT_ID"  // Replace with actual client ID

    // MARK: Initialization
    private init() {}

    // MARK: - Sign In with Supabase OAuth

    /// Initiate Google Sign In via Supabase OAuth
    func signIn() async throws {
        isSigningIn = true
        lastError = nil

        defer { isSigningIn = false }

        let supabase = SupabaseService.shared.supabase

        // Use Supabase's built-in OAuth flow
        try await supabase.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "veloce://auth-callback")
        )
    }

    /// Handle OAuth callback URL
    func handleCallback(url: URL) async throws {
        let supabase = SupabaseService.shared.supabase

        try await supabase.auth.session(from: url)
    }

    /// Sign in with ID token (for native Google Sign In)
    func signInWithIdToken(_ idToken: String, accessToken: String? = nil) async throws {
        isSigningIn = true
        lastError = nil

        defer { isSigningIn = false }

        let supabase = SupabaseService.shared.supabase

        try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }

    // MARK: - Sign Out

    /// Sign out from Google
    func signOut() async throws {
        let supabase = SupabaseService.shared.supabase
        try await supabase.auth.signOut()
    }
}

// MARK: - Google Sign In Error

enum GoogleSignInError: Error, LocalizedError {
    case cancelled
    case failed(String)
    case noIdToken
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Sign in was cancelled"
        case .failed(let message):
            return "Sign in failed: \(message)"
        case .noIdToken:
            return "No ID token received from Google"
        case .invalidConfiguration:
            return "Google Sign In is not properly configured"
        }
    }
}
