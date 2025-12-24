//
//  LivingUniverseCore.swift
//  Veloce
//
//  Living Universe - Your Productivity Creates Reality
//  A cosmic visualization where every task becomes a star,
//  every goal becomes a planet, and your progress builds a universe.
//
//  Award-Winning Tier Visual Design
//

import SwiftUI
import SwiftData

// MARK: - Universe Evolution Tier

enum UniverseTier: Int, CaseIterable {
    case void = 0        // Level 1-2: Empty space, single dim star
    case protoSystem = 1 // Level 3-5: Star brightens, dust clouds form
    case youngSystem = 2 // Level 6-10: 1-2 planets, sparse star field
    case matureSystem = 3 // Level 11-20: Full planetary system, nebula patches
    case stellarEmpire = 4 // Level 21-35: Multiple star systems, dense stars
    case galaxyCore = 5   // Level 36-50: Spiral arms form, aurora effects
    case universal = 6    // Level 50+: Multiple galaxies, cosmic web

    static func forLevel(_ level: Int) -> UniverseTier {
        switch level {
        case 1...2: return .void
        case 3...5: return .protoSystem
        case 6...10: return .youngSystem
        case 11...20: return .matureSystem
        case 21...35: return .stellarEmpire
        case 36...50: return .galaxyCore
        default: return .universal
        }
    }

    var starIntensity: Double {
        switch self {
        case .void: return 0.4
        case .protoSystem: return 0.6
        case .youngSystem: return 0.75
        case .matureSystem: return 0.85
        case .stellarEmpire: return 0.95
        case .galaxyCore: return 1.0
        case .universal: return 1.2
        }
    }

    var backgroundStarCount: Int {
        switch self {
        case .void: return 20
        case .protoSystem: return 50
        case .youngSystem: return 100
        case .matureSystem: return 180
        case .stellarEmpire: return 300
        case .galaxyCore: return 450
        case .universal: return 600
        }
    }

    var nebulaOpacity: Double {
        switch self {
        case .void, .protoSystem: return 0.0
        case .youngSystem: return 0.15
        case .matureSystem: return 0.3
        case .stellarEmpire: return 0.45
        case .galaxyCore: return 0.6
        case .universal: return 0.75
        }
    }

    var showSpiralArms: Bool {
        self.rawValue >= UniverseTier.galaxyCore.rawValue
    }

    var showCosmicWeb: Bool {
        self == .universal
    }
}

// MARK: - Living Universe Core

struct LivingUniverseCore: View {
    // MARK: Data Inputs
    let level: Int
    let totalPoints: Int
    let levelProgress: Double
    let streak: Int
    let goals: [Goal]
    let completedTaskCount: Int
    let unlockedAchievements: Set<AchievementType>

    // MARK: Animation States
    @State private var centralStarPulse: Double = 0
    @State private var coronaRotation: Double = 0
    @State private var coronaPulse: Double = 0
    @State private var plasmaFlarePhase: Double = 0
    @State private var gravitationalLensPhase: Double = 0
    @State private var particleOrbitPhase: Double = 0
    @State private var nebulaFlowPhase: Double = 0
    @State private var starFieldTwinkle: Double = 0
    @State private var cosmicWebPulse: Double = 0
    @State private var displayedPoints: Int = 0
    @State private var hasAppeared: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Computed Properties
    private var tier: UniverseTier { UniverseTier.forLevel(level) }
    private var activeGoals: [Goal] { goals.filter { !$0.isCompleted }.prefix(6).map { $0 } }

    // MARK: Color Palette
    private let auroraColors: [Color] = [
        Color(red: 0.67, green: 0.33, blue: 0.97), // Vivid Purple
        Color(red: 0.55, green: 0.36, blue: 0.96), // Purple
        Color(red: 0.39, green: 0.40, blue: 0.95), // Indigo
        Color(red: 0.23, green: 0.51, blue: 0.96), // Blue
        Color(red: 0.05, green: 0.65, blue: 0.91), // Sky
        Color(red: 0.02, green: 0.71, blue: 0.83), // Cyan
        Color(red: 0.08, green: 0.72, blue: 0.65), // Teal
        Color(red: 0.06, green: 0.73, blue: 0.51), // Emerald
    ]

    private let voidBlack = Color(red: 0.01, green: 0.01, blue: 0.02)

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2

            ZStack {
                // Layer 0: Deep Void Background
                voidBlack

                // Layer 1: Cosmic Web (Universal tier only)
                if tier.showCosmicWeb && !reduceMotion {
                    cosmicWebLayer(size: size, center: CGPoint(x: centerX, y: centerY))
                }

                // Layer 2: Spiral Arms (Galaxy Core+)
                if tier.showSpiralArms && !reduceMotion {
                    spiralArmsLayer(size: size, center: CGPoint(x: centerX, y: centerY))
                }

                // Layer 3: Background Star Field
                starFieldLayer(size: size, center: CGPoint(x: centerX, y: centerY))

                // Layer 4: Achievement Nebulae
                if tier.nebulaOpacity > 0 {
                    nebulaLayer(size: size, center: CGPoint(x: centerX, y: centerY))
                }

                // Layer 5: Streak Comet Trail
                if streak > 0 {
                    cometTrailLayer(size: size, center: CGPoint(x: centerX, y: centerY))
                }

                // Layer 6: Goal Planets
                planetarySystemLayer(size: size, center: CGPoint(x: centerX, y: centerY))

                // Layer 7: Gravitational Lensing Effect
                if tier.rawValue >= UniverseTier.matureSystem.rawValue {
                    gravitationalLensLayer(size: size, center: CGPoint(x: centerX, y: centerY))
                }

                // Layer 8: Central Star (XP Core)
                centralStarLayer(size: size, center: CGPoint(x: centerX, y: centerY))

                // Layer 9: XP Display Overlay
                xpDisplayLayer(size: size, center: CGPoint(x: centerX, y: centerY))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            startAnimations()
            animatePointsCounter()
        }
        .onChange(of: totalPoints) { _, newValue in
            animatePointsCounter()
        }
    }

    // MARK: - Layer 1: Cosmic Web (Universal Tier)

    @ViewBuilder
    private func cosmicWebLayer(size: CGFloat, center: CGPoint) -> some View {
        Canvas { context, canvasSize in
            let webNodes = 12
            let nodePositions = (0..<webNodes).map { i -> CGPoint in
                let baseAngle = Double(i) / Double(webNodes) * 2.0 * Double.pi
                let angle = baseAngle + cosmicWebPulse * 0.1
                let sinOffset = Darwin.sin(Double(i) * 0.7 + cosmicWebPulse) * 0.2
                let radius = size * 0.4 * (0.8 + sinOffset)
                let x = center.x + Darwin.cos(angle) * radius
                let y = center.y + Darwin.sin(angle) * radius
                return CGPoint(x: x, y: y)
            }

            // Draw web connections
            for i in 0..<webNodes {
                for j in (i+1)..<webNodes {
                    let distance = hypot(
                        nodePositions[i].x - nodePositions[j].x,
                        nodePositions[i].y - nodePositions[j].y
                    )

                    let threshold = size * 0.35
                    if distance < threshold {
                        let normalizedDistance = Double(distance / threshold)
                        let opacity = (1.0 - normalizedDistance) * 0.15 * (0.7 + cosmicWebPulse * 0.3)

                        var path = Path()
                        path.move(to: nodePositions[i])
                        path.addLine(to: nodePositions[j])

                        context.stroke(
                            path,
                            with: .color(auroraColors[2].opacity(opacity)),
                            lineWidth: 1
                        )
                    }
                }
            }

            // Draw nodes
            for (i, pos) in nodePositions.enumerated() {
                let sinValue = Darwin.sin(Double(i) + cosmicWebPulse * 2) * 0.2
                let nodeSize = size * 0.01 * (0.8 + sinValue)
                let nodeRect = CGRect(
                    x: pos.x - nodeSize/2,
                    y: pos.y - nodeSize/2,
                    width: nodeSize,
                    height: nodeSize
                )
                context.fill(Ellipse().path(in: nodeRect), with: .color(auroraColors[4].opacity(0.4)))
            }
        }
        .blur(radius: 2)
    }

    // MARK: - Layer 2: Spiral Arms (Galaxy Core+)

    @ViewBuilder
    private func spiralArmsLayer(size: CGFloat, center: CGPoint) -> some View {
        Canvas { context, canvasSize in
            let armCount = 2
            let pointsPerArm = 60

            for arm in 0..<armCount {
                let armOffset = Double(arm) * .pi

                for i in 0..<pointsPerArm {
                    let t = Double(i) / Double(pointsPerArm)
                    let spiralAngle = t * 3 * .pi + armOffset + coronaRotation * 0.05
                    let radius = t * size * 0.45

                    let x = center.x + cos(spiralAngle) * radius
                    let y = center.y + sin(spiralAngle) * radius

                    let starSize = size * 0.003 * (1 + t * 0.5)
                    let opacity = t * 0.4 * (0.7 + sin(starFieldTwinkle * 2 + Double(i) * 0.3) * 0.3)

                    let starRect = CGRect(
                        x: x - starSize/2,
                        y: y - starSize/2,
                        width: starSize,
                        height: starSize
                    )

                    let color = auroraColors[(i + arm * 3) % auroraColors.count]
                    context.fill(Ellipse().path(in: starRect), with: .color(color.opacity(opacity)))
                }
            }
        }
        .blur(radius: 1)
    }

    // MARK: - Layer 3: Star Field (Completed Tasks)

    @ViewBuilder
    private func starFieldLayer(size: CGFloat, center: CGPoint) -> some View {
        Canvas { context, canvasSize in
            // Seeded random for consistent star positions
            srand48(42)

            let starCount = min(tier.backgroundStarCount + completedTaskCount / 5, 800)

            for i in 0..<starCount {
                // Distribute stars across the canvas
                let angle = drand48() * 2 * .pi
                let radiusFactor = sqrt(drand48()) // Square root for even distribution
                let radius = radiusFactor * size * 0.55

                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius

                // Vary star sizes
                let baseSizeCategory = drand48()
                let starSize: CGFloat
                if baseSizeCategory < 0.7 {
                    starSize = size * CGFloat(0.001 + drand48() * 0.002) // Dim distant stars
                } else if baseSizeCategory < 0.9 {
                    starSize = size * CGFloat(0.002 + drand48() * 0.003) // Medium stars
                } else {
                    starSize = size * CGFloat(0.003 + drand48() * 0.004) // Bright stars
                }

                // Twinkle effect
                let twinklePhase = sin(starFieldTwinkle * (1 + drand48() * 2) + drand48() * 10)
                let baseOpacity = 0.3 + drand48() * 0.5
                let opacity = baseOpacity * (0.7 + twinklePhase * 0.3) * tier.starIntensity

                let starRect = CGRect(
                    x: x - starSize/2,
                    y: y - starSize/2,
                    width: starSize,
                    height: starSize
                )

                // Star color based on "temperature"
                let colorIndex = Int(drand48() * 3)
                let starColor: Color
                switch colorIndex {
                case 0: starColor = .white
                case 1: starColor = Color(red: 0.9, green: 0.95, blue: 1.0) // Blue-white
                default: starColor = Color(red: 1.0, green: 0.95, blue: 0.85) // Yellow-white
                }

                context.fill(Ellipse().path(in: starRect), with: .color(starColor.opacity(opacity)))

                // Add subtle glow for brighter stars
                if baseSizeCategory > 0.85 {
                    let glowRect = CGRect(
                        x: x - starSize,
                        y: y - starSize,
                        width: starSize * 2,
                        height: starSize * 2
                    )
                    context.fill(
                        Ellipse().path(in: glowRect),
                        with: .color(starColor.opacity(opacity * 0.2))
                    )
                }
            }
        }
    }

    // MARK: - Layer 4: Achievement Nebulae

    @ViewBuilder
    private func nebulaLayer(size: CGFloat, center: CGPoint) -> some View {
        let achievementCount = unlockedAchievements.count
        let nebulaCount = min(achievementCount / 3 + 1, 5)

        ForEach(0..<nebulaCount, id: \.self) { i in
            let angle = Double(i) / Double(nebulaCount) * 2 * .pi + nebulaFlowPhase * 0.1
            let radius = size * (0.25 + Double(i % 3) * 0.08)
            let offsetX = cos(angle) * radius
            let offsetY = sin(angle) * radius

            // Nebula cloud
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            auroraColors[i % auroraColors.count].opacity(tier.nebulaOpacity * 0.6),
                            auroraColors[(i + 2) % auroraColors.count].opacity(tier.nebulaOpacity * 0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.12
                    )
                )
                .frame(width: size * 0.25, height: size * 0.18)
                .rotationEffect(.degrees(Double(i * 45) + nebulaFlowPhase * 5))
                .scaleEffect(1 + sin(nebulaFlowPhase + Double(i)) * 0.1)
                .offset(x: offsetX, y: offsetY)
                .blur(radius: size * 0.03)
        }
    }

    // MARK: - Layer 5: Streak Comet Trail

    @ViewBuilder
    private func cometTrailLayer(size: CGFloat, center: CGPoint) -> some View {
        let trailLength = min(Double(streak) / 100, 1.0)
        let trailOpacity = 0.3 + trailLength * 0.4

        Canvas { context, canvasSize in
            let startAngle = particleOrbitPhase * 0.3
            let arcLength = (0.5 + trailLength * 1.5) * .pi
            let radius = size * 0.38

            // Draw comet trail as gradient arc
            for i in 0..<30 {
                let t = Double(i) / 30.0
                let angle = startAngle - t * arcLength
                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius

                let particleOpacity = (1 - t) * trailOpacity * (0.8 + sin(particleOrbitPhase * 3 + Double(i) * 0.5) * 0.2)
                let particleSize = size * 0.008 * (1 - t * 0.5)

                let particleRect = CGRect(
                    x: x - particleSize/2,
                    y: y - particleSize/2,
                    width: particleSize,
                    height: particleSize
                )

                // Gradient from gold to orange to red
                let color: Color
                if t < 0.3 {
                    color = Color(red: 1.0, green: 0.85, blue: 0.35) // Gold
                } else if t < 0.6 {
                    color = Color(red: 1.0, green: 0.55, blue: 0.25) // Orange
                } else {
                    color = Color(red: 0.95, green: 0.35, blue: 0.25) // Red
                }

                context.fill(Ellipse().path(in: particleRect), with: .color(color.opacity(particleOpacity)))
            }

            // Comet head
            let headAngle = startAngle
            let headX = center.x + cos(headAngle) * radius
            let headY = center.y + sin(headAngle) * radius
            let headSize = size * 0.025

            let headRect = CGRect(
                x: headX - headSize/2,
                y: headY - headSize/2,
                width: headSize,
                height: headSize
            )

            // Comet glow
            let glowRect = CGRect(
                x: headX - headSize,
                y: headY - headSize,
                width: headSize * 2,
                height: headSize * 2
            )

            context.fill(Ellipse().path(in: glowRect), with: .color(Color.orange.opacity(0.4)))
            context.fill(Ellipse().path(in: headRect), with: .color(Color.white.opacity(0.9)))
        }
        .blur(radius: 2)
    }

    // MARK: - Layer 6: Planetary System (Goals)

    @ViewBuilder
    private func planetarySystemLayer(size: CGFloat, center: CGPoint) -> some View {
        ForEach(Array(activeGoals.enumerated()), id: \.element.id) { index, goal in
            CosmicPlanet(
                goal: goal,
                orbitIndex: index,
                totalPlanets: activeGoals.count,
                universeSize: size,
                orbitPhase: particleOrbitPhase
            )
            .position(x: center.x, y: center.y)
        }
    }

    // MARK: - Layer 7: Gravitational Lensing

    @ViewBuilder
    private func gravitationalLensLayer(size: CGFloat, center: CGPoint) -> some View {
        // Subtle distortion ring around the star
        SwiftUI.Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.clear,
                        Color.white.opacity(0.05),
                        Color.clear,
                        Color.white.opacity(0.08)
                    ],
                    center: .center,
                    angle: .degrees(gravitationalLensPhase * 20)
                ),
                lineWidth: size * 0.003
            )
            .frame(width: size * 0.25, height: size * 0.25)
            .scaleEffect(1 + gravitationalLensPhase * 0.02)
            .position(x: center.x, y: center.y)
            .blur(radius: 1)
    }

    // MARK: - Layer 8: Central Star

    @ViewBuilder
    private func centralStarLayer(size: CGFloat, center: CGPoint) -> some View {
        let intensity = tier.starIntensity
        let starSize = size * 0.18

        ZStack {
            // Layer 8a: Outer Corona (rotating aurora)
            ForEach(0..<3, id: \.self) { ring in
                SwiftUI.Circle()
                    .fill(
                        AngularGradient(
                            colors: rotatedColors(by: ring * 2),
                            center: .center,
                            angle: .degrees(coronaRotation * (ring % 2 == 0 ? 1 : -1))
                        )
                    )
                    .frame(width: starSize * (2.0 - Double(ring) * 0.25), height: starSize * (2.0 - Double(ring) * 0.25))
                    .blur(radius: starSize * (0.3 - Double(ring) * 0.05))
                    .opacity((0.25 - Double(ring) * 0.06) * intensity * (0.8 + coronaPulse * 0.2))
            }

            // Layer 8b: Inner Glow (radial)
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            auroraColors[0].opacity(0.7 * intensity),
                            auroraColors[2].opacity(0.4 * intensity),
                            auroraColors[4].opacity(0.2 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: starSize * 0.8
                    )
                )
                .frame(width: starSize * 1.6, height: starSize * 1.6)
                .scaleEffect(1 + centralStarPulse * 0.08)

            // Layer 8c: Plasma Surface
            SwiftUI.Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            auroraColors[4].opacity(0.7),
                            Color.white.opacity(0.85),
                            auroraColors[0].opacity(0.6),
                            Color.white.opacity(0.9)
                        ],
                        center: .center,
                        angle: .degrees(coronaRotation * 2)
                    )
                )
                .frame(width: starSize * 0.6, height: starSize * 0.6)
                .blur(radius: starSize * 0.02)

            // Layer 8d: Hot Core
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.95),
                            Color(red: 0.9, green: 0.95, blue: 1.0).opacity(0.8),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: starSize * 0.25
                    )
                )
                .frame(width: starSize * 0.5, height: starSize * 0.5)
                .scaleEffect(1 + centralStarPulse * 0.1)

            // Layer 8e: Plasma Flares (for higher tiers)
            if tier.rawValue >= UniverseTier.matureSystem.rawValue {
                ForEach(0..<4, id: \.self) { flare in
                    plasmaFlare(
                        size: starSize,
                        angle: Double(flare) * 90 + plasmaFlarePhase * 30,
                        intensity: intensity
                    )
                }
            }

            // Layer 8f: Level Progress Ring
            SwiftUI.Circle()
                .trim(from: 0, to: levelProgress)
                .stroke(
                    LinearGradient(
                        colors: [auroraColors[0], auroraColors[4]],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.006, lineCap: .round)
                )
                .frame(width: starSize * 0.75, height: starSize * 0.75)
                .rotationEffect(.degrees(-90))
                .shadow(color: auroraColors[0].opacity(0.5), radius: 4)
        }
        .position(x: center.x, y: center.y)
    }

    @ViewBuilder
    private func plasmaFlare(size: CGFloat, angle: Double, intensity: Double) -> some View {
        let flareLength = size * 0.35 * (0.7 + sin(plasmaFlarePhase * 2) * 0.3)

        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.6 * intensity),
                        auroraColors[0].opacity(0.3 * intensity),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: size * 0.06, height: flareLength)
            .offset(y: -size * 0.3 - flareLength / 2)
            .rotationEffect(.degrees(angle))
            .blur(radius: 3)
    }

    private func rotatedColors(by offset: Int) -> [Color] {
        var colors = auroraColors
        for _ in 0..<offset {
            let first = colors.removeFirst()
            colors.append(first)
        }
        return colors + [colors[0]]
    }

    // MARK: - Layer 9: XP Display

    @ViewBuilder
    private func xpDisplayLayer(size: CGFloat, center: CGPoint) -> some View {
        VStack(spacing: size * 0.015) {
            // XP Counter
            Text("\(displayedPoints)")
                .font(.system(size: size * 0.08, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(displayedPoints)))
                .shadow(color: auroraColors[0].opacity(0.5), radius: 10)

            Text("XP")
                .font(.system(size: size * 0.025, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.6))
                .tracking(4)

            // Level Badge
            levelBadge(size: size)
        }
        .position(x: center.x, y: center.y)
    }

    @ViewBuilder
    private func levelBadge(size: CGFloat) -> some View {
        ZStack {
            // Badge background
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    auroraColors[0].opacity(0.5),
                                    auroraColors[4].opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            HStack(spacing: size * 0.01) {
                Image(systemName: "star.fill")
                    .font(.system(size: size * 0.022))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [auroraColors[0], auroraColors[4]],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("LEVEL \(level)")
                    .font(.system(size: size * 0.022, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, size * 0.02)
            .padding(.vertical, size * 0.008)
        }
        .fixedSize()
    }

    // MARK: - Animations

    private func startAnimations() {
        // Central star breathing
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            centralStarPulse = 1
        }

        // Corona rotation
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            coronaRotation = 360
        }

        // Corona pulse
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            coronaPulse = 1
        }

        // Plasma flares
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            plasmaFlarePhase = 1
        }

        // Gravitational lens
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            gravitationalLensPhase = 1
        }

        // Particle orbits (for planets and comets)
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            particleOrbitPhase = 2 * .pi
        }

        // Nebula flow
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            nebulaFlowPhase = 1
        }

        // Star field twinkle
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            starFieldTwinkle = 2 * .pi
        }

        // Cosmic web pulse
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            cosmicWebPulse = 1
        }
    }

    private func animatePointsCounter() {
        let steps = 25
        let increment = (totalPoints - displayedPoints) / steps

        guard increment != 0 else {
            displayedPoints = totalPoints
            return
        }

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                if i == steps - 1 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        displayedPoints = totalPoints
                    }
                } else {
                    displayedPoints += increment
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black

        LivingUniverseCore(
            level: 25,
            totalPoints: 4580,
            levelProgress: 0.67,
            streak: 14,
            goals: [],
            completedTaskCount: 156,
            unlockedAchievements: [.firstTask, .tasksBronze, .streakBronze, .streakSilver]
        )
        .frame(height: 400)
    }
}
