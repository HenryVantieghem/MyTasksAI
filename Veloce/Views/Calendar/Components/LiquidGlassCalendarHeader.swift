//
//  LiquidGlassCalendarHeader.swift
//  Veloce
//
//  iOS 26 Liquid Glass Calendar Header
//  Native glass effects with proper HIG touch targets and typography
//

import SwiftUI

// MARK: - Liquid Glass Calendar Header

struct LiquidGlassCalendarHeader: View {
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDateTap: () -> Void
    let onTodayTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let calendar = Calendar.current

    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    // Responsive padding
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 24 : 16
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main header row
            HStack(spacing: 12) {
                // Navigation group
                navigationGroup

                Spacer()

                // Right side controls
                HStack(spacing: 8) {
                    // Today button (only show if not today)
                    if !isToday {
                        todayButton
                    }

                    // View mode segmented control
                    viewModeSegment
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 12)

            // Context subtitle (shows week range or month context)
            contextSubtitle
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 8)
        }
        .background {
            // Subtle separator at bottom
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color(.separator).opacity(0.3))
                    .frame(height: 0.5)
            }
        }
    }

    // MARK: - Navigation Group

    private var navigationGroup: some View {
        HStack(spacing: 8) {
            // Previous button - 44pt minimum touch target
            Button {
                HapticsService.shared.lightImpact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onPrevious()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44) // HIG minimum
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Month/Year Display
            Button(action: onDateTap) {
                HStack(spacing: 6) {
                    Text(formattedDate)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                }
                .frame(height: 44) // Touch target
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Next button - 44pt minimum touch target
            Button {
                HapticsService.shared.lightImpact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onNext()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44) // HIG minimum
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Formatted Date

    private var formattedDate: String {
        switch viewMode {
        case .day:
            return selectedDate.formatted(.dateTime.month(.wide).day())
        case .week:
            return selectedDate.formatted(.dateTime.month(.wide).year())
        case .month:
            return selectedDate.formatted(.dateTime.month(.wide).year())
        }
    }

    // MARK: - Context Subtitle

    @ViewBuilder
    private var contextSubtitle: some View {
        switch viewMode {
        case .day:
            HStack {
                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                if calendar.isDateInToday(selectedDate) {
                    Text("Today")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }

                Spacer()
            }

        case .week:
            HStack {
                if let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start,
                   let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) {
                    Text("\(weekStart.formatted(.dateTime.month(.abbreviated).day())) - \(weekEnd.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                if isCurrentWeek {
                    Text("This Week")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }

                Spacer()
            }

        case .month:
            HStack {
                if let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) {
                    let daysInMonth = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 30
                    Text("\(daysInMonth) days")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                if isCurrentMonth {
                    Text("This Month")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }

                Spacer()
            }
        }
    }

    private var isCurrentWeek: Bool {
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
              let selectedWeekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else {
            return false
        }
        return calendar.isDate(currentWeekStart, inSameDayAs: selectedWeekStart)
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(Date(), equalTo: selectedDate, toGranularity: .month)
    }

    // MARK: - Today Button

    private var todayButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                onTodayTap()
            }
        } label: {
            Text("Today")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .glassEffect(in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - View Mode Segment (Liquid Glass)

    private var viewModeSegment: some View {
        HStack(spacing: 2) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                viewModeButton(for: mode)
            }
        }
        .padding(4)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func viewModeButton(for mode: CalendarViewMode) -> some View {
        let isSelected = viewMode == mode

        return Button {
            guard viewMode != mode else { return }
            HapticsService.shared.selectionFeedback()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                viewMode = mode
            }
        } label: {
            Text(mode.displayLabel)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentColor.opacity(0.15))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CalendarViewMode Extension

extension CalendarViewMode {
    var displayLabel: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
}

// MARK: - Liquid Glass Date Picker Sheet

struct LiquidGlassDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
            }
            .navigationTitle("Go to Date")
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
}

// MARK: - Preview

#Preview("Calendar Header") {
    VStack {
        LiquidGlassCalendarHeader(
            selectedDate: .constant(Date()),
            viewMode: .constant(.week),
            onPrevious: {},
            onNext: {},
            onDateTap: {},
            onTodayTap: {}
        )

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
