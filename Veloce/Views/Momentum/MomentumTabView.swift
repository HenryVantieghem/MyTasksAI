//
//  MomentumTabView.swift
//  MyTasksAI
//
//  Momentum Tab - The emotional center of the app
//  Giant animated score, level progress, weekly insights
//

import SwiftUI
import SwiftData

struct MomentumTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query(sort: \Goal.targetDate) private var goals: [Goal]

    @State private var selectedDate: Date = Date()
    @State private var showShareSheet = false
    @State private var animateScore = false

    // Goal state
    @State private var goalsVM = GoalsViewModel()
    @State private var showGoalCreation = false
    @State private var showGoalDetail = false
    @State private var selectedGoal: Goal?

    private var gamification: GamificationService { GamificationService.shared }

    // MARK: - Goal Computed Properties

    /// The most urgent active goal to spotlight
    private var spotlightGoal: Goal? {
        let activeGoals = goals.filter { !$0.isCompleted }
        // Prioritize goals due within 7 days that are less than 90% complete
        return activeGoals.first { goal in
            guard let days = goal.daysRemaining else { return false }
            return days <= 7 && goal.progress < 0.9
        } ?? activeGoals.first { $0.isCheckInDue } ?? activeGoals.first
    }

    /// Calculate linked tasks progress for spotlight goal
    private var linkedTasksProgress: Double {
        guard let goal = spotlightGoal else { return 0 }
        return goalsVM.calculateLinkedTasksProgress(for: goal, tasks: tasks)
    }

    // MARK: - Date-Filtered Statistics

    /// Tasks completed on the selected date
    private var tasksCompletedOnDate: Int {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard task.isCompleted, let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: selectedDate)
        }.count
    }

    /// Check if viewing today
    private var isViewingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        ZStack {
            // Background
            VoidBackground.momentum

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Date selector
                    TodayDateSelector(selectedDate: $selectedDate)
                        .padding(.top, Theme.Spacing.universalHeaderHeight)

                    // Goal Spotlight Section - Most urgent goal
                    GoalSpotlightSection(
                        spotlightGoal: spotlightGoal,
                        linkedTasksProgress: linkedTasksProgress,
                        onGoalTap: { goal in
                            selectedGoal = goal
                            showGoalDetail = true
                        },
                        onAddGoal: {
                            showGoalCreation = true
                        }
                    )

                    // Giant Momentum Score
                    MomentumScoreCard(
                        score: gamification.totalPoints,
                        level: gamification.currentLevel,
                        progress: gamification.levelProgress
                    )

                    // Streak Flame
                    StreakFlameCard(streak: gamification.currentStreak)

                    // Weekly Insights Chart - centered on selected date
                    WeeklyInsightsChart(tasks: tasks, centerDate: selectedDate)

                    // Day's Progress - filtered by selected date
                    DayProgressCard(
                        date: selectedDate,
                        completed: isViewingToday ? gamification.tasksCompletedToday : tasksCompletedOnDate,
                        goal: gamification.dailyGoal,
                        isToday: isViewingToday
                    )

                    // Achievement Showcase
                    AchievementShowcaseCard(achievements: gamification.unlockedAchievements)

                    // Share Week Button
                    ShareWeekButton {
                        showShareSheet = true
                    }
                    .padding(.bottom, 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, Theme.Spacing.universalHeaderHeight)
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

// MARK: - Momentum Score Card

struct MomentumScoreCard: View {
    let score: Int
    let level: Int
    let progress: Double

    @State private var displayedScore: Int = 0
    @State private var ringProgress: Double = 0
    @State private var glowPhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            // Level badge
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 16))
                Text("LEVEL \(level)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(hex: "FFD700").opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 1)
                    )
            )

            // Giant score
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: "8B5CF6"),
                                Color(hex: "3B82F6"),
                                Color(hex: "06B6D4"),
                                Color(hex: "8B5CF6")
                            ],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 8)
                    .opacity(0.5 + glowPhase * 0.3)

                // Progress ring background
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 180, height: 180)

                // Progress ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6"), Color(hex: "06B6D4")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // Score number
                VStack(spacing: 4) {
                    Text("\(displayedScore)")
                        .font(.system(size: 64, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("MOMENTUM")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // XP to next level
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))% to Level \(level + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            if reduceMotion {
                displayedScore = score
                ringProgress = progress
                return
            }

            // Animate score counting up
            animateCount(to: score, duration: 1.5)

            // Animate ring
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
                ringProgress = progress
            }

            // Glow animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }

    private func animateCount(to target: Int, duration: Double) {
        let steps = 30
        let interval = duration / Double(steps)
        let increment = Double(target) / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                displayedScore = Int(increment * Double(i + 1))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayedScore = target
        }
    }
}

// MARK: - Streak Flame Card

struct StreakFlameCard: View {
    let streak: Int

    @State private var flameIntensity: Double = 0
    @State private var particlePhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isOnFire: Bool { streak >= 3 }

    var body: some View {
        HStack(spacing: 20) {
            // Flame visualization
            ZStack {
                if isOnFire && !reduceMotion {
                    // Animated particles
                    ForEach(0..<8, id: \.self) { i in
                        FlameParticle(index: i, phase: particlePhase, intensity: flameIntensity)
                    }
                }

                // Main flame
                Image(systemName: isOnFire ? "flame.fill" : "flame")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        isOnFire ?
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "F7931E"), Color(hex: "FFD700")],
                            startPoint: .bottom,
                            endPoint: .top
                        ) :
                        LinearGradient(colors: [.white.opacity(0.3)], startPoint: .bottom, endPoint: .top)
                    )
                    .scaleEffect(1 + flameIntensity * 0.1)
                    .shadow(color: isOnFire ? Color(hex: "FF6B35").opacity(0.6) : .clear, radius: 12)
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(streak == 1 ? "Day Streak" : "Day Streak")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                if isOnFire {
                    Text("You're on fire! 🔥")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "FF6B35"))
                }
            }

            Spacer()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isOnFire ?
                            LinearGradient(colors: [Color(hex: "FF6B35").opacity(0.5), Color(hex: "FFD700").opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            guard isOnFire, !reduceMotion else { return }

            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                flameIntensity = 1
            }

            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                particlePhase = 1
            }
        }
    }
}

struct FlameParticle: View {
    let index: Int
    let phase: Double
    let intensity: Double

    var body: some View {
        let seed = Double(index)
        let angle = (seed / 8) * 2 * .pi + phase * 2 * .pi
        let radius: CGFloat = 20 + CGFloat(sin(seed * 1.7)) * 10
        let x = cos(angle) * radius * 0.5
        let y = -abs(sin(angle)) * radius - phase * 30

        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FF6B35").opacity(0.5), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 4
                )
            )
            .frame(width: 8, height: 8)
            .offset(x: x, y: y)
            .opacity(1 - phase)
    }
}

// MARK: - Weekly Insights Chart

struct WeeklyInsightsChart: View {
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

    private var isViewingCurrentWeek: Bool {
        let calendar = Calendar.current
        return calendar.isDate(centerDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isViewingCurrentWeek ? "This Week" : "Week of \(centerDate.formatted(.dateTime.month(.abbreviated).day()))")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(weekData.enumerated()), id: \.offset) { index, data in
                    WeeklyBar(
                        day: data.day,
                        count: data.count,
                        maxCount: maxCount,
                        isSelected: data.isSelected
                    )
                }
            }
            .frame(height: 120)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct WeeklyBar: View {
    let day: String
    let count: Int
    let maxCount: Int
    let isSelected: Bool

    @State private var barHeight: CGFloat = 0

    private var targetHeight: CGFloat {
        CGFloat(count) / CGFloat(maxCount) * 80
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isSelected ?
                    LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "06B6D4")], startPoint: .bottom, endPoint: .top) :
                    LinearGradient(colors: [.white.opacity(0.3)], startPoint: .bottom, endPoint: .top)
                )
                .frame(width: 32, height: max(barHeight, 8))

            Text(day)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(Double.random(in: 0...0.3))) {
                barHeight = targetHeight
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

    private var dayLabel: String {
        if isToday {
            return isComplete ? "Daily goal achieved! 🎉" : "Tasks today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Tasks on \(formatter.string(from: date))"
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 60, height: 60)

                Circle()
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
                    .foregroundStyle(.white)

                Text(dayLabel)
                    .font(.system(size: 14))
                    .foregroundStyle(isComplete && isToday ? Color(hex: "10B981") : .white.opacity(0.6))
            }

            Spacer()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isComplete && isToday ?
                            LinearGradient(colors: [Color(hex: "10B981").opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                ringProgress = progress
            }
        }
        .onChange(of: completed) { _, newValue in
            let newProgress = goal > 0 ? min(Double(newValue) / Double(goal), 1.0) : 0
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                ringProgress = newProgress
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
                    .foregroundStyle(.white)

                Spacer()

                Text("\(achievements.count) unlocked")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }

            if achievements.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "trophy")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Complete tasks to earn achievements")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct AchievementBadge: View {
    let achievement: AchievementType

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
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
                    .foregroundStyle(
                        LinearGradient(
                            colors: [achievement.color, achievement.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(achievement.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}

// MARK: - Share Week Button

struct ShareWeekButton: View {
    let action: () -> Void

    @State private var isPressed = false

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
            .shadow(color: Color(hex: "8B5CF6").opacity(0.4), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
            // Header
            HStack {
                Text("Week in Review")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // Stats
            HStack(spacing: 24) {
                WeekStatItem(value: "\(tasksCompleted)", label: "Tasks Done")
                WeekStatItem(value: "\(streak)", label: "Day Streak")
                WeekStatItem(value: "\(score)", label: "Total XP")
            }
            .padding(.horizontal, 24)

            Spacer()

            // Share button
            Button {
                // Share functionality
            } label: {
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
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    }
}

struct WeekStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    MomentumTabView()
}
