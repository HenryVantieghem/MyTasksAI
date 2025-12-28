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
            GoalQuickActionButton(
                icon: "slider.horizontal.3",
                label: "Progress",
                color: Theme.Colors.aiCyan
            ) {
                // Show progress update
            }

            // Check-in
            if goal.isCheckInDue {
                GoalQuickActionButton(
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
                GoalQuickActionButton(
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
        case .steps:
            GoalStepsSection(goal: goal)
        case .roadmap:
            GoalRoadmapSection(goal: goal, goalsVM: goalsVM)
        case .notes:
            GoalNotesSection(goal: goal)
        case .insights:
            GoalInsightsSection(goal: goal, goalsVM: goalsVM)
        }
    }

    // MARK: - AI Generation Banner

    @State private var aiGenerationElapsed: Int = 0
    @State private var aiGenerationTimer: Timer?

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
                } else if goalsVM.error != nil {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Colors.warning)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            // Text
            VStack(spacing: 6) {
                if goalsVM.isRefiningGoal || goalsVM.isGeneratingRoadmap {
                    Text("Analyzing Your Goal...")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(aiGenerationElapsed > 10 ?
                         "This is taking longer than usual..." :
                         "Creating your personalized roadmap")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else if let error = goalsVM.error {
                    Text("Generation Failed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(error)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                } else {
                    Text("Unlock AI Insights")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Get SMART analysis, milestones, and personalized guidance")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }

            // CTA Button
            if !goalsVM.isRefiningGoal && !goalsVM.isGeneratingRoadmap {
                Button {
                    startAIGeneration()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: goalsVM.error != nil ? "arrow.clockwise" : "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                        Text(goalsVM.error != nil ? "Try Again" : "Generate AI Analysis")
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
            } else if aiGenerationElapsed > 15 {
                // Cancel button if taking too long
                Button {
                    cancelAIGeneration()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
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
        .onChange(of: goalsVM.isRefiningGoal) { _, isRefining in
            if isRefining {
                startAITimer()
            } else if !goalsVM.isGeneratingRoadmap {
                stopAITimer()
            }
        }
        .onChange(of: goalsVM.isGeneratingRoadmap) { _, isGenerating in
            if isGenerating && !goalsVM.isRefiningGoal {
                startAITimer()
            } else if !isGenerating {
                stopAITimer()
            }
        }
    }

    private func startAIGeneration() {
        goalsVM.error = nil
        aiGenerationElapsed = 0
        Task {
            await goalsVM.generateAllAIContent(for: goal, context: modelContext)
        }
    }

    private func cancelAIGeneration() {
        // Force reset the loading states
        goalsVM.isRefiningGoal = false
        goalsVM.isGeneratingRoadmap = false
        goalsVM.error = "Generation cancelled"
        stopAITimer()
    }

    private func startAITimer() {
        aiGenerationElapsed = 0
        aiGenerationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            aiGenerationElapsed += 1
        }
    }

    private func stopAITimer() {
        aiGenerationTimer?.invalidate()
        aiGenerationTimer = nil
        aiGenerationElapsed = 0
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

// MARK: - Goal Quick Action Button

private struct GoalQuickActionButton: View {
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
    case steps
    case roadmap
    case notes
    case insights

    var title: String {
        switch self {
        case .steps: return "Steps"
        case .notes: return "Notes"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .steps: return "list.bullet.circle"
        case .roadmap: return "map"
        case .notes: return "note.text"
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

// MARK: - Goal Steps Section (Psychology: Implementation Intentions)

struct GoalStepsSection: View {
    @Bindable var goal: Goal
    @State private var newStepText = ""
    @State private var showingAddStep = false
    @FocusState private var isInputFocused: Bool

    private var steps: [GoalActionStep] {
        goal.decodedActionSteps
    }

    private var completedCount: Int {
        steps.filter(\.isCompleted).count
    }

    var body: some View {
        VStack(spacing: 20) {
            // Progress Summary
            if !steps.isEmpty {
                stepsProgressCard
            }

            // Why It Matters (Motivation Section)
            whyItMattersSection

            // If-Then Plans (WOOP Methodology)
            ifThenPlansSection

            // Action Steps List
            stepsListSection

            // Add Step Input
            if showingAddStep {
                addStepInput
            }
        }
    }

    // MARK: - Progress Card

    private var stepsProgressCard: some View {
        SectionCard(title: "Your Action Steps", icon: "list.bullet.circle") {
            VStack(spacing: 12) {
                HStack {
                    Text("\(completedCount) of \(steps.count) completed")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Text("\(Int(goal.actionStepsProgress * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(goal.themeColor)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [goal.themeColor, goal.themeColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * goal.actionStepsProgress, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: goal.actionStepsProgress)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    // MARK: - Why It Matters Section

    private var whyItMattersSection: some View {
        SectionCard(title: "Why This Matters", icon: "heart.fill") {
            VStack(spacing: 12) {
                if let motivation = goal.whyItMatters, !motivation.isEmpty {
                    Text(motivation)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        // Edit motivation
                    } label: {
                        Text("Edit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(goal.themeColor)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("Connect to your deeper motivation")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)

                        MotivationPromptButton(goal: goal)
                    }
                }
            }
        }
    }

    // MARK: - If-Then Plans Section

    private var ifThenPlansSection: some View {
        SectionCard(title: "Obstacle Plans", icon: "shield.fill") {
            VStack(spacing: 12) {
                let plans = goal.decodedIfThenPlans

                if plans.isEmpty {
                    VStack(spacing: 8) {
                        Text("Prepare for obstacles with If-Then plans")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("\"If I feel unmotivated, then I will...\"")
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(.white.opacity(0.4))
                            .italic()

                        AddIfThenButton(goal: goal)
                    }
                } else {
                    ForEach(plans) { plan in
                        IfThenPlanRow(plan: plan, goal: goal)
                    }

                    AddIfThenButton(goal: goal)
                }
            }
        }
    }

    // MARK: - Steps List

    private var stepsListSection: some View {
        SectionCard(title: "Steps to Success", icon: "stairs") {
            VStack(spacing: 0) {
                if steps.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.3))

                        Text("Break your goal into small, actionable steps")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                } else {
                    ForEach(steps) { step in
                        ActionStepRow(step: step, goal: goal, goalColor: goal.themeColor)
                    }
                }

                // Add step button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingAddStep.toggle()
                        if showingAddStep {
                            isInputFocused = true
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showingAddStep ? "xmark" : "plus")
                            .font(.system(size: 14, weight: .medium))

                        Text(showingAddStep ? "Cancel" : "Add Step")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(goal.themeColor)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Add Step Input

    private var addStepInput: some View {
        HStack(spacing: 12) {
            TextField("What's the next action?", text: $newStepText)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit {
                    addStep()
                }

            Button {
                addStep()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(newStepText.isEmpty ? .white.opacity(0.3) : goal.themeColor)
            }
            .disabled(newStepText.isEmpty)
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(goal.themeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func addStep() {
        guard !newStepText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let step = GoalActionStep(
            title: newStepText.trimmingCharacters(in: .whitespacesAndNewlines),
            sortOrder: steps.count
        )

        goal.addActionStep(step)
        newStepText = ""
        HapticsService.shared.impact(.light)

        // Keep focus for adding more
    }
}

// MARK: - Action Step Row

struct ActionStepRow: View {
    let step: GoalActionStep
    @Bindable var goal: Goal
    let goalColor: Color

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                goal.toggleActionStep(step.id)
                HapticsService.shared.impact(step.isCompleted ? .rigid : .light)
            }
        } label: {
            HStack(spacing: 14) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            step.isCompleted ? Theme.Colors.success : .white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if step.isCompleted {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                Text(step.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(step.isCompleted ? .white.opacity(0.5) : .white)
                    .strikethrough(step.isCompleted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Delete button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        goal.removeActionStep(step.id)
                        HapticsService.shared.impact(.light)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Motivation Prompt Button

struct MotivationPromptButton: View {
    @Bindable var goal: Goal
    @State private var showingSheet = false

    var body: some View {
        Button {
            showingSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                Text("Add Your Why")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(goal.themeColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(goal.themeColor.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSheet) {
            MotivationInputSheet(goal: goal)
        }
    }
}

// MARK: - Motivation Input Sheet

struct MotivationInputSheet: View {
    @Bindable var goal: Goal
    @Environment(\.dismiss) private var dismiss
    @State private var motivationText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.standard

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Why does this goal matter to you?")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Connecting to your deeper motivation increases follow-through by 3x")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Prompts
                    VStack(spacing: 8) {
                        ForEach(motivationPrompts, id: \.self) { prompt in
                            Button {
                                if motivationText.isEmpty {
                                    motivationText = prompt
                                } else {
                                    motivationText += " " + prompt
                                }
                            } label: {
                                Text(prompt)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(.white.opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextEditor(text: $motivationText)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial.opacity(0.5))
                        )

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Your Motivation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        goal.whyItMatters = motivationText.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(goal.themeColor)
                    .disabled(motivationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                motivationText = goal.whyItMatters ?? ""
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    private var motivationPrompts: [String] {
        [
            "This will help me...",
            "I want to feel...",
            "This matters because...",
            "Achieving this means..."
        ]
    }
}

// MARK: - Add If-Then Button

struct AddIfThenButton: View {
    @Bindable var goal: Goal
    @State private var showingSheet = false

    var body: some View {
        Button {
            showingSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                Text("Add Obstacle Plan")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(Theme.Colors.aiCyan)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSheet) {
            IfThenInputSheet(goal: goal)
        }
    }
}

// MARK: - If-Then Input Sheet

struct IfThenInputSheet: View {
    @Bindable var goal: Goal
    @Environment(\.dismiss) private var dismiss
    @State private var obstacle = ""
    @State private var response = ""

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.standard

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Create an Obstacle Plan")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("If-Then plans help you overcome obstacles automatically")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // If section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("IF")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.Colors.warning)

                            Text("this obstacle happens...")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        TextField("I feel unmotivated...", text: $obstacle, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial.opacity(0.5))
                            )
                    }

                    // Then section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("THEN")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.Colors.success)

                            Text("I will...")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        TextField("Start with just 5 minutes...", text: $response, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial.opacity(0.5))
                            )
                    }

                    // Common obstacles
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common obstacles:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))

                        GoalTagFlowLayout(spacing: 8) {
                            ForEach(commonObstacles, id: \.self) { obs in
                                Button {
                                    obstacle = obs
                                } label: {
                                    Text(obs)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(.white.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Obstacle Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        let plan = IfThenPlan(
                            obstacle: obstacle.trimmingCharacters(in: .whitespacesAndNewlines),
                            response: response.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        goal.addIfThenPlan(plan)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.aiCyan)
                    .disabled(obstacle.isEmpty || response.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    private var commonObstacles: [String] {
        [
            "I feel unmotivated",
            "I get distracted",
            "I'm too tired",
            "I run out of time",
            "I feel overwhelmed"
        ]
    }
}

// MARK: - If-Then Plan Row

struct IfThenPlanRow: View {
    let plan: IfThenPlan
    @Bindable var goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("IF")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.warning)

                Text(plan.obstacle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 6) {
                Text("THEN")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.success)

                Text(plan.response)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
        .contextMenu {
            Button(role: .destructive) {
                goal.removeIfThenPlan(plan.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Goal Notes Section

struct GoalNotesSection: View {
    @Bindable var goal: Goal
    @State private var showingAddNote = false
    @State private var newNoteText = ""
    @State private var selectedMood: GoalNote.NoteMood?
    @FocusState private var isInputFocused: Bool

    private var notes: [GoalNote] {
        goal.decodedNotes
    }

    var body: some View {
        VStack(spacing: 20) {
            // Add note button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingAddNote.toggle()
                    if showingAddNote {
                        isInputFocused = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showingAddNote ? "xmark" : "plus")
                        .font(.system(size: 14, weight: .medium))
                    Text(showingAddNote ? "Cancel" : "Add Progress Note")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(goal.themeColor)
                )
            }
            .buttonStyle(.plain)

            // Add note input
            if showingAddNote {
                addNoteInput
            }

            // Notes list
            if notes.isEmpty && !showingAddNote {
                emptyNotesState
            } else {
                ForEach(notes) { note in
                    NoteRow(note: note, goal: goal)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyNotesState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 4) {
                Text("Track Your Journey")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Record thoughts, wins, and learnings as you progress")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
    }

    // MARK: - Add Note Input

    private var addNoteInput: some View {
        VStack(spacing: 12) {
            // Mood selector
            HStack(spacing: 8) {
                Text("How are you feeling?")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                ForEach(GoalNote.NoteMood.allCases, id: \.self) { mood in
                    Button {
                        selectedMood = selectedMood == mood ? nil : mood
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        Image(systemName: mood.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(selectedMood == mood ? mood.color : .white.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(selectedMood == mood ? mood.color.opacity(0.2) : .white.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Text input
            HStack(spacing: 12) {
                TextField("What's happening with your goal?", text: $newNoteText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .lineLimit(3...6)
                    .focused($isInputFocused)

                Button {
                    addNote()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(newNoteText.isEmpty ? .white.opacity(0.3) : goal.themeColor)
                }
                .disabled(newNoteText.isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(goal.themeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func addNote() {
        guard !newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let note = GoalNote(
            content: newNoteText.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: selectedMood
        )

        goal.addNote(note)
        newNoteText = ""
        selectedMood = nil
        showingAddNote = false
        HapticsService.shared.notification(.success)
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: GoalNote
    @Bindable var goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let mood = note.mood {
                    HStack(spacing: 4) {
                        Image(systemName: mood.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(mood.color)

                        Text(mood.rawValue.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(mood.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(mood.color.opacity(0.15))
                    )
                }

                Spacer()

                Text(note.createdAt.formatted(.relative(presentation: .named)))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Text(note.content)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .contextMenu {
            Button(role: .destructive) {
                goal.removeNote(note.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Flow Layout for Tags

struct GoalTagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            height = y + rowHeight
        }
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
