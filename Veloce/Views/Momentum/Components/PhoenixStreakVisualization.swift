//
//  PhoenixStreakVisualization.swift
//  Veloce
//
//  Phoenix Streak - A Mythical Creature That Evolves With Your Consistency
//  From humble ember to cosmic legend, your streak transforms
//  into an ever more majestic phoenix.
//

import SwiftUI

// MARK: - Phoenix Tier

enum PhoenixTier: Int, CaseIterable {
    case none = 0       // 0 days: Gray ember, dormant
    case spark = 1      // 1-2 days: Orange ember, small flickers
    case bronze = 2     // 3-6 days: Small phoenix silhouette
    case silver = 3     // 7-13 days: Rising phoenix, feathers visible
    case gold = 4       // 14-29 days: Blazing phoenix, flame wings
    case diamond = 5    // 30-99 days: Majestic iridescent phoenix
    case legendary = 6  // 100+ days: Cosmic reality-bending phoenix

    static func forStreak(_ days: Int) -> PhoenixTier {
        switch days {
        case 0: return .none
        case 1...2: return .spark
        case 3...6: return .bronze
        case 7...13: return .silver
        case 14...29: return .gold
        case 30...99: return .diamond
        default: return .legendary
        }
    }

    var tierName: String {
        switch self {
        case .none: return "Dormant"
        case .spark: return "Spark"
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .diamond: return "Diamond"
        case .legendary: return "Legendary"
        }
    }

    var primaryColor: Color {
        switch self {
        case .none: return Color(red: 0.4, green: 0.4, blue: 0.45)
        case .spark: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .diamond: return Color(red: 0.58, green: 0.25, blue: 0.98)
        case .legendary: return Color(red: 0.4, green: 0.8, blue: 1.0)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .none: return Color(red: 0.3, green: 0.3, blue: 0.35)
        case .spark: return Color(red: 0.9, green: 0.4, blue: 0.1)
        case .bronze: return Color(red: 0.6, green: 0.35, blue: 0.1)
        case .silver: return Color(red: 0.55, green: 0.55, blue: 0.6)
        case .gold: return Color(red: 0.9, green: 0.55, blue: 0.0)
        case .diamond: return Color(red: 0.35, green: 0.45, blue: 0.98)
        case .legendary: return Color(red: 0.98, green: 0.45, blue: 0.65)
        }
    }

    var glowIntensity: Double {
        switch self {
        case .none: return 0.1
        case .spark: return 0.3
        case .bronze: return 0.45
        case .silver: return 0.6
        case .gold: return 0.75
        case .diamond: return 0.9
        case .legendary: return 1.0
        }
    }

    var particleCount: Int {
        switch self {
        case .none: return 0
        case .spark: return 3
        case .bronze: return 8
        case .silver: return 15
        case .gold: return 25
        case .diamond: return 40
        case .legendary: return 60
        }
    }
}

// MARK: - Phoenix Streak Visualization

struct PhoenixStreakVisualization: View {
    let streak: Int
    var size: CGFloat = 120

    // Animation States
    @State private var flamePhase: Double = 0
    @State private var wingBeat: Double = 0
    @State private var featherShimmer: Double = 0
    @State private var emberRise: Double = 0
    @State private var coreGlow: Double = 0
    @State private var cosmicWarp: Double = 0
    @State private var iriscentShift: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tier: PhoenixTier { PhoenixTier.forStreak(streak) }

    var body: some View {
        ZStack {
            // Background glow aura
            phoenixAura

            // Particle system (embers/sparkles)
            if tier.particleCount > 0 && !reduceMotion {
                emberParticles
            }

            // Phoenix body based on tier
            switch tier {
            case .none:
                dormantEmber
            case .spark:
                sparkEmber
            case .bronze:
                bronzePhoenix
            case .silver:
                silverPhoenix
            case .gold:
                goldPhoenix
            case .diamond:
                diamondPhoenix
            case .legendary:
                legendaryPhoenix
            }

            // Streak number display
            streakDisplay
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Phoenix Aura

    @ViewBuilder
    private var phoenixAura: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        tier.primaryColor.opacity(tier.glowIntensity * 0.4 * (0.8 + coreGlow * 0.4)),
                        tier.secondaryColor.opacity(tier.glowIntensity * 0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.1,
                    endRadius: size * 0.5
                )
            )
            .scaleEffect(1 + coreGlow * 0.1)
            .blur(radius: size * 0.1)
    }

    // MARK: - Ember Particles

    @ViewBuilder
    private var emberParticles: some View {
        Canvas { context, canvasSize in
            srand48(Int(streak))

            for i in 0..<tier.particleCount {
                let baseAngle = drand48() * 2 * .pi
                let radiusOffset = drand48()
                let riseOffset = (emberRise + drand48()) .truncatingRemainder(dividingBy: 1.0)

                // Particles rise and drift
                let radius = size * 0.15 + radiusOffset * size * 0.25
                let angle = baseAngle + sin(emberRise * 2 + Double(i)) * 0.3
                let riseY = riseOffset * size * 0.4

                let x = canvasSize.width / 2 + cos(angle) * radius * (1 - riseOffset * 0.5)
                let y = canvasSize.height / 2 - riseY

                let particleSize = size * 0.015 * (1 - riseOffset * 0.5)
                let opacity = (1 - riseOffset) * tier.glowIntensity

                let rect = CGRect(
                    x: x - particleSize/2,
                    y: y - particleSize/2,
                    width: particleSize,
                    height: particleSize
                )

                // Color varies by tier
                let color: Color
                if tier == .legendary {
                    // Iridescent particles
                    let hue = (iriscentShift + Double(i) * 0.1).truncatingRemainder(dividingBy: 1.0)
                    color = Color(hue: hue, saturation: 0.8, brightness: 1.0)
                } else {
                    color = i % 2 == 0 ? tier.primaryColor : tier.secondaryColor
                }

                context.fill(Ellipse().path(in: rect), with: .color(color.opacity(opacity)))

                // Glow for brighter particles
                if drand48() > 0.7 {
                    let glowRect = CGRect(
                        x: x - particleSize,
                        y: y - particleSize,
                        width: particleSize * 2,
                        height: particleSize * 2
                    )
                    context.fill(Ellipse().path(in: glowRect), with: .color(color.opacity(opacity * 0.3)))
                }
            }
        }
    }

    // MARK: - Tier 0: Dormant Ember

    @ViewBuilder
    private var dormantEmber: some View {
        ZStack {
            // Dim coal
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            tier.primaryColor.opacity(0.3),
                            tier.secondaryColor.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.15
                    )
                )
                .frame(width: size * 0.3, height: size * 0.3)
                .scaleEffect(1 + coreGlow * 0.05)
        }
    }

    // MARK: - Tier 1: Spark Ember

    @ViewBuilder
    private var sparkEmber: some View {
        ZStack {
            // Flickering ember
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            tier.primaryColor,
                            tier.secondaryColor.opacity(0.5),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.4),
                        startRadius: 0,
                        endRadius: size * 0.12
                    )
                )
                .frame(width: size * 0.2, height: size * 0.25)
                .scaleEffect(x: 1 + sin(flamePhase * 5) * 0.1, y: 1 + cos(flamePhase * 4) * 0.15)
                .offset(x: sin(flamePhase * 3) * size * 0.02)

            // Small flame tip
            flameShape(width: size * 0.08, height: size * 0.15)
                .fill(
                    LinearGradient(
                        colors: [tier.primaryColor, tier.secondaryColor.opacity(0.3)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .offset(y: -size * 0.1)
                .scaleEffect(y: 1 + sin(flamePhase * 6) * 0.2)
                .blur(radius: 1)
        }
    }

    // MARK: - Tier 2: Bronze Phoenix

    @ViewBuilder
    private var bronzePhoenix: some View {
        ZStack {
            // Body core
            phoenixBodyCore(scale: 0.7)

            // Small wing hints
            phoenixWing(side: .left, scale: 0.5)
            phoenixWing(side: .right, scale: 0.5)

            // Tail plume
            phoenixTail(scale: 0.5)
        }
    }

    // MARK: - Tier 3: Silver Phoenix

    @ViewBuilder
    private var silverPhoenix: some View {
        ZStack {
            // Rising body
            phoenixBodyCore(scale: 0.85)

            // Visible wings
            phoenixWing(side: .left, scale: 0.7)
            phoenixWing(side: .right, scale: 0.7)

            // Feather details
            phoenixFeathers(count: 5, scale: 0.6)

            // Flowing tail
            phoenixTail(scale: 0.7)
        }
    }

    // MARK: - Tier 4: Gold Phoenix

    @ViewBuilder
    private var goldPhoenix: some View {
        ZStack {
            // Flame wing trails
            flameWingTrail(side: .left)
            flameWingTrail(side: .right)

            // Blazing body
            phoenixBodyCore(scale: 1.0)

            // Full flame wings
            phoenixWing(side: .left, scale: 1.0)
            phoenixWing(side: .right, scale: 1.0)

            // Rich feathers
            phoenixFeathers(count: 8, scale: 0.8)

            // Majestic tail
            phoenixTail(scale: 1.0)

            // Crown flame
            crownFlame
        }
    }

    // MARK: - Tier 5: Diamond Phoenix

    @ViewBuilder
    private var diamondPhoenix: some View {
        ZStack {
            // Iridescent wing aura
            iriscentWingAura

            // Diamond-encrusted body
            phoenixBodyCore(scale: 1.1)
                .overlay(
                    diamondSparkles
                )

            // Crystalline wings
            phoenixWing(side: .left, scale: 1.2)
            phoenixWing(side: .right, scale: 1.2)

            // Prismatic feathers
            phoenixFeathers(count: 12, scale: 1.0)

            // Flowing iridescent tail
            phoenixTail(scale: 1.2)

            // Halo crown
            diamondHalo
        }
    }

    // MARK: - Tier 6: Legendary Phoenix

    @ViewBuilder
    private var legendaryPhoenix: some View {
        ZStack {
            // Reality distortion field
            realityWarpField

            // Cosmic aurora
            cosmicAurora

            // Transcendent body
            phoenixBodyCore(scale: 1.3)
                .overlay(cosmicOverlay)

            // Reality-bending wings
            phoenixWing(side: .left, scale: 1.4)
            phoenixWing(side: .right, scale: 1.4)

            // Ethereal feathers
            phoenixFeathers(count: 16, scale: 1.2)

            // Cosmic tail
            phoenixTail(scale: 1.4)

            // Stellar crown
            stellarCrown
        }
    }

    // MARK: - Component Builders

    @ViewBuilder
    private func phoenixBodyCore(scale: CGFloat) -> some View {
        ZStack {
            // Core glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            tier.primaryColor.opacity(0.8),
                            tier.secondaryColor.opacity(0.4),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.4),
                        startRadius: 0,
                        endRadius: size * 0.15 * scale
                    )
                )
                .frame(width: size * 0.22 * scale, height: size * 0.28 * scale)
                .scaleEffect(1 + coreGlow * 0.1)

            // Head
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            tier.primaryColor.opacity(0.7)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: size * 0.05 * scale
                    )
                )
                .frame(width: size * 0.1 * scale, height: size * 0.1 * scale)
                .offset(y: -size * 0.12 * scale)
        }
    }

    @ViewBuilder
    private func phoenixWing(side: WingSide, scale: CGFloat) -> some View {
        let xOffset = side == .left ? -size * 0.15 * scale : size * 0.15 * scale
        let rotation = side == .left ? -15.0 - wingBeat * 15 : 15.0 + wingBeat * 15

        wingShape(scale: scale)
            .fill(
                LinearGradient(
                    colors: [
                        tier.primaryColor.opacity(0.9),
                        tier.secondaryColor.opacity(0.6),
                        tier.primaryColor.opacity(0.3)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: size * 0.25 * scale, height: size * 0.35 * scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: -size * 0.02 * scale)
            .scaleEffect(x: side == .left ? -1 : 1, y: 1)
            .blur(radius: 1)
    }

    private func wingShape(scale: CGFloat) -> some Shape {
        // Flame-like wing shape
        return FlameWingShape()
    }

    @ViewBuilder
    private func phoenixFeathers(count: Int, scale: CGFloat) -> some View {
        ForEach(0..<count, id: \.self) { i in
            let angle = Double(i) / Double(count) * 180 - 90
            let delay = Double(i) * 0.05

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            tier.primaryColor.opacity(0.7 + featherShimmer * 0.3),
                            tier.secondaryColor.opacity(0.3)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: size * 0.015 * scale, height: size * 0.08 * scale)
                .offset(y: -size * 0.2 * scale)
                .rotationEffect(.degrees(angle))
                .opacity(0.6 + sin(featherShimmer * 3 + delay * 10) * 0.4)
        }
    }

    @ViewBuilder
    private func phoenixTail(scale: CGFloat) -> some View {
        ForEach(0..<5, id: \.self) { i in
            let spread = Double(i - 2) * 8

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            tier.primaryColor.opacity(0.8),
                            tier.secondaryColor.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.025 * scale, height: size * 0.2 * scale)
                .offset(y: size * 0.18 * scale)
                .rotationEffect(.degrees(spread + sin(flamePhase * 2 + Double(i)) * 5))
                .blur(radius: 1)
        }
    }

    @ViewBuilder
    private func flameWingTrail(side: WingSide) -> some View {
        let xOffset = side == .left ? -size * 0.2 : size * 0.2

        ForEach(0..<3, id: \.self) { i in
            flameShape(width: size * 0.08, height: size * 0.15)
                .fill(tier.secondaryColor.opacity(0.3 - Double(i) * 0.08))
                .offset(x: xOffset + sin(flamePhase + Double(i)) * size * 0.02, y: Double(i) * size * 0.03)
                .blur(radius: 2)
        }
    }

    @ViewBuilder
    private var crownFlame: some View {
        ForEach(0..<3, id: \.self) { i in
            flameShape(width: size * 0.04, height: size * 0.08)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), tier.primaryColor.opacity(0.5)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .offset(x: CGFloat(i - 1) * size * 0.04, y: -size * 0.22)
                .scaleEffect(y: 1 + sin(flamePhase * 5 + Double(i)) * 0.3)
        }
    }

    @ViewBuilder
    private var iriscentWingAura: some View {
        ForEach(0..<2, id: \.self) { side in
            let xOffset = side == 0 ? -size * 0.15 : size * 0.15

            SwiftUI.Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hue: iriscentShift, saturation: 0.8, brightness: 1.0),
                            Color(hue: iriscentShift + 0.3, saturation: 0.7, brightness: 0.9),
                            Color(hue: iriscentShift + 0.6, saturation: 0.8, brightness: 1.0),
                            Color(hue: iriscentShift, saturation: 0.8, brightness: 1.0)
                        ],
                        center: .center
                    )
                )
                .frame(width: size * 0.3, height: size * 0.3)
                .offset(x: xOffset)
                .blur(radius: size * 0.08)
                .opacity(0.4)
        }
    }

    @ViewBuilder
    private var diamondSparkles: some View {
        Canvas { context, canvasSize in
            for i in 0..<8 {
                let angle = Double(i) / 8.0 * 2 * .pi + featherShimmer
                let radius = size * 0.08
                let x = canvasSize.width / 2 + cos(angle) * radius
                let y = canvasSize.height / 2 + sin(angle) * radius

                let sparkleSize = size * 0.015 * (0.8 + sin(featherShimmer * 3 + Double(i)) * 0.4)

                // Diamond shape (rotated square)
                var path = Path()
                path.move(to: CGPoint(x: x, y: y - sparkleSize))
                path.addLine(to: CGPoint(x: x + sparkleSize, y: y))
                path.addLine(to: CGPoint(x: x, y: y + sparkleSize))
                path.addLine(to: CGPoint(x: x - sparkleSize, y: y))
                path.closeSubpath()

                context.fill(path, with: .color(Color.white.opacity(0.8)))
            }
        }
    }

    @ViewBuilder
    private var diamondHalo: some View {
        SwiftUI.Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        tier.primaryColor,
                        tier.secondaryColor,
                        Color.white.opacity(0.8),
                        tier.primaryColor
                    ],
                    center: .center,
                    angle: .degrees(featherShimmer * 60)
                ),
                lineWidth: size * 0.01
            )
            .frame(width: size * 0.35, height: size * 0.35)
            .offset(y: -size * 0.15)
            .blur(radius: 1)
    }

    @ViewBuilder
    private var realityWarpField: some View {
        ForEach(0..<3, id: \.self) { ring in
            SwiftUI.Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear,
                            tier.primaryColor.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        angle: .degrees(cosmicWarp * 30 + Double(ring) * 60)
                    ),
                    lineWidth: size * 0.003
                )
                .frame(width: size * (0.6 + Double(ring) * 0.15), height: size * (0.6 + Double(ring) * 0.15))
                .scaleEffect(1 + sin(cosmicWarp + Double(ring)) * 0.05)
        }
    }

    @ViewBuilder
    private var cosmicAurora: some View {
        ForEach(0..<4, id: \.self) { layer in
            SwiftUI.Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hue: iriscentShift + Double(layer) * 0.2, saturation: 0.9, brightness: 1.0).opacity(0.2),
                            Color.clear,
                            Color(hue: iriscentShift + 0.5 + Double(layer) * 0.2, saturation: 0.8, brightness: 0.9).opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        angle: .degrees(cosmicWarp * 20 + Double(layer) * 45)
                    )
                )
                .frame(width: size * (0.7 - Double(layer) * 0.1), height: size * (0.7 - Double(layer) * 0.1))
                .blur(radius: size * 0.05)
        }
    }

    @ViewBuilder
    private var cosmicOverlay: some View {
        SwiftUI.Circle()
            .fill(
                AngularGradient(
                    colors: [
                        Color(hue: iriscentShift, saturation: 0.6, brightness: 1.0).opacity(0.3),
                        Color(hue: iriscentShift + 0.33, saturation: 0.5, brightness: 0.9).opacity(0.2),
                        Color(hue: iriscentShift + 0.66, saturation: 0.6, brightness: 1.0).opacity(0.3),
                        Color(hue: iriscentShift, saturation: 0.6, brightness: 1.0).opacity(0.3)
                    ],
                    center: .center,
                    angle: .degrees(cosmicWarp * 30)
                )
            )
            .blendMode(.overlay)
    }

    @ViewBuilder
    private var stellarCrown: some View {
        ZStack {
            // Stellar rays
            ForEach(0..<8, id: \.self) { ray in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color(hue: iriscentShift + Double(ray) * 0.1, saturation: 0.8, brightness: 1.0).opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: size * 0.015, height: size * 0.06 + sin(cosmicWarp * 3 + Double(ray)) * size * 0.02)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(ray) * 45))
            }

            // Central star
            SwiftUI.Circle()
                .fill(Color.white)
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(y: -size * 0.22)
                .shadow(color: Color.white.opacity(0.8), radius: 5)
        }
    }

    // MARK: - Streak Display

    @ViewBuilder
    private var streakDisplay: some View {
        VStack(spacing: 2) {
            Text("\(streak)")
                .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                .foregroundStyle(
                    tier == .legendary
                    ? AnyShapeStyle(LinearGradient(
                        colors: [
                            Color(hue: iriscentShift, saturation: 0.8, brightness: 1.0),
                            Color(hue: iriscentShift + 0.3, saturation: 0.7, brightness: 0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    : AnyShapeStyle(tier.primaryColor)
                )
                .shadow(color: tier.primaryColor.opacity(0.5), radius: 4)

            Text("DAY STREAK")
                .font(.system(size: size * 0.06, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))
                .tracking(1)
        }
        .offset(y: size * 0.35)
    }

    // MARK: - Shape Helpers

    private func flameShape(width: CGFloat, height: CGFloat) -> some Shape {
        FlameShape()
    }

    // MARK: - Animations

    private func startAnimations() {
        // Flame flicker
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            flamePhase = 1
        }

        // Wing beat
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            wingBeat = 1
        }

        // Feather shimmer
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            featherShimmer = 1
        }

        // Ember rise
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            emberRise = 1
        }

        // Core glow
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            coreGlow = 1
        }

        // Cosmic warp (legendary only)
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            cosmicWarp = 2 * .pi
        }

        // Iridescent color shift
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            iriscentShift = 1
        }
    }
}

// MARK: - Wing Side

enum WingSide {
    case left, right
}

// MARK: - Custom Shapes

struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.8, y: h * 0.6),
            control: CGPoint(x: w * 0.9, y: h * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 0.7, y: h * 0.9)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.2, y: h * 0.6),
            control: CGPoint(x: w * 0.3, y: h * 0.9)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control: CGPoint(x: w * 0.1, y: h * 0.3)
        )

        return path
    }
}

struct FlameWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Wing shape - curved flame-like
        path.move(to: CGPoint(x: w * 0.2, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.1, y: h * 0.3),
            control: CGPoint(x: 0, y: h * 0.7)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control: CGPoint(x: w * 0.2, y: h * 0.1)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.4),
            control: CGPoint(x: w * 0.8, y: h * 0.1)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.8, y: h),
            control: CGPoint(x: w, y: h * 0.7)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 40) {
            ForEach([0, 1, 5, 10, 20, 50, 150], id: \.self) { streak in
                VStack {
                    PhoenixStreakVisualization(streak: streak, size: 150)

                    Text(PhoenixTier.forStreak(streak).tierName)
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.caption)
                }
            }
        }
        .padding()
    }
    .background(Color.black)
}
