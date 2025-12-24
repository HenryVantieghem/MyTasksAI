//
//  CustomTimePicker.swift
//  Veloce
//
//  Custom time picker sheet for focus sessions
//  Wheel picker with presets and custom duration
//

import SwiftUI

// MARK: - Custom Time Picker Sheet

struct CustomTimePickerSheet: View {
    @Binding var selectedMinutes: Int
    @Binding var selectedMode: FocusTimerMode
    let onStart: (Int) -> Void

    @State private var hours: Int = 0
    @State private var minutes: Int = 25

    @Environment(\.dismiss) private var dismiss

    // Quick presets
    private let presets: [(String, Int)] = [
        ("15 min", 15),
        ("30 min", 30),
        ("45 min", 45),
        ("1 hour", 60),
        ("1.5 hours", 90),
        ("2 hours", 120)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.04)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header description
                    Text("Set your focus duration")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 8)

                    // Wheel picker
                    wheelPicker

                    // Total duration display
                    totalDurationDisplay

                    // Quick presets
                    presetButtons

                    Spacer()

                    // Start button
                    startButton
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
            }
            .navigationTitle("Custom Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .onAppear {
            // Initialize from selected minutes
            hours = selectedMinutes / 60
            minutes = selectedMinutes % 60
            if minutes == 0 && hours == 0 {
                minutes = 25 // Default
            }
        }
    }

    // MARK: - Wheel Picker

    private var wheelPicker: some View {
        HStack(spacing: 0) {
            // Hours picker
            Picker("Hours", selection: $hours) {
                ForEach(0..<5) { h in
                    Text("\(h)")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)

            Text("h")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            // Minutes picker
            Picker("Minutes", selection: $minutes) {
                ForEach(0..<60) { m in
                    Text(String(format: "%02d", m))
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)

            Text("m")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(height: 150)
        .padding(.horizontal, 24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
    }

    // MARK: - Total Duration Display

    private var totalDurationDisplay: some View {
        let totalMinutes = hours * 60 + minutes

        return HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.aiAmber)

            Text(formatDuration(totalMinutes))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            if totalMinutes >= 60 {
                Text("(\(totalMinutes) minutes)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background {
            Capsule()
                .fill(Theme.Colors.aiAmber.opacity(0.15))
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else if minutes == 60 {
            return "1 hour"
        } else if minutes % 60 == 0 {
            return "\(minutes / 60) hours"
        } else {
            let h = minutes / 60
            let m = minutes % 60
            return "\(h)h \(m)m"
        }
    }

    // MARK: - Preset Buttons

    private var presetButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(presets, id: \.1) { preset in
                    let isSelected = (hours * 60 + minutes) == preset.1

                    Button {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            hours = preset.1 / 60
                            minutes = preset.1 % 60
                        }
                    } label: {
                        Text(preset.0)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Theme.Colors.aiAmber.opacity(0.3) : Color.white.opacity(0.05))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                isSelected ? Theme.Colors.aiAmber.opacity(0.5) : Color.white.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        let totalMinutes = hours * 60 + minutes
        let isValid = totalMinutes >= 1

        return Button {
            guard isValid else { return }
            HapticsService.shared.impact()
            selectedMinutes = totalMinutes
            selectedMode = .custom
            onStart(totalMinutes)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Start \(formatDuration(totalMinutes)) Focus")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isValid
                            ? LinearGradient(
                                colors: [Theme.Colors.aiAmber, Theme.Colors.aiOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
            }
            .shadow(
                color: isValid ? Theme.Colors.aiAmber.opacity(0.4) : Color.clear,
                radius: 16,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .disabled(!isValid)
        .padding(.bottom, 16)
    }
}

// MARK: - Break Duration Picker

struct BreakDurationPicker: View {
    @Binding var breakMinutes: Int
    @Environment(\.dismiss) private var dismiss

    private let options = [3, 5, 10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.04)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("How long do you want to rest?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 8)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(options, id: \.self) { mins in
                            let isSelected = breakMinutes == mins

                            Button {
                                HapticsService.shared.selectionFeedback()
                                breakMinutes = mins
                                dismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    Text("\(mins)")
                                        .font(.system(size: 32, weight: .light, design: .rounded))
                                        .foregroundStyle(isSelected ? Color(red: 0.22, green: 0.88, blue: 0.58) : .white)

                                    Text("minutes")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            isSelected
                                                ? Color(red: 0.22, green: 0.88, blue: 0.58).opacity(0.15)
                                                : Color.white.opacity(0.05)
                                        )
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    isSelected
                                                        ? Color(red: 0.22, green: 0.88, blue: 0.58).opacity(0.5)
                                                        : Color.white.opacity(0.1),
                                                    lineWidth: 1
                                                )
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)

                    Spacer()
                }
            }
            .navigationTitle("Break Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        breakMinutes = 0
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview("Custom Time Picker") {
    CustomTimePickerSheet(
        selectedMinutes: .constant(25),
        selectedMode: .constant(.custom),
        onStart: { _ in }
    )
}

#Preview("Break Duration Picker") {
    BreakDurationPicker(breakMinutes: .constant(5))
}
