//
//  SmartScheduleModule.swift
//  MyTasksAI
//
//  Smart scheduling with peak hours and suggestions
//  BEST/GOOD/OKAY quality indicators
//  Calendar integration
//

import SwiftUI

// MARK: - Smart Schedule Module

struct SmartScheduleModule: View {
    let task: TaskItem
    @Bindable var viewModel: GeniusSheetViewModel
    let onAddToCalendar: () -> Void

    private let accentColor = Theme.TaskCardColors.schedule

    var body: some View {
        ModuleCard(
            title: "SMART SCHEDULE",
            icon: "calendar.badge.clock",
            accentColor: accentColor
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Peak hours indicator
                peakHoursView

                // Schedule suggestions
                if viewModel.scheduleSuggestions.isEmpty {
                    defaultSuggestions
                } else {
                    ForEach(viewModel.scheduleSuggestions) { suggestion in
                        suggestionRow(suggestion)
                    }
                }

                // Add to calendar button
                addToCalendarButton
            }
        }
    }

    // MARK: - Peak Hours View

    private var peakHoursView: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(accentColor)

            Text("Your best \(task.taskType.displayName.uppercased()) time: ")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))

            Text(viewModel.userPeakHours)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accentColor)
        }
    }

    // MARK: - Default Suggestions

    private var defaultSuggestions: some View {
        VStack(spacing: Theme.Spacing.sm) {
            suggestionRow(GeniusScheduleSuggestion(
                rank: .best,
                date: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date(),
                reason: "You have a clear 2hr block, peak energy"
            ))

            suggestionRow(GeniusScheduleSuggestion(
                rank: .good,
                date: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()) ?? Date(),
                reason: "Your typical peak \(task.taskType.displayName) time"
            ))
        }
    }

    // MARK: - Suggestion Row

    private func suggestionRow(_ suggestion: GeniusScheduleSuggestion) -> some View {
        Button {
            // Schedule task
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                // Quality indicator
                Text(suggestion.rank.emoji)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(suggestion.rank.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(suggestion.rank.color)

                        Text(suggestion.formattedTime)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text(suggestion.reason)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(accentColor.opacity(0.6))
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(suggestion.rank.color.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(suggestion.rank.color.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add to Calendar Button

    private var addToCalendarButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onAddToCalendar()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.plus")
                Text("Add to Calendar")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accentColor.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        SmartScheduleModule(
            task: {
                let task = TaskItem(title: "Write quarterly report")
                task.taskTypeRaw = TaskType.create.rawValue
                return task
            }(),
            viewModel: GeniusSheetViewModel(),
            onAddToCalendar: { print("Add to calendar") }
        )
        .padding()
    }
}
