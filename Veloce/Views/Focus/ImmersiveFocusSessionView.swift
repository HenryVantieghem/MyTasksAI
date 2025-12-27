//
//  ImmersiveFocusSessionView.swift
//  Veloce
//
//  Full-screen immersive focus session experience
//  Aurora background, orbital timer, zen atmosphere
//  Mode-specific atmospheres and gamification integration
//

import SwiftUI

// MARK: - Focus Mode Atmosphere

struct FocusModeAtmosphere {
    let primaryColor: Color
    let secondaryColor: Color
    let tertiaryColor: Color
    let waveAmplitude: CGFloat
    let waveFrequency: Double
    let particleCount: Int
    let glowIntensity: Double

    static func atmosphere(for mode: FocusTimerMode) -> FocusModeAtmosphere {
        switch mode {
        case .pomodoro:
            return FocusModeAtmosphere(
                primaryColor: Theme.Colors.aiAmber,
                secondaryColor: Theme.Colors.aiOrange,
                tertiaryColor: Theme.Colors.aiPink.opacity(0.5),
                waveAmplitude: 120,
                waveFrequency: 2.0,
                particleCount: 50,
                glowIntensity: 0.8
            )
        case .deepWork:
            return FocusModeAtmosphere(
                primaryColor: Theme.Colors.aiPurple,
                secondaryColor: Theme.Colors.aiBlue,
                tertiaryColor: Theme.Colors.aiCyan.opacity(0.4),
                waveAmplitude: 80,
                waveFrequency: 1.5,
                particleCount: 35,
                glowIntensity: 0.6
            )
        case .flowState:
            return FocusModeAtmosphere(
                primaryColor: Theme.Colors.aiCyan,
                secondaryColor: Theme.Colors.aiPink,
                tertiaryColor: Theme.Colors.aiPurple.opacity(0.4),
                waveAmplitude: 60,
                waveFrequency: 1.0,
                particleCount: 60,
                glowIntensity: 0.5
            )
        case .custom:
            return FocusModeAtmosphere(
                primaryColor: Theme.Colors.aiAmber,
                secondaryColor: Theme.Colors.aiPurple,
                tertiaryColor: Theme.Colors.aiCyan.opacity(0.3),
                waveAmplitude: 90,
                waveFrequency: 1.8,
                particleCount: 45,
                glowIntensity: 0.7
            )
        }
    }

    static let breakAtmosphere = FocusModeAtmosphere(
        primaryColor: Theme.Colors.aiCyan,
        secondaryColor: Theme.Colors.aiGreen,
        tertiaryColor: Theme.Colors.aiBlue.opacity(0.3),
        waveAmplitude: 100,
        waveFrequency: 1.2,
        particleCount: 40,
        glowIntensity: 0.5
    )
}

// MARK: - Immersive Focus Session View

struct ImmersiveFocusSessionView: View {
    var session: FocusSession?
    var onComplete: ((Bool) -> Void)?

    // Timer state
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var totalTime: TimeInterval = 25 * 60
    @State private var isRunning = true
    @State private var isPaused = false
    @State private var isBreak = false

    // Session tracking
    @State private var sessionsCompleted = 0
    @State private var currentSessionNumber = 1

    // Visual states
    @State private var auroraPhase: Double = 0
    @State private var breathingScale: CGFloat = 1
    @State private var showCompletion = false
    @State private var showExitConfirmation = false
    @State private var showMilestoneCelebration = false
    @State private var currentMilestone: MilestoneType?

    // Gamification
    @State private var xpEarned: Int = 0

    // Services
    private let blockingService = FocusBlockingService.shared
    private let gamificationService = GamificationService.shared

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Computed atmosphere based on mode
    private var currentAtmosphere: FocusModeAtmosphere {
        if isBreak {
            return FocusModeAtmosphere.breakAtmosphere
        }
        return FocusModeAtmosphere.atmosphere(for: session?.mode ?? .pomodoro)
    }

    private var timer: Timer.TimerPublisher {
        Timer.publish(every: 1, on: .main, in: .common)
    }

    @State private var timerSubscription: AnyCancellable?

    var body: some View {
        ZStack {
            // Aurora background
            auroraBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top controls
                topControlsBar
                    .padding(.top, 60)

                Spacer()

                // Central timer orb
                orbitalTimerView
                    .scaleEffect(breathingScale)

                Spacer()

                // Session info
                sessionInfoBar

                // Bottom controls
                bottomControls
                    .padding(.bottom, 50)
            }

            // Exit confirmation overlay
            if showExitConfirmation {
                exitConfirmationOverlay
            }

            // Completion celebration
            if showCompletion {
                completionCelebrationOverlay
            }

            // Milestone celebration (gem unlock)
            if showMilestoneCelebration, let milestone = currentMilestone {
                MilestoneCelebrationView(milestone: milestone) {
                    showMilestoneCelebration = false
                    currentMilestone = nil
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupSession()
            startTimer()
            startAmbientAnimations()
        }
        .onDisappear {
            timerSubscription?.cancel()
        }
    }

    // MARK: - Aurora Background

    private var auroraBackground: some View {
        ZStack {
            // Base void
            Color.black

            // Aurora layers - uses mode-specific atmosphere
            GeometryReader { geometry in
                ZStack {
                    // Primary aurora wave
                    auroraWave(
                        color: currentAtmosphere.primaryColor,
                        phase: auroraPhase,
                        amplitude: currentAtmosphere.waveAmplitude,
                        frequency: currentAtmosphere.waveFrequency
                    )
                    .opacity(0.3 * currentAtmosphere.glowIntensity)
                    .offset(y: geometry.size.height * 0.3)

                    // Secondary aurora wave
                    auroraWave(
                        color: currentAtmosphere.secondaryColor,
                        phase: auroraPhase + 0.5,
                        amplitude: currentAtmosphere.waveAmplitude * 0.8,
                        frequency: currentAtmosphere.waveFrequency * 1.3
                    )
                    .opacity(0.2 * currentAtmosphere.glowIntensity)
                    .offset(y: geometry.size.height * 0.4)

                    // Tertiary subtle wave
                    auroraWave(
                        color: currentAtmosphere.tertiaryColor,
                        phase: auroraPhase + 1,
                        amplitude: currentAtmosphere.waveAmplitude * 0.6,
                        frequency: currentAtmosphere.waveFrequency * 1.6
                    )
                    .opacity(0.15 * currentAtmosphere.glowIntensity)
                    .offset(y: geometry.size.height * 0.5)
                }
            }

            // Particle overlay
            particleFieldView
                .opacity(0.4)

            // Vignette
            RadialGradient(
                colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.7)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
        }
    }

    private func auroraWave(color: Color, phase: Double, amplitude: CGFloat, frequency: Double) -> some View {
        Canvas { context, size in
            var path = Path()

            let waveHeight = amplitude
            let wavelength = size.width / frequency

            path.move(to: CGPoint(x: 0, y: size.height))

            for x in stride(from: 0, to: size.width, by: 2) {
                let relativeX = x / wavelength
                let y = sin(relativeX * .pi * 2 + phase * .pi * 2) * waveHeight + size.height / 2
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()

            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        color.opacity(0.6),
                        color.opacity(0.3),
                        color.opacity(0.1),
                        .clear
                    ]),
                    startPoint: CGPoint(x: size.width / 2, y: 0),
                    endPoint: CGPoint(x: size.width / 2, y: size.height)
                )
            )
        }
        .blur(radius: 30)
    }

    private var particleFieldView: some View {
        Canvas { context, size in
            var generator = SeededRandomGenerator(seed: 123)

            for _ in 0..<currentAtmosphere.particleCount {
                let x = CGFloat.random(in: 0...size.width, using: &generator)
                let y = CGFloat.random(in: 0...size.height, using: &generator)
                let particleSize = CGFloat.random(in: 1...2.5, using: &generator)
                let brightness = Double.random(in: 0.3...0.8, using: &generator)

                let rect = CGRect(
                    x: x - particleSize / 2,
                    y: y - particleSize / 2,
                    width: particleSize,
                    height: particleSize
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(brightness))
                )
            }
        }
    }

    // MARK: - Top Controls

    private var topControlsBar: some View {
        HStack {
            // Exit button
            Button {
                if timeRemaining < totalTime {
                    showExitConfirmation = true
                } else {
                    endSession(completed: false)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            // Mode indicator
            modeIndicator

            Spacer()

            // Skip break button (only during breaks)
            if isBreak {
                Button {
                    skipBreak()
                } label: {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
    }

    private var modeIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(currentAtmosphere.primaryColor)
                .frame(width: 8, height: 8)

            Text(isBreak ? "Break Time" : (session?.mode.rawValue ?? "Focus Session"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(.ultraThinMaterial))
    }

    // MARK: - Orbital Timer

    private var orbitalTimerView: some View {
        ZStack {
            // Outer glow - mode-specific atmosphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentAtmosphere.primaryColor.opacity(0.3 * currentAtmosphere.glowIntensity),
                            currentAtmosphere.primaryColor.opacity(0.1 * currentAtmosphere.glowIntensity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 200
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 20)

            // Progress ring background
            Circle()
                .stroke(.white.opacity(0.1), lineWidth: 8)
                .frame(width: 260, height: 260)

            // Progress ring - mode-specific gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            currentAtmosphere.primaryColor,
                            currentAtmosphere.secondaryColor,
                            currentAtmosphere.primaryColor
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Inner glass orb
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 220, height: 220)
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    currentAtmosphere.primaryColor.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }

            // Time display
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(isBreak ? "until next session" : "remaining")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Orbiting dot - mode-specific
            Circle()
                .fill(currentAtmosphere.primaryColor)
                .frame(width: 12, height: 12)
                .shadow(color: currentAtmosphere.primaryColor.opacity(0.8), radius: 8)
                .offset(y: -130)
                .rotationEffect(.degrees(360 * progress - 90))
                .animation(.linear(duration: 1), value: progress)
        }
    }

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1 - (timeRemaining / totalTime)
    }

    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Session Info

    private var sessionInfoBar: some View {
        HStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: 4) {
                Text("\(currentSessionNumber)")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Session")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text("\(sessionsCompleted)")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.success)

                Text("Completed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            if let task = session?.tasks.first {
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Image(systemName: task.taskType.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(taskTypeColor(for: task.taskType))

                    Text(task.title.prefix(12) + (task.title.count > 12 ? "..." : ""))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.lg)
        .padding(.horizontal, Theme.Spacing.xl)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.bottom, Theme.Spacing.lg)
    }

    private func taskTypeColor(for type: TaskType) -> Color {
        switch type {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: Theme.Spacing.xl) {
            // Rewind 30s
            Button {
                adjustTime(by: 30)
            } label: {
                Image(systemName: "gobackward.30")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            // Play/Pause
            Button {
                togglePause()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        currentAtmosphere.primaryColor,
                                        currentAtmosphere.secondaryColor
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: currentAtmosphere.primaryColor.opacity(0.5), radius: 20)
            }

            // Forward 30s
            Button {
                adjustTime(by: -30)
            } label: {
                Image(systemName: "goforward.30")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
    }

    // MARK: - Exit Confirmation

    private var exitConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    showExitConfirmation = false
                }

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Colors.aiOrange)

                Text("End Session?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text("You've been focused for \(elapsedTimeString). Ending now won't count as a completed session.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        showExitConfirmation = false
                    } label: {
                        Text("Keep Going")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.aiAmber)
                            }
                    }

                    Button {
                        endSession(completed: false)
                    } label: {
                        Text("End")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            }
                    }
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.xl)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            }
            .padding(.horizontal, 40)
        }
    }

    private var elapsedTimeString: String {
        let elapsed = totalTime - timeRemaining
        let minutes = Int(elapsed) / 60
        if minutes < 1 {
            return "less than a minute"
        } else if minutes == 1 {
            return "1 minute"
        } else {
            return "\(minutes) minutes"
        }
    }

    // MARK: - Completion Celebration

    private var completionCelebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                // Celebration animation
                ZStack {
                    Circle()
                        .fill(Theme.Colors.success.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .scaleEffect(breathingScale * 1.2)

                    Circle()
                        .fill(Theme.Colors.success.opacity(0.3))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Session Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Great focus! You've completed \(sessionsCompleted) session\(sessionsCompleted == 1 ? "" : "s") today.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                // XP Earned
                if xpEarned > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.aiAmber)

                        Text("+\(xpEarned) XP")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.aiAmber, Theme.Colors.aiOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.aiAmber.opacity(0.2))
                    }
                }

                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        startBreak()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 24))
                            Text("Take Break")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.Colors.aiCyan)
                        }
                    }

                    Button {
                        startNextSession()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                            Text("Continue")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.Colors.aiAmber)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.md)

                Button {
                    endSession(completed: true)
                } label: {
                    Text("Finish for Now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.xl)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Timer Logic

    private func setupSession() {
        if let session = session {
            totalTime = TimeInterval(session.duration * 60)
            timeRemaining = totalTime
        } else {
            totalTime = 25 * 60
            timeRemaining = totalTime
        }
    }

    private func startTimer() {
        timerSubscription = timer.autoconnect().sink { _ in
            guard isRunning && !isPaused else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerCompleted()
            }
        }
    }

    private func timerCompleted() {
        HapticsService.shared.notification(.success)

        if isBreak {
            // Break ended, start new session
            isBreak = false
            startNextSession()
        } else {
            // Focus session completed
            sessionsCompleted += 1

            // Award gamification XP
            awardSessionXP()

            // Check for milestone achievements
            checkForMilestones()

            showCompletion = true
        }
    }

    private func awardSessionXP() {
        let sessionMinutes = Int(totalTime / 60)
        let baseXP = sessionMinutes * 2 // 2 XP per minute

        // Bonus for longer sessions
        let bonusXP: Int
        if sessionMinutes >= 90 {
            bonusXP = 100 // Deep work bonus
        } else if sessionMinutes >= 45 {
            bonusXP = 50
        } else if sessionMinutes >= 25 {
            bonusXP = 25
        } else {
            bonusXP = 0
        }

        xpEarned = baseXP + bonusXP

        // Award points via gamification service
        _ = gamificationService.awardPoints(xpEarned)

        // Record focus time
        gamificationService.recordFocusTime(minutes: sessionMinutes)
    }

    private func checkForMilestones() {
        // Check for first focus session (Sapphire gem)
        if sessionsCompleted == 1 {
            showMilestone(.gemUnlocked(.sapphire))
            return
        }

        // Check for 90+ minute session (Emerald gem - Deep Diver)
        let sessionMinutes = Int(totalTime / 60)
        if sessionMinutes >= 90 {
            showMilestone(.gemUnlocked(.emerald))
            return
        }

        // Check streak milestones (Ruby at 7 days, Diamond at 30 days)
        // This would integrate with a streak tracking system
        // For now, we'll trigger on session count as placeholder
        if sessionsCompleted == 7 {
            showMilestone(.streakMilestone(7))
        } else if sessionsCompleted == 30 {
            showMilestone(.streakMilestone(30))
        }
    }

    private func showMilestone(_ milestone: MilestoneType) {
        currentMilestone = milestone
        showMilestoneCelebration = true
    }

    private func togglePause() {
        isPaused.toggle()
        HapticsService.shared.impact()
    }

    private func adjustTime(by seconds: TimeInterval) {
        timeRemaining = max(0, min(totalTime, timeRemaining + seconds))
        HapticsService.shared.selectionFeedback()
    }

    private func skipBreak() {
        isBreak = false
        startNextSession()
    }

    private func startBreak() {
        showCompletion = false
        isBreak = true
        timeRemaining = 5 * 60 // 5 minute break
        totalTime = 5 * 60
    }

    private func startNextSession() {
        showCompletion = false
        isBreak = false
        currentSessionNumber += 1

        if let session = session {
            totalTime = TimeInterval(session.duration * 60)
        } else {
            totalTime = 25 * 60
        }
        timeRemaining = totalTime
    }

    private func endSession(completed: Bool) {
        timerSubscription?.cancel()

        // Stop any active app blocking
        if session?.enableAppBlocking == true {
            Task { await blockingService.endSession() }
        }

        onComplete?(completed)
        dismiss()
    }

    // MARK: - Ambient Animations

    private func startAmbientAnimations() {
        guard !reduceMotion else { return }

        // Aurora wave animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            auroraPhase = 1
        }

        // Breathing animation
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathingScale = 1.05
        }
    }
}

// Note: FocusSession is defined in FocusTimerSetupView.swift

// MARK: - Cancellable Import

import Combine

// MARK: - Preview

#Preview {
    ImmersiveFocusSessionView(
        session: FocusSession(),
        onComplete: { _ in }
    )
}
