//
//  BlockingScheduleCreatorView.swift
//  Veloce
//
//  Create and edit app blocking schedules
//  Set time ranges, days, and apps to block
//

import SwiftUI
import FamilyControls

// MARK: - Blocking Schedule Creator View

struct BlockingScheduleCreatorView: View {
    @State private var scheduleName = ""
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedDays: Set<ScheduleWeekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var showAppPicker = false
    @State private var selectedApps = FamilyActivitySelection()
    @State private var isAllDay = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                scheduleHeader

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Schedule name
                        nameSection

                        // Time range
                        timeSection

                        // Days selection
                        daysSection

                        // Apps to block
                        appsSection
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, 120)
                }

                // Save button
                saveButton
            }
        }
        .preferredColorScheme(.dark)
        .familyActivityPicker(isPresented: $showAppPicker, selection: $selectedApps)
    }

    // MARK: - Header

    private var scheduleHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .dynamicTypeFont(base: 16, weight: .medium)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Text("New Schedule")
                .dynamicTypeFont(base: 17, weight: .semibold)
                .foregroundStyle(.white)

            Spacer()

            // Invisible balance
            Text("Cancel")
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Schedule Name")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.7))

            TextField("e.g., Morning Focus", text: $scheduleName)
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(.white)
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Time")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Toggle("All Day", isOn: $isAllDay)
                    .labelsHidden()
                    .tint(Theme.Colors.aiCyan)

                Text("All Day")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(.white.opacity(0.7))
            }

            if !isAllDay {
                HStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("From")
                            .dynamicTypeFont(base: 12, weight: .medium)
                            .foregroundStyle(.white.opacity(0.5))

                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .accentColor(Theme.Colors.aiCyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("To")
                            .dynamicTypeFont(base: 12, weight: .medium)
                            .foregroundStyle(.white.opacity(0.5))

                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .accentColor(Theme.Colors.aiCyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }
                }
            }
        }
    }

    // MARK: - Days Section

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Days")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.7))

            // Day buttons
            HStack(spacing: 8) {
                ForEach(ScheduleWeekday.allCases, id: \.self) { day in
                    dayButton(day)
                }
            }

            // Quick select
            HStack(spacing: Theme.Spacing.sm) {
                quickSelectButton("Weekdays") {
                    selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                }

                quickSelectButton("Weekends") {
                    selectedDays = [.saturday, .sunday]
                }

                quickSelectButton("Every Day") {
                    selectedDays = Set(ScheduleWeekday.allCases)
                }
            }
        }
    }

    private func dayButton(_ day: ScheduleWeekday) -> some View {
        let isSelected = selectedDays.contains(day)

        return Button {
            if isSelected {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
        } label: {
            Text(day.shortName)
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(isSelected ? Theme.Colors.aiCyan : Color.white.opacity(0.1))
                }
                .overlay {
                    if !isSelected {
                        Circle()
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    }
                }
        }
    }

    private func quickSelectButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .dynamicTypeFont(base: 12, weight: .medium)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
        }
    }

    // MARK: - Apps Section

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Apps to Block")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.7))

            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .dynamicTypeFont(base: 20)
                        .foregroundStyle(Theme.Colors.aiCyan)

                    Text(selectedApps.applicationTokens.isEmpty ? "Select Apps" : "\(selectedApps.applicationTokens.count) apps selected")
                        .dynamicTypeFont(base: 16, weight: .medium)
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(Theme.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.Colors.aiCyan.opacity(0.3), lineWidth: 1)
                }
            }

            // App group shortcuts
            VStack(spacing: Theme.Spacing.sm) {
                Text("Or use a group")
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(.white.opacity(0.5))

                HStack(spacing: Theme.Spacing.sm) {
                    appGroupChip(name: "Social Media", color: .pink)
                    appGroupChip(name: "Entertainment", color: .purple)
                    appGroupChip(name: "Games", color: .orange)
                }
            }
        }
    }

    private func appGroupChip(name: String, color: Color) -> some View {
        Button {
            // Would select the app group
        } label: {
            Text(name)
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(color.opacity(0.3))
                }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(.white.opacity(0.1))

            Button {
                saveSchedule()
            } label: {
                Text("Save Schedule")
                    .dynamicTypeFont(base: 17, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.aiCyan, Theme.Colors.aiBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
            }
            .disabled(scheduleName.isEmpty || selectedDays.isEmpty)
            .opacity(scheduleName.isEmpty || selectedDays.isEmpty ? 0.5 : 1)
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func saveSchedule() {
        // Would save to persistence
        HapticsService.shared.notification(.success)
        dismiss()
    }
}

// MARK: - Schedule Weekday (renamed to avoid conflict with BrainDumpViewModel.Weekday)

enum ScheduleWeekday: String, CaseIterable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var shortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    var fullName: String {
        rawValue.capitalized
    }
}

// MARK: - Preview

#Preview {
    BlockingScheduleCreatorView()
}
