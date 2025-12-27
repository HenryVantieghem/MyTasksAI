//
//  AIOracleSection.swift
//  Veloce
//
//  Full Oracle Mode AI Section
//  Comprehensive AI insights with thought process, resources, and prompt builder
//

import SwiftUI

// MARK: - AI Oracle Section

/// Full Oracle Mode AI section for TaskDetailSheet
/// Features: paragraph advice, confidence scores, thought process, resources, prompt builder
struct AIOracleSection: View {
    let task: TaskItem
    let onRefresh: () -> Void

    @State private var isThoughtProcessExpanded = false
    @State private var isResourcesExpanded = true
    @State private var isRefreshing = false
    @State private var refreshRotation: Double = 0
    @State private var copiedPrompt = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Computed properties for display
    private var confidenceScore: Int {
        // Calculate confidence from various factors
        if task.aiAdvice != nil && task.aiThoughtProcess != nil {
            return 87 // High confidence if we have both
        } else if task.aiAdvice != nil {
            return 72 // Medium confidence
        }
        return 0
    }

    private var thoughtProcessSteps: [String] {
        guard let process = task.aiThoughtProcess else {
            return [
                "Analyzed task title and context",
                "Identified task type and complexity",
                "Generated actionable recommendations"
            ]
        }
        // Split thought process into steps
        return process.components(separatedBy: ". ")
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            headerSection

            Divider()
                .padding(.vertical, 12)

            // MARK: - Main Advice
            adviceSection

            // MARK: - Thought Process Accordion
            thoughtProcessSection
                .padding(.top, 16)

            // MARK: - Resources Section
            resourcesSection
                .padding(.top, 16)

            // MARK: - AI Prompt Builder
            promptBuilderSection
                .padding(.top, 16)
        }
        .padding(16)
        .veloceSectionCard(tint: Theme.AdaptiveColors.aiPrimary)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // Sparkles icon with glow
            ZStack {
                Circle()
                    .fill(Theme.AdaptiveColors.aiPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.AdaptiveColors.aiPrimary)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.3))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Oracle")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if confidenceScore > 0 {
                    HStack(spacing: 4) {
                        Text("\(confidenceScore)% confident")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Confidence indicator dots
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(index < (confidenceScore / 33) ? Theme.AdaptiveColors.aiPrimary : Color(.tertiarySystemFill))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Refresh button
            Button {
                refreshAI()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.AdaptiveColors.aiSecondary)
                    .rotationEffect(.degrees(refreshRotation))
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)
        }
    }

    // MARK: - Advice Section

    private var adviceSection: some View {
        Group {
            if isRefreshing {
                // Loading state
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)

                    Text("Analyzing your task...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else if let advice = task.aiAdvice {
                // Full paragraph advice
                Text(advice)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                // Metadata pills
                if task.estimatedMinutes != nil || task.aiPriority != nil {
                    HStack(spacing: 8) {
                        if let minutes = task.estimatedMinutes {
                            OracleMetadataPill(
                                icon: "clock.fill",
                                text: formatTime(minutes),
                                color: Theme.AdaptiveColors.aiSecondary
                            )
                        }

                        if let priority = task.aiPriority {
                            OracleMetadataPill(
                                icon: priorityIcon(for: priority),
                                text: priority.capitalized,
                                color: priorityColor(for: priority)
                            )
                        }

                        if task.scheduledTime != nil {
                            OracleMetadataPill(
                                icon: "calendar",
                                text: "Scheduled",
                                color: Theme.AdaptiveColors.accent
                            )
                        }
                    }
                    .padding(.top, 12)
                }
            } else {
                // No advice yet
                Text("Tap refresh to get AI insights for this task.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Thought Process Section

    private var thoughtProcessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Disclosure header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isThoughtProcessExpanded.toggle()
                }
                HapticsService.shared.selectionFeedback()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.AdaptiveColors.aiTertiary)

                    Text("Thought Process")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isThoughtProcessExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Expanded content
            if isThoughtProcessExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(thoughtProcessSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            // Step number
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(Theme.AdaptiveColors.aiPrimary.opacity(0.8))
                                .clipShape(Circle())

                            // Step text
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.leading, 4)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Resources Section

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.AdaptiveColors.aiSecondary)

                Text("Helpful Resources")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Resource links (always visible per plan)
            VStack(spacing: 8) {
                // Article suggestion
                ResourceLinkRow(
                    icon: "doc.text.fill",
                    title: "How to complete \(task.taskType.displayName.lowercased()) tasks effectively",
                    subtitle: "Best practices guide",
                    color: Theme.AdaptiveColors.aiSecondary,
                    action: {
                        // Open article search
                        let query = task.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "https://www.google.com/search?q=how+to+\(query)") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                // YouTube suggestion
                ResourceLinkRow(
                    icon: "play.rectangle.fill",
                    title: "Tutorial: \(task.title.prefix(30))...",
                    subtitle: "YouTube videos",
                    color: .red,
                    action: {
                        // Open YouTube search
                        let query = task.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "https://www.youtube.com/results?search_query=\(query)+tutorial") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Prompt Builder Section

    private var promptBuilderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "message.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.AdaptiveColors.aiPrimary)

                Text("AI Prompt")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                // Copy button
                Button {
                    copyPrompt()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedPrompt ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))

                        Text(copiedPrompt ? "Copied!" : "Copy")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(copiedPrompt ? Theme.AdaptiveColors.success : Theme.AdaptiveColors.aiPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        (copiedPrompt ? Theme.AdaptiveColors.success : Theme.AdaptiveColors.aiPrimary)
                            .opacity(0.12)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Generated prompt
            Text(generatedPrompt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Computed Properties

    private var generatedPrompt: String {
        var prompt = "Help me with this task: \"\(task.title)\""

        if let context = task.contextNotes, !context.isEmpty {
            prompt += "\n\nContext: \(context)"
        }

        if let minutes = task.estimatedMinutes {
            prompt += "\n\nEstimated time: \(formatTime(minutes))"
        }

        prompt += "\n\nPlease provide:\n1. Step-by-step breakdown\n2. Tips for efficiency\n3. Potential challenges and solutions"

        return prompt
    }

    // MARK: - Actions

    private func refreshAI() {
        isRefreshing = true
        HapticsService.shared.softImpact()

        if !reduceMotion {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                refreshRotation = 360
            }
        }

        onRefresh()

        // Reset after callback (actual completion handled by parent)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isRefreshing = false
                refreshRotation = 0
            }
        }
    }

    private func copyPrompt() {
        UIPasteboard.general.string = generatedPrompt
        HapticsService.shared.success()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            copiedPrompt = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedPrompt = false
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }

    private func priorityIcon(for priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "minus.circle.fill"
        case "low": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }

    private func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return Theme.AdaptiveColors.destructive
        case "medium": return Theme.AdaptiveColors.warning
        case "low": return Theme.AdaptiveColors.success
        default: return .secondary
        }
    }
}

// MARK: - Oracle Metadata Pill

struct OracleMetadataPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))

            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Resource Link Row

struct ResourceLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Arrow
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("AI Oracle Section") {
    ScrollView {
        AIOracleSection(
            task: TaskItem(title: "Write quarterly report for Q4 2024"),
            onRefresh: { }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
