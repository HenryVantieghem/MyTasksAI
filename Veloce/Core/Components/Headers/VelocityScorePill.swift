//
//  VelocityScorePill.swift
//  Veloce
//
//  Tappable pill showing Velocity Score (0-100) with tier icon and gradient
//  Part of the universal header component
//

import SwiftUI

struct VelocityScorePill: View {
    let score: Int
    let tier: ScoreTier
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: tier.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tier.gradient)

                Text("\(score)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: score)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            VelocityScorePill(score: 47, tier: .building, onTap: {})
            VelocityScorePill(score: 78, tier: .excellent, onTap: {})
            VelocityScorePill(score: 95, tier: .legendary, onTap: {})
        }
    }
}
