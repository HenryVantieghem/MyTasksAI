//
//  CelestialSchedulePickerSheet.swift
//  Veloce
//
//  Simple date/time picker sheet for scheduling tasks.
//

import SwiftUI

struct CelestialSchedulePickerSheet: View {
    @Binding var selectedDate: Date?
    let task: TaskItem

    @Environment(\.dismiss) private var dismiss
    @State private var pickerDate: Date

    init(selectedDate: Binding<Date?>, task: TaskItem) {
        self._selectedDate = selectedDate
        self.task = task
        self._pickerDate = State(initialValue: selectedDate.wrappedValue ?? Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                // Task title reference
                HStack {
                    Text("Schedule:")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.screenPadding)

                // Date picker
                DatePicker(
                    "Select Date & Time",
                    selection: $pickerDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(Theme.TaskCardColors.schedule)
                .padding(.horizontal, Theme.Spacing.screenPadding)

                Spacer()

                // Buttons
                VStack(spacing: Theme.Spacing.sm) {
                    // Set Schedule button
                    Button {
                        selectedDate = pickerDate
                        HapticsService.shared.softImpact()
                        dismiss()
                    } label: {
                        Text("Set Schedule")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Theme.TaskCardColors.schedule)
                            )
                    }
                    .buttonStyle(.plain)

                    // Clear button
                    if selectedDate != nil {
                        Button {
                            selectedDate = nil
                            HapticsService.shared.selectionFeedback()
                            dismiss()
                        } label: {
                            Text("Remove Schedule")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.Colors.destructive)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
                .padding(.bottom, Theme.Spacing.lg)
            }
            .navigationTitle("Schedule Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CelestialSchedulePickerSheet(
        selectedDate: .constant(Date()),
        task: TaskItem(title: "Complete project proposal")
    )
}
