//
//  GlassModifiers.swift
//  MyTasksAI
//
//  Glass Morphism View Modifiers
//  Modern frosted glass effects for iOS
//

import SwiftUI

// MARK: - Living Cosmos Dark Theme Only
// All adaptive modifiers now use dark mode values directly since
// the app enforces .preferredColorScheme(.dark) universally

extension View {
    /// Apply opacity (uses dark mode value directly)
    func adaptiveOpacity(light: Double, dark: Double) -> some View {
        self.opacity(dark)
    }

    /// Apply shadow (uses dark mode values directly)
    func adaptiveShadow(
        lightColor: Color = .black.opacity(0.1),
        darkColor: Color = .black.opacity(0.3),
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        self.shadow(
            color: darkColor,
            radius: radius * 1.5,
            x: x,
            y: y
        )
    }
}

// MARK: - iOS 26 Native Liquid Glass Extensions
// NOTE: Main iOS 26 glass extensions are in LiquidGlassDesignSystem.swift
// This file only contains legacy compatibility modifiers

// MARK: - Legacy Glass Effect Modifier (Pre-iOS 26 Compatibility)
/// Uses ultraThinMaterial for backwards compatibility
struct GlassEffectModifier: ViewModifier {
    let cornerRadius: CGFloat
    let opacity: Double
    let borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            )
    }
}

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.2),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            }
            .themeShadow(Theme.Shadow.smDark)
    }
}

// MARK: - Glass Button Modifier
struct GlassButtonModifier: ViewModifier {
    let isPressed: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.2),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            }
            .shadow(
                color: .black.opacity(0.3),
                radius: 6,
                x: 0,
                y: 2
            )
            .scaleEffect(isPressed ? DesignTokens.Scale.pressed : 1)
            .opacity(isPressed ? DesignTokens.Opacity.pressed : 1)
    }
}

// MARK: - Glass TextField Style
struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Theme.Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.textField))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.textField)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(0.2),
                radius: 3,
                x: 0,
                y: 1
            )
    }
}

// MARK: - Floating Glass Modifier
struct FloatingGlassModifier: ViewModifier {
    @State private var isHovering = false

    let elevation: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(0.4),
                radius: elevation * 1.5,
                x: 0,
                y: elevation * 0.75
            )
    }
}

// MARK: - View Extensions
extension View {
    /// Apply legacy glass effect (ultraThinMaterial-based)
    /// For iOS 26+, prefer using native .glassEffect() or .liquidGlassCard()
    func legacyGlassEffect(
        cornerRadius: CGFloat = Theme.CornerRadius.card,
        opacity: Double = DesignTokens.Opacity.glassBackground,
        borderWidth: CGFloat = DesignTokens.BorderWidth.glassBorder
    ) -> some View {
        modifier(GlassEffectModifier(
            cornerRadius: cornerRadius,
            opacity: opacity,
            borderWidth: borderWidth
        ))
    }

    /// Apply glass card style
    func glassCard(
        padding: CGFloat = Theme.Spacing.cardPadding,
        cornerRadius: CGFloat = Theme.CornerRadius.card
    ) -> some View {
        modifier(GlassCardModifier(
            padding: padding,
            cornerRadius: cornerRadius
        ))
    }

    /// Apply glass button style
    func glassButton(
        isPressed: Bool = false,
        cornerRadius: CGFloat = Theme.CornerRadius.button
    ) -> some View {
        modifier(GlassButtonModifier(
            isPressed: isPressed,
            cornerRadius: cornerRadius
        ))
    }

    /// Apply floating glass style
    func floatingGlass(elevation: CGFloat = 8) -> some View {
        modifier(FloatingGlassModifier(elevation: elevation))
    }
}

// MARK: - Glass Pill Button Style
struct GlassPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.subheadline)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(0.25),
                radius: 4,
                x: 0,
                y: 1
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassPillButtonStyle {
    static var glassPill: GlassPillButtonStyle { GlassPillButtonStyle() }
}

// MARK: - Pressable Button Style
/// Standard press feedback style for interactive elements
/// Provides subtle scale effect with spring animation
struct PressableButtonStyle: ButtonStyle {
    let scale: CGFloat

    init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.pressSpring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }

    static func pressable(scale: CGFloat) -> PressableButtonStyle {
        PressableButtonStyle(scale: scale)
    }
}

// MARK: - Glass Segmented Control Style
struct GlassSegmentedStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .pickerStyle(.segmented)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }
}

extension View {
    func glassSegmented() -> some View {
        modifier(GlassSegmentedStyle())
    }
}

// MARK: - Glass Sheet Background
struct GlassSheetBackground: View {
    var body: some View {
        ZStack {
            // Base blur
            Rectangle()
                .fill(.ultraThinMaterial)

            // Gradient overlay
            LinearGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.05),
                    Theme.Colors.aiBlue.opacity(0.03),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Border highlight
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass Navigation Bar Style
struct GlassNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.hidden, for: .navigationBar)
            .background {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: 100)
                    Spacer()
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func glassNavigationBar() -> some View {
        modifier(GlassNavigationBarModifier())
    }
}

// MARK: - Tinted Liquid Glass Modifier (iOS 26 Style with Color Tint)
/// Renamed to avoid conflict with LiquidGlassModifier in LiquidGlassHelper.swift
struct TintedLiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if let tint = tint {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(tint.opacity(0.1))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// Apply tinted liquid glass effect (iOS 26 style with optional color tint)
    func tintedLiquidGlass(
        cornerRadius: CGFloat = Theme.CornerRadius.lg,
        tint: Color? = nil
    ) -> some View {
        modifier(TintedLiquidGlassModifier(cornerRadius: cornerRadius, tint: tint))
    }
}

// MARK: - Premium Glass Card Modifier
/// Enhanced glass effect with deeper blur, iridescent border, and stronger shadows
struct PremiumGlassCardModifier: ViewModifier {
    @State private var borderPhase: CGFloat = 0

    let cornerRadius: CGFloat
    let animateBorder: Bool
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base blur layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Subtle gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (tint ?? Theme.Colors.aiPurple).opacity(0.08),
                                    (tint ?? Theme.Colors.aiBlue).opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Inner highlight for glass depth
                    RoundedRectangle(cornerRadius: cornerRadius - 1)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.08),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                        .padding(1)
                }
            }
            .overlay {
                // Iridescent animated border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        animateBorder ?
                        AnyShapeStyle(
                            AngularGradient(
                                colors: [
                                    Theme.Colors.aiPurple.opacity(0.6),
                                    Theme.Colors.aiBlue.opacity(0.5),
                                    Theme.Colors.aiCyan.opacity(0.4),
                                    Theme.Colors.aiPink.opacity(0.5),
                                    Theme.Colors.aiPurple.opacity(0.6)
                                ],
                                center: .center,
                                angle: .degrees(borderPhase)
                            )
                        ) :
                        AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25),
                                    .white.opacity(0.08),
                                    (tint ?? Theme.Colors.aiPurple).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ),
                        lineWidth: animateBorder ? 1.5 : 0.5
                    )
            }
            // Multi-layer shadow for depth
            .shadow(color: (tint ?? Theme.Colors.aiPurple).opacity(0.15), radius: 20, x: 0, y: 8)
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
            .onAppear {
                if animateBorder {
                    withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                        borderPhase = 360
                    }
                }
            }
    }
}

extension View {
    /// Apply premium glass card effect with enhanced visuals
    func premiumGlassCard(
        cornerRadius: CGFloat = Theme.CornerRadius.xl,
        animateBorder: Bool = false,
        tint: Color? = nil
    ) -> some View {
        modifier(PremiumGlassCardModifier(
            cornerRadius: cornerRadius,
            animateBorder: animateBorder,
            tint: tint
        ))
    }
}

// MARK: - Frosted Glass Modifier
/// Deep frosted glass effect with subtle inner glow
struct FrostedGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: FrostedGlassIntensity

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Deep blur
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(intensity.material)

                    // Noise texture simulation (subtle gradient)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.03),
                                    .clear,
                                    .white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: .black.opacity(0.35),
                radius: 16,
                x: 0,
                y: 8
            )
    }
}

enum FrostedGlassIntensity {
    case light
    case regular
    case thick

    var material: Material {
        switch self {
        case .light: return .ultraThinMaterial
        case .regular: return .thinMaterial
        case .thick: return .regularMaterial
        }
    }
}

extension View {
    /// Apply frosted glass effect with customizable intensity
    func frostedGlass(
        cornerRadius: CGFloat = Theme.CornerRadius.lg,
        intensity: FrostedGlassIntensity = .regular
    ) -> some View {
        modifier(FrostedGlassModifier(cornerRadius: cornerRadius, intensity: intensity))
    }
}

// MARK: - Glass Glow Modifier
/// Glass effect with colored glow halo
struct GlassGlowModifier: ViewModifier {
    @State private var glowPulse: CGFloat = 1.0

    let cornerRadius: CGFloat
    let glowColor: Color
    let animated: Bool

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: cornerRadius + 4)
                        .fill(glowColor.opacity(0.2))
                        .blur(radius: 12)
                        .scaleEffect(glowPulse)

                    // Base glass
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Tinted overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(glowColor.opacity(0.08))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                glowColor.opacity(0.5),
                                glowColor.opacity(0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: glowColor.opacity(0.3), radius: 16, x: 0, y: 6)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .onAppear {
                if animated {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        glowPulse = 1.08
                    }
                }
            }
    }
}

extension View {
    /// Apply glass effect with colored glow halo
    func glassGlow(
        cornerRadius: CGFloat = Theme.CornerRadius.lg,
        color: Color = Theme.Colors.accent,
        animated: Bool = false
    ) -> some View {
        modifier(GlassGlowModifier(
            cornerRadius: cornerRadius,
            glowColor: color,
            animated: animated
        ))
    }
}

// MARK: - Celestial Glass (Unified Glass System)
/// A unified glass modifier using CelestialColors for consistent styling across the app
/// This replaces the need for multiple glass modifiers with inconsistent opacities

/// Style variants for CelestialGlass
enum CelestialGlassStyle {
    case card          // Standard content card
    case floating      // Elevated with extra shadow
    case button        // Interactive with press states
    case input         // Text field styling
    case premium       // Animated iridescent border
    case tabBar        // Tab bar specific styling
}

/// Tint variants for CelestialGlass
enum CelestialGlassTint {
    case neutral       // Subtle nebula shift
    case nebula        // Purple-cyan gradient tint
    case success       // Green tint
    case warning       // Orange tint
    case error         // Red tint

    var color: Color {
        switch self {
        case .neutral: return Theme.CelestialColors.nebulaCore
        case .nebula: return Theme.CelestialColors.nebulaCore
        case .success: return Theme.CelestialColors.successNebula
        case .warning: return Theme.CelestialColors.warningNebula
        case .error: return Theme.CelestialColors.errorNebula
        }
    }

    var secondaryColor: Color {
        switch self {
        case .neutral: return Theme.CelestialColors.nebulaEdge
        case .nebula: return Theme.CelestialColors.nebulaEdge
        case .success: return Theme.CelestialColors.successNebula.opacity(0.7)
        case .warning: return Theme.CelestialColors.warningNebula.opacity(0.7)
        case .error: return Theme.CelestialColors.errorNebula.opacity(0.7)
        }
    }
}

/// Unified glass modifier for the Celestial Void design system
struct CelestialGlassModifier: ViewModifier {
    let style: CelestialGlassStyle
    let tint: CelestialGlassTint
    let cornerRadius: CGFloat
    let isPressed: Bool
    let isFocused: Bool

    @State private var borderPhase: CGFloat = 0

    init(
        style: CelestialGlassStyle = .card,
        tint: CelestialGlassTint = .neutral,
        cornerRadius: CGFloat? = nil,
        isPressed: Bool = false,
        isFocused: Bool = false
    ) {
        self.style = style
        self.tint = tint
        self.cornerRadius = cornerRadius ?? Self.defaultCornerRadius(for: style)
        self.isPressed = isPressed
        self.isFocused = isFocused
    }

    private static func defaultCornerRadius(for style: CelestialGlassStyle) -> CGFloat {
        switch style {
        case .card: return Theme.CornerRadius.xl
        case .floating: return Theme.CornerRadius.xl
        case .button: return Theme.CornerRadius.lg
        case .input: return Theme.CornerRadius.xl
        case .premium: return Theme.CornerRadius.xl
        case .tabBar: return 28
        }
    }

    private var borderOpacity: Double {
        if isFocused {
            return Theme.CelestialColors.glassBorderFocusedOpacity
        }
        return Theme.CelestialColors.glassBorderOpacity
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .card: return 12
        case .floating: return 20
        case .button: return 8
        case .input: return 6
        case .premium: return 24
        case .tabBar: return 20
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .card: return 4
        case .floating: return 10
        case .button: return 2
        case .input: return 2
        case .premium: return 8
        case .tabBar: return 10
        }
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base glass material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Subtle tint overlay
                    if style == .premium || tint != .neutral {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.color.opacity(0.08),
                                        tint.secondaryColor.opacity(0.04),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .overlay {
                // Border based on style
                if style == .premium {
                    // Animated iridescent border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    Theme.CelestialColors.nebulaCore.opacity(0.6),
                                    Theme.CelestialColors.nebulaGlow.opacity(0.5),
                                    Theme.CelestialColors.nebulaEdge.opacity(0.4),
                                    Theme.CelestialColors.nebulaCore.opacity(0.6)
                                ],
                                center: .center,
                                angle: .degrees(borderPhase)
                            ),
                            lineWidth: 1.5
                        )
                } else {
                    // Standard gradient border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            Theme.CelestialColors.glassBorder(opacity: borderOpacity),
                            lineWidth: isFocused ? 1.5 : 1
                        )
                }
            }
            // Glow shadow
            .shadow(
                color: tint.color.opacity(style == .premium ? 0.25 : 0.15),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            // Depth shadow
            .shadow(
                color: Color.black.opacity(0.25),
                radius: shadowRadius / 2,
                x: 0,
                y: shadowY / 2
            )
            // Press effect for buttons
            .scaleEffect(isPressed ? 0.97 : 1)
            .opacity(isPressed ? 0.9 : 1)
            .animation(Theme.Animation.fast, value: isPressed)
            .animation(Theme.Animation.fast, value: isFocused)
            .onAppear {
                if style == .premium {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        borderPhase = 360
                    }
                }
            }
    }
}

extension View {
    /// Apply unified Celestial Glass effect
    /// - Parameters:
    ///   - style: The glass style variant
    ///   - tint: The color tint for the glass
    ///   - cornerRadius: Optional custom corner radius
    ///   - isPressed: Whether the element is pressed (for buttons)
    ///   - isFocused: Whether the element is focused (for inputs)
    func celestialGlass(
        _ style: CelestialGlassStyle = .card,
        tint: CelestialGlassTint = .neutral,
        cornerRadius: CGFloat? = nil,
        isPressed: Bool = false,
        isFocused: Bool = false
    ) -> some View {
        modifier(CelestialGlassModifier(
            style: style,
            tint: tint,
            cornerRadius: cornerRadius,
            isPressed: isPressed,
            isFocused: isFocused
        ))
    }
}

// MARK: - Celestial Glass Button Style
/// Button style using CelestialGlass for consistent styling
struct CelestialGlassButtonStyle: ButtonStyle {
    let tint: CelestialGlassTint
    let cornerRadius: CGFloat

    init(tint: CelestialGlassTint = .neutral, cornerRadius: CGFloat = Theme.CornerRadius.lg) {
        self.tint = tint
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .celestialGlass(.button, tint: tint, cornerRadius: cornerRadius, isPressed: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CelestialGlassButtonStyle {
    static var celestialGlass: CelestialGlassButtonStyle { CelestialGlassButtonStyle() }

    static func celestialGlass(tint: CelestialGlassTint) -> CelestialGlassButtonStyle {
        CelestialGlassButtonStyle(tint: tint)
    }
}

// MARK: - Living Cosmos: Morphic Glass System
/// Advanced glass effects for the Living Cosmos task card redesign
/// Features: shape morphing, refraction effects, multi-layer depth, organic breathing

// MARK: - Morphic Glass Modifier
/// Glass container that subtly morphs on interaction with organic breathing
struct MorphicGlassModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let cornerRadius: CGFloat
    let taskTypeColor: Color
    let isPressed: Bool
    let isHighPriority: Bool

    @State private var breathePhase: CGFloat = 0
    @State private var morphOffset: CGSize = .zero

    // Morphing intensity
    private var morphScale: CGFloat {
        if isPressed {
            return 0.97  // Sink into void
        }
        if isHighPriority && !reduceMotion {
            return 1.0 + (breathePhase * 0.008)  // Subtle breathing
        }
        return 1.0
    }

    private var innerGlowIntensity: Double {
        if isPressed {
            return 0.25  // Intensify on press
        }
        if isHighPriority {
            return 0.12 + (Double(breathePhase) * 0.08)
        }
        return 0.08
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Layer 1: Deep void shadow (creates depth)
                    RoundedRectangle(cornerRadius: cornerRadius + 2)
                        .fill(Theme.CelestialColors.voidDeep)
                        .offset(y: isPressed ? 1 : 3)
                        .blur(radius: isPressed ? 2 : 4)

                    // Layer 2: Base glass material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Layer 3: Task type nebula tint
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [
                                    taskTypeColor.opacity(innerGlowIntensity),
                                    taskTypeColor.opacity(innerGlowIntensity * 0.3),
                                    Color.clear
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )

                    // Layer 4: Inner light (glass depth illusion)
                    RoundedRectangle(cornerRadius: cornerRadius - 1)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.15),
                                    .white.opacity(0.05),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                        .padding(1)
                }
            }
            // Refraction border (prismatic edge)
            .overlay {
                MorphicRefractionBorder(
                    cornerRadius: cornerRadius,
                    taskTypeColor: taskTypeColor,
                    isPressed: isPressed
                )
            }
            // Multi-layer shadow system
            .shadow(
                color: taskTypeColor.opacity(isPressed ? 0.3 : 0.2),
                radius: isPressed ? 8 : 16,
                x: 0,
                y: isPressed ? 2 : 6
            )
            .shadow(
                color: Color.black.opacity(isPressed ? 0.4 : 0.25),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 1 : 3
            )
            // Morphing transforms
            .scaleEffect(morphScale)
            .animation(Theme.Animation.stellarBounce, value: isPressed)
            .onAppear {
                if isHighPriority && !reduceMotion {
                    withAnimation(Theme.Animation.plasmaPulse) {
                        breathePhase = 1
                    }
                }
            }
    }
}

// MARK: - Morphic Refraction Border
/// Creates prismatic light-splitting effect on glass edges
struct MorphicRefractionBorder: View {
    let cornerRadius: CGFloat
    let taskTypeColor: Color
    let isPressed: Bool

    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Base border gradient
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            taskTypeColor.opacity(0.4),
                            Theme.CelestialColors.nebulaEdge.opacity(0.3),
                            .white.opacity(0.15),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isPressed ? 2 : 1.5
                )

            // Traveling shimmer highlight (refraction simulation)
            if !reduceMotion {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                .clear,
                                .clear,
                                .white.opacity(0.4),
                                Theme.CelestialColors.plasmaCore.opacity(0.3),
                                .white.opacity(0.3),
                                .clear,
                                .clear,
                                .clear
                            ],
                            center: .center,
                            angle: .degrees(shimmerPhase)
                        ),
                        lineWidth: 1
                    )
                    .onAppear {
                        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                            shimmerPhase = 360
                        }
                    }
            }
        }
    }
}

// MARK: - Plasma Core Glow
/// Animated glow effect for energy core visualization
struct PlasmaGlowModifier: ViewModifier {
    let color: Color
    let intensity: Double  // 0-1
    let isAnimated: Bool

    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var glowRadius: CGFloat {
        let base: CGFloat = 8 + (CGFloat(intensity) * 12)
        if isAnimated && !reduceMotion {
            return base + (pulsePhase * 4)
        }
        return base
    }

    private var glowOpacity: Double {
        let base = 0.3 + (intensity * 0.4)
        if isAnimated && !reduceMotion {
            return base + (Double(pulsePhase) * 0.15)
        }
        return base
    }

    func body(content: Content) -> some View {
        content
            .background {
                SwiftUI.Circle()
                    .fill(color.opacity(glowOpacity))
                    .blur(radius: glowRadius)
                    .scaleEffect(1.5 + (pulsePhase * 0.2))
            }
            .onAppear {
                if isAnimated && !reduceMotion {
                    withAnimation(Theme.Animation.plasmaPulse) {
                        pulsePhase = 1
                    }
                }
            }
    }
}

// MARK: - Supernova Burst Effect
/// Explosive particle burst for completion celebrations
struct SupernovaBurstModifier: ViewModifier {
    let isTriggered: Bool
    let color: Color
    let particleCount: Int

    @State private var particles: [GlassSupernovaParticle] = []
    @State private var burstScale: CGFloat = 0
    @State private var burstOpacity: Double = 1

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    // Central flash
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white,
                                    color.opacity(0.8),
                                    color.opacity(0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .scaleEffect(burstScale)
                        .opacity(burstOpacity)

                    // Particles
                    ForEach(particles) { particle in
                        SwiftUI.Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.offset.width, y: particle.offset.height)
                            .opacity(particle.opacity)
                            .blur(radius: particle.blur)
                    }
                }
            }
            .onChange(of: isTriggered) { _, triggered in
                if triggered {
                    triggerSupernova()
                }
            }
    }

    private func triggerSupernova() {
        // Flash burst
        withAnimation(Theme.Animation.supernovaBurst) {
            burstScale = 2
            burstOpacity = 0.8
        }

        // Fade flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                burstOpacity = 0
            }
        }

        // Generate particles
        let colors: [Color] = [
            .white,
            color,
            Theme.CelestialColors.plasmaCore,
            Theme.CelestialColors.auroraGreen,
            Theme.CelestialColors.solarFlare
        ]

        for i in 0..<particleCount {
            let angle = Double(i) * (2 * .pi / Double(particleCount))
            let distance = CGFloat.random(in: 50...120)
            let particle = GlassSupernovaParticle(
                id: UUID(),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 3...8),
                offset: .zero,
                targetOffset: CGSize(
                    width: CGFloat(Darwin.cos(Double(angle))) * distance,
                    height: CGFloat(Darwin.sin(Double(angle))) * distance
                ),
                opacity: 1,
                blur: CGFloat.random(in: 0...2)
            )
            particles.append(particle)

            // Animate particle outward
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].offset = particle.targetOffset
                }
            }

            // Fade particle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                        particles[index].opacity = 0
                    }
                }
            }
        }

        // Clear particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles.removeAll()
            burstScale = 0
        }
    }
}

struct GlassSupernovaParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var offset: CGSize
    let targetOffset: CGSize
    var opacity: Double
    let blur: CGFloat
}

// MARK: - Urgency Glow Modifier
/// Time-based glow that shifts from calm cyan to critical red
struct UrgencyGlowModifier: ViewModifier {
    let urgencyLevel: GlassUrgencyLevel  // 0 = calm, 1 = near, 2 = critical
    let isAnimated: Bool

    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum GlassUrgencyLevel {
        case calm
        case near
        case critical
        case overdue

        var color: Color {
            switch self {
            case .calm: return Theme.CelestialColors.urgencyCalm
            case .near: return Theme.CelestialColors.urgencyNear
            case .critical, .overdue: return Theme.CelestialColors.urgencyCritical
            }
        }

        var pulseSpeed: Double {
            switch self {
            case .calm: return 3.0
            case .near: return 2.0
            case .critical: return 1.2
            case .overdue: return 0.8
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        urgencyLevel.color.opacity(0.3 + (Double(pulsePhase) * 0.3)),
                        lineWidth: 2
                    )
                    .blur(radius: 4 + (pulsePhase * 2))
                    .opacity(urgencyLevel == .calm ? 0 : 1)
            }
            .shadow(
                color: urgencyLevel.color.opacity(0.2 + (Double(pulsePhase) * 0.2)),
                radius: 12 + (pulsePhase * 4),
                x: 0,
                y: 4
            )
            .onAppear {
                if isAnimated && !reduceMotion && urgencyLevel != .calm {
                    withAnimation(
                        .easeInOut(duration: urgencyLevel.pulseSpeed)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulsePhase = 1
                    }
                }
            }
    }
}

// MARK: - View Extensions for Living Cosmos

extension View {
    /// Apply morphic glass effect (Living Cosmos task cards)
    func morphicGlass(
        cornerRadius: CGFloat = 18,
        taskTypeColor: Color = Theme.CelestialColors.nebulaCore,
        isPressed: Bool = false,
        isHighPriority: Bool = false
    ) -> some View {
        modifier(MorphicGlassModifier(
            cornerRadius: cornerRadius,
            taskTypeColor: taskTypeColor,
            isPressed: isPressed,
            isHighPriority: isHighPriority
        ))
    }

    /// Apply plasma core glow effect
    func plasmaGlow(
        color: Color = Theme.CelestialColors.plasmaCore,
        intensity: Double = 0.5,
        isAnimated: Bool = true
    ) -> some View {
        modifier(PlasmaGlowModifier(
            color: color,
            intensity: intensity,
            isAnimated: isAnimated
        ))
    }

    /// Apply supernova burst effect on trigger
    func supernovaBurst(
        isTriggered: Bool,
        color: Color = Theme.CelestialColors.auroraGreen,
        particleCount: Int = 24
    ) -> some View {
        modifier(SupernovaBurstModifier(
            isTriggered: isTriggered,
            color: color,
            particleCount: particleCount
        ))
    }

    /// Apply urgency glow based on deadline proximity
    func urgencyGlow(
        level: UrgencyGlowModifier.UrgencyLevel,
        isAnimated: Bool = true
    ) -> some View {
        modifier(UrgencyGlowModifier(
            urgencyLevel: level,
            isAnimated: isAnimated
        ))
    }
}

// MARK: - Floating Island Modifier
/// Creates floating glass island effect for expanded card sections
struct FloatingIslandModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let depth: CGFloat  // 0 = background, 1 = foreground
    let floatPhase: CGFloat  // 0-1 for staggered animation

    @State private var floatOffset: CGFloat = 0

    private var baseOffset: CGFloat {
        if reduceMotion { return 0 }
        return sin(floatPhase * .pi * 2) * 3  // Subtle 3pt float
    }

    private var shadowIntensity: Double {
        0.15 + (Double(depth) * 0.1)
    }

    func body(content: Content) -> some View {
        content
            .offset(y: floatOffset + baseOffset)
            .shadow(
                color: Theme.CelestialColors.nebulaCore.opacity(shadowIntensity),
                radius: 12 + (depth * 8),
                x: 0,
                y: 4 + (depth * 4)
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 8,
                x: 0,
                y: 2
            )
            .onAppear {
                if !reduceMotion {
                    withAnimation(
                        Theme.Animation.orbitalFloat
                            .delay(Double(floatPhase) * 0.5)
                    ) {
                        floatOffset = 4
                    }
                }
            }
    }
}

extension View {
    /// Apply floating island effect for expanded card sections
    func floatingIsland(depth: CGFloat = 0.5, floatPhase: CGFloat = 0) -> some View {
        modifier(FloatingIslandModifier(depth: depth, floatPhase: floatPhase))
    }
}
