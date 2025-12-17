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
