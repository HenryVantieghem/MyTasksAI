//
//  CelestialTaskDetailsSection.swift
//  Veloce
//
//  Task details section with context notes, sub-tasks, and duration picker.
//  Styled for the celestial dark theme.
//

import SwiftUI

struct CelestialTaskDetailsSection: View {
    @Bindable var viewModel: CelestialTaskCardViewModel
    @State private var isAddingSubTask = false
    @State private var newSubTaskTitle = ""
    @State private var expandedSubTaskId: UUID?
    @FocusState private var isNewSubTaskFocused: Bool
    @FocusState private var isContextFocused: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Context Notes
            contextNotesSection

            // AI Thought Process (if available)
            if !viewModel.aiThoughtProcessText.isEmpty {
                aiThoughtProcessSection
            }

            // Sub-Tasks
            subTasksSection

            // Duration Picker
            durationPickerSection
        }
        .padding(Theme.Spacing.md)
        .celestialGlassCard(accent: CelestialCardSection.taskDetails.accentColor)
    }

    // MARK: - Context Notes

    private var contextNotesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: "text.quote")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)

                Text("Context & Notes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()
            }

            // Text Editor
            ZStack(alignment: .topLeading) {
                if viewModel.editedContextNotes.isEmpty && !isContextFocused {
                    Text("Add context, notes, or links to help you complete this task...")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }

                TextEditor(text: $viewModel.editedContextNotes)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .focused($isContextFocused)
                    .frame(minHeight: 80, maxHeight: 150)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .onChange(of: viewModel.editedContextNotes) { _, newValue in
                        viewModel.markContextChanged(newValue)
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isContextFocused
                            ? Theme.Colors.accent.opacity(0.5)
                            : .white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - AI Thought Process

    private var aiThoughtProcessSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("AI Analysis")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }

            Text(viewModel.aiThoughtProcessText)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(4)
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.Colors.aiPurple.opacity(0.08))
        )
    }

    // MARK: - Sub-Tasks Section

    private var subTasksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header with progress
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)

                Text("Sub-Tasks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                if !viewModel.subTasks.isEmpty {
                    Text(viewModel.subTaskProgressString)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }

            // Progress bar
            if !viewModel.subTasks.isEmpty {
                progressBar
            }

            // Sub-task list
            if viewModel.isLoadingSubTasks {
                loadingState
            } else if viewModel.subTasks.isEmpty && !isAddingSubTask {
                emptyState
            } else {
                subTaskList
            }

            // Add button or input
            if isAddingSubTask {
                addSubTaskInput
            } else {
                addSubTaskButton
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.1))

                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accent,
                                Theme.Colors.success
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * viewModel.subTaskProgress)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.subTaskProgress)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: Theme.Spacing.sm) {
                    SwiftUI.Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 18, height: 18)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.1))
                        .frame(height: 14)

                    Spacer()
                }
                .opacity(1 - Double(index) * 0.2)
            }
        }
        .shimmer()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundStyle(Theme.CelestialColors.starDim)

            Text("No sub-tasks yet")
                .font(.system(size: 13))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
    }

    // MARK: - Sub-Task List

    private var subTaskList: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(viewModel.subTasks.sorted { $0.orderIndex < $1.orderIndex }) { subTask in
                CelestialSubTaskRow(
                    subTask: subTask,
                    isExpanded: expandedSubTaskId == subTask.id,
                    onToggle: {
                        viewModel.toggleSubTask(subTask)
                    },
                    onExpand: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            expandedSubTaskId = expandedSubTaskId == subTask.id ? nil : subTask.id
                        }
                    },
                    onDelete: {
                        viewModel.deleteSubTask(subTask)
                    },
                    onUpdateTitle: { newTitle in
                        viewModel.updateSubTaskTitle(subTask, newTitle: newTitle)
                    }
                )
            }
        }
    }

    // MARK: - Add Sub-Task Button

    private var addSubTaskButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAddingSubTask = true
                isNewSubTaskFocused = true
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.accent)

                Text("Add sub-task")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starDim)

                Spacer()
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.03))
                    .strokeBorder(.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Sub-Task Input

    private var addSubTaskInput: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "circle")
                .font(.system(size: 14))
                .foregroundStyle(Theme.CelestialColors.starDim)

            TextField("What's the step?", text: $newSubTaskTitle)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .focused($isNewSubTaskFocused)
                .onSubmit { addNewSubTask() }
                .submitLabel(.done)

            Button {
                addNewSubTask()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(newSubTaskTitle.isEmpty ? Theme.CelestialColors.starDim : Theme.Colors.success)
            }
            .disabled(newSubTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)

            Button {
                cancelAddSubTask()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.Colors.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Duration Picker Section

    private var durationPickerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.TaskCardColors.schedule)

                Text("Estimated Duration")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()
            }

            // Duration options
            HStack(spacing: Theme.Spacing.sm) {
                ForEach([15, 30, 45, 60, 90], id: \.self) { minutes in
                    durationChip(minutes)
                }
            }
        }
    }

    private func durationChip(_ minutes: Int) -> some View {
        let isSelected = viewModel.editedDuration == minutes

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    viewModel.editedDuration = nil
                } else {
                    viewModel.editedDuration = minutes
                }
                viewModel.hasUnsavedChanges = true
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            Text(formatDuration(minutes))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starDim)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected
                              ? Theme.TaskCardColors.schedule.opacity(0.3)
                              : .white.opacity(0.05))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isSelected
                                        ? Theme.TaskCardColors.schedule.opacity(0.5)
                                        : .white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func addNewSubTask() {
        let title = newSubTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        viewModel.addSubTask(title: title)
        HapticsService.shared.softImpact()

        newSubTaskTitle = ""
        isNewSubTaskFocused = true
    }

    private func cancelAddSubTask() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isAddingSubTask = false
            newSubTaskTitle = ""
            isNewSubTaskFocused = false
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Celestial Sub-Task Row

struct CelestialSubTaskRow: View {
    let subTask: SubTask
    let isExpanded: Bool
    let onToggle: () -> Void
    let onExpand: () -> Void
    let onDelete: () -> Void
    var onUpdateTitle: ((String) -> Void)?

    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: Theme.Spacing.sm) {
                // Status button
                Button(action: onToggle) {
                    statusIcon
                }
                .buttonStyle(.plain)

                // Order + Title (with inline editing)
                VStack(alignment: .leading, spacing: 2) {
                    if isEditing {
                        // Edit mode
                        HStack(spacing: 4) {
                            Text("\(subTask.orderIndex).")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Theme.CelestialColors.starDim)

                            TextField("Step title", text: $editedTitle)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .focused($isTitleFocused)
                                .submitLabel(.done)
                                .onSubmit { saveEdit() }
                        }
                    } else {
                        // Display mode - tap to edit
                        HStack(spacing: 4) {
                            Text("\(subTask.orderIndex).")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Theme.CelestialColors.starDim)

                            Text(subTask.title)
                                .font(.system(size: 14))
                                .foregroundStyle(subTask.status == .completed
                                                 ? Theme.CelestialColors.starDim
                                                 : .white)
                                .strikethrough(subTask.status == .completed)
                        }
                        .onTapGesture {
                            startEditing()
                        }
                    }

                    if let minutes = subTask.estimatedMinutes {
                        Text(formatDuration(minutes))
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }

                Spacer()

                // Action buttons
                if isEditing {
                    // Save/Cancel buttons
                    HStack(spacing: 8) {
                        Button {
                            saveEdit()
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.Colors.success)
                        }
                        .buttonStyle(.plain)

                        Button {
                            cancelEdit()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // Edit + Delete + Expand buttons
                    HStack(spacing: 8) {
                        // Edit button
                        Button {
                            startEditing()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.6))
                        }
                        .buttonStyle(.plain)

                        // Delete button
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.error.opacity(0.6))
                        }
                        .buttonStyle(.plain)

                        // Expand button (if has reasoning)
                        if subTask.aiReasoning != nil {
                            Button(action: onExpand) {
                                Image(systemName: isExpanded ? "chevron.up" : "info.circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.aiPurple.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.sm)

            // Expanded reasoning
            if isExpanded, let reasoning = subTask.aiReasoning {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.aiPurple.opacity(0.6))

                    Text(reasoning)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isEditing ? Theme.Colors.accent.opacity(0.1) : backgroundForStatus)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isEditing ? Theme.Colors.accent.opacity(0.5) : borderForStatus,
                    lineWidth: isEditing || subTask.status == .inProgress ? 1.5 : 0.5
                )
        )
    }

    // MARK: - Edit Helpers

    private func startEditing() {
        editedTitle = subTask.title
        isEditing = true
        isTitleFocused = true
        HapticsService.shared.selectionFeedback()
    }

    private func saveEdit() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed != subTask.title {
            onUpdateTitle?(trimmed)
            HapticsService.shared.softImpact()
        }
        isEditing = false
        isTitleFocused = false
    }

    private func cancelEdit() {
        isEditing = false
        isTitleFocused = false
        editedTitle = subTask.title
    }

    private var statusIcon: some View {
        Group {
            switch subTask.status {
            case .pending:
                SwiftUI.Circle()
                    .strokeBorder(Theme.CelestialColors.starDim, lineWidth: 1.5)
                    .frame(width: 18, height: 18)
            case .inProgress:
                ZStack {
                    SwiftUI.Circle()
                        .strokeBorder(Theme.Colors.accent, lineWidth: 1.5)
                    SwiftUI.Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 6, height: 6)
                }
                .frame(width: 18, height: 18)
            case .completed:
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.success)
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 18, height: 18)
            }
        }
    }

    private var backgroundForStatus: Color {
        switch subTask.status {
        case .pending:
            return .white.opacity(0.03)
        case .inProgress:
            return Theme.Colors.accent.opacity(0.08)
        case .completed:
            return Theme.Colors.success.opacity(0.05)
        }
    }

    private var borderForStatus: Color {
        switch subTask.status {
        case .pending:
            return .white.opacity(0.1)
        case .inProgress:
            return Theme.Colors.accent.opacity(0.3)
        case .completed:
            return Theme.Colors.success.opacity(0.2)
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            CelestialTaskDetailsSection(
                viewModel: {
                    let task = TaskItem(title: "Complete project proposal")
                    task.starRating = 3
                    let vm = CelestialTaskCardViewModel(task: task)
                    vm.editedContextNotes = "Need to include budget projections and timeline."
                    vm.aiThoughtProcessText = "This is a document creation task. Structured breakdown follows best practices: research -> outline -> content -> visuals -> review."
                    return vm
                }()
            )
            .padding()
        }
    }
}
