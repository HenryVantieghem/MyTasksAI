//
//  CelestialHeaderSection.swift
//  Veloce
//
//  Header section for CelestialTaskCard with editable title,
//  priority stars, duration badge, and task type indicator.
//

import SwiftUI

struct CelestialHeaderSection: View {
    @Bindable var viewModel: CelestialTaskCardViewModel
    @FocusState private var isTitleFocused: Bool
    @State private var isEditingTitle = false

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Top row: Task type badge + Duration badges
            HStack(spacing: Theme.Spacing.sm) {
                taskTypeBadge
                Spacer()

                // AI estimated duration (if available)
                if let aiMinutes = viewModel.aiEstimatedDuration {
                    aiDurationBadge(aiMinutes)
                }

                // Manual duration (if set and different from AI)
                if let duration = viewModel.formattedDuration,
                   viewModel.aiEstimatedDuration == nil {
                    durationBadge(duration)
                }
            }

            // Editable Title
            titleSection

            // Priority Stars + Scheduled Time
            HStack {
                priorityStars
                Spacer()
                if let scheduledTime = viewModel.editedScheduledTime {
                    scheduledTimeBadge(scheduledTime)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .celestialGlassCard(accent: viewModel.taskTypeColor)
    }

    // MARK: - Task Type Badge

    private var taskTypeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.task.taskType.icon)
                .dynamicTypeFont(base: 12, weight: .semibold)

            Text(viewModel.task.taskType.displayName)
                .dynamicTypeFont(base: 12, weight: .semibold)
        }
        .foregroundStyle(viewModel.taskTypeColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(viewModel.taskTypeColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(viewModel.taskTypeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Duration Badge

    private func durationBadge(_ duration: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .dynamicTypeFont(base: 11, weight: .medium)
            Text(duration)
                .dynamicTypeFont(base: 12, weight: .medium)
        }
        .foregroundStyle(Theme.CelestialColors.starWhite)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - AI Duration Badge

    private func aiDurationBadge(_ minutes: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .dynamicTypeFont(base: 10, weight: .medium)
            Image(systemName: "clock")
                .dynamicTypeFont(base: 11, weight: .medium)
            Text(formatAIDuration(minutes))
                .dynamicTypeFont(base: 12, weight: .medium)

            // Confidence indicator
            if let confidence = viewModel.durationConfidence {
                confidenceIndicator(confidence)
            }
        }
        .foregroundStyle(Theme.Colors.aiPurple)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Theme.Colors.aiPurple.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.Colors.aiPurple.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func confidenceIndicator(_ confidence: String) -> some View {
        let icon: String
        let color: Color

        switch confidence.lowercased() {
        case "high":
            icon = "checkmark.circle.fill"
            color = Theme.Colors.success
        case "low":
            icon = "questionmark.circle"
            color = Theme.Colors.warning
        default:
            icon = "circle.fill"
            color = Theme.Colors.aiPurple
        }

        return Image(systemName: icon)
            .dynamicTypeFont(base: 9)
            .foregroundStyle(color)
    }

    private func formatAIDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditingTitle {
                TextField("Task title", text: $viewModel.editedTitle)
                    .dynamicTypeFont(base: 22, weight: .bold)
                    .foregroundStyle(.white)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isEditingTitle = false
                        viewModel.markTitleChanged(viewModel.editedTitle)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(viewModel.taskTypeColor.opacity(0.5), lineWidth: 1)
                            )
                    )
            } else {
                Button {
                    isEditingTitle = true
                    isTitleFocused = true
                } label: {
                    HStack {
                        Text(viewModel.editedTitle)
                            .dynamicTypeFont(base: 22, weight: .bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)

                        Spacer()

                        Image(systemName: "pencil")
                            .dynamicTypeFont(base: 14, weight: .medium)
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Priority Stars

    private var priorityStars: some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if viewModel.editedPriority == index {
                            viewModel.editedPriority = 0
                        } else {
                            viewModel.editedPriority = index
                        }
                        viewModel.hasUnsavedChanges = true
                    }
                    HapticsService.shared.selectionFeedback()
                } label: {
                    Image(systemName: index <= viewModel.editedPriority ? "star.fill" : "star")
                        .dynamicTypeFont(base: 18, weight: .medium)
                        .foregroundStyle(
                            index <= viewModel.editedPriority
                                ? Theme.Colors.xp
                                : Theme.CelestialColors.starDim
                        )
                        .symbolEffect(.bounce, value: viewModel.editedPriority == index)
                }
                .buttonStyle(.plain)
            }

            Text("Priority")
                .dynamicTypeFont(base: 12, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starDim)
                .padding(.leading, 4)
        }
    }

    // MARK: - Scheduled Time Badge

    private func scheduledTimeBadge(_ date: Date) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .dynamicTypeFont(base: 11, weight: .medium)

            Text(formatScheduledTime(date))
                .dynamicTypeFont(base: 12, weight: .medium)
        }
        .foregroundStyle(Theme.TaskCardColors.schedule)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Theme.TaskCardColors.schedule.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.TaskCardColors.schedule.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func formatScheduledTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today,' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow,' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        CelestialHeaderSection(
            viewModel: {
                let task = TaskItem(title: "Complete project proposal for client meeting")
                task.starRating = 3
                task.taskType = .create
                task.duration = 45
                task.scheduledTime = Date().addingTimeInterval(3600)
                return CelestialTaskCardViewModel(task: task)
            }()
        )
        .padding()
    }
}
