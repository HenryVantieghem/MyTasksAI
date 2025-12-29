//
//  AuroraGlass.swift
//  Veloce
//
//  Aurora Glass System - iOS 17-26 Compatible Glass Effects
//  Liquid Glass on iOS 26+, elegant fallbacks on earlier versions
//

import SwiftUI

// MARK: - Aurora Glass System

/// Glass effect variants for Aurora Design System
public enum AuroraGlassStyle {
    /// Standard glass - most versatile, full adaptive behavior
    case standard

    /// Interactive glass - for buttons and controls
    case interactive

    /// Subtle glass - lighter effect for secondary elements
    case subtle

    /// Prismatic glass - with chromatic aberration border
    case prismatic

    /// Plasma glass - with glowing, animated border
    case plasma

    /// Clear glass - more transparent (use sparingly)
    case clear
}

// MARK: - View Extension

extension View {

    /// Apply Aurora glass effect with iOS version compatibility
    /// - Parameters:
    ///   - style: The glass style to apply
    ///   - shape: The shape for the glass effect
    ///   - tint: Optional tint color
    /// - Returns: View with glass effect
    @ViewBuilder
    public func auroraGlass<S: Shape>(
        _ style: AuroraGlassStyle = .standard,
        in shape: S = RoundedRectangle(cornerRadius: Aurora.Radius.standard),
        tint: Color? = nil
    ) -> some View {
        if #available(iOS 26, *) {
            self.modifier(AuroraGlassModifierIOS26(style: style, shape: shape, tint: tint))
        } else {
            self.modifier(AuroraGlassModifierFallback(style: style, shape: shape, tint: tint))
        }
    }

    /// Apply Aurora glass capsule (convenience)
    @ViewBuilder
    public func auroraGlassCapsule(
        _ style: AuroraGlassStyle = .standard,
        tint: Color? = nil
    ) -> some View {
        auroraGlass(style, in: Capsule(), tint: tint)
    }

    /// Apply Aurora glass card (convenience)
    @ViewBuilder
    public func auroraGlassCard(
        cornerRadius: CGFloat = Aurora.Radius.standard,
        tint: Color? = nil
    ) -> some View {
        auroraGlass(.standard, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), tint: tint)
    }

    /// Apply solid void card (for content layer - NOT glass)
    public func auroraVoidCard(
        cornerRadius: CGFloat = Aurora.Radius.standard,
        category: String? = nil
    ) -> some View {
        self.modifier(AuroraVoidCardModifier(cornerRadius: cornerRadius, category: category))
    }
}

// MARK: - iOS 26+ Glass Modifier (Native Liquid Glass)

@available(iOS 26, *)
struct AuroraGlassModifierIOS26<S: Shape>: ViewModifier {
    let style: AuroraGlassStyle
    let shape: S
    let tint: Color?

    func body(content: Content) -> some View {
        switch style {
        case .standard:
            content
                .glassEffect(.regular, in: shape)
                .tint(tint)

        case .interactive:
            content
                .glassEffect(.regular.interactive(true), in: shape)
                .tint(tint)

        case .subtle:
            content
                .glassEffect(.regular, in: shape)
                .opacity(0.85)
                .tint(tint)

        case .prismatic:
            content
                .glassEffect(.regular, in: shape)
                .overlay(
                    PrismaticBorderOverlay(shape: shape)
                )
                .tint(tint)

        case .plasma:
            content
                .glassEffect(.regular.interactive(true), in: shape)
                .overlay(
                    PlasmaBorderOverlay(shape: shape)
                )
                .tint(tint)

        case .clear:
            content
                .glassEffect(.clear, in: shape)
                .tint(tint)
        }
    }
}

// MARK: - iOS 17-25 Fallback Glass Modifier

struct AuroraGlassModifierFallback<S: Shape>: ViewModifier {
    let style: AuroraGlassStyle
    let shape: S
    let tint: Color?

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        switch style {
        case .standard:
            standardGlass(content)

        case .interactive:
            interactiveGlass(content)

        case .subtle:
            subtleGlass(content)

        case .prismatic:
            prismaticGlass(content)

        case .plasma:
            plasmaGlass(content)

        case .clear:
            clearGlass(content)
        }
    }

    // MARK: Standard Glass

    @ViewBuilder
    private func standardGlass(_ content: Content) -> some View {
        content
            .background(
                shape
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                (tint ?? Aurora.Colors.electricCyan).opacity(0.25),
                                Aurora.Colors.borealisViolet.opacity(0.15),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: (tint ?? Aurora.Colors.electricCyan).opacity(0.15),
                radius: 12,
                x: 0,
                y: 4
            )
    }

    // MARK: Interactive Glass

    @ViewBuilder
    private func interactiveGlass(_ content: Content) -> some View {
        content
            .background(
                shape
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                (tint ?? Aurora.Colors.electricCyan).opacity(0.35),
                                Aurora.Colors.borealisViolet.opacity(0.25),
                                .white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: (tint ?? Aurora.Colors.electricCyan).opacity(0.2),
                radius: 16,
                x: 0,
                y: 6
            )
    }

    // MARK: Subtle Glass

    @ViewBuilder
    private func subtleGlass(_ content: Content) -> some View {
        content
            .background(
                shape
                    .fill(.thinMaterial)
                    .opacity(0.7)
            )
            .overlay(
                shape
                    .stroke(
                        Color.white.opacity(0.08),
                        lineWidth: 0.5
                    )
            )
    }

    // MARK: Prismatic Glass

    @ViewBuilder
    private func prismaticGlass(_ content: Content) -> some View {
        content
            .background(
                shape
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                PrismaticBorderOverlay(shape: shape)
            )
            .shadow(
                color: Aurora.Colors.electricCyan.opacity(0.2),
                radius: 16,
                x: 0,
                y: 6
            )
    }

    // MARK: Plasma Glass

    @ViewBuilder
    private func plasmaGlass(_ content: Content) -> some View {
        content
            .background(
                shape
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                PlasmaBorderOverlay(shape: shape)
            )
            .shadow(
                color: Aurora.Colors.electricCyan.opacity(0.25),
                radius: 20,
                x: 0,
                y: 8
            )
    }

    // MARK: Clear Glass

    @ViewBuilder
    private func clearGlass(_ content: Content) -> some View {
        content
            .background(
                shape
                    .fill(.thinMaterial)
                    .opacity(0.5)
            )
            .overlay(
                shape
                    .stroke(
                        Color.white.opacity(0.1),
                        lineWidth: 0.5
                    )
            )
    }
}

// MARK: - Prismatic Border Overlay

struct PrismaticBorderOverlay<S: Shape>: View {
    let shape: S

    @State private var phase: Double = 0

    var body: some View {
        shape
            .stroke(
                AngularGradient(
                    colors: [
                        Aurora.Colors.electricCyan.opacity(0.6),
                        Aurora.Colors.deepPlasma.opacity(0.4),
                        Aurora.Colors.borealisViolet.opacity(0.5),
                        Aurora.Colors.stellarMagenta.opacity(0.4),
                        Aurora.Colors.cosmicGold.opacity(0.3),
                        Aurora.Colors.prismaticGreen.opacity(0.4),
                        Aurora.Colors.electricCyan.opacity(0.6)
                    ],
                    center: .center,
                    startAngle: .degrees(phase),
                    endAngle: .degrees(phase + 360)
                ),
                lineWidth: 1.5
            )
            .blur(radius: 0.5)
            .onAppear {
                withAnimation(
                    .linear(duration: AuroraMotion.Duration.prismaticRotation)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 360
                }
            }
    }
}

// MARK: - Plasma Border Overlay

struct PlasmaBorderOverlay<S: Shape>: View {
    let shape: S

    @State private var phase: Double = 0
    @State private var glowIntensity: CGFloat = 0.3

    var body: some View {
        ZStack {
            // Outer glow
            shape
                .stroke(
                    AngularGradient(
                        colors: [
                            Aurora.Colors.electricCyan,
                            Aurora.Colors.borealisViolet,
                            Aurora.Colors.stellarMagenta,
                            Aurora.Colors.electricCyan
                        ],
                        center: .center,
                        startAngle: .degrees(phase),
                        endAngle: .degrees(phase + 360)
                    ),
                    lineWidth: 3
                )
                .blur(radius: 8)
                .opacity(glowIntensity)

            // Inner sharp border
            shape
                .stroke(
                    AngularGradient(
                        colors: [
                            Aurora.Colors.electricCyan.opacity(0.8),
                            Aurora.Colors.borealisViolet.opacity(0.6),
                            Aurora.Colors.stellarMagenta.opacity(0.7),
                            Aurora.Colors.electricCyan.opacity(0.8)
                        ],
                        center: .center,
                        startAngle: .degrees(phase),
                        endAngle: .degrees(phase + 360)
                    ),
                    lineWidth: 1.5
                )
        }
        .onAppear {
            // Rotation
            withAnimation(
                .linear(duration: 8)
                .repeatForever(autoreverses: false)
            ) {
                phase = 360
            }

            // Glow pulse
            withAnimation(
                .easeInOut(duration: AuroraMotion.Duration.glowPulse)
                .repeatForever(autoreverses: true)
            ) {
                glowIntensity = 0.6
            }
        }
    }
}

// MARK: - Void Card Modifier (Solid background for content)

struct AuroraVoidCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let category: String?

    private var categoryColor: Color {
        switch category?.lowercased() {
        case "work": return Aurora.Colors.categoryWork
        case "personal": return Aurora.Colors.categoryPersonal
        case "creative": return Aurora.Colors.categoryCreative
        case "learning": return Aurora.Colors.categoryLearning
        case "health": return Aurora.Colors.categoryHealth
        default: return Aurora.Colors.electricCyan
        }
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Aurora.Colors.voidNebula)
            )
            .overlay(
                // Aurora edge on left (4px category bar)
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(categoryColor)
                        .frame(width: 4)
                        .shadow(color: categoryColor.opacity(0.5), radius: 8, x: 0, y: 0)

                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .shadow(
                color: categoryColor.opacity(0.25),
                radius: 12,
                x: 0,
                y: 4
            )
            .shadow(
                color: .black.opacity(0.3),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Glass Container (Performance optimization)

/// Container for grouping multiple glass elements
/// Reduces rendering overhead and enables morphing
public struct AuroraGlassContainer<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 26, *) {
            // Use GlassEffectContainer for iOS 26+
            GlassEffectContainer {
                content
            }
        } else {
            // Simple container for fallback
            content
        }
    }
}

// MARK: - Preview

#Preview("Aurora Glass Styles") {
    ScrollView {
        VStack(spacing: Aurora.Spacing.xl) {
            // Standard
            Text("Standard Glass")
                .font(Aurora.Typography.headline)
                .foregroundStyle(Aurora.Colors.textPrimary)
                .padding()
                .auroraGlass(.standard, in: RoundedRectangle(cornerRadius: 16))

            // Interactive
            Text("Interactive Glass")
                .font(Aurora.Typography.headline)
                .foregroundStyle(Aurora.Colors.textPrimary)
                .padding()
                .auroraGlass(.interactive, in: RoundedRectangle(cornerRadius: 16))

            // Prismatic
            Text("Prismatic Glass")
                .font(Aurora.Typography.headline)
                .foregroundStyle(Aurora.Colors.textPrimary)
                .padding()
                .auroraGlass(.prismatic, in: RoundedRectangle(cornerRadius: 16))

            // Plasma
            Text("Plasma Glass")
                .font(Aurora.Typography.headline)
                .foregroundStyle(Aurora.Colors.textPrimary)
                .padding()
                .auroraGlass(.plasma, in: RoundedRectangle(cornerRadius: 16))

            // Capsule
            Text("Glass Capsule")
                .font(Aurora.Typography.bodyBold)
                .foregroundStyle(Aurora.Colors.textPrimary)
                .padding(.horizontal, Aurora.Spacing.lg)
                .padding(.vertical, Aurora.Spacing.sm)
                .auroraGlassCapsule(.interactive)

            // Void Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Void Card (Content Layer)")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
                Text("Solid background for task cards")
                    .font(Aurora.Typography.callout)
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .auroraVoidCard(category: "work")

            // Another void card
            VStack(alignment: .leading, spacing: 8) {
                Text("Creative Task")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
                Text("With magenta aurora edge")
                    .font(Aurora.Typography.callout)
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .auroraVoidCard(category: "creative")
        }
        .padding(Aurora.Spacing.lg)
    }
    .background(Aurora.Colors.voidCosmos)
}
