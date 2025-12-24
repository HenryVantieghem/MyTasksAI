//
//  MomentumTabViewRedesign.swift
//  Veloce
//
//  Revolutionary Momentum Page - Living Universe
//  Your productivity creates a personal cosmos where goals orbit as planets,
//  completed tasks become stars, and your streak blazes as a phoenix.
//
//  Award-Winning Design with Deep Gamification Integration
//

import SwiftUI
import SwiftData

// MARK: - Momentum Tab View (Redesigned)

struct MomentumTabViewRedesign: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query(sort: \Goal.targetDate) private var goals: [Goal]

    @State private var selectedDate: Date = Date()
    @State private var showShareSheet = false
    @State private var scrollOffset: CGFloat = 0

    // Goal state
    @State private var goalsVM = GoalsViewModel()
    @State private var showGoalCreation = false
    @State private var showGoalDetail = false
    @State private var selectedGoal: Goal?

    // Animation states
    @State private var hasAnimatedEntry = false

    private var gamification: GamificationService { GamificationService.shared }

    // MARK: - Computed Properties

    private var spotlightGoal: Goal? {
        let activeGoals = goals.filter { !$0.isCompleted }
        return activeGoals.first { goal in
            guard let days = goal.daysRemaining else { return false }
            return days <= 7 && goal.progress < 0.9
        } ?? activeGoals.first { $0.isCheckInDue } ?? activeGoals.first
    }

    private var linkedTasksProgress: Double {
        guard let goal = spotlightGoal else { return 0 }
        return goalsVM.calculateLinkedTasksProgress(for: goal, tasks: tasks)
    }

    private var tasksCompletedOnDate: Int {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard task.isCompleted, let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: selectedDate)
        }.count
    }

    private var isViewingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    private var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    private var weeklyTasksCompleted: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return tasks.filter { task in
            guard task.isCompleted, let completedAt = task.completedAt else { return false }
            return completedAt >= weekAgo
        }.count
    }

    // Parallax calculations
    private var heroScale: CGFloat {
        let maxScroll: CGFloat = 200
        let minScale: CGFloat = 0.6
        let progress = min(1, max(0, scrollOffset / maxScroll))
        return 1.0 - progress * (1.0 - minScale)
    }

    private var heroOpacity: Double {
        let fadeStart: CGFloat = 100
        let fadeEnd: CGFloat = 250
        if scrollOffset < fadeStart { return 1.0 }
        if scrollOffset > fadeEnd { return 0.3 }
        return 1.0 - Double((scrollOffset - fadeStart) / (fadeEnd - fadeStart)) * 0.7
    }

    private var stickyHeaderOpacity: Double {
        let showStart: CGFloat = 150
        if scrollOffset < showStart { return 0 }
        return min(1.0, Double((scrollOffset - showStart) / 100))
    }

    var body: some View {
        ZStack {
            // Deep void background
            Color(red: 0.01, green: 0.01, blue: 0.02)
                .ignoresSafeArea()

            // Main scrollable content
            ScrollView(showsIndicators: false) {
                scrollContent
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: -geometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }

            // Sticky header (appears on scroll)
            VStack {
                stickyHeader
                    .opacity(stickyHeaderOpacity)
                Spacer()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            WeekInReviewSheet(
                score: gamification.totalPoints,
                streak: gamification.currentStreak,
                tasksCompleted: weeklyTasksCompleted
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showGoalCreation) {
            GoalCreationSheet(goalsVM: goalsVM)
        }
        .sheet(isPresented: $showGoalDetail) {
            if let goal = selectedGoal {
                GoalDetailSheet(goal: goal, goalsVM: goalsVM)
            }
        }
        .task {
            await goalsVM.loadGoals(context: modelContext)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                hasAnimatedEntry = true
            }
        }
    }

    // MARK: - Scroll Content

    @ViewBuilder
    private var scrollContent: some View {
        VStack(spacing: 0) {
            // Hero Section - Living Universe
            heroSection
                .frame(height: 420)

            // Content Sections
            VStack(spacing: 28) {
                // Phoenix Streak (if active)
                if gamification.currentStreak > 0 {
                    phoenixStreakSection
                        .transition(.scale.combined(with: .opacity))
                }

                // Date Selector
                TodayPillView(selectedDate: $selectedDate)

                // Goal Spotlight
                GoalSpotlightSection(
                    spotlightGoal: spotlightGoal,
                    linkedTasksProgress: linkedTasksProgress,
                    onGoalTap: { goal in
                        selectedGoal = goal
                        showGoalDetail = true
                    },
                    onAddGoal: { showGoalCreation = true }
                )

                // Stats Dashboard
                StatsDashboard(
                    tasksCompleted: gamification.totalTasksCompleted,
                    completionRate: gamification.completionRate,
                    focusHours: gamification.focusHours,
                    streak: gamification.currentStreak
                )

                // Weekly Activity Chart
                WeeklyActivityCard(tasks: tasks, centerDate: selectedDate)

                // Day Progress
                DayProgressCard(
                    date: selectedDate,
                    completed: isViewingToday ? gamification.tasksCompletedToday : tasksCompletedOnDate,
                    goal: gamification.dailyGoal,
                    isToday: isViewingToday
                )

                // Achievements
                AchievementShowcaseCard(achievements: gamification.unlockedAchievements)

                // AI Insight Card
                AIInsightCard(
                    insight: gamification.latestInsight,
                    onAction: { }
                )

                // Share Button
                ShareWeekButton { showShareSheet = true }
                    .padding(.bottom, 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    // MARK: - Hero Section

    @ViewBuilder
    private var heroSection: some View {
        ZStack {
            // Living Universe visualization
            LivingUniverseCore(
                level: gamification.currentLevel,
                totalPoints: gamification.totalPoints,
                levelProgress: gamification.levelProgress,
                streak: gamification.currentStreak,
                goals: activeGoals,
                completedTaskCount: completedTaskCount,
                unlockedAchievements: gamification.unlockedAchievements
            )
            .scaleEffect(heroScale)
            .opacity(heroOpacity)
            .offset(y: -scrollOffset * 0.3) // Parallax effect
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60) // Safe area
    }

    // MARK: - Phoenix Streak Section

    @ViewBuilder
    private var phoenixStreakSection: some View {
        VStack(spacing: 12) {
            PhoenixStreakVisualization(
                streak: gamification.currentStreak,
                size: 140
            )

            // Tier badge
            let tier = PhoenixTier.forStreak(gamification.currentStreak)
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(tier.primaryColor)
                Text(tier.tierName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(tier.primaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tier.primaryColor.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(tier.primaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.vertical, 20)
    }

    // MARK: - Sticky Header

    @ViewBuilder
    private var stickyHeader: some View {
        HStack(spacing: 16) {
            // Compact XP display
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.25, blue: 0.98),
                                Color(red: 0.20, green: 0.78, blue: 0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("\(gamification.totalPoints) XP")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            // Level badge
            Text("LVL \(gamification.currentLevel)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.25, blue: 0.98),
                                    Color(red: 0.42, green: 0.45, blue: 0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Spacer()

            // Streak indicator
            if gamification.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)

                    Text("\(gamification.currentStreak)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.01, blue: 0.02),
                    Color(red: 0.01, green: 0.01, blue: 0.02).opacity(0.95),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    MomentumTabViewRedesign()
}
