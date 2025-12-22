//
//  DesignTokens.swift
//  MyTasksAI
//
//  Additional Design Tokens and Constants
//  Numeric values, durations, and component-specific tokens
//

import SwiftUI

// MARK: - Design Tokens
/// Additional design tokens complementing Theme
enum DesignTokens {

    // MARK: - Durations (milliseconds)
    enum Duration {
        static let instant: Double = 0.05
        static let fast: Double = 0.15
        static let normal: Double = 0.3
        static let slow: Double = 0.5
        static let verySlow: Double = 0.8
        static let pageTransition: Double = 0.35

        // AI-specific
        static let aiThinkingCycle: Double = 2.0
        static let aiColorTransition: Double = 0.8
        static let shimmerCycle: Double = 1.5

        // Iridescent
        static let iridescentRotation: Double = 8.0
        static let pulseGlow: Double = 2.0
    }

    // MARK: - Z-Index Layers
    enum ZIndex {
        static let background: Double = 0
        static let content: Double = 1
        static let cards: Double = 2
        static let floatingElements: Double = 3
        static let modals: Double = 4
        static let overlays: Double = 5
        static let alerts: Double = 6
        static let toasts: Double = 7
    }

    // MARK: - Opacity Levels
    enum Opacity {
        static let disabled: Double = 0.4
        static let secondary: Double = 0.6
        static let subtle: Double = 0.15
        static let overlay: Double = 0.5
        static let pressed: Double = 0.8
        static let hover: Double = 0.9
        static let glassBorder: Double = 0.35
        static let glassBackground: Double = 0.15
    }

    // MARK: - Scale Effects
    enum Scale {
        static let pressed: CGFloat = 0.97
        static let pressedStrong: CGFloat = 0.95
        static let expanded: CGFloat = 1.02
        static let focused: CGFloat = 1.01
        static let shrunk: CGFloat = 0.9
    }

    // MARK: - Blur Radius
    enum Blur {
        static let subtle: CGFloat = 4
        static let light: CGFloat = 8
        static let medium: CGFloat = 16
        static let heavy: CGFloat = 24
        static let extreme: CGFloat = 40
        static let glassBackground: CGFloat = 20
        static let iridescentGlow: CGFloat = 60
    }

    // MARK: - Border Width
    enum BorderWidth {
        static let hairline: CGFloat = 0.5
        static let thin: CGFloat = 1
        static let medium: CGFloat = 2
        static let thick: CGFloat = 3
        static let glassBorder: CGFloat = 0.5
        static let focusRing: CGFloat = 2
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let tiny: CGFloat = 12
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 40
        static let huge: CGFloat = 48
        static let tabBar: CGFloat = 24
        static let navBar: CGFloat = 20
    }

    // MARK: - Avatar Sizes
    enum AvatarSize {
        static let tiny: CGFloat = 24
        static let small: CGFloat = 32
        static let medium: CGFloat = 48
        static let large: CGFloat = 64
        static let xLarge: CGFloat = 80
        static let profile: CGFloat = 100
    }

    // MARK: - Component Heights
    enum Height {
        static let button: CGFloat = 50
        static let buttonSmall: CGFloat = 40
        static let buttonLarge: CGFloat = 56
        static let textField: CGFloat = 50
        static let textFieldSmall: CGFloat = 40
        static let searchBar: CGFloat = 44
        static let navigationBar: CGFloat = 44
        static let tabBar: CGFloat = 49
        static let pill: CGFloat = 36
        static let pillSmall: CGFloat = 28
        static let badge: CGFloat = 20
        static let progressBar: CGFloat = 8
        static let divider: CGFloat = 1
        static let taskRow: CGFloat = 72
        static let taskRowCompact: CGFloat = 56
    }

    // MARK: - Sheet Detents
    enum SheetDetent {
        static let small: CGFloat = 0.25
        static let medium: CGFloat = 0.5
        static let large: CGFloat = 0.85
        static let full: CGFloat = 1.0
    }

    // MARK: - Gesture Thresholds
    enum Gesture {
        static let swipeThreshold: CGFloat = 50
        static let dragVelocity: CGFloat = 500
        static let longPressDuration: Double = 0.5
        static let doubleTapInterval: Double = 0.3
    }

    // MARK: - Gamification Values
    enum Gamification {
        // Points
        static let pointsTaskComplete: Int = 10
        static let pointsOnTimeBonus: Int = 5
        static let pointsAIViewed: Int = 2
        static let pointsStreakDay: Int = 20
        static let pointsGoalMet: Int = 50
        static let pointsAchievement: Int = 100

        // Convenience aliases
        static let taskComplete: Int = pointsTaskComplete
        static let onTimeBonus: Int = pointsOnTimeBonus

        // Streak thresholds
        static let streakBronze: Int = 3
        static let streakSilver: Int = 7
        static let streakGold: Int = 30
        static let streakDiamond: Int = 100

        // Task milestones
        static let tasksBronze: Int = 10
        static let tasksSilver: Int = 50
        static let tasksGold: Int = 100
        static let tasksDiamond: Int = 500

        /// Calculate level from total points
        static func level(for points: Int) -> Int {
            max(1, Int(ceil(sqrt(Double(points) / 100))))
        }

        /// Points required for next level
        static func pointsForLevel(_ level: Int) -> Int {
            level * level * 100
        }

        /// Progress to next level (0.0 - 1.0)
        static func progressToNextLevel(points: Int) -> Double {
            let currentLevel = level(for: points)
            let currentLevelPoints = pointsForLevel(currentLevel - 1)
            let nextLevelPoints = pointsForLevel(currentLevel)
            let progress = Double(points - currentLevelPoints) / Double(nextLevelPoints - currentLevelPoints)
            return min(max(progress, 0), 1)
        }
    }

    // MARK: - Energy Core Configuration
    enum EnergyCore {
        // MARK: Sizing
        /// Standard orb size for task cards
        static let size: CGFloat = 28
        /// Large orb for detail view
        static let sizeLarge: CGFloat = 36
        /// Small orb for compact lists
        static let sizeSmall: CGFloat = 22

        // MARK: Rings
        /// Inner ring width
        static let ringInnerWidth: CGFloat = 1.5
        /// Outer ring width (priority indicator)
        static let ringOuterWidth: CGFloat = 2
        /// Ring padding from orb
        static let ringPadding: CGFloat = 3

        // MARK: Animation
        /// Breathing animation duration (medium energy)
        static let breatheDuration: Double = 2.0
        /// Pulse animation duration (high energy)
        static let pulseDuration: Double = 1.0
        /// Particle orbit duration (max energy)
        static let orbitDuration: Double = 3.0
        /// Fill change animation duration
        static let fillDuration: Double = 0.5
        /// Completion implosion duration
        static let implosionDuration: Double = 0.3

        // MARK: Particles
        /// Number of orbiting particles for max energy
        static let particleCount: Int = 6
        /// Particle size
        static let particleSize: CGFloat = 4
        /// Orbit radius multiplier (from center)
        static let orbitRadius: CGFloat = 1.4

        // MARK: Energy Thresholds (points)
        /// Low energy threshold (10-25 points)
        static let lowThreshold: Int = 25
        /// Medium energy threshold (26-50 points)
        static let mediumThreshold: Int = 50
        /// High energy threshold (51-75 points)
        static let highThreshold: Int = 75
        /// Max energy is 76+ points

        // MARK: Glow
        /// Base glow radius
        static let glowRadius: CGFloat = 8
        /// Max glow radius (high energy)
        static let glowRadiusMax: CGFloat = 16
        /// Glow pulse intensity range
        static let glowPulseMin: Double = 0.6
        static let glowPulseMax: Double = 1.0
    }

    // MARK: - Input Bar Configuration
    enum InputBar {
        // MARK: Sizing
        /// Container corner radius
        static let cornerRadius: CGFloat = 24
        /// Container horizontal padding
        static let horizontalPadding: CGFloat = 16
        /// Container vertical padding
        static let verticalPadding: CGFloat = 12
        /// Button size (plus, mic, send)
        static let buttonSize: CGFloat = 36
        /// Button icon size
        static let buttonIconSize: CGFloat = 18
        /// Minimum text field height
        static let minHeight: CGFloat = 44
        /// Maximum expanded height
        static let maxHeight: CGFloat = 120

        // MARK: Spacing
        /// Space between greeting and input
        static let greetingSpacing: CGFloat = 8
        /// Space between elements in input
        static let elementSpacing: CGFloat = 12
        /// Bottom margin from safe area
        static let bottomMargin: CGFloat = 8

        // MARK: Animation
        /// Send button appearance duration
        static let sendAppearDuration: Double = 0.25
        /// Greeting fade duration
        static let greetingFadeDuration: Double = 0.4
        /// Plus button rotation duration
        static let plusRotationDuration: Double = 0.3
        /// Glow animation duration
        static let glowDuration: Double = 2.0
    }

    // MARK: - AI Configuration
    enum AI {
        static let maxAdviceLength: Int = 200
        static let minEstimateMinutes: Int = 1
        static let maxEstimateMinutes: Int = 480
        static let processingTimeoutSeconds: Double = 30
        static let maxRetries: Int = 3
        static let retryDelaySeconds: Double = 1.0
    }

    // MARK: - Calendar Configuration
    enum Calendar {
        static let defaultDuration: Int = 30 // minutes
        static let durationOptions: [Int] = [15, 30, 45, 60, 90, 120, 180, 240]
        static let reminderOptions: [Int] = [0, 5, 15, 30, 60, 1440] // minutes before
        static let weekStartsOnMonday: Bool = true
        static let visibleHoursStart: Int = 6
        static let visibleHoursEnd: Int = 22
    }

    // MARK: - Sync Configuration
    enum Sync {
        static let debounceSeconds: Double = 1.0
        static let batchSize: Int = 50
        static let maxRetries: Int = 3
        static let retryDelaySeconds: Double = 2.0
        static let offlineQueueLimit: Int = 100
    }
}

// MARK: - Spring Configuration
/// Detailed spring animation configurations
struct SpringConfig {
    let response: Double
    let dampingFraction: Double
    let blendDuration: Double

    var animation: Animation {
        .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
    }

    // Presets
    static let snappy = SpringConfig(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    static let bouncy = SpringConfig(response: 0.5, dampingFraction: 0.6, blendDuration: 0)
    static let smooth = SpringConfig(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    static let gentle = SpringConfig(response: 0.6, dampingFraction: 0.85, blendDuration: 0)
    static let stiff = SpringConfig(response: 0.2, dampingFraction: 0.9, blendDuration: 0)
}

// MARK: - Transition Presets
extension AnyTransition {
    /// Slide up with fade
    static var slideUpFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Scale with fade
    static var scaleFade: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }

    /// Slide from leading
    static var slideFromLeading: AnyTransition {
        .move(edge: .leading).combined(with: .opacity)
    }

    /// Slide from trailing
    static var slideFromTrailing: AnyTransition {
        .move(edge: .trailing).combined(with: .opacity)
    }

    /// Pop in (bouncy scale)
    static var popIn: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
}

// MARK: - Animation Extensions
extension Animation {
    /// Bouncy spring for celebrations
    static var bouncy: Animation {
        SpringConfig.bouncy.animation
    }

    /// Snappy spring for quick feedback
    static var snappy: Animation {
        SpringConfig.snappy.animation
    }

    /// Smooth spring for standard transitions
    static var smooth: Animation {
        SpringConfig.smooth.animation
    }

    /// Gentle spring for subtle movements
    static var gentle: Animation {
        SpringConfig.gentle.animation
    }

    /// Stiff spring for precise movements
    static var stiff: Animation {
        SpringConfig.stiff.animation
    }
}
