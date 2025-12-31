//
//  LiquidGlassTaskDetailSheet.swift
//  Veloce
//
//  Aurora Design System - Cosmic Task Codex
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
            Aurora.Colors.voidCosmos
                .ignoresSafeArea()

            // Aurora wave background - responds to task state
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
                    Aurora.Colors.voidNebula.opacity(0.5),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Aurora firefly field
            if !reduceMotion {
                AuroraFireflyField(
                    particleCount: 30,
                    colors: [
                        Aurora.Colors.electricCyan.opacity(0.4),
                        Aurora.Colors.borealisViolet.opacity(0.3),
                        Aurora.Colors.stellarMagenta.opacity(0.2)
                    ]
                )
                .opacity(0.5)
            }
        }
    }

    /// Category color for task
    private var taskCategoryColor: Color {
        switch task.taskType {
        case .create: return Aurora.Colors.categoryCreative
        case .communicate: return Aurora.Colors.categoryPersonal
        case .consume: return Aurora.Colors.categoryLearning
        case .coordinate: return Aurora.Colors.categoryWork
        }
    }

    // MARK: - Header Bar (Sticky)

    private var headerBar: some View {
        HStack {
            // Close button with aurora glow
            Button {
                AuroraHaptics.light()
                AuroraSoundEngine.shared.play(.buttonTap)
                onDismiss()
            } label: {
                ZStack {
                    // Ambient glow
                    Circle()
                        .fill(Aurora.Colors.electricCyan.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .blur(radius: 4)

                    Image(systemName: "xmark")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(Aurora.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .auroraGlass(in: Circle())

            Spacer()

            // Title with mystical typography
            Text("Cosmic Codex")
                .font(Aurora.Typography.headline)
                .foregroundStyle(Aurora.Colors.textPrimary)

            Spacer()

            // Menu button with aurora styling
            Menu {
                Button(action: {
                    AuroraHaptics.light()
                    onDuplicate()
                }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Button(action: {
                    AuroraHaptics.light()
                    showSnoozeOptions = true
                }) {
                    Label("Snooze", systemImage: "clock.arrow.circlepath")
                }
                Divider()
                Button(role: .destructive, action: {
                    AuroraHaptics.medium()
                    showDeleteConfirm = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                ZStack {
                    // Ambient glow
                    Circle()
                        .fill(Aurora.Colors.borealisViolet.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .blur(radius: 4)

                    Image(systemName: "ellipsis")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(Aurora.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .auroraGlass(in: Circle())
        }
        .padding(.horizontal, Aurora.Spacing.lg)
        .padding(.vertical, Aurora.Spacing.md)
        .background {
            Rectangle()
                .fill(Aurora.Colors.voidNebula.opacity(0.6))
                .overlay {
                    // Top edge prismatic highlight
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Aurora.Colors.electricCyan.opacity(0.2),
                                    Aurora.Colors.borealisViolet.opacity(0.1),
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
        VStack(alignment: .leading, spacing: Aurora.Spacing.lg) {
            // Title row with aurora checkbox and edit
            HStack(alignment: .top, spacing: Aurora.Spacing.md) {
                // Completion checkbox with aurora glow
                Button {
                    AuroraHaptics.dopamineBurst()
                    AuroraSoundEngine.shared.play(.taskComplete)
                    onComplete()
                } label: {
                    ZStack {
                        // Aurora glow ring
                        if task.isCompleted {
                            Circle()
                                .fill(Aurora.Colors.prismaticGreen.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .blur(radius: 6)
                        }

                        Circle()
                            .strokeBorder(
                                task.isCompleted
                                    ? Aurora.Colors.prismaticGreen
                                    : Aurora.Colors.textTertiary.opacity(0.4),
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .dynamicTypeFont(base: 14, weight: .bold)
                                .foregroundStyle(Aurora.Colors.prismaticGreen)
                        }
                    }
                }

                // Editable title with aurora typography
                VStack(alignment: .leading, spacing: Aurora.Spacing.sm) {
                    if viewModel.isEditingTitle {
                        TextField("Task title", text: $viewModel.editableTitle)
                            .font(Aurora.Typography.title2)
                            .foregroundStyle(Aurora.Colors.textPrimary)
                            .submitLabel(.done)
                            .onSubmit { viewModel.isEditingTitle = false }
                    } else {
                        Text(viewModel.editableTitle)
                            .font(Aurora.Typography.title2)
                            .foregroundStyle(Aurora.Colors.textPrimary)
                            .strikethrough(task.isCompleted, color: Aurora.Colors.textTertiary)
                    }
                }

                Spacer()

                // Edit button with aurora glow
                Button {
                    AuroraHaptics.light()
                    viewModel.isEditingTitle.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Aurora.Colors.electricCyan.opacity(0.1))
                            .frame(width: 36, height: 36)
                            .blur(radius: 4)

                        Image(systemName: "pencil")
                            .dynamicTypeFont(base: 14)
                            .foregroundStyle(Aurora.Colors.electricCyan)
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
                            Aurora.Colors.electricCyan.opacity(0.3),
                            Aurora.Colors.borealisViolet.opacity(0.2),
                            Aurora.Colors.stellarMagenta.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Quick Action Buttons - Aurora Interactive Snippets
            VStack(spacing: Aurora.Spacing.md) {
                // Time of Day Button
                InteractiveSnippetButton(
                    icon: "clock.fill",
                    label: "Time of Day",
                    value: task.scheduledTimeFormatted ?? "Not Set",
                    accentColor: Aurora.Colors.electricCyan
                ) {
                    AuroraHaptics.light()
                    showSchedulePicker = true
                }

                // Duration Button
                InteractiveSnippetButton(
                    icon: "timer",
                    label: "Duration",
                    value: viewModel.estimatedMinutes > 0 ? "\(viewModel.estimatedMinutes) min" : "Set Duration",
                    accentColor: Aurora.Colors.borealisViolet
                ) {
                    AuroraHaptics.light()
                    showDurationPicker = true
                }

                // Recurring Button
                InteractiveSnippetButton(
                    icon: "arrow.trianglehead.2.clockwise.rotate.90",
                    label: "Recurring",
                    value: selectedRecurringType.displayName,
                    accentColor: Aurora.Colors.cosmicGold
                ) {
                    AuroraHaptics.light()
                    showRecurringPicker = true
                }
            }
        }
        .padding(Aurora.Spacing.lg)
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
                    AuroraHaptics.medium()
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
                    AuroraHaptics.medium()
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
        VStack(alignment: .leading, spacing: Aurora.Spacing.lg) {
            // Header with aurora progress ring
            HStack {
                HStack(spacing: Aurora.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(Aurora.Colors.electricCyan)

                    Text("Constellation Path")
                        .font(Aurora.Typography.headline)
                        .foregroundStyle(Aurora.Colors.textPrimary)
                }

                Spacer()

                // Progress indicator with aurora glow
                HStack(spacing: Aurora.Spacing.sm) {
                    Text(viewModel.subTasks.progressString)
                        .font(Aurora.Typography.callout)
                        .foregroundStyle(Aurora.Colors.textSecondary)

                    // Aurora progress ring
                    ZStack {
                        Circle()
                            .stroke(Aurora.Colors.textTertiary.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        Circle()
                            .trim(from: 0, to: viewModel.subTasks.progress)
                            .stroke(
                                AngularGradient(
                                    colors: Aurora.Gradients.auroraSpectrum,
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))

                        // Inner glow for completed
                        if viewModel.subTasks.progress > 0 {
                            Circle()
                                .fill(Aurora.Colors.prismaticGreen.opacity(0.3))
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
                    VStack(spacing: Aurora.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Aurora.Colors.borealisViolet.opacity(0.1))
                                .frame(width: 60, height: 60)
                                .blur(radius: 8)

                            Image(systemName: "star.circle")
                                .dynamicTypeFont(base: 32)
                                .foregroundStyle(Aurora.Colors.textTertiary.opacity(0.5))
                        }
                        Text("No stepping stones yet")
                            .font(Aurora.Typography.callout)
                            .foregroundStyle(Aurora.Colors.textTertiary)
                        Text("Break your task into constellation points")
                            .font(Aurora.Typography.caption)
                            .foregroundStyle(Aurora.Colors.textTertiary.opacity(0.7))
                    }
                    .padding(.vertical, Aurora.Spacing.xl)
                    Spacer()
                }
            } else {
                VStack(spacing: Aurora.Spacing.sm) {
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
                HStack(spacing: Aurora.Spacing.md) {
                    TextField("Add a stepping stone...", text: $viewModel.newSubTaskTitle)
                        .font(Aurora.Typography.body)
                        .foregroundStyle(Aurora.Colors.textPrimary)
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
                            .foregroundStyle(Aurora.Colors.textTertiary)
                    }
                }
                .padding(Aurora.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Aurora.Colors.voidNebula.opacity(0.5))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Aurora.Colors.electricCyan.opacity(0.3), lineWidth: 1)
                        }
                }
            }

            // Action buttons with aurora styling
            HStack(spacing: Aurora.Spacing.md) {
                Button {
                    AuroraHaptics.light()
                    viewModel.isAddingSubTask = true
                } label: {
                    HStack(spacing: Aurora.Spacing.xs) {
                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 12, weight: .bold)
                        Text("Add Step")
                            .font(Aurora.Typography.callout)
                    }
                    .foregroundStyle(Aurora.Colors.electricCyan)
                    .padding(.horizontal, Aurora.Spacing.md)
                    .padding(.vertical, Aurora.Spacing.sm)
                }
                .auroraGlass(in: Capsule())

                Button {
                    AuroraHaptics.medium()
                    AuroraSoundEngine.shared.play(.aiActivate)
                    Task { await viewModel.generateAISubTasks() }
                } label: {
                    HStack(spacing: Aurora.Spacing.xs) {
                        Image(systemName: "wand.and.stars")
                            .dynamicTypeFont(base: 12, weight: .bold)
                            .symbolEffect(.pulse, options: .repeating.speed(0.5))
                        Text("AI Generate")
                            .font(Aurora.Typography.callout)
                    }
                    .foregroundStyle(Aurora.Colors.textPrimary)
                    .padding(.horizontal, Aurora.Spacing.md)
                    .padding(.vertical, Aurora.Spacing.sm)
                    .background(Aurora.Gradients.aiGradient)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(Aurora.Spacing.lg)
        .auroraGlassCard(accent: Aurora.Colors.electricCyan)
    }

    // MARK: - AI Oracle Section (Violet Void + Mystical Insights)

    private var aiGeniusSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.lg) {
            // Mystical header with oracle styling
            aiOracleHeader

            // Context Input Section with aurora styling
            aiContextInputSection

            // Loading or Content
            if viewModel.isLoadingAI {
                aiOracleLoadingState
            } else {
                VStack(alignment: .leading, spacing: Aurora.Spacing.lg) {
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
        .padding(Aurora.Spacing.lg)
        .background {
            // Violet void background for oracle section
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.deepPlasma.opacity(0.3),
                            Aurora.Colors.borealisViolet.opacity(0.2),
                            Aurora.Colors.voidNebula.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .auroraGlassCard(accent: Aurora.Colors.borealisViolet)
    }

    // MARK: - AI Oracle Header

    private var aiOracleHeader: some View {
        HStack {
            HStack(spacing: Aurora.Spacing.sm) {
                // Mystical oracle icon with glow
                ZStack {
                    Circle()
                        .fill(Aurora.Colors.borealisViolet.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .blur(radius: 4)

                    Image(systemName: "sparkles")
                        .dynamicTypeFont(base: 16)
                        .foregroundStyle(Aurora.Colors.stellarMagenta)
                        .symbolEffect(.pulse, options: .repeating, value: viewModel.isLoadingAI)
                }

                Text("AI Oracle")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                // Powered by Perplexity badge with aurora styling
                Text("Perplexity")
                    .dynamicTypeFont(base: 9, weight: .medium)
                    .foregroundStyle(Aurora.Colors.borealisViolet)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Aurora.Colors.borealisViolet.opacity(0.15))
                            .overlay {
                                Capsule()
                                    .strokeBorder(Aurora.Colors.borealisViolet.opacity(0.3), lineWidth: 0.5)
                            }
                    }
            }

            Spacer()

            // Update Insights button with aurora glow
            Button {
                AuroraHaptics.medium()
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
                        .font(Aurora.Typography.caption)
                }
                .foregroundStyle(Aurora.Colors.borealisViolet)
                .padding(.horizontal, Aurora.Spacing.sm)
                .padding(.vertical, Aurora.Spacing.xs)
            }
            .auroraGlass(in: Capsule())
            .disabled(viewModel.isLoadingAI)
        }
    }

    // MARK: - AI Context Input

    private var aiContextInputSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.sm) {
            Text("Oracle Context")
                .font(Aurora.Typography.caption)
                .foregroundStyle(Aurora.Colors.textTertiary)

            HStack(spacing: Aurora.Spacing.sm) {
                TextField("Share details to enhance the oracle's wisdom...", text: $viewModel.aiContext)
                    .font(Aurora.Typography.body)
                    .foregroundStyle(Aurora.Colors.textPrimary)
                    .padding(.horizontal, Aurora.Spacing.md)
                    .padding(.vertical, Aurora.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Aurora.Colors.voidNebula.opacity(0.4))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Aurora.Colors.borealisViolet.opacity(0.3),
                                                Aurora.Colors.stellarMagenta.opacity(0.2)
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
        VStack(spacing: Aurora.Spacing.lg) {
            // Aurora pulsing orbs
            HStack(spacing: Aurora.Spacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(Aurora.Gradients.auroraSpectrum[index % Aurora.Gradients.auroraSpectrum.count].opacity(0.3))
                            .frame(width: 16, height: 16)
                            .blur(radius: 4)

                        Circle()
                            .fill(Aurora.Gradients.auroraSpectrum[index % Aurora.Gradients.auroraSpectrum.count])
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
                .font(Aurora.Typography.callout)
                .foregroundStyle(Aurora.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Aurora.Spacing.xl)
    }

    // MARK: - AI Oracle Advice Card

    private var aiOracleAdviceCard: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.md) {
            HStack(spacing: Aurora.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Aurora.Colors.cosmicGold.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .blur(radius: 4)

                    Image(systemName: "lightbulb.fill")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(Aurora.Colors.cosmicGold)
                }

                Text("Oracle Wisdom")
                    .font(Aurora.Typography.subheadline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
            }

            // Advice text with typewriter-style appearance
            Text(viewModel.aiAdvice)
                .font(Aurora.Typography.body)
                .foregroundStyle(Aurora.Colors.textPrimary.opacity(0.9))
                .lineSpacing(4)

            if !viewModel.aiThoughtProcess.isEmpty {
                DisclosureGroup {
                    Text(viewModel.aiThoughtProcess)
                        .font(Aurora.Typography.caption)
                        .foregroundStyle(Aurora.Colors.textSecondary)
                        .padding(.top, Aurora.Spacing.sm)
                } label: {
                    HStack(spacing: Aurora.Spacing.xs) {
                        Image(systemName: "brain")
                            .dynamicTypeFont(base: 10)
                        Text("Oracle's reasoning")
                            .font(Aurora.Typography.caption)
                    }
                    .foregroundStyle(Aurora.Colors.borealisViolet)
                }
                .tint(Aurora.Colors.borealisViolet)
            }
        }
        .padding(Aurora.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.cosmicGold.opacity(0.1),
                            Aurora.Colors.cosmicGold.opacity(0.05)
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
                                    Aurora.Colors.cosmicGold.opacity(0.3),
                                    Aurora.Colors.cosmicGold.opacity(0.1)
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
        VStack(alignment: .leading, spacing: Aurora.Spacing.sm) {
            HStack(spacing: Aurora.Spacing.sm) {
                Image(systemName: "link")
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(Aurora.Colors.electricCyan)

                Text("Cosmic Sources")
                    .font(Aurora.Typography.subheadline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
            }

            // Inline link chips with aurora styling
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Aurora.Spacing.sm) {
                    ForEach(viewModel.aiWebSources) { source in
                        Button {
                            AuroraHaptics.light()
                            if let url = URL(string: source.url) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .dynamicTypeFont(base: 10)

                                Text(source.source)
                                    .font(Aurora.Typography.caption)
                                    .lineLimit(1)

                                Image(systemName: "arrow.up.right")
                                    .dynamicTypeFont(base: 8)
                            }
                            .foregroundStyle(Aurora.Colors.electricCyan)
                            .padding(.horizontal, Aurora.Spacing.md)
                            .padding(.vertical, Aurora.Spacing.sm)
                            .background {
                                Capsule()
                                    .fill(Aurora.Colors.electricCyan.opacity(0.1))
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(Aurora.Colors.electricCyan.opacity(0.3), lineWidth: 1)
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
        VStack(alignment: .leading, spacing: Aurora.Spacing.md) {
            HStack(spacing: Aurora.Spacing.sm) {
                Image(systemName: "play.rectangle.fill")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Aurora.Colors.stellarMagenta)

                Text("Learning Portals")
                    .font(Aurora.Typography.subheadline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
            }

            VStack(spacing: Aurora.Spacing.sm) {
                ForEach(viewModel.aiYouTubeResources) { resource in
                    Button {
                        AuroraHaptics.light()
                        if let url = resource.youtubeSearchURL {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: Aurora.Spacing.md) {
                            // YouTube icon with aurora glow
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Aurora.Colors.stellarMagenta.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .blur(radius: 2)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Aurora.Colors.stellarMagenta.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "play.fill")
                                    .dynamicTypeFont(base: 16)
                                    .foregroundStyle(Aurora.Colors.stellarMagenta)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(resource.searchQuery)
                                    .font(Aurora.Typography.body)
                                    .foregroundStyle(Aurora.Colors.textPrimary)
                                    .lineLimit(1)

                                Text(resource.reasoning)
                                    .font(Aurora.Typography.caption)
                                    .foregroundStyle(Aurora.Colors.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Relevance indicator with aurora styling
                            Text("\(Int(resource.relevanceScore * 100))%")
                                .dynamicTypeFont(base: 11, weight: .medium)
                                .foregroundStyle(Aurora.Colors.prismaticGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(Aurora.Colors.prismaticGreen.opacity(0.15))
                                }

                            Image(systemName: "arrow.up.right")
                                .dynamicTypeFont(base: 12)
                                .foregroundStyle(Aurora.Colors.textTertiary)
                        }
                        .padding(Aurora.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Aurora.Colors.voidNebula.opacity(0.3))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Time Estimate Cards

    private var aiTimeEstimateCards: some View {
        HStack(spacing: Aurora.Spacing.md) {
            // Estimated Time Card with aurora styling
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(Aurora.Colors.cosmicGold)

                    Text("Estimated")
                        .font(Aurora.Typography.caption)
                        .foregroundStyle(Aurora.Colors.textTertiary)
                }

                Text(viewModel.aiEstimatedTimeDisplay)
                    .font(Aurora.Typography.title3)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                // Confidence indicator with aurora colors
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor(viewModel.aiEstimateConfidence))
                        .frame(width: 6, height: 6)

                    Text(viewModel.aiEstimateConfidence.capitalized)
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(Aurora.Colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Aurora.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Aurora.Colors.voidNebula.opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Aurora.Colors.cosmicGold.opacity(0.25), lineWidth: 1)
                    }
            }

            // Best Time Card with Schedule Now
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(Aurora.Colors.prismaticGreen)

                    Text("Best Time")
                        .font(Aurora.Typography.caption)
                        .foregroundStyle(Aurora.Colors.textTertiary)
                }

                Text(viewModel.aiBestTimeDisplay)
                    .font(Aurora.Typography.subheadline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
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
                            AuroraHaptics.dopamineBurst()
                            AuroraSoundEngine.shared.play(.taskComplete)
                        }
                    } label: {
                        Text("Schedule")
                            .dynamicTypeFont(base: 10, weight: .semibold)
                            .foregroundStyle(Aurora.Colors.voidCosmos)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Aurora.Colors.prismaticGreen)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Aurora.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Aurora.Colors.voidNebula.opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Aurora.Colors.prismaticGreen.opacity(0.25), lineWidth: 1)
                    }
            }
        }
    }

    private func confidenceColor(_ confidence: String) -> Color {
        switch confidence.lowercased() {
        case "high": return Aurora.Colors.prismaticGreen
        case "medium": return Aurora.Colors.cosmicGold
        case "low": return Aurora.Colors.warning
        default: return Aurora.Colors.textTertiary
        }
    }

    // MARK: - AI Suggested Sub-tasks Section

    private var aiSuggestedSubTasksSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.md) {
            HStack {
                HStack(spacing: Aurora.Spacing.sm) {
                    Image(systemName: "list.bullet.clipboard")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(Aurora.Colors.electricCyan)

                    Text("Oracle's Suggested Steps")
                        .font(Aurora.Typography.subheadline)
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    Text("\(viewModel.aiSuggestedSubTasks.count)")
                        .dynamicTypeFont(base: 11, weight: .medium)
                        .foregroundStyle(Aurora.Colors.electricCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(Aurora.Colors.electricCyan.opacity(0.15))
                        }
                }

                Spacer()

                // Add All button with aurora styling
                Button {
                    AuroraHaptics.dopamineBurst()
                    viewModel.addAllAISuggestedSubTasks()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .dynamicTypeFont(base: 12)
                        Text("Add All")
                            .dynamicTypeFont(base: 12, weight: .semibold)
                    }
                    .foregroundStyle(Aurora.Colors.voidCosmos)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Aurora.Colors.prismaticGreen)
                    .clipShape(Capsule())
                }
            }

            // Sub-task suggestions with aurora styling
            VStack(spacing: Aurora.Spacing.sm) {
                ForEach(viewModel.aiSuggestedSubTasks) { suggestion in
                    HStack(spacing: Aurora.Spacing.md) {
                        // Add button with aurora glow
                        Button {
                            AuroraHaptics.light()
                            viewModel.addSingleAISuggestedSubTask(suggestion)
                        } label: {
                            Image(systemName: "plus.circle")
                                .dynamicTypeFont(base: 18)
                                .foregroundStyle(Aurora.Colors.electricCyan)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(Aurora.Typography.body)
                                .foregroundStyle(Aurora.Colors.textPrimary)

                            HStack(spacing: 8) {
                                Text("\(suggestion.estimatedMinutes) min")
                                    .font(Aurora.Typography.caption)
                                    .foregroundStyle(Aurora.Colors.cosmicGold)

                                if !suggestion.reasoning.isEmpty {
                                    Text(suggestion.reasoning)
                                        .font(Aurora.Typography.caption)
                                        .foregroundStyle(Aurora.Colors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(Aurora.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Aurora.Colors.voidNebula.opacity(0.3))
                    }
                }
            }
        }
    }

    // MARK: - AI Prompt Section

    private var aiPromptSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.md) {
            HStack(spacing: Aurora.Spacing.sm) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Aurora.Colors.borealisViolet)

                Text("Cosmic Prompt")
                    .font(Aurora.Typography.subheadline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
            }

            // Prompt preview with aurora styling
            Text(viewModel.aiPrompt)
                .font(Aurora.Typography.body)
                .foregroundStyle(Aurora.Colors.textPrimary.opacity(0.85))
                .lineLimit(4)
                .padding(Aurora.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Aurora.Colors.voidNebula.opacity(0.3))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Aurora.Colors.borealisViolet.opacity(0.2), lineWidth: 1)
                        }
                }

            // Action buttons with aurora styling
            HStack(spacing: Aurora.Spacing.md) {
                // Copy button
                Button {
                    AuroraHaptics.light()
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
                            .font(Aurora.Typography.callout)
                    }
                    .foregroundStyle(Aurora.Colors.textPrimary)
                    .padding(.horizontal, Aurora.Spacing.lg)
                    .padding(.vertical, Aurora.Spacing.sm)
                }
                .auroraGlass(in: Capsule())

                // Open in ChatGPT button
                Button {
                    AuroraHaptics.light()
                    viewModel.openInChatGPT()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .dynamicTypeFont(base: 12)
                        Text("ChatGPT")
                            .font(Aurora.Typography.callout)
                    }
                    .foregroundStyle(Aurora.Colors.textPrimary)
                    .padding(.horizontal, Aurora.Spacing.lg)
                    .padding(.vertical, Aurora.Spacing.sm)
                    .background {
                        Capsule()
                            .fill(Aurora.Colors.borealisViolet.opacity(0.3))
                    }
                }
                .auroraGlass(in: Capsule())
            }
        }
    }

    // MARK: - AI Error Card

    private func aiErrorCard(_ error: String) -> some View {
        HStack(spacing: Aurora.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .dynamicTypeFont(base: 14)
                .foregroundStyle(Aurora.Colors.warning)

            Text(error)
                .font(Aurora.Typography.caption)
                .foregroundStyle(Aurora.Colors.textPrimary.opacity(0.8))
                .lineLimit(2)

            Spacer()

            Button {
                AuroraHaptics.light()
                Task { await viewModel.loadAIInsights() }
            } label: {
                Text("Retry")
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(Aurora.Colors.warning)
            }
        }
        .padding(Aurora.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Aurora.Colors.warning.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Aurora.Colors.warning.opacity(0.3), lineWidth: 1)
                }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.md) {
            HStack {
                Image(systemName: "note.text")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Aurora.Colors.electricCyan)

                Text("Cosmic Notes")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Spacer()
            }

            TextEditor(text: $viewModel.editableNotes)
                .font(Aurora.Typography.body)
                .foregroundStyle(Aurora.Colors.textPrimary.opacity(0.9))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(Aurora.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Aurora.Colors.voidNebula.opacity(0.4))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Aurora.Colors.electricCyan.opacity(0.2), lineWidth: 1)
                        }
                }
                .overlay(alignment: .topLeading) {
                    if viewModel.editableNotes.isEmpty {
                        Text("Add notes to guide your focus...")
                            .font(Aurora.Typography.body)
                            .foregroundStyle(Aurora.Colors.textTertiary.opacity(0.6))
                            .padding(.horizontal, Aurora.Spacing.lg)
                            .padding(.vertical, Aurora.Spacing.lg)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(Aurora.Spacing.lg)
        .auroraGlassCard()
    }

    // MARK: - Focus Mode Section (Portal Preview)

    private var focusModeSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.lg) {
            HStack(spacing: Aurora.Spacing.sm) {
                // Portal vortex icon
                ZStack {
                    Circle()
                        .fill(Aurora.Gradients.aiGradient)
                        .frame(width: 32, height: 32)
                        .blur(radius: 4)

                    Image(systemName: "bolt.fill")
                        .dynamicTypeFont(base: 14)
                        .foregroundStyle(Aurora.Colors.textPrimary)
                }

                Text("Focus Portal")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
            }

            // Focus mode options with aurora styling
            HStack(spacing: Aurora.Spacing.sm) {
                AuroraFocusModeOption(
                    icon: "brain.head.profile",
                    title: "Deep Work",
                    isSelected: viewModel.selectedFocusMode == .deepWork,
                    color: Aurora.Colors.borealisViolet,
                    onTap: {
                        AuroraHaptics.light()
                        viewModel.selectedFocusMode = .deepWork
                    }
                )

                AuroraFocusModeOption(
                    icon: "timer",
                    title: "Pomodoro",
                    isSelected: viewModel.selectedFocusMode == .pomodoro,
                    color: Aurora.Colors.electricCyan,
                    onTap: {
                        AuroraHaptics.light()
                        viewModel.selectedFocusMode = .pomodoro
                    }
                )

                AuroraFocusModeOption(
                    icon: "bolt.fill",
                    title: "Flow",
                    isSelected: viewModel.selectedFocusMode == .flowState,
                    color: Aurora.Colors.cosmicGold,
                    onTap: {
                        AuroraHaptics.light()
                        viewModel.selectedFocusMode = .flowState
                    }
                )
            }

            // App blocking toggle with aurora styling
            HStack {
                Image(systemName: "shield.fill")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Aurora.Colors.cosmicGold)

                Text("Block Apps")
                    .font(Aurora.Typography.body)
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Spacer()

                Toggle("", isOn: $viewModel.appBlockingEnabled)
                    .labelsHidden()
                    .tint(Aurora.Colors.cosmicGold)
            }
            .padding(Aurora.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Aurora.Colors.voidNebula.opacity(0.4))
            }

            Text("Select apps to block during focus")
                .font(Aurora.Typography.caption)
                .foregroundStyle(Aurora.Colors.textTertiary)
        }
        .padding(Aurora.Spacing.lg)
        .auroraGlassCard(accent: Aurora.Colors.electricCyan)
    }

    // MARK: - Collaboration Section

    private var collaborationSection: some View {
        VStack(alignment: .leading, spacing: Aurora.Spacing.md) {
            HStack(spacing: Aurora.Spacing.sm) {
                Image(systemName: "person.2.circle.fill")
                    .dynamicTypeFont(base: 16)
                    .foregroundStyle(Aurora.Colors.stellarMagenta)

                Text("Cosmic Circles")
                    .font(Aurora.Typography.headline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
            }

            Button {
                AuroraHaptics.light()
                showFriendPicker = true
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Aurora.Colors.stellarMagenta.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 14, weight: .bold)
                            .foregroundStyle(Aurora.Colors.stellarMagenta)
                    }

                    Text("Add from Circles")
                        .font(Aurora.Typography.body)
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .dynamicTypeFont(base: 12)
                        .foregroundStyle(Aurora.Colors.textTertiary)
                }
                .padding(Aurora.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Aurora.Colors.voidNebula.opacity(0.4))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Aurora.Colors.stellarMagenta.opacity(0.2), lineWidth: 1)
                        }
                }
            }

            Text("Tap to invite friends for accountability")
                .font(Aurora.Typography.caption)
                .foregroundStyle(Aurora.Colors.textTertiary)
        }
        .padding(Aurora.Spacing.lg)
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
                    AuroraHaptics.celebration()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Action Bar (Sticky Bottom)

    private var actionBar: some View {
        HStack(spacing: Aurora.Spacing.lg) {
            // Complete button (primary) with aurora glow
            Button {
                AuroraHaptics.dopamineBurst()
                AuroraSoundEngine.shared.play(.taskComplete)
                onComplete()
            } label: {
                HStack(spacing: Aurora.Spacing.sm) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "checkmark")
                        .dynamicTypeFont(base: 16, weight: .bold)
                    Text(task.isCompleted ? "Completed" : "Complete")
                        .font(Aurora.Typography.headline)
                }
                .foregroundStyle(Aurora.Colors.voidCosmos)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Aurora.Spacing.lg)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Aurora.Colors.prismaticGreen)
                    .shadow(color: Aurora.Colors.prismaticGreen.opacity(0.4), radius: 8, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Start Focus button with aurora styling
            Button {
                AuroraHaptics.portalOpen()
                AuroraSoundEngine.shared.play(.aiActivate)
                onStartTimer(task)
                onDismiss()
            } label: {
                HStack(spacing: Aurora.Spacing.sm) {
                    Image(systemName: "play.fill")
                        .dynamicTypeFont(base: 14)
                    Text("Focus")
                        .font(Aurora.Typography.headline)
                }
                .foregroundStyle(Aurora.Colors.textPrimary)
                .padding(.horizontal, Aurora.Spacing.xl)
                .padding(.vertical, Aurora.Spacing.lg)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Aurora.Gradients.aiGradient)
                    .shadow(color: Aurora.Colors.electricCyan.opacity(0.3), radius: 8, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, Aurora.Spacing.lg)
        .padding(.vertical, Aurora.Spacing.lg)
        .background {
            Rectangle()
                .fill(Aurora.Colors.voidNebula.opacity(0.8))
                .overlay {
                    // Top edge prismatic highlight
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Aurora.Colors.electricCyan.opacity(0.3),
                                    Aurora.Colors.borealisViolet.opacity(0.2),
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
            HStack(spacing: Aurora.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Aurora.Colors.prismaticGreen.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .blur(radius: 4)

                    Image(systemName: "checkmark.circle.fill")
                        .dynamicTypeFont(base: 16)
                        .foregroundStyle(Aurora.Colors.prismaticGreen)
                }

                Text("Copied to cosmic clipboard!")
                    .font(Aurora.Typography.subheadline)
                    .foregroundStyle(Aurora.Colors.textPrimary)
            }
            .padding(.horizontal, Aurora.Spacing.xl)
            .padding(.vertical, Aurora.Spacing.md)
            .background {
                Capsule()
                    .fill(Aurora.Colors.voidNebula.opacity(0.9))
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Aurora.Colors.prismaticGreen.opacity(0.4),
                                        Aurora.Colors.electricCyan.opacity(0.2)
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
        AuroraHaptics.medium()
        AuroraSoundEngine.shared.play(.buttonTap)
    }

    private func snoozeTomorrowMorning() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let snoozeDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        onSnooze(snoozeDate)
        AuroraHaptics.medium()
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
        AuroraHaptics.light()
    }

    func cycleRecurring() {
        AuroraHaptics.light()
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
        AuroraHaptics.light()
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
            AuroraHaptics.dopamineBurst()
            AuroraSoundEngine.shared.play(.taskComplete)
        } else {
            AuroraHaptics.light()
        }
    }

    func deleteSubTask(_ subTask: SubTask) {
        subTasks.removeAll { $0.id == subTask.id }
        task?.subtasks = subTasks
        AuroraHaptics.medium()
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

        AuroraHaptics.medium()
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
        AuroraHaptics.celebration()
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
        AuroraHaptics.light()
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
        AuroraHaptics.medium()
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
        HStack(spacing: Aurora.Spacing.md) {
            // Aurora checkbox with glow
            Button(action: onToggle) {
                ZStack {
                    // Glow layer
                    if subTask.status == .completed {
                        Circle()
                            .fill(Aurora.Colors.prismaticGreen.opacity(0.3))
                            .frame(width: 26, height: 26)
                            .blur(radius: 4)
                    }

                    Circle()
                        .strokeBorder(
                            subTask.status == .completed
                                ? Aurora.Colors.prismaticGreen
                                : Aurora.Colors.textTertiary.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if subTask.status == .completed {
                        Image(systemName: "checkmark")
                            .dynamicTypeFont(base: 11, weight: .bold)
                            .foregroundStyle(Aurora.Colors.prismaticGreen)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(subTask.title)
                    .font(Aurora.Typography.body)
                    .foregroundStyle(subTask.status == .completed ? Aurora.Colors.textTertiary : Aurora.Colors.textPrimary)
                    .strikethrough(subTask.status == .completed, color: Aurora.Colors.textTertiary)

                if let minutes = subTask.estimatedMinutes {
                    Text("\(minutes)m")
                        .font(Aurora.Typography.caption)
                        .foregroundStyle(Aurora.Colors.textTertiary)
                }
            }

            Spacer()

            // AI-generated indicator with aurora sparkle
            if subTask.isAIGenerated {
                ZStack {
                    Image(systemName: "sparkle")
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(Aurora.Colors.borealisViolet.opacity(0.5))
                        .blur(radius: 2)

                    Image(systemName: "sparkle")
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(Aurora.Colors.borealisViolet.opacity(0.8))
                }
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(Aurora.Colors.error.opacity(0.7))
            }
        }
        .padding(.horizontal, Aurora.Spacing.lg)
        .padding(.vertical, Aurora.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Aurora.Colors.voidNebula.opacity(0.3))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            subTask.status == .completed
                                ? Aurora.Colors.prismaticGreen.opacity(0.2)
                                : Aurora.Colors.textTertiary.opacity(0.1),
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
        VStack(alignment: .leading, spacing: Aurora.Spacing.md) {
            HStack(spacing: Aurora.Spacing.sm) {
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
                    .font(Aurora.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Aurora.Colors.textPrimary.opacity(0.9))
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
            VStack(spacing: Aurora.Spacing.sm) {
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
                        .foregroundStyle(isSelected ? color : Aurora.Colors.textTertiary)
                }

                Text(title)
                    .font(Aurora.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Aurora.Colors.textPrimary : Aurora.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Aurora.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : Aurora.Colors.voidNebula.opacity(0.3))
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
                                        colors: [Aurora.Colors.textTertiary.opacity(0.1)],
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
                    .fill(Aurora.Colors.voidNebula.opacity(0.5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        (accent ?? Aurora.Colors.textTertiary).opacity(0.25),
                                        (accent ?? Aurora.Colors.textTertiary).opacity(0.1)
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
        HStack(spacing: Aurora.Spacing.md) {
            // Completion checkbox with aurora styling
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            subTask.isCompleted ? Aurora.Colors.prismaticGreen : Aurora.Colors.glassBorder,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if subTask.isCompleted {
                        Circle()
                            .fill(Aurora.Colors.prismaticGreen)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .buttonStyle(.plain)

            // Sub-task title
            Text(subTask.title)
                .font(Aurora.Typography.body)
                .foregroundStyle(subTask.isCompleted ? Aurora.Colors.textTertiary : Aurora.Colors.textPrimary)
                .strikethrough(subTask.isCompleted)

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(Aurora.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(Aurora.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Aurora.Colors.voidNebula.opacity(0.3))
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
