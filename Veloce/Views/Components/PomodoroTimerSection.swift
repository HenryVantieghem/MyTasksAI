//
//  PomodoroTimerSection.swift
//  MyTasksAI
//
//  Pomodoro Timer Section for Task Detail Sheet
//  Focus timer with presets and AI estimate integration
//

import SwiftUI

// MARK: - Pomodoro Timer Section
struct PomodoroTimerSection: View {
    let task: TaskItem
    @State private var timerMinutes: Int = 25
    @State private var isTimerRunning: Bool = false
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?

    private let presets = [5, 15, 25] // Minutes

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
            }

            // Timer display
            Text(formattedTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(isTimerRunning ? Theme.Colors.accent : Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)

            // Preset buttons
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(presets, id: \.self) { minutes in
                    presetButton(minutes: minutes)
                }

                // AI estimate button (if available)
                if let aiMinutes = task.estimatedMinutes {
                    presetButton(minutes: aiMinutes, isAI: true)
                }
            }

            // Start/Pause button
            Button {
                toggleTimer()
                HapticsService.shared.impact()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                    Text(isTimerRunning ? "Pause" : "Start")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.accent, Theme.Colors.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .liquidGlass(cornerRadius: Theme.Radius.card)
        .onAppear {
            // Initialize with AI estimate if available, otherwise default to 25
            timerMinutes = task.estimatedMinutes ?? 25
            remainingSeconds = timerMinutes * 60
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Formatted Time
    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Preset Button
    private func presetButton(minutes: Int, isAI: Bool = false) -> some View {
        Button {
            selectPreset(minutes: minutes)
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 4) {
                if isAI {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                }
                Text("\(minutes)m")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(timerMinutes == minutes ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                timerMinutes == minutes
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
        timerMinutes = minutes
        remainingSeconds = minutes * 60
    }

    private func toggleTimer() {
        if isTimerRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                completeTimer()
            }
        }
    }

    private func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func completeTimer() {
        pauseTimer()
        HapticsService.shared.celebration()
        // Reset for next session
        remainingSeconds = timerMinutes * 60
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        IridescentBackground()
        PomodoroTimerSection(task: {
            let task = TaskItem(title: "Test task")
            task.estimatedMinutes = 30
            return task
        }())
        .padding()
    }
}
