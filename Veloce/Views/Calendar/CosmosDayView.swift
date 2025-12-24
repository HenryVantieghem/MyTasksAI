//
//  CosmosDayView.swift
//  Veloce
//
//  Living Cosmos Day Timeline
//  A vertical scrollable timeline with plasma task blocks and cosmic effects
//

import SwiftUI
import EventKit

// MARK: - Cosmos Day View

struct CosmosDayView: View {
    let date: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onReschedule: ((TaskItem, Date) -> Void)?
    let onTimeSlotLongPress: ((Date) -> Void)?

    @State private var dropTargetTime: Date?
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let startHour = LivingCosmos.Calendar.startHour
    private let endHour = LivingCosmos.Calendar.endHour
    private let hourHeight = LivingCosmos.Calendar.hourHeight
    private let timeGutterWidth = LivingCosmos.Calendar.timeGutterWidth
    private let blockPadding = LivingCosmos.Calendar.blockPadding

    // MARK: - Computed Properties

    private var scheduledTasks: [TaskItem] {
        tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            let hour = Calendar.current.component(.hour, from: scheduledTime)
            return hour >= startHour && hour < endHour
        }
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

    private var totalHeight: CGFloat {
        CGFloat(endHour - startHour) * hourHeight
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // All-day events banner
            if !allDayEvents.isEmpty {
                allDayEventsBanner
                    .padding(.bottom, 8)
            }

            // Main scrollable timeline
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid background
                        hourGrid

                        // Apple Calendar events (background layer)
                        eventsLayer

                        // Task blocks (foreground layer)
                        tasksLayer

                        // Current time "Now Horizon" indicator
                        if isToday {
                            NowHorizonIndicator(
                                hourHeight: hourHeight,
                                startHour: startHour,
                                timeGutterWidth: timeGutterWidth
                            )
                            .id("nowHorizon")
                        }

                        // Drop zones for drag-and-drop
                        dropZonesLayer

                        // Long-press zones for quick-add
                        longPressZonesLayer
                    }
                    .frame(height: totalHeight)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(timelineBorder)
                .onAppear {
                    scrollToCurrentTime(proxy: proxy)
                    withAnimation(LivingCosmos.Animations.stellarBounce.delay(0.2)) {
                        appeared = true
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - All-Day Events Banner

    private var allDayEventsBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allDayEvents, id: \.eventIdentifier) { event in
                    HStack(spacing: 6) {
                        SwiftUI.Circle()
                            .fill(Color(cgColor: event.calendar.cgColor))
                            .frame(width: 8, height: 8)

                        Text(event.title ?? "Event")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule()
                                    .stroke(Color(cgColor: event.calendar.cgColor).opacity(0.3), lineWidth: 1)
                            }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Hour Grid

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(spacing: 0) {
                    // Time label
                    Text(formatHour(hour))
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .frame(width: timeGutterWidth, alignment: .trailing)
                        .padding(.trailing, 8)

                    // Hour line
                    Rectangle()
                        .fill(Theme.CelestialColors.starGhost)
                        .frame(height: 1)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }

    // MARK: - Events Layer

    @ViewBuilder
    private var eventsLayer: some View {
        ForEach(timedEvents, id: \.eventIdentifier) { event in
            CosmosEventBlock(
                event: event,
                hourHeight: hourHeight,
                startHour: startHour
            )
            .padding(.leading, timeGutterWidth + blockPadding)
            .padding(.trailing, blockPadding)
            .offset(y: yOffset(for: event))
        }
    }

    // MARK: - Tasks Layer

    @ViewBuilder
    private var tasksLayer: some View {
        ForEach(Array(scheduledTasks.enumerated()), id: \.element.id) { index, task in
            CosmosTimeBlock(
                task: task,
                hourHeight: hourHeight,
                onTap: { onTaskTap(task) },
                onComplete: {
                    // Toggle completion
                    task.isCompleted.toggle()
                    if task.isCompleted {
                        task.completedAt = Date()
                        HapticsService.shared.success()
                    }
                }
            )
            .offset(y: yOffset(for: task))
            .padding(.leading, timeGutterWidth + blockPadding)
            .padding(.trailing, blockPadding)
            .draggable(task) {
                CosmosTaskDragPreview(task: task)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(
                LivingCosmos.Animations.stellarBounce.delay(Double(index) * 0.06),
                value: appeared
            )
        }
    }

    // MARK: - Drop Zones Layer

    @ViewBuilder
    private var dropZonesLayer: some View {
        ForEach(0..<((endHour - startHour) * 4), id: \.self) { slot in
            let hour = startHour + slot / 4
            let minute = (slot % 4) * LivingCosmos.Calendar.snapInterval

            Rectangle()
                .fill(Color.clear)
                .frame(height: hourHeight / 4)
                .offset(y: CGFloat(slot) * (hourHeight / 4))
                .padding(.leading, timeGutterWidth)
                .dropDestination(for: TaskItem.self) { items, _ in
                    guard let task = items.first else { return false }
                    let targetDate = makeTargetDate(hour: hour, minute: minute)
                    HapticsService.shared.success()
                    onReschedule?(task, targetDate)
                    return true
                } isTargeted: { targeted in
                    if targeted {
                        dropTargetTime = makeTargetDate(hour: hour, minute: minute)
                        HapticsService.shared.selectionFeedback()
                    } else if dropTargetTime == makeTargetDate(hour: hour, minute: minute) {
                        dropTargetTime = nil
                    }
                }
                .overlay {
                    if dropTargetTime == makeTargetDate(hour: hour, minute: minute) {
                        CosmosDropTargetIndicator()
                            .padding(.leading, timeGutterWidth + blockPadding)
                            .padding(.trailing, blockPadding)
                    }
                }
        }
    }

    // MARK: - Long Press Zones Layer

    @ViewBuilder
    private var longPressZonesLayer: some View {
        ForEach(0..<((endHour - startHour) * 4), id: \.self) { slot in
            let hour = startHour + slot / 4
            let minute = (slot % 4) * LivingCosmos.Calendar.snapInterval

            Rectangle()
                .fill(Color.clear)
                .frame(height: hourHeight / 4)
                .offset(y: CGFloat(slot) * (hourHeight / 4))
                .padding(.leading, timeGutterWidth)
                .onLongPressGesture(minimumDuration: 0.5) {
                    let targetDate = makeTargetDate(hour: hour, minute: minute)
                    HapticsService.shared.impact()
                    onTimeSlotLongPress?(targetDate)
                }
        }
    }

    // MARK: - Timeline Border

    private var timelineBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Helper Functions

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    private func yOffset(for task: TaskItem) -> CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)
        let hourOffset = CGFloat(hour - startHour) * hourHeight
        let minuteOffset = CGFloat(minute) / 60.0 * hourHeight
        return hourOffset + minuteOffset
    }

    private func yOffset(for event: EKEvent) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        let hourOffset = CGFloat(hour - startHour) * hourHeight
        let minuteOffset = CGFloat(minute) / 60.0 * hourHeight
        return hourOffset + minuteOffset
    }

    private func makeTargetDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? date
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        guard isToday else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                proxy.scrollTo("nowHorizon", anchor: .center)
            }
        }
    }
}

// MARK: - Event Block

struct CosmosEventBlock: View {
    let event: EKEvent
    let hourHeight: CGFloat
    let startHour: Int

    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var blockHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600
        return max(CGFloat(hours) * hourHeight, LivingCosmos.Calendar.minBlockHeight)
    }

    private var eventColor: Color {
        Color(cgColor: event.calendar.cgColor)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(eventColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Event")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(blockHeight > 50 ? 2 : 1)

                if blockHeight > 40 {
                    Text(formatEventTime())
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(height: blockHeight)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .opacity(LivingCosmos.Calendar.eventOpacity)
                .overlay {
                    // Subtle shimmer
                    if !reduceMotion {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.03),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .offset(x: shimmerPhase)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(eventColor.opacity(0.2), lineWidth: 1)
                }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                shimmerPhase = 200
            }
        }
    }

    private func formatEventTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
}

// MARK: - Task Drag Preview

struct CosmosTaskDragPreview: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 8) {
            SwiftUI.Circle()
                .fill(task.taskType.tiimoColor)
                .frame(width: 12, height: 12)

            Text(task.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .stroke(task.taskType.tiimoColor.opacity(0.5), lineWidth: 1)
                }
        }
        .shadow(color: task.taskType.tiimoColor.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Drop Target Indicator

struct CosmosDropTargetIndicator: View {
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Theme.CelestialColors.nebulaEdge.opacity(0.2))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.CelestialColors.nebulaEdge, lineWidth: 2)
                    .scaleEffect(pulseScale)
            }
            .frame(height: LivingCosmos.Calendar.minBlockHeight)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulseScale = 1.02
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.calendar

        CosmosDayView(
            date: Date(),
            tasks: [],
            events: [],
            onTaskTap: { _ in },
            onReschedule: nil,
            onTimeSlotLongPress: nil
        )
    }
}
