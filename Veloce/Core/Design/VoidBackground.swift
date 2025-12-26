//
//  VoidBackground.swift
//  Veloce
//
//  Living Cosmos - Dynamic Productivity Nebula
//  Deep cosmic background with dynamic nebula that responds to productivity,
//  ambient star field, and parallax effects for scroll response
//

import SwiftUI

// MARK: - Void Background

/// The cosmic void background used throughout the app
struct VoidBackground: View {
    let glowPosition: VoidDesign.GlowPosition
    let glowColor: Color
    let starCount: Int
    let showOrb: Bool
    let orbSize: VoidDesign.OrbSize
    let orbStyle: AIOrbAnimationStyle
    let productivity: ProductivityLevel
    let enableParallax: Bool

    @State private var twinklePhase: Double = 0
    @State private var nebulaPhase: CGFloat = 0
    @State private var stars: [CosmicStar] = []
    @State private var scrollOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum ProductivityLevel {
        case neutral
        case productive
        case struggling

        var nebulaColors: [Color] {
            switch self {
            case .neutral:
                return [
                    Theme.CelestialColors.nebulaCore,
                    Theme.CelestialColors.nebulaEdge,
                    Theme.Colors.aiPurple
                ]
            case .productive:
                return [
                    Theme.CelestialColors.auroraGreen.opacity(0.8),
                    Theme.CelestialColors.plasmaCore,
                    Theme.Colors.aiPurple
                ]
            case .struggling:
                return [
                    Theme.CelestialColors.nebulaCore.opacity(0.6),
                    Theme.CelestialColors.nebulaEdge.opacity(0.4),
                    Color.clear
                ]
            }
        }

        var intensity: Double {
            switch self {
            case .neutral: return 0.12
            case .productive: return 0.18
            case .struggling: return 0.06
            }
        }
    }

    init(
        glowPosition: VoidDesign.GlowPosition = .bottom,
        glowColor: Color = Theme.Colors.aiPurple,
        starCount: Int = VoidDesign.Stars.countStandard,
        showOrb: Bool = false,
        orbSize: VoidDesign.OrbSize = .medium,
        orbStyle: AIOrbAnimationStyle = .breathing,
        productivity: ProductivityLevel = .neutral,
        enableParallax: Bool = true
    ) {
        self.glowPosition = glowPosition
        self.glowColor = glowColor
        self.starCount = starCount
        self.showOrb = showOrb
        self.orbSize = orbSize
        self.orbStyle = orbStyle
        self.productivity = productivity
        self.enableParallax = enableParallax
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep void gradient base
                voidGradient

                // Dynamic nebula layers
                dynamicNebula(in: geometry)

                // Ambient glow
                ambientGlow(in: geometry)

                // Enhanced star field
                cosmicStarField(in: geometry)

                // Optional centered orb
                if showOrb {
                    AIOrb(
                        size: orbSize,
                        animationStyle: orbStyle,
                        showParticles: orbStyle == .thinking,
                        showRings: true
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.35
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startCosmicAnimations()
        }
    }

    // MARK: - Void Gradient

    private var voidGradient: some View {
        LinearGradient(
            colors: [
                Theme.CelestialColors.voidDeep,
                Theme.CelestialColors.void,
                Theme.CelestialColors.abyss
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Dynamic Nebula

    private func dynamicNebula(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Primary nebula cloud
            NebulaCloud(
                colors: productivity.nebulaColors,
                position: UnitPoint(x: 0.3, y: 0.2),
                radius: 300,
                phase: nebulaPhase,
                intensity: productivity.intensity
            )

            // Secondary nebula wisp
            NebulaCloud(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.1),
                    Theme.CelestialColors.plasmaCore.opacity(0.05),
                    Color.clear
                ],
                position: UnitPoint(x: 0.7, y: 0.6),
                radius: 200,
                phase: nebulaPhase * 0.7,
                intensity: 0.08
            )

            // Tertiary distant wisp
            NebulaCloud(
                colors: [
                    Theme.CelestialColors.nebulaEdge.opacity(0.06),
                    Color.clear
                ],
                position: UnitPoint(x: 0.1, y: 0.8),
                radius: 250,
                phase: nebulaPhase * 0.5,
                intensity: 0.05
            )
        }
        .offset(y: enableParallax ? scrollOffset * 0.1 : 0)
    }

    // MARK: - Ambient Glow

    private func ambientGlow(in geometry: GeometryProxy) -> some View {
        RadialGradient(
            colors: [
                glowColor.opacity(glowPosition.intensity * (productivity == .productive ? 1.3 : 1)),
                glowColor.opacity(glowPosition.intensity * 0.3),
                Color.clear
            ],
            center: glowUnitPoint(in: geometry),
            startRadius: 0,
            endRadius: glowPosition.radius
        )
    }

    private func glowUnitPoint(in geometry: GeometryProxy) -> UnitPoint {
        switch glowPosition {
        case .bottom:
            return .bottom
        case .topTrailing:
            return .topTrailing
        case .center, .centerSubtle:
            return .center
        case .bottomLeading:
            return .bottomLeading
        }
    }

    // MARK: - Cosmic Star Field

    private func cosmicStarField(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            for star in stars {
                let twinkle = reduceMotion ? 1.0 : sin(twinklePhase + star.twinkleDelay * .pi) * 0.5 + 0.5
                let opacity = star.baseOpacity * (0.5 + twinkle * 0.5)

                // Parallax offset for depth
                let parallaxY = enableParallax ? scrollOffset * star.parallaxFactor * 0.05 : 0

                let rect = CGRect(
                    x: star.position.x - star.size / 2,
                    y: star.position.y - star.size / 2 + parallaxY,
                    width: star.size,
                    height: star.size
                )

                // Color based on star type
                let starColor: Color
                switch star.starType {
                case .bright:
                    starColor = Color.white.opacity(opacity)
                case .plasma:
                    starColor = Theme.CelestialColors.plasmaCore.opacity(opacity * 0.8)
                case .nebula:
                    starColor = Theme.CelestialColors.nebulaEdge.opacity(opacity * 0.6)
                case .dim:
                    starColor = Theme.CelestialColors.starDim.opacity(opacity)
                }

                context.fill(
                    SwiftUI.Circle().path(in: rect),
                    with: .color(starColor)
                )

                // Glow for larger stars
                if star.size > 2 && !reduceMotion {
                    let glowRect = CGRect(
                        x: star.position.x - star.size,
                        y: star.position.y - star.size + parallaxY,
                        width: star.size * 2,
                        height: star.size * 2
                    )
                    context.fill(
                        SwiftUI.Circle().path(in: glowRect),
                        with: .color(starColor.opacity(0.2))
                    )
                }
            }
        }
        .onAppear {
            // Use a reasonable default size, actual size determined by view bounds
            regenerateStars(in: CGSize(width: 400, height: 800))
        }
    }

    private func regenerateStars(in size: CGSize) {
        stars = CosmicStar.generateField(count: starCount, in: size)
    }

    // MARK: - Animations

    private func startCosmicAnimations() {
        guard !reduceMotion else { return }

        // Star twinkle
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            twinklePhase = .pi * 2
        }

        // Nebula drift
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            nebulaPhase = 1
        }
    }

    // MARK: - Scroll Tracking

    func trackScroll(offset: CGFloat) -> VoidBackground {
        // Note: Since scrollOffset is @State, we can't modify it on a copy.
        // This method returns self unchanged - scroll tracking should be done
        // via a different mechanism (e.g., PreferenceKey or initializer parameter)
        let result = self
        // scrollOffset is managed by SwiftUI @State, not modifiable on struct copy
        return result
    }
}

// MARK: - Nebula Cloud

struct NebulaCloud: View {
    let colors: [Color]
    let position: UnitPoint
    let radius: CGFloat
    let phase: CGFloat
    let intensity: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RadialGradient(
            colors: colors.map { $0.opacity(intensity) } + [Color.clear],
            center: animatedPosition,
            startRadius: 20,
            endRadius: radius
        )
        .blur(radius: 30)
    }

    private var animatedPosition: UnitPoint {
        guard !reduceMotion else { return position }

        let xDrift = Darwin.sin(Double(phase) * .pi * 2) * 0.05
        let yDrift = Darwin.cos(Double(phase) * .pi * 2) * 0.03

        return UnitPoint(
            x: position.x + xDrift,
            y: position.y + yDrift
        )
    }
}

// MARK: - Cosmic Star

struct CosmicStar: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let twinkleDelay: Double
    let parallaxFactor: CGFloat
    let starType: StarType

    enum StarType {
        case bright
        case plasma
        case nebula
        case dim
    }

    static func generateField(count: Int, in size: CGSize) -> [CosmicStar] {
        (0..<count).map { _ in
            let starType: StarType
            let random = Double.random(in: 0...1)
            if random < 0.1 {
                starType = .bright
            } else if random < 0.2 {
                starType = .plasma
            } else if random < 0.3 {
                starType = .nebula
            } else {
                starType = .dim
            }

            return CosmicStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: starType == .bright ? CGFloat.random(in: 2...3) : CGFloat.random(in: 0.8...2),
                baseOpacity: starType == .bright ? Double.random(in: 0.6...0.9) : Double.random(in: 0.3...0.6),
                twinkleDelay: Double.random(in: 0...2),
                parallaxFactor: CGFloat.random(in: 0.2...1.0),
                starType: starType
            )
        }
    }
}

// MARK: - Void Background Variants

extension VoidBackground {
    /// Standard background (default settings)
    static var standard: VoidBackground {
        VoidBackground(glowPosition: .bottom, glowColor: Theme.Colors.aiPurple)
    }

    /// Tasks page background (glow at bottom)
    static var tasks: VoidBackground {
        VoidBackground(glowPosition: .bottom, glowColor: Theme.Colors.aiPurple, productivity: .neutral)
    }

    /// Productive tasks background (enhanced glow)
    static func tasksProductive(completedCount: Int) -> VoidBackground {
        VoidBackground(
            glowPosition: .bottom,
            glowColor: Theme.Colors.aiPurple,
            productivity: completedCount > 3 ? .productive : .neutral
        )
    }

    /// Calendar page background (glow at top trailing)
    static var calendar: VoidBackground {
        VoidBackground(glowPosition: .topTrailing, glowColor: Theme.Colors.aiBlue)
    }

    /// Momentum tab background (unified purple glow)
    static var momentum: VoidBackground {
        VoidBackground(glowPosition: .center, glowColor: Theme.Colors.aiPurple, starCount: VoidDesign.Stars.countDense, productivity: .productive)
    }

    /// Journal page background (unified purple glow with standard stars)
    static var journal: VoidBackground {
        VoidBackground(glowPosition: .bottom, glowColor: Theme.Colors.aiPurple, starCount: VoidDesign.Stars.countStandard)
    }

    /// Brain dump background (glow at bottom leading)
    static var brainDump: VoidBackground {
        VoidBackground(glowPosition: .bottomLeading, glowColor: Theme.Colors.aiPurple, starCount: VoidDesign.Stars.countDense)
    }

    /// Settings background (subtle center glow)
    static var settings: VoidBackground {
        VoidBackground(glowPosition: .centerSubtle, glowColor: Theme.Colors.aiPurple, starCount: VoidDesign.Stars.countSparse)
    }

    /// Focus mode background (strong center glow)
    static var focus: VoidBackground {
        VoidBackground(glowPosition: .center, glowColor: Theme.Colors.aiAmber, starCount: VoidDesign.Stars.countSparse)
    }

    /// AI Hub background (purple/cyan glow)
    static var ai: VoidBackground {
        VoidBackground(glowPosition: .center, glowColor: Theme.Colors.aiPurple, starCount: VoidDesign.Stars.countStandard)
    }

    /// Circles/Social tab background (purple/blue social glow)
    static var circles: VoidBackground {
        VoidBackground(
            glowPosition: .center,
            glowColor: Theme.Colors.aiPurple,
            starCount: VoidDesign.Stars.countStandard,
            productivity: .neutral
        )
    }

    /// Auth background with hero orb
    static var auth: VoidBackground {
        VoidBackground(
            glowPosition: .center,
            glowColor: Theme.Colors.aiPurple,
            starCount: VoidDesign.Stars.countDense,
            showOrb: true,
            orbSize: .hero,
            orbStyle: .breathing
        )
    }

    /// Onboarding background with medium orb
    static var onboarding: VoidBackground {
        VoidBackground(
            glowPosition: .center,
            glowColor: Theme.Colors.aiPurple,
            starCount: VoidDesign.Stars.countStandard,
            showOrb: true,
            orbSize: .large,
            orbStyle: .breathing
        )
    }

    /// Celebration background (task completed)
    static var celebration: VoidBackground {
        VoidBackground(
            glowPosition: .center,
            glowColor: Theme.CelestialColors.auroraGreen,
            starCount: VoidDesign.Stars.countDense,
            productivity: .productive
        )
    }
}

// MARK: - Simple Void Background

/// Lightweight void background without stars (for sheets/overlays)
struct SimpleVoidBackground: View {
    let glowColor: Color
    let glowOpacity: Double

    init(glowColor: Color = Theme.Colors.aiPurple, glowOpacity: Double = 0.1) {
        self.glowColor = glowColor
        self.glowOpacity = glowOpacity
    }

    var body: some View {
        ZStack {
            Theme.CelestialColors.voidDeep

            // Nebula hint
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaCore.opacity(glowOpacity * 0.5),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadius: 0,
                endRadius: 200
            )

            RadialGradient(
                colors: [
                    glowColor.opacity(glowOpacity),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Void Sheet Background

/// Background for bottom sheets with void styling
struct VoidSheetBackground: View {
    var body: some View {
        ZStack {
            // Base material
            Rectangle()
                .fill(.ultraThinMaterial)

            // Void overlay
            LinearGradient(
                colors: [
                    Theme.CelestialColors.abyss.opacity(0.9),
                    Theme.CelestialColors.void.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Nebula hint
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaCore.opacity(0.06),
                    Color.clear
                ],
                center: UnitPoint(x: 0.2, y: 0.2),
                startRadius: 0,
                endRadius: 200
            )

            // Subtle AI gradient
            LinearGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.05),
                    Theme.CelestialColors.plasmaCore.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Top border highlight
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.plasmaCore.opacity(0.4),
                                Theme.Colors.aiPurple.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - View Extension

extension View {
    /// Apply void background to a view
    func voidBackground(
        glowPosition: VoidDesign.GlowPosition = .bottom,
        glowColor: Color = Theme.Colors.aiPurple,
        starCount: Int = VoidDesign.Stars.countStandard,
        productivity: VoidBackground.ProductivityLevel = .neutral
    ) -> some View {
        self.background {
            VoidBackground(
                glowPosition: glowPosition,
                glowColor: glowColor,
                starCount: starCount,
                productivity: productivity
            )
        }
    }

    /// Apply simple void background (no stars)
    func simpleVoidBackground(glowColor: Color = Theme.Colors.aiPurple) -> some View {
        self.background {
            SimpleVoidBackground(glowColor: glowColor)
        }
    }

    /// Apply dynamic void background based on productivity
    func dynamicVoidBackground(completedTasks: Int, totalTasks: Int) -> some View {
        let productivity: VoidBackground.ProductivityLevel
        if totalTasks == 0 {
            productivity = .neutral
        } else if Double(completedTasks) / Double(totalTasks) > 0.5 {
            productivity = .productive
        } else if completedTasks == 0 {
            productivity = .struggling
        } else {
            productivity = .neutral
        }

        return self.background {
            VoidBackground(
                glowPosition: .bottom,
                glowColor: Theme.Colors.aiPurple,
                productivity: productivity
            )
        }
    }
}

// MARK: - Presentation Background Extension

extension View {
    /// Apply void sheet background for presentations
    func voidPresentationBackground() -> some View {
        self.presentationBackground {
            VoidSheetBackground()
        }
    }
}

// MARK: - Preview

#Preview("Void Background - Tasks") {
    VStack {
        Text("Tasks Page")
            .font(.largeTitle)
            .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
        VoidBackground.tasks
    }
}

#Preview("Void Background - Productive") {
    VStack {
        Text("Productive Mode")
            .font(.largeTitle)
            .foregroundStyle(.white)

        Text("3+ tasks completed")
            .foregroundStyle(Theme.CelestialColors.auroraGreen)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
        VoidBackground.tasksProductive(completedCount: 5)
    }
}

#Preview("Void Background - Auth") {
    VStack {
        Spacer()

        Text("Veloce")
            .font(.system(size: 40, weight: .bold))
            .foregroundStyle(.white)

        Text("AI-Powered Productivity")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))

        Spacer()
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
        VoidBackground.auth
    }
}

#Preview("Void Background - Celebration") {
    VStack {
        Text("Task Completed!")
            .font(.largeTitle)
            .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
        VoidBackground.celebration
    }
}

#Preview("Void Background Variants") {
    TabView {
        VoidBackground.tasks
            .overlay {
                Text("Tasks").foregroundStyle(.white)
            }
            .tabItem { Text("Tasks") }

        VoidBackground.calendar
            .overlay {
                Text("Calendar").foregroundStyle(.white)
            }
            .tabItem { Text("Calendar") }

        VoidBackground.brainDump
            .overlay {
                Text("Brain Dump").foregroundStyle(.white)
            }
            .tabItem { Text("Brain") }

        VoidBackground.focus
            .overlay {
                Text("Focus").foregroundStyle(.white)
            }
            .tabItem { Text("Focus") }

        VoidBackground.celebration
            .overlay {
                Text("Celebration").foregroundStyle(.white)
            }
            .tabItem { Text("Celebrate") }
    }
}
