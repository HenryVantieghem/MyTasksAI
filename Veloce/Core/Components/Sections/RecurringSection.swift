//
//  RecurringSection.swift
//  MyTasksAI
//
//  Recurring task configuration UI
//  Daily, Weekdays, Weekly, Biweekly, Monthly, Custom
//

import SwiftUI

// MARK: - Recurring Type Extended
enum RecurringTypeExtended: String, CaseIterable, Codable, Sendable {
    case once = "once"
    case daily = "daily"
    case weekdays = "weekdays"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .once: return "Once"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekly: return "Weekly"
        case .biweekly: return "Biweekly"
        case .monthly: return "Monthly"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .once: return "1.circle"
        case .daily: return "arrow.clockwise"
        case .weekdays: return "briefcase"
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar"
        case .monthly: return "calendar.badge.plus"
        case .custom: return "gearshape"
        }
    }

    var shortLabel: String {
        switch self {
        case .once: return "Once"
        case .daily: return "Daily"
        case .weekdays: return "M-F"
        case .weekly: return "Weekly"
        case .biweekly: return "2 Weeks"
        case .monthly: return "Monthly"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Recurring Section
struct RecurringSection: View {
    @Binding var selectedType: RecurringTypeExtended
    @Binding var customDays: Set<Int>  // 0-6 for Sun-Sat
    @Binding var endDate: Date?
    let onChanged: () -> Void

    @State private var showEndDatePicker = false

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let accentColor = Theme.Colors.aiPurple

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            headerView

            // Quick options (scrollable pills)
            recurringTypePills

            // Custom days picker (shown when custom selected)
            if selectedType == .custom {
                customDaysPicker
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // End date option (shown when not "once")
            if selectedType != .once {
                endDateSection
                    .transition(.opacity)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
        .animation(.spring(response: 0.3), value: selectedType)
        .animation(.spring(response: 0.3), value: endDate != nil)
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "repeat")
                    .font(.system(size: 14))
                    .foregroundStyle(accentColor)

                Text("REPEAT")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            if selectedType != .once {
                Text(selectedType.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(accentColor)
            }
        }
    }

    // MARK: - Type Pills
    private var recurringTypePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(RecurringTypeExtended.allCases, id: \.self) { type in
                    recurringPill(type: type)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func recurringPill(type: RecurringTypeExtended) -> some View {
        let isSelected = selectedType == type

        return Button {
            selectedType = type
            onChanged()
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12))
                Text(type.shortLabel)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? accentColor : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Days Picker
    private var customDaysPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Repeat on:")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    dayButton(day: day)
                }
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private func dayButton(day: Int) -> some View {
        let isSelected = customDays.contains(day)

        return Button {
            if isSelected {
                customDays.remove(day)
            } else {
                customDays.insert(day)
            }
            onChanged()
            HapticsService.shared.selectionFeedback()
        } label: {
            Text(dayLabels[day])
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 38, height: 38)
                .background(
                    SwiftUI.Circle()
                        .fill(isSelected ? accentColor : Color.white.opacity(0.08))
                )
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - End Date Section
    private var endDateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Toggle(isOn: Binding(
                get: { endDate != nil },
                set: { newValue in
                    if newValue {
                        endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                    } else {
                        endDate = nil
                    }
                    onChanged()
                }
            )) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.minus")
                        .font(.system(size: 12))
                    Text("Set end date")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.7))
            }
            .tint(accentColor)

            if let endDate, showEndDatePicker || true {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { endDate },
                        set: { self.endDate = $0; onChanged() }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .colorScheme(.dark)
                .tint(accentColor)
                .labelsHidden()
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }
}

// MARK: - Recurring Badge (for task cards)
struct RecurringBadge: View {
    let type: RecurringTypeExtended

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat")
                .font(.system(size: 9))
            Text(type.shortLabel)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(Theme.Colors.aiPurple)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Theme.Colors.aiPurple.opacity(0.15))
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        VStack(spacing: 32) {
            RecurringSection(
                selectedType: .constant(.weekly),
                customDays: .constant([1, 3, 5]), // Mon, Wed, Fri
                endDate: .constant(nil),
                onChanged: { }
            )

            RecurringBadge(type: .daily)

            RecurringBadge(type: .custom)
        }
        .padding()
    }
}
