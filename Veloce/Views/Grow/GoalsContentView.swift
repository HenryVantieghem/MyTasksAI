//
//  GoalsContentView.swift
//  Veloce
//
//  Utopian Design System - Goals Dashboard
//  Goals segment with progress tracking and gold gamification
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
            // Title row with Utopian styling
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    // Utopian glow title
                    ZStack(alignment: .leading) {
                        Text("Your Goals")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(UtopianDesignFallback.Colors.completed)
                            .blur(radius: 8)
                            .opacity(0.4)

                        Text("Your Goals")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Text(headerSubtitle)
                        .font(UtopianDesignFallback.Typography.body)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button {
                    showGoalCreation = true
                    HapticsService.shared.impact(.light)
                } label: {
                    ZStack {
                        // Glow halo
                        Circle()
                            .fill(UtopianDesignFallback.Colors.completed)
                            .frame(width: addButtonSize, height: addButtonSize)
                            .blur(radius: 12)
                            .opacity(0.4)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        UtopianDesignFallback.Colors.completed,
                                        UtopianDesignFallback.Colors.focusActive.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: addButtonSize, height: addButtonSize)
                            .shadow(color: UtopianDesignFallback.Colors.completed.opacity(0.5), radius: 16, y: 6)

                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 20, weight: .bold)
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .iPadHoverEffect(.lift)
            }
            .padding(.top, layout.spacing)

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
        HStack(spacing: 12) {
            UtopianGoalStatCard(
                icon: "flame.fill",
                value: "\(activeCount)",
                label: "Active",
                iconColor: UtopianDesignFallback.Colors.focusActive
            )

            UtopianGoalStatCard(
                icon: "checkmark.seal.fill",
                value: "\(completedCount)",
                label: "Completed",
                iconColor: UtopianDesignFallback.Colors.completed
            )

            UtopianGoalStatCard(
                icon: "chart.line.uptrend.xyaxis",
                value: "\(Int(averageProgress * 100))%",
                label: "Progress",
                iconColor: UtopianDesignFallback.Colors.aiPurple
            )
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
            // Utopian constellation illustration
            ZStack {
                // Outer glow rings with utopian colors
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            UtopianDesignFallback.Colors.completed.opacity(0.15 - Double(index) * 0.04),
                            lineWidth: 1
                        )
                        .frame(width: 120 + CGFloat(index) * 40, height: 120 + CGFloat(index) * 40)
                }

                // Central utopian orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    UtopianDesignFallback.Colors.completed.opacity(0.3),
                                    UtopianDesignFallback.Colors.focusActive.opacity(0.15),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: selectedFilter == .completed ? "checkmark.seal" : "leaf.fill")
                        .dynamicTypeFont(base: 40)
                        .foregroundStyle(UtopianDesignFallback.Colors.completed.opacity(0.7))
                }
            }

            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(UtopianDesignFallback.Typography.title3)
                    .foregroundStyle(.white)

                Text(emptyStateSubtitle)
                    .font(UtopianDesignFallback.Typography.callout)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            if selectedFilter == .active {
                Button {
                    showGoalCreation = true
                    HapticsService.shared.impact(.medium)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .dynamicTypeFont(base: 16)
                        Text("Create Your First Goal")
                            .font(UtopianDesignFallback.Typography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [UtopianDesignFallback.Colors.completed, UtopianDesignFallback.Colors.focusActive.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: UtopianDesignFallback.Colors.completed.opacity(0.4), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 60)
        .offset(y: animateIn ? 0 : 30)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.2), value: animateIn)
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

// MARK: - Utopian Goal Filter Pill

private struct GoalFilterPill: View {
    let filter: GoalFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button {
            action()
            HapticsService.shared.impact(.light)
        } label: {
            HStack(spacing: 8) {
                Text(filter.rawValue)
                    .font(UtopianDesignFallback.Typography.subheadline)
                    .fontWeight(isSelected ? .bold : .semibold)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isSelected ? UtopianDesignFallback.Colors.completed.opacity(0.3) : .white.opacity(0.5).opacity(0.2))
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    Capsule()
                        .fill(UtopianDesignFallback.Colors.completed.opacity(0.2))
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            UtopianDesignFallback.Colors.completed.opacity(0.5),
                                            UtopianDesignFallback.Colors.focusActive.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: UtopianDesignFallback.Colors.completed.opacity(0.3), radius: 8, y: 2)
                } else {
                    Capsule()
                        .fill(Color.white.opacity(0.1).opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
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

// MARK: - Utopian Goal Stat Card

struct UtopianGoalStatCard: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glow halo
                Circle()
                    .fill(iconColor)
                    .frame(width: 36, height: 36)
                    .blur(radius: 8)
                    .opacity(0.3)

                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(UtopianDesignFallback.Typography.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [iconColor.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        UtopianGradients.background(for: Date())
            .ignoresSafeArea()

        GoalsContentView(
            goals: [],
            goalsVM: GoalsViewModel()
        )
    }
    .preferredColorScheme(.dark)
}
