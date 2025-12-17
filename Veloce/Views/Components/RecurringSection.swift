//
//  RecurringSection.swift
//  MyTasksAI
//
//  Recurring Options Section for Task Detail Sheet
//  Set task repeat frequency: Once, Daily, Weekly, Custom
//

import SwiftUI

// MARK: - Recurring Section
struct RecurringSection: View {
    @Bindable var task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "repeat")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.aiPurple)
                Text("Repeat")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            // Options
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(RecurringType.allCases, id: \.self) { type in
                    recurringButton(type: type)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .liquidGlass(cornerRadius: Theme.Radius.card)
    }

    // MARK: - Recurring Button
    private func recurringButton(type: RecurringType) -> some View {
        let isSelected = task.recurring == type

        return Button {
            task.setRecurring(type)
            HapticsService.shared.selectionFeedback()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                Text(type.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? AnyShapeStyle(Theme.Colors.aiPurple)
                    : AnyShapeStyle(Theme.Colors.glassBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        IridescentBackground()
        RecurringSection(task: TaskItem(title: "Test task"))
            .padding()
    }
}
