//
//  GlassModifiers.swift
//  MyTasksAI
//
//  Glass Morphism View Modifiers
//  Modern frosted glass effects for iOS
//

import SwiftUI

// MARK: - Dark Mode Aware Modifier
/// Applies different values based on color scheme for polished dark mode
struct DarkModeAwareModifier<Light: View, Dark: View>: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let lightView: () -> Light
    let darkView: () -> Dark

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            darkView()
        } else {
            lightView()
        }
    }
}

extension View {
    /// Apply different views based on color scheme
    func darkModeAware<Light: View, Dark: View>(
        light: @escaping () -> Light,
        dark: @escaping () -> Dark
    ) -> some View {
        modifier(DarkModeAwareModifier(lightView: light, darkView: dark))
    }

    /// Apply different opacity based on color scheme
    func adaptiveOpacity(light: Double, dark: Double) -> some View {
        modifier(AdaptiveOpacityModifier(lightOpacity: light, darkOpacity: dark))
    }

    /// Apply different shadow based on color scheme
    func adaptiveShadow(
        lightColor: Color = .black.opacity(0.1),
        darkColor: Color = .black.opacity(0.3),
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        modifier(AdaptiveShadowModifier(
            lightColor: lightColor,
            darkColor: darkColor,
            radius: radius,
            x: x,
            y: y
        ))
    }
}

// MARK: - Adaptive Opacity Modifier
struct AdaptiveOpacityModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let lightOpacity: Double
    let darkOpacity: Double

    func body(content: Content) -> some View {
        content.opacity(colorScheme == .dark ? darkOpacity : lightOpacity)
    }
}

// MARK: - Adaptive Shadow Modifier
struct AdaptiveShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let lightColor: Color
    let darkColor: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(
            color: colorScheme == .dark ? darkColor : lightColor,
            radius: colorScheme == .dark ? radius * 1.5 : radius,  // Larger blur in dark mode
            x: x,
            y: y
        )
    }
}

// MARK: - Glass Effect Modifier
struct GlassEffectModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

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
                                .white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.1)
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
    @Environment(\.colorScheme) private var colorScheme

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
                                        .white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                                        .white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            }
            .themeShadow(Theme.Shadow.sm)
    }
}

// MARK: - Glass Button Modifier
struct GlassButtonModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
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
                                        .white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                        .white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            }
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                radius: colorScheme == .dark ? 6 : 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isPressed ? DesignTokens.Scale.pressed : 1)
            .opacity(isPressed ? DesignTokens.Opacity.pressed : 1)
    }
}

// MARK: - Glass TextField Style
struct GlassTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme

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
                                .white.opacity(colorScheme == .dark ? 0.15 : 0.25),
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                radius: colorScheme == .dark ? 3 : 2,
                x: 0,
                y: 1
            )
    }
}

// MARK: - Floating Glass Modifier
struct FloatingGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
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
                                .white.opacity(colorScheme == .dark ? 0.15 : 0.25),
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15),
                radius: colorScheme == .dark ? elevation * 1.5 : elevation,
                x: 0,
                y: colorScheme == .dark ? elevation * 0.75 : elevation / 2
            )
    }
}

// MARK: - View Extensions
extension View {
    /// Apply glass effect
    func glassEffect(
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
    @Environment(\.colorScheme) private var colorScheme

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
                                .white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                radius: colorScheme == .dark ? 4 : 2,
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
    @Environment(\.colorScheme) private var colorScheme

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
                                .white.opacity(colorScheme == .dark ? 0.1 : 0.3),
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
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
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

// MARK: - Liquid Glass Modifier (iOS 26 Style)
struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

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
                                .white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// Apply liquid glass effect (iOS 26 style)
    func liquidGlass(
        cornerRadius: CGFloat = Theme.CornerRadius.lg,
        tint: Color? = nil
    ) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, tint: tint))
    }
}

// MARK: - Premium Glass Card Modifier
/// Enhanced glass effect with deeper blur, iridescent border, and stronger shadows
struct PremiumGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
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
                                    (tint ?? Theme.Colors.aiPurple).opacity(colorScheme == .dark ? 0.08 : 0.04),
                                    (tint ?? Theme.Colors.aiBlue).opacity(colorScheme == .dark ? 0.04 : 0.02),
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
                                    .white.opacity(colorScheme == .dark ? 0.08 : 0.15),
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
                                    .white.opacity(colorScheme == .dark ? 0.25 : 0.5),
                                    .white.opacity(colorScheme == .dark ? 0.08 : 0.2),
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
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 12, x: 0, y: 4)
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
    @Environment(\.colorScheme) private var colorScheme

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
                                    .white.opacity(colorScheme == .dark ? 0.03 : 0.08),
                                    .clear,
                                    .white.opacity(colorScheme == .dark ? 0.02 : 0.05)
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
                                .white.opacity(colorScheme == .dark ? 0.2 : 0.4),
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.35 : 0.12),
                radius: colorScheme == .dark ? 16 : 10,
                x: 0,
                y: colorScheme == .dark ? 8 : 5
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
    @Environment(\.colorScheme) private var colorScheme
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
                                .white.opacity(colorScheme == .dark ? 0.1 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: glowColor.opacity(0.3), radius: 16, x: 0, y: 6)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
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
