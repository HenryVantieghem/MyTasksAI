//
//  LiquidGlassDesignSystem.swift
//  MyTasksAI
//
//  🌊 iOS 26 Native Liquid Glass Design System
//  Apple's Liquid Glass is a dynamic material that combines optical properties
//  of glass with a sense of fluidity. It blurs content, reflects light, and reacts
//  to touch in real-time.
//
//  Architecture:
//  - Navigation Layer: Liquid Glass (buttons, toolbars, floating UI)
//  - Content Layer: Solid backgrounds (cards, lists, content)
//  - Effects Layer: Glows, halos, morphing animations
//

import SwiftUI

// MARK: - Liquid Glass Design System

enum LiquidGlassDesignSystem {
    
    // MARK: - Vibrant Accents (Pop Against Void)
    
    enum VibrantAccents {
        /// Electric Cyan - Ultra-bright primary action
        static let electricCyan = Color(red: 0.0, green: 0.95, blue: 1.0)
        
        /// Plasma Purple - Rich vivid purple for AI/premium
        static let plasmaPurple = Color(red: 0.65, green: 0.25, blue: 1.0)
        
        /// Aurora Green - Vibrant success
        static let auroraGreen = Color(red: 0.15, green: 1.0, blue: 0.65)
        
        /// Solar Gold - Warm achievement
        static let solarGold = Color(red: 1.0, green: 0.85, blue: 0.25)
        
        /// Nebula Pink - Celebration/energy
        static let nebulaPink = Color(red: 1.0, green: 0.45, blue: 0.75)
        
        /// Cosmic Blue - Deep interactive
        static let cosmicBlue = Color(red: 0.25, green: 0.55, blue: 1.0)
        
        /// Stellar White - Pure highlight
        static let stellarWhite = Color(red: 1.0, green: 0.98, blue: 0.95)
    }
    
    // MARK: - Void Backgrounds (Deep Space Layering)
    
    enum Void {
        /// Ultimate void - deepest background
        static let deepSpace = Color(red: 0.01, green: 0.01, blue: 0.03)
        
        /// Standard void - main background
        static let cosmos = Color(red: 0.02, green: 0.02, blue: 0.04)
        
        /// Card surface - elevated over void
        static let abyss = Color(red: 0.04, green: 0.04, blue: 0.06)
        
        /// Interactive surface
        static let nebula = Color(red: 0.06, green: 0.06, blue: 0.10)
    }
    
    // MARK: - Semantic Colors
    
    enum Semantic {
        static let success = VibrantAccents.auroraGreen
        static let warning = VibrantAccents.solarGold
        static let error = Color(red: 1.0, green: 0.35, blue: 0.40)
        static let info = VibrantAccents.cosmicBlue
        static let premium = VibrantAccents.plasmaPurple
    }
    
    // MARK: - Text Colors
    
    enum Text {
        /// Primary text - 95% white
        static let primary = Color.white.opacity(0.95)
        
        /// Secondary text - 60% white
        static let secondary = Color.white.opacity(0.60)
        
        /// Tertiary text - 40% white
        static let tertiary = Color.white.opacity(0.40)
        
        /// Disabled text - 25% white
        static let disabled = Color.white.opacity(0.25)
    }
    
    // MARK: - Typography (SF Pro + SF Rounded)
    
    enum Typography {
        // MARK: Display (Thin, Editorial)
        static let displayHero = Font.system(size: 48, weight: .thin)
        static let displayLarge = Font.system(size: 36, weight: .thin)
        static let displayMedium = Font.system(size: 28, weight: .thin)
        
        // MARK: Titles (Rounded for Friendliness)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 18, weight: .semibold, design: .rounded)
        
        // MARK: Body
        static let body = Font.system(size: 16, weight: .regular)
        static let bodyBold = Font.system(size: 16, weight: .semibold)
        static let callout = Font.system(size: 15, weight: .regular)
        
        // MARK: Supporting
        static let caption = Font.system(size: 13, weight: .medium)
        static let caption2 = Font.system(size: 11, weight: .regular)
        
        // MARK: Special
        static let aiWhisper = Font.system(size: 14, weight: .regular, design: .serif).italic()
        static let code = Font.system(size: 13, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing (8pt Grid)
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48

        // Semantic
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let comfortable: CGFloat = 20
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
        
        // Semantic
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let input: CGFloat = 12
    }
    
    // MARK: - Animation Springs
    
    enum Springs {
        /// UI interactions (250ms) - buttons, toggles
        static let ui: SwiftUI.Animation = .spring(response: 0.25, dampingFraction: 0.7)
        
        /// Sheet presentations (400ms) - modals, drawers
        static let sheet: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.75)
        
        /// Focus transitions (500ms) - cards expanding, morphing
        static let focus: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.75)
        
        /// Bouncy feedback (350ms) - completion, celebrations
        static let bouncy: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.6)
        
        /// Quick response (150ms) - immediate feedback
        static let quick: SwiftUI.Animation = .spring(response: 0.15, dampingFraction: 0.8)
        
        /// Gentle float (600ms) - ambient motion
        static let gentle: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.85)
    }
    
    // MARK: - Continuous Animations
    
    enum ContinuousAnimation {
        /// Breathing (2.5s cycle)
        static let breathing: SwiftUI.Animation = .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        
        /// Rotation (8s continuous)
        static let rotation: SwiftUI.Animation = .linear(duration: 8).repeatForever(autoreverses: false)
        
        /// Pulse (1.5s cycle)
        static let pulse: SwiftUI.Animation = .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        
        /// Shimmer (3s sweep)
        static let shimmer: SwiftUI.Animation = .easeInOut(duration: 3).repeatForever(autoreverses: false)
    }
    
    // MARK: - Shadows & Glows
    
    enum Shadow {
        static let small = ShadowToken(color: .black.opacity(0.2), radius: 4, y: 2)
        static let medium = ShadowToken(color: .black.opacity(0.25), radius: 8, y: 4)
        static let large = ShadowToken(color: .black.opacity(0.3), radius: 16, y: 8)
        
        static func glow(color: Color, radius: CGFloat = 20) -> ShadowToken {
            ShadowToken(color: color.opacity(0.4), radius: radius, y: 0)
        }
    }
    
    struct ShadowToken {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }

    // MARK: - Glass Tints (For Interactive States)

    enum GlassTints {
        static let interactive = VibrantAccents.electricCyan
        static let success = VibrantAccents.auroraGreen
        static let error = Semantic.error
        static let warning = VibrantAccents.solarGold
        static let subtle = Color.white.opacity(0.1)
        static let neutral = Color.white.opacity(0.15)
    }

    // MARK: - Glass Configuration

    enum GlassConfig {
        static let borderOpacityRest: Double = 0.2
        static let borderOpacityPressed: Double = 0.4
        static let borderOpacityFocused: Double = 0.6
        static let backgroundBlur: CGFloat = 20
        static let cornerRadius: CGFloat = 16
    }

    // MARK: - Sizing Tokens

    enum Sizing {
        static let buttonHeight: CGFloat = 50
        static let inputHeight: CGFloat = 48
        static let textFieldHeight: CGFloat = 48
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 20
        static let iconLarge: CGFloat = 24
        static let touchTarget: CGFloat = 44
        static let cornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 12
    }

    // MARK: - Gradients

    enum Gradients {
        static var primary: LinearGradient {
            LinearGradient(
                colors: [VibrantAccents.electricCyan, VibrantAccents.plasmaPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var ctaPrimary: LinearGradient {
            LinearGradient(
                colors: [VibrantAccents.electricCyan, VibrantAccents.plasmaPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var success: LinearGradient {
            LinearGradient(
                colors: [VibrantAccents.auroraGreen, VibrantAccents.electricCyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        static var sunset: LinearGradient {
            LinearGradient(
                colors: [VibrantAccents.solarGold, VibrantAccents.nebulaPink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var prismaticBorder: AngularGradient {
            AngularGradient(
                colors: [
                    VibrantAccents.electricCyan,
                    VibrantAccents.plasmaPurple,
                    VibrantAccents.nebulaPink,
                    VibrantAccents.electricCyan
                ],
                center: .center
            )
        }
    }

    // MARK: - Morph Animation Tokens

    enum MorphAnimation {
        static let duration: Double = 0.35
        static let damping: Double = 0.75
        static let response: Double = 0.4
        static let shimmerSweep: Double = 3.0
        static let prismaticRotation: Double = 8.0
        static let glowPulse: Double = 2.0
    }
}

// MARK: - Validation State

enum GlassValidationState: Equatable {
    case idle
    case valid
    case invalid(String)
    case validating

    var tint: Color {
        switch self {
        case .idle: return LiquidGlassDesignSystem.Text.tertiary
        case .valid: return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        case .invalid: return LiquidGlassDesignSystem.Semantic.error
        case .validating: return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        }
    }
}

// MARK: - Button Styles

enum LiquidGlassButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive
    case success

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive, .success:
            return .white
        case .secondary, .ghost:
            return LiquidGlassDesignSystem.Text.primary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .primary:
            return LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
        case .secondary:
            return LiquidGlassDesignSystem.Void.nebula
        case .ghost:
            return .clear
        case .destructive:
            return LiquidGlassDesignSystem.Semantic.error
        case .success:
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        }
    }
}

// MARK: - Extended Springs

extension LiquidGlassDesignSystem.Springs {
    /// Press animation (150ms) - button press feedback
    static let press: SwiftUI.Animation = .spring(response: 0.15, dampingFraction: 0.8)
}

// MARK: - iOS 26 Native Liquid Glass View Extensions

extension View {
    
    // MARK: - Navigation Layer (Glass)
    
    /// Apply iOS 26 native Liquid Glass for interactive navigation elements
    /// Use for: Buttons, toolbars, tab bars, floating controls
    func liquidGlassInteractive<S: InsettableShape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffect(.regular.interactive(true), in: shape))
        } else {
            // Fallback to material-based glass
            return AnyView(
                self
                    .padding(12)
                    .background(.ultraThinMaterial, in: shape)
                    .overlay {
                        shape.strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                    }
            )
        }
    }
    
    /// Convenience method for Capsule shapes
    func liquidGlassInteractive() -> some View {
        liquidGlassInteractive(in: Capsule())
    }
    
    /// Apply iOS 26 native Liquid Glass card (non-interactive)
    /// Use for: Glass containers that don't respond to touch
    func liquidGlassCard(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius)))
        } else {
            return AnyView(
                self
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            )
        }
    }
    
    /// Apply iOS 26 native Liquid Glass with prominent tint
    /// Use for: Primary CTAs, important actions
    func liquidGlassProminent<S: InsettableShape>(in shape: S, tint: Color = LiquidGlassDesignSystem.VibrantAccents.plasmaPurple) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffect(.regular.tint(tint).interactive(true), in: shape))
        } else {
            return AnyView(
                self
                    .padding(12)
                    .background {
                        ZStack {
                            shape.fill(.ultraThinMaterial)
                            shape.fill(tint.opacity(0.15))
                        }
                    }
                    .clipShape(shape)
                    .overlay {
                        shape.strokeBorder(
                            tint.opacity(0.4),
                            lineWidth: 1
                        )
                    }
            )
        }
    }
    
    // MARK: - Content Layer (Solid Backgrounds)
    
    /// Solid card background for content (NOT glass)
    /// Use for: Task cards, list items, content sections
    func liquidContentCard(
        cornerRadius: CGFloat = 16,
        tint: Color? = nil,
        borderColor: Color? = nil
    ) -> some View {
        self
            .padding(LiquidGlassDesignSystem.Spacing.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LiquidGlassDesignSystem.Void.abyss)
                    .overlay {
                        if let tint = tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.08))
                        }
                    }
            }
            .overlay {
                if let borderColor = borderColor {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(borderColor.opacity(0.3), lineWidth: 1)
                }
            }
    }
    
    /// Elevated content card with shadow
    func liquidElevatedCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(LiquidGlassDesignSystem.Spacing.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LiquidGlassDesignSystem.Void.nebula)
            }
            .shadow(
                color: LiquidGlassDesignSystem.Shadow.medium.color,
                radius: LiquidGlassDesignSystem.Shadow.medium.radius,
                x: LiquidGlassDesignSystem.Shadow.medium.x,
                y: LiquidGlassDesignSystem.Shadow.medium.y
            )
    }
    
    // MARK: - Effects Layer
    
    /// Apply colored glow halo around element
    func liquidGlow(
        color: Color = LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
        radius: CGFloat = 20,
        intensity: Double = 0.4
    ) -> some View {
        self
            .shadow(color: color.opacity(intensity), radius: radius, x: 0, y: 0)
    }
    
    /// Apply pulsing glow animation
    func liquidPulsingGlow(
        color: Color = LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
        baseIntensity: Double = 0.3,
        pulseIntensity: Double = 0.6
    ) -> some View {
        modifier(LiquidGlassPulsingGlowModifier(color: color, baseIntensity: baseIntensity, pulseIntensity: pulseIntensity))
    }
    
    /// Apply Liquid Glass text field styling (iOS 26 native)
    func liquidGlassTextField() -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(
                self
                    .padding(LiquidGlassDesignSystem.Spacing.md)
                    .frame(height: 48)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.input))
            )
        } else {
            return AnyView(
                self
                    .padding(LiquidGlassDesignSystem.Spacing.md)
                    .frame(height: 48)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.input))
            )
        }
    }
    
    /// Apply screen padding
    func liquidScreenPadding() -> some View {
        self.padding(.horizontal, LiquidGlassDesignSystem.Spacing.screenPadding)
    }
    
    /// Apply Liquid Glass shadow
    func liquidShadow(_ token: LiquidGlassDesignSystem.ShadowToken) -> some View {
        self.shadow(color: token.color, radius: token.radius, x: token.x, y: token.y)
    }
}

// MARK: - Liquid Glass Pulsing Glow Modifier

private struct LiquidGlassPulsingGlowModifier: ViewModifier {
    let color: Color
    let baseIntensity: Double
    let pulseIntensity: Double

    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(baseIntensity + (Double(phase) * (pulseIntensity - baseIntensity))),
                radius: 20 + (phase * 10),
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(LiquidGlassDesignSystem.ContinuousAnimation.pulse) {
                    phase = 1
                }
            }
    }
}

// MARK: - Simple Liquid Glass Button Styles

struct SimpleLiquidGlassButton {

    /// Primary CTA button with native glass effect
    static func primary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(LiquidGlassDesignSystem.Typography.bodyBold)
                    .foregroundStyle(.white)
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [
                        LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                        LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.button))
            .liquidGlow(
                color: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                radius: 24,
                intensity: 0.5
            )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
    
    /// Secondary button with native iOS 26 Liquid Glass
    static func secondary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(LiquidGlassDesignSystem.Typography.bodyBold)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LiquidGlassDesignSystem.Text.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding(.horizontal, 20)
        }
        .background {
            let shape = RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.button)
            
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular.interactive(true), in: shape)
            } else {
                shape.fill(.ultraThinMaterial)
            }
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
    
    /// Success button with green gradient
    static func success(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(title)
                    .font(LiquidGlassDesignSystem.Typography.bodyBold)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [
                        LiquidGlassDesignSystem.Semantic.success,
                        LiquidGlassDesignSystem.VibrantAccents.electricCyan
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.button))
            .liquidGlow(
                color: LiquidGlassDesignSystem.Semantic.success,
                radius: 20,
                intensity: 0.4
            )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
    
    /// Destructive button
    static func destructive(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(LiquidGlassDesignSystem.Typography.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LiquidGlassDesignSystem.Semantic.error)
                .clipShape(RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.button))
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

/// Button press feedback style
struct LiquidButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(LiquidGlassDesignSystem.Springs.ui, value: configuration.isPressed)
    }
}

// MARK: - Simple Liquid Glass TextField

struct SimpleLiquidGlassTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    
    @FocusState private var isFocused: Bool
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(LiquidGlassDesignSystem.Text.tertiary)
            }
            
            TextField(placeholder, text: $text)
                .font(LiquidGlassDesignSystem.Typography.body)
                .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                .focused($isFocused)
                .tint(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
        }
        .padding(LiquidGlassDesignSystem.Spacing.md)
        .frame(height: 48)
        .background {
            let shape = RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.input)
            let tintColor = isFocused ? LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.2) : Color.clear
            
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(
                        .regular.tint(tintColor),
                        in: shape
                    )
            } else {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if isFocused {
                        shape.fill(tintColor)
                    }
                }
            }
        }
        .animation(LiquidGlassDesignSystem.Springs.quick, value: isFocused)
    }
}

// MARK: - Simple Liquid Glass Tab Bar Item

struct SimpleLiquidGlassTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        isSelected ?
                        LiquidGlassDesignSystem.VibrantAccents.electricCyan :
                        LiquidGlassDesignSystem.Text.tertiary
                    )
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        isSelected ?
                        LiquidGlassDesignSystem.Text.primary :
                        LiquidGlassDesignSystem.Text.tertiary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iOS 26 Native Liquid Glass Button Styles

// Note: GlassButtonStyle and GlassProminentButtonStyle are iOS 26 system types
// Use .glass and .glassProminent directly when available in iOS 26

// MARK: - Fallback for Pre-iOS 26

/// Fallback glass button style for iOS < 26
struct LiquidGlassFallbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, LiquidGlassDesignSystem.Spacing.lg)
            .padding(.vertical, LiquidGlassDesignSystem.Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.25),
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(LiquidGlassDesignSystem.Springs.ui, value: configuration.isPressed)
    }
}

// MARK: - Haptics Service Extension
// Note: glassFocus() and glassMorph() are defined in HapticsService.swift

// MARK: - Preview

#Preview("Liquid Glass Components") {
    ZStack {
        // Void background
        LiquidGlassDesignSystem.Void.cosmos
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 32) {
                // Buttons
                VStack(spacing: 16) {
                    SimpleLiquidGlassButton.primary("Launch App", icon: "rocket.fill") {}
                    SimpleLiquidGlassButton.success("Complete", icon: "checkmark") {}
                    SimpleLiquidGlassButton.destructive("Delete") {}
                }
                .padding(.horizontal, 24)
                
                // Cards
                VStack(spacing: 16) {
                    Text("Solid Content Card")
                        .liquidContentCard()
                    
                    Text("Elevated Card")
                        .liquidElevatedCard()
                    
                    Text("Tinted Card")
                        .liquidContentCard(tint: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple)
                }
                .padding(.horizontal, 24)
                
                // Text with glow
                Text("Glowing Text")
                    .font(LiquidGlassDesignSystem.Typography.title1)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                    .liquidPulsingGlow(color: LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                    .padding()
            }
            .padding(.vertical, 40)
        }
    }
}
