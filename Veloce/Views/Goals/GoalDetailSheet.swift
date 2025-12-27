//
//  GoalDetailSheet.swift
//  Veloce
//
//  Goal Detail Sheet - Premium Full-Featured View
//  Complete goal management with Overview, Roadmap, Tasks, and Insights
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
    @State private var showEditSheet = false
    @State private var showCompleteConfirmation = false
    @State private var isDeleting = false
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.standard

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with constellation orb
                        headerSection

                        // Quick actions
                        if !goal.isCompleted {
                            quickActions
                        }

                        // Tab selector
                        tabSelector

                        // AI Generation Banner (show if no AI content)
                        if !goalsVM.hasAIContent(goal) && goalsVM.isAIAvailable && !goal.isCompleted {
                            aiGenerationBanner
                        }

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
                        if !goal.isCompleted {
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

                            Button {
                                showEditSheet = true
                            } label: {
                                Label("Edit Goal", systemImage: "pencil")
                            }

                            Divider()

                            Button {
                                showCompleteConfirmation = true
                            } label: {
                                Label("Mark Complete", systemImage: "checkmark.seal")
                            }
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
            .sheet(isPresented: $showEditSheet) {
                GoalEditSheet(goal: goal, goalsVM: goalsVM)
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
                Text("This will permanently delete \"\(goal.displayTitle)\" and all its milestones.")
            }
            .confirmationDialog(
                "Complete Goal",
                isPresented: $showCompleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Mark Complete") {
                    completeGoal()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Mark \"\(goal.displayTitle)\" as complete? You've made great progress!")
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateIn = true
                }
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
                .scaleEffect(animateIn ? 1 : 0.8)
                .opacity(animateIn ? 1 : 0)

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
            .offset(y: animateIn ? 0 : 10)
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateIn)

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
            .offset(y: animateIn ? 0 : 10)
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: animateIn)

            // Progress bar
            progressBar
                .offset(y: animateIn ? 0 : 10)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateIn)
        }
    }

    private var progressBar: some View {
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
                        .shadow(color: goal.themeColor.opacity(0.5), radius: 8, y: 0)
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

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            // Update Progress
            QuickActionButton(
                icon: "slider.horizontal.3",
                label: "Progress",
                color: Theme.Colors.aiCyan
            ) {
                // Show progress update
            }

            // Check-in
            if goal.isCheckInDue {
                QuickActionButton(
                    icon: "bell.badge.fill",
                    label: "Check-in",
                    color: Theme.Colors.warning,
                    showBadge: true
                ) {
                    showCheckInSheet = true
                }
            }

            // Generate AI
            if !goalsVM.hasAIContent(goal) && goalsVM.isAIAvailable {
                QuickActionButton(
                    icon: "sparkles",
                    label: "AI Roadmap",
                    color: Theme.Colors.aiPurple
                ) {
                    Task {
                        await goalsVM.generateAllAIContent(for: goal, context: modelContext)
                    }
                }
            }
        }
        .offset(y: animateIn ? 0 : 10)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: animateIn)
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
        .offset(y: animateIn ? 0 : 10)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateIn)
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
            GoalInsightsSection(goal: goal, goalsVM: goalsVM)
        }
    }

    // MARK: - AI Generation Banner

    private var aiGenerationBanner: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.2))
                    .frame(width: 60, height: 60)

                if goalsVM.isRefiningGoal || goalsVM.isGeneratingRoadmap {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.aiPurple))
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            // Text
            VStack(spacing: 6) {
                Text(goalsVM.isRefiningGoal || goalsVM.isGeneratingRoadmap ?
                     "Analyzing Your Goal..." : "Unlock AI Insights")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text(goalsVM.isRefiningGoal || goalsVM.isGeneratingRoadmap ?
                     "Creating your personalized roadmap" :
                     "Get SMART analysis, milestones, and personalized guidance")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // CTA Button
            if !goalsVM.isRefiningGoal && !goalsVM.isGeneratingRoadmap {
                Button {
                    Task {
                        await goalsVM.generateAllAIContent(for: goal, context: modelContext)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Generate AI Analysis")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiPurple.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func deleteGoal() {
        isDeleting = true
        goalsVM.deleteGoal(goal, context: modelContext)
        dismiss()
    }

    private func completeGoal() {
        goalsVM.completeGoal(goal, context: modelContext)
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var showBadge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundStyle(color)
                        )

                    if showBadge {
                        Circle()
                            .fill(Theme.Colors.error)
                            .frame(width: 10, height: 10)
                            .offset(x: 2, y: -2)
                    }
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
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
                // Progress summary
                if milestones.count > 0 {
                    progressSummary
                }

                // Milestones list
                ForEach(milestones) { milestone in
                    MilestoneCard(
                        milestone: milestone,
                        goalColor: goal.themeColor,
                        onToggle: {
                            goalsVM.toggleMilestoneCompletion(milestone, context: modelContext)
                        }
                    )
                }
            }
        }
    }

    private var progressSummary: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(milestones.filter(\.isCompleted).count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.success)

                Text("Completed")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Divider()
                .frame(height: 40)
                .background(.white.opacity(0.2))

            VStack(spacing: 4) {
                Text("\(milestones.filter { !$0.isCompleted }.count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Remaining")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Divider()
                .frame(height: 40)
                .background(.white.opacity(0.2))

            VStack(spacing: 4) {
                let totalPoints = milestones.reduce(0) { $0 + $1.pointsValue }
                Text("\(totalPoints)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "FFD700"))

                Text("XP Total")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
        )
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

            if goalsVM.isAIAvailable {
                Button {
                    Task {
                        await goalsVM.generateRoadmap(for: goal, context: modelContext)
                    }
                } label: {
                    HStack {
                        if goalsVM.isGeneratingRoadmap {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(goalsVM.isGeneratingRoadmap ? "Generating..." : "Generate Roadmap")
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
                .disabled(goalsVM.isGeneratingRoadmap)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Tasks Section

struct GoalTasksSection: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.modelContext) private var modelContext

    private var pendingSuggestions: [PendingTaskSuggestion] {
        goalsVM.pendingTaskSuggestions
    }

    var body: some View {
        VStack(spacing: 20) {
            // Pending approvals
            if !pendingSuggestions.isEmpty {
                SectionCard(title: "AI Suggested Tasks", icon: "sparkles") {
                    VStack(spacing: 12) {
                        ForEach(pendingSuggestions) { suggestion in
                            PendingTaskRow(
                                suggestion: suggestion,
                                onApprove: {
                                    goalsVM.approveTaskSuggestion(suggestion, for: goal, context: modelContext)
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
                            Text("\(goal.linkedTaskCount) tasks connected to this goal")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.7))

                            Spacer()
                        }

                        // Progress indicator
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)

                                Capsule()
                                    .fill(Theme.Colors.success)
                                    .frame(width: geometry.size.width * goal.progress, height: 6)
                            }
                        }
                        .frame(height: 6)
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

                    Text("Generate a roadmap to get AI-suggested tasks, or link existing tasks to this goal")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Insights Section

struct GoalInsightsSection: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Check-in streak
            SectionCard(title: "Check-in Streak", icon: "flame") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(goal.checkInStreak)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("weeks")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Text("\(goal.totalCheckIns) total check-ins")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    if goal.checkInStreak >= 3 {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 56, height: 56)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 28))
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
            }

            // Progress over time
            SectionCard(title: "Progress Journey", icon: "chart.xyaxis.line") {
                VStack(spacing: 12) {
                    // Visual progress
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { index in
                            let milestone = Double(index + 1) * 0.2
                            let isReached = goal.progress >= milestone

                            VStack(spacing: 4) {
                                Circle()
                                    .fill(isReached ? goal.themeColor : Color.white.opacity(0.2))
                                    .frame(width: 12, height: 12)

                                Text("\(Int(milestone * 100))%")
                                    .font(.system(size: 10))
                                    .foregroundStyle(isReached ? .white : .white.opacity(0.4))
                            }

                            if index < 4 {
                                Capsule()
                                    .fill(goal.progress >= milestone + 0.2 ? goal.themeColor : Color.white.opacity(0.2))
                                    .frame(height: 3)
                            }
                        }
                    }

                    Text("Current Progress: \(Int(goal.progress * 100))%")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Timeline
            SectionCard(title: "Goal Timeline", icon: "clock") {
                VStack(alignment: .leading, spacing: 12) {
                    TimelineRow(
                        label: "Started",
                        value: goal.createdAt.formatted(.dateTime.month(.abbreviated).day().year()),
                        icon: "play.circle.fill",
                        color: Theme.Colors.aiCyan
                    )

                    if let targetDate = goal.targetDate {
                        TimelineRow(
                            label: "Target",
                            value: targetDate.formatted(.dateTime.month(.abbreviated).day().year()),
                            icon: "flag.checkered",
                            color: goal.isOverdue ? Theme.Colors.error : Theme.Colors.warning
                        )
                    }

                    if goal.isCompleted, let completedAt = goal.completedAt {
                        TimelineRow(
                            label: "Completed",
                            value: completedAt.formatted(.dateTime.month(.abbreviated).day().year()),
                            icon: "checkmark.seal.fill",
                            color: Theme.Colors.success
                        )
                    }
                }
            }

            // Points
            if goal.pointsAwarded > 0 || goal.milestoneCount > 0 {
                SectionCard(title: "Rewards", icon: "star.fill") {
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("\(goal.pointsAwarded)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("XP Earned")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        if goal.timeframeEnum != nil {
                            Divider()
                                .frame(height: 40)
                                .background(.white.opacity(0.2))

                            VStack(spacing: 4) {
                                Text("\(goal.timeframeEnum?.pointsMultiplier ?? 1, specifier: "%.1f")x")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Multiplier")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Timeline Row

private struct TimelineRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
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
    var goalColor: Color = Theme.Colors.aiPurple
    let onToggle: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            milestone.isCompleted ? Theme.Colors.success : .white.opacity(0.3),
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
                            .foregroundStyle(milestone.isOverdue && !milestone.isCompleted ?
                                Theme.Colors.error.opacity(0.8) : .white.opacity(0.4))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("+\(milestone.pointsValue) XP")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Color(hex: "FFD700").opacity(milestone.isCompleted ? 0.4 : 0.8))
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
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = false }
                }
        )
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

                    if let minutes = suggestion.estimatedMinutes, minutes > 0 {
                        Text("\(minutes)min")
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

// MARK: - Goal Edit Sheet

struct GoalEditSheet: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: GoalCategory = .personal
    @State private var targetDate: Date = Date()
    @State private var progress: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.standard

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Goal Title", systemImage: "target")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))

                            CrystallineTextField(text: $title, placeholder: "Goal title", icon: "target")
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Description", systemImage: "text.alignleft")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))

                            TextEditor(text: $description)
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80, maxHeight: 120)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial.opacity(0.5))
                                )
                        }

                        // Progress slider
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.6))

                                Spacer()

                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }

                            Slider(value: $progress, in: 0...1, step: 0.05)
                                .tint(goal.themeColor)
                        }

                        // Target date
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Target Date", systemImage: "calendar")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))

                            DatePicker("Target", selection: $targetDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .tint(goal.themeColor)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
            .onAppear {
                title = goal.title
                description = goal.goalDescription ?? ""
                selectedCategory = goal.categoryEnum ?? .personal
                targetDate = goal.targetDate ?? Date()
                progress = goal.progress
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    private func saveChanges() {
        goal.title = title
        goal.goalDescription = description.isEmpty ? nil : description
        goal.category = selectedCategory.rawValue
        goal.targetDate = targetDate
        goal.updateProgress(progress)
        goalsVM.updateGoal(goal, context: modelContext)
        dismiss()
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
