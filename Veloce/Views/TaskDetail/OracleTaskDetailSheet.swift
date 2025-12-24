//
//  OracleTaskDetailSheet.swift
//  Veloce
//
//  The AI Oracle Experience - Consulting an intelligent cosmic guide
//  Mystical, premium, and deeply insightful task command center
//

import SwiftUI

// MARK: - Oracle Task Detail Sheet

struct OracleTaskDetailSheet: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onDuplicate: () -> Void
    let onSnooze: (Date) -> Void
    let onDelete: () -> Void
    let onSchedule: (Date) -> Void
    let onStartTimer: (TaskItem) -> Void
    let onDismiss: () -> Void

    // Sheet presentation
    @State private var sheetOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var appeared: Bool = false

    // Editing states
    @State private var editableTitle: String = ""
    @State private var editableNotes: String = ""
    @State private var starRating: Int = 2
    @State private var estimatedMinutes: Int = 30
    @State private var isEditingTitle: Bool = false

    // AI states
    @State private var isOracleThinking: Bool = false
    @State private var oracleInsight: String = ""
    @State private var strategyPoints: [String] = []
    @State private var potentialBlockers: [String] = []
    @State private var successPrediction: Int = 75
    @State private var showTypingAnimation: Bool = false

    // Sub-tasks
    @State private var subTasks: [SubTask] = []
    @State private var subTaskProgress: CGFloat = 0

    // Oracle chat
    @State private var showOracleChat: Bool = false
    @State private var chatMessages: [OracleChatMessage] = []
    @State private var chatInput: String = ""

    // Toast
    @State private var showCopiedToast: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Deep void background with subtle gradient
            oracleBackground

            // Main content
            VStack(spacing: 0) {
                // Drag indicator
                dragIndicator
                    .padding(.top, 12)

                // Scrollable content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Oracle Header
                        OracleHeader(
                            task: task,
                            editableTitle: $editableTitle,
                            starRating: $starRating,
                            estimatedMinutes: $estimatedMinutes,
                            isEditing: $isEditingTitle,
                            onTitleChanged: { newTitle in
                                // Save title change
                            }
                        )
                        .oracleReveal(appeared: appeared, delay: 0)

                        // Context & Notes
                        OracleNotesSection(
                            notes: $editableNotes,
                            placeholder: "Add context to help the Oracle give better advice..."
                        )
                        .oracleReveal(appeared: appeared, delay: 0.05)

                        // AI Oracle Insight (Main Feature)
                        AIInsightOracle(
                            insight: oracleInsight,
                            isThinking: isOracleThinking,
                            showTyping: showTypingAnimation,
                            successPrediction: successPrediction,
                            onRefresh: {
                                refreshOracleInsight()
                            }
                        )
                        .oracleReveal(appeared: appeared, delay: 0.1)

                        // Strategy Crystal
                        StrategyCrystal(
                            strategyPoints: strategyPoints,
                            blockers: potentialBlockers,
                            firstStepTime: "2 min"
                        )
                        .oracleReveal(appeared: appeared, delay: 0.15)

                        // Sub-Task Constellations
                        SubTaskConstellations(
                            subTasks: $subTasks,
                            progress: subTaskProgress,
                            onAddSubTask: { title in
                                addSubTask(title: title)
                            },
                            onToggleSubTask: { subTask in
                                toggleSubTask(subTask)
                            },
                            onDeleteSubTask: { subTask in
                                deleteSubTask(subTask)
                            },
                            onReorder: { from, to in
                                reorderSubTasks(from: from, to: to)
                            },
                            onGenerateAI: {
                                generateAISubTasks()
                            }
                        )
                        .oracleReveal(appeared: appeared, delay: 0.2)

                        // AI Prompt Generator
                        AIPromptGenerator(
                            taskTitle: task.title,
                            subTasks: subTasks,
                            context: editableNotes,
                            onCopy: {
                                showCopiedToast = true
                                HapticsService.shared.impact()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopiedToast = false
                                }
                            }
                        )
                        .oracleReveal(appeared: appeared, delay: 0.25)

                        // Knowledge Stars (Resources)
                        KnowledgeStars(
                            taskTitle: task.title,
                            taskType: task.taskType
                        )
                        .oracleReveal(appeared: appeared, delay: 0.3)

                        // Time Orbit (Scheduling)
                        TimeOrbit(
                            task: task,
                            estimatedMinutes: estimatedMinutes,
                            onSchedule: { date in
                                onSchedule(date)
                            }
                        )
                        .oracleReveal(appeared: appeared, delay: 0.35)

                        // Oracle Chat (Expandable)
                        OracleChatSection(
                            isExpanded: $showOracleChat,
                            messages: $chatMessages,
                            input: $chatInput,
                            taskContext: task.title,
                            onSendMessage: { message in
                                sendOracleMessage(message)
                            }
                        )
                        .oracleReveal(appeared: appeared, delay: 0.4)

                        // Focus Mode Recommendation
                        FocusModeRecommendation(
                            task: task,
                            onStartSession: {
                                onStartTimer(task)
                                onDismiss()
                            }
                        )
                        .oracleReveal(appeared: appeared, delay: 0.45)

                        // Bottom spacing for action bar
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }

            // Fixed bottom action bar
            VStack {
                Spacer()
                OracleActionBar(
                    task: task,
                    onComplete: onComplete,
                    onDuplicate: onDuplicate,
                    onSnooze: { date in
                        onSnooze(date)
                    },
                    onDelete: onDelete
                )
            }

            // Copied toast
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .gesture(dragGesture)
        .onAppear {
            setupInitialState()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            loadOracleContent()
        }
    }

    // MARK: - Background

    private var oracleBackground: some View {
        ZStack {
            // Deep void
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()

            // Subtle radial gradient
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaCore.opacity(0.08),
                    Theme.CelestialColors.voidDeep.opacity(0.5),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Ambient particles (reduced for performance)
            if !reduceMotion {
                OracleAmbientParticles()
                    .opacity(0.4)
            }
        }
    }

    // MARK: - Drag Indicator

    private var dragIndicator: some View {
        Capsule()
            .fill(Theme.CelestialColors.starDim.opacity(0.4))
            .frame(width: 40, height: 5)
            .padding(.bottom, 8)
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)

                Text("Copied to clipboard!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .strokeBorder(Theme.CelestialColors.auroraGreen.opacity(0.3), lineWidth: 1)
                    }
            }
            .padding(.top, 60)

            Spacer()
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    sheetOffset = value.translation.height
                    isDragging = true
                }
            }
            .onEnded { value in
                isDragging = false
                // Velocity-based dismiss
                let velocity = value.predictedEndTranslation.height - value.translation.height
                if value.translation.height > 150 || velocity > 500 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        sheetOffset = 1000
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        sheetOffset = 0
                    }
                }
            }
    }

    // MARK: - Setup

    private func setupInitialState() {
        editableTitle = task.title
        editableNotes = task.contextNotes ?? ""
        starRating = task.starRating
        estimatedMinutes = task.estimatedMinutes ?? 30
    }

    private func loadOracleContent() {
        isOracleThinking = true

        // Simulate AI thinking delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isOracleThinking = false
                showTypingAnimation = true
            }

            // Load AI insight
            oracleInsight = task.aiAdvice ?? generateFallbackInsight()
            strategyPoints = generateStrategyPoints()
            potentialBlockers = ["Time constraint with other commitments", "May need additional research"]
            successPrediction = calculateSuccessPrediction()

            // Load sub-tasks
            loadExistingSubTasks()
        }
    }

    private func refreshOracleInsight() {
        HapticsService.shared.impact()
        isOracleThinking = true
        showTypingAnimation = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isOracleThinking = false
                showTypingAnimation = true
            }
            oracleInsight = "The Oracle has reconsidered your task. Focus on breaking it into smaller, achievable steps. Start with the easiest part to build momentum."
            strategyPoints = [
                "Begin with a 2-minute warm-up action",
                "Set a clear stopping point",
                "Prepare your environment first",
                "Use the Pomodoro technique for sustained focus"
            ]
        }
    }

    // MARK: - Helpers

    private func generateFallbackInsight() -> String {
        switch task.taskType {
        case .create:
            return "Creative tasks require a clear mind and dedicated focus time. Consider scheduling this during your peak energy hours. Start with an outline to organize your thoughts before diving into details."
        case .communicate:
            return "Communication tasks benefit from preparation. Draft your key points before the conversation. Remember: clarity and brevity are valued. Listen actively and follow up promptly."
        case .consume:
            return "Learning is most effective when you're actively engaged. Take notes, ask questions, and try to apply what you learn immediately. Consider teaching the material to someone else to solidify understanding."
        case .coordinate:
            return "Coordination requires clear expectations and follow-through. Document decisions, set deadlines, and assign clear ownership. Regular check-ins prevent surprises."
        }
    }

    private func generateStrategyPoints() -> [String] {
        [
            "Start with a 2-minute micro-action to build momentum",
            "Break the task into 3-5 concrete steps",
            "Set a specific deadline for each step",
            "Prepare your workspace before starting"
        ]
    }

    private func calculateSuccessPrediction() -> Int {
        var score = 60

        // High priority boost
        if task.starRating >= 3 { score += 10 }

        // Has AI advice
        if task.aiAdvice != nil { score += 5 }

        // Has scheduled time
        if task.scheduledTime != nil { score += 10 }

        // Has context
        if task.contextNotes != nil { score += 5 }

        return min(95, score)
    }

    private func loadExistingSubTasks() {
        // TODO: Load from Supabase
        subTasks = []
        updateSubTaskProgress()
    }

    private func addSubTask(title: String) {
        let newSubTask = SubTask(
            id: UUID(),
            taskId: task.id,
            title: title,
            status: .pending,
            orderIndex: subTasks.count,
            isAIGenerated: false
        )
        subTasks.append(newSubTask)
        updateSubTaskProgress()
        HapticsService.shared.selectionFeedback()
    }

    private func toggleSubTask(_ subTask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == subTask.id }) {
            subTasks[index].status = subTask.status == .completed ? .pending : .completed
            updateSubTaskProgress()
            HapticsService.shared.selectionFeedback()
        }
    }

    private func deleteSubTask(_ subTask: SubTask) {
        subTasks.removeAll { $0.id == subTask.id }
        updateSubTaskProgress()
        HapticsService.shared.impact()
    }

    private func reorderSubTasks(from: Int, to: Int) {
        subTasks.move(fromOffsets: IndexSet(integer: from), toOffset: to)
        for (index, _) in subTasks.enumerated() {
            subTasks[index].orderIndex = index
        }
    }

    private func updateSubTaskProgress() {
        let completed = subTasks.filter { $0.status == .completed }.count
        let total = subTasks.count
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            subTaskProgress = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        }
    }

    private func generateAISubTasks() {
        HapticsService.shared.impact()
        // TODO: Call PerplexityService
    }

    private func sendOracleMessage(_ message: String) {
        guard !message.isEmpty else { return }

        // Add user message
        chatMessages.append(OracleChatMessage(
            id: UUID(),
            content: message,
            isUser: true,
            timestamp: Date()
        ))

        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = generateOracleResponse(for: message)
            chatMessages.append(OracleChatMessage(
                id: UUID(),
                content: response,
                isUser: false,
                timestamp: Date()
            ))
        }

        chatInput = ""
        HapticsService.shared.selectionFeedback()
    }

    private func generateOracleResponse(for question: String) -> String {
        let lowercased = question.lowercased()

        if lowercased.contains("start") || lowercased.contains("begin") {
            return "Begin with the smallest possible action - something you can complete in under 2 minutes. This builds momentum and makes the larger task feel more approachable."
        } else if lowercased.contains("break") || lowercased.contains("divide") {
            return "I recommend breaking this into 3-5 distinct phases. Each phase should have a clear deliverable. Would you like me to suggest a breakdown based on your task type?"
        } else if lowercased.contains("time") || lowercased.contains("long") {
            return "Based on similar tasks, I estimate this will take \(estimatedMinutes) minutes of focused work. Consider using Pomodoro intervals for optimal concentration."
        } else {
            return "That's a thoughtful question. Consider approaching this task with curiosity rather than pressure. What specific aspect would you like guidance on?"
        }
    }
}

// MARK: - Oracle Chat Message Model

struct OracleChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Oracle Reveal Modifier

extension View {
    func oracleReveal(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            .scaleEffect(appeared ? 1 : 0.95)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8).delay(delay),
                value: appeared
            )
    }
}

// MARK: - Oracle Ambient Particles

struct OracleAmbientParticles: View {
    @State private var particles: [AmbientParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: 2)
                    .opacity(particle.opacity)
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [
            Theme.CelestialColors.nebulaCore.opacity(0.6),
            Theme.Colors.aiAmber.opacity(0.4),
            Theme.CelestialColors.starWhite.opacity(0.3)
        ]

        for i in 0..<15 {
            let particle = AmbientParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...6),
                color: colors.randomElement() ?? .white,
                opacity: Double.random(in: 0.2...0.5)
            )
            particles.append(particle)
        }
    }
}

struct AmbientParticle: Identifiable {
    let id: UUID
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
}

// MARK: - Preview

#Preview {
    OracleTaskDetailSheet(
        task: {
            let task = TaskItem(title: "Create pitch deck for Syba.io")
            task.starRating = 3
            task.taskTypeRaw = TaskType.create.rawValue
            task.estimatedMinutes = 90
            task.aiAdvice = "Start with an outline of your key value propositions. Focus on the problem you solve, your unique approach, and clear metrics."
            return task
        }(),
        onComplete: {},
        onDuplicate: {},
        onSnooze: { _ in },
        onDelete: {},
        onSchedule: { _ in },
        onStartTimer: { _ in },
        onDismiss: {}
    )
}

// MARK: - Oracle Header

/// Premium header with category glow, interactive priority stars, and editable title
struct OracleHeader: View {
    let task: TaskItem
    @Binding var editableTitle: String
    @Binding var starRating: Int
    @Binding var estimatedMinutes: Int
    @Binding var isEditing: Bool
    let onTitleChanged: (String) -> Void

    @State private var categoryGlow: CGFloat = 0
    @FocusState private var isTitleFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category pill with glow
            categoryPill

            // Editable title
            titleSection

            // Priority stars + estimated time
            HStack(spacing: 20) {
                priorityStars
                Spacer()
                estimatedTimeDisplay
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.voidMedium.opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    task.taskType.color.opacity(0.4),
                                    task.taskType.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    categoryGlow = 1
                }
            }
        }
    }

    private var categoryPill: some View {
        HStack(spacing: 8) {
            Image(systemName: task.taskType.icon)
                .font(.system(size: 14, weight: .semibold))

            Text(task.taskType.displayName)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(task.taskType.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(task.taskType.color.opacity(0.15))
                .overlay {
                    Capsule()
                        .strokeBorder(task.taskType.color.opacity(0.3), lineWidth: 1)
                }
                .shadow(
                    color: task.taskType.color.opacity(reduceMotion ? 0.2 : 0.2 + categoryGlow * 0.15),
                    radius: reduceMotion ? 8 : 8 + categoryGlow * 8,
                    x: 0,
                    y: 0
                )
        }
    }

    private var titleSection: some View {
        Group {
            if isEditing {
                TextField("Task title", text: $editableTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isEditing = false
                        onTitleChanged(editableTitle)
                    }
                    .onAppear {
                        isTitleFocused = true
                    }
            } else {
                Text(editableTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .onTapGesture {
                        isEditing = true
                        HapticsService.shared.selectionFeedback()
                    }
            }
        }
    }

    private var priorityStars: some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: index <= starRating ? "star.fill" : "star")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        index <= starRating
                            ? Theme.Colors.aiAmber
                            : Theme.CelestialColors.starDim.opacity(0.5)
                    )
                    .scaleEffect(index <= starRating ? 1.0 : 0.9)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            starRating = starRating == index ? index - 1 : index
                        }
                        HapticsService.shared.selectionFeedback()
                    }
            }

            Text("Priority")
                .font(.system(size: 12))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .padding(.leading, 4)
        }
    }

    private var estimatedTimeDisplay: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 14))
                .foregroundStyle(Theme.CelestialColors.nebulaCore)

            Text("\(estimatedMinutes) min")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.CelestialColors.nebulaCore.opacity(0.15))
        }
        .onTapGesture {
            // Cycle through common durations
            let durations = [15, 30, 45, 60, 90, 120]
            if let currentIndex = durations.firstIndex(of: estimatedMinutes) {
                estimatedMinutes = durations[(currentIndex + 1) % durations.count]
            } else {
                estimatedMinutes = 30
            }
            HapticsService.shared.selectionFeedback()
        }
    }
}

// MARK: - Oracle Notes Section

/// Expandable notes/context area
struct OracleNotesSection: View {
    @Binding var notes: String
    let placeholder: String

    @State private var isExpanded: Bool = false
    @FocusState private var isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticsService.shared.selectionFeedback()
            } label: {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)

                    Text("Context & Notes")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }

            // Expandable content
            if isExpanded {
                TextEditor(text: $notes)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 150)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    }
                    .focused($isEditing)
                    .overlay(alignment: .topLeading) {
                        if notes.isEmpty && !isEditing {
                            Text(placeholder)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.voidMedium.opacity(0.4))
        }
        .onAppear {
            isExpanded = !notes.isEmpty
        }
    }
}

// MARK: - AI Insight Oracle

/// The main AI insight section with swirling orb and typing animation
struct AIInsightOracle: View {
    let insight: String
    let isThinking: Bool
    let showTyping: Bool
    let successPrediction: Int
    let onRefresh: () -> Void

    @State private var orbRotation: Double = 0
    @State private var orbPulse: CGFloat = 1
    @State private var typedText: String = ""
    @State private var displayedCharacters: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            // Header with swirling orb
            HStack(alignment: .top, spacing: 12) {
                // Oracle orb
                oracleOrb
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Oracle Insight")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)

                        Spacer()

                        // Refresh button
                        Button {
                            onRefresh()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.CelestialColors.nebulaCore)
                                .rotationEffect(.degrees(isThinking ? 360 : 0))
                                .animation(
                                    isThinking ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                    value: isThinking
                                )
                        }
                        .disabled(isThinking)
                    }

                    // Success prediction
                    HStack(spacing: 6) {
                        Text("Success likelihood:")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.CelestialColors.starDim)

                        Text("\(successPrediction)%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(successColor)
                    }
                }
            }

            // Insight text with typing effect
            if isThinking {
                thinkingIndicator
            } else {
                insightText
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.nebulaCore.opacity(0.15),
                            Theme.CelestialColors.voidMedium.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            Theme.CelestialColors.nebulaCore.opacity(0.3),
                            lineWidth: 1
                        )
                }
        }
        .onChange(of: insight) { _, newValue in
            if showTyping && !reduceMotion {
                startTypingAnimation(text: newValue)
            } else {
                typedText = newValue
            }
        }
        .onAppear {
            if !insight.isEmpty {
                if showTyping && !reduceMotion {
                    startTypingAnimation(text: insight)
                } else {
                    typedText = insight
                }
            }

            if !reduceMotion {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    orbRotation = 360
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    orbPulse = 1.15
                }
            }
        }
    }

    private var oracleOrb: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.nebulaCore.opacity(0.4),
                            Theme.CelestialColors.nebulaCore.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 30
                    )
                )
                .scaleEffect(orbPulse)
                .blur(radius: 4)

            // Inner orb with swirl
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Theme.CelestialColors.nebulaCore,
                            Theme.Colors.aiPurple,
                            Theme.CelestialColors.nebulaCore.opacity(0.5),
                            Theme.CelestialColors.nebulaCore
                        ],
                        center: .center
                    )
                )
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(orbRotation))

            // Core sparkle
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var thinkingIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.CelestialColors.nebulaCore)
                    .frame(width: 8, height: 8)
                    .opacity(isThinking ? 1 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isThinking
                    )
            }

            Text("Oracle is thinking...")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var insightText: some View {
        Text(typedText)
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var successColor: Color {
        switch successPrediction {
        case 80...100: return Theme.CelestialColors.auroraGreen
        case 60..<80: return Theme.Colors.aiAmber
        default: return Theme.CelestialColors.nebulaCore
        }
    }

    private func startTypingAnimation(text: String) {
        typedText = ""
        displayedCharacters = 0

        let characters = Array(text)
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if displayedCharacters < characters.count {
                typedText.append(characters[displayedCharacters])
                displayedCharacters += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Strategy Crystal

/// Strategy breakdown with shimmer effect and actionable bullet points
struct StrategyCrystal: View {
    let strategyPoints: [String]
    let blockers: [String]
    let firstStepTime: String

    @State private var shimmerOffset: CGFloat = -200
    @State private var expandedBlockers: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, Theme.CelestialColors.nebulaCore],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Strategy Crystal")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()
            }

            // Strategy points
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(strategyPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: 12) {
                        // Step indicator
                        ZStack {
                            Circle()
                                .fill(Theme.CelestialColors.nebulaCore.opacity(0.2))
                                .frame(width: 24, height: 24)

                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.CelestialColors.nebulaCore)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(point)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.9))

                            // First step CTA
                            if index == 0 {
                                Text("Start here • \(firstStepTime)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
            }

            // Potential blockers (collapsible)
            if !blockers.isEmpty {
                Divider()
                    .background(Theme.CelestialColors.starDim.opacity(0.2))

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            expandedBlockers.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.aiAmber)

                            Text("Potential Blockers")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.Colors.aiAmber)

                            Spacer()

                            Image(systemName: expandedBlockers ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.CelestialColors.starDim)
                        }
                    }

                    if expandedBlockers {
                        ForEach(blockers, id: \.self) { blocker in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Theme.Colors.aiAmber.opacity(0.5))
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 6)

                                Text(blocker)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.voidMedium.opacity(0.5))
                .overlay {
                    // Shimmer effect
                    if !reduceMotion {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.cyan.opacity(0.3), Theme.CelestialColors.nebulaCore.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
        }
    }
}

// MARK: - Sub-Task Constellations

/// Sub-tasks displayed as interconnected mini-cards
struct SubTaskConstellations: View {
    @Binding var subTasks: [SubTask]
    let progress: CGFloat
    let onAddSubTask: (String) -> Void
    let onToggleSubTask: (SubTask) -> Void
    let onDeleteSubTask: (SubTask) -> Void
    let onReorder: (Int, Int) -> Void
    let onGenerateAI: () -> Void

    @State private var newSubTaskTitle: String = ""
    @State private var isAddingNew: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var swipedTaskId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with progress
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)

                Text("Sub-tasks")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                // Progress indicator
                HStack(spacing: 6) {
                    Text("\(completedCount)/\(subTasks.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    // Mini progress ring
                    ZStack {
                        Circle()
                            .stroke(Theme.CelestialColors.starDim.opacity(0.3), lineWidth: 2)
                            .frame(width: 18, height: 18)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                Theme.CelestialColors.auroraGreen,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: 18, height: 18)
                            .rotationEffect(.degrees(-90))
                    }
                }
            }

            // Sub-task list
            if subTasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(subTasks.enumerated()), id: \.element.id) { index, subTask in
                        subTaskCard(subTask, index: index)
                    }
                }
            }

            // Add new sub-task
            if isAddingNew {
                addSubTaskInput
            }

            // Action buttons
            HStack(spacing: 12) {
                // Add manually
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isAddingNew = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isInputFocused = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))

                        Text("Add Step")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .strokeBorder(Theme.CelestialColors.nebulaCore.opacity(0.4), lineWidth: 1)
                    }
                }

                // AI Generate
                Button {
                    onGenerateAI()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 12, weight: .bold))

                        Text("AI Generate")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Theme.CelestialColors.nebulaCore.opacity(0.3))
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.voidMedium.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.CelestialColors.auroraGreen.opacity(0.2), lineWidth: 1)
                }
        }
    }

    private var completedCount: Int {
        subTasks.filter { $0.status == .completed }.count
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "list.bullet.indent")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.5))

                Text("No sub-tasks yet")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.7))
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    private func subTaskCard(_ subTask: SubTask, index: Int) -> some View {
        HStack(spacing: 12) {
            // Completion toggle
            Button {
                onToggleSubTask(subTask)
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(
                            subTask.status == .completed
                                ? Theme.CelestialColors.auroraGreen
                                : Theme.CelestialColors.starDim.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if subTask.status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.CelestialColors.auroraGreen)
                    }
                }
            }

            // Title
            Text(subTask.title)
                .font(.system(size: 14))
                .foregroundStyle(subTask.status == .completed ? Theme.CelestialColors.starDim : .white)
                .strikethrough(subTask.status == .completed, color: Theme.CelestialColors.starDim)
                .frame(maxWidth: .infinity, alignment: .leading)

            // AI badge
            if subTask.isAIGenerated {
                Image(systemName: "sparkle")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.nebulaCore.opacity(0.7))
            }

            // Delete button (shown on swipe)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onDeleteSubTask(subTask)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        }
    }

    private var addSubTaskInput: some View {
        HStack(spacing: 12) {
            TextField("Add a step...", text: $newSubTaskTitle)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit {
                    if !newSubTaskTitle.isEmpty {
                        onAddSubTask(newSubTaskTitle)
                        newSubTaskTitle = ""
                    }
                    isAddingNew = false
                }

            Button {
                isAddingNew = false
                newSubTaskTitle = ""
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.CelestialColors.nebulaCore.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

// MARK: - AI Prompt Generator

/// Generate and copy AI prompts for task execution
struct AIPromptGenerator: View {
    let taskTitle: String
    let subTasks: [SubTask]
    let context: String
    let onCopy: () -> Void

    @State private var isExpanded: Bool = false
    @State private var generatedPrompt: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    if isExpanded && generatedPrompt.isEmpty {
                        generatePrompt()
                    }
                }
                HapticsService.shared.selectionFeedback()
            } label: {
                HStack {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.aiPurple)

                    Text("AI Prompt Generator")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("Copy for ChatGPT/Claude")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Generated prompt
                    Text(generatedPrompt)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(3)
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        }

                    // Copy button
                    Button {
                        UIPasteboard.general.string = generatedPrompt
                        onCopy()
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 13))

                            Text("Copy Prompt")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.aiPurple)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.voidMedium.opacity(0.4))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.Colors.aiPurple.opacity(0.2), lineWidth: 1)
                }
        }
    }

    private func generatePrompt() {
        var prompt = "Help me complete this task: \"\(taskTitle)\"\n\n"

        if !context.isEmpty {
            prompt += "Context: \(context)\n\n"
        }

        if !subTasks.isEmpty {
            prompt += "Sub-tasks to complete:\n"
            for (index, subTask) in subTasks.enumerated() {
                let status = subTask.status == .completed ? "✓" : "○"
                prompt += "\(index + 1). \(status) \(subTask.title)\n"
            }
            prompt += "\n"
        }

        prompt += "Please provide:\n"
        prompt += "1. A clear step-by-step approach\n"
        prompt += "2. Potential challenges and how to overcome them\n"
        prompt += "3. Time-saving tips\n"
        prompt += "4. Quality checkpoints"

        generatedPrompt = prompt
    }
}

// MARK: - Knowledge Stars (Resources)

/// External resources displayed as tappable star cards
struct KnowledgeStars: View {
    let taskTitle: String
    let taskType: TaskType

    @State private var resources: [TaskResource] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiBlue)

                Text("Knowledge Stars")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.CelestialColors.starDim)
                }
            }

            // Resource cards
            if resources.isEmpty && !isLoading {
                emptyResourceState
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(resources) { resource in
                        resourceCard(resource)
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.voidMedium.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.Colors.aiBlue.opacity(0.2), lineWidth: 1)
                }
        }
        .onAppear {
            loadResources()
        }
    }

    private var emptyResourceState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.5))

                Text("No resources found")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.7))
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    private func resourceCard(_ resource: TaskResource) -> some View {
        Button {
            if let url = URL(string: resource.url) {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Type icon
                HStack {
                    Image(systemName: resource.type.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(resource.type.color)

                    if let duration = resource.duration {
                        Text(duration)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }

                    Spacer()
                }

                // Title
                Text(resource.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Source
                Text(resource.source)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(resource.type.color.opacity(0.2), lineWidth: 1)
                    }
            }
        }
    }

    private func loadResources() {
        // Simulate loading resources
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            resources = [
                TaskResource(
                    title: "Getting Started Guide",
                    url: "https://example.com",
                    source: "Documentation",
                    type: .documentation
                ),
                TaskResource(
                    title: "Quick Tutorial",
                    url: "https://youtube.com",
                    source: "YouTube",
                    type: .youtube,
                    duration: "8 min"
                )
            ]
            isLoading = false
        }
    }
}

// MARK: - Time Orbit (Scheduling)

/// Circular orbit visualization for scheduling
struct TimeOrbit: View {
    let task: TaskItem
    let estimatedMinutes: Int
    let onSchedule: (Date) -> Void

    @State private var selectedSlot: ScheduleSlot?
    @State private var orbitRotation: Double = 0
    @State private var showDatePicker: Bool = false
    @State private var customDate: Date = Date()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.aiAmber)

                Text("Time Orbit")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("~\(estimatedMinutes) min")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            // Quick schedule slots
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(scheduleSlots) { slot in
                        scheduleSlotButton(slot)
                    }

                    // Custom time
                    Button {
                        showDatePicker = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16))

                            Text("Custom")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .frame(width: 70, height: 70)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Theme.CelestialColors.starDim.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Currently scheduled indicator
            if let scheduled = task.scheduledTime {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)

                    Text("Scheduled: \(formattedDate(scheduled))")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(Theme.CelestialColors.auroraGreen.opacity(0.15))
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.voidMedium.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.Colors.aiAmber.opacity(0.2), lineWidth: 1)
                }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }

    private var scheduleSlots: [ScheduleSlot] {
        let calendar = Calendar.current
        let now = Date()

        return [
            ScheduleSlot(
                id: UUID(),
                label: "Now",
                sublabel: "Start immediately",
                date: now,
                icon: "bolt.fill"
            ),
            ScheduleSlot(
                id: UUID(),
                label: "In 1 hour",
                sublabel: formattedTime(calendar.date(byAdding: .hour, value: 1, to: now)!),
                date: calendar.date(byAdding: .hour, value: 1, to: now)!,
                icon: "clock"
            ),
            ScheduleSlot(
                id: UUID(),
                label: "Tomorrow",
                sublabel: "9:00 AM",
                date: tomorrowMorning(),
                icon: "sunrise"
            ),
            ScheduleSlot(
                id: UUID(),
                label: "This Weekend",
                sublabel: "Saturday",
                date: nextWeekend(),
                icon: "sparkles"
            )
        ]
    }

    private func scheduleSlotButton(_ slot: ScheduleSlot) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSlot = slot
            }
            onSchedule(slot.date)
            HapticsService.shared.selectionFeedback()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: slot.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(
                        selectedSlot?.id == slot.id
                            ? Theme.Colors.aiAmber
                            : Theme.CelestialColors.starDim
                    )

                Text(slot.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        selectedSlot?.id == slot.id
                            ? .white
                            : Theme.CelestialColors.starDim
                    )

                Text(slot.sublabel)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.7))
            }
            .frame(width: 80, height: 80)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        selectedSlot?.id == slot.id
                            ? Theme.Colors.aiAmber.opacity(0.2)
                            : Color.white.opacity(0.03)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                selectedSlot?.id == slot.id
                                    ? Theme.Colors.aiAmber.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    }
            }
        }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker(
                "Select Date & Time",
                selection: $customDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Schedule Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDatePicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        onSchedule(customDate)
                        showDatePicker = false
                        HapticsService.shared.successFeedback()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func tomorrowMorning() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
    }

    private func nextWeekend() -> Date {
        let calendar = Calendar.current
        var date = Date()
        while calendar.component(.weekday, from: date) != 7 { // Saturday
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
    }
}

struct ScheduleSlot: Identifiable {
    let id: UUID
    let label: String
    let sublabel: String
    let date: Date
    let icon: String
}

// MARK: - Oracle Chat Section

/// Expandable chat interface for contextual questions
struct OracleChatSection: View {
    @Binding var isExpanded: Bool
    @Binding var messages: [OracleChatMessage]
    @Binding var input: String
    let taskContext: String
    let onSendMessage: (String) -> Void

    @FocusState private var isInputFocused: Bool
    @State private var isThinking: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticsService.shared.selectionFeedback()
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)

                    Text("Ask the Oracle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    if !messages.isEmpty {
                        Text("\(messages.count) messages")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }

            // Expanded chat content
            if isExpanded {
                VStack(spacing: 12) {
                    // Messages
                    if messages.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    messageRow(message)
                                }

                                if isThinking {
                                    thinkingIndicator
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }

                    // Quick suggestions
                    if messages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickSuggestions, id: \.self) { suggestion in
                                    Button {
                                        sendMessage(suggestion)
                                    } label: {
                                        Text(suggestion)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.CelestialColors.nebulaCore)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background {
                                                Capsule()
                                                    .strokeBorder(Theme.CelestialColors.nebulaCore.opacity(0.3), lineWidth: 1)
                                            }
                                    }
                                }
                            }
                        }
                    }

                    // Input field
                    HStack(spacing: 12) {
                        TextField("Ask a question...", text: $input)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .focused($isInputFocused)
                            .submitLabel(.send)
                            .onSubmit {
                                sendMessage(input)
                            }

                        Button {
                            sendMessage(input)
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    input.isEmpty
                                        ? Theme.CelestialColors.starDim.opacity(0.5)
                                        : Theme.CelestialColors.nebulaCore
                                )
                        }
                        .disabled(input.isEmpty)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.05))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(Theme.CelestialColors.nebulaCore.opacity(0.2), lineWidth: 1)
                            }
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.voidMedium.opacity(0.4))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.CelestialColors.nebulaCore.opacity(0.15), lineWidth: 1)
                }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 24))
                .foregroundStyle(Theme.CelestialColors.nebulaCore.opacity(0.5))

            Text("Ask me anything about this task")
                .font(.system(size: 13))
                .foregroundStyle(Theme.CelestialColors.starDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func messageRow(_ message: OracleChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                message.isUser
                                    ? Theme.CelestialColors.nebulaCore.opacity(0.3)
                                    : Color.white.opacity(0.05)
                            )
                    }

                Text(formattedTime(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.6))
            }

            if !message.isUser {
                Spacer()
            }
        }
    }

    private var thinkingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.CelestialColors.nebulaCore)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 14)
    }

    private var quickSuggestions: [String] {
        [
            "How should I start?",
            "Break this into steps",
            "What tools do I need?",
            "How long will this take?"
        ]
    }

    private func sendMessage(_ message: String) {
        guard !message.isEmpty else { return }
        isThinking = true
        onSendMessage(message)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isThinking = false
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Focus Mode Recommendation

/// Suggests optimal focus mode settings for the task
struct FocusModeRecommendation: View {
    let task: TaskItem
    let onStartSession: () -> Void

    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    // Pulsing background
                    Circle()
                        .fill(Theme.Colors.aiAmber.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .scaleEffect(reduceMotion ? 1.0 : 1 + pulsePhase * 0.15)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiAmber)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus Mode")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Recommended: \(recommendedDuration) min session")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }

                Spacer()
            }

            // Focus benefits
            VStack(alignment: .leading, spacing: 8) {
                focusBenefit(icon: "bell.slash.fill", text: "Notifications silenced")
                focusBenefit(icon: "app.badge", text: "Distracting apps blocked")
                focusBenefit(icon: "timer", text: "Pomodoro timer ready")
            }

            // Start button
            Button {
                onStartSession()
                HapticsService.shared.successFeedback()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))

                    Text("Start Focus Session")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.Colors.aiAmber)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiAmber.opacity(0.1),
                            Theme.CelestialColors.voidMedium.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.Colors.aiAmber.opacity(0.25), lineWidth: 1)
                }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulsePhase = 1
                }
            }
        }
    }

    private var recommendedDuration: Int {
        switch task.taskType {
        case .create: return 45
        case .communicate: return 25
        case .consume: return 30
        case .coordinate: return 15
        }
    }

    private func focusBenefit(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.aiAmber.opacity(0.8))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - Oracle Action Bar

/// Fixed bottom action bar with Complete, Duplicate, Snooze, Delete
struct OracleActionBar: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onDuplicate: () -> Void
    let onSnooze: (Date) -> Void
    let onDelete: () -> Void

    @State private var showSnoozeOptions: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var completePulse: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            // Complete (Primary)
            Button {
                onComplete()
                HapticsService.shared.successFeedback()
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        // Pulse effect
                        Circle()
                            .fill(Theme.CelestialColors.auroraGreen.opacity(0.3))
                            .frame(width: 48, height: 48)
                            .scaleEffect(reduceMotion ? 1.0 : 1 + completePulse * 0.2)
                            .opacity(1 - completePulse * 0.5)

                        Circle()
                            .fill(Theme.CelestialColors.auroraGreen)
                            .frame(width: 44, height: 44)

                        Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.black)
                    }

                    Text("Complete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.auroraGreen)
                }
            }
            .frame(maxWidth: .infinity)

            // Duplicate
            Button {
                onDuplicate()
                HapticsService.shared.selectionFeedback()
            } label: {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        }

                    Text("Duplicate")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
            .frame(maxWidth: .infinity)

            // Snooze
            Button {
                showSnoozeOptions = true
                HapticsService.shared.selectionFeedback()
            } label: {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        }

                    Text("Snooze")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                }
            }
            .frame(maxWidth: .infinity)

            // Delete
            Button {
                showDeleteConfirm = true
                HapticsService.shared.impact()
            } label: {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundStyle(.red.opacity(0.8))
                        }

                    Text("Delete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Rectangle()
                        .fill(Theme.CelestialColors.voidDeep.opacity(0.8))
                }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.CelestialColors.starDim.opacity(0.1))
                        .frame(height: 1)
                }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    completePulse = 1
                }
            }
        }
        .confirmationDialog("Snooze Task", isPresented: $showSnoozeOptions) {
            Button("1 Hour") {
                snoozeFor(hours: 1)
            }
            Button("3 Hours") {
                snoozeFor(hours: 3)
            }
            Button("Tomorrow Morning") {
                snoozeTomorrowMorning()
            }
            Button("Next Week") {
                snoozeNextWeek()
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func snoozeFor(hours: Int) {
        let snoozeDate = Calendar.current.date(byAdding: .hour, value: hours, to: Date())!
        onSnooze(snoozeDate)
        HapticsService.shared.successFeedback()
    }

    private func snoozeTomorrowMorning() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let snoozeDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        onSnooze(snoozeDate)
        HapticsService.shared.successFeedback()
    }

    private func snoozeNextWeek() {
        let snoozeDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        onSnooze(snoozeDate)
        HapticsService.shared.successFeedback()
    }
}
