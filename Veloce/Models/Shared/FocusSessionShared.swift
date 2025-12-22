//
//  FocusSessionShared.swift
//  Veloce
//
//  Shared models for Focus/App Blocking feature
//  Used for communication between main app and extensions via App Groups
//

import Foundation

// MARK: - App Group Configuration

/// App Group container helper for sharing data between app and extensions
public enum FocusAppGroup {
    /// The shared App Group identifier (must match all targets)
    public static let identifier = "group.com.veloce.app"

    /// Shared UserDefaults for quick key-value storage
    public static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    /// Shared container URL for file-based storage
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// Save Codable data to shared container
    public static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        userDefaults?.set(data, forKey: key)
    }

    /// Load Codable data from shared container
    public static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Remove data for key
    public static func remove(forKey key: String) {
        userDefaults?.removeObject(forKey: key)
    }
}

// MARK: - Shared Focus Session

/// Shared model for passing focus session data between app and extensions
/// This is used by DeviceActivityMonitor and Shield extensions
public struct FocusSessionShared: Codable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let taskTitle: String?
    public let taskId: UUID?
    public let duration: Int  // seconds
    public let startTime: Date
    public let endTime: Date
    public let isDeepFocus: Bool
    public let motivationalMessage: String?

    // MARK: Storage Keys
    public static let storageKey = "currentFocusSession"
    public static let sessionEndedKey = "focusSessionEnded"
    public static let endSessionRequestKey = "endFocusSessionRequested"

    // MARK: Computed Properties

    /// Time remaining in seconds
    public var timeRemaining: Int {
        max(0, Int(endTime.timeIntervalSince(Date())))
    }

    /// Progress from 0 to 1
    public var progress: Double {
        guard duration > 0 else { return 0 }
        let elapsed = duration - timeRemaining
        return Double(elapsed) / Double(duration)
    }

    /// Whether the session has expired
    public var isExpired: Bool {
        Date() >= endTime
    }

    /// Formatted time remaining (MM:SS)
    public var formattedTimeRemaining: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        title: String,
        taskTitle: String? = nil,
        taskId: UUID? = nil,
        duration: Int,
        startTime: Date = Date(),
        isDeepFocus: Bool = false,
        motivationalMessage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.taskTitle = taskTitle
        self.taskId = taskId
        self.duration = duration
        self.startTime = startTime
        self.endTime = startTime.addingTimeInterval(TimeInterval(duration))
        self.isDeepFocus = isDeepFocus
        self.motivationalMessage = motivationalMessage ?? FocusSessionShared.randomMotivation()
    }

    // MARK: Motivational Messages

    private static func randomMotivation() -> String {
        let messages = [
            "Stay focused, you've got this!",
            "Deep work leads to great results.",
            "One task at a time, one victory at a time.",
            "Your future self will thank you.",
            "Distractions can wait. Your goals can't.",
            "Focus is a superpower. Use it wisely.",
            "Every minute of focus is an investment.",
            "The magic happens in deep concentration.",
            "Trust the process. Stay present.",
            "Your attention is your most valuable asset."
        ]
        return messages.randomElement() ?? messages[0]
    }
}

// MARK: - Shield Configuration

/// Configuration for the custom blocking screen UI
/// Sent from main app to ShieldConfigurationExtension
public struct ShieldConfigShared: Codable, Sendable, Equatable {
    public let title: String
    public let subtitle: String
    public let primaryButtonLabel: String
    public let secondaryButtonLabel: String?
    public let iconName: String
    public let accentColorHex: String
    public let isDeepFocus: Bool
    public let sessionEndTime: Date?

    // MARK: Storage Key
    public static let storageKey = "shieldConfiguration"

    // MARK: Computed Properties

    /// Time remaining until session ends
    public var timeRemaining: Int? {
        guard let endTime = sessionEndTime else { return nil }
        return max(0, Int(endTime.timeIntervalSince(Date())))
    }

    // MARK: Initialization

    public init(
        title: String = "Stay Focused",
        subtitle: String,
        primaryButtonLabel: String = "Back to Work",
        secondaryButtonLabel: String? = nil,
        iconName: String = "shield.lefthalf.filled",
        accentColorHex: String = "#9440FA",  // Nebula purple
        isDeepFocus: Bool = false,
        sessionEndTime: Date? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.primaryButtonLabel = primaryButtonLabel
        self.secondaryButtonLabel = isDeepFocus ? nil : secondaryButtonLabel
        self.iconName = iconName
        self.accentColorHex = accentColorHex
        self.isDeepFocus = isDeepFocus
        self.sessionEndTime = sessionEndTime
    }

    /// Create configuration for a focus session
    public static func forSession(_ session: FocusSessionShared, blockedAppName: String?) -> ShieldConfigShared {
        let subtitle: String
        if let appName = blockedAppName {
            subtitle = "\(appName) is blocked during your focus session"
        } else {
            subtitle = "This app is blocked during your focus session"
        }

        return ShieldConfigShared(
            title: session.isDeepFocus ? "Deep Focus Active" : "Stay Focused",
            subtitle: subtitle,
            primaryButtonLabel: "Back to Work",
            secondaryButtonLabel: session.isDeepFocus ? nil : "End Session",
            iconName: session.isDeepFocus ? "lock.shield.fill" : "shield.lefthalf.filled",
            accentColorHex: session.isDeepFocus ? "#FF6B6B" : "#9440FA",
            isDeepFocus: session.isDeepFocus,
            sessionEndTime: session.endTime
        )
    }
}

// MARK: - Focus Session Type

/// Types of focus sessions
public enum FocusSessionType: String, Codable, Sendable, CaseIterable {
    case timed = "timed"           // User-initiated, starts immediately
    case scheduled = "scheduled"   // Future start time
    case pomodoro = "pomodoro"     // Linked to Pomodoro timer
    case recurring = "recurring"   // Part of a recurring schedule

    public var displayName: String {
        switch self {
        case .timed: return "Timed Session"
        case .scheduled: return "Scheduled Session"
        case .pomodoro: return "Pomodoro Focus"
        case .recurring: return "Recurring Session"
        }
    }

    public var iconName: String {
        switch self {
        case .timed: return "timer"
        case .scheduled: return "calendar.badge.clock"
        case .pomodoro: return "leaf.fill"
        case .recurring: return "repeat"
        }
    }
}

// MARK: - Blocked App Selection

/// Represents a selection of apps/categories to block
/// Used for persisting user's block list selections
public struct BlockedAppSelection: Codable, Sendable, Equatable {
    /// Serialized ApplicationToken data
    public var applicationTokensData: Data?
    /// Serialized ActivityCategoryToken data
    public var categoryTokensData: Data?
    /// Serialized WebDomainToken data
    public var webDomainTokensData: Data?

    /// Whether this selection includes any items
    public var isEmpty: Bool {
        let appsEmpty = applicationTokensData == nil || applicationTokensData!.isEmpty
        let categoriesEmpty = categoryTokensData == nil || categoryTokensData!.isEmpty
        let domainsEmpty = webDomainTokensData == nil || webDomainTokensData!.isEmpty
        return appsEmpty && categoriesEmpty && domainsEmpty
    }

    public init(
        applicationTokensData: Data? = nil,
        categoryTokensData: Data? = nil,
        webDomainTokensData: Data? = nil
    ) {
        self.applicationTokensData = applicationTokensData
        self.categoryTokensData = categoryTokensData
        self.webDomainTokensData = webDomainTokensData
    }
}

// MARK: - Device Activity Names

/// Custom DeviceActivityName identifiers for monitoring
public extension String {
    static let focusSessionActivity = "com.veloce.focusSession"
    static let scheduledFocusActivity = "com.veloce.scheduledFocus"
    static let recurringFocusActivity = "com.veloce.recurringFocus"
}
