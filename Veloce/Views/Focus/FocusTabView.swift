//
//  FocusTabView.swift
//  Veloce
//
//  Focus Tab - Timer and Focus Sessions
//  Opal + Tiimo inspired design with working countdown timer
//

import SwiftUI

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
    @State private var selectedMode: FocusTimerMode = .pomodoro
    @State private var isSessionActive = false
    @State private var remainingSeconds: Int = 25 * 60
    @State private var totalSeconds: Int = 25 * 60
    @State private var showModeSelector = false
    @State private var showBlockingSheet = false
    @State private var timer: Timer?

    // Animation states
    @State private var timerRingProgress: Double = 1.0
    @State private var breathingScale: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            VoidBackground.focus

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // Timer Ring
                timerRingView
                    .padding(.bottom, Theme.Spacing.lg)

                // Mode Selector
                modeSelectorView

                // Action Buttons
                actionButtons

                Spacer()

                // AI Insight
                focusInsightCard

                // Today's Sessions
                todaySessionsCard
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.top, Theme.Spacing.universalHeaderHeight + Theme.Spacing.lg)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showModeSelector) {
            FocusTimerModePickerSheet(selectedMode: $selectedMode)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBlockingSheet) {
            AppBlockingSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            resetTimer()
            startBreathingAnimation()
        }
        .onChange(of: selectedMode) { _, newMode in
            if !isSessionActive {
                resetTimer()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Timer Ring

    private var timerRingView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiAmber.opacity(0.3),
                            Theme.Colors.aiAmber.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 20)
                .scaleEffect(breathingScale)

            // Track ring
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 240, height: 240)

            // Progress ring
            Circle()
                .trim(from: 0, to: timerRingProgress)
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.aiAmber, Theme.Colors.aiOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerRingProgress)

            // Time display
            VStack(spacing: Theme.Spacing.sm) {
                Text(formattedTime)
                    .font(.system(size: 56, weight: .thin, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(isSessionActive ? "Focus Mode" : "Ready to focus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                // Mode badge
                HStack(spacing: 6) {
                    Image(systemName: selectedMode.icon)
                        .font(.system(size: 12))
                    Text(selectedMode.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Theme.Colors.aiAmber)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(Theme.Colors.aiAmber.opacity(0.15))
                }
            }
        }
    }

    // MARK: - Mode Selector

    private var modeSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FocusTimerMode.allCases, id: \.self) { mode in
                    FocusTimerModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode
                    ) {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedMode = mode
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
        }
        .padding(.horizontal, -Theme.Spacing.screenPadding)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Start/Pause Button
            Button {
                HapticsService.shared.impact()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if isSessionActive {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isSessionActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isSessionActive ? "Pause" : "Start Focus")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.aiAmber, Theme.Colors.aiOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .buttonStyle(.plain)
            .shadow(color: Theme.Colors.aiAmber.opacity(0.4), radius: 16, y: 8)

            // Reset Button (only when active or paused with time remaining)
            if isSessionActive || remainingSeconds != totalSeconds {
                Button {
                    HapticsService.shared.lightImpact()
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 52, height: 52)
                        .background {
                            Circle()
                                .fill(.ultraThinMaterial)
                        }
                        .glassEffect(.regular, in: Circle())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Focus Insight Card

    private var focusInsightCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.Colors.aiAmber)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your peak focus is 9-11 AM")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text("Schedule deep work sessions then!")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.aiAmber.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.aiAmber.opacity(0.2), lineWidth: 1)
        }
    }

    // MARK: - Today's Sessions

    private var todaySessionsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Today's Focus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("2h 15m")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Colors.aiAmber)
            }

            HStack(spacing: 12) {
                SessionBadge(mode: .pomodoro, count: 3)
                SessionBadge(mode: .deepWork, count: 1)
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 100)
    }

    // MARK: - Timer Logic

    private func startTimer() {
        isSessionActive = true
        HapticsService.shared.success()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                updateProgress()

                // Haptic feedback at milestones
                if remainingSeconds == 60 {
                    HapticsService.shared.lightImpact()
                } else if remainingSeconds <= 3 && remainingSeconds > 0 {
                    HapticsService.shared.lightImpact()
                }
            } else {
                completeSession()
            }
        }
    }

    private func pauseTimer() {
        isSessionActive = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        totalSeconds = selectedMode.duration * 60
        remainingSeconds = totalSeconds
        timerRingProgress = 1.0
    }

    private func updateProgress() {
        if totalSeconds > 0 {
            timerRingProgress = Double(remainingSeconds) / Double(totalSeconds)
        }
    }

    private func completeSession() {
        pauseTimer()
        HapticsService.shared.success()

        // Show completion feedback
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            timerRingProgress = 0
        }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            resetTimer()
        }
    }

    // MARK: - Animations

    private func startBreathingAnimation() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breathingScale = 1.05
        }
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
                    .font(.system(size: 12, weight: .semibold))

                if mode.duration > 0 {
                    Text("\(mode.duration) min")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    Text("∞")
                        .font(.system(size: 10))
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
                .font(.system(size: 12))
            Text("×\(count)")
                .font(.system(size: 12, weight: .bold))
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
                                .font(.system(size: 20))
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

// MARK: - App Blocking Sheet

struct AppBlockingSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(Theme.Colors.aiAmber)

                Text("App Blocking")
                    .font(.title2.bold())

                Text("Block distracting apps during your focus sessions. Requires Screen Time permissions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button("Enable App Blocking") {
                    // Will integrate with FamilyActivityPicker
                }
                .buttonStyle(.glassProminent)
            }
            .padding()
            .navigationTitle("App Blocking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FocusTabView()
}
