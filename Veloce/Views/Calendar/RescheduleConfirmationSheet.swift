//
//  RescheduleConfirmationSheet.swift
//  Veloce
//
//  Reschedule Confirmation Sheet - Confirm task rescheduling after drag-drop
//  Shows before/after times and optional calendar event update
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Reschedule Confirmation Sheet

struct RescheduleConfirmationSheet: View {
    let task: TaskItem
    let originalTime: Date?
    let newTime: Date
    let onConfirm: (Bool) -> Void  // Bool = update calendar event
    let onCancel: () -> Void

    @State private var updateCalendarEvent = true

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "calendar.badge.clock")
                    .dynamicTypeFont(base: 48)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Reschedule Task")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            // Task title
            Text(task.title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, Theme.Spacing.lg)

            // Time comparison
            HStack(spacing: Theme.Spacing.xl) {
                // Original time
                VStack(spacing: Theme.Spacing.xs) {
                    Text("From")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textTertiary)

                    if let originalTime = originalTime {
                        Text(originalTime.formatted(.dateTime.hour().minute()))
                            .font(Theme.Typography.title3)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Text(originalTime.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    } else {
                        Text("Unscheduled")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Arrow
                Image(systemName: "arrow.right")
                    .dynamicTypeFont(base: 20, weight: .medium)
                    .foregroundStyle(Theme.Colors.accent)

                // New time
                VStack(spacing: Theme.Spacing.xs) {
                    Text("To")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text(newTime.formatted(.dateTime.hour().minute()))
                        .font(Theme.Typography.title3)
                        .foregroundStyle(Theme.Colors.accent)

                    Text(newTime.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Theme.Colors.glassBackground)
            )
            .padding(.horizontal, Theme.Spacing.lg)

            // Calendar sync toggle
            if task.calendarEventId != nil {
                Toggle(isOn: $updateCalendarEvent) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Theme.Colors.aiBlue)
                        Text("Update calendar event")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.accent))
                .padding(.horizontal, Theme.Spacing.lg)
            }

            // Buttons
            VStack(spacing: Theme.Spacing.sm) {
                // Confirm button
                Button {
                    HapticsService.shared.success()
                    onConfirm(updateCalendarEvent)
                } label: {
                    Text("Confirm Reschedule")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
                .buttonStyle(.plain)

                // Cancel button
                Button {
                    HapticsService.shared.lightImpact()
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(.vertical, Theme.Spacing.xl)
        .presentationDetents([.height(450)])
        .presentationDragIndicator(.visible)
        .voidPresentationBackground()
    }
}

// MARK: - Task ID Transfer Wrapper

/// Lightweight Sendable wrapper for transferring task IDs in drag operations
/// SwiftData @Model classes are not Sendable, so we transfer just the UUID
struct TaskTransferID: Codable, Transferable, Sendable {
    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .plainText)
    }

    init(from task: TaskItem) {
        self.id = task.id
    }
}

// MARK: - Draggable Task Card Modifier

struct DraggableTaskModifier: ViewModifier {
    let task: TaskItem
    @State private var isDragging = false

    func body(content: Content) -> some View {
        content
            .opacity(isDragging ? 0.5 : 1)
            .scaleEffect(isDragging ? 0.95 : 1)
            .animation(.spring(response: 0.3), value: isDragging)
            .draggable(TaskTransferID(from: task)) {
                // Drag preview
                TaskDragPreview(task: task)
            }
    }
}

// MARK: - Task Drag Preview

struct TaskDragPreview: View {
    let task: TaskItem

    private var priorityColor: Color {
        switch task.starRating {
        case 3: return Theme.Colors.error
        case 2: return Theme.Colors.xp
        default: return Theme.Colors.aiBlue
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            SwiftUI.Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)

            Text(task.title)
                .font(Theme.Typography.callout)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Capsule()
                .fill(priorityColor.opacity(0.9))
                .shadow(color: priorityColor.opacity(0.5), radius: 8)
        )
    }
}

// MARK: - Drop Zone Modifier

struct CalendarDropZoneModifier: ViewModifier {
    let targetTime: Date
    let onDrop: (UUID, Date) -> Void

    @State private var isTargeted = false

    func body(content: Content) -> some View {
        content
            .background {
                if isTargeted {
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                .fill(Theme.Colors.accent.opacity(0.1))
                        )
                }
            }
            .dropDestination(for: TaskTransferID.self) { items, _ in
                guard let transferID = items.first else { return false }
                onDrop(transferID.id, targetTime)
                return true
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTargeted = targeted
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func draggableTask(_ task: TaskItem) -> some View {
        modifier(DraggableTaskModifier(task: task))
    }

    func calendarDropZone(targetTime: Date, onDrop: @escaping (UUID, Date) -> Void) -> some View {
        modifier(CalendarDropZoneModifier(targetTime: targetTime, onDrop: onDrop))
    }
}

// MARK: - Preview

#Preview {
    RescheduleConfirmationSheet(
        task: TaskItem(title: "Team meeting discussion", userId: UUID()),
        originalTime: Date(),
        newTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
        onConfirm: { _ in },
        onCancel: {}
    )
}
