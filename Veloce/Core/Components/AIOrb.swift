//
//  AIOrb.swift
//  Veloce
//
//  AI Orb Component - Iridescent Cloud Orb
//  Reusable animated orb for AI presence across the app
//

import SwiftUI

enum AIOrbAnimationStyle {
    case breathing, thinking, pulse, idle, none
}

struct AIOrb: View {
    let size: VoidDesign.OrbSize
    let animationStyle: AIOrbAnimationStyle
    let showParticles: Bool
    let showRings: Bool

    @State private var orbScale: CGFloat = 1.0
    @State private var orbRotation: Double = 0
    @State private var glowOpacity: Double = 0.5
    @State private var ringScale: CGFloat = 0.8
    @State private var particleOffset: CGFloat = 0
    @State private var floatPhase: Double = 0
    @State private var colorShiftPhase: Double = 0
    @State private var shimmerPhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let iridescenceColors: [Color] = [
        Color(red: 0.95, green: 0.75, blue: 0.85),
        Color(red: 0.85, green: 0.65, blue: 0.90),
        Color(red: 0.70, green: 0.60, blue: 0.95),
        Color(red: 0.55, green: 0.70, blue: 0.95),
        Color(red: 0.50, green: 0.80, blue: 0.95),
        Color(red: 0.60, green: 0.85, blue: 0.90),
        Color(red: 0.80, green: 0.70, blue: 0.95),
        Color(red: 0.90, green: 0.70, blue: 0.88),
    ]

    private var deepBlue: Color { Color(red: 0.12, green: 0.15, blue: 0.35) }
    private var midBlue: Color { Color(red: 0.20, green: 0.25, blue: 0.50) }

    init(size: VoidDesign.OrbSize = .medium, animationStyle: AIOrbAnimationStyle = .breathing, showParticles: Bool = false, showRings: Bool = true) {
        self.size = size; self.animationStyle = animationStyle; self.showParticles = showParticles; self.showRings = showRings
    }

    private var orbDiameter: CGFloat { size.rawValue }
    private var containerSize: CGFloat { orbDiameter * 2.5 }

    var body: some View {
        ZStack {
            atmosphericGlow
            if showRings { glowRings }
            mainOrbBody
            innerLuminescence
            iridescentSurface
            edgeHighlightRim
            specularHighlights
            if showParticles && !reduceMotion { floatingParticles }
        }
        .frame(width: containerSize, height: containerSize)
        .offset(y: -floatPhase * orbDiameter * 0.04)
        .onAppear { guard !reduceMotion else { return }; startAnimations() }
    }

    private var atmosphericGlow: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [iridescenceColors[4].opacity(0.35 * glowOpacity), iridescenceColors[2].opacity(0.20 * glowOpacity), Color.clear], center: .center, startRadius: orbDiameter * 0.25, endRadius: orbDiameter * 0.9)).frame(width: orbDiameter * 2.5, height: orbDiameter * 2.5).blur(radius: orbDiameter * 0.25)
            Circle().fill(RadialGradient(colors: [iridescenceColors[0].opacity(0.25 * glowOpacity), iridescenceColors[7].opacity(0.12 * glowOpacity), Color.clear], center: UnitPoint(x: 0.6, y: 0.4), startRadius: orbDiameter * 0.15, endRadius: orbDiameter * 0.6)).frame(width: orbDiameter * 2.25, height: orbDiameter * 2.25).blur(radius: orbDiameter * 0.2).offset(x: orbDiameter * 0.08)
        }
    }

    private var glowRings: some View {
        ForEach(0..<3, id: \.self) { index in
            Circle().stroke(LinearGradient(colors: [iridescenceColors[4].opacity(0.30 - Double(index) * 0.08), iridescenceColors[0].opacity(0.20 - Double(index) * 0.05), iridescenceColors[2].opacity(0.10 - Double(index) * 0.02)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size.rawValue >= 40 ? 1.5 : 0.5)
                .frame(width: orbDiameter * 1.75 + CGFloat(index) * (size.rawValue >= 80 ? 50 : 25), height: orbDiameter * 1.75 + CGFloat(index) * (size.rawValue >= 80 ? 50 : 25))
                .scaleEffect(ringScale + CGFloat(index) * 0.1).opacity(0.5 - Double(index) * 0.15).rotationEffect(.degrees(orbRotation + Double(index * 30)))
        }
    }

    private var mainOrbBody: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [midBlue.opacity(0.85), deepBlue.opacity(0.95), deepBlue], center: UnitPoint(x: 0.35, y: 0.35), startRadius: orbDiameter * 0.05, endRadius: orbDiameter * 0.35)).frame(width: orbDiameter * 0.65, height: orbDiameter * 0.65)
            Circle().fill(AngularGradient(colors: [iridescenceColors[2].opacity(0.25), iridescenceColors[4].opacity(0.20), iridescenceColors[6].opacity(0.15), iridescenceColors[0].opacity(0.20), iridescenceColors[2].opacity(0.25)], center: .center, angle: .degrees(colorShiftPhase * 30))).frame(width: orbDiameter * 0.60, height: orbDiameter * 0.60).blur(radius: orbDiameter * 0.06).blendMode(.screen)
            Circle().fill(LinearGradient(colors: [Color.clear, deepBlue.opacity(0.4), deepBlue.opacity(0.6)], startPoint: UnitPoint(x: 0.5, y: 0.3), endPoint: .bottom)).frame(width: orbDiameter * 0.65, height: orbDiameter * 0.65)
        }.scaleEffect(orbScale)
    }

    private var innerLuminescence: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color.white.opacity(0.55), iridescenceColors[4].opacity(0.35), iridescenceColors[2].opacity(0.15), Color.clear], center: UnitPoint(x: 0.45, y: 0.42), startRadius: 0, endRadius: orbDiameter * 0.25)).frame(width: orbDiameter * 0.55, height: orbDiameter * 0.55).blur(radius: orbDiameter * 0.04)
            Circle().fill(RadialGradient(colors: [iridescenceColors[0].opacity(0.35 * (0.8 + glowOpacity * 0.4)), iridescenceColors[7].opacity(0.20), Color.clear], center: UnitPoint(x: 0.55, y: 0.48), startRadius: 0, endRadius: orbDiameter * 0.18)).frame(width: orbDiameter * 0.45, height: orbDiameter * 0.45).blur(radius: orbDiameter * 0.03)
        }.scaleEffect(orbScale)
    }

    private var iridescentSurface: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [Color.white.opacity(0.45), iridescenceColors[4].opacity(0.35), iridescenceColors[0].opacity(0.25), Color.clear], startPoint: UnitPoint(x: 0.1, y: 0.15), endPoint: UnitPoint(x: 0.7, y: 0.6))).frame(width: orbDiameter * 0.55, height: orbDiameter * 0.35).rotationEffect(.degrees(-25)).offset(x: -orbDiameter * 0.08, y: -orbDiameter * 0.10).blur(radius: orbDiameter * 0.025)
            Ellipse().fill(LinearGradient(colors: [iridescenceColors[5].opacity(0.30 * (0.85 + shimmerPhase * 0.15)), iridescenceColors[4].opacity(0.20), Color.clear], startPoint: UnitPoint(x: 0.8, y: 0.3), endPoint: UnitPoint(x: 0.4, y: 0.8))).frame(width: orbDiameter * 0.25, height: orbDiameter * 0.45).offset(x: orbDiameter * 0.15, y: -orbDiameter * 0.02).blur(radius: orbDiameter * 0.02)
            Ellipse().fill(RadialGradient(colors: [iridescenceColors[0].opacity(0.30), iridescenceColors[1].opacity(0.18), Color.clear], center: .center, startRadius: 0, endRadius: orbDiameter * 0.15)).frame(width: orbDiameter * 0.30, height: orbDiameter * 0.25).offset(x: -orbDiameter * 0.10, y: orbDiameter * 0.12).blur(radius: orbDiameter * 0.02)
        }.scaleEffect(orbScale)
    }

    private var edgeHighlightRim: some View {
        ZStack {
            Circle().stroke(AngularGradient(colors: [Color.white.opacity(0.50), iridescenceColors[4].opacity(0.35), Color.clear, Color.clear, iridescenceColors[0].opacity(0.20), Color.white.opacity(0.35)], center: .center, startAngle: .degrees(-60), endAngle: .degrees(300)), lineWidth: orbDiameter * 0.025).frame(width: orbDiameter * 0.62, height: orbDiameter * 0.62).blur(radius: orbDiameter * 0.01)
            Circle().stroke(LinearGradient(colors: [Color.white.opacity(0.25), Color.clear, iridescenceColors[2].opacity(0.15), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: orbDiameter * 0.012).frame(width: orbDiameter * 0.58, height: orbDiameter * 0.58)
        }.scaleEffect(orbScale)
    }

    private var specularHighlights: some View {
        ZStack {
            Ellipse().fill(RadialGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.50), Color.clear], center: .center, startRadius: 0, endRadius: orbDiameter * 0.06)).frame(width: orbDiameter * 0.12, height: orbDiameter * 0.06).offset(x: -orbDiameter * 0.12, y: -orbDiameter * 0.16).blur(radius: orbDiameter * 0.008)
            Ellipse().fill(Color.white.opacity(0.40)).frame(width: orbDiameter * 0.06, height: orbDiameter * 0.03).offset(x: -orbDiameter * 0.08, y: -orbDiameter * 0.20).blur(radius: 2)
            Circle().fill(Color.white.opacity(0.70 * (0.7 + shimmerPhase * 0.3))).frame(width: orbDiameter * 0.025, height: orbDiameter * 0.025).offset(x: -orbDiameter * 0.15, y: -orbDiameter * 0.13).blur(radius: 0.5)
        }.scaleEffect(orbScale)
    }

    private var floatingParticles: some View {
        let count = size.rawValue >= 80 ? 8 : (size.rawValue >= 40 ? 6 : 4)
        return ForEach(0..<count, id: \.self) { index in
            let seed = Double(index) * 1.618, baseAngle = seed * .pi * 2 / Double(count), currentAngle = baseAngle + particleOffset, radius = orbDiameter * 0.9 * (0.85 + sin(seed * 2.1) * 0.15)
            Circle().fill(RadialGradient(colors: [Color.white.opacity(0.9), iridescenceColors[index % iridescenceColors.count].opacity(0.6), Color.clear], center: .center, startRadius: 0, endRadius: orbDiameter * 0.04)).frame(width: orbDiameter * 0.08, height: orbDiameter * 0.08).offset(x: cos(currentAngle) * radius, y: sin(currentAngle) * radius * 0.5).blur(radius: orbDiameter * 0.01)
        }
    }

    private func startAnimations() {
        switch animationStyle {
        case .breathing:
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { orbScale = 1.08; glowOpacity = 0.75 }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { ringScale = 1.0 }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { floatPhase = 1.0 }
            withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) { colorShiftPhase = 12.0 }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { shimmerPhase = 1.0 }
        case .thinking:
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { orbScale = 1.1; glowOpacity = 0.85 }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { orbRotation = 360 }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { ringScale = 1.0 }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { particleOffset = .pi * 2 }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { floatPhase = 1.0 }
            withAnimation(.linear(duration: 15.0).repeatForever(autoreverses: false)) { colorShiftPhase = 12.0 }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { shimmerPhase = 1.0 }
        case .pulse:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { orbScale = 1.15; glowOpacity = 0.95 }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { ringScale = 1.1 }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { shimmerPhase = 1.0 }
        case .idle:
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { orbScale = 1.03; glowOpacity = 0.55 }
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) { floatPhase = 0.5 }
            withAnimation(.linear(duration: 30.0).repeatForever(autoreverses: false)) { colorShiftPhase = 12.0 }
        case .none: break
        }
    }
}

struct MiniAIOrb: View {
    let size: CGFloat; let animated: Bool
    @State private var scale: CGFloat = 1.0; @State private var opacity: Double = 0.8
    private let iridescenceColors: [Color] = [Color(red: 0.50, green: 0.80, blue: 0.95), Color(red: 0.70, green: 0.60, blue: 0.95), Color(red: 0.95, green: 0.75, blue: 0.85)]
    init(size: CGFloat = 12, animated: Bool = true) { self.size = size; self.animated = animated }
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [iridescenceColors[0].opacity(0.4), iridescenceColors[1].opacity(0.2), Color.clear], center: .center, startRadius: 0, endRadius: size * 0.8)).frame(width: size * 1.5, height: size * 1.5).blur(radius: size * 0.3)
            Circle().fill(RadialGradient(colors: [Color(red: 0.20, green: 0.25, blue: 0.50).opacity(0.85), Color(red: 0.12, green: 0.15, blue: 0.35)], center: UnitPoint(x: 0.35, y: 0.35), startRadius: 0, endRadius: size * 0.5)).frame(width: size, height: size).overlay(Circle().fill(RadialGradient(colors: [Color.white.opacity(0.5), iridescenceColors[0].opacity(0.3), Color.clear], center: UnitPoint(x: 0.4, y: 0.4), startRadius: 0, endRadius: size * 0.4))).scaleEffect(scale).opacity(opacity)
        }.onAppear { if animated { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { scale = 1.1; opacity = 1.0 } } }
    }
}

struct AIStatusIndicator: View {
    let isActive: Bool; let size: CGFloat
    @State private var pulse: CGFloat = 1.0
    private var activeColor: Color { Color(red: 0.50, green: 0.80, blue: 0.95) }
    init(isActive: Bool = true, size: CGFloat = 8) { self.isActive = isActive; self.size = size }
    var body: some View {
        Circle().fill(isActive ? activeColor : Theme.Colors.textTertiary).frame(width: size, height: size).scaleEffect(pulse).shadow(color: (isActive ? activeColor : Color.clear).opacity(0.5), radius: 4)
            .onAppear { if isActive { withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse = 1.3 } } }
    }
}

#Preview("AI Orb") { ZStack { Color(red: 0.10, green: 0.12, blue: 0.30).ignoresSafeArea(); AIOrb(size: .hero, animationStyle: .breathing) } }
