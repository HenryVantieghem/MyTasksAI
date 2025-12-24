//
//  TiimoDateCarousel.swift
//  Veloce
//
//  Tiimo-Style Date Carousel
//  Horizontal scrolling date pill navigation
//

import SwiftUI

// MARK: - Tiimo Date Carousel

/// Horizontal scrolling date carousel for quick date navigation
struct TiimoDateCarousel: View {
    @Binding var selectedDate: Date
    let hasEvents: (Date) -> Bool

    @State private var scrollPosition: Int?

    private var dates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-TiimoDesignTokens.DateCarousel.daysBefore...TiimoDesignTokens.DateCarousel.daysAfter).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }

    private var todayIndex: Int {
        TiimoDesignTokens.DateCarousel.daysBefore
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TiimoDesignTokens.DateCarousel.spacing) {
                    ForEach(dates.indices, id: \.self) { index in
                        let date = dates[index]
                        TiimoDatePill(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            hasEvents: hasEvents(date)
                        ) {
                            HapticsService.shared.selectionFeedback()
                            withAnimation(TiimoDesignTokens.Animation.viewTransition) {
                                selectedDate = date
                            }
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollTargetLayout()
            .onAppear {
                // Scroll to today on first appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.none) {
                        proxy.scrollTo(todayIndex, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                // Scroll to selected date
                if let index = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
                    withAnimation(TiimoDesignTokens.Animation.viewTransition) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
        .frame(height: TiimoDesignTokens.DateCarousel.height)
    }
}

// MARK: - Date Pill

/// Individual date pill in the carousel
struct TiimoDatePill: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var glowPulse: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Day name
                Text(dayName)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))

                // Day number
                Text(dayNumber)
                    .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                // Event indicator
                eventIndicator
            }
            .frame(
                width: TiimoDesignTokens.DateCarousel.pillWidth,
                height: TiimoDesignTokens.DateCarousel.pillHeight
            )
            .background(pillBackground)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(TiimoDesignTokens.Animation.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            if hasEvents && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dayName) \(dayNumber)\(hasEvents ? ", has events" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Computed Properties

    private var dayName: String {
        date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    @ViewBuilder
    private var eventIndicator: some View {
        SwiftUI.Circle()
            .fill(hasEvents ? indicatorColor : .clear)
            .frame(width: 5, height: 5)
            .shadow(
                color: hasEvents ? indicatorColor.opacity(glowPulse ? 0.6 : 0.3) : .clear,
                radius: glowPulse ? 4 : 2
            )
    }

    private var indicatorColor: Color {
        isSelected ? .white : Theme.Colors.aiCyan
    }

    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: TiimoDesignTokens.DateCarousel.pillCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.6),
                            Theme.Colors.aiBlue.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Theme.Colors.aiPurple.opacity(0.3), radius: 8, y: 4)
        } else if isToday {
            RoundedRectangle(cornerRadius: TiimoDesignTokens.DateCarousel.pillCornerRadius)
                .stroke(Theme.Colors.aiCyan.opacity(0.5), lineWidth: 1)
        } else {
            Color.clear
        }
    }
}

// MARK: - Month Year Header

/// Header showing current month and year with navigation
struct TiimoMonthYearHeader: View {
    @Binding var selectedDate: Date
    let onMonthTap: () -> Void

    private var monthYearText: String {
        selectedDate.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        Button(action: onMonthTap) {
            HStack(spacing: 8) {
                Text(monthYearText)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select month: \(monthYearText)")
        .accessibilityHint("Double tap to open month picker")
    }
}

// MARK: - View Mode Toggle

/// Segmented control for Day/Week/Month view modes
struct TiimoViewModeToggle: View {
    @Binding var viewMode: TiimoViewMode

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TiimoViewMode.allCases, id: \.self) { mode in
                Button {
                    HapticsService.shared.selectionFeedback()
                    withAnimation(TiimoDesignTokens.Animation.viewTransition) {
                        viewMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12, weight: .semibold))

                        if viewMode == mode {
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundStyle(viewMode == mode ? .primary : .secondary)
                    .padding(.horizontal, viewMode == mode ? 14 : 10)
                    .padding(.vertical, 10)
                    .background {
                        if viewMode == mode {
                            Capsule()
                                .fill(Theme.Colors.aiCyan.opacity(0.2))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassEffect(.regular, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("View mode: \(viewMode.rawValue)")
    }
}

// MARK: - View Mode Enum

/// Calendar view modes
enum TiimoViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var icon: String {
        switch self {
        case .day: return "sun.horizon"
        case .week: return "calendar.day.timeline.left"
        case .month: return "calendar"
        }
    }
}

// MARK: - Preview

#Preview("Date Carousel") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 24) {
            TiimoMonthYearHeader(
                selectedDate: .constant(Date()),
                onMonthTap: {}
            )

            TiimoDateCarousel(
                selectedDate: .constant(Date()),
                hasEvents: { date in
                    // Sample: every other day has events
                    Calendar.current.component(.day, from: date) % 2 == 0
                }
            )

            TiimoViewModeToggle(viewMode: .constant(.day))
        }
        .padding()
    }
}
