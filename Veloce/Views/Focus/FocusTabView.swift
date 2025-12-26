//
//  FocusTabView.swift
//  Veloce
//
//  Focus Tab - Timer and Focus Sessions
//  Opal + Tiimo inspired design with working countdown timer
//

import SwiftUI
import FamilyControls

// MARK: - Focus Section

enum FocusSection: String, CaseIterable {
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

    // Section navigation
    @State private var selectedSection: FocusSection = .timer

    // Timer state
    @State private var selectedMode: FocusTimerMode = .pomodoro
    @State private var isSessionActive = false
    @State private var remainingSeconds: Int = 25 * 60
    @State private var totalSeconds: Int = 25 * 60
    @State private var showModeSelector = false
    @State private var showBlockingSheet = false
    @State private var showAppBlockingPicker = false
    @State private var timer: Timer?
    @State private var showTaskCompletionPrompt = false

    // App Blocking
    @State private var enableAppBlocking = false
    private let blockingService = FocusBlockingService.shared

    // Pattern Learning
    private let patternService = PatternLearningService.shared

    // Animation states
    @State private var timerRingProgress: Double = 1.0
    @State private var breathingScale: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var focusStatusText: String {
        if let task = taskContext?.task {
            if isSessionActive {
                return task.title
            } else {
                return "Focus on: \(task.title)"
            }
        } else {
            return isSessionActive ? "Focus Mode" : "Ready to focus"
        }
    }

    var body: some View {
        ZStack {
            VoidBackground.focus

            VStack(spacing: 0) {
                // Section Navigation
                sectionNavigationView
                    .padding(.top, Theme.Spacing.universalHeaderHeight + Theme.Spacing.sm)

                // Section Content
                switch selectedSection {
                case .timer:
                    timerSectionContent
                case .schedules:
                    FocusSchedulesView()
                case .history:
                    FocusHistoryView()
                case .presets:
                    FocusPresetsView()
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showModeSelector) {
            FocusTimerModePickerSheet(selectedMode: $selectedMode)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBlockingSheet) {
            FocusAppBlockingConfigSheet(enableBlocking: $enableAppBlocking)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .familyActivityPicker(
            isPresented: $showAppBlockingPicker,
            selection: Bindable(blockingService).selectedAppsToBlock
        )
        .onChange(of: blockingService.selectedAppsToBlock) { _, _ in
            blockingService.saveSelection()
        }
        .onAppear {
            configureFromTaskContext()
            resetTimer()
            startBreathingAnimation()
        }
        .alert("Task Completed?", isPresented: $showTaskCompletionPrompt) {
            Button("Yes, completed!") {
                onSessionComplete?(true)
            }
            Button("Not yet") {
                onSessionComplete?(false)
            }
        } message: {
            if let task = taskContext?.task {
                Text("Did you complete '\(task.title)'?")
            } else {
                Text("Did you complete your task?")
            }
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

    // MARK: - Section Navigation

    private var sectionNavigationView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FocusSection.allCases, id: \.self) { section in
                    FocusSectionPill(
                        section: section,
                        isSelected: selectedSection == section
                    ) {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    // MARK: - Timer Section Content

    private var timerSectionContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                    .frame(height: Theme.Spacing.md)

                // Timer Ring
                timerRingView
                    .padding(.bottom, Theme.Spacing.lg)

                // Mode Selector
                modeSelectorView

                // App Blocking Toggle
                appBlockingToggle

                // Action Buttons
                actionButtons

                Spacer()
                    .frame(height: Theme.Spacing.lg)

                // AI Insight
                focusInsightCard

                // Today's Sessions
                todaySessionsCard
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
        }
    }

    // MARK: - Timer Ring

    private var timerRingView: some View {
        ZStack {
            // Outer glow
            SwiftUI.Circle()
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
            SwiftUI.Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 240, height: 240)

            // Progress ring
            SwiftUI.Circle()
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

                Text(focusStatusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)

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

    // MARK: - App Blocking Toggle

    private var appBlockingToggle: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(enableAppBlocking ? Theme.Colors.aiAmber : .secondary)

                    Text("App Blocking")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(enableAppBlocking ? .primary : .secondary)
                }

                Spacer()

                Toggle("", isOn: $enableAppBlocking)
                    .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.aiAmber))
                    .labelsHidden()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            if enableAppBlocking {
                HStack(spacing: Theme.Spacing.sm) {
                    if blockingService.isAuthorized {
                        if blockingService.hasAppsSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.success)

                            Text(blockingService.selectionSummary)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.warning)

                            Text("No apps selected")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            showAppBlockingPicker = true
                            HapticsService.shared.selectionFeedback()
                        } label: {
                            Text(blockingService.hasAppsSelected ? "Edit" : "Select Apps")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.Colors.aiAmber)
                        }
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.warning)

                        Text("Screen Time access required")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            Task {
                                try? await blockingService.requestAuthorizationIfNeeded()
                            }
                        } label: {
                            Text("Enable")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.Colors.aiAmber)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: enableAppBlocking)
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
                            SwiftUI.Circle()
                                .fill(.ultraThinMaterial)
                        }
                        .glassEffect(.regular, in: SwiftUI.Circle())
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

    // MARK: - Task Context Configuration

    private func configureFromTaskContext() {
        guard let context = taskContext else { return }

        // Set custom mode with task duration
        selectedMode = .custom

        // Configure duration from task estimate
        totalSeconds = context.suggestedDuration * 60
        remainingSeconds = totalSeconds

        // Configure app blocking based on task settings
        enableAppBlocking = context.enableAppBlocking
    }

    // MARK: - Timer Logic

    private func startTimer() {
        isSessionActive = true
        HapticsService.shared.success()

        // Start app blocking if enabled
        if enableAppBlocking && blockingService.hasAppsSelected {
            Task {
                do {
                    try await blockingService.startSession(
                        title: selectedMode.rawValue,
                        duration: totalSeconds,
                        isDeepFocus: selectedMode == .deepWork
                    )
                } catch {
                    // Continue without blocking if it fails
                    print("App blocking failed: \(error.localizedDescription)")
                }
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
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
    }

    private func pauseTimer() {
        isSessionActive = false
        timer?.invalidate()
        timer = nil

        // End app blocking on pause
        if blockingService.isBlocking {
            Task {
                await blockingService.endSession(completed: false)
            }
        }
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
        timer?.invalidate()
        timer = nil
        isSessionActive = false
        HapticsService.shared.success()

        // Record focus session for pattern learning
        let durationMinutes = (totalSeconds - remainingSeconds) / 60
        patternService.recordFocusSession(
            mode: selectedMode.rawValue,
            durationMinutes: durationMinutes,
            completed: true
        )

        // End app blocking on completion
        if blockingService.isBlocking {
            Task {
                await blockingService.endSession(completed: true)
            }
        }

        // Show completion feedback
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            timerRingProgress = 0
        }

        // If launched from a task, prompt for task completion
        if taskContext != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showTaskCompletionPrompt = true
            }
        } else {
            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                resetTimer()
            }
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
                        .font(.system(size: 64, weight: .thin))
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
                                    .font(.system(size: 24))
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
                            .font(.system(size: 16, weight: .semibold))
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
                                .font(.system(size: 16, weight: .semibold))
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
    let section: FocusSection
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
