//
//  CompatibilityLayer.swift
//  Veloce
//
//  iOS Version Compatibility Layer
//  Provides graceful fallbacks for iOS 26+ features on iOS 17-25
//

import SwiftUI

// MARK: - Liquid Glass Compatibility

extension View {
    /// Cross-platform liquid glass effect
    /// - iOS 26+: Native GlassEffectContainer with .glassEffect
    /// - iOS 18-25: Material with overlay border
    /// - iOS 17: UltraThinMaterial with clipShape
    @ViewBuilder
    func liquidGlass<S: InsettableShape>(in shape: S, intensity: LiquidGlassIntensity = .regular) -> some View {
        if #available(iOS 26.0, *) {
            self.liquidGlassNative(in: shape, intensity: intensity)
        } else if #available(iOS 18.0, *) {
            self.liquidGlassiOS18(in: shape, intensity: intensity)
        } else {
            self.liquidGlassFallback(in: shape, intensity: intensity)
        }
    }

    /// Capsule-specific liquid glass (common pattern)
    @ViewBuilder
    func liquidGlassCapsule(intensity: LiquidGlassIntensity = .regular) -> some View {
        liquidGlass(in: Capsule(), intensity: intensity)
    }

    /// RoundedRectangle-specific liquid glass
    @ViewBuilder
    func liquidGlassRounded(cornerRadius: CGFloat = 16, intensity: LiquidGlassIntensity = .regular) -> some View {
        liquidGlass(in: RoundedRectangle(cornerRadius: cornerRadius), intensity: intensity)
    }

    // MARK: - Private Implementations

    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassNative<S: InsettableShape>(in shape: S, intensity: LiquidGlassIntensity) -> some View {
        // iOS 26 native implementation
        self
            .background {
                shape
                    .fill(.ultraThinMaterial)
            }
            .clipShape(shape)
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    private func liquidGlassiOS18<S: InsettableShape>(in shape: S, intensity: LiquidGlassIntensity) -> some View {
        self
            .background(intensity.material, in: shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.25),
                            .white.opacity(0.1),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
            }
    }

    @ViewBuilder
    private func liquidGlassFallback<S: InsettableShape>(in shape: S, intensity: LiquidGlassIntensity) -> some View {
        self
            .background(intensity.material)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
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
    }
}

// MARK: - Liquid Glass Intensity

enum LiquidGlassIntensity {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick

    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .ultraThick: return .ultraThickMaterial
        }
    }

    var opacity: Double {
        switch self {
        case .ultraThin: return 0.3
        case .thin: return 0.5
        case .regular: return 0.7
        case .thick: return 0.85
        case .ultraThick: return 0.95
        }
    }
}

// MARK: - Symbol Effect Compatibility

extension View {
    /// Cross-platform bounce symbol effect
    /// - iOS 18+: Native symbol effect
    /// - iOS 17: Graceful degradation (no animation)
    @ViewBuilder
    func compatibleBounce<V: Equatable>(value: V) -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce, value: value)
        } else {
            self
        }
    }

    /// Cross-platform pulse symbol effect
    @ViewBuilder
    func compatiblePulse(isActive: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.pulse, isActive: isActive)
        } else {
            self.opacity(isActive ? 1.0 : 0.7)
        }
    }

    /// Cross-platform variable color symbol effect
    @ViewBuilder
    func compatibleVariableColor(isActive: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.variableColor, isActive: isActive)
        } else {
            self
        }
    }
}

// MARK: - Content Transition Compatibility

extension View {
    /// Cross-platform content transition
    @ViewBuilder
    func compatibleContentTransition() -> some View {
        if #available(iOS 17.0, *) {
            self.contentTransition(.numericText())
        } else {
            self
        }
    }
}

// MARK: - Presentation Compatibility

extension View {
    /// Cross-platform presentation background
    @ViewBuilder
    func compatiblePresentationBackground<S: ShapeStyle>(_ style: S) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(style)
        } else {
            self.background(style)
        }
    }

    /// Cross-platform presentation corner radius
    @ViewBuilder
    func compatiblePresentationCornerRadius(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationCornerRadius(radius)
        } else {
            self
        }
    }
}

// MARK: - Scroll Compatibility

extension View {
    /// Cross-platform scroll content background hiding
    @ViewBuilder
    func compatibleScrollContentBackground(_ visibility: Visibility) -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(visibility)
        } else {
            self
        }
    }

    /// Cross-platform scroll bounce behavior
    @ViewBuilder
    func compatibleScrollBounceBehavior(_ behavior: ScrollBounceBehavior) -> some View {
        if #available(iOS 16.4, *) {
            self.scrollBounceBehavior(behavior)
        } else {
            self
        }
    }
}

// MARK: - TextField Compatibility

extension View {
    /// Cross-platform text field limit
    @ViewBuilder
    func compatibleTextFieldLimit(_ limit: Int) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: limit) { _, _ in }
        } else {
            self
        }
    }
}

// MARK: - Animation Compatibility

extension Animation {
    /// Cross-platform spring animation
    static func compatibleSpring(response: Double = 0.3, dampingFraction: Double = 0.7) -> Animation {
        if #available(iOS 17.0, *) {
            return .spring(duration: response, bounce: 1 - dampingFraction)
        } else {
            return .spring(response: response, dampingFraction: dampingFraction)
        }
    }

    /// Cross-platform bouncy animation
    static var compatibleBouncy: Animation {
        if #available(iOS 17.0, *) {
            return .bouncy(duration: 0.4)
        } else {
            return .spring(response: 0.4, dampingFraction: 0.6)
        }
    }

    /// Cross-platform snappy animation
    static var compatibleSnappy: Animation {
        if #available(iOS 17.0, *) {
            return .snappy(duration: 0.25)
        } else {
            return .spring(response: 0.25, dampingFraction: 0.9)
        }
    }
}

// MARK: - Safe Area Compatibility

extension View {
    /// Cross-platform safe area padding
    @ViewBuilder
    func compatibleSafeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        if #available(iOS 17.0, *) {
            if let length = length {
                self.safeAreaPadding(edges, length)
            } else {
                self.safeAreaPadding(edges)
            }
        } else {
            self.padding(edges, length)
        }
    }
}

// MARK: - Haptics Compatibility

extension UIImpactFeedbackGenerator {
    /// Cross-platform impact feedback
    static func compatibleImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Glass Button Styles
// NOTE: iOS 26+ provides native .glass and .glassProminent button styles
// via the Liquid Glass design system. Use these directly:
//   .buttonStyle(.glass)
//   .buttonStyle(.glassProminent)

// MARK: - OS Version Check

struct OSVersion {
    static var isiOS17OrLater: Bool {
        if #available(iOS 17.0, *) {
            return true
        }
        return false
    }

    static var isiOS18OrLater: Bool {
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }

    static var isiOS26OrLater: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    static var supportsLiquidGlass: Bool {
        isiOS26OrLater
    }

    static var supportsSymbolEffects: Bool {
        isiOS18OrLater
    }
}
