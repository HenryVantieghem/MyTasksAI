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
