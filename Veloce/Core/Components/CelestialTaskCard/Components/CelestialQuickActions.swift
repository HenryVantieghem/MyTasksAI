//
//  CelestialQuickActions.swift
//  Veloce
//
//  Quick action buttons for CelestialTaskCard:
//  Complete, Duplicate, Snooze, Delete
//

import SwiftUI

struct CelestialQuickActions: View {
    let onComplete: () -> Void
    let onDuplicate: () -> Void
    let onSnooze: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Primary action: Complete
            completeButton

            // Secondary actions row
            HStack(spacing: Theme.Spacing.sm) {
                duplicateButton
                snoozeButton
                deleteButton
            }
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button(action: onComplete) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .dynamicTypeFont(base: 18, weight: .semibold)

                Text("Mark Complete")
                    .dynamicTypeFont(base: 16, weight: .semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.success,
                                Theme.Colors.success.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Theme.Colors.success.opacity(0.3), radius: 8, y: 4)
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Duplicate Button

    private var duplicateButton: some View {
        Button(action: onDuplicate) {
            VStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .dynamicTypeFont(base: 18, weight: .medium)

                Text("Duplicate")
                    .dynamicTypeFont(base: 11, weight: .medium)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Snooze Button

    private var snoozeButton: some View {
        Button(action: onSnooze) {
            VStack(spacing: 6) {
                Image(systemName: "moon.zzz")
                    .dynamicTypeFont(base: 18, weight: .medium)

                Text("Snooze")
                    .dynamicTypeFont(base: 11, weight: .medium)
            }
            .foregroundStyle(Theme.TaskCardColors.schedule)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.TaskCardColors.schedule.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.TaskCardColors.schedule.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(action: onDelete) {
            VStack(spacing: 6) {
                Image(systemName: "trash")
                    .dynamicTypeFont(base: 18, weight: .medium)

                Text("Delete")
                    .dynamicTypeFont(base: 11, weight: .medium)
            }
            .foregroundStyle(Theme.Colors.destructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.Colors.destructive.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.Colors.destructive.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack {
            Spacer()

            CelestialQuickActions(
                onComplete: { print("Complete") },
                onDuplicate: { print("Duplicate") },
                onSnooze: { print("Snooze") },
                onDelete: { print("Delete") }
            )
            .padding()
        }
    }
}
