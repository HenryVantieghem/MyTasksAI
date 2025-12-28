//
//  LiquidGlassComponents.swift
//  MyTasksAI
//
//  Premium iOS 26 Liquid Glass Component Library
//  Built with native .glassEffect() APIs following Apple HIG
//  Use these components throughout the app for consistent, premium glass effects
//

import SwiftUI

// MARK: - Liquid Glass Design System

/// Central design system for all Liquid Glass effects in the app
/// Following Apple's iOS 26 Liquid Glass Design Guidelines
enum LiquidGlassDesignSystem {
    
    // MARK: - Glass Styles
    
    /// Standard glass for cards and containers
    static let card: Glass = .regular
    
    /// Interactive glass for buttons and controls
    static let interactive: Glass = .regular.interactive(true)
    
    /// Tinted glass for colored accents
    static func tinted(_ color: Color) -> Glass {
        .regular.tint(color)
    }
    
    /// Interactive tinted glass
    static func interactiveTinted(_ color: Color) -> Glass {
        .regular.tint(color).interactive(true)
    }
    
    // MARK: - Spacing for Glass Containers
    
    /// Default spacing for morphing glass elements
    static let morphingSpacing: CGFloat = 40.0
    
    /// Tight spacing for closely grouped elements
    static let tightSpacing: CGFloat = 20.0
    
    /// Wide spacing for distinct elements
    static let wideSpacing: CGFloat = 60.0
    
    // MARK: - Color Palette (Vibrant Accents for Liquid Glass)
    
    enum VibrantAccents {
        static let electricCyan = Color(red: 0.0, green: 0.95, blue: 1.0)
        static let plasmaPurple = Color(red: 0.65, green: 0.25, blue: 1.0)
        static let auroraGreen = Color(red: 0.15, green: 1.0, blue: 0.65)
        static let solarGold = Color(red: 1.0, green: 0.85, blue: 0.25)
        static let nebulaPink = Color(red: 1.0, green: 0.45, blue: 0.75)
        static let cosmicBlue = Color(red: 0.25, green: 0.55, blue: 1.0)
        
        /// Primary gradient for CTAs
        static var primaryGradient: LinearGradient {
            LinearGradient(
                colors: [electricCyan, plasmaPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Premium Animation Springs
    
    enum Springs {
        /// Ultra-responsive UI interactions
        static let ui = Animation.spring(response: 0.25, dampingFraction: 0.7)
        
        /// Smooth page transitions
        static let page = Animation.spring(response: 0.35, dampingFraction: 0.75)
        
        /// Focus transitions (onboarding, sheets)
        static let focus = Animation.spring(response: 0.45, dampingFraction: 0.8)
        
        /// Gentle ambient animations
        static let ambient = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        
        /// Morphing glass transitions
        static let morph = Animation.spring(response: 0.4, dampingFraction: 0.7)
    }
}

// MARK: - Liquid Glass Button

/// Premium Liquid Glass button with native iOS 26 glass effect
struct LiquidGlassButton {
    
    // MARK: - Primary Button (CTA)
    
    /// Primary action button with vibrant gradient and glass effect
    static func primary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(.white)
            .background {
                LiquidGlassDesignSystem.VibrantAccents.primaryGradient
            }
        }
        .glassEffect(.regular.interactive(), in: Capsule())
        .shadow(color: LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.4), radius: 20, y: 10)
    }
    
    // MARK: - Secondary Button
    
    /// Secondary action button with subtle glass
    static func secondary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(.white.opacity(0.9))
        }
        .glassEffect(.regular.interactive(), in: Capsule())
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - Icon Button
    
    /// Circular icon button with glass
    static func icon(
        systemName: String,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: size, height: size)
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
    
    // MARK: - Success Button
    
    /// Success state button (e.g., "Enabled", "Complete")
    static func success(
        _ title: String,
        icon: String = "checkmark.circle.fill",
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(.white)
            .background {
                LinearGradient(
                    colors: [
                        LiquidGlassDesignSystem.VibrantAccents.auroraGreen,
                        Color(hex: "10B981")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .glassEffect(.regular.interactive(), in: Capsule())
        .shadow(color: LiquidGlassDesignSystem.VibrantAccents.auroraGreen.opacity(0.4), radius: 20, y: 10)
    }
}

// MARK: - Liquid Glass Card

/// Premium card component with Liquid Glass background
struct LiquidGlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    let content: Content
    
    init(
        cornerRadius: CGFloat = 20,
        tint: Color? = nil,
        interactive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.interactive = interactive
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background {
                if let tint = tint {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(0.1))
                }
            }
            .glassEffect(
                interactive ? .regular.interactive() : .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                tint?.opacity(0.4) ?? .white.opacity(0.2),
                                tint?.opacity(0.2) ?? .white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: (tint ?? .black).opacity(0.2),
                radius: 16,
                y: 8
            )
    }
}

// MARK: - Liquid Glass Text Field

/// Premium text input with Liquid Glass background
struct LiquidGlassTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void
    
    init(
        placeholder: String,
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self._isFocused = isFocused
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 17))
            .foregroundStyle(.white)
            .tint(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit(onSubmit)
            .glassEffect(
                .regular.interactive(),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isFocused ? [
                                LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.6),
                                LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.4)
                            ] : [
                                .white.opacity(0.2),
                                .white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 1.5 : 0.5
                    )
            }
            .shadow(
                color: isFocused ? LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.3) : .black.opacity(0.2),
                radius: isFocused ? 20 : 12,
                y: isFocused ? 10 : 6
            )
            .animation(LiquidGlassDesignSystem.Springs.ui, value: isFocused)
    }
}

// MARK: - Liquid Glass Section Header

/// Section header with glass background
struct LiquidGlassSectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Liquid Glass Pill (Tag/Badge)

/// Small pill component for tags, categories, etc.
struct LiquidGlassPill: View {
    let text: String
    let icon: String?
    let color: Color
    
    init(
        text: String,
        icon: String? = nil,
        color: Color = LiquidGlassDesignSystem.VibrantAccents.electricCyan
    ) {
        self.text = text
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(color.opacity(0.2))
        }
        .glassEffect(.regular, in: Capsule())
        .overlay {
            Capsule()
                .stroke(color.opacity(0.4), lineWidth: 0.5)
        }
    }
}

// MARK: - Liquid Glass Toggle Row

/// Settings-style toggle row with glass background
struct LiquidGlassToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = LiquidGlassDesignSystem.VibrantAccents.electricCyan,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(iconColor)
        }
        .padding(16)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.2),
                            .white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }
}

// MARK: - Liquid Glass Container (for Morphing Effects)

/// Container that enables multiple glass elements to morph together
struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(
        spacing: CGFloat = LiquidGlassDesignSystem.morphingSpacing,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content
        }
    }
}

// MARK: - Premium Glow Effects

/// Premium glow modifiers for Liquid Glass elements
extension View {
    /// Apply iridescent glow to glass elements
    func premiumGlowCapsule(
        style: PremiumGlowStyle = .subtle,
        intensity: PremiumGlowIntensity = .medium,
        animated: Bool = true
    ) -> some View {
        modifier(PremiumGlowModifier(
            style: style,
            intensity: intensity,
            animated: animated
        ))
    }
}

enum PremiumGlowStyle {
    case subtle       // Single color glow
    case iridescent   // Multi-color prismatic glow
    case energetic    // Pulsing vibrant glow
}

enum PremiumGlowIntensity {
    case whisper      // Barely visible
    case medium       // Noticeable
    case bold         // Strong presence
    
    var opacity: Double {
        switch self {
        case .whisper: return 0.15
        case .medium: return 0.3
        case .bold: return 0.5
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .whisper: return 12
        case .medium: return 20
        case .bold: return 32
        }
    }
}

struct PremiumGlowModifier: ViewModifier {
    let style: PremiumGlowStyle
    let intensity: PremiumGlowIntensity
    let animated: Bool
    
    @State private var glowPhase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    glowLayer(in: geometry.size)
                }
            }
            .onAppear {
                if animated {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        glowPhase = 1
                    }
                }
            }
    }
    
    @ViewBuilder
    private func glowLayer(in size: CGSize) -> some View {
        switch style {
        case .subtle:
            Capsule()
                .stroke(
                    LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(intensity.opacity),
                    lineWidth: 2
                )
                .blur(radius: intensity.radius)
            
        case .iridescent:
            Capsule()
                .stroke(
                    AngularGradient(
                        colors: [
                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                            LiquidGlassDesignSystem.VibrantAccents.auroraGreen,
                            LiquidGlassDesignSystem.VibrantAccents.nebulaPink,
                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
                        ],
                        center: .center,
                        angle: .degrees(glowPhase * 360)
                    ),
                    lineWidth: 3
                )
                .blur(radius: intensity.radius)
                .opacity(intensity.opacity)
            
        case .energetic:
            Capsule()
                .fill(
                    RadialGradient(
                        colors: [
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(intensity.opacity * (0.8 + glowPhase * 0.4)),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: intensity.radius * 2
                    )
                )
        }
    }
}

// MARK: - Glass Constellation Progress (Onboarding)

/// Constellation-style progress indicator with glass nodes
struct GlassConstellationProgress: View {
    let steps: [CosmicOnboardingStep]
    let currentStep: CosmicOnboardingStep
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                constellationNode(for: step, index: index)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }
    
    @ViewBuilder
    private func constellationNode(for step: CosmicOnboardingStep, index: Int) -> some View {
        let isActive = step == currentStep
        let isPast = steps.firstIndex(of: step)! < steps.firstIndex(of: currentStep)!
        
        Circle()
            .fill(
                isPast || isActive ?
                LiquidGlassDesignSystem.VibrantAccents.electricCyan :
                    Color.white.opacity(0.2)
            )
            .frame(width: isActive ? 10 : 6, height: isActive ? 10 : 6)
            .overlay {
                if isActive {
                    Circle()
                        .stroke(LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.4), lineWidth: 2)
                        .blur(radius: 4)
                        .scaleEffect(1.5)
                }
            }
            .matchedGeometryEffect(id: "node\(index)", in: namespace)
    }
}

// MARK: - Previews

#Preview("Liquid Glass Components") {
    ScrollView {
        VStack(spacing: 24) {
            // Buttons
            VStack(spacing: 16) {
                LiquidGlassButton.primary("Get Started", icon: "arrow.right", action: {})
                LiquidGlassButton.secondary("Learn More", action: {})
                LiquidGlassButton.success("Enabled", action: {})
                
                HStack {
                    LiquidGlassButton.icon(systemName: "star.fill", action: {})
                    LiquidGlassButton.icon(systemName: "heart.fill", action: {})
                    LiquidGlassButton.icon(systemName: "bookmark.fill", action: {})
                }
            }
            .padding(.horizontal)
            
            // Cards
            LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Premium Card")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text("This card features native iOS 26 Liquid Glass with a subtle purple tint.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            
            // Pills
            HStack {
                LiquidGlassPill(text: "Work", icon: "briefcase.fill", color: .blue)
                LiquidGlassPill(text: "Personal", icon: "house.fill", color: .purple)
                LiquidGlassPill(text: "Health", icon: "heart.fill", color: .red)
            }
            .padding(.horizontal)
            
            // Section Header
            LiquidGlassSectionHeader(title: "Recent Tasks", icon: "clock.fill", action: {})
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    .background(Color(red: 0.02, green: 0.02, blue: 0.04))
    .preferredColorScheme(.dark)
}
