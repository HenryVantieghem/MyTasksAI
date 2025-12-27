//
//  GlowingOrbLogo.swift
//  Veloce
//
//  Iridescent Cloud Orb Logo
//  A luminous, ethereal sphere with soft iridescent colors
//  Inspired by soap bubbles and aurora clouds
//

import SwiftUI

// MARK: - Glowing Orb Logo

/// Iridescent cloud orb logo with ethereal presence
struct GlowingOrbLogo: View {
    let size: LogoSize
    var isAnimating: Bool = true
    var showParticles: Bool = true
    var intensity: Double = 1.0

    @State private var floatPhase: Double = 0
    @State private var breathePhase: Double = 0
    @State private var colorShiftPhase: Double = 0
    @State private var shimmerPhase: Double = 0
    @State private var glowPulsePhase: Double = 0

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

    var body: some View {
        ZStack {
            if size.showGlow { atmosphericGlow; diffusedHalo }
            mainOrbBody
            innerLuminescence
            iridescentSurface
            edgeHighlightRim
            specularHighlights
            if showParticles && size.showParticles && !reduceMotion { floatingMotes }
        }
        .frame(width: size.dimension * 1.6, height: size.dimension * 1.6)
        .offset(y: -floatPhase * size.dimension * 0.06)
        .onAppear { guard isAnimating && !reduceMotion else { return }; startAnimations() }
    }

    private var atmosphericGlow: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [iridescenceColors[4].opacity(0.35 * intensity * (0.85 + glowPulsePhase * 0.15)), iridescenceColors[2].opacity(0.20 * intensity), Color.clear], center: .center, startRadius: size.dimension * 0.25, endRadius: size.dimension * 0.75))
                .frame(width: size.dimension * 1.5, height: size.dimension * 1.5)
                .blur(radius: size.dimension * 0.15)
            Circle()
                .fill(RadialGradient(colors: [iridescenceColors[0].opacity(0.25 * intensity), iridescenceColors[7].opacity(0.12 * intensity), Color.clear], center: UnitPoint(x: 0.6, y: 0.4), startRadius: size.dimension * 0.15, endRadius: size.dimension * 0.55))
                .frame(width: size.dimension * 1.4, height: size.dimension * 1.4)
                .blur(radius: size.dimension * 0.12)
                .offset(x: size.dimension * 0.05)
        }
    }

    private var diffusedHalo: some View {
        Circle()
            .fill(RadialGradient(colors: [Color.white.opacity(0.15 * intensity), iridescenceColors[4].opacity(0.20 * intensity * (0.9 + breathePhase * 0.1)), iridescenceColors[2].opacity(0.10 * intensity), Color.clear], center: .center, startRadius: size.dimension * 0.22, endRadius: size.dimension * 0.55))
            .frame(width: size.dimension * 1.1, height: size.dimension * 1.1)
            .blur(radius: size.dimension * 0.08)
            .scaleEffect(1.0 + breathePhase * 0.04)
    }

    private var mainOrbBody: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [midBlue.opacity(0.85), deepBlue.opacity(0.95), deepBlue], center: UnitPoint(x: 0.35, y: 0.35), startRadius: size.dimension * 0.05, endRadius: size.dimension * 0.35))
                .frame(width: size.dimension * 0.65, height: size.dimension * 0.65)
            Circle()
                .fill(AngularGradient(colors: [iridescenceColors[2].opacity(0.25), iridescenceColors[4].opacity(0.20), iridescenceColors[6].opacity(0.15), iridescenceColors[0].opacity(0.20), iridescenceColors[2].opacity(0.25)], center: .center, angle: .degrees(colorShiftPhase * 30)))
                .frame(width: size.dimension * 0.60, height: size.dimension * 0.60)
                .blur(radius: size.dimension * 0.06)
                .blendMode(.screen)
            Circle()
                .fill(LinearGradient(colors: [Color.clear, deepBlue.opacity(0.4), deepBlue.opacity(0.6)], startPoint: UnitPoint(x: 0.5, y: 0.3), endPoint: .bottom))
                .frame(width: size.dimension * 0.65, height: size.dimension * 0.65)
        }
        .scaleEffect(1.0 + breathePhase * 0.02)
    }

    private var innerLuminescence: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.white.opacity(0.55 * intensity), iridescenceColors[4].opacity(0.35 * intensity), iridescenceColors[2].opacity(0.15 * intensity), Color.clear], center: UnitPoint(x: 0.45, y: 0.42), startRadius: 0, endRadius: size.dimension * 0.25))
                .frame(width: size.dimension * 0.55, height: size.dimension * 0.55)
                .blur(radius: size.dimension * 0.04)
            Circle()
                .fill(RadialGradient(colors: [iridescenceColors[0].opacity(0.35 * intensity * (0.8 + glowPulsePhase * 0.2)), iridescenceColors[7].opacity(0.20 * intensity), Color.clear], center: UnitPoint(x: 0.55, y: 0.48), startRadius: 0, endRadius: size.dimension * 0.18))
                .frame(width: size.dimension * 0.45, height: size.dimension * 0.45)
                .blur(radius: size.dimension * 0.03)
        }
    }

    private var iridescentSurface: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(colors: [Color.white.opacity(0.45), iridescenceColors[4].opacity(0.35), iridescenceColors[0].opacity(0.25), Color.clear], startPoint: UnitPoint(x: 0.1, y: 0.15), endPoint: UnitPoint(x: 0.7, y: 0.6)))
                .frame(width: size.dimension * 0.55, height: size.dimension * 0.35)
                .rotationEffect(.degrees(-25))
                .offset(x: -size.dimension * 0.08, y: -size.dimension * 0.10)
                .blur(radius: size.dimension * 0.025)
            Ellipse()
                .fill(LinearGradient(colors: [iridescenceColors[5].opacity(0.30 * (0.85 + shimmerPhase * 0.15)), iridescenceColors[4].opacity(0.20), Color.clear], startPoint: UnitPoint(x: 0.8, y: 0.3), endPoint: UnitPoint(x: 0.4, y: 0.8)))
                .frame(width: size.dimension * 0.25, height: size.dimension * 0.45)
                .offset(x: size.dimension * 0.15, y: -size.dimension * 0.02)
                .blur(radius: size.dimension * 0.02)
            Ellipse()
                .fill(RadialGradient(colors: [iridescenceColors[0].opacity(0.30), iridescenceColors[1].opacity(0.18), Color.clear], center: .center, startRadius: 0, endRadius: size.dimension * 0.15))
                .frame(width: size.dimension * 0.30, height: size.dimension * 0.25)
                .offset(x: -size.dimension * 0.10, y: size.dimension * 0.12)
                .blur(radius: size.dimension * 0.02)
        }
    }

    private var edgeHighlightRim: some View {
        ZStack {
            Circle()
                .stroke(AngularGradient(colors: [Color.white.opacity(0.50), iridescenceColors[4].opacity(0.35), Color.clear, Color.clear, iridescenceColors[0].opacity(0.20), Color.white.opacity(0.35)], center: .center, startAngle: .degrees(-60), endAngle: .degrees(300)), lineWidth: size.dimension * 0.025)
                .frame(width: size.dimension * 0.62, height: size.dimension * 0.62)
                .blur(radius: size.dimension * 0.01)
            Circle()
                .stroke(LinearGradient(colors: [Color.white.opacity(0.25), Color.clear, iridescenceColors[2].opacity(0.15), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size.dimension * 0.012)
                .frame(width: size.dimension * 0.58, height: size.dimension * 0.58)
        }
    }

    private var specularHighlights: some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.50), Color.clear], center: .center, startRadius: 0, endRadius: size.dimension * 0.06))
                .frame(width: size.dimension * 0.12, height: size.dimension * 0.06)
                .offset(x: -size.dimension * 0.12, y: -size.dimension * 0.16)
                .blur(radius: size.dimension * 0.008)
            Ellipse().fill(Color.white.opacity(0.40)).frame(width: size.dimension * 0.06, height: size.dimension * 0.03).offset(x: -size.dimension * 0.08, y: -size.dimension * 0.20).blur(radius: 2)
            Circle().fill(Color.white.opacity(0.70 * (0.7 + shimmerPhase * 0.3))).frame(width: size.dimension * 0.025, height: size.dimension * 0.025).offset(x: -size.dimension * 0.15, y: -size.dimension * 0.13).blur(radius: 0.5)
        }
    }

    private var floatingMotes: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                IridescentMote(index: index, phase: colorShiftPhase, orbSize: size.dimension, colors: iridescenceColors)
            }
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { floatPhase = 1.0 }
        withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) { breathePhase = 1.0 }
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) { colorShiftPhase = 12.0 }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { shimmerPhase = 1.0 }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glowPulsePhase = 1.0 }
    }
}

private struct IridescentMote: View {
    let index: Int; let phase: Double; let orbSize: CGFloat; let colors: [Color]
    var body: some View {
        let seed = Double(index) * 1.618, baseAngle = seed * .pi * 2 / 8, radius = orbSize * (0.38 + sin(seed * 2.1) * 0.08), sz = orbSize * (0.015 + sin(seed * 1.7) * 0.008)
        let currentAngle = baseAngle + phase * 0.3, x = cos(currentAngle) * radius, y = sin(currentAngle) * radius * 0.5
        Circle().fill(RadialGradient(colors: [Color.white.opacity(0.9), colors[index % colors.count].opacity(0.4 + sin(phase * .pi + Double(index)) * 0.3), Color.clear], center: .center, startRadius: 0, endRadius: sz)).frame(width: sz * 2, height: sz * 2).offset(x: x, y: y).blur(radius: sz * 0.2)
    }
}

// MARK: - Static Orb Logo

struct StaticOrbLogo: View {
    let size: LogoSize; var intensity: Double = 1.0
    private let iridescenceColors: [Color] = [Color(red: 0.95, green: 0.75, blue: 0.85), Color(red: 0.85, green: 0.65, blue: 0.90), Color(red: 0.70, green: 0.60, blue: 0.95), Color(red: 0.55, green: 0.70, blue: 0.95), Color(red: 0.50, green: 0.80, blue: 0.95)]
    private var deepBlue: Color { Color(red: 0.12, green: 0.15, blue: 0.35) }
    var body: some View {
        ZStack {
            if size.showGlow { Circle().fill(RadialGradient(colors: [iridescenceColors[4].opacity(0.30 * intensity), iridescenceColors[2].opacity(0.15 * intensity), Color.clear], center: .center, startRadius: size.dimension * 0.20, endRadius: size.dimension * 0.60)).frame(width: size.dimension * 1.2, height: size.dimension * 1.2).blur(radius: size.dimension * 0.10) }
            Circle().fill(RadialGradient(colors: [Color(red: 0.25, green: 0.30, blue: 0.55).opacity(0.85), deepBlue.opacity(0.95), deepBlue], center: UnitPoint(x: 0.35, y: 0.35), startRadius: size.dimension * 0.05, endRadius: size.dimension * 0.35)).frame(width: size.dimension * 0.65, height: size.dimension * 0.65)
            Circle().fill(RadialGradient(colors: [Color.white.opacity(0.50 * intensity), iridescenceColors[4].opacity(0.30 * intensity), Color.clear], center: UnitPoint(x: 0.45, y: 0.42), startRadius: 0, endRadius: size.dimension * 0.20)).frame(width: size.dimension * 0.50, height: size.dimension * 0.50).blur(radius: size.dimension * 0.03)
            Ellipse().fill(LinearGradient(colors: [Color.white.opacity(0.40), iridescenceColors[4].opacity(0.30), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: size.dimension * 0.50, height: size.dimension * 0.30).rotationEffect(.degrees(-25)).offset(x: -size.dimension * 0.06, y: -size.dimension * 0.10).blur(radius: size.dimension * 0.02)
            Ellipse().fill(RadialGradient(colors: [iridescenceColors[0].opacity(0.25), Color.clear], center: .center, startRadius: 0, endRadius: size.dimension * 0.12)).frame(width: size.dimension * 0.25, height: size.dimension * 0.20).offset(x: -size.dimension * 0.08, y: size.dimension * 0.10).blur(radius: size.dimension * 0.02)
            Ellipse().fill(RadialGradient(colors: [Color.white.opacity(0.80), Color.white.opacity(0.40), Color.clear], center: .center, startRadius: 0, endRadius: size.dimension * 0.05)).frame(width: size.dimension * 0.10, height: size.dimension * 0.05).offset(x: -size.dimension * 0.10, y: -size.dimension * 0.15).blur(radius: 1)
        }.frame(width: size.dimension, height: size.dimension)
    }
}

// MARK: - Loading Orb Logo

struct LoadingOrbLogo: View {
    let size: LogoSize
    @State private var pulsePhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let iridescenceColors: [Color] = [Color(red: 0.50, green: 0.80, blue: 0.95), Color(red: 0.70, green: 0.60, blue: 0.95), Color(red: 0.95, green: 0.75, blue: 0.85)]
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let progress = (pulsePhase + Double(index) * 0.33).truncatingRemainder(dividingBy: 1.0)
                Circle().stroke(LinearGradient(colors: [iridescenceColors[index % 3].opacity((1.0 - progress) * 0.5), iridescenceColors[(index + 1) % 3].opacity((1.0 - progress) * 0.25), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2).frame(width: size.dimension * (0.7 + progress * 0.5), height: size.dimension * (0.7 + progress * 0.5))
            }
            GlowingOrbLogo(size: size, isAnimating: true, showParticles: false, intensity: 0.9 + pulsePhase * 0.2)
        }.onAppear { guard !reduceMotion else { return }; withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { pulsePhase = 1.0 } }
    }
}

// MARK: - Success Orb Burst

struct SuccessOrbBurst: View {
    let size: LogoSize; @Binding var shouldBurst: Bool
    @State private var burstParticles: [OrbBurstParticle] = []; @State private var showCheckmark = false; @State private var ringScale: CGFloat = 0.5
    private let successColors: [Color] = [Color(red: 0.50, green: 0.80, blue: 0.95), Color(red: 0.70, green: 0.60, blue: 0.95), Color(red: 0.95, green: 0.75, blue: 0.85), Color(red: 0.40, green: 0.85, blue: 0.70), Color.white]
    var body: some View {
        ZStack {
            Circle().stroke(LinearGradient(colors: [Color(red: 0.40, green: 0.85, blue: 0.70), Color(red: 0.50, green: 0.80, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3).frame(width: size.dimension * ringScale, height: size.dimension * ringScale).opacity(showCheckmark ? 0 : 0.8)
            GlowingOrbLogo(size: size, isAnimating: true, showParticles: false, intensity: 1.3)
            ForEach(burstParticles) { p in Circle().fill(p.color).frame(width: p.size, height: p.size).offset(x: p.offset.width, y: p.offset.height).opacity(p.opacity).blur(radius: p.size * 0.15) }
            if showCheckmark { Image(systemName: "checkmark").font(.system(size: size.dimension * 0.22, weight: .bold)).foregroundStyle(.white).shadow(color: Color(red: 0.40, green: 0.85, blue: 0.70).opacity(0.8), radius: 10).transition(.scale.combined(with: .opacity)) }
        }.frame(width: size.dimension * 1.8, height: size.dimension * 1.8).onChange(of: shouldBurst) { _, newValue in if newValue { triggerBurst() } }
    }
    private func triggerBurst() {
        burstParticles = (0..<24).map { i in let angle = Double(i) / 24.0 * 2 * .pi, dist = CGFloat.random(in: size.dimension * 0.4...size.dimension * 0.9); return OrbBurstParticle(id: UUID(), color: successColors[i % 5], size: CGFloat.random(in: 5...14), offset: .zero, targetOffset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist), opacity: 1.0) }
        withAnimation(.easeOut(duration: 0.5)) { ringScale = 1.5 }
        withAnimation(.easeOut(duration: 0.7)) { for i in burstParticles.indices { burstParticles[i].offset = burstParticles[i].targetOffset } }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) { for i in burstParticles.indices { burstParticles[i].opacity = 0 } }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.25)) { showCheckmark = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { shouldBurst = false; showCheckmark = false; burstParticles = []; ringScale = 0.5 }
    }
}

private struct OrbBurstParticle: Identifiable { let id: UUID; let color: Color; let size: CGFloat; var offset: CGSize; let targetOffset: CGSize; var opacity: Double }

// MARK: - Orb Logo With Text

struct OrbLogoWithText: View {
    let size: LogoSize; var showTagline: Bool = true
    var body: some View {
        VStack(spacing: size.dimension * 0.12) {
            GlowingOrbLogo(size: size)
            VStack(spacing: 6) {
                Text("Veloce").font(.system(size: size.dimension * 0.18, weight: .thin)).foregroundStyle(LinearGradient(colors: [.white, .white.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                if showTagline { Text("INFINITE MOMENTUM").font(.system(size: size.dimension * 0.055, weight: .medium)).foregroundStyle(.white.opacity(0.5)).tracking(3) }
            }
        }
    }
}

#Preview("Iridescent Cloud Orb") { ZStack { Color(red: 0.10, green: 0.12, blue: 0.30).ignoresSafeArea(); GlowingOrbLogo(size: .hero) } }
