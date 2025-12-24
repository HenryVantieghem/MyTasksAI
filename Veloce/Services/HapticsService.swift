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

    /// Impact feedback with style (alias)
    func impactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        impact(style)
    }

    /// Success feedback (alias for notification success)
    func successFeedback() {
        notification(.success)
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

    // MARK: - Enhanced Task Completion Haptics

    /// Task completion with satisfying 3-step pattern: soft → medium → success
    func taskCompleteEnhanced() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.taskComplete)
    }

    /// Points earned feedback - intensity scales with amount
    /// - Parameter amount: Points earned (affects intensity, 0-100 scale)
    func pointsEarned(amount: Int) {
        guard hapticsEnabled else { return }

        let normalizedIntensity = min(1.0, Float(amount) / 50.0)

        if supportsHaptics {
            playDynamicPattern(intensity: normalizedIntensity, sharpness: 0.6)
        } else {
            if amount >= 50 {
                notification(.success)
            } else if amount >= 25 {
                impact(.medium)
            } else {
                impact(.light)
            }
        }
    }

    /// Tab switch - crisp light feedback
    func tabSwitch() {
        guard hapticsEnabled else { return }
        impact(.light)
        selection?.selectionChanged()
    }

    /// Streak milestone celebration - escalating pattern
    /// - Parameter days: Current streak day count
    func streakMilestone(days: Int) {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        // Intensity increases with streak length
        if days >= 30 {
            playCustomPattern(.streakEpic)
        } else if days >= 7 {
            playCustomPattern(.streakWeek)
        } else {
            playCustomPattern(.streak)
        }
    }

    /// Card press feedback - scale down feel
    func cardPress() {
        guard hapticsEnabled else { return }
        impact(.soft)
    }

    /// Card release feedback - spring bounce feel
    func cardRelease() {
        guard hapticsEnabled else { return }
        impact(.light)
    }

    /// Orb glow interaction - soft pulsing feel
    func orbGlow() {
        guard hapticsEnabled else { return }
        impact(.soft)
    }

    /// Checkbox toggle with satisfying feedback
    func checkboxToggle(isCompleting: Bool) {
        guard hapticsEnabled else { return }

        if isCompleting {
            taskCompleteEnhanced()
        } else {
            impact(.light)
        }
    }

    /// Send button ready pulse
    func sendReady() {
        guard hapticsEnabled else { return }
        impact(.soft)
    }

    /// Calendar drag feedback
    func calendarDrag() {
        guard hapticsEnabled else { return }
        impact(.light)
    }

    /// Calendar drop feedback
    func calendarDrop() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.calendarDrop)
    }

    /// Swipe action feedback (complete/delete task)
    func swipeAction() {
        guard hapticsEnabled else { return }
        impact(.medium)
    }

    /// Pull to refresh start
    func pullRefreshStart() {
        guard hapticsEnabled else { return }
        impact(.soft)
    }

    /// Pull to refresh threshold reached
    func pullRefreshTriggered() {
        guard hapticsEnabled else { return }
        impact(.medium)
    }

    /// AI processing started
    func aiProcessingStart() {
        guard hapticsEnabled else { return }
        impact(.soft)
    }

    /// AI processing complete
    func aiProcessingComplete() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.aiComplete)
    }

    // MARK: - Gamification Haptics

    /// Combo increase - rising intensity based on combo level
    /// - Parameter comboCount: Current combo count
    func comboUp(comboCount: Int) {
        guard hapticsEnabled, supportsHaptics else {
            if comboCount >= 4 {
                impact(.heavy)
            } else {
                impact(.medium)
            }
            return
        }

        if comboCount >= 6 {
            playCustomPattern(.comboMax)
        } else if comboCount >= 4 {
            playCustomPattern(.comboHigh)
        } else {
            playCustomPattern(.comboUp)
        }
    }

    /// Boss hit - sharp impact for dealing damage
    func bossHit() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.heavy)
            return
        }

        playCustomPattern(.bossHit)
    }

    /// Boss defeated - extended celebration sequence
    func bossDefeated() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.bossDefeated)
    }

    /// Power-up activation - soft pulse → sharp confirm
    func powerUpActivate() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.heavy)
            return
        }

        playCustomPattern(.powerUpActivate)
    }

    /// Secret/rare achievement unlock - mysterious pattern
    func achievementSecret() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.achievementSecret)
    }

    /// Daily quest complete
    func questComplete() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.questComplete)
    }

    /// Milestone reached on a goal
    func milestoneReached() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }

        playCustomPattern(.milestone)
    }

    // MARK: - Dynamic Pattern Playback

    private func playDynamicPattern(intensity: Float, sharpness: Float) {
        guard let engine else { return }

        do {
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: 0)

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            impact(.medium)
        }
    }

    // MARK: - Custom Pattern Playback
    private enum HapticPattern {
        case celebration
        case streak
        case streakWeek
        case streakEpic
        case achievement
        case levelUp
        case taskComplete
        case calendarDrop
        case aiComplete
        // Gamification patterns
        case comboUp
        case comboHigh
        case comboMax
        case bossHit
        case bossDefeated
        case powerUpActivate
        case achievementSecret
        case questComplete
        case milestone

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

            case .taskComplete:
                // 3-step satisfying pattern: soft → medium → success
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.1),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.2)
                ]

            case .streakWeek:
                // 7-day streak celebration - rising intensity
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0, duration: 0.15),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.2),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.35)
                ]

            case .streakEpic:
                // 30+ day streak - extended celebration sequence
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0, duration: 0.3),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.35),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.5),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0.65),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.7, duration: 0.4)
                ]

            case .calendarDrop:
                // Satisfying drop with bounce
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.12),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0.2)
                ]

            case .aiComplete:
                // AI processing complete - smooth rising finish
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0, duration: 0.2),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.25)
                ]

            // MARK: Gamification Patterns

            case .comboUp:
                // Rising intensity for building combo
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.08)
                ]

            case .comboHigh:
                // Higher combo (x2) - more intense rising sequence
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.06),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.12)
                ]

            case .comboMax:
                // Maximum combo (x3) - epic power surge
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0, duration: 0.1),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.1),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.15),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0.2)
                ]

            case .bossHit:
                // Sharp impact for boss damage
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0.08)
                ]

            case .bossDefeated:
                // Extended victory celebration
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0, duration: 0.3),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.35),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.5),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0.65),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.7, duration: 0.5)
                ]

            case .powerUpActivate:
                // Soft pulse → sharp confirm
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0, duration: 0.15),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.2)
                ]

            case .achievementSecret:
                // Mysterious pattern for rare achievements
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ], relativeTime: 0.1, duration: 0.3),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.45),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.6),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0.65, duration: 0.4)
                ]

            case .questComplete:
                // Daily quest complete - satisfying finish
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.1),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.15, duration: 0.2)
                ]

            case .milestone:
                // Goal milestone reached - celebratory
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0, duration: 0.2),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.25),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.35),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
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
