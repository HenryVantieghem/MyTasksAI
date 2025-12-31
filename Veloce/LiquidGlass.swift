//
//  LiquidGlass.swift
//  Veloce
//
//  DEPRECATED: Use NativeLiquidGlass.swift instead
//
//  This file provides legacy compatibility for existing code.
//  New code should use the native APIs in NativeLiquidGlass.swift.
//

import SwiftUI

// MARK: - Legacy Compatibility (Deprecated)

@available(*, deprecated, message: "Use adaptiveGlass() from NativeLiquidGlass.swift instead")
public struct LiquidGlassBackground: View {
    public var cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 20) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}

@available(*, deprecated, message: "Use adaptiveGlassCapsule() from NativeLiquidGlass.swift instead")
public struct LiquidGlassCapsule: View {
    public init() {}

    public var body: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: Capsule())
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
}

@available(*, deprecated, message: "Use adaptiveGlass() from NativeLiquidGlass.swift instead")
public extension View {
    func liquidGlassContainer(cornerRadius: CGFloat = 20) -> some View {
        self.adaptiveGlass(cornerRadius: cornerRadius)
    }
}
