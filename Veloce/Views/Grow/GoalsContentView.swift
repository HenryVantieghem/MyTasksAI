//
//  GoalsContentView.swift
//  Veloce
//
//  Goals segment for Grow tab
//  Displays active goals with progress and add goal functionality
//

import SwiftUI

struct GoalsContentView: View {
    let goals: [Goal]
    @Bindable var goalsVM: GoalsViewModel

    @State private var showGoalCreation = false
    @State private var showGoalDetail = false
    @State private var selectedGoal: Goal?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Header with Add Button
                HStack {
                    Text("Active Goals")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        showGoalCreation = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }
                }
                .padding(.top, 20)

                // Goals List
                if goals.isEmpty {
                    emptyGoalsState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(goals) { goal in
                            GoalCard(
                                goal: goal,
                                onTap: {
                                    selectedGoal = goal
                                    showGoalDetail = true
                                }
                            )
                        }
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showGoalCreation) {
            GoalCreationSheet(goalsVM: goalsVM)
        }
        .sheet(isPresented: $showGoalDetail) {
            if let goal = selectedGoal {
                GoalDetailSheet(goal: goal, goalsVM: goalsVM)
            }
        }
    }

    // MARK: - Empty State

    private var emptyGoalsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))

            Text("No goals yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.6))

            Text("Set goals to track your progress and stay motivated")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showGoalCreation = true
            } label: {
                Text("Create Goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.aiPurple, in: Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void

    private var daysRemaining: Int {
        guard let targetDate = goal.targetDate else { return 0 }
        let calendar = Calendar.current
        return max(0, calendar.dateComponents([.day], from: Date(), to: targetDate).day ?? 0)
    }

    private var categoryIcon: String {
        switch goal.category?.lowercased() {
        case "health": return "heart.fill"
        case "work": return "briefcase.fill"
        case "learning": return "book.fill"
        case "fitness": return "figure.run"
        case "finance": return "dollarsign.circle.fill"
        default: return "leaf.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(Theme.Colors.aiPurple)

                    Text(goal.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.aiPurple)
                            .frame(width: geo.size.width * goal.progress)
                    }
                }
                .frame(height: 8)

                // Detail
                Text("\(Int(goal.progress * 100))% complete • \(daysRemaining) days remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        GoalsContentView(
            goals: [],
            goalsVM: GoalsViewModel()
        )
    }
}
