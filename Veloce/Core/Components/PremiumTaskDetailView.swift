//
//  PremiumTaskDetailView.swift
//  Veloce
//
//  Premium Full-Screen Task Detail View
//  Celestial Observatory aesthetic - cosmic dark theme with glass morphism
//

import SwiftUI

// MARK: - Premium Task Detail View

struct PremiumTaskDetailView: View {
    let task: TaskItem
    @Bindable var viewModel: ChatTasksViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State
    @State private var appeared = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    // Editing states
    @State private var editableTitle: String = ""
    @State private var contextNotes: String = ""
    @State private var selectedDuration: Int? = nil
    @State private var customDurationText: String = ""
    @State private var showCustomDuration = false

    // AI states
    @State private var isLoadingAI = false
    @State private var aiDebounceTask: Task<Void, Never>?
    @State private var chatMessages: [PremiumChatMessage] = []

    // Sub-task states
    @State private var subTasks: [SubTask] = []
    @State private var youtubeResources: [YouTubeResource] = []
    @State private var scheduleSuggestion: ScheduleSuggestion?

    // Recurring states
    @State private var recurringType: RecurringTypeExtended = .once
    @State private var recurringCustomDays: Set<Int> = []
    @State private var recurringEndDate: Date?

    // Schedule states
    @State private var showSchedulePicker = false
    @State private var selectedScheduleDate: Date = Date()

    // Focus mode
    @State private var showFocusMode = false

    // Pomodoro
    @State private var pomodoroService = PomodoroTimerService.shared

    // Animation timing
    private let cardAnimationDelay: Double = 0.05

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - Background
                celestialBackground

                // MARK: - Main Content
                VStack(spacing: 0) {
                    // Custom navigation bar
                    navigationBar
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -20)

                    // Scrollable content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // All feature cards with staggered animations
                            Group {
                                titleCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 1)

                                durationPickerCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 2)

                                contextInputCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 3)

                                pomodoroCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 4)

                                aiInsightCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 5)
                            }

                            Group {
                                aiChatCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 6)

                                subTasksCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 7)

                                youtubeResourcesCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 8)

                                scheduleCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 9)

                                recurringCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 10)

                                actionsCard
                                    .cardAnimation(appeared: appeared, delay: cardAnimationDelay * 11)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
                .offset(y: dragOffset)
            }
            .gesture(dragDismissGesture)
        }
        .ignoresSafeArea()
        .onAppear {
            initializeStates()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            HapticsService.shared.lightImpact()
        }
        .task {
            await loadAIContent()
        }
        .sheet(isPresented: $showSchedulePicker) {
            schedulePickerSheet
        }
        .fullScreenCover(isPresented: $showFocusMode) {
            FocusTimerSetupView(
                taskContext: FocusTaskContext(task: task),
                onStartSession: { _ in }
            )
        }
        .sheet(isPresented: $showCustomDuration) {
            customDurationSheet
        }
    }

    // MARK: - Celestial Background

    private var celestialBackground: some View {
        ZStack {
            // Deep void base
            Color.black

            // Nebula gradient overlay
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.02, blue: 0.15).opacity(0.8),
                    Color.black,
                    Color(red: 0.02, green: 0.05, blue: 0.12).opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle aurora effect
            RadialGradient(
                colors: [
                    Theme.Colors.aiPurple.opacity(0.08),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 400
            )

            // Secondary glow
            RadialGradient(
                colors: [
                    Theme.Colors.aiBlue.opacity(0.05),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 50,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 16) {
            // Close button
            Button {
                HapticsService.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(
                        SwiftUI.Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        SwiftUI.Circle()
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            // Completion indicator
            completionIndicator

            Spacer()

            // Options menu
            Menu {
                Button {
                    viewModel.duplicateTask(task)
                    HapticsService.shared.softImpact()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }

                Button {
                    viewModel.snoozeTask(task)
                    HapticsService.shared.softImpact()
                } label: {
                    Label("Snooze", systemImage: "clock.arrow.circlepath")
                }

                Divider()

                Button(role: .destructive) {
                    viewModel.deleteTask(task)
                    HapticsService.shared.warning()
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(
                        SwiftUI.Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        SwiftUI.Circle()
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 8)
    }

    // MARK: - Completion Indicator

    private var completionIndicator: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                viewModel.toggleCompletion(task)
            }
            HapticsService.shared.impact()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    SwiftUI.Circle()
                        .strokeBorder(
                            task.isCompleted ? Theme.Colors.success : .white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if task.isCompleted {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .dynamicTypeFont(base: 12, weight: .bold)
                            .foregroundStyle(.white)
                    }
                }

                Text(task.isCompleted ? "Completed" : "Mark Complete")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(task.isCompleted ? Theme.Colors.success : .white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        task.isCompleted ? Theme.Colors.success.opacity(0.3) : .white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Title Card

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Editable title
            HStack(spacing: 14) {
                // Completion checkbox
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.toggleCompletion(task)
                    }
                    HapticsService.shared.impact()
                } label: {
                    ZStack {
                        SwiftUI.Circle()
                            .strokeBorder(
                                task.isCompleted ? Theme.Colors.success : Theme.Colors.textTertiary,
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if task.isCompleted {
                            SwiftUI.Circle()
                                .fill(Theme.Colors.success)
                                .frame(width: 28, height: 28)

                            Image(systemName: "checkmark")
                                .dynamicTypeFont(base: 14, weight: .bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Title TextField
                TextField("Task title", text: $editableTitle, axis: .vertical)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(task.isCompleted ? Theme.Colors.textTertiary : .white)
                    .strikethrough(task.isCompleted, color: Theme.Colors.textTertiary)
                    .onChange(of: editableTitle) { _, newValue in
                        task.title = newValue
                        task.updatedAt = Date()
                    }
                    .submitLabel(.done)
            }

            // Priority stars
            priorityPicker
        }
        .padding(20)
        .glassCard(accent: nil)
    }

    // MARK: - Priority Picker

    private var priorityPicker: some View {
        HStack(spacing: 12) {
            Text("Priority")
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: 8) {
                ForEach([1, 2, 3], id: \.self) { stars in
                    Button {
                        task.starRating = stars
                        task.updatedAt = Date()
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        HStack(spacing: 2) {
                            ForEach(0..<stars, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .dynamicTypeFont(base: 12)
                            }
                        }
                        .foregroundStyle(task.starRating == stars ? Theme.Colors.warning : Theme.Colors.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(task.starRating == stars ? Theme.Colors.warning.opacity(0.15) : .white.opacity(0.05))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    task.starRating == stars ? Theme.Colors.warning.opacity(0.3) : .clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
    }

    // MARK: - Duration Picker Card

    private var durationPickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.aiBlue)

                Text("Duration")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                if let duration = task.duration ?? selectedDuration {
                    Text(formatDuration(duration))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.aiBlue)
                }
            }

            // Preset buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach([15, 30, 60, 120, 240], id: \.self) { mins in
                        DurationPresetButton(
                            minutes: mins,
                            isSelected: (task.duration ?? selectedDuration) == mins,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedDuration = mins
                                    task.duration = mins
                                    task.updatedAt = Date()
                                }
                                HapticsService.shared.selectionFeedback()
                            }
                        )
                    }

                    // Custom button
                    Button {
                        showCustomDuration = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .dynamicTypeFont(base: 12, weight: .semibold)
                            Text("Custom")
                                .dynamicTypeFont(base: 13, weight: .medium)
                        }
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .glassCard(accent: Theme.Colors.aiBlue.opacity(0.05))
    }

    // MARK: - Context Input Card

    private var contextInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "text.alignleft")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.accent)

                Text("Context")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                if isLoadingAI {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Theme.Colors.aiPurple)
                }
            }

            // Context text editor
            TextEditor(text: $contextNotes)
                .dynamicTypeFont(base: 14)
                .foregroundStyle(.white.opacity(0.9))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
                .onChange(of: contextNotes) { _, newValue in
                    task.contextNotes = newValue
                    task.updatedAt = Date()
                    debounceAIRegeneration()
                }

            // Helper text
            Text("Add details to get better AI suggestions")
                .dynamicTypeFont(base: 12)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(20)
        .glassCard(accent: Theme.Colors.accent.opacity(0.05))
    }

    // MARK: - Pomodoro Card

    private var pomodoroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.destructive)

                Text("Focus Timer")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                if pomodoroService.isRunning {
                    Text(pomodoroService.currentSession?.formattedTime ?? "")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.destructive)
                }
            }

            // Timer controls
            HStack(spacing: 12) {
                // Quick start buttons
                ForEach([15, 25, 45], id: \.self) { mins in
                    Button {
                        pomodoroService.startSession(
                            taskId: task.id,
                            taskTitle: task.title,
                            duration: mins * 60
                        )
                        HapticsService.shared.impact()
                    } label: {
                        Text("\(mins)m")
                            .dynamicTypeFont(base: 14, weight: .semibold)
                            .foregroundStyle(pomodoroService.isRunning ? Theme.Colors.textTertiary : .white)
                            .frame(width: 50, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(pomodoroService.isRunning)
                }

                Spacer()

                // Full focus mode button
                Button {
                    showFocusMode = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .dynamicTypeFont(base: 14)
                        Text("Focus Mode")
                            .dynamicTypeFont(base: 13, weight: .medium)
                    }
                    .foregroundStyle(Theme.Colors.destructive)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.destructive.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .glassCard(accent: Theme.Colors.destructive.opacity(0.05))
    }

    // MARK: - AI Insight Card

    private var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.3))

                Text("AI Insight")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                // Refresh button
                Button {
                    Task { await loadAIContent() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(Theme.Colors.aiBlue)
                        .rotationEffect(.degrees(isLoadingAI ? 360 : 0))
                        .animation(isLoadingAI ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingAI)
                }
                .buttonStyle(.plain)
            }

            // Content
            if isLoadingAI {
                // Shimmer loading
                ShimmerView()
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let advice = task.aiAdvice {
                Text(advice)
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Metadata pills
                HStack(spacing: 8) {
                    if let minutes = task.estimatedMinutes {
                        MetadataPill(
                            icon: "clock.fill",
                            text: formatDuration(minutes),
                            color: Theme.Colors.aiBlue
                        )
                    }

                    if let priority = task.aiPriority {
                        MetadataPill(
                            icon: priorityIcon(for: priority),
                            text: priority.capitalized,
                            color: priorityColor(for: priority)
                        )
                    }
                }
            } else {
                // Empty state
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text("Tap refresh to generate AI insights")
                        .dynamicTypeFont(base: 13)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .glassCard(accent: Theme.Colors.aiPurple.opacity(0.05))
    }

    // MARK: - AI Chat Card

    private var aiChatCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("Ask AI")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()
            }

            // Quick suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    QuickSuggestionChip(text: "How do I start?") {
                        sendChatMessage("How do I start this task?")
                    }
                    QuickSuggestionChip(text: "Break it down") {
                        sendChatMessage("Can you break down this task into smaller steps?")
                    }
                    QuickSuggestionChip(text: "Why important?") {
                        sendChatMessage("Why is this task important?")
                    }
                }
            }

            // Chat messages (last 3)
            if !chatMessages.isEmpty {
                VStack(spacing: 8) {
                    ForEach(chatMessages.suffix(3)) { message in
                        PremiumChatMessageBubble(message: message)
                    }
                }
            }
        }
        .padding(20)
        .glassCard(accent: Theme.Colors.aiPurple.opacity(0.05))
    }

    // MARK: - Sub-Tasks Card

    private var subTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with progress
            HStack {
                Image(systemName: "checklist")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.success)

                Text("Sub-Tasks")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                if !subTasks.isEmpty {
                    let completed = subTasks.filter { $0.status == .completed }.count
                    Text("\(completed)/\(subTasks.count)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.success)
                }
            }

            // Sub-task list
            if subTasks.isEmpty {
                // Empty state with generate button
                Button {
                    generateSubTasks()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate sub-tasks with AI")
                            .dynamicTypeFont(base: 14, weight: .medium)
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.aiPurple.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 8) {
                    ForEach(subTasks) { subtask in
                        PremiumSubTaskRow(
                            subtask: subtask,
                            onToggle: {
                                toggleSubTask(subtask)
                            }
                        )
                    }
                }

                // Progress bar
                ProgressView(value: Double(subTasks.filter { $0.status == .completed }.count), total: Double(subTasks.count))
                    .tint(Theme.Colors.success)
            }
        }
        .padding(20)
        .glassCard(accent: Theme.Colors.success.opacity(0.05))
    }

    // MARK: - YouTube Resources Card

    private var youtubeResourcesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(.red)

                Text("Learning Resources")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    loadYouTubeResources()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .dynamicTypeFont(base: 14, weight: .medium)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            if youtubeResources.isEmpty {
                // Empty state
                Button {
                    loadYouTubeResources()
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Find learning resources")
                            .dynamicTypeFont(base: 14, weight: .medium)
                    }
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.red.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 10) {
                    ForEach(youtubeResources.prefix(3)) { resource in
                        PremiumYouTubeResourceRow(resource: resource)
                    }
                }
            }
        }
        .padding(20)
        .glassCard(accent: Color.red.opacity(0.05))
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.accent)

                Text("Schedule")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()
            }

            if let scheduledTime = task.scheduledTime {
                // Scheduled info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scheduledTime.formatted(date: .abbreviated, time: .omitted))
                            .dynamicTypeFont(base: 15, weight: .medium)
                            .foregroundStyle(.white)

                        Text(scheduledTime.formatted(date: .omitted, time: .shortened))
                            .dynamicTypeFont(base: 13)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    Button("Change") {
                        selectedScheduleDate = scheduledTime
                        showSchedulePicker = true
                    }
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.accent)
                }
            } else {
                // Quick schedule buttons
                HStack(spacing: 10) {
                    QuickScheduleButton(title: "Today", date: Date()) { date in
                        scheduleTask(for: date)
                    }
                    QuickScheduleButton(title: "Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) { date in
                        scheduleTask(for: date)
                    }
                    QuickScheduleButton(title: "Next Week", date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!) { date in
                        scheduleTask(for: date)
                    }

                    Spacer()

                    Button {
                        showSchedulePicker = true
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .dynamicTypeFont(base: 18)
                            .foregroundStyle(Theme.Colors.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .glassCard(accent: Theme.Colors.accent.opacity(0.05))
    }

    // MARK: - Recurring Card

    private var recurringCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "repeat")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.accent)

                Text("Repeat")
                    .dynamicTypeFont(base: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                if task.isRecurring {
                    RecurringBadge(type: task.recurringExtended)
                }
            }

            // Type selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RecurringTypeExtended.allCases, id: \.self) { type in
                        RecurringTypeButton(
                            type: type,
                            isSelected: recurringType == type,
                            onSelect: {
                                recurringType = type
                                task.setRecurringExtended(
                                    type: type,
                                    customDays: recurringCustomDays.isEmpty ? nil : recurringCustomDays,
                                    endDate: recurringEndDate
                                )
                                HapticsService.shared.selectionFeedback()
                            }
                        )
                    }
                }
            }
        }
        .padding(20)
        .glassCard(accent: Theme.Colors.accent.opacity(0.05))
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        HStack(spacing: 0) {
            ActionButton(icon: "doc.on.doc", title: "Duplicate", color: Theme.Colors.textPrimary) {
                viewModel.duplicateTask(task)
                HapticsService.shared.softImpact()
            }

            Divider()
                .frame(height: 40)

            ActionButton(icon: "clock.arrow.circlepath", title: "Snooze", color: Theme.Colors.textPrimary) {
                viewModel.snoozeTask(task)
                HapticsService.shared.softImpact()
            }

            Divider()
                .frame(height: 40)

            ActionButton(icon: "trash", title: "Delete", color: Theme.Colors.destructive) {
                viewModel.deleteTask(task)
                HapticsService.shared.warning()
                dismiss()
            }
        }
        .padding(.vertical, 4)
        .glassCard(accent: nil)
    }

    // MARK: - Schedule Picker Sheet

    private var schedulePickerSheet: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("Cancel") {
                    showSchedulePicker = false
                }
                .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Text("Schedule Task")
                    .dynamicTypeFont(base: 17, weight: .semibold)

                Spacer()

                Button("Done") {
                    scheduleTask(for: selectedScheduleDate)
                    showSchedulePicker = false
                }
                .foregroundStyle(Theme.Colors.accent)
                .fontWeight(.semibold)
            }
            .padding(.top, 8)

            DatePicker(
                "Select date and time",
                selection: $selectedScheduleDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .tint(Theme.Colors.accent)

            Spacer()
        }
        .padding(20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Custom Duration Sheet

    private var customDurationSheet: some View {
        VStack(spacing: 24) {
            Text("Set Duration")
                .dynamicTypeFont(base: 20, weight: .semibold)

            HStack(spacing: 16) {
                TextField("Minutes", text: $customDurationText)
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 120)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )

                Text("minutes")
                    .dynamicTypeFont(base: 18)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Button("Set Duration") {
                if let mins = Int(customDurationText), mins > 0 {
                    selectedDuration = mins
                    task.duration = mins
                    task.updatedAt = Date()
                    HapticsService.shared.impact()
                }
                showCustomDuration = false
            }
            .dynamicTypeFont(base: 17, weight: .semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.accent)
            )

            Spacer()
        }
        .padding(24)
        .presentationDetents([.height(300)])
    }

    // MARK: - Drag Dismiss Gesture

    private var dragDismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                    isDragging = true
                }
            }
            .onEnded { value in
                isDragging = false
                if value.translation.height > 150 || value.velocity.height > 1000 {
                    HapticsService.shared.lightImpact()
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Helper Methods

    private func initializeStates() {
        editableTitle = task.title
        contextNotes = task.contextNotes ?? ""
        selectedDuration = task.duration
        recurringType = task.recurringExtended
        if let days = task.recurringDays {
            recurringCustomDays = Set(days)
        }
        recurringEndDate = task.recurringEndDate
    }

    private func loadAIContent() async {
        guard !isLoadingAI else { return }
        isLoadingAI = true

        // Simulate AI loading (replace with actual PerplexityService call)
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Load sub-tasks
        generateSubTasks()

        isLoadingAI = false
    }

    private func debounceAIRegeneration() {
        aiDebounceTask?.cancel()
        aiDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second debounce
            if !Task.isCancelled {
                await loadAIContent()
            }
        }
    }

    private func generateSubTasks() {
        let taskWords = task.title.lowercased()

        if taskWords.contains("report") || taskWords.contains("presentation") {
            subTasks = [
                SubTask(title: "Research and gather data", estimatedMinutes: 15, status: .pending, orderIndex: 1),
                SubTask(title: "Create outline/structure", estimatedMinutes: 10, status: .pending, orderIndex: 2),
                SubTask(title: "Write main content", estimatedMinutes: 25, status: .pending, orderIndex: 3),
                SubTask(title: "Add visuals/formatting", estimatedMinutes: 15, status: .pending, orderIndex: 4),
                SubTask(title: "Review and polish", estimatedMinutes: 10, status: .pending, orderIndex: 5)
            ]
        } else {
            subTasks = [
                SubTask(title: "Define clear objectives", estimatedMinutes: 5, status: .pending, orderIndex: 1),
                SubTask(title: "Break into actionable steps", estimatedMinutes: 10, status: .pending, orderIndex: 2),
                SubTask(title: "Execute main work", estimatedMinutes: 20, status: .pending, orderIndex: 3),
                SubTask(title: "Review and complete", estimatedMinutes: 10, status: .pending, orderIndex: 4)
            ]
        }
    }

    private func toggleSubTask(_ subtask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == subtask.id }) {
            var updated = subTasks[index]
            updated.status = updated.status == .completed ? .pending : .completed
            subTasks[index] = updated
            HapticsService.shared.selectionFeedback()
        }
    }

    private func loadYouTubeResources() {
        // Placeholder - integrate with PerplexityService
        youtubeResources = []
    }

    private func sendChatMessage(_ message: String) {
        let userMessage = PremiumChatMessage(role: .user, content: message)
        chatMessages.append(userMessage)

        // Simulate AI response
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            let aiResponse = PremiumChatMessage(role: .assistant, content: "I'll help you with that! Based on your task '\(task.title)', here's my suggestion...")
            chatMessages.append(aiResponse)
        }
    }

    private func scheduleTask(for date: Date) {
        task.scheduledTime = date
        task.updatedAt = Date()
        HapticsService.shared.softImpact()
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func priorityIcon(for priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "minus.circle.fill"
        case "low": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }

    private func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return Theme.Colors.destructive
        case "medium": return Theme.Colors.warning
        case "low": return Theme.Colors.success
        default: return Theme.Colors.textTertiary
        }
    }
}

// MARK: - Supporting Components

struct DurationPresetButton: View {
    let minutes: Int
    let isSelected: Bool
    let onSelect: () -> Void

    private var label: String {
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }

    var body: some View {
        Button(action: onSelect) {
            Text(label)
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.aiBlue : .white.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Theme.Colors.aiBlue.opacity(0.5) : .clear, lineWidth: 1)
                )
                .shadow(color: isSelected ? Theme.Colors.aiBlue.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}

struct QuickSuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(Theme.Colors.aiPurple)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Theme.Colors.aiPurple.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}

struct PremiumChatMessageBubble: View {
    let message: PremiumChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            Text(message.content)
                .dynamicTypeFont(base: 13)
                .foregroundStyle(message.role == .user ? .white : Theme.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.role == .user ? Theme.Colors.aiPurple : .white.opacity(0.08))
                )

            if message.role == .assistant { Spacer() }
        }
    }
}

struct PremiumSubTaskRow: View {
    let subtask: SubTask
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    SwiftUI.Circle()
                        .strokeBorder(
                            subtask.status == .completed ? Theme.Colors.success : Theme.Colors.textTertiary,
                            lineWidth: 1.5
                        )
                        .frame(width: 20, height: 20)

                    if subtask.status == .completed {
                        SwiftUI.Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 20, height: 20)

                        Image(systemName: "checkmark")
                            .dynamicTypeFont(base: 10, weight: .bold)
                            .foregroundStyle(.white)
                    }
                }

                // Title
                Text(subtask.title)
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(subtask.status == .completed ? Theme.Colors.textTertiary : .white)
                    .strikethrough(subtask.status == .completed, color: Theme.Colors.textTertiary)

                Spacer()

                // Time estimate
                if let mins = subtask.estimatedMinutes {
                    Text("\(mins)m")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct PremiumYouTubeResourceRow: View {
    let resource: YouTubeResource

    var body: some View {
        Group {
            if let url = resource.watchURL {
                Link(destination: url) {
                    rowContent
                }
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(.red.opacity(0.2))
                .frame(width: 80, height: 45)
                .overlay(
                    Image(systemName: "play.fill")
                        .foregroundStyle(.red)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .dynamicTypeFont(base: 13, weight: .medium)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let channelName = resource.channelName {
                    Text(channelName)
                        .dynamicTypeFont(base: 11)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .dynamicTypeFont(base: 12)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.05))
        )
    }
}

struct QuickScheduleButton: View {
    let title: String
    let date: Date
    let onSelect: (Date) -> Void

    var body: some View {
        Button {
            onSelect(date)
        } label: {
            Text(title)
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }
}

struct RecurringTypeButton: View {
    let type: RecurringTypeExtended
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(type.displayName)
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.accent : .white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }
}

struct ShimmerView: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.white.opacity(0.05))
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.1),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}

// MARK: - Card Animation Modifier

extension View {
    func cardAnimation(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: appeared)
    }

    fileprivate func premiumGlassCard(accent: Color?) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(accent ?? .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - Premium Chat Message Model

struct PremiumChatMessage: Identifiable {
    let id = UUID()
    let role: PremiumChatRole
    let content: String

    enum PremiumChatRole {
        case user
        case assistant
    }
}

// MARK: - Preview

#Preview {
    let task = TaskItem(title: "Complete quarterly presentation")
    task.aiAdvice = "Focus on key metrics and use visuals for impact. Schedule this for morning when you're most alert."
    task.estimatedMinutes = 60
    task.aiPriority = "high"

    return PremiumTaskDetailView(
        task: task,
        viewModel: ChatTasksViewModel()
    )
}
