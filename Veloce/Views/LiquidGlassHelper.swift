//
//  LiquidGlassHelper.swift
//  Veloce
//
//  Liquid Glass Design System Helper
//  Reusable modifiers and utilities for consistent liquid glass effects
//

import SwiftUI

// MARK: - Liquid Glass Preset Styles

/// Visual emphasis style for liquid glass effects (distinct from LiquidGlassStyle in DesignSystem)
enum GlassVisualStyle {
    case subtle      // Low emphasis - pills, badges
    case standard    // Medium emphasis - cards, rows
    case prominent   // High emphasis - focused states, key UI
    case floating    // Navigation bars, tab bars
}

// MARK: - Liquid Glass View Modifier

struct LiquidGlassModifier: ViewModifier {
    let style: GlassVisualStyle
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background {
                liquidGlassBackground
            }
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .shadow(color: contactShadowColor, radius: contactShadowRadius, x: 0, y: contactShadowY)
    }
    
    // MARK: - Glass Background
    
    @ViewBuilder
    private var liquidGlassBackground: some View {
        ZStack {
            // Base ultra-thin material
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // Depth gradient
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(depthGradient)
            
            // Glossy highlight
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(highlightGradient)
                .padding(.bottom, highlightPadding)
            
            // Border definition
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderGradient, lineWidth: 0.5)
        }
    }
    
    // MARK: - Style-Specific Properties
    
    private var depthGradient: LinearGradient {
        switch style {
        case .subtle:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.white.opacity(0.02),
                    Color.white.opacity(0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .standard:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.02),
                    Color.white.opacity(0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .prominent:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.10),
                    Color.white.opacity(0.03),
                    Color.white.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .floating:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.02),
                    Color.white.opacity(0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var highlightGradient: LinearGradient {
        switch style {
        case .subtle:
            return LinearGradient(
                colors: [Color.white.opacity(0.10), .clear],
                startPoint: .top,
                endPoint: .center
            )
        case .standard:
            return LinearGradient(
                colors: [Color.white.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .center
            )
        case .prominent:
            return LinearGradient(
                colors: [Color.white.opacity(0.15), .clear],
                startPoint: .top,
                endPoint: .center
            )
        case .floating:
            return LinearGradient(
                colors: [Color.white.opacity(0.15), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
    }
    
    private var borderGradient: LinearGradient {
        switch style {
        case .subtle:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standard:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .prominent:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .floating:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.20),
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var highlightPadding: CGFloat {
        switch style {
        case .subtle: return 20
        case .standard: return 30
        case .prominent: return 35
        case .floating: return 25
        }
    }
    
    // MARK: - Shadow Properties
    
    private var shadowColor: Color {
        Color.black.opacity(0.08)
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .subtle: return 6
        case .standard: return 10
        case .prominent: return 16
        case .floating: return 20
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .subtle: return 2
        case .standard: return 3
        case .prominent: return 5
        case .floating: return 10
        }
    }
    
    private var contactShadowColor: Color {
        Color.black.opacity(0.04)
    }
    
    private var contactShadowRadius: CGFloat {
        switch style {
        case .subtle: return 2
        case .standard: return 3
        case .prominent: return 5
        case .floating: return 5
        }
    }
    
    private var contactShadowY: CGFloat {
        1
    }
}

// MARK: - View Extension

extension View {
    /// Apply Apple Liquid Glass effect with preset style
    /// - Parameters:
    ///   - style: Preset style (subtle, standard, prominent, floating)
    ///   - cornerRadius: Corner radius for the glass shape
    func liquidGlass(
        _ style: GlassVisualStyle = .standard,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(LiquidGlassModifier(style: style, cornerRadius: cornerRadius))
    }
    
    /// Apply Apple Liquid Glass effect to a capsule shape
    /// - Parameter style: Preset style
    func liquidGlassCapsule(
        _ style: GlassVisualStyle = .standard
    ) -> some View {
        modifier(LiquidGlassModifier(style: style, cornerRadius: 999))
    }
    
    /// Apply Apple Liquid Glass effect to a circle shape
    /// - Parameter style: Preset style
    func liquidGlassCircle(
        _ style: GlassVisualStyle = .standard
    ) -> some View {
        modifier(LiquidGlassModifier(style: style, cornerRadius: 999))
    }
}

// MARK: - Liquid Glass Shape Builder

/// Helper to build custom liquid glass backgrounds
struct LiquidGlassShape<S: InsettableShape>: View {
    let shape: S
    let style: GlassVisualStyle
    
    var body: some View {
        ZStack {
            // Base material
            shape
                .fill(.ultraThinMaterial)
            
            // Depth gradient
            shape
                .fill(depthGradient)
            
            // Highlight
            shape
                .fill(highlightGradient)
            
            // Border
            shape
                .strokeBorder(borderGradient, lineWidth: 0.5)
        }
    }
    
    private var depthGradient: LinearGradient {
        let opacities: (top: Double, middle: Double, bottom: Double) = {
            switch style {
            case .subtle: return (0.06, 0.02, 0.03)
            case .standard: return (0.08, 0.02, 0.04)
            case .prominent: return (0.10, 0.03, 0.05)
            case .floating: return (0.08, 0.02, 0.04)
            }
        }()
        
        return LinearGradient(
            colors: [
                Color.white.opacity(opacities.top),
                Color.white.opacity(opacities.middle),
                Color.white.opacity(opacities.bottom)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var highlightGradient: LinearGradient {
        let opacity: Double = {
            switch style {
            case .subtle: return 0.10
            case .standard: return 0.12
            case .prominent: return 0.15
            case .floating: return 0.15
            }
        }()
        
        return LinearGradient(
            colors: [Color.white.opacity(opacity), .clear],
            startPoint: .top,
            endPoint: .center
        )
    }
    
    private var borderGradient: LinearGradient {
        let opacities: (top: Double, middle: Double, bottom: Double) = {
            switch style {
            case .subtle: return (0.12, 0.05, 0.08)
            case .standard: return (0.15, 0.05, 0.10)
            case .prominent: return (0.25, 0.08, 0.15)
            case .floating: return (0.20, 0.05, 0.10)
            }
        }()
        
        return LinearGradient(
            colors: [
                Color.white.opacity(opacities.top),
                Color.white.opacity(opacities.middle),
                Color.white.opacity(opacities.bottom)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preset Glass Components

/// Ready-to-use liquid glass button (generic version, distinct from LiquidGlassButton)
struct GlassButtonView<Label: View>: View {
    let action: () -> Void
    let style: GlassVisualStyle
    @ViewBuilder let label: () -> Label

    @State private var isPressed = false

    init(
        style: GlassVisualStyle = .standard,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.style = style
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: action) {
            label()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .liquidGlassCapsule(style)
        }
        .buttonStyle(GlassButtonStyle())
    }
}

private struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Liquid Glass Card

/// Ready-to-use liquid glass card container
struct LiquidGlassCard<Content: View>: View {
    let style: GlassVisualStyle
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        style: GlassVisualStyle = .standard,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .liquidGlass(style, cornerRadius: cornerRadius)
    }
}

// MARK: - Preview Helpers

#Preview("Liquid Glass Styles") {
    ZStack {
        // Rich background to show transparency
        LinearGradient(
            colors: [
                Color(hex: "1a1a2e"),
                Color(hex: "16213e"),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // Add some background elements
        VStack {
            ForEach(0..<8) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 60)
                    .padding(.horizontal)
            }
        }
        
        VStack(spacing: 30) {
            Text("Liquid Glass Styles")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.white)
                .padding(.top, 60)
            
            // Subtle
            VStack(alignment: .leading, spacing: 8) {
                Text("Subtle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Low emphasis components")
                    .padding()
                    .liquidGlassCapsule(.subtle)
            }
            
            // Standard
            VStack(alignment: .leading, spacing: 8) {
                Text("Standard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Card")
                        .font(.headline)
                    Text("Most common cards and rows")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .liquidGlass(.standard, cornerRadius: 16)
            }
            
            // Prominent
            VStack(alignment: .leading, spacing: 8) {
                Text("Prominent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    Text("Focused Input")
                        .font(.headline)
                    Text("High emphasis UI elements")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .liquidGlass(.prominent, cornerRadius: 20)
            }
            
            // Floating
            VStack(alignment: .leading, spacing: 8) {
                Text("Floating")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 20) {
                    Image(systemName: "house.fill")
                    Image(systemName: "calendar")
                    Image(systemName: "timer")
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Image(systemName: "book")
                }
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .padding()
                .liquidGlassCapsule(.floating)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}

#Preview("Glass Button") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            GlassButtonView(style: .standard, action: {}) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Task")
                }
                .foregroundStyle(.white)
            }

            GlassButtonView(style: .prominent, action: {}) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("AI Magic")
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "06B6D4")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
    }
}

#Preview("Glass Cards") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 16) {
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Standard Card")
                            .font(.headline)
                        Text("This is a liquid glass card with standard emphasis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                
                LiquidGlassCard(style: .prominent, cornerRadius: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prominent Card")
                            .font(.title3.weight(.semibold))
                        Text("Higher emphasis with more definition")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Featured Content")
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .padding()
        }
    }
}
