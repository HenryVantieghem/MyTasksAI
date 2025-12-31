//
//  TimerPresetGrid.swift
//  Veloce
//
//  Beautiful preset duration grid for quick timer selection
//  Tiimo-inspired visual design with 5min to 8hr range
//

import SwiftUI

// MARK: - Timer Preset

struct TimerPreset: Identifiable, Equatable {
    let id = UUID()
    let minutes: Int
    let label: String
    let isExtended: Bool  // For 4h+ sessions

    static let allPresets: [TimerPreset] = [
        // Row 1: Quick focus
        TimerPreset(minutes: 5, label: "5m", isExtended: false),
        TimerPreset(minutes: 10, label: "10m", isExtended: false),
        TimerPreset(minutes: 15, label: "15m", isExtended: false),
        TimerPreset(minutes: 20, label: "20m", isExtended: false),

        // Row 2: Standard focus (Pomodoro-style)
        TimerPreset(minutes: 25, label: "25m", isExtended: false),
        TimerPreset(minutes: 30, label: "30m", isExtended: false),
        TimerPreset(minutes: 45, label: "45m", isExtended: false),
        TimerPreset(minutes: 60, label: "1h", isExtended: false),

        // Row 3: Deep work
        TimerPreset(minutes: 90, label: "90m", isExtended: false),
        TimerPreset(minutes: 120, label: "2h", isExtended: false),
        TimerPreset(minutes: 180, label: "3h", isExtended: false),
        TimerPreset(minutes: 240, label: "4h", isExtended: true),

        // Row 4: Extended sessions
        TimerPreset(minutes: 300, label: "5h", isExtended: true),
        TimerPreset(minutes: 360, label: "6h", isExtended: true),
        TimerPreset(minutes: 420, label: "7h", isExtended: true),
        TimerPreset(minutes: 480, label: "8h", isExtended: true)
    ]
}

// MARK: - Timer Preset Grid

struct TimerPresetGrid: View {
    @Binding var selectedMinutes: Int
    let accentColor: Color
    let onPresetSelected: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(TimerPreset.allPresets) { preset in
                PresetButton(
                    preset: preset,
                    isSelected: selectedMinutes == preset.minutes,
                    accentColor: accentColor
                ) {
                    selectPreset(preset)
                }
            }
        }
    }

    private func selectPreset(_ preset: TimerPreset) {
        if !reduceMotion {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMinutes = preset.minutes
            }
        } else {
            selectedMinutes = preset.minutes
        }

        HapticsService.shared.selectionFeedback()
        onPresetSelected(preset.minutes)
    }
}

// MARK: - Preset Button

private struct PresetButton: View {
    let preset: TimerPreset
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(preset.label)
                    .font(.system(size: 15, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.75))

                if preset.isExtended {
                    Image(systemName: "bolt.fill")
                        .dynamicTypeFont(base: 8)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : accentColor.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                presetBackground
            }
            .scaleEffect(isPressed ? 0.94 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel("\(preset.minutes) minutes")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }

    @ViewBuilder
    private var presetBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.35),
                            accentColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.6), lineWidth: 1.5)
                }
                .shadow(color: accentColor.opacity(0.3), radius: 8, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.4))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                }
        }
    }
}

// MARK: - Compact Preset Row (Alternative Layout)

struct CompactPresetRow: View {
    @Binding var selectedMinutes: Int
    let accentColor: Color
    let onPresetSelected: (Int) -> Void

    private let quickPresets = [15, 25, 30, 45, 60, 90]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPresets, id: \.self) { minutes in
                    CompactPresetChip(
                        minutes: minutes,
                        isSelected: selectedMinutes == minutes,
                        accentColor: accentColor
                    ) {
                        selectedMinutes = minutes
                        HapticsService.shared.selectionFeedback()
                        onPresetSelected(minutes)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Compact Preset Chip

private struct CompactPresetChip: View {
    let minutes: Int
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    private var label: String {
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(accentColor.opacity(0.3))
                            .overlay {
                                Capsule()
                                    .stroke(accentColor.opacity(0.5), lineWidth: 1)
                            }
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.3))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Timer Preset Grid") {
    ZStack {
        LinearGradient(
            colors: [
                Theme.CelestialColors.voidDeep,
                Theme.CelestialColors.void,
                Theme.CelestialColors.abyss
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 32) {
            Text("Select Duration")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.6))

            TimerPresetGrid(
                selectedMinutes: .constant(30),
                accentColor: Theme.Colors.success
            ) { minutes in
                print("Selected: \(minutes) minutes")
            }
            .padding(.horizontal, 20)

            Divider()
                .background(.white.opacity(0.2))

            Text("Compact Version")
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white.opacity(0.6))

            CompactPresetRow(
                selectedMinutes: .constant(25),
                accentColor: Theme.Colors.aiAmber
            ) { _ in }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
