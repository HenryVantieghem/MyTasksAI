//
//  GoalsViewModel.swift
//  MyTasksAI
//
//  Goal Genius ViewModel
//  Manages goals, AI analysis, and progress tracking
//

import Foundation
import SwiftData
import SwiftUI
import Supabase

// MARK: - Goals ViewModel
@MainActor
@Observable
final class GoalsViewModel {

    // MARK: Dependencies
    private let perplexity = PerplexityService.shared
    private let gamification = GamificationService.shared
    private let haptics = HapticsService.shared

    // MARK: State
    var goals: [Goal] = []
    var milestones: [GoalMilestone] = []
    var taskLinks: [GoalTaskLink] = []
    var selectedGoal: Goal?
    var pendingTaskSuggestions: [PendingTaskSuggestion] = []
    var userPatterns: UserProductivityProfile?

    // MARK: Loading States
    var isLoading = false
    var isGeneratingRoadmap = false
    var isRefiningGoal = false
    var isCheckingIn = false

    // MARK: Error State
    var error: String?

    // MARK: Filters
    var activeTimeframe: GoalTimeframe?
    var showCompleted = false

    // MARK: - Computed Properties

    /// Active (not completed) goals
    var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
            .filter { activeTimeframe == nil || $0.timeframeEnum == activeTimeframe }
            .sorted { ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture) }
    }

    /// Completed goals
    var completedGoals: [Goal] {
        goals.filter(\.isCompleted)
            .sorted { ($0.completedAt ?? .now) > ($1.completedAt ?? .now) }
    }

    /// The most urgent active goal (spotlight)
    var spotlightGoal: Goal? {
        // Prioritize goals that are:
        // 1. Due within 7 days and less than 90% complete
        // 2. Have a check-in due
        // 3. Otherwise, the nearest deadline
        activeGoals.first { goal in
            guard let days = goal.daysRemaining else { return false }
            return days <= 7 && goal.progress < 0.9
        } ?? activeGoals.first { $0.isCheckInDue } ?? activeGoals.first
    }

    /// Goals with check-ins due
    var goalsNeedingCheckIn: [Goal] {
        activeGoals.filter(\.isCheckInDue)
    }

    /// Goals by timeframe
    func goals(for timeframe: GoalTimeframe) -> [Goal] {
        activeGoals.filter { $0.timeframeEnum == timeframe }
    }

    /// Milestones for a specific goal
    func milestones(for goal: Goal) -> [GoalMilestone] {
        milestones.filter { $0.goalId == goal.id }.sorted
    }

    /// Task links for a specific goal
    func taskLinks(for goal: Goal) -> [GoalTaskLink] {
        taskLinks.filter { $0.goalId == goal.id }
    }

    /// Pending task suggestions count
    var pendingApprovalCount: Int {
        pendingTaskSuggestions.count
    }

    // MARK: - Data Loading

    /// Load all goals from SwiftData
    func loadGoals(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let goalsDescriptor = FetchDescriptor<Goal>(
                sortBy: [SortDescriptor(\.targetDate, order: .forward)]
            )
            goals = try context.fetch(goalsDescriptor)

            let milestonesDescriptor = FetchDescriptor<GoalMilestone>()
            milestones = try context.fetch(milestonesDescriptor)

            let linksDescriptor = FetchDescriptor<GoalTaskLink>()
            taskLinks = try context.fetch(linksDescriptor)

            error = nil

            // Load user patterns from Supabase
            await loadUserPatterns()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Load user productivity patterns from Supabase
    func loadUserPatterns() async {
        guard let userId = SupabaseService.shared.currentUserId else { return }

        do {
            let patterns: [UserProductivityProfile] = try await SupabaseService.shared.supabase
                .from("user_productivity_patterns")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            userPatterns = patterns.first
        } catch {
            print("Failed to load user patterns: \(error.localizedDescription)")
        }
    }

    // MARK: - Goal CRUD

    /// Create a new goal
    func createGoal(
        title: String,
        description: String?,
        category: GoalCategory,
        timeframe: GoalTimeframe,
        targetDate: Date,
        context: ModelContext
    ) async -> Goal {
        let goal = Goal(
            title: title,
            goalDescription: description,
            targetDate: targetDate,
            category: category.rawValue,
            timeframe: timeframe.rawValue
        )

        // Set initial check-in date
        goal.nextCheckInSuggested = timeframe.checkInFrequency.nextCheckInDate(from: .now)

        context.insert(goal)
        goals.append(goal)

        haptics.impact(.medium)

        // Auto-refine with AI if available
        if perplexity.isReady {
            await refineGoalWithAI(goal, context: context)
        }

        // Award achievement for first goal
        if goals.count == 1 {
            gamification.unlockAchievement(.goalSetter)
        }

        return goal
    }

    /// Update an existing goal
    func updateGoal(_ goal: Goal, context: ModelContext) {
        goal.updatedAt = .now
        try? context.save()
    }

    /// Delete a goal
    func deleteGoal(_ goal: Goal, context: ModelContext) {
        // Delete associated milestones
        for milestone in milestones(for: goal) {
            context.delete(milestone)
        }
        milestones.removeAll { $0.goalId == goal.id }

        // Delete associated task links
        for link in taskLinks(for: goal) {
            context.delete(link)
        }
        taskLinks.removeAll { $0.goalId == goal.id }

        // Delete the goal
        context.delete(goal)
        goals.removeAll { $0.id == goal.id }

        haptics.impact(.light)
    }

    // MARK: - AI Features

    /// Generate all AI content for a goal (refinement + roadmap)
    /// Call this when user taps "Generate AI Analysis" CTA
    func generateAllAIContent(for goal: Goal, context: ModelContext) async {
        guard perplexity.isReady else {
            error = "AI service not available. Please check your settings."
            return
        }

        // First, refine the goal with SMART analysis
        await refineGoalWithAI(goal, context: context)

        // Then generate the roadmap if refinement succeeded
        if goal.aiRefinedTitle != nil {
            await generateRoadmap(for: goal, context: context)
        }
    }

    /// Check if a goal has AI content generated
    func hasAIContent(_ goal: Goal) -> Bool {
        goal.aiRefinedTitle != nil || goal.hasRoadmap
    }

    /// Check if AI service is available
    var isAIAvailable: Bool {
        perplexity.isReady
    }

    /// Refine goal with AI SMART analysis
    func refineGoalWithAI(_ goal: Goal, context: ModelContext) async {
        guard perplexity.isReady else { return }

        isRefiningGoal = true
        defer { isRefiningGoal = false }

        do {
            let refinement = try await perplexity.refineGoalToSMART(
                title: goal.title,
                description: goal.goalDescription,
                category: goal.categoryEnum,
                timeframe: goal.timeframeEnum ?? .milestone
            )

            // Apply refinement to goal
            goal.aiRefinedTitle = refinement.refinedTitle
            goal.aiRefinedDescription = refinement.refinedDescription
            goal.aiObstacles = refinement.potentialObstacles
            goal.aiSuccessMetrics = refinement.successMetrics
            goal.aiMotivationalQuote = refinement.motivationalQuote
            goal.aiAnalyzedAt = .now

            // Mark SMART criteria as met
            goal.isSpecific = true
            goal.isMeasurable = true
            goal.isAchievable = true
            goal.isRelevant = true
            goal.isTimeBound = true

            goal.updatedAt = .now
            try? context.save()

            error = nil
        } catch {
            self.error = "Failed to refine goal: \(error.localizedDescription)"
        }
    }

    /// Generate AI roadmap for a goal
    func generateRoadmap(for goal: Goal, context: ModelContext) async {
        guard perplexity.isReady else {
            error = "AI service not available"
            return
        }

        isGeneratingRoadmap = true
        defer { isGeneratingRoadmap = false }

        do {
            // Convert UserProductivityProfile to UserPatterns format if available
            let patterns: UserPatterns? = userPatterns.flatMap { productivity in
                UserPatterns(
                    preferredLearningStyle: nil,
                    peakProductivityHours: productivity.energyPatterns?.max(by: { $0.value < $1.value })?.key,
                    bestDays: nil,
                    avgDurationByType: nil
                )
            }

            let roadmap = try await perplexity.generateGoalRoadmap(
                goal: goal,
                userPatterns: patterns
            )

            // Store roadmap
            try goal.setRoadmap(roadmap)

            // Create milestone models
            var sortOrder = 0
            for phase in roadmap.phases {
                for milestone in phase.milestones {
                    let targetDate = milestone.targetDate(from: goal.createdAt)

                    let goalMilestone = GoalMilestone(
                        goalId: goal.id,
                        userId: goal.userId,
                        title: milestone.title,
                        milestoneDescription: milestone.description,
                        targetDate: targetDate,
                        sortOrder: sortOrder,
                        pointsValue: milestone.pointsValue,
                        aiGenerated: true,
                        aiReasoning: milestone.successIndicator,
                        successIndicator: milestone.successIndicator
                    )
                    context.insert(goalMilestone)
                    milestones.append(goalMilestone)
                    sortOrder += 1
                }

                // Create pending task suggestions for habits and tasks
                for habit in phase.dailyHabits {
                    let suggestion = PendingTaskSuggestion(
                        title: habit.title,
                        estimatedMinutes: habit.durationMinutes,
                        linkType: .habit,
                        aiReasoning: habit.reasoning,
                        suggestedSchedule: habit.bestTime
                    )
                    pendingTaskSuggestions.append(suggestion)
                }

                for task in phase.oneTimeTasks {
                    let suggestion = PendingTaskSuggestion(
                        title: task.title,
                        estimatedMinutes: task.estimatedMinutes,
                        linkType: .directAction,
                        aiReasoning: task.reasoning,
                        priority: task.priority
                    )
                    pendingTaskSuggestions.append(suggestion)
                }
            }

            goal.milestoneCount = sortOrder
            goal.updatedAt = .now
            try? context.save()

            haptics.notification(.success)
            error = nil
        } catch {
            self.error = "Failed to generate roadmap: \(error.localizedDescription)"
            haptics.notification(.error)
        }
    }

    /// Perform weekly check-in for a goal
    func performWeeklyCheckIn(
        for goal: Goal,
        blockers: [String]?,
        context: ModelContext
    ) async -> WeeklyCheckIn? {
        guard perplexity.isReady else {
            error = "AI service not available"
            return nil
        }

        isCheckingIn = true
        defer { isCheckingIn = false }

        do {
            let checkIn = try await perplexity.generateWeeklyCheckIn(
                goal: goal,
                recentProgress: goal.progress,
                completedMilestones: goal.completedMilestoneCount,
                totalMilestones: goal.milestoneCount,
                blockers: blockers
            )

            // Record the check-in
            goal.recordCheckIn()

            // Add progress snapshot
            goal.addProgressSnapshot(notes: blockers?.joined(separator: ", "))

            try? context.save()

            // Award points for consistent check-ins
            if goal.checkInStreak >= 3 {
                _ = gamification.awardPoints(10)
            }

            haptics.notification(.success)
            error = nil
            return checkIn
        } catch {
            self.error = "Failed to generate check-in: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Task Approval Flow

    /// Approve a pending task suggestion (creates the task)
    func approveTaskSuggestion(
        _ suggestion: PendingTaskSuggestion,
        for goal: Goal,
        context: ModelContext
    ) {
        // Remove from pending
        pendingTaskSuggestions.removeAll { $0.id == suggestion.id }

        // Note: The actual task creation would be handled by the caller
        // since TaskItem is managed elsewhere. We just track the approval.

        haptics.impact(.light)
    }

    /// Reject a pending task suggestion
    func rejectTaskSuggestion(_ suggestion: PendingTaskSuggestion) {
        pendingTaskSuggestions.removeAll { $0.id == suggestion.id }
    }

    /// Approve all selected task suggestions
    func approveSelectedSuggestions(for goal: Goal, context: ModelContext) {
        let selected = pendingTaskSuggestions.filter(\.isSelected)
        for suggestion in selected {
            approveTaskSuggestion(suggestion, for: goal, context: context)
        }
    }

    // MARK: - Milestone Management

    /// Toggle milestone completion
    func toggleMilestoneCompletion(_ milestone: GoalMilestone, context: ModelContext) {
        milestone.toggleCompletion()

        // Update parent goal's milestone counts
        if let goal = goals.first(where: { $0.id == milestone.goalId }) {
            let goalMilestones = milestones(for: goal)
            goal.updateMilestoneCounts(
                completed: goalMilestones.completedCount,
                total: goalMilestones.count
            )

            // Award points if completed
            if milestone.isCompleted {
                _ = gamification.awardPoints(milestone.pointsValue)
                haptics.notification(.success)
            }
        }

        try? context.save()
    }

    // MARK: - Goal Completion

    /// Complete a goal
    func completeGoal(_ goal: Goal, context: ModelContext) {
        goal.complete()

        // Calculate and award points
        let basePoints = goal.timeframeEnum?.baseCompletionPoints ?? 100
        let multiplier = goal.timeframeEnum?.pointsMultiplier ?? 1.0
        let bonusPoints = goal.progress >= 1.0 ? 50 : 0
        let totalPoints = Int(Double(basePoints) * multiplier) + bonusPoints

        goal.pointsAwarded = totalPoints
        _ = gamification.awardPoints(totalPoints)

        // Unlock achievement
        gamification.unlockAchievement(.goalAchiever)

        try? context.save()
        haptics.celebration()
    }

    // MARK: - Progress Calculation

    /// Calculate progress based on linked tasks
    func calculateLinkedTasksProgress(
        for goal: Goal,
        tasks: [TaskItem]
    ) -> Double {
        let goalLinks = taskLinks(for: goal).approved
        guard !goalLinks.isEmpty else { return 0 }

        let linkedTaskIds = Set(goalLinks.map(\.taskId))
        let linkedTasks = tasks.filter { linkedTaskIds.contains($0.id) }

        guard !linkedTasks.isEmpty else { return 0 }

        // Weight by link type
        var totalWeight: Double = 0
        var completedWeight: Double = 0

        for link in goalLinks {
            let weight = link.linkTypeEnum.progressWeight
            totalWeight += weight

            if let task = linkedTasks.first(where: { $0.id == link.taskId }),
               task.isCompleted {
                completedWeight += weight
            }
        }

        return totalWeight > 0 ? completedWeight / totalWeight : 0
    }
}

// MARK: - Goal Collection Extensions
extension Array where Element == Goal {
    /// Filter by timeframe
    func ofTimeframe(_ timeframe: GoalTimeframe) -> [Goal] {
        filter { $0.timeframeEnum == timeframe }
    }

    /// Active goals (not completed)
    var active: [Goal] {
        filter { !$0.isCompleted }
    }

    /// Completed goals
    var completed: [Goal] {
        filter(\.isCompleted)
    }

    /// Goals due within N days
    func dueSoon(days: Int = 7) -> [Goal] {
        filter { goal in
            guard let remaining = goal.daysRemaining else { return false }
            return remaining >= 0 && remaining <= days && !goal.isCompleted
        }
    }

    /// Overdue goals
    var overdue: [Goal] {
        filter(\.isOverdue)
    }

    /// Goals needing check-in
    var needingCheckIn: [Goal] {
        filter(\.isCheckInDue)
    }

    /// Total progress across all goals
    var averageProgress: Double {
        guard !isEmpty else { return 0 }
        return reduce(0.0) { $0 + $1.progress } / Double(count)
    }
}
