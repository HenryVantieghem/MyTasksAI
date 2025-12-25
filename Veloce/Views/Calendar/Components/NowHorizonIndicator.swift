//
//  NowHorizonIndicator.swift
//  Veloce
//
//  Living Cosmos "Now Horizon" - Current Time Indicator
//  A plasma-glowing line that shows the current moment in time
//  with pulsing effects and traveling energy shimmer
//

import SwiftUI
import Combine

struct NowHorizonIndicator: View {
    let hourHeight: CGFloat
    let startHour: Int
    let timeGutterWidth: CGFloat

    @State private var currentTime = Date()
    @State private var pulsePhase: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -100
    @State private var glowIntensity: CGFloat = 0.3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // MARK: - Computed Properties

    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let hourOffset = CGFloat(hour - startHour) * hourHeight
        let minuteOffset = CGFloat(minute) / 60.0 * hourHeight
        return hourOffset + minuteOffset
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // "NOW" label with glow
            nowLabel

            // Plasma core orb
            plasmaCore

            // Horizon line with shimmer
            horizonLine
        }
        .offset(y: yOffset)
        .onAppear {
            startAnimations()
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }

    // MARK: - Components

    private var nowLabel: some View {
        Text("NOW")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.CelestialColors.plasmaCore)
            .shadow(
                color: Theme.CelestialColors.plasmaCore.opacity(glowIntensity),
                radius: 4
            )
            .frame(width: timeGutterWidth, alignment: .trailing)
            .padding(.trailing, 4)
    }

    private var plasmaCore: some View {
        ZStack {
            // Outer glow ring (breathing)
            SwiftUI.Circle()
                .fill(Theme.CelestialColors.plasmaCore.opacity(0.15))
                .frame(
                    width: 20 + (pulsePhase * 8),
                    height: 20 + (pulsePhase * 8)
                )
                .blur(radius: 6)

            // Middle glow
            SwiftUI.Circle()
                .fill(Theme.CelestialColors.plasmaCore.opacity(0.3))
                .frame(
                    width: 14 + (pulsePhase * 4),
                    height: 14 + (pulsePhase * 4)
                )
                .blur(radius: 3)

            // Core dot with radial gradient
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            Theme.CelestialColors.plasmaCore
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: LivingCosmos.Calendar.nowDotSize / 2
                    )
                )
                .frame(
                    width: LivingCosmos.Calendar.nowDotSize,
                    height: LivingCosmos.Calendar.nowDotSize
                )
                .shadow(
                    color: Theme.CelestialColors.plasmaCore.opacity(0.8),
                    radius: 4
                )
        }
        .offset(x: -LivingCosmos.Calendar.nowDotSize / 2)
    }

    private var horizonLine: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Base line with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.plasmaCore,
                                Theme.CelestialColors.plasmaCore.opacity(0.6),
                                Theme.CelestialColors.plasmaCore.opacity(0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)

                // Traveling shimmer highlight
                if !reduceMotion {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.6),
                                    .white.opacity(0.9),
                                    .white.opacity(0.6),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60, height: 3)
                        .offset(x: shimmerOffset)
                        .blur(radius: 1)
                }
            }
        }
        .frame(height: 3)
        .offset(x: -LivingCosmos.Calendar.nowDotSize / 2)
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Breathing pulse
        withAnimation(LivingCosmos.Animations.plasmaPulse) {
            pulsePhase = 1
        }

        // Glow intensity variation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowIntensity = 0.6
        }

        // Traveling shimmer (use a reasonable max width that works on all devices)
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            shimmerOffset = 500
        }
    }
}

// MARK: - Compact Now Indicator (for Week View)

struct CosmosCompactNowIndicator: View {
    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Diamond marker at top
            DiamondShape()
                .fill(Theme.CelestialColors.plasmaCore)
                .frame(width: 8, height: 8)
                .shadow(
                    color: Theme.CelestialColors.plasmaCore.opacity(0.5),
                    radius: 4
                )

            // Vertical line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.plasmaCore,
                            Theme.CelestialColors.plasmaCore.opacity(0.3),
                            Theme.CelestialColors.plasmaCore.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
        }
        .scaleEffect(1 + pulsePhase * 0.05)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(LivingCosmos.Animations.plasmaPulse) {
                pulsePhase = 1
            }
        }
    }
}

// MARK: - Diamond Shape

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY

        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: midY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview("Now Horizon") {
    ZStack {
        VoidBackground.calendar

        VStack {
            NowHorizonIndicator(
                hourHeight: 80,
                startHour: 6,
                timeGutterWidth: 54
            )
        }
        .padding()
    }
}

#Preview("Compact Now Indicator") {
    ZStack {
        VoidBackground.calendar

        CosmosCompactNowIndicator()
            .frame(height: 100)
    }
}
