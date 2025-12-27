//
//  FocusMainView.swift
//  Veloce
//
//  Reimagined Focus Experience
//  Two main portals: Focus Timer & App Blocking
//  Cosmic Observatory aesthetic with stunning glass effects
//

import SwiftUI
import FamilyControls

// MARK: - Quick Focus Mode

enum QuickFocusMode: String, CaseIterable {
    case pomodoro = "Pomodoro"
    case deepWork = "Deep Work"
    case flow = "Flow"

    var duration: TimeInterval {
        switch self {
        case .pomodoro: return 25 * 60
        case .deepWork: return 90 * 60
        case .flow: return 0 // Counts up
        }
    }

    var icon: String {
        switch self {
        case .pomodoro: return "clock"
        case .deepWork: return "brain.head.profile"
        case .flow: return "bolt"
        }
    }

    var label: String {
        switch self {
        case .pomodoro: return "25m"
        case .deepWork: return "90m"
        case .flow: return "∞"
        }
    }

    var accentColor: Color {
        switch self {
        case .pomodoro: return Theme.Colors.aiAmber
        case .deepWork: return Theme.Colors.aiPurple
        case .flow: return Theme.Colors.aiCyan
        }
    }
}

enum QuickTimerState {
    case idle, running, paused
}

// MARK: - Focus Main View

struct FocusMainView: View {
    // Task context (when launched from a task)
    var taskContext: FocusTaskContext?
    var onSessionComplete: ((Bool) -> Void)?

    // Navigation state
    @State private var showFocusTimer = false
    @State private var showAppBlocking = false
    @State private var showActiveSession = false

    // Quick timer state
    @State private var selectedMode: QuickFocusMode = .pomodoro
    @State private var timerState: QuickTimerState = .idle
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var totalTime: TimeInterval = 25 * 60
    @State private var timer: Timer?

    // Services
    private let blockingService = FocusBlockingService.shared

    // Animation states
    @State private var portalPulse: CGFloat = 0
    @State private var backgroundRotation: Double = 0
    @State private var starsOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Cosmic background with enhanced depth
            enhancedCosmicBackground

            ScrollView {
                VStack(spacing: 0) {
                    // Header area with subtle greeting
                    headerView
                        .padding(.top, Theme.Spacing.universalHeaderHeight)

                    // Quick Timer Section (above portal cards)
                    quickTimerSection
                        .padding(.top, Theme.Spacing.lg)

                    // Mode Selector
                    modeSelectorView
                        .padding(.top, Theme.Spacing.lg)

                    // Two main portal cards
                    portalCardsView
                        .padding(.top, Theme.Spacing.xl)

                    // Quick stats bar
                    quickStatsBar
                        .padding(.top, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.floatingTabBarClearance)
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showFocusTimer) {
            FocusTimerSetupView(
                taskContext: taskContext,
                onStartSession: { session in
                    showFocusTimer = false
                    showActiveSession = true
                }
            )
        }
        .fullScreenCover(isPresented: $showAppBlocking) {
            AppBlockingMainView()
        }
        .fullScreenCover(isPresented: $showActiveSession) {
            ImmersiveFocusSessionView(
                onComplete: { completed in
                    showActiveSession = false
                    onSessionComplete?(completed)
                }
            )
        }
        .onAppear {
            startAmbientAnimations()

            // Check for active session
            if blockingService.isBlocking {
                showActiveSession = true
            }

            // Auto-show timer setup if launched from task
            if taskContext != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFocusTimer = true
                }
            }
        }
    }

    // MARK: - Enhanced Cosmic Background

    private var enhancedCosmicBackground: some View {
        ZStack {
            // Base void gradient
            LinearGradient(
                colors: [
                    Theme.CelestialColors.voidDeep,
                    Theme.CelestialColors.void,
                    Theme.CelestialColors.abyss
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Rotating nebula layers
            nebulaLayers

            // Central focus glow
            RadialGradient(
                colors: [
                    Theme.Colors.aiAmber.opacity(0.15),
                    Theme.Colors.aiOrange.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .scaleEffect(1 + portalPulse * 0.1)

            // Star field
            starFieldView
                .opacity(starsOpacity)
        }
    }

    private var nebulaLayers: some View {
        ZStack {
            // Purple nebula (top-right)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.12),
                            Theme.Colors.aiPurple.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 400)
                .rotationEffect(.degrees(backgroundRotation * 0.5))
                .offset(x: 150, y: -200)

            // Amber nebula (center-left)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiAmber.opacity(0.08),
                            Theme.Colors.aiOrange.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 350)
                .rotationEffect(.degrees(-backgroundRotation * 0.3))
                .offset(x: -100, y: 100)

            // Cyan nebula (bottom)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiCyan.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 300)
                .rotationEffect(.degrees(backgroundRotation * 0.2))
                .offset(x: 50, y: 300)
        }
        .blur(radius: 60)
        .ignoresSafeArea()
    }

    private var starFieldView: some View {
        Canvas { context, size in
            // Generate deterministic stars
            let stars = generateStars(count: 60, in: size)

            for star in stars {
                let rect = CGRect(
                    x: star.x - star.size / 2,
                    y: star.y - star.size / 2,
                    width: star.size,
                    height: star.size
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(star.brightness))
                )
            }
        }
        .ignoresSafeArea()
    }

    private func generateStars(count: Int, in size: CGSize) -> [(x: CGFloat, y: CGFloat, size: CGFloat, brightness: Double)] {
        var stars: [(x: CGFloat, y: CGFloat, size: CGFloat, brightness: Double)] = []
        var generator = SeededRandomGenerator(seed: 42)

        for _ in 0..<count {
            let star = (
                x: CGFloat.random(in: 0...size.width, using: &generator),
                y: CGFloat.random(in: 0...size.height, using: &generator),
                size: CGFloat.random(in: 1...3, using: &generator),
                brightness: Double.random(in: 0.2...0.8, using: &generator)
            )
            stars.append(star)
        }
        return stars
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(headerGreeting)
                .font(.system(size: 28, weight: .thin))
                .foregroundStyle(.white)

            Text("Enter your focus sanctuary")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, Theme.Spacing.lg)
    }

    private var headerGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning Focus"
        case 12..<17: return "Afternoon Focus"
        case 17..<21: return "Evening Focus"
        default: return "Night Focus"
        }
    }

    // MARK: - Quick Timer Section

    private var quickTimerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Timer Circle
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                    .frame(width: 180, height: 180)

                // Progress ring
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        LinearGradient(
                            colors: [selectedMode.accentColor, selectedMode.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerProgress)

                // Glow effect
                Circle()
                    .stroke(selectedMode.accentColor.opacity(0.3), lineWidth: 20)
                    .frame(width: 180, height: 180)
                    .blur(radius: 15)

                // Time display + Play button
                VStack(spacing: 12) {
                    Text(timerDisplayString)
                        .font(.system(size: 40, weight: .light, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    // Play/Pause Button
                    Button {
                        toggleTimer()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedMode.accentColor)
                                .frame(width: 48, height: 48)
                                .shadow(color: selectedMode.accentColor.opacity(0.4), radius: 12, y: 4)

                            Image(systemName: timerState == .running ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .offset(x: timerState == .running ? 0 : 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Mode Selector

    private var modeSelectorView: some View {
        HStack(spacing: 12) {
            ForEach(QuickFocusMode.allCases, id: \.self) { mode in
                QuickModeButton(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    isDisabled: timerState != .idle
                ) {
                    selectMode(mode)
                }
            }
        }
    }

    // MARK: - Timer Computed Properties

    private var timerProgress: Double {
        guard totalTime > 0 else {
            return selectedMode == .flow ? 1 : 0
        }
        return timeRemaining / totalTime
    }

    private var timerDisplayString: String {
        let absTime = abs(timeRemaining)
        let minutes = Int(absTime) / 60
        let seconds = Int(absTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Timer Actions

    private func toggleTimer() {
        HapticsService.shared.impact(.medium)

        switch timerState {
        case .idle:
            startTimer()
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        }
    }

    private func startTimer() {
        timerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            if selectedMode == .flow {
                timeRemaining += 1
            } else if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeSession()
            }
        }
    }

    private func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        timer = nil
    }

    private func resumeTimer() {
        timerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            if selectedMode == .flow {
                timeRemaining += 1
            } else if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeSession()
            }
        }
    }

    private func completeSession() {
        timer?.invalidate()
        timer = nil
        timerState = .idle

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Reset to mode duration
        timeRemaining = selectedMode.duration
        totalTime = selectedMode.duration
    }

    private func selectMode(_ mode: QuickFocusMode) {
        guard timerState == .idle else { return }

        HapticsService.shared.selectionFeedback()
        selectedMode = mode
        timeRemaining = mode.duration
        totalTime = mode.duration
    }

    // MARK: - Portal Cards

    private var portalCardsView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Focus Timer Portal
            FocusPortalCard(
                title: "Focus Timer",
                subtitle: "Set duration & start session",
                icon: "timer",
                accentColor: Theme.Colors.aiAmber,
                glowIntensity: 0.7 + portalPulse * 0.2
            ) {
                HapticsService.shared.impact()
                showFocusTimer = true
            }

            // App Blocking Portal
            FocusPortalCard(
                title: "App Blocking",
                subtitle: "Control your digital space",
                icon: "shield.lefthalf.filled",
                accentColor: Theme.Colors.aiCyan,
                glowIntensity: 0.5 + portalPulse * 0.15
            ) {
                HapticsService.shared.impact()
                showAppBlocking = true
            }
        }
    }

    // MARK: - Quick Stats Bar

    private var quickStatsBar: some View {
        HStack(spacing: Theme.Spacing.lg) {
            quickStatItem(value: "2h 45m", label: "Today's Focus", icon: "flame.fill", color: Theme.Colors.aiOrange)

            Divider()
                .frame(height: 30)
                .background(.white.opacity(0.2))

            quickStatItem(value: "5", label: "Sessions", icon: "checkmark.circle.fill", color: Theme.Colors.success)

            Divider()
                .frame(height: 30)
                .background(.white.opacity(0.2))

            quickStatItem(value: "85%", label: "Focus Score", icon: "star.fill", color: Theme.Colors.aiAmber)
        }
        .padding(Theme.Spacing.md)
        // 🌟 LIQUID GLASS: Interactive glass stats bar
        .glassEffect(
            .regular.interactive(true),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }

    private func quickStatItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Ambient Animations

    private func startAmbientAnimations() {
        guard !reduceMotion else {
            starsOpacity = 0.7
            return
        }

        // Fade in stars
        withAnimation(.easeOut(duration: 1.5)) {
            starsOpacity = 0.7
        }

        // Portal breathing
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            portalPulse = 1
        }

        // Slow background rotation
        withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
            backgroundRotation = 360
        }
    }
}

// MARK: - Focus Portal Card

struct FocusPortalCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let glowIntensity: Double
    let action: () -> Void

    @State private var isPressed = false
    @State private var orbRotation: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                // Portal glow background
                portalGlow

                // Glass container
                HStack(spacing: Theme.Spacing.lg) {
                    // Left: Animated orb icon
                    orbIconView

                    // Center: Title & subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    // Right: Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(Theme.Spacing.xl)
                // 🌟 LIQUID GLASS: Interactive glass with tint for portal effect
                .glassEffect(
                    .regular
                        .tint(accentColor.opacity(0.08))
                        .interactive(true),
                    in: RoundedRectangle(cornerRadius: 24)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.5),
                                    accentColor.opacity(0.3),
                                    .white.opacity(0.2),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: accentColor.opacity(0.2), radius: 16, y: 8)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    orbRotation = 360
                }
            }
        }
    }

    private var portalGlow: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(
                RadialGradient(
                    colors: [
                        accentColor.opacity(0.2 * glowIntensity),
                        accentColor.opacity(0.05 * glowIntensity),
                        Color.clear
                    ],
                    center: .leading,
                    startRadius: 0,
                    endRadius: 300
                )
            )
            .blur(radius: 20)
            .offset(x: -20)
    }

    private var orbIconView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(accentColor.opacity(0.3))
                .frame(width: 70, height: 70)
                .blur(radius: 15)

            // Rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            accentColor.opacity(0.6),
                            accentColor.opacity(0.2),
                            .clear,
                            accentColor.opacity(0.2),
                            accentColor.opacity(0.6)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(orbRotation))

            // Inner orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor,
                            accentColor.opacity(0.7)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 25
                    )
                )
                .frame(width: 44, height: 44)

            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Quick Mode Button

struct QuickModeButton: View {
    let mode: QuickFocusMode
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .medium))

                Text(mode.rawValue)
                    .font(.system(size: 12, weight: .medium))

                Text(mode.label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(
                .regular
                    .tint(isSelected ? mode.accentColor.opacity(0.15) : Color.clear)
                    .interactive(true),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .foregroundStyle(isSelected ? mode.accentColor : .white.opacity(0.7))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? mode.accentColor : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.4 : 1)
        .buttonStyle(.plain)
    }
}

// MARK: - Seeded Random Generator

struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Preview

#Preview {
    FocusMainView()
}
