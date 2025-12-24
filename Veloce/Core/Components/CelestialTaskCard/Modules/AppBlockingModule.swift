//
//  AppBlockingModule.swift
//  Veloce
//
//  Per-task app blocking toggle module
//  Integrates with FocusBlockingService for Screen Time API
//

import SwiftUI
import FamilyControls

struct AppBlockingModule: View {
    let task: TaskItem
    @Binding var enableBlocking: Bool
    var onSelectionChange: ((FamilyActivitySelection) -> Void)?

    @State private var showAppPicker = false
    @State private var localSelection: FamilyActivitySelection = FamilyActivitySelection()

    private let blockingService = FocusBlockingService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header with toggle
            HStack {
                // Icon and title
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.TaskCardColors.workMode)

                    Text("App Blocking")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.TaskCardColors.workMode)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: $enableBlocking)
                    .toggleStyle(SwitchToggleStyle(tint: Theme.TaskCardColors.workMode))
                    .labelsHidden()
            }

            // Content when enabled
            if enableBlocking {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    // Authorization check
                    if !blockingService.isAuthorized {
                        authorizationNeededView
                    } else {
                        // Selection summary
                        selectionSummaryView

                        // Select apps button
                        Button {
                            showAppPicker = true
                            HapticsService.shared.selectionFeedback()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.app")
                                Text(hasSelection ? "Edit Blocked Apps" : "Select Apps to Block")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Theme.TaskCardColors.workMode)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Info text
                    Text("Apps will be blocked when you start a focus session for this task")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.TaskCardColors.workMode.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(Theme.TaskCardColors.workMode.opacity(0.15), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: enableBlocking)
        .onAppear {
            loadSavedSelection()
        }
        .familyActivityPicker(
            isPresented: $showAppPicker,
            selection: $localSelection
        )
        .onChange(of: localSelection) { _, newValue in
            saveSelection(newValue)
            onSelectionChange?(newValue)
        }
    }

    // MARK: - Authorization Needed View

    private var authorizationNeededView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.warning)

                Text("Screen Time access required")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Button {
                Task {
                    try? await blockingService.requestAuthorizationIfNeeded()
                }
            } label: {
                Text("Enable in Settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.TaskCardColors.workMode)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.Colors.warning.opacity(0.1))
        )
    }

    // MARK: - Selection Summary View

    private var selectionSummaryView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if hasSelection {
                // Show count of blocked apps
                Image(systemName: "app.badge.checkmark.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.success)

                Text(selectionSummary)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.starDim)

                Text("No apps selected")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.05))
        )
    }

    // MARK: - Helpers

    private var hasSelection: Bool {
        !localSelection.applicationTokens.isEmpty ||
        !localSelection.categoryTokens.isEmpty
    }

    private var selectionSummary: String {
        let appCount = localSelection.applicationTokens.count
        let categoryCount = localSelection.categoryTokens.count

        var parts: [String] = []
        if appCount > 0 {
            parts.append("\(appCount) app\(appCount == 1 ? "" : "s")")
        }
        if categoryCount > 0 {
            parts.append("\(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")")
        }

        return parts.isEmpty ? "No apps selected" : parts.joined(separator: ", ") + " blocked"
    }

    private func loadSavedSelection() {
        // Load from task's stored data
        if let data = task.blockedAppsData,
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            localSelection = selection
        } else {
            // Use global selection as default
            localSelection = blockingService.selectedAppsToBlock
        }
    }

    private func saveSelection(_ selection: FamilyActivitySelection) {
        // Save to task
        if let data = try? PropertyListEncoder().encode(selection) {
            task.blockedAppsData = data
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack {
            AppBlockingModule(
                task: TaskItem(title: "Focus on project"),
                enableBlocking: .constant(true)
            )
            .padding()

            AppBlockingModule(
                task: TaskItem(title: "Quick email"),
                enableBlocking: .constant(false)
            )
            .padding()
        }
    }
}
