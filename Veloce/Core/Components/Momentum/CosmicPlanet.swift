//
//  CosmicPlanet.swift
//  Veloce
//
//  Cosmic Planet - Goal Visualization
//  Each goal becomes a unique celestial body in your personal universe
//  Rings form as milestones complete, atmosphere glows with progress
//

import SwiftUI

// MARK: - Goal Category Colors

enum GoalPlanetType: String, CaseIterable {
    case career = "career"
    case health = "health"
    case learning = "learning"
    case finance = "finance"
    case relationships = "relationships"
    case creative = "creative"
    case personal = "personal"
    case other = "other"

    var primaryColor: Color {
        switch self {
        case .career: return Color(red: 0.23, green: 0.51, blue: 0.96) // Blue
        case .health: return Color(red: 0.20, green: 0.85, blue: 0.55) // Green
        case .learning: return Color(red: 0.58, green: 0.25, blue: 0.98) // Purple
        case .finance: return Color(red: 0.98, green: 0.75, blue: 0.25) // Gold
        case .relationships: return Color(red: 0.98, green: 0.45, blue: 0.65) // Pink
        case .creative: return Color(red: 0.98, green: 0.55, blue: 0.25) // Orange
        case .personal: return Color(red: 0.20, green: 0.78, blue: 0.95) // Cyan
        case .other: return Color(red: 0.50, green: 0.50, blue: 0.60) // Gray
        }
    }

    var secondaryColor: Color {
        switch self {
        case .career: return Color(red: 0.15, green: 0.35, blue: 0.75)
        case .health: return Color(red: 0.10, green: 0.60, blue: 0.40)
        case .learning: return Color(red: 0.40, green: 0.18, blue: 0.75)
        case .finance: return Color(red: 0.75, green: 0.55, blue: 0.15)
        case .relationships: return Color(red: 0.75, green: 0.30, blue: 0.50)
        case .creative: return Color(red: 0.75, green: 0.40, blue: 0.18)
        case .personal: return Color(red: 0.15, green: 0.55, blue: 0.72)
        case .other: return Color(red: 0.35, green: 0.35, blue: 0.45)
        }
    }

    var atmosphereColor: Color {
        primaryColor.opacity(0.4)
    }

    static func from(category: String?) -> GoalPlanetType {
        guard let category = category?.lowercased() else { return .other }
        return GoalPlanetType(rawValue: category) ?? .other
    }
}

// MARK: - Cosmic Planet

struct CosmicPlanet: View {
    let goal: Goal
    let orbitIndex: Int
    let totalPlanets: Int
    let universeSize: CGFloat
    let orbitPhase: Double

    // Animation states
    @State private var rotationPhase: Double = 0
    @State private var atmospherePulse: Double = 0
    @State private var ringShimmer: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Computed properties
    private var planetType: GoalPlanetType {
        GoalPlanetType.from(category: goal.category)
    }

    private var urgency: Double {
        guard let daysRemaining = goal.daysRemaining else { return 0.5 }
        // More urgent = larger planet, faster orbit
        return max(0.2, min(1.0, 1.0 - Double(daysRemaining) / 30.0))
    }

    private var planetSize: CGFloat {
        let baseSize = universeSize * 0.04
        let urgencyBonus = universeSize * 0.02 * urgency
        return baseSize + urgencyBonus
    }

    private var orbitRadius: CGFloat {
        // Distribute planets at different orbital distances
        let baseRadius = universeSize * 0.18
        let spacing = universeSize * 0.06
        return baseRadius + CGFloat(orbitIndex) * spacing
    }

    private var orbitSpeed: Double {
        // Faster orbit for more urgent goals
        let baseSpeed = 1.0
        return baseSpeed * (0.7 + urgency * 0.6)
    }

    private var milestoneRingCount: Int {
        // Each completed milestone adds a ring (Saturn-style)
        return min(goal.completedMilestoneCount, 4)
    }

    private var linkedTaskProgress: Double {
        // Glow intensity based on linked task completion
        guard goal.linkedTaskCount > 0 else { return 0.3 }
        return goal.progress
    }

    var body: some View {
        ZStack {
            // Orbital path hint (very subtle)
            orbitalPath

            // The planet itself
            planetBody
                .offset(planetPosition)
        }
        .onAppear {
            guard !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Orbital Path

    @ViewBuilder
    private var orbitalPath: some View {
        SwiftUI.Circle()
            .stroke(
                Color.white.opacity(0.03),
                style: StrokeStyle(lineWidth: 1, dash: [4, 8])
            )
            .frame(width: orbitRadius * 2, height: orbitRadius * 2)
    }

    // MARK: - Planet Position

    private var planetPosition: CGSize {
        let angle = orbitPhase * orbitSpeed + Double(orbitIndex) * (2 * .pi / Double(max(totalPlanets, 1)))
        let x = cos(angle) * orbitRadius
        let y = sin(angle) * orbitRadius * 0.4 // Elliptical orbit (flattened)
        return CGSize(width: x, height: y)
    }

    // MARK: - Planet Body

    @ViewBuilder
    private var planetBody: some View {
        ZStack {
            // Layer 1: Outer atmosphere glow
            atmosphereGlow

            // Layer 2: Milestone rings (if any)
            if milestoneRingCount > 0 {
                milestoneRings
            }

            // Layer 3: Planet surface
            planetSurface

            // Layer 4: Surface highlights
            surfaceHighlights

            // Layer 5: Progress indicator
            progressIndicator
        }
        .frame(width: planetSize * 3, height: planetSize * 3)
    }

    // MARK: - Atmosphere Glow

    @ViewBuilder
    private var atmosphereGlow: some View {
        SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        planetType.primaryColor.opacity(0.5 * linkedTaskProgress),
                        planetType.primaryColor.opacity(0.2 * linkedTaskProgress),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: planetSize * 0.3,
                    endRadius: planetSize * 1.2
                )
            )
            .frame(width: planetSize * 2.4, height: planetSize * 2.4)
            .scaleEffect(1 + atmospherePulse * 0.1)
            .blur(radius: planetSize * 0.15)
    }

    // MARK: - Milestone Rings (Saturn-style)

    @ViewBuilder
    private var milestoneRings: some View {
        ForEach(0..<milestoneRingCount, id: \.self) { ring in
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [
                            planetType.primaryColor.opacity(0.6 - Double(ring) * 0.1),
                            planetType.secondaryColor.opacity(0.4 - Double(ring) * 0.08),
                            planetType.primaryColor.opacity(0.5 - Double(ring) * 0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: planetSize * 0.03
                )
                .frame(
                    width: planetSize * (1.6 + Double(ring) * 0.25),
                    height: planetSize * (0.4 + Double(ring) * 0.06)
                )
                .rotationEffect(.degrees(-15))
                .rotation3DEffect(.degrees(75), axis: (x: 1, y: 0, z: 0))
                .opacity(0.8 + ringShimmer * 0.2)
                .blur(radius: 0.5)
        }
    }

    // MARK: - Planet Surface

    @ViewBuilder
    private var planetSurface: some View {
        ZStack {
            // Base sphere with gradient
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetType.primaryColor,
                            planetType.secondaryColor,
                            planetType.secondaryColor.opacity(0.8)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: planetSize * 0.6
                    )
                )
                .frame(width: planetSize, height: planetSize)

            // Surface texture (subtle bands for gas giants feel)
            ForEach(0..<3, id: \.self) { band in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: planetSize * 0.9, height: planetSize * 0.06)
                    .offset(y: CGFloat(band - 1) * planetSize * 0.2)
                    .rotationEffect(.degrees(Double(band) * 5 + rotationPhase * 2))
            }

            // Terminator line (day/night boundary)
            SwiftUI.Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.4)
                        ],
                        startPoint: UnitPoint(x: 0.3, y: 0.3),
                        endPoint: UnitPoint(x: 0.9, y: 0.9)
                    )
                )
                .frame(width: planetSize, height: planetSize)
        }
    }

    // MARK: - Surface Highlights

    @ViewBuilder
    private var surfaceHighlights: some View {
        ZStack {
            // Specular highlight (sun reflection)
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: planetSize * 0.15
                    )
                )
                .frame(width: planetSize * 0.3, height: planetSize * 0.2)
                .offset(x: -planetSize * 0.2, y: -planetSize * 0.2)
                .blur(radius: 1)

            // Edge rim light
            SwiftUI.Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            planetType.primaryColor.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: planetSize * 0.02
                )
                .frame(width: planetSize, height: planetSize)
        }
    }

    // MARK: - Progress Indicator

    @ViewBuilder
    private var progressIndicator: some View {
        // Small progress ring around the planet
        SwiftUI.Circle()
            .trim(from: 0, to: goal.progress)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        planetType.primaryColor.opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: planetSize * 0.04, lineCap: .round)
            )
            .frame(width: planetSize * 1.2, height: planetSize * 1.2)
            .rotationEffect(.degrees(-90))
            .shadow(color: planetType.primaryColor.opacity(0.5), radius: 3)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Planet rotation
        withAnimation(.linear(duration: 20 / orbitSpeed).repeatForever(autoreverses: false)) {
            rotationPhase = 360
        }

        // Atmosphere pulse
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            atmospherePulse = 1
        }

        // Ring shimmer
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            ringShimmer = 1
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black

        // Create sample goals for preview
        VStack {
            Text("Goal Planets Preview")
                .foregroundStyle(.white)
                .font(.headline)

            ZStack {
                // Orbit visualization
                ForEach(0..<3, id: \.self) { i in
                    SwiftUI.Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat(150 + i * 60), height: CGFloat(150 + i * 60))
                }
            }
        }
    }
}
