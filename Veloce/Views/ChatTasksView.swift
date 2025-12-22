//
//  ChatTasksView.swift
//  Veloce
//
//  Chat Tasks View
//  Claude Code-inspired chat-style task interface
//

import SwiftUI

// MARK: - Chat Tasks View

struct ChatTasksView: View {
    @Bindable var viewModel: ChatTasksViewModel

    // Sheet state
    @State private var selectedTask: TaskItem?
    @State private var showGeniusSheet = false
    @State private var showTaskDetailSheet = false

    // Animation state
    @State private var showConfetti = false
    @State private var showAICreationAnimation = false
    @State private var pointsAnimations: [PointsAnimationState] = []
    @State private var lastCompletedPosition: CGPoint = .zero

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background - Void design system
            VoidBackground.tasks

            // Main content
            VStack(spacing: 0) {
                // Task feed or empty state
                if viewModel.sortedTasks.isEmpty && viewModel.recentlyCompleted.isEmpty {
                    EmptyTasksView {
                        // Input bar is now managed at container level
                        // User can tap the input bar directly
                    }
                    .padding(.top, Theme.Spacing.universalHeaderHeight)
                } else {
                    taskFeed
                }
            }

            // Confetti overlay
            if showConfetti {
                ConfettiBurst(particleCount: 60)
                    .ignoresSafeArea()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showConfetti = false
                        }
                    }
            }

            // Points animations
            PointsAnimationContainer(animations: $pointsAnimations)

            // Genius Task Sheet overlay
            if showGeniusSheet, let task = selectedTask {
                GeniusTaskSheet(
                    task: task,
                    isPresented: $showGeniusSheet,
                    onEditTapped: {
                        showGeniusSheet = false
                        showTaskDetailSheet = true
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }

            // AI Creation Animation overlay
            if showAICreationAnimation {
                AITaskCreationAnimation {
                    showAICreationAnimation = false
                }
                .zIndex(2)
            }
        }
        .fullScreenCover(isPresented: $showTaskDetailSheet) {
            if let task = selectedTask {
                PremiumTaskDetailView(task: task, viewModel: viewModel)
            }
        }
    }

    // MARK: - Task Feed

    private var taskFeed: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    // Recently completed section
                    if !viewModel.recentlyCompleted.isEmpty {
                        completedSection
                    }

                    // Active tasks - Using TaskCardV2 with Energy Core and AI Whisper
                    ForEach(viewModel.sortedTasks) { task in
                        TaskCardV2(
                            task: task,
                            onTap: {
                                selectedTask = task
                                showGeniusSheet = true
                            },
                            onToggleComplete: {
                                completeTask(task)
                            }
                        )
                        .id(task.id)
                        .transition(.asymmetric(
                            insertion: .push(from: .bottom).combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }

                    // Bottom spacer for input bar
                    Spacer(minLength: 20)
                        .id("bottom")
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
                .padding(.top, Theme.Spacing.universalHeaderHeight)
            }
            .onChange(of: viewModel.sortedTasks.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Completed Section

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Recently Completed")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textTertiary)
                .padding(.horizontal, Theme.Spacing.sm)

            ForEach(viewModel.recentlyCompleted) { task in
                CompletedTaskRow(task: task) {
                    viewModel.uncompleteTask(task)
                }
            }
        }
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Actions

    private func completeTask(_ task: TaskItem) {
        // Get position for points animation - use a reasonable default center
        let screenCenter = CGPoint(x: 200, y: 400)

        // Complete and get points
        let points = viewModel.completeTask(task)

        // Show points animation
        let animation = PointsAnimationState(
            points: points,
            position: screenCenter,
            isBonus: points > DesignTokens.Gamification.taskComplete
        )
        pointsAnimations.append(animation)

        // Check for celebration triggers
        let gamification = GamificationService.shared
        if gamification.tasksCompletedToday == gamification.dailyGoal {
            // Daily goal reached!
            showConfetti = true
        }
    }
}

// MARK: - Completed Task Row

struct CompletedTaskRow: View {
    let task: TaskItem
    let onUncomplete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Completed checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.Colors.success)

            // Title
            Text(task.title)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textTertiary)
                .strikethrough(true, color: Theme.Colors.textTertiary)
                .lineLimit(1)

            Spacer()

            // Undo button
            Button {
                onUncomplete()
            } label: {
                Text("Undo")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
        )
    }
}

// MARK: - Chat Schedule Picker Sheet

struct ChatSchedulePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Date) -> Void

    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                DatePicker(
                    "Schedule",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(Theme.Colors.accent)

                Button {
                    onSelect(selectedDate)
                    dismiss()
                } label: {
                    Text("Set Schedule")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
            }
            .padding(Theme.Spacing.screenPadding)
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

// MARK: - Priority Picker Sheet

struct PriorityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(1...3, id: \.self) { priority in
                    Button {
                        HapticsService.shared.selectionFeedback()
                        onSelect(priority)
                        dismiss()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            // Stars
                            HStack(spacing: 4) {
                                ForEach(0..<priority, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Theme.Colors.xp)
                                }
                                ForEach(0..<(3 - priority), id: \.self) { _ in
                                    Image(systemName: "star")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                            }

                            Spacer()

                            // Label
                            Text(priorityLabel(priority))
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.md)
                                .fill(Theme.Colors.glassBackground.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.screenPadding)
            .navigationTitle("Set Priority")
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

    private func priorityLabel(_ priority: Int) -> String {
        switch priority {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "Medium"
        }
    }
}

// MARK: - Chat Task Detail Sheet

struct ChatTaskDetailSheet: View {
    let task: TaskItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Title
                    Text(task.title)
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    // Metadata
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        if task.starRating > 0 {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Theme.Colors.xp)
                                Text("Priority: \(task.starRating)/3")
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }

                        if let scheduled = task.scheduledTime {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(Theme.Colors.aiBlue)
                                Text("Scheduled: \(scheduled.formatted(date: .abbreviated, time: .shortened))")
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }

                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundStyle(Theme.Colors.textTertiary)
                            Text("Created: \(task.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(Theme.Spacing.screenPadding)
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatTasksView(viewModel: ChatTasksViewModel())
    }
}
