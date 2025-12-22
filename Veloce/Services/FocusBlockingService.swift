//
//  FocusBlockingService.swift
//  Veloce
//
//  Core Focus Blocking Service
//  Manages app blocking via Screen Time API (ManagedSettings, DeviceActivity)
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

// MARK: - Focus Blocking Service

/// Core service for managing app blocking during focus sessions
/// Coordinates between FamilyControls, ManagedSettings, and DeviceActivity frameworks
@MainActor
@Observable
final class FocusBlockingService {
    // MARK: Singleton

    static let shared = FocusBlockingService()

    // MARK: Dependencies

    private let authService = ScreenTimeAuthService.shared

    // MARK: State

    /// Currently active focus session
    private(set) var activeFocusSession: FocusSessionShared?

    /// Whether app blocking is currently active
    private(set) var isBlocking: Bool = false

    /// Current selection of apps to block
    var selectedAppsToBlock: FamilyActivitySelection = FamilyActivitySelection()

    /// Saved block lists (loaded from SwiftData)
    private(set) var savedBlockLists: [String: FamilyActivitySelection] = [:]

    /// Error message if blocking failed
    private(set) var blockingError: String?

    // MARK: Private

    private let store = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()

    // MARK: Keys

    private let selectionKey = "selectedAppsToBlock"
    private let defaultBlockListKey = "defaultBlockList"

    // MARK: Initialization

    private init() {
        loadSavedSelection()
        checkForActiveSession()
    }

    // MARK: - Authorization

    /// Whether the service is authorized to block apps
    var isAuthorized: Bool {
        authService.isAuthorized
    }

    /// Request authorization if not already authorized
    func requestAuthorizationIfNeeded() async throws {
        if !isAuthorized {
            try await authService.requestAuthorization()
        }
    }

    // MARK: - Session Management

    /// Start a new focus session with app blocking
    /// - Parameters:
    ///   - title: Session title
    ///   - duration: Duration in seconds
    ///   - taskId: Optional linked task ID
    ///   - taskTitle: Optional linked task title
    ///   - isDeepFocus: Whether this is an unbreakable Deep Focus session
    ///   - selection: Apps/categories to block (uses current selection if nil)
    func startSession(
        title: String,
        duration: Int,
        taskId: UUID? = nil,
        taskTitle: String? = nil,
        isDeepFocus: Bool = false,
        selection: FamilyActivitySelection? = nil
    ) async throws {
        guard isAuthorized else {
            throw FocusBlockingError.notAuthorized
        }

        blockingError = nil

        // Use provided selection or current selection
        let appsToBlock = selection ?? selectedAppsToBlock

        // Validate we have something to block
        guard !appsToBlock.applicationTokens.isEmpty ||
              !appsToBlock.categoryTokens.isEmpty else {
            throw FocusBlockingError.noAppsSelected
        }

        // Create session
        let session = FocusSessionShared(
            title: title,
            taskTitle: taskTitle,
            taskId: taskId,
            duration: duration,
            isDeepFocus: isDeepFocus
        )

        // Save session to App Group for extensions
        FocusAppGroup.save(session, forKey: FocusSessionShared.storageKey)

        // Create shield configuration
        let shieldConfig = ShieldConfigShared.forSession(session, blockedAppName: nil)
        FocusAppGroup.save(shieldConfig, forKey: ShieldConfigShared.storageKey)

        // Apply blocking restrictions
        applyBlocking(selection: appsToBlock)

        // Start device activity monitoring
        try startMonitoring(for: session)

        // Update state
        activeFocusSession = session
        isBlocking = true

        // Haptic feedback
        HapticsService.shared.impact()
    }

    /// End the current focus session
    /// - Parameter completed: Whether the session was completed naturally (not canceled)
    func endSession(completed: Bool = false) async {
        // Clear restrictions
        clearBlocking()

        // Stop monitoring
        stopMonitoring()

        // Clear App Group data
        FocusAppGroup.remove(forKey: FocusSessionShared.storageKey)
        FocusAppGroup.remove(forKey: ShieldConfigShared.storageKey)
        FocusAppGroup.remove(forKey: FocusSessionShared.sessionEndedKey)
        FocusAppGroup.remove(forKey: FocusSessionShared.endSessionRequestKey)

        // Award points if completed
        if completed, let session = activeFocusSession {
            await awardSessionPoints(session: session)
        }

        // Update state
        activeFocusSession = nil
        isBlocking = false

        // Haptic feedback
        HapticsService.shared.taskComplete()
    }

    /// Check if Deep Focus mode can be canceled
    var canCancelSession: Bool {
        guard let session = activeFocusSession else { return true }
        return !session.isDeepFocus
    }

    // MARK: - Blocking Control

    /// Apply blocking restrictions to selected apps
    private func applyBlocking(selection: FamilyActivitySelection) {
        // Shield selected applications
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens

        // Shield selected categories
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        // Shield web domains if any
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    /// Clear all blocking restrictions
    private func clearBlocking() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    // MARK: - Device Activity Monitoring

    /// Start monitoring for session end
    private func startMonitoring(for session: FocusSessionShared) throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: false
        )

        // Create activity name with session ID
        let activityName = DeviceActivityName(rawValue: "\(String.focusSessionActivity).\(session.id.uuidString)")

        // Create event for session end
        let endEvent = DeviceActivityEvent(
            threshold: DateComponents(second: session.duration)
        )

        do {
            try deviceActivityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: [
                    DeviceActivityEvent.Name(rawValue: "sessionEnd"): endEvent
                ]
            )
        } catch {
            blockingError = "Failed to start monitoring: \(error.localizedDescription)"
            throw FocusBlockingError.monitoringFailed(error)
        }
    }

    /// Stop all device activity monitoring
    private func stopMonitoring() {
        deviceActivityCenter.stopMonitoring()
    }

    // MARK: - Selection Management

    /// Save current selection to UserDefaults
    func saveSelection() {
        // Selection contains opaque tokens that can be encoded
        if let data = try? PropertyListEncoder().encode(selectedAppsToBlock) {
            FocusAppGroup.userDefaults?.set(data, forKey: selectionKey)
        }
    }

    /// Load saved selection from UserDefaults
    private func loadSavedSelection() {
        guard let data = FocusAppGroup.userDefaults?.data(forKey: selectionKey),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }
        selectedAppsToBlock = selection
    }

    /// Clear current selection
    func clearSelection() {
        selectedAppsToBlock = FamilyActivitySelection()
        FocusAppGroup.userDefaults?.removeObject(forKey: selectionKey)
    }

    /// Update selection from FamilyActivityPicker
    func updateSelection(_ selection: FamilyActivitySelection) {
        selectedAppsToBlock = selection
        saveSelection()
    }

    // MARK: - Session State

    /// Check for active session on app launch
    private func checkForActiveSession() {
        // Check if there's an active session in App Group
        if let session = FocusAppGroup.load(FocusSessionShared.self, forKey: FocusSessionShared.storageKey) {
            if !session.isExpired {
                activeFocusSession = session
                isBlocking = true
            } else {
                // Session expired while app was closed
                Task {
                    await endSession(completed: true)
                }
            }
        }

        // Check for end session request from extension
        if FocusAppGroup.userDefaults?.bool(forKey: FocusSessionShared.endSessionRequestKey) == true {
            Task {
                await endSession(completed: false)
            }
        }
    }

    /// Refresh session state (call from app foreground)
    func refreshSessionState() {
        checkForActiveSession()
    }

    // MARK: - Gamification

    /// Award points for completing a focus session
    private func awardSessionPoints(session: FocusSessionShared) async {
        let gamificationService = GamificationService.shared

        // Base points for completing a focus session
        var points = 25

        // Bonus for Deep Focus
        if session.isDeepFocus {
            points += 50
        }

        // Bonus for longer sessions (1 hour+)
        if session.duration >= 3600 {
            points += 15
        }

        // Award the points
        _ = gamificationService.awardPoints(points)
    }

    // MARK: - Selection Summary

    /// Human-readable summary of current selection
    var selectionSummary: String {
        let appCount = selectedAppsToBlock.applicationTokens.count
        let categoryCount = selectedAppsToBlock.categoryTokens.count

        if appCount == 0 && categoryCount == 0 {
            return "No apps selected"
        }

        var parts: [String] = []
        if appCount > 0 {
            parts.append("\(appCount) app\(appCount == 1 ? "" : "s")")
        }
        if categoryCount > 0 {
            parts.append("\(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")")
        }

        return parts.joined(separator: ", ")
    }

    /// Whether any apps are selected for blocking
    var hasAppsSelected: Bool {
        !selectedAppsToBlock.applicationTokens.isEmpty ||
        !selectedAppsToBlock.categoryTokens.isEmpty
    }
}

// MARK: - Focus Blocking Errors

enum FocusBlockingError: LocalizedError {
    case notAuthorized
    case noAppsSelected
    case sessionAlreadyActive
    case monitoringFailed(Error)
    case deepFocusCannotCancel

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Screen Time access is not authorized. Please enable it in Settings to use app blocking."
        case .noAppsSelected:
            return "Please select at least one app or category to block."
        case .sessionAlreadyActive:
            return "A focus session is already active."
        case .monitoringFailed(let error):
            return "Failed to start session monitoring: \(error.localizedDescription)"
        case .deepFocusCannotCancel:
            return "Deep Focus sessions cannot be ended early. Stay focused!"
        }
    }
}
