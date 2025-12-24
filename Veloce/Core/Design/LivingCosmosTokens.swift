//
//  LivingCosmosTokens.swift
//  Veloce
//
//  Living Cosmos Unified Design System
//  Consolidates all celestial design tokens for consistent app-wide styling
//

import SwiftUI

// MARK: - Living Cosmos Design System

/// Unified design tokens for the Living Cosmos aesthetic
enum LivingCosmos {

    // MARK: - Page Backgrounds

    /// Pre-configured VoidBackground variants for each page
    enum Backgrounds {
        /// Tasks page - bottom purple glow, standard stars
        static var tasks: some View {
            VoidBackground.tasks
        }

        /// Calendar page - blue topTrailing glow
        static var calendar: some View {
            VoidBackground.calendar
        }

        /// Momentum page - center glow, dense stars, productive
        static var momentum: some View {
            VoidBackground.momentum
        }

        /// Focus page - amber center glow, sparse stars
        static var focus: some View {
            VoidBackground.focus
        }

        /// Circles page - purple center glow for social
        static var circles: some View {
            VoidBackground(
                glowPosition: .center,
                glowColor: Theme.Colors.aiPurple,
                starCount: VoidDesign.Stars.countStandard,
                productivity: .neutral
            )
        }

        /// Journal page - bottom glow, standard stars
        static var journal: some View {
            VoidBackground.journal
        }

        /// Settings page - subtle center glow, sparse stars
        static var settings: some View {
            VoidBackground.settings
        }

        /// Auth page - center glow with hero orb
        static var auth: some View {
            VoidBackground.auth
        }

        /// Onboarding page - center glow with large orb
        static var onboarding: some View {
            VoidBackground.onboarding
        }
    }

    // MARK: - Section Styling

    /// Section header styling tokens
    enum SectionHeader {
        static let font = Theme.Typography.cosmosSectionHeader
        static let color = Theme.CelestialColors.starDim
        static let spacing: CGFloat = Theme.Spacing.sm
        static let letterSpacing: CGFloat = 1.5
    }

    // MARK: - Card Styling

    /// Floating island card tokens
    enum FloatingIsland {
        static let cornerRadius: CGFloat = 20
        static let padding: CGFloat = Theme.Spacing.lg
        static let glowIntensity: Double = 0.15
        static let borderOpacity: Double = 0.2
        static let shadowRadius: CGFloat = 16
        static let floatOffset: CGFloat = 4

        /// Glass material for cards
        static let material: Material = .ultraThinMaterial
    }

    // MARK: - Button Tokens

    enum Button {
        /// Primary button gradient
        static let primaryGradient = LinearGradient(
            colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// Secondary button background
        static let secondaryBackground = Theme.CelestialColors.void.opacity(0.6)

        /// Ghost button border
        static let ghostBorder = Theme.CelestialColors.starDim

        /// Button corner radius
        static let cornerRadius: CGFloat = 14

        /// Button height
        static let height: CGFloat = 54

        /// Icon size in buttons
        static let iconSize: CGFloat = 18

        /// Press scale effect
        static let pressScale: CGFloat = 0.96
    }

    // MARK: - Toggle/Stepper Tokens

    enum Controls {
        /// Icon container size
        static let iconContainerSize: CGFloat = 40

        /// Icon size
        static let iconSize: CGFloat = 18

        /// Row padding
        static let rowPadding: CGFloat = Theme.Spacing.md

        /// Row height
        static let rowHeight: CGFloat = 56

        /// Divider inset
        static let dividerInset: CGFloat = 56
    }

    // MARK: - Progress Bar Tokens

    enum ProgressBar {
        /// Bar height
        static let height: CGFloat = 8

        /// Corner radius
        static let cornerRadius: CGFloat = 4

        /// Glow radius for tip
        static let glowRadius: CGFloat = 8

        /// Background opacity
        static let backgroundOpacity: Double = 0.2
    }

    // MARK: - Avatar Tokens

    enum Avatar {
        /// Small avatar size
        static let sizeSmall: CGFloat = 40

        /// Medium avatar size
        static let sizeMedium: CGFloat = 60

        /// Large avatar size
        static let sizeLarge: CGFloat = 100

        /// Hero avatar size (profile edit)
        static let sizeHero: CGFloat = 140

        /// Border width
        static let borderWidth: CGFloat = 3

        /// Level badge size
        static let badgeSize: CGFloat = 28

        /// Edit button size
        static let editButtonSize: CGFloat = 36
    }

    // MARK: - Animation Presets

    enum Animations {
        /// Standard spring animation
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)

        /// Quick spring for micro-interactions
        static let quick = Animation.spring(response: 0.2, dampingFraction: 0.7)

        /// Stagger delay between items
        static let staggerDelay: Double = 0.08

        /// Portal open animation
        static let portalOpen = Animation.spring(response: 0.5, dampingFraction: 0.75)

        /// Stellar bounce for reveals
        static let stellarBounce = Animation.spring(response: 0.6, dampingFraction: 0.7)

        /// Plasma pulse for highlights
        static let plasmaPulse = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

        /// Orbital float for ambient motion
        static let orbitalFloat = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)

        /// Supernova burst duration
        static let supernovaDuration: Double = 0.6
    }

    // MARK: - Glow Effects

    enum Glow {
        /// Subtle glow for cards
        static let subtle: CGFloat = 8

        /// Medium glow for active states
        static let medium: CGFloat = 12

        /// Strong glow for emphasis
        static let strong: CGFloat = 20

        /// Plasma glow for energy effects
        static let plasma: CGFloat = 30
    }

    // MARK: - Onboarding Tokens

    enum Onboarding {
        /// Progress orb size
        static let progressOrbSize: CGFloat = 12

        /// Progress orb spacing
        static let progressOrbSpacing: CGFloat = 8

        /// Feature card icon size
        static let featureIconSize: CGFloat = 48

        /// Step transition delay
        static let stepTransitionDelay: Double = 0.3

        /// Celebration particle count
        static let celebrationParticles: Int = 32
    }

    // MARK: - Calendar Tokens

    enum Calendar {
        /// Hour height in day view (cosmic-scaled for readability)
        static let hourHeight: CGFloat = 80

        /// Compact hour height for week view
        static let compactHourHeight: CGFloat = 50

        /// Time gutter width (for "NOW" label and times)
        static let timeGutterWidth: CGFloat = 54

        /// Task block corner radius (softer for plasma feel)
        static let blockCornerRadius: CGFloat = 14

        /// Minimum block height for tasks
        static let minBlockHeight: CGFloat = 48

        /// Day cell size for month view
        static let dayCellSize: CGFloat = 44

        /// Now indicator dot size (plasma core)
        static let nowDotSize: CGFloat = 12

        /// View switcher height
        static let viewSwitcherHeight: CGFloat = 44

        /// Start hour for day timeline
        static let startHour: Int = 6

        /// End hour for day timeline
        static let endHour: Int = 24

        /// Week day column calculated width
        static var weekDayColumnWidth: CGFloat {
            (UIScreen.main.bounds.width - timeGutterWidth - 32) / 7
        }

        /// Month grid cell size
        static let monthCellSize: CGFloat = (UIScreen.main.bounds.width - 48) / 7

        /// Event block opacity (secondary to tasks)
        static let eventOpacity: Double = 0.75

        /// Header height with date carousel
        static let headerHeight: CGFloat = 100

        /// Snap interval for drag-to-reschedule (minutes)
        static let snapInterval: Int = 15

        /// Quick-add portal animation duration
        static let portalDuration: Double = 0.4

        /// Task block inner padding
        static let blockPadding: CGFloat = 12

        /// Max task indicator dots in month view
        static let maxIndicatorDots: Int = 3
    }
}

// MARK: - Cosmos Glass View Modifier (Simple version for LivingCosmos)

struct CosmosGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let accentColor: Color?
    let isSelected: Bool
    let padding: CGFloat

    init(
        cornerRadius: CGFloat = LivingCosmos.FloatingIsland.cornerRadius,
        accentColor: Color? = nil,
        isSelected: Bool = false,
        padding: CGFloat = LivingCosmos.FloatingIsland.padding
    ) {
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
        self.isSelected = isSelected
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LivingCosmos.FloatingIsland.material)
                    .overlay {
                        // Accent gradient overlay
                        if let accent = accentColor ?? (isSelected ? Theme.Colors.aiPurple : nil) {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            accent.opacity(0.08),
                                            accent.opacity(0.03),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .overlay {
                        // Border
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isSelected ? 0.3 : 0.2),
                                        Color.white.opacity(0.1),
                                        (accentColor ?? Theme.Colors.aiPurple).opacity(isSelected ? 0.4 : 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    }
            }
            .shadow(
                color: (accentColor ?? Theme.Colors.aiPurple).opacity(isSelected ? 0.2 : 0.1),
                radius: isSelected ? LivingCosmos.Glow.medium : LivingCosmos.Glow.subtle
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 8,
                y: 4
            )
    }
}

// MARK: - Cosmos Floating Island View Modifier

struct CosmosFloatingIslandModifier: ViewModifier {
    let accentColor: Color
    @State private var floatOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .modifier(CosmosGlassModifier(accentColor: accentColor, isSelected: true))
            .offset(y: reduceMotion ? 0 : floatOffset)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(LivingCosmos.Animations.orbitalFloat) {
                    floatOffset = LivingCosmos.FloatingIsland.floatOffset
                }
            }
    }
}

// MARK: - Cosmos Staggered Reveal Modifier

struct CosmosStaggeredRevealModifier: ViewModifier {
    let index: Int
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                LivingCosmos.Animations.stellarBounce.delay(Double(index) * LivingCosmos.Animations.staggerDelay),
                value: isVisible
            )
    }
}

// MARK: - Cosmos Supernova Burst Modifier

struct CosmosSupernovaBurstModifier: ViewModifier {
    @Binding var trigger: Bool
    let color: Color
    let particleCount: Int

    @State private var particles: [CosmosSupernovaParticle] = []

    func body(content: Content) -> some View {
        ZStack {
            content

            ForEach(particles) { particle in
                SwiftUI.Circle()
                    .fill(color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.width, y: particle.offset.height)
                    .opacity(particle.opacity)
                    .blur(radius: particle.blur)
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue {
                triggerBurst()
            }
        }
    }

    private func triggerBurst() {
        particles = (0..<particleCount).map { _ in
            CosmosSupernovaParticle()
        }

        withAnimation(.easeOut(duration: LivingCosmos.Animations.supernovaDuration)) {
            particles = particles.map { particle in
                var p = particle
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 50...150)
                p.offset = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
                p.opacity = 0
                p.blur = 4
                return p
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + LivingCosmos.Animations.supernovaDuration) {
            trigger = false
            particles = []
        }
    }
}

struct CosmosSupernovaParticle: Identifiable {
    let id = UUID()
    var offset: CGSize = .zero
    var opacity: Double = 1
    var blur: CGFloat = 0
    let size: CGFloat = CGFloat.random(in: 4...8)
}

// MARK: - View Extensions

extension View {
    /// Apply celestial glass card styling (uses simple cosmos glass)
    func celestialGlass(
        cornerRadius: CGFloat = LivingCosmos.FloatingIsland.cornerRadius,
        accentColor: Color? = nil,
        isSelected: Bool = false,
        padding: CGFloat = LivingCosmos.FloatingIsland.padding
    ) -> some View {
        modifier(CosmosGlassModifier(
            cornerRadius: cornerRadius,
            accentColor: accentColor,
            isSelected: isSelected,
            padding: padding
        ))
    }

    /// Apply floating island styling with ambient motion
    func floatingIsland(accentColor: Color = Theme.Colors.aiPurple) -> some View {
        modifier(CosmosFloatingIslandModifier(accentColor: accentColor))
    }

    /// Apply staggered reveal animation (index-based)
    func staggeredReveal(index: Int, isVisible: Bool) -> some View {
        modifier(CosmosStaggeredRevealModifier(index: index, isVisible: isVisible))
    }

    /// Apply supernova burst effect
    func supernovaBurst(
        trigger: Binding<Bool>,
        color: Color = Theme.CelestialColors.auroraGreen,
        particleCount: Int = 24
    ) -> some View {
        modifier(CosmosSupernovaBurstModifier(trigger: trigger, color: color, particleCount: particleCount))
    }
}

// MARK: - Section Header View

struct CosmicSectionHeader: View {
    let title: String
    let icon: String?
    let iconColor: Color

    init(_ title: String, icon: String? = nil, iconColor: Color = Theme.CelestialColors.starDim) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title.uppercased())
                .font(LivingCosmos.SectionHeader.font)
                .foregroundStyle(LivingCosmos.SectionHeader.color)
                .tracking(LivingCosmos.SectionHeader.letterSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview("Celestial Glass Cards") {
    ZStack {
        VoidBackground.tasks

        VStack(spacing: Theme.Spacing.lg) {
            Text("Regular Card")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .celestialGlass()

            Text("Selected Card")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .celestialGlass(isSelected: true)

            Text("Accent Card")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .celestialGlass(accentColor: Theme.CelestialColors.auroraGreen)

            Text("Floating Island")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .floatingIsland()
        }
        .padding()
    }
}

#Preview("Section Headers") {
    ZStack {
        VoidBackground.settings

        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            CosmicSectionHeader("Preferences")
            CosmicSectionHeader("Daily Goals", icon: "target", iconColor: Theme.Colors.success)
            CosmicSectionHeader("Account", icon: "person.fill", iconColor: Theme.Colors.aiPurple)
        }
        .padding()
    }
}
