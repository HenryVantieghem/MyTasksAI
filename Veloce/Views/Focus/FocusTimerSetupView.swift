//
//  FocusTimerSetupView.swift
//  Veloce
//
//  Focus Timer Setup Experience
//  Beautiful orbital duration picker with task selection & app blocking pre-config
//

import SwiftUI
import FamilyControls

// MARK: - Focus Timer Setup View

struct FocusTimerSetupView: View {
    var taskContext: FocusTaskContext?
    var onStartSession: ((FocusSession) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Timer configuration
    @State private var selectedMinutes: Int = 25
    @State private var selectedBreakMinutes: Int = 5
    @State private var selectedMode: FocusTimerMode = .pomodoro

    // Task selection
    @State private var selectedTasks: [TaskItem] = []
    @State private var showTaskPicker = false

    // App blocking
    @State private var enableAppBlocking = false
    @State private var showAppBlockingPicker = false

    // Animation states
    @State private var ringRotation: Double = 0
    @State private var pulseScale: CGFloat = 1
    @State private var orbGlow: Double = 0.5

    // Services
    private let blockingService = FocusBlockingService.shared

    var body: some View {
        ZStack {
            // Background
            timerSetupBackground

            VStack(spacing: 0) {
                // Top bar with dismiss
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.xxl) {
                        // Orbital duration picker
                        orbitalDurationPicker
                            .padding(.top, Theme.Spacing.lg)

                        // Mode selector
                        modeSelector

                        // Break time selector
                        breakTimeSelector

                        // Task selection
                        taskSelectionSection

                        // App blocking section
                        appBlockingSection

                        // Start button
                        startButton
                            .padding(.bottom, Theme.Spacing.xxxl)
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                }
            }
        }
        .preferredColorScheme(.dark)
        .familyActivityPicker(
            isPresented: $showAppBlockingPicker,
            selection: Bindable(blockingService).selectedAppsToBlock
        )
        .onChange(of: blockingService.selectedAppsToBlock) { _, _ in
            blockingService.saveSelection()
        }
        .onChange(of: selectedMode) { _, newMode in
            updateDurationForMode(newMode)
        }
        .onAppear {
            startAnimations()
            configureFromContext()
        }
    }

    // MARK: - Background

    private var timerSetupBackground: some View {
        ZStack {
            // Deep void
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()

            // Amber focus glow
            RadialGradient(
                colors: [
                    Theme.Colors.aiAmber.opacity(0.12),
                    Theme.Colors.aiOrange.opacity(0.06),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.25),
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
            .scaleEffect(pulseScale)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                HapticsService.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                    }
            }

            Spacer()

            Text("Focus Timer")
                .dynamicTypeFont(base: 17, weight: .semibold)
                .foregroundStyle(.white)

            Spacer()

            // Placeholder for balance
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Orbital Duration Picker

    private var orbitalDurationPicker: some View {
        ZStack {
            // Outer ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.aiAmber.opacity(0.2 * orbGlow),
                            Theme.Colors.aiAmber.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 30)

            // Orbital track (outer)
            orbitalTrack(radius: 140, opacity: 0.15)

            // Orbital track (inner)
            orbitalTrack(radius: 105, opacity: 0.1)

            // Rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Colors.aiAmber.opacity(0.8),
                            Theme.Colors.aiAmber.opacity(0.3),
                            .clear,
                            .clear,
                            Theme.Colors.aiAmber.opacity(0.3),
                            Theme.Colors.aiAmber.opacity(0.8)
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(ringRotation))

            // Time display
            timeDisplayView

            // Duration adjustment buttons
            durationAdjustmentButtons
        }
        .frame(height: 320)
    }

    private func orbitalTrack(radius: CGFloat, opacity: Double) -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(opacity),
                        .white.opacity(opacity * 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 1, dash: [4, 8])
            )
            .frame(width: radius * 2, height: radius * 2)
    }

    private var timeDisplayView: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Minutes display
            Text("\(selectedMinutes)")
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: selectedMinutes)

            Text("minutes")
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(2)
        }
    }

    private var durationAdjustmentButtons: some View {
        HStack(spacing: 200) {
            // Decrease button
            durationButton(icon: "minus", action: decreaseDuration)
                .offset(x: -10)

            // Increase button
            durationButton(icon: "plus", action: increaseDuration)
                .offset(x: 10)
        }
    }

    private func durationButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsService.shared.selectionFeedback()
            action()
        } label: {
            Image(systemName: icon)
                .dynamicTypeFont(base: 20, weight: .semibold)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Focus Mode")
                .dynamicTypeFont(base: 13, weight: .semibold)
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(FocusTimerMode.allCases, id: \.self) { mode in
                        FocusModeChip(
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
            }
            .scrollClipDisabled()
        }
    }

    // MARK: - Break Time Selector

    private var breakTimeSelector: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Break Time")
                    .dynamicTypeFont(base: 13, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Text("\(selectedBreakMinutes) min")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.aiCyan)
            }

            // Break time slider
            HStack(spacing: Theme.Spacing.md) {
                ForEach([5, 10, 15, 20], id: \.self) { minutes in
                    breakTimeChip(minutes: minutes)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }

    private func breakTimeChip(minutes: Int) -> some View {
        Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(.spring(response: 0.3)) {
                selectedBreakMinutes = minutes
            }
        } label: {
            Text("\(minutes)m")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(selectedBreakMinutes == minutes ? .white : .white.opacity(0.6))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background {
                    if selectedBreakMinutes == minutes {
                        Capsule()
                            .fill(Theme.Colors.aiCyan.opacity(0.3))
                    } else {
                        Capsule()
                            .fill(.white.opacity(0.05))
                    }
                }
                .overlay {
                    if selectedBreakMinutes == minutes {
                        Capsule()
                            .stroke(Theme.Colors.aiCyan.opacity(0.5), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Task Selection

    private var taskSelectionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Focus Tasks")
                    .dynamicTypeFont(base: 13, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Button {
                    showTaskPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 12, weight: .semibold)
                        Text("Add")
                            .dynamicTypeFont(base: 13, weight: .semibold)
                    }
                    .foregroundStyle(Theme.Colors.aiAmber)
                }
            }

            if selectedTasks.isEmpty && taskContext == nil {
                // Empty state
                HStack {
                    Image(systemName: "checkmark.circle.badge.plus")
                        .dynamicTypeFont(base: 24)
                        .foregroundStyle(.white.opacity(0.3))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No tasks selected")
                            .dynamicTypeFont(base: 14, weight: .medium)
                            .foregroundStyle(.white.opacity(0.6))

                        Text("Focus on anything, or add specific tasks")
                            .dynamicTypeFont(base: 12)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()
                }
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.03))
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
            } else {
                // Task list
                VStack(spacing: Theme.Spacing.xs) {
                    if let context = taskContext {
                        selectedTaskRow(task: context.task)
                    }

                    ForEach(selectedTasks) { task in
                        selectedTaskRow(task: task)
                    }
                }
            }
        }
    }

    private func selectedTaskRow(task: TaskItem) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(Theme.TaskCardColors.create.opacity(0.3))
                .frame(width: 8, height: 8)

            Text(task.title)
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            if taskContext?.task.id != task.id {
                Button {
                    selectedTasks.removeAll { $0.id == task.id }
                } label: {
                    Image(systemName: "xmark")
                        .dynamicTypeFont(base: 12, weight: .medium)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.05))
        }
    }

    // MARK: - App Blocking Section

    private var appBlockingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with toggle
            HStack {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "shield.lefthalf.filled")
                        .dynamicTypeFont(base: 18)
                        .foregroundStyle(enableAppBlocking ? Theme.Colors.aiCyan : .white.opacity(0.4))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Block Distracting Apps")
                            .dynamicTypeFont(base: 15, weight: .semibold)
                            .foregroundStyle(.white)

                        Text("Stay focused by blocking apps")
                            .dynamicTypeFont(base: 12)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                Toggle("", isOn: $enableAppBlocking)
                    .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.aiCyan))
                    .labelsHidden()
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        enableAppBlocking ? Theme.Colors.aiCyan.opacity(0.3) : .white.opacity(0.1),
                        lineWidth: 1
                    )
            }

            // App selection (when enabled)
            if enableAppBlocking {
                appBlockingContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: enableAppBlocking)
    }

    private var appBlockingContent: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if blockingService.isAuthorized {
                // Show current selection or add button
                if blockingService.hasAppsSelected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .dynamicTypeFont(base: 14)
                            .foregroundStyle(Theme.Colors.success)

                        Text(blockingService.selectionSummary)
                            .dynamicTypeFont(base: 14)
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        Button {
                            showAppBlockingPicker = true
                        } label: {
                            Text("Edit")
                                .dynamicTypeFont(base: 13, weight: .semibold)
                                .foregroundStyle(Theme.Colors.aiCyan)
                        }
                    }
                    .padding(Theme.Spacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.success.opacity(0.1))
                    }
                } else {
                    Button {
                        showAppBlockingPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.app.fill")
                                .dynamicTypeFont(base: 16)

                            Text("Select Apps to Block")
                                .dynamicTypeFont(base: 14, weight: .semibold)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .dynamicTypeFont(base: 12, weight: .semibold)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .foregroundStyle(Theme.Colors.aiCyan)
                        .padding(Theme.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.aiCyan.opacity(0.1))
                                .stroke(Theme.Colors.aiCyan.opacity(0.3), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Authorization required
                Button {
                    Task {
                        try? await blockingService.requestAuthorizationIfNeeded()
                    }
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.Colors.warning)

                        Text("Screen Time access required")
                            .dynamicTypeFont(base: 13)
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        Text("Enable")
                            .dynamicTypeFont(base: 13, weight: .semibold)
                            .foregroundStyle(Theme.Colors.aiCyan)
                    }
                    .padding(Theme.Spacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.warning.opacity(0.1))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            HapticsService.shared.success()
            startFocusSession()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "play.fill")
                    .dynamicTypeFont(base: 18)

                Text("Start Focus")
                    .dynamicTypeFont(base: 18, weight: .semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
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
            .shadow(color: Theme.Colors.aiAmber.opacity(0.4), radius: 20, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Actions

    private func increaseDuration() {
        let increments = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]
        if let currentIndex = increments.firstIndex(where: { $0 >= selectedMinutes }) {
            if currentIndex < increments.count - 1 {
                selectedMinutes = increments[currentIndex + 1]
            }
        } else {
            selectedMinutes = min(selectedMinutes + 5, 180)
        }
        selectedMode = .custom
    }

    private func decreaseDuration() {
        let increments = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]
        if let currentIndex = increments.lastIndex(where: { $0 <= selectedMinutes }) {
            if currentIndex > 0 {
                selectedMinutes = increments[currentIndex - 1]
            }
        } else {
            selectedMinutes = max(selectedMinutes - 5, 5)
        }
        selectedMode = .custom
    }

    private func updateDurationForMode(_ mode: FocusTimerMode) {
        switch mode {
        case .pomodoro:
            selectedMinutes = 25
            selectedBreakMinutes = 5
        case .deepWork:
            selectedMinutes = 90
            selectedBreakMinutes = 20
        case .flowState:
            selectedMinutes = 60
            selectedBreakMinutes = 10
        case .custom:
            break // Keep current
        }
    }

    private func configureFromContext() {
        if let context = taskContext {
            selectedMinutes = context.suggestedDuration
            enableAppBlocking = context.enableAppBlocking
            selectedMode = .custom
        }
    }

    private func startFocusSession() {
        let session = FocusSession(
            duration: selectedMinutes * 60,
            breakDuration: selectedBreakMinutes * 60,
            mode: selectedMode,
            tasks: taskContext != nil ? [taskContext!.task] : selectedTasks,
            enableAppBlocking: enableAppBlocking && blockingService.hasAppsSelected
        )

        onStartSession?(session)
        dismiss()
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
            orbGlow = 0.8
        }
    }
}

// MARK: - Focus Mode Chip

struct FocusModeChip: View {
    let mode: FocusTimerMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))

                Text(mode.rawValue)
                    .dynamicTypeFont(base: 12, weight: .semibold)

                Text(mode.durationLabel)
                    .dynamicTypeFont(base: 10)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .frame(width: 80, height: 80)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Theme.Colors.aiAmber.opacity(0.25) : .white.opacity(0.05))
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.Colors.aiAmber, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Focus Session Model

struct FocusSession {
    let id = UUID()
    let duration: Int // seconds
    let breakDuration: Int // seconds
    let mode: FocusTimerMode
    let tasks: [TaskItem]
    let enableAppBlocking: Bool
    let startedAt = Date()

    init(
        duration: Int = 25 * 60,
        breakDuration: Int = 5 * 60,
        mode: FocusTimerMode = .pomodoro,
        tasks: [TaskItem] = [],
        enableAppBlocking: Bool = false
    ) {
        self.duration = duration
        self.breakDuration = breakDuration
        self.mode = mode
        self.tasks = tasks
        self.enableAppBlocking = enableAppBlocking
    }
}

// MARK: - Extensions

extension FocusTimerMode {
    var durationLabel: String {
        switch self {
        case .pomodoro: return "25 min"
        case .deepWork: return "90 min"
        case .flowState: return "∞"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Preview

#Preview {
    FocusTimerSetupView()
}
