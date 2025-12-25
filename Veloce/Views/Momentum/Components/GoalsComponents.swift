//
//  GoalsComponents.swift
//  Veloce
//
//  Goals Section Components - Premium Goal Tracking
//  Expandable cards, systems tracking, achievement-oriented design
//
//  Award-Winning Tier Visual Design
//

import SwiftUI

// MARK: - Create Goal Button

struct CreateGoalButton: View {
    let action: () -> Void

    @State private var isPressed = false
    @State private var glowPhase: Double = 0

    var body: some View {
        Button(action: {
            HapticsService.shared.impact(.medium)
            action()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.CelestialColors.auroraGreen.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Circle()
                        .stroke(Theme.CelestialColors.auroraGreen.opacity(0.5 + glowPhase * 0.3), lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(1 + glowPhase * 0.1)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Create New Goal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Set your north star")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Theme.CelestialColors.auroraGreen.opacity(0.4),
                                        Theme.CelestialColors.auroraGreen.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }
}

// MARK: - Goals Empty State

struct GoalsEmptyState: View {
    let onCreateGoal: () -> Void

    @State private var floatOffset: CGFloat = 0
    @State private var starRotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            // Illustration
            ZStack {
                // Orbital rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            Theme.CelestialColors.auroraGreen.opacity(0.1 - Double(i) * 0.02),
                            lineWidth: 1
                        )
                        .frame(width: CGFloat(100 + i * 40), height: CGFloat(100 + i * 40))
                        .rotationEffect(.degrees(Double(i) * 30 + starRotation))
                }

                // Central star
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.CelestialColors.auroraGreen.opacity(0.3),
                                    Theme.CelestialColors.auroraGreen.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.CelestialColors.auroraGreen, Theme.CelestialColors.plasmaCore],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .offset(y: floatOffset)
            }
            .frame(height: 180)

            VStack(spacing: 12) {
                Text("Set Your North Star")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Goals give your tasks meaning and direction.\nCreate your first goal to start building momentum.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Example goals
            VStack(spacing: 8) {
                Text("Popular goals to get started:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))

                HStack(spacing: 8) {
                    ExampleGoalChip(text: "Launch a project", icon: "rocket.fill")
                    ExampleGoalChip(text: "Learn a skill", icon: "brain.head.profile")
                }

                HStack(spacing: 8) {
                    ExampleGoalChip(text: "Build a habit", icon: "repeat")
                    ExampleGoalChip(text: "Complete a course", icon: "book.fill")
                }
            }
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatOffset = -8
            }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                starRotation = 360
            }
        }
    }
}

struct ExampleGoalChip: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))

            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Expandable Goal Card

struct ExpandableGoalCard: View {
    let goal: Goal
    let tasks: [TaskItem]
    let goalsVM: GoalsViewModel
    let onTap: () -> Void

    @State private var isExpanded = false
    @State private var progressAnimated: Double = 0

    private var linkedTasks: [TaskItem] {
        // TODO: Add linkedGoalId property to TaskItem model when goal linking is implemented
        []
    }

    private var completedLinkedTasks: Int {
        linkedTasks.filter { $0.isCompleted }.count
    }

    // Compute priority based on days remaining and progress
    private var priority: GoalPriority {
        if goal.isOverdue { return .critical }
        if let days = goal.daysRemaining {
            if days <= 7 && goal.progress < 0.5 { return .high }
            if days <= 14 { return .medium }
        }
        return .low
    }

    private var priorityColor: Color {
        switch priority {
        case .critical, .high: return Theme.CelestialColors.urgencyCritical
        case .medium: return Theme.CelestialColors.urgencyNear
        case .low: return Theme.CelestialColors.urgencyCalm
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed view (always visible)
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticsService.shared.selectionFeedback()
            } label: {
                collapsedContent
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    priorityColor.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                progressAnimated = goal.progress
            }
        }
    }

    @ViewBuilder
    private var collapsedContent: some View {
        HStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: progressAnimated)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.CelestialColors.auroraGreen, Theme.CelestialColors.plasmaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(goal.progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // Priority indicator
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)

                    Text(goal.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                if let daysRemaining = goal.daysRemaining {
                    Text("\(daysRemaining) days remaining")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(16)
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.1))

            // Linked tasks section
            if !linkedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Linked Tasks")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        Text("\(completedLinkedTasks)/\(linkedTasks.count)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.CelestialColors.auroraGreen)
                    }

                    ForEach(linkedTasks.prefix(3)) { task in
                        LinkedTaskRow(task: task)
                    }

                    if linkedTasks.count > 3 {
                        Text("+\(linkedTasks.count - 3) more tasks")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            // Milestones from roadmap
            if let roadmap = goal.decodedRoadmap, !roadmap.phases.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Milestones")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        Text(goal.milestoneProgressString)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.CelestialColors.auroraGreen)
                    }

                    ForEach(roadmap.phases.prefix(3)) { phase in
                        RoadmapPhaseRowView(phase: phase)
                    }

                    if roadmap.phases.count > 3 {
                        Text("+\(roadmap.phases.count - 3) more phases")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    onTap()
                } label: {
                    Text("View Details")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            Capsule()
                                .fill(Theme.CelestialColors.auroraGreen.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Theme.CelestialColors.auroraGreen.opacity(0.4), lineWidth: 1)
                                )
                        }
                }
                .buttonStyle(.plain)

                Spacer()

                // Quick check-in
                Button {
                    HapticsService.shared.successFeedback()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Check In")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Linked Task Row

struct LinkedTaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(task.isCompleted ? Theme.CelestialColors.auroraGreen : .white.opacity(0.3))

            Text(task.title)
                .font(.system(size: 14))
                .foregroundStyle(task.isCompleted ? .white.opacity(0.5) : .white)
                .strikethrough(task.isCompleted)
                .lineLimit(1)

            Spacer()
        }
    }
}

// MARK: - Roadmap Phase Row View

struct RoadmapPhaseRowView: View {
    let phase: RoadmapPhase

    private var totalItems: Int {
        phase.milestones.count + phase.oneTimeTasks.count + phase.dailyHabits.count
    }

    private var durationText: String {
        let weeks = phase.durationWeeks
        return weeks == 1 ? "1 week" : "\(weeks) weeks"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Phase indicator
            ZStack {
                Circle()
                    .fill(Theme.CelestialColors.nebulaCore.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: "flag.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.nebulaEdge)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(phase.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if totalItems > 0 {
                    Text("\(totalItems) items")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            // Duration badge
            Text(durationText)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.05)))
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        }
    }
}

// MARK: - Goal Progress Animation

struct GoalProgressCelebration: View {
    let percentage: Int
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        if isShowing {
            VStack(spacing: 16) {
                ZStack {
                    // Burst effect
                    ForEach(0..<12, id: \.self) { i in
                        Rectangle()
                            .fill(Theme.CelestialColors.auroraGreen)
                            .frame(width: 4, height: 20)
                            .offset(y: -50)
                            .rotationEffect(.degrees(Double(i) * 30))
                            .scaleEffect(scale)
                            .opacity(opacity)
                    }

                    // Badge
                    ZStack {
                        Circle()
                            .fill(Theme.CelestialColors.auroraGreen.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Circle()
                            .stroke(Theme.CelestialColors.auroraGreen, lineWidth: 3)
                            .frame(width: 80, height: 80)

                        Text("\(percentage)%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.CelestialColors.auroraGreen)
                    }
                    .scaleEffect(scale)
                }

                Text(celebrationMessage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1
                    opacity = 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowing = false
                    }
                }
            }
        }
    }

    private var celebrationMessage: String {
        switch percentage {
        case 25: return "Great start!"
        case 50: return "Halfway there!"
        case 75: return "Almost done!"
        case 100: return "Goal achieved!"
        default: return "Keep going!"
        }
    }
}
