//
//  CelestialFocusSection.swift
//  Veloce
//
//  Focus section with work mode selection and Pomodoro timer controls.
//  Supports Deep Work, Pomodoro, and custom focus modes.
//

import SwiftUI

struct CelestialFocusSection: View {
    @Bindable var viewModel: CelestialTaskCardViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Work Mode Recommendation
            workModeRecommendation

            // Work Mode Selector
            workModeSelector

            // Start Focus Button
            startFocusButton
        }
        .padding(Theme.Spacing.md)
        .celestialGlassCard(accent: Theme.TaskCardColors.workMode)
    }

    // MARK: - Work Mode Recommendation

    private var workModeRecommendation: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("AI Recommendation")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()
            }

            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: viewModel.suggestedWorkMode.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(viewModel.suggestedWorkMode.color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(viewModel.suggestedWorkMode.color.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.suggestedWorkMode.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(viewModel.workModeReason)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .lineLimit(2)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(viewModel.suggestedWorkMode.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(viewModel.suggestedWorkMode.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Work Mode Selector

    private var workModeSelector: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Choose Your Mode")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starDim)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(WorkMode.allCases, id: \.self) { mode in
                    workModeCard(mode)
                }
            }
        }
    }

    private func workModeCard(_ mode: WorkMode) -> some View {
        let isSelected = viewModel.selectedWorkMode == mode
        let isRecommended = mode == viewModel.suggestedWorkMode

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedWorkMode = mode
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: mode.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : mode.color)

                    if isRecommended {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Theme.Colors.xp)
                            .offset(x: 4, y: -4)
                    }
                }

                Text(mode.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starDim)
                    .lineLimit(1)

                Text(mode.durationText)
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : Theme.CelestialColors.starDim.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? mode.color : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isSelected ? .clear : mode.color.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Start Focus Button

    private var startFocusButton: some View {
        Button {
            viewModel.showFocusMode = true
            HapticsService.shared.mediumImpact()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "scope")
                    .font(.system(size: 16, weight: .semibold))

                Text("Start Focus Session")
                    .font(.system(size: 15, weight: .semibold))

                if let mode = viewModel.selectedWorkMode {
                    Text("• \(mode.durationText)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                viewModel.selectedWorkMode?.color ?? Theme.TaskCardColors.workMode,
                                (viewModel.selectedWorkMode?.color ?? Theme.TaskCardColors.workMode).opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: (viewModel.selectedWorkMode?.color ?? Theme.TaskCardColors.workMode).opacity(0.3), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Work Mode Extension

extension WorkMode {
    var color: Color {
        switch self {
        case .deepWork:
            return Theme.TaskCardColors.workMode
        case .pomodoro:
            return Theme.TaskCardColors.schedule
        case .flowState:
            return Theme.Colors.aiPurple
        }
    }

    var displayName: String {
        switch self {
        case .deepWork:
            return "Deep Work"
        case .pomodoro:
            return "Pomodoro"
        case .flowState:
            return "Flow State"
        }
    }

    var durationText: String {
        switch self {
        case .deepWork:
            return "90 min"
        case .pomodoro:
            return "25 min"
        case .flowState:
            return "No limit"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            CelestialFocusSection(
                viewModel: {
                    let task = TaskItem(title: "Complete project proposal")
                    task.starRating = 3
                    task.taskType = .create
                    return CelestialTaskCardViewModel(task: task)
                }()
            )
            .padding()
        }
    }
}
