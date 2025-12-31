//
//  LiquidGlassTaskDetailSheet.swift
//  Veloce
//
//  Utopian Design System - Cosmic Task Codex
//  Mystical tome unfolding with prismatic glass, constellation
//  stepping stones, AI oracle insights, and portal vortex effects.
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

    // MARK: - Quick Action Pickers
    @State private var showSchedulePicker = false
    @State private var showDurationPicker = false
    @State private var showRecurringPicker = false
    @State private var showFriendPicker = false

    // MARK: - Recurring State
    @State private var selectedRecurringType: RecurringTypeExtended = .once
    @State private var customRecurringDays: Set<Int> = []
    @State private var recurringEndDate: Date? = nil

    // MARK: - Namespace for Glass Animations
    @Namespace private var quickActionNamespace

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

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
            // Deep cosmic void
            UtopianGradients.background(for: Date())
                .ignoresSafeArea()

            // Utopian wave background - responds to task state
            AuroraAnimatedWaveBackground.forProductivityState(
                taskCount: viewModel.subTasks.count,
                completedToday: viewModel.subTasks.filter { $0.status == .completed }.count
            )
            .ignoresSafeArea()
            .opacity(0.4)

            // Subtle gradient from task type
            RadialGradient(
                colors: [
                    taskCategoryColor.opacity(0.15),
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Utopian firefly field
            if !reduceMotion {
                AuroraFireflyField(
                    particleCount: 30,
                    colors: [
                        UtopianDesignFallback.Colors.focusActive.opacity(0.4),
                        UtopianDesignFallback.Colors.aiPurple.opacity(0.3),
                        UtopianDesignFallback.Colors.aiPurple.opacity(0.2)
                    ]
                )
                .opacity(0.5)
            }
        }
    }

    /// Category color for task
    private var taskCategoryColor: Color {
        switch task.taskType {
        case .create: return UtopianDesignFallback.Colors.aiPurple
        case .communicate: return UtopianDesignFallback.Colors.focusActive
        case .consume: return UtopianDesignFallback.Colors.completed
        case .coordinate: return UtopianDesignFallback.Gamification.starGold
        }
    }

    // MARK: - Header Bar (Sticky)

    private var headerBar: some View {
        HStack {
            // Close button with Utopian glow
            Button {
                HapticsService.shared.impact(.light)
                AuroraSoundEngine.shared.play(.buttonTap)
                onDismiss()
            } label: {
                ZStack {
                    // Ambient glow
                    Circle()
                        .fill(UtopianDesignFallback.Colors.focusActive.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .blur(radius: 4)

                    Image(systemName: "xmark")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
            }
            .auroraGlass(in: Circle())

            Spacer()

            // Title with mystical typography
            Text("Cosmic Codex")
                .font(UtopianDesignFallback.Typography.headline)
                .foregroundStyle(.white)

            Spacer()

            // Menu button with Utopian styling
            Menu {
                Button(action: {
                    HapticsService.shared.impact(.light)
                    onDuplicate()
                }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Button(action: {
                    HapticsService.shared.impact(.light)
                    showSnoozeOptions = true
                }) {
                    Label("Snooze", systemImage: "clock.arrow.circlepath")
                }
                Divider()
                Button(role: .destructive, action: {
                    HapticsService.shared.impact(.medium)
                    showDeleteConfirm = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                ZStack {
                    // Ambient glow
                    Circle()
                        .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .blur(radius: 4)

                    Image(systemName: "ellipsis")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
            }
            .auroraGlass(in: Circle())
        }
        .padding(.horizontal, UtopianDesignFallback.Spacing.lg)
        .padding(.vertical, UtopianDesignFallback.Spacing.md)
        .background {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .overlay {
                    // Top edge prismatic highlight
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    UtopianDesignFallback.Colors.focusActive.opacity(0.2),
                                    UtopianDesignFallback.Colors.aiPurple.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .offset(y: -6)
                }
        }
        .auroraGlass(in: Rectangle())
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
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.lg) {
            // Title row with aurora checkbox and edit
            HStack(alignment: .top, spacing: UtopianDesignFallback.Spacing.md) {
                // Completion checkbox with aurora glow
                Button {
                    HapticsService.shared.notification(.success)
                    AuroraSoundEngine.shared.play(.taskComplete)
                    onComplete()
                } label: {
                    ZStack {
                        // Aurora glow ring
                        if task.isCompleted {
                            Circle()
                                .fill(UtopianDesignFallback.Colors.completed.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .blur(radius: 6)
                        }

                        Circle()
                            .strokeBorder(
                                task.isCompleted
                                    ? UtopianDesignFallback.Colors.completed
                                    : .white.opacity(0.5).opacity(0.4),
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .dynamicTypeFont(base: 14, weight: .bold)
                                .foregroundStyle(UtopianDesignFallback.Colors.completed)
                        }
                    }
                }

                // Editable title with aurora typography
                VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.sm) {
                    if viewModel.isEditingTitle {
                        TextField("Task title", text: $viewModel.editableTitle)
                            .font(UtopianDesignFallback.Typography.title2)
                            .foregroundStyle(.white)
                            .submitLabel(.done)
                            .onSubmit { viewModel.isEditingTitle = false }
                    } else {
                        Text(viewModel.editableTitle)
                            .font(UtopianDesignFallback.Typography.title2)
                            .foregroundStyle(.white)
                            .strikethrough(task.isCompleted, color: .white.opacity(0.5))
                    }
                }

                Spacer()

                // Edit button with aurora glow
                Button {
                    HapticsService.shared.impact(.light)
                    viewModel.isEditingTitle.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(UtopianDesignFallback.Colors.focusActive.opacity(0.1))
                            .frame(width: 36, height: 36)
                            .blur(radius: 4)

                        Image(systemName: "pencil")
                            .dynamicTypeFont(base: 14)
                            .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
                            .frame(width: 32, height: 32)
                    }
                }
                .auroraGlass(in: Circle())
            }

            // Prismatic divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            UtopianDesignFallback.Colors.focusActive.opacity(0.3),
                            UtopianDesignFallback.Colors.aiPurple.opacity(0.2),
                            UtopianDesignFallback.Colors.aiPurple.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Quick Action Buttons - Aurora Interactive Snippets
            VStack(spacing: UtopianDesignFallback.Spacing.md) {
                // Time of Day Button
                InteractiveSnippetButton(
                    icon: "clock.fill",
                    label: "Time of Day",
                    value: task.scheduledTimeFormatted ?? "Not Set",
                    accentColor: UtopianDesignFallback.Colors.focusActive
                ) {
                    HapticsService.shared.impact(.light)
                    showSchedulePicker = true
                }

                // Duration Button
                InteractiveSnippetButton(
                    icon: "timer",
                    label: "Duration",
                    value: viewModel.estimatedMinutes > 0 ? "\(viewModel.estimatedMinutes) min" : "Set Duration",
                    accentColor: UtopianDesignFallback.Colors.aiPurple
                ) {
                    HapticsService.shared.impact(.light)
                    showDurationPicker = true
                }

                // Recurring Button
                InteractiveSnippetButton(
                    icon: "arrow.trianglehead.2.clockwise.rotate.90",
                    label: "Recurring",
                    value: selectedRecurringType.displayName,
                    accentColor: UtopianDesignFallback.Gamification.starGold
                ) {
                    HapticsService.shared.impact(.light)
                    showRecurringPicker = true
                }
            }
        }
        .padding(UtopianDesignFallback.Spacing.lg)
        .auroraGlassCard()
        // Schedule Picker Sheet
        .sheet(isPresented: $showSchedulePicker) {
            CalendarSchedulingSheet(task: task) { scheduledDate, duration in
                task.scheduledTime = scheduledDate
                task.estimatedMinutes = duration
                viewModel.estimatedMinutes = duration
                task.updatedAt = Date()
                onSchedule(scheduledDate)

                // Sync to Apple Calendar
                Task {
                    await syncToCalendar(date: scheduledDate, duration: duration)
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        // Duration Picker Sheet
        .sheet(isPresented: $showDurationPicker) {
            DurationPickerSheet(
                selectedDuration: viewModel.estimatedMinutes,
                onSelect: { duration in
                    viewModel.estimatedMinutes = duration
                    task.estimatedMinutes = duration
                    task.duration = duration
                    task.updatedAt = Date()

                    // Update calendar event if exists
                    if let eventId = task.calendarEventId {
                        Task {
                            try? await CalendarService.shared.updateEvent(
                                eventId: eventId,
                                title: nil,
                                startDate: nil,
                                duration: duration
                            )
                        }
                    }

                    showDurationPicker = false
                    HapticsService.shared.impact(.medium)
                    AuroraSoundEngine.shared.play(.buttonTap)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
        // Recurring Picker Sheet
        .sheet(isPresented: $showRecurringPicker) {
            RecurringPickerSheet(
                selectedType: $selectedRecurringType,
                customDays: $customRecurringDays,
                endDate: $recurringEndDate,
                onSave: {
                    task.setRecurringExtended(
                        type: selectedRecurringType,
                        customDays: customRecurringDays.isEmpty ? nil : customRecurringDays,
                        endDate: recurringEndDate
                    )
                    task.updatedAt = Date()
                    showRecurringPicker = false
                    HapticsService.shared.impact(.medium)
                    AuroraSoundEngine.shared.play(.buttonTap)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Sub-tasks Section (Constellation Stepping Stones)

    private var subTasksSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.lg) {
            // Header with aurora progress ring
            HStack {
                HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(UtopianDesignFallback.Colors.focusActive)

                    Text("Constellation Path")
                        .font(UtopianDesignFallback.Typography.headline)
                        .foregroundStyle(.white)
                }

                Spacer()

                // Progress indicator with aurora glow
                HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                    Text(viewModel.subTasks.progressString)
                        .font(UtopianDesignFallback.Typography.callout)
                        .foregroundStyle(.white.opacity(0.7))

                    // Aurora progress ring
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.5).opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        Circle()
                            .trim(from: 0, to: viewModel.subTasks.progress)
                            .stroke(
                                AngularGradient(
                                    colors: [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))

                        // Inner glow for completed
                        if viewModel.subTasks.progress > 0 {
                            Circle()
                                .fill(UtopianDesignFallback.Colors.completed.opacity(0.3))
                                .frame(width: 16, height: 16)
                                .blur(radius: 4)
                        }
                    }
                }
            }

            // Sub-task constellation list
            if viewModel.subTasks.isEmpty {
                // Empty state with cosmic messaging
                HStack {
                    Spacer()
                    VStack(spacing: UtopianDesignFallback.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.1))
                                .frame(width: 60, height: 60)
                                .blur(radius: 8)

                            Image(systemName: "star.circle")
                                .dynamicTypeFont(base: 32)
                                .foregroundStyle(.white.opacity(0.5).opacity(0.5))
                        }
                        Text("No stepping stones yet")
                            .font(UtopianDesignFallback.Typography.callout)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Break your task into constellation points")
                            .font(UtopianDesignFallback.Typography.caption)
                            .foregroundStyle(.white.opacity(0.5).opacity(0.7))
                    }
                    .padding(.vertical, UtopianDesignFallback.Spacing.xl)
                    Spacer()
                }
            } else {
                VStack(spacing: UtopianDesignFallback.Spacing.sm) {
                    ForEach(Array(viewModel.subTasks.enumerated()), id: \.element.id) { index, subTask in
                        AuroraSubTaskRow(
                            subTask: subTask,
                            index: index,
                            totalCount: viewModel.subTasks.count,
                            onToggle: { viewModel.toggleSubTask(subTask) },
                            onDelete: { viewModel.deleteSubTask(subTask) }
                        )
                    }
                }
            }

            // Add sub-task input with aurora styling
            if viewModel.isAddingSubTask {
                HStack(spacing: UtopianDesignFallback.Spacing.md) {
                    TextField("Add a stepping stone...", text: $viewModel.newSubTaskTitle)
                        .font(UtopianDesignFallback.Typography.body)
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
                            .dynamicTypeFont(base: 12, weight: .medium)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(UtopianDesignFallback.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1).opacity(0.5))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(UtopianDesignFallback.Colors.focusActive.opacity(0.3), lineWidth: 1)
                        }
                }
            }

            // Action buttons with aurora styling
            HStack(spacing: UtopianDesignFallback.Spacing.md) {
                Button {
                    HapticsService.shared.impact(.light)
                    viewModel.isAddingSubTask = true
                } label: {
                    HStack(spacing: UtopianDesignFallback.Spacing.xs) {
                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 12, weight: .bold)
                        Text("Add Step")
                            .font(UtopianDesignFallback.Typography.callout)
                    }
                    .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
                    .padding(.horizontal, UtopianDesignFallback.Spacing.md)
                    .padding(.vertical, UtopianDesignFallback.Spacing.sm)
                }
                .auroraGlass(in: Capsule())

                Button {
                    HapticsService.shared.impact(.medium)
                    AuroraSoundEngine.shared.play(.aiActivate)
                    Task { await viewModel.generateAISubTasks() }
                } label: {
                    HStack(spacing: UtopianDesignFallback.Spacing.xs) {
                        Image(systemName: "wand.and.stars")
                            .dynamicTypeFont(base: 12, weight: .bold)
                            .symbolEffect(.pulse, options: .repeating.speed(0.5))
                        Text("AI Generate")
                            .font(UtopianDesignFallback.Typography.callout)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, UtopianDesignFallback.Spacing.md)
                    .padding(.vertical, UtopianDesignFallback.Spacing.sm)
                    .background(LinearGradient(colors: [UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.focusActive], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(UtopianDesignFallback.Spacing.lg)
        .auroraGlassCard(accent: UtopianDesignFallback.Colors.focusActive)
    }

    // MARK: - AI Oracle Section (Violet Void + Mystical Insights)

    private var aiGeniusSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.lg) {
            // Mystical header with oracle styling
            aiOracleHeader

            // Context Input Section with aurora styling
            aiContextInputSection

            // Loading or Content
            if viewModel.isLoadingAI {
                aiOracleLoadingState
            } else {
                VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.lg) {
                    // AI Oracle Advice Card (violet void styling)
                    if !viewModel.aiAdvice.isEmpty {
                        aiOracleAdviceCard
                    }

                    // Web Sources (Inline Link Chips)
                    if !viewModel.aiWebSources.isEmpty {
                        aiWebSourcesSection
                    }

                    // YouTube Resources
                    if !viewModel.aiYouTubeResources.isEmpty {
                        aiYouTubeSection
                    }

                    // Time Estimate & Best Time Cards
                    aiTimeEstimateCards

                    // AI Suggested Sub-tasks
                    if !viewModel.aiSuggestedSubTasks.isEmpty {
                        aiSuggestedSubTasksSection
                    }

                    // AI Prompt Section
                    aiPromptSection
                }
            }

            // Error Display
            if let error = viewModel.aiError {
                aiErrorCard(error)
            }
        }
        .padding(UtopianDesignFallback.Spacing.lg)
        .background {
            // Violet void background for oracle section
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            UtopianDesignFallback.Colors.aiPurple.opacity(0.8).opacity(0.3),
                            UtopianDesignFallback.Colors.aiPurple.opacity(0.2),
                            Color.white.opacity(0.1).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .auroraGlassCard(accent: UtopianDesignFallback.Colors.aiPurple)
    }

    // MARK: - AI Oracle Header

    private var aiOracleHeader: some View {
        HStack {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                // Mystical oracle icon with glow
                ZStack {
                    Circle()
                        .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .blur(radius: 4)

                    Image(systemName: "sparkles")
                        .dynamicTypeFont(base: 16)
                        .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                        .symbolEffect(.pulse, options: .repeating, value: viewModel.isLoadingAI)
                }

                Text("AI Oracle")
                    .font(UtopianDesignFallback.Typography.headline)
                    .foregroundStyle(.white)

                // Powered by Perplexity badge with aurora styling
                Text("Perplexity")
                    .dynamicTypeFont(base: 9, weight: .medium)
                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.15))
                            .overlay {
                                Capsule()
                                    .strokeBorder(UtopianDesignFallback.Colors.aiPurple.opacity(0.3), lineWidth: 0.5)
                            }
                    }
            }

            Spacer()

            // Update Insights button with aurora glow
            Button {
                HapticsService.shared.impact(.medium)
                AuroraSoundEngine.shared.play(.aiActivate)
                Task { await viewModel.loadAIInsights() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .dynamicTypeFont(base: 12, weight: .medium)
                        .rotationEffect(.degrees(viewModel.isLoadingAI ? 360 : 0))
                        .animation(
                            viewModel.isLoadingAI ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: viewModel.isLoadingAI
                        )
                    Text("Consult")
                        .font(UtopianDesignFallback.Typography.caption)
                }
                .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                .padding(.horizontal, UtopianDesignFallback.Spacing.sm)
                .padding(.vertical, UtopianDesignFallback.Spacing.xs)
            }
            .auroraGlass(in: Capsule())
            .disabled(viewModel.isLoadingAI)
        }
    }

    // MARK: - AI Context Input

    private var aiContextInputSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.sm) {
            Text("Oracle Context")
                .font(UtopianDesignFallback.Typography.caption)
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                TextField("Share details to enhance the oracle's wisdom...", text: $viewModel.aiContext)
                    .font(UtopianDesignFallback.Typography.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, UtopianDesignFallback.Spacing.md)
                    .padding(.vertical, UtopianDesignFallback.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1).opacity(0.4))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                UtopianDesignFallback.Colors.aiPurple.opacity(0.3),
                                                UtopianDesignFallback.Colors.aiPurple.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                    }
            }
        }
    }

    // MARK: - AI Oracle Loading State

    private var aiOracleLoadingState: some View {
        VStack(spacing: UtopianDesignFallback.Spacing.lg) {
            // Aurora pulsing orbs
            HStack(spacing: UtopianDesignFallback.Spacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill([UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed][index % [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed].count].opacity(0.3))
                            .frame(width: 16, height: 16)
                            .blur(radius: 4)

                        Circle()
                            .fill([UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed][index % [UtopianDesignFallback.Colors.focusActive, UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.completed].count])
                            .frame(width: 8, height: 8)
                            .scaleEffect(viewModel.isLoadingAI ? 1.3 : 0.7)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: viewModel.isLoadingAI
                            )
                    }
                }
            }

            Text("The oracle is contemplating...")
                .font(UtopianDesignFallback.Typography.callout)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, UtopianDesignFallback.Spacing.xl)
    }

    // MARK: - AI Oracle Advice Card

    private var aiOracleAdviceCard: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.md) {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(UtopianDesignFallback.Gamification.starGold.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .blur(radius: 4)

                    Image(systemName: "lightbulb.fill")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(UtopianDesignFallback.Gamification.starGold)
                }

                Text("Oracle Wisdom")
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .foregroundStyle(.white)
            }

            // Advice text with typewriter-style appearance
            Text(viewModel.aiAdvice)
                .font(UtopianDesignFallback.Typography.body)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)

            if !viewModel.aiThoughtProcess.isEmpty {
                DisclosureGroup {
                    Text(viewModel.aiThoughtProcess)
                        .font(UtopianDesignFallback.Typography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, UtopianDesignFallback.Spacing.sm)
                } label: {
                    HStack(spacing: UtopianDesignFallback.Spacing.xs) {
                        Image(systemName: "brain")
                            .dynamicTypeFont(base: 10)
                        Text("Oracle's reasoning")
                            .font(UtopianDesignFallback.Typography.caption)
                    }
                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                }
                .tint(UtopianDesignFallback.Colors.aiPurple)
            }
        }
        .padding(UtopianDesignFallback.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            UtopianDesignFallback.Gamification.starGold.opacity(0.1),
                            UtopianDesignFallback.Gamification.starGold.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    UtopianDesignFallback.Gamification.starGold.opacity(0.3),
                                    UtopianDesignFallback.Gamification.starGold.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }

    // MARK: - Web Sources Section (Inline Link Chips)

    private var aiWebSourcesSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.sm) {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                Image(systemName: "link")
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(UtopianDesignFallback.Colors.focusActive)

                Text("Cosmic Sources")
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .foregroundStyle(.white)
            }

            // Inline link chips with aurora styling
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                    ForEach(viewModel.aiWebSources) { source in
                        Button {
                            HapticsService.shared.impact(.light)
                            if let url = URL(string: source.url) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .dynamicTypeFont(base: 10)

                                Text(source.source)
                                    .font(UtopianDesignFallback.Typography.caption)
                                    .lineLimit(1)

                                Image(systemName: "arrow.up.right")
                                    .dynamicTypeFont(base: 8)
                            }
                            .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
                            .padding(.horizontal, UtopianDesignFallback.Spacing.md)
                            .padding(.vertical, UtopianDesignFallback.Spacing.sm)
                            .background {
                                Capsule()
                                    .fill(UtopianDesignFallback.Colors.focusActive.opacity(0.1))
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(UtopianDesignFallback.Colors.focusActive.opacity(0.3), lineWidth: 1)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - YouTube Resources Section

    private var aiYouTubeSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.md) {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                Image(systemName: "play.rectangle.fill")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)

                Text("Learning Portals")
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .foregroundStyle(.white)
            }

            VStack(spacing: UtopianDesignFallback.Spacing.sm) {
                ForEach(viewModel.aiYouTubeResources) { resource in
                    Button {
                        HapticsService.shared.impact(.light)
                        if let url = resource.youtubeSearchURL {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: UtopianDesignFallback.Spacing.md) {
                            // YouTube icon with aurora glow
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .blur(radius: 2)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "play.fill")
                                    .dynamicTypeFont(base: 16)
                                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(resource.searchQuery)
                                    .font(UtopianDesignFallback.Typography.body)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(resource.reasoning)
                                    .font(UtopianDesignFallback.Typography.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Relevance indicator with aurora styling
                            Text("\(Int(resource.relevanceScore * 100))%")
                                .dynamicTypeFont(base: 11, weight: .medium)
                                .foregroundStyle(UtopianDesignFallback.Colors.completed)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(UtopianDesignFallback.Colors.completed.opacity(0.15))
                                }

                            Image(systemName: "arrow.up.right")
                                .dynamicTypeFont(base: 12)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(UtopianDesignFallback.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1).opacity(0.3))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Time Estimate Cards

    private var aiTimeEstimateCards: some View {
        HStack(spacing: UtopianDesignFallback.Spacing.md) {
            // Estimated Time Card with aurora styling
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(UtopianDesignFallback.Gamification.starGold)

                    Text("Estimated")
                        .font(UtopianDesignFallback.Typography.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(viewModel.aiEstimatedTimeDisplay)
                    .font(UtopianDesignFallback.Typography.title3)
                    .foregroundStyle(.white)

                // Confidence indicator with aurora colors
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor(viewModel.aiEstimateConfidence))
                        .frame(width: 6, height: 6)

                    Text(viewModel.aiEstimateConfidence.capitalized)
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UtopianDesignFallback.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.1).opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(UtopianDesignFallback.Gamification.starGold.opacity(0.25), lineWidth: 1)
                    }
            }

            // Best Time Card with Schedule Now
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(UtopianDesignFallback.Colors.completed)

                    Text("Best Time")
                        .font(UtopianDesignFallback.Typography.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(viewModel.aiBestTimeDisplay)
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Schedule Now button with aurora styling
                if viewModel.aiBestTime != nil {
                    Button {
                        if let bestTime = viewModel.aiBestTime {
                            task.scheduledTime = bestTime
                            task.updatedAt = Date()
                            Task {
                                await syncToCalendar(date: bestTime, duration: viewModel.aiEstimatedMinutes > 0 ? viewModel.aiEstimatedMinutes : viewModel.estimatedMinutes)
                            }
                            HapticsService.shared.notification(.success)
                            AuroraSoundEngine.shared.play(.taskComplete)
                        }
                    } label: {
                        Text("Schedule")
                            .dynamicTypeFont(base: 10, weight: .semibold)
                            .foregroundStyle(UtopianGradients.background(for: Date()))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(UtopianDesignFallback.Colors.completed)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UtopianDesignFallback.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.1).opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(UtopianDesignFallback.Colors.completed.opacity(0.25), lineWidth: 1)
                    }
            }
        }
    }

    private func confidenceColor(_ confidence: String) -> Color {
        switch confidence.lowercased() {
        case "high": return UtopianDesignFallback.Colors.completed
        case "medium": return UtopianDesignFallback.Gamification.starGold
        case "low": return UtopianDesignFallback.Colors.warning
        default: return .white.opacity(0.5)
        }
    }

    // MARK: - AI Suggested Sub-tasks Section

    private var aiSuggestedSubTasksSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.md) {
            HStack {
                HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                    Image(systemName: "list.bullet.clipboard")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(UtopianDesignFallback.Colors.focusActive)

                    Text("Oracle's Suggested Steps")
                        .font(UtopianDesignFallback.Typography.subheadline)
                        .foregroundStyle(.white)

                    Text("\(viewModel.aiSuggestedSubTasks.count)")
                        .dynamicTypeFont(base: 11, weight: .medium)
                        .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(UtopianDesignFallback.Colors.focusActive.opacity(0.15))
                        }
                }

                Spacer()

                // Add All button with aurora styling
                Button {
                    HapticsService.shared.notification(.success)
                    viewModel.addAllAISuggestedSubTasks()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .dynamicTypeFont(base: 12)
                        Text("Add All")
                            .dynamicTypeFont(base: 12, weight: .semibold)
                    }
                    .foregroundStyle(UtopianGradients.background(for: Date()))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(UtopianDesignFallback.Colors.completed)
                    .clipShape(Capsule())
                }
            }

            // Sub-task suggestions with aurora styling
            VStack(spacing: UtopianDesignFallback.Spacing.sm) {
                ForEach(viewModel.aiSuggestedSubTasks) { suggestion in
                    HStack(spacing: UtopianDesignFallback.Spacing.md) {
                        // Add button with aurora glow
                        Button {
                            HapticsService.shared.impact(.light)
                            viewModel.addSingleAISuggestedSubTask(suggestion)
                        } label: {
                            Image(systemName: "plus.circle")
                                .dynamicTypeFont(base: 18)
                                .foregroundStyle(UtopianDesignFallback.Colors.focusActive)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(UtopianDesignFallback.Typography.body)
                                .foregroundStyle(.white)

                            HStack(spacing: 8) {
                                Text("\(suggestion.estimatedMinutes) min")
                                    .font(UtopianDesignFallback.Typography.caption)
                                    .foregroundStyle(UtopianDesignFallback.Gamification.starGold)

                                if !suggestion.reasoning.isEmpty {
                                    Text(suggestion.reasoning)
                                        .font(UtopianDesignFallback.Typography.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(UtopianDesignFallback.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1).opacity(0.3))
                    }
                }
            }
        }
    }

    // MARK: - AI Prompt Section

    private var aiPromptSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.md) {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)

                Text("Cosmic Prompt")
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .foregroundStyle(.white)
            }

            // Prompt preview with aurora styling
            Text(viewModel.aiPrompt)
                .font(UtopianDesignFallback.Typography.body)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(4)
                .padding(UtopianDesignFallback.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1).opacity(0.3))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(UtopianDesignFallback.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                        }
                }

            // Action buttons with aurora styling
            HStack(spacing: UtopianDesignFallback.Spacing.md) {
                // Copy button
                Button {
                    HapticsService.shared.impact(.light)
                    viewModel.copyPromptToClipboard()
                    showCopiedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopiedToast = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .dynamicTypeFont(base: 12)
                        Text("Copy")
                            .font(UtopianDesignFallback.Typography.callout)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, UtopianDesignFallback.Spacing.lg)
                    .padding(.vertical, UtopianDesignFallback.Spacing.sm)
                }
                .auroraGlass(in: Capsule())

                // Open in ChatGPT button
                Button {
                    HapticsService.shared.impact(.light)
                    viewModel.openInChatGPT()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .dynamicTypeFont(base: 12)
                        Text("ChatGPT")
                            .font(UtopianDesignFallback.Typography.callout)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, UtopianDesignFallback.Spacing.lg)
                    .padding(.vertical, UtopianDesignFallback.Spacing.sm)
                    .background {
                        Capsule()
                            .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.3))
                    }
                }
                .auroraGlass(in: Capsule())
            }
        }
    }

    // MARK: - AI Error Card

    private func aiErrorCard(_ error: String) -> some View {
        HStack(spacing: UtopianDesignFallback.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .dynamicTypeFont(base: 14)
                .foregroundStyle(UtopianDesignFallback.Colors.warning)

            Text(error)
                .font(UtopianDesignFallback.Typography.caption)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)

            Spacer()

            Button {
                HapticsService.shared.impact(.light)
                Task { await viewModel.loadAIInsights() }
            } label: {
                Text("Retry")
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(UtopianDesignFallback.Colors.warning)
            }
        }
        .padding(UtopianDesignFallback.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(UtopianDesignFallback.Colors.warning.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(UtopianDesignFallback.Colors.warning.opacity(0.3), lineWidth: 1)
                }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.md) {
            HStack {
                Image(systemName: "note.text")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(UtopianDesignFallback.Colors.focusActive)

                Text("Cosmic Notes")
                    .font(UtopianDesignFallback.Typography.headline)
                    .foregroundStyle(.white)

                Spacer()
            }

            TextEditor(text: $viewModel.editableNotes)
                .font(UtopianDesignFallback.Typography.body)
                .foregroundStyle(.white.opacity(0.9))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(UtopianDesignFallback.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1).opacity(0.4))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(UtopianDesignFallback.Colors.focusActive.opacity(0.2), lineWidth: 1)
                        }
                }
                .overlay(alignment: .topLeading) {
                    if viewModel.editableNotes.isEmpty {
                        Text("Add notes to guide your focus...")
                            .font(UtopianDesignFallback.Typography.body)
                            .foregroundStyle(.white.opacity(0.5).opacity(0.6))
                            .padding(.horizontal, UtopianDesignFallback.Spacing.lg)
                            .padding(.vertical, UtopianDesignFallback.Spacing.lg)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(UtopianDesignFallback.Spacing.lg)
        .auroraGlassCard()
    }

    // MARK: - Focus Mode Section (Portal Preview)

    private var focusModeSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.lg) {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                // Portal vortex icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.focusActive], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 32, height: 32)
                        .blur(radius: 4)

                    Image(systemName: "bolt.fill")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(.white)
                }

                Text("Focus Portal")
                    .font(UtopianDesignFallback.Typography.headline)
                    .foregroundStyle(.white)
            }

            // Focus mode options with aurora styling
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                AuroraFocusModeOption(
                    icon: "brain.head.profile",
                    title: "Deep Work",
                    isSelected: viewModel.selectedFocusMode == .deepWork,
                    color: UtopianDesignFallback.Colors.aiPurple,
                    onTap: {
                        HapticsService.shared.impact(.light)
                        viewModel.selectedFocusMode = .deepWork
                    }
                )

                AuroraFocusModeOption(
                    icon: "timer",
                    title: "Pomodoro",
                    isSelected: viewModel.selectedFocusMode == .pomodoro,
                    color: UtopianDesignFallback.Colors.focusActive,
                    onTap: {
                        HapticsService.shared.impact(.light)
                        viewModel.selectedFocusMode = .pomodoro
                    }
                )

                AuroraFocusModeOption(
                    icon: "bolt.fill",
                    title: "Flow",
                    isSelected: viewModel.selectedFocusMode == .flowState,
                    color: UtopianDesignFallback.Gamification.starGold,
                    onTap: {
                        HapticsService.shared.impact(.light)
                        viewModel.selectedFocusMode = .flowState
                    }
                )
            }

            // App blocking toggle with aurora styling
            HStack {
                Image(systemName: "shield.fill")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(UtopianDesignFallback.Gamification.starGold)

                Text("Block Apps")
                    .font(UtopianDesignFallback.Typography.body)
                    .foregroundStyle(.white)

                Spacer()

                Toggle("", isOn: $viewModel.appBlockingEnabled)
                    .labelsHidden()
                    .tint(UtopianDesignFallback.Gamification.starGold)
            }
            .padding(UtopianDesignFallback.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1).opacity(0.4))
            }

            Text("Select apps to block during focus")
                .font(UtopianDesignFallback.Typography.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(UtopianDesignFallback.Spacing.lg)
        .auroraGlassCard(accent: UtopianDesignFallback.Colors.focusActive)
    }

    // MARK: - Collaboration Section

    private var collaborationSection: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.md) {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                Image(systemName: "person.2.circle.fill")
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)

                Text("Cosmic Circles")
                    .font(UtopianDesignFallback.Typography.headline)
                    .foregroundStyle(.white)
            }

            Button {
                HapticsService.shared.impact(.light)
                showFriendPicker = true
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(UtopianDesignFallback.Colors.aiPurple.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 14, weight: .bold)
                            .foregroundStyle(UtopianDesignFallback.Colors.aiPurple)
                    }

                    Text("Add from Circles")
                        .font(UtopianDesignFallback.Typography.body)
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(UtopianDesignFallback.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1).opacity(0.4))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(UtopianDesignFallback.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                        }
                }
            }

            Text("Tap to invite friends for accountability")
                .font(UtopianDesignFallback.Typography.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(UtopianDesignFallback.Spacing.lg)
        .auroraGlassCard()
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(
                taskId: task.id,
                taskTitle: task.title,
                onInvite: { friendIds in
                    // Invite each friend via SharedTaskService
                    Task {
                        for friendId in friendIds {
                            try? await SharedTaskService.shared.inviteFriendToTask(
                                taskId: task.id,
                                friendId: friendId
                            )
                        }
                    }
                    HapticsService.shared.notification(.success)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Action Bar (Sticky Bottom)

    private var actionBar: some View {
        HStack(spacing: UtopianDesignFallback.Spacing.lg) {
            // Complete button (primary) with aurora glow
            Button {
                HapticsService.shared.notification(.success)
                AuroraSoundEngine.shared.play(.taskComplete)
                onComplete()
            } label: {
                HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "checkmark")
                        .dynamicTypeFont(base: 16, weight: .bold)
                    Text(task.isCompleted ? "Completed" : "Complete")
                        .font(UtopianDesignFallback.Typography.headline)
                }
                .foregroundStyle(UtopianGradients.background(for: Date()))
                .frame(maxWidth: .infinity)
                .padding(.vertical, UtopianDesignFallback.Spacing.lg)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(UtopianDesignFallback.Colors.completed)
                    .shadow(color: UtopianDesignFallback.Colors.completed.opacity(0.4), radius: 8, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Start Focus button with aurora styling
            Button {
                HapticsService.shared.notification(.success)
                AuroraSoundEngine.shared.play(.aiActivate)
                onStartTimer(task)
                onDismiss()
            } label: {
                HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                    Image(systemName: "play.fill")
                        .dynamicTypeFont(base: 14)
                    Text("Focus")
                        .font(UtopianDesignFallback.Typography.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, UtopianDesignFallback.Spacing.xl)
                .padding(.vertical, UtopianDesignFallback.Spacing.lg)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [UtopianDesignFallback.Colors.aiPurple, UtopianDesignFallback.Colors.focusActive], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: UtopianDesignFallback.Colors.focusActive.opacity(0.3), radius: 8, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, UtopianDesignFallback.Spacing.lg)
        .padding(.vertical, UtopianDesignFallback.Spacing.lg)
        .background {
            Rectangle()
                .fill(Color.white.opacity(0.1).opacity(0.8))
                .overlay {
                    // Top edge prismatic highlight
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    UtopianDesignFallback.Colors.focusActive.opacity(0.3),
                                    UtopianDesignFallback.Colors.aiPurple.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .offset(y: -24)
                }
        }
        .auroraGlass(in: Rectangle())
    }

    // MARK: - Cosmic Toast

    private var copiedToast: some View {
        VStack {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(UtopianDesignFallback.Colors.completed.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .blur(radius: 4)

                    Image(systemName: "checkmark.circle.fill")
                        .dynamicTypeFont(base: 16)
                        .foregroundStyle(UtopianDesignFallback.Colors.completed)
                }

                Text("Copied to cosmic clipboard!")
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, UtopianDesignFallback.Spacing.xl)
            .padding(.vertical, UtopianDesignFallback.Spacing.md)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.1).opacity(0.9))
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        UtopianDesignFallback.Colors.completed.opacity(0.4),
                                        UtopianDesignFallback.Colors.focusActive.opacity(0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .auroraGlass(in: Capsule())
            .padding(.top, 60)

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func snoozeFor(hours: Int) {
        let snoozeDate = Calendar.current.date(byAdding: .hour, value: hours, to: Date())!
        onSnooze(snoozeDate)
        HapticsService.shared.impact(.medium)
        AuroraSoundEngine.shared.play(.buttonTap)
    }

    private func snoozeTomorrowMorning() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let snoozeDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        onSnooze(snoozeDate)
        HapticsService.shared.impact(.medium)
        AuroraSoundEngine.shared.play(.buttonTap)
    }

    // MARK: - Calendar Sync

    private func syncToCalendar(date: Date, duration: Int) async {
        // Check if task already has a calendar event
        if let existingEventId = task.calendarEventId {
            // Update existing event
            do {
                try await CalendarService.shared.updateEvent(
                    eventId: existingEventId,
                    title: task.title,
                    startDate: date,
                    duration: duration
                )
            } catch {
                print("Failed to update calendar event: \(error)")
            }
        } else {
            // Create new calendar event
            do {
                let eventId = try await CalendarService.shared.createEvent(
                    for: task,
                    at: date,
                    duration: duration
                )
                // Store the event ID on the task
                task.calendarEventId = eventId
                task.updatedAt = Date()
            } catch {
                print("Failed to create calendar event: \(error)")
            }
        }
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

    // AI State - Core
    var isLoadingAI: Bool = false
    var aiError: String?
    var aiContext: String = ""  // User-provided context for AI

    // AI State - Resources
    var aiWebSources: [AIWebSourceDisplay] = []
    var aiYouTubeResources: [AIYouTubeResourceDisplay] = []

    // AI State - Insights
    var aiAdvice: String = ""
    var aiThoughtProcess: String = ""
    var aiEstimatedMinutes: Int = 0
    var aiEstimateConfidence: String = "medium"
    var aiBestTime: Date?
    var aiBestTimeReason: String = ""

    // AI State - Suggested Sub-tasks
    var aiSuggestedSubTasks: [AISuggestedSubTaskDisplay] = []

    // AI State - Prompt for ChatGPT
    var aiPrompt: String = ""

    // Focus Mode
    var selectedFocusMode: WorkMode = .deepWork
    var appBlockingEnabled: Bool = false

    // Task reference
    private var task: TaskItem?

    // Computed Properties
    var aiEstimatedTimeDisplay: String {
        if aiEstimatedMinutes > 0 {
            return formatDuration(aiEstimatedMinutes)
        }
        return estimatedMinutes > 0 ? formatDuration(estimatedMinutes) : "Not set"
    }

    var aiBestTimeDisplay: String {
        guard let bestTime = aiBestTime else { return "Not suggested" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE h:mm a"
        return formatter.string(from: bestTime)
    }

    var hasAIInsights: Bool {
        !aiAdvice.isEmpty || !aiWebSources.isEmpty || !aiYouTubeResources.isEmpty
    }

    // MARK: - Setup

    func setup(task: TaskItem) {
        self.task = task
        self.editableTitle = task.title
        self.editableNotes = task.contextNotes ?? ""
        self.estimatedMinutes = task.estimatedMinutes ?? 30
        self.appBlockingEnabled = task.enableAppBlocking
        self.subTasks = task.subtasks

        // Initialize AI prompt
        aiPrompt = generateAIPrompt(for: task)
    }

    // MARK: - Duration Helpers

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes % 60 == 0 {
            return "\(minutes / 60)h"
        } else {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
    }

    func cycleDuration() {
        let durations = [15, 30, 45, 60, 90, 120]
        if let currentIndex = durations.firstIndex(of: estimatedMinutes) {
            estimatedMinutes = durations[(currentIndex + 1) % durations.count]
        } else {
            estimatedMinutes = 30
        }
        HapticsService.shared.impact(.light)
    }

    func cycleRecurring() {
        HapticsService.shared.impact(.light)
    }

    // MARK: - Sub-task Management

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
        task?.subtasks = subTasks
        newSubTaskTitle = ""
        isAddingSubTask = false
        HapticsService.shared.impact(.light)
        AuroraSoundEngine.shared.play(.buttonTap)
    }

    func toggleSubTask(_ subTask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == subTask.id }) {
            let newStatus: SubTaskStatus = subTask.status == .completed ? .pending : .completed
            subTasks[index].status = newStatus
            subTasks[index].completedAt = newStatus == .completed ? Date() : nil
        }
        task?.subtasks = subTasks
        if subTask.status != .completed {
            HapticsService.shared.notification(.success)
            AuroraSoundEngine.shared.play(.taskComplete)
        } else {
            HapticsService.shared.impact(.light)
        }
    }

    func deleteSubTask(_ subTask: SubTask) {
        subTasks.removeAll { $0.id == subTask.id }
        task?.subtasks = subTasks
        HapticsService.shared.impact(.medium)
    }

    // MARK: - AI Insights (Perplexity Integration)

    func loadAIInsights() async {
        guard let task = task else { return }

        isLoadingAI = true
        aiError = nil
        defer { isLoadingAI = false }

        // Generate prompt for ChatGPT/Claude copy
        aiPrompt = generateAIPrompt(for: task)

        // Check if Perplexity is configured
        guard PerplexityService.shared.isReady else {
            // Use fallback insights
            await loadFallbackInsights(for: task)
            return
        }

        do {
            // Call Perplexity for comprehensive task analysis
            let response = try await PerplexityService.shared.analyzeTask(
                title: task.title,
                notes: task.notes,
                context: aiContext.isEmpty ? nil : aiContext
            )

            // Update AI state from response
            aiAdvice = response.advice
            aiThoughtProcess = response.thoughtProcess ?? ""
            aiEstimatedMinutes = response.estimatedMinutes ?? estimatedMinutes

            // Parse schedule suggestion
            if let schedule = response.scheduleSuggestion {
                aiBestTimeReason = schedule.reasoning ?? ""
                aiBestTime = suggestedTimeFromTimeOfDay(schedule.suggestedTimeOfDay)
            }

            // Parse sub-tasks
            if let subTasksData = response.subTasks {
                aiSuggestedSubTasks = subTasksData.map { st in
                    AISuggestedSubTaskDisplay(
                        title: st.title,
                        estimatedMinutes: st.estimatedMinutes ?? 10,
                        reasoning: st.reasoning ?? ""
                    )
                }
            }

            // Parse YouTube resources
            if let youtube = response.youtubeResources {
                aiYouTubeResources = youtube.map { yt in
                    AIYouTubeResourceDisplay(from: yt)
                }
            }

            // Parse web sources from citations if available
            if let sources = response.sources {
                aiWebSources = sources.enumerated().map { index, url in
                    AIWebSourceDisplay(
                        title: "Source \(index + 1)",
                        url: url,
                        source: extractDomain(from: url)
                    )
                }
            }

        } catch {
            aiError = error.localizedDescription
            // Fallback to basic insights
            await loadFallbackInsights(for: task)
        }
    }

    private func loadFallbackInsights(for task: TaskItem) async {
        // Simulate thinking time
        try? await Task.sleep(for: .milliseconds(500))

        // Generate basic insights without AI
        aiAdvice = generateFallbackAdvice(for: task)
        aiEstimatedMinutes = estimatedMinutes > 0 ? estimatedMinutes : 30
        aiBestTime = suggestedTimeFromTimeOfDay(suggestBestTimeOfDay())
        aiBestTimeReason = "Based on typical productivity patterns"

        // Generate basic sub-task suggestions
        aiSuggestedSubTasks = [
            AISuggestedSubTaskDisplay(title: "Review requirements and gather materials", estimatedMinutes: 5, reasoning: "Start with preparation"),
            AISuggestedSubTaskDisplay(title: "Complete main action", estimatedMinutes: max(estimatedMinutes - 10, 15), reasoning: "Core task execution"),
            AISuggestedSubTaskDisplay(title: "Review and finalize", estimatedMinutes: 5, reasoning: "Quality check before completion")
        ]
    }

    private func generateFallbackAdvice(for task: TaskItem) -> String {
        switch task.taskType {
        case .create:
            return "Block distractions and set a clear goal before starting. Creative work benefits from uninterrupted focus time."
        case .communicate:
            return "Prepare your key points beforehand. Be clear and concise to save everyone's time."
        case .consume:
            return "Take notes as you go and summarize key points. Active engagement improves retention."
        case .coordinate:
            return "Batch similar administrative tasks together. Set a timer to prevent scope creep."
        }
    }

    private func suggestBestTimeOfDay() -> String {
        guard let task = task else { return "morning" }
        switch task.taskType {
        case .create: return "morning"
        case .communicate: return "afternoon"
        case .consume: return "morning"
        case .coordinate: return "afternoon"
        }
    }

    private func suggestedTimeFromTimeOfDay(_ timeOfDay: String?) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())

        switch timeOfDay?.lowercased() {
        case "morning":
            components.hour = 9
        case "afternoon":
            components.hour = 14
        case "evening":
            components.hour = 18
        default:
            components.hour = 9
        }
        components.minute = 0

        // If time has passed, suggest tomorrow
        if let suggestedDate = calendar.date(from: components),
           suggestedDate < Date() {
            return calendar.date(byAdding: .day, value: 1, to: suggestedDate) ?? suggestedDate
        }

        return calendar.date(from: components) ?? Date()
    }

    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else { return "Web" }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    // MARK: - AI Sub-tasks

    func generateAISubTasks() async {
        guard let task = task else { return }

        HapticsService.shared.impact(.medium)
        AuroraSoundEngine.shared.play(.aiActivate)
        isLoadingAI = true
        defer { isLoadingAI = false }

        // If we already have suggestions, just add them
        if !aiSuggestedSubTasks.isEmpty {
            addAllAISuggestedSubTasks()
            return
        }

        // Otherwise generate new ones via Perplexity
        if PerplexityService.shared.isReady {
            do {
                let response = try await PerplexityService.shared.analyzeTask(
                    title: task.title,
                    notes: task.notes,
                    context: aiContext.isEmpty ? nil : aiContext
                )

                if let subTasksData = response.subTasks {
                    aiSuggestedSubTasks = subTasksData.map { st in
                        AISuggestedSubTaskDisplay(
                            title: st.title,
                            estimatedMinutes: st.estimatedMinutes ?? 10,
                            reasoning: st.reasoning ?? ""
                        )
                    }
                    addAllAISuggestedSubTasks()
                }
            } catch {
                // Fallback
                await loadFallbackInsights(for: task)
                addAllAISuggestedSubTasks()
            }
        } else {
            // Generate basic sub-tasks
            await loadFallbackInsights(for: task)
            addAllAISuggestedSubTasks()
        }
    }

    func addAllAISuggestedSubTasks() {
        for suggestion in aiSuggestedSubTasks {
            let newSubTask = SubTask(
                id: UUID(),
                title: suggestion.title,
                estimatedMinutes: suggestion.estimatedMinutes,
                status: .pending,
                orderIndex: subTasks.count,
                aiReasoning: suggestion.reasoning,
                taskId: task?.id
            )
            subTasks.append(newSubTask)
        }
        task?.subtasks = subTasks
        aiSuggestedSubTasks = []  // Clear suggestions after adding
        HapticsService.shared.notification(.success)
        AuroraSoundEngine.shared.play(.aiComplete)
    }

    func addSingleAISuggestedSubTask(_ suggestion: AISuggestedSubTaskDisplay) {
        let newSubTask = SubTask(
            id: UUID(),
            title: suggestion.title,
            estimatedMinutes: suggestion.estimatedMinutes,
            status: .pending,
            orderIndex: subTasks.count,
            aiReasoning: suggestion.reasoning,
            taskId: task?.id
        )
        subTasks.append(newSubTask)
        task?.subtasks = subTasks
        aiSuggestedSubTasks.removeAll { $0.id == suggestion.id }
        HapticsService.shared.impact(.light)
        AuroraSoundEngine.shared.play(.buttonTap)
    }

    // MARK: - AI Prompt Generation

    private func generateAIPrompt(for task: TaskItem) -> String {
        let contextSection = aiContext.isEmpty ? "" : "\nAdditional context: \(aiContext)"
        let notesSection = task.contextNotes.map { "\nNotes: \($0)" } ?? ""

        return """
        Help me complete: "\(task.title)"
        \(notesSection)\(contextSection)

        Please provide:
        1. A step-by-step approach to complete this efficiently
        2. Potential challenges I might face and how to overcome them
        3. Time-saving tips specific to this type of task
        4. Resources or tools that could help
        """
    }

    func copyPromptToClipboard() {
        UIPasteboard.general.string = aiPrompt
        HapticsService.shared.impact(.medium)
        AuroraSoundEngine.shared.play(.buttonTap)
    }

    func openInChatGPT() {
        let encodedPrompt = aiPrompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://chat.openai.com/?q=\(encodedPrompt)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Local AI UI Models

/// Local UI model for web sources (wraps URL strings with display info)
struct AIWebSourceDisplay: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let source: String
}

/// Local UI model for YouTube resources with computed URL
struct AIYouTubeResourceDisplay: Identifiable {
    let id = UUID()
    let searchQuery: String
    let relevanceScore: Double
    let reasoning: String

    var youtubeSearchURL: URL? {
        let query = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(query)")
    }

    init(from resource: AIYouTubeResource) {
        self.searchQuery = resource.searchQuery
        self.relevanceScore = resource.relevanceScore ?? 0.8
        self.reasoning = resource.reasoning ?? ""
    }

    init(searchQuery: String, relevanceScore: Double, reasoning: String) {
        self.searchQuery = searchQuery
        self.relevanceScore = relevanceScore
        self.reasoning = reasoning
    }
}

/// Local UI model for suggested sub-tasks
struct AISuggestedSubTaskDisplay: Identifiable {
    let id = UUID()
    let title: String
    let estimatedMinutes: Int
    let reasoning: String
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
                    .dynamicTypeFont(base: 12)
                Text(text)
                    .dynamicTypeFont(base: 13, weight: .medium)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .glassEffect(.regular, in: Capsule())
    }
}

/// Aurora-styled sub-task row - constellation stepping stone
struct SubTaskRow: View {
    let subTask: SubTask
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: UtopianDesignFallback.Spacing.md) {
            // Aurora checkbox with glow
            Button(action: onToggle) {
                ZStack {
                    // Glow layer
                    if subTask.status == .completed {
                        Circle()
                            .fill(UtopianDesignFallback.Colors.completed.opacity(0.3))
                            .frame(width: 26, height: 26)
                            .blur(radius: 4)
                    }

                    Circle()
                        .strokeBorder(
                            subTask.status == .completed
                                ? UtopianDesignFallback.Colors.completed
                                : .white.opacity(0.5).opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if subTask.status == .completed {
                        Image(systemName: "checkmark")
                            .dynamicTypeFont(base: 11, weight: .bold)
                            .foregroundStyle(UtopianDesignFallback.Colors.completed)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(subTask.title)
                    .font(UtopianDesignFallback.Typography.body)
                    .foregroundStyle(subTask.status == .completed ? .white.opacity(0.5) : .white)
                    .strikethrough(subTask.status == .completed, color: .white.opacity(0.5))

                if let minutes = subTask.estimatedMinutes {
                    Text("\(minutes)m")
                        .font(UtopianDesignFallback.Typography.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            // AI-generated indicator with aurora sparkle
            if subTask.isAIGenerated {
                ZStack {
                    Image(systemName: "sparkle")
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(UtopianDesignFallback.Colors.aiPurple.opacity(0.5))
                        .blur(radius: 2)

                    Image(systemName: "sparkle")
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(UtopianDesignFallback.Colors.aiPurple.opacity(0.8))
                }
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(UtopianDesignFallback.Colors.error.opacity(0.7))
            }
        }
        .padding(.horizontal, UtopianDesignFallback.Spacing.lg)
        .padding(.vertical, UtopianDesignFallback.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1).opacity(0.3))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            subTask.status == .completed
                                ? UtopianDesignFallback.Colors.completed.opacity(0.2)
                                : .white.opacity(0.5).opacity(0.1),
                            lineWidth: 1
                        )
                }
        }
    }
}

/// Aurora-styled AI insight row with cosmic styling
struct AIInsightRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: UtopianDesignFallback.Spacing.md) {
            HStack(spacing: UtopianDesignFallback.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .blur(radius: 3)

                    Image(systemName: icon)
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
            }

            content()
        }
    }
}

/// Aurora-styled focus mode option with glow effects
struct AuroraFocusModeOption: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: UtopianDesignFallback.Spacing.sm) {
                ZStack {
                    // Glow layer when selected
                    if isSelected {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .blur(radius: 6)
                    }

                    Image(systemName: icon)
                        .dynamicTypeFont(base: 18)
                        .foregroundStyle(isSelected ? color : .white.opacity(0.5))
                }

                Text(title)
                    .font(UtopianDesignFallback.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, UtopianDesignFallback.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.1).opacity(0.3))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected
                                    ? LinearGradient(
                                        colors: [color.opacity(0.5), color.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                    : LinearGradient(
                                        colors: [.white.opacity(0.5).opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      ),
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

// MARK: - Aurora Glass Card Extension

extension View {
    /// Aurora-styled glass card with optional accent color
    func auroraGlassCard(accent: Color? = nil) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1).opacity(0.5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        (accent ?? .white.opacity(0.5)).opacity(0.25),
                                        (accent ?? .white.opacity(0.5)).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .auroraGlass(in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Aurora SubTask Row

struct AuroraSubTaskRow: View {
    let subTask: SubTask
    let index: Int
    let totalCount: Int
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: UtopianDesignFallback.Spacing.md) {
            // Completion checkbox with aurora styling
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            subTask.isCompleted ? UtopianDesignFallback.Colors.completed : Color.white.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if subTask.isCompleted {
                        Circle()
                            .fill(UtopianDesignFallback.Colors.completed)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .buttonStyle(.plain)

            // Sub-task title
            Text(subTask.title)
                .font(UtopianDesignFallback.Typography.body)
                .foregroundStyle(subTask.isCompleted ? .white.opacity(0.5) : .white)
                .strikethrough(subTask.isCompleted)

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(UtopianDesignFallback.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1).opacity(0.3))
        }
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
