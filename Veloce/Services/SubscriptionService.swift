//
//  SubscriptionService.swift
//  Veloce
//
//  Subscription Service - RevenueCat Integration
//  Handles Pro ($9.99/mo) and Creator ($19.99/mo) subscriptions
//  Includes local 3-day free trial (no payment required)
//

import Foundation
import SwiftUI
import RevenueCat
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
    private(set) var currentTier: SubscriptionTier = .free
    private(set) var subscription: Subscription?

    // RevenueCat state
    private(set) var offerings: Offerings?
    private(set) var customerInfo: CustomerInfo?
    private(set) var isConfigured: Bool = false

    // Trial tracking
    private(set) var installDate: Date

    // RevenueCat Entitlement IDs (configure these in RevenueCat dashboard)
    static let proEntitlementId = "pro"
    static let creatorEntitlementId = "creator"

    // Product IDs (for reference - RevenueCat uses these internally)
    static let proMonthlyId = "com.veloce.pro.monthly"
    static let proYearlyId = "com.veloce.pro.yearly"
    static let creatorMonthlyId = "com.veloce.creator.monthly"
    static let creatorYearlyId = "com.veloce.creator.yearly"

    // Dependencies
    private let supabase = SupabaseService.shared

    // MARK: Initialization
    private init() {
        // Get or set install date for local trial
        if let savedDate = UserDefaults.standard.object(forKey: "veloce_install_date") as? Date {
            self.installDate = savedDate
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: "veloce_install_date")
            self.installDate = now
        }
    }

    // MARK: - Secret Loading

    private func loadSecret(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let value = plist[key] as? String,
              !value.isEmpty,
              !value.contains("YOUR_") else {
            return nil
        }
        return value
    }

    // MARK: - Configuration

    func configure() async {
        #if DEBUG
        print("[SubscriptionService] Configuring RevenueCat...")
        #endif

        // Load API key from Secrets.plist
        guard let apiKey = loadSecret(key: "REVENUECAT_API_KEY") else {
            #if DEBUG
            print("[SubscriptionService] RevenueCat API key not found in Secrets.plist")
            print("[SubscriptionService] Add REVENUECAT_API_KEY to Secrets.plist with your appl_xxx key")
            #endif
            error = "RevenueCat not configured. Add REVENUECAT_API_KEY to Secrets.plist"

            // Still check local trial even without RevenueCat
            checkLocalFreeTrial()
            return
        }

        // Configure RevenueCat SDK
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(storeKitVersion: .storeKit2)
                .build()
        )

        isConfigured = true

        #if DEBUG
        print("[SubscriptionService] RevenueCat configured successfully")
        #endif

        // Start listening for customer info updates
        listenForCustomerInfoUpdates()

        // Load offerings and check subscription status
        await loadOfferings()
        await checkSubscriptionStatus()
    }

    // MARK: - Load Offerings

    func loadOfferings() async {
        guard isConfigured else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            offerings = try await Purchases.shared.offerings()

            #if DEBUG
            if let current = offerings?.current {
                print("[SubscriptionService] Loaded offering: \(current.identifier)")
                print("[SubscriptionService] Available packages: \(current.availablePackages.count)")
                for package in current.availablePackages {
                    print("  - \(package.identifier): \(package.storeProduct.localizedPriceString)")
                }
            }
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("[SubscriptionService] Error loading offerings: \(error)")
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

        // Check RevenueCat entitlements if configured
        if isConfigured {
            do {
                customerInfo = try await Purchases.shared.customerInfo()
                updateTierFromCustomerInfo()
            } catch {
                #if DEBUG
                print("[SubscriptionService] Error getting customer info: \(error)")
                #endif
            }
        }

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

    // MARK: - Update Tier from CustomerInfo

    private func updateTierFromCustomerInfo() {
        guard let info = customerInfo else {
            currentTier = .free
            isSubscribed = false
            return
        }

        // Check for Creator entitlement first (higher tier)
        if info.entitlements[Self.creatorEntitlementId]?.isActive == true {
            currentTier = .creator
            isSubscribed = true
            isInTrial = false
        }
        // Then check for Pro entitlement
        else if info.entitlements[Self.proEntitlementId]?.isActive == true {
            currentTier = .pro
            isSubscribed = true
            isInTrial = false
        }
        // No active subscription
        else {
            currentTier = .free
            isSubscribed = false
        }

        #if DEBUG
        print("[SubscriptionService] Updated tier from CustomerInfo: \(currentTier)")
        print("[SubscriptionService] Active entitlements: \(info.entitlements.active.keys.joined(separator: ", "))")
        #endif
    }

    // MARK: - Listen for Customer Info Updates

    private func listenForCustomerInfoUpdates() {
        Task {
            for await info in Purchases.shared.customerInfoStream {
                await MainActor.run {
                    self.customerInfo = info
                    self.updateTierFromCustomerInfo()

                    #if DEBUG
                    print("[SubscriptionService] Customer info updated via stream")
                    #endif
                }

                // Sync with Supabase when subscription changes
                await syncSubscriptionToSupabase()
            }
        }
    }

    // MARK: - Local Free Trial Check

    /// Local 3-day trial that doesn't require payment info
    private func checkLocalFreeTrial() {
        let daysSinceInstall = Calendar.current.dateComponents(
            [.day],
            from: installDate,
            to: Date()
        ).day ?? 0

        if daysSinceInstall <= 3 {
            isInTrial = true
            trialDaysRemaining = max(0, 3 - daysSinceInstall)
        } else {
            isInTrial = false
            trialDaysRemaining = 0
        }

        #if DEBUG
        print("[SubscriptionService] Local trial check - days since install: \(daysSinceInstall), in trial: \(isInTrial)")
        #endif
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

    // MARK: - Purchase with RevenueCat

    func purchase(_ package: Package) async throws -> CustomerInfo {
        guard isConfigured else {
            throw SubscriptionError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        let result = try await Purchases.shared.purchase(package: package)

        if result.userCancelled {
            throw SubscriptionError.purchaseCancelled
        }

        customerInfo = result.customerInfo
        updateTierFromCustomerInfo()
        await syncSubscriptionToSupabase()

        #if DEBUG
        print("[SubscriptionService] Purchase successful for package: \(package.identifier)")
        #endif

        return result.customerInfo
    }

    func purchasePro(yearly: Bool = false) async throws {
        guard let offering = offerings?.current else {
            #if DEBUG
            print("[SubscriptionService] No offering available - simulating purchase in debug")
            currentTier = .pro
            isSubscribed = true
            return
            #else
            throw SubscriptionError.productNotFound
            #endif
        }

        let packageId = yearly ? "annual" : "monthly"

        // Find the Pro package
        if let package = offering.availablePackages.first(where: {
            $0.identifier.lowercased().contains(packageId) &&
            $0.storeProduct.productIdentifier.contains("pro")
        }) {
            _ = try await purchase(package)
        } else if let package = yearly ? offering.annual : offering.monthly {
            // Fallback to standard package types
            _ = try await purchase(package)
        } else {
            #if DEBUG
            print("[SubscriptionService] No Pro package found - simulating purchase")
            currentTier = .pro
            isSubscribed = true
            #else
            throw SubscriptionError.productNotFound
            #endif
        }
    }

    func purchaseCreator(yearly: Bool = false) async throws {
        guard let offering = offerings?.current else {
            #if DEBUG
            print("[SubscriptionService] No offering available - simulating purchase in debug")
            currentTier = .creator
            isSubscribed = true
            return
            #else
            throw SubscriptionError.productNotFound
            #endif
        }

        let packageId = yearly ? "annual" : "monthly"

        // Find the Creator package
        if let package = offering.availablePackages.first(where: {
            $0.identifier.lowercased().contains(packageId) &&
            $0.storeProduct.productIdentifier.contains("creator")
        }) {
            _ = try await purchase(package)
        } else {
            #if DEBUG
            print("[SubscriptionService] No Creator package found - simulating purchase")
            currentTier = .creator
            isSubscribed = true
            #else
            throw SubscriptionError.productNotFound
            #endif
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        guard isConfigured else {
            throw SubscriptionError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        customerInfo = try await Purchases.shared.restorePurchases()
        updateTierFromCustomerInfo()
        await syncSubscriptionToSupabase()

        #if DEBUG
        print("[SubscriptionService] Purchases restored")
        #endif
    }

    // MARK: - Supabase Sync

    private func syncSubscriptionToSupabase() async {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            // Get transaction info from RevenueCat if available
            var appleTransactionId: String?
            var expiresAt: Date?

            if let info = customerInfo,
               let activeEntitlement = info.entitlements.active.values.first {
                appleTransactionId = activeEntitlement.originalPurchaseDate?.description
                expiresAt = activeEntitlement.expirationDate
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

    // MARK: - Package Helpers

    /// Get available packages from current offering
    var availablePackages: [Package] {
        offerings?.current?.availablePackages ?? []
    }

    /// Get a specific package by identifier
    func package(identifier: String) -> Package? {
        offerings?.current?.package(identifier: identifier)
    }

    /// Get monthly package for a tier
    func monthlyPackage(for tier: SubscriptionTier) -> Package? {
        guard let offering = offerings?.current else { return nil }

        switch tier {
        case .free:
            return nil
        case .pro:
            return offering.availablePackages.first {
                $0.storeProduct.productIdentifier == Self.proMonthlyId
            } ?? offering.monthly
        case .creator:
            return offering.availablePackages.first {
                $0.storeProduct.productIdentifier == Self.creatorMonthlyId
            }
        }
    }

    /// Get yearly package for a tier
    func yearlyPackage(for tier: SubscriptionTier) -> Package? {
        guard let offering = offerings?.current else { return nil }

        switch tier {
        case .free:
            return nil
        case .pro:
            return offering.availablePackages.first {
                $0.storeProduct.productIdentifier == Self.proYearlyId
            } ?? offering.annual
        case .creator:
            return offering.availablePackages.first {
                $0.storeProduct.productIdentifier == Self.creatorYearlyId
            }
        }
    }

    // MARK: - Manage Subscription

    func openManageSubscriptions() {
        if let url = customerInfo?.managementURL {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Subscription Error

enum SubscriptionError: Error, LocalizedError {
    case productNotFound
    case verificationFailed
    case purchaseFailed
    case purchaseCancelled
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
        case .purchaseCancelled:
            return "Purchase was cancelled."
        case .restoreFailed:
            return "Unable to restore purchases. Please try again."
        case .notConfigured:
            return "Subscription service not configured. Please add your RevenueCat API key."
        case .trialExpired:
            return "Your free trial has expired. Subscribe to continue."
        }
    }
}
