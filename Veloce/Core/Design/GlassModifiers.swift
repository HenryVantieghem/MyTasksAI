//
//  GlassModifiers.swift
//  MyTasksAI
//
//  Glass Morphism View Modifiers
//  Modern frosted glass effects for iOS
//

import SwiftUI

// MARK: - Glass Effect Modifier
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
                                .white.opacity(0.3),
                                .white.opacity(0.1)
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
                                Theme.Colors.glassBorder,
                                lineWidth: 0.5
                            )
                    )
            }
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
                    .stroke(Theme.Colors.glassBorder, lineWidth: 0.5)
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
                    .stroke(Theme.Colors.glassBorder, lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: elevation,
                x: 0,
                y: elevation / 2
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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.subheadline)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Theme.Colors.glassBorder, lineWidth: 0.5)
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
