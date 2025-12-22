//
//  GoalDetailSheet.swift
//  MyTasksAI
//
//  Goal Detail Sheet
//  Comprehensive goal view with Overview, Roadmap, Tasks, and Insights sections
//

import SwiftUI
import SwiftData

struct GoalDetailSheet: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var selectedTab: GoalDetailTab = .overview
    @State private var showCheckInSheet = false
    @State private var showRoadmapApproval = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.standard

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with constellation orb
                        headerSection

                        // Tab selector
                        tabSelector

                        // Tab content
                        tabContent
                            .padding(.bottom, 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if goal.isCheckInDue {
                            Button {
                                showCheckInSheet = true
                            } label: {
                                Label("Weekly Check-in", systemImage: "bell.badge")
                            }
                        }

                        Button {
                            showRoadmapApproval = true
                        } label: {
                            Label("View Roadmap", systemImage: "map")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Goal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showCheckInSheet) {
                WeeklyCheckInSheet(goal: goal, goalsVM: goalsVM)
            }
            .sheet(isPresented: $showRoadmapApproval) {
                AIRoadmapApprovalSheet(goal: goal, goalsVM: goalsVM)
            }
            .confirmationDialog(
                "Delete Goal",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteGoal()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete \"\(goal.displayTitle)\" and all its milestones. This action cannot be undone.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Constellation orb
            GoalStatusOrb(goal: goal, size: 100)
                .padding(.top, 20)

            // Title
            VStack(spacing: 8) {
                Text(goal.displayTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if let aiTitle = goal.aiRefinedTitle, aiTitle != goal.title {
                    Text(goal.title)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Badges row
            HStack(spacing: 12) {
                if let timeframe = goal.timeframeEnum {
                    TimeframeBadge(timeframe: timeframe, size: .regular)
                }

                if let days = goal.daysRemaining {
                    DaysRemainingPill(days: days, isOverdue: goal.isOverdue)
                }

                if let category = goal.categoryEnum {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 11))
                        Text(category.displayName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(category.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(category.color.opacity(0.15))
                    )
                }
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [goal.themeColor, goal.themeColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * goal.progress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(Int(goal.progress * 100))% complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    if goal.milestoneCount > 0 {
                        Text("\(goal.completedMilestoneCount)/\(goal.milestoneCount) milestones")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(GoalDetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))

                        Text(tab.title)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab ?
                        RoundedRectangle(cornerRadius: 12)
                            .fill(goal.themeColor.opacity(0.2)) :
                        nil
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
        )
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            GoalOverviewSection(goal: goal)
        case .roadmap:
            GoalRoadmapSection(goal: goal, goalsVM: goalsVM)
        case .tasks:
            GoalTasksSection(goal: goal, goalsVM: goalsVM)
        case .insights:
            GoalInsightsSection(goal: goal)
        }
    }

    // MARK: - Actions

    private func deleteGoal() {
        isDeleting = true
        goalsVM.deleteGoal(goal, context: modelContext)
        dismiss()
    }
}

// MARK: - Goal Detail Tab

enum GoalDetailTab: String, CaseIterable {
    case overview
    case roadmap
    case tasks
    case insights

    var title: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .roadmap: return "map"
        case .tasks: return "checklist"
        case .insights: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Overview Section

struct GoalOverviewSection: View {
    let goal: Goal

    var body: some View {
        VStack(spacing: 20) {
            // AI Refined Description
            if let description = goal.aiRefinedDescription ?? goal.goalDescription {
                SectionCard(title: "About This Goal", icon: "text.alignleft") {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineSpacing(4)
                }
            }

            // Success Metrics
            if let metrics = goal.aiSuccessMetrics, !metrics.isEmpty {
                SectionCard(title: "Success Metrics", icon: "checkmark.seal") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(metrics, id: \.self) { metric in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Colors.success)

                                Text(metric)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }

            // Potential Obstacles
            if let obstacles = goal.aiObstacles, !obstacles.isEmpty {
                SectionCard(title: "Potential Obstacles", icon: "exclamationmark.triangle") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(obstacles, id: \.self) { obstacle in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Colors.warning)

                                Text(obstacle)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }

            // Motivational Quote
            if let quote = goal.aiMotivationalQuote {
                SectionCard(title: "AI Coach Says", icon: "sparkles") {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.Colors.aiPurple.opacity(0.6))

                        Text(quote)
                            .font(.system(size: 15).italic())
                            .foregroundStyle(.white.opacity(0.7))
                            .lineSpacing(4)
                    }
                }
            }

            // SMART Criteria
            SectionCard(title: "SMART Analysis", icon: "target") {
                VStack(spacing: 12) {
                    SMARTCriteriaRow(label: "Specific", isMet: goal.isSpecific)
                    SMARTCriteriaRow(label: "Measurable", isMet: goal.isMeasurable)
                    SMARTCriteriaRow(label: "Achievable", isMet: goal.isAchievable)
                    SMARTCriteriaRow(label: "Relevant", isMet: goal.isRelevant)
                    SMARTCriteriaRow(label: "Time-Bound", isMet: goal.isTimeBound)
                }
            }
        }
    }
}

// MARK: - Roadmap Section

struct GoalRoadmapSection: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.modelContext) private var modelContext

    private var milestones: [GoalMilestone] {
        goalsVM.milestones(for: goal)
    }

    var body: some View {
        VStack(spacing: 20) {
            if milestones.isEmpty {
                emptyState
            } else {
                ForEach(milestones) { milestone in
                    MilestoneCard(
                        milestone: milestone,
                        onToggle: {
                            goalsVM.toggleMilestoneCompletion(milestone, context: modelContext)
                        }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))

            Text("No roadmap generated yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            Text("Generate an AI roadmap to get personalized milestones")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await goalsVM.generateRoadmap(for: goal, context: modelContext)
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Roadmap")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiPurple.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Tasks Section

struct GoalTasksSection: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel

    private var pendingSuggestions: [PendingTaskSuggestion] {
        goalsVM.pendingTaskSuggestions
    }

    var body: some View {
        VStack(spacing: 20) {
            // Pending approvals
            if !pendingSuggestions.isEmpty {
                SectionCard(title: "Pending Approvals", icon: "sparkles") {
                    VStack(spacing: 12) {
                        ForEach(pendingSuggestions) { suggestion in
                            PendingTaskRow(
                                suggestion: suggestion,
                                onApprove: {
                                    // Would create actual task here
                                },
                                onReject: {
                                    goalsVM.rejectTaskSuggestion(suggestion)
                                }
                            )
                        }
                    }
                }
            }

            // Linked tasks summary
            if goal.linkedTaskCount > 0 {
                SectionCard(title: "Linked Tasks", icon: "link") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(goal.linkedTaskCount) tasks linked")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.7))

                            Spacer()

                            // Progress indicator would go here
                        }
                    }
                }
            }

            // Empty state
            if pendingSuggestions.isEmpty && goal.linkedTaskCount == 0 {
                VStack(spacing: 16) {
                    Image(systemName: "checklist")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No tasks linked yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))

                    Text("Generate a roadmap to get AI-suggested tasks")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Insights Section

struct GoalInsightsSection: View {
    let goal: Goal

    var body: some View {
        VStack(spacing: 20) {
            // Check-in streak
            SectionCard(title: "Check-in Streak", icon: "flame") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(goal.checkInStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Weekly check-ins")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    if goal.checkInStreak >= 3 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                    }
                }
            }

            // Time invested
            SectionCard(title: "Goal Timeline", icon: "clock") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Started")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text(goal.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    if let targetDate = goal.targetDate {
                        HStack {
                            Text("Target")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            Text(targetDate.formatted(.dateTime.month(.abbreviated).day().year()))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }

                    if goal.isCompleted, let completedAt = goal.completedAt {
                        HStack {
                            Text("Completed")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            Text(completedAt.formatted(.dateTime.month(.abbreviated).day().year()))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.Colors.success)
                        }
                    }
                }
            }

            // Points
            if goal.pointsAwarded > 0 {
                SectionCard(title: "Points Earned", icon: "star.fill") {
                    HStack {
                        Text("\(goal.pointsAwarded)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("XP")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))

                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Section Card

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - SMART Criteria Row

struct SMARTCriteriaRow: View {
    let label: String
    let isMet: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundStyle(isMet ? Theme.Colors.success : .white.opacity(0.3))
        }
    }
}

// MARK: - Milestone Card

struct MilestoneCard: View {
    let milestone: GoalMilestone
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            milestone.isCompleted ?
                            Theme.Colors.success : .white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if milestone.isCompleted {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(milestone.isCompleted ? .white.opacity(0.5) : .white)
                        .strikethrough(milestone.isCompleted)

                    if let description = milestone.milestoneDescription {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(2)
                    }

                    HStack(spacing: 12) {
                        if let targetDate = milestone.targetDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(targetDate.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.white.opacity(0.4))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("+\(milestone.pointsValue) XP")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Color(hex: "FFD700").opacity(0.7))
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                milestone.isCompleted ?
                                Theme.Colors.success.opacity(0.3) : .white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pending Task Row

struct PendingTaskRow: View {
    let suggestion: PendingTaskSuggestion
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)

                if let reasoning = suggestion.aiReasoning {
                    Text(reasoning)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: suggestion.linkType.icon)
                            .font(.system(size: 10))
                        Text(suggestion.linkType.displayName)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Theme.Colors.aiPurple.opacity(0.7))

                    if suggestion.estimatedMinutes > 0 {
                        Text("\(suggestion.estimatedMinutes)min")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.white.opacity(0.1)))
                }

                Button(action: onApprove) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.Colors.success))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview {
    let goal = Goal(
        title: "Launch my productivity app",
        goalDescription: "Ship the MVP of MyTasksAI to the App Store",
        targetDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
        category: GoalCategory.career.rawValue,
        timeframe: GoalTimeframe.milestone.rawValue
    )

    GoalDetailSheet(goal: goal, goalsVM: GoalsViewModel())
        .modelContainer(for: [Goal.self, GoalMilestone.self])
}
