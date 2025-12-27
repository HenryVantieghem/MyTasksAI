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

            // Quick Action Buttons - Interactive Snippets Design (WWDC 2025)
            VStack(spacing: 12) {
                // Time of Day Button
                InteractiveSnippetButton(
                    icon: "clock.fill",
                    label: "Time of Day",
                    value: task.scheduledTimeFormatted ?? "Not Set",
                    accentColor: Theme.Colors.aiBlue
                ) {
                    HapticsService.shared.selectionFeedback()
                    showSchedulePicker = true
                }

                // Duration Button
                InteractiveSnippetButton(
                    icon: "timer",
                    label: "Duration",
                    value: viewModel.estimatedMinutes > 0 ? "\(viewModel.estimatedMinutes) min" : "Set Duration",
                    accentColor: Theme.CelestialColors.nebulaCore
                ) {
                    HapticsService.shared.selectionFeedback()
                    showDurationPicker = true
                }

                // Recurring Button
                InteractiveSnippetButton(
                    icon: "arrow.trianglehead.2.clockwise.rotate.90",
                    label: "Recurring",
                    value: selectedRecurringType.displayName,
                    accentColor: Theme.Colors.aiAmber
                ) {
                    HapticsService.shared.selectionFeedback()
                    showRecurringPicker = true
                }
            }
        }
        .padding(20)
        .glassCard()
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
                            await CalendarService.shared.updateEvent(
                                eventId: eventId,
                                title: nil,
                                startDate: nil,
                                duration: duration
                            )
                        }
                    }

                    showDurationPicker = false
                    HapticsService.shared.successFeedback()
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
                    HapticsService.shared.successFeedback()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
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
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Header with sparkle
            aiGeniusHeader

            // Context Input Section
            aiContextInputSection

            // Loading or Content
            if viewModel.isLoadingAI {
                aiLoadingState
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // AI Advice Card
                    if !viewModel.aiAdvice.isEmpty {
                        aiAdviceCard
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
        .padding(20)
        .glassCard(accent: Theme.CelestialColors.nebulaCore)
    }

    // MARK: - AI Genius Header

    private var aiGeniusHeader: some View {
        HStack {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)
                    .symbolEffect(.pulse, options: .repeating, value: viewModel.isLoadingAI)

                Text("AI Insights")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                // Powered by Perplexity badge
                Text("Perplexity")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Theme.CelestialColors.nebulaCore.opacity(0.15))
                    }
            }

            Spacer()

            // Update Insights button
            Button {
                HapticsService.shared.impact()
                Task { await viewModel.loadAIInsights() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .rotationEffect(.degrees(viewModel.isLoadingAI ? 360 : 0))
                        .animation(
                            viewModel.isLoadingAI ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: viewModel.isLoadingAI
                        )
                    Text("Update")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.CelestialColors.nebulaCore)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .glassEffect(.regular, in: Capsule())
            .disabled(viewModel.isLoadingAI)
        }
    }

    // MARK: - AI Context Input

    private var aiContextInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Add Context")
                .font(Theme.Typography.cosmosMeta)
                .foregroundStyle(Theme.CelestialColors.starDim)

            HStack(spacing: Theme.Spacing.sm) {
                TextField("e.g., first time doing this, deadline is Friday...", text: $viewModel.aiContext)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Theme.CelestialColors.starDim.opacity(0.2), lineWidth: 1)
                            }
                    }
            }
        }
    }

    // MARK: - AI Loading State

    private var aiLoadingState: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Theme.CelestialColors.nebulaCore)
                        .frame(width: 8, height: 8)
                        .scaleEffect(viewModel.isLoadingAI ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: viewModel.isLoadingAI
                        )
                }
            }

            Text("Analyzing with Perplexity AI...")
                .font(.system(size: 13))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - AI Advice Card

    private var aiAdviceCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiAmber)

                Text("AI Advice")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(viewModel.aiAdvice)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)

            if !viewModel.aiThoughtProcess.isEmpty {
                DisclosureGroup {
                    Text(viewModel.aiThoughtProcess)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .padding(.top, 8)
                } label: {
                    Text("Show reasoning")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)
                }
                .tint(Theme.CelestialColors.nebulaCore)
            }
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.aiAmber.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Theme.Colors.aiAmber.opacity(0.2), lineWidth: 1)
                }
        }
    }

    // MARK: - Web Sources Section (Inline Link Chips)

    private var aiWebSourcesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.aiBlue)

                Text("Web Sources")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }

            // Inline link chips (horizontal scroll)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.aiWebSources) { source in
                        Button {
                            if let url = URL(string: source.url) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .font(.system(size: 10))

                                Text(source.source)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 8))
                            }
                            .foregroundStyle(Theme.Colors.aiBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(Theme.Colors.aiBlue.opacity(0.12))
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(Theme.Colors.aiBlue.opacity(0.25), lineWidth: 1)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)

                Text("YouTube Resources")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(viewModel.aiYouTubeResources) { resource in
                    Button {
                        if let url = resource.youtubeSearchURL {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            // YouTube icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.red.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "play.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.red)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(resource.searchQuery)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(resource.reasoning)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.CelestialColors.starDim)
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Relevance indicator
                            Text("\(Int(resource.relevanceScore * 100))%")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.CelestialColors.auroraGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(Theme.CelestialColors.auroraGreen.opacity(0.15))
                                }

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                        }
                        .padding(Theme.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.03))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Time Estimate Cards

    private var aiTimeEstimateCards: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Estimated Time Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.aiAmber)

                    Text("Estimated")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Text(viewModel.aiEstimatedTimeDisplay)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                // Confidence indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor(viewModel.aiEstimateConfidence))
                        .frame(width: 6, height: 6)

                    Text(viewModel.aiEstimateConfidence.capitalized)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Theme.Colors.aiAmber.opacity(0.2), lineWidth: 1)
                    }
            }

            // Best Time Card with Schedule Now
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)

                    Text("Best Time")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Text(viewModel.aiBestTimeDisplay)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Schedule Now button
                if viewModel.aiBestTime != nil {
                    Button {
                        if let bestTime = viewModel.aiBestTime {
                            task.scheduledTime = bestTime
                            task.updatedAt = Date()
                            Task {
                                await syncToCalendar(date: bestTime, duration: viewModel.aiEstimatedMinutes > 0 ? viewModel.aiEstimatedMinutes : viewModel.estimatedMinutes)
                            }
                            HapticsService.shared.successFeedback()
                        }
                    } label: {
                        Text("Schedule")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.CelestialColors.auroraGreen)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Theme.CelestialColors.auroraGreen.opacity(0.2), lineWidth: 1)
                    }
            }
        }
    }

    private func confidenceColor(_ confidence: String) -> Color {
        switch confidence.lowercased() {
        case "high": return Theme.CelestialColors.auroraGreen
        case "medium": return Theme.Colors.aiAmber
        case "low": return .orange
        default: return Theme.CelestialColors.starDim
        }
    }

    // MARK: - AI Suggested Sub-tasks Section

    private var aiSuggestedSubTasksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)

                    Text("AI Suggested Steps")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("\(viewModel.aiSuggestedSubTasks.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(Theme.CelestialColors.nebulaCore.opacity(0.15))
                        }
                }

                Spacer()

                // Add All button
                Button {
                    viewModel.addAllAISuggestedSubTasks()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("Add All")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.CelestialColors.auroraGreen)
                    .clipShape(Capsule())
                }
            }

            // Sub-task suggestions
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(viewModel.aiSuggestedSubTasks) { suggestion in
                    HStack(spacing: Theme.Spacing.md) {
                        // Add button
                        Button {
                            viewModel.addSingleAISuggestedSubTask(suggestion)
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.CelestialColors.nebulaCore)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)

                            HStack(spacing: 8) {
                                Text("\(suggestion.estimatedMinutes) min")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.Colors.aiAmber)

                                if !suggestion.reasoning.isEmpty {
                                    Text(suggestion.reasoning)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.CelestialColors.starDim)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(Theme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.03))
                    }
                }
            }
        }
    }

    // MARK: - AI Prompt Section

    private var aiPromptSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("AI Prompt")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Prompt preview
            Text(viewModel.aiPrompt)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(4)
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                }

            // Action buttons
            HStack(spacing: Theme.Spacing.md) {
                // Copy button
                Button {
                    viewModel.copyPromptToClipboard()
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .glassEffect(.regular, in: Capsule())

                // Open in ChatGPT button
                Button {
                    viewModel.openInChatGPT()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 12))
                        Text("ChatGPT")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.aiPurple.opacity(0.3))
                    }
                }
                .glassEffect(.regular, in: Capsule())
            }
        }
    }

    // MARK: - AI Error Card

    private func aiErrorCard(_ error: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.orange)

            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)

            Spacer()

            Button {
                Task { await viewModel.loadAIInsights() }
            } label: {
                Text("Retry")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange)
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.orange.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
                }
        }
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
                showFriendPicker = true
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
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(
                taskId: task.id,
                taskTitle: task.title,
                onInvite: { friendIds in
                    // Invite each friend via SharedTaskService
                    Task {
                        for friendId in friendIds {
                            await SharedTaskService.shared.inviteFriendToTask(
                                taskId: task.id,
                                friendId: friendId
                            )
                        }
                    }
                    HapticsService.shared.successFeedback()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
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
        HapticsService.shared.selectionFeedback()
    }

    func cycleRecurring() {
        HapticsService.shared.selectionFeedback()
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
        HapticsService.shared.selectionFeedback()
    }

    func toggleSubTask(_ subTask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == subTask.id }) {
            let newStatus: SubTaskStatus = subTask.status == .completed ? .pending : .completed
            subTasks[index].status = newStatus
            subTasks[index].completedAt = newStatus == .completed ? Date() : nil
        }
        task?.subtasks = subTasks
        HapticsService.shared.selectionFeedback()
    }

    func deleteSubTask(_ subTask: SubTask) {
        subTasks.removeAll { $0.id == subTask.id }
        task?.subtasks = subTasks
        HapticsService.shared.impact()
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

        HapticsService.shared.impact()
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
        HapticsService.shared.successFeedback()
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
        HapticsService.shared.selectionFeedback()
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
        HapticsService.shared.successFeedback()
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
