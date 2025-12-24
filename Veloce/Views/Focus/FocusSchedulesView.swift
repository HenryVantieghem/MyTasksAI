//
//  FocusSchedulesView.swift
//  Veloce
//
//  Scheduled Focus Sessions - Opal-style automation
//  Automatically start focus sessions at scheduled times
//

import SwiftUI
import SwiftData

// MARK: - Focus Schedules View

struct FocusSchedulesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScheduledFocusSession.startHour) private var schedules: [ScheduledFocusSession]

    @State private var showCreateSheet = false
    @State private var selectedSchedule: ScheduledFocusSession?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                headerSection

                if schedules.isEmpty {
                    emptyStateView
                } else {
                    // Schedule Cards
                    schedulesList
                }

                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.top, Theme.Spacing.md)
        }
        .sheet(isPresented: $showCreateSheet) {
            ScheduleCreationSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedSchedule) { schedule in
            ScheduleCreationSheet(editingSchedule: schedule)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Schedules")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("Automate your focus sessions")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button {
                HapticsService.shared.impact()
                showCreateSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.aiAmber)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
                .frame(height: 60)

            // Icon
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.aiAmber.opacity(0.3),
                                Theme.Colors.aiAmber.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(Theme.Colors.aiAmber)
            }

            VStack(spacing: 8) {
                Text("No Schedules Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Create scheduled focus sessions to automatically block apps at specific times")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            Button {
                HapticsService.shared.impact()
                showCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Schedule")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background {
                    Capsule()
                        .fill(Theme.Colors.aiAmber)
                }
            }
            .buttonStyle(.plain)
            .shadow(color: Theme.Colors.aiAmber.opacity(0.4), radius: 12, y: 4)
        }
    }

    // MARK: - Schedules List

    private var schedulesList: some View {
        VStack(spacing: 12) {
            ForEach(schedules) { schedule in
                ScheduleCard(schedule: schedule) {
                    selectedSchedule = schedule
                } onToggle: { isEnabled in
                    schedule.isEnabled = isEnabled
                    schedule.updatedAt = Date()
                    try? modelContext.save()
                } onDelete: {
                    modelContext.delete(schedule)
                    try? modelContext.save()
                }
            }
        }
    }
}

// MARK: - Schedule Card

struct ScheduleCard: View {
    let schedule: ScheduledFocusSession
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Time
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.formattedStartTime)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(schedule.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { onToggle($0) }
                ))
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.aiAmber))
                .labelsHidden()
            }

            Divider()
                .background(.white.opacity(0.1))

            HStack {
                // Duration badge
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                    Text("\(schedule.durationMinutes) min")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(.white.opacity(0.1))
                }

                // Days badge (if recurring)
                if schedule.isRecurring {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                        Text(schedule.formattedRecurringDays)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(.white.opacity(0.1))
                    }
                }

                // Deep Focus badge
                if schedule.isDeepFocus {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                        Text("Deep Focus")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.aiAmber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.aiAmber.opacity(0.15))
                    }
                }

                Spacer()

                // Edit button
                Button {
                    HapticsService.shared.selectionFeedback()
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background {
                            SwiftUI.Circle()
                                .fill(.white.opacity(0.1))
                        }
                }
                .buttonStyle(.plain)

                // Delete button
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.error.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background {
                            SwiftUI.Circle()
                                .fill(Theme.Colors.error.opacity(0.1))
                        }
                }
                .buttonStyle(.plain)
            }

            // Next occurrence
            if let nextOccurrence = schedule.nextOccurrence {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                    Text("Next: \(nextOccurrence, format: .dateTime.weekday().hour().minute())")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Theme.Colors.aiAmber.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .opacity(schedule.isEnabled ? 1 : 0.6)
        .confirmationDialog("Delete Schedule?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                HapticsService.shared.impact()
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete \"\(schedule.title)\"")
        }
    }
}

// MARK: - Schedule Creation Sheet

struct ScheduleCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Edit mode
    var editingSchedule: ScheduledFocusSession?

    // Form state
    @State private var title: String = ""
    @State private var startTime: Date = Date()
    @State private var duration: Int = 25  // minutes
    @State private var isRecurring: Bool = false
    @State private var selectedDays: Set<Int> = []
    @State private var isDeepFocus: Bool = false

    private let durationOptions = [15, 25, 45, 60, 90, 120]
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        TextField("e.g., Morning Focus", text: $title)
                            .font(.system(size: 16))
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            }
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Start Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Time")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 120)
                            .clipped()
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duration")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(durationOptions, id: \.self) { mins in
                                    ScheduleDurationChip(
                                        minutes: mins,
                                        isSelected: duration == mins
                                    ) {
                                        HapticsService.shared.selectionFeedback()
                                        duration = mins
                                    }
                                }
                            }
                        }
                    }

                    // Recurring Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $isRecurring) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.Colors.aiAmber)
                                Text("Repeat")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.aiAmber))

                        if isRecurring {
                            // Day selector
                            HStack(spacing: 8) {
                                ForEach(0..<7, id: \.self) { day in
                                    ScheduleDayChip(
                                        day: dayNames[day],
                                        isSelected: selectedDays.contains(day)
                                    ) {
                                        HapticsService.shared.selectionFeedback()
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                }
                            }

                            // Quick select buttons
                            HStack(spacing: 10) {
                                ScheduleQuickDayButton(title: "Weekdays") {
                                    selectedDays = [1, 2, 3, 4, 5]
                                }
                                ScheduleQuickDayButton(title: "Weekends") {
                                    selectedDays = [0, 6]
                                }
                                ScheduleQuickDayButton(title: "Every day") {
                                    selectedDays = [0, 1, 2, 3, 4, 5, 6]
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isRecurring)

                    // Deep Focus Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isDeepFocus) {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.Colors.aiAmber)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Deep Focus")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Cannot be canceled once started")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.aiAmber))
                    }

                    Spacer()
                        .frame(height: 40)
                }
                .padding(Theme.Spacing.screenPadding)
            }
            .background(VoidBackground.focus)
            .navigationTitle(editingSchedule != nil ? "Edit Schedule" : "New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSchedule()
                        dismiss()
                    }
                    .disabled(title.isEmpty || (isRecurring && selectedDays.isEmpty))
                }
            }
        }
        .onAppear {
            if let schedule = editingSchedule {
                title = schedule.title
                startTime = schedule.startTime
                duration = schedule.durationMinutes
                isRecurring = schedule.isRecurring
                selectedDays = Set(schedule.recurringDays ?? [])
                isDeepFocus = schedule.isDeepFocus
            }
        }
    }

    private func saveSchedule() {
        if let schedule = editingSchedule {
            // Update existing
            schedule.title = title
            schedule.startTime = startTime
            schedule.startHour = Calendar.current.component(.hour, from: startTime)
            schedule.startMinute = Calendar.current.component(.minute, from: startTime)
            schedule.duration = duration * 60
            schedule.isRecurring = isRecurring
            schedule.recurringDays = isRecurring ? Array(selectedDays) : nil
            schedule.isDeepFocus = isDeepFocus
            schedule.updatedAt = Date()
        } else {
            // Create new
            let schedule = ScheduledFocusSession(
                title: title,
                startTime: startTime,
                duration: duration * 60,
                isRecurring: isRecurring,
                recurringDays: isRecurring ? Array(selectedDays) : nil,
                isDeepFocus: isDeepFocus
            )
            modelContext.insert(schedule)
        }

        try? modelContext.save()
        HapticsService.shared.success()
    }
}

// MARK: - Supporting Components

struct ScheduleDurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes) min")
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(isSelected ? Theme.Colors.aiAmber : .white.opacity(0.1))
                }
        }
        .buttonStyle(.plain)
    }
}

struct ScheduleDayChip: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .frame(width: 40, height: 40)
                .background {
                    SwiftUI.Circle()
                        .fill(isSelected ? Theme.Colors.aiAmber : .white.opacity(0.1))
                }
        }
        .buttonStyle(.plain)
    }
}

struct ScheduleQuickDayButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    FocusSchedulesView()
        .preferredColorScheme(.dark)
}
