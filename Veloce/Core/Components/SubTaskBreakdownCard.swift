//
//  SubTaskBreakdownCard.swift
//  Veloce
//
//  Claude Code-style task breakdown with progress tracking
//  AI generates actionable sub-tasks for systematic completion
//  Manual add/edit/delete/reorder support
//

import SwiftUI

struct SubTaskBreakdownCard: View {
    @Binding var subTasks: [SubTask]
    let taskTitle: String
    let onSubTaskStatusChanged: (SubTask) -> Void
    let onSubTaskAdded: (String) -> Void
    let onSubTaskDeleted: (SubTask) -> Void
    let onSubTaskUpdated: (SubTask) -> Void
    let onSubTasksReordered: ([SubTask]) -> Void
    let onRefresh: () -> Void

    @State private var isLoading: Bool = false
    @State private var appeared: Bool = false
    @State private var expandedSubTaskId: UUID?
    @State private var isAddingSubTask: Bool = false
    @State private var newSubTaskTitle: String = ""
    @State private var editingSubTaskId: UUID?
    @State private var editingSubTaskTitle: String = ""
    @FocusState private var isNewSubTaskFocused: Bool
    @FocusState private var isEditingFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header with progress
            headerView

            // AI reasoning summary
            if let firstReasoning = subTasks.first?.aiReasoning, !firstReasoning.isEmpty {
                reasoningSummaryView(firstReasoning)
            }

            // Progress bar
            if !subTasks.isEmpty {
                progressBarView
            }

            // Sub-task list
            if isLoading {
                loadingView
            } else if subTasks.isEmpty && !isAddingSubTask {
                emptyStateView
            } else {
                subTaskListView
            }

            // Add subtask section
            if isAddingSubTask {
                addSubTaskInputView
            } else {
                addSubTaskButton
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.glassBorder.opacity(0.2))
                }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "list.bullet.clipboard.fill")
                .foregroundStyle(Theme.Colors.accent)
                .dynamicTypeFont(base: 18)

            Text("Task Breakdown")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.primaryText)

            Spacer()

            // Refresh button
            Button {
                refreshSubTasks()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.5 : 1)
        }
    }

    // MARK: - Reasoning Summary

    private func reasoningSummaryView(_ reasoning: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "brain.head.profile")
                .font(.caption)
                .foregroundStyle(Theme.Colors.aiPurple.opacity(0.7))

            Text(reasoning)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
                .lineLimit(2)
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colors.aiPurple.opacity(0.05))
        }
    }

    // MARK: - Progress Bar

    private var progressBarView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text("Progress:")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)

                Spacer()

                Text(subTasks.progressDisplay)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.accent)

                if let remaining = subTasks.formattedRemainingTime {
                    Text("• \(remaining) left")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.tertiaryText)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.glassBackground.opacity(0.5))
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.accent, Theme.Colors.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * subTasks.progress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: subTasks.progress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(0..<3, id: \.self) { index in
                loadingSkeletonRow
                    .opacity(1 - Double(index) * 0.2)
            }
        }
    }

    private var loadingSkeletonRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
                .frame(width: 20, height: 20)

            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
                .frame(height: 16)

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
                .frame(width: 40, height: 12)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .shimmer()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .dynamicTypeFont(base: 24)
                .foregroundStyle(Theme.Colors.tertiaryText)

            Text("No breakdown yet")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)

            Button {
                refreshSubTasks()
            } label: {
                Text("Generate Breakdown")
                    .font(Theme.Typography.caption)
            }
            .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Sub-Task List

    private var subTaskListView: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(subTasks.sorted { $0.orderIndex < $1.orderIndex }) { subTask in
                BreakdownSubTaskRow(
                    subTask: subTask,
                    isExpanded: expandedSubTaskId == subTask.id,
                    isEditing: editingSubTaskId == subTask.id,
                    editingTitle: editingSubTaskId == subTask.id ? $editingSubTaskTitle : .constant(""),
                    isEditingFocused: $isEditingFocused,
                    onToggleStatus: { updatedSubTask in
                        onSubTaskStatusChanged(updatedSubTask)
                    },
                    onToggleExpand: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if expandedSubTaskId == subTask.id {
                                expandedSubTaskId = nil
                            } else {
                                expandedSubTaskId = subTask.id
                            }
                        }
                    },
                    onStartEdit: {
                        startEditing(subTask)
                    },
                    onCommitEdit: {
                        commitEdit(for: subTask)
                    },
                    onCancelEdit: {
                        cancelEdit()
                    },
                    onDelete: {
                        deleteSubTask(subTask)
                    },
                    onMoveUp: subTask.orderIndex > 1 ? {
                        moveSubTask(subTask, direction: .up)
                    } : nil,
                    onMoveDown: subTask.orderIndex < subTasks.count ? {
                        moveSubTask(subTask, direction: .down)
                    } : nil
                )
            }
        }
    }

    // MARK: - Add SubTask Button

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
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(Theme.Colors.accent)

                Text("Add subtask")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)

                Spacer()
            }
            .padding(Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Theme.Colors.glassBackground.opacity(0.2))
                    .strokeBorder(Theme.Colors.glassBorder.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add SubTask Input

    private var addSubTaskInputView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "circle")
                .dynamicTypeFont(base: 16)
                .foregroundStyle(Theme.Colors.tertiaryText)

            TextField("What's the step?", text: $newSubTaskTitle)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.primaryText)
                .focused($isNewSubTaskFocused)
                .onSubmit {
                    addNewSubTask()
                }
                .submitLabel(.done)

            // Save button
            Button {
                addNewSubTask()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .dynamicTypeFont(base: 22)
                    .foregroundStyle(newSubTaskTitle.isEmpty ? Theme.Colors.tertiaryText : Theme.Colors.success)
            }
            .disabled(newSubTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)

            // Cancel button
            Button {
                cancelAddSubTask()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .dynamicTypeFont(base: 22)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colors.accent.opacity(0.08))
                .strokeBorder(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - Add/Edit Actions

    private func addNewSubTask() {
        let title = newSubTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        onSubTaskAdded(title)
        HapticsService.shared.softImpact()

        // Reset
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

    private func startEditing(_ subTask: SubTask) {
        editingSubTaskId = subTask.id
        editingSubTaskTitle = subTask.title
        isEditingFocused = true
        HapticsService.shared.selectionFeedback()
    }

    private func commitEdit(for subTask: SubTask) {
        let trimmed = editingSubTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != subTask.title else {
            cancelEdit()
            return
        }

        var updated = subTask
        updated.title = trimmed
        onSubTaskUpdated(updated)
        HapticsService.shared.softImpact()
        cancelEdit()
    }

    private func cancelEdit() {
        editingSubTaskId = nil
        editingSubTaskTitle = ""
        isEditingFocused = false
    }

    private func deleteSubTask(_ subTask: SubTask) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            onSubTaskDeleted(subTask)
        }
        HapticsService.shared.softImpact()
    }

    private enum MoveDirection { case up, down }

    private func moveSubTask(_ subTask: SubTask, direction: MoveDirection) {
        var sorted = subTasks.sorted { $0.orderIndex < $1.orderIndex }
        guard let currentIndex = sorted.firstIndex(where: { $0.id == subTask.id }) else { return }

        let targetIndex = direction == .up ? currentIndex - 1 : currentIndex + 1
        guard targetIndex >= 0, targetIndex < sorted.count else { return }

        // Swap
        sorted.swapAt(currentIndex, targetIndex)

        // Update order indices
        for (index, var task) in sorted.enumerated() {
            task.orderIndex = index + 1
            sorted[index] = task
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            onSubTasksReordered(sorted)
        }
        HapticsService.shared.selectionFeedback()
    }

    // MARK: - Actions

    private func refreshSubTasks() {
        isLoading = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        onRefresh()

        // Simulate loading (in production, this is handled by the parent)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
}

// MARK: - Breakdown Sub-Task Row

fileprivate struct BreakdownSubTaskRow: View {
    let subTask: SubTask
    let isExpanded: Bool
    let isEditing: Bool
    @Binding var editingTitle: String
    var isEditingFocused: FocusState<Bool>.Binding
    let onToggleStatus: (SubTask) -> Void
    let onToggleExpand: () -> Void
    let onStartEdit: () -> Void
    let onCommitEdit: () -> Void
    let onCancelEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: Theme.Spacing.sm) {
                // Status button
                Button {
                    toggleStatus()
                } label: {
                    statusIcon
                }
                .buttonStyle(.plain)

                // Order number and title (or editing field)
                if isEditing {
                    editingView
                } else {
                    titleView
                }

                Spacer()

                // Actions
                if !isEditing {
                    rowActions
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.sm)

            // Expanded reasoning
            if isExpanded, let reasoning = subTask.aiReasoning {
                reasoningView(reasoning)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(backgroundForStatus)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .strokeBorder(borderForStatus, lineWidth: subTask.status == .inProgress ? 1.5 : 0.5)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button { onStartEdit() } label: {
                Label("Edit", systemImage: "pencil")
            }

            if let moveUp = onMoveUp {
                Button { moveUp() } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
            }

            if let moveDown = onMoveDown {
                Button { moveDown() } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
            }

            Divider()

            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Title View

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Theme.Spacing.xs) {
                Text("\(subTask.orderIndex).")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.Colors.tertiaryText)

                Text(subTask.title)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(subTask.status == .completed
                                     ? Theme.Colors.tertiaryText
                                     : Theme.Colors.primaryText)
                    .strikethrough(subTask.status == .completed)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onStartEdit()
            }

            // Time estimate
            if let minutes = subTask.estimatedMinutes {
                Text(minutes.formattedDuration)
                    .dynamicTypeFont(base: 10)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Editing View

    private var editingView: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text("\(subTask.orderIndex).")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.Colors.tertiaryText)

            TextField("Subtask title", text: $editingTitle)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.primaryText)
                .focused(isEditingFocused)
                .onSubmit { onCommitEdit() }
                .submitLabel(.done)

            Button { onCommitEdit() } label: {
                Image(systemName: "checkmark.circle.fill")
                    .dynamicTypeFont(base: 20)
                    .foregroundStyle(Theme.Colors.success)
            }

            Button { onCancelEdit() } label: {
                Image(systemName: "xmark.circle.fill")
                    .dynamicTypeFont(base: 20)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Row Actions

    private var rowActions: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Reorder buttons
            if onMoveUp != nil || onMoveDown != nil {
                HStack(spacing: 2) {
                    if let moveUp = onMoveUp {
                        Button { moveUp() } label: {
                            Image(systemName: "chevron.up")
                                .dynamicTypeFont(base: 10, weight: .semibold)
                                .foregroundStyle(Theme.Colors.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }

                    if let moveDown = onMoveDown {
                        Button { moveDown() } label: {
                            Image(systemName: "chevron.down")
                                .dynamicTypeFont(base: 10, weight: .semibold)
                                .foregroundStyle(Theme.Colors.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.glassBackground.opacity(0.3))
                )
            }

            // Expand indicator (if has reasoning)
            if subTask.aiReasoning != nil {
                Button {
                    onToggleExpand()
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "info.circle")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.aiPurple.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var statusIcon: some View {
        Group {
            switch subTask.status {
            case .pending:
                SwiftUI.Circle()
                    .strokeBorder(Theme.Colors.tertiaryText, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            case .inProgress:
                ZStack {
                    SwiftUI.Circle()
                        .strokeBorder(Theme.Colors.accent, lineWidth: 1.5)
                    SwiftUI.Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 20, height: 20)
            case .completed:
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.success)
                    Image(systemName: "checkmark")
                        .dynamicTypeFont(base: 10, weight: .bold)
                        .foregroundStyle(.white)
                }
                .frame(width: 20, height: 20)
            }
        }
    }

    private var backgroundForStatus: Color {
        switch subTask.status {
        case .pending:
            return Theme.Colors.glassBackground.opacity(0.2)
        case .inProgress:
            return Theme.Colors.accent.opacity(0.08)
        case .completed:
            return Theme.Colors.success.opacity(0.05)
        }
    }

    private var borderForStatus: Color {
        switch subTask.status {
        case .pending:
            return Theme.Colors.glassBorder.opacity(0.2)
        case .inProgress:
            return Theme.Colors.accent.opacity(0.3)
        case .completed:
            return Theme.Colors.success.opacity(0.2)
        }
    }

    private func reasoningView(_ reasoning: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            Image(systemName: "brain.head.profile")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.aiPurple.opacity(0.6))

            Text(reasoning)
                .dynamicTypeFont(base: 11)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.sm)
    }

    private func toggleStatus() {
        var updatedSubTask = subTask

        // Cycle through statuses
        switch subTask.status {
        case .pending:
            updatedSubTask.status = .inProgress
        case .inProgress:
            updatedSubTask.status = .completed
            updatedSubTask.completedAt = Date()
        case .completed:
            updatedSubTask.status = .pending
            updatedSubTask.completedAt = nil
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        onToggleStatus(updatedSubTask)
    }
}

// MARK: - Shimmer Effect

// Note: shimmer() modifier is defined in Core/Design/IridescentGlow.swift

// MARK: - Preview

#Preview {
    ScrollView {
        SubTaskBreakdownCard(
            subTasks: .constant([
                SubTask(title: "Gather Q3 data from dashboard", estimatedMinutes: 10, status: .completed, orderIndex: 1, aiReasoning: "Start with data to inform the rest of the report"),
                SubTask(title: "Create slide template", estimatedMinutes: 15, status: .completed, orderIndex: 2),
                SubTask(title: "Write executive summary", estimatedMinutes: 20, status: .inProgress, orderIndex: 3, aiReasoning: "Key message should be clear and concise"),
                SubTask(title: "Add charts and visualizations", estimatedMinutes: 25, status: .pending, orderIndex: 4),
                SubTask(title: "Review and polish", estimatedMinutes: 15, status: .pending, orderIndex: 5)
            ]),
            taskTitle: "Finish quarterly report",
            onSubTaskStatusChanged: { _ in },
            onSubTaskAdded: { print("Added: \($0)") },
            onSubTaskDeleted: { print("Deleted: \($0.title)") },
            onSubTaskUpdated: { print("Updated: \($0.title)") },
            onSubTasksReordered: { print("Reordered: \($0.map { $0.title })") },
            onRefresh: { }
        )
        .padding()
    }
    .background(Theme.Colors.background)
}
