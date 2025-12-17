//
//  AIThoughtProcessSheet.swift
//  Veloce
//
//  Full-screen sheet showing AI's thought process and task analysis
//

import SwiftUI

struct AIThoughtProcessSheet: View {
    @Environment(\.dismiss) private var dismiss

    let task: TaskItem
    let thoughtProcess: String
    let subTasks: [SubTask]

    @State private var selectedTab: AITab = .reasoning

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector

                    // Content
                    TabView(selection: $selectedTab) {
                        reasoningTab
                            .tag(AITab.reasoning)

                        breakdownTab
                            .tag(AITab.breakdown)

                        insightsTab
                            .tag(AITab.insights)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(AITab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func tabButton(_ tab: AITab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16))

                Text(tab.title)
                    .font(Theme.Typography.caption)
            }
            .foregroundStyle(selectedTab == tab ? Theme.Colors.accent : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.accent.opacity(0.1))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reasoning Tab

    private var reasoningTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Task header
                taskHeader

                // Thought process
                if !thoughtProcess.isEmpty {
                    sectionCard(title: "My Reasoning", icon: "brain.head.profile") {
                        Text(thoughtProcess)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }

                // Task analysis
                sectionCard(title: "Task Analysis", icon: "magnifyingglass") {
                    taskAnalysis
                }

                // Pattern matching
                sectionCard(title: "Patterns Detected", icon: "chart.line.uptrend.xyaxis") {
                    patternsList
                }
            }
            .padding(Theme.Spacing.screenPadding)
        }
    }

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(task.title)
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.textPrimary)

            if let category = task.category {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "tag")
                        .font(.caption)
                    Text(category)
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.aiPurple.opacity(0.05))
        }
    }

    private var taskAnalysis: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            analysisRow("Priority", value: task.priorityStars)
            analysisRow("Estimated Time", value: task.estimatedMinutes?.formattedDuration ?? "Not set")
            analysisRow("Complexity", value: complexityAssessment)
            analysisRow("Type", value: detectTaskType())
        }
    }

    private func analysisRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private var complexityAssessment: String {
        let wordCount = task.title.split(separator: " ").count

        if wordCount > 8 || subTasks.count > 5 {
            return "High"
        } else if wordCount > 4 || subTasks.count > 3 {
            return "Medium"
        }
        return "Low"
    }

    private func detectTaskType() -> String {
        let title = task.title.lowercased()

        if title.contains("report") || title.contains("document") || title.contains("write") {
            return "Documentation"
        } else if title.contains("meeting") || title.contains("call") || title.contains("discuss") {
            return "Communication"
        } else if title.contains("review") || title.contains("check") || title.contains("audit") {
            return "Review"
        } else if title.contains("fix") || title.contains("bug") || title.contains("resolve") {
            return "Problem-solving"
        } else if title.contains("create") || title.contains("build") || title.contains("design") {
            return "Creation"
        }
        return "General"
    }

    private var patternsList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            patternRow("Task keywords analyzed for type detection")
            patternRow("Complexity estimated from structure and scope")

            if !subTasks.isEmpty {
                patternRow("\(subTasks.count) sub-tasks identified for systematic completion")
            }

            if task.estimatedMinutes != nil {
                patternRow("Time distributed based on task complexity")
            }
        }
    }

    private func patternRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text("•")
                .foregroundStyle(Theme.Colors.aiPurple)

            Text(text)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Breakdown Tab

    private var breakdownTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                if subTasks.isEmpty {
                    emptyBreakdownState
                } else {
                    // Progress overview
                    progressOverview

                    // Sub-tasks list
                    sectionCard(title: "Task Breakdown", icon: "list.bullet.clipboard") {
                        subTasksList
                    }

                    // Time allocation
                    sectionCard(title: "Time Allocation", icon: "clock") {
                        timeAllocation
                    }
                }
            }
            .padding(Theme.Spacing.screenPadding)
        }
    }

    private var emptyBreakdownState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No breakdown generated yet")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("AI will break down your task into actionable steps")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
    }

    private var progressOverview: some View {
        HStack(spacing: Theme.Spacing.lg) {
            progressMetric(
                "\(subTasks.filter { $0.status == .completed }.count)/\(subTasks.count)",
                label: "Completed"
            )

            progressMetric(
                subTasks.totalEstimatedMinutes.formattedDuration,
                label: "Total Time"
            )

            progressMetric(
                "\(Int(subTasks.progress * 100))%",
                label: "Progress"
            )
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.accent.opacity(0.05))
        }
    }

    private func progressMetric(_ value: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.accent)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var subTasksList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(subTasks.sorted { $0.orderIndex < $1.orderIndex }) { subTask in
                subTaskRow(subTask)
            }
        }
    }

    private func subTaskRow(_ subTask: SubTask) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: subTask.status.icon)
                .foregroundStyle(statusColor(for: subTask.status))
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(subTask.orderIndex). \(subTask.title)")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(subTask.status == .completed ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                    .strikethrough(subTask.status == .completed)

                if let minutes = subTask.estimatedMinutes {
                    Text(minutes.formattedDuration)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
        }
    }

    private func statusColor(for status: SubTaskStatus) -> Color {
        switch status {
        case .pending: return Theme.Colors.textTertiary
        case .inProgress: return Theme.Colors.accent
        case .completed: return Theme.Colors.success
        }
    }

    private var timeAllocation: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(subTasks.sorted { $0.orderIndex < $1.orderIndex }) { subTask in
                if let minutes = subTask.estimatedMinutes {
                    let percentage = Double(minutes) / Double(max(subTasks.totalEstimatedMinutes, 1))

                    HStack {
                        Text("Step \(subTask.orderIndex)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 50, alignment: .leading)

                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.accent.opacity(0.3))
                                .frame(width: geometry.size.width * percentage)
                        }
                        .frame(height: 8)

                        Text(minutes.formattedDuration)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Insights Tab

    private var insightsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                sectionCard(title: "Productivity Tips", icon: "lightbulb") {
                    productivityTips
                }

                sectionCard(title: "Recommendations", icon: "star") {
                    recommendations
                }

                sectionCard(title: "Confidence Level", icon: "gauge.with.needle") {
                    confidenceIndicator
                }
            }
            .padding(Theme.Spacing.screenPadding)
        }
    }

    private var productivityTips: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            tipRow("Start with the most important step first")
            tipRow("Take short breaks between steps for better focus")

            if task.estimatedMinutes ?? 0 > 60 {
                tipRow("Consider splitting this into multiple sessions")
            }

            if detectTaskType() == "Documentation" {
                tipRow("Outline first, then fill in details")
            }
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.success)
                .font(.caption)

            Text(text)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            recommendationRow("Schedule during your peak productivity hours")
            recommendationRow("Remove distractions before starting")

            if subTasks.count > 3 {
                recommendationRow("Use the sub-task list to track progress")
            }
        }
    }

    private func recommendationRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "arrow.right.circle")
                .foregroundStyle(Theme.Colors.accent)
                .font(.caption)

            Text(text)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private var confidenceIndicator: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index < confidenceScore ? Theme.Colors.aiPurple : Theme.Colors.glassBackground)
                        .frame(width: 12, height: 12)
                }

                Spacer()

                Text(confidenceLabel)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Text("Based on task clarity, context provided, and pattern matching.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    private var confidenceScore: Int {
        var score = 2

        if !thoughtProcess.isEmpty { score += 1 }
        if task.title.count > 10 { score += 1 }
        if !subTasks.isEmpty { score += 1 }

        return min(score, 5)
    }

    private var confidenceLabel: String {
        switch confidenceScore {
        case 5: return "Very High"
        case 4: return "High"
        case 3: return "Moderate"
        default: return "Low"
        }
    }

    // MARK: - Helper

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            content()
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
        }
    }
}

// MARK: - AI Tab

enum AITab: String, CaseIterable, Identifiable {
    case reasoning = "reasoning"
    case breakdown = "breakdown"
    case insights = "insights"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reasoning: return "Reasoning"
        case .breakdown: return "Breakdown"
        case .insights: return "Insights"
        }
    }

    var icon: String {
        switch self {
        case .reasoning: return "brain.head.profile"
        case .breakdown: return "list.bullet.clipboard"
        case .insights: return "lightbulb"
        }
    }
}

// MARK: - Preview

#Preview {
    AIThoughtProcessSheet(
        task: TaskItem(
            title: "Finish quarterly report",
            estimatedMinutes: 90,
            starRating: 3
        ),
        thoughtProcess: "I analyzed this task and determined it's a document creation task. I've broken it into steps that follow a logical flow: data gathering, structure creation, writing, and review.",
        subTasks: [
            SubTask(title: "Gather Q3 data", estimatedMinutes: 20, status: .completed, orderIndex: 1),
            SubTask(title: "Create outline", estimatedMinutes: 15, status: .completed, orderIndex: 2),
            SubTask(title: "Write content", estimatedMinutes: 40, status: .inProgress, orderIndex: 3),
            SubTask(title: "Review and polish", estimatedMinutes: 15, status: .pending, orderIndex: 4)
        ]
    )
}
