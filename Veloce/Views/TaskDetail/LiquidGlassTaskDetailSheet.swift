//
//  LiquidGlassTaskDetailSheet.swift
//  Veloce
//
//  Ultra-Premium Task Detail Sheet with Liquid Glass Design
//  iOS 26+ Liquid Glass styling with Perplexity AI integration
//

import SwiftUI

// MARK: - Liquid Glass Task Detail Sheet

struct LiquidGlassTaskDetailSheet: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onDuplicate: () -> Void
    let onSnooze: (Date) -> Void
    let onDelete: () -> Void
    let onSchedule: (Date) -> Void
    let onStartTimer: (TaskItem) -> Void
    let onDismiss: () -> Void

    // MARK: - State
    @State private var viewModel = TaskDetailViewModel()
    @State private var appeared = false
    @State private var showCopiedToast = false
    @State private var showSnoozeOptions = false
    @State private var showDeleteConfirm = false
    @State private var showMoreMenu = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Main content
            VStack(spacing: 0) {
                // Sticky Header
                headerBar

                // Scrollable content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Section 1: Task Title + Quick Actions
                        taskTitleSection
                            .sectionReveal(appeared: appeared, delay: 0)

                        // Section 2: Sub-tasks
                        subTasksSection
                            .sectionReveal(appeared: appeared, delay: 0.05)

                        // Section 3: AI Genius (Perplexity Powered)
                        aiGeniusSection
                            .sectionReveal(appeared: appeared, delay: 0.1)

                        // Section 4: Context & Notes
                        notesSection
                            .sectionReveal(appeared: appeared, delay: 0.15)

                        // Section 5: Focus Mode
                        focusModeSection
                            .sectionReveal(appeared: appeared, delay: 0.2)

                        // Section 6: Collaboration
                        collaborationSection
                            .sectionReveal(appeared: appeared, delay: 0.25)

                        // Bottom spacer for action bar
                        Spacer(minLength: 140)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }

            // Sticky Bottom Action Bar
            VStack {
                Spacer()
                actionBar
            }

            // Toast overlay
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            viewModel.setup(task: task)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            Task { await viewModel.loadAIInsights() }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()

            // Subtle gradient from task type
            RadialGradient(
                colors: [
                    task.taskType.color.opacity(0.12),
                    Theme.CelestialColors.voidDeep.opacity(0.5),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Ambient particles
            if !reduceMotion {
                AmbientParticleField()
                    .opacity(0.3)
            }
        }
    }

    // MARK: - Header Bar (Sticky)

    private var headerBar: some View {
        HStack {
            // Close button
            Button {
                HapticsService.shared.selectionFeedback()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            .glassEffect(.regular, in: Circle())

            Spacer()

            Text("Task Details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            // Menu button
            Menu {
                Button(action: { onDuplicate() }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Button(action: { showSnoozeOptions = true }) {
                    Label("Snooze", systemImage: "clock.arrow.circlepath")
                }
                Divider()
                Button(role: .destructive, action: { showDeleteConfirm = true }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            .glassEffect(.regular, in: Circle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        }
        .glassEffect(.regular, in: Rectangle())
        .confirmationDialog("Snooze Task", isPresented: $showSnoozeOptions) {
            Button("1 Hour") { snoozeFor(hours: 1) }
            Button("3 Hours") { snoozeFor(hours: 3) }
            Button("Tomorrow Morning") { snoozeTomorrowMorning() }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Task Title + Quick Actions

    private var taskTitleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title row with checkbox and edit
            HStack(alignment: .top, spacing: 14) {
                // Completion checkbox
                Button {
                    HapticsService.shared.successFeedback()
                    onComplete()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                task.isCompleted
                                    ? Theme.CelestialColors.auroraGreen
                                    : Theme.CelestialColors.starDim.opacity(0.4),
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.CelestialColors.auroraGreen)
                        }
                    }
                }

                // Editable title
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isEditingTitle {
                        TextField("Task title", text: $viewModel.editableTitle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .submitLabel(.done)
                            .onSubmit { viewModel.isEditingTitle = false }
                    } else {
                        Text(viewModel.editableTitle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .strikethrough(task.isCompleted, color: Theme.CelestialColors.starDim)
                    }
                }

                Spacer()

                // Edit button
                Button {
                    HapticsService.shared.selectionFeedback()
                    viewModel.isEditingTitle.toggle()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)
                        .frame(width: 32, height: 32)
                }
                .glassEffect(.regular, in: Circle())
            }

            // Divider
            Rectangle()
                .fill(Theme.CelestialColors.starDim.opacity(0.15))
                .frame(height: 1)

            // Quick action pills
            HStack(spacing: 10) {
                // Duration pill
                QuickActionPill(
                    icon: "clock",
                    text: viewModel.estimatedMinutes > 0 ? "\(viewModel.estimatedMinutes)m" : "Add",
                    color: Theme.CelestialColors.nebulaCore,
                    onTap: { viewModel.cycleDuration() }
                )

                // Schedule pill
                QuickActionPill(
                    icon: "calendar",
                    text: task.scheduledDateFormatted ?? "Today",
                    color: Theme.Colors.aiBlue,
                    onTap: { viewModel.showSchedulePicker = true }
                )

                // Recurring pill
                QuickActionPill(
                    icon: "arrow.triangle.2.circlepath",
                    text: task.recurring.displayName,
                    color: Theme.Colors.aiAmber,
                    onTap: { viewModel.cycleRecurring() }
                )
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Sub-tasks Section

    private var subTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with progress
            HStack {
                Text("Sub-tasks")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                // Progress indicator
                HStack(spacing: 8) {
                    Text(viewModel.subTasks.progressString)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    // Mini progress ring
                    ZStack {
                        Circle()
                            .stroke(Theme.CelestialColors.starDim.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)

                        Circle()
                            .trim(from: 0, to: viewModel.subTasks.progress)
                            .stroke(
                                Theme.CelestialColors.auroraGreen,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-90))
                    }
                }
            }

            // Sub-task list
            if viewModel.subTasks.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.indent")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.5))
                        Text("No sub-tasks yet")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.7))
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.subTasks.enumerated()), id: \.element.id) { index, subTask in
                        SubTaskRow(
                            subTask: subTask,
                            onToggle: { viewModel.toggleSubTask(subTask) },
                            onDelete: { viewModel.deleteSubTask(subTask) }
                        )
                    }
                }
            }

            // Add sub-task input
            if viewModel.isAddingSubTask {
                HStack(spacing: 12) {
                    TextField("Add a step...", text: $viewModel.newSubTaskTitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .submitLabel(.done)
                        .onSubmit {
                            viewModel.addSubTask()
                        }

                    Button {
                        viewModel.isAddingSubTask = false
                        viewModel.newSubTaskTitle = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Theme.CelestialColors.nebulaCore.opacity(0.3), lineWidth: 1)
                        }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    HapticsService.shared.selectionFeedback()
                    viewModel.isAddingSubTask = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add Step")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .glassEffect(.regular, in: Capsule())

                Button {
                    HapticsService.shared.impact()
                    Task { await viewModel.generateAISubTasks() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 12, weight: .bold))
                        Text("AI Generate")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .glassEffect(.regular, in: Capsule())
                .tint(Theme.CelestialColors.nebulaCore)
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - AI Genius Section (Perplexity Powered)

    private var aiGeniusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with sparkle
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("AI Insights")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                // Refresh button
                Button {
                    HapticsService.shared.impact()
                    Task { await viewModel.loadAIInsights() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)
                        .rotationEffect(.degrees(viewModel.isLoadingAI ? 360 : 0))
                        .animation(
                            viewModel.isLoadingAI ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: viewModel.isLoadingAI
                        )
                }
                .disabled(viewModel.isLoadingAI)
            }

            if viewModel.isLoadingAI {
                // Loading state
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Theme.CelestialColors.nebulaCore)
                            .frame(width: 8, height: 8)
                            .opacity(viewModel.isLoadingAI ? 1 : 0.3)
                    }
                    Text("Analyzing task...")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .padding(.vertical, 12)
            } else {
                // Insights content
                VStack(alignment: .leading, spacing: 16) {
                    // Helpful Resources
                    if !viewModel.aiResources.isEmpty {
                        AIInsightRow(
                            icon: "link",
                            title: "Helpful Resources",
                            color: Theme.Colors.aiBlue
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.aiResources.prefix(3)) { resource in
                                    Button {
                                        if let url = URL(string: resource.url) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: resource.type.icon)
                                                .font(.system(size: 12))
                                                .foregroundStyle(resource.type.color)

                                            Text(resource.title)
                                                .font(.system(size: 13))
                                                .foregroundStyle(Theme.Colors.aiBlue)
                                                .lineLimit(1)

                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Theme.CelestialColors.starDim)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // AI Assistant Prompt
                    AIInsightRow(
                        icon: "bubble.left.and.text.bubble.right",
                        title: "AI Assistant Prompt",
                        color: Theme.Colors.aiPurple
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(viewModel.aiPrompt)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(3)
                                .padding(12)
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.05))
                                }

                            Button {
                                UIPasteboard.general.string = viewModel.aiPrompt
                                HapticsService.shared.successFeedback()
                                showCopiedToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopiedToast = false
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                    Text("Copy")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                            }
                            .glassEffect(.regular, in: Capsule())
                            .tint(Theme.Colors.aiPurple)
                        }
                    }

                    // Time Estimate & Best Time
                    HStack(spacing: 12) {
                        // Estimated time
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.aiAmber)
                                Text("Estimated")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.CelestialColors.starDim)
                            }
                            Text(viewModel.aiEstimatedTime)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        }

                        // Best time
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                                Text("Best Time")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.CelestialColors.starDim)
                            }
                            Text(viewModel.aiBestTime)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassCard(accent: Theme.CelestialColors.nebulaCore)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("Notes")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()
            }

            TextEditor(text: $viewModel.editableNotes)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                }
                .overlay(alignment: .topLeading) {
                    if viewModel.editableNotes.isEmpty {
                        Text("Add notes to help focus...")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Focus Mode Section

    private var focusModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Mode")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            // Focus mode options
            HStack(spacing: 10) {
                FocusModeOption(
                    icon: "brain.head.profile",
                    title: "Deep Work",
                    isSelected: viewModel.selectedFocusMode == .deepWork,
                    onTap: { viewModel.selectedFocusMode = .deepWork }
                )

                FocusModeOption(
                    icon: "timer",
                    title: "Pomodoro",
                    isSelected: viewModel.selectedFocusMode == .pomodoro,
                    onTap: { viewModel.selectedFocusMode = .pomodoro }
                )

                FocusModeOption(
                    icon: "bolt.fill",
                    title: "Flow",
                    isSelected: viewModel.selectedFocusMode == .flowState,
                    onTap: { viewModel.selectedFocusMode = .flowState }
                )
            }

            // App blocking toggle
            HStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiAmber)

                Text("Block Apps")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)

                Spacer()

                Toggle("", isOn: $viewModel.appBlockingEnabled)
                    .labelsHidden()
                    .tint(Theme.Colors.aiAmber)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            }

            Text("Select apps to block during focus")
                .font(.system(size: 12))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Collaboration Section

    private var collaborationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Do it together")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Button {
                HapticsService.shared.selectionFeedback()
                // Open circles picker
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.Colors.aiBlue)

                    Text("Add from Circles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                }
            }

            Text("Tap to invite friends for accountability")
                .font(.system(size: 12))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Action Bar (Sticky Bottom)

    private var actionBar: some View {
        HStack(spacing: 16) {
            // Complete button (primary)
            Button {
                HapticsService.shared.successFeedback()
                onComplete()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text(task.isCompleted ? "Completed" : "Complete")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            .tint(Theme.CelestialColors.auroraGreen)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.CelestialColors.auroraGreen)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Start Focus button
            Button {
                HapticsService.shared.impact()
                onStartTimer(task)
                onDismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("Focus")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: Rectangle())
    }

    // MARK: - Toast

    private var copiedToast: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)

                Text("Copied to clipboard!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: Capsule())
            .padding(.top, 60)

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func snoozeFor(hours: Int) {
        let snoozeDate = Calendar.current.date(byAdding: .hour, value: hours, to: Date())!
        onSnooze(snoozeDate)
        HapticsService.shared.successFeedback()
    }

    private func snoozeTomorrowMorning() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let snoozeDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        onSnooze(snoozeDate)
        HapticsService.shared.successFeedback()
    }
}

// MARK: - View Model

@Observable
class TaskDetailViewModel {
    // Task state
    var editableTitle: String = ""
    var editableNotes: String = ""
    var estimatedMinutes: Int = 30
    var isEditingTitle: Bool = false
    var showSchedulePicker: Bool = false

    // Sub-tasks
    var subTasks: [SubTask] = []
    var isAddingSubTask: Bool = false
    var newSubTaskTitle: String = ""

    // AI State
    var isLoadingAI: Bool = false
    var aiResources: [TaskResource] = []
    var aiPrompt: String = "Help me complete this task efficiently..."
    var aiEstimatedTime: String = "15-20 min"
    var aiBestTime: String = "Tomorrow 9AM"

    // Focus Mode
    var selectedFocusMode: WorkMode = .deepWork
    var appBlockingEnabled: Bool = false

    // Task reference
    private var task: TaskItem?

    func setup(task: TaskItem) {
        self.task = task
        self.editableTitle = task.title
        self.editableNotes = task.contextNotes ?? ""
        self.estimatedMinutes = task.estimatedMinutes ?? 30
        self.appBlockingEnabled = task.enableAppBlocking
        // Load persisted subtasks
        self.subTasks = task.subtasks
    }

    func cycleDuration() {
        let durations = [15, 30, 45, 60, 90, 120]
        if let currentIndex = durations.firstIndex(of: estimatedMinutes) {
            estimatedMinutes = durations[(currentIndex + 1) % durations.count]
        } else {
            estimatedMinutes = 30
        }
        HapticsService.shared.selectionFeedback()
    }

    func cycleRecurring() {
        HapticsService.shared.selectionFeedback()
        // TODO: Cycle through recurring options
    }

    func addSubTask() {
        guard !newSubTaskTitle.isEmpty else { return }
        let newSubTask = SubTask(
            id: UUID(),
            title: newSubTaskTitle,
            status: .pending,
            orderIndex: subTasks.count,
            taskId: task?.id
        )
        subTasks.append(newSubTask)
        // Persist to task
        task?.subtasks = subTasks
        newSubTaskTitle = ""
        isAddingSubTask = false
        HapticsService.shared.selectionFeedback()
    }

    func toggleSubTask(_ subTask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == subTask.id }) {
            let newStatus: SubTaskStatus = subTask.status == .completed ? .pending : .completed
            subTasks[index].status = newStatus
            subTasks[index].completedAt = newStatus == .completed ? Date() : nil
        }
        // Persist to task
        task?.subtasks = subTasks
        HapticsService.shared.selectionFeedback()
    }

    func deleteSubTask(_ subTask: SubTask) {
        subTasks.removeAll { $0.id == subTask.id }
        // Persist to task
        task?.subtasks = subTasks
        HapticsService.shared.impact()
    }

    func loadAIInsights() async {
        guard let task = task else { return }

        isLoadingAI = true
        defer { isLoadingAI = false }

        // Generate AI prompt
        aiPrompt = generateAIPrompt(for: task)

        // Simulate AI insights (replace with actual Perplexity call)
        try? await Task.sleep(for: .seconds(1.5))

        // Set sample insights
        aiEstimatedTime = "\(estimatedMinutes)-\(estimatedMinutes + 10) min"
        aiBestTime = generateBestTime()

        // Load sample resources
        aiResources = [
            TaskResource(
                title: "Getting Started Guide",
                url: "https://example.com",
                source: "Documentation",
                type: .documentation
            ),
            TaskResource(
                title: "Quick Tutorial",
                url: "https://youtube.com",
                source: "YouTube",
                type: .youtube,
                duration: "8 min"
            )
        ]
    }

    func generateAISubTasks() async {
        HapticsService.shared.impact()

        // Add sample AI-generated sub-tasks
        let aiSubTasks = [
            SubTask(id: UUID(), title: "Review requirements", estimatedMinutes: 5, status: .pending, orderIndex: subTasks.count, aiReasoning: "AI generated", taskId: task?.id),
            SubTask(id: UUID(), title: "Break down into steps", estimatedMinutes: 10, status: .pending, orderIndex: subTasks.count + 1, aiReasoning: "AI generated", taskId: task?.id),
            SubTask(id: UUID(), title: "Execute main action", estimatedMinutes: 15, status: .pending, orderIndex: subTasks.count + 2, aiReasoning: "AI generated", taskId: task?.id)
        ]

        subTasks.append(contentsOf: aiSubTasks)
        // Persist to task
        task?.subtasks = subTasks
    }

    private func generateAIPrompt(for task: TaskItem) -> String {
        """
        Help me complete: "\(task.title)"

        Context: \(task.contextNotes ?? "None provided")

        Please provide:
        1. A step-by-step approach
        2. Potential challenges
        3. Time-saving tips
        """
    }

    private func generateBestTime() -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        if hour < 12 {
            return "Today 2PM"
        } else if hour < 17 {
            return "Tomorrow 9AM"
        } else {
            return "Tomorrow 10AM"
        }
    }
}

// MARK: - Supporting Views

struct QuickActionPill: View {
    let icon: String
    let text: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(text)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .glassEffect(.regular, in: Capsule())
    }
}

struct SubTaskRow: View {
    let subTask: SubTask
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            subTask.status == .completed
                                ? Theme.CelestialColors.auroraGreen
                                : Theme.CelestialColors.starDim.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if subTask.status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.CelestialColors.auroraGreen)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(subTask.title)
                    .font(.system(size: 14))
                    .foregroundStyle(subTask.status == .completed ? Theme.CelestialColors.starDim : .white)
                    .strikethrough(subTask.status == .completed, color: Theme.CelestialColors.starDim)

                if let minutes = subTask.estimatedMinutes {
                    Text("\(minutes)m")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }

            Spacer()

            if subTask.isAIGenerated {
                Image(systemName: "sparkle")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore.opacity(0.7))
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        }
    }
}

struct AIInsightRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            content()
        }
    }
}

struct FocusModeOption: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Theme.Colors.aiAmber : Theme.CelestialColors.starDim)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Theme.CelestialColors.starDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.aiAmber.opacity(0.2) : Color.white.opacity(0.03))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Theme.Colors.aiAmber.opacity(0.5) : Color.clear,
                                lineWidth: 1
                            )
                    }
            }
        }
    }
}

// AmbientParticleField is imported from Core/Components/Animations/AmbientParticleField.swift

private struct TaskDetailParticleData: Identifiable {
    let id: UUID
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
}

// MARK: - View Extensions

extension View {
    func glassCard(accent: Color? = nil) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.CelestialColors.voidDeep.opacity(0.5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        (accent ?? Theme.CelestialColors.starDim).opacity(0.25),
                                        (accent ?? Theme.CelestialColors.starDim).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    func sectionReveal(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 25)
            .scaleEffect(appeared ? 1 : 0.96)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8).delay(delay),
                value: appeared
            )
    }
}

// MARK: - Preview

#Preview {
    LiquidGlassTaskDetailSheet(
        task: {
            let task = TaskItem(title: "Send email to Nicholas")
            task.starRating = 3
            task.taskTypeRaw = TaskType.communicate.rawValue
            task.estimatedMinutes = 15
            task.aiAdvice = "Keep it concise and professional."
            return task
        }(),
        onComplete: {},
        onDuplicate: {},
        onSnooze: { _ in },
        onDelete: {},
        onSchedule: { _ in },
        onStartTimer: { _ in },
        onDismiss: {}
    )
}
