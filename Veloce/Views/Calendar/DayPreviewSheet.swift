//
//  DayPreviewSheet.swift
//  Veloce
//
//  Living Cosmos Day Preview Sheet
//  A bottom sheet showing tasks for a selected day in month view
//

import SwiftUI
import EventKit

struct DayPreviewSheet: View {
    let date: Date
    let tasks: [TaskItem]
    let events: [EKEvent]
    let onTaskTap: (TaskItem) -> Void
    let onViewFullDay: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetHeader

            // Content
            if tasks.isEmpty && events.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Tasks section
                        if !tasks.isEmpty {
                            tasksSection
                        }

                        // Events section
                        if !events.isEmpty {
                            eventsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background {
            ZStack {
                Color.black.opacity(0.8)
                VoidBackground.calendar.opacity(0.3)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(LivingCosmos.Animations.stellarBounce.delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        VStack(spacing: 8) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date.formatted(.dateTime.weekday(.wide)))
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Text(date.formatted(.dateTime.month(.wide).day()))
                        .font(Theme.Typography.cosmosTitleLarge)
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    HapticsService.shared.impact()
                    onViewFullDay()
                } label: {
                    HStack(spacing: 4) {
                        Text("View Day")
                            .dynamicTypeFont(base: 14, weight: .medium)

                        Image(systemName: "arrow.right")
                            .dynamicTypeFont(base: 12, weight: .semibold)
                    }
                    .foregroundStyle(Theme.CelestialColors.plasmaCore)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Theme.CelestialColors.plasmaCore.opacity(0.15))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("TASKS")
                    .font(LivingCosmos.SectionHeader.font)
                    .foregroundStyle(LivingCosmos.SectionHeader.color)
                    .tracking(LivingCosmos.SectionHeader.letterSpacing)

                Spacer()

                Text("\(tasks.count)")
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            // Task list
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                DayPreviewTaskRow(task: task, onTap: { onTaskTap(task) })
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(
                        LivingCosmos.Animations.stellarBounce.delay(Double(index) * 0.05),
                        value: appeared
                    )
            }
        }
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("CALENDAR EVENTS")
                    .font(LivingCosmos.SectionHeader.font)
                    .foregroundStyle(LivingCosmos.SectionHeader.color)
                    .tracking(LivingCosmos.SectionHeader.letterSpacing)

                Spacer()

                Text("\(events.count)")
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            // Event list
            ForEach(events, id: \.eventIdentifier) { event in
                DayPreviewEventRow(event: event)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                SwiftUI.Circle()
                    .fill(Theme.CelestialColors.nebulaCore.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.checkmark")
                    .dynamicTypeFont(base: 36, weight: .light)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            VStack(spacing: 4) {
                Text("Clear Day")
                    .font(Theme.Typography.cosmosTitle)
                    .foregroundStyle(.white)

                Text("No tasks or events scheduled")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            Spacer()
        }
    }
}

// MARK: - Task Row

struct DayPreviewTaskRow: View {
    let task: TaskItem
    let onTap: () -> Void

    @State private var isPressed = false

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Plasma core indicator
                ZStack {
                    SwiftUI.Circle()
                        .fill(taskColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [taskColor, taskColor.opacity(0.6)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 24, height: 24)

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .dynamicTypeFont(base: 10, weight: .bold)
                            .foregroundStyle(.white)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .dynamicTypeFont(base: 15, weight: .medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .strikethrough(task.isCompleted, color: .white.opacity(0.5))

                    HStack(spacing: 8) {
                        if let time = task.scheduledTime {
                            Label(time.formatted(.dateTime.hour().minute()), systemImage: "clock")
                                .font(Theme.Typography.cosmosMeta)
                                .foregroundStyle(Theme.CelestialColors.starDim)
                        }

                        if let duration = task.estimatedMinutes {
                            Text("\(duration)m")
                                .font(Theme.Typography.cosmosMeta)
                                .foregroundStyle(Theme.CelestialColors.starGhost)
                        }
                    }
                }

                Spacer()

                // Points
                if !task.isCompleted {
                    Text("+\(task.potentialPoints)")
                        .font(Theme.Typography.cosmosPoints)
                        .foregroundStyle(taskColor)
                }

                Image(systemName: "chevron.right")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [taskColor.opacity(0.08), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(taskColor.opacity(0.2), lineWidth: 1)
                    }
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(LivingCosmos.Animations.quick) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(LivingCosmos.Animations.quick) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Event Row

struct DayPreviewEventRow: View {
    let event: EKEvent

    private var eventColor: Color {
        Color(cgColor: event.calendar.cgColor)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(eventColor)
                .frame(width: 4, height: 36)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Event")
                    .dynamicTypeFont(base: 15, weight: .medium)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                if event.isAllDay {
                    Text("All Day")
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                } else {
                    Text(formatEventTime())
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }

            Spacer()

            // Calendar name
            Text(event.calendar.title)
                .dynamicTypeFont(base: 11, weight: .medium)
                .foregroundStyle(eventColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(eventColor.opacity(0.15))
                }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .opacity(0.8)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(eventColor.opacity(0.15), lineWidth: 1)
                }
        }
    }

    private func formatEventTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        return "\(start) - \(end)"
    }
}

// MARK: - Preview

#Preview {
    DayPreviewSheet(
        date: Date(),
        tasks: [],
        events: [],
        onTaskTap: { _ in },
        onViewFullDay: {}
    )
}
