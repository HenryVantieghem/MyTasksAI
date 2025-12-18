//
//  DatePillView.swift
//  MyTasksAI
//
//  Apple Notes-style swipeable date navigation pill
//  Swipe left for previous day, right for next day
//

import SwiftUI

// MARK: - Date Pill View

struct DatePillView: View {
    @Binding var selectedDate: Date

    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Configuration
    private let swipeThreshold: CGFloat = 50
    private let pillHeight: CGFloat = 36
    private let arrowSize: CGFloat = 12

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Left arrow (previous day)
            Button {
                navigateToDate(offset: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: arrowSize, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous day")

            // Date pill
            datePill
                .offset(x: dragOffset)
                .gesture(swipeGesture)

            // Right arrow (next day)
            Button {
                navigateToDate(offset: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: arrowSize, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next day")
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Subviews

    private var datePill: some View {
        Text(displayText)
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(minWidth: 120)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(Theme.Colors.glassBorder, lineWidth: 0.5)
            )
            .contentShape(Capsule())
            .accessibilityLabel(accessibilityDateLabel)
            .accessibilityHint("Swipe left or right to change day")
    }

    // MARK: - Computed Properties

    private var displayText: String {
        NotesLine.displayDate(for: selectedDate)
    }

    private var accessibilityDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimating else { return }
                // Limit drag to reasonable bounds
                dragOffset = max(-100, min(100, value.translation.width))
            }
            .onEnded { value in
                guard !isAnimating else { return }

                if value.translation.width < -swipeThreshold {
                    // Swiped left → next day
                    navigateToDate(offset: 1)
                } else if value.translation.width > swipeThreshold {
                    // Swiped right → previous day
                    navigateToDate(offset: -1)
                }

                // Reset offset
                let animation: Animation? = reduceMotion ? nil : Theme.Animation.fast
                withAnimation(animation) {
                    dragOffset = 0
                }
            }
    }

    // MARK: - Methods

    private func navigateToDate(offset: Int) {
        guard !isAnimating else { return }

        isAnimating = true
        HapticsService.shared.selectionFeedback()

        let animation: Animation? = reduceMotion ? nil : Theme.Animation.fast

        // Slide out animation
        withAnimation(animation) {
            dragOffset = offset > 0 ? -60 : 60
        }

        // Update date and slide back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
                selectedDate = newDate
            }

            withAnimation(animation) {
                dragOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isAnimating = false
            }
        }
    }
}

// MARK: - Compact Stats Bar

struct CompactStatsBar: View {
    let completedCount: Int
    let totalCount: Int
    let streakDays: Int
    let points: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Completion count
            HStack(spacing: Theme.Spacing.xxs) {
                Text("\(completedCount)/\(totalCount)")
                    .font(Theme.Typography.caption1Medium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("completed")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            separator

            // Streak
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.streakOrange)
                Text("\(streakDays) day\(streakDays == 1 ? "" : "s")")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            separator

            // Points
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.xp)
                Text("\(points) pts")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var separator: some View {
        Text("·")
            .font(Theme.Typography.caption1)
            .foregroundStyle(Theme.Colors.textTertiary)
    }
}

// MARK: - Preview

#Preview("Date Pill") {
    struct PreviewWrapper: View {
        @State private var date = Date()

        var body: some View {
            VStack(spacing: 20) {
                DatePillView(selectedDate: $date)

                Text("Selected: \(date.formatted(date: .complete, time: .omitted))")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding()
            .background(Theme.Colors.background)
        }
    }
    return PreviewWrapper()
}

#Preview("With Stats") {
    VStack(spacing: Theme.Spacing.sm) {
        DatePillView(selectedDate: .constant(Date()))

        CompactStatsBar(
            completedCount: 2,
            totalCount: 5,
            streakDays: 3,
            points: 120
        )
    }
    .padding()
    .background(Theme.Colors.background)
}

#Preview("Yesterday") {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    return DatePillView(selectedDate: .constant(yesterday))
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Tomorrow") {
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    return DatePillView(selectedDate: .constant(tomorrow))
        .padding()
        .background(Theme.Colors.background)
}
