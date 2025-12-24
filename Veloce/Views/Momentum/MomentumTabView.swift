//
//  MomentumTabView.swift
//  Veloce
//
//  Achievement Arena - Premium Gamification Experience
//  Central Level Orb, weekly charts, achievements, AI insights
//

import SwiftUI
import SwiftData

// MARK: - Momentum Tab View

struct MomentumTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query(sort: \Goal.targetDate) private var goals: [Goal]

    @State private var selectedDate: Date = Date()
    @State private var showShareSheet = false

    // Goal state
    @State private var goalsVM = GoalsViewModel()
    @State private var showGoalCreation = false
    @State private var showGoalDetail = false
    @State private var selectedGoal: Goal?
    @State private var showVelocityDetails = false

    private var gamification: GamificationService { GamificationService.shared }

    // Velocity Score calculation
    private var velocityScore: VelocityScore {
        VelocityScore(
            currentStreak: gamification.currentStreak,
            longestStreak: gamification.longestStreak,
            tasksCompletedThisWeek: weeklyTasksCompleted,
            weeklyGoal: gamification.weeklyGoal,
            focusMinutesThisWeek: Int(gamification.focusHours * 60),
            focusGoalMinutes: 5 * 60, // 5 hours default
            tasksOnTime: gamification.totalTasksCompleted, // Using total as fallback
            totalTasksCompleted: gamification.totalTasksCompleted
        )
    }

    // MARK: - Goal Computed Properties

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

    var body: some View {
        ZStack {
            VoidBackground.momentum

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Date pill
                    TodayPillView(selectedDate: $selectedDate)
                        .padding(.top, Theme.Spacing.universalHeaderHeight + 16)

                    // Central Level Orb - Hero element
                    LevelProgressOrb(
                        level: gamification.currentLevel,
                        progress: gamification.levelProgress,
                        totalPoints: gamification.totalPoints,
                        streak: gamification.currentStreak
                    )

                    // Velocity Score Card
                    Button {
                        showVelocityDetails = true
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        VelocityScoreCompact(score: velocityScore)
                    }
                    .buttonStyle(.plain)

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

                    // Weekly Activity Chart
                    WeeklyActivityCard(tasks: tasks, centerDate: selectedDate)

                    // Stats Dashboard
                    StatsDashboard(
                        tasksCompleted: gamification.totalTasksCompleted,
                        completionRate: gamification.completionRate,
                        focusHours: gamification.focusHours,
                        streak: gamification.currentStreak
                    )

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
        .sheet(isPresented: $showVelocityDetails) {
            VelocityScoreDetailSheet(score: velocityScore)
        }
        .task {
            await goalsVM.loadGoals(context: modelContext)
        }
    }

    private var weeklyTasksCompleted: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return tasks.filter { task in
            guard task.isCompleted, let completedAt = task.completedAt else { return false }
            return completedAt >= weekAgo
        }.count
    }
}

// MARK: - Level Progress Orb

struct LevelProgressOrb: View {
    let level: Int
    let progress: Double
    let totalPoints: Int
    let streak: Int

    @State private var orbBreathScale: CGFloat = 1.0
    @State private var ringRotation: Double = 0
    @State private var glowIntensity: Double = 0.5
    @State private var displayedPoints: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let orbColors: [Color] = [
        Color(hex: "8B5CF6"),
        Color(hex: "6366F1"),
        Color(hex: "3B82F6"),
        Color(hex: "06B6D4"),
        Color(hex: "14B8A6")
    ]

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { ring in
                    SwiftUI.Circle()
                        .stroke(
                            AngularGradient(
                                colors: orbColors + [orbColors[0]],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 200 + CGFloat(ring * 30), height: 200 + CGFloat(ring * 30))
                        .opacity(0.15 - Double(ring) * 0.04)
                        .rotationEffect(.degrees(ringRotation + Double(ring * 60)))
                        .blur(radius: CGFloat(ring + 1) * 2)
                }

                // Main orb container
                ZStack {
                    // Outer glow
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    orbColors[1].opacity(glowIntensity * 0.5),
                                    orbColors[2].opacity(glowIntensity * 0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)

                    // Progress ring background
                    SwiftUI.Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 160, height: 160)

                    // Progress ring
                    SwiftUI.Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: orbColors + [orbColors[0]],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))

                    // Core orb
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    orbColors[1].opacity(0.8),
                                    orbColors[2].opacity(0.6),
                                    orbColors[3].opacity(0.4)
                                ],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(orbBreathScale)
                        .shadow(color: orbColors[1].opacity(0.5), radius: 20)

                    // Inner content
                    VStack(spacing: 4) {
                        Text("\(displayedPoints)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text("XP")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Streak ring (when active)
                if streak > 0 {
                    SwiftUI.Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 180, height: 180)
                        .opacity(min(1.0, Double(streak) / 7.0))
                        .scaleEffect(orbBreathScale)
                }
            }

            // Level badge
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 18))
                Text("LEVEL \(level)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(2)
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())

            // Progress text
            Text("\(Int(progress * 100))% to Level \(level + 1)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            guard !reduceMotion else {
                displayedPoints = totalPoints
                return
            }

            // Animate points
            animatePoints()

            // Breathing animation
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                orbBreathScale = 1.05
            }

            // Ring rotation
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
        }
    }

    private func animatePoints() {
        let steps = 20
        let interval = 1.0 / Double(steps)
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                displayedPoints = Int(Double(totalPoints) * Double(i + 1) / Double(steps))
            }
        }
    }
}

// MARK: - Weekly Activity Card

struct WeeklyActivityCard: View {
    let tasks: [TaskItem]
    var centerDate: Date = Date()

    private var weekData: [(day: String, count: Int, isSelected: Bool)] {
        let calendar = Calendar.current
        var data: [(String, Int, Bool)] = []
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: centerDate) ?? centerDate
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            let count = tasks.filter { task in
                guard task.isCompleted, let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: date)
            }.count
            let isSelected = calendar.isDate(date, inSameDayAs: centerDate)
            data.append((dayName, count, isSelected))
        }
        return data
    }

    private var maxCount: Int {
        max(weekData.map { $0.count }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(weekData.enumerated()), id: \.offset) { index, data in
                    ActivityBar(
                        day: data.day,
                        count: data.count,
                        maxCount: maxCount,
                        isSelected: data.isSelected,
                        delay: Double(index) * 0.05
                    )
                }
            }
            .frame(height: 120)
        }
        .padding(24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct ActivityBar: View {
    let day: String
    let count: Int
    let maxCount: Int
    let isSelected: Bool
    let delay: Double

    @State private var barHeight: CGFloat = 0

    private var targetHeight: CGFloat {
        CGFloat(count) / CGFloat(maxCount) * 80
    }

    private let barGradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "06B6D4")],
        startPoint: .bottom,
        endPoint: .top
    )

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? barGradient : LinearGradient(colors: [.white.opacity(0.2)], startPoint: .bottom, endPoint: .top))
                .frame(width: 32, height: max(barHeight, 8))

            Text(day)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay)) {
                barHeight = targetHeight
            }
        }
    }
}

// MARK: - Stats Dashboard

struct StatsDashboard: View {
    let tasksCompleted: Int
    let completionRate: Double
    let focusHours: Double
    let streak: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            MomentumStatCard(value: "\(tasksCompleted)", label: "Tasks", icon: "checkmark.circle.fill", color: Color(hex: "10B981"))
            MomentumStatCard(value: "\(Int(completionRate * 100))%", label: "Rate", icon: "chart.line.uptrend.xyaxis", color: Color(hex: "3B82F6"))
            MomentumStatCard(value: String(format: "%.1f", focusHours), label: "Hours", icon: "clock.fill", color: Color(hex: "8B5CF6"))
            MomentumStatCard(value: "\(streak)", label: "Streak", icon: "flame.fill", color: Color(hex: "F59E0B"))
        }
    }
}

private struct MomentumStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - AI Insight Card

struct AIInsightCard: View {
    let insight: String?
    let onAction: () -> Void

    var body: some View {
        if let insight = insight, !insight.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "8B5CF6"))

                    Text("AI Insight")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "8B5CF6"))
                }

                Text(insight)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(3)

                Button(action: onAction) {
                    HStack {
                        Text("Learn more")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color(hex: "8B5CF6"))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "8B5CF6").opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Day Progress Card

struct DayProgressCard: View {
    let date: Date
    let completed: Int
    let goal: Int
    var isToday: Bool = true

    @State private var ringProgress: Double = 0

    private var progress: Double {
        goal > 0 ? min(Double(completed) / Double(goal), 1.0) : 0
    }

    private var isComplete: Bool { completed >= goal }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                SwiftUI.Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 60, height: 60)

                SwiftUI.Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        isComplete ?
                        LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "06B6D4")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "3B82F6")], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: "10B981"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(completed)/\(goal)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(isToday && isComplete ? "Daily goal achieved!" : "Tasks today")
                    .font(.system(size: 14))
                    .foregroundStyle(isComplete && isToday ? Color(hex: "10B981") : .secondary)
            }

            Spacer()
        }
        .padding(24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                ringProgress = progress
            }
        }
    }
}

// MARK: - Achievement Showcase Card

struct AchievementShowcaseCard: View {
    let achievements: Set<AchievementType>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(achievements.count) unlocked")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            if achievements.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "trophy")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)
                        Text("Complete tasks to earn achievements")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(achievements).prefix(5), id: \.self) { achievement in
                            AchievementBadge(achievement: achievement)
                        }
                    }
                }
            }
        }
        .padding(24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct AchievementBadge: View {
    let achievement: AchievementType

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [achievement.color.opacity(0.3), achievement.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(achievement.color)
            }

            Text(achievement.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}

// MARK: - Share Week Button

struct ShareWeekButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("Share My Week")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "8B5CF6"), Color(hex: "3B82F6")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color(hex: "8B5CF6").opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Week In Review Sheet

struct WeekInReviewSheet: View {
    let score: Int
    let streak: Int
    let tasksCompleted: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Week in Review")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            HStack(spacing: 24) {
                WeekStatItem(value: "\(tasksCompleted)", label: "Tasks Done")
                WeekStatItem(value: "\(streak)", label: "Day Streak")
                WeekStatItem(value: "\(score)", label: "Total XP")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button { } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "3B82F6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct WeekStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    MomentumTabView()
        .preferredColorScheme(.dark)
}
