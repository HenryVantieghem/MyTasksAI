//
//  OfflineManager.swift
//  Veloce
//
//  Network Connectivity Monitoring
//  Provides real-time network state with reactive updates
//

import Foundation
import Network
import Combine

// MARK: - Connection State

enum ConnectionState: Equatable {
    case online
    case offline
    case connecting

    var isConnected: Bool {
        self == .online
    }

    var statusText: String {
        switch self {
        case .online: return "Connected"
        case .offline: return "Offline"
        case .connecting: return "Connecting..."
        }
    }

    var iconName: String {
        switch self {
        case .online: return "wifi"
        case .offline: return "wifi.slash"
        case .connecting: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Connection Quality

enum ConnectionQuality: Comparable {
    case unknown
    case poor
    case moderate
    case good
    case excellent

    var shouldSync: Bool {
        self >= .moderate
    }

    var syncDelay: TimeInterval {
        switch self {
        case .unknown, .poor: return 5.0
        case .moderate: return 2.0
        case .good: return 1.0
        case .excellent: return 0.5
        }
    }
}

// MARK: - Offline Manager

@MainActor
@Observable
final class OfflineManager {
    // MARK: Singleton
    static let shared = OfflineManager()

    // MARK: Published State
    private(set) var connectionState: ConnectionState = .connecting
    private(set) var connectionQuality: ConnectionQuality = .unknown
    private(set) var isExpensive: Bool = false
    private(set) var isConstrained: Bool = false
    private(set) var lastOnlineDate: Date?
    private(set) var offlineDuration: TimeInterval = 0

    // MARK: Computed Properties
    var isOnline: Bool { connectionState == .online }
    var isOffline: Bool { connectionState == .offline }
    var shouldDeferSync: Bool { isExpensive || isConstrained || connectionQuality < .moderate }

    // MARK: Network Monitor
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.veloce.network.monitor", qos: .utility)

    // MARK: State Persistence
    private let offlineStartKey = "veloce.offline.startDate"

    // MARK: Publishers
    private var stateSubject = PassthroughSubject<ConnectionState, Never>()
    var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // MARK: Callbacks
    var onConnectionRestored: (() -> Void)?
    var onConnectionLost: (() -> Void)?

    // MARK: Initialization

    private init() {
        setupNetworkMonitoring()
        loadOfflineState()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Network Monitoring Setup

    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func handlePathUpdate(_ path: NWPath) {
        let previousState = connectionState

        // Update connection state
        switch path.status {
        case .satisfied:
            connectionState = .online
            if previousState != .online {
                lastOnlineDate = Date()
                calculateOfflineDuration()
                onConnectionRestored?()
            }

        case .unsatisfied:
            connectionState = .offline
            if previousState == .online {
                saveOfflineStart()
                onConnectionLost?()
            }

        case .requiresConnection:
            connectionState = .connecting

        @unknown default:
            connectionState = .offline
        }

        // Update connection quality
        updateConnectionQuality(path)

        // Update constraints
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        // Publish state change
        if previousState != connectionState {
            stateSubject.send(connectionState)
        }
    }

    private func updateConnectionQuality(_ path: NWPath) {
        guard path.status == .satisfied else {
            connectionQuality = .unknown
            return
        }

        // Determine quality based on interface type
        if path.usesInterfaceType(.wifi) {
            connectionQuality = path.isExpensive ? .moderate : .excellent
        } else if path.usesInterfaceType(.cellular) {
            connectionQuality = path.isConstrained ? .poor : .good
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionQuality = .excellent
        } else {
            connectionQuality = .moderate
        }
    }

    // MARK: - Offline Duration Tracking

    private func saveOfflineStart() {
        UserDefaults.standard.set(Date(), forKey: offlineStartKey)
    }

    private func loadOfflineState() {
        if let startDate = UserDefaults.standard.object(forKey: offlineStartKey) as? Date {
            offlineDuration = Date().timeIntervalSince(startDate)
        }
    }

    private func calculateOfflineDuration() {
        if let startDate = UserDefaults.standard.object(forKey: offlineStartKey) as? Date {
            offlineDuration = Date().timeIntervalSince(startDate)
            UserDefaults.standard.removeObject(forKey: offlineStartKey)
        }
    }

    // MARK: - Utility Methods

    /// Wait for network to become available
    func waitForConnection(timeout: TimeInterval = 30) async -> Bool {
        guard !isOnline else { return true }

        return await withCheckedContinuation { continuation in
            var cancelled = false
            var hasResumed = false

            // Set up timeout
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if !cancelled && !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: false)
                }
            }

            // Subscribe to state changes
            var cancellable: AnyCancellable?
            cancellable = statePublisher
                .filter { $0 == .online }
                .first()
                .sink { _ in
                    cancelled = true
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: true)
                    }
                    cancellable?.cancel()
                }
        }
    }

    /// Refresh network state manually
    func refreshConnectionState() {
        monitor.cancel()
        monitor.start(queue: monitorQueue)
    }

    /// Get human-readable offline duration
    var offlineDurationText: String {
        guard offlineDuration > 0 else { return "" }

        let hours = Int(offlineDuration) / 3600
        let minutes = (Int(offlineDuration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m offline"
        } else if minutes > 0 {
            return "\(minutes) minutes offline"
        } else {
            return "Less than a minute offline"
        }
    }
}
