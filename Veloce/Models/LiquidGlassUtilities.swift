//
//  LiquidGlassUtilities.swift
//  MyTasksAI
//
//  Minimal Utility Extensions for Liquid Glass
//  Uses native iOS 26 APIs with pre-iOS 26 fallbacks
//

import SwiftUI

// MARK: - Liquid Content Card Modifiers

extension View {
    /// Content layer card with solid background (NOT glass - per Apple guidelines)
    /// Use for: list items, task cards, content containers
    func liquidContentCard(
        cornerRadius: CGFloat = 16,
        tint: Color? = nil
    ) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemBackground))
                    .overlay {
                        if let tint = tint {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(tint.opacity(0.08))
                        }
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Elevated content card with shadow
    func liquidElevatedCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.tertiarySystemBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }

    /// Void background for dark theme
    func liquidVoidBackground() -> some View {
        self.background(LiquidGlassDesignSystem.Void.cosmos)
    }
}

// MARK: - Simple Glow Effect

extension View {
    /// Simple glow shadow (no animation - per pure native approach)
    func liquidGlow(
        color: Color = LiquidGlassDesignSystem.VibrantAccents.electricCyan,
        radius: CGFloat = 16,
        intensity: Double = 0.5
    ) -> some View {
        self.shadow(color: color.opacity(intensity), radius: radius, y: 0)
    }
}

// MARK: - Gradient Progress Bar

struct GradientProgressBar: View {
    let progress: Double
    let height: CGFloat
    let cornerRadius: CGFloat
    let colors: [Color]

    init(
        progress: Double,
        height: CGFloat = 8,
        cornerRadius: CGFloat = 4,
        colors: [Color] = [
            LiquidGlassDesignSystem.VibrantAccents.electricCyan,
            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
        ]
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.cornerRadius = cornerRadius
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.1))

                // Progress
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Liquid Button Press Style

struct LiquidButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == LiquidButtonPressStyle {
    static var liquidPress: LiquidButtonPressStyle { LiquidButtonPressStyle() }
}

// MARK: - Cosmic Tap Button Style (Legacy Compatibility)

struct CosmicTapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CosmicTapButtonStyle {
    static var cosmicTap: CosmicTapButtonStyle { CosmicTapButtonStyle() }
}

// MARK: - Preview

#Preview("Utilities") {
    ZStack {
        LiquidGlassDesignSystem.Void.cosmos
            .ignoresSafeArea()

        VStack(spacing: 24) {
            // Content cards
            VStack(spacing: 12) {
                Text("Content Card")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .liquidContentCard()

                Text("Elevated Card")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .liquidElevatedCard()

                Text("Tinted Card")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .liquidContentCard(tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan)
            }
            .padding(.horizontal, 20)

            // Progress bar
            GradientProgressBar(progress: 0.7)
                .padding(.horizontal, 20)

            // Button with glow
            Button("Glowing Button") { }
                .buttonStyle(.borderedProminent)
                .tint(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                .liquidGlow()
        }
    }
    .preferredColorScheme(.dark)
}
