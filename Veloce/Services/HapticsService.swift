//
//  HapticsService.swift
//  MyTasksAI
//
//  Haptic Feedback Service
//  Provides tactile feedback throughout the app
//

import UIKit
import SwiftUI
import CoreHaptics

// MARK: - Haptics Service
@MainActor
final class HapticsService {
    // MARK: Singleton
    static let shared = HapticsService()

    // MARK: Properties
    private var impactLight: UIImpactFeedbackGenerator?
    private var impactMedium: UIImpactFeedbackGenerator?
    private var impactHeavy: UIImpactFeedbackGenerator?
    private var selection: UISelectionFeedbackGenerator?
    private var notification: UINotificationFeedbackGenerator?

    private var supportsHaptics: Bool
    private var engine: CHHapticEngine?

    // MARK: User Preference
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    // MARK: Initialization
    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        prepareGenerators()
        setupHapticEngine()
    }

    // MARK: - Setup
    private func prepareGenerators() {
        impactLight = UIImpactFeedbackGenerator(style: .light)
        impactMedium = UIImpactFeedbackGenerator(style: .medium)
        impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        selection = UISelectionFeedbackGenerator()
        notification = UINotificationFeedbackGenerator()

        // Prepare for immediate use
        impactLight?.prepare()
        impactMedium?.prepare()
        selection?.prepare()
    }

    private func setupHapticEngine() {
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    // MARK: - Basic Feedback
    /// Light impact - UI selection, button taps
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }

        switch style {
        case .light:
            impactLight?.impactOccurred()
        case .medium:
            impactMedium?.impactOccurred()
        case .heavy:
            impactHeavy?.impactOccurred()
        case .soft:
            impactLight?.impactOccurred(intensity: 0.5)
        case .rigid:
            impactHeavy?.impactOccurred(intensity: 0.8)
        @unknown default:
            impactMedium?.impactOccurred()
        }
    }

    /// Selection feedback - picker changes, segment switches
    func selectionFeedback() {
        guard hapticsEnabled else { return }
        selection?.selectionChanged()
    }

    /// Notification feedback - success, warning, error
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        self.notification?.notificationOccurred(type)
    }

    // MARK: - Convenience Methods
    /// Task completion celebration
    func taskComplete() {
        guard hapticsEnabled else { return }
        notification(.success)
    }

    /// Error occurred
    func error() {
        guard hapticsEnabled else { return }
        notification(.error)
    }

    /// Warning
    func warning() {
        guard hapticsEnabled else { return }
        notification(.warning)
    }

    /// Success feedback
    func success() {
        guard hapticsEnabled else { return }
        notification(.success)
    }

    /// Button tap
    func buttonTap() {
        guard hapticsEnabled else { return }
        impact(.light)
    }

    /// Light impact convenience
    func lightImpact() {
        impact(.light)
    }

    /// Medium impact convenience
    func mediumImpact() {
        impact(.medium)
    }

    /// Heavy impact convenience
    func heavyImpact() {
        impact(.heavy)
    }

    /// Soft impact convenience
    func softImpact() {
        impact(.soft)
    }

    /// Rigid impact convenience
    func rigidImpact() {
        impact(.rigid)
    }

    /// Toggle switch
    func toggle() {
        guard hapticsEnabled else { return }
        impact(.medium)
    }

    // MARK: - Custom Patterns
    /// Double tap pattern
    func doubleTap() {
        guard hapticsEnabled, supportsHaptics else { return }

        Task {
            impact(.light)
            try? await Task.sleep(nanoseconds: 100_000_000)
            impact(.light)
        }
    }

    /// Success celebration pattern
    func celebration() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.celebration)
    }

    /// Streak achieved pattern
    func streakAchieved() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.streak)
    }

    /// Achievement unlocked pattern
    func achievementUnlocked() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.achievement)
    }

    /// Level up pattern
    func levelUp() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.levelUp)
    }

    // MARK: - Custom Pattern Playback
    private enum HapticPattern {
        case celebration
        case streak
        case achievement
        case levelUp

        var events: [CHHapticEvent] {
            switch self {
            case .celebration:
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.15),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.3)
                ]

            case .streak:
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0, duration: 0.2),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.25)
                ]

            case .achievement:
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.1),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.2),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0.3, duration: 0.3)
                ]

            case .levelUp:
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0, duration: 0.5),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0.5)
                ]
            }
        }
    }

    private func playCustomPattern(_ pattern: HapticPattern) {
        guard let engine else { return }

        do {
            let hapticPattern = try CHHapticPattern(events: pattern.events, parameters: [])
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: 0)
        } catch {
            // Fallback to simple notification
            notification(.success)
        }
    }
}

// Note: Using SwiftUI's built-in @AppStorage property wrapper
