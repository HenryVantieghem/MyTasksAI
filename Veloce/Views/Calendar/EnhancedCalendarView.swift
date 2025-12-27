//
//  EnhancedCalendarView.swift
//  Veloce
//
//  Premium Calendar - Week-centric Visual Planner
//  Glass effects, task indicators, and connected time slots
//

import SwiftUI
import SwiftData

// MARK: - Enhanced Calendar View

/// Main calendar entry point - delegates to PremiumCalendarView
struct EnhancedCalendarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        PremiumCalendarView(viewModel: viewModel)
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EnhancedCalendarView(viewModel: CalendarViewModel())
    }
}
