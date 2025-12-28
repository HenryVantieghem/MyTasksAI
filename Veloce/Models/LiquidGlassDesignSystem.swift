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
}

// MARK: - iOS 26 Native Liquid Glass View Extensions

extension View {
    
    // MARK: - Navigation Layer (Glass)
    
    /// Apply iOS 26 native Liquid Glass for interactive navigation elements
    /// Use for: Buttons, toolbars, tab bars, floating controls
    @available(iOS 26.0, *)
    func liquidGlassInteractive<S: Shape>(in shape: S = Capsule() as! S) -> some View {
        self.glassEffect(.regular.interactive(true), in: shape)
    }
    
    /// Apply iOS 26 native Liquid Glass card (non-interactive)
    /// Use for: Glass containers that don't respond to touch
    @available(iOS 26.0, *)
    func liquidGlassCard(cornerRadius: CGFloat = 16) -> some View {
        self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    /// Apply iOS 26 native Liquid Glass with prominent tint
    /// Use for: Primary CTAs, important actions
    @available(iOS 26.0, *)
    func liquidGlassProminent<S: Shape>(in shape: S = Capsule() as! S, tint: Color = LiquidGlassDesignSystem.VibrantAccents.plasmaPurple) -> some View {
        self.glassEffect(.regular.tint(tint).interactive(true), in: shape)
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
        modifier(PulsingGlowModifier(color: color, baseIntensity: baseIntensity, pulseIntensity: pulseIntensity))
    }
    
    /// Apply Liquid Glass text field styling (iOS 26 native)
    @available(iOS 26.0, *)
    func liquidGlassTextField() -> some View {
        self
            .padding(LiquidGlassDesignSystem.Spacing.md)
            .frame(height: 48)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.input))
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

// MARK: - Pulsing Glow Modifier

private struct PulsingGlowModifier: ViewModifier {
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

// MARK: - Liquid Glass Button Styles (iOS 26)

struct LiquidGlassButton {
    
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
    
    /// Secondary button with glass effect
    @available(iOS 26.0, *)
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
        }
        .liquidGlassInteractive(in: RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.button))
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

// MARK: - Liquid Glass TextField (iOS 26)

@available(iOS 26.0, *)
struct LiquidGlassTextField: View {
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
        .glassEffect(
            isFocused ? .regular.tint(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.2)) : .regular,
            in: RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Radius.input)
        )
        .animation(LiquidGlassDesignSystem.Springs.quick, value: isFocused)
    }
}

// MARK: - Liquid Glass Tab Bar Item (iOS 26)

@available(iOS 26.0, *)
struct LiquidGlassTabItem: View {
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

// When iOS 26 is available, use these:
@available(iOS 26.0, *)
extension ButtonStyle where Self == GlassButtonStyle {
    /// iOS 26 native glass button style
    static var liquidGlass: GlassButtonStyle { .glass }
    
    /// iOS 26 native prominent glass button style
    static var liquidGlassProminent: GlassProminentButtonStyle { .glassProminent }
}

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

extension HapticsService {
    /// Glass focus feedback
    func glassFocus() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Glass morph feedback
    func glassMorph() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}

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
                    LiquidGlassButton.primary("Launch App", icon: "rocket.fill") {}
                    LiquidGlassButton.success("Complete", icon: "checkmark") {}
                    LiquidGlassButton.destructive("Delete") {}
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
