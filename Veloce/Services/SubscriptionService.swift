//
//  SubscriptionService.swift
//  Veloce
//
//  Subscription Service - Stub Implementation
//  Placeholder for in-app purchases (RevenueCat removed for now)
//

import Foundation
import SwiftUI

// MARK: - Subscription Service

@MainActor
@Observable
final class SubscriptionService {
    // MARK: Singleton
    static let shared = SubscriptionService()

    // MARK: State
    private(set) var isProUser: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var error: String?

    // MARK: Initialization
    private init() {}

    // MARK: - Configuration
    func configure() {
        // Stub: No-op without RevenueCat
        // Set isProUser to true for development/testing
        #if DEBUG
        isProUser = true
        #endif
    }

    // MARK: - Purchase (Stub)
    func purchaseMonthly() async throws {
        throw SubscriptionError.notConfigured
    }

    func purchaseYearly() async throws {
        throw SubscriptionError.notConfigured
    }

    func purchaseLifetime() async throws {
        throw SubscriptionError.notConfigured
    }

    // MARK: - Restore Purchases (Stub)
    func restorePurchases() async throws {
        throw SubscriptionError.notConfigured
    }

    // MARK: - Check Entitlement
    func checkProAccess() -> Bool {
        return isProUser
    }

    // MARK: - Manage Subscription
    func openManageSubscriptions() {
        guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Subscription Error

enum SubscriptionError: Error, LocalizedError {
    case packageNotFound
    case purchaseFailed
    case restoreFailed
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .packageNotFound:
            return "Subscription package not found"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .restoreFailed:
            return "Unable to restore purchases. Please try again."
        case .notConfigured:
            return "Subscription service not configured"
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case free
    case monthly
    case yearly
    case lifetime

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "Up to 10 tasks",
                "Basic AI advice",
                "Light & dark mode"
            ]
        case .monthly, .yearly, .lifetime:
            return [
                "Unlimited tasks",
                "Advanced AI insights",
                "Sub-task breakdown",
                "YouTube learning resources",
                "Smart scheduling",
                "Calendar sync",
                "Priority support",
                "All future features"
            ]
        }
    }
}
