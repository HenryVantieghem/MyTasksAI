//
//  FocusMode.swift
//  Veloce
//
//  Full-screen immersive focus timer with aurora glow effects
//  Beautiful breathing animations and service-connected timer
//

import SwiftUI
import FamilyControls

struct FocusMode: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @State private var pomodoroService = PomodoroTimerService.shared
    @State private var focusBlockingService = FocusBlockingService.shared
    @State private var screenTimeAuthService = ScreenTimeAuthService.shared
    @State private var showBreakPrompt = false
    @State private var showFocusSetup = false
    @State private var enableAppBlocking = false
    @State private var isDeepFocus = false

    // MARK: - Computed Properties

    private var isActiveForThisTask: Bool {
        pomodoroService.currentSession?.taskId == task.id
    }

    private var currentProgress: Double {
        pomodoroService.currentSession?.progress ?? 0
    }

    private var sessionsCompleted: Int {
        pomodoroService.currentSession?.sessionsCompleted ?? 0
    }

    private var isOnBreak: Bool {
        pomodoroService.currentSession?.state == .breakTime
    }

    var body: some View {
        ZStack {
            // Layer 1: Beautiful aurora glow background
            FocusModeGlow(
                progress: currentProgress,
                isActive: pomodoroService.isRunning,
                taskTitle: task.title
            )

            // Layer 2: Content overlay
            VStack(spacing: 0) {
                // Close button (top right)
                HStack {
                    Spacer()
                    closeButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // Task title with glow
                taskTitleView

                // Timer display (overlaid on glow center)
                timerDisplay
                    .padding(.top, 40)

                // Session counter
                sessionCounterView
                    .padding(.top, 24)

                // App blocking indicator
                if focusBlockingService.isBlocking {
                    blockingIndicator
                        .padding(.top, 16)
                }

                Spacer()

                // Control buttons
                controlButtons
                    .padding(.bottom, 60)
            }

            // Break prompt overlay
            if showBreakPrompt {
                breakPromptOverlay
            }
        }
        .onChange(of: pomodoroService.currentSession?.state) { _, newState in
            if newState == .completed {
                showBreakPrompt = true
                // End app blocking when session completes
                if focusBlockingService.isBlocking {
                    Task {
                        await focusBlockingService.endSession(completed: true)
                    }
                }
            }
        }
        .sheet(isPresented: $showFocusSetup) {
            FocusSessionSetupView(task: task) { duration, deepFocus, selection in
                isDeepFocus = deepFocus
                enableAppBlocking = selection != nil
                startFocusSession(duration: duration, isDeepFocus: deepFocus, selection: selection)
            }
        }
        .onAppear {
            // Check if blocking is available
            enableAppBlocking = screenTimeAuthService.isAuthorized && focusBlockingService.hasAppsSelected
        }
    }

    // MARK: - Start Focus Session with Blocking

    private func startFocusSession(duration: Int, isDeepFocus: Bool, selection: FamilyActivitySelection?) {
        // Start pomodoro timer
        pomodoroService.startSession(
            taskId: task.id,
            taskTitle: task.title,
            duration: duration
        )

        // Start app blocking if enabled
        if let selection = selection, !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
            Task {
                do {
                    try await focusBlockingService.startSession(
                        title: "Focus: \(task.title)",
                        duration: duration,
                        taskId: task.id,
                        taskTitle: task.title,
                        isDeepFocus: isDeepFocus,
                        selection: selection
                    )
                } catch {
                    print("Failed to start app blocking: \(error)")
                }
            }
        }

        HapticsService.shared.impact()
    }

    // MARK: - Close Button
    private var closeButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(SwiftUI.Circle())
        }
    }

    // MARK: - Task Title
    private var taskTitleView: some View {
        VStack(spacing: 8) {
            if isOnBreak {
                Text("Break Time")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiCyan)
            }

            Text(task.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 20)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Timer Display
    @ViewBuilder
    private var timerDisplay: some View {
        if let session = pomodoroService.currentSession, isActiveForThisTask {
            VStack(spacing: 8) {
                Text(session.formattedTime)
                    .font(.system(size: 72, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(.white)
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 30)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: session.remainingSeconds)

                // Time remaining label
                Text(isOnBreak ? "until focus resumes" : "remaining")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        } else {
            // No active session - show start prompt
            VStack(spacing: 16) {
                Text("Ready to focus?")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(task.estimatedMinutes ?? 25) min session")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Blocking Indicator
    private var blockingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: isDeepFocus ? "lock.shield.fill" : "shield.lefthalf.filled")
                .font(.system(size: 14))
                .foregroundStyle(isDeepFocus ? Theme.Colors.aiPurple : Theme.Colors.aiCyan)

            Text(isDeepFocus ? "Deep Focus Active" : "Apps Blocked")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            Text("•")
                .foregroundStyle(.white.opacity(0.3))

            Text(focusBlockingService.selectionSummary)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.3))
        .clipShape(Capsule())
    }

    // MARK: - Session Counter
    private var sessionCounterView: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                sessionDot(index: index, completed: index < sessionsCompleted)
            }
        }
    }

    private func sessionDot(index: Int, completed: Bool) -> some View {
        ZStack {
            SwiftUI.Circle()
                .fill(completed ? Theme.Colors.aiCyan : Color.white.opacity(0.15))
                .frame(width: 12, height: 12)

            if completed {
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiCyan)
                    .frame(width: 12, height: 12)
                    .shadow(color: Theme.Colors.aiCyan.opacity(0.8), radius: 6)
            }
        }
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 24) {
            if pomodoroService.isRunning && isActiveForThisTask {
                // Pause button
                controlButton(
                    icon: "pause.fill",
                    size: 70,
                    isPrimary: true
                ) {
                    pomodoroService.pauseSession()
                }

            } else if isActiveForThisTask && pomodoroService.currentSession != nil {
                // Resume button
                controlButton(
                    icon: "play.fill",
                    size: 70,
                    isPrimary: true
                ) {
                    pomodoroService.resumeSession()
                }

            } else {
                // Start buttons - Quick start and Advanced
                VStack(spacing: 12) {
                    // Quick start button
                    Button {
                        let duration = (task.estimatedMinutes ?? 25) * 60
                        pomodoroService.startSession(
                            taskId: task.id,
                            taskTitle: task.title,
                            duration: duration
                        )
                        HapticsService.shared.impact()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                            Text("Start Focus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 15)
                    }

                    // Advanced focus button (with app blocking)
                    Button {
                        showFocusSetup = true
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 14))
                            Text("Focus with App Blocking")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial.opacity(0.3))
                        .clipShape(Capsule())
                    }
                }
            }

            // Stop button (always visible when session active)
            if isActiveForThisTask && pomodoroService.currentSession != nil {
                // Check if Deep Focus prevents stopping
                if focusBlockingService.isBlocking && !focusBlockingService.canCancelSession {
                    // Deep Focus - show locked indicator instead of stop
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                        Text("Deep Focus")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.aiPurple.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.3))
                    .clipShape(Capsule())
                } else {
                    controlButton(
                        icon: "stop.fill",
                        size: 56,
                        isPrimary: false
                    ) {
                        pomodoroService.stopSession()
                        // Also end app blocking
                        if focusBlockingService.isBlocking {
                            Task {
                                await focusBlockingService.endSession(completed: false)
                            }
                        }
                        dismiss()
                    }
                }
            }
        }
    }

    private func controlButton(
        icon: String,
        size: CGFloat,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticsService.shared.impact()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(
                    isPrimary
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(.ultraThinMaterial.opacity(0.5))
                )
                .clipShape(SwiftUI.Circle())
                .shadow(color: isPrimary ? Theme.Colors.aiPurple.opacity(0.4) : .clear, radius: 10)
        }
    }

    // MARK: - Break Prompt Overlay
    private var breakPromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Celebration icon
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Colors.aiCyan)
                    .shadow(color: Theme.Colors.aiCyan.opacity(0.8), radius: 20)

                Text("Session Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("You've completed \(sessionsCompleted) session\(sessionsCompleted == 1 ? "" : "s").\nTime for a short break?")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    // Take break
                    Button {
                        showBreakPrompt = false
                        pomodoroService.startBreak()
                        HapticsService.shared.impact()
                    } label: {
                        Text("Take Break")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.aiCyan)
                            .clipShape(Capsule())
                    }

                    // Skip break
                    Button {
                        showBreakPrompt = false
                        pomodoroService.skipBreak()
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }

                // Done for now
                Button {
                    showBreakPrompt = false
                    pomodoroService.stopSession()
                    dismiss()
                } label: {
                    Text("Done for now")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 8)
                }
            }
            .padding(32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Preview
#Preview {
    FocusMode(task: {
        let task = TaskItem(title: "Complete the design review for new feature")
        task.estimatedMinutes = 25
        return task
    }())
}
