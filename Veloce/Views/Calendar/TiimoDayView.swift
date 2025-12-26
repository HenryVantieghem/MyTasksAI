//
//  TiimoDayView.swift
//  Veloce
//
//  Tiimo-Style Vertical Day Timeline
//  The core visual planner experience
//

import SwiftUI
import EventKit
import UniformTypeIdentifiers

// MARK: - Tiimo Day View

/// Vertical scrolling day timeline - the signature Tiimo experience
struct TiimoDayView: View {
    let date: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onEventTap: ((EKEvent) -> Void)?
    let onReschedule: ((TaskItem, Date) -> Void)?
    let onTimeSlotTap: ((Date) -> Void)?

    @State private var dropTargetTime: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let startHour = TiimoDesignTokens.Timeline.startHour
    private let endHour = TiimoDesignTokens.Timeline.endHour
    private let hourHeight = TiimoDesignTokens.Timeline.hourHeight
    private let timeGutterWidth = TiimoDesignTokens.Timeline.timeGutterWidth
    private let blockInset = TiimoDesignTokens.Timeline.blockInset

    // MARK: - Computed Properties

    /// Tasks scheduled within visible hours
    private var scheduledTasks: [TaskItem] {
        tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: scheduledTime)
            return hour >= startHour && hour < endHour
        }
    }

    /// Events within visible hours (excluding all-day)
    private var timedEvents: [EKEvent] {
        events.filter { !$0.isAllDay }
    }

    /// All-day events
    private var allDayEvents: [EKEvent] {
        events.filter { $0.isAllDay }
    }

    /// Check if date is today
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // All-day events banner
            if !allDayEvents.isEmpty {
                TiimoAllDayEventBanner(events: allDayEvents)
                    .padding(.bottom, 8)
            }

            // Main scrollable timeline
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid background
                        TiimoHourGrid(
                            startHour: startHour,
                            endHour: endHour,
                            hourHeight: hourHeight
                        )

                        // Apple Calendar events (background layer)
                        eventsLayer

                        // Task blocks (foreground layer)
                        tasksLayer

                        // Current time indicator
                        if isToday {
                            TiimoCurrentTimeIndicator(
                                hourHeight: hourHeight,
                                startHour: startHour,
                                timeGutterWidth: timeGutterWidth
                            )
                            .id("now")
                        }

                        // Drop zones for drag-and-drop
                        dropZonesLayer
                    }
                    .frame(height: TiimoDesignTokens.Timeline.totalHeight)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(timelineBorder)
                .onAppear {
                    scrollToCurrentTime(proxy: proxy)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Layers

    /// Layer containing Apple Calendar events
    @ViewBuilder
    private var eventsLayer: some View {
        ForEach(timedEvents, id: \.eventIdentifier) { event in
            TiimoEventBlock(
                event: event,
                hourHeight: hourHeight,
                startHour: startHour
            )
            .padding(.leading, timeGutterWidth + blockInset)
            .padding(.trailing, blockInset)
            .onTapGesture {
                onEventTap?(event)
            }
        }
    }

    /// Layer containing task blocks
    @ViewBuilder
    private var tasksLayer: some View {
        ForEach(scheduledTasks) { task in
            TiimoTimeBlock(
                task: task,
                hourHeight: hourHeight,
                onTap: { onTaskTap(task) },
                onLongPress: {
                    // Initiate drag mode
                    HapticsService.shared.impact()
                }
            )
            .offset(y: yOffset(for: task))
            .padding(.leading, timeGutterWidth + blockInset)
            .padding(.trailing, blockInset)
            .draggable(TaskTransferID(from: task)) {
                TiimoTaskDragPreview(task: task)
            }
        }
    }

    /// Layer containing invisible drop zones
    @ViewBuilder
    private var dropZonesLayer: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - timeGutterWidth - (blockInset * 2)

            ForEach(0..<((endHour - startHour) * 4), id: \.self) { slot in
                let hour = startHour + slot / 4
                let minute = (slot % 4) * 15

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: availableWidth, height: hourHeight / 4)
                    .offset(
                        x: timeGutterWidth + blockInset,
                        y: CGFloat(slot) * hourHeight / 4
                    )
                    .dropDestination(for: TaskTransferID.self) { items, _ in
                        guard let transferID = items.first,
                              let task = tasks.first(where: { $0.id == transferID.id }) else { return false }
                        let targetDate = makeTargetDate(hour: hour, minute: minute)
                        HapticsService.shared.success()
                        onReschedule?(task, targetDate)
                        dropTargetTime = nil
                        return true
                    } isTargeted: { targeted in
                        if targeted {
                            dropTargetTime = makeTargetDate(hour: hour, minute: minute)
                            HapticsService.shared.selectionFeedback()
                        } else if dropTargetTime != nil {
                            // Only clear if we're the current target
                            let targetHour = Calendar.current.component(.hour, from: dropTargetTime!)
                            let targetMinute = Calendar.current.component(.minute, from: dropTargetTime!)
                            if targetHour == hour && targetMinute == minute {
                                dropTargetTime = nil
                            }
                        }
                    }
                    .onTapGesture {
                        let targetDate = makeTargetDate(hour: hour, minute: minute)
                        onTimeSlotTap?(targetDate)
                    }
            }

            // Drop target indicator
            if let targetTime = dropTargetTime {
                TiimoDropTargetIndicator(
                    time: targetTime,
                    hourHeight: hourHeight,
                    startHour: startHour,
                    timeGutterWidth: timeGutterWidth
                )
            }
        }
    }

    private var timelineBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.1),
                        .white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Helper Functions

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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                proxy.scrollTo("now", anchor: .center)
            }
        }
    }
}

// MARK: - Empty State View

/// Shown when no tasks are scheduled for the day
struct TiimoDayEmptyState: View {
    let onAddTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.6),
                            Theme.Colors.aiCyan.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 4) {
                Text(TiimoDesignTokens.GentleLanguage.emptyDay)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text(TiimoDesignTokens.GentleLanguage.emptyDaySubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Button {
                HapticsService.shared.impact()
                onAddTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Task")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Theme.Colors.aiPurple.opacity(0.8))
                )
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
        Color.black.ignoresSafeArea()

        TiimoDayView(
            date: Date(),
            tasks: [
                TaskItem(
                    title: "Morning planning",
                    estimatedMinutes: 30,
                    scheduledTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
                    taskTypeRaw: "coordinate"
                ),
                TaskItem(
                    title: "Write documentation",
                    estimatedMinutes: 90,
                    scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()),
                    taskTypeRaw: "create",
                    starRating: 3
                ),
                TaskItem(
                    title: "Team call",
                    estimatedMinutes: 45,
                    scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
                    taskTypeRaw: "communicate"
                )
            ],
            events: [],
            onTaskTap: { _ in },
            onEventTap: nil,
            onReschedule: nil,
            onTimeSlotTap: nil
        )
    }
}
