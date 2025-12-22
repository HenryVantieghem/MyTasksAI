//
//  AIRoadmapApprovalSheet.swift
//  MyTasksAI
//
//  AI Roadmap Approval Sheet
//  Shows AI-generated roadmap with approval flow for suggested tasks
//

import SwiftUI
import SwiftData

struct AIRoadmapApprovalSheet: View {
    let goal: Goal
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var roadmap: GoalRoadmap?
    @State private var isLoading = false
    @State private var isApproving = false
    @State private var selectedSuggestions: Set<UUID> = []
    @State private var error: String?

    private var allSuggestions: [PendingTaskSuggestion] {
        goalsVM.pendingTaskSuggestions
    }

    private var selectedCount: Int {
        allSuggestions.filter { selectedSuggestions.contains($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VoidBackground.standard

                if isLoading {
                    loadingView
                } else if let roadmap = roadmap ?? goal.roadmap {
                    roadmapContent(roadmap)
                } else {
                    emptyState
                }
            }
            .navigationTitle("AI Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .task {
            if goal.roadmap == nil && roadmap == nil {
                await loadRoadmap()
            } else {
                roadmap = goal.roadmap
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            // Animated orb
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Theme.Colors.aiPurple.opacity(0.3 - Double(index) * 0.1),
                            lineWidth: 2
                        )
                        .frame(width: 80 + CGFloat(index) * 30, height: 80 + CGFloat(index) * 30)
                        .rotationEffect(.degrees(Double(index) * 120))
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }

            VStack(spacing: 8) {
                Text("Generating Your Roadmap")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text("AI is analyzing your goal and creating a personalized plan...")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            ProgressView()
                .tint(Theme.Colors.aiPurple)
        }
        .padding(40)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text("No Roadmap Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Generate an AI-powered roadmap to get personalized milestones and task suggestions")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            if let error = error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.error)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.error.opacity(0.1))
                    )
            }

            Button {
                Task { await loadRoadmap() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    Text("Generate Roadmap")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiPurple.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }

    // MARK: - Roadmap Content

    private func roadmapContent(_ roadmap: GoalRoadmap) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Success header
                roadmapHeader(roadmap)

                // Phases
                ForEach(Array(roadmap.phases.enumerated()), id: \.offset) { index, phase in
                    PhaseCard(
                        phase: phase,
                        phaseNumber: index + 1,
                        selectedSuggestions: $selectedSuggestions,
                        allSuggestions: allSuggestions
                    )
                }

                // Coaching notes
                if !roadmap.coachingNotes.isEmpty {
                    coachingNotesCard(roadmap.coachingNotes)
                }

                // Approval button
                if !allSuggestions.isEmpty {
                    approvalSection
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    // MARK: - Header

    private func roadmapHeader(_ roadmap: GoalRoadmap) -> some View {
        VStack(spacing: 16) {
            // Success probability
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: roadmap.successProbability)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.Colors.success, Theme.Colors.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(roadmap.successProbability * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Success")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Stats
            HStack(spacing: 24) {
                StatPill(
                    icon: "clock",
                    value: "\(Int(roadmap.totalEstimatedHours))h",
                    label: "Total Time"
                )

                StatPill(
                    icon: "flag.checkered",
                    value: "\(roadmap.phases.flatMap(\.milestones).count)",
                    label: "Milestones"
                )

                StatPill(
                    icon: "calendar",
                    value: "\(roadmap.phases.count)",
                    label: "Phases"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.success.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Coaching Notes

    private func coachingNotesCard(_ notes: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "FFD700"))

            VStack(alignment: .leading, spacing: 6) {
                Text("Coach's Notes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))

                Text(notes)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "FFD700").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "FFD700").opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Approval Section

    private var approvalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(selectedCount) of \(allSuggestions.count) tasks selected")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Button {
                    if selectedCount == allSuggestions.count {
                        selectedSuggestions.removeAll()
                    } else {
                        selectedSuggestions = Set(allSuggestions.map(\.id))
                    }
                } label: {
                    Text(selectedCount == allSuggestions.count ? "Deselect All" : "Select All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
                .buttonStyle(.plain)
            }

            Button {
                approveSelected()
            } label: {
                HStack(spacing: 10) {
                    if isApproving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle")
                    }

                    Text(isApproving ? "Creating Tasks..." : "Create \(selectedCount) Tasks")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selectedCount > 0 ?
                    LinearGradient(
                        colors: [Theme.Colors.success, Theme.Colors.success.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(selectedCount == 0 || isApproving)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.8))
        )
    }

    // MARK: - Actions

    private func loadRoadmap() async {
        isLoading = true
        error = nil

        await goalsVM.generateRoadmap(for: goal, context: modelContext)

        roadmap = goal.roadmap
        isLoading = false

        if roadmap == nil {
            error = goalsVM.error
        }

        // Pre-select all suggestions
        selectedSuggestions = Set(allSuggestions.map(\.id))
    }

    private func approveSelected() {
        isApproving = true

        for suggestion in allSuggestions where selectedSuggestions.contains(suggestion.id) {
            goalsVM.approveTaskSuggestion(suggestion, for: goal, context: modelContext)
        }

        isApproving = false
        dismiss()
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Phase Card

private struct PhaseCard: View {
    let phase: RoadmapPhase
    let phaseNumber: Int
    @Binding var selectedSuggestions: Set<UUID>
    let allSuggestions: [PendingTaskSuggestion]

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Phase header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Phase number badge
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.aiPurple.opacity(0.2))
                            .frame(width: 32, height: 32)

                        Text("\(phaseNumber)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(phase.focus)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                // Milestones
                if !phase.milestones.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Milestones", systemImage: "flag.checkered")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))

                        ForEach(phase.milestones, id: \.title) { milestone in
                            HStack(spacing: 10) {
                                Image(systemName: "circle")
                                    .font(.system(size: 8))
                                    .foregroundStyle(Theme.Colors.aiCyan)

                                Text(milestone.title)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                }

                // Daily habits
                if !phase.dailyHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Daily Habits", systemImage: "repeat")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))

                        ForEach(phase.dailyHabits, id: \.title) { habit in
                            TaskSuggestionRow(
                                title: habit.title,
                                duration: "\(habit.durationMinutes)min",
                                icon: "repeat.circle",
                                isSelected: isSuggestionSelected(habit.title),
                                onToggle: { toggleSuggestion(habit.title) }
                            )
                        }
                    }
                }

                // One-time tasks
                if !phase.oneTimeTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tasks", systemImage: "checklist")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))

                        ForEach(phase.oneTimeTasks, id: \.title) { task in
                            TaskSuggestionRow(
                                title: task.title,
                                duration: "\(task.estimatedMinutes)min",
                                icon: "circle",
                                isSelected: isSuggestionSelected(task.title),
                                onToggle: { toggleSuggestion(task.title) }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func isSuggestionSelected(_ title: String) -> Bool {
        if let suggestion = allSuggestions.first(where: { $0.title == title }) {
            return selectedSuggestions.contains(suggestion.id)
        }
        return false
    }

    private func toggleSuggestion(_ title: String) {
        if let suggestion = allSuggestions.first(where: { $0.title == title }) {
            if selectedSuggestions.contains(suggestion.id) {
                selectedSuggestions.remove(suggestion.id)
            } else {
                selectedSuggestions.insert(suggestion.id)
            }
        }
    }
}

// MARK: - Task Suggestion Row

private struct TaskSuggestionRow: View {
    let title: String
    let duration: String
    let icon: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected ? Theme.Colors.success : .white.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.Colors.success)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(isSelected ? 1 : 0.7))
                        .strikethrough(!isSelected, color: .white.opacity(0.3))

                    Text(duration)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Theme.Colors.success.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let goal = Goal(
        title: "Launch my productivity app",
        goalDescription: "Ship MVP to App Store",
        targetDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
        category: GoalCategory.career.rawValue,
        timeframe: GoalTimeframe.milestone.rawValue
    )

    AIRoadmapApprovalSheet(goal: goal, goalsVM: GoalsViewModel())
        .modelContainer(for: [Goal.self])
}
