//
//  PremiumGlowEffect.swift
//  Veloce
//
//  Premium Glow Effect System - Apple-Level Polish
//  Subtle gradient glow borders that feel premium and alive
//
//  Inspired by GPT-5 interface aesthetic: soft iridescent glow
//  that transitions from magenta/purple to cyan around elements
//

import SwiftUI

// MARK: - Premium Glow Style

/// Different glow style presets for various UI contexts
enum PremiumGlowStyle {
    /// Default iridescent: purple → cyan gradient (like GPT-5 input)
    case iridescent
    /// AI accent: nebula purple → electric blue
    case aiAccent
    /// Success: green → cyan
    case success
    /// Warm: orange → magenta
    case warm
    /// Focus: cyan → purple
    case focus
    /// Custom gradient colors
    case custom(colors: [Color])

    var gradientColors: [Color] {
        switch self {
        case .iridescent:
            return [
                Color(red: 0.75, green: 0.35, blue: 0.85),  // Soft magenta
                Color(red: 0.58, green: 0.25, blue: 0.98),  // Nebula purple
                Color(red: 0.35, green: 0.55, blue: 0.98),  // Electric blue
                Color(red: 0.25, green: 0.78, blue: 0.92),  // Plasma cyan
            ]
        case .aiAccent:
            return [
                Theme.Colors.aiPurple,
                Theme.Colors.aiBlue,
                Theme.Colors.aiCyan
            ]
        case .success:
            return [
                Theme.Colors.aiGreen,
                Theme.Colors.aiCyan
            ]
        case .warm:
            return [
                Theme.Colors.aiOrange,
                Theme.Colors.aiPink
            ]
        case .focus:
            return [
                Theme.Colors.aiCyan,
                Theme.Colors.aiPurple
            ]
        case .custom(let colors):
            return colors
        }
    }
}

// MARK: - Premium Glow Intensity

/// Controls how prominent the glow effect is
enum PremiumGlowIntensity {
    /// Very subtle - barely visible, ultra-premium
    case whisper
    /// Subtle - noticeable but refined
    case subtle
    /// Medium - clearly visible
    case medium
    /// Strong - prominent for emphasis
    case strong

    var glowOpacity: Double {
        switch self {
        case .whisper: return 0.15
        case .subtle: return 0.25
        case .medium: return 0.4
        case .strong: return 0.6
        }
    }

    var borderOpacity: Double {
        switch self {
        case .whisper: return 0.2
        case .subtle: return 0.35
        case .medium: return 0.5
        case .strong: return 0.7
        }
    }

    var blurRadius: CGFloat {
        switch self {
        case .whisper: return 8
        case .subtle: return 12
        case .medium: return 18
        case .strong: return 24
        }
    }
}

// MARK: - Premium Glow Modifier

/// Adds a premium gradient glow border effect to any view
struct PremiumGlowModifier<S: Shape>: ViewModifier {
    let shape: S
    let style: PremiumGlowStyle
    let intensity: PremiumGlowIntensity
    let animated: Bool
    let borderWidth: CGFloat

    @State private var gradientRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        shape: S,
        style: PremiumGlowStyle = .iridescent,
        intensity: PremiumGlowIntensity = .subtle,
        animated: Bool = true,
        borderWidth: CGFloat = 1.5
    ) {
        self.shape = shape
        self.style = style
        self.intensity = intensity
        self.animated = animated
        self.borderWidth = borderWidth
    }

    func body(content: Content) -> some View {
        content
            .background {
                // Outer glow layer (blurred)
                shape
                    .stroke(
                        AngularGradient(
                            colors: style.gradientColors + [style.gradientColors.first ?? .clear],
                            center: .center,
                            angle: .degrees(gradientRotation)
                        ),
                        lineWidth: borderWidth + 4
                    )
                    .blur(radius: intensity.blurRadius)
                    .opacity(intensity.glowOpacity)
                    .scaleEffect(pulseScale)
            }
            .overlay {
                // Sharp border layer
                shape
                    .stroke(
                        AngularGradient(
                            colors: style.gradientColors + [style.gradientColors.first ?? .clear],
                            center: .center,
                            angle: .degrees(gradientRotation)
                        ),
                        lineWidth: borderWidth
                    )
                    .opacity(intensity.borderOpacity)
            }
            .onAppear {
                guard animated && !reduceMotion else { return }

                // Slow rotation animation
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    gradientRotation = 360
                }

                // Subtle pulse
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    pulseScale = 1.03
                }
            }
    }
}

// MARK: - Linear Glow Modifier (for non-round shapes)

/// Linear gradient glow for rectangular/capsule shapes
struct LinearGlowModifier<S: Shape>: ViewModifier {
    let shape: S
    let style: PremiumGlowStyle
    let intensity: PremiumGlowIntensity
    let animated: Bool
    let borderWidth: CGFloat

    @State private var gradientOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        shape: S,
        style: PremiumGlowStyle = .iridescent,
        intensity: PremiumGlowIntensity = .subtle,
        animated: Bool = true,
        borderWidth: CGFloat = 1.5
    ) {
        self.shape = shape
        self.style = style
        self.intensity = intensity
        self.animated = animated
        self.borderWidth = borderWidth
    }

    func body(content: Content) -> some View {
        let animatedStartPoint = UnitPoint(x: gradientOffset, y: 0.5)
        let animatedEndPoint = UnitPoint(x: gradientOffset + 1, y: 0.5)

        content
            .background {
                // Outer glow layer (blurred)
                shape
                    .stroke(
                        LinearGradient(
                            colors: style.gradientColors,
                            startPoint: animatedStartPoint,
                            endPoint: animatedEndPoint
                        ),
                        lineWidth: borderWidth + 4
                    )
                    .blur(radius: intensity.blurRadius)
                    .opacity(intensity.glowOpacity)
                    .scaleEffect(pulseScale)
            }
            .overlay {
                // Sharp border layer
                shape
                    .stroke(
                        LinearGradient(
                            colors: style.gradientColors,
                            startPoint: animatedStartPoint,
                            endPoint: animatedEndPoint
                        ),
                        lineWidth: borderWidth
                    )
                    .opacity(intensity.borderOpacity)
            }
            .onAppear {
                guard animated && !reduceMotion else { return }

                // Slow sweep animation
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                    gradientOffset = -0.5
                }

                // Subtle pulse
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.02
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Add premium iridescent glow to any shape
    func premiumGlow<S: Shape>(
        shape: S,
        style: PremiumGlowStyle = .iridescent,
        intensity: PremiumGlowIntensity = .subtle,
        animated: Bool = true,
        borderWidth: CGFloat = 1.5
    ) -> some View {
        modifier(PremiumGlowModifier(
            shape: shape,
            style: style,
            intensity: intensity,
            animated: animated,
            borderWidth: borderWidth
        ))
    }

    /// Add premium linear glow (better for wide/rectangular shapes)
    func premiumLinearGlow<S: Shape>(
        shape: S,
        style: PremiumGlowStyle = .iridescent,
        intensity: PremiumGlowIntensity = .subtle,
        animated: Bool = true,
        borderWidth: CGFloat = 1.5
    ) -> some View {
        modifier(LinearGlowModifier(
            shape: shape,
            style: style,
            intensity: intensity,
            animated: animated,
            borderWidth: borderWidth
        ))
    }

    /// Convenience: Premium glow capsule
    func premiumGlowCapsule(
        style: PremiumGlowStyle = .iridescent,
        intensity: PremiumGlowIntensity = .subtle,
        animated: Bool = true
    ) -> some View {
        premiumLinearGlow(
            shape: Capsule(),
            style: style,
            intensity: intensity,
            animated: animated
        )
    }

    /// Convenience: Premium glow rounded rectangle
    func premiumGlowRoundedRect(
        cornerRadius: CGFloat = 16,
        style: PremiumGlowStyle = .iridescent,
        intensity: PremiumGlowIntensity = .subtle,
        animated: Bool = true
    ) -> some View {
        premiumGlow(
            shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
            style: style,
            intensity: intensity,
            animated: animated
        )
    }

    /// Convenience: Premium glow circle
    func premiumGlowCircle(
        style: PremiumGlowStyle = .iridescent,
        intensity: PremiumGlowIntensity = .subtle,
        animated: Bool = true
    ) -> some View {
        premiumGlow(
            shape: Circle(),
            style: style,
            intensity: intensity,
            animated: animated
        )
    }
}

// MARK: - Premium Glow Button Style

/// Button style that adds glow on press/hover
struct PremiumGlowButtonStyle: ButtonStyle {
    let style: PremiumGlowStyle
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(style: PremiumGlowStyle = .aiAccent, cornerRadius: CGFloat = 12) {
        self.style = style
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .premiumGlowRoundedRect(
                cornerRadius: cornerRadius,
                style: style,
                intensity: configuration.isPressed ? .medium : .whisper,
                animated: true
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == PremiumGlowButtonStyle {
    static var premiumGlow: PremiumGlowButtonStyle { PremiumGlowButtonStyle() }

    static func premiumGlow(
        style: PremiumGlowStyle,
        cornerRadius: CGFloat = 12
    ) -> PremiumGlowButtonStyle {
        PremiumGlowButtonStyle(style: style, cornerRadius: cornerRadius)
    }
}

// MARK: - Preview

#Preview("Premium Glow Effects") {
    ScrollView {
        VStack(spacing: 32) {
            // Input bar style
            Text("What's on your mind?")
                .dynamicTypeFont(base: 16, weight: .light)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background {
                    Capsule()
                        .fill(Color(.systemGray6).opacity(0.3))
                }
                .premiumGlowCapsule(intensity: .subtle)
                .padding(.horizontal, 20)

            // Button examples
            VStack(spacing: 16) {
                Text("Button Styles")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button("Focus Mode") {
                    print("Tapped")
                }
                .dynamicTypeFont(base: 15, weight: .medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(Theme.AdaptiveColors.aiGradient)
                }
                .premiumGlowCapsule(style: .aiAccent, intensity: .subtle)

                Button("Success Action") {
                    print("Tapped")
                }
                .dynamicTypeFont(base: 15, weight: .medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(Theme.AdaptiveColors.success)
                }
                .premiumGlowCapsule(style: .success, intensity: .subtle)
            }

            // Card example
            VStack(alignment: .leading, spacing: 8) {
                Text("Task Card")
                    .font(.headline)
                Text("This shows the glow on cards")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .premiumGlowRoundedRect(intensity: .whisper)
            .padding(.horizontal, 20)

            // Intensity comparison
            VStack(spacing: 16) {
                Text("Intensity Levels")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ForEach([
                    ("Whisper", PremiumGlowIntensity.whisper),
                    ("Subtle", PremiumGlowIntensity.subtle),
                    ("Medium", PremiumGlowIntensity.medium),
                    ("Strong", PremiumGlowIntensity.strong)
                ], id: \.0) { name, intensity in
                    Text(name)
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background {
                            Capsule()
                                .fill(Color(.tertiarySystemFill))
                        }
                        .premiumGlowCapsule(intensity: intensity)
                }
            }
        }
        .padding(.vertical, 32)
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
