//
//  RecurringPickerSheet.swift
//  Veloce
//
//  Wrapper sheet for RecurringSection with Liquid Glass styling
//  Aurora Design System + iOS 26 Glass Effects
//

import SwiftUI

// MARK: - Recurring Picker Sheet

struct RecurringPickerSheet: View {
    @Binding var selectedType: RecurringTypeExtended
    @Binding var customDays: Set<Int>
    @Binding var endDate: Date?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            handleBar

            // Header
            headerSection

            // Content
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Recurring Section
                    RecurringSection(
                        selectedType: $selectedType,
                        customDays: $customDays,
                        endDate: $endDate,
                        onChanged: {
                            HapticsService.shared.selectionFeedback()
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(Theme.Animations.cosmicSpring.delay(0.1), value: appeared)

                    // Quick info card
                    if selectedType != .once {
                        infoCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(Theme.Animations.cosmicSpring.delay(0.2), value: appeared)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }

            // Action buttons
            actionButtons
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
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .dynamicTypeFont(base: 18)
                    .foregroundStyle(Theme.Colors.aiAmber)

                Text("Repeat Task")
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

            Text("Set how often this task repeats")
                .font(Theme.Typography.cosmosMeta)
                .foregroundStyle(Theme.CelestialColors.starDim)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "info.circle.fill")
                .dynamicTypeFont(base: 16)
                .foregroundStyle(Theme.Colors.aiBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Recurring Task")
                    .dynamicTypeFont(base: 13, weight: .semibold)
                    .foregroundStyle(.white)

                Text(recurringDescription)
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.aiBlue.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.Colors.aiBlue.opacity(0.2), lineWidth: 1)
                }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    private var recurringDescription: String {
        switch selectedType {
        case .once:
            return "This task will not repeat"
        case .daily:
            return "A new task will be created every day"
        case .weekdays:
            return "Repeats Monday through Friday"
        case .weekends:
            return "Repeats Saturday and Sunday"
        case .weekly:
            return "Repeats every week on this day"
        case .biweekly:
            return "Repeats every two weeks"
        case .monthly:
            return "Repeats on the same date each month"
        case .custom:
            if customDays.isEmpty {
                return "Select days for custom repeat"
            }
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let selected = customDays.sorted().compactMap { dayNames[safe: $0] }
            return "Repeats on \(selected.joined(separator: ", "))"
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Clear button (if not once)
            if selectedType != .once {
                Button {
                    withAnimation(Theme.Animations.cosmicSpring) {
                        selectedType = .once
                        customDays = []
                        endDate = nil
                    }
                    HapticsService.shared.selectionFeedback()
                } label: {
                    Text("Clear")
                        .dynamicTypeFont(base: 15, weight: .medium)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.lg)
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            }

            // Save button
            Button {
                onSave()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark")
                        .dynamicTypeFont(base: 14, weight: .bold)

                    Text("Save")
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
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.lg)
    }
}

// MARK: - Preview

#Preview {
    RecurringPickerSheet(
        selectedType: .constant(.weekly),
        customDays: .constant([]),
        endDate: .constant(nil),
        onSave: {}
    )
}
