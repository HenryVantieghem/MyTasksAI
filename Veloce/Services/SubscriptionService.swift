//
//  SubscriptionService.swift
//  Veloce
//
//  Subscription Service - RevenueCat Integration
//  Handles Pro ($9.99/mo) and Creator ($19.99/mo) subscriptions
//  Includes local 3-day free trial (no payment required)
//
//  Trial Flow:
//  1. First-time users see FreeTrialWelcomeView
//  2. Upon sign up/sign in, trial starts (3 days)
//  3. During trial, full app access (no paywall)
//  4. After 3 days, paywall appears - must subscribe to continue
//

import Foundation
import SwiftUI
import RevenueCat
import Supabase

// MARK: - Trial Constants

private enum TrialConstants {
    static let trialDurationDays: Int = 3
    static let trialStartDateKey = "mytasksai_trial_start_date"
    static let trialStartedKey = "mytasksai_trial_started"
    static let lastKnownDateKey = "mytasksai_last_known_date"
    static let installDateKey = "mytasksai_install_date"
}

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
    private(set) var trialHoursRemaining: Int = 0
    private(set) var isLoading: Bool = false
    private(set) var error: String?
    private(set) var currentTier: SubscriptionTier = .free
    private(set) var subscription: Subscription?
    private(set) var trialExpired: Bool = false

    // RevenueCat state
    private(set) var offerings: Offerings?
    private(set) var customerInfo: CustomerInfo?
    private(set) var isConfigured: Bool = false

    // Trial tracking
    private(set) var trialStartDate: Date?
    private(set) var trialEndDate: Date?
    private(set) var installDate: Date

    // Callback for trial expiration (used by AppViewModel)
    var onTrialExpired: (() -> Void)?

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

    // Timer for checking trial expiration
    private var trialCheckTimer: Timer?

    // MARK: Initialization
    private init() {
        // Get install date
        if let savedDate = UserDefaults.standard.object(forKey: TrialConstants.installDateKey) as? Date {
            self.installDate = savedDate
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: TrialConstants.installDateKey)
            self.installDate = now
        }

        // Load trial start date if exists
        if let savedTrialStart = UserDefaults.standard.object(forKey: TrialConstants.trialStartDateKey) as? Date {
            self.trialStartDate = savedTrialStart
            self.trialEndDate = Calendar.current.date(byAdding: .day, value: TrialConstants.trialDurationDays, to: savedTrialStart)
        }

        // Save current date for tampering detection
        UserDefaults.standard.set(Date(), forKey: TrialConstants.lastKnownDateKey)
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

    /// Check if trial has been started and if it's still active
    /// Trial only starts when user signs up/signs in, not on install
    private func checkLocalFreeTrial() {
        // First check for date tampering
        if detectDateTampering() {
            #if DEBUG
            print("[SubscriptionService] Date tampering detected - expiring trial")
            #endif
            expireTrialImmediately()
            return
        }

        // Update last known date
        UserDefaults.standard.set(Date(), forKey: TrialConstants.lastKnownDateKey)

        // If trial hasn't started yet, user is NOT in trial (they need to sign up first)
        guard let startDate = trialStartDate else {
            isInTrial = false
            trialDaysRemaining = 0
            trialHoursRemaining = 0
            trialExpired = false
            #if DEBUG
            print("[SubscriptionService] Trial not started yet - awaiting sign up")
            #endif
            return
        }

        let now = Date()

        // Calculate end date
        guard let endDate = Calendar.current.date(byAdding: .day, value: TrialConstants.trialDurationDays, to: startDate) else {
            isInTrial = false
            trialExpired = true
            return
        }

        trialEndDate = endDate

        // Check if trial is still active
        if now < endDate {
            isInTrial = true
            trialExpired = false

            // Calculate remaining time
            let components = Calendar.current.dateComponents([.day, .hour], from: now, to: endDate)
            trialDaysRemaining = max(0, components.day ?? 0)
            trialHoursRemaining = max(0, components.hour ?? 0)

            #if DEBUG
            print("[SubscriptionService] Trial active - \(trialDaysRemaining) days, \(trialHoursRemaining) hours remaining")
            #endif
        } else {
            // Trial has expired
            isInTrial = false
            trialDaysRemaining = 0
            trialHoursRemaining = 0
            trialExpired = true

            #if DEBUG
            print("[SubscriptionService] Trial expired")
            #endif

            // Notify listeners
            onTrialExpired?()
        }
    }

    /// Detect if user has tampered with device date to extend trial
    private func detectDateTampering() -> Bool {
        guard let lastKnownDate = UserDefaults.standard.object(forKey: TrialConstants.lastKnownDateKey) as? Date else {
            return false
        }

        let now = Date()

        // If current date is significantly before last known date, user may have changed date
        // Allow 1 hour tolerance for minor clock adjustments
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: lastKnownDate) ?? lastKnownDate

        if now < oneHourAgo {
            #if DEBUG
            print("[SubscriptionService] Date tampering detected: current \(now) is before last known \(lastKnownDate)")
            #endif
            return true
        }

        return false
    }

    /// Immediately expire the trial (used for tampering detection)
    private func expireTrialImmediately() {
        isInTrial = false
        trialDaysRemaining = 0
        trialHoursRemaining = 0
        trialExpired = true

        // Set trial end date to past
        if let startDate = trialStartDate {
            trialEndDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate)
        }

        onTrialExpired?()
    }

    // MARK: - Trial Timer

    /// Start a timer to periodically check trial status
    func startTrialExpirationTimer() {
        stopTrialExpirationTimer()

        // Check every minute
        trialCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkLocalFreeTrial()

                // If trial just expired while user was in app, trigger callback
                if self?.trialExpired == true && self?.isSubscribed == false {
                    self?.onTrialExpired?()
                }
            }
        }
    }

    func stopTrialExpirationTimer() {
        trialCheckTimer?.invalidate()
        trialCheckTimer = nil
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

    /// Start the free trial when user signs up or signs in for the first time
    /// This should be called after successful authentication
    @discardableResult
    func startFreeTrial() -> Bool {
        // Check if trial was already started
        if trialStartDate != nil {
            #if DEBUG
            print("[SubscriptionService] Trial already started on \(trialStartDate!)")
            #endif
            // Refresh trial status
            checkLocalFreeTrial()
            return isInTrial
        }

        let now = Date()

        // Save trial start date
        trialStartDate = now
        trialEndDate = Calendar.current.date(byAdding: .day, value: TrialConstants.trialDurationDays, to: now)

        UserDefaults.standard.set(now, forKey: TrialConstants.trialStartDateKey)
        UserDefaults.standard.set(true, forKey: TrialConstants.trialStartedKey)
        UserDefaults.standard.set(now, forKey: TrialConstants.lastKnownDateKey)

        isInTrial = true
        trialDaysRemaining = TrialConstants.trialDurationDays
        trialHoursRemaining = 0
        trialExpired = false
        isSubscribed = false
        error = nil

        // Start expiration timer
        startTrialExpirationTimer()

        #if DEBUG
        print("[SubscriptionService] Free trial started - ends on \(trialEndDate!)")
        #endif

        // Sync trial start to Supabase
        Task {
            await syncTrialToSupabase()
        }

        return true
    }

    /// Check if user has ever started a trial (to prevent re-starting)
    var hasTrialBeenStarted: Bool {
        UserDefaults.standard.bool(forKey: TrialConstants.trialStartedKey) || trialStartDate != nil
    }

    /// Check if user can start a free trial (hasn't used it before)
    var canStartFreeTrial: Bool {
        !hasTrialBeenStarted
    }

    /// Sync trial status to Supabase for server-side tracking
    private func syncTrialToSupabase() async {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            // Update user's trial info in Supabase
            let trialData: [String: AnyEncodable] = [
                "trial_started_at": AnyEncodable(trialStartDate),
                "trial_ends_at": AnyEncodable(trialEndDate),
                "updated_at": AnyEncodable(Date())
            ]

            try await client
                .from("users")
                .update(trialData)
                .eq("id", value: userId)
                .execute()

            #if DEBUG
            print("[SubscriptionService] Trial synced to Supabase")
            #endif
        } catch {
            #if DEBUG
            print("[SubscriptionService] Failed to sync trial to Supabase: \(error)")
            #endif
        }
    }

    /// Load trial info from Supabase (for reinstall/new device scenarios)
    func loadTrialFromSupabase() async {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            struct UserTrialInfo: Decodable {
                let trial_started_at: Date?
                let trial_ends_at: Date?
            }

            let response: [UserTrialInfo] = try await client
                .from("users")
                .select("trial_started_at, trial_ends_at")
                .eq("id", value: userId)
                .execute()
                .value

            if let userInfo = response.first,
               let serverTrialStart = userInfo.trial_started_at {
                // Server has trial info - use it (prevents trial reset on reinstall)
                let localTrialStart = trialStartDate

                // Use whichever trial started earlier (prevents extending trial)
                if localTrialStart == nil || serverTrialStart < localTrialStart! {
                    trialStartDate = serverTrialStart
                    trialEndDate = userInfo.trial_ends_at ?? Calendar.current.date(byAdding: .day, value: TrialConstants.trialDurationDays, to: serverTrialStart)

                    // Save to local
                    UserDefaults.standard.set(serverTrialStart, forKey: TrialConstants.trialStartDateKey)
                    UserDefaults.standard.set(true, forKey: TrialConstants.trialStartedKey)

                    #if DEBUG
                    print("[SubscriptionService] Loaded trial from Supabase - started: \(serverTrialStart)")
                    #endif
                }

                // Re-check trial status with server data
                checkLocalFreeTrial()
            }
        } catch {
            #if DEBUG
            print("[SubscriptionService] Failed to load trial from Supabase: \(error)")
            #endif
        }
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
