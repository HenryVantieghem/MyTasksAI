//
//  TodayPillView.swift
//  Veloce
//
//  Unified date navigation pill with iOS 26 Liquid Glass
//  Swipeable navigation, Today indicator, consistent across all pages
//

import SwiftUI

// MARK: - Today Pill View

struct TodayPillView: View {
    @Binding var selectedDate: Date

    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Configuration
    private let swipeThreshold: CGFloat = 50
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
            .contentShape(Rectangle())
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
            .contentShape(Rectangle())
            .accessibilityLabel("Next day")
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Subviews

    private var datePill: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Today indicator dot
            if Calendar.current.isDateInToday(selectedDate) {
                Circle()
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
        // iOS 26 Native Liquid Glass effect
        .glassEffect(.regular, in: .capsule)
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

// MARK: - Preview

#Preview("Today Pill") {
    struct PreviewWrapper: View {
        @State private var date = Date()

        var body: some View {
            VStack(spacing: 40) {
                TodayPillView(selectedDate: $date)

                Text("Selected: \(date.formatted(date: .complete, time: .omitted))")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding()
            .background { VoidBackground.standard }
        }
    }
    return PreviewWrapper()
}

#Preview("Today Pill - Yesterday") {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    return TodayPillView(selectedDate: .constant(yesterday))
        .padding()
        .background { VoidBackground.standard }
}

#Preview("Today Pill - Week Ago") {
    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    return TodayPillView(selectedDate: .constant(weekAgo))
        .padding()
        .background { VoidBackground.standard }
}
