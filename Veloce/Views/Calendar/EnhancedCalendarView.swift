//
//  EnhancedCalendarView.swift
//  Veloce
//
//  Calendar Entry Point - iOS 26 Liquid Glass Design
//  Delegates to LiquidGlassCalendarView with proper HIG compliance
//

import SwiftUI
import SwiftData

// MARK: - Enhanced Calendar View

/// Main calendar entry point - uses iOS 26 Liquid Glass calendar
struct EnhancedCalendarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        LiquidGlassCalendarView(viewModel: viewModel)
    }
}

// MARK: - Calendar Date Picker Sheet (Updated for iOS 26)

struct CalendarDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EnhancedCalendarView(viewModel: CalendarViewModel())
}
