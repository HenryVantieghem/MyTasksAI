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

    // MARK: - ✨ Ultra-Premium Haptic Patterns

    /// Epic Task Complete - The ultimate ~1.5s celebration sequence
    /// Full 7-phase crescendo: anticipation → confirmation → crescendo → burst → afterglow → sparkles → settle
    /// Perfectly synchronized with TaskCardV5's epic celebration animation
    func epicTaskComplete() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }
        playCustomPattern(.epicTaskComplete)
    }

    /// Dopamine burst - The ultimate task completion feeling
    /// A euphoric cascade that feels like pure accomplishment
    func dopamineBurst() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }
        playCustomPattern(.dopamineBurst)
    }

    /// Magnetic snap - Satisfying lock-in feeling for selections
    /// Like snapping a magnetic piece perfectly into place
    func magneticSnap() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.rigid)
            return
        }
        playCustomPattern(.magneticSnap)
    }

    /// Cosmic pulse - Deep resonant pulse for major achievements
    /// A wave of energy that radiates outward
    func cosmicPulse() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }
        playCustomPattern(.cosmicPulse)
    }

    /// Starburst ascend - Rising success pattern for level ups
    /// Energy builds and explodes upward
    func starburstAscend() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }
        playCustomPattern(.starburstAscend)
    }

    /// Gravity drop - Satisfying weight drop for confirmations
    /// Like dropping something heavy and solid
    func gravityDrop() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.heavy)
            return
        }
        playCustomPattern(.gravityDrop)
    }

    /// Sparkle cascade - Gentle cascading sparkles for delightful moments
    /// Light touches that dance across the senses
    func sparkleCascade() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.light)
            return
        }
        playCustomPattern(.sparkleCascade)
    }

    /// Heartbeat pulse - Rhythmic pulse for streaks and momentum
    /// A living, breathing feeling of progress
    func heartbeatPulse() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.medium)
            return
        }
        playCustomPattern(.heartbeatPulse)
    }

    /// Whoosh glide - Smooth transition feeling for navigation
    /// Like air rushing past during movement
    func whooshGlide() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.soft)
            return
        }
        playCustomPattern(.whooshGlide)
    }

    /// Electric surge - Quick energy burst for power-ups and boosts
    /// Sharp electricity coursing through
    func electricSurge() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.rigid)
            return
        }
        playCustomPattern(.electricSurge)
    }

    /// Ripple wave - Expanding wave for notifications and alerts
    /// A wave that radiates outward from center
    func rippleWave() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.warning)
            return
        }
        playCustomPattern(.rippleWave)
    }

    // MARK: - 🔮 Liquid Glass Haptic Patterns

    /// Glass focus - Subtle crystalline touch when focusing text fields
    /// Like tapping on a fine crystal glass
    func glassFocus() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.soft)
            return
        }
        playCustomPattern(.glassFocus)
    }

    /// Glass morph - Smooth transition feel for glass morphing animations
    /// Fluid sensation like mercury flowing
    func glassMorph() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.light)
            return
        }
        playCustomPattern(.glassMorph)
    }

    /// Form submit - Anticipation → success pattern for form submissions
    /// Builds tension then releases with confirmation
    func formSubmit() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }
        playCustomPattern(.formSubmit)
    }

    /// Onboarding complete - Epic cosmic celebration for completing onboarding
    /// The ultimate journey completion feeling
    func onboardingComplete() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }
        playCustomPattern(.onboardingComplete)
    }

    /// Page transition - Whoosh with settle for navigation transitions
    /// Smooth glide with satisfying landing
    func pageTransition() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.soft)
            return
        }
        playCustomPattern(.pageTransition)
    }

    /// Glass button press - Premium feedback for liquid glass buttons
    /// Subtle but satisfying crystalline press
    func glassButtonPress() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.medium)
            return
        }
        playCustomPattern(.glassButtonPress)
    }

    /// Success confirm - Confirmation feedback for successful actions
    /// Clear and satisfying confirmation
    func successConfirm() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }
        playCustomPattern(.successConfirm)
    }

    /// Auth success - Special pattern for successful authentication
    /// Triumphant and welcoming
    func authSuccess() {
        guard hapticsEnabled, supportsHaptics else {
            notification(.success)
            return
        }
        playCustomPattern(.authSuccess)
    }

    // MARK: - Premium Interaction Patterns

    /// Button press - Satisfying immediate feedback
    func premiumButtonPress() {
        guard hapticsEnabled else { return }
        impact(.medium)
    }

    /// Button release with bounce
    func premiumButtonRelease() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.light)
            return
        }
        playDynamicPattern(intensity: 0.3, sharpness: 0.8)
    }

    /// Sheet presentation with elegant weight
    func sheetPresent() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.medium)
            return
        }
        playCustomPattern(.sheetPresent)
    }

    /// Sheet dismissal with satisfying close
    func sheetDismiss() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.light)
            return
        }
        playDynamicPattern(intensity: 0.5, sharpness: 0.4)
    }

    /// Threshold crossed - For swipe actions and pull-to-refresh
    func thresholdCrossed() {
        guard hapticsEnabled else { return }
        impact(.rigid)
    }

    /// Scroll snap - For paginated scrolling
    func scrollSnap() {
        guard hapticsEnabled else { return }
        selectionFeedback()
    }

    /// Long press recognized
    func longPressRecognized() {
        guard hapticsEnabled, supportsHaptics else {
            impact(.heavy)
            return
        }
        playCustomPattern(.longPressRecognized)
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
        // ✨ Ultra-Premium patterns
        case dopamineBurst
        case magneticSnap
        case cosmicPulse
        case starburstAscend
        case gravityDrop
        case sparkleCascade
        case heartbeatPulse
        case whooshGlide
        case electricSurge
        case rippleWave
        case sheetPresent
        case longPressRecognized
        // Epic Task Completion (~1.5s full sequence)
        case epicTaskComplete
        // 🔮 Liquid Glass patterns
        case glassFocus
        case glassMorph
        case formSubmit
        case onboardingComplete
        case pageTransition
        case glassButtonPress
        case successConfirm
        case authSuccess

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

            // MARK: ✨ Ultra-Premium Patterns

            case .dopamineBurst:
                // The ultimate task completion - euphoric cascade
                // Builds anticipation → explosive climax → satisfying fade
                return [
                    // Anticipation build
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0, duration: 0.08),
                    // First spark
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.08),
                    // Growing energy
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.12),
                    // CLIMAX - The dopamine hit
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.16),
                    // Resonant afterglow
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0.2, duration: 0.15),
                    // Final sparkle
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.38)
                ]

            case .magneticSnap:
                // Satisfying lock-in - like magnets clicking together
                return [
                    // Approach tension
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0, duration: 0.05),
                    // SNAP - Sharp satisfying click
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.95),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0.05),
                    // Tiny settle bounce
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.1)
                ]

            case .cosmicPulse:
                // Deep resonant pulse - a wave of energy
                return [
                    // Deep bass rumble start
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ], relativeTime: 0, duration: 0.25),
                    // Wave peak
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.12),
                    // Resonance fade
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                    ], relativeTime: 0.28, duration: 0.2)
                ]

            case .starburstAscend:
                // Rising energy that explodes - for level ups
                return [
                    // Building energy (low to high)
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.05),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.1),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.14),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.85),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75)
                    ], relativeTime: 0.17),
                    // BURST - The explosion
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0.2),
                    // Starburst scatter
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.22, duration: 0.18)
                ]

            case .gravityDrop:
                // Heavy satisfying drop - for confirmations
                return [
                    // Weightless moment
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0),
                    // IMPACT - Heavy landing
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.08),
                    // Ground shake
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                    ], relativeTime: 0.1, duration: 0.12),
                    // Settle bounce
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0.24)
                ]

            case .sparkleCascade:
                // Gentle cascading sparkles - delightful moments
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                    ], relativeTime: 0.06),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.95)
                    ], relativeTime: 0.11),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.18),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.22),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.88)
                    ], relativeTime: 0.24)
                ]

            case .heartbeatPulse:
                // Rhythmic pulse - living, breathing progress
                return [
                    // First beat (lub)
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0),
                    // Second beat (dub)
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
                    ], relativeTime: 0.12)
                ]

            case .whooshGlide:
                // Smooth transition - air rushing past
                return [
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0, duration: 0.1),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.05, duration: 0.08),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.12, duration: 0.06)
                ]

            case .electricSurge:
                // Quick sharp electricity - power-ups
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.95)
                    ], relativeTime: 0.03),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0.06),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.1)
                ]

            case .rippleWave:
                // Expanding wave - notifications
                return [
                    // Center impact
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0),
                    // First ripple
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.08, duration: 0.1),
                    // Second ripple
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                    ], relativeTime: 0.2, duration: 0.1)
                ]

            case .sheetPresent:
                // Elegant sheet presentation with weight
                return [
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0),
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.05, duration: 0.12)
                ]

            case .longPressRecognized:
                // Long press recognition - satisfying confirm
                return [
                    // Initial hold feedback
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0, duration: 0.1),
                    // Recognition pop
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.85),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.1)
                ]

            case .epicTaskComplete:
                // ✨ EPIC TASK COMPLETION - The Ultimate Celebration (~1.5s)
                // A crescendo of euphoria culminating in pure accomplishment
                return [
                    // Phase 1: Soft anticipation (T+0ms)
                    // The moment of intention, the finger touches down
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0),

                    // Phase 2: Medium confirmation (T+100ms)
                    // The checkbox starts to fill, momentum building
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.1),

                    // Phase 3: Rising crescendo (T+200ms, T+280ms, T+360ms)
                    // Energy builds exponentially toward climax
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.2),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.28),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                    ], relativeTime: 0.36),

                    // Phase 4: Particle burst accent (T+400ms)
                    // The visual explosion triggers haptic starburst
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.4),

                    // Phase 5: Satisfying resonant tail (T+450ms, 0.25s duration)
                    // The warm afterglow of accomplishment
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.45, duration: 0.25),

                    // Phase 6: XP sparkle accents (T+700ms, T+800ms, T+900ms)
                    // Light touches as XP flies upward
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.7),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.8),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.9),

                    // Phase 7: Final settle (T+1000ms)
                    // The gentle landing, task complete, pure satisfaction
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 1.0, duration: 0.15)
                ]

            // MARK: 🔮 Liquid Glass Patterns

            case .glassFocus:
                // Subtle crystalline touch - like tapping fine crystal
                // Delicate and refined for text field focus
                return [
                    // Initial crystal touch
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                    ], relativeTime: 0),
                    // Subtle resonance
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.03, duration: 0.06)
                ]

            case .glassMorph:
                // Fluid sensation like mercury flowing
                // Smooth transition for glass morphing animations
                return [
                    // Fluid start
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0, duration: 0.15),
                    // Mid-morph pulse
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.08),
                    // Settle into new form
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                    ], relativeTime: 0.15, duration: 0.1)
                ]

            case .formSubmit:
                // Anticipation → success for form submissions
                // Builds tension then releases with confirmation
                return [
                    // Anticipation build
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0, duration: 0.12),
                    // Rising tension
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.1),
                    // Success burst
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.2),
                    // Satisfying confirmation
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.25, duration: 0.15)
                ]

            case .onboardingComplete:
                // Epic cosmic celebration for completing onboarding
                // The ultimate journey completion (~1.2s)
                return [
                    // Lift off
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 0, duration: 0.2),
                    // Rising energy
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.15),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.25),
                    // Cosmic burst
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.35),
                    // Starburst scatter
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.4, duration: 0.3),
                    // Sparkle accents
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.6),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.65)
                    ], relativeTime: 0.75),
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.9),
                    // Final cosmic settle
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ], relativeTime: 1.0, duration: 0.2)
                ]

            case .pageTransition:
                // Whoosh with settle for navigation transitions
                // Smooth glide with satisfying landing
                return [
                    // Whoosh start
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0, duration: 0.08),
                    // Glide peak
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.05, duration: 0.1),
                    // Settle
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.15),
                    // Final rest
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.18, duration: 0.05)
                ]

            case .glassButtonPress:
                // Premium feedback for liquid glass buttons
                // Crystalline press with subtle resonance
                return [
                    // Initial crystalline impact
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0),
                    // Glass resonance
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.03, duration: 0.08),
                    // Subtle settle
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.12)
                ]

            case .successConfirm:
                // Clear and satisfying confirmation
                // Definitive success feeling
                return [
                    // Confirmation tap
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0),
                    // Success resonance
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.05, duration: 0.12),
                    // Final clarity
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.18)
                ]

            case .authSuccess:
                // Triumphant and welcoming authentication success
                // Gateway opening feeling
                return [
                    // Unlock click
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0),
                    // Gateway opening
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ], relativeTime: 0.05, duration: 0.15),
                    // Welcome burst
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.15),
                    // Warm embrace
                    CHHapticEvent(eventType: .hapticContinuous, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                    ], relativeTime: 0.2, duration: 0.2),
                    // Sparkle welcome
                    CHHapticEvent(eventType: .hapticTransient, parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.35)
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
