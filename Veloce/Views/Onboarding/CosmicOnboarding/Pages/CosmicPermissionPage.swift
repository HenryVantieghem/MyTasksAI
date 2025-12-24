//
//  CosmicPermissionPage.swift
//  Veloce
//
//  Cosmic Permission Pages - Calendar, Notifications, Screen Time
//  Beautiful permission requests with benefit-focused copy and custom illustrations
//

import SwiftUI

// MARK: - Permission Type

enum PermissionType: Identifiable {
    case calendar
    case notifications
    case screenTime

    var id: String {
        switch self {
        case .calendar: return "calendar"
        case .notifications: return "notifications"
        case .screenTime: return "screenTime"
        }
    }

    var title: String {
        switch self {
        case .calendar: return "Sync Your Time"
        case .notifications: return "Stay on Track"
        case .screenTime: return "Block Distractions"
        }
    }

    var subtitle: String {
        switch self {
        case .calendar:
            return "We'll help you find perfect focus windows in your schedule"
        case .notifications:
            return "Gentle reminders to keep you moving toward your goals"
        case .screenTime:
            return "Let us help you stay focused by blocking distracting apps"
        }
    }

    var icon: String {
        switch self {
        case .calendar: return "calendar.badge.clock"
        case .notifications: return "bell.badge.fill"
        case .screenTime: return "shield.checkered"
        }
    }

    var color: Color {
        switch self {
        case .calendar: return Theme.Colors.aiBlue
        case .notifications: return Theme.CelestialColors.solarFlare
        case .screenTime: return Theme.Colors.aiPurple
        }
    }

    var benefits: [(icon: String, text: String)] {
        switch self {
        case .calendar:
            return [
                ("clock.badge.checkmark", "Smart scheduling suggestions"),
                ("calendar.day.timeline.left", "View tasks alongside events"),
                ("sparkles", "AI-powered time optimization")
            ]
        case .notifications:
            return [
                ("bell.badge", "Timely task reminders"),
                ("target", "Goal progress updates"),
                ("flame.fill", "Streak protection alerts")
            ]
        case .screenTime:
            return [
                ("shield.fill", "Focus session protection"),
                ("app.badge.checkmark", "Custom app blocking"),
                ("chart.bar.fill", "Usage insights")
            ]
        }
    }
}

// MARK: - Cosmic Permission Page

struct CosmicPermissionPage: View {
    let type: PermissionType
    let isGranted: Bool
    let onAllow: () async -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var illustrationScale: CGFloat = 0.8
    @State private var isRequesting = false
    @State private var showSuccess = false
    @State private var benefitAppearance: [Bool] = [false, false, false]
    @State private var orbRotation: Double = 0
    @State private var orbPulse: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer(minLength: geometry.size.height * 0.05)

                    // Illustration
                    illustrationSection
                        .padding(.top, Theme.Spacing.lg)

                    // Title & Subtitle
                    titleSection

                    // Benefits list
                    benefitsSection
                        .padding(.horizontal, Theme.Spacing.lg)

                    Spacer(minLength: 60)

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl * 2)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isGranted) { _, granted in
            if granted {
                withAnimation(LivingCosmos.Animations.spring) {
                    showSuccess = true
                }
            }
        }
    }

    // MARK: - Illustration Section

    private var illustrationSection: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(
                        type.color.opacity(0.15 - Double(ring) * 0.04),
                        lineWidth: 2
                    )
                    .frame(
                        width: 160 + CGFloat(ring) * 50,
                        height: 160 + CGFloat(ring) * 50
                    )
                    .scaleEffect(1 + orbPulse * 0.03 * CGFloat(ring + 1))
            }

            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            type.color.opacity(0.3),
                            type.color.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)

            // Orbiting particles
            ForEach(0..<5) { i in
                Circle()
                    .fill(type.color.opacity(0.6))
                    .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                    .offset(x: 90 + CGFloat(i) * 15)
                    .rotationEffect(.degrees(orbRotation + Double(i) * 72))
            }

            // Main icon container
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                type.color.opacity(0.3),
                                type.color.opacity(0.15),
                                Theme.CelestialColors.void.opacity(0.5)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Glass overlay
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)

                // Border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                type.color.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)

                // Icon
                if showSuccess || isGranted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: type.icon)
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(type.color)
                }
            }
        }
        .scaleEffect(illustrationScale)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(type.title)
                .font(.system(size: 32, weight: .thin, design: .default))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Text(type.subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(type.benefits.enumerated()), id: \.offset) { index, benefit in
                PermissionBenefitRow(
                    icon: benefit.icon,
                    text: benefit.text,
                    color: type.color,
                    isVisible: benefitAppearance[index]
                )

                if index < type.benefits.count - 1 {
                    Divider()
                        .background(Theme.CelestialColors.starGhost.opacity(0.2))
                        .padding(.vertical, Theme.Spacing.sm)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    type.color.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 30)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            if isGranted || showSuccess {
                // Continue button after permission granted
                Button {
                    HapticsService.shared.impact()
                    onContinue()
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
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
                    .shadow(color: Theme.CelestialColors.auroraGreen.opacity(0.4), radius: 15, y: 8)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else {
                // Allow button
                Button {
                    requestPermission()
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Allow \(type.title.replacingOccurrences(of: "Sync Your ", with: "").replacingOccurrences(of: "Stay on ", with: "").replacingOccurrences(of: "Block ", with: ""))")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [type.color, type.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: type.color.opacity(0.4), radius: 15, y: 8)
                }
                .buttonStyle(.plain)
                .disabled(isRequesting)

                // Maybe Later button
                Button {
                    HapticsService.shared.lightImpact()
                    onSkip()
                } label: {
                    Text("Maybe Later")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }
            }

            // Settings note for denied
            if !isGranted && !showSuccess {
                Text("You can enable this later in Settings")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.starGhost.opacity(0.6))
                    .padding(.top, Theme.Spacing.sm)
            }
        }
        .opacity(showContent ? 1 : 0)
        .animation(LivingCosmos.Animations.spring, value: isGranted)
        .animation(LivingCosmos.Animations.spring, value: showSuccess)
    }

    // MARK: - Permission Request

    private func requestPermission() {
        isRequesting = true

        Task {
            await onAllow()
            await MainActor.run {
                isRequesting = false
                if isGranted {
                    showSuccess = true
                    HapticsService.shared.success()
                }
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        if reduceMotion {
            showContent = true
            illustrationScale = 1
            benefitAppearance = [true, true, true]
            return
        }

        // Content appears
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showContent = true
            illustrationScale = 1
        }

        // Orb rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            orbRotation = 360
        }

        // Orb pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            orbPulse = 1
        }

        // Benefits appear with stagger
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.1) {
                withAnimation(LivingCosmos.Animations.stellarBounce) {
                    benefitAppearance[i] = true
                }
            }
        }
    }
}

// MARK: - Permission Benefit Row

struct PermissionBenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    let isVisible: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starWhite)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.CelestialColors.auroraGreen.opacity(0.7))
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
}

// MARK: - Preview

#Preview("Calendar Permission") {
    ZStack {
        VoidBackground.onboarding

        CosmicPermissionPage(
            type: .calendar,
            isGranted: false,
            onAllow: { },
            onSkip: { },
            onContinue: { }
        )
    }
}

#Preview("Notification Permission") {
    ZStack {
        VoidBackground.onboarding

        CosmicPermissionPage(
            type: .notifications,
            isGranted: false,
            onAllow: { },
            onSkip: { },
            onContinue: { }
        )
    }
}

#Preview("Screen Time Permission") {
    ZStack {
        VoidBackground.onboarding

        CosmicPermissionPage(
            type: .screenTime,
            isGranted: true,
            onAllow: { },
            onSkip: { },
            onContinue: { }
        )
    }
}
