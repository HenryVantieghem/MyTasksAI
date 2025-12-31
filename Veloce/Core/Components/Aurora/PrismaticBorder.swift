//
//  PrismaticBorder.swift
//  Veloce
//
//  DEPRECATED: Prismatic Border Effects
//  These custom effects have been replaced with native iOS 26 Liquid Glass.
//
//  Migration Guide:
//  - Replace .prismaticBorder() with simple .shadow() + .clipShape()
//  - Use native .glassEffect() for glass appearance
//  - Remove custom animated borders for pure Apple aesthetic
//
//  Example:
//  // Before:
//  Button("Action") { }.prismaticBorder(Capsule(), style: .ai)
//
//  // After:
//  Button("Action") { }
//      .clipShape(Capsule())
//      .shadow(color: .cyan.opacity(0.3), radius: 12, y: 4)
//

import SwiftUI

// MARK: - DEPRECATED - Use native shadows instead

// MARK: - Prismatic Border Style

public enum PrismaticBorderStyle: Equatable {
    /// Full spectrum rotating border
    case spectrum
    /// Cyan-violet AI gradient
    case ai
    /// Category-based color
    case category(String?)
    /// Custom colors
    case custom([Color])
    /// Recording state (red pulsing)
    case recording
    /// Success celebration (green-gold)
    case success

    public static func == (lhs: PrismaticBorderStyle, rhs: PrismaticBorderStyle) -> Bool {
        switch (lhs, rhs) {
        case (.spectrum, .spectrum): return true
        case (.ai, .ai): return true
        case let (.category(a), .category(b)): return a == b
        case let (.custom(a), .custom(b)): return a.count == b.count
        case (.recording, .recording): return true
        case (.success, .success): return true
        default: return false
        }
    }
}

// MARK: - Prismatic Border Modifier

public struct PrismaticBorderModifier<S: Shape>: ViewModifier {
    let shape: S
    let style: PrismaticBorderStyle
    let lineWidth: CGFloat
    let glowRadius: CGFloat
    let animated: Bool

    @State private var rotationPhase: Double = 0
    @State private var pulseIntensity: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        shape: S,
        style: PrismaticBorderStyle = .spectrum,
        lineWidth: CGFloat = 1.5,
        glowRadius: CGFloat = 8,
        animated: Bool = true
    ) {
        self.shape = shape
        self.style = style
        self.lineWidth = lineWidth
        self.glowRadius = glowRadius
        self.animated = animated
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    // Outer glow
                    shape
                        .stroke(
                            borderGradient,
                            lineWidth: lineWidth + 2
                        )
                        .blur(radius: glowRadius)
                        .opacity(pulseIntensity * 0.6)

                    // Main border
                    shape
                        .stroke(
                            borderGradient,
                            lineWidth: lineWidth
                        )
                        .blur(radius: 0.5)
                }
            )
            .onAppear {
                if animated && !reduceMotion {
                    startAnimations()
                }
            }
    }

    private var borderGradient: AngularGradient {
        AngularGradient(
            colors: borderColors,
            center: .center,
            startAngle: .degrees(rotationPhase),
            endAngle: .degrees(rotationPhase + 360)
        )
    }

    private var borderColors: [Color] {
        switch style {
        case .spectrum:
            return Aurora.Gradients.auroraSpectrum

        case .ai:
            return [
                Aurora.Colors.electricCyan,
                Aurora.Colors.deepPlasma,
                Aurora.Colors.borealisViolet,
                Aurora.Colors.electricCyan
            ]

        case .category(let category):
            let baseColor = categoryColor(category)
            return [
                baseColor,
                baseColor.opacity(0.7),
                Aurora.Colors.stellarWhite.opacity(0.3),
                baseColor.opacity(0.7),
                baseColor
            ]

        case .custom(let colors):
            return colors + [colors.first ?? .clear]

        case .recording:
            return [
                Aurora.Colors.error,
                Aurora.Colors.stellarMagenta,
                Aurora.Colors.error.opacity(0.7),
                Aurora.Colors.error
            ]

        case .success:
            return [
                Aurora.Colors.prismaticGreen,
                Aurora.Colors.cosmicGold,
                Aurora.Colors.prismaticGreen.opacity(0.7),
                Aurora.Colors.prismaticGreen
            ]
        }
    }

    private func categoryColor(_ category: String?) -> Color {
        switch category?.lowercased() {
        case "work": return Aurora.Colors.categoryWork
        case "personal": return Aurora.Colors.categoryPersonal
        case "creative": return Aurora.Colors.categoryCreative
        case "learning": return Aurora.Colors.categoryLearning
        case "health": return Aurora.Colors.categoryHealth
        default: return Aurora.Colors.electricCyan
        }
    }

    private func startAnimations() {
        // Rotation
        withAnimation(
            .linear(duration: AuroraMotion.Duration.prismaticRotation)
            .repeatForever(autoreverses: false)
        ) {
            rotationPhase = 360
        }

        // Pulse
        withAnimation(
            .easeInOut(duration: style == .recording ? 0.5 : AuroraMotion.Duration.glowPulse)
            .repeatForever(autoreverses: true)
        ) {
            pulseIntensity = style == .recording ? 1.0 : 0.8
        }
    }
}

// MARK: - View Extension

extension View {

    /// Apply prismatic rotating border
    /// - Warning: DEPRECATED - Use `.shadow()` instead for native Liquid Glass aesthetic
    @available(*, deprecated, message: "Use .shadow(color:radius:y:) instead for native iOS 26 aesthetic")
    public func prismaticBorder<S: Shape>(
        _ shape: S,
        style: PrismaticBorderStyle = .spectrum,
        lineWidth: CGFloat = 1.5,
        glowRadius: CGFloat = 8,
        animated: Bool = true
    ) -> some View {
        self.modifier(
            PrismaticBorderModifier(
                shape: shape,
                style: style,
                lineWidth: lineWidth,
                glowRadius: glowRadius,
                animated: animated
            )
        )
    }

    /// Apply AI-style prismatic border (cyan-violet)
    /// - Warning: DEPRECATED - Use `.shadow()` instead
    @available(*, deprecated, message: "Use .shadow(color: .cyan.opacity(0.3), radius: 12, y: 4) instead")
    public func aiBorder<S: Shape>(
        _ shape: S,
        lineWidth: CGFloat = 1.5,
        animated: Bool = true
    ) -> some View {
        self.prismaticBorder(shape, style: .ai, lineWidth: lineWidth, animated: animated)
    }

    /// Apply category-colored prismatic border
    /// - Warning: DEPRECATED - Use `.shadow()` instead
    @available(*, deprecated, message: "Use .shadow(color:radius:y:) with category color instead")
    public func categoryBorder<S: Shape>(
        _ shape: S,
        category: String?,
        lineWidth: CGFloat = 1.5,
        animated: Bool = true
    ) -> some View {
        self.prismaticBorder(shape, style: .category(category), lineWidth: lineWidth, animated: animated)
    }
}

// MARK: - Chromatic Aberration Effect

/// Chromatic aberration (RGB color splitting) effect
public struct ChromaticAberration<Content: View>: View {

    let content: Content
    let offset: CGFloat
    let opacity: CGFloat

    public init(
        offset: CGFloat = 2,
        opacity: CGFloat = 0.3,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.offset = offset
        self.opacity = opacity
    }

    public var body: some View {
        ZStack {
            // Red channel (offset right)
            content
                .colorMultiply(.red)
                .opacity(opacity)
                .offset(x: offset, y: 0)

            // Blue channel (offset left)
            content
                .colorMultiply(.blue)
                .opacity(opacity)
                .offset(x: -offset, y: 0)

            // Green channel (center)
            content
                .colorMultiply(.green)
                .opacity(opacity)

            // Original content
            content
        }
    }
}

// MARK: - View Extension for Chromatic

extension View {

    /// Apply chromatic aberration effect
    public func chromaticAberration(
        offset: CGFloat = 2,
        opacity: CGFloat = 0.3
    ) -> some View {
        ChromaticAberration(offset: offset, opacity: opacity) {
            self
        }
    }
}

// MARK: - Aurora Edge (Task Card Category Bar)

/// Glowing category edge for task cards
public struct AuroraEdge: View {

    let category: String?
    let height: CGFloat
    let animated: Bool

    @State private var glowIntensity: CGFloat = 0.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        category: String?,
        height: CGFloat = .infinity,
        animated: Bool = true
    ) {
        self.category = category
        self.height = height
        self.animated = animated
    }

    private var edgeColor: Color {
        switch category?.lowercased() {
        case "work": return Aurora.Colors.categoryWork
        case "personal": return Aurora.Colors.categoryPersonal
        case "creative": return Aurora.Colors.categoryCreative
        case "learning": return Aurora.Colors.categoryLearning
        case "health": return Aurora.Colors.categoryHealth
        default: return Aurora.Colors.electricCyan
        }
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            // Glow halo
            RoundedRectangle(cornerRadius: 2)
                .fill(edgeColor)
                .frame(width: 4)
                .blur(radius: 8)
                .opacity(glowIntensity)
                .offset(x: 2)

            // Main edge
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [edgeColor, edgeColor.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)

            // Shimmer line
            if !reduceMotion && animated {
                ShimmerLine(color: edgeColor)
            }
        }
        .frame(height: height)
        .onAppear {
            if animated && !reduceMotion {
                withAnimation(
                    .easeInOut(duration: AuroraMotion.Duration.breathingCycle)
                    .repeatForever(autoreverses: true)
                ) {
                    glowIntensity = 0.7
                }
            }
        }
    }
}

// MARK: - Shimmer Line

struct ShimmerLine: View {
    let color: Color

    @State private var offset: CGFloat = -1

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, color.opacity(0.8), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: 20)
            .offset(y: offset * 100)
            .onAppear {
                withAnimation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false)
                ) {
                    offset = 1
                }
            }
    }
}

// MARK: - Interactive Glow Border

/// Border that responds to interaction state
public struct InteractiveGlowBorder<S: Shape>: View {

    let shape: S
    let color: Color
    let isActive: Bool
    let lineWidth: CGFloat

    @State private var glowIntensity: CGFloat = 0

    public init(
        shape: S,
        color: Color = Aurora.Colors.electricCyan,
        isActive: Bool = false,
        lineWidth: CGFloat = 2
    ) {
        self.shape = shape
        self.color = color
        self.isActive = isActive
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            // Glow
            shape
                .stroke(color, lineWidth: lineWidth + 4)
                .blur(radius: 12)
                .opacity(glowIntensity * 0.5)

            // Border
            shape
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(glowIntensity), color.opacity(glowIntensity * 0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
        }
        .onChange(of: isActive) { _, newValue in
            withAnimation(AuroraMotion.Spring.ui) {
                glowIntensity = newValue ? 1.0 : 0.2
            }
        }
        .onAppear {
            glowIntensity = isActive ? 1.0 : 0.2
        }
    }
}

// MARK: - Preview

#Preview("Prismatic Borders") {
    ScrollView {
        VStack(spacing: 30) {
            // Spectrum
            RoundedRectangle(cornerRadius: 16)
                .fill(Aurora.Colors.voidNebula)
                .frame(height: 80)
                .prismaticBorder(RoundedRectangle(cornerRadius: 16), style: .spectrum)
                .overlay(Text("Spectrum").foregroundStyle(.white))

            // AI
            RoundedRectangle(cornerRadius: 16)
                .fill(Aurora.Colors.voidNebula)
                .frame(height: 80)
                .aiBorder(RoundedRectangle(cornerRadius: 16))
                .overlay(Text("AI Border").foregroundStyle(.white))

            // Category
            RoundedRectangle(cornerRadius: 16)
                .fill(Aurora.Colors.voidNebula)
                .frame(height: 80)
                .categoryBorder(RoundedRectangle(cornerRadius: 16), category: "creative")
                .overlay(Text("Creative Category").foregroundStyle(.white))

            // Recording
            Capsule()
                .fill(Aurora.Colors.voidNebula)
                .frame(height: 56)
                .prismaticBorder(Capsule(), style: .recording)
                .overlay(Text("Recording").foregroundStyle(.white))

            // Success
            RoundedRectangle(cornerRadius: 16)
                .fill(Aurora.Colors.voidNebula)
                .frame(height: 80)
                .prismaticBorder(RoundedRectangle(cornerRadius: 16), style: .success)
                .overlay(Text("Success").foregroundStyle(.white))

            // Aurora Edge
            HStack(spacing: 0) {
                AuroraEdge(category: "work")
                    .frame(width: 20)

                VStack(alignment: .leading) {
                    Text("Task Card")
                        .font(Aurora.Typography.headline)
                    Text("With aurora edge")
                        .font(Aurora.Typography.callout)
                        .foregroundStyle(Aurora.Colors.textSecondary)
                }
                .padding()

                Spacer()
            }
            .frame(height: 80)
            .background(Aurora.Colors.voidNebula)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Chromatic aberration
            Image(systemName: "sparkles")
                .dynamicTypeFont(base: 60)
                .foregroundStyle(Aurora.Colors.electricCyan)
                .chromaticAberration(offset: 3)
        }
        .padding()
        .foregroundStyle(Aurora.Colors.textPrimary)
    }
    .background(Aurora.Colors.voidCosmos)
}
