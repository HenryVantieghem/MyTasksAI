//
//  SmartScheduleCard.swift
//  Veloce
//
//  AI-powered schedule suggestions based on calendar and user patterns
//  Recommends optimal time slots for task completion
//

import SwiftUI

struct SmartScheduleCard: View {
    let suggestion: ScheduleSuggestion?
    let estimatedMinutes: Int?
    let onAccept: (Date) -> Void
    let onShowAlternatives: () -> Void
    let onRefresh: () -> Void

    @State private var isLoading: Bool = false
    @State private var appeared: Bool = false
    @State private var showingAlternatives: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            headerView

            // Content
            if isLoading {
                loadingView
            } else if let suggestion = suggestion {
                suggestionContentView(suggestion)
            } else {
                emptyStateView
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.glassBackground.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.glassBorder.opacity(0.2))
                }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(Theme.Colors.accent)
                .font(.system(size: 18))

            Text("Smart Schedule")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.primaryText)

            Spacer()

            // Refresh button
            Button {
                refreshSuggestion()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.5 : 1)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Analyzing your schedule...")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.glassBackground.opacity(0.3))
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 24))
                .foregroundStyle(Theme.Colors.tertiaryText)

            Text("No schedule suggestion yet")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)

            Button {
                refreshSuggestion()
            } label: {
                Text("Find Best Time")
                    .font(Theme.Typography.caption)
            }
            .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Suggestion Content

    private func suggestionContentView(_ suggestion: ScheduleSuggestion) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Main suggestion
            mainSuggestionView(suggestion)

            // Reason
            reasonView(suggestion.reason)

            // Conflicts warning
            if let conflicts = suggestion.conflictingEvents, !conflicts.isEmpty {
                conflictsWarning(conflicts)
            }

            // Action buttons
            actionButtonsView(suggestion)

            // Alternatives
            if showingAlternatives, let alternatives = suggestion.alternativeTimes {
                alternativesView(alternatives)
            }
        }
    }

    private func mainSuggestionView(_ suggestion: ScheduleSuggestion) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            // Date/Time display
            VStack(alignment: .leading, spacing: 4) {
                Text("Best time:")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)

                Text(formatDate(suggestion.suggestedTime))
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.primaryText)

                Text(formatTime(suggestion.suggestedTime))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.accent)
            }

            Spacer()

            // Confidence indicator
            confidenceIndicator(suggestion.confidence)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.accent.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .strokeBorder(Theme.Colors.accent.opacity(0.2))
                }
        }
    }

    private func confidenceIndicator(_ confidence: Double) -> some View {
        VStack(spacing: 4) {
            // Circular progress
            ZStack {
                SwiftUI.Circle()
                    .stroke(Theme.Colors.glassBackground, lineWidth: 4)
                    .frame(width: 50, height: 50)

                SwiftUI.Circle()
                    .trim(from: 0, to: confidence)
                    .stroke(
                        confidenceColor(for: confidence),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(confidence * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryText)
            }

            Text(confidenceLabel(for: confidence))
                .font(.system(size: 9))
                .foregroundStyle(Theme.Colors.tertiaryText)
        }
    }

    private func reasonView(_ reason: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(Theme.Colors.warning.opacity(0.8))

            Text(reason)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    private func conflictsWarning(_ conflicts: [String]) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(Theme.Colors.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text("Potential conflicts:")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.warning)

                ForEach(conflicts, id: \.self) { conflict in
                    Text("• \(conflict)")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colors.warning.opacity(0.1))
        }
    }

    // MARK: - Action Buttons

    private func actionButtonsView(_ suggestion: ScheduleSuggestion) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            // Accept button
            Button {
                acceptSuggestion(suggestion.suggestedTime)
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark")
                    Text("Accept")
                }
                .font(Theme.Typography.subheadline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)

            // Alternatives button
            if suggestion.alternativeTimes != nil {
                Button {
                    withAnimation {
                        showingAlternatives.toggle()
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: showingAlternatives ? "chevron.up" : "clock.arrow.2.circlepath")
                        Text(showingAlternatives ? "Hide" : "Alternatives")
                    }
                    .font(Theme.Typography.subheadline)
                }
                .buttonStyle(.glass)
            }
        }
    }

    // MARK: - Alternatives View

    private func alternativesView(_ alternatives: [Date]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Alternative times:")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)

            ForEach(alternatives, id: \.self) { date in
                alternativeRow(date)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func alternativeRow(_ date: Date) -> some View {
        Button {
            acceptSuggestion(date)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatDate(date))
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.primaryText)

                    Text(formatTime(date))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.accent)
                }

                Spacer()

                Image(systemName: "plus.circle")
                    .foregroundStyle(Theme.Colors.accent)
            }
            .padding(Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Theme.Colors.glassBackground.opacity(0.3))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func confidenceColor(for confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0: return Theme.Colors.success
        case 0.6..<0.8: return Theme.Colors.accent
        default: return Theme.Colors.warning
        }
    }

    private func confidenceLabel(for confidence: Double) -> String {
        switch confidence {
        case 0.8...1.0: return "High"
        case 0.6..<0.8: return "Moderate"
        default: return "Low"
        }
    }

    // MARK: - Actions

    private func refreshSuggestion() {
        isLoading = true

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        onRefresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }

    private func acceptSuggestion(_ date: Date) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onAccept(date)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        SmartScheduleCard(
            suggestion: ScheduleSuggestion(
                suggestedTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(9 * 3600),
                reason: "You complete similar tasks 40% faster in the morning. Your calendar is free at this time.",
                confidence: 0.85,
                alternativeTimes: [
                    Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(14 * 3600),
                    Calendar.current.date(byAdding: .day, value: 2, to: Date())!.addingTimeInterval(10 * 3600)
                ],
                conflictingEvents: nil
            ),
            estimatedMinutes: 45,
            onAccept: { _ in },
            onShowAlternatives: { },
            onRefresh: { }
        )
        .padding()
    }
    .background(Theme.Colors.background)
}
