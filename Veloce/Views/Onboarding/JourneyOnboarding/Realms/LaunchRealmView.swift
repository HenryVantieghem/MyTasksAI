//
//  LaunchRealmView.swift
//  MyTasksAI
//
//  Step 5: "Launch into Orbit"
//  Summary and launch with celebratory animation
//

import SwiftUI

struct LaunchRealmView: View {
    @Bindable var viewModel: JourneyOnboardingViewModel
    let onLaunch: () -> Void

    @State private var showContent = false
    @State private var orbState: EtherealOrbState = .idle
    @State private var isLaunching = false
    @State private var portalScale: CGFloat = 1.0
    @State private var portalRotation: Double = 0
    @State private var showBurst = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let accentCyan = Color(red: 0.55, green: 0.85, blue: 0.95)
    private let accentPurple = Color(red: 0.75, green: 0.55, blue: 0.90)
    private let successGreen = Color(red: 0.40, green: 0.85, blue: 0.65)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.05)

                    // Portal/Orb Section
                    ZStack {
                        // Portal rings (behind orb)
                        if showContent {
                            portalRings
                        }

                        // Ethereal Orb
                        EtherealOrb(
                            size: .hero,
                            state: orbState,
                            isAnimating: true,
                            intensity: isLaunching ? 1.8 : 1.0,
                            showGlow: true
                        )
                        .scaleEffect(showContent ? portalScale : 0.7)
                        .opacity(showContent ? 1 : 0)
                    }

                    Spacer()
                        .frame(height: 28)

                    // Header
                    VStack(spacing: 10) {
                        Text("Ready for Liftoff")
                            .font(.system(size: 28, weight: .thin))
                            .tracking(2)
                            .foregroundStyle(.white)

                        Text("Your journey awaits")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)

                    Spacer()
                        .frame(height: 32)

                    // Summary Card
                    VStack(spacing: 18) {
                        // Goals summary
                        SummaryRow(
                            icon: "target",
                            title: "Your Goals",
                            value: viewModel.goalSummary,
                            color: accentCyan
                        )

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // Permissions summary
                        SummaryRow(
                            icon: "bolt.fill",
                            title: "Powers Enabled",
                            value: viewModel.permissionsSummary.isEmpty ? "None yet" : viewModel.permissionsSummary.joined(separator: ", "),
                            color: viewModel.permissionsSummary.isEmpty ? .white.opacity(0.4) : successGreen
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.06), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    )
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Spacer()

                    // Launch Button
                    Button {
                        triggerLaunch()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16, weight: .medium))

                            Text("Start Your Journey")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [successGreen, accentCyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(
                            color: successGreen.opacity(0.45),
                            radius: 22,
                            y: 8
                        )
                    }
                    .disabled(isLaunching)
                    .opacity(showContent ? 1 : 0)
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 50)
                }

                // Burst effect overlay
                if showBurst {
                    EtherealParticleBurst(
                        center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.28),
                        colors: [accentCyan, accentPurple, successGreen, .white],
                        particleCount: 32
                    )
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Portal Rings

    private var portalRings: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            accentCyan.opacity(0.4),
                            accentPurple.opacity(0.2),
                            Color.clear,
                            accentCyan.opacity(0.3)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(portalRotation))

            // Middle ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            accentPurple.opacity(0.3),
                            Color.clear,
                            accentCyan.opacity(0.25),
                            Color.clear
                        ],
                        center: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 320, height: 320)
                .rotationEffect(.degrees(-portalRotation * 0.7))

            // Outer glow ring
            Circle()
                .stroke(
                    RadialGradient(
                        colors: [accentCyan.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 150,
                        endRadius: 180
                    ),
                    lineWidth: 30
                )
                .frame(width: 360, height: 360)
                .blur(radius: 8)
        }
        .opacity(isLaunching ? 0 : 0.8)
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else {
            showContent = true
            return
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }

        // Portal ring rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            portalRotation = 360
        }

        // Orb active state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            orbState = .active
        }
    }

    private func triggerLaunch() {
        guard !isLaunching else { return }
        isLaunching = true

        HapticsService.shared.celebration()

        // Orb celebration
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            orbState = .celebration
            portalScale = 1.15
        }

        // Show burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showBurst = true
        }

        // Scale down and complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                portalScale = 0.9
            }
        }

        // Complete onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onLaunch()
        }
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.01, green: 0.01, blue: 0.02)
            .ignoresSafeArea()

        LaunchRealmView(viewModel: JourneyOnboardingViewModel()) {
            print("Launched!")
        }
    }
}
