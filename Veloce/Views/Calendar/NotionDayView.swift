//
//  NotionDayView.swift
//  Veloce
//
//  Notion Calendar-Inspired Day View
//  Clean, swipeable day timeline with beautiful event blocks
//

import SwiftUI
import EventKit

// MARK: - Notion Day View

struct NotionDayView: View {
    let date: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onEventTap: ((EKEvent) -> Void)?
    let onTimeSlotTap: ((Date) -> Void)?
    let onComplete: ((TaskItem) -> Void)?

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let startHour = NotionCalendarTokens.Timeline.startHour
    private let endHour = NotionCalendarTokens.Timeline.endHour
    private let hourHeight = NotionCalendarTokens.Timeline.hourHeight
    private let timeGutterWidth = NotionCalendarTokens.Timeline.timeGutterWidth

    // MARK: - Computed Properties

    private var scheduledTasks: [TaskItem] {
        tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            let hour = Calendar.current.component(.hour, from: scheduledTime)
            return hour >= startHour && hour < endHour
        }.sorted { ($0.scheduledTime ?? .distantFuture) < ($1.scheduledTime ?? .distantFuture) }
    }

    private var timedEvents: [EKEvent] {
        events.filter { !$0.isAllDay }
    }

    private var allDayEvents: [EKEvent] {
        events.filter { $0.isAllDay }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // All-day events
            if !allDayEvents.isEmpty {
                NotionAllDayBanner(events: allDayEvents)
            }

            // Timeline
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid background
                        NotionTimelineGrid()

                        // Apple Calendar events layer (behind tasks)
                        eventsLayer

                        // Task blocks layer
                        tasksLayer

                        // Current time indicator (today only)
                        if isToday {
                            NotionCurrentTimeIndicator(
                                hourHeight: hourHeight,
                                startHour: startHour,
                                timeGutterWidth: timeGutterWidth
                            )
                            .id("now")
                        }

                        // Tap zones for quick add
                        tapZonesLayer
                    }
                    .frame(height: NotionCalendarTokens.Timeline.totalHeight)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(timelineBorder)
                .onAppear {
                    scrollToCurrentTime(proxy: proxy)
                }
            }
            .offset(x: dragOffset * 0.3)
        }
        .padding(.horizontal, NotionCalendarTokens.Spacing.screenPadding)
        .contentShape(Rectangle())
    }

    // MARK: - Events Layer

    @ViewBuilder
    private var eventsLayer: some View {
        ForEach(timedEvents, id: \.eventIdentifier) { event in
            NotionAppleEventBlock(
                event: event,
                hourHeight: hourHeight,
                startHour: startHour
            )
            .padding(.leading, timeGutterWidth + NotionCalendarTokens.Timeline.blockInset)
            .padding(.trailing, NotionCalendarTokens.Timeline.blockInset)
            .onTapGesture {
                onEventTap?(event)
            }
            .opacity(0.85)
        }
    }

    // MARK: - Tasks Layer

    @ViewBuilder
    private var tasksLayer: some View {
        ForEach(scheduledTasks) { task in
            NotionTaskBlock(
                task: task,
                hourHeight: hourHeight,
                onTap: { onTaskTap(task) },
                onComplete: onComplete != nil ? { onComplete?(task) } : nil
            )
            .offset(y: yOffset(for: task))
            .padding(.leading, timeGutterWidth + NotionCalendarTokens.Timeline.blockInset)
            .padding(.trailing, NotionCalendarTokens.Timeline.blockInset)
        }
    }

    // MARK: - Tap Zones Layer

    @ViewBuilder
    private var tapZonesLayer: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - timeGutterWidth - (NotionCalendarTokens.Timeline.blockInset * 2)

            ForEach(0..<((endHour - startHour) * 4), id: \.self) { slot in
                let hour = startHour + slot / 4
                let minute = (slot % 4) * 15

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: availableWidth, height: hourHeight / 4)
                    .offset(
                        x: timeGutterWidth + NotionCalendarTokens.Timeline.blockInset,
                        y: CGFloat(slot) * hourHeight / 4
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let targetDate = makeTargetDate(hour: hour, minute: minute)
                        HapticsService.shared.selectionFeedback()
                        onTimeSlotTap?(targetDate)
                    }
            }
        }
    }

    private var timelineBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.08),
                        .white.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    // MARK: - Helpers

    private func yOffset(for task: TaskItem) -> CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private func makeTargetDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? date
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        guard isToday else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(NotionCalendarTokens.Animation.scrollToNow) {
                proxy.scrollTo("now", anchor: .center)
            }
        }
    }
}

// MARK: - Empty State

struct NotionDayEmptyState: View {
    let onAddTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text
            VStack(spacing: 6) {
                Text("Nothing scheduled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Tap to add your first task for the day")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Add button
            Button(action: onAddTap) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Add Task")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Preview

#Preview("Day View") {
    ZStack {
        VoidBackground.calendar

        VStack {
            Spacer()
                .frame(height: 120)

            NotionDayView(
                date: Date(),
                tasks: [
                    TaskItem(
                        title: "Morning planning session",
                        estimatedMinutes: 30,
                        scheduledTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
                        taskTypeRaw: "coordinate"
                    ),
                    TaskItem(
                        title: "Design new calendar UI",
                        estimatedMinutes: 90,
                        scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()),
                        taskTypeRaw: "create",
                        starRating: 3
                    ),
                    TaskItem(
                        title: "Team sync call",
                        estimatedMinutes: 45,
                        scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
                        taskTypeRaw: "communicate"
                    )
                ],
                events: [],
                onTaskTap: { _ in },
                onEventTap: nil,
                onTimeSlotTap: nil,
                onComplete: nil
            )

            Spacer()
        }
    }
}

#Preview("Empty State") {
    ZStack {
        VoidBackground.calendar

        NotionDayEmptyState(onAddTap: {})
    }
}
