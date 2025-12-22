//
//  SubscriptionService.swift
//  Veloce
//
//  Subscription Service - RevenueCat Integration
//  Handles $9.99/month subscription with 3-day free trial
//

import Foundation
import SwiftUI
import RevenueCat

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
    private(set) var currentOffering: Offering?

    // Trial tracking
    private(set) var installDate: Date

    // RevenueCat product IDs
    private let monthlyProductId = "mytasksai_pro_monthly"
    private let entitlementId = "pro"

    // MARK: API Key - Load from Secrets.plist
    private var revenueCatAPIKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["REVENUECAT_API_KEY"] as? String else {
            fatalError("RevenueCat API key not found in Secrets.plist")
        }
        return key
    }

    // MARK: Initialization
    private init() {
        // Get or set install date
        if let savedDate = UserDefaults.standard.object(forKey: "mytasksai_install_date") as? Date {
            self.installDate = savedDate
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: "mytasksai_install_date")
            self.installDate = now
        }
    }

    // MARK: - Configuration

    func configure() {
        #if DEBUG
        print("🔔 [SubscriptionService] configure() called")
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: revenueCatAPIKey)

        #if DEBUG
        print("🔔 [SubscriptionService] RevenueCat configured with API key")
        #endif

        // Check subscription status on launch
        Task {
            await checkSubscriptionStatus()
            await fetchOfferings()
        }
    }

    // MARK: - Fetch Offerings

    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            print("Error fetching offerings: \(error)")
        }
    }

    // MARK: - Check Subscription Status

    func checkSubscriptionStatus() async {
        isLoading = true
        defer { isLoading = false }

        #if DEBUG
        print("🔔 [SubscriptionService] checkSubscriptionStatus() called")
        #endif

        do {
            let customerInfo = try await Purchases.shared.customerInfo()

            #if DEBUG
            print("🔔 [SubscriptionService] Got customer info from RevenueCat")
            print("🔔 [SubscriptionService] Entitlements: \(customerInfo.entitlements.all.keys)")
            #endif

            // Check if user has active pro entitlement
            if let entitlement = customerInfo.entitlements[entitlementId],
               entitlement.isActive {
                isSubscribed = true

                #if DEBUG
                print("🔔 [SubscriptionService] User has active '\(entitlementId)' entitlement")
                #endif

                // Check if in trial period
                isInTrial = entitlement.periodType == .trial

                if isInTrial, let expirationDate = entitlement.expirationDate {
                    trialDaysRemaining = Calendar.current.dateComponents(
                        [.day],
                        from: Date(),
                        to: expirationDate
                    ).day ?? 0
                }
            } else {
                isSubscribed = false
                isInTrial = false

                #if DEBUG
                print("🔔 [SubscriptionService] No active entitlement, checking local trial")
                #endif

                // Fall back to local trial check
                checkLocalFreeTrial()
            }
        } catch {
            self.error = error.localizedDescription
            print("❌ [SubscriptionService] Error checking subscription: \(error)")
            // Fall back to local trial check
            checkLocalFreeTrial()
        }

        #if DEBUG
        print("🔔 [SubscriptionService] Final state - isSubscribed: \(isSubscribed), isInTrial: \(isInTrial), canAccessApp: \(canAccessApp), shouldShowPaywall: \(shouldShowPaywall)")
        #endif
    }

    // MARK: - Local Free Trial Check (Fallback)

    private func checkLocalFreeTrial() {
        let daysSinceInstall = Calendar.current.dateComponents(
            [.day],
            from: installDate,
            to: Date()
        ).day ?? 0

        #if DEBUG
        print("🔔 [SubscriptionService] checkLocalFreeTrial - installDate: \(installDate), daysSinceInstall: \(daysSinceInstall)")
        #endif

        if daysSinceInstall <= 3 {
            isInTrial = true
            trialDaysRemaining = 3 - daysSinceInstall
        } else {
            isInTrial = false
            trialDaysRemaining = 0
        }

        #if DEBUG
        // Toggle these to test paywall in simulator:
        // - bypassPaywallForTesting = true → skip paywall entirely
        // - forceShowPaywall = true → always show paywall (for testing UI)
        // Uncomment the appropriate block below when testing:

        // FORCE PAYWALL (uncomment to test):
        // print("🔔 [SubscriptionService] Forcing paywall to show (DEBUG mode)")
        // isInTrial = false
        // isSubscribed = false
        // trialDaysRemaining = 0

        // BYPASS PAYWALL (uncomment to test):
        // print("🔔 [SubscriptionService] Bypassing paywall (DEBUG mode)")
        // isSubscribed = true
        #endif
    }

    // MARK: - Check if User Can Access App

    var canAccessApp: Bool {
        isSubscribed || isInTrial
    }

    var shouldShowPaywall: Bool {
        !canAccessApp
    }

    // MARK: - Start Free Trial (Local)

    /// Starts a 3-day free trial locally. This is the primary way users start using the app.
    /// No payment required upfront - after 3 days, user must subscribe to continue.
    /// Returns true if trial was started successfully.
    @discardableResult
    func startFreeTrial() -> Bool {
        // Check if user has already used their trial
        let hasUsedTrial = UserDefaults.standard.bool(forKey: "mytasksai_trial_used")

        if hasUsedTrial {
            // User already used trial - they need to subscribe
            #if DEBUG
            print("🔔 [SubscriptionService] Trial already used - user must subscribe")
            #endif
            return false
        }

        // Start fresh 3-day trial
        let now = Date()
        UserDefaults.standard.set(now, forKey: "mytasksai_install_date")
        UserDefaults.standard.set(true, forKey: "mytasksai_trial_started")
        UserDefaults.standard.set(true, forKey: "mytasksai_trial_used")
        installDate = now

        isInTrial = true
        trialDaysRemaining = 3
        isSubscribed = false
        error = nil

        #if DEBUG
        print("🔔 [SubscriptionService] Free trial started - 3 days from \(now)")
        #endif

        return true
    }

    /// Check if user can start a free trial (hasn't used it before)
    var canStartFreeTrial: Bool {
        !UserDefaults.standard.bool(forKey: "mytasksai_trial_used")
    }

    // MARK: - Purchase Monthly Subscription

    func purchaseMonthly() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Fetch offerings if not cached
            if currentOffering == nil {
                await fetchOfferings()
            }

            // If no offerings available (simulator without StoreKit config), start local trial
            guard let monthly = currentOffering?.monthly else {
                #if DEBUG
                print("🔔 [SubscriptionService] No RevenueCat package found - starting local trial")
                _ = startFreeTrial()
                return
                #else
                throw SubscriptionError.packageNotFound
                #endif
            }

            let result = try await Purchases.shared.purchase(package: monthly)

            if result.customerInfo.entitlements[entitlementId]?.isActive == true {
                isSubscribed = true
                isInTrial = result.customerInfo.entitlements[entitlementId]?.periodType == .trial
            } else {
                throw SubscriptionError.purchaseFailed
            }
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()

            if customerInfo.entitlements[entitlementId]?.isActive == true {
                isSubscribed = true
                isInTrial = customerInfo.entitlements[entitlementId]?.periodType == .trial
            } else {
                isSubscribed = false
            }
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Manage Subscription

    func openManageSubscriptions() {
        guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Legacy Compatibility

    var isProUser: Bool {
        canAccessApp
    }

    func checkProAccess() -> Bool {
        canAccessApp
    }
}

// MARK: - Subscription Error

enum SubscriptionError: Error, LocalizedError {
    case packageNotFound
    case purchaseFailed
    case restoreFailed
    case notConfigured
    case trialExpired

    var errorDescription: String? {
        switch self {
        case .packageNotFound:
            return "Subscription package not found"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .restoreFailed:
            return "Unable to restore purchases. Please try again."
        case .notConfigured:
            return "Subscription service not configured. Please add RevenueCat SDK."
        case .trialExpired:
            return "Your free trial has expired. Subscribe to continue."
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case free
    case monthly

    var displayName: String {
        switch self {
        case .free: return "Free Trial"
        case .monthly: return "Pro"
        }
    }

    var price: String {
        switch self {
        case .free: return "3 Days Free"
        case .monthly: return "$9.99/month"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "3 days of full access",
                "All Pro features included",
                "No credit card required"
            ]
        case .monthly:
            return [
                "Unlimited AI-powered tasks",
                "Brain dump thought processing",
                "Smart scheduling suggestions",
                "Full gamification experience",
                "Calendar integration",
                "Priority support",
                "All future features"
            ]
        }
    }
}
