//
//  GoalsContentView.swift
//  Veloce
//
//  Goals segment for Grow tab - Premium Redesign
//  Comprehensive goal tracking with beautiful visualizations
//

import SwiftUI
import SwiftData

struct GoalsContentView: View {
    let goals: [Goal]
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.responsiveLayout) private var layout

    @State private var showGoalCreation = false
    @State private var selectedGoal: Goal?
    @State private var animateIn = false
    @State private var selectedFilter: GoalFilter = .active

    private var filteredGoals: [Goal] {
        switch selectedFilter {
        case .active:
            return goals.filter { !$0.isCompleted }
                .sorted { ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture) }
        case .completed:
            return goals.filter { $0.isCompleted }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        case .all:
            return goals.sorted { ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture) }
        }
    }

    private var activeCount: Int { goals.filter { !$0.isCompleted }.count }
    private var completedCount: Int { goals.filter { $0.isCompleted }.count }

    // Adaptive columns for iPad goals grid
    private var goalsColumns: [GridItem] {
        let columnCount: Int
        switch layout.deviceType {
        case .iPhoneSE, .iPhoneStandard, .iPhoneProMax:
            columnCount = 1
        case .iPadMini, .iPad:
            columnCount = 2
        case .iPadPro11, .iPadPro13:
            columnCount = layout.isLandscape ? 3 : 2
        }
        return Array(repeating: GridItem(.flexible(), spacing: layout.spacing), count: columnCount)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: layout.spacing * 1.5) {
                // Header with stats
                headerSection

                // Filter pills
                filterSection

                // Goals grid/list
                if filteredGoals.isEmpty {
                    emptyState
                } else {
                    goalsSection
                }

                Spacer(minLength: layout.bottomSafeArea)
            }
            .padding(.horizontal, layout.screenPadding)
            .maxWidthConstrained()
        }
        .sheet(isPresented: $showGoalCreation) {
            GoalCreationSheet(goalsVM: goalsVM)
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailSheet(goal: goal, goalsVM: goalsVM)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }

    // MARK: - Header Section

    // Responsive button size
    private var addButtonSize: CGFloat {
        layout.deviceType.isTablet ? 56 : 48
    }

    private var headerSection: some View {
        VStack(spacing: layout.spacing * 1.25) {
            // Title row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Goals")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(headerSubtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button {
                    showGoalCreation = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.aiPurple,
                                        Theme.Colors.aiPurple.opacity(0.8),
                                        Theme.Colors.aiBlue.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: addButtonSize, height: addButtonSize)
                            .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 16, y: 6)

                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .iPadHoverEffect(.lift)
            }
            .padding(.top, layout.spacing)
            .glassEffect(.regular.tint(Theme.Colors.aiPurple).interactive(), in: .rect(cornerRadius: 20))

            // Stats cards
            if !goals.isEmpty {
                statsRow
            }
        }
        .offset(y: animateIn ? 0 : 20)
        .opacity(animateIn ? 1 : 0)
    }

    private var headerSubtitle: String {
        if activeCount == 0 && completedCount == 0 {
            return "Start your journey"
        } else if activeCount == 0 {
            return "All goals completed!"
        } else if activeCount == 1 {
            return "1 active goal"
        } else {
            return "\(activeCount) active goals"
        }
    }

    private var statsRow: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                GoalStatCard(
                    icon: "flame.fill",
                    value: "\(activeCount)",
                    label: "Active",
                    color: Theme.Colors.aiCyan
                )
                
                GoalStatCard(
                    icon: "checkmark.seal.fill",
                    value: "\(completedCount)",
                    label: "Completed",
                    color: Theme.Colors.success
                )
                
                GoalStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(Int(averageProgress * 100))%",
                    label: "Progress",
                    color: Theme.Colors.aiPurple
                )
            }
        }
    }

    private var averageProgress: Double {
        let active = goals.filter { !$0.isCompleted }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0) { $0 + $1.progress } / Double(active.count)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        HStack(spacing: 8) {
            ForEach(GoalFilter.allCases, id: \.self) { filter in
                GoalFilterPill(
                    filter: filter,
                    isSelected: selectedFilter == filter,
                    count: countFor(filter)
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedFilter = filter
                    }
                }
            }

            Spacer()
        }
        .offset(y: animateIn ? 0 : 20)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateIn)
    }

    private func countFor(_ filter: GoalFilter) -> Int {
        switch filter {
        case .active: return activeCount
        case .completed: return completedCount
        case .all: return goals.count
        }
    }

    // MARK: - Goals Section

    @State private var goalToDelete: Goal?
    @State private var showDeleteConfirmation = false
    @State private var showCheckInSheet = false
    @State private var checkInGoal: Goal?

    private var goalsSection: some View {
        // Use grid on iPad, slidable cards on iPhone
        Group {
            if layout.deviceType.isTablet {
                LazyVGrid(columns: goalsColumns, spacing: layout.spacing) {
                    ForEach(Array(filteredGoals.enumerated()), id: \.element.id) { index, goal in
                        PremiumGoalCard(
                            goal: goal,
                            goalsVM: goalsVM,
                            onTap: {
                                selectedGoal = goal
                            }
                        )
                        .offset(y: animateIn ? 0 : 30)
                        .opacity(animateIn ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8).delay(0.15 + Double(index) * 0.05),
                            value: animateIn
                        )
                    }
                }
            } else {
                LazyVStack(spacing: layout.spacing) {
                    ForEach(Array(filteredGoals.enumerated()), id: \.element.id) { index, goal in
                        SlidableGoalCard(
                            goal: goal,
                            goalsVM: goalsVM,
                            onTap: {
                                selectedGoal = goal
                            },
                            onGenerateAI: {
                                Task {
                                    await goalsVM.generateAllAIContent(for: goal, context: modelContext)
                                }
                            },
                            onCheckIn: {
                                checkInGoal = goal
                                showCheckInSheet = true
                            },
                            onDelete: {
                                goalToDelete = goal
                                showDeleteConfirmation = true
                            }
                        )
                        .offset(y: animateIn ? 0 : 30)
                        .opacity(animateIn ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8).delay(0.15 + Double(index) * 0.05),
                            value: animateIn
                        )
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Goal",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete {
                    goalsVM.deleteGoal(goal, context: modelContext)
                }
                goalToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                goalToDelete = nil
            }
        } message: {
            if let goal = goalToDelete {
                Text("This will permanently delete \"\(goal.displayTitle)\" and all its milestones.")
            }
        }
        .sheet(isPresented: $showCheckInSheet) {
            if let goal = checkInGoal {
                WeeklyCheckInSheet(goal: goal, goalsVM: goalsVM)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            // Animated illustration
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Theme.Colors.aiPurple.opacity(0.1 - Double(index) * 0.03),
                            lineWidth: 1
                        )
                        .frame(width: 120 + CGFloat(index) * 40, height: 120 + CGFloat(index) * 40)
                }

                // Central orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.aiPurple.opacity(0.3),
                                    Theme.Colors.aiPurple.opacity(0.1),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: selectedFilter == .completed ? "checkmark.seal" : "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.aiPurple.opacity(0.6))
                }
            }

            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text(emptyStateSubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            if selectedFilter == .active {
                Button {
                    showGoalCreation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Create Your First Goal")
                            .font(.system(size: 15, weight: .semibold))
                    }
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
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 60)
        .offset(y: animateIn ? 0 : 30)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateIn)
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .active: return "No Active Goals"
        case .completed: return "No Completed Goals Yet"
        case .all: return "No Goals Yet"
        }
    }

    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .active: return "Set meaningful goals and let AI guide you to success"
        case .completed: return "Complete your first goal to see it here"
        case .all: return "Start your growth journey by setting a goal"
        }
    }
}

// MARK: - Goal Filter

enum GoalFilter: String, CaseIterable {
    case active = "Active"
    case completed = "Completed"
    case all = "All"
}

// MARK: - Goal Filter Pill

private struct GoalFilterPill: View {
    let filter: GoalFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(filter.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .bold : .semibold))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.3) : .white.opacity(0.15))
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.aiPurple,
                                        Theme.Colors.aiPurple.opacity(0.8),
                                        Theme.Colors.aiBlue.opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 12, y: 4)
                    } else {
                        Capsule()
                            .fill(.white.opacity(0.1))
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .glassEffect(isSelected ? .regular.tint(Theme.Colors.aiPurple).interactive() : .regular, in: .capsule)
    }
}

// MARK: - Goal Stat Card

private struct GoalStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.15),
                            color.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.4), radius: 12, y: 6)
        )
        .glassEffect(.regular.tint(color).interactive(), in: .rect(cornerRadius: 18))
    }
}

// MARK: - Premium Goal Card

struct PremiumGoalCard: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GoalCardView(goal: goal)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.standard
        GoalsContentView(
            goals: [],
            goalsVM: GoalsViewModel()
        )
    }
}
