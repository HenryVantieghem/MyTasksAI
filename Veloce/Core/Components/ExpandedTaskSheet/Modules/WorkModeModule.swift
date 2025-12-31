//
//  WorkModeModule.swift
//  MyTasksAI
//
//  Deep Work vs Pomodoro toggle
//  AI explanation for recommendation
//  Timer integration with FocusMode launch
//

import SwiftUI

// MARK: - Work Mode Module

struct WorkModeModule: View {
    let task: TaskItem
    @Bindable var viewModel: GeniusSheetViewModel
    let onStartFocus: () -> Void

    @State private var pomodoroService = PomodoroTimerService.shared

    private let accentColor = Theme.TaskCardColors.workMode

    private var isTimerActiveForThisTask: Bool {
        pomodoroService.currentSession?.taskId == task.id
    }

    var body: some View {
        ModuleCard(
            title: "WORK MODE",
            icon: "brain.head.profile.fill",
            accentColor: accentColor
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Mode selector
                HStack(spacing: Theme.Spacing.sm) {
                    modeCard(.deepWork)
                    modeCard(.pomodoro)
                }

                // AI Explanation
                aiExplanation

                // Start button
                startTimerButton
            }
        }
    }

    // MARK: - Mode Card

    private func modeCard(_ mode: WorkMode) -> some View {
        let isSelected = viewModel.selectedWorkMode == mode
        let isRecommended = viewModel.suggestedWorkMode == mode

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedWorkMode = mode
            }
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        } label: {
            VStack(spacing: 8) {
                // Icon
                Image(systemName: mode.icon)
                    .dynamicTypeFont(base: 24, weight: .medium)

                // Mode name
                Text(mode.rawValue)
                    .dynamicTypeFont(base: 13, weight: .semibold)

                // Duration
                Text(mode.duration)
                    .dynamicTypeFont(base: 11, weight: .regular)
                    .foregroundStyle(.white.opacity(0.7))

                // AI recommended badge
                if isRecommended {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .dynamicTypeFont(base: 8)
                        Text("AI Pick")
                            .dynamicTypeFont(base: 9, weight: .medium)
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.15))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? accentColor.opacity(0.5) : Color.white.opacity(0.08),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Explanation

    private var aiExplanation: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .dynamicTypeFont(base: 12)
                .foregroundStyle(accentColor)
                .padding(.top, 2)

            Text(viewModel.workModeReason)
                .dynamicTypeFont(base: 13, weight: .regular)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(3)
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.opacity(0.05))
        )
    }

    // MARK: - Start Timer Button

    private var startTimerButton: some View {
        Button {
            startFocusSession()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: buttonIcon)
                    .dynamicTypeFont(base: 12)
                Text(buttonLabel)
                    .dynamicTypeFont(base: 14, weight: .semibold)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: accentColor.opacity(0.3), radius: 6, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    private var buttonIcon: String {
        if isTimerActiveForThisTask {
            return pomodoroService.isPaused ? "play.fill" : "pause.fill"
        }
        return "play.fill"
    }

    private var buttonLabel: String {
        if isTimerActiveForThisTask {
            if pomodoroService.isPaused {
                return "Resume Focus"
            }
            return "Pause Focus"
        }
        return "Start \(viewModel.selectedWorkMode?.rawValue ?? "Deep Work")"
    }

    private func startFocusSession() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isTimerActiveForThisTask {
            // Toggle pause/resume
            if pomodoroService.isPaused {
                pomodoroService.resumeSession()
                onStartFocus()  // Show FocusMode
            } else {
                pomodoroService.pauseSession()
            }
        } else {
            // Start new session
            let duration = viewModel.selectedWorkMode == .deepWork ? 90 * 60 : 25 * 60
            pomodoroService.startSession(
                taskId: task.id,
                taskTitle: task.title,
                duration: duration
            )
            viewModel.isTimerActive = true
            onStartFocus()  // Launch FocusMode full-screen
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        WorkModeModule(
            task: {
                let task = TaskItem(title: "Write quarterly report")
                task.taskTypeRaw = TaskType.create.rawValue
                return task
            }(),
            viewModel: {
                let vm = GeniusSheetViewModel()
                vm.suggestedWorkMode = .deepWork
                vm.selectedWorkMode = .deepWork
                vm.workModeReason = "Creative tasks need uninterrupted flow. Pomodoro breaks would fragment your thinking."
                return vm
            }(),
            onStartFocus: { print("Start Focus") }
        )
        .padding()
    }
}
