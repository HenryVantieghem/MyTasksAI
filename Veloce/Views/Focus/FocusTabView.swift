//
//  FocusTabView.swift
//  Veloce
//
//  Focus Tab - Timer and Focus Sessions
//  Opal + Tiimo inspired design with working countdown timer
//

import SwiftUI
import FamilyControls

// MARK: - Focus Tab Section

enum FocusTabSection: String, CaseIterable {
    case timer = "Timer"
    case schedules = "Schedules"
    case history = "History"
    case presets = "Presets"

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .schedules: return "calendar.badge.clock"
        case .history: return "chart.bar.fill"
        case .presets: return "shield.lefthalf.filled"
        }
    }
}

// MARK: - Focus Task Context

/// Context passed from a task to pre-configure the Focus session
struct FocusTaskContext {
    let task: TaskItem
    let suggestedDuration: Int
    let enableAppBlocking: Bool

    init(task: TaskItem) {
        self.task = task
        self.suggestedDuration = task.estimatedMinutes ?? 25
        self.enableAppBlocking = false  // App blocking defaults to off
    }
}

// MARK: - Focus Timer Mode

enum FocusTimerMode: String, CaseIterable {
    case deepWork = "Deep Work"
    case pomodoro = "Pomodoro"
    case flowState = "Flow State"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .pomodoro: return "timer"
        case .flowState: return "waveform.path.ecg"
        case .custom: return "slider.horizontal.3"
        }
    }

    var duration: Int {
        switch self {
        case .deepWork: return 90
        case .pomodoro: return 25
        case .flowState: return 0 // Unlimited
        case .custom: return 45
        }
    }

    var breakDuration: Int {
        switch self {
        case .deepWork: return 20
        case .pomodoro: return 5
        case .flowState: return 0
        case .custom: return 10
        }
    }

    var description: String {
        switch self {
        case .deepWork: return "90 min deep focus, 20 min break"
        case .pomodoro: return "25 min work, 5 min break"
        case .flowState: return "Work until naturally done"
        case .custom: return "Set your own duration"
        }
    }
}

// MARK: - Focus Tab View

struct FocusTabView: View {
    // Task context (when launched from a task)
    var taskContext: FocusTaskContext?
    var onSessionComplete: ((Bool) -> Void)?

    var body: some View {
        FocusMainView(
            taskContext: taskContext,
            onSessionComplete: onSessionComplete
        )
    }
}

// MARK: - Focus Timer Mode Card

struct FocusTimerModeCard: View {
    let mode: FocusTimerMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))

                Text(mode.rawValue)
                    .dynamicTypeFont(base: 12, weight: .semibold)

                if mode.duration > 0 {
                    Text("\(mode.duration) min")
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    Text("∞")
                        .dynamicTypeFont(base: 10)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .frame(width: 80, height: 80)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.aiAmber.opacity(0.3) : .white.opacity(0.05))
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.aiAmber, lineWidth: 2)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Badge

struct SessionBadge: View {
    let mode: FocusTimerMode
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.icon)
                .dynamicTypeFont(base: 12)
            Text("×\(count)")
                .dynamicTypeFont(base: 12, weight: .bold)
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.white.opacity(0.1))
        }
    }
}

// MARK: - Focus Timer Mode Picker Sheet

struct FocusTimerModePickerSheet: View {
    @Binding var selectedMode: FocusTimerMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(FocusTimerMode.allCases, id: \.self) { mode in
                    Button {
                        selectedMode = mode
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: mode.icon)
                                .dynamicTypeFont(base: 20)
                                .foregroundStyle(Theme.Colors.aiAmber)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .font(.headline)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.Colors.aiAmber)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Focus Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Focus App Blocking Config Sheet

struct FocusAppBlockingConfigSheet: View {
    @Binding var enableBlocking: Bool
    @State private var showAppPicker = false
    @Environment(\.dismiss) private var dismiss

    private let blockingService = FocusBlockingService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                // Hero Icon
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.aiAmber.opacity(0.3),
                                    Theme.Colors.aiAmber.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "shield.lefthalf.filled")
                        .dynamicTypeFont(base: 64, weight: .thin)
                        .foregroundStyle(Theme.Colors.aiAmber)
                }
                .padding(.top, Theme.Spacing.lg)

                // Title & Description
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Focus Shield")
                        .font(.title.bold())

                    Text("Block distracting apps during focus sessions to stay in the zone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }

                // Current Selection Summary
                if blockingService.isAuthorized {
                    VStack(spacing: Theme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apps to Block")
                                    .font(.headline)

                                Text(blockingService.hasAppsSelected ? blockingService.selectionSummary : "None selected")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if blockingService.hasAppsSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .dynamicTypeFont(base: 24)
                                    .foregroundStyle(Theme.Colors.success)
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

                        Button {
                            showAppPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.app")
                                Text(blockingService.hasAppsSelected ? "Edit Blocked Apps" : "Select Apps to Block")
                            }
                            .dynamicTypeFont(base: 16, weight: .semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.aiAmber)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                } else {
                    // Authorization needed
                    VStack(spacing: Theme.Spacing.md) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Theme.Colors.warning)

                            Text("Screen Time access is required to block apps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Theme.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.warning.opacity(0.1))
                        }

                        Button {
                            Task {
                                try? await blockingService.requestAuthorizationIfNeeded()
                            }
                        } label: {
                            Text("Enable Screen Time Access")
                                .dynamicTypeFont(base: 16, weight: .semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.Colors.aiAmber)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer()

                // Enable Toggle
                Toggle(isOn: $enableBlocking) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundStyle(enableBlocking ? Theme.Colors.aiAmber : .secondary)
                        Text("Enable for Focus Sessions")
                            .font(.headline)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.aiAmber))
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
            }
            .navigationTitle("App Blocking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .familyActivityPicker(
                isPresented: $showAppPicker,
                selection: Bindable(blockingService).selectedAppsToBlock
            )
            .onChange(of: blockingService.selectedAppsToBlock) { _, _ in
                blockingService.saveSelection()
            }
        }
    }
}

// MARK: - Focus Section Pill (Liquid Glass)

struct FocusSectionPill: View {
    let section: FocusTabSection
    let isSelected: Bool
    let action: () -> Void

    @Namespace private var pillNamespace

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                Text(section.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Theme.Colors.aiAmber.opacity(0.3))
                }
            }
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Preview

#Preview {
    FocusTabView()
}
