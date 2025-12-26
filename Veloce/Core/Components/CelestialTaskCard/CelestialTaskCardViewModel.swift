//
//  CelestialTaskCardViewModel.swift
//  Veloce
//
//  Consolidated ViewModel for the unified CelestialTaskCard
//  Merges state from GeniusSheetViewModel, TaskDetailSheet, and PremiumTaskDetailView
//

import Foundation
import SwiftUI
import SwiftData
import Supabase

// MARK: - Card Section Enum

enum CelestialCardSection: String, CaseIterable, Hashable {
    case taskDetails = "Task Details"
    case aiGenius = "AI Genius"
    case schedule = "Schedule"
    case focus = "Focus"

    var icon: String {
        switch self {
        case .taskDetails: return "list.bullet.clipboard"
        case .aiGenius: return "sparkles"
        case .schedule: return "calendar"
        case .focus: return "scope"
        }
    }

    var accentColor: Color {
        switch self {
        case .taskDetails: return Theme.Colors.accent
        case .aiGenius: return Theme.Colors.aiPurple
        case .schedule: return Theme.TaskCardColors.schedule
        case .focus: return Theme.TaskCardColors.workMode
        }
    }
}

// MARK: - Celestial Task Card ViewModel

@MainActor
@Observable
final class CelestialTaskCardViewModel {

    // MARK: - Task Reference

    let task: TaskItem

    // MARK: - Editing State

    var editedTitle: String
    var editedContextNotes: String
    var editedDuration: Int?
    var editedScheduledTime: Date?
    var editedRecurringType: RecurringTypeExtended
    var editedRecurringDays: Set<Int>
    var editedRecurringEndDate: Date?
    var editedPriority: Int

    // MARK: - Sub-Tasks (Supabase Persisted)

    var subTasks: [SubTask] = []
    var isLoadingSubTasks: Bool = false

    // MARK: - AI Genius Module State (from GeniusSheetViewModel)

    // Emotional Check-In
    var selectedEmotion: Emotion?
    var emotionResponse: String?
    var showEmotionalCheckIn: Bool = false

    // Start Here (Micro-Challenge)
    var firstStepTitle: String = "Open and write just the first line"
    var firstStepSeconds: Int = 30
    var isChallengeActive: Bool = false
    var countdown: Int = 30
    var challengeCompleted: Bool = false

    // AI Strategy
    var aiStrategy: String?
    var strategySource: String?
    var isStrategyExpanded: Bool = false
    var isStrategyLoading: Bool = false

    // AI Resources
    var aiResources: [TaskResource] = []

    // Work Mode
    var suggestedWorkMode: WorkMode = .deepWork
    var workModeReason: String = ""
    var selectedWorkMode: WorkMode?
    var isTimerActive: Bool = false

    // AI Chat
    var chatInput: String = ""
    var chatMessages: [CelestialChatMessage] = []
    var isAIThinking: Bool = false

    // MARK: - Schedule State

    var scheduleSuggestions: [GeniusScheduleSuggestion] = []
    var userPeakHours: String = "9-11 AM"
    var isLoadingSchedule: Bool = false

    // MARK: - YouTube Resources

    var youtubeResources: [YouTubeResource] = []
    var isLoadingYouTube: Bool = false

    // MARK: - AI Thought Process

    var aiThoughtProcessText: String = ""

    // MARK: - Celestial AI Strategy (Rich Model)

    var celestialStrategy: CelestialAIStrategy?
    var strategyError: String?

    // MARK: - YouTube Search Resources (Deep-links)

    var youtubeSearchResources: [YouTubeSearchResource] = []

    // MARK: - AI Duration Estimation

    var aiEstimatedDuration: Int?
    var durationConfidence: String?
    var durationReasoning: String?

    // MARK: - UI State

    var hasUnsavedChanges: Bool = false
    var isInitialLoadComplete: Bool = false

    // MARK: - App Blocking State

    var enableAppBlocking: Bool

    // MARK: - Sheet States

    var showFocusMode: Bool = false
    var showCalendarScheduling: Bool = false
    var showSchedulePicker: Bool = false
    var showReflectionSheet: Bool = false

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let supabase = SupabaseService.shared
    private let haptics = HapticsService.shared

    // MARK: - Computed Properties

    var showEmotionalCheckInModule: Bool {
        (task.timesRescheduled ?? 0) >= 2 || task.emotionalBlocker != nil
    }

    var taskTypeColor: Color {
        switch task.taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    var formattedDuration: String? {
        guard let minutes = editedDuration ?? task.estimatedMinutes else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    var subTaskProgress: Double {
        subTasks.progress
    }

    var subTaskProgressString: String {
        subTasks.progressString
    }

    // MARK: - Initialization

    init(task: TaskItem) {
        self.task = task

        // Initialize editing states from task
        self.editedTitle = task.title
        self.editedContextNotes = task.contextNotes ?? ""
        self.editedDuration = task.duration ?? task.estimatedMinutes
        self.editedScheduledTime = task.scheduledTime
        self.editedRecurringType = task.recurringExtended
        self.editedRecurringDays = Set(task.recurringDays ?? [])
        self.editedRecurringEndDate = task.recurringEndDate
        self.editedPriority = task.starRating

        // Initialize AI state from task
        self.aiStrategy = task.aiAdvice ?? task.aiThoughtProcess
        self.aiThoughtProcessText = task.aiThoughtProcess ?? ""

        // Set emotional check-in flag
        self.showEmotionalCheckIn = (task.timesRescheduled ?? 0) >= 2

        // Initialize app blocking state
        self.enableAppBlocking = task.enableAppBlocking

        // Set work mode recommendation based on task type
        configureWorkModeRecommendation()
    }

    // MARK: - Setup

    func setup(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Load All Data

    func loadAllData() async {
        guard !isInitialLoadComplete else { return }

        // Load all data in parallel for performance
        async let subTasksLoad: () = loadSubTasks()
        async let youtubeLoad: () = loadYouTubeResources()
        async let scheduleLoad: () = loadScheduleSuggestions()
        async let strategyLoad: () = loadAIStrategy()
        async let durationLoad: () = loadAIDurationEstimate()

        _ = await (subTasksLoad, youtubeLoad, scheduleLoad, strategyLoad, durationLoad)

        isInitialLoadComplete = true
    }

    // MARK: - Sub-Tasks

    func loadSubTasks() async {
        isLoadingSubTasks = true
        defer { isLoadingSubTasks = false }

        do {
            // Try loading from Supabase first
            let loaded: [SubTask] = try await supabase.supabase
                .from("sub_tasks")
                .select()
                .eq("task_id", value: task.id.uuidString)
                .order("order_index")
                .execute()
                .value

            if !loaded.isEmpty {
                subTasks = loaded
            } else {
                // Generate fallback sub-tasks
                generateFallbackSubTasks()
            }
        } catch {
            print("Failed to load sub-tasks: \(error.localizedDescription)")
            generateFallbackSubTasks()
        }
    }

    private func generateFallbackSubTasks() {
        let taskWords = task.title.lowercased()

        if taskWords.contains("report") || taskWords.contains("presentation") || taskWords.contains("document") {
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
            aiThoughtProcessText = "Identified as a meeting task. Breaking into preparation and execution phases."
        } else if taskWords.contains("email") || taskWords.contains("reply") || taskWords.contains("respond") {
            subTasks = [
                SubTask(title: "Review context/thread", estimatedMinutes: 5, status: .pending, orderIndex: 1, taskId: task.id),
                SubTask(title: "Draft response", estimatedMinutes: 10, status: .pending, orderIndex: 2, taskId: task.id),
                SubTask(title: "Proofread and send", estimatedMinutes: 5, status: .pending, orderIndex: 3, taskId: task.id)
            ]
            aiThoughtProcessText = "Communication task identified. Simple three-step flow: review → draft → send."
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

    func toggleSubTask(_ subtask: SubTask) {
        guard let index = subTasks.firstIndex(where: { $0.id == subtask.id }) else { return }

        var updated = subTasks[index]
        updated.status = updated.status == .completed ? .pending : .completed
        updated.completedAt = updated.status == .completed ? Date() : nil
        subTasks[index] = updated

        haptics.selectionFeedback()

        Task { await saveSubTaskToSupabase(updated) }
    }

    func addSubTask(title: String) {
        let newSubTask = SubTask(
            title: title,
            estimatedMinutes: nil,
            status: .pending,
            orderIndex: subTasks.count + 1,
            taskId: task.id
        )
        subTasks.append(newSubTask)
        Task { await saveSubTaskToSupabase(newSubTask) }
    }

    func deleteSubTask(_ subtask: SubTask) {
        subTasks.removeAll { $0.id == subtask.id }
        // Reorder remaining
        for (index, _) in subTasks.enumerated() {
            subTasks[index].orderIndex = index + 1
        }
        Task { await deleteSubTaskFromSupabase(subtask) }
    }

    // MARK: - YouTube Resources

    func loadYouTubeResources() async {
        let cache = AIResponseCache.shared

        // Check cache first
        if let cached = cache.getYouTubeSearches(for: task.id) {
            youtubeSearchResources = cached
            return
        }

        guard !isLoadingYouTube else { return }
        isLoadingYouTube = true
        defer { isLoadingYouTube = false }

        do {
            // Try generating via Perplexity
            let perplexity = PerplexityService.shared
            guard perplexity.isReady else {
                youtubeSearchResources = YouTubeSearchResource.fallbacks(for: task.title, taskId: task.id)
                return
            }

            let searches = try await perplexity.generateYouTubeSearchQueries(
                taskTitle: task.title,
                context: task.contextNotes,
                maxQueries: 3
            )

            youtubeSearchResources = searches
            cache.setYouTubeSearches(searches, for: task.id)

        } catch {
            print("Failed to generate YouTube searches: \(error.localizedDescription)")
            youtubeSearchResources = YouTubeSearchResource.fallbacks(for: task.title, taskId: task.id)
        }

        // Also try loading existing resources from Supabase (legacy)
        do {
            let loaded: [YouTubeResource] = try await supabase.supabase
                .from("task_youtube_resources")
                .select()
                .eq("task_id", value: task.id.uuidString)
                .execute()
                .value
            youtubeResources = loaded
        } catch {
            youtubeResources = []
        }
    }

    // MARK: - Schedule Suggestions

    func loadScheduleSuggestions() async {
        isLoadingSchedule = true
        defer { isLoadingSchedule = false }

        // Default suggestion: tomorrow at 9 AM
        let tomorrow9am = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow9am)
        components.hour = 9
        components.minute = 0

        if let suggestedDate = Calendar.current.date(from: components) {
            scheduleSuggestions = [
                GeniusScheduleSuggestion(
                    rank: .best,
                    date: suggestedDate,
                    reason: "Your calendar is free and you're typically most productive in the morning."
                )
            ]
        }
    }

    // MARK: - AI Strategy

    func loadAIStrategy() async {
        let cache = AIResponseCache.shared

        // Check cache first
        if let cached = cache.getStrategy(for: task.id) {
            celestialStrategy = cached
            aiStrategy = cached.formattedStrategy
            strategySource = "AI Genius"

            // Also update duration if available
            if let minutes = cached.estimatedMinutes {
                aiEstimatedDuration = minutes
            }
            return
        }

        guard !isStrategyLoading else { return }
        isStrategyLoading = true
        strategyError = nil
        defer { isStrategyLoading = false }

        do {
            let perplexity = PerplexityService.shared
            guard perplexity.isReady else {
                // Use fallback strategy
                let fallback = CelestialAIStrategy.fallback(for: task)
                celestialStrategy = fallback
                aiStrategy = fallback.formattedStrategy
                strategySource = "Offline Analysis"
                aiEstimatedDuration = fallback.estimatedMinutes
                return
            }

            let strategy = try await perplexity.generateCelestialStrategy(task: task)
            celestialStrategy = strategy
            aiStrategy = strategy.formattedStrategy
            strategySource = "AI Genius"

            // Update task's estimated minutes if we got one
            if let estimatedMinutes = strategy.estimatedMinutes {
                aiEstimatedDuration = estimatedMinutes
            }

            // Cache the result
            cache.setStrategy(strategy, for: task.id)

            // Persist AI advice to task
            task.aiAdvice = strategy.overview
            task.aiThoughtProcess = strategy.thoughtProcess

        } catch {
            strategyError = error.localizedDescription

            // Use fallback strategy
            let fallback = CelestialAIStrategy.fallback(for: task)
            celestialStrategy = fallback
            aiStrategy = fallback.formattedStrategy
            strategySource = "Offline Analysis"
            aiEstimatedDuration = fallback.estimatedMinutes
        }
    }

    func refreshAIStrategy() async {
        // Invalidate cache
        AIResponseCache.shared.invalidate(taskId: task.id)
        celestialStrategy = nil
        aiStrategy = nil

        // Reload
        await loadAIStrategy()
        haptics.softImpact()
    }

    // MARK: - AI Duration Estimation

    func loadAIDurationEstimate() async {
        // Skip if already have duration from strategy
        guard aiEstimatedDuration == nil else { return }

        let cache = AIResponseCache.shared

        // Check cache
        if let cached = cache.getDuration(for: task.id) {
            aiEstimatedDuration = cached.minutes
            durationConfidence = cached.confidence
            durationReasoning = cached.reasoning
            return
        }

        do {
            let perplexity = PerplexityService.shared
            guard perplexity.isReady else {
                // Use task type default
                aiEstimatedDuration = task.taskType.suggestedDuration
                durationConfidence = "low"
                return
            }

            let estimate = try await perplexity.estimateDuration(task: task)
            aiEstimatedDuration = estimate.minutes
            durationConfidence = estimate.confidence
            durationReasoning = estimate.reasoning

            // Cache the result
            cache.setDuration(estimate.minutes, confidence: estimate.confidence, reasoning: estimate.reasoning, for: task.id)

            // Update task if no estimate exists
            if task.estimatedMinutes == nil {
                editedDuration = estimate.minutes
            }

        } catch {
            // Use task type default
            aiEstimatedDuration = task.taskType.suggestedDuration
            durationConfidence = "low"
        }
    }

    // MARK: - Emotional Check-In

    func selectEmotion(_ emotion: Emotion) {
        selectedEmotion = emotion

        switch emotion {
        case .anxious:
            emotionResponse = "I hear you. Anxiety often protects us from failure—but it can also hold us back. Let's shrink this down to something so tiny your brain won't see it as a threat."
        case .overwhelmed:
            emotionResponse = "When something feels too big, our brain protects us by avoiding it. That's completely normal. Let's break this into a 30-second action."
        case .unmotivated:
            emotionResponse = "Here's a secret: motivation comes AFTER starting, not before. You just need to do the tiniest thing to get momentum going."
        case .ready:
            emotionResponse = "Excellent! Let's channel that energy. Your first step is waiting for you below."
        }

        haptics.selectionFeedback()
    }

    // MARK: - Micro-Challenge

    private var challengeTask: Task<Void, Never>?

    func startMicroChallenge() {
        isChallengeActive = true
        countdown = firstStepSeconds

        // Use Task-based timer to avoid Swift 6 Sendable issues with Timer
        challengeTask = Task { [weak self] in
            while let self = self, self.countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }

                self.countdown -= 1

                // Haptic at 3, 2, 1
                if self.countdown <= 3 && self.countdown > 0 {
                    self.haptics.lightImpact()
                }
            }

            if let self = self, !Task.isCancelled {
                self.completeMicroChallenge()
            }
        }
    }

    func completeMicroChallenge() {
        challengeTask?.cancel()
        challengeTask = nil
        isChallengeActive = false
        challengeCompleted = true
        haptics.celebration()
    }

    // MARK: - AI Chat

    func sendChatMessage(_ message: String) async {
        guard !message.isEmpty else { return }

        // Add user message
        chatMessages.append(CelestialChatMessage(role: .user, content: message))
        chatInput = ""
        isAIThinking = true

        // Simulate AI response
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        isAIThinking = false
        chatMessages.append(CelestialChatMessage(
            role: .assistant,
            content: "Based on your task '\(task.title)', I'd suggest starting with the smallest possible action. Would you like me to break this down further?"
        ))
    }

    // MARK: - Work Mode Configuration

    private func configureWorkModeRecommendation() {
        if task.taskType == .create {
            suggestedWorkMode = .deepWork
            workModeReason = "Creative tasks need uninterrupted flow. Pomodoro breaks would fragment your thinking."
        } else {
            suggestedWorkMode = .pomodoro
            workModeReason = "This task is well-suited for focused sprints with short breaks."
        }
        selectedWorkMode = suggestedWorkMode
    }

    // MARK: - Task Actions

    func saveChanges() {
        task.title = editedTitle
        task.contextNotes = editedContextNotes.isEmpty ? nil : editedContextNotes
        task.duration = editedDuration
        task.scheduledTime = editedScheduledTime
        task.starRating = editedPriority
        task.setRecurringExtended(
            type: editedRecurringType,
            customDays: editedRecurringDays.isEmpty ? nil : editedRecurringDays,
            endDate: editedRecurringEndDate
        )
        task.enableAppBlocking = enableAppBlocking
        task.updatedAt = Date()

        hasUnsavedChanges = false

        // Save SwiftData context
        if let context = modelContext {
            try? context.save()
        }
    }

    func markTitleChanged(_ newTitle: String) {
        editedTitle = newTitle
        hasUnsavedChanges = editedTitle != task.title
    }

    func markContextChanged(_ newContext: String) {
        editedContextNotes = newContext
        hasUnsavedChanges = editedContextNotes != (task.contextNotes ?? "")
    }

    // MARK: - Supabase Persistence

    private func saveSubTaskToSupabase(_ subtask: SubTask) async {
        do {
            var subtaskToSave = subtask
            subtaskToSave.taskId = task.id

            try await supabase.supabase
                .from("sub_tasks")
                .upsert(subtaskToSave)
                .execute()
        } catch {
            print("Failed to save subtask: \(error.localizedDescription)")
        }
    }

    private func deleteSubTaskFromSupabase(_ subtask: SubTask) async {
        do {
            try await supabase.supabase
                .from("sub_tasks")
                .delete()
                .eq("id", value: subtask.id.uuidString)
                .execute()
        } catch {
            print("Failed to delete subtask: \(error.localizedDescription)")
        }
    }

    // MARK: - SubTask Title Update

    func updateSubTaskTitle(_ subtask: SubTask, newTitle: String) {
        guard let index = subTasks.firstIndex(where: { $0.id == subtask.id }) else { return }

        var updated = subTasks[index]
        updated.title = newTitle
        subTasks[index] = updated

        haptics.selectionFeedback()

        Task { await saveSubTaskToSupabase(updated) }
    }

    // MARK: - Cleanup

    func cleanup() {
        challengeTask?.cancel()
        challengeTask = nil
    }
}

// MARK: - Chat Message Model

struct CelestialChatMessage: Identifiable {
    let id = UUID()
    let role: CelestialChatRole
    let content: String

    enum CelestialChatRole {
        case user
        case assistant
    }
}

// Note: GeniusScheduleSuggestion and ScheduleRank are defined in TaskType.swift
