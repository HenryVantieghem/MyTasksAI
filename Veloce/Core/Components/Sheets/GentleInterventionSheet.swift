//
//  GentleInterventionSheet.swift
//  MyTasksAI
//
//  Gentle Intervention - Anti-Procrastination Detection
//  Compassionate nudges for tasks rescheduled 3+ times
//

import SwiftUI

struct GentleInterventionSheet: View {
    let task: TaskItem
    let onReschedule: () -> Void
    let onBreakDown: () -> Void
    let onRemove: () -> Void
    let onDismiss: () -> Void

    @State private var selectedBlocker: TaskBlocker?
    @State private var showBlockerResponse = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(.white.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Task info
                    taskInfoCard

                    // Blocker identifier
                    if selectedBlocker == nil {
                        BlockerIdentifier(selectedBlocker: $selectedBlocker)
                            .onChange(of: selectedBlocker) { _, newValue in
                                if newValue != nil {
                                    withAnimation(.spring(response: 0.4).delay(0.2)) {
                                        showBlockerResponse = true
                                    }
                                }
                            }
                    }

                    // Blocker response
                    if let blocker = selectedBlocker, showBlockerResponse {
                        blockerResponseCard(for: blocker)
                    }

                    // Action buttons
                    actionButtons
                }
                .padding(24)
            }
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.1))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Gentle icon
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6").opacity(0.3), Color(hex: "06B6D4").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "heart.fill")
                    .dynamicTypeFont(base: 28)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6"), Color(hex: "06B6D4")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 4) {
                Text("Let's talk about this task")
                    .dynamicTypeFont(base: 20, weight: .semibold)
                    .foregroundStyle(.white)

                Text("It's been rescheduled a few times. That's okay—let's figure out what's going on.")
                    .dynamicTypeFont(base: 15)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Task Info Card

    private var taskInfoCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(taskColor)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .dynamicTypeFont(base: 16, weight: .medium)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let times = task.timesRescheduled, times > 0 {
                        Label("Rescheduled \(times)x", systemImage: "arrow.clockwise")
                            .dynamicTypeFont(base: 12)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var taskColor: Color {
        switch task.taskType {
        case .create: return Color(hex: "8B5CF6")
        case .communicate: return Color(hex: "3B82F6")
        case .consume: return Color(hex: "06B6D4")
        case .coordinate: return Color(hex: "F56B6B")
        }
    }

    // MARK: - Blocker Response

    private func blockerResponseCard(for blocker: TaskBlocker) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Color(hex: "06B6D4"))

                Text("Here's a thought...")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(blocker.suggestion)
                .dynamicTypeFont(base: 15)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "06B6D4").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "06B6D4").opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Break it down
            Button {
                HapticsService.shared.impact(.medium)
                onBreakDown()
            } label: {
                HStack {
                    Image(systemName: "rectangle.split.3x1")
                    Text("Break it into smaller steps")
                }
                .dynamicTypeFont(base: 16, weight: .semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "3B82F6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Reschedule
            Button {
                HapticsService.shared.selectionFeedback()
                onReschedule()
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                    Text("Reschedule to another day")
                }
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Remove
            Button {
                HapticsService.shared.selectionFeedback()
                onRemove()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Remove this task")
                }
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            // Keep as is
            Button {
                onDismiss()
            } label: {
                Text("Keep it for now")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    GentleInterventionSheet(
        task: {
            let t = TaskItem(title: "Finish quarterly report")
            t.timesRescheduled = 4
            t.taskTypeRaw = TaskType.create.rawValue
            return t
        }(),
        onReschedule: {},
        onBreakDown: {},
        onRemove: {},
        onDismiss: {}
    )
}
