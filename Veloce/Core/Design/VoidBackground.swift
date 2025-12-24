//
//  VoidBackground.swift
//  Veloce
//
//  Void Background View
//  Deep cosmic background with twinkling stars and ambient glow
//  Used across all pages for unified void aesthetic
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

    @State private var twinklePhase: Double = 0
    @State private var stars: [StarParticle] = []

    init(
        glowPosition: VoidDesign.GlowPosition = .bottom,
        glowColor: Color = Theme.Colors.aiPurple,
        starCount: Int = VoidDesign.Stars.countStandard,
        showOrb: Bool = false,
        orbSize: VoidDesign.OrbSize = .medium,
        orbStyle: AIOrbAnimationStyle = .breathing
    ) {
        self.glowPosition = glowPosition
        self.glowColor = glowColor
        self.starCount = starCount
        self.showOrb = showOrb
        self.orbSize = orbSize
        self.orbStyle = orbStyle
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep black gradient base
                voidGradient

                // Ambient glow
                ambientGlow(in: geometry)

                // Star field
                starField(in: geometry)

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
            startTwinkle()
        }
    }

    // MARK: - Void Gradient

    private var voidGradient: some View {
        LinearGradient(
            colors: [
                VoidDesign.Colors.voidBlack,
                VoidDesign.Colors.voidSurface,
                VoidDesign.Colors.voidDeep
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Ambient Glow

    private func ambientGlow(in geometry: GeometryProxy) -> some View {
        RadialGradient(
            colors: [
                glowColor.opacity(glowPosition.intensity),
                Color.clear
            ],
            center: glowUnitPoint(in: geometry),
            startRadius: 0,
            endRadius: glowPosition.radius
        )
    }

    private func glowUnitPoint(in geometry: GeometryProxy) -> UnitPoint {
        // Convert glow position to actual unit point
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

    // MARK: - Star Field

    private func starField(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            for star in stars {
                let twinkle = sin(twinklePhase + star.twinkleDelay * .pi) * 0.5 + 0.5
                let opacity = star.baseOpacity * (0.5 + twinkle * 0.5)

                let rect = CGRect(
                    x: star.position.x - star.size / 2,
                    y: star.position.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )

                context.fill(
                    Circle().path(in: rect),
                    with: .color(star.isBright ? VoidDesign.Colors.starWhite.opacity(opacity) : VoidDesign.Colors.starDim.opacity(opacity))
                )
            }
        }
        .onAppear {
            regenerateStars(in: geometry.size)
        }
        .onChange(of: geometry.size) { _, newSize in
            regenerateStars(in: newSize)
        }
    }

    private func regenerateStars(in size: CGSize) {
        stars = StarParticle.generateField(count: starCount, in: size, brightPercentage: 0.15)
    }

    private func startTwinkle() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            twinklePhase = .pi * 2
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
        VoidBackground(glowPosition: .bottom, glowColor: Theme.Colors.aiPurple)
    }

    /// Calendar page background (glow at top trailing)
    static var calendar: VoidBackground {
        VoidBackground(glowPosition: .topTrailing, glowColor: Theme.Colors.aiBlue)
    }

    /// Momentum tab background (unified purple glow)
    static var momentum: VoidBackground {
        VoidBackground(glowPosition: .center, glowColor: Theme.Colors.aiPurple, starCount: VoidDesign.Stars.countDense)
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
        VoidBackground(glowPosition: .center, glowColor: Theme.Colors.aiCyan, starCount: VoidDesign.Stars.countSparse)
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
            VoidDesign.Colors.voidBlack

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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Base material
            Rectangle()
                .fill(.ultraThinMaterial)

            // Void overlay
            LinearGradient(
                colors: [
                    VoidDesign.Colors.voidSurface.opacity(0.8),
                    VoidDesign.Colors.voidDeep.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle AI gradient
            LinearGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.05),
                    Theme.Colors.aiBlue.opacity(0.03),
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
                                Theme.Colors.aiPurple.opacity(0.3),
                                Theme.Colors.aiBlue.opacity(0.2),
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
        starCount: Int = VoidDesign.Stars.countStandard
    ) -> some View {
        self.background {
            VoidBackground(
                glowPosition: glowPosition,
                glowColor: glowColor,
                starCount: starCount
            )
        }
    }

    /// Apply simple void background (no stars)
    func simpleVoidBackground(glowColor: Color = Theme.Colors.aiPurple) -> some View {
        self.background {
            SimpleVoidBackground(glowColor: glowColor)
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

#Preview("Void Background - Auth") {
    VStack {
        Spacer()

        Text("MyTasksAI")
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

#Preview("Void Background - Calendar") {
    VStack {
        Text("Calendar Page")
            .font(.largeTitle)
            .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
        VoidBackground.calendar
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

        VoidBackground.settings
            .overlay {
                Text("Settings").foregroundStyle(.white)
            }
            .tabItem { Text("Settings") }

        VoidBackground.focus
            .overlay {
                Text("Focus").foregroundStyle(.white)
            }
            .tabItem { Text("Focus") }
    }
}
