//
//  StatsPillView.swift
//  Veloce
//
//  Stats Pill View
//  Compact tappable stats display for header
//

import SwiftUI

// MARK: - Stats Pill View

struct StatsPillView: View {
    let streak: Int
    let points: Int
    let level: Int
    let onTap: () -> Void

    @State private var glowPulse: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.accentSecondary)
                        .symbolEffect(.pulse, options: .repeating, value: streak > 0)

                    Text("\(streak)")
                        .font(AppTypography.stats)
                        .foregroundStyle(AppColors.textPrimary)
                }

                // Points
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.accentSecondary)

                    Text(formatPoints(points))
                        .font(AppTypography.stats)
                        .foregroundStyle(AppColors.textPrimary)
                        .contentTransition(.numericText())
                }

                // Level badge
                Text("\(level)")
                    .font(AppTypography.statsBadge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accentPrimary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
        }
        .buttonStyle(.plain)
        .onAppear {
            if streak > 0 {
                withAnimation(Theme.Animation.aiPulse) {
                    glowPulse = true
                }
            }
        }
    }

    // MARK: - Pill Background

    private var pillBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule()
                    .stroke(
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
            )
    }

    // MARK: - Glow Overlay

    private var glowOverlay: some View {
        Capsule()
            .stroke(Theme.Colors.streakOrange, lineWidth: 2)
            .blur(radius: 4)
            .opacity(streak > 0 && glowPulse ? 0.3 : 0)
    }

    // MARK: - Helpers

    private func formatPoints(_ points: Int) -> String {
        if points >= 10000 {
            return String(format: "%.1fK", Double(points) / 1000)
        } else if points >= 1000 {
            return String(format: "%.1fK", Double(points) / 1000)
        }
        return "\(points)"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StatsPillView(streak: 5, points: 1250, level: 3) { }
        StatsPillView(streak: 0, points: 500, level: 1) { }
        StatsPillView(streak: 30, points: 15000, level: 12) { }
    }
    .padding()
    .background(AppColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
