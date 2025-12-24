//
//  MomentumDashboardView.swift
//  Veloce
//
//  Premium Analytics & Goal-Tracking Dashboard
//  Three-section design: Stats | Goals | Insights
//  Where users understand their progress and plan their growth
//
//  Award-Winning Tier Visual Design
//

import SwiftUI
import SwiftData

// MARK: - Momentum Section

enum MomentumSection: String, CaseIterable, Identifiable {
    case stats = "Stats"
    case goals = "Goals"
    case insights = "Insights"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .stats: return "chart.bar.fill"
        case .goals: return "target"
        case .insights: return "sparkles"
        }
    }

    var accentColor: Color {
        switch self {
        case .stats: return Theme.CelestialColors.plasmaCore
        case .goals: return Theme.CelestialColors.auroraGreen
        case .insights: return Theme.CelestialColors.nebulaCore
        }
    }
}

// MARK: - Momentum Dashboard View

struct MomentumDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query(sort: \Goal.targetDate) private var goals: [Goal]

    @State private var selectedSection: MomentumSection = .stats
    @State private var selectedDate: Date = Date()
    @State private var showGoalCreation = false
    @State private var showGoalDetail = false
    @State private var selectedGoal: Goal?
    @State private var goalsVM = GoalsViewModel()
    @State private var showOracleChat = false
    @State private var hasAnimatedEntry = false

    private var gamification: GamificationService { GamificationService.shared }

    // MARK: - Computed Properties

    private var velocityScore: VelocityScore {
        VelocityScore(
            currentStreak: gamification.currentStreak,
            longestStreak: gamification.longestStreak,
            tasksCompletedThisWeek: weeklyTasksCompleted,
            weeklyGoal: gamification.weeklyGoal,
            focusMinutesThisWeek: Int(gamification.focusHours * 60),
            focusGoalMinutes: 5 * 60,
            tasksOnTime: gamification.totalTasksCompleted,
            totalTasksCompleted: gamification.totalTasksCompleted
        )
    }

    private var weeklyTasksCompleted: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return tasks.filter { task in
            guard task.isCompleted, let completedAt = task.completedAt else { return false }
            return completedAt >= weekAgo
        }.count
    }

    private var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    var body: some View {
        ZStack {
            // Dynamic background based on section
            backgroundForSection
                .animation(.easeInOut(duration: 0.5), value: selectedSection)

            VStack(spacing: 0) {
                // Header
                dashboardHeader

                // Section Selector
                sectionSelector
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Content Area
                TabView(selection: $selectedSection) {
                    statsSection
                        .tag(MomentumSection.stats)

                    goalsSection
                        .tag(MomentumSection.goals)

                    insightsSection
                        .tag(MomentumSection.insights)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedSection)
            }
        }
        .sheet(isPresented: $showGoalCreation) {
            GoalCreationSheet(goalsVM: goalsVM)
                .voidPresentationBackground()
        }
        .sheet(isPresented: $showGoalDetail) {
            if let goal = selectedGoal {
                GoalDetailSheet(goal: goal, goalsVM: goalsVM)
                    .voidPresentationBackground()
            }
        }
        .sheet(isPresented: $showOracleChat) {
            OracleChatSheet()
                .voidPresentationBackground()
        }
        .task {
            await goalsVM.loadGoals(context: modelContext)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                hasAnimatedEntry = true
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundForSection: some View {
        ZStack {
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()

            // Section-specific nebula
            switch selectedSection {
            case .stats:
                RadialGradient(
                    colors: [
                        Theme.CelestialColors.plasmaCore.opacity(0.15),
                        Theme.CelestialColors.nebulaEdge.opacity(0.08),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()

            case .goals:
                RadialGradient(
                    colors: [
                        Theme.CelestialColors.auroraGreen.opacity(0.12),
                        Theme.CelestialColors.plasmaCore.opacity(0.06),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()

            case .insights:
                ZStack {
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.nebulaCore.opacity(0.18),
                            Theme.CelestialColors.nebulaGlow.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )

                    // Mystical orb hints
                    ForEach(0..<3, id: \.self) { i in
                        SwiftUI.Circle()
                            .fill(Theme.CelestialColors.nebulaCore.opacity(0.05))
                            .frame(width: 150, height: 150)
                            .blur(radius: 40)
                            .offset(
                                x: CGFloat.random(in: -100...100),
                                y: CGFloat.random(in: -200...200)
                            )
                    }
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var dashboardHeader: some View {
        HStack(alignment: .center) {
            // XP Badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("\(gamification.totalPoints)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()

            // Title
            Text("Momentum")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            // Date Navigator
            DateNavigatorPill(selectedDate: $selectedDate)
        }
        .padding(.horizontal, 20)
        .padding(.top, Theme.Spacing.universalHeaderHeight)
        .padding(.bottom, 8)
    }

    // MARK: - Section Selector

    @ViewBuilder
    private var sectionSelector: some View {
        HStack(spacing: 8) {
            ForEach(MomentumSection.allCases) { section in
                sectionPill(section)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
    }

    @ViewBuilder
    private func sectionPill(_ section: MomentumSection) -> some View {
        let isSelected = selectedSection == section

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedSection = section
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(section.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(section.accentColor.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(section.accentColor.opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Hero Productivity Score
                ProductivityScoreRing(score: velocityScore)
                    .padding(.top, 16)

                // Quick Stats Row
                QuickStatsRow(
                    tasksCompleted: gamification.totalTasksCompleted,
                    focusHours: gamification.focusHours,
                    completionRate: gamification.completionRate,
                    streak: gamification.currentStreak
                )

                // Weekly Activity Heatmap
                WeeklyHeatmapCard(tasks: tasks, selectedDate: selectedDate)

                // Focus Time Chart
                FocusTimeChart(tasks: tasks)

                // Task Completion Trend
                CompletionTrendChart(tasks: tasks)

                // Personal Bests
                PersonalBestsCard(gamification: gamification)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Goals Section

    @ViewBuilder
    private var goalsSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Create Goal Button
                CreateGoalButton {
                    showGoalCreation = true
                }
                .padding(.top, 16)

                if activeGoals.isEmpty {
                    GoalsEmptyState(onCreateGoal: { showGoalCreation = true })
                        .padding(.top, 40)
                } else {
                    // Goal Cards
                    ForEach(activeGoals) { goal in
                        ExpandableGoalCard(
                            goal: goal,
                            tasks: tasks,
                            goalsVM: goalsVM,
                            onTap: {
                                selectedGoal = goal
                                showGoalDetail = true
                            }
                        )
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Insights Section

    @ViewBuilder
    private var insightsSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Oracle Header
                OracleHeaderView()
                    .padding(.top, 16)

                // Pattern Recognition Card
                PatternRecognitionCard(tasks: tasks, gamification: gamification)

                // AI Suggestions Card
                AISuggestionsCard(tasks: tasks, gamification: gamification)

                // Weekly Reflection
                WeeklyReflectionCard(
                    tasks: tasks,
                    gamification: gamification,
                    velocityScore: velocityScore
                )

                // Predictions Card
                PredictionsCard(goals: activeGoals, tasks: tasks)

                // Ask the Oracle
                AskOracleCard(onAsk: { showOracleChat = true })

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Date Navigator Pill

struct DateNavigatorPill: View {
    @Binding var selectedDate: Date

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
                HapticsService.shared.lightFeedback()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Text(isToday ? "Today" : selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)

            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
                HapticsService.shared.lightFeedback()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .disabled(isToday)
            .opacity(isToday ? 0.3 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    MomentumDashboardView()
        .preferredColorScheme(.dark)
}
