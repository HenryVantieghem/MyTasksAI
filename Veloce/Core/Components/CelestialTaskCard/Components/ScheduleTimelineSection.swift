//
//  ScheduleTimelineSection.swift
//  Veloce
//
//  Mini day timeline with quick schedule chips
//  Visual timeline with draggable task block
//

import SwiftUI

// MARK: - Schedule Timeline Section

struct ScheduleTimelineSection: View {
    @Binding var scheduledTime: Date?
    let taskTypeColor: Color
    let onTimeSelected: (Date?) -> Void

    @State private var showTimePicker = false

    private let quickOptions: [(String, Date?)] = {
        let calendar = Calendar.current
        let now = Date()

        // "Now" - current time
        let nowOption = ("Now", now)

        // "Later Today" - 2 hours from now or 5pm, whichever is later
        let twoHoursLater = calendar.date(byAdding: .hour, value: 2, to: now) ?? now
        var laterComponents = calendar.dateComponents([.year, .month, .day], from: now)
        laterComponents.hour = 17
        laterComponents.minute = 0
        let fivePM = calendar.date(from: laterComponents) ?? now
        let laterToday = max(twoHoursLater, fivePM)
        let laterOption = ("Later", laterToday)

        // "Tomorrow 9am"
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        tomorrowComponents.hour = 9
        tomorrowComponents.minute = 0
        let tomorrowNine = calendar.date(from: tomorrowComponents) ?? tomorrow
        let tomorrowOption = ("Tomorrow 9am", tomorrowNine)

        return [nowOption, laterOption, tomorrowOption]
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quick schedule chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickOptions, id: \.0) { option in
                        QuickScheduleChip(
                            label: option.0,
                            isSelected: isTimeMatch(option.1),
                            color: taskTypeColor
                        ) {
                            HapticsService.shared.selectionFeedback()
                            scheduledTime = option.1
                            onTimeSelected(option.1)
                        }
                    }

                    // Custom time picker
                    QuickScheduleChip(
                        label: "Pick...",
                        isSelected: false,
                        color: Theme.CelestialColors.starDim
                    ) {
                        showTimePicker = true
                    }
                }
            }

            // Mini day timeline
            MiniDayTimeline(
                scheduledTime: scheduledTime,
                taskTypeColor: taskTypeColor
            )

            // Current schedule display
            if let time = scheduledTime {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(taskTypeColor)

                    Text(formatDateTime(time))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.CelestialColors.starWhite)

                    Spacer()

                    // Clear button
                    Button(action: {
                        HapticsService.shared.selectionFeedback()
                        scheduledTime = nil
                        onTimeSelected(nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.CelestialColors.starDim)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(taskTypeColor.opacity(0.1))
                )
            }
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(
                selectedTime: $scheduledTime,
                taskTypeColor: taskTypeColor,
                onDismiss: {
                    showTimePicker = false
                    onTimeSelected(scheduledTime)
                }
            )
            .presentationDetents([.medium])
        }
    }

    private func isTimeMatch(_ time: Date?) -> Bool {
        guard let scheduled = scheduledTime, let check = time else { return false }
        // Match within 5 minutes
        return abs(scheduled.timeIntervalSince(check)) < 300
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else {
            formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Quick Schedule Chip

struct QuickScheduleChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Theme.CelestialColors.void : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mini Day Timeline

struct MiniDayTimeline: View {
    let scheduledTime: Date?
    let taskTypeColor: Color

    private let hours = [6, 9, 12, 15, 18, 21] // 6am, 9am, 12pm, 3pm, 6pm, 9pm

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.CelestialColors.nebulaDust)
                    .frame(height: 8)

                // Hour markers
                ForEach(hours, id: \.self) { hour in
                    Circle()
                        .fill(Theme.CelestialColors.starGhost)
                        .frame(width: 6, height: 6)
                        .offset(x: offsetFor(hour: hour, in: geometry.size.width) - 3)
                }

                // Current time indicator
                currentTimeIndicator(width: geometry.size.width)

                // Scheduled time indicator
                if let time = scheduledTime {
                    scheduledTimeIndicator(for: time, width: geometry.size.width)
                }
            }
        }
        .frame(height: 24)
    }

    private func offsetFor(hour: Int, in width: CGFloat) -> CGFloat {
        // Map 0-24 hours to 0-width
        let normalizedHour = CGFloat(hour) / 24.0
        return normalizedHour * width
    }

    private func currentTimeIndicator(width: CGFloat) -> some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        let totalMinutes = CGFloat(hour * 60 + minute)
        let dayMinutes: CGFloat = 24 * 60
        let offset = (totalMinutes / dayMinutes) * width

        return Circle()
            .fill(Theme.CelestialColors.plasmaCore)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(Theme.CelestialColors.plasmaCore.opacity(0.5), lineWidth: 2)
            )
            .offset(x: offset - 5)
    }

    private func scheduledTimeIndicator(for date: Date, width: CGFloat) -> some View {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        let totalMinutes = CGFloat(hour * 60 + minute)
        let dayMinutes: CGFloat = 24 * 60
        let offset = (totalMinutes / dayMinutes) * width

        return RoundedRectangle(cornerRadius: 4)
            .fill(taskTypeColor)
            .frame(width: 20, height: 14)
            .overlay(
                Image(systemName: "flag.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
            )
            .offset(x: offset - 10, y: 0)
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var selectedTime: Date?
    let taskTypeColor: Color
    let onDismiss: () -> Void

    @State private var pickerDate: Date = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    "Select time",
                    selection: $pickerDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(taskTypeColor)

                Spacer()
            }
            .padding()
            .background(Theme.CelestialColors.abyss.ignoresSafeArea())
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(Theme.CelestialColors.starDim)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedTime = pickerDate
                        onDismiss()
                    }
                    .foregroundColor(taskTypeColor)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            pickerDate = selectedTime ?? Date()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack {
            ScheduleTimelineSection(
                scheduledTime: .constant(Date()),
                taskTypeColor: Theme.TaskCardColors.create,
                onTimeSelected: { _ in }
            )
            .padding()
        }
    }
}
