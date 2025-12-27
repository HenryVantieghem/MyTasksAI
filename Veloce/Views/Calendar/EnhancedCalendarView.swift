//
//  EnhancedCalendarView.swift
//  Veloce
//
//  Notion Calendar-Inspired Visual Planner - Entry Point
//  Clean, minimal calendar with visual timeline,
//  swipe navigation, and Apple Calendar integration
//

import SwiftUI
import SwiftData

// MARK: - Enhanced Calendar View

/// Main calendar entry point - delegates to NotionCalendarView
struct EnhancedCalendarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        NotionCalendarView(viewModel: viewModel)
    }
}

// MARK: - Calendar Date Picker Sheet

struct CalendarDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Select Date")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.aiCyan)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .tint(Theme.Colors.aiCyan)
                .padding(.horizontal, 8)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    }
}

// MARK: - Calendar Task Preview Sheet

struct CalendarTaskPreviewSheet: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with color accent
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(taskColor)
                    .frame(width: 4, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        Label(task.taskType.rawValue, systemImage: task.taskType.defaultIcon)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(taskColor)

                        if let minutes = task.estimatedMinutes {
                            Text("•")
                                .foregroundStyle(.white.opacity(0.3))
                            Text("\(minutes) min")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()
                .background(.white.opacity(0.1))

            // Time info
            if let scheduledTime = task.scheduledTime {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(scheduledTime.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            // Notes if any
            if let notes = task.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(notes)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Spacer()
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    }
}

// MARK: - Scheduled Task Card (Reused Component)

struct ScheduledTaskCard: View {
    let task: TaskItem
    let onTap: () -> Void

    @State private var isPressed = false

    private var taskColor: Color {
        task.taskType.tiimoColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Color indicator with glow
                RoundedRectangle(cornerRadius: 4)
                    .fill(taskColor)
                    .frame(width: 4, height: 40)
                    .shadow(color: taskColor.opacity(0.5), radius: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let time = task.scheduledTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(time.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Points badge
                if let minutes = task.estimatedMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.Colors.aiGold)
                        Text("+\(max(10, minutes / 3))")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.aiGold.opacity(0.15))
                    )
                }
            }
            .padding(14)
            .frame(width: 220)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        HapticsService.shared.impact()
                        isPressed = true
                    }
                }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EnhancedCalendarView(viewModel: CalendarViewModel())
    }
}
