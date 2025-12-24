//
//  CelestialSectionDivider.swift
//  Veloce
//
//  Visual divider between sections in CelestialTaskCard
//  Replaces collapsible section headers with always-visible dividers
//

import SwiftUI

// MARK: - Celestial Section Divider

struct CelestialSectionDivider: View {
    let title: String
    let icon: String
    var accentColor: Color = Theme.CelestialColors.starDim

    var body: some View {
        HStack(spacing: 12) {
            // Cosmic line (left) - gradient fade in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, accentColor.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Section label with icon
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))

                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
            }
            .foregroundStyle(accentColor)

            // Cosmic line (right) - gradient fade out
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Themed Dividers

extension CelestialSectionDivider {

    /// Task Details section divider
    static func taskDetails() -> CelestialSectionDivider {
        CelestialSectionDivider(
            title: "Task Details",
            icon: "list.bullet.clipboard",
            accentColor: Theme.Colors.accent
        )
    }

    /// AI Genius section divider
    static func aiGenius() -> CelestialSectionDivider {
        CelestialSectionDivider(
            title: "AI Genius",
            icon: "sparkles",
            accentColor: Theme.Colors.aiPurple
        )
    }

    /// Repeat/Recurring section divider
    static func recurring() -> CelestialSectionDivider {
        CelestialSectionDivider(
            title: "Repeat",
            icon: "repeat",
            accentColor: Theme.Colors.aiPurple
        )
    }

    /// Schedule section divider
    static func schedule() -> CelestialSectionDivider {
        CelestialSectionDivider(
            title: "Schedule",
            icon: "calendar",
            accentColor: Theme.TaskCardColors.schedule
        )
    }

    /// Focus section divider
    static func focus() -> CelestialSectionDivider {
        CelestialSectionDivider(
            title: "Focus",
            icon: "scope",
            accentColor: Theme.TaskCardColors.workMode
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.lg) {
            CelestialSectionDivider.taskDetails()

            Text("Task details content here...")
                .foregroundStyle(.white)
                .padding()

            CelestialSectionDivider.aiGenius()

            Text("AI Genius content here...")
                .foregroundStyle(.white)
                .padding()

            CelestialSectionDivider.recurring()

            Text("Recurring options here...")
                .foregroundStyle(.white)
                .padding()

            CelestialSectionDivider.schedule()

            Text("Schedule content here...")
                .foregroundStyle(.white)
                .padding()

            CelestialSectionDivider.focus()

            Text("Focus mode content here...")
                .foregroundStyle(.white)
                .padding()
        }
        .padding()
    }
}
