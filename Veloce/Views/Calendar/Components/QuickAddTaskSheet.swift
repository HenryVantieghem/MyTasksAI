//
//  QuickAddTaskSheet.swift
//  Veloce
//
//  Quick task creation sheet with iOS 26 design
//  Minimal, focused input with duration selector
//

import SwiftUI

// MARK: - Quick Add Task Sheet

struct QuickAddTaskSheet: View {
    let selectedTime: Date
    let onAdd: (String, Date, Int) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var taskTitle = ""
    @State private var selectedDuration = 30
    @State private var adjustedTime: Date

    @FocusState private var isTitleFocused: Bool

    private let durations = [15, 30, 45, 60, 90, 120]

    init(selectedTime: Date, onAdd: @escaping (String, Date, Int) -> Void, onCancel: @escaping () -> Void) {
        self.selectedTime = selectedTime
        self.onAdd = onAdd
        self.onCancel = onCancel
        self._adjustedTime = State(initialValue: selectedTime)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Time display
                timeHeader

                // Task title input
                taskTitleInput

                // Duration selector
                durationSelector

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
    }

    // MARK: - Time Header

    private var timeHeader: some View {
        VStack(spacing: 8) {
            Text(adjustedTime.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.secondary)

            DatePicker(
                "",
                selection: $adjustedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(height: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Task Title Input

    private var taskTitleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task")
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(.secondary)

            TextField("What do you need to do?", text: $taskTitle)
                .dynamicTypeFont(base: 17)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($isTitleFocused)
                .submitLabel(.done)
                .onSubmit {
                    if !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        addTask()
                    }
                }
        }
    }

    // MARK: - Duration Selector

    private var durationSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(durations, id: \.self) { duration in
                    durationButton(duration)
                }
            }
        }
    }

    private func durationButton(_ duration: Int) -> some View {
        let isSelected = selectedDuration == duration

        return Button {
            HapticsService.shared.selectionFeedback()
            selectedDuration = duration
        } label: {
            Text(formatDuration(duration))
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                )
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) hour"
        }
    }

    // MARK: - Actions

    private func addTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        HapticsService.shared.success()
        onAdd(trimmedTitle, adjustedTime, selectedDuration)
        dismiss()
    }
}

// MARK: - Task Detail Sheet (Simplified)

struct CalendarTaskDetailSheet: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onDuplicate: () -> Void
    let onSnooze: (Date) -> Void
    let onDelete: () -> Void
    let onSchedule: (Date) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Task info section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .dynamicTypeFont(base: 20, weight: .semibold)

                        if let time = task.scheduledTime {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .dynamicTypeFont(base: 13)
                                Text(time.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                                    .dynamicTypeFont(base: 14)
                            }
                            .foregroundStyle(.secondary)
                        }

                        if let duration = task.estimatedMinutes ?? task.duration {
                            HStack(spacing: 6) {
                                Image(systemName: "hourglass")
                                    .dynamicTypeFont(base: 13)
                                Text("\(duration) minutes")
                                    .dynamicTypeFont(base: 14)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Actions section
                Section {
                    Button {
                        HapticsService.shared.success()
                        onComplete()
                        dismiss()
                    } label: {
                        Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete", systemImage: task.isCompleted ? "circle" : "checkmark.circle.fill")
                    }

                    Button {
                        onDuplicate()
                        dismiss()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                }

                // Reschedule section
                Section("Reschedule") {
                    Button {
                        // Snooze 1 hour
                        if let time = task.scheduledTime {
                            onSnooze(time.addingTimeInterval(3600))
                            dismiss()
                        }
                    } label: {
                        Label("In 1 Hour", systemImage: "clock.arrow.circlepath")
                    }

                    Button {
                        // Tomorrow same time
                        if let time = task.scheduledTime {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: time)!
                            onSnooze(tomorrow)
                            dismiss()
                        }
                    } label: {
                        Label("Tomorrow", systemImage: "sun.max")
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Quick Add") {
    QuickAddTaskSheet(
        selectedTime: Date(),
        onAdd: { _, _, _ in },
        onCancel: {}
    )
}
