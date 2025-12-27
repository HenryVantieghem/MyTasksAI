//
//  VelocityScorePill.swift
//  Veloce
//
//  Premium pill showing Velocity Score (0-100) with tier icon, gradient, and glow
//  Part of the universal header component
//

import SwiftUI

struct VelocityScorePill: View {
    let score: Int
    let tier: ScoreTier
    let onTap: () -> Void

    // Animation state
    @State private var glowPhase: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Glow opacity based on animation phase
    private var glowOpacity: Double {
        reduceMotion ? 0.4 : (glowPhase ? 0.55 : 0.3)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 7) {
                // Filled icon with tier gradient
                Image(systemName: tier.iconFilled)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tier.gradient)

                // Score number
                Text("\(score)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        tier.gradient.opacity(0.5),
                        lineWidth: 1
                    )
            )
            // Tier-colored outer glow (layered for depth)
            .shadow(color: tier.color.opacity(glowOpacity), radius: 8, x: 0, y: 0)
            .shadow(color: tier.color.opacity(glowOpacity * 0.4), radius: 16, x: 0, y: 2)
        }
        .buttonStyle(PillButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft), trigger: score)
        .onAppear {
            startGlowAnimation()
        }
    }

    private func startGlowAnimation() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowPhase = true
        }
    }
}

// MARK: - Pill Button Style

struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 24) {
            // All tiers
            VelocityScorePill(score: 12, tier: .beginning, onTap: {})
            VelocityScorePill(score: 28, tier: .starting, onTap: {})
            VelocityScorePill(score: 47, tier: .building, onTap: {})
            VelocityScorePill(score: 68, tier: .good, onTap: {})
            VelocityScorePill(score: 82, tier: .excellent, onTap: {})
            VelocityScorePill(score: 95, tier: .legendary, onTap: {})
        }
    }
}
