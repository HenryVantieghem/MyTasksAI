//
//  AuroraBackground.swift
//  Veloce
//
//  Aurora Background
//  Ethereal flowing aurora borealis effect with animated streamers,
//  twinkling starfield, and ambient glow
//

import SwiftUI

// MARK: - Aurora Background

struct AuroraBackground: View {
    let showStars: Bool
    let starCount: Int
    let auroraIntensity: Double
    let glowColor: Color
    let glowPosition: UnitPoint
    let animated: Bool

    @State private var auroraPhase: Double = 0
    @State private var twinklePhase: Double = 0
    @State private var stars: [AuroraStarParticle] = []

    init(
        showStars: Bool = true,
        starCount: Int = 30,
        auroraIntensity: Double = 0.35,
        glowColor: Color = Aurora.Colors.violet,
        glowPosition: UnitPoint = .center,
        animated: Bool = true
    ) {
        self.showStars = showStars
        self.starCount = starCount
        self.auroraIntensity = auroraIntensity
        self.glowColor = glowColor
        self.glowPosition = glowPosition
        self.animated = animated
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Deep cosmic black base
                cosmicBase

                // Layer 2: Flowing aurora streamers
                auroraStreamers(in: geometry)

                // Layer 3: Central ambient glow
                ambientGlow

                // Layer 4: Star field
                if showStars {
                    starField(in: geometry)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if animated {
                startAnimations()
            }
        }
    }

    // MARK: - Cosmic Base

    private var cosmicBase: some View {
        LinearGradient(
            colors: [
                Aurora.Colors.cosmicBlack,
                Aurora.Colors.cosmicDeep,
                Aurora.Colors.cosmicBlack
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Aurora Streamers

    private func auroraStreamers(in geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height

        return ZStack {
            // Streamer 1: Violet → Electric (top-left to center)
            auroraStreamer(
                colors: [Aurora.Colors.violet, Aurora.Colors.purple, Aurora.Colors.electric],
                startPoint: UnitPoint(x: -0.2 + auroraPhase * 0.3, y: 0.1),
                endPoint: UnitPoint(x: 0.8 + auroraPhase * 0.2, y: 0.5),
                width: width,
                height: height,
                opacity: auroraIntensity * 0.8,
                blur: 80
            )

            // Streamer 2: Electric → Cyan (top-right flowing down)
            auroraStreamer(
                colors: [Aurora.Colors.electric, Aurora.Colors.cyan],
                startPoint: UnitPoint(x: 0.9 - auroraPhase * 0.2, y: 0.0),
                endPoint: UnitPoint(x: 0.3 - auroraPhase * 0.15, y: 0.6),
                width: width,
                height: height,
                opacity: auroraIntensity * 0.6,
                blur: 100
            )

            // Streamer 3: Cyan → Emerald (subtle bottom accent)
            auroraStreamer(
                colors: [Aurora.Colors.cyan.opacity(0.7), Aurora.Colors.emerald.opacity(0.5)],
                startPoint: UnitPoint(x: 0.1 + auroraPhase * 0.25, y: 0.7),
                endPoint: UnitPoint(x: 0.9 - auroraPhase * 0.2, y: 0.95),
                width: width,
                height: height,
                opacity: auroraIntensity * 0.4,
                blur: 120
            )
        }
    }

    private func auroraStreamer(
        colors: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        width: CGFloat,
        height: CGFloat,
        opacity: Double,
        blur: CGFloat
    ) -> some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .frame(width: width * 1.5, height: height * 0.6)
            .blur(radius: blur)
            .opacity(opacity)
            .offset(
                x: (startPoint.x - 0.5) * width * 0.5,
                y: (startPoint.y - 0.3) * height * 0.5
            )
    }

    // MARK: - Ambient Glow

    private var ambientGlow: some View {
        RadialGradient(
            colors: [
                glowColor.opacity(auroraIntensity * 0.5),
                glowColor.opacity(auroraIntensity * 0.2),
                Color.clear
            ],
            center: glowPosition,
            startRadius: 50,
            endRadius: 400
        )
    }

    // MARK: - Star Field

    private func starField(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            for star in stars {
                let twinkle = sin(twinklePhase + star.twinkleDelay * .pi) * 0.5 + 0.5
                let opacity = star.baseOpacity * (0.4 + twinkle * 0.6)

                let rect = CGRect(
                    x: star.position.x - star.size / 2,
                    y: star.position.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )

                let color = star.isBright
                    ? Aurora.Colors.starBright.opacity(opacity)
                    : Aurora.Colors.starDim.opacity(opacity)

                context.fill(SwiftUI.Circle().path(in: rect), with: .color(color))
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
        stars = AuroraStarParticle.generateField(count: starCount, in: size, brightPercentage: 0.15)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Aurora flow animation
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: true)) {
            auroraPhase = 1
        }

        // Star twinkle animation
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            twinklePhase = .pi * 2
        }
    }
}

// MARK: - Aurora Background Variants

extension AuroraBackground {

    /// Auth screen background with prominent aurora
    static var auth: AuroraBackground {
        AuroraBackground(
            showStars: true,
            starCount: 40,
            auroraIntensity: 0.40,
            glowColor: Aurora.Colors.violet,
            glowPosition: .center
        )
    }

    /// Onboarding welcome screen (dramatic aurora)
    static var onboardingWelcome: AuroraBackground {
        AuroraBackground(
            showStars: true,
            starCount: 35,
            auroraIntensity: 0.45,
            glowColor: Aurora.Colors.purple,
            glowPosition: .center
        )
    }

    /// Onboarding steps (subtler aurora)
    static var onboardingStep: AuroraBackground {
        AuroraBackground(
            showStars: true,
            starCount: 25,
            auroraIntensity: 0.30,
            glowColor: Aurora.Colors.electric,
            glowPosition: UnitPoint(x: 0.5, y: 0.3)
        )
    }

    /// Onboarding completion (celebration aurora)
    static var onboardingComplete: AuroraBackground {
        AuroraBackground(
            showStars: true,
            starCount: 50,
            auroraIntensity: 0.50,
            glowColor: Aurora.Colors.cyan,
            glowPosition: .center
        )
    }

    /// Minimal aurora for sheets/overlays
    static var minimal: AuroraBackground {
        AuroraBackground(
            showStars: false,
            starCount: 0,
            auroraIntensity: 0.20,
            glowColor: Aurora.Colors.violet,
            glowPosition: .center
        )
    }
}

// MARK: - View Extension

extension View {
    /// Apply aurora background
    func auroraBackground(
        showStars: Bool = true,
        starCount: Int = 30,
        auroraIntensity: Double = 0.35,
        glowColor: Color = Aurora.Colors.violet,
        glowPosition: UnitPoint = .center
    ) -> some View {
        self.background {
            AuroraBackground(
                showStars: showStars,
                starCount: starCount,
                auroraIntensity: auroraIntensity,
                glowColor: glowColor,
                glowPosition: glowPosition
            )
        }
    }
}

// MARK: - Preview

#Preview("Aurora Background - Auth") {
    VStack {
        Spacer()

        Text("MyTasksAI")
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundStyle(.white)

        Text("AI-Powered Productivity")
            .font(.subheadline)
            .foregroundStyle(Aurora.Colors.textSecondary)

        Spacer()
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
        AuroraBackground.auth
    }
}

#Preview("Aurora Background - Variants") {
    TabView {
        AuroraBackground.auth
            .overlay {
                Text("Auth").foregroundStyle(.white)
            }
            .tabItem { Text("Auth") }

        AuroraBackground.onboardingWelcome
            .overlay {
                Text("Welcome").foregroundStyle(.white)
            }
            .tabItem { Text("Welcome") }

        AuroraBackground.onboardingStep
            .overlay {
                Text("Step").foregroundStyle(.white)
            }
            .tabItem { Text("Step") }

        AuroraBackground.onboardingComplete
            .overlay {
                Text("Complete").foregroundStyle(.white)
            }
            .tabItem { Text("Complete") }
    }
}
