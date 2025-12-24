//
//  CelestialScheduleSection.swift
//  Veloce
//
//  Schedule section with smart suggestions and manual scheduling.
//  Note: Recurring configuration is now a separate dedicated section.
//

import SwiftUI

struct CelestialScheduleSection: View {
    @Bindable var viewModel: CelestialTaskCardViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Smart Schedule Suggestions
            smartScheduleSuggestions

            // Manual Schedule Picker
            manualSchedulePicker
        }
        .padding(Theme.Spacing.md)
        .celestialGlassCard(accent: Theme.TaskCardColors.schedule)
    }

    // MARK: - Smart Schedule Suggestions

    private var smartScheduleSuggestions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.TaskCardColors.schedule)

                Text("Smart Suggestions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                if viewModel.isLoadingSchedule {
                    ProgressView()
                        .tint(Theme.TaskCardColors.schedule)
                        .scaleEffect(0.8)
                }
            }

            if viewModel.scheduleSuggestions.isEmpty {
                Text("Loading suggestions...")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.scheduleSuggestions) { suggestion in
                        scheduleSuggestionRow(suggestion)
                    }
                }
            }
        }
    }

    private func scheduleSuggestionRow(_ suggestion: GeniusScheduleSuggestion) -> some View {
        let isSelected = viewModel.editedScheduledTime == suggestion.date

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.editedScheduledTime = suggestion.date
                viewModel.hasUnsavedChanges = true
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                // Rank indicator
                rankIndicator(suggestion.rank)

                VStack(alignment: .leading, spacing: 2) {
                    Text(formatSuggestionDate(suggestion.date))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)

                    Text(suggestion.reason)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.TaskCardColors.schedule)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected
                          ? Theme.TaskCardColors.schedule.opacity(0.15)
                          : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isSelected
                                    ? Theme.TaskCardColors.schedule.opacity(0.3)
                                    : .white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func rankIndicator(_ rank: ScheduleRank) -> some View {
        let (color, icon): (Color, String) = {
            switch rank {
            case .best: return (Theme.Colors.success, "star.fill")
            case .good: return (Theme.TaskCardColors.schedule, "hand.thumbsup.fill")
            case .okay: return (Theme.CelestialColors.starDim, "arrow.right.circle")
            }
        }()

        return Image(systemName: icon)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(
                SwiftUI.Circle()
                    .fill(color.opacity(0.15))
            )
    }

    // MARK: - Manual Schedule Picker

    private var manualSchedulePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.TaskCardColors.schedule)

                Text("Pick Your Own Time")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()
            }

            // Current selection or picker button
            Button {
                viewModel.showSchedulePicker = true
            } label: {
                HStack {
                    if let scheduled = viewModel.editedScheduledTime {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatFullDate(scheduled))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)

                            Text(formatTime(scheduled))
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.TaskCardColors.schedule)
                        }
                    } else {
                        Text("Not scheduled")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .padding(Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.05))
                )
            }
            .buttonStyle(.plain)

            // Clear button if scheduled
            if viewModel.editedScheduledTime != nil {
                Button {
                    withAnimation {
                        viewModel.editedScheduledTime = nil
                        viewModel.hasUnsavedChanges = true
                    }
                    HapticsService.shared.selectionFeedback()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 12))
                        Text("Clear schedule")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatSuggestionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else {
            formatter.dateFormat = "EEEE 'at' h:mm a"
        }

        return formatter.string(from: date)
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            CelestialScheduleSection(
                viewModel: {
                    let task = TaskItem(title: "Complete project proposal")
                    task.starRating = 3
                    let vm = CelestialTaskCardViewModel(task: task)
                    vm.editedScheduledTime = Date().addingTimeInterval(3600 * 3)
                    return vm
                }()
            )
            .padding()
        }
    }
}
