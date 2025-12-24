//
//  SubscriptionTypes.swift
//  Veloce
//
//  Subscription Types - Models for subscription management
//

import Foundation
import SwiftUI

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, Sendable, CaseIterable {
    case free
    case pro
    case creator

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .creator: return "Creator"
        }
    }

    var monthlyPrice: Int {
        switch self {
        case .free: return 0
        case .pro: return 999      // $9.99
        case .creator: return 1999  // $19.99
        }
    }

    var yearlyPrice: Int {
        switch self {
        case .free: return 0
        case .pro: return 7999      // $79.99
        case .creator: return 15999  // $159.99
        }
    }

    var priceDisplay: String {
        monthlyPrice == 0 ? "Free" : "$\(String(format: "%.2f", Double(monthlyPrice) / 100))/mo"
    }

    var features: [String] {
        switch self {
        case .free:
            return ["Basic task management", "5 AI suggestions/day"]
        case .pro:
            return ["Unlimited AI scheduling", "Advanced analytics", "Priority support"]
        case .creator:
            return ["Everything in Pro", "Full feature access", "Early access to new features"]
        }
    }

    var color: Color {
        switch self {
        case .free: return .gray
        case .pro: return Theme.Colors.aiPurple
        case .creator: return .orange
        }
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus: String, Codable, Sendable {
    case active
    case canceled
    case expired
    case trial
}

// MARK: - Subscription

struct Subscription: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var tier: SubscriptionTier
    var status: SubscriptionStatus
    var appleTransactionId: String?
    let startedAt: Date?
    var expiresAt: Date?
    var autoRenew: Bool
    let createdAt: Date?
    var updatedAt: Date?

    var isActive: Bool {
        status == .active || status == .trial
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tier, status
        case appleTransactionId = "apple_transaction_id"
        case startedAt = "started_at"
        case expiresAt = "expires_at"
        case autoRenew = "auto_renew"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Create Subscription Request

struct CreateSubscriptionRequest: Codable, Sendable {
    let userId: UUID
    let tier: String
    let status: String
    let appleTransactionId: String?
    let expiresAt: Date?
    let autoRenew: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tier, status
        case appleTransactionId = "apple_transaction_id"
        case expiresAt = "expires_at"
        case autoRenew = "auto_renew"
    }
}

// MARK: - Update Subscription Request

struct UpdateSubscriptionRequest: Codable, Sendable {
    let tier: String
    let status: String
    let appleTransactionId: String?
    let expiresAt: Date?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case tier, status
        case appleTransactionId = "apple_transaction_id"
        case expiresAt = "expires_at"
        case updatedAt = "updated_at"
    }
}
