//
//  HealthSection.swift
//  MyTasksAI
//
//  Apple Health Integration Section for Task Detail Sheet
//  UI toggle for tracking focus time as mindful minutes
//

import SwiftUI

// MARK: - Health Section
struct HealthSection: View {
    @State private var isHealthTrackingEnabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header row with toggle
            HStack {
                // Icon and title
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.success)
                    Text("Apple Health")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: $isHealthTrackingEnabled)
                    .labelsHidden()
                    .tint(Theme.Colors.success)
                    .onChange(of: isHealthTrackingEnabled) { _, newValue in
                        HapticsService.shared.selectionFeedback()
                    }
            }

            // Description
            Text("Track focus time as mindful minutes")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.textTertiary)

            // Info banner (when enabled)
            if isHealthTrackingEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.success)
                    Text("Focus sessions will be saved to Health")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(Theme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.success.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(Theme.Spacing.lg)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHealthTrackingEnabled)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        IridescentBackground()
        HealthSection()
            .padding()
    }
}
