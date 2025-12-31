//
//  NativeLiquidGlass.swift
//  Veloce
//
//  Pure Native Apple Liquid Glass Design System (iOS 26+)
//
//  This file provides the minimal API surface needed for Liquid Glass.
//  All effects (highlights, shadows, borders, interaction feedback)
//  are handled automatically by the system.
//
//  Architecture:
//  - Navigation Layer: Liquid Glass (buttons, toolbars, floating UI)
//  - Content Layer: Solid backgrounds (cards, lists, content)
//
//  References:
//  - https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass
//  - WWDC25 Session 219: Meet Liquid Glass
//  - WWDC25 Session 323: Build a SwiftUI app with the new design
//

import SwiftUI

// MARK: - Native Liquid Glass Modifiers (iOS 26+)

@available(iOS 26.0, *)
extension View {

    // MARK: - Navigation Layer (Use Glass)

    /// Interactive glass for buttons, controls, and floating UI
    /// System automatically handles: highlights, shadows, interaction feedback
    func nativeGlassInteractive(in shape: some Shape = Capsule()) -> some View {
        self.glassEffect(.regular.interactive(), in: shape)
    }

    /// Static glass container for navigation elements
    func nativeGlassContainer(cornerRadius: CGFloat = 16) -> some View {
        self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Prominent glass with tint for primary CTAs (use sparingly)
    func nativeGlassProminent(tint: Color, in shape: some Shape = Capsule()) -> some View {
        self.glassEffect(.regular.tint(tint).interactive(), in: shape)
    }

    /// Glass with custom shape
    func nativeGlass<S: Shape>(in shape: S) -> some View {
        self.glassEffect(.regular, in: shape)
    }

    /// Interactive glass with custom shape
    func nativeGlassInteractive<S: Shape>(in shape: S) -> some View {
        self.glassEffect(.regular.interactive(), in: shape)
    }
}

// MARK: - Content Layer Modifiers (NO Glass - Solid Backgrounds)
// Designed for Utopian gradient backgrounds

extension View {

    /// Solid card for content layer (NOT glass)
    /// Use for: list items, task cards, content containers
    /// Optimized for Utopian gradient backgrounds
    func contentCard(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Elevated content card with subtle shadow
    func elevatedContentCard(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }

    /// Subtle card for minimal visual weight
    func subtleCard(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Utopian gradient background (time-aware)
    func utopianBackground() -> some View {
        self.background(UtopianGradients.background(for: Date()).ignoresSafeArea())
    }
}

// MARK: - GlassEffectContainer Wrapper (Performance + Morphing)

@available(iOS 26.0, *)
struct NativeGlassContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer {
            content
        }
    }
}

// MARK: - Scroll Edge Effect Helper

@available(iOS 26.0, *)
extension View {
    /// Apply scroll edge effect for legibility when content scrolls under glass
    /// Use .hard for pinned accessory views, .soft for gradual fade
    func glassScrollEdge(style: ScrollEdgeEffectStyle = .hard, for edges: Edge.Set = .top) -> some View {
        self.scrollEdgeEffectStyle(style, for: edges)
    }
}

// MARK: - Morphing Support

@available(iOS 26.0, *)
extension View {
    /// Apply glass effect ID for fluid morphing transitions between glass shapes
    /// System automatically creates smooth morphing animations when IDs match
    func glassMorphID<ID: Hashable>(_ id: ID) -> some View {
        self.glassEffectID(id)
    }
}

// MARK: - Container Relative Shape

@available(iOS 26.0, *)
extension View {
    /// Align control shape with container curvature for visual continuity
    /// Creates concentric nesting: controls → sheets → windows → display
    func glassContainerShape() -> some View {
        self.containerShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Pre-iOS 26 Fallback

extension View {
    /// Fallback glass effect using ultraThinMaterial for pre-iOS 26
    @ViewBuilder
    func fallbackGlass(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Adaptive glass that uses native on iOS 26+, fallback otherwise
    @ViewBuilder
    func adaptiveGlass(cornerRadius: CGFloat = 16, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
            }
        } else {
            self.fallbackGlass(cornerRadius: cornerRadius)
        }
    }

    /// Adaptive glass capsule
    @ViewBuilder
    func adaptiveGlassCapsule(interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: Capsule())
            } else {
                self.glassEffect(.regular, in: Capsule())
            }
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Button Styles

/// Primary button style using native borderedProminent
struct NativePrimaryButtonStyle: ButtonStyle {
    let tint: Color

    init(tint: Color = .accentColor) {
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(tint)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

/// Secondary button style using native glass
struct NativeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .adaptiveGlassCapsule(interactive: true)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Convenience Extensions

extension ButtonStyle where Self == NativePrimaryButtonStyle {
    static func nativePrimary(tint: Color = .accentColor) -> NativePrimaryButtonStyle {
        NativePrimaryButtonStyle(tint: tint)
    }
}

extension ButtonStyle where Self == NativeSecondaryButtonStyle {
    static var nativeSecondary: NativeSecondaryButtonStyle {
        NativeSecondaryButtonStyle()
    }
}

// MARK: - Preview

#Preview("Native Glass + Utopian Gradients") {
    ZStack {
        // Utopian gradient background
        UtopianGradients.background(for: Date())
            .ignoresSafeArea()

        VStack(spacing: 24) {
            // Navigation layer - Glass
            Text("Navigation Layer (Glass)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 12) {
                Button("Primary") { }
                    .buttonStyle(.nativePrimary(tint: Color(hex: "#7C3AED")))

                Button("Secondary") { }
                    .buttonStyle(.nativeSecondary)
            }

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical)

            // Content layer - Solid
            Text("Content Layer (Solid)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 8) {
                Text("Task Card")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Solid background over Utopian gradient")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .contentCard()

            VStack(alignment: .leading, spacing: 8) {
                Text("Elevated Card")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Higher opacity + shadow")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .elevatedContentCard()
        }
        .padding()
    }
}
