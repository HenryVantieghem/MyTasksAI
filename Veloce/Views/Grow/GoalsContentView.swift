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
                        .dynamicTypeFont(base: 28, weight: .bold)
                        .foregroundStyle(.white)

                    Text(headerSubtitle)
                        .dynamicTypeFont(base: 14, weight: .regular)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Button {
                    showGoalCreation = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.aiPurple, Theme.Colors.aiPurple.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: addButtonSize, height: addButtonSize)
                            .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 4)

                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 20, weight: .semibold)
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

    private var goalsSection: some View {
        // Use grid on iPad, list on iPhone
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
            HStack(spacing: 6) {
                Text(filter.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.2) : .white.opacity(0.1))
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.Colors.aiPurple : .white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Stat Card

private struct GoalStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Premium Goal Card

struct PremiumGoalCard: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var glowPulse: Double = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var daysRemaining: Int {
        guard let targetDate = goal.targetDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0)
    }

    private var themeColor: Color {
        goal.timeframeEnum?.color ?? goal.categoryEnum?.color ?? Theme.Colors.aiPurple
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header row
                HStack(spacing: 12) {
                    // Progress orb
                    GoalStatusOrb(goal: goal, size: 52)

                    // Title and category
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.displayTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 8) {
                            if let category = goal.categoryEnum {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 10))
                                    Text(category.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundStyle(category.color.opacity(0.8))
                            }

                            if let timeframe = goal.timeframeEnum {
                                Text("•")
                                    .foregroundStyle(.white.opacity(0.3))

                                HStack(spacing: 3) {
                                    Image(systemName: timeframe.icon)
                                        .font(.system(size: 9))
                                    Text(timeframe.displayName)
                                        .font(.system(size: 11))
                                }
                                .foregroundStyle(timeframe.color.opacity(0.7))
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    // Days badge or completed
                    if goal.isCompleted {
                        completedBadge
                    } else {
                        daysBadge
                    }
                }

                // Progress bar
                progressSection

                // Bottom info row
                bottomRow
            }
            .padding(18)
            .background(cardBackground)
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
        .onAppear { startAnimations() }
    }

    private var completedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
            Text("Done")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Theme.Colors.success)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.Colors.success.opacity(0.15))
        )
    }

    private var daysBadge: some View {
        VStack(spacing: 2) {
            Text("\(daysRemaining)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(daysRemaining <= 3 ? Theme.Colors.warning : .white)

            Text("days")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(width: 44)
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [themeColor, themeColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geometry.size.width * goal.progress), height: 6)
                        .shadow(color: themeColor.opacity(0.5), radius: 4, y: 0)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(Int(goal.progress * 100))% complete")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                if goal.milestoneCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 9))
                        Text("\(goal.completedMilestoneCount)/\(goal.milestoneCount)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 12) {
            // Check-in indicator
            if goal.isCheckInDue {
                HStack(spacing: 4) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 10))
                    Text("Check-in due")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Theme.Colors.warning)
            }

            // AI status
            if goal.hasRoadmap {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("AI Roadmap")
                        .font(.system(size: 11))
                }
                .foregroundStyle(Theme.Colors.aiPurple.opacity(0.7))
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial.opacity(0.5))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            colors: [
                                themeColor.opacity(0.1 * glowPulse),
                                .clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                themeColor.opacity(0.3),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPulse = 1.0
        }
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
