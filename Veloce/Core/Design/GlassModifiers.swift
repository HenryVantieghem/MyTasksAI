//
//  GlassModifiers.swift
//  Veloce
//
//  Legacy Glass Modifiers (Pre-iOS 26 Fallbacks Only)
//
//  For iOS 26+, use NativeLiquidGlass.swift with native .glassEffect() APIs.
//  This file provides minimal fallback support for older iOS versions.
//

import SwiftUI

// MARK: - Legacy Glass Effect (Pre-iOS 26)

/// Simple glass effect using ultraThinMaterial for backwards compatibility
@available(iOS, deprecated: 26.0, message: "Use .glassEffect() from NativeLiquidGlass.swift")
struct LegacyGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Legacy Glass Card

@available(iOS, deprecated: 26.0, message: "Use .contentCard() from NativeLiquidGlass.swift")
struct LegacyGlassCardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Simple Press Button Style

/// Standard press feedback for buttons
struct PressableButtonStyle: ButtonStyle {
    let scale: CGFloat

    init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }

    static func pressable(scale: CGFloat) -> PressableButtonStyle {
        PressableButtonStyle(scale: scale)
    }
}

// MARK: - View Extensions (Legacy Compatibility)

extension View {
    /// Legacy glass effect - use adaptiveGlass() from NativeLiquidGlass.swift instead
    @available(iOS, deprecated: 26.0, message: "Use adaptiveGlass() from NativeLiquidGlass.swift")
    func legacyGlassEffect(cornerRadius: CGFloat = 16) -> some View {
        modifier(LegacyGlassModifier(cornerRadius: cornerRadius))
    }

    /// Legacy glass card - use contentCard() from NativeLiquidGlass.swift instead
    @available(iOS, deprecated: 26.0, message: "Use contentCard() from NativeLiquidGlass.swift")
    func glassCard(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        modifier(LegacyGlassCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Theme Shadow Extension (For Compatibility)
// NOTE: themeShadow(_ style: ShadowStyle) is defined in Theme.swift
// Use Theme.Shadow.sm, Theme.Shadow.md, Theme.Shadow.lg etc. with that function
