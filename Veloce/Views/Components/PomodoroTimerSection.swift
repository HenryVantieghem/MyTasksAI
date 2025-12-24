//
//  PomodoroTimerSection.swift
//  MyTasksAI
//
//  Pomodoro Timer Section for Task Detail Sheet
//  Focus timer with presets and AI estimate integration
//  NOW WIRED to PomodoroTimerService.shared for global state
//

import SwiftUI

// MARK: - Pomodoro Timer Section
struct PomodoroTimerSection: View {
    let task: TaskItem
    let onStartFocus: () -> Void  // Callback to launch FocusMode full-screen

    // Global service binding - no more local timer state!
    @State private var pomodoroService = PomodoroTimerService.shared
    @State private var selectedDuration: Int = 25  // For preset selection only

    private let presets = [5, 15, 25] // Minutes

    // MARK: - Computed Properties (from service)

    /// Is the timer currently running for THIS task?
    private var isTimerActiveForThisTask: Bool {
        pomodoroService.currentSession?.taskId == task.id
    }

    /// Is timer running (for this task or any task)?
    private var isTimerRunning: Bool {
        pomodoroService.isRunning
    }

    /// Is timer paused for this task?
    private var isTimerPaused: Bool {
        guard let session = pomodoroService.currentSession else { return false }
        return session.taskId == task.id && session.state == .paused
    }

    /// Remaining seconds from service (or selected duration)
    private var remainingSeconds: Int {
        if isTimerActiveForThisTask {
            return pomodoroService.currentSession?.remainingSeconds ?? (selectedDuration * 60)
        }
        return selectedDuration * 60
    }

    /// Button state: Start, Pause, or Resume
    private var buttonState: TimerButtonState {
        if isTimerActiveForThisTask {
            if pomodoroService.isRunning {
                return .pause
            } else if isTimerPaused {
                return .resume
            }
        }
        return .start
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.accent)
                Text("Focus Timer")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                // Session counter (if active)
                if let session = pomodoroService.currentSession, session.taskId == task.id {
                    sessionCounter(sessionsCompleted: session.sessionsCompleted)
                }
            }

            // Timer display with glow when running
            ZStack {
                // Glow effect when running
                if isTimerActiveForThisTask && isTimerRunning {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.accent.opacity(0.2))
                        .blur(radius: 30)
                        .frame(width: 120, height: 120)
                }

                Text(formattedTime)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundStyle(isTimerActiveForThisTask && isTimerRunning ? Theme.Colors.accent : Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)

            // Preset buttons (disabled if any timer is running)
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(presets, id: \.self) { minutes in
                    presetButton(minutes: minutes)
                }

                // AI estimate button (if available)
                if let aiMinutes = task.estimatedMinutes {
                    presetButton(minutes: aiMinutes, isAI: true)
                }
            }

            // Start/Pause/Resume button
            Button {
                handleButtonTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: buttonState.icon)
                        .font(.system(size: 16))
                    Text(buttonState.title)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(
                            LinearGradient(
                                colors: buttonState.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }

            // Stop button (only when timer is active for this task)
            if isTimerActiveForThisTask {
                Button {
                    pomodoroService.stopSession()
                    HapticsService.shared.selectionFeedback()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                        Text("Stop Timer")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .liquidGlass(cornerRadius: Theme.Radius.card)
        .onAppear {
            // Initialize selected duration with AI estimate if available
            selectedDuration = task.estimatedMinutes ?? 25
        }
    }

    // MARK: - Formatted Time
    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Session Counter
    private func sessionCounter(sessionsCompleted: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                SwiftUI.Circle()
                    .fill(index < sessionsCompleted ? Theme.Colors.aiCyan : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Preset Button
    private func presetButton(minutes: Int, isAI: Bool = false) -> some View {
        let isSelected = selectedDuration == minutes && !isTimerActiveForThisTask

        return Button {
            selectPreset(minutes: minutes)
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 4) {
                if isAI {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                }
                Text("\(minutes)m")
                    .font(.system(size: 13, weight: .medium, design: .default))
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(Theme.Colors.accent)
                    : AnyShapeStyle(Theme.Colors.glassBackground)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isTimerRunning)
        .opacity(isTimerRunning ? 0.5 : 1)
    }

    // MARK: - Actions
    private func selectPreset(minutes: Int) {
        guard !isTimerRunning else { return }
        selectedDuration = minutes
    }

    private func handleButtonTap() {
        switch buttonState {
        case .start:
            // Start new session and launch FocusMode
            pomodoroService.startSession(
                taskId: task.id,
                taskTitle: task.title,
                duration: selectedDuration * 60
            )
            onStartFocus()  // Launch full-screen FocusMode

        case .pause:
            pomodoroService.pauseSession()

        case .resume:
            pomodoroService.resumeSession()
            onStartFocus()  // Re-launch FocusMode on resume
        }
    }
}

// MARK: - Timer Button State
private enum TimerButtonState {
    case start
    case pause
    case resume

    var icon: String {
        switch self {
        case .start: return "play.fill"
        case .pause: return "pause.fill"
        case .resume: return "play.fill"
        }
    }

    var title: String {
        switch self {
        case .start: return "Start Focus"
        case .pause: return "Pause"
        case .resume: return "Resume"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .start, .resume:
            return [Theme.Colors.accent, Theme.Colors.accentSecondary]
        case .pause:
            return [Theme.Colors.warning, Theme.Colors.warning.opacity(0.8)]
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        IridescentBackground()
        PomodoroTimerSection(
            task: {
                let task = TaskItem(title: "Test task")
                task.estimatedMinutes = 30
                return task
            }(),
            onStartFocus: {
                print("Launch FocusMode!")
            }
        )
        .padding()
    }
}
