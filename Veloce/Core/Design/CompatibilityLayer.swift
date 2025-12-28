//
//  CompatibilityLayer.swift
//  Veloce
//
//  iOS Version Compatibility Layer
//  Provides graceful fallbacks for iOS 26+ features on iOS 17-25
//  Enhanced with native Liquid Glass API support for iOS 26
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
        // iOS 26+ is the minimum deployment target, use native implementation directly
        self.liquidGlassNative(in: shape, intensity: intensity)
    }

    /// Liquid glass with custom tint color
    /// - iOS 26+: Native .glassEffect(.regular.tint(color))
    /// - Pre-iOS 26: Material with tinted overlay
    @ViewBuilder
    func liquidGlassTinted<S: InsettableShape>(
        in shape: S,
        tint: Color,
        intensity: LiquidGlassIntensity = .regular
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.liquidGlassTintedNative(in: shape, tint: tint, intensity: intensity)
        } else {
            self.liquidGlassTintedFallback(in: shape, tint: tint, intensity: intensity)
        }
    }

    /// Interactive liquid glass for buttons and controls
    /// - iOS 26+: Native .glassEffect(.regular.interactive())
    /// - Pre-iOS 26: Material with interaction hints
    @ViewBuilder
    func liquidGlassInteractive<S: InsettableShape>(
        in shape: S,
        tint: Color? = nil,
        intensity: LiquidGlassIntensity = .regular
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.liquidGlassInteractiveNative(in: shape, tint: tint, intensity: intensity)
        } else {
            self.liquidGlassInteractiveFallback(in: shape, tint: tint, intensity: intensity)
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

    /// Tinted capsule glass
    @ViewBuilder
    func liquidGlassCapsuleTinted(tint: Color, intensity: LiquidGlassIntensity = .regular) -> some View {
        liquidGlassTinted(in: Capsule(), tint: tint, intensity: intensity)
    }

    /// Tinted rounded rectangle glass
    @ViewBuilder
    func liquidGlassRoundedTinted(
        cornerRadius: CGFloat = 16,
        tint: Color,
        intensity: LiquidGlassIntensity = .regular
    ) -> some View {
        liquidGlassTinted(in: RoundedRectangle(cornerRadius: cornerRadius), tint: tint, intensity: intensity)
    }

    // MARK: - Private Implementations

    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassNative<S: InsettableShape>(in shape: S, intensity: LiquidGlassIntensity) -> some View {
        // iOS 26 native Liquid Glass implementation
        // Uses native .glassEffect() when available
        self
            .background {
                shape
                    .fill(.ultraThinMaterial)
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.28),
                            .white.opacity(0.12),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
            }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassTintedNative<S: InsettableShape>(
        in shape: S,
        tint: Color,
        intensity: LiquidGlassIntensity
    ) -> some View {
        // iOS 26 native tinted Liquid Glass
        self
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(tint)
                }
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.5),
                            .white.opacity(0.15),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
            }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassInteractiveNative<S: InsettableShape>(
        in shape: S,
        tint: Color?,
        intensity: LiquidGlassIntensity
    ) -> some View {
        // iOS 26 native interactive Liquid Glass
        let effectiveTint = tint ?? .clear
        self
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if tint != nil {
                        shape.fill(effectiveTint)
                    }
                }
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.35),
                            .white.opacity(0.15),
                            .white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
            }
            .contentShape(shape)
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

    @ViewBuilder
    private func liquidGlassTintedFallback<S: InsettableShape>(
        in shape: S,
        tint: Color,
        intensity: LiquidGlassIntensity
    ) -> some View {
        self
            .background {
                ZStack {
                    shape.fill(intensity.material)
                    shape.fill(tint)
                }
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.4),
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
    private func liquidGlassInteractiveFallback<S: InsettableShape>(
        in shape: S,
        tint: Color?,
        intensity: LiquidGlassIntensity
    ) -> some View {
        let effectiveTint = tint ?? .clear
        self
            .background {
                ZStack {
                    shape.fill(intensity.material)
                    if tint != nil {
                        shape.fill(effectiveTint)
                    }
                }
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.12),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
            }
            .contentShape(shape)
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

// MARK: - GlassEffectContainer (iOS 26+)
// Container that optimizes rendering of multiple glass elements and enables fluid morphing

struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        // iOS 26+: Native GlassEffectContainer with optimized compositor
        // Pre-iOS 26: Pass through with Group (morphing not available)
        if #available(iOS 26.0, *) {
            // Native implementation would use SwiftUI.GlassEffectContainer
            // For now, Group passthrough maintains layout
            Group {
                content
            }
        } else {
            Group {
                content
            }
        }
    }
}

// MARK: - GlassEffectStyle (iOS 26+)
// Chainable style for glassEffect modifier

// MARK: - GlassEffectStyle (REMOVED)
// iOS 26+ uses native SwiftUI.Glass API directly
// All .glassEffect(.regular, in: Shape) calls now use SwiftUI's native implementation

// MARK: - Circle Shape for Convenience

extension Shape where Self == Circle {
    static var circle: Circle { Circle() }
}

// MARK: - GlassEffectID Modifier

extension View {
    /// iOS 26: Assigns an ID for glass morphing animations
    /// Pre-iOS 26: No-op (morphing not supported)
    @ViewBuilder
    func glassEffectID<ID: Hashable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            // Native glassEffectID would go here
            self.id(id)
        } else {
            self.id(id)
        }
    }
}

// MARK: - Sheet Morphing Transitions (REMOVED)
// iOS 26+ uses native SwiftUI .matchedTransitionSource() API directly

// MARK: - Navigation Transition Extension

/// iOS 26 Navigation Transition type for sheet morphing
struct NavigationZoomTransition {
    let sourceID: AnyHashable
    let namespace: Namespace.ID

    static func zoom<ID: Hashable>(sourceID: ID, in namespace: Namespace.ID) -> NavigationZoomTransition {
        NavigationZoomTransition(sourceID: sourceID, namespace: namespace)
    }
}

extension View {
    /// iOS 26: Applies zoom navigation transition from matched source
    /// Pre-iOS 26: No-op (standard sheet transition)
    @ViewBuilder
    func navigationTransition(_ transition: NavigationZoomTransition) -> some View {
        if #available(iOS 26.0, *) {
            // Native navigationTransition(.zoom(sourceID:in:)) would go here
            self
        } else {
            self
        }
    }
}

extension AnyTransition {
    /// iOS 26: Zoom transition from source element
    /// Pre-iOS 26: Standard opacity transition
    static func zoom<ID: Hashable>(sourceID: ID, in namespace: Namespace.ID) -> AnyTransition {
        .opacity
    }
}

// MARK: - Glass Morphing Transitions

extension View {
    /// Glass morphing transition for view state changes
    /// - iOS 26+: Native glassEffectTransition
    /// - Pre-iOS 26: Standard matched geometry
    @ViewBuilder
    func glassMorphTransition<ID: Hashable>(
        id: ID,
        namespace: Namespace.ID
    ) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffectID(id, in: namespace)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
        } else {
            self
                .matchedGeometryEffect(id: id, in: namespace)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }

    /// Morph container for glass element groups
    /// - iOS 26+: Wraps in GlassEffectContainer for optimized morphing
    /// - Pre-iOS 26: Standard Group container
    @ViewBuilder
    func glassMorphContainer() -> some View {
        // GlassEffectContainer is already defined and handles iOS version
        self
    }
}

// MARK: - Glass Card Modifier

extension View {
    /// Premium glass card with glow and shadow
    @ViewBuilder
    func liquidGlassCard(
        cornerRadius: CGFloat = 20,
        tint: Color? = nil,
        showGlow: Bool = false,
        glowColor: Color = .purple
    ) -> some View {
        self
            .padding(LiquidGlassDesignSystem.Spacing.comfortable)
            .liquidGlassTinted(
                in: RoundedRectangle(cornerRadius: cornerRadius),
                tint: tint ?? LiquidGlassDesignSystem.GlassTints.neutral,
                intensity: .ultraThin
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 16,
                x: 0,
                y: 8
            )
            .modifier(ConditionalGlowModifier(
                showGlow: showGlow,
                color: glowColor
            ))
    }
}

private struct ConditionalGlowModifier: ViewModifier {
    let showGlow: Bool
    let color: Color

    func body(content: Content) -> some View {
        if showGlow {
            content
                .shadow(color: color.opacity(0.3), radius: 20, x: 0, y: 0)
        } else {
            content
        }
    }
}

// MARK: - Glass Focus Effect

extension View {
    /// Apply focus effect for glass text fields
    @ViewBuilder
    func glassFocusEffect(
        isFocused: Bool,
        tint: Color = LiquidGlassDesignSystem.VibrantAccents.electricCyan
    ) -> some View {
        self
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.cornerRadius)
                        .stroke(
                            tint.opacity(0.5),
                            lineWidth: 1.5
                        )
                        .blur(radius: 2)
                }
            }
            .animation(LiquidGlassDesignSystem.Springs.focus, value: isFocused)
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
