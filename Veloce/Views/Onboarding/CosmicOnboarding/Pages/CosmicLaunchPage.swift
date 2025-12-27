//
//  CosmicLaunchPage.swift
//  Veloce
//
//  Cosmic Launch Page - The Final Step Before Liftoff
//  Dramatic portal/rocket animation with countdown to productivity
//

import SwiftUI

struct CosmicLaunchPage: View {
    let userName: String
    let goalSummary: String?
    let onLaunch: () -> Void

    @State private var showContent = false
    @State private var showPortal = false
    @State private var showRocket = false
    @State private var showTitle = false
    @State private var showButton = false
    @State private var portalRotation: Double = 0
    @State private var portalScale: CGFloat = 1
    @State private var portalPulse: CGFloat = 0
    @State private var rocketOffset: CGFloat = 0
    @State private var rocketGlow: CGFloat = 0
    @State private var starBurst: CGFloat = 0
    @State private var isLaunching = false
    @State private var launchProgress: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.responsiveLayout) private var layout

    // MARK: - Responsive Sizes

    // Portal/orb sizes scale with device
    private var portalBaseSize: CGFloat {
        layout.portalOrbSize
    }

    private var portalHeight: CGFloat {
        layout.deviceType.isTablet ? 400 : 300
    }

    private var buttonHeight: CGFloat {
        layout.buttonHeight
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Star burst effect during launch
                if isLaunching {
                    LaunchStarBurst(progress: launchProgress)
                }

                VStack(spacing: layout.spacing * 1.5) {
                    Spacer()

                    // Portal/Rocket illustration
                    portalIllustration
                        .frame(height: portalHeight)

                    // Title section
                    titleSection

                    Spacer()

                    // Launch button
                    launchButton
                        .padding(.horizontal, layout.screenPadding)
                        .padding(.bottom, layout.bottomSafeArea)
                }
                .maxWidthConstrained()
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Portal Illustration

    // Responsive inner core size
    private var innerCoreSize: CGFloat {
        portalBaseSize * 0.53  // ~160 at base 300
    }

    // Responsive energy swirl size
    private var energySwirlSize: CGFloat {
        portalBaseSize * 0.43  // ~130 at base 300
    }

    // Responsive rocket icon size
    private var rocketIconSize: CGFloat {
        layout.deviceType.isTablet ? 60 : 48
    }

    private var portalIllustration: some View {
        ZStack {
            // Outer portal rings - scale with portalBaseSize
            ForEach(0..<4) { ring in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(0.5),
                                Theme.CelestialColors.solarFlare.opacity(0.4),
                                Theme.Colors.aiBlue.opacity(0.3),
                                Theme.Colors.aiPurple.opacity(0.5)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 3 - CGFloat(ring) * 0.5
                    )
                    .frame(
                        width: portalBaseSize * 0.67 + CGFloat(ring) * (portalBaseSize * 0.17),
                        height: portalBaseSize * 0.67 + CGFloat(ring) * (portalBaseSize * 0.17)
                    )
                    .rotationEffect(.degrees(portalRotation * (ring % 2 == 0 ? 1 : -1)))
                    .scaleEffect(1 + portalPulse * 0.02 * CGFloat(ring + 1))
                    .opacity(0.6 - Double(ring) * 0.12)
            }

            // Portal vortex glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.4),
                            Theme.CelestialColors.solarFlare.opacity(0.2),
                            Theme.Colors.aiBlue.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: portalBaseSize * 0.5
                    )
                )
                .frame(width: portalBaseSize, height: portalBaseSize)
                .scaleEffect(1 + portalPulse * 0.05)

            // Inner portal core
            ZStack {
                // Deep space core
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.CelestialColors.void,
                                Theme.Colors.aiPurple.opacity(0.3),
                                Theme.Colors.aiPurple.opacity(0.6)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: innerCoreSize * 0.5
                        )
                    )
                    .frame(width: innerCoreSize, height: innerCoreSize)

                // Energy swirl
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Theme.CelestialColors.solarFlare.opacity(0.8),
                                Theme.Colors.aiPurple.opacity(0.6),
                                Theme.Colors.aiBlue.opacity(0.8),
                                Theme.CelestialColors.solarFlare.opacity(0.8)
                            ],
                            center: .center
                        ),
                        lineWidth: layout.deviceType.isTablet ? 5 : 4
                    )
                    .frame(width: energySwirlSize, height: energySwirlSize)
                    .rotationEffect(.degrees(-portalRotation * 2))
                    .blur(radius: 2)

                // Rocket
                ZStack {
                    // Rocket glow/trail
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.CelestialColors.solarFlare.opacity(rocketGlow * 0.6),
                                    Theme.Colors.aiPurple.opacity(rocketGlow * 0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: rocketIconSize * 0.83, height: rocketIconSize * 1.67)
                        .offset(y: rocketIconSize * 1.04)
                        .blur(radius: 10)

                    // Rocket icon - Dynamic Type for accessibility
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: rocketIconSize, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white,
                                    Theme.CelestialColors.starWhite.opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(-45))
                        .shadow(color: Theme.CelestialColors.solarFlare.opacity(0.5), radius: 10)
                        .shadow(color: .white.opacity(0.3), radius: 5)
                }
                .offset(y: rocketOffset)
                .scaleEffect(showRocket ? 1 : 0.5)
                .opacity(showRocket ? 1 : 0)
            }
            .opacity(showPortal ? 1 : 0)
            .scaleEffect(showPortal ? 1 : 0.5)
        }
        .scaleEffect(isLaunching ? 1.5 : 1)
        .opacity(isLaunching ? 0 : 1)
    }

    private var displayName: String {
        userName.isEmpty ? "Explorer" : userName.components(separatedBy: " ").first ?? userName
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: layout.spacing) {
            Text("Ready for Liftoff, \(displayName)")
                .dynamicTypeFont(base: 30, weight: .thin)
                .foregroundStyle(Theme.CelestialColors.starWhite)
                .multilineTextAlignment(.center)

            if let goal = goalSummary, !goal.isEmpty {
                Text("Your mission: \(goal)")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.CelestialColors.solarFlare.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, layout.screenPadding)
            }

            Text("Your productivity journey begins now")
                .dynamicTypeFont(base: 15, weight: .regular)
                .foregroundStyle(Theme.CelestialColors.starDim)
                .multilineTextAlignment(.center)

            // Fun stats preview
            HStack(spacing: layout.spacing * 1.5) {
                LaunchStatBadge(icon: "target", value: "∞", label: "Goals", layout: layout)
                LaunchStatBadge(icon: "flame.fill", value: "1", label: "Streak", layout: layout)
                LaunchStatBadge(icon: "star.fill", value: "0", label: "Focus hrs", layout: layout)
            }
            .padding(.top, layout.spacing)
        }
        .opacity(showTitle ? 1 : 0)
        .offset(y: showTitle ? 0 : 30)
        .opacity(isLaunching ? 0 : 1)
    }

    // MARK: - Launch Button

    private var launchButton: some View {
        VStack(spacing: layout.spacing) {
            Button {
                triggerLaunch()
            } label: {
                ZStack {
                    // Pulsing glow behind button
                    Capsule()
                        .fill(Theme.CelestialColors.auroraGreen.opacity(0.3))
                        .frame(height: buttonHeight)
                        .scaleEffect(1 + portalPulse * 0.05)
                        .blur(radius: 10)

                    HStack(spacing: layout.spacing * 0.5) {
                        if isLaunching {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "bolt.fill")
                                .dynamicTypeFont(base: 18, weight: .semibold)

                            Text("Launch My Journey")
                                .dynamicTypeFont(base: 17, weight: .bold)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.CelestialColors.auroraGreen,
                                        Theme.CelestialColors.auroraGreen.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Theme.CelestialColors.auroraGreen.opacity(0.5), radius: 20, y: 8)
                }
            }
            .buttonStyle(.plain)
            .iPadHoverEffect(.lift)
            .disabled(isLaunching)
        }
        .opacity(showButton ? 1 : 0)
        .offset(y: showButton ? 0 : 30)
        .opacity(isLaunching ? 0 : 1)
    }

    // MARK: - Launch Sequence

    private func triggerLaunch() {
        HapticsService.shared.impact()

        isLaunching = true

        // Rocket flies up
        withAnimation(.easeIn(duration: 0.5)) {
            rocketOffset = -200
            rocketGlow = 1
        }

        // Star burst expands
        withAnimation(.easeOut(duration: 1.0)) {
            launchProgress = 1
        }

        // Haptic feedback sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticsService.shared.success()
        }

        // Complete onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onLaunch()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        if reduceMotion {
            showContent = true
            showPortal = true
            showRocket = true
            showTitle = true
            showButton = true
            portalPulse = 0.5
            return
        }

        // Portal appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                showPortal = true
            }
        }

        // Portal rotation
        withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
            portalRotation = 360
        }

        // Portal pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            portalPulse = 1
        }

        // Rocket appears with float
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showRocket = true
            }

            // Rocket floating motion
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                rocketOffset = -10
            }

            // Rocket glow pulse
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                rocketGlow = 0.6
            }
        }

        // Title appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showTitle = true
            }
        }

        // Button appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }
}

// MARK: - Launch Stat Badge

struct LaunchStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let layout: ResponsiveLayout

    // Responsive badge size
    private var badgeSize: CGFloat {
        layout.deviceType.isTablet ? 60 : 50
    }

    var body: some View {
        VStack(spacing: layout.spacing * 0.25) {
            ZStack {
                Circle()
                    .fill(Theme.CelestialColors.void.opacity(0.5))
                    .frame(width: badgeSize, height: badgeSize)

                Circle()
                    .stroke(
                        Theme.CelestialColors.starGhost.opacity(0.2),
                        lineWidth: 1
                    )
                    .frame(width: badgeSize, height: badgeSize)

                Image(systemName: icon)
                    .dynamicTypeFont(base: 18, weight: .medium)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Text(value)
                .dynamicTypeFont(base: 20, weight: .bold)
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Text(label)
                .dynamicTypeFont(base: 11, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starGhost)
        }
    }
}

// MARK: - Launch Star Burst

struct LaunchStarBurst: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            // Central flash
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            Theme.CelestialColors.auroraGreen.opacity(0.8),
                            Theme.Colors.aiPurple.opacity(0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400 * progress
                    )
                )
                .frame(width: 800 * progress, height: 800 * progress)
                .opacity(Double(1.0) - Double(progress) * 0.3)

            // Radiating lines
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.8),
                                Theme.CelestialColors.auroraGreen.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: 300 * progress)
                    .offset(y: -150 * progress)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            // Particle bursts
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(.white)
                    .frame(width: CGFloat.random(in: 3...8), height: CGFloat.random(in: 3...8))
                    .offset(
                        x: cos(Double(i) * 0.314) * 200 * progress,
                        y: sin(Double(i) * 0.314) * 200 * progress
                    )
                    .opacity(1 - progress)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.onboarding

        CosmicLaunchPage(
            userName: "Alex",
            goalSummary: "Launch my side project and grow it to 1000 users"
        ) {
            print("Launched!")
        }
    }
}
