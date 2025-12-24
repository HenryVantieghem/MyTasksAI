//
//  CelestialRecurringSectionWrapper.swift
//  Veloce
//
//  Wrapper for RecurringSection that integrates with CelestialTaskCard
//  Provides recurring task configuration (once, daily, weekdays, weekly, biweekly, monthly, custom)
//

import SwiftUI

// MARK: - Celestial Recurring Section Wrapper

struct CelestialRecurringSectionWrapper: View {
    @Bindable var viewModel: CelestialTaskCardViewModel

    var body: some View {
        RecurringSection(
            selectedType: $viewModel.editedRecurringType,
            customDays: $viewModel.editedRecurringDays,
            endDate: $viewModel.editedRecurringEndDate,
            onChanged: {
                viewModel.hasUnsavedChanges = true
                HapticsService.shared.selectionFeedback()
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                CelestialSectionDivider.recurring()

                CelestialRecurringSectionWrapper(
                    viewModel: {
                        let task = TaskItem(title: "Weekly team meeting")
                        task.setRecurringExtended(type: .weekly, customDays: nil, endDate: nil)
                        return CelestialTaskCardViewModel(task: task)
                    }()
                )
            }
            .padding()
        }
    }
}
