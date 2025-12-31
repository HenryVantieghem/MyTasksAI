//
//  ImmersiveFocusSessionView.swift
//  Veloce
//
//  Full-screen immersive focus session experience
//  Utopian background, orbital timer, zen atmosphere
//

import SwiftUI

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

    // Services
    private let blockingService = FocusBlockingService.shared

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var timer: Timer.TimerPublisher {
        Timer.publish(every: 1, on: .main, in: .common)
    }

    @State private var timerSubscription: AnyCancellable?

    var body: some View {
        ZStack {
            // Utopian background
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

    // MARK: - Utopian Background

    private var auroraBackground: some View {
        ZStack {
            // Base void
            Color.black

            // Utopian layers
            GeometryReader { geometry in
                ZStack {
                    // Primary aurora wave
                    auroraWave(
                        color: isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber,
                        phase: auroraPhase,
                        amplitude: 100,
                        frequency: 1.5
                    )
                    .opacity(0.3)
                    .offset(y: geometry.size.height * 0.3)

                    // Secondary aurora wave
                    auroraWave(
                        color: isBreak ? Theme.Colors.aiPurple : Theme.Colors.aiOrange,
                        phase: auroraPhase + 0.5,
                        amplitude: 80,
                        frequency: 2
                    )
                    .opacity(0.2)
                    .offset(y: geometry.size.height * 0.4)

                    // Tertiary subtle wave
                    auroraWave(
                        color: Theme.Colors.aiPurple,
                        phase: auroraPhase + 1,
                        amplitude: 60,
                        frequency: 2.5
                    )
                    .opacity(0.15)
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

            for _ in 0..<40 {
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
                    .dynamicTypeFont(base: 18, weight: .medium)
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
                        .dynamicTypeFont(base: 14, weight: .medium)
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
                .fill(isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber)
                .frame(width: 8, height: 8)

            Text(isBreak ? "Break Time" : "Focus Session")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(.ultraThinMaterial))
    }

    // MARK: - Orbital Timer

    private var orbitalTimerView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber).opacity(0.3),
                            (isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber).opacity(0.1),
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

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber,
                            isBreak ? Theme.Colors.aiPurple : Theme.Colors.aiOrange,
                            isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber
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
                                    .white.opacity(0.1),
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

                Text(isBreak ? "until next session" : "remaining")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Orbiting dot
            Circle()
                .fill(isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber)
                .frame(width: 12, height: 12)
                .shadow(color: (isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber).opacity(0.8), radius: 8)
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
                    .dynamicTypeFont(base: 12, weight: .medium)
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
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(.white.opacity(0.5))
            }

            if let task = session?.tasks.first {
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Image(systemName: task.taskType.icon)
                        .dynamicTypeFont(base: 20)
                        .foregroundStyle(taskTypeColor(for: task.taskType))

                    Text(task.title.prefix(12) + (task.title.count > 12 ? "..." : ""))
                        .dynamicTypeFont(base: 12, weight: .medium)
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
                    .dynamicTypeFont(base: 24, weight: .medium)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            // Play/Pause
            Button {
                togglePause()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .dynamicTypeFont(base: 32, weight: .medium)
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber,
                                        isBreak ? Theme.Colors.aiPurple : Theme.Colors.aiOrange
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: (isBreak ? Theme.Colors.aiCyan : Theme.Colors.aiAmber).opacity(0.5), radius: 20)
            }

            // Forward 30s
            Button {
                adjustTime(by: -30)
            } label: {
                Image(systemName: "goforward.30")
                    .dynamicTypeFont(base: 24, weight: .medium)
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
                    .dynamicTypeFont(base: 48)
                    .foregroundStyle(Theme.Colors.aiOrange)

                Text("End Session?")
                    .dynamicTypeFont(base: 24, weight: .bold)
                    .foregroundStyle(.white)

                Text("You've been focused for \(elapsedTimeString). Ending now won't count as a completed session.")
                    .dynamicTypeFont(base: 15)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        showExitConfirmation = false
                    } label: {
                        Text("Keep Going")
                            .dynamicTypeFont(base: 16, weight: .semibold)
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
                            .dynamicTypeFont(base: 16, weight: .semibold)
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
                        .dynamicTypeFont(base: 48, weight: .bold)
                        .foregroundStyle(.white)
                }

                Text("Session Complete!")
                    .dynamicTypeFont(base: 28, weight: .bold)
                    .foregroundStyle(.white)

                Text("Great focus! You've completed \(sessionsCompleted + 1) session\(sessionsCompleted == 0 ? "" : "s") today.")
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        startBreak()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "cup.and.saucer.fill")
                                .dynamicTypeFont(base: 24)
                            Text("Take Break")
                                .dynamicTypeFont(base: 14, weight: .medium)
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
                                .dynamicTypeFont(base: 24)
                            Text("Continue")
                                .dynamicTypeFont(base: 14, weight: .medium)
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
                        .dynamicTypeFont(base: 15, weight: .medium)
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
        if isBreak {
            // Break ended, start new session
            HapticsService.shared.heartbeatPulse() // Gentle pulse for break end
            isBreak = false
            startNextSession()
        } else {
            // Focus session completed - CELEBRATE!
            HapticsService.shared.starburstAscend() // Rising triumph haptic
            sessionsCompleted += 1
            showCompletion = true
        }
    }

    private func togglePause() {
        isPaused.toggle()
        HapticsService.shared.magneticSnap() // Satisfying pause click
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

        // Utopian wave animation
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
