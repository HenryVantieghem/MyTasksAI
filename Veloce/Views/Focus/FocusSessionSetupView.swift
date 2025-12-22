//
//  FocusSessionSetupView.swift
//  Veloce
//
//  Beautiful focus session configuration with Celestial Void aesthetic
//  Allows users to configure duration, blocked apps, and Deep Focus mode
//

import SwiftUI
import FamilyControls

// MARK: - Focus Session Setup View

struct FocusSessionSetupView: View {
    @Environment(\.dismiss) private var dismiss

    // Optional task link
    let task: TaskItem?

    // Completion handler
    let onStart: (Int, Bool, FamilyActivitySelection?) -> Void

    // MARK: State

    @State private var focusBlockingService = FocusBlockingService.shared
    @State private var screenTimeAuthService = ScreenTimeAuthService.shared

    @State private var selectedDuration: Int = 25  // minutes
    @State private var enableAppBlocking: Bool = true
    @State private var isDeepFocus: Bool = false
    @State private var showAppPicker: Bool = false
    @State private var showDeepFocusWarning: Bool = false
    @State private var appSelection: FamilyActivitySelection = FamilyActivitySelection()

    // Duration presets
    private let durationPresets = [15, 25, 45, 60, 90, 120]

    var body: some View {
        ZStack {
            // Deep void background with subtle gradient
            backgroundGradient

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Duration section
                        durationSection

                        // App blocking section
                        appBlockingSection

                        // Deep Focus section
                        deepFocusSection

                        // Start button
                        startButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerView(selection: $appSelection)
        }
        .alert("Enable Deep Focus?", isPresented: $showDeepFocusWarning) {
            Button("Cancel", role: .cancel) {
                isDeepFocus = false
            }
            Button("Enable Deep Focus", role: .destructive) {
                startSession()
            }
        } message: {
            Text("Deep Focus mode cannot be ended early. You won't be able to access blocked apps for \(selectedDuration) minutes. Are you sure?")
        }
        .onAppear {
            appSelection = focusBlockingService.selectedAppsToBlock
            if let taskMinutes = task?.estimatedMinutes {
                selectedDuration = taskMinutes
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Theme.CelestialColors.void
                .ignoresSafeArea()

            // Subtle nebula glow at top
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaCore.opacity(0.15),
                    Theme.CelestialColors.void
                ],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .frame(width: 36, height: 36)
                    .background(Theme.CelestialColors.abyss)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Focus Session")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.CelestialColors.starWhite)

                if let task = task {
                    Text(task.title)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Placeholder for balance
            Color.clear
                .frame(width: 36, height: 36)
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Duration", icon: "timer", color: Theme.CelestialColors.nebulaCore)

            // Duration display
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("\(selectedDuration)")
                        .font(.system(size: 64, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("minutes")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
                Spacer()
            }

            // Duration presets
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(durationPresets, id: \.self) { duration in
                    durationButton(minutes: duration)
                }
            }

            // Custom slider
            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { Double(selectedDuration) },
                    set: { selectedDuration = Int($0) }
                ), in: 5...180, step: 5)
                .tint(Theme.CelestialColors.nebulaCore)

                HStack {
                    Text("5 min")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                    Spacer()
                    Text("3 hours")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(glassCard)
    }

    private func durationButton(minutes: Int) -> some View {
        let isSelected = selectedDuration == minutes
        let label = minutes >= 60 ? "\(minutes/60)h\(minutes % 60 > 0 ? " \(minutes % 60)m" : "")" : "\(minutes)m"

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDuration = minutes
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            Text(label)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Theme.CelestialColors.starWhite : Theme.CelestialColors.starDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Theme.CelestialColors.nebulaCore.opacity(0.3) : Theme.CelestialColors.nebulaDust)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Theme.CelestialColors.nebulaCore.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - App Blocking Section

    private var appBlockingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "App Blocking", icon: "shield.lefthalf.filled", color: Theme.CelestialColors.nebulaGlow)

            // Toggle
            Toggle(isOn: $enableAppBlocking) {
                HStack(spacing: 12) {
                    Text("Block Distracting Apps")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starWhite)
                }
            }
            .tint(Theme.CelestialColors.nebulaCore)

            if enableAppBlocking {
                // Authorization check
                if !screenTimeAuthService.isAuthorized {
                    authorizationBanner
                } else {
                    // Selected apps summary
                    appSelectionCard
                }
            }
        }
        .padding(20)
        .background(glassCard)
    }

    private var authorizationBanner: some View {
        Button {
            Task {
                try? await screenTimeAuthService.requestAuthorization()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.CelestialColors.warningNebula)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Screen Time Access Required")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("Tap to grant access")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.CelestialColors.warningNebula)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.CelestialColors.warningNebula.opacity(0.15))
            )
        }
    }

    private var appSelectionCard: some View {
        Button {
            showAppPicker = true
            HapticsService.shared.selectionFeedback()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.CelestialColors.nebulaCore.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(appSelectionSummary)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("Tap to edit")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.CelestialColors.nebulaDust)
            )
        }
    }

    private var appSelectionSummary: String {
        let appCount = appSelection.applicationTokens.count
        let categoryCount = appSelection.categoryTokens.count

        if appCount == 0 && categoryCount == 0 {
            return "Select apps to block"
        }

        var parts: [String] = []
        if appCount > 0 { parts.append("\(appCount) app\(appCount == 1 ? "" : "s")") }
        if categoryCount > 0 { parts.append("\(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Deep Focus Section

    private var deepFocusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Deep Focus", icon: "lock.shield.fill", color: Theme.CelestialColors.errorNebula)

            Toggle(isOn: $isDeepFocus) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Deep Focus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Text("Cannot be ended early • +50 bonus points")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
            .tint(Theme.CelestialColors.errorNebula)

            if isDeepFocus {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.warningNebula)

                    Text("You won't be able to cancel this session once started.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.CelestialColors.warningNebula)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.CelestialColors.warningNebula.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(glassCard)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            if isDeepFocus {
                showDeepFocusWarning = true
            } else {
                startSession()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isDeepFocus ? "lock.shield.fill" : "play.fill")
                    .font(.system(size: 18))

                Text(isDeepFocus ? "Start Deep Focus" : "Start Focus Session")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: isDeepFocus
                        ? [Theme.CelestialColors.errorNebula, Theme.CelestialColors.nebulaCore]
                        : [Theme.CelestialColors.nebulaCore, Theme.CelestialColors.nebulaGlow],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: (isDeepFocus ? Theme.CelestialColors.errorNebula : Theme.CelestialColors.nebulaCore).opacity(0.4), radius: 15)
        }
        .disabled(!canStart)
        .opacity(canStart ? 1 : 0.5)
        .padding(.top, 8)
    }

    private var canStart: Bool {
        if enableAppBlocking {
            return screenTimeAuthService.isAuthorized &&
                   (!appSelection.applicationTokens.isEmpty || !appSelection.categoryTokens.isEmpty)
        }
        return true
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.CelestialColors.starWhite)
        }
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Theme.CelestialColors.abyss)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.nebulaCore.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Actions

    private func startSession() {
        let selection = enableAppBlocking ? appSelection : nil
        onStart(selectedDuration * 60, isDeepFocus, selection)
        HapticsService.shared.impact()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    FocusSessionSetupView(task: nil) { duration, isDeep, selection in
        print("Start session: \(duration)s, deep: \(isDeep)")
    }
}
