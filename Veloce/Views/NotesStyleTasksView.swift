//
//  NotesStyleTasksView.swift
//  MyTasksAI
//
//  Apple Notes-style open sheet for tasks
//  Minimal, text-first design with tap-to-expand interaction
//
//  Inspired by:
//  - Apple Notes (clean, free-form, collapsible)
//  - Claude/Anthropic (warm colors, friendly)
//  - Tiimo (gentle, non-punishing)
//  - Things 3 (intentional minimalism)
//

import SwiftUI
import SwiftData

// MARK: - Notes Style Tasks View

/// Apple Notes-inspired task sheet with line-by-line interaction
struct NotesStyleTasksView: View {
    @Bindable var viewModel: TasksViewModel
    @State private var expandedTaskId: UUID?
    @State private var newTaskText = ""
    @State private var isAddingTask = false
    @FocusState private var isNewTaskFocused: Bool
    @FocusState private var focusedTaskId: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Cream white background (Claude-inspired)
            NotesBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                notesHeader

                // Task lines
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Existing tasks
                            ForEach(viewModel.filteredTasks) { task in
                                TaskLineView(
                                    task: task,
                                    viewModel: viewModel,
                                    isExpanded: expandedTaskId == task.id,
                                    onTap: {
                                        toggleExpansion(for: task)
                                    },
                                    onComplete: {
                                        toggleCompletion(for: task)
                                    }
                                )
                                .id(task.id)
                            }

                            // New task input line
                            newTaskLine
                                .id("newTask")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 120) // Space for keyboard
                    }
                    .onChange(of: isNewTaskFocused) { _, focused in
                        if focused {
                            withAnimation {
                                proxy.scrollTo("newTask", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .animation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.85), value: expandedTaskId)
    }

    // MARK: - Notes Header

    private var notesHeader: some View {
        HStack(spacing: 16) {
            // Date indicator (like Notes)
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(NotesTheme.Colors.textPrimary)

                Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(NotesTheme.Colors.textSecondary)
            }

            Spacer()

            // Stats pill
            if viewModel.todayCompleted > 0 || !viewModel.filteredTasks.isEmpty {
                StatsPill(
                    completed: viewModel.todayCompleted,
                    total: viewModel.filteredTasks.count
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - New Task Line

    private var newTaskLine: some View {
        HStack(spacing: 12) {
            // Empty checkbox
            Circle()
                .stroke(NotesTheme.Colors.textTertiary.opacity(0.4), lineWidth: 1.5)
                .frame(width: 22, height: 22)

            // Text input
            TextField("Add a task...", text: $newTaskText)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(NotesTheme.Colors.textPrimary)
                .focused($isNewTaskFocused)
                .submitLabel(.done)
                .onSubmit {
                    createTask()
                }

            Spacer()
        }
        .padding(.vertical, 14)
        .opacity(0.6)
    }

    // MARK: - Actions

    private func toggleExpansion(for task: TaskItem) {
        HapticsService.shared.selectionFeedback()

        if expandedTaskId == task.id {
            expandedTaskId = nil
        } else {
            expandedTaskId = task.id
        }
    }

    private func toggleCompletion(for task: TaskItem) {
        HapticsService.shared.impact(.medium)
        viewModel.toggleCompletion(task)
    }

    private func createTask() {
        guard !newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        viewModel.createTask(title: newTaskText.trimmingCharacters(in: .whitespacesAndNewlines))
        newTaskText = ""
        HapticsService.shared.impact(.light)
    }
}

// MARK: - Task Line View

/// Individual task line that can expand to show detail card
struct TaskLineView: View {
    let task: TaskItem
    @Bindable var viewModel: TasksViewModel
    let isExpanded: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var showDetailSheet = false
    @State private var checkScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Main line content
            HStack(spacing: 12) {
                // Checkbox
                Button {
                    animateCheckbox()
                    onComplete()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(
                                task.isCompleted ? NotesTheme.Colors.success : NotesTheme.Colors.textTertiary.opacity(0.4),
                                lineWidth: 1.5
                            )
                            .frame(width: 22, height: 22)

                        if task.isCompleted {
                            Circle()
                                .fill(NotesTheme.Colors.success)
                                .frame(width: 18, height: 18)

                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .scaleEffect(checkScale)
                }
                .buttonStyle(.plain)

                // Task title
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(task.isCompleted ? NotesTheme.Colors.textTertiary : NotesTheme.Colors.textPrimary)
                        .strikethrough(task.isCompleted, color: NotesTheme.Colors.textTertiary)
                        .lineLimit(isExpanded ? nil : 2)

                    // Metadata (only when not expanded)
                    if !isExpanded {
                        taskMetadata
                    }
                }

                Spacer()

                // Metadata on right (like calorie app reference)
                if !isExpanded, let minutes = task.estimatedMinutes {
                    Text("\(minutes)m")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(NotesTheme.Colors.textSecondary)
                }

                // Expand indicator
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NotesTheme.Colors.textTertiary.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 0 : 0))
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // Expanded content - inline detail card
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                    ))
            }

            // Divider
            if !isExpanded {
                Divider()
                    .padding(.leading, 34)
            }
        }
    }

    // MARK: - Task Metadata

    private var taskMetadata: some View {
        HStack(spacing: 8) {
            // Star rating
            if task.starRating > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<task.starRating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                    }
                }
                .foregroundStyle(NotesTheme.Colors.gold)
            }

            // AI indicator
            if task.aiProcessedAt != nil {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundStyle(NotesTheme.Colors.aiPurple)
            }

            // Scheduled time
            if let scheduled = task.scheduledTime {
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(scheduled, format: .dateTime.hour().minute())
                        .font(.system(.caption2, design: .rounded))
                }
                .foregroundStyle(NotesTheme.Colors.textTertiary)
            }
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 12) {
            // AI Insight Card (compact)
            if let advice = task.aiAdvice {
                NotesAIInsightCard(
                    advice: advice,
                    estimatedMinutes: task.estimatedMinutes,
                    priority: task.aiPriority
                )
            }

            // Quick Actions Row
            NotesQuickActions(
                onSchedule: { /* Show scheduler */ },
                onAIRefresh: { viewModel.reprocessAI(for: task) },
                onViewMore: { showDetailSheet = true }
            )

            // Metadata Summary
            NotesMetadataRow(task: task)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 34) // Align with text
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NotesTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.bottom, 12)
        .sheet(isPresented: $showDetailSheet) {
            TaskDetailSheet(task: task, viewModel: viewModel)
        }
    }

    // MARK: - Animations

    private func animateCheckbox() {
        guard !reduceMotion else { return }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            checkScale = 1.2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                checkScale = 1.0
            }
        }
    }
}

// MARK: - Notes AI Insight Card (Compact)

struct NotesAIInsightCard: View {
    let advice: String
    let estimatedMinutes: Int?
    let priority: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NotesTheme.Colors.aiPurple)

                Text("AI Insight")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(NotesTheme.Colors.textSecondary)

                Spacer()
            }

            // Advice text
            Text(advice)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(NotesTheme.Colors.textPrimary)
                .lineLimit(3)

            // Pills
            HStack(spacing: 8) {
                if let minutes = estimatedMinutes {
                    MetadataPillSmall(icon: "clock", text: "\(minutes)m", color: NotesTheme.Colors.aiBlue)
                }

                if let priority = priority {
                    MetadataPillSmall(
                        icon: priorityIcon(for: priority),
                        text: priority.capitalized,
                        color: priorityColor(for: priority)
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(NotesTheme.Colors.aiBackground)
        )
    }

    private func priorityIcon(for priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "exclamationmark.triangle.fill"
        case "medium": return "equal.circle.fill"
        default: return "arrow.down.circle.fill"
        }
    }

    private func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return NotesTheme.Colors.error
        case "medium": return NotesTheme.Colors.warning
        default: return NotesTheme.Colors.success
        }
    }
}

// MARK: - Notes Quick Actions

struct NotesQuickActions: View {
    let onSchedule: () -> Void
    let onAIRefresh: () -> Void
    let onViewMore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "calendar", label: "Schedule", action: onSchedule)
            QuickActionButton(icon: "arrow.clockwise", label: "Re-analyze", action: onAIRefresh)
            QuickActionButton(icon: "ellipsis", label: "More", action: onViewMore)

            Spacer()
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(.caption, design: .rounded))
            }
            .foregroundStyle(NotesTheme.Colors.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(NotesTheme.Colors.primary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notes Metadata Row

struct NotesMetadataRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 16) {
            if task.starRating > 0 {
                Label {
                    Text("\(task.starRating) Priority")
                } icon: {
                    HStack(spacing: 1) {
                        ForEach(0..<task.starRating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                        }
                    }
                    .foregroundStyle(NotesTheme.Colors.gold)
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(NotesTheme.Colors.textSecondary)
            }

            if let scheduled = task.scheduledTime {
                Label {
                    Text(scheduled, format: .dateTime.hour().minute())
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(NotesTheme.Colors.textSecondary)
            }

            Spacer()

            Text("Created \(task.createdAt, format: .relative(presentation: .named))")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(NotesTheme.Colors.textTertiary)
        }
    }
}

// MARK: - Metadata Pill Small

struct MetadataPillSmall: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(.caption2, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Stats Pill

struct StatsPill: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(NotesTheme.Colors.success)

            Text("\(completed)/\(total)")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(NotesTheme.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Notes Background

struct NotesBackground: View {
    var body: some View {
        NotesTheme.Colors.background
            .overlay(
                // Subtle paper texture
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .clear,
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

// MARK: - Notes Theme (Uses Theme.Colors.Claude)

enum NotesTheme {
    enum Colors {
        // Claude-inspired warm palette (aliases to Theme.Colors.Claude)
        static let primary = Theme.Colors.Claude.primary
        static let background = Theme.Colors.Claude.background
        static let cardBackground = Theme.Colors.Claude.cardBackground

        // Text (aliases to Theme.Colors.Claude)
        static let textPrimary = Theme.Colors.Claude.textPrimary
        static let textSecondary = Theme.Colors.Claude.textSecondary
        static let textTertiary = Theme.Colors.Claude.textTertiary

        // Semantic (from Theme.Colors)
        static let success = Theme.Colors.success
        static let warning = Theme.Colors.warning
        static let error = Theme.Colors.error
        static let gold = Theme.Colors.gold

        // AI (from Theme.Colors)
        static let aiPurple = Theme.Colors.aiPurple
        static let aiBlue = Theme.Colors.aiBlue
        static let aiBackground = Color(red: 0.96, green: 0.94, blue: 1.0)
    }
}

// MARK: - Preview

#Preview {
    NotesStyleTasksView(viewModel: TasksViewModel())
}
