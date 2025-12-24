//
//  CelebrationOverlay.swift
//  Veloce
//
//  Full-Screen Celebration Overlays
//  Dramatic milestone celebrations with supernova effects
//

import SwiftUI

// MARK: - Celebration Overlay Container

struct CelebrationOverlayContainer: View {
    @State private var showingOverlay = false
    @State private var currentEvent: CelebrationEvent?
    @State private var showingDailyWins = false

    var body: some View {
        ZStack {
            // XP float animations (always visible)
            XPFloatContainer()

            // Particle effects layer
            if let event = currentEvent {
                CelebrationParticleOverlay(event: event)
            }

            // Milestone overlay (full screen takeover)
            if showingOverlay, let event = currentEvent, event.level == .milestone {
                MilestoneOverlay(
                    event: event,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showingOverlay = false
                        }
                    },
                    onShare: {
                        // Generate and share card
                        if let message = event.message {
                            ShareCardGenerator.share(
                                cardType: .milestone(
                                    title: message,
                                    value: event.displayXP,
                                    description: "Completed"
                                )
                            )
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Personal best banner
            if let event = currentEvent, let best = event.isPersonalBest {
                NewRecordBanner(
                    personalBest: best,
                    isShowing: Binding(
                        get: { currentEvent?.isPersonalBest != nil },
                        set: { if !$0 { currentEvent = nil } }
                    )
                )
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .allowsHitTesting(showingOverlay)
        .onReceive(CelebrationEngine.shared.celebrationTriggered) { event in
            currentEvent = event

            if event.level == .milestone {
                withAnimation(.spring(response: 0.5)) {
                    showingOverlay = true
                }
            }

            // Clear non-milestone events after animation
            if event.level != .milestone && event.isPersonalBest == nil {
                Task {
                    try? await Task.sleep(for: .seconds(event.level.duration))
                    if currentEvent?.id == event.id {
                        currentEvent = nil
                    }
                }
            }
        }
    }
}

// MARK: - Milestone Overlay

struct MilestoneOverlay: View {
    let event: CelebrationEvent
    let onDismiss: () -> Void
    let onShare: () -> Void

    @State private var phase: AnimationPhase = .entering
    @State private var showContent = false
    @State private var particleOffset: CGFloat = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var glowPulse: Double = 0

    enum AnimationPhase {
        case entering
        case revealed
        case exiting
    }

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Supernova effect background
            supernovaBackground

            // Content
            if showContent {
                VStack(spacing: 32) {
                    Spacer()

                    // Main achievement display
                    achievementDisplay

                    // XP earned
                    xpDisplay

                    // Action buttons
                    actionButtons

                    Spacer()
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Supernova Background

    private var supernovaBackground: some View {
        ZStack {
            // Expanding rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        Theme.Celebration.plasmaCore.opacity(0.3 - Double(i) * 0.1),
                        lineWidth: 2
                    )
                    .scaleEffect(ringScale + CGFloat(i) * 0.3)
                    .opacity(ringOpacity)
            }

            // Central glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Celebration.supernovaWhite,
                            Theme.Celebration.plasmaCore.opacity(0.8),
                            Theme.Celebration.nebulaCore.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(0.5 + glowPulse * 0.3)
                .blur(radius: 40)

            // Particle burst
            ParticleEmitterView(
                type: .supernova,
                at: CGPoint(
                    x: UIScreen.main.bounds.width / 2,
                    y: UIScreen.main.bounds.height / 2
                ),
                particleCount: 100
            )
        }
    }

    // MARK: - Achievement Display

    private var achievementDisplay: some View {
        VStack(spacing: 20) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Celebration.starGold.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(1.0 + glowPulse * 0.1)

                Image(systemName: milestoneIcon)
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Celebration.starGold,
                                Theme.Celebration.solarFlare
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.Celebration.starGold.opacity(0.8), radius: 20)
            }

            // Title
            VStack(spacing: 8) {
                Text("MILESTONE")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Celebration.starGold)
                    .tracking(4)

                Text(event.message ?? "Achievement Unlocked!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    private var milestoneIcon: String {
        if let message = event.message?.lowercased() {
            if message.contains("level") {
                return "arrow.up.circle.fill"
            } else if message.contains("streak") {
                return "flame.fill"
            } else if message.contains("tasks") {
                return "checkmark.circle.fill"
            }
        }
        return "trophy.fill"
    }

    // MARK: - XP Display

    private var xpDisplay: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.Celebration.starGold)

                Text("+\(event.displayXP)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Celebration.starGold,
                                Theme.Celebration.solarFlare
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("XP")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            if event.hasMultiplier {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))

                    Text("×\(String(format: "%.1f", event.multiplier)) Cosmic Flow Bonus!")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Theme.Celebration.flameInner)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Share button
            Button {
                onShare()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Achievement")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Celebration.nebulaCore,
                                    Theme.Celebration.plasmaCore
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }

            // Continue button
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Animation

    private func startAnimation() {
        // Ring expansion
        withAnimation(.easeOut(duration: 0.8)) {
            ringScale = 4.0
            ringOpacity = 1.0
        }

        // Fade out rings
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            ringOpacity = 0
        }

        // Show content after initial burst
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            showContent = true
            phase = .revealed
        }

        // Continuous glow pulse
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = 1.0
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = false
            phase = .exiting
        }

        Task {
            try? await Task.sleep(for: .milliseconds(300))
            onDismiss()
        }
    }
}

// MARK: - Level Up Overlay

struct LevelUpOverlay: View {
    let newLevel: Int
    let totalXP: Int
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var numberScale: CGFloat = 0
    @State private var starRotations: [Double] = Array(repeating: 0, count: 5)
    @State private var glowIntensity: Double = 0

    var body: some View {
        if isShowing {
            ZStack {
                // Backdrop
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }

                VStack(spacing: 32) {
                    Spacer()

                    // Level badge with glow
                    ZStack {
                        // Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Theme.Celebration.nebulaCore.opacity(0.4),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(1.0 + glowIntensity * 0.2)

                        // Ring
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [
                                        Theme.Celebration.plasmaCore,
                                        Theme.Celebration.nebulaCore,
                                        Theme.Celebration.plasmaCore
                                    ],
                                    center: .center
                                ),
                                lineWidth: 6
                            )
                            .frame(width: 140, height: 140)

                        // Level number
                        Text("\(newLevel)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .scaleEffect(numberScale)
                    }

                    // Level up text
                    VStack(spacing: 8) {
                        Text("LEVEL UP!")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Theme.Celebration.plasmaCore,
                                        Theme.Celebration.nebulaCore
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("\(totalXP) Total XP")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    // Animated stars
                    HStack(spacing: 16) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.Celebration.starGold)
                                .rotationEffect(.degrees(starRotations[i]))
                                .shadow(color: Theme.Celebration.starGold.opacity(0.8), radius: 8)
                        }
                    }

                    Spacer()

                    // Continue button
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background {
                                Capsule()
                                    .fill(Theme.Celebration.nebulaCore)
                            }
                    }
                    .padding(.bottom, 48)
                }
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .onAppear {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        // Main scale in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }

        // Number pop
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.2)) {
            numberScale = 1.2
        }
        withAnimation(.spring(response: 0.2).delay(0.35)) {
            numberScale = 1.0
        }

        // Star animations (staggered)
        for i in 0..<5 {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.1)
            ) {
                starRotations[i] = 360
            }
        }

        // Glow pulse
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 1.0
        }

        // Play sounds
        CelebrationSounds.shared.playLevelUp()
        HapticsService.shared.levelUp()
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            scale = 0.9
        }

        Task {
            try? await Task.sleep(for: .milliseconds(300))
            isShowing = false
        }
    }
}

// MARK: - Achievement Banner Overlay

struct AchievementBannerOverlay: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isShowing: Bool

    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        if isShowing {
            VStack {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.Celebration.starGold.opacity(0.2))
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Celebration.starGold)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    Theme.Celebration.starGold.opacity(0.3),
                                    lineWidth: 1
                                )
                        }
                }
                .padding(.horizontal, 20)
                .offset(y: offset)
                .opacity(opacity)

                Spacer()
            }
            .onAppear {
                // Slide in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    offset = 0
                    opacity = 1
                }

                // Auto-dismiss
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = -100
                        opacity = 0
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Milestone Overlay") {
    MilestoneOverlay(
        event: CelebrationEvent(
            level: .milestone,
            xpEarned: 100,
            multiplier: 1.5,
            position: .zero,
            message: "100 Tasks Complete!",
            isPersonalBest: nil
        ),
        onDismiss: {},
        onShare: {}
    )
}

#Preview("Level Up Overlay") {
    LevelUpOverlay(
        newLevel: 10,
        totalXP: 5000,
        isShowing: .constant(true)
    )
}
