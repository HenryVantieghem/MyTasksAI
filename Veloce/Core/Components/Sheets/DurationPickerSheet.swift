//
//  DurationPickerSheet.swift
//  Veloce
//
//  Ultra-Premium Duration Picker with Liquid Glass Design
//  Utopian Design System + iOS 26 Glass Effects
//

import SwiftUI

// MARK: - Duration Picker Sheet

struct DurationPickerSheet: View {
    let selectedDuration: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentSelection: Int
    @State private var appeared = false

    // Duration presets with descriptions
    private let presets: [(duration: Int, label: String, description: String, icon: String)] = [
        (15, "15 min", "Quick task", "bolt.fill"),
        (30, "30 min", "Short focus", "timer"),
        (45, "45 min", "Standard session", "clock.fill"),
        (60, "1 hour", "Deep work", "brain.head.profile"),
        (90, "1.5 hours", "Extended focus", "flame.fill"),
        (120, "2 hours", "Marathon session", "mountain.2.fill")
    ]

    init(selectedDuration: Int, onSelect: @escaping (Int) -> Void) {
        self.selectedDuration = selectedDuration
        self.onSelect = onSelect
        self._currentSelection = State(initialValue: selectedDuration)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            handleBar

            // Header
            headerSection

            // Duration options
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(Array(presets.enumerated()), id: \.element.duration) { index, preset in
                        DurationOptionRow(
                            duration: preset.duration,
                            label: preset.label,
                            description: preset.description,
                            icon: preset.icon,
                            isSelected: currentSelection == preset.duration,
                            onSelect: {
                                withAnimation(Theme.Animations.cosmicSpring) {
                                    currentSelection = preset.duration
                                }
                                HapticsService.shared.selectionFeedback()
                            }
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            Theme.Animations.cosmicSpring.delay(Double(index) * 0.05),
                            value: appeared
                        )
                    }

                    // Custom duration option
                    customDurationSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            Theme.Animations.cosmicSpring.delay(0.3),
                            value: appeared
                        )
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }

            // Confirm button
            confirmButton
        }
        .background {
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }

    // MARK: - Handle Bar

    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Theme.CelestialColors.starDim.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "timer")
                    .dynamicTypeFont(base: 18)
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("Set Duration")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .frame(width: 32, height: 32)
                }
                .glassEffect(.regular, in: Circle())
            }

            Text("How long will this task take?")
                .font(Theme.Typography.cosmosMeta)
                .foregroundStyle(Theme.CelestialColors.starDim)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Custom Duration

    private var customDurationSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Theme.CelestialColors.starDim.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, Theme.Spacing.sm)

            HStack {
                Text("Custom")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.CelestialColors.starDim)

                Spacer()

                // Stepper-style control
                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        if currentSelection > 5 {
                            currentSelection -= 5
                            HapticsService.shared.selectionFeedback()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .dynamicTypeFont(base: 14, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .glassEffect(.regular, in: Circle())

                    Text("\(currentSelection) min")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 80)

                    Button {
                        if currentSelection < 240 {
                            currentSelection += 5
                            HapticsService.shared.selectionFeedback()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 14, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .glassEffect(.regular, in: Circle())
                }
            }
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            onSelect(currentSelection)
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark")
                    .dynamicTypeFont(base: 14, weight: .bold)

                Text("Set \(formatDuration(currentSelection))")
                    .dynamicTypeFont(base: 16, weight: .semibold)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.auroraGreen)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.lg)
    }

    // MARK: - Helpers

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

// MARK: - Duration Option Row

private struct DurationOptionRow: View {
    let duration: Int
    let label: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.CelestialColors.nebulaCore.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .dynamicTypeFont(base: 18)
                        .foregroundStyle(isSelected ? Theme.CelestialColors.nebulaCore : Theme.CelestialColors.starDim)
                }

                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(description)
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Theme.CelestialColors.nebulaCore : Theme.CelestialColors.starDim.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Theme.CelestialColors.nebulaCore)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Theme.CelestialColors.nebulaCore.opacity(0.08) : Color.white.opacity(0.03))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Theme.CelestialColors.nebulaCore.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DurationPickerSheet(selectedDuration: 30) { duration in
        print("Selected: \(duration) min")
    }
}
