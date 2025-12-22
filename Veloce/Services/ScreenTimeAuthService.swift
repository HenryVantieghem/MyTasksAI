//
//  ScreenTimeAuthService.swift
//  Veloce
//
//  Screen Time API Authorization Service
//  Handles FamilyControls authorization for app blocking features
//

import Foundation
import FamilyControls

// MARK: - Screen Time Authorization Service

/// Manages FamilyControls authorization for Screen Time API access
/// Required for app blocking functionality
@MainActor
@Observable
final class ScreenTimeAuthService {
    // MARK: Singleton

    static let shared = ScreenTimeAuthService()

    // MARK: State

    /// Current authorization status
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    /// Whether the app is authorized to use Screen Time API
    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    /// Human-readable status description
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not Set Up"
        case .denied:
            return "Access Denied"
        case .approved:
            return "Enabled"
        @unknown default:
            return "Unknown"
        }
    }

    /// Error message if authorization failed
    private(set) var authorizationError: String?

    // MARK: Private

    private let center = AuthorizationCenter.shared

    // MARK: Initialization

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Public Methods

    /// Request authorization to use Screen Time API
    /// This will show the system authorization prompt
    func requestAuthorization() async throws {
        authorizationError = nil

        do {
            // Request authorization for individual (non-child) user
            // iOS 16+ supports .individual authorization for personal use
            try await center.requestAuthorization(for: .individual)
            checkAuthorizationStatus()

            if authorizationStatus == .approved {
                // Save that user has completed authorization
                UserDefaults.standard.set(true, forKey: "screenTimeAuthCompleted")
            }
        } catch {
            authorizationError = error.localizedDescription
            checkAuthorizationStatus()
            throw ScreenTimeAuthError.authorizationFailed(error)
        }
    }

    /// Check and update the current authorization status
    func checkAuthorizationStatus() {
        authorizationStatus = center.authorizationStatus
    }

    /// Revoke authorization (user must do this in Settings)
    /// This method just clears local state
    func clearAuthorization() {
        UserDefaults.standard.removeObject(forKey: "screenTimeAuthCompleted")
        checkAuthorizationStatus()
    }

    /// Whether user has ever completed authorization setup
    var hasCompletedSetup: Bool {
        UserDefaults.standard.bool(forKey: "screenTimeAuthCompleted")
    }

    // MARK: - Status Helpers

    /// Icon name for current status
    var statusIcon: String {
        switch authorizationStatus {
        case .notDetermined:
            return "questionmark.circle"
        case .denied:
            return "xmark.circle"
        case .approved:
            return "checkmark.circle.fill"
        @unknown default:
            return "exclamationmark.circle"
        }
    }

    /// Color name for current status (Theme.Colors reference)
    var statusColorName: String {
        switch authorizationStatus {
        case .approved:
            return "success"
        case .denied:
            return "error"
        default:
            return "warning"
        }
    }
}

// MARK: - Authorization Errors

enum ScreenTimeAuthError: LocalizedError {
    case authorizationFailed(Error)
    case notAuthorized
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let error):
            return "Authorization failed: \(error.localizedDescription)"
        case .notAuthorized:
            return "Screen Time access is not authorized. Please enable it in Settings."
        case .notAvailable:
            return "Screen Time API is not available on this device."
        }
    }
}

// MARK: - AuthorizationStatus Extension

extension AuthorizationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .approved:
            return "Approved"
        @unknown default:
            return "Unknown"
        }
    }
}
