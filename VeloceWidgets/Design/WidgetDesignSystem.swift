//
//  WidgetDesignSystem.swift
//  VeloceWidgets
//
//  Aurora Design System for Widgets
//  Ethereal cosmic aesthetic matching the auth screens
//  Crystalline glass, flowing aurora, twinkling starfield
//

import SwiftUI
import WidgetKit

// MARK: - Widget Aurora Namespace

enum WidgetAurora {

    // MARK: - Colors

    enum Colors {

        // Aurora Palette - Rich, Vibrant
        static let violet = Color(red: 0.48, green: 0.12, blue: 0.74)
        static let purple = Color(red: 0.58, green: 0.22, blue: 0.88)
        static let electric = Color(red: 0.24, green: 0.56, blue: 0.98)
        static let cyan = Color(red: 0.14, green: 0.82, blue: 0.94)
        static let emerald = Color(red: 0.20, green: 0.85, blue: 0.64)
        static let rose = Color(red: 0.98, green: 0.36, blue: 0.64)
        static let gold = Color(red: 1.0, green: 0.84, blue: 0.40)

        // Cosmic Backgrounds
        static let cosmicBlack = Color(red: 0.02, green: 0.02, blue: 0.04)
        static let cosmicDeep = Color(red: 0.03, green: 0.03, blue: 0.06)
        static let cosmicSurface = Color(red: 0.06, green: 0.06, blue: 0.10)
        static let cosmicElevated = Color(red: 0.08, green: 0.08, blue: 0.14)

        // Glass Effects
        static let glassBase = Color.white.opacity(0.03)
        static let glassFocused = Color.white.opacity(0.06)
        static let glassBorder = Color.white.opacity(0.10)
        static let glassBorderFocused = Color.white.opacity(0.18)
        static let glassHighlight = Color.white.opacity(0.20)

        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.85)
        static let textTertiary = Color.white.opacity(0.60)
        static let textQuaternary = Color.white.opacity(0.40)

        // Semantic Colors
        static let success = Color(red: 0.20, green: 0.88, blue: 0.56)
        static let error = Color(red: 1.0, green: 0.36, blue: 0.36)
        static let warning = Color(red: 1.0, green: 0.76, blue: 0.28)

        // Flame Colors (for streak)
        static let flameCore = Color(red: 1.0, green: 0.95, blue: 0.85)
        static let flameInner = Color(red: 1.0, green: 0.75, blue: 0.20)
        static let flameMid = Color(red: 1.0, green: 0.45, blue: 0.15)
        static let flameOuter = Color(red: 0.90, green: 0.25, blue: 0.10)
    }

    // MARK: - Gradients

    enum Gradients {

        /// Primary aurora gradient
        static var aurora: LinearGradient {
            LinearGradient(
                colors: [Colors.violet, Colors.electric, Colors.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Full aurora spectrum
        static var auroraFull: LinearGradient {
            LinearGradient(
                colors: [Colors.violet, Colors.purple, Colors.electric, Colors.cyan, Colors.emerald],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Cosmic background
        static var cosmic: LinearGradient {
            LinearGradient(
                colors: [Colors.cosmicBlack, Colors.cosmicDeep, Colors.cosmicBlack],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        /// Widget cosmic background with aurora tint
        static var widgetBackground: LinearGradient {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.08),
                    Color(red: 0.02, green: 0.03, blue: 0.06),
                    Color(red: 0.03, green: 0.02, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Angular aurora for progress rings
        static var auroraRing: AngularGradient {
            AngularGradient(
                colors: [
                    Colors.violet,
                    Colors.purple,
                    Colors.electric,
                    Colors.cyan,
                    Colors.violet
                ],
                center: .center
            )
        }

        /// Glass border gradient
        static var glassBorder: LinearGradient {
            LinearGradient(
                colors: [
                    Colors.glassHighlight,
                    Colors.glassBorder,
                    Colors.glassBorder.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Flame gradient for streak
        static var flame: LinearGradient {
            LinearGradient(
                colors: [Colors.flameCore, Colors.flameInner, Colors.flameMid, Colors.flameOuter],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        /// Radial glow
        static func radialGlow(color: Color = Colors.violet, intensity: Double = 0.3) -> RadialGradient {
            RadialGradient(
                colors: [color.opacity(intensity), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
        }
    }

    // MARK: - Typography

    enum Typography {
        static let heroNumber = Font.system(size: 42, weight: .thin, design: .rounded)
        static let largeNumber = Font.system(size: 32, weight: .light, design: .rounded)
        static let mediumNumber = Font.system(size: 24, weight: .light, design: .rounded)
        static let smallNumber = Font.system(size: 18, weight: .regular, design: .rounded)

        static let headline = Font.system(size: 16, weight: .semibold)
        static let subheadline = Font.system(size: 14, weight: .medium)
        static let body = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 11, weight: .medium)
        static let micro = Font.system(size: 10, weight: .medium)
    }

    // MARK: - Layout

    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 10
        static let tinyCornerRadius: CGFloat = 6

        static let spacing: CGFloat = 12
        static let smallSpacing: CGFloat = 8
        static let tinySpacing: CGFloat = 4
    }
}

// MARK: - Widget Cosmic Background

struct WidgetCosmicBackground: View {
    var showStars: Bool = true
    var showAurora: Bool = true
    var auroraIntensity: Double = 0.35
    var starCount: Int = 15

    var body: some View {
        ZStack {
            // Base cosmic gradient
            WidgetAurora.Gradients.widgetBackground

            // Aurora glow layer
            if showAurora {
                auroraLayer
            }

            // Star particles
            if showStars {
                starLayer
            }
        }
    }

    private var auroraLayer: some View {
        ZStack {
            // Top-left violet glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            WidgetAurora.Colors.violet.opacity(auroraIntensity * 0.6),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 200, height: 150)
                .offset(x: -80, y: -60)

            // Center-right electric glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            WidgetAurora.Colors.electric.opacity(auroraIntensity * 0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 160, height: 120)
                .offset(x: 60, y: 20)

            // Bottom cyan accent
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            WidgetAurora.Colors.cyan.opacity(auroraIntensity * 0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 140, height: 100)
                .offset(x: -20, y: 70)
        }
    }

    private var starLayer: some View {
        GeometryReader { geo in
            ForEach(0..<starCount, id: \.self) { index in
                let seed = Double(index * 31 + 7)
                let x = CGFloat((seed.truncatingRemainder(dividingBy: 100)) / 100) * geo.size.width
                let y = CGFloat(((seed * 1.3).truncatingRemainder(dividingBy: 100)) / 100) * geo.size.height
                let size = CGFloat(1 + (seed.truncatingRemainder(dividingBy: 3)))
                let opacity = 0.2 + (seed.truncatingRemainder(dividingBy: 5)) / 10

                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: size, height: size)
                    .position(x: x, y: y)
            }
        }
    }
}

// MARK: - Widget Glass Card

struct WidgetGlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = WidgetAurora.Layout.cornerRadius
    var showBorder: Bool = true

    init(cornerRadius: CGFloat = WidgetAurora.Layout.cornerRadius, showBorder: Bool = true, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(WidgetAurora.Colors.glassBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                showBorder ? WidgetAurora.Gradients.glassBorder : .clear,
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Aurora Progress Ring

struct AuroraProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    var showGlow: Bool = true

    init(progress: Double, size: CGFloat = 80, lineWidth: CGFloat = 8, showGlow: Bool = true) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.showGlow = showGlow
    }

    var body: some View {
        ZStack {
            // Glow
            if showGlow {
                Circle()
                    .stroke(WidgetAurora.Colors.violet.opacity(0.3), lineWidth: lineWidth + 8)
                    .frame(width: size, height: size)
                    .blur(radius: 8)
            }

            // Background ring
            Circle()
                .stroke(WidgetAurora.Colors.glassBorder, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    WidgetAurora.Gradients.auroraRing,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // End cap glow
            if progress > 0.05 {
                Circle()
                    .fill(WidgetAurora.Colors.cyan)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * progress - 90))
                    .shadow(color: WidgetAurora.Colors.cyan.opacity(0.8), radius: 4)
            }
        }
    }
}

// MARK: - Aurora Flame

struct AuroraFlame: View {
    let intensity: FlameIntensity
    let size: CGFloat

    enum FlameIntensity {
        case none, spark, kindle, flame, blaze, inferno

        var scale: CGFloat {
            switch self {
            case .none: return 0.3
            case .spark: return 0.5
            case .kindle: return 0.7
            case .flame: return 0.85
            case .blaze: return 1.0
            case .inferno: return 1.15
            }
        }

        var colors: [Color] {
            switch self {
            case .none:
                return [WidgetAurora.Colors.textQuaternary, WidgetAurora.Colors.textQuaternary.opacity(0.3)]
            case .spark:
                return [WidgetAurora.Colors.flameInner, WidgetAurora.Colors.flameMid]
            case .kindle:
                return [WidgetAurora.Colors.flameInner, WidgetAurora.Colors.flameMid, WidgetAurora.Colors.flameOuter]
            case .flame:
                return [WidgetAurora.Colors.flameCore, WidgetAurora.Colors.flameInner, WidgetAurora.Colors.flameMid, WidgetAurora.Colors.flameOuter]
            case .blaze:
                return [WidgetAurora.Colors.flameCore, WidgetAurora.Colors.flameInner, WidgetAurora.Colors.flameMid, WidgetAurora.Colors.flameOuter, WidgetAurora.Colors.violet.opacity(0.5)]
            case .inferno:
                return [Color.white, WidgetAurora.Colors.flameCore, WidgetAurora.Colors.flameInner, WidgetAurora.Colors.flameMid, WidgetAurora.Colors.violet]
            }
        }

        var glowColor: Color {
            switch self {
            case .none: return .clear
            case .spark, .kindle: return WidgetAurora.Colors.flameMid
            case .flame: return WidgetAurora.Colors.flameInner
            case .blaze, .inferno: return WidgetAurora.Colors.flameCore
            }
        }
    }

    var body: some View {
        ZStack {
            // Glow
            if intensity != .none {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: intensity.colors.map { $0.opacity(0.4) } + [Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: 12)
            }

            // Flame icon
            Image(systemName: "flame.fill")
                .font(.system(size: size * intensity.scale))
                .foregroundStyle(
                    LinearGradient(
                        colors: intensity.colors,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .shadow(color: intensity.glowColor.opacity(0.6), radius: 8)
        }
    }
}

// MARK: - Widget Stat Pill

struct WidgetStatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(value)
                .font(WidgetAurora.Typography.micro)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Widget Aurora Button

struct WidgetAuroraButton: View {
    let title: String
    let icon: String?
    let url: URL

    init(_ title: String, icon: String? = nil, url: URL) {
        self.title = title
        self.icon = icon
        self.url = url
    }

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(WidgetAurora.Typography.caption)
            }
            .foregroundStyle(WidgetAurora.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: WidgetAurora.Layout.smallCornerRadius)
                    .fill(WidgetAurora.Gradients.aurora.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: WidgetAurora.Layout.smallCornerRadius)
                            .stroke(WidgetAurora.Colors.glassHighlight, lineWidth: 0.5)
                    )
            )
            .shadow(color: WidgetAurora.Colors.violet.opacity(0.3), radius: 8, y: 2)
        }
    }
}

// MARK: - Focus Timer Ring

struct FocusTimerRing: View {
    let progress: Double
    let state: FocusTimerState
    let size: CGFloat
    let lineWidth: CGFloat

    enum FocusTimerState {
        case idle, active, paused, breakTime

        var primaryColor: Color {
            switch self {
            case .idle: return WidgetAurora.Colors.textQuaternary
            case .active: return Color(red: 1.0, green: 0.55, blue: 0.20) // Amber/Orange
            case .paused: return WidgetAurora.Colors.gold
            case .breakTime: return WidgetAurora.Colors.emerald
            }
        }

        var secondaryColor: Color {
            switch self {
            case .idle: return WidgetAurora.Colors.glassBorder
            case .active: return Color(red: 1.0, green: 0.35, blue: 0.15) // Deep orange
            case .paused: return WidgetAurora.Colors.flameInner
            case .breakTime: return WidgetAurora.Colors.cyan
            }
        }

        var glowColor: Color {
            switch self {
            case .idle: return .clear
            case .active: return Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.4)
            case .paused: return WidgetAurora.Colors.gold.opacity(0.3)
            case .breakTime: return WidgetAurora.Colors.emerald.opacity(0.3)
            }
        }

        var icon: String {
            switch self {
            case .idle: return "play.fill"
            case .active: return "timer"
            case .paused: return "pause.fill"
            case .breakTime: return "cup.and.saucer.fill"
            }
        }
    }

    init(progress: Double, state: FocusTimerState = .active, size: CGFloat = 80, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.state = state
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Ambient glow
            if state != .idle {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [state.glowColor, state.glowColor.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * 1.6, height: size * 1.6)
                    .blur(radius: 10)
            }

            // Background ring
            Circle()
                .stroke(WidgetAurora.Colors.glassBorder, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [state.primaryColor, state.secondaryColor, state.primaryColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: state.glowColor, radius: 6)

            // End cap glow
            if progress > 0.02 && state != .idle {
                Circle()
                    .fill(state.primaryColor)
                    .frame(width: lineWidth * 0.8, height: lineWidth * 0.8)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * progress - 90))
                    .shadow(color: state.primaryColor.opacity(0.8), radius: 4)
            }
        }
    }
}

// MARK: - Level Badge

struct LevelBadge: View {
    let level: Int
    let size: LevelBadgeSize

    enum LevelBadgeSize {
        case small, medium, large

        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
    }

    private var tierColors: (primary: Color, secondary: Color) {
        switch level {
        case 1...9: return (WidgetAurora.Colors.emerald, WidgetAurora.Colors.cyan)
        case 10...24: return (WidgetAurora.Colors.electric, WidgetAurora.Colors.violet)
        case 25...49: return (WidgetAurora.Colors.gold, WidgetAurora.Colors.flameInner)
        case 50...99: return (WidgetAurora.Colors.rose, WidgetAurora.Colors.violet)
        default: return (WidgetAurora.Colors.violet, Color.white) // Diamond tier
        }
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tierColors.primary.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.8
                    )
                )
                .frame(width: size.dimension * 1.4, height: size.dimension * 1.4)
                .blur(radius: 6)

            // Badge background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [tierColors.primary, tierColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.dimension, height: size.dimension)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: tierColors.primary.opacity(0.5), radius: 4)

            // Star icon at top
            Image(systemName: "star.fill")
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .offset(y: -size.dimension * 0.28)

            // Level number
            Text("\(level)")
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .offset(y: 2)
        }
    }
}

// MARK: - XP Progress Bar

struct XPProgressBar: View {
    let currentXP: Int
    let requiredXP: Int
    let height: CGFloat

    private var progress: Double {
        guard requiredXP > 0 else { return 0 }
        return min(1.0, Double(currentXP) / Double(requiredXP))
    }

    init(currentXP: Int, requiredXP: Int, height: CGFloat = 8) {
        self.currentXP = currentXP
        self.requiredXP = requiredXP
        self.height = height
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track with subtle gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                WidgetAurora.Colors.glassBorder.opacity(0.5),
                                WidgetAurora.Colors.glassBorder
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: height)

                // Progress fill with gold gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                WidgetAurora.Colors.gold,
                                WidgetAurora.Colors.flameInner,
                                WidgetAurora.Colors.gold
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geo.size.width * progress), height: height)
                    .shadow(color: WidgetAurora.Colors.gold.opacity(0.5), radius: 4)

                // Shimmer highlight
                if progress > 0.1 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(30, geo.size.width * progress * 0.4), height: height * 0.4)
                        .offset(x: geo.size.width * progress * 0.3, y: -height * 0.15)
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let size: CGFloat

    init(size: CGFloat = 60) {
        self.size = size
    }

    var body: some View {
        ZStack {
            // Outer pulsing glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            WidgetAurora.Colors.cyan.opacity(0.3),
                            WidgetAurora.Colors.violet.opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.9
                    )
                )
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: 12)

            // Button background with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            WidgetAurora.Colors.violet,
                            WidgetAurora.Colors.electric,
                            WidgetAurora.Colors.cyan
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: WidgetAurora.Colors.violet.opacity(0.4), radius: 8, y: 2)

            // Plus icon
            Image(systemName: "plus")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Calendar Date Display

struct CalendarDateDisplay: View {
    let date: Date
    let size: CalendarDisplaySize

    enum CalendarDisplaySize {
        case compact, full
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    var body: some View {
        VStack(spacing: size == .compact ? 2 : 4) {
            // Day name
            Text(dayName)
                .font(.system(size: size == .compact ? 10 : 12, weight: .semibold))
                .foregroundStyle(WidgetAurora.Colors.cyan)

            // Day number with dramatic styling
            Text(dayNumber)
                .font(.system(size: size == .compact ? 32 : 42, weight: .thin, design: .rounded))
                .foregroundStyle(WidgetAurora.Colors.textPrimary)

            // Month
            Text(monthName)
                .font(.system(size: size == .compact ? 9 : 11, weight: .medium))
                .foregroundStyle(WidgetAurora.Colors.textTertiary)
        }
    }
}

// MARK: - Event Card (for Calendar Widget)

struct WidgetEventCard: View {
    let title: String
    let time: String
    let color: Color
    let isTask: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Color indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3)
                .shadow(color: color.opacity(0.5), radius: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WidgetAurora.Typography.body)
                    .foregroundStyle(WidgetAurora.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: isTask ? "checkmark.circle" : "calendar")
                        .font(.system(size: 9))
                    Text(time)
                        .font(WidgetAurora.Typography.micro)
                }
                .foregroundStyle(WidgetAurora.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(WidgetAurora.Colors.glassBase)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Cosmic Orb (for visual flair)

struct CosmicOrb: View {
    let size: CGFloat
    let primaryColor: Color
    let secondaryColor: Color

    init(size: CGFloat = 40, primaryColor: Color = WidgetAurora.Colors.violet, secondaryColor: Color = WidgetAurora.Colors.electric) {
        self.size = size
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [primaryColor.opacity(0.4), secondaryColor.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size * 2, height: size * 2)
                .blur(radius: 8)

            // Main orb
            Circle()
                .fill(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: primaryColor.opacity(0.5), radius: 6)

            // Inner highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.3), .clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.6, height: size * 0.6)
                .offset(x: -size * 0.15, y: -size * 0.15)
        }
    }
}

// MARK: - Preview

#Preview("Design System") {
    ScrollView {
        VStack(spacing: 24) {
            // Aurora Progress Ring
            VStack(spacing: 8) {
                Text("Progress Rings")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                HStack(spacing: 20) {
                    AuroraProgressRing(progress: 0.3, size: 60, lineWidth: 6)
                    AuroraProgressRing(progress: 0.7, size: 80, lineWidth: 8)
                    FocusTimerRing(progress: 0.5, state: .active, size: 60, lineWidth: 6)
                }
            }

            // Flames
            VStack(spacing: 8) {
                Text("Flame Intensities")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                HStack(spacing: 16) {
                    AuroraFlame(intensity: .spark, size: 28)
                    AuroraFlame(intensity: .kindle, size: 32)
                    AuroraFlame(intensity: .flame, size: 36)
                    AuroraFlame(intensity: .blaze, size: 40)
                    AuroraFlame(intensity: .inferno, size: 44)
                }
            }

            // Level Badges
            VStack(spacing: 8) {
                Text("Level Badges")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                HStack(spacing: 16) {
                    LevelBadge(level: 5, size: .small)
                    LevelBadge(level: 15, size: .medium)
                    LevelBadge(level: 35, size: .medium)
                    LevelBadge(level: 100, size: .large)
                }
            }

            // XP Progress Bar
            VStack(spacing: 8) {
                Text("XP Progress")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                XPProgressBar(currentXP: 750, requiredXP: 1000, height: 10)
                    .frame(width: 200)
            }

            // Stat Pills
            VStack(spacing: 8) {
                Text("Stat Pills")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                HStack(spacing: 8) {
                    WidgetStatPill(icon: "checkmark.circle.fill", value: "5", color: WidgetAurora.Colors.success)
                    WidgetStatPill(icon: "flame.fill", value: "7", color: WidgetAurora.Colors.flameInner)
                    WidgetStatPill(icon: "star.fill", value: "Lv 12", color: WidgetAurora.Colors.gold)
                }
            }

            // Quick Add Button
            VStack(spacing: 8) {
                Text("Quick Add")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                QuickAddButton(size: 50)
            }

            // Calendar Display
            VStack(spacing: 8) {
                Text("Date Display")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                CalendarDateDisplay(date: Date(), size: .full)
            }

            // Event Card
            VStack(spacing: 8) {
                Text("Event Cards")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                WidgetEventCard(
                    title: "Team standup",
                    time: "9:00 AM",
                    color: WidgetAurora.Colors.electric,
                    isTask: false
                )
                .frame(width: 200)

                WidgetEventCard(
                    title: "Complete project",
                    time: "2:00 PM",
                    color: WidgetAurora.Colors.violet,
                    isTask: true
                )
                .frame(width: 200)
            }

            // Cosmic Orb
            VStack(spacing: 8) {
                Text("Cosmic Orb")
                    .font(WidgetAurora.Typography.caption)
                    .foregroundStyle(WidgetAurora.Colors.textTertiary)

                CosmicOrb(size: 40)
            }
        }
        .padding(20)
    }
    .background(WidgetCosmicBackground(starCount: 25))
}
