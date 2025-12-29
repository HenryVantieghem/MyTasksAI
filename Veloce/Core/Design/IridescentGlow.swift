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
                    SwiftUI.Circle()
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
            SwiftUI.Circle()
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
            SwiftUI.Circle()
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
            SwiftUI.Circle()
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

// MARK: - Pulsing Glow Modifier (Iridescent version)
struct IridescentPulsingGlowModifier: ViewModifier {
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

    /// Apply pulsing glow (iridescent version)
    func iridescentPulsingGlow(
        color: Color = Theme.Colors.aiPurple,
        radius: CGFloat = 15
    ) -> some View {
        modifier(IridescentPulsingGlowModifier(color: color, radius: radius))
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
            SwiftUI.Circle()
                .stroke(
                    Theme.Colors.textSecondary.opacity(0.2),
                    lineWidth: lineWidth
                )

            // Progress ring
            SwiftUI.Circle()
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
                SwiftUI.Circle()
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

// MARK: - Micro-Interaction Modifiers

/// Press feedback with scale and haptics
struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false
    let scale: CGFloat
    let hapticStyle: HapticStyle

    enum HapticStyle {
        case none
        case light
        case medium
        case selection
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(Theme.Animation.quickSpring, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            triggerHaptic()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }

    private func triggerHaptic() {
        switch hapticStyle {
        case .none: break
        case .light: HapticsService.shared.lightImpact()
        case .medium: HapticsService.shared.impact()
        case .selection: HapticsService.shared.selectionFeedback()
        }
    }
}

extension View {
    /// Add press feedback with scale animation
    func pressEffect(
        scale: CGFloat = 0.96,
        haptic: PressEffectModifier.HapticStyle = .selection
    ) -> some View {
        modifier(PressEffectModifier(scale: scale, hapticStyle: haptic))
    }
}

/// Bounce entrance animation
struct BounceEntranceModifier: ViewModifier {
    @State private var appeared = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.6)
                    .delay(delay)
                ) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Add bounce entrance animation
    func bounceEntrance(delay: Double = 0) -> some View {
        modifier(BounceEntranceModifier(delay: delay))
    }
}

/// Slide up entrance animation
struct SlideUpEntranceModifier: ViewModifier {
    @State private var appeared = false
    let offset: CGFloat
    let delay: Double

    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : offset)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.75)
                    .delay(delay)
                ) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Add slide up entrance animation
    func slideUpEntrance(offset: CGFloat = 30, delay: Double = 0) -> some View {
        modifier(SlideUpEntranceModifier(offset: offset, delay: delay))
    }
}

/// Fade and scale entrance for staggered lists
struct StaggeredEntranceModifier: ViewModifier {
    @State private var appeared = false
    let index: Int
    let baseDelay: Double
    let staggerDelay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                let totalDelay = baseDelay + (Double(index) * staggerDelay)
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(totalDelay)
                ) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Add staggered entrance animation for list items
    func staggeredEntrance(
        index: Int,
        baseDelay: Double = 0.1,
        staggerDelay: Double = 0.05
    ) -> some View {
        modifier(StaggeredEntranceModifier(
            index: index,
            baseDelay: baseDelay,
            staggerDelay: staggerDelay
        ))
    }
}

/// Gentle float animation for background elements
struct FloatAnimationModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    let amplitude: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = amplitude
                }
            }
    }
}

extension View {
    /// Add gentle floating animation
    func floatAnimation(amplitude: CGFloat = 8, duration: Double = 3) -> some View {
        modifier(FloatAnimationModifier(amplitude: amplitude, duration: duration))
    }
}

/// Shake animation for errors or attention
struct ShakeAnimationModifier: ViewModifier {
    @Binding var trigger: Bool
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(shakeNumber: trigger ? 3 : 0, intensity: intensity))
            .animation(.spring(response: 0.2, dampingFraction: 0.3), value: trigger)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        trigger = false
                    }
                }
            }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakeNumber: CGFloat
    let intensity: CGFloat

    var animatableData: CGFloat {
        get { shakeNumber }
        set { shakeNumber = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            intensity * sin(shakeNumber * .pi * 2),
            y: 0
        ))
    }
}

extension View {
    /// Add shake animation triggered by binding
    func shakeAnimation(trigger: Binding<Bool>, intensity: CGFloat = 10) -> some View {
        modifier(ShakeAnimationModifier(trigger: trigger, intensity: intensity))
    }
}

/// Success check animation
struct SuccessCheckModifier: ViewModifier {
    @Binding var isShowing: Bool
    @State private var checkScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 1

    func body(content: Content) -> some View {
        content
            .overlay {
                if isShowing {
                    ZStack {
                        // Expanding ring
                        SwiftUI.Circle()
                            .stroke(Theme.Colors.success, lineWidth: 2)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)

                        // Check icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.Colors.success)
                            .scaleEffect(checkScale)
                    }
                    .onAppear {
                        HapticsService.shared.celebration()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                            checkScale = 1
                        }
                        withAnimation(.easeOut(duration: 0.6)) {
                            ringScale = 1.5
                            ringOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                checkScale = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isShowing = false
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    /// Add success check animation overlay
    func successCheck(isShowing: Binding<Bool>) -> some View {
        modifier(SuccessCheckModifier(isShowing: isShowing))
    }
}

/// Ripple effect on tap
struct RippleEffectModifier: ViewModifier {
    @State private var ripples: [RippleState] = []
    let color: Color

    struct RippleState: Identifiable {
        let id = UUID()
        let position: CGPoint
        var scale: CGFloat = 0
        var opacity: Double = 0.5
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    ForEach(ripples) { ripple in
                        SwiftUI.Circle()
                            .fill(color.opacity(ripple.opacity))
                            .frame(width: 40, height: 40)
                            .scaleEffect(ripple.scale)
                            .position(ripple.position)
                    }
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                addRipple(at: location)
            }
    }

    private func addRipple(at position: CGPoint) {
        let ripple = RippleState(position: position)
        ripples.append(ripple)

        withAnimation(.easeOut(duration: 0.5)) {
            if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                ripples[index].scale = 4
                ripples[index].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

extension View {
    /// Add ripple effect on tap
    func rippleEffect(color: Color = Theme.Colors.accent.opacity(0.3)) -> some View {
        modifier(RippleEffectModifier(color: color))
    }
}

/// Breathing animation for AI elements
struct BreathingGlowModifier: ViewModifier {
    @State private var intensity: Double = 0.3
    let color: Color
    let minIntensity: Double
    let maxIntensity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity), radius: 15)
            .shadow(color: color.opacity(intensity * 0.5), radius: 25)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    intensity = maxIntensity
                }
            }
    }
}

extension View {
    /// Add breathing glow animation for AI elements
    func breathingGlow(
        color: Color = Theme.Colors.aiPurple,
        min: Double = 0.2,
        max: Double = 0.6
    ) -> some View {
        modifier(BreathingGlowModifier(
            color: color,
            minIntensity: min,
            maxIntensity: max
        ))
    }
}
