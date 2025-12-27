//
//  CalendarSchedulingSheet.swift
//  MyTasksAI
//
//  Full calendar scheduling modal with date/time pickers
//  Creates EventKit events and saves to task
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - Calendar Scheduling Sheet
struct CalendarSchedulingSheet: View {
    let task: TaskItem
    let onScheduled: ((Date, Int) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var calendarService = CalendarService.shared
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var selectedDuration: Int = 30
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var existingEvents: [EKEvent] = []
    @State private var showSuccess = false

    private let durationPresets = [15, 30, 45, 60, 90, 120]

    init(task: TaskItem, onScheduled: ((Date, Int) -> Void)? = nil) {
        self.task = task
        self.onScheduled = onScheduled
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background
                    .ignoresSafeArea()

                if calendarService.isAuthorized {
                    schedulingContent
                } else {
                    permissionRequestView
                }
            }
            .navigationTitle("Schedule Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
        .task {
            // Default duration to AI estimate
            selectedDuration = task.estimatedMinutes ?? 30

            // Ensure calendars are loaded
            if calendarService.isAuthorized {
                await calendarService.loadCalendars()
            }

            // Load existing events for preview
            await loadEventsForSelectedDate()
        }
        .onChange(of: selectedDate) { _, _ in
            Task {
                await loadEventsForSelectedDate()
            }
        }
    }

    // MARK: - Permission Request View
    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(Theme.Colors.aiPurple)

            Text("Calendar Access Required")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text("Allow access to add this task to your calendar and see your availability.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await calendarService.requestAccess()
                }
            } label: {
                Text("Allow Calendar Access")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Theme.Colors.aiPurple)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
    }

    // MARK: - Scheduling Content
    private var schedulingContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Task header
                taskHeader

                // Date picker
                dateSection

                // Time picker
                timeSection

                // Duration selector
                durationSection

                // Timeline preview
                timelinePreview

                // Confirm button
                confirmButton
            }
            .padding(Theme.Spacing.screenPadding)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Task Header
    private var taskHeader: some View {
        HStack(spacing: 12) {
            // Task type color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(task.taskType.color)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let estimate = task.estimatedMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("AI suggests \(estimate) min")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Date Section
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Date", systemImage: "calendar")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            DatePicker(
                "",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .colorScheme(.dark)
            .tint(Theme.Colors.aiCyan)
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }

    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Time", systemImage: "clock")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .colorScheme(.dark)
            .labelsHidden()
            .frame(height: 120)
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }

    // MARK: - Duration Section
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Duration", systemImage: "hourglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 10) {
                ForEach(durationPresets, id: \.self) { minutes in
                    durationPresetButton(minutes: minutes)
                }
            }
        }
    }

    private func durationPresetButton(minutes: Int) -> some View {
        let isSelected = selectedDuration == minutes
        let isAIRecommended = minutes == task.estimatedMinutes

        return Button {
            selectedDuration = minutes
            HapticsService.shared.selectionFeedback()
        } label: {
            VStack(spacing: 4) {
                if isAIRecommended {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
                Text(formatDuration(minutes))
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(isSelected ? Theme.Colors.aiPurple : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .stroke(
                        isAIRecommended && !isSelected
                            ? Theme.Colors.aiPurple.opacity(0.5)
                            : .clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }

    // MARK: - Timeline Preview
    private var timelinePreview: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Preview", systemImage: "eye")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            MiniTimelinePreview(
                scheduledDate: combinedDateTime,
                duration: selectedDuration,
                existingEvents: existingEvents
            )
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.white.opacity(0.03))
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }

    // MARK: - Confirm Button
    private var confirmButton: some View {
        Button {
            Task {
                await scheduleTask()
            }
        } label: {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add to Calendar")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 10)
        }
        .disabled(isCreating)
    }

    // MARK: - Helpers

    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        return calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) ?? selectedDate
    }

    private func loadEventsForSelectedDate() async {
        guard calendarService.isAuthorized else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        _ = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate

        // Use CalendarService's eventStore to fetch events
        // This is a simplified version - in production you'd add a method to CalendarService
        existingEvents = []
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.success.opacity(0.2))
                        .frame(width: 100, height: 100)

                    SwiftUI.Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 70, height: 70)

                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Added to Calendar")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Text(combinedDateTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func scheduleTask() async {
        isCreating = true
        defer { isCreating = false }

        do {
            let scheduledTime = combinedDateTime

            // Update task
            task.scheduledTime = scheduledTime
            task.duration = selectedDuration
            task.updatedAt = Date()

            // Create calendar event
            if calendarService.isAuthorized {
                let eventId = try await calendarService.createEvent(
                    for: task,
                    at: scheduledTime,
                    duration: selectedDuration
                )
                task.calendarEventId = eventId
            }

            try modelContext.save()

            // Callback
            onScheduled?(scheduledTime, selectedDuration)

            HapticsService.shared.celebration()

            // Show success then dismiss
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showSuccess = true
            }

            try? await Task.sleep(for: .seconds(1.2))
            dismiss()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticsService.shared.error()
        }
    }
}

// MARK: - Mini Timeline Preview

struct MiniTimelinePreview: View {
    let scheduledDate: Date
    let duration: Int
    let existingEvents: [EKEvent]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background with hour lines
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { hour in
                        HStack(spacing: 8) {
                            Text(hourLabel(for: hour))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 40, alignment: .trailing)

                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                        }
                        if hour < 3 {
                            Spacer()
                        }
                    }
                }

                // Scheduled task block
                let taskBlock = RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.Colors.aiPurple.opacity(0.3))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.Colors.aiPurple, lineWidth: 1)
                    }
                    .frame(width: geometry.size.width - 60, height: blockHeight(for: duration, in: geometry.size.height))
                    .offset(x: 52, y: blockOffset(in: geometry.size.height))

                taskBlock
            }
        }
        .padding(Theme.Spacing.sm)
    }

    private func hourLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledDate) + index - 1
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: scheduledDate) {
            return formatter.string(from: date).lowercased()
        }
        return ""
    }

    private func blockHeight(for duration: Int, in totalHeight: CGFloat) -> CGFloat {
        let hoursShown: CGFloat = 3
        let minutesPerHour: CGFloat = 60
        let heightPerMinute = totalHeight / (hoursShown * minutesPerHour)
        return CGFloat(duration) * heightPerMinute
    }

    private func blockOffset(in totalHeight: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: scheduledDate)
        let heightPerMinute = totalHeight / (3 * 60)
        return (totalHeight / 3) + CGFloat(minute) * heightPerMinute
    }
}

// MARK: - Preview
#Preview {
    CalendarSchedulingSheet(
        task: {
            let task = TaskItem(title: "Complete the quarterly report")
            task.estimatedMinutes = 45
            return task
        }()
    )
}
