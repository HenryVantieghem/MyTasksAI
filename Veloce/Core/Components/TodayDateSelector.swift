//
//  TodayDateSelector.swift
//  MyTasksAI
//
//  Reusable date selector pill with unlimited swipe navigation
//  Shows "Today", "Yesterday", "Tomorrow" or formatted date
//

import SwiftUI

// MARK: - Today Date Selector

struct TodayDateSelector: View {
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
        HStack(spacing: Theme.Spacing.sm) {
            // Today indicator dot
            if Calendar.current.isDateInToday(selectedDate) {
                SwiftUI.Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: 6, height: 6)
            }

            Text(displayText)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
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

// MARK: - Compact Date Selector Variant

/// A more compact version of the date selector for tighter spaces
struct CompactDateSelector: View {
    @Binding var selectedDate: Date

    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let swipeThreshold: CGFloat = 40

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Left arrow
            Button {
                navigateToDate(offset: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .buttonStyle(.plain)

            // Date text
            Text(compactDisplayText)
                .font(Theme.Typography.caption1Medium)
                .foregroundStyle(Theme.Colors.textSecondary)
                .offset(x: dragOffset * 0.3)
                .gesture(compactSwipeGesture)

            // Right arrow
            Button {
                navigateToDate(offset: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var compactDisplayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    private var compactSwipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimating else { return }
                dragOffset = max(-50, min(50, value.translation.width))
            }
            .onEnded { value in
                guard !isAnimating else { return }

                if value.translation.width < -swipeThreshold {
                    navigateToDate(offset: 1)
                } else if value.translation.width > swipeThreshold {
                    navigateToDate(offset: -1)
                }

                let animation: Animation? = reduceMotion ? nil : Theme.Animation.fast
                withAnimation(animation) {
                    dragOffset = 0
                }
            }
    }

    private func navigateToDate(offset: Int) {
        guard !isAnimating else { return }

        isAnimating = true
        HapticsService.shared.selectionFeedback()

        if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
            selectedDate = newDate
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isAnimating = false
        }
    }
}

// MARK: - Preview

#Preview("Today Date Selector") {
    struct PreviewWrapper: View {
        @State private var date = Date()

        var body: some View {
            VStack(spacing: 40) {
                TodayDateSelector(selectedDate: $date)

                CompactDateSelector(selectedDate: $date)

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

#Preview("Yesterday") {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    return TodayDateSelector(selectedDate: .constant(yesterday))
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Week Ago") {
    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    return TodayDateSelector(selectedDate: .constant(weekAgo))
        .padding()
        .background(Theme.Colors.background)
}
