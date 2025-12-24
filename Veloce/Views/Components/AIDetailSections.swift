//
//  AIDetailSections.swift
//  MyTasksAI
//
//  AI Detail Sheet Sections - Enhanced AI advice with guidance and workflow
//  Displays best advice, guidance links, and workflow suggestions
//

import SwiftUI

// MARK: - AI Advice Section

/// Displays the main AI advice with an icon and title
struct AIAdviceSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            // Advice content
            Text(content)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(iconColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
    }
}

// MARK: - AI Guidance Section

/// Displays AI-suggested guidance links and resources
struct AIGuidanceSection: View {
    let sources: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiBlue)

                Text("Best Guidance")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            // Guidance links
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(sources.prefix(3), id: \.self) { source in
                    GuidanceLinkRow(source: source)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.aiBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
    }
}

// MARK: - Guidance Link Row

struct GuidanceLinkRow: View {
    let source: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "arrow.up.right.circle")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.aiBlue.opacity(0.8))

            Text(source)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AI Workflow Section

/// Displays AI-suggested workflow steps for completing the task
struct AIWorkflowSection: View {
    let task: TaskItem

    // Generate workflow steps based on task
    private var workflowSteps: [WorkflowStep] {
        generateWorkflowSteps()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "flowchart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiCyan)

                Text("Best Workflow")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            // Workflow steps
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(workflowSteps.enumerated()), id: \.element.id) { index, step in
                    WorkflowStepRow(
                        step: step,
                        isLast: index == workflowSteps.count - 1
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.aiCyan.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
    }

    // Generate workflow steps based on task properties
    private func generateWorkflowSteps() -> [WorkflowStep] {
        var steps: [WorkflowStep] = []

        // Step 1: Start preparation
        steps.append(WorkflowStep(
            number: 1,
            title: "Prepare",
            description: "Clear distractions and gather resources"
        ))

        // Step 2: Based on estimated time
        if let mins = task.estimatedMinutes {
            if mins <= 15 {
                steps.append(WorkflowStep(
                    number: 2,
                    title: "Quick Focus",
                    description: "Complete in one focused session"
                ))
            } else if mins <= 45 {
                steps.append(WorkflowStep(
                    number: 2,
                    title: "Deep Work",
                    description: "Work for \(mins) min with no interruptions"
                ))
            } else {
                steps.append(WorkflowStep(
                    number: 2,
                    title: "Break it Down",
                    description: "Split into \(mins / 25)-min Pomodoro sessions"
                ))
            }
        } else {
            steps.append(WorkflowStep(
                number: 2,
                title: "Focus",
                description: "Work on the task with full attention"
            ))
        }

        // Step 3: Review
        steps.append(WorkflowStep(
            number: 3,
            title: "Review",
            description: "Check work quality before marking complete"
        ))

        return steps
    }
}

// MARK: - Workflow Step Model

struct WorkflowStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let description: String
}

// MARK: - Workflow Step Row

struct WorkflowStepRow: View {
    let step: WorkflowStep
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Step number with connector line
            VStack(spacing: 0) {
                // Number circle
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiCyan.opacity(0.3))
                        .frame(width: 24, height: 24)

                    Text("\(step.number)")
                        .font(.system(size: 11, weight: .bold, design: .default))
                        .foregroundStyle(Theme.Colors.aiCyan)
                }

                // Connector line (if not last)
                if !isLast {
                    Rectangle()
                        .fill(Theme.Colors.aiCyan.opacity(0.2))
                        .frame(width: 2, height: 20)
                }
            }

            // Step content
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(step.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : Theme.Spacing.sm)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("AI Advice Section") {
    VStack(spacing: 16) {
        AIAdviceSection(
            icon: "lightbulb.fill",
            iconColor: .yellow,
            title: "Best Suggested Advice",
            content: "Start this task in the morning when your energy is highest. Break it into smaller chunks of 25 minutes."
        )

        AIGuidanceSection(sources: [
            "Deep Work by Cal Newport",
            "Getting Things Done Method",
            "Pomodoro Technique Guide"
        ])

        AIWorkflowSection(task: {
            let task = TaskItem(title: "Finish presentation slides")
            task.estimatedMinutes = 45
            return task
        }())
    }
    .padding()
    .background(IridescentBackground(intensity: 0.2))
}
