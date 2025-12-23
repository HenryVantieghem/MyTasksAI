//
//  TaskDetailSheetIntegration.swift
//  Veloce
//
//  DEPRECATED: This file is a legacy integration guide.
//  All features are now implemented in TaskDetailSheet.swift
//
//  See TaskDetailSheet.swift for the actual implementation:
//  - loadSubTasks() - GeminiService AI breakdown + Supabase persistence
//  - loadYouTubeResources() - GeminiService YouTube search + Supabase persistence
//  - loadScheduleSuggestion() - GeminiService scheduling + Supabase persistence
//  - saveReflectionToSupabase() - Task reflection persistence
//  - updateUserPatterns() - User productivity patterns tracking
//

import SwiftUI

// MARK: - ============================================
// MARK: - STEP 1: Add these @State properties to TaskDetailSheet
// MARK: - ============================================

/*
 Add these properties alongside your existing @State variables:

 // AI Enhancement States
 @State private var contextNotes: String = ""
 @State private var subTasks: [SubTask] = []
 @State private var youtubeResources: [YouTubeResource] = []
 @State private var scheduleSuggestion: ScheduleSuggestion?
 @State private var aiThoughtProcess: String = ""

 // Sheet States
 @State private var showingReflectionSheet: Bool = false
 @State private var showingBrainDumpSheet: Bool = false

 // Loading States
 @State private var isLoadingSubTasks: Bool = false
 @State private var isLoadingYouTube: Bool = false
 @State private var isLoadingSchedule: Bool = false

 // Get priority from task (default to medium)
 private var taskPriority: TaskPriority {
     TaskPriority(rawValue: task.starRating ?? 2) ?? .medium
 }
*/

// MARK: - ============================================
// MARK: - STEP 2: Add these cards to your ScrollView content
// MARK: - ============================================

/*
 Add these cards AFTER your existing title card and BEFORE the schedule card.
 Follow the existing animation pattern with incremental delays.

 Your card order should be:
 1. Title Card (existing)
 2. Context Input Module (NEW)
 3. AI Insight Card (existing, enhanced)
 4. AI Prompt Card (NEW)
 5. Sub-Task Breakdown Card (NEW)
 6. AI Thought Process Card (NEW)
 7. YouTube Learning Card (NEW)
 8. Smart Schedule Card (NEW)
 9. Schedule Card (existing)
 10. Pomodoro Timer (existing)
 11. Actions Card (existing)
*/

// Example integration view showing the new cards:
struct TaskDetailSheetEnhanced: View {
    let task: TaskItem // Your existing task model
    @Environment(\.dismiss) private var dismiss

    // Existing states...
    @State private var appeared: Bool = false

    // NEW: AI Enhancement States
    @State private var contextNotes: String = ""
    @State private var subTasks: [SubTask] = []
    @State private var youtubeResources: [YouTubeResource] = []
    @State private var scheduleSuggestion: ScheduleSuggestion?
    @State private var aiThoughtProcess: String = ""
    @State private var showingReflectionSheet: Bool = false

    // Priority (from task or default)
    private var taskPriority: TaskPriority {
        // Replace with: TaskPriority(rawValue: task.starRating ?? 2) ?? .medium
        .medium
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {

                // ========================================
                // Card 1: Title Card (your existing card)
                // ========================================
                // titleCard
                //     .opacity(appeared ? 1 : 0)
                //     .offset(y: appeared ? 0 : 20)
                //     .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.05), value: appeared)

                // ========================================
                // Card 2: Context Input Module (NEW)
                // ========================================
                ContextInputModule(
                    contextNotes: $contextNotes,
                    taskTitle: task.title,
                    onContextUpdated: { newContext in
                        // Trigger AI regeneration when context changes
                        regenerateAIContent()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1), value: appeared)

                // ========================================
                // Card 3: AI Insight Card (your existing card)
                // ========================================
                // aiInsightCard
                //     .opacity(appeared ? 1 : 0)
                //     .offset(y: appeared ? 0 : 20)
                //     .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: appeared)

                // ========================================
                // Card 4: AI Prompt Card (NEW) - Always Expanded
                // ========================================
                AIPromptCard(
                    taskTitle: task.title,
                    contextNotes: contextNotes.isEmpty ? nil : contextNotes,
                    estimatedMinutes: task.estimatedMinutes,
                    priority: taskPriority,
                    previousLearnings: nil // TODO: Load from previous reflections
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: appeared)

                // ========================================
                // Card 5: Sub-Task Breakdown (NEW) - Claude Code Style
                // ========================================
                SubTaskBreakdownCard(
                    subTasks: $subTasks,
                    taskTitle: task.title,
                    onSubTaskStatusChanged: { updatedSubTask in
                        updateSubTaskStatus(updatedSubTask)
                    },
                    onSubTaskAdded: { _ in },
                    onSubTaskDeleted: { _ in },
                    onSubTaskUpdated: { _ in },
                    onSubTasksReordered: { _ in },
                    onRefresh: {
                        loadSubTasks()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: appeared)

                // ========================================
                // Card 6: AI Thought Process (NEW) - Collapsible
                // ========================================
                if !aiThoughtProcess.isEmpty || !subTasks.isEmpty {
                    AIThoughtProcessCard(
                        thoughtProcess: aiThoughtProcess,
                        subTasks: subTasks,
                        taskTitle: task.title,
                        estimatedMinutes: task.estimatedMinutes
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: appeared)
                }

                // ========================================
                // Card 7: YouTube Learning Resources (NEW)
                // ========================================
                YouTubeLearningCard(
                    resources: $youtubeResources,
                    taskTitle: task.title,
                    onRefresh: {
                        loadYouTubeResources()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.35), value: appeared)

                // ========================================
                // Card 8: Smart Schedule (NEW)
                // ========================================
                SmartScheduleCard(
                    suggestion: scheduleSuggestion,
                    estimatedMinutes: task.estimatedMinutes,
                    onAccept: { selectedDate in
                        scheduleTask(at: selectedDate)
                    },
                    onShowAlternatives: {
                        // Show alternatives view
                    },
                    onRefresh: {
                        loadScheduleSuggestion()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.4), value: appeared)

                // ========================================
                // Card 9: Schedule Card (your existing card)
                // ========================================
                // scheduleCard
                //     .opacity(appeared ? 1 : 0)
                //     .offset(y: appeared ? 0 : 20)
                //     .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.45), value: appeared)

                // ========================================
                // Card 10: Pomodoro Timer (your existing card)
                // ========================================
                // pomodoroCard
                //     .opacity(appeared ? 1 : 0)
                //     .offset(y: appeared ? 0 : 20)
                //     .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.5), value: appeared)

                // ========================================
                // Card 11: Actions Card (your existing card)
                // ========================================
                // actionsCard
                //     .opacity(appeared ? 1 : 0)
                //     .offset(y: appeared ? 0 : 20)
                //     .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.55), value: appeared)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
        .onAppear {
            loadInitialData()
            withAnimation {
                appeared = true
            }
        }
        .sheet(isPresented: $showingReflectionSheet) {
            ReflectionSheet(
                taskTitle: task.title,
                estimatedMinutes: task.estimatedMinutes,
                onSave: { reflection in
                    saveReflection(reflection)
                },
                onSkip: {
                    // User skipped reflection
                }
            )
            .presentationDetents([.large])
        }
    }

    // MARK: - Data Loading Methods

    private func loadInitialData() {
        // Load all AI content in parallel
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await loadSubTasks() }
                group.addTask { await loadYouTubeResources() }
                group.addTask { await loadScheduleSuggestion() }
            }
        }
    }

    private func regenerateAIContent() {
        // Debounce and regenerate when context changes
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            loadSubTasks()
        }
    }

    @MainActor
    private func loadSubTasks() {
        // TODO: Call GeminiService.generateSubTaskBreakdown()
        // For now, using placeholder data
        subTasks = [
            SubTask(title: "Research requirements", estimatedMinutes: 10, status: .pending, orderIndex: 1, aiReasoning: "Start by understanding what's needed"),
            SubTask(title: "Create outline", estimatedMinutes: 15, status: .pending, orderIndex: 2, aiReasoning: "Structure before content"),
            SubTask(title: "Complete main work", estimatedMinutes: 25, status: .pending, orderIndex: 3),
            SubTask(title: "Review and polish", estimatedMinutes: 10, status: .pending, orderIndex: 4)
        ]

        aiThoughtProcess = "Breaking this task into logical steps based on best practices. Started with research phase, then structure, then execution."
    }

    @MainActor
    private func loadYouTubeResources() {
        // TODO: Call GeminiService.findYouTubeResources()
        youtubeResources = [] // Will be populated by AI
    }

    @MainActor
    private func loadScheduleSuggestion() {
        // TODO: Call GeminiService.generateScheduleSuggestion()
        // with CalendarService.getFreeSlots() and user patterns
        let tomorrow9am = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            .addingTimeInterval(9 * 3600)

        scheduleSuggestion = ScheduleSuggestion(
            suggestedTime: tomorrow9am,
            reason: "Your calendar is free and you tend to be most productive in the morning.",
            confidence: 0.85,
            alternativeTimes: nil,
            conflictingEvents: nil
        )
    }

    private func updateSubTaskStatus(_ subTask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == subTask.id }) {
            subTasks[index] = subTask
            // TODO: Save to Supabase
        }
    }

    private func scheduleTask(at date: Date) {
        // TODO: Update task.scheduledDate and sync with calendar
    }

    private func saveReflection(_ reflection: TaskReflection) {
        // TODO: Save to Supabase and update user patterns
    }
}

// MARK: - ============================================
// MARK: - STEP 3: Trigger Reflection Sheet on Task Completion
// MARK: - ============================================

/*
 In your existing task completion handler (likely in actionsCard or similar),
 add this after marking the task complete:

 // Show reflection sheet immediately after completion
 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
     showingReflectionSheet = true
 }

 Example:

 Button {
     completeTask()

     // NEW: Trigger reflection
     DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
         showingReflectionSheet = true
     }
 } label: {
     Label("Complete", systemImage: "checkmark.circle.fill")
 }
 .buttonStyle(.glassProminent)
*/

// MARK: - ============================================
// MARK: - STEP 4: Add GeminiService Methods (in GeminiService.swift)
// MARK: - ============================================

/*
 Add these methods to your existing GeminiService:

 // 1. Generate sub-task breakdown
 func generateSubTaskBreakdown(taskTitle: String, context: String?) async throws -> [SubTask]

 // 2. Generate AI thought process
 func generateThoughtProcess(taskTitle: String, subTasks: [SubTask]) async throws -> String

 // 3. Find YouTube resources
 func findYouTubeResources(taskTitle: String) async throws -> [YouTubeResource]

 // 4. Generate schedule suggestion
 func generateScheduleSuggestion(
     taskTitle: String,
     estimatedMinutes: Int?,
     freeSlots: [DateInterval],
     userPatterns: UserProductivityPatterns?
 ) async throws -> ScheduleSuggestion

 // 5. Generate reflection tips
 func generateReflectionTips(
     taskTitle: String,
     difficultyRating: Int,
     wasEstimateAccurate: Bool?
 ) async throws -> [String]
*/

// MARK: - Preview
// Uses the actual TaskItem model from Models/Task.swift

#Preview {
    TaskDetailSheetEnhanced(
        task: TaskItem(title: "Finish quarterly report", estimatedMinutes: 45, starRating: 3)
    )
}
