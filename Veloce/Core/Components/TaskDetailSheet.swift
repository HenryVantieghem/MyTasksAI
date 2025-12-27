//
//  TaskDetailSheet.swift
//  MyTasksAI
//
//  Beautiful Slide-Up Task Detail Sheet
//  Glass cards with AI insights, scheduling, and actions
//

import SwiftUI
import Supabase

// MARK: - Task Detail Content View

/// Slide-up sheet showing full task details with AI insight
struct TaskDetailContentView: View {
    let task: TaskItem
    let onToggleComplete: () -> Void
    let onReprocessAI: () -> Void
    let onSchedule: (Date) -> Void
    let onDuplicate: () -> Void
    let onSnooze: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void

    @State private var appeared: Bool = false
    @State private var showThoughtProcess: Bool = false
    @State private var showSchedulePicker: Bool = false
    @State private var isRefreshingAI: Bool = false
    @State private var refreshRotation: Double = 0

    // MARK: - Cognitive Productivity States
    @State private var contextNotes: String = ""
    @State private var subTasks: [SubTask] = []
    @State private var youtubeResources: [YouTubeResource] = []
    @State private var scheduleSuggestion: ScheduleSuggestion?
    @State private var aiThoughtProcessText: String = ""
    @State private var showingReflectionSheet: Bool = false

    // MARK: - Editing States
    @State private var editableTitle: String = ""
    @State private var recurringType: RecurringTypeExtended = .once
    @State private var recurringCustomDays: Set<Int> = []
    @State private var recurringEndDate: Date?
    @State private var showDeleteConfirmation: Bool = false
    @State private var showCalendarScheduling: Bool = false

    // Get priority from task (default to medium)
    private var taskPriority: TaskPriority {
        TaskPriority(rawValue: task.starRating) ?? .medium
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title card
                titleCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // MARK: - Context Input Module (NEW)
                ContextInputModule(
                    contextNotes: $contextNotes,
                    taskTitle: task.title,
                    onContextUpdated: { _ in
                        regenerateAIContent()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.05), value: appeared)

                // AI Insight card (existing)
                aiInsightCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1), value: appeared)

                // MARK: - AI Prompt Card (NEW) - Always Expanded
                AIPromptCard(
                    taskTitle: task.title,
                    contextNotes: contextNotes.isEmpty ? nil : contextNotes,
                    estimatedMinutes: task.estimatedMinutes,
                    priority: taskPriority,
                    previousLearnings: nil
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: appeared)

                // MARK: - Sub-Task Breakdown Card (NEW) - Claude Code Style
                SubTaskBreakdownCard(
                    subTasks: $subTasks,
                    taskTitle: task.title,
                    onSubTaskStatusChanged: { updatedSubTask in
                        updateSubTaskStatus(updatedSubTask)
                    },
                    onSubTaskAdded: { title in
                        addSubTask(title: title)
                    },
                    onSubTaskDeleted: { subtask in
                        deleteSubTask(subtask)
                    },
                    onSubTaskUpdated: { subtask in
                        updateSubTask(subtask)
                    },
                    onSubTasksReordered: { reordered in
                        subTasks = reordered
                    },
                    onRefresh: {
                        loadSubTasks()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: appeared)

                // MARK: - Recurring Section
                recurringCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.22), value: appeared)

                // MARK: - AI Thought Process Card (NEW) - Collapsible
                if !aiThoughtProcessText.isEmpty || !subTasks.isEmpty {
                    AIThoughtProcessCard(
                        thoughtProcess: aiThoughtProcessText,
                        subTasks: subTasks,
                        taskTitle: task.title,
                        estimatedMinutes: task.estimatedMinutes
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: appeared)
                }

                // MARK: - YouTube Learning Resources (NEW)
                YouTubeLearningCard(
                    resources: $youtubeResources,
                    taskTitle: task.title,
                    onRefresh: {
                        loadYouTubeResources()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: appeared)

                // MARK: - Smart Schedule Card (NEW)
                SmartScheduleCard(
                    suggestion: scheduleSuggestion,
                    estimatedMinutes: task.estimatedMinutes,
                    onAccept: { selectedDate in
                        onSchedule(selectedDate)
                    },
                    onShowAlternatives: { },
                    onRefresh: {
                        loadScheduleSuggestion()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.35), value: appeared)

                // Schedule card (existing)
                scheduleCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.4), value: appeared)

                // Actions card (existing)
                actionsCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.45), value: appeared)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.clear)
        .onAppear {
            HapticsService.shared.lightImpact()
            loadInitialData()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showThoughtProcess) {
            AIThoughtProcessSheet(
                task: task,
                thoughtProcess: task.aiThoughtProcess ?? "",
                subTasks: []
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSchedulePicker) {
            SchedulePickerSheet(
                currentDate: task.scheduledTime,
                onSchedule: { date in
                    onSchedule(date)
                    showSchedulePicker = false
                },
                onDismiss: {
                    showSchedulePicker = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingReflectionSheet) {
            ReflectionSheet(
                taskTitle: task.title,
                estimatedMinutes: task.estimatedMinutes,
                onSave: { reflection in
                    saveReflection(reflection)
                },
                onSkip: { }
            )
            .presentationDetents([.large])
        }
    }

    // MARK: - Title Card

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: 14) {
                // Checkbox
                Button(action: {
                    HapticsService.shared.impact()
                    onToggleComplete()
                }) {
                    ZStack {
                        SwiftUI.Circle()
                            .strokeBorder(
                                task.isCompleted ? Theme.Colors.success : Theme.Colors.textTertiary,
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if task.isCompleted {
                            SwiftUI.Circle()
                                .fill(Theme.Colors.success)
                                .frame(width: 28, height: 28)

                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Editable Title
                EditableTaskTitle(
                    title: $editableTitle,
                    onCommit: { newTitle in
                        task.title = newTitle
                        task.updatedAt = Date()
                    },
                    isCompleted: task.isCompleted
                )

                Spacer()
            }

            // Recurring badge if recurring
            if task.isRecurring {
                RecurringBadge(type: task.recurringExtended)
            }

            // Priority picker
            priorityPicker
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Priority Picker

    private var priorityPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Priority:")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textSecondary)

            ForEach([1, 2, 3], id: \.self) { stars in
                Button {
                    task.starRating = stars
                    task.updatedAt = Date()
                    HapticsService.shared.selectionFeedback()
                } label: {
                    Text(String(repeating: "★", count: stars))
                        .font(.system(size: 16))
                        .foregroundStyle(task.starRating == stars ? Theme.Colors.warning : Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Recurring Section Card

    private var recurringCard: some View {
        RecurringSection(
            selectedType: $recurringType,
            customDays: $recurringCustomDays,
            endDate: $recurringEndDate,
            onChanged: {
                task.setRecurringExtended(
                    type: recurringType,
                    customDays: recurringCustomDays.isEmpty ? nil : recurringCustomDays,
                    endDate: recurringEndDate
                )
            }
        )
    }

    // MARK: - AI Insight Card

    private var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.3))

                Text("AI Insight")
                    .font(Theme.Typography.subheadlineMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                // Refresh button
                Button {
                    refreshAI()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiBlue)
                        .rotationEffect(.degrees(refreshRotation))
                }
                .buttonStyle(.plain)
            }

            // AI Content
            if isRefreshingAI || task.aiAdvice == nil {
                // Processing state
                HStack(spacing: 8) {
                    CompactAIIndicator(isProcessing: true, size: 18)

                    Text("Analyzing your task...")
                        .font(Theme.Typography.aiWhisper)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, 8)
            } else if let advice = task.aiAdvice {
                // Advice text
                Text(advice)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Metadata pills
                HStack(spacing: 8) {
                    if let minutes = task.estimatedMinutes {
                        MetadataPill(
                            icon: "clock.fill",
                            text: task.estimatedTimeFormatted ?? "\(minutes)m",
                            color: Theme.Colors.aiBlue
                        )
                    }

                    if let priority = task.aiPriority {
                        MetadataPill(
                            icon: priorityIcon(for: priority),
                            text: priority.capitalized,
                            color: priorityColor(for: priority)
                        )
                    }

                    if task.scheduledTime != nil {
                        MetadataPill(
                            icon: "calendar",
                            text: task.scheduledDateFormatted ?? "Scheduled",
                            color: Theme.Colors.accent
                        )
                    }
                }

                // Sources (if available)
                if let sources = task.aiSources, !sources.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sources")
                            .font(Theme.Typography.caption1Medium)
                            .foregroundStyle(Theme.Colors.textTertiary)

                        ForEach(sources, id: \.self) { source in
                            Text(source)
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Colors.aiBlue)
                        }
                    }
                }

                // Thought process button
                if task.aiThoughtProcess != nil {
                    Button {
                        showThoughtProcess = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "brain")
                                .font(.system(size: 12))

                            Text("How AI arrived at this advice")
                                .font(Theme.Typography.caption1)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.top, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .glassCard(tint: Theme.Colors.aiPurple.opacity(0.05))
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)

                Text("Schedule")
                    .font(Theme.Typography.subheadlineMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()
            }

            if task.scheduledTime != nil {
                // Show scheduled info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.scheduledDateFormatted ?? "")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        if let time = task.scheduledTimeFormatted {
                            Text(time)
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }

                    Spacer()

                    Button("Change") {
                        showSchedulePicker = true
                    }
                    .font(Theme.Typography.caption1Medium)
                    .foregroundStyle(Theme.Colors.accent)
                }
            } else {
                // Add to calendar button
                Button {
                    showSchedulePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))

                        Text("Add to Calendar")
                            .font(Theme.Typography.subheadline)
                    }
                    .foregroundStyle(Theme.Colors.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        HStack(spacing: 0) {
            ActionButton(
                icon: "doc.on.doc",
                title: "Duplicate",
                action: onDuplicate
            )

            Divider()
                .frame(height: 40)

            ActionButton(
                icon: "clock.arrow.circlepath",
                title: "Snooze",
                action: onSnooze
            )

            Divider()
                .frame(height: 40)

            ActionButton(
                icon: "trash",
                title: "Delete",
                color: Theme.Colors.destructive,
                action: {
                    HapticsService.shared.warning()
                    onDelete()
                }
            )
        }
        .padding(.vertical, 4)
        .glassCard()
    }

    // MARK: - Helpers

    private func refreshAI() {
        isRefreshingAI = true
        HapticsService.shared.softImpact()

        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            refreshRotation = 360
        }

        onReprocessAI()

        // Simulate completion (actual completion should be handled by view model)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isRefreshingAI = false
                refreshRotation = 0
            }
        }
    }

    private func priorityIcon(for priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "minus.circle.fill"
        case "low": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }

    private func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return Theme.Colors.destructive
        case "medium": return Theme.Colors.warning
        case "low": return Theme.Colors.success
        default: return Theme.Colors.textTertiary
        }
    }

    // MARK: - Cognitive Productivity Methods

    private func loadInitialData() {
        // Initialize editing states from task
        editableTitle = task.title
        recurringType = task.recurringExtended
        if let days = task.recurringDays {
            recurringCustomDays = Set(days)
        }
        recurringEndDate = task.recurringEndDate
        contextNotes = task.contextNotes ?? ""

        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await loadSubTasks() }
                group.addTask { await loadYouTubeResources() }
                group.addTask { await loadScheduleSuggestion() }
            }
        }
    }

    private func regenerateAIContent() {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            loadSubTasks()
        }
    }

    @MainActor
    private func loadSubTasks() {
        // Call PerplexityService for AI-powered task breakdown
        Task {
            do {
                guard PerplexityService.shared.isReady else {
                    // Fallback to mock data if Gemini not configured
                    generateFallbackSubTasks()
                    return
                }

                let analysis = try await PerplexityService.shared.generateGeniusAnalysis(
                    title: task.title,
                    notes: task.contextNotes,
                    context: nil,
                    userPatterns: nil
                )

                // Convert execution steps to SubTasks
                subTasks = analysis.executionSteps.map { step in
                    SubTask(
                        title: step.description,
                        estimatedMinutes: step.estimatedMinutes,
                        status: step.isCompleted ? .completed : .pending,
                        orderIndex: step.orderIndex,
                        aiReasoning: nil,
                        taskId: task.id
                    )
                }

                // Set thought process from mentor advice
                aiThoughtProcessText = analysis.mentorAdvice.mainAdvice

                // Save to Supabase
                await saveSubTasksToSupabase()

            } catch {
                print("PerplexityService error: \(error.localizedDescription)")
                generateFallbackSubTasks()
            }
        }
    }

    private func generateFallbackSubTasks() {
        let taskWords = task.title.lowercased()

        if taskWords.contains("report") || taskWords.contains("presentation") {
            subTasks = [
                SubTask(title: "Research and gather data", estimatedMinutes: 15, status: .pending, orderIndex: 1, aiReasoning: "Start with data collection to inform content", taskId: task.id),
                SubTask(title: "Create outline/structure", estimatedMinutes: 10, status: .pending, orderIndex: 2, aiReasoning: "Structure before detailed content", taskId: task.id),
                SubTask(title: "Write main content", estimatedMinutes: 25, status: .pending, orderIndex: 3, taskId: task.id),
                SubTask(title: "Add visuals/formatting", estimatedMinutes: 15, status: .pending, orderIndex: 4, taskId: task.id),
                SubTask(title: "Review and polish", estimatedMinutes: 10, status: .pending, orderIndex: 5, taskId: task.id)
            ]
            aiThoughtProcessText = "Recognized this as a document creation task. Structured breakdown follows best practices: research → outline → content → visuals → review."
        } else if taskWords.contains("meeting") || taskWords.contains("call") {
            subTasks = [
                SubTask(title: "Prepare agenda points", estimatedMinutes: 10, status: .pending, orderIndex: 1, aiReasoning: "Clear agenda ensures productive meeting", taskId: task.id),
                SubTask(title: "Gather relevant materials", estimatedMinutes: 10, status: .pending, orderIndex: 2, taskId: task.id),
                SubTask(title: "Send calendar invite/reminder", estimatedMinutes: 5, status: .pending, orderIndex: 3, taskId: task.id),
                SubTask(title: "Conduct meeting", estimatedMinutes: 30, status: .pending, orderIndex: 4, taskId: task.id)
            ]
            aiThoughtProcessText = "Identified as a meeting task. Breaking into preparation and execution phases for maximum effectiveness."
        } else {
            subTasks = [
                SubTask(title: "Define clear objectives", estimatedMinutes: 5, status: .pending, orderIndex: 1, aiReasoning: "Clarity on goals improves focus", taskId: task.id),
                SubTask(title: "Break into actionable steps", estimatedMinutes: 10, status: .pending, orderIndex: 2, taskId: task.id),
                SubTask(title: "Execute main work", estimatedMinutes: 20, status: .pending, orderIndex: 3, taskId: task.id),
                SubTask(title: "Review and complete", estimatedMinutes: 10, status: .pending, orderIndex: 4, taskId: task.id)
            ]
            aiThoughtProcessText = "Created a general task breakdown following the define → plan → execute → review pattern."
        }
    }

    @MainActor
    private func loadYouTubeResources() {
        // YouTube resources are loaded from GeniusTaskAnalysis in loadSubTasks
        // The AI provides TaskResource objects which we convert to YouTubeResource
        Task {
            do {
                guard PerplexityService.shared.isReady else {
                    youtubeResources = []
                    return
                }

                let analysis = try await PerplexityService.shared.generateGeniusAnalysis(
                    title: task.title,
                    notes: task.contextNotes,
                    context: nil,
                    userPatterns: nil
                )

                // Convert TaskResource to YouTubeResource for youtube types
                youtubeResources = analysis.resources
                    .filter { $0.type == .youtube }
                    .map { resource in
                        YouTubeResource(
                            videoId: extractYouTubeId(from: resource.url) ?? "",
                            title: resource.title,
                            channelName: resource.source,
                            durationSeconds: parseDuration(resource.duration),
                            viewCount: nil,
                            thumbnailURL: nil,
                            relevanceScore: nil,
                            taskId: task.id
                        )
                    }

                // Save to Supabase
                await saveYouTubeResourcesToSupabase()

            } catch {
                print("Failed to load YouTube resources: \(error.localizedDescription)")
                youtubeResources = []
            }
        }
    }

    private func extractYouTubeId(from url: String) -> String? {
        // Extract video ID from YouTube URL
        if let range = url.range(of: "v=") {
            let startIndex = range.upperBound
            let endIndex = url[startIndex...].firstIndex(of: "&") ?? url.endIndex
            return String(url[startIndex..<endIndex])
        }
        if url.contains("youtu.be/") {
            return url.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        }
        return nil
    }

    private func parseDuration(_ duration: String?) -> Int? {
        guard let duration else { return nil }
        // Parse "8 min" format to seconds
        let components = duration.lowercased().components(separatedBy: " ")
        if let minutes = Int(components.first ?? "") {
            return minutes * 60
        }
        return nil
    }

    @MainActor
    private func loadScheduleSuggestion() {
        Task {
            do {
                guard PerplexityService.shared.isReady else {
                    // Use default suggestion
                    setDefaultScheduleSuggestion()
                    return
                }

                let suggestions = try await PerplexityService.shared.generateScheduleSuggestions(
                    task: task,
                    calendar: [],
                    userPatterns: nil
                )

                if let best = suggestions.first {
                    scheduleSuggestion = ScheduleSuggestion(
                        suggestedTime: best.date,
                        reason: best.reason,
                        confidence: best.rank == .best ? 0.9 : (best.rank == .good ? 0.75 : 0.6),
                        alternativeTimes: suggestions.dropFirst().prefix(2).map { $0.date },
                        conflictingEvents: nil
                    )

                    // Save to task
                    await saveScheduleToSupabase()
                } else {
                    setDefaultScheduleSuggestion()
                }

            } catch {
                print("Failed to load schedule suggestion: \(error.localizedDescription)")
                setDefaultScheduleSuggestion()
            }
        }
    }

    private func setDefaultScheduleSuggestion() {
        let tomorrow9am = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow9am)
        var ninAM = DateComponents()
        ninAM.year = components.year
        ninAM.month = components.month
        ninAM.day = components.day
        ninAM.hour = 9
        ninAM.minute = 0

        if let suggestedDate = Calendar.current.date(from: ninAM) {
            scheduleSuggestion = ScheduleSuggestion(
                suggestedTime: suggestedDate,
                reason: "Your calendar is free and you tend to be most productive in the morning.",
                confidence: 0.85,
                alternativeTimes: nil,
                conflictingEvents: nil
            )
        }
    }

    private func updateSubTaskStatus(_ updatedSubTask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == updatedSubTask.id }) {
            subTasks[index] = updatedSubTask
            Task { await saveSubTaskToSupabase(updatedSubTask) }
        }
    }

    private func addSubTask(title: String) {
        let newSubTask = SubTask(
            title: title,
            estimatedMinutes: nil,
            status: .pending,
            orderIndex: subTasks.count + 1,
            aiReasoning: nil,
            taskId: task.id
        )
        subTasks.append(newSubTask)
        Task { await saveSubTaskToSupabase(newSubTask) }
    }

    private func deleteSubTask(_ subtask: SubTask) {
        subTasks.removeAll { $0.id == subtask.id }
        // Reorder remaining tasks
        for (index, _) in subTasks.enumerated() {
            subTasks[index].orderIndex = index + 1
        }
        Task { await deleteSubTaskFromSupabase(subtask) }
    }

    private func updateSubTask(_ subtask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == subtask.id }) {
            subTasks[index] = subtask
            Task { await saveSubTaskToSupabase(subtask) }
        }
    }

    private func saveReflection(_ reflection: TaskReflection) {
        Task { await saveReflectionToSupabase(reflection) }
    }

    // MARK: - Supabase Persistence

    private func saveSubTasksToSupabase() async {
        guard !subTasks.isEmpty else { return }

        do {
            // Delete existing subtasks for this task
            try await SupabaseService.shared.supabase
                .from("sub_tasks")
                .delete()
                .eq("task_id", value: task.id.uuidString)
                .execute()

            // Insert all subtasks
            let subtasksWithTaskId = subTasks.map { subtask -> SubTask in
                var copy = subtask
                copy.taskId = task.id
                return copy
            }
            try await SupabaseService.shared.supabase
                .from("sub_tasks")
                .insert(subtasksWithTaskId)
                .execute()

            print("Saved \(subTasks.count) subtasks to Supabase")
        } catch {
            print("Failed to save subtasks to Supabase: \(error.localizedDescription)")
        }
    }

    private func saveSubTaskToSupabase(_ subtask: SubTask) async {
        do {
            var subtaskToSave = subtask
            subtaskToSave.taskId = task.id

            try await SupabaseService.shared.supabase
                .from("sub_tasks")
                .upsert(subtaskToSave)
                .execute()
        } catch {
            print("Failed to save subtask to Supabase: \(error.localizedDescription)")
        }
    }

    private func deleteSubTaskFromSupabase(_ subtask: SubTask) async {
        do {
            try await SupabaseService.shared.supabase
                .from("sub_tasks")
                .delete()
                .eq("id", value: subtask.id.uuidString)
                .execute()
        } catch {
            print("Failed to delete subtask from Supabase: \(error.localizedDescription)")
        }
    }

    private func saveYouTubeResourcesToSupabase() async {
        guard !youtubeResources.isEmpty else { return }

        do {
            // Delete existing resources for this task
            try await SupabaseService.shared.supabase
                .from("task_youtube_resources")
                .delete()
                .eq("task_id", value: task.id.uuidString)
                .execute()

            // Insert new resources
            let resourcesToSave = youtubeResources.map { resource -> YouTubeResource in
                var copy = resource
                copy.taskId = task.id
                return copy
            }
            try await SupabaseService.shared.supabase
                .from("task_youtube_resources")
                .insert(resourcesToSave)
                .execute()

            print("Saved \(youtubeResources.count) YouTube resources to Supabase")
        } catch {
            print("Failed to save YouTube resources to Supabase: \(error.localizedDescription)")
        }
    }

    private func saveScheduleToSupabase() async {
        guard let suggestion = scheduleSuggestion else { return }

        do {
            // Encode schedule suggestion as JSON
            let encoder = JSONEncoder()
            let scheduleData = try encoder.encode(suggestion)

            try await SupabaseService.shared.supabase
                .from("tasks")
                .update(["schedule_suggestion": scheduleData])
                .eq("id", value: task.id.uuidString)
                .execute()

            print("Saved schedule suggestion to task")
        } catch {
            print("Failed to save schedule suggestion: \(error.localizedDescription)")
        }
    }

    private func saveReflectionToSupabase(_ reflection: TaskReflection) async {
        guard let userId = SupabaseService.shared.currentUserId else {
            print("No user logged in")
            return
        }

        do {
            // Create reflection with user ID
            let reflectionToSave = TaskReflection(
                id: UUID(),
                taskId: task.id,
                userId: userId,
                difficultyRating: reflection.difficultyRating,
                wasEstimateAccurate: reflection.wasEstimateAccurate,
                learnings: reflection.learnings,
                tipsForNext: reflection.tipsForNext,
                actualMinutes: reflection.actualMinutes,
                createdAt: Date()
            )

            try await SupabaseService.shared.supabase
                .from("task_reflections")
                .insert(reflectionToSave)
                .execute()

            // Update user productivity patterns
            await updateUserPatterns(reflection: reflection)

            print("Saved reflection to Supabase")
        } catch {
            print("Failed to save reflection: \(error.localizedDescription)")
        }
    }

    private func updateUserPatterns(reflection: TaskReflection) async {
        guard let userId = SupabaseService.shared.currentUserId else { return }

        do {
            // Check if patterns exist for this user
            let existing: [UserProductivityProfile] = try await SupabaseService.shared.supabase
                .from("user_productivity_patterns")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            if let patterns = existing.first {
                // Update existing patterns
                var updatedPatterns = patterns
                updatedPatterns.completedTaskCount = patterns.completedTaskCount + 1
                updatedPatterns.updatedAt = Date()

                // Update AI accuracy if estimate existed
                if let estimated = task.estimatedMinutes,
                   let actual = reflection.actualMinutes {
                    let accuracy = 1.0 - abs(Double(estimated - actual) / Double(estimated))
                    let currentScore = patterns.aiAccuracyScore ?? 0.5
                    updatedPatterns.aiAccuracyScore = (currentScore + accuracy) / 2.0
                }

                try await SupabaseService.shared.supabase
                    .from("user_productivity_patterns")
                    .update(updatedPatterns)
                    .eq("user_id", value: userId.uuidString)
                    .execute()
            } else {
                // Create new patterns
                let newPatterns = UserProductivityProfile(
                    id: UUID(),
                    userId: userId,
                    energyPatterns: nil,
                    aiAccuracyScore: nil,
                    completedTaskCount: 1,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                try await SupabaseService.shared.supabase
                    .from("user_productivity_patterns")
                    .insert(newPatterns)
                    .execute()
            }
        } catch {
            print("Failed to update user patterns: \(error.localizedDescription)")
        }
    }

    private func triggerReflection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingReflectionSheet = true
        }
    }
}

// MARK: - Supporting Components

struct MetadataPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))

            Text(text)
                .font(Theme.Typography.caption1Medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    var color: Color = Theme.Colors.textPrimary
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))

                Text(title)
                    .font(Theme.Typography.caption1)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isPressed ? color.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Glass Card Modifier

extension View {
    /// 🌟 LIQUID GLASS: Premium glass card with interactive effect and optional tint
    func glassCard(tint: Color? = nil) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .if(tint != nil) { view in
                        view.overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(tint!)
                        )
                    }
            }
            .glassEffect(
                .regular
                    .interactive(true),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

// Conditional modifier helper
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Schedule Picker Sheet

struct SchedulePickerSheet: View {
    let currentDate: Date?
    let onSchedule: (Date) -> Void
    let onDismiss: () -> Void

    @State private var selectedDate: Date

    init(
        currentDate: Date?,
        onSchedule: @escaping (Date) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.currentDate = currentDate
        self.onSchedule = onSchedule
        self.onDismiss = onDismiss
        self._selectedDate = State(initialValue: currentDate ?? Date())
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Text("Schedule Task")
                    .font(Theme.Typography.headline)

                Spacer()

                Button("Done") {
                    onSchedule(selectedDate)
                }
                .foregroundStyle(Theme.Colors.accent)
                .fontWeight(.semibold)
            }
            .padding(.top, 8)

            // Quick options
            HStack(spacing: 12) {
                QuickDateButton(title: "Today", date: Date()) { date in
                    selectedDate = date
                }

                QuickDateButton(title: "Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) { date in
                    selectedDate = date
                }

                QuickDateButton(title: "Next Week", date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!) { date in
                    selectedDate = date
                }
            }

            // Date picker
            DatePicker(
                "Select date and time",
                selection: $selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .tint(Theme.Colors.accent)

            Spacer()
        }
        .padding(20)
    }
}

struct QuickDateButton: View {
    let title: String
    let date: Date
    let onSelect: (Date) -> Void

    var body: some View {
        Button {
            onSelect(date)
        } label: {
            Text(title)
                .font(Theme.Typography.caption1Medium)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Theme.Colors.cardBackground)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Detail Sheet Wrapper

/// Wrapper view for TaskDetailContentView that accepts a TasksViewModel
struct TaskDetailSheet: View {
    let task: TaskItem
    @Bindable var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TaskDetailContentView(
            task: task,
            onToggleComplete: {
                viewModel.toggleCompletion(task)
            },
            onReprocessAI: {
                viewModel.reprocessAI(for: task)
            },
            onSchedule: { date in
                task.scheduledTime = date
                task.updatedAt = Date()
            },
            onDuplicate: {
                viewModel.duplicateTask(task)
            },
            onSnooze: {
                viewModel.snoozeTask(task)
            },
            onDelete: {
                viewModel.deleteTask(task)
                dismiss()
            },
            onDismiss: {
                dismiss()
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

// MARK: - Preview

#Preview("Task Detail Content View") {
    struct PreviewWrapper: View {
        let task: TaskItem = {
            let t = TaskItem(title: "Finish presentation slides for quarterly review")
            t.aiAdvice = "Break this into 3 sections: intro (5 min), main points (15 min), conclusion (5 min). Use the company template for consistency. Consider adding data visualizations for impact."
            t.estimatedMinutes = 45
            t.aiPriority = "high"
            t.aiThoughtProcess = "Analyzed the task title for key components. Identified this as a professional presentation task. Retrieved best practices for effective slide creation."
            return t
        }()

        var body: some View {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    TaskDetailContentView(
                        task: task,
                        onToggleComplete: {},
                        onReprocessAI: {},
                        onSchedule: { _ in },
                        onDuplicate: {},
                        onSnooze: {},
                        onDelete: {},
                        onDismiss: {}
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                }
        }
    }

    return PreviewWrapper()
}
