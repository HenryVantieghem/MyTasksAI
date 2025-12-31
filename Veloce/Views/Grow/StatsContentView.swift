//
//  StatsContentView.swift
//  Veloce
//
//  Utopian Design System - Growth Stats Dashboard
//  Stats segment with velocity ring, gold gamification, and time-aware gradients
//

import SwiftUI

struct StatsContentView: View {
    let velocityScore: Double
    let streak: Int
    let longestStreak: Int
    let tasksCompleted: Int
    let tasksCompletedToday: Int
    let dailyGoal: Int
    let focusHours: Double
    let completionRate: Double
    let level: Int
    let totalPoints: Int
    let levelProgress: Double

    @Environment(\.responsiveLayout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAnimated = false
    @State private var orbRotation: Double = 0
    @State private var glowPulse: CGFloat = 0.5

    // Adaptive columns based on device
    private var gridColumns: [GridItem] {
        let columnCount: Int
        switch layout.deviceType {
        case .iPhoneSE, .iPhoneStandard, .iPhoneProMax:
            columnCount = 2
        case .iPadMini, .iPad:
            columnCount = 3
        case .iPadPro11, .iPadPro13:
            columnCount = layout.isLandscape ? 4 : 3
        }
        return Array(repeating: GridItem(.flexible(), spacing: layout.spacing), count: columnCount)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: layout.spacing * 1.5) {
                // Velocity Energy Core (Hero)
                velocityEnergyCore
                    .padding(.top, layout.spacing)

                // Energy Stats Grid - adaptive columns
                energyStatsGrid

                // Weekly Trend with aurora styling
                weeklyTrendCard

                // Streaks Section with flame effect
                if streak > 0 {
                    auroraStreaksCard
                }

                Spacer(minLength: layout.bottomSafeArea)
            }
            .padding(.horizontal, layout.screenPadding)
            .maxWidthConstrained()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                hasAnimated = true
            }
            startOrbAnimation()
        }
    }

    // MARK: - Velocity Energy Core

    // Responsive circle size based on device
    private var circleSize: CGFloat {
        switch layout.deviceType {
        case .iPhoneSE: return 140
        case .iPhoneStandard: return 160
        case .iPhoneProMax: return 180
        case .iPadMini: return 200
        case .iPad, .iPadPro11: return 220
        case .iPadPro13: return 260
        }
    }

    private var velocityEnergyCore: some View {
        ZStack {
            // Outer glow halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Aurora.Colors.electricCyan.opacity(0.2 * glowPulse),
                            Aurora.Colors.borealisViolet.opacity(0.1 * glowPulse),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: circleSize * 0.4,
                        endRadius: circleSize * 0.8
                    )
                )
                .frame(width: circleSize * 1.4, height: circleSize * 1.4)
                .blur(radius: 20)

            // Orbiting particles
            if !reduceMotion {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Aurora.Gradients.auroraSpectrum[i % Aurora.Gradients.auroraSpectrum.count])
                        .frame(width: 6, height: 6)
                        .blur(radius: 1)
                        .offset(x: circleSize * 0.55)
                        .rotationEffect(.degrees(orbRotation + Double(i) * 60))
                }
            }

            // Outer ring with aurora gradient
            Circle()
                .stroke(Aurora.Colors.voidNebula, lineWidth: layout.deviceType.isTablet ? 10 : 8)
                .frame(width: circleSize, height: circleSize)

            // Progress ring with prismatic aurora gradient
            Circle()
                .trim(from: 0, to: hasAnimated ? velocityScore / 100 : 0)
                .stroke(
                    AngularGradient(
                        colors: [
                            Aurora.Colors.electricCyan,
                            Aurora.Colors.borealisViolet,
                            Aurora.Colors.stellarMagenta,
                            Aurora.Colors.electricCyan
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: layout.deviceType.isTablet ? 10 : 8, lineCap: .round)
                )
                .frame(width: circleSize, height: circleSize)
                .rotationEffect(.degrees(-90))
                .shadow(color: Aurora.Colors.electricCyan.opacity(0.5), radius: 8)

            // Inner glow
            Circle()
                .fill(Aurora.Colors.electricCyan.opacity(0.1))
                .frame(width: circleSize * 0.7, height: circleSize * 0.7)
                .blur(radius: 15)

            // Score display - Aurora style with glow
            VStack(spacing: Aurora.Spacing.xs) {
                ZStack {
                    Text("\(Int(velocityScore))")
                        .font(.system(size: circleSize * 0.35, weight: .bold, design: .rounded))
                        .foregroundStyle(Aurora.Colors.electricCyan)
                        .blur(radius: 6)
                        .opacity(0.5)

                    Text("\(Int(velocityScore))")
                        .font(.system(size: circleSize * 0.35, weight: .bold, design: .rounded))
                        .foregroundStyle(Aurora.Colors.textPrimary)
                }

                Text("VELOCITY")
                    .font(Aurora.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Aurora.Colors.textTertiary)
                    .tracking(2)
            }
        }
    }

    private func startOrbAnimation() {
        guard !reduceMotion else { return }

        // Slow orbital rotation
        withAnimation(
            .linear(duration: 20)
            .repeatForever(autoreverses: false)
        ) {
            orbRotation = 360
        }

        // Glow pulse
        withAnimation(
            .easeInOut(duration: AuroraMotion.Duration.glowPulse)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = 1.0
        }
    }

    // MARK: - Energy Stats Grid

    private var energyStatsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: layout.spacing) {
            // Aurora energy cell stat cards
            AuroraStatCell(
                value: "\(tasksCompletedToday)/\(dailyGoal)",
                label: "Today",
                progress: Double(tasksCompletedToday) / Double(max(dailyGoal, 1)),
                color: Aurora.Colors.prismaticGreen
            )

            AuroraStatCell(
                value: "\(tasksCompleted)",
                label: "All Time",
                progress: min(Double(tasksCompleted) / 500, 1.0),
                color: Aurora.Colors.electricCyan
            )

            AuroraStatCell(
                value: String(format: "%.1fh", focusHours),
                label: "Focus",
                progress: min(focusHours / 40, 1.0),
                color: Aurora.Colors.borealisViolet
            )

            AuroraStatCell(
                value: "\(Int(completionRate))%",
                label: "On Time",
                progress: completionRate / 100,
                color: Aurora.Colors.cosmicGold
            )
        }
    }

    // MARK: - Weekly Trend Card

    // Responsive bar width for weekly trend
    private var trendBarWidth: CGFloat {
        layout.deviceType.isTablet ? 36 : 28
    }

    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Aurora.Colors.borealisViolet)

                Text("Weekly Trend")
                    .font(Aurora.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }

            HStack(alignment: .bottom, spacing: layout.spacing * 0.75) {
                ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 6) {
                        // Aurora gradient bar with glow
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Aurora.Colors.borealisViolet,
                                        Aurora.Colors.stellarMagenta.opacity(0.7)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: trendBarWidth, height: CGFloat.random(in: 20...80))
                            .shadow(color: Aurora.Colors.borealisViolet.opacity(0.3), radius: 4, y: 2)

                        Text(day)
                            .font(Aurora.Typography.caption)
                            .foregroundStyle(Aurora.Colors.textTertiary)
                    }
                }
            }
            .frame(height: layout.deviceType.isTablet ? 120 : 100, alignment: .bottom)
        }
        .padding(layout.cardPadding)
        .background(Aurora.Colors.voidNebula, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.borealisViolet.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Aurora Streaks Card

    private var auroraStreaksCard: some View {
        VStack(spacing: layout.spacing) {
            HStack {
                // Flame icon with glow
                ZStack {
                    Image(systemName: "flame.fill")
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(Aurora.Colors.stellarMagenta)
                        .blur(radius: 4)
                        .opacity(0.6)

                    Image(systemName: "flame.fill")
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Aurora.Colors.cosmicGold, Aurora.Colors.stellarMagenta],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }

                Text("Current Streak")
                    .font(Aurora.Typography.body)
                    .foregroundStyle(Aurora.Colors.textPrimary)
                Spacer()

                // Aurora streak number with glow
                ZStack {
                    Text("\(streak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Aurora.Colors.stellarMagenta)
                        .blur(radius: 4)
                        .opacity(0.4)

                    Text("\(streak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Aurora.Colors.stellarMagenta)
                }

                Text("days")
                    .font(Aurora.Typography.caption)
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }

            // Aurora divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Aurora.Colors.stellarMagenta.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack {
                // Trophy icon with glow
                ZStack {
                    Image(systemName: "trophy.fill")
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(Aurora.Colors.cosmicGold)
                        .blur(radius: 4)
                        .opacity(0.6)

                    Image(systemName: "trophy.fill")
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(Aurora.Colors.cosmicGold)
                }

                Text("Longest Streak")
                    .font(Aurora.Typography.body)
                    .foregroundStyle(Aurora.Colors.textPrimary)
                Spacer()

                // Aurora longest streak number with glow
                ZStack {
                    Text("\(longestStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Aurora.Colors.cosmicGold)
                        .blur(radius: 4)
                        .opacity(0.4)

                    Text("\(longestStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Aurora.Colors.cosmicGold)
                }

                Text("days")
                    .font(Aurora.Typography.caption)
                    .foregroundStyle(Aurora.Colors.textSecondary)
            }
        }
        .padding(layout.cardPadding)
        .background(Aurora.Colors.voidNebula, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.stellarMagenta.opacity(0.3),
                            Aurora.Colors.cosmicGold.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Aurora.Colors.stellarMagenta.opacity(0.2), radius: 12, y: 4)
    }
}

// MARK: - Aurora Stat Cell

struct AuroraStatCell: View {
    let value: String
    let label: String
    let progress: Double
    let color: Color

    @Environment(\.responsiveLayout) private var layout
    @State private var animatedProgress: Double = 0
    @State private var glowIntensity: CGFloat = 0.3

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing * 0.75) {
            // Aurora value with glow effect
            ZStack(alignment: .leading) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .blur(radius: 6)
                    .opacity(glowIntensity)

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(Aurora.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(Aurora.Colors.textSecondary)
                .tracking(0.5)

            // Aurora progress bar with shimmer
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedProgress)
                        .shadow(color: color.opacity(0.5), radius: 4)
                }
            }
            .frame(height: layout.deviceType.isTablet ? 6 : 4)
        }
        .padding(layout.cardPadding)
        .background(Aurora.Colors.voidNebula, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: [color.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: color.opacity(0.15), radius: 8, y: 4)
        .onAppear {
            withAnimation(AuroraMotion.Spring.morph.delay(0.3)) {
                animatedProgress = progress
            }
            // Subtle glow pulse
            withAnimation(
                .easeInOut(duration: AuroraMotion.Duration.glowPulse)
                .repeatForever(autoreverses: true)
            ) {
                glowIntensity = 0.5
            }
        }
    }
}

#Preview {
    ZStack {
        Aurora.Colors.voidCosmos.ignoresSafeArea()

        StatsContentView(
            velocityScore: 67,
            streak: 12,
            longestStreak: 30,
            tasksCompleted: 127,
            tasksCompletedToday: 5,
            dailyGoal: 8,
            focusHours: 3.5,
            completionRate: 92,
            level: 5,
            totalPoints: 1250,
            levelProgress: 0.65
        )
    }
    .preferredColorScheme(.dark)
}
