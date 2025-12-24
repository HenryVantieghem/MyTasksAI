//
//  SubscriptionService.swift
//  Veloce
//
//  Subscription Service - StoreKit 2 Integration
//  Handles Pro ($9.99/mo) and Creator ($19.99/mo) subscriptions
//

import Foundation
import SwiftUI
import StoreKit
import Supabase

// MARK: - Subscription Service

@MainActor
@Observable
final class SubscriptionService {
    // MARK: Singleton
    static let shared = SubscriptionService()

    // MARK: State
    private(set) var isSubscribed: Bool = false
    private(set) var isInTrial: Bool = false
    private(set) var trialDaysRemaining: Int = 0
    private(set) var isLoading: Bool = false
    private(set) var error: String?
    private(set) var products: [Product] = []
    private(set) var purchasedSubscriptions: [Product] = []
    private(set) var currentTier: SubscriptionTier = .free
    private(set) var subscription: Subscription?

    // Trial tracking
    private(set) var installDate: Date

    // StoreKit Product IDs
    static let proMonthlyId = "com.veloce.pro.monthly"
    static let proYearlyId = "com.veloce.pro.yearly"
    static let creatorMonthlyId = "com.veloce.creator.monthly"
    static let creatorYearlyId = "com.veloce.creator.yearly"

    private var updateListenerTask: Task<Void, Error>?

    // Dependencies
    private let supabase = SupabaseService.shared

    // MARK: Initialization
    private init() {
        // Get or set install date
        if let savedDate = UserDefaults.standard.object(forKey: "veloce_install_date") as? Date {
            self.installDate = savedDate
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: "veloce_install_date")
            self.installDate = now
        }

        updateListenerTask = listenForTransactions()
    }

    nonisolated func cleanup() {
        // Note: This is called manually if needed, but Task will be deallocated naturally
    }

    // MARK: - Configuration

    func configure() async {
        #if DEBUG
        print("[SubscriptionService] Configuring...")
        #endif

        await loadProducts()
        await checkSubscriptionStatus()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds: Set<String> = [
                Self.proMonthlyId,
                Self.proYearlyId,
                Self.creatorMonthlyId,
                Self.creatorYearlyId
            ]

            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }

            #if DEBUG
            print("[SubscriptionService] Loaded \(products.count) products")
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("[SubscriptionService] Error loading products: \(error)")
            #endif
        }
    }

    // MARK: - Check Subscription Status

    func checkSubscriptionStatus() async {
        isLoading = true
        defer { isLoading = false }

        #if DEBUG
        print("[SubscriptionService] Checking subscription status...")
        #endif

        // Reset state
        var highestTier: SubscriptionTier = .free

        // Check App Store subscriptions
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.productID.contains("creator") {
                highestTier = .creator
            } else if transaction.productID.contains("pro") && highestTier != .creator {
                highestTier = .pro
            }
        }

        currentTier = highestTier
        isSubscribed = highestTier != .free

        // Update purchased subscriptions list
        await updatePurchasedSubscriptions()

        // Check local trial if not subscribed
        if !isSubscribed {
            checkLocalFreeTrial()
        } else {
            isInTrial = false
        }

        // Sync with Supabase
        await syncSubscriptionToSupabase()

        #if DEBUG
        print("[SubscriptionService] Final state - tier: \(currentTier), subscribed: \(isSubscribed), trial: \(isInTrial)")
        #endif
    }

    // MARK: - Local Free Trial Check

    private func checkLocalFreeTrial() {
        let daysSinceInstall = Calendar.current.dateComponents(
            [.day],
            from: installDate,
            to: Date()
        ).day ?? 0

        if daysSinceInstall <= 3 {
            isInTrial = true
            trialDaysRemaining = 3 - daysSinceInstall
        } else {
            isInTrial = false
            trialDaysRemaining = 0
        }
    }

    // MARK: - Access Checks

    var canAccessApp: Bool {
        isSubscribed || isInTrial
    }

    var shouldShowPaywall: Bool {
        !canAccessApp
    }

    var isPro: Bool {
        currentTier == .pro || currentTier == .creator
    }

    var isCreator: Bool {
        currentTier == .creator
    }

    var canPublishTemplates: Bool {
        isCreator
    }

    var canAccessPremiumTemplates: Bool {
        isPro
    }

    var aiSuggestionsLimit: Int {
        switch currentTier {
        case .free: return 5
        case .pro, .creator: return Int.max
        }
    }

    // Legacy compatibility
    var isProUser: Bool {
        canAccessApp
    }

    func checkProAccess() -> Bool {
        canAccessApp
    }

    // MARK: - Start Free Trial

    @discardableResult
    func startFreeTrial() -> Bool {
        let hasUsedTrial = UserDefaults.standard.bool(forKey: "veloce_trial_used")

        if hasUsedTrial {
            #if DEBUG
            print("[SubscriptionService] Trial already used")
            #endif
            return false
        }

        let now = Date()
        UserDefaults.standard.set(now, forKey: "veloce_install_date")
        UserDefaults.standard.set(true, forKey: "veloce_trial_started")
        UserDefaults.standard.set(true, forKey: "veloce_trial_used")
        installDate = now

        isInTrial = true
        trialDaysRemaining = 3
        isSubscribed = false
        error = nil

        #if DEBUG
        print("[SubscriptionService] Free trial started")
        #endif

        return true
    }

    var canStartFreeTrial: Bool {
        !UserDefaults.standard.bool(forKey: "veloce_trial_used")
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateTierFromTransaction(transaction)
            await syncSubscriptionToSupabase()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    func purchasePro(yearly: Bool = false) async throws {
        let productId = yearly ? Self.proYearlyId : Self.proMonthlyId
        guard let product = products.first(where: { $0.id == productId }) else {
            // Fallback for simulator
            #if DEBUG
            print("[SubscriptionService] No product found - simulating purchase")
            currentTier = .pro
            isSubscribed = true
            return
            #else
            throw SubscriptionError.productNotFound
            #endif
        }
        _ = try await purchase(product)
    }

    func purchaseCreator(yearly: Bool = false) async throws {
        let productId = yearly ? Self.creatorYearlyId : Self.creatorMonthlyId
        guard let product = products.first(where: { $0.id == productId }) else {
            #if DEBUG
            print("[SubscriptionService] No product found - simulating purchase")
            currentTier = .creator
            isSubscribed = true
            return
            #else
            throw SubscriptionError.productNotFound
            #endif
        }
        _ = try await purchase(product)
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        try await AppStore.sync()
        await checkSubscriptionStatus()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateTierFromTransaction(transaction)
                    await self.syncSubscriptionToSupabase()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func updateTierFromTransaction(_ transaction: StoreKit.Transaction) async {
        if transaction.productID.contains("creator") {
            currentTier = .creator
            isSubscribed = true
        } else if transaction.productID.contains("pro") {
            currentTier = .pro
            isSubscribed = true
        }
        isInTrial = false
        await updatePurchasedSubscriptions()
    }

    private func updatePurchasedSubscriptions() async {
        var purchased: [Product] = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if let product = products.first(where: { $0.id == transaction.productID }) {
                purchased.append(product)
            }
        }

        purchasedSubscriptions = purchased
    }

    // MARK: - Supabase Sync

    private func syncSubscriptionToSupabase() async {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            var appleTransactionId: String?
            var expiresAt: Date?

            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                appleTransactionId = String(transaction.id)
                expiresAt = transaction.expirationDate
                break
            }

            let existing: [Subscription] = try await client
                .from("subscriptions")
                .select("*")
                .eq("user_id", value: userId)
                .execute()
                .value

            let status = isInTrial ? "trial" : (isSubscribed ? "active" : "expired")

            if existing.isEmpty {
                let subscriptionData = CreateSubscriptionRequest(
                    userId: userId,
                    tier: currentTier.rawValue,
                    status: status,
                    appleTransactionId: appleTransactionId,
                    expiresAt: expiresAt,
                    autoRenew: true
                )

                try await client
                    .from("subscriptions")
                    .insert(subscriptionData)
                    .execute()
            } else {
                let updateData = UpdateSubscriptionRequest(
                    tier: currentTier.rawValue,
                    status: status,
                    appleTransactionId: appleTransactionId,
                    expiresAt: expiresAt,
                    updatedAt: Date()
                )

                try await client
                    .from("subscriptions")
                    .update(updateData)
                    .eq("user_id", value: userId)
                    .execute()
            }

            subscription = try await loadSubscription()
        } catch {
            #if DEBUG
            print("[SubscriptionService] Sync failed: \(error)")
            #endif
        }
    }

    func loadSubscription() async throws -> Subscription? {
        guard supabase.isConfigured else { return nil }

        let client = try supabase.getClient()
        guard let userId = try await client.auth.session.user.id as UUID? else { return nil }

        let response: [Subscription] = try await client
            .from("subscriptions")
            .select("*")
            .eq("user_id", value: userId)
            .execute()
            .value

        subscription = response.first
        if let sub = subscription {
            currentTier = sub.tier
        }
        return response.first
    }

    // MARK: - Product Helpers

    func product(for tier: SubscriptionTier, yearly: Bool) -> Product? {
        let productId: String
        switch tier {
        case .free:
            return nil
        case .pro:
            productId = yearly ? Self.proYearlyId : Self.proMonthlyId
        case .creator:
            productId = yearly ? Self.creatorYearlyId : Self.creatorMonthlyId
        }
        return products.first { $0.id == productId }
    }

    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    func isSubscribed(to productId: String) -> Bool {
        purchasedSubscriptions.contains { $0.id == productId }
    }

    // MARK: - Manage Subscription

    func openManageSubscriptions() {
        guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Subscription Error

enum SubscriptionError: Error, LocalizedError {
    case productNotFound
    case verificationFailed
    case purchaseFailed
    case restoreFailed
    case notConfigured
    case trialExpired

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found"
        case .verificationFailed:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .restoreFailed:
            return "Unable to restore purchases. Please try again."
        case .notConfigured:
            return "Subscription service not configured"
        case .trialExpired:
            return "Your free trial has expired. Subscribe to continue."
        }
    }
}
