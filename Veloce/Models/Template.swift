//
//  Template.swift
//  Veloce
//
//  Template Model - Task workflow templates for marketplace
//  Part of Templates Marketplace feature
//

import Foundation
import SwiftUI

// MARK: - Template Category
enum TemplateCategory: String, Codable, Sendable, CaseIterable {
    case morningRoutine = "morning_routine"
    case work
    case fitness
    case learning
    case creative
    case health
    case custom

    var displayName: String {
        switch self {
        case .morningRoutine: return "Morning Routine"
        case .work: return "Work"
        case .fitness: return "Fitness"
        case .learning: return "Learning"
        case .creative: return "Creative"
        case .health: return "Health"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .morningRoutine: return "sunrise"
        case .work: return "briefcase"
        case .fitness: return "figure.run"
        case .learning: return "book"
        case .creative: return "paintbrush"
        case .health: return "heart"
        case .custom: return "square.grid.2x2"
        }
    }

    var color: Color {
        switch self {
        case .morningRoutine: return .orange
        case .work: return .blue
        case .fitness: return .green
        case .learning: return .purple
        case .creative: return .pink
        case .health: return .red
        case .custom: return .gray
        }
    }
}

// MARK: - Template Model
struct Template: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let creatorId: UUID
    var title: String
    var description: String?
    var category: TemplateCategory
    var templateData: TemplateData
    var isPublic: Bool
    var isPremium: Bool
    var priceCents: Int
    var downloadCount: Int
    var ratingAvg: Float
    var ratingCount: Int
    var tags: [String]
    var previewImageUrl: String?
    let createdAt: Date?
    var updatedAt: Date?

    // Joined creator data
    var creator: FriendProfile?

    var priceDisplay: String {
        priceCents == 0 ? "Free" : "$\(String(format: "%.2f", Double(priceCents) / 100))"
    }

    var formattedRating: String {
        ratingCount == 0 ? "New" : String(format: "%.1f", ratingAvg)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case title, description, category
        case templateData = "template_data"
        case isPublic = "is_public"
        case isPremium = "is_premium"
        case priceCents = "price_cents"
        case downloadCount = "download_count"
        case ratingAvg = "rating_avg"
        case ratingCount = "rating_count"
        case tags
        case previewImageUrl = "preview_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Template, rhs: Template) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Template Data
struct TemplateData: Codable, Sendable, Hashable {
    var tasks: [TemplateTask]
    var estimatedTotalMinutes: Int
    var recommendedTime: String?  // "morning", "afternoon", "evening"

    var taskCount: Int { tasks.count }
}

// MARK: - Template Task
struct TemplateTask: Codable, Sendable, Hashable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var notes: String?
    var estimatedMinutes: Int
    var starRating: Int
    var order: Int

    enum CodingKeys: String, CodingKey {
        case title, notes
        case estimatedMinutes = "estimated_minutes"
        case starRating = "star_rating"
        case order
    }
}

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
            return ["Basic task management", "5 AI suggestions/day", "Community templates"]
        case .pro:
            return ["Unlimited AI scheduling", "Premium templates", "Advanced analytics", "Priority support"]
        case .creator:
            return ["Everything in Pro", "Publish templates", "Earn 70% revenue", "Creator analytics"]
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

enum SubscriptionStatus: String, Codable, Sendable {
    case active
    case canceled
    case expired
    case trial
}

// MARK: - Template Rating
struct TemplateRating: Codable, Identifiable, Sendable {
    let id: UUID
    let templateId: UUID
    let userId: UUID
    var rating: Int
    var review: String?
    let createdAt: Date?

    var user: FriendProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case userId = "user_id"
        case rating, review
        case createdAt = "created_at"
    }
}

// MARK: - Create Template Request
struct CreateTemplateRequest: Codable, Sendable {
    let creatorId: UUID
    let title: String
    let description: String?
    let category: String
    let templateData: TemplateData
    let isPublic: Bool
    let isPremium: Bool
    let priceCents: Int
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case creatorId = "creator_id"
        case title, description, category
        case templateData = "template_data"
        case isPublic = "is_public"
        case isPremium = "is_premium"
        case priceCents = "price_cents"
        case tags
    }
}
