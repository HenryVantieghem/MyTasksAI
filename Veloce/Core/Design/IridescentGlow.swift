//
//  IridescentGlow.swift
//  MyTasksAI
//
//  Iridescent and Glow Effects
//  AI-inspired visual effects for task app
//

import SwiftUI

// MARK: - Iridescent Background
struct IridescentBackground: View {
    let intensity: Double

    init(intensity: Double = 0.5) {
        self.intensity = intensity
    }

    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                Theme.Colors.background

                // Animated iridescent layers
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: iridescentColors(for: index),
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.8
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(1.5 - Double(index) * 0.3),
                            height: geometry.size.width * CGFloat(1.5 - Double(index) * 0.3)
                        )
                        .offset(
                            x: cos(phase + Double(index) * .pi / 1.5) * 50,
                            y: sin(phase + Double(index) * .pi / 1.5) * 50
                        )
                        .blur(radius: DesignTokens.Blur.iridescentGlow)
                        .opacity(intensity * 0.3)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(Theme.Animation.iridescentRotation) {
                phase = .pi * 2
            }
        }
    }

    private func iridescentColors(for index: Int) -> [Color] {
        switch index {
        case 0: return [Theme.Colors.aiPurple, Theme.Colors.aiBlue.opacity(0)]
        case 1: return [Theme.Colors.aiCyan, Theme.Colors.aiPink.opacity(0)]
        default: return [Theme.Colors.aiBlue, Theme.Colors.aiPurple.opacity(0)]
        }
    }
}

// MARK: - Iridescent Orb
struct IridescentOrb: View {
    let size: CGFloat
    var animated: Bool = true

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Theme.Colors.aiPurple,
                            Theme.Colors.aiBlue,
                            Theme.Colors.aiCyan,
                            Theme.Colors.aiPink,
                            Theme.Colors.aiPurple
                        ],
                        center: .center,
                        angle: .degrees(rotation)
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.3)
                .opacity(0.6)

            // Inner orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.9),
                            Theme.Colors.aiPurple.opacity(0.8),
                            Theme.Colors.aiBlue.opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)

            // Highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.8), .clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.3
                    )
                )
                .frame(width: size * 0.6, height: size * 0.6)
                .offset(x: -size * 0.15, y: -size * 0.15)
        }
        .onAppear {
            if animated {
                withAnimation(Theme.Animation.iridescentRotation) {
                    rotation = 360
                }
            }
        }
    }
}

// MARK: - Glow Effect Modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(opacity), radius: radius)
            .shadow(color: color.opacity(opacity * 0.5), radius: radius * 2)
    }
}

// MARK: - Pulsing Glow Modifier
struct PulsingGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isPulsing ? 0.6 : 0.3),
                radius: isPulsing ? radius * 1.5 : radius
            )
            .onAppear {
                withAnimation(Theme.Animation.aiPulse) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Glow Shimmer Effect
struct GlowShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    let gradient: Gradient

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 3)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(Theme.Animation.aiShimmer) {
                    phase = 1
                }
            }
    }
}

// MARK: - AI Glow Effect
struct AIGlowModifier: ViewModifier {
    @State private var glowIntensity: Double = 0.5

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Theme.Colors.aiPurple.opacity(glowIntensity * 0.6),
                radius: 15
            )
            .shadow(
                color: Theme.Colors.aiBlue.opacity(glowIntensity * 0.4),
                radius: 25
            )
            .onAppear {
                withAnimation(Theme.Animation.aiPulse) {
                    glowIntensity = 1.0
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Apply glow effect
    func glow(
        color: Color = Theme.Colors.accent,
        radius: CGFloat = 10,
        opacity: Double = 0.5
    ) -> some View {
        modifier(GlowModifier(color: color, radius: radius, opacity: opacity))
    }

    /// Apply pulsing glow
    func pulsingGlow(
        color: Color = Theme.Colors.aiPurple,
        radius: CGFloat = 15
    ) -> some View {
        modifier(PulsingGlowModifier(color: color, radius: radius))
    }

    /// Apply shimmer glow effect
    func shimmerGlow() -> some View {
        modifier(GlowShimmerModifier(
            gradient: Gradient(colors: [
                .clear,
                .white.opacity(0.5),
                .clear
            ])
        ))
    }

    /// Apply AI glow effect
    func aiGlow() -> some View {
        modifier(AIGlowModifier())
    }
}

// MARK: - Animated Gradient Border
struct AnimatedGradientBorder: View {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat

    @State private var rotation: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                AngularGradient(
                    colors: [
                        Theme.Colors.aiPurple,
                        Theme.Colors.aiBlue,
                        Theme.Colors.aiCyan,
                        Theme.Colors.aiPink,
                        Theme.Colors.aiPurple
                    ],
                    center: .center,
                    angle: .degrees(rotation)
                ),
                lineWidth: lineWidth
            )
            .onAppear {
                withAnimation(Theme.Animation.iridescentRotation) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Iridescent Background Modifier
struct IridescentBackgroundModifier: ViewModifier {
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .background {
                IridescentBackground(intensity: intensity)
            }
    }
}

extension View {
    /// Apply iridescent background
    func iridescentBackground(intensity: Double = 0.5) -> some View {
        modifier(IridescentBackgroundModifier(intensity: intensity))
    }
}

// MARK: - Glowing Progress Ring
struct GlowingProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    var showGlow: Bool = true

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Theme.Colors.textSecondary.opacity(0.2),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Theme.Colors.accentGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            // Glow
            if showGlow && progress > 0 {
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        Theme.Colors.accent,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 8)
                    .opacity(0.5)
            }
        }
        .frame(width: size, height: size)
        .animation(Theme.Animation.spring, value: progress)
    }
}
