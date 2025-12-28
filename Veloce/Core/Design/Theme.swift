//
//  Theme.swift
//  MyTasksAI
//
//  Comprehensive Design System
//  Award-Winning Visual Language with AI-Inspired Aesthetics
//

import SwiftUI

// MARK: - Theme
/// Central design system namespace
enum Theme {

    // MARK: - Celestial Colors (Unified Color System)
    /// The definitive color palette for the Celestial Void aesthetic
    /// All other color references should eventually migrate to this
    enum CelestialColors {
        // MARK: Deep Space Blacks (Layered Depth)
        /// True deep space - the darkest background
        static let void = Color(red: 0.02, green: 0.02, blue: 0.04)
        /// Ultimate void - even darker for depth layers
        static let voidDeep = Color(red: 0.01, green: 0.01, blue: 0.03)
        /// Card backgrounds on void
        static let abyss = Color(red: 0.04, green: 0.04, blue: 0.06)
        /// Elevated surfaces
        static let nebulaDust = Color(red: 0.06, green: 0.06, blue: 0.10)

        // MARK: Bioluminescent Accents (Living Cosmos)
        /// Plasma core - bright cyan energy
        static let plasmaCore = Color(red: 0.4, green: 0.9, blue: 1.0)
        /// Aurora green - organic vitality
        static let auroraGreen = Color(red: 0.2, green: 1.0, blue: 0.6)
        /// Solar flare - warm energy burst
        static let solarFlare = Color(red: 1.0, green: 0.7, blue: 0.3)
        /// Supernova white - completion celebration
        static let supernovaWhite = Color(red: 1.0, green: 0.98, blue: 0.95)

        // MARK: Urgency Spectrum (Time-Based Glow)
        /// Calm cyan - plenty of time remaining
        static let urgencyCalm = Color(hex: "06B6D4")
        /// Near amber - deadline approaching
        static let urgencyNear = Color(hex: "FBBF24")
        /// Critical red - overdue or imminent
        static let urgencyCritical = Color(hex: "EF4444")

        // MARK: Nebula Core (Primary AI Palette)
        /// Vivid purple - primary AI accent
        static let nebulaCore = Color(red: 0.58, green: 0.25, blue: 0.98)
        /// Blue-shifted glow
        static let nebulaGlow = Color(red: 0.42, green: 0.45, blue: 0.98)
        /// Cyan rim for highlights
        static let nebulaEdge = Color(red: 0.20, green: 0.78, blue: 0.95)

        // MARK: Stellar Accents (Text & Icons on Dark)
        /// Pure white for primary text
        static let starWhite = Color.white
        /// 60% white for secondary text
        static let starDim = Color.white.opacity(0.6)
        /// 25% white for ghost/hint elements
        static let starGhost = Color.white.opacity(0.25)

        // MARK: Status Nebulae (Semantic Colors)
        /// Success green with cosmic tint
        static let successNebula = Color(red: 0.20, green: 0.85, blue: 0.55)
        /// Warning amber
        static let warningNebula = Color(red: 0.98, green: 0.75, blue: 0.25)
        /// Error red with warmth
        static let errorNebula = Color(red: 0.98, green: 0.35, blue: 0.40)

        // MARK: Glass Constants
        /// Consistent border opacity for all glass effects
        static let glassBorderOpacity: Double = 0.25
        /// Selected/focused border opacity
        static let glassBorderFocusedOpacity: Double = 0.4

        // MARK: Gradients
        /// Primary nebula gradient (purple → blue → cyan)
        static var nebulaGradient: LinearGradient {
            LinearGradient(
                colors: [nebulaCore, nebulaGlow, nebulaEdge],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Subtle border gradient for glass effects
        static func glassBorder(opacity: Double = glassBorderOpacity) -> LinearGradient {
            LinearGradient(
                colors: [
                    nebulaCore.opacity(opacity),
                    nebulaEdge.opacity(opacity * 0.5),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Task Card Colors (Genius Card System)
    /// Color palette for the revolutionary task card experience
    /// Each color is carefully chosen for emotional impact and visual hierarchy
    enum TaskCardColors {
        // MARK: Task Type Colors (Bioluminescent)
        /// CREATE tasks - Creative work, writing, designing
        static let create = Color(red: 0.58, green: 0.25, blue: 0.98)       // Nebula Purple
        /// COMMUNICATE tasks - Emails, calls, meetings
        static let communicate = Color(red: 0.30, green: 0.55, blue: 0.98)  // Stellar Blue
        /// CONSUME tasks - Reading, learning, watching
        static let consume = Color(red: 0.20, green: 0.85, blue: 0.75)      // Cosmic Teal
        /// COORDINATE tasks - Admin, organizing, planning
        static let coordinate = Color(red: 0.95, green: 0.80, blue: 0.25)   // Solar Yellow

        // MARK: Module Accent Colors
        /// Emotional Check-In - Warm, compassionate
        static let emotional = Color(red: 0.98, green: 0.45, blue: 0.65)    // Warm Rose
        /// START HERE - Achievement, action
        static let startHere = Color(red: 0.30, green: 0.90, blue: 0.50)    // Achievement Green
        /// AI Strategy - Intelligence, wisdom
        static let strategy = Color(red: 0.65, green: 0.35, blue: 0.98)     // AI Purple
        /// Resources - Knowledge, learning
        static let resources = Color(red: 0.35, green: 0.65, blue: 0.98)    // Knowledge Blue
        /// Smart Schedule - Time, planning
        static let schedule = Color(red: 0.25, green: 0.85, blue: 0.95)     // Time Cyan
        /// Work Mode - Focus, energy
        static let workMode = Color(red: 0.98, green: 0.55, blue: 0.25)     // Focus Orange

        // MARK: Points & Gamification
        /// Points glow - Reward, achievement
        static let pointsGlow = Color(red: 0.98, green: 0.65, blue: 0.15)   // Fire Gold
        /// Streak fire - Momentum, consistency
        static let streakFire = Color(red: 0.98, green: 0.40, blue: 0.20)   // Hot Orange

        // MARK: Void Spectrum (Dark backgrounds)
        static let void = Color(red: 0.02, green: 0.02, blue: 0.04)
        static let abyss = Color(red: 0.04, green: 0.04, blue: 0.06)
        static let nebulaDust = Color(red: 0.08, green: 0.08, blue: 0.12)

        // MARK: Iridescent Gradient (Animation palette)
        static let iridescent: [Color] = [
            Color(red: 0.98, green: 0.45, blue: 0.65),  // Rose
            Color(red: 0.65, green: 0.35, blue: 0.98),  // Purple
            Color(red: 0.35, green: 0.65, blue: 0.98),  // Blue
            Color(red: 0.25, green: 0.85, blue: 0.95),  // Cyan
            Color(red: 0.98, green: 0.45, blue: 0.65)   // Rose (loop)
        ]

        // MARK: Task Type Gradient
        static var taskTypeGradient: LinearGradient {
            LinearGradient(
                colors: [create, communicate, consume, coordinate],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // MARK: Module Gradient (for sheet background)
        static func moduleGradient(for accent: Color) -> LinearGradient {
            LinearGradient(
                colors: [accent.opacity(0.15), accent.opacity(0.05), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Task Section Colors (Kanban & List Sections)
    /// Vibrant gradient palette for task sections inspired by Apple widget designs
    /// Creates 3D depth and premium visual hierarchy for Smart List and Kanban views
    enum TaskSectionColors {
        // MARK: Section Accent Colors
        /// In Progress - Warm amber/orange energy (active work)
        static let inProgressPrimary = Color(hex: "FBBF24")   // Amber
        static let inProgressSecondary = Color(hex: "F97316") // Orange

        /// To Do - Cosmic purple/blue nebula (pending tasks)
        static let toDoPrimary = CelestialColors.nebulaCore   // Purple
        static let toDoSecondary = Color(red: 0.28, green: 0.52, blue: 0.98) // AI Blue

        /// Done - Success green/teal aurora (completed)
        static let donePrimary = CelestialColors.auroraGreen  // Green
        static let doneSecondary = Color(hex: "2DD4BF")       // Teal

        // MARK: Section Gradients (Apple Widget Style)
        /// In Progress: Amber → Orange glow (pulsing for active work)
        static var inProgressGradient: LinearGradient {
            LinearGradient(
                colors: [inProgressPrimary, inProgressSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// To Do: Purple → Blue nebula (cosmic depth)
        static var toDoGradient: LinearGradient {
            LinearGradient(
                colors: [toDoPrimary, toDoSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Done: Green → Teal success aurora
        static var doneGradient: LinearGradient {
            LinearGradient(
                colors: [donePrimary, doneSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // MARK: 3D Orb Gradients (For Section Headers)
        /// Creates a 3D glowing orb effect for section indicators
        static func orbGradient(primary: Color) -> RadialGradient {
            RadialGradient(
                colors: [.white, primary, primary.opacity(0.8)],
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadius: 0,
                endRadius: 8
            )
        }

        /// Outer glow for orb (adds depth)
        static func orbGlow(color: Color, intensity: Double = 0.4) -> Color {
            color.opacity(intensity)
        }

        // MARK: Card Tint Backgrounds
        /// Subtle tint for task cards based on section
        static func cardTint(for section: String) -> Color {
            switch section.lowercased() {
            case "in progress", "inprogress":
                return inProgressPrimary.opacity(0.06)
            case "to do", "todo":
                return toDoPrimary.opacity(0.06)
            case "done", "completed":
                return donePrimary.opacity(0.06)
            default:
                return Color.clear
            }
        }

        // MARK: Dynamic Gradient Selection
        static func gradient(for section: String) -> LinearGradient {
            switch section.lowercased() {
            case "in progress", "inprogress":
                return inProgressGradient
            case "to do", "todo":
                return toDoGradient
            case "done", "completed":
                return doneGradient
            default:
                return toDoGradient
            }
        }

        static func primaryColor(for section: String) -> Color {
            switch section.lowercased() {
            case "in progress", "inprogress":
                return inProgressPrimary
            case "to do", "todo":
                return toDoPrimary
            case "done", "completed":
                return donePrimary
            default:
                return toDoPrimary
            }
        }
    }

    // MARK: - Energy Core Colors (Power Meter System)
    /// Color palette for the Energy Core power visualization
    enum EnergyColors {
        // MARK: Fill Gradients (by energy level)
        /// Low energy fill (10-25pts) - dim, dormant
        static let lowFill = LinearGradient(
            colors: [
                Color(red: 0.25, green: 0.25, blue: 0.35).opacity(0.6),
                Color(red: 0.35, green: 0.35, blue: 0.45).opacity(0.4)
            ],
            startPoint: .bottom,
            endPoint: .top
        )

        /// Medium energy fill (26-50pts) - charging
        static let mediumFill = LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.35, blue: 0.85),
                Color(red: 0.55, green: 0.45, blue: 0.95).opacity(0.7)
            ],
            startPoint: .bottom,
            endPoint: .top
        )

        /// High energy fill (51-75pts) - pulsing
        static let highFill = LinearGradient(
            colors: [
                Color(red: 0.58, green: 0.25, blue: 0.98),
                Color(red: 0.68, green: 0.45, blue: 1.0),
                Color(red: 0.42, green: 0.45, blue: 0.98).opacity(0.8)
            ],
            startPoint: .bottom,
            endPoint: .top
        )

        /// Max energy fill (76-100pts) - overflow, iridescent
        static let maxFill = LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.45, blue: 0.65),
                Color(red: 0.65, green: 0.35, blue: 0.98),
                Color(red: 0.35, green: 0.65, blue: 0.98),
                Color(red: 0.25, green: 0.85, blue: 0.95)
            ],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )

        // MARK: Glow Colors
        /// Dim glow for low energy
        static let glowDim = Color(red: 0.35, green: 0.35, blue: 0.45).opacity(0.2)
        /// Medium glow for breathing state
        static let glowMedium = Color(red: 0.58, green: 0.35, blue: 0.85).opacity(0.4)
        /// Bright glow for pulsing state
        static let glowBright = Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.6)
        /// Intense glow for max energy
        static let glowMax = Color(red: 0.65, green: 0.35, blue: 0.98).opacity(0.8)

        // MARK: Particle Colors
        /// Orbiting particle colors for max energy
        static let particleColors: [Color] = [
            Color(red: 0.98, green: 0.45, blue: 0.65),
            Color(red: 0.65, green: 0.35, blue: 0.98),
            Color(red: 0.35, green: 0.65, blue: 0.98),
            Color(red: 0.25, green: 0.85, blue: 0.95),
            Color(red: 0.98, green: 0.82, blue: 0.35)
        ]

        // MARK: Ring Colors
        /// Inner ring for the power meter
        static let ringInner = Color.white.opacity(0.15)
        /// Outer ring accent
        static let ringOuter = Color.white.opacity(0.08)
        /// Charged ring when high energy
        static let ringCharged = Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.3)
    }

    // MARK: - Celestial Luminescence (Ethereal Orb Palette)
    /// Premium color palette for the EtherealOrb and ethereal UI elements
    /// Inspired by translucent iridescent glass spheres with soft gradients
    enum CelestialLuminescence {
        // MARK: Core Orb Colors
        /// Deep void indigo - the orb's inner core
        static let voidIndigo = Color(red: 0.08, green: 0.06, blue: 0.18)
        /// Soft pink - warm inner glow
        static let softPink = Color(red: 0.95, green: 0.65, blue: 0.80)
        /// Soft purple - mid-layer iridescence
        static let softPurple = Color(red: 0.75, green: 0.55, blue: 0.90)
        /// Soft cyan - outer layer glow
        static let softCyan = Color(red: 0.55, green: 0.85, blue: 0.95)
        /// Cyan rim - bright edge highlight
        static let cyanRim = Color(red: 0.25, green: 0.85, blue: 0.95)

        // MARK: Ambient Colors
        /// Deep space background
        static let deepSpace = Color(red: 0.01, green: 0.01, blue: 0.02)
        /// Nebula hints for subtle background effects
        static let nebulaHint = Color(red: 0.15, green: 0.08, blue: 0.25)
        /// Aurora accent for backgrounds
        static let auroraHint = Color(red: 0.08, green: 0.15, blue: 0.22)

        // MARK: Success/Action Colors
        /// Success green for launch/completion
        static let successGreen = Color(red: 0.40, green: 0.85, blue: 0.65)
        /// Celebration gold
        static let celebrationGold = Color(red: 0.98, green: 0.82, blue: 0.35)

        // MARK: Gradients
        /// Main ethereal orb gradient
        static var orbGradient: LinearGradient {
            LinearGradient(
                colors: [softPink, softPurple, softCyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Rim highlight gradient
        static var rimGradient: AngularGradient {
            AngularGradient(
                colors: [
                    cyanRim.opacity(0.9),
                    softPurple.opacity(0.5),
                    Color.clear,
                    softPink.opacity(0.3),
                    cyanRim.opacity(0.9)
                ],
                center: .center
            )
        }

        /// Cosmic background gradient
        static var cosmicBackground: LinearGradient {
            LinearGradient(
                colors: [
                    deepSpace,
                    nebulaHint.opacity(0.3),
                    auroraHint.opacity(0.2),
                    deepSpace
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// CTA button gradient (cyan → purple)
        static var ctaGradient: LinearGradient {
            LinearGradient(
                colors: [softCyan, softPurple],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        /// Launch button gradient (green → cyan)
        static var launchGradient: LinearGradient {
            LinearGradient(
                colors: [successGreen, softCyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Input Bar Colors
    /// Color palette for the floating input bar
    enum InputBarColors {
        /// Greeting text color
        static let greetingText = CelestialColors.starDim
        /// Greeting accent for time-aware highlights
        static let greetingAccent = Color(red: 0.58, green: 0.25, blue: 0.98)
        /// Send button gradient
        static let sendGradient = LinearGradient(
            colors: [
                Color(red: 0.58, green: 0.25, blue: 0.98),
                Color(red: 0.42, green: 0.45, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        /// Send button glow
        static let sendGlow = Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.5)
        /// Mic button inactive
        static let micInactive = CelestialColors.starGhost
        /// Plus button background
        static let plusBackground = Color.white.opacity(0.08)
        /// Plus button active
        static let plusActive = Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.2)
    }

    // MARK: - Animation Tokens (Genius Animations)
    /// Animation timing and duration constants for the task card system
    enum GeniusAnimation {
        /// Delay between module cascade appearances
        static let moduleStagger: Double = 0.08
        /// Sheet presentation spring
        static let sheetSpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        /// Card breathing animation for high-priority
        static let cardBreathing = SwiftUI.Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
        /// Orb rotation speed
        static let orbRotation = SwiftUI.Animation.linear(duration: 2).repeatForever(autoreverses: false)
        /// Fast orb for singularity core
        static let singularityRotation = SwiftUI.Animation.linear(duration: 1).repeatForever(autoreverses: false)
        /// Particle orbit
        static let particleOrbit = SwiftUI.Animation.linear(duration: 4).repeatForever(autoreverses: false)
        /// Ring rotation (outer)
        static let ringRotation = SwiftUI.Animation.linear(duration: 6).repeatForever(autoreverses: false)
        /// Glow pulse
        static let glowPulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        /// Aurora wave
        static let auroraWave = SwiftUI.Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
        /// Total creation animation duration
        static let creationDuration: Double = 3.5
        /// Inline spark duration
        static let sparkDuration: Double = 2.0
    }

    // MARK: - Colors
    enum Colors {
        // MARK: Primary Brand Colors
        /// Deep violet - the signature brand color
        static let accent = Color(red: 0.42, green: 0.28, blue: 0.98)
        /// Lighter violet for gradients
        static let accentSecondary = Color(red: 0.58, green: 0.38, blue: 1.0)
        /// Subtle tint for backgrounds
        static let accentTint = Color(red: 0.42, green: 0.28, blue: 0.98).opacity(0.08)

        // MARK: Background Colors
        static let background = Color(uiColor: .systemBackground)
        static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
        static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)
        static let backgroundElevated = Color(uiColor: .systemBackground).opacity(0.95)

        // MARK: Text Colors
        static let textPrimary = Color(uiColor: .label)
        static let textSecondary = Color(uiColor: .secondaryLabel)
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        static let textOnAccent = Color.white

        // MARK: Semantic Text Colors
        static let errorText = Color(red: 0.95, green: 0.28, blue: 0.28)
        static let successText = Color(red: 0.18, green: 0.72, blue: 0.38)
        static let warningText = Color(red: 0.92, green: 0.62, blue: 0.15)
        static let linkText = Color(red: 0.35, green: 0.48, blue: 0.95)
        static let hintText = Color(uiColor: .tertiaryLabel)
        static let placeholderText = Color(uiColor: .placeholderText)

        // MARK: Semantic Colors
        static let success = Color(red: 0.22, green: 0.78, blue: 0.42)
        static let warning = Color(red: 0.98, green: 0.72, blue: 0.18)
        static let error = Color(red: 0.98, green: 0.32, blue: 0.32)
        static let info = Color(red: 0.32, green: 0.58, blue: 0.98)

        // MARK: AI Colors (Vibrant Iridescent Palette)
        /// Rich violet for primary AI elements
        static let aiPurple = Color(red: 0.58, green: 0.25, blue: 0.98)
        /// Electric blue for accents
        static let aiBlue = Color(red: 0.28, green: 0.52, blue: 0.98)
        /// Bright cyan for highlights
        static let aiCyan = Color(red: 0.18, green: 0.82, blue: 0.92)
        /// Vibrant pink for energy
        static let aiPink = Color(red: 0.98, green: 0.38, blue: 0.68)
        /// Warm gold for premium feel
        static let aiGold = Color(red: 0.98, green: 0.82, blue: 0.35)
        /// Sunset orange for warmth
        static let aiOrange = Color(red: 0.98, green: 0.58, blue: 0.22)
        /// Focus amber for timer/focus mode
        static let aiAmber = Color(red: 0.96, green: 0.62, blue: 0.14)
        /// Fresh green for vitality
        static let aiGreen = Color(red: 0.22, green: 0.88, blue: 0.58)

        // MARK: Iridescent Colors (Celebration/Effects)
        static let iridescentPink = Color(red: 1.0, green: 0.48, blue: 0.78)
        static let iridescentCyan = Color(red: 0.38, green: 0.92, blue: 1.0)
        static let iridescentYellow = Color(red: 1.0, green: 0.92, blue: 0.38)
        static let iridescentLavender = Color(red: 0.78, green: 0.58, blue: 1.0)
        static let iridescentMint = Color(red: 0.38, green: 0.98, blue: 0.68)
        static let iridescentPeach = Color(red: 1.0, green: 0.72, blue: 0.58)

        // MARK: Gamification Colors
        static let streakOrange = Color(red: 0.98, green: 0.48, blue: 0.12)
        static let xp = Color(red: 0.92, green: 0.78, blue: 0.22)
        static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
        static let fire = Color(red: 0.98, green: 0.32, blue: 0.12)
        static let diamond = Color(red: 0.68, green: 0.88, blue: 1.0)
        static let platinum = Color(red: 0.88, green: 0.88, blue: 0.92)

        // MARK: Aliases
        static let primaryText = textPrimary
        static let secondaryText = textSecondary
        static let tertiaryText = textTertiary
        static let destructive = error
        static let glassBackground = Color.white.opacity(0.1)
        static let cardBackgroundSecondary = Color(uiColor: .tertiarySystemBackground)

        // MARK: Surface Colors
        static let cardBackground = Color(uiColor: .secondarySystemBackground)
        static let glassBorder = Color.white.opacity(0.2)
        static let divider = Color(uiColor: .separator)

        // MARK: Dark Mode Aware Colors (use with DarkModeAware modifier)
        /// Returns different colors based on color scheme
        static func adaptiveGlass(light: Double = 0.1, dark: Double = 0.15) -> (light: Color, dark: Color) {
            (Color.white.opacity(light), Color.white.opacity(dark))
        }

        static func adaptiveBorder(light: Double = 0.2, dark: Double = 0.25) -> (light: Color, dark: Color) {
            (Color.white.opacity(light), Color.white.opacity(dark))
        }

        static func adaptiveShadow(light: Double = 0.1, dark: Double = 0.3) -> (light: Color, dark: Color) {
            (Color.black.opacity(light), Color.black.opacity(dark))
        }

        // MARK: Gradient Presets
        static var accentGradient: LinearGradient {
            LinearGradient(
                colors: [accent, accentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var iridescentGradient: [Color] {
            [aiPurple, aiBlue, aiCyan, aiPink]
        }

        static var iridescentGradientLinear: LinearGradient {
            LinearGradient(
                colors: iridescentGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var aiGradient: [Color] {
            [aiOrange, aiPurple, aiBlue, aiCyan]
        }

        static var aiGradientLinear: LinearGradient {
            LinearGradient(
                colors: aiGradient,
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        static var successGradient: LinearGradient {
            LinearGradient(
                colors: [success, success.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // MARK: Angular Gradients
        static func iridescentAngularGradient(angle: Angle = .degrees(0)) -> AngularGradient {
            AngularGradient(
                colors: [aiPurple, aiBlue, aiCyan, aiPink, aiPurple],
                center: .center,
                angle: angle
            )
        }
    }

    // MARK: - Layout Constants
    enum Layout {
        static let regularPadding: CGFloat = 48
        static let maxCardWidth: CGFloat = 600
        static let maxContentWidth: CGFloat = 800
    }

    // MARK: - Typography
    enum Typography {
        // MARK: Display (Editorial Thin - Auth Style)
        /// Hero display text - ultra thin for premium feel
        static let displayHero = Font.system(size: 42, weight: .thin, design: .default)
        /// Large display text
        static let displayLarge = Font.system(size: 36, weight: .thin, design: .default)
        /// Medium display text
        static let displayMedium = Font.system(size: 28, weight: .thin, design: .default)
        /// Small display text
        static let displaySmall = Font.system(size: 24, weight: .thin, design: .default)

        // MARK: Page Title (Main Navigation Headers)
        /// Page title - ultra-thin elegant typography for main page headers
        /// Inspired by the MyTasksAI brand aesthetic: refined, modern, sophisticated
        static let pageTitle = Font.system(size: 22, weight: .ultraLight, design: .default)
        /// Page title compact - for scrolled/collapsed states
        static let pageTitleCompact = Font.system(size: 18, weight: .thin, design: .default)

        // MARK: Living Cosmos Typography
        /// Task title - SF Pro Rounded for softer, approachable feel
        static let cosmosTitle = Font.system(size: 16, weight: .semibold, design: .rounded)
        /// Task title large - for expanded card headers
        static let cosmosTitleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
        /// Section headers in expanded card
        static let cosmosSectionHeader = Font.system(size: 13, weight: .semibold, design: .rounded)
        /// Metadata - SF Mono for technical precision feel
        static let cosmosMeta = Font.system(size: 11, weight: .medium, design: .monospaced)
        /// Metadata small - for timestamps
        static let cosmosMetaSmall = Font.system(size: 10, weight: .regular, design: .monospaced)
        /// AI whisper - New York (serif) italic for editorial human feel
        static let cosmosWhisper = Font.system(size: 14, weight: .regular, design: .serif).italic()
        /// AI whisper small
        static let cosmosWhisperSmall = Font.system(size: 12, weight: .regular, design: .serif).italic()
        /// Points display - rounded for gamification
        static let cosmosPoints = Font.system(size: 14, weight: .bold, design: .rounded)
        /// Points display large
        static let cosmosPointsLarge = Font.system(size: 24, weight: .bold, design: .rounded)
        /// Energy label - thin for ethereal feel
        static let cosmosEnergy = Font.system(size: 10, weight: .light, design: .rounded)

        // MARK: Display (Standard weights)
        static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
        static let title = Font.system(.title, design: .default, weight: .semibold)
        static let title1 = Font.system(.title, design: .default, weight: .bold)
        static let title2 = Font.system(.title2, design: .default, weight: .semibold)
        static let title3 = Font.system(.title3, design: .default, weight: .medium)

        // MARK: Title Light Variants (Auth-inspired)
        /// Light weight title for elegant headers
        static let titleLight = Font.system(.title, design: .default, weight: .light)
        static let title2Light = Font.system(.title2, design: .default, weight: .light)
        static let title3Light = Font.system(.title3, design: .default, weight: .light)

        // MARK: Body
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        static let body = Font.system(.body, design: .default)
        static let bodyBold = Font.system(.body, design: .default, weight: .semibold)
        static let bodyLight = Font.system(.body, design: .default, weight: .light)
        static let callout = Font.system(.callout, design: .default)
        static let calloutLight = Font.system(.callout, design: .default, weight: .light)

        // MARK: Supporting
        static let subheadline = Font.system(.subheadline, design: .default)
        static let subheadlineMedium = Font.system(.subheadline, design: .default, weight: .medium)
        static let subheadlineLight = Font.system(.subheadline, design: .default, weight: .light)
        static let footnote = Font.system(.footnote, design: .default)
        static let footnoteLight = Font.system(.footnote, design: .default, weight: .light)
        static let caption = Font.system(.caption, design: .default)
        static let caption1 = Font.system(.caption, design: .default)  // Alias for caption
        static let caption1Medium = Font.system(.caption, design: .default, weight: .medium)
        static let caption2 = Font.system(.caption2, design: .default)

        // MARK: AI Fonts
        static let aiWhisper = Font.system(.footnote, design: .default).italic()
        /// AI insight text - thin and ethereal
        static let aiInsight = Font.system(.callout, design: .default, weight: .light).italic()

        // MARK: Pill/Button Text
        static let pillText = Font.system(.subheadline, design: .default, weight: .medium)
        /// Thin pill text for elegant buttons
        static let pillTextLight = Font.system(.subheadline, design: .default, weight: .light)

        // MARK: Points/Stats Display
        /// Large points display
        static let pointsLarge = Font.system(size: 32, weight: .light, design: .default)
        /// Medium points display
        static let pointsMedium = Font.system(size: 24, weight: .light, design: .default)
        /// Small points display
        static let pointsSmall = Font.system(size: 18, weight: .medium, design: .default)

        // MARK: Monospace
        static let code = Font.system(.body, design: .monospaced)
        static let codeSmall = Font.system(.footnote, design: .monospaced)

        // MARK: Tab Bar
        static let tabLabel = Font.system(size: 12, weight: .semibold, design: .default)
        static let tabLabelLight = Font.system(size: 12, weight: .medium, design: .default)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48

        // Semantic
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let compactSpacing: CGFloat = 8

        // Header
        static let universalHeaderHeight: CGFloat = 60

        // Floating Tab Bar
        static let floatingTabBarClearance: CGFloat = 100
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 999

        // Semantic
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let textField: CGFloat = 12
        static let pill: CGFloat = 999

        // Aliases
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    // Radius alias for convenience
    typealias Radius = CornerRadius

    // MARK: - Size
    enum Size {
        static let checkboxSize: CGFloat = 24
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
    }

    // MARK: - Shadow
    enum Shadow {
        // Light mode shadows
        static let sm = ShadowStyle(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let md = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let lg = ShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        static let glow = ShadowStyle(color: Colors.accent.opacity(0.4), radius: 20, x: 0, y: 0)
        static let aiGlow = ShadowStyle(color: Colors.aiPurple.opacity(0.5), radius: 24, x: 0, y: 0)

        // Dark mode enhanced shadows (use with adaptiveShadow modifier)
        static let smDark = ShadowStyle(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        static let mdDark = ShadowStyle(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        static let lgDark = ShadowStyle(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        static let glowDark = ShadowStyle(color: Colors.accent.opacity(0.5), radius: 24, x: 0, y: 0)
        static let aiGlowDark = ShadowStyle(color: Colors.aiPurple.opacity(0.6), radius: 28, x: 0, y: 0)
    }

    // MARK: - Animation
    enum Animation {
        static let instant = SwiftUI.Animation.easeOut(duration: 0.1)
        static let fast = SwiftUI.Animation.easeOut(duration: 0.2)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)

        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let springSnappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let springGentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
        static let bouncySpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let quickSpring = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.7)

        // AI Animations
        static let aiPulse = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        static let aiShimmer = SwiftUI.Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
        static let iridescentRotation = SwiftUI.Animation.linear(duration: 8.0).repeatForever(autoreverses: false)

        // MARK: Cosmic Springs (Living Cosmos)
        /// Portal opening - dramatic expansion for card detail transition
        static let portalOpen = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.75)
        /// Stellar bounce - satisfying bounce for interactions
        static let stellarBounce = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.6)
        /// Orbital float - gentle ambient floating motion
        static let orbitalFloat = SwiftUI.Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
        /// Supernova burst - explosive completion celebration
        static let supernovaBurst = SwiftUI.Animation.easeOut(duration: 0.4)
        /// Plasma pulse - living energy core heartbeat
        static let plasmaPulse = SwiftUI.Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        /// Aurora wave - flowing aurora tendrils
        static let auroraWave = SwiftUI.Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        /// Gravity pull - items being attracted
        static let gravityPull = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.7)
        /// Parallax shift - device tilt response
        static let parallaxShift = SwiftUI.Animation.interactiveSpring(response: 0.15, dampingFraction: 0.8)
        /// Stagger delay base - for orchestrated entry animations
        static let staggerDelay: Double = 0.06

        /// Cosmic spring - premium fluid animation for cosmic UI
        static let cosmicSpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
    }

    // MARK: - Animations Alias
    /// Alias for Animation to support both naming conventions
    typealias Animations = Animation
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    /// Apply theme shadow
    func themeShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    /// Apply adaptive theme shadow (different in light/dark mode)
    func themeShadow(_ light: ShadowStyle, dark: ShadowStyle) -> some View {
        modifier(AdaptiveThemeShadowModifier(lightShadow: light, darkShadow: dark))
    }

    /// Apply standard adaptive shadow (auto-selects light/dark variant)
    func adaptiveThemeShadow(_ size: AdaptiveShadowSize) -> some View {
        switch size {
        case .sm:
            return AnyView(themeShadow(Theme.Shadow.sm, dark: Theme.Shadow.smDark))
        case .md:
            return AnyView(themeShadow(Theme.Shadow.md, dark: Theme.Shadow.mdDark))
        case .lg:
            return AnyView(themeShadow(Theme.Shadow.lg, dark: Theme.Shadow.lgDark))
        case .glow:
            return AnyView(themeShadow(Theme.Shadow.glow, dark: Theme.Shadow.glowDark))
        case .aiGlow:
            return AnyView(themeShadow(Theme.Shadow.aiGlow, dark: Theme.Shadow.aiGlowDark))
        }
    }
}

/// Adaptive shadow sizes for convenience
enum AdaptiveShadowSize {
    case sm, md, lg, glow, aiGlow
}

/// Modifier for shadows (always uses dark mode values)
struct AdaptiveThemeShadowModifier: ViewModifier {
    let lightShadow: ShadowStyle
    let darkShadow: ShadowStyle

    func body(content: Content) -> some View {
        // Always use dark shadow since app enforces dark mode
        content.shadow(color: darkShadow.color, radius: darkShadow.radius, x: darkShadow.x, y: darkShadow.y)
    }
}

// MARK: - Card Style Extensions
extension View {
    /// Apply card style with adaptive shadows
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }

    /// Apply glass card style with adaptive dark mode
    func glassCardStyle() -> some View {
        modifier(GlassCardStyleModifier())
    }

    /// Apply screen padding
    func screenPadding() -> some View {
        self.padding(.horizontal, Theme.Spacing.screenPadding)
    }
}

/// Card style modifier (uses dark mode styling)
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.cardPadding)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .shadow(
                color: .black.opacity(0.2),
                radius: 6,
                x: 0,
                y: 3
            )
    }
}

/// Glass card style modifier (uses dark mode styling)
struct GlassCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.cardPadding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(0.25),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Height.button)
            .background(
                Theme.Colors.accentGradient
                    .opacity(isEnabled ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.button))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Colors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Height.button)
            .background(Theme.Colors.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.button)
                    .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.bodyBold)
            .foregroundStyle(Theme.Colors.accent)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                configuration.isPressed ?
                Theme.Colors.accent.opacity(0.1) :
                    Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}

// MARK: - Glass Button Styles
// NOTE: iOS 26 provides built-in .glass and .glassProminent button styles
// via Liquid Glass design system. Use .buttonStyle(.glass) directly.

// MARK: - iOS 26 Adaptive Colors
extension Theme {
    /// iOS 26 semantic colors that blend with Liquid Glass design system
    /// Use these for proper light/dark mode adaptation and HIG compliance
    enum AdaptiveColors {
        // MARK: Background Layers (NOT glass - solid for content)
        /// Primary card/content background - adapts to appearance
        static let cardBackground = Color(.secondarySystemGroupedBackground)
        /// Sheet/modal background
        static let sheetBackground = Color(.systemGroupedBackground)
        /// Elevated surface background
        static let elevatedBackground = Color(.tertiarySystemGroupedBackground)
        /// True background (root level)
        static let primaryBackground = Color(.systemBackground)

        // MARK: Semantic Accents (work in light/dark)
        /// Primary brand accent
        static let accent = Color.purple
        /// Success state
        static let success = Color.green
        /// Warning state
        static let warning = Color.orange
        /// Destructive/error state
        static let destructive = Color.red
        /// Informational
        static let info = Color.blue

        // MARK: AI Feature Colors (vibrant, brand-specific)
        /// Primary AI accent (nebula purple)
        static let aiPrimary = Color(red: 0.58, green: 0.25, blue: 0.98)
        /// Secondary AI accent (electric blue)
        static let aiSecondary = Color(red: 0.28, green: 0.52, blue: 0.98)
        /// AI tertiary (cyan highlight)
        static let aiTertiary = Color(red: 0.18, green: 0.82, blue: 0.92)

        // MARK: Text Colors (semantic)
        /// Primary text - adapts automatically
        static let textPrimary = Color(.label)
        /// Secondary text
        static let textSecondary = Color(.secondaryLabel)
        /// Tertiary/hint text
        static let textTertiary = Color(.tertiaryLabel)
        /// Quaternary/ghost text
        static let textQuaternary = Color(.quaternaryLabel)

        // MARK: Interactive Element Colors
        /// Border for cards and containers
        static let border = Color(.separator)
        /// Subtle border for glass elements
        static let glassBorder = Color.white.opacity(0.2)
        /// Fill for interactive elements
        static let fill = Color(.systemFill)
        /// Secondary fill
        static let secondaryFill = Color(.secondarySystemFill)

        // MARK: Gradients
        /// AI gradient for buttons and highlights
        static var aiGradient: LinearGradient {
            LinearGradient(
                colors: [aiPrimary, aiSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Premium accent gradient
        static var accentGradient: LinearGradient {
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - iOS 26 Liquid Glass View Extensions
extension View {
    /// Apply iOS 26 native Liquid Glass effect for navigation/interactive elements
    /// Use for: buttons, pickers, toolbars, input bars - NOT for content cards
    @available(iOS 26.0, *)
    func veloceGlass() -> some View {
        self.glassEffect()
    }

    /// Apply iOS 26 native Liquid Glass with custom shape
    @available(iOS 26.0, *)
    func veloceGlass<S: Shape>(in shape: S) -> some View {
        self.glassEffect(in: shape)
    }

    /// Apply iOS 26 native Liquid Glass capsule (for pill-shaped elements)
    @available(iOS 26.0, *)
    func veloceGlassCapsule() -> some View {
        self.glassEffect(in: Capsule())
    }

    /// Card background for content (NOT glass - per HIG, glass is for navigation layer only)
    /// Use for: task cards, list items, content sections
    func veloceCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(Theme.Spacing.cardPadding)
            .background(Theme.AdaptiveColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Elevated card with subtle shadow
    func veloceElevatedCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(Theme.Spacing.cardPadding)
            .background(Theme.AdaptiveColors.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    /// Section card with optional tint color for task type indication
    func veloceSectionCard(tint: Color? = nil, cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(Theme.Spacing.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.AdaptiveColors.cardBackground)
                    .overlay {
                        if let tint = tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.08))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(tint?.opacity(0.2) ?? Color.clear, lineWidth: 0.5)
            }
    }
}

// MARK: - Fallback Liquid Glass (Pre-iOS 26)
extension View {
    /// Fallback glass effect for iOS < 26
    /// Provides similar visual appearance using ultraThinMaterial
    func veloceGlassFallback<S: Shape>(in shape: S = Capsule() as! S) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .white.opacity(0.1), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
    }

    /// Adaptive glass that uses iOS 26 native when available, fallback otherwise
    @ViewBuilder
    func adaptiveGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: shape)
        } else {
            self.veloceGlassFallback(in: shape)
        }
    }

    /// Adaptive glass capsule
    @ViewBuilder
    func adaptiveGlassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: Capsule())
        } else {
            self.veloceGlassFallback(in: Capsule())
        }
    }
}
