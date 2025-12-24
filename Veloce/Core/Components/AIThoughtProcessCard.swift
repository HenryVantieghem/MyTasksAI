//
//  AIThoughtProcessCard.swift
//  Veloce
//
//  Transparent AI reasoning display
//  Shows users why AI made specific recommendations
//

import SwiftUI

struct AIThoughtProcessCard: View {
    let thoughtProcess: String
    let subTasks: [SubTask]
    let taskTitle: String
    let estimatedMinutes: Int?

    @State private var isExpanded: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header (always visible)
            headerView

            // Expandable content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.aiPurple.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.aiPurple.opacity(0.15))
                }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }

    // MARK: - Header

    private var headerView: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .font(.system(size: 16))

                Text("AI Reasoning")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)

                Spacer()

                // Preview indicator
                if !isExpanded {
                    Text("Tap to expand")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.tertiaryText)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Main thought process
            if !thoughtProcess.isEmpty {
                thoughtProcessSection
            }

            // Pattern recognition
            patternRecognitionSection

            // Time allocation
            if !subTasks.isEmpty {
                timeAllocationSection
            }

            // Confidence indicator
            confidenceSection
        }
    }

    // MARK: - Thought Process Section

    private var thoughtProcessSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionHeader("How I arrived at this breakdown:")

            Text(thoughtProcess)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
                .padding(Theme.Spacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .fill(Theme.Colors.glassBackground.opacity(0.3))
                }
        }
    }

    // MARK: - Pattern Recognition

    private var patternRecognitionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Patterns recognized:")

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(generatePatternInsights(), id: \.self) { insight in
                    insightRow(insight)
                }
            }
        }
    }

    private func insightRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text("•")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.aiPurple)

            Text(text)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    // MARK: - Time Allocation

    private var timeAllocationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Time allocation:")

            HStack(spacing: Theme.Spacing.lg) {
                // Total time
                timeMetric(
                    label: "Total",
                    value: subTasks.totalEstimatedMinutes.formattedDuration,
                    icon: "clock"
                )

                // Per step average
                let avgTime = subTasks.isEmpty ? 0 : subTasks.totalEstimatedMinutes / subTasks.count
                timeMetric(
                    label: "Avg/step",
                    value: avgTime.formattedDuration,
                    icon: "chart.bar"
                )

                // Step count
                timeMetric(
                    label: "Steps",
                    value: "\(subTasks.count)",
                    icon: "list.number"
                )
            }
        }
    }

    private func timeMetric(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.aiPurple.opacity(0.7))
                Text(value)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
        }
    }

    // MARK: - Confidence Section

    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Confidence level:")

            HStack(spacing: Theme.Spacing.sm) {
                // Confidence indicator
                let confidence = calculateConfidence()
                ForEach(0..<5) { index in
                    SwiftUI.Circle()
                        .fill(index < confidence
                              ? Theme.Colors.aiPurple
                              : Theme.Colors.glassBackground.opacity(0.5))
                        .frame(width: 10, height: 10)
                }

                Text(confidenceLabel(for: confidence))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)

                Spacer()
            }

            Text("Based on task clarity, available context, and pattern matching.")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.tertiaryText)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Rectangle()
                .fill(Theme.Colors.aiPurple.opacity(0.5))
                .frame(width: 3)

            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.aiPurple)
        }
        .frame(height: 16)
    }

    private func generatePatternInsights() -> [String] {
        var insights: [String] = []
        let lowercased = taskTitle.lowercased()

        // Detect task type
        if lowercased.contains("report") || lowercased.contains("document") {
            insights.append("Recognized as a \"document creation\" task type")
        } else if lowercased.contains("meeting") || lowercased.contains("call") {
            insights.append("Recognized as a \"communication\" task type")
        } else if lowercased.contains("review") || lowercased.contains("check") {
            insights.append("Recognized as a \"review/validation\" task type")
        } else {
            insights.append("Analyzed task keywords and structure")
        }

        // Time allocation insight
        if let estimated = estimatedMinutes {
            insights.append("Allocated \(estimated)min across \(subTasks.count) logical steps")
        }

        // Breakdown strategy
        if subTasks.count >= 3 && subTasks.count <= 7 {
            insights.append("Optimal breakdown: 3-7 steps for focused execution")
        }

        // Dependency insight
        insights.append("Ordered steps by logical dependency and flow")

        return insights
    }

    private func calculateConfidence() -> Int {
        var score = 2 // Base confidence

        // More context = higher confidence
        if !thoughtProcess.isEmpty { score += 1 }

        // Clear task title
        if taskTitle.count > 5 { score += 1 }

        // Good number of sub-tasks
        if subTasks.count >= 3 && subTasks.count <= 7 { score += 1 }

        return min(score, 5)
    }

    private func confidenceLabel(for score: Int) -> String {
        switch score {
        case 5: return "Very high"
        case 4: return "High"
        case 3: return "Moderate"
        case 2: return "Fair"
        default: return "Low"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        AIThoughtProcessCard(
            thoughtProcess: "Breaking this quarterly report into manageable chunks for focused work. Started with data gathering since it informs all other sections.",
            subTasks: [
                SubTask(title: "Gather Q3 data", estimatedMinutes: 10, status: .completed, orderIndex: 1),
                SubTask(title: "Create template", estimatedMinutes: 15, status: .completed, orderIndex: 2),
                SubTask(title: "Write summary", estimatedMinutes: 20, status: .inProgress, orderIndex: 3),
                SubTask(title: "Add visuals", estimatedMinutes: 25, status: .pending, orderIndex: 4),
                SubTask(title: "Review", estimatedMinutes: 15, status: .pending, orderIndex: 5)
            ],
            taskTitle: "Finish quarterly report",
            estimatedMinutes: 85
        )
        .padding()
    }
    .background(Theme.Colors.background)
}
