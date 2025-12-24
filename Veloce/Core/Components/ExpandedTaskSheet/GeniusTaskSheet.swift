//
//  GeniusTaskSheet.swift
//  MyTasksAI
//
//  Slidable bottom sheet with all 7 genius modules
//  Coexists with TaskDetailSheet - this is for quick AI insights
//  TaskDetailSheet is for full editing
//

import SwiftUI

// MARK: - Genius Task Sheet

struct GeniusTaskSheet: View {
    let task: TaskItem
    @Binding var isPresented: Bool
    let onEditTapped: () -> Void

    @State private var viewModel = GeniusSheetViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var moduleAppearances: [Bool] = Array(repeating: false, count: 7)
    @State private var showFocusMode = false
    @State private var showCalendarScheduling = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var taskTypeColor: Color {
        switch task.taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    private var showEmotionalCheckIn: Bool {
        (task.timesRescheduled ?? 0) >= 2 || task.emotionalBlocker != nil
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                sheetContent
                    .frame(maxHeight: geometry.size.height * 0.85)
                    .offset(y: dragOffset)
                    .gesture(dragGesture)
            }
        }
        .background(
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
        )
        .task {
            await viewModel.loadData(for: task)
            animateModulesIn()
        }
        .fullScreenCover(isPresented: $showFocusMode) {
            FocusMode(task: task)
        }
        .sheet(isPresented: $showCalendarScheduling) {
            CalendarSchedulingSheet(task: task)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Sheet Content

    private var sheetContent: some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandle

            // Header
            sheetHeader

            // Scrollable modules
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Module 1: Emotional Check-In (conditional)
                    if showEmotionalCheckIn {
                        EmotionalCheckInModule(
                            task: task,
                            viewModel: viewModel
                        )
                        .opacity(moduleAppearances[0] ? 1 : 0)
                        .offset(y: moduleAppearances[0] ? 0 : 20)
                    }

                    // Module 2: START HERE
                    StartHereModule(
                        task: task,
                        viewModel: viewModel
                    )
                    .opacity(moduleAppearances[1] ? 1 : 0)
                    .offset(y: moduleAppearances[1] ? 0 : 20)

                    // Module 3: AI Strategy
                    AIStrategyModule(
                        task: task,
                        viewModel: viewModel
                    )
                    .opacity(moduleAppearances[2] ? 1 : 0)
                    .offset(y: moduleAppearances[2] ? 0 : 20)

                    // Module 4: Resources
                    ResourcesModule(
                        resources: viewModel.aiResources
                    )
                    .opacity(moduleAppearances[3] ? 1 : 0)
                    .offset(y: moduleAppearances[3] ? 0 : 20)

                    // Module 5: Smart Schedule
                    SmartScheduleModule(
                        task: task,
                        viewModel: viewModel,
                        onAddToCalendar: { showCalendarScheduling = true }
                    )
                    .opacity(moduleAppearances[4] ? 1 : 0)
                    .offset(y: moduleAppearances[4] ? 0 : 20)

                    // Module 6: Work Mode
                    WorkModeModule(
                        task: task,
                        viewModel: viewModel,
                        onStartFocus: { showFocusMode = true }
                    )
                    .opacity(moduleAppearances[5] ? 1 : 0)
                    .offset(y: moduleAppearances[5] ? 0 : 20)

                    // Module 7: AI Chat
                    AIChatModule(
                        task: task,
                        viewModel: viewModel
                    )
                    .opacity(moduleAppearances[6] ? 1 : 0)
                    .offset(y: moduleAppearances[6] ? 0 : 20)

                    // Full Details button
                    fullDetailsButton
                        .padding(.top, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.xl)
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
                .padding(.top, Theme.Spacing.md)
            }
        }
        .background(sheetBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                // Task type badge
                HStack(spacing: 4) {
                    Image(systemName: task.taskType.icon)
                        .font(.system(size: 12, weight: .medium))
                    Text(task.taskType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(taskTypeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(taskTypeColor.opacity(0.15))
                )

                Spacer()

                // Edit button
                Button {
                    onEditTapped()
                } label: {
                    Text("Edit")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiBlue)
                }
            }

            // Task title
            Text(task.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Quick stats
            HStack(spacing: Theme.Spacing.md) {
                if let estimate = task.estimatedTimeFormatted {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(estimate)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }

                Text(task.priorityStars)
                    .font(.system(size: 14))
                    .foregroundStyle(task.priority.color)

                if task.hasAIProcessing {
                    AIBadgeAnimated(isProcessing: false)
                }

                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Sheet Background

    private var sheetBackground: some View {
        ZStack {
            // Base dark
            Color.black.opacity(0.95)

            // Gradient accent from task type
            LinearGradient(
                colors: [
                    taskTypeColor.opacity(0.15),
                    taskTypeColor.opacity(0.05),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Glass effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        }
    }

    // MARK: - Full Details Button

    private var fullDetailsButton: some View {
        Button {
            onEditTapped()
        } label: {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("Full Details")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Theme.Colors.glassBorder.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > 100 || value.velocity.height > 500 {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Animation

    private func animateModulesIn() {
        guard !reduceMotion else {
            moduleAppearances = Array(repeating: true, count: 7)
            return
        }

        for i in 0..<7 {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Theme.GeniusAnimation.moduleStagger * Double(i)
            ) {
                withAnimation(Theme.GeniusAnimation.sheetSpring) {
                    moduleAppearances[i] = true
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - Genius Sheet ViewModel

@Observable
class GeniusSheetViewModel {
    // Emotional Check-In
    var selectedEmotion: Emotion?
    var emotionResponse: String?
    var showEmotionalCheckIn: Bool = false

    // Start Here
    var firstStepTitle: String = "Open a new document and write just the title"
    var firstStepSeconds: Int = 30
    var isChallengeActive: Bool = false
    var countdown: Int = 30
    var challengeCompleted: Bool = false

    // AI Strategy
    var aiStrategy: String?
    var strategySource: String?
    var isStrategyExpanded: Bool = false
    var isStrategyLoading: Bool = false

    // Resources
    var aiResources: [TaskResource] = []

    // Schedule
    var scheduleSuggestions: [GeniusScheduleSuggestion] = []
    var userPeakHours: String = "9-11 AM"

    // Work Mode
    var suggestedWorkMode: WorkMode = .deepWork
    var workModeReason: String = ""
    var selectedWorkMode: WorkMode?
    var isTimerActive: Bool = false

    // Chat
    var chatInput: String = ""
    var chatMessages: [ChatMessage] = []
    var isAIThinking: Bool = false

    // AI Breakdown (for ExecutionSteps module)
    var aiBreakdown: [ExecutionStep] = []

    func loadData(for task: TaskItem) async {
        // Check if emotional check-in needed
        showEmotionalCheckIn = (task.timesRescheduled ?? 0) >= 2

        // Load AI strategy
        isStrategyLoading = true
        aiStrategy = task.aiAdvice ?? task.aiThoughtProcess
        strategySource = "Productivity Research"
        isStrategyLoading = false

        // Generate first step
        firstStepTitle = "Open a new document and write just the title"
        firstStepSeconds = 30

        // Set work mode recommendation
        if task.taskType == .create {
            suggestedWorkMode = .deepWork
            workModeReason = "Creative tasks need uninterrupted flow. Pomodoro breaks would fragment your thinking."
        } else {
            suggestedWorkMode = .pomodoro
            workModeReason = "This task is well-suited for focused sprints with short breaks."
        }
        selectedWorkMode = suggestedWorkMode
    }

    func selectEmotion(_ emotion: Emotion) {
        selectedEmotion = emotion

        // Generate compassionate response based on emotion
        switch emotion {
        case .anxious:
            emotionResponse = "I hear you. Anxiety often protects us from failure—but it can also hold us back. Let's shrink this down to something so tiny your brain won't see it as a threat."
        case .overwhelmed:
            emotionResponse = "When something feels too big, our brain protects us by avoiding it. That's completely normal. Let's break this into a 30-second action."
        case .unmotivated:
            emotionResponse = "Here's a secret: motivation comes AFTER starting, not before. You just need to do the tiniest thing to get momentum going."
        case .ready:
            emotionResponse = "Excellent! Let's channel that energy. Your first step is waiting for you below."
        }
    }

    func startMicroChallenge() {
        isChallengeActive = true
        countdown = firstStepSeconds

        // Start countdown
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.countdown > 0 {
                self.countdown -= 1

                // Haptic at 3, 2, 1
                if self.countdown <= 3 && self.countdown > 0 {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            } else {
                timer.invalidate()
                self.completeMicroChallenge()
            }
        }
    }

    func completeMicroChallenge() {
        isChallengeActive = false
        challengeCompleted = true

        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func sendChatMessage(_ message: String) async {
        guard !message.isEmpty else { return }

        // Add user message
        chatMessages.append(ChatMessage(role: .user, content: message))
        chatInput = ""
        isAIThinking = true

        // Simulate AI response (would connect to GeminiService)
        try? await Task.sleep(for: .seconds(1.5))

        isAIThinking = false
        chatMessages.append(ChatMessage(
            role: .assistant,
            content: "Based on your task, I'd suggest starting with the smallest possible action. Would you like me to break this down further?"
        ))
    }

    func toggleStepCompletion(_ step: ExecutionStep) {
        if let index = aiBreakdown.firstIndex(where: { $0.id == step.id }) {
            aiBreakdown[index].isCompleted.toggle()
        }
    }
}

// MARK: - Supporting Types

enum Emotion: String, CaseIterable {
    case anxious = "Anxious"
    case overwhelmed = "Overwhelmed"
    case unmotivated = "Unmotivated"
    case ready = "Ready"

    var emoji: String {
        switch self {
        case .anxious: return "😰"
        case .overwhelmed: return "🤯"
        case .unmotivated: return "😴"
        case .ready: return "🙂"
        }
    }
}

enum WorkMode: String, CaseIterable {
    case deepWork = "Deep Work"
    case pomodoro = "Pomodoro"
    case flowState = "Flow State"

    var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .pomodoro: return "timer"
        case .flowState: return "waveform.path.ecg"
        }
    }

    var duration: String {
        switch self {
        case .deepWork: return "90 min"
        case .pomodoro: return "25 min"
        case .flowState: return "No limit"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String

    enum ChatRole {
        case user
        case assistant
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        GeniusTaskSheet(
            task: {
                let task = TaskItem(title: "Write quarterly business report")
                task.starRating = 3
                task.estimatedMinutes = 60
                task.taskTypeRaw = TaskType.create.rawValue
                task.aiAdvice = "Focus on key metrics and actionable insights."
                task.timesRescheduled = 3
                return task
            }(),
            isPresented: .constant(true),
            onEditTapped: {}
        )
    }
}
