//
//  TimelineQuickAddView.swift
//  Veloce
//
//  Timeline Quick Add View - Create tasks directly from calendar time slots
//  Minimal input with AI enhancement
//

import SwiftUI

// MARK: - Timeline Quick Add View

struct TimelineQuickAddView: View {
    let selectedTime: Date
    let onAdd: (String, Date, Int) -> Void
    let onCancel: () -> Void

    @State private var taskTitle: String = ""
    @State private var duration: Int = 30
    @FocusState private var isFocused: Bool

    private let durationOptions = [15, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Text("Quick Add")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Button {
                    HapticsService.shared.lightImpact()
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            // Time display
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiBlue)

                Text(selectedTime.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()
            }

            // Task input
            HStack(spacing: Theme.Spacing.sm) {
                TextField("What needs to be done?", text: $taskTitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !taskTitle.isEmpty {
                            addTask()
                        }
                    }

                // AI sparkle
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Theme.Colors.glassBackground)
            )

            // Duration picker
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Duration")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            DurationChip(
                                minutes: minutes,
                                isSelected: duration == minutes,
                                onTap: {
                                    HapticsService.shared.selectionFeedback()
                                    duration = minutes
                                }
                            )
                        }
                    }
                }
            }

            // Add button
            Button {
                addTask()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to Schedule")
                }
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .fill(
                            taskTitle.isEmpty
                                ? AnyShapeStyle(Theme.Colors.textTertiary)
                                : AnyShapeStyle(Theme.Colors.accentGradient)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(taskTitle.isEmpty)
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .onAppear {
            isFocused = true
        }
    }

    private func addTask() {
        guard !taskTitle.isEmpty else { return }
        HapticsService.shared.success()
        onAdd(taskTitle, selectedTime, duration)
    }
}

// MARK: - Duration Chip

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var displayText: String {
        if minutes < 60 {
            return "\(minutes)m"
        } else if minutes == 60 {
            return "1h"
        } else {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(displayText)
                .font(Theme.Typography.caption1)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.accent : Theme.Colors.glassBackground)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced Quick Add View (with More Details option)

struct EnhancedQuickAddView: View {
    let selectedTime: Date
    let onAdd: (String, Date, Int) -> Void
    let onCancel: () -> Void
    let onExpandToDetail: () -> Void

    @State private var taskTitle: String = ""
    @State private var duration: Int = 30
    @FocusState private var isFocused: Bool

    private let durationOptions = [15, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Quick Add")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    HapticsService.shared.lightImpact()
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            // Time display
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiBlue)

                Text(selectedTime.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
            }

            // Task input
            HStack(spacing: 10) {
                TextField("What needs to be done?", text: $taskTitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !taskTitle.isEmpty {
                            addTask()
                        }
                    }

                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    }
            )

            // Duration picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            DurationChip(
                                minutes: minutes,
                                isSelected: duration == minutes,
                                onTap: {
                                    HapticsService.shared.selectionFeedback()
                                    duration = minutes
                                }
                            )
                        }
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                // More Details button
                Button {
                    HapticsService.shared.selectionFeedback()
                    onExpandToDetail()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14))
                        Text("More details")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
                            }
                    }
                }
                .buttonStyle(.plain)

                // Add button
                Button {
                    addTask()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                taskTitle.isEmpty
                                    ? AnyShapeStyle(Color.white.opacity(0.15))
                                    : AnyShapeStyle(
                                        LinearGradient(
                                            colors: [
                                                Theme.Colors.aiPurple,
                                                Theme.Colors.aiBlue
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .shadow(
                        color: taskTitle.isEmpty ? .clear : Theme.Colors.aiPurple.opacity(0.3),
                        radius: 8,
                        y: 4
                    )
                }
                .buttonStyle(.plain)
                .disabled(taskTitle.isEmpty)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .onAppear {
            isFocused = true
        }
    }

    private func addTask() {
        guard !taskTitle.isEmpty else { return }
        HapticsService.shared.success()
        onAdd(taskTitle, selectedTime, duration)
    }
}

// MARK: - Timeline Quick Add Sheet

struct TimelineQuickAddSheet: View {
    let selectedTime: Date
    let onAdd: (String, Date, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TimelineQuickAddView(
            selectedTime: selectedTime,
            onAdd: { title, time, duration in
                onAdd(title, time, duration)
                dismiss()
            },
            onCancel: {
                dismiss()
            }
        )
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VoidBackground.calendar

        VStack {
            Spacer()

            TimelineQuickAddView(
                selectedTime: Date(),
                onAdd: { _, _, _ in },
                onCancel: {}
            )
            .padding()
        }
    }
}
