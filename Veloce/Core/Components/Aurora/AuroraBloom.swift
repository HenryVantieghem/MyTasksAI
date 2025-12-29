//
//  AuroraBloom.swift
//  Veloce
//
//  Aurora Bloom Effects - Glow, Halo, and Light Bleeding
//  Anamorphic lens flare inspired visual effects
//

import SwiftUI

// MARK: - Aurora Bloom View

/// Multi-layer bloom effect for glowing elements
public struct AuroraBloom<Content: View>: View {

    let content: Content
    let color: Color
    let intensity: CGFloat
    let animated: Bool

    @State private var pulsePhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        color: Color = Aurora.Colors.electricCyan,
        intensity: CGFloat = Aurora.GlowIntensity.standard,
        animated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.color = color
        self.intensity = intensity
        self.animated = animated
    }

    public var body: some View {
        ZStack {
            // Outer bloom (large, soft)
            content
                .blur(radius: Aurora.Blur.bloom)
                .opacity(animated ? (intensity * 0.2 + pulsePhase * 0.1) : intensity * 0.2)
                .scaleEffect(1.2)

            // Middle bloom
            content
                .blur(radius: Aurora.Blur.heavy)
                .opacity(animated ? (intensity * 0.3 + pulsePhase * 0.15) : intensity * 0.3)
                .scaleEffect(1.1)

            // Inner glow
            content
                .blur(radius: Aurora.Blur.standard)
                .opacity(animated ? (intensity * 0.4 + pulsePhase * 0.1) : intensity * 0.4)

            // Core content
            content
        }
        .onAppear {
            if animated && !reduceMotion {
                withAnimation(
                    .easeInOut(duration: AuroraMotion.Duration.glowPulse)
                    .repeatForever(autoreverses: true)
                ) {
                    pulsePhase = 1
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {

    /// Apply aurora bloom effect
    public func auroraBloom(
        color: Color = Aurora.Colors.electricCyan,
        intensity: CGFloat = Aurora.GlowIntensity.standard,
        animated: Bool = false
    ) -> some View {
        AuroraBloom(color: color, intensity: intensity, animated: animated) {
            self
        }
    }

    /// Apply pulsing halo effect
    public func auroraHalo(
        color: Color = Aurora.Colors.electricCyan,
        radius: CGFloat = 20,
        animated: Bool = true
    ) -> some View {
        self.modifier(AuroraHaloModifier(color: color, radius: radius, animated: animated))
    }

    /// Apply inner glow effect
    public func auroraInnerGlow(
        color: Color = Aurora.Colors.electricCyan,
        radius: CGFloat = 8
    ) -> some View {
        self.modifier(AuroraInnerGlowModifier(color: color, radius: radius))
    }

    /// Apply completion bloom burst
    public func auroraCompletionBloom(
        isActive: Bool,
        color: Color = Aurora.Colors.prismaticGreen
    ) -> some View {
        self.modifier(AuroraCompletionBloomModifier(isActive: isActive, color: color))
    }

    /// Apply urgency glow
    public func auroraUrgencyGlow(
        level: UrgencyLevel
    ) -> some View {
        self.modifier(AuroraUrgencyGlowModifier(level: level))
    }
}

// MARK: - Urgency Level

public enum UrgencyLevel {
    case none
    case low       // > 4 hours
    case medium    // 1-4 hours
    case high      // < 1 hour
    case critical  // Overdue

    var color: Color {
        switch self {
        case .none: return .clear
        case .low: return Aurora.Colors.prismaticGreen
        case .medium: return Aurora.Colors.cosmicGold
        case .high: return Aurora.Colors.warning
        case .critical: return Aurora.Colors.error
        }
    }

    var pulseSpeed: Double {
        switch self {
        case .none: return 0
        case .low: return 3.0
        case .medium: return 2.0
        case .high: return 1.5
        case .critical: return 1.0
        }
    }

    var intensity: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 0.2
        case .medium: return 0.35
        case .high: return 0.5
        case .critical: return 0.7
        }
    }
}

// MARK: - Halo Modifier

struct AuroraHaloModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let animated: Bool

    @State private var glowIntensity: CGFloat = 0.3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowIntensity), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(glowIntensity * 0.5), radius: radius * 1.5, x: 0, y: 0)
            .onAppear {
                if animated && !reduceMotion {
                    withAnimation(
                        .easeInOut(duration: AuroraMotion.Duration.glowPulse)
                        .repeatForever(autoreverses: true)
                    ) {
                        glowIntensity = 0.6
                    }
                }
            }
    }
}

// MARK: - Inner Glow Modifier

struct AuroraInnerGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                content
                    .blur(radius: radius)
                    .blendMode(.overlay)
                    .opacity(0.3)
            )
            .overlay(
                content
                    .blur(radius: radius / 2)
                    .blendMode(.softLight)
                    .opacity(0.2)
            )
    }
}

// MARK: - Completion Bloom Modifier

struct AuroraCompletionBloomModifier: ViewModifier {
    let isActive: Bool
    let color: Color

    @State private var bloomScale: CGFloat = 1.0
    @State private var bloomOpacity: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack {
            // Bloom layers
            if isActive {
                content
                    .blur(radius: 30)
                    .scaleEffect(bloomScale)
                    .opacity(bloomOpacity)

                content
                    .blur(radius: 15)
                    .scaleEffect(bloomScale * 0.9)
                    .opacity(bloomOpacity * 1.2)
            }

            content
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerBloom()
            }
        }
    }

    private func triggerBloom() {
        // Burst
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bloomScale = 1.5
            bloomOpacity = 0.6
        }

        // Fade
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            bloomOpacity = 0
            bloomScale = 1.0
        }
    }
}

// MARK: - Urgency Glow Modifier

struct AuroraUrgencyGlowModifier: ViewModifier {
    let level: UrgencyLevel

    @State private var glowIntensity: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .shadow(
                color: level.color.opacity(glowIntensity),
                radius: 12,
                x: 0,
                y: 0
            )
            .shadow(
                color: level.color.opacity(glowIntensity * 0.5),
                radius: 20,
                x: 0,
                y: 4
            )
            .onAppear {
                startPulsing()
            }
            .onChange(of: level) { _, _ in
                startPulsing()
            }
    }

    private func startPulsing() {
        guard level != .none else {
            glowIntensity = 0
            return
        }

        guard !reduceMotion else {
            glowIntensity = level.intensity
            return
        }

        withAnimation(
            .easeInOut(duration: level.pulseSpeed)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = level.intensity
        }
    }
}

// MARK: - Anamorphic Lens Flare

/// Horizontal light streak effect (like anamorphic lens flare)
public struct AuroraLensFlare: View {

    let color: Color
    let width: CGFloat
    let intensity: CGFloat

    @State private var shimmerPhase: CGFloat = -1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        color: Color = Aurora.Colors.electricCyan,
        width: CGFloat = 200,
        intensity: CGFloat = 0.4
    ) {
        self.color = color
        self.width = width
        self.intensity = intensity
    }

    public var body: some View {
        ZStack {
            // Main horizontal streak
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            color.opacity(intensity * 0.3),
                            color.opacity(intensity),
                            color.opacity(intensity * 0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: 2)
                .blur(radius: 4)

            // Highlight
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Aurora.Colors.stellarWhite.opacity(intensity * 0.5),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width * 0.6, height: 1)

            // Shimmer
            if !reduceMotion {
                Capsule()
                    .fill(Aurora.Colors.stellarWhite.opacity(0.3))
                    .frame(width: 20, height: 3)
                    .blur(radius: 2)
                    .offset(x: shimmerPhase * (width / 2))
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerPhase = 1
                }
            }
        }
    }
}

// MARK: - Ripple Effect

/// Expanding ripple circles
public struct AuroraRipple: View {

    @Binding var isActive: Bool

    let color: Color
    let ringCount: Int

    @State private var ripples: [RippleState] = []

    public init(
        isActive: Binding<Bool>,
        color: Color = Aurora.Colors.electricCyan,
        ringCount: Int = 3
    ) {
        self._isActive = isActive
        self.color = color
        self.ringCount = ringCount
    }

    public var body: some View {
        ZStack {
            ForEach(ripples.indices, id: \.self) { index in
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(ripples[index].scale)
                    .opacity(ripples[index].opacity)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerRipple()
            }
        }
    }

    private func triggerRipple() {
        ripples = (0..<ringCount).map { _ in RippleState() }

        for i in 0..<ringCount {
            let delay = Double(i) * 0.15

            withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                ripples[i].scale = 2.5
            }

            withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                ripples[i].opacity = 0
            }
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ripples = []
            isActive = false
        }
    }
}

struct RippleState {
    var scale: CGFloat = 0.5
    var opacity: Double = 0.8
}

// MARK: - Preview

#Preview("Aurora Bloom Effects") {
    ZStack {
        Aurora.Colors.voidCosmos.ignoresSafeArea()

        VStack(spacing: 40) {
            // Static bloom
            Circle()
                .fill(Aurora.Colors.electricCyan)
                .frame(width: 60, height: 60)
                .auroraBloom(intensity: 0.5)

            // Animated bloom
            Circle()
                .fill(Aurora.Colors.stellarMagenta)
                .frame(width: 60, height: 60)
                .auroraBloom(animated: true)

            // Halo
            RoundedRectangle(cornerRadius: 12)
                .fill(Aurora.Colors.voidNebula)
                .frame(width: 120, height: 50)
                .auroraHalo(color: Aurora.Colors.borealisViolet)
                .overlay(Text("Halo").foregroundStyle(.white))

            // Lens flare
            AuroraLensFlare(color: Aurora.Colors.cosmicGold, width: 300)

            // Urgency levels
            HStack(spacing: 20) {
                ForEach([UrgencyLevel.low, .medium, .high, .critical], id: \.self) { level in
                    Circle()
                        .fill(Aurora.Colors.voidNebula)
                        .frame(width: 40, height: 40)
                        .auroraUrgencyGlow(level: level)
                }
            }
        }
    }
}
