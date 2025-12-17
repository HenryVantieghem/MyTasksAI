//
//  SubTaskBreakdownCard.swift
//  Veloce
//
//  Claude Code-style task breakdown with progress tracking
//  AI generates actionable sub-tasks for systematic completion
//

import SwiftUI

struct SubTaskBreakdownCard: View {
    @Binding var subTasks: [SubTask]
    let taskTitle: String
    let onSubTaskStatusChanged: (SubTask) -> Void
    let onRefresh: () -> Void

    @State private var isLoading: Bool = false
    @State private var appeared: Bool = false
    @State private var expandedSubTaskId: UUID?

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
            } else if subTasks.isEmpty {
                emptyStateView
            } else {
                subTaskListView
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
                .font(.system(size: 18))

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
                .font(.system(size: 24))
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
                SubTaskRow(
                    subTask: subTask,
                    isExpanded: expandedSubTaskId == subTask.id,
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
                    }
                )
            }
        }
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

// MARK: - Sub-Task Row

struct SubTaskRow: View {
    let subTask: SubTask
    let isExpanded: Bool
    let onToggleStatus: (SubTask) -> Void
    let onToggleExpand: () -> Void

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

                // Order number and title
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

                    // Time estimate
                    if let minutes = subTask.estimatedMinutes {
                        Text(minutes.formattedDuration)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.tertiaryText)
                    }
                }

                Spacer()

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
    }

    private var statusIcon: some View {
        Group {
            switch subTask.status {
            case .pending:
                Circle()
                    .strokeBorder(Theme.Colors.tertiaryText, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            case .inProgress:
                ZStack {
                    Circle()
                        .strokeBorder(Theme.Colors.accent, lineWidth: 1.5)
                    Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 20, height: 20)
            case .completed:
                ZStack {
                    Circle()
                        .fill(Theme.Colors.success)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
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
                .font(.system(size: 11))
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
            onRefresh: { }
        )
        .padding()
    }
    .background(Theme.Colors.background)
}
