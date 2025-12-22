//
//  FocusModeGlow.swift
//  MyTasksAI
//
//  Aurora glow effects for Focus Mode
//  Beautiful breathing aurora with logo-style glow like Apple Sign In
//

import SwiftUI

// MARK: - Focus Mode Glow
struct FocusModeGlow: View {
    let progress: Double  // 0.0 to 1.0
    let isActive: Bool
    let taskTitle: String

    // MARK: - Animation State
    @State private var breatheScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.5
    @State private var ringRotation: Double = 0
    @State private var auroraPhase: Double = 0
    @State private var orbPulse: Double = 1.0
    @State private var particlePhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Layer 1: Deep void with aurora streamers
                voidAuroraBackground(size: geometry.size)

                // Layer 2: Outer glow rings (breathing)
                outerGlowRings(centerSize: size * 0.6)

                // Layer 3: Progress ring with iridescent glow
                progressRing(size: size * 0.55)

                // Layer 4: Central orb (logo-style)
                centralOrb(size: size * 0.25)

                // Layer 5: Floating particles (during active timer)
                if isActive && !reduceMotion {
                    floatingParticles(bounds: geometry.size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Layer 1: Void Aurora Background
    private func voidAuroraBackground(size: CGSize) -> some View {
        ZStack {
            // Deep void base
            Color(red: 0.02, green: 0.02, blue: 0.05)

            // Aurora streamers
            ForEach(0..<4, id: \.self) { index in
                auroraStreamer(index: index, size: size)
            }
        }
    }

    private func auroraStreamer(index: Int, size: CGSize) -> some View {
        let colors = auroraColors(for: index)
        let offset = auroraOffset(for: index, phase: auroraPhase)

        return Ellipse()
            .fill(
                RadialGradient(
                    colors: colors,
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.6
                )
            )
            .frame(
                width: size.width * (1.2 - Double(index) * 0.15),
                height: size.height * (0.8 - Double(index) * 0.1)
            )
            .blur(radius: 80 + CGFloat(index) * 20)
            .opacity(isActive ? 0.6 : 0.35)
            .offset(x: offset.x, y: offset.y)
            .rotationEffect(.degrees(Double(index) * 30 + auroraPhase * 15))
    }

    private func auroraColors(for index: Int) -> [Color] {
        switch index % 4 {
        case 0: return [Theme.Colors.aiPurple, Theme.Colors.aiPurple.opacity(0)]
        case 1: return [Theme.Colors.aiBlue, Theme.Colors.aiBlue.opacity(0)]
        case 2: return [Theme.Colors.aiCyan, Theme.Colors.aiCyan.opacity(0)]
        default: return [Theme.Colors.aiPink.opacity(0.7), Theme.Colors.aiPink.opacity(0)]
        }
    }

    private func auroraOffset(for index: Int, phase: Double) -> CGPoint {
        let baseAngle = Double(index) * .pi / 2
        let animatedAngle = baseAngle + phase * .pi / 4
        let radius: Double = 40 + Double(index) * 20

        return CGPoint(
            x: cos(animatedAngle) * radius,
            y: sin(animatedAngle) * radius * 0.6
        )
    }

    // MARK: - Layer 2: Outer Glow Rings
    private func outerGlowRings(centerSize: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(0.4 - Double(index) * 0.1),
                                Theme.Colors.aiBlue.opacity(0.3 - Double(index) * 0.08),
                                Theme.Colors.aiCyan.opacity(0.25 - Double(index) * 0.06),
                                Theme.Colors.aiPink.opacity(0.2 - Double(index) * 0.05),
                                Theme.Colors.aiPurple.opacity(0.4 - Double(index) * 0.1)
                            ],
                            center: .center,
                            angle: .degrees(ringRotation + Double(index * 45))
                        ),
                        lineWidth: 2 - CGFloat(index) * 0.5
                    )
                    .frame(
                        width: centerSize + CGFloat(index) * 50,
                        height: centerSize + CGFloat(index) * 50
                    )
                    .scaleEffect(breatheScale + CGFloat(index) * 0.03)
                    .blur(radius: CGFloat(index + 1) * 6)
            }
        }
    }

    // MARK: - Layer 3: Progress Ring
    private func progressRing(size: CGFloat) -> some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 10)
                .frame(width: size, height: size)

            // Progress fill with iridescent gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Colors.aiPurple,
                            Theme.Colors.aiBlue,
                            Theme.Colors.aiCyan,
                            Theme.Colors.aiPink,
                            Theme.Colors.aiPurple
                        ],
                        center: .center,
                        angle: .degrees(ringRotation * 0.5)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.Colors.aiPurple.opacity(glowIntensity), radius: 20)
                .shadow(color: Theme.Colors.aiCyan.opacity(glowIntensity * 0.6), radius: 35)

            // Progress end cap glow
            if progress > 0.02 {
                Circle()
                    .fill(Theme.Colors.aiCyan)
                    .frame(width: 14, height: 14)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * progress - 90))
                    .shadow(color: Theme.Colors.aiCyan.opacity(0.8), radius: 10)
                    .shadow(color: .white.opacity(0.5), radius: 5)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: progress)
    }

    // MARK: - Layer 4: Central Orb (Logo Style)
    private func centralOrb(size: CGFloat) -> some View {
        ZStack {
            // Outer soft glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.5),
                            Theme.Colors.aiBlue.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 1.5
                    )
                )
                .frame(width: size * 3, height: size * 3)
                .blur(radius: 30)
                .scaleEffect(breatheScale)

            // Core gradient orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.95),
                            Theme.Colors.aiPurple.opacity(0.8),
                            Theme.Colors.aiBlue.opacity(0.7),
                            Theme.Colors.aiCyan.opacity(0.5)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    // Shine highlight (like Apple Sign In button)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .clear],
                                startPoint: .topLeading,
                                endPoint: UnitPoint(x: 0.6, y: 0.6)
                            )
                        )
                        .frame(width: size * 0.7, height: size * 0.7)
                        .offset(x: -size * 0.1, y: -size * 0.1)
                        .blur(radius: 2)
                )
                .scaleEffect(orbPulse)
                .shadow(color: Theme.Colors.aiPurple.opacity(0.6), radius: 25)
                .shadow(color: Theme.Colors.aiCyan.opacity(0.4), radius: 40)
        }
    }

    // MARK: - Layer 5: Floating Particles
    private func floatingParticles(bounds: CGSize) -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                particle(index: index, bounds: bounds)
            }
        }
    }

    private func particle(index: Int, bounds: CGSize) -> some View {
        let baseAngle = Double(index) * (2 * .pi / 12)
        let animatedAngle = baseAngle + particlePhase * .pi
        let radius = bounds.width * 0.3 + sin(particlePhase * 2 + Double(index)) * 30
        let size = CGFloat(4 + (index % 3) * 2)

        return Circle()
            .fill(particleColor(for: index))
            .frame(width: size, height: size)
            .blur(radius: 1)
            .offset(
                x: cos(animatedAngle) * radius,
                y: sin(animatedAngle) * radius * 0.7
            )
            .opacity(0.6 + sin(particlePhase * 3 + Double(index)) * 0.3)
    }

    private func particleColor(for index: Int) -> Color {
        switch index % 4 {
        case 0: return Theme.Colors.aiPurple
        case 1: return Theme.Colors.aiCyan
        case 2: return Theme.Colors.aiBlue
        default: return .white.opacity(0.8)
        }
    }

    // MARK: - Animations
    private func startAnimations() {
        guard !reduceMotion else { return }

        // Breathing animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            breatheScale = 1.08
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = isActive ? 0.8 : 0.5
        }

        // Ring rotation (slow, continuous)
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Aurora phase shift
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            auroraPhase = 1
        }

        // Orb pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            orbPulse = 1.05
        }

        // Particle movement
        if isActive {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                particlePhase = 2
            }
        }
    }
}

// MARK: - Preview
#Preview("Focus Mode Glow - Active") {
    FocusModeGlow(
        progress: 0.65,
        isActive: true,
        taskTitle: "Complete design review"
    )
}

#Preview("Focus Mode Glow - Idle") {
    FocusModeGlow(
        progress: 0,
        isActive: false,
        taskTitle: "Start focusing"
    )
}
