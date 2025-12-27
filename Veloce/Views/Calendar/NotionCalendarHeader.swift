//
//  NotionCalendarHeader.swift
//  Veloce
//
//  Notion Calendar-Inspired Header
//  Clean header with month/year, today button, and view mode toggle
//

import SwiftUI

// MARK: - Notion Calendar Header

struct NotionCalendarHeader: View {
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    let onDateTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        HStack(spacing: NotionCalendarTokens.Spacing.componentSpacing) {
            // Month/Year Display
            monthYearButton

            Spacer()

            // Today Button
            todayButton

            // View Mode Toggle
            viewModeToggle
        }
        .padding(.horizontal, NotionCalendarTokens.Spacing.screenPadding)
        .frame(height: NotionCalendarTokens.Header.height)
    }

    // MARK: - Month/Year Button

    private var monthYearButton: some View {
        Button(action: onDateTap) {
            HStack(spacing: 8) {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(NotionCalendarTokens.Typography.monthYear)
                    .foregroundStyle(.white)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Today Button

    private var todayButton: some View {
        Button {
            withAnimation(NotionCalendarTokens.Animation.daySwipe) {
                selectedDate = Date()
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            Text("Today")
                .font(NotionCalendarTokens.Typography.todayButton)
                .foregroundStyle(isToday ? Theme.Colors.aiCyan : .white.opacity(0.7))
                .padding(.horizontal, NotionCalendarTokens.Header.todayButtonPadding)
                .padding(.vertical, 8)
                .background {
                    if isToday {
                        Capsule()
                            .fill(Theme.Colors.aiCyan.opacity(0.12))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: 2) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                viewModeButton(for: mode)
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                }
        }
    }

    private func viewModeButton(for mode: CalendarViewMode) -> some View {
        Button {
            guard viewMode != mode else { return }

            withAnimation(NotionCalendarTokens.Animation.viewModeChange) {
                viewMode = mode
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            Text(mode.rawValue)
                .font(NotionCalendarTokens.Typography.viewToggle)
                .foregroundStyle(viewMode == mode ? .white : .white.opacity(0.5))
                .padding(.horizontal, NotionCalendarTokens.Header.togglePadding)
                .padding(.vertical, 8)
                .background {
                    if viewMode == mode {
                        Capsule()
                            .fill(.white.opacity(0.12))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Navigation Strip

struct NotionDateStrip: View {
    @Binding var selectedDate: Date
    let hasEvents: (Date) -> Bool

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(weekDates, id: \.self) { date in
                dateCell(for: date)
            }
        }
        .padding(.horizontal, NotionCalendarTokens.Spacing.screenPadding)
        .padding(.vertical, 8)
    }

    private func dateCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasEvent = hasEvents(date)

        return Button {
            withAnimation(NotionCalendarTokens.Animation.quick) {
                selectedDate = date
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            VStack(spacing: 4) {
                // Day of week
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(NotionCalendarTokens.Typography.dayOfWeek)
                    .foregroundStyle(isSelected ? .white : NotionCalendarTokens.Colors.secondaryText)

                // Date number
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(NotionCalendarTokens.Colors.selectedDate)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .stroke(Theme.Colors.aiCyan, lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(isSelected ? NotionCalendarTokens.Typography.dateNumberLarge : NotionCalendarTokens.Typography.dateNumber)
                        .foregroundStyle(isSelected ? .white : (isToday ? Theme.Colors.aiCyan : .white.opacity(0.8)))
                }
                .frame(width: 40, height: 40)

                // Event indicator dot
                Circle()
                    .fill(hasEvent ? Theme.Colors.aiPurple : Color.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Calendar Header") {
    ZStack {
        VoidBackground.calendar

        VStack {
            Spacer()
                .frame(height: 60)

            NotionCalendarHeader(
                selectedDate: .constant(Date()),
                viewMode: .constant(.day),
                onDateTap: {}
            )

            NotionDateStrip(
                selectedDate: .constant(Date()),
                hasEvents: { _ in Bool.random() }
            )

            Spacer()
        }
    }
}
