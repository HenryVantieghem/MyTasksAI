//
//  TaskInputChips.swift
//  Veloce
//
//  Chip components for the Floating Island Task Input Bar
//  Priority, Date, Category, Duration chips with beautiful animations
//

import SwiftUI

// MARK: - Priority Chip View

struct PriorityChipView: View {
    @Binding var priority: InputTaskPriority
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 4) {
                // Stars display
                HStack(spacing: 2) {
                    ForEach(1...3, id: \.self) { index in
                        Image(systemName: index <= priority.rawValue ? "star.fill" : "star")
                            .dynamicTypeFont(base: 10, weight: .medium)
                            .foregroundStyle(index <= priority.rawValue ? priority.color : Color.white.opacity(0.3))
                    }
                }

                Image(systemName: "chevron.down")
                    .dynamicTypeFont(base: 8, weight: .bold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(priority.color.opacity(0.15))
                    .overlay {
                        Capsule()
                            .stroke(priority.color.opacity(0.3), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Priority: \(priority.label)")
        .accessibilityHint("Double tap to change priority")
        .popover(isPresented: $showPicker) {
            PriorityPickerPopover(selection: $priority)
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Priority Picker Popover

struct PriorityPickerPopover: View {
    @Binding var selection: InputTaskPriority
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            Text("Priority")
                .dynamicTypeFont(base: 13, weight: .semibold)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            ForEach(InputTaskPriority.allCases) { priority in
                Button {
                    selection = priority
                    HapticsService.shared.selectionFeedback()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        // Stars
                        HStack(spacing: 2) {
                            ForEach(1...3, id: \.self) { index in
                                Image(systemName: index <= priority.rawValue ? "star.fill" : "star")
                                    .dynamicTypeFont(base: 12, weight: .medium)
                                    .foregroundStyle(index <= priority.rawValue ? priority.color : Color.white.opacity(0.3))
                            }
                        }

                        Text(priority.label)
                            .dynamicTypeFont(base: 14, weight: .medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selection == priority {
                            Image(systemName: "checkmark")
                                .dynamicTypeFont(base: 12, weight: .bold)
                                .foregroundStyle(priority.color)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        if selection == priority {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(priority.color.opacity(0.1))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 180)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Date Chip View

struct DateChipView: View {
    let date: Date
    let time: Date?
    let onTap: () -> Void
    let onRemove: () -> Void

    private var displayText: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            if let time = time {
                return "Today \(timeString(time))"
            }
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            if let time = time {
                return "Tomorrow \(timeString(time))"
            }
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            if let time = time {
                return "\(formatter.string(from: date)) \(timeString(time))"
            }
            return formatter.string(from: date)
        }
    }

    private func timeString(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .dynamicTypeFont(base: 10, weight: .semibold)

                    Text(displayText)
                        .dynamicTypeFont(base: 12, weight: .medium)
                }
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .dynamicTypeFont(base: 8, weight: .bold)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Theme.Colors.aiBlue)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.Colors.aiBlue.opacity(0.15))
                .overlay {
                    Capsule()
                        .stroke(Theme.Colors.aiBlue.opacity(0.3), lineWidth: 0.5)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Date: \(displayText)")
        .accessibilityHint("Double tap to edit, or swipe to remove")
    }
}

// MARK: - Category Chip View

struct CategoryChipView: View {
    let category: InputTemplateCategory
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .dynamicTypeFont(base: 10, weight: .semibold)

            Text(category.displayName)
                .dynamicTypeFont(base: 12, weight: .medium)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .dynamicTypeFont(base: 8, weight: .bold)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(category.color.opacity(0.15))
                .overlay {
                    Capsule()
                        .stroke(category.color.opacity(0.3), lineWidth: 0.5)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Category: \(category.displayName)")
        .accessibilityHint("Swipe to remove")
    }
}

// MARK: - Duration Chip View

struct DurationChipView: View {
    let minutes: Int
    let onRemove: () -> Void

    private var displayText: String {
        if minutes < 60 {
            return "\(minutes)min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .dynamicTypeFont(base: 10, weight: .semibold)

            Text("~\(displayText)")
                .dynamicTypeFont(base: 12, weight: .medium)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .dynamicTypeFont(base: 8, weight: .bold)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Theme.Colors.aiGreen)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.Colors.aiGreen.opacity(0.15))
                .overlay {
                    Capsule()
                        .stroke(Theme.Colors.aiGreen.opacity(0.3), lineWidth: 0.5)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Duration: approximately \(displayText)")
        .accessibilityHint("Swipe to remove")
    }
}

// MARK: - Add Chip Button

struct AddChipButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsService.shared.selectionFeedback()
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 10, weight: .medium)

                Text(label)
                    .dynamicTypeFont(base: 11, weight: .medium)

                Image(systemName: "plus")
                    .dynamicTypeFont(base: 8, weight: .bold)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(label)")
        .accessibilityHint("Double tap to add")
    }
}

// MARK: - Inline Date Picker Sheet

struct InlineDatePickerSheet: View {
    @Binding var selectedDate: Date?
    @Binding var selectedTime: Date?
    let onDismiss: () -> Void

    @State private var tempDate: Date = Date()
    @State private var tempTime: Date = Date()
    @State private var includeTime = false

    private let quickOptions: [(String, String, Date)] = [
        ("Today", "sun.max", Date()),
        ("Tomorrow", "sunrise", Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
        ("This Weekend", "sparkles", nextWeekend()),
        ("Next Week", "calendar", Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Quick options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quickOptions, id: \.0) { option in
                            InputQuickDateButton(
                                title: option.0,
                                icon: option.1,
                                isSelected: isSameDay(tempDate, option.2),
                                action: {
                                    tempDate = option.2
                                    HapticsService.shared.selectionFeedback()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                Divider()
                    .padding(.horizontal)

                // Date picker
                DatePicker(
                    "Date",
                    selection: $tempDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)

                // Time toggle
                Toggle(isOn: $includeTime) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Add Time")
                    }
                }
                .tint(Theme.Colors.aiBlue)
                .padding(.horizontal)

                // Time picker (if enabled)
                if includeTime {
                    DatePicker(
                        "Time",
                        selection: $tempTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedDate = tempDate
                        selectedTime = includeTime ? tempTime : nil
                        HapticsService.shared.success()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.aiBlue)
                }
            }
        }
        .onAppear {
            if let date = selectedDate {
                tempDate = date
            }
            if let time = selectedTime {
                tempTime = time
                includeTime = true
            }
        }
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}

// Helper function
private func nextWeekend() -> Date {
    let calendar = Calendar.current
    let today = Date()
    let weekday = calendar.component(.weekday, from: today)

    // Calculate days until Saturday (weekday 7)
    let daysUntilSaturday = (7 - weekday + 7) % 7
    let daysToAdd = daysUntilSaturday == 0 ? 7 : daysUntilSaturday

    return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
}

// MARK: - Input Quick Date Button

struct InputQuickDateButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.aiBlue : Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .dynamicTypeFont(base: 18, weight: .medium)
                        .foregroundStyle(isSelected ? .white : .secondary)
                }

                Text(title)
                    .dynamicTypeFont(base: 11, weight: .medium)
                    .foregroundStyle(isSelected ? Theme.Colors.aiBlue : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    @Binding var selectedCategories: Set<InputTemplateCategory>
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(InputTemplateCategory.allCases) { category in
                    Button {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else if selectedCategories.count < 3 {
                            selectedCategories.insert(category)
                        }
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: category.icon)
                                    .dynamicTypeFont(base: 16, weight: .medium)
                                    .foregroundStyle(category.color)
                            }

                            Text(category.displayName)
                                .dynamicTypeFont(base: 16, weight: .medium)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark.circle.fill")
                                    .dynamicTypeFont(base: 22)
                                    .foregroundStyle(category.color)
                            } else {
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Priority Chip") {
    struct PreviewWrapper: View {
        @State private var priority: InputTaskPriority = .medium

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                PriorityChipView(priority: $priority)
            }
        }
    }
    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Date Chip") {
    ZStack {
        Color.black.ignoresSafeArea()
        DateChipView(
            date: Date(),
            time: Date(),
            onTap: {},
            onRemove: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Category Chip") {
    ZStack {
        Color.black.ignoresSafeArea()
        CategoryChipView(category: .work, onRemove: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Duration Chip") {
    ZStack {
        Color.black.ignoresSafeArea()
        DurationChipView(minutes: 45, onRemove: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Add Chip Button") {
    ZStack {
        Color.black.ignoresSafeArea()
        AddChipButton(icon: "calendar", label: "Date", action: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Chips Row") {
    struct PreviewWrapper: View {
        @State private var priority: InputTaskPriority = .high
        @State private var selectedDate: Date? = Date()
        @State private var selectedTime: Date? = Date()
        @State private var categories: Set<InputTemplateCategory> = [.work, .personal]

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        PriorityChipView(priority: $priority)

                        if let date = selectedDate {
                            DateChipView(
                                date: date,
                                time: selectedTime,
                                onTap: {},
                                onRemove: { selectedDate = nil }
                            )
                        }

                        ForEach(Array(categories), id: \.self) { category in
                            CategoryChipView(category: category) {
                                categories.remove(category)
                            }
                        }

                        AddChipButton(icon: "tag", label: "Tag", action: {})

                        DurationChipView(minutes: 30, onRemove: {})
                    }
                    .padding()
                }
            }
        }
    }
    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Date Picker Sheet") {
    struct PreviewWrapper: View {
        @State private var date: Date? = nil
        @State private var time: Date? = nil
        @State private var showSheet = true

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
            }
            .sheet(isPresented: $showSheet) {
                InlineDatePickerSheet(
                    selectedDate: $date,
                    selectedTime: $time,
                    onDismiss: { showSheet = false }
                )
            }
        }
    }
    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
